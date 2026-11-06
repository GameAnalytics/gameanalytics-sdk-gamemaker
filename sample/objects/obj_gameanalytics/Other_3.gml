/// @description Game End — stop waiting on any in-flight request

// Without this, shutdown blocks until the pending request times out.
ga_http_abort();
