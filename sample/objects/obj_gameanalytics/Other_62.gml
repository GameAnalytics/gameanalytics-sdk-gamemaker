/// @description Async HTTP — hand GameAnalytics' responses back to the SDK

// async_load is delivered to every instance with this event, so a game's own
// http_request handling is unaffected: this returns false for anything that is
// not a GameAnalytics request and leaves it alone.
ga_http_handle_async();
