/// @description Set up the sample UI and wait for the game keys

// The SDK is deliberately NOT initialized here. Its configure_* calls and
// ga_initialize have to run in that order, and the keys come from the setup
// screen, so all of it happens in ga_sample_action_initialize() once the keys
// have been entered.

ga_sample_log_init();
ga_sample_info_init();
ga_sample_input_init();
ga_sample_ui_build_buttons();

global.__ga_info.ab_supported = ga_sample_ab_supported();

// Keys from a previous run, if any.
ga_sample_input_load();
ga_sample_ui_build_setup(display_get_gui_width(), display_get_gui_height());
ga_sample_input_focus(ga_sample_input_value("game_key") == "" ? 0 : -1);

// Remote configs and A/B assignment arrive asynchronously, so the panels
// re-read the SDK once a second (the [F] button forces it immediately).
refresh_countdown = game_get_speed(gamespeed_fps);

if (ga_sample_input_is_complete()) {
    ga_sample_log("keys restored from your last run - press Enter to initialize", GA_LOG_INFO);
} else {
    ga_sample_log("paste your game key and secret from gameanalytics.com to begin", GA_LOG_INFO);
}
