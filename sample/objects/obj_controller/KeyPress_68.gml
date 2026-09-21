/// @description Track design events

// Ignore shortcuts while the key fields have focus, so typing a key can't fire
// events, and before the SDK is initialized.
if (!global.__ga_info.initialized || ga_sample_input_focused()) exit;

ga_sample_trigger("design");
