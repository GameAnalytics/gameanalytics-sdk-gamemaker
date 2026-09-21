/// GA_SampleActions — the demo actions the sample can fire, plus the single
/// dispatcher both input paths go through.
///
/// Buttons (Step_0) and keyboard shortcuts (KeyPress_*) both call
/// ga_sample_trigger(id), so a shortcut and its button can never drift apart,
/// and both give the same visual feedback.

/// @func ga_sample_trigger(id)
/// @desc Runs the action registered under `id` and flashes its button.
/// @param {String} id one of the ids in ga_sample_ui_build_buttons()
function ga_sample_trigger(id) {
    ga_sample_ui_flash(id);

    if (id == "initialize") {
        ga_sample_action_initialize();
        return;
    }

    if (string_pos("paste_", id) == 1) {
        ga_sample_input_paste(string_delete(id, 1, 6));
        return;
    }

    // Every other action records an event, which needs an initialized SDK.
    if (!global.__ga_info.initialized) {
        ga_sample_log("enter your game keys and initialize first", GA_LOG_WARN);
        return;
    }

    switch (id) {
        case "business": ga_sample_action_business();      break;
        case "level":    ga_sample_action_complete_level(); break;
        case "design":   ga_sample_action_design();        break;
        case "error":    ga_sample_action_error();         break;
        case "ad":       ga_sample_action_ad();            break;
        case "config":   ga_sample_action_read_config();   break;
        case "refresh":  ga_sample_action_refresh();       break;
        case "clear":    ga_sample_log_clear();            break;
        default:
            show_debug_message("[GA Sample] Unknown action id: " + string(id));
            break;
    }
}

/// @func ga_sample_action_initialize()
/// @desc Configures and starts the SDK with the keys typed on the setup screen.
///       The configure_* calls have to happen before ga_initialize, which is
///       why they live here rather than in Create.
function ga_sample_action_initialize() {
    if (global.__ga_info.initialized) {
        ga_sample_log("already initialized - restart the sample to use different keys", GA_LOG_WARN);
        return;
    }

    var _game_key    = ga_sample_input_value("game_key");
    var _game_secret = ga_sample_input_value("game_secret");

    if (!ga_sample_input_is_complete()) {
        ga_sample_log("game key must be 32 characters and the secret 40 - got "
            + string(string_length(_game_key)) + " and " + string(string_length(_game_secret)),
            GA_LOG_WARN);
        return;
    }

    var _build        = "1.0.0";
    var _user_id      = "sample-user-0001";
    var _ext_user_id  = "ext-user-42";
    var _dimension_01 = "free";

    // Identity and configuration, all of which must precede initialize.
    ga_configure_user_id(_user_id);
    ga_configure_external_user_id(_ext_user_id);
    ga_configure_build(_build);
    ga_configure_dimensions_01(["free", "premium"]);
    ga_configure_dimensions_02(["beginner", "intermediate", "expert"]);
    ga_configure_resource_currencies(["Gold", "Gems"]);
    ga_configure_resource_item_types(["IAP", "PowerUp"]);

    ga_set_info_log(true);
    ga_set_verbose_log(false);

    ga_initialize(_game_key, _game_secret);

    ga_add_design_event("Game:Start");
    ga_add_progression_event(GA_PROGRESSIONSTATUS_START, "World01", "Level01");
    ga_set_custom_dimension_01(_dimension_01);

    global.__ga_info.user_id               = _user_id;
    global.__ga_info.ext_user_id           = _ext_user_id;
    global.__ga_info.ext_user_id_supported = ga_sample_ab_supported();
    global.__ga_info.build                 = _build;
    global.__ga_info.dimension_01          = _dimension_01;
    global.__ga_info.ab_supported          = ga_sample_ab_supported();
    global.__ga_info.game_key              = _game_key;
    global.__ga_info.initialized           = true;
    ga_sample_info_refresh();

    ga_sample_input_save();
    ga_sample_input_focus(-1);

    ga_sample_log("initialized on " + ga_sample_platform_name() + " - build " + _build, GA_LOG_INFO);
    ga_sample_log("keys saved locally; events submit through GameMaker's HTTP", GA_LOG_INFO);
}

/// @func ga_sample_action_business()
/// @desc Business event — an in-app purchase of a 99c gold pack.
function ga_sample_action_business() {
    ga_add_business_event("USD", 99, "IAP", "GoldPack100", "Shop");
    ga_sample_log("business  USD 99  IAP:GoldPack100  cart:Shop");
}

/// @func ga_sample_action_complete_level()
/// @desc Progression + resource + design events for finishing a level.
function ga_sample_action_complete_level() {
    ga_add_progression_event(GA_PROGRESSIONSTATUS_COMPLETE, "World01", "Level01");
    ga_add_progression_event_with_score(GA_PROGRESSIONSTATUS_COMPLETE, "World01", "Level01", "", 1250);
    ga_add_resource_event(GA_RESOURCEFLOWTYPE_SOURCE, "Gold", 50, "IAP", "LevelReward");
    ga_add_design_event_with_value("Level:CompletionTime", 42.5);
    ga_sample_log("progression  Complete:World01:Level01  score 1250");
    ga_sample_log("resource  Source Gold +50  IAP:LevelReward");
    ga_sample_log("design  Level:CompletionTime = 42.5");
}

/// @func ga_sample_action_design()
/// @desc Design events, with and without a value.
function ga_sample_action_design() {
    ga_add_design_event("Sample:ButtonPressed");
    ga_add_design_event_with_value("Sample:Score", 100);
    ga_sample_log("design  Sample:ButtonPressed");
    ga_sample_log("design  Sample:Score = 100");
}

/// @func ga_sample_action_error()
/// @desc Error event at warning severity.
function ga_sample_action_error() {
    ga_add_error_event(GA_ERRORSEVERITY_WARNING, "Sample warning from obj_controller");
    ga_sample_log("error  Warning: Sample warning from obj_controller", GA_LOG_WARN);
}

/// @func ga_sample_action_ad()
/// @desc Ad events — rewarded video shown, then reward received.
function ga_sample_action_ad() {
    ga_add_ad_event(GA_ADACTION_SHOW, GA_ADTYPE_REWARDEDVIDEO, "admob", "level_end");
    ga_add_ad_event_with_duration(GA_ADACTION_REWARDRECEIVED, GA_ADTYPE_REWARDEDVIDEO, "admob", "level_end", 30);
    ga_sample_log("ad  Show RewardedVideo  admob:level_end");
    ga_sample_log("ad  RewardReceived RewardedVideo  30s");
}

/// @func ga_sample_action_read_config()
/// @desc Reads a single remote-config key with a fallback, which is how a game
///       would normally consume remote configs.
function ga_sample_action_read_config() {
    var _key   = "test_key";
    var _value = ga_get_remote_configs_value(_key, "default_value");
    ga_sample_log("remote config  " + _key + " = " + string(_value), GA_LOG_CONFIG);

    if (!ga_is_remote_configs_ready()) {
        ga_sample_log("remote configs not ready yet - that was the default value", GA_LOG_WARN);
    }
}

/// @func ga_sample_action_refresh()
/// @desc Re-reads identity / A/B / remote-config state into the info panels.
function ga_sample_action_refresh() {
    ga_sample_info_refresh();
    var _count = array_length(global.__ga_info.remote_rows);
    ga_sample_log("refreshed SDK info - remote configs ready: "
        + (global.__ga_info.remote_ready ? "yes" : "no")
        + ", " + string(_count) + " key" + (_count == 1 ? "" : "s"), GA_LOG_INFO);
}
