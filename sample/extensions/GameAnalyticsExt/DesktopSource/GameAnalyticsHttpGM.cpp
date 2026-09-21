//
// GAHttpClient implementation on top of GameMaker's own HTTP stack.
//
// Why: the C++ SDK's default client is cURL, which means shipping libcurl and
// OpenSSL inside the extension — per-architecture static builds via vcpkg, and
// OpenSSL cannot be built for x86_64 here, which would cost the universal
// binary. GameMaker's runner already has a working HTTP/TLS stack on Windows,
// macOS and Linux, so this routes the SDK's requests through it: one
// implementation for all three desktop targets and no external dependencies.
// (Android and iOS don't need this — they use the native GA SDKs, which bring
// their own networking.)
//
// How it fits together, given what the runner actually offers:
//   * The SDK calls sendRequest() on its own worker thread, while GameMaker
//     must be driven from the game thread.
//   * The native HTTP_Request in the runner interface cannot return a response
//     to native code: its completion callback is handed a NULL payload and an
//     unset ds_map index (it expects the extension to *create* the map), and
//     the interface exposes ds_map writes but no reads. Verified empirically —
//     "http async: ctx=... payload=0x0 map=... mapValue=-1".
//   * So the request is issued by GML's documented http_request(), whose Async
//     HTTP event carries both http_status and the body.
//
//   SDK worker thread                game thread (GML)
//   -----------------                -----------------
//   sendRequest()
//     queue the request
//     wait on condition  .........   ga_http_pump()     (per step)
//                                      http_request(url, "POST", headers, body)
//                                    Async HTTP event
//                                      gaHttpDeliver(status, body)
//     <- signalled
//   return {code, packet}
//
// The SDK submits from a single worker thread and blocks until sendRequest
// returns, so at most one request is ever in flight and no request id
// bookkeeping is needed. gaHttpPendingUrl() lets the GML side confirm that an
// async event belongs to this request rather than to the game's own traffic.
//
// GML strings cannot carry NUL bytes, so a gzipped body cannot be handed to
// http_request. Release builds of the SDK gzip the payload (GAHTTPApi sets
// useGzip unless _DEBUG), so it is inflated back to JSON here and sent
// uncompressed, without the Content-Encoding header — the same wire format the
// SDK itself uses in debug builds, at the cost of some upload bandwidth.
//
// The Authorization header is an HMAC-SHA256 over the bytes being sent, so it
// is recomputed over the inflated body with the SDK's own helper; leaving the
// SDK's signature in place returns 401 from the API.
//

#include "GameAnalytics/GameAnalytics.h"
#include "GameAnalytics/GAHttpClient.h"

// Internal header, for the SDK's own HMAC helper — the Authorization header is
// signed over the request body, so inflating the body means re-signing it with
// exactly the same algorithm the server expects.
#include "GAUtilities.h"

#include <zlib.h>

#include <chrono>
#include <condition_variable>
#include <cstring>
#include <mutex>
#include <string>
#include <vector>

#if defined(_WIN32)
#define GM_API extern "C" __declspec(dllexport)
#else
#define GM_API extern "C" __attribute__((visibility("default")))
#endif

namespace
{
    // How long the SDK thread waits for GML to deliver a response before
    // giving up. A miss is reported to the SDK as a failed request, which it
    // retries on its next flush, so this only needs to be generous.
    constexpr int kRequestTimeoutSeconds = 60;

    struct PendingRequest
    {
        bool active     = false;   // sendRequest is waiting on this
        bool dispatched = false;   // HTTP_Request has been issued
        bool completed  = false;   // a response (or failure) has arrived

        std::string url;
        std::string auth;   // header value only, GML builds the header map
        std::string body;   // plain JSON, safe to hand to GML as a string

        long        code = -1;
        std::string response;
    };

    std::mutex              g_mutex;
    std::condition_variable g_cv;
    PendingRequest          g_pending;

    // Needed to re-sign a body this client had to re-encode. Set from
    // initialize(); never logged.
    std::mutex  g_secretMutex;
    std::string g_gameSecret;

    // The SDK hands over a complete header line ("Authorization: ..."); GML
    // needs the value on its own to put in the header map.
    std::string headerValue(std::string const& headerLine)
    {
        const std::string::size_type colon = headerLine.find(':');
        if (colon == std::string::npos) return headerLine;

        std::string value = headerLine.substr(colon + 1);
        const std::string::size_type start = value.find_first_not_of(" \t");
        return (start == std::string::npos) ? std::string() : value.substr(start);
    }

    // Inflates a gzip stream. Returns false and leaves `out` untouched if the
    // data is not valid gzip, in which case the caller sends it verbatim.
    bool gunzip(std::vector<uint8_t> const& in, std::string& out)
    {
        if (in.empty()) return false;

        z_stream stream = {};
        if (inflateInit2(&stream, 15 + 16) != Z_OK) return false;   // 16 => gzip wrapper

        stream.next_in  = const_cast<Bytef*>(in.data());
        stream.avail_in = static_cast<uInt>(in.size());

        std::string result;
        char buffer[16384];
        int status = Z_OK;

        do
        {
            stream.next_out  = reinterpret_cast<Bytef*>(buffer);
            stream.avail_out = sizeof(buffer);

            status = inflate(&stream, Z_NO_FLUSH);
            if (status != Z_OK && status != Z_STREAM_END)
            {
                inflateEnd(&stream);
                return false;
            }
            result.append(buffer, sizeof(buffer) - stream.avail_out);
        }
        while (status != Z_STREAM_END);

        inflateEnd(&stream);
        out = std::move(result);
        return true;
    }
}

namespace gameanalytics
{
    class GAHttpClientGameMaker : public GAHttpClient
    {
    public:

        void initialize() override
        {
        }

        void cleanup() override
        {
            // Never leave the SDK thread parked on a request that can no
            // longer be pumped (the game is shutting down).
            std::lock_guard<std::mutex> lock(g_mutex);
            if (g_pending.active && !g_pending.completed)
            {
                g_pending.code      = -1;
                g_pending.completed = true;
                g_cv.notify_all();
            }
        }

        Response sendRequest(
            std::string const& url,
            std::string const& auth,
            std::vector<uint8_t> const& payloadData,
            bool useGzip,
            void* userData) override
        {
            (void)userData;

            Response response;

            std::unique_lock<std::mutex> lock(g_mutex);

            g_pending        = PendingRequest();
            g_pending.active = true;
            g_pending.url    = url;
            g_pending.auth   = headerValue(auth);

            if (useGzip && gunzip(payloadData, g_pending.body))
            {
                // Body changed, so the SDK's signature no longer matches it.
                std::string secret;
                {
                    std::lock_guard<std::mutex> secretLock(g_secretMutex);
                    secret = g_gameSecret;
                }

                if (!secret.empty())
                {
                    const std::vector<uint8_t> signedBytes(g_pending.body.begin(), g_pending.body.end());
                    std::vector<uint8_t> hmac;
                    gameanalytics::utilities::GAUtilities::hmacWithKey(secret.c_str(), signedBytes, hmac);

                    std::string recomputed(reinterpret_cast<const char*>(hmac.data()), hmac.size());
                    const std::string::size_type nul = recomputed.find('\0');
                    if (nul != std::string::npos) recomputed.resize(nul);

                    if (!recomputed.empty()) g_pending.auth = recomputed;
                }
            }
            else
            {
                g_pending.body.assign(payloadData.begin(), payloadData.end());
            }

            const bool delivered = g_cv.wait_for(
                lock,
                std::chrono::seconds(kRequestTimeoutSeconds),
                [] { return g_pending.completed; });

            if (delivered)
            {
                response.code = g_pending.code;
                if (!g_pending.response.empty())
                {
                    const uint8_t* bytes = reinterpret_cast<const uint8_t*>(g_pending.response.data());
                    response.packet.assign(bytes, bytes + g_pending.response.size());
                }
            }

            g_pending = PendingRequest();
            return response;
        }
    };
}

// ---------------------------------------------------------------------------
// Entry points driven from GML
// ---------------------------------------------------------------------------

/// Claims the queued request, if any, for GML to send. Returns 1 when there is
/// one to issue (its url/auth/body are then readable below), otherwise 0.
GM_API double gaHttpPump()
{
    std::lock_guard<std::mutex> lock(g_mutex);
    if (!g_pending.active || g_pending.dispatched || g_pending.completed)
    {
        return 0.0;
    }
    g_pending.dispatched = true;
    return 1.0;
}

/// True while a request is waiting for its response.
GM_API double gaHttpHasPending()
{
    std::lock_guard<std::mutex> lock(g_mutex);
    return (g_pending.active && !g_pending.completed) ? 1.0 : 0.0;
}

/// The URL of the in-flight request, also used by the GML side to tell this
/// request's async event apart from the game's own HTTP traffic.
GM_API const char* gaHttpPendingUrl()
{
    static thread_local std::string url;
    std::lock_guard<std::mutex> lock(g_mutex);
    url = g_pending.active ? g_pending.url : std::string();
    return url.c_str();
}

/// Value for the Authorization header of the in-flight request.
GM_API const char* gaHttpPendingAuth()
{
    static thread_local std::string auth;
    std::lock_guard<std::mutex> lock(g_mutex);
    auth = g_pending.active ? g_pending.auth : std::string();
    return auth.c_str();
}

/// Body of the in-flight request as JSON text.
GM_API const char* gaHttpPendingBody()
{
    static thread_local std::string body;
    std::lock_guard<std::mutex> lock(g_mutex);
    body = g_pending.active ? g_pending.body : std::string();
    return body.c_str();
}

/// Hands a completed response back to the waiting SDK thread. `status` is the
/// HTTP status code, or a negative value for a transport failure.
GM_API void gaHttpDeliver(double status, const char* body)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    if (!g_pending.active || g_pending.completed)
    {
        return;
    }
    g_pending.code      = static_cast<long>(status);
    g_pending.response  = body ? body : "";
    g_pending.completed = true;
    g_cv.notify_all();
}

/// Fails the in-flight request immediately. Call on game end so shutdown does
/// not wait out the timeout.
GM_API void gaHttpAbort()
{
    std::lock_guard<std::mutex> lock(g_mutex);
    if (g_pending.active && !g_pending.completed)
    {
        g_pending.code      = -1;
        g_pending.completed = true;
        g_cv.notify_all();
    }
}

// Called from the extension's initialize() entry point so bodies this client
// re-encodes can be re-signed.
void gaGmSetGameSecret(const char* gameSecret)
{
    std::lock_guard<std::mutex> lock(g_secretMutex);
    g_gameSecret = gameSecret ? gameSecret : "";
}

// Installed from the extension's initialize() entry point, which is the only
// point at which the SDK accepts a custom client.
void gaGmInstallHttpClient()
{
    static bool installed = false;
    if (installed) return;
    installed = true;

    gameanalytics::GameAnalytics::configureHttpClient<gameanalytics::GAHttpClientGameMaker>();
}
