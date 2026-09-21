/// @description Async HTTP

// Hands GameAnalytics' own responses back to the SDK and returns false for
// everything else, so a game's http_request handling goes in the else branch.
if (!ga_http_handle_async()) {
    // not a GameAnalytics request
}
