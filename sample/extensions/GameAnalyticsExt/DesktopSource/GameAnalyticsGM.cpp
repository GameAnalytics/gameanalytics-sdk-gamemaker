//
// GameAnalytics GameMaker extension — desktop (Windows / macOS / Linux)
//
// GameMaker can only pass up to 4 arguments to a native extension function
// once any of them is a string ("Extension function X has more than 4
// parameters and they are not all numbers"), but the C++ SDK's event calls
// take 6-7 arguments now that they carry customFields/mergeFields. This file
// bridges the two: the wide calls are exposed as single-string entry points
// taking a JSON array of the arguments, and everything that already fits
// GameMaker's limit is exposed directly.
//
// Every array access here is bounds-checked. The previously shipped binary
// validated `json.Size() == 5` and then read `json[5]` for customFields, which
// is an out-of-bounds read of the parsed document: the resulting garbage
// pointer crashed inside the SDK's own snprintf, and GameAnalytics' signal
// handler then walked the stack with backtrace_symbols(), which is what made
// the game appear to freeze before it died. Trailing arguments are optional
// here, so both the legacy N-element payloads and the newer payloads that
// append customFields/mergeFields are accepted.
//
// GameMaker ABI: numbers cross as double, strings as char*. Functions return
// double (declared returnType 2) or char* (returnType 1). Returned strings
// point at a thread-local buffer that stays valid until the next call of the
// same function, which is long enough for GameMaker to copy the value out.
//

#include "GameAnalytics/GameAnalytics.h"

#include <string>
#include <vector>
#include <cstdlib>
#include <cstring>

#if defined(_WIN32)
#define GM_API extern "C" __declspec(dllexport)
#else
#define GM_API extern "C" __attribute__((visibility("default")))
#endif

namespace
{
    // ---------------------------------------------------------------------
    // Small helpers
    // ---------------------------------------------------------------------

    inline std::string str(const char* s)
    {
        return s ? std::string(s) : std::string();
    }

    inline bool toBool(double flag)
    {
        return flag != 0.0;
    }

    // Returned strings must outlive the call without leaking. The previous
    // binary allocated with `new char[size]` and never freed it (and truncated
    // the value, since it passed the unterminated size to snprintf).
    const char* keepString(std::string const& value)
    {
        static thread_local std::string buffers[8];
        static thread_local std::size_t next = 0;

        std::string& slot = buffers[next];
        next = (next + 1) % 8;
        slot = value;
        return slot.c_str();
    }

    // ---------------------------------------------------------------------
    // Minimal JSON reader for a flat array of strings/numbers/bools
    //
    // Deliberately hand-rolled and total: it never throws, never reads past
    // the input, and yields a vector of tokens. Anything malformed produces
    // fewer tokens, which the callers treat as "argument not supplied".
    // ---------------------------------------------------------------------

    struct Token
    {
        enum Kind { Null, Number, String, Bool } kind = Null;
        double      number = 0.0;
        bool        boolean = false;
        std::string text;
    };

    void skipSpace(const char* s, std::size_t len, std::size_t& i)
    {
        while (i < len && (s[i] == ' ' || s[i] == '\t' || s[i] == '\n' || s[i] == '\r')) ++i;
    }

    bool readString(const char* s, std::size_t len, std::size_t& i, std::string& out)
    {
        if (i >= len || s[i] != '"') return false;
        ++i;
        out.clear();
        while (i < len && s[i] != '"')
        {
            if (s[i] == '\\' && i + 1 < len)
            {
                ++i;
                switch (s[i])
                {
                    case 'n':  out.push_back('\n'); break;
                    case 't':  out.push_back('\t'); break;
                    case 'r':  out.push_back('\r'); break;
                    case 'b':  out.push_back('\b'); break;
                    case 'f':  out.push_back('\f'); break;
                    case 'u':
                    {
                        // Keep the escape verbatim; these payloads are built by
                        // the GML wrapper and carry no \u escapes in practice.
                        out.append("\\u");
                        for (int k = 0; k < 4 && i + 1 < len; ++k) out.push_back(s[++i]);
                        break;
                    }
                    default:   out.push_back(s[i]); break;
                }
                ++i;
            }
            else
            {
                out.push_back(s[i++]);
            }
        }
        if (i >= len) return false; // unterminated
        ++i;                        // closing quote
        return true;
    }

    // Parses a JSON array into tokens. Nested arrays/objects are skipped over
    // and recorded as their raw text, so a customFields object can be passed
    // either as a JSON string or as a real object.
    std::vector<Token> parseArgs(const char* json)
    {
        std::vector<Token> args;
        if (!json) return args;

        const std::size_t len = std::strlen(json);
        std::size_t i = 0;

        skipSpace(json, len, i);
        if (i >= len || json[i] != '[') return args;
        ++i;

        while (i < len)
        {
            skipSpace(json, len, i);
            if (i >= len || json[i] == ']') break;

            Token token;
            if (json[i] == '"')
            {
                if (!readString(json, len, i, token.text)) break;
                token.kind = Token::String;
            }
            else if (json[i] == '{' || json[i] == '[')
            {
                // Copy the nested value verbatim, tracking depth and strings.
                const char open = json[i];
                const char close = (open == '{') ? '}' : ']';
                int depth = 0;
                const std::size_t start = i;
                bool inString = false;
                for (; i < len; ++i)
                {
                    const char c = json[i];
                    if (inString)
                    {
                        if (c == '\\' && i + 1 < len) ++i;
                        else if (c == '"') inString = false;
                        continue;
                    }
                    if (c == '"') inString = true;
                    else if (c == open) ++depth;
                    else if (c == close && --depth == 0) { ++i; break; }
                }
                token.kind = Token::String;
                token.text.assign(json + start, i - start);
            }
            else if (std::strncmp(json + i, "true", 4) == 0)
            {
                token.kind = Token::Bool; token.boolean = true;  i += 4;
            }
            else if (std::strncmp(json + i, "false", 5) == 0)
            {
                token.kind = Token::Bool; token.boolean = false; i += 5;
            }
            else if (std::strncmp(json + i, "null", 4) == 0)
            {
                token.kind = Token::Null; i += 4;
            }
            else
            {
                const std::size_t start = i;
                while (i < len && (std::isdigit((unsigned char)json[i]) || json[i] == '-' ||
                                   json[i] == '+' || json[i] == '.' || json[i] == 'e' || json[i] == 'E'))
                {
                    ++i;
                }
                if (i == start) break; // unrecognised — stop rather than spin
                token.kind = Token::Number;
                token.number = std::strtod(std::string(json + start, i - start).c_str(), nullptr);
            }

            args.push_back(token);

            skipSpace(json, len, i);
            if (i < len && json[i] == ',') ++i;
        }

        return args;
    }

    // Bounds-checked accessors — an index past the end yields the default.
    std::string argString(std::vector<Token> const& args, std::size_t index)
    {
        if (index >= args.size()) return std::string();
        Token const& t = args[index];
        if (t.kind == Token::String) return t.text;
        if (t.kind == Token::Number) return std::to_string(t.number);
        if (t.kind == Token::Bool)   return t.boolean ? "true" : "false";
        return std::string();
    }

    double argNumber(std::vector<Token> const& args, std::size_t index)
    {
        if (index >= args.size()) return 0.0;
        Token const& t = args[index];
        if (t.kind == Token::Number) return t.number;
        if (t.kind == Token::Bool)   return t.boolean ? 1.0 : 0.0;
        if (t.kind == Token::String) return std::strtod(t.text.c_str(), nullptr);
        return 0.0;
    }

    bool argBool(std::vector<Token> const& args, std::size_t index)
    {
        if (index >= args.size()) return false;
        Token const& t = args[index];
        if (t.kind == Token::Bool)   return t.boolean;
        if (t.kind == Token::Number) return t.number != 0.0;
        if (t.kind == Token::String) return t.text == "true" || t.text == "1";
        return false;
    }

    gameanalytics::StringVector toStringVector(const char* json)
    {
        gameanalytics::StringVector out;
        std::vector<Token> args = parseArgs(json);
        out.reserve(args.size());
        for (std::size_t i = 0; i < args.size(); ++i)
        {
            if (args[i].kind == Token::String) out.push_back(args[i].text);
        }
        return out;
    }
}

// -------------------------------------------------------------------------
// Configuration
// -------------------------------------------------------------------------

GM_API void configureAvailableCustomDimensions01(const char* customDimensionsJson)
{
    gameanalytics::GameAnalytics::configureAvailableCustomDimensions01(toStringVector(customDimensionsJson));
}

GM_API void configureAvailableCustomDimensions02(const char* customDimensionsJson)
{
    gameanalytics::GameAnalytics::configureAvailableCustomDimensions02(toStringVector(customDimensionsJson));
}

GM_API void configureAvailableCustomDimensions03(const char* customDimensionsJson)
{
    gameanalytics::GameAnalytics::configureAvailableCustomDimensions03(toStringVector(customDimensionsJson));
}

GM_API void configureAvailableResourceCurrencies(const char* resourceCurrenciesJson)
{
    gameanalytics::GameAnalytics::configureAvailableResourceCurrencies(toStringVector(resourceCurrenciesJson));
}

GM_API void configureAvailableResourceItemTypes(const char* resourceItemTypesJson)
{
    gameanalytics::GameAnalytics::configureAvailableResourceItemTypes(toStringVector(resourceItemTypesJson));
}

GM_API void configureBuild(const char* build)
{
    gameanalytics::GameAnalytics::configureBuild(str(build));
}

GM_API void configureWritablePath(const char* writablePath)
{
    gameanalytics::GameAnalytics::configureWritablePath(str(writablePath));
}

GM_API void configureSdkGameEngineVersion(const char* sdkGameEngineVersion)
{
    gameanalytics::GameAnalytics::configureSdkGameEngineVersion(str(sdkGameEngineVersion));
}

GM_API void configureGameEngineVersion(const char* engineVersion)
{
    gameanalytics::GameAnalytics::configureGameEngineVersion(str(engineVersion));
}

GM_API void configureUserId(const char* userId)
{
    gameanalytics::GameAnalytics::configureUserId(str(userId));
}

GM_API void configureExternalUserId(const char* externalUserId)
{
    gameanalytics::GameAnalytics::configureExternalUserId(str(externalUserId));
}

// Implemented in GameAnalyticsHttpGM.cpp — routes the SDK's HTTP through
// GameMaker's own stack so the extension needs no curl/OpenSSL. Must be
// installed before initialize(), which is the SDK's cut-off for a custom client.
void gaGmInstallHttpClient();
void gaGmSetGameSecret(const char* gameSecret);

GM_API void initialize(const char* gameKey, const char* gameSecret)
{
    gaGmInstallHttpClient();
    gaGmSetGameSecret(gameSecret);
    gameanalytics::GameAnalytics::initialize(str(gameKey), str(gameSecret));
}

// -------------------------------------------------------------------------
// Events — JSON entry points (arguments that do not fit GameMaker's limit)
//
// Payloads, with the trailing two elements optional in every case:
//   business:         [currency, amount, itemType, itemId, cartType, fields, mergeFields]
//   resource:         [flowType, currency, amount, itemType, itemId, fields, mergeFields]
//   progression:      [status, progression01, progression02, progression03, fields, mergeFields]
//   progression+score:[status, progression01, progression02, progression03, score, fields, mergeFields]
// -------------------------------------------------------------------------

GM_API void addBusinessEventJson(const char* jsonArgs)
{
    std::vector<Token> args = parseArgs(jsonArgs);
    if (args.size() < 5) return;

    gameanalytics::GameAnalytics::addBusinessEvent(
        argString(args, 0),
        (int)argNumber(args, 1),
        argString(args, 2),
        argString(args, 3),
        argString(args, 4),
        argString(args, 5),
        argBool(args, 6));
}

GM_API void addResourceEventJson(const char* jsonArgs)
{
    std::vector<Token> args = parseArgs(jsonArgs);
    if (args.size() < 5) return;

    gameanalytics::GameAnalytics::addResourceEvent(
        (gameanalytics::EGAResourceFlowType)(int)argNumber(args, 0),
        argString(args, 1),
        (float)argNumber(args, 2),
        argString(args, 3),
        argString(args, 4),
        argString(args, 5),
        argBool(args, 6));
}

GM_API void addProgressionEventJson(const char* jsonArgs)
{
    std::vector<Token> args = parseArgs(jsonArgs);
    if (args.size() < 4) return;

    gameanalytics::GameAnalytics::addProgressionEvent(
        (gameanalytics::EGAProgressionStatus)(int)argNumber(args, 0),
        argString(args, 1),
        argString(args, 2),
        argString(args, 3),
        argString(args, 4),
        argBool(args, 5));
}

GM_API void addProgressionEventWithScoreJson(const char* jsonArgs)
{
    std::vector<Token> args = parseArgs(jsonArgs);
    if (args.size() < 5) return;

    gameanalytics::GameAnalytics::addProgressionEvent(
        (gameanalytics::EGAProgressionStatus)(int)argNumber(args, 0),
        (int)argNumber(args, 4),
        argString(args, 1),
        argString(args, 2),
        argString(args, 3),
        argString(args, 5),
        argBool(args, 6));
}

// -------------------------------------------------------------------------
// Events — direct entry points that fit inside GameMaker's 4-argument limit
// -------------------------------------------------------------------------

GM_API void addProgressionEvent(double status, const char* progression01, const char* progression02, const char* progression03)
{
    gameanalytics::GameAnalytics::addProgressionEvent(
        (gameanalytics::EGAProgressionStatus)(int)status,
        str(progression01),
        str(progression02),
        str(progression03));
}

GM_API void addDesignEvent(const char* eventId, const char* customFields, double mergeFields)
{
    gameanalytics::GameAnalytics::addDesignEvent(str(eventId), str(customFields), toBool(mergeFields));
}

GM_API void addDesignEventWithValue(const char* eventId, double value, const char* customFields, double mergeFields)
{
    gameanalytics::GameAnalytics::addDesignEvent(str(eventId), value, str(customFields), toBool(mergeFields));
}

GM_API void addErrorEvent(double severity, const char* message, const char* customFields, double mergeFields)
{
    gameanalytics::GameAnalytics::addErrorEvent(
        (gameanalytics::EGAErrorSeverity)(int)severity,
        str(message),
        str(customFields),
        toBool(mergeFields));
}

// Legacy direct variants, kept so this library stays a drop-in replacement for
// the previously shipped binary (the GMS1 project declares these arities).
GM_API void addBusinessEvent(const char* currency, double amount, const char* itemType, const char* itemId, const char* cartType)
{
    gameanalytics::GameAnalytics::addBusinessEvent(str(currency), (int)amount, str(itemType), str(itemId), str(cartType));
}

GM_API void addResourceEvent(double flowType, const char* currency, double amount, const char* itemType, const char* itemId)
{
    gameanalytics::GameAnalytics::addResourceEvent(
        (gameanalytics::EGAResourceFlowType)(int)flowType, str(currency), (float)amount, str(itemType), str(itemId));
}

GM_API void addProgressionEventWithScore(double status, const char* progression01, const char* progression02, const char* progression03, double score)
{
    gameanalytics::GameAnalytics::addProgressionEvent(
        (gameanalytics::EGAProgressionStatus)(int)status,
        (int)score,
        str(progression01),
        str(progression02),
        str(progression03));
}

// -------------------------------------------------------------------------
// Settings
// -------------------------------------------------------------------------

GM_API void setEnabledInfoLog(double flag)
{
    gameanalytics::GameAnalytics::setEnabledInfoLog(toBool(flag));
}

GM_API void setEnabledVerboseLog(double flag)
{
    gameanalytics::GameAnalytics::setEnabledVerboseLog(toBool(flag));
}

GM_API void setEnabledManualSessionHandling(double flag)
{
    gameanalytics::GameAnalytics::setEnabledManualSessionHandling(toBool(flag));
}

GM_API void setEnabledErrorReporting(double flag)
{
    gameanalytics::GameAnalytics::setEnabledErrorReporting(toBool(flag));
}

GM_API void setEnabledEventSubmission(double flag)
{
    gameanalytics::GameAnalytics::setEnabledEventSubmission(toBool(flag));
}

GM_API void setCustomDimension01(const char* dimension)
{
    gameanalytics::GameAnalytics::setCustomDimension01(str(dimension));
}

GM_API void setCustomDimension02(const char* dimension)
{
    gameanalytics::GameAnalytics::setCustomDimension02(str(dimension));
}

GM_API void setCustomDimension03(const char* dimension)
{
    gameanalytics::GameAnalytics::setCustomDimension03(str(dimension));
}

GM_API void setGlobalCustomEventFields(const char* customFields)
{
    gameanalytics::GameAnalytics::setGlobalCustomEventFields(str(customFields));
}

// -------------------------------------------------------------------------
// Session / lifecycle
// -------------------------------------------------------------------------

GM_API void gameAnalyticsStartSession()
{
    gameanalytics::GameAnalytics::startSession();
}

GM_API void gameAnalyticsEndSession()
{
    gameanalytics::GameAnalytics::endSession();
}

GM_API void onResume()
{
    gameanalytics::GameAnalytics::onResume();
}

GM_API void onSuspend()
{
    gameanalytics::GameAnalytics::onSuspend();
}

GM_API void onQuit()
{
    gameanalytics::GameAnalytics::onQuit();
}

// -------------------------------------------------------------------------
// Identity / remote configs / A/B testing
// -------------------------------------------------------------------------

GM_API const char* getUserId()
{
    return keepString(gameanalytics::GameAnalytics::getUserId());
}

GM_API const char* getExternalUserId()
{
    return keepString(gameanalytics::GameAnalytics::getExternalUserId());
}

GM_API const char* getRemoteConfigsValueAsString(const char* key)
{
    return keepString(gameanalytics::GameAnalytics::getRemoteConfigsValueAsString(str(key)));
}

GM_API const char* getRemoteConfigsValueAsStringWithDefaultValue(const char* key, const char* defaultValue)
{
    return keepString(gameanalytics::GameAnalytics::getRemoteConfigsValueAsString(str(key), str(defaultValue)));
}

GM_API const char* getRemoteConfigsValueAsJson(const char* key)
{
    return keepString(gameanalytics::GameAnalytics::getRemoteConfigsValueAsJson(str(key)));
}

GM_API double isRemoteConfigsReady()
{
    return gameanalytics::GameAnalytics::isRemoteConfigsReady() ? 1.0 : 0.0;
}

GM_API const char* getRemoteConfigsContentAsString()
{
    return keepString(gameanalytics::GameAnalytics::getRemoteConfigsContentAsString());
}

GM_API const char* getABTestingId()
{
    return keepString(gameanalytics::GameAnalytics::getABTestingId());
}

GM_API const char* getABTestingVariantId()
{
    return keepString(gameanalytics::GameAnalytics::getABTestingVariantId());
}
