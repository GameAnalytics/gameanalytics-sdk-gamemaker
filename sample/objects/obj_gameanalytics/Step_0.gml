/// @description Issue whatever the SDK has queued

// On desktop the native library hands its requests to GameMaker rather than
// linking cURL, so something has to issue them once per step. ga_initialize()
// creates this object so a game does not have to wire that up itself.
//
// Safe if the game also calls ga_http_pump() from its own object: the first
// caller in a step claims the queued request and the second finds nothing.
ga_http_pump();
