/// @description GameAnalytics GameMaker SDK wrapper
/// @desc Dispatches to the real per-platform extension bindings declared in
///       extensions/GameAnalyticsExt/GameAnalyticsExt.yy. Functions/params with
///       no native implementation on a platform are dropped or no-op with a
///       debug warning rather than left calling a nonexistent symbol.

#region Macros / Enums

#macro GA_ERRORSEVERITY_DEBUG    1
#macro GA_ERRORSEVERITY_INFO     2
#macro GA_ERRORSEVERITY_WARNING  3
#macro GA_ERRORSEVERITY_ERROR    4
#macro GA_ERRORSEVERITY_CRITICAL 5

#macro GA_RESOURCEFLOWTYPE_SOURCE 1
#macro GA_RESOURCEFLOWTYPE_SINK   2

#macro GA_PROGRESSIONSTATUS_START    1
#macro GA_PROGRESSIONSTATUS_COMPLETE 2
#macro GA_PROGRESSIONSTATUS_FAIL     3

#macro GA_ADACTION_CLICKED         1
#macro GA_ADACTION_SHOW            2
#macro GA_ADACTION_FAILEDSHOW       3
#macro GA_ADACTION_REWARDRECEIVED  4
#macro GA_ADACTION_REQUEST         5
#macro GA_ADACTION_LOADED          6

#macro GA_ADTYPE_VIDEO          1
#macro GA_ADTYPE_REWARDEDVIDEO  2
#macro GA_ADTYPE_PLAYABLE       3
#macro GA_ADTYPE_INTERSTITIAL   4
#macro GA_ADTYPE_OFFERWALL      5
#macro GA_ADTYPE_BANNER         6

#macro GA_ADERROR_UNKNOWN          1
#macro GA_ADERROR_OFFLINE          2
#macro GA_ADERROR_NOFILL           3
#macro GA_ADERROR_INTERNALERROR    4
#macro GA_ADERROR_INVALIDREQUEST   5
#macro GA_ADERROR_UNABLETOPRECACHE 6

#endregion

#region Internal Helpers

/// @func __ga_array_to_json(arr)
/// @desc Converts a GML array of strings to a JSON array string, e.g. ["a","b","c"]
/// @param {Array<String>} arr
/// @return {String}
function __ga_array_to_json(arr) {
    var _len = array_length(arr);
    var _result = "[";
    for (var _i = 0; _i < _len; _i++) {
        _result += "\"" + string(arr[_i]) + "\"";
        if (_i < _len - 1) _result += ",";
    }
    _result += "]";
    return _result;
}

/// @func __ga_mixed_array_to_json(arr)
/// @desc Converts a GML array of strings/reals to a JSON array string, preserving
///       type per element (strings quoted, reals bare) — matches the payload shape
///       the native *Json extension functions (addBusinessEventJson, etc.) expect.
/// @param {Array} arr
/// @return {String}
function __ga_mixed_array_to_json(arr) {
    var _len = array_length(arr);
    var _result = "[";
    for (var _i = 0; _i < _len; _i++) {
        var _v = arr[_i];
        if (is_string(_v)) {
            _result += "\"" + _v + "\"";
        } else {
            _result += string(_v);
        }
        if (_i < _len - 1) _result += ",";
    }
    _result += "]";
    return _result;
}

/// @func __ga_unsupported(featureName)
/// @desc Logs once that a feature has no native implementation in this SDK build,
///       for functions that are safe no-ops rather than hard failures.
/// @param {String} featureName
function __ga_unsupported(featureName) {
    show_debug_message("[GameAnalytics] " + featureName + " is not implemented by this platform's SDK build — ignoring call.");
}

#endregion
#region Configuration

/// @func ga_configure_build(build)
/// @param {String} build
function ga_configure_build(build) {
    if (os_browser != browser_not_a_browser) {
        ga_configure_build_html(build);
    } else {
        switch (os_type) {
            case os_android: ga_configure_build_android(build); break;
            case os_ios: ga_configure_build_ios(build); break;
            case os_windows: configureBuild_windows(build); break;
            case os_macosx: configureBuild_mac(build); break;
            case os_linux: configureBuild_linux(build); break;
        }
    }
}

/// @func ga_configure_user_id(userId)
/// @param {String} userId
function ga_configure_user_id(userId) {
    if (os_browser != browser_not_a_browser) {
        ga_configure_user_id_html(userId);
    } else {
        switch (os_type) {
            case os_android: ga_configure_user_id_android(userId); break;
            case os_ios: ga_configure_user_id_ios(userId); break;
            case os_windows: configureUserId_windows(userId); break;
            case os_macosx: configureUserId_mac(userId); break;
            case os_linux: configureUserId_linux(userId); break;
        }
    }
}

/// @func ga_configure_external_user_id(extUserId)
/// @param {String} extUserId
function ga_configure_external_user_id(extUserId) {
    if (os_browser != browser_not_a_browser) {
        ga_configure_external_user_id_html(extUserId);
        return;
    }
    switch (os_type) {
        case os_android: ga_configure_external_user_id_android(extUserId); break;
        case os_ios:     ga_configure_external_user_id_ios(extUserId);     break;
        case os_macosx:  configureExternalUserId_mac(extUserId);     break;
        case os_windows: configureExternalUserId_windows(extUserId); break;
        case os_linux:   configureExternalUserId_linux(extUserId);   break;
        default: __ga_unsupported("ga_configure_external_user_id"); break;
    }
}

/// @func ga_configure_dimensions_01(dimensions)
/// @param {Array<String>} dimensions
function ga_configure_dimensions_01(dimensions) {
    var _json = __ga_array_to_json(dimensions);
    if (os_browser != browser_not_a_browser) {
        ga_configure_dimensions01_html(_json);
    } else {
        switch (os_type) {
            case os_android: ga_configure_dimensions01_android(_json); break;
            case os_ios: ga_configure_dimensions01_ios(_json); break;
            case os_windows: configureAvailableCustomDimensions01_windows(_json); break;
            case os_macosx: configureAvailableCustomDimensions01_mac(_json); break;
            case os_linux: configureAvailableCustomDimensions01_linux(_json); break;
        }
    }
}

/// @func ga_configure_dimensions_02(dimensions)
/// @param {Array<String>} dimensions
function ga_configure_dimensions_02(dimensions) {
    var _json = __ga_array_to_json(dimensions);
    if (os_browser != browser_not_a_browser) {
        ga_configure_dimensions02_html(_json);
    } else {
        switch (os_type) {
            case os_android: ga_configure_dimensions02_android(_json); break;
            case os_ios: ga_configure_dimensions02_ios(_json); break;
            case os_windows: configureAvailableCustomDimensions02_windows(_json); break;
            case os_macosx: configureAvailableCustomDimensions02_mac(_json); break;
            case os_linux: configureAvailableCustomDimensions02_linux(_json); break;
        }
    }
}

/// @func ga_configure_dimensions_03(dimensions)
/// @param {Array<String>} dimensions
function ga_configure_dimensions_03(dimensions) {
    var _json = __ga_array_to_json(dimensions);
    if (os_browser != browser_not_a_browser) {
        ga_configure_dimensions03_html(_json);
    } else {
        switch (os_type) {
            case os_android: ga_configure_dimensions03_android(_json); break;
            case os_ios: ga_configure_dimensions03_ios(_json); break;
            case os_windows: configureAvailableCustomDimensions03_windows(_json); break;
            case os_macosx: configureAvailableCustomDimensions03_mac(_json); break;
            case os_linux: configureAvailableCustomDimensions03_linux(_json); break;
        }
    }
}

/// @func ga_configure_resource_currencies(currencies)
/// @param {Array<String>} currencies
function ga_configure_resource_currencies(currencies) {
    var _json = __ga_array_to_json(currencies);
    if (os_browser != browser_not_a_browser) {
        ga_configure_resource_currencies_html(_json);
    } else {
        switch (os_type) {
            case os_android: ga_configure_resource_currencies_android(_json); break;
            case os_ios: ga_configure_resource_currencies_ios(_json); break;
            case os_windows: configureAvailableResourceCurrencies_windows(_json); break;
            case os_macosx: configureAvailableResourceCurrencies_mac(_json); break;
            case os_linux: configureAvailableResourceCurrencies_linux(_json); break;
        }
    }
}

/// @func ga_configure_resource_item_types(types)
/// @param {Array<String>} types
function ga_configure_resource_item_types(types) {
    var _json = __ga_array_to_json(types);
    if (os_browser != browser_not_a_browser) {
        ga_configure_resource_item_types_html(_json);
    } else {
        switch (os_type) {
            case os_android: ga_configure_resource_item_types_android(_json); break;
            case os_ios: ga_configure_resource_item_types_ios(_json); break;
            case os_windows: configureAvailableResourceItemTypes_windows(_json); break;
            case os_macosx: configureAvailableResourceItemTypes_mac(_json); break;
            case os_linux: configureAvailableResourceItemTypes_linux(_json); break;
        }
    }
}

#endregion

#region Initialization

/// @func ga_initialize(gameKey, gameSecret)
/// @param {String} gameKey
/// @param {String} gameSecret
/// @func __ga_http_autowire()
/// @desc Creates the instance that drives the desktop HTTP bridge, so a game
///       does not have to wire ga_http_pump / ga_http_handle_async /
///       ga_http_abort into an object of its own.
///
///       The Async HTTP event is the reason this needs an object at all:
///       GameMaker delivers async_load only to instances that define the
///       event, so a script or a time source cannot receive it.
///
///       Looked up by name rather than referenced directly, so the SDK scripts
///       still compile if obj_gameanalytics was not imported alongside them.
function __ga_http_autowire() {
    if (!__ga_http_uses_gm_stack()) return true;

    var _obj = asset_get_index("obj_gameanalytics");
    if (_obj == -1) {
        show_debug_message(
            "[GameAnalytics] obj_gameanalytics is missing, so nothing will be "
            + "uploaded on desktop. Import it alongside the GameAnalytics "
            + "scripts, or call ga_http_pump/ga_http_handle_async/ga_http_abort "
            + "from an object of your own.");
        return false;
    }

    if (instance_exists(_obj)) return true;

    // instance_create_depth needs a room to be running, which means
    // ga_initialize must be called from a Create or Room Start event.
    if (!room_exists(room)) {
        show_debug_message(
            "[GameAnalytics] ga_initialize was called before a room was "
            + "running, so the HTTP bridge could not start. Call it from a "
            + "Create or Room Start event.");
        return false;
    }

    instance_create_depth(0, 0, 0, _obj);
    return true;
}

function ga_initialize(gameKey, gameSecret) {
    var _sdkVersion = "gamemaker 4.1.0";
    if (os_browser != browser_not_a_browser) {
        ga_configure_sdk_version_html(_sdkVersion);
        ga_initialize_html(gameKey, gameSecret);
    } else {
        switch (os_type) {
            case os_android:
                ga_configure_sdk_version_android(_sdkVersion);
                ga_initialize_android(gameKey, gameSecret);
                break;
            case os_ios:
                ga_configure_sdk_version_ios(_sdkVersion);
                ga_initialize_ios(gameKey, gameSecret);
                break;
            case os_windows:
                configureSdkGameEngineVersion_windows(_sdkVersion);
                native_ga_initialize_windows(gameKey, gameSecret);
                break;
            case os_macosx:
                configureSdkGameEngineVersion_mac(_sdkVersion);
                native_ga_initialize_mac(gameKey, gameSecret);
                break;
            case os_linux:
                configureSdkGameEngineVersion_linux(_sdkVersion);
                native_ga_initialize_linux(gameKey, gameSecret);
                break;
        }

        // Desktop uploads go through GameMaker's HTTP, which needs an instance
        // to receive the Async HTTP event. Started here so the game does not
        // have to.
        __ga_http_autowire();
    }
}

#endregion

#region Settings

/// @func ga_set_info_log(enabled)
/// @param {Bool} enabled
function ga_set_info_log(enabled) {
    if (os_browser != browser_not_a_browser) {
        ga_set_info_log_html(enabled);
    } else {
        switch (os_type) {
            case os_android: ga_set_info_log_android(enabled); break;
            case os_ios: ga_set_info_log_ios(enabled); break;
            case os_windows: setEnabledInfoLog_windows(enabled); break;
            case os_macosx: setEnabledInfoLog_mac(enabled); break;
            case os_linux: setEnabledInfoLog_linux(enabled); break;
        }
    }
}

/// @func ga_set_verbose_log(enabled)
/// @param {Bool} enabled
function ga_set_verbose_log(enabled) {
    if (os_browser != browser_not_a_browser) {
        ga_set_verbose_log_html(enabled);
    } else {
        switch (os_type) {
            case os_android: ga_set_verbose_log_android(enabled); break;
            case os_ios: ga_set_verbose_log_ios(enabled); break;
            case os_windows: setEnabledVerboseLog_windows(enabled); break;
            case os_macosx: setEnabledVerboseLog_mac(enabled); break;
            case os_linux: setEnabledVerboseLog_linux(enabled); break;
        }
    }
}

/// @func ga_set_event_submission(enabled, cacheLocally)
/// @desc cacheLocally has no native binding on any platform in this SDK build
///       and is accepted for API compatibility but ignored.
/// @param {Bool} enabled
/// @param {Bool} cacheLocally
function ga_set_event_submission(enabled, cacheLocally = false) {
    if (os_browser != browser_not_a_browser) {
        ga_set_event_submission_html(enabled, cacheLocally);
    } else {
        switch (os_type) {
            case os_android: ga_set_event_submission_android(enabled, cacheLocally); break;
            case os_ios:     ga_set_event_submission_ios(enabled, cacheLocally);     break;
            case os_windows: setEnabledEventSubmission_windows(enabled); break;
            case os_macosx:  setEnabledEventSubmission_mac(enabled);     break;
            case os_linux:   setEnabledEventSubmission_linux(enabled);   break;
        }
    }
}

/// @func ga_set_error_reporting(flag)
/// @desc Bound on windows/mac/linux (native setEnabledErrorReporting). Not
///       exposed by the android/ios/html extension bindings in this build — no-op there.
/// @param {Bool} flag
function ga_set_error_reporting(flag) {
    switch (os_type) {
        case os_windows: setEnabledErrorReporting_windows(flag); break;
        case os_macosx:  setEnabledErrorReporting_mac(flag);     break;
        case os_linux:   setEnabledErrorReporting_linux(flag);   break;
        default:         __ga_unsupported("ga_set_error_reporting"); break;
    }
}

/// @func ga_set_manual_session_handling(enabled)
/// @param {Bool} enabled
function ga_set_manual_session_handling(enabled) {
    if (os_browser != browser_not_a_browser) {
        ga_set_manual_session_html(enabled);
    } else {
        switch (os_type) {
            case os_android: ga_set_manual_session_android(enabled); break;
            case os_ios: ga_set_manual_session_ios(enabled); break;
            case os_windows: setEnabledManualSessionHandling_windows(enabled); break;
            case os_macosx: setEnabledManualSessionHandling_mac(enabled); break;
            case os_linux: setEnabledManualSessionHandling_linux(enabled); break;
        }
    }
}

#endregion

#region Session

/// @func ga_start_session()
function ga_start_session() {
    if (os_browser != browser_not_a_browser) {
        ga_start_session_html();
    } else {
        switch (os_type) {
            case os_android: ga_start_session_android(); break;
            case os_ios: ga_start_session_ios(); break;
            case os_windows: startSession_windows(); break;
            case os_macosx: startSession_mac(); break;
            case os_linux: startSession_linux(); break;
        }
    }
}

/// @func ga_end_session()
function ga_end_session() {
    if (os_browser != browser_not_a_browser) {
        ga_end_session_html();
    } else {
        switch (os_type) {
            case os_android: ga_end_session_android(); break;
            case os_ios: ga_end_session_ios(); break;
            case os_windows: endSession_windows(); break;
            case os_macosx: endSession_mac(); break;
            case os_linux: endSession_linux(); break;
        }
    }
}

/// @func ga_on_quit()
/// @desc Not bound for android/ios in this extension — no-op with a debug warning there.
function ga_on_quit() {
    if (os_browser != browser_not_a_browser) {
        ga_on_quit_html();
    } else {
        switch (os_type) {
        case os_android: ga_on_quit_android(); break;
        case os_ios: ga_on_quit_ios(); break;
        case os_windows: onStop_windows(); break;
        case os_macosx: onStop_mac(); break;
        case os_linux: onStop_linux(); break;
        }
    }
}

#endregion

#region Custom Dimensions

/// @func ga_set_custom_dimension_01(value)
/// @param {String} value
function ga_set_custom_dimension_01(value) {
    if (os_browser != browser_not_a_browser) {
        ga_set_dimension01_html(value);
    } else {
        switch (os_type) {
            case os_android: ga_set_dimension01_android(value); break;
            case os_ios: ga_set_dimension01_ios(value); break;
            case os_windows: setCustomDimension01_windows(value); break;
            case os_macosx: setCustomDimension01_mac(value); break;
            case os_linux: setCustomDimension01_linux(value); break;
        }
    }
}

/// @func ga_set_custom_dimension_02(value)
/// @param {String} value
function ga_set_custom_dimension_02(value) {
    if (os_browser != browser_not_a_browser) {
        ga_set_dimension02_html(value);
    } else {
        switch (os_type) {
            case os_android: ga_set_dimension02_android(value); break;
            case os_ios: ga_set_dimension02_ios(value); break;
            case os_windows: setCustomDimension02_windows(value); break;
            case os_macosx: setCustomDimension02_mac(value); break;
            case os_linux: setCustomDimension02_linux(value); break;
        }
    }
}

/// @func ga_set_custom_dimension_03(value)
/// @param {String} value
function ga_set_custom_dimension_03(value) {
    if (os_browser != browser_not_a_browser) {
        ga_set_dimension03_html(value);
    } else {
        switch (os_type) {
            case os_android: ga_set_dimension03_android(value); break;
            case os_ios: ga_set_dimension03_ios(value); break;
            case os_windows: setCustomDimension03_windows(value); break;
            case os_macosx: setCustomDimension03_mac(value); break;
            case os_linux: setCustomDimension03_linux(value); break;
        }
    }
}

#endregion

#region Events

/// @func ga_add_business_event(currency, amount, itemType, itemId, cartType, fields, mergeFields)
/// @desc fields/mergeFields are accepted for API compatibility but not forwarded —
///       no platform's addBusinessEventJson binding in this SDK build accepts them.
/// @param {String} currency
/// @param {Real}   amount
/// @param {String} itemType
/// @param {String} itemId
/// @param {String} cartType
/// @param {String} fields
/// @param {Bool}   mergeFields
function ga_add_business_event(currency, amount, itemType, itemId, cartType, fields = "{}", mergeFields = false) {
    if (os_browser != browser_not_a_browser) {
        ga_add_business_event_html(currency, amount, itemType, itemId, cartType, fields, mergeFields);
    } else {
        var _json = __ga_mixed_array_to_json([currency, amount, itemType, itemId, cartType]);
        switch (os_type) {
            case os_android: ga_add_business_event_android(currency, amount, itemType, itemId, cartType, fields, mergeFields); break;
            case os_ios:     ga_add_business_event_ios(currency, amount, itemType, itemId, cartType, fields, mergeFields);     break;
            case os_windows: addBusinessEventJson_windows(_json); break;
            case os_macosx:  addBusinessEventJson_mac(_json);     break;
            case os_linux:   addBusinessEventJson_linux(_json);   break;
        }
    }
}

/// @func ga_add_resource_event(flowType, currency, amount, itemType, itemId, fields, mergeFields)
/// @desc fields/mergeFields are accepted for API compatibility but not forwarded —
///       no platform's addResourceEventJson binding in this SDK build accepts them.
/// @param {Real}   flowType
/// @param {String} currency
/// @param {Real}   amount
/// @param {String} itemType
/// @param {String} itemId
/// @param {String} fields
/// @param {Bool}   mergeFields
function ga_add_resource_event(flowType, currency, amount, itemType, itemId, fields = "{}", mergeFields = false) {
    if (os_browser != browser_not_a_browser) {
        ga_add_resource_event_html(flowType, currency, amount, itemType, itemId, fields, mergeFields);
    } else {
        var _json = __ga_mixed_array_to_json([flowType, currency, amount, itemType, itemId]);
        switch (os_type) {
            case os_android: ga_add_resource_event_android(flowType, currency, amount, itemType, itemId, fields, mergeFields); break;
            case os_ios:     ga_add_resource_event_ios(flowType, currency, amount, itemType, itemId, fields, mergeFields);     break;
            case os_windows: addResourceEventJson_windows(_json); break;
            case os_macosx:  addResourceEventJson_mac(_json);     break;
            case os_linux:   addResourceEventJson_linux(_json);   break;
        }
    }
}

/// @func ga_add_progression_event(status, prog1, prog2, prog3, fields, mergeFields)
/// @desc fields/mergeFields are accepted for API compatibility but not forwarded —
///       no platform's addProgressionEvent binding in this SDK build accepts them.
/// @param {Real}   status
/// @param {String} prog1
/// @param {String} prog2
/// @param {String} prog3
/// @param {String} fields
/// @param {Bool}   mergeFields
function ga_add_progression_event(status, prog1, prog2 = "", prog3 = "", fields = "{}", mergeFields = false) {
    if (os_browser != browser_not_a_browser) {
        ga_add_progression_event_html(status, prog1, prog2, prog3, fields, mergeFields);
    } else {
        switch (os_type) {
            case os_android: ga_add_progression_event_android(status, prog1, prog2, prog3, fields, mergeFields); break;
            case os_ios:     ga_add_progression_event_ios(status, prog1, prog2, prog3, fields, mergeFields);     break;
            case os_windows: addProgressionEvent_windows(status, prog1, prog2, prog3); break;
            case os_macosx:  addProgressionEvent_mac(status, prog1, prog2, prog3);     break;
            case os_linux:   addProgressionEvent_linux(status, prog1, prog2, prog3);   break;
        }
    }
}

/// @func ga_add_progression_event_with_score(status, prog1, prog2, prog3, score, fields, mergeFields)
/// @desc fields/mergeFields are accepted for API compatibility but not forwarded —
///       no platform's addProgressionEventWithScoreJson binding in this SDK build accepts them.
/// @param {Real}   status
/// @param {String} prog1
/// @param {String} prog2
/// @param {String} prog3
/// @param {Real}   score
/// @param {String} fields
/// @param {Bool}   mergeFields
function ga_add_progression_event_with_score(status, prog1, prog2 = "", prog3 = "", score = 0, fields = "{}", mergeFields = false) {
    if (os_browser != browser_not_a_browser) {
        ga_add_progression_event_score_html(status, prog1, prog2, prog3, score, fields, mergeFields);
    } else {
        var _json = __ga_mixed_array_to_json([status, prog1, prog2, prog3, score]);
        switch (os_type) {
            case os_android: ga_add_progression_event_score_android(status, prog1, prog2, prog3, score, fields, mergeFields); break;
            case os_ios:     ga_add_progression_event_score_ios(status, prog1, prog2, prog3, score, fields, mergeFields);     break;
            case os_windows: addProgressionEventWithScoreJson_windows(_json); break;
            case os_macosx:  addProgressionEventWithScoreJson_mac(_json);     break;
            case os_linux:   addProgressionEventWithScoreJson_linux(_json);   break;
        }
    }
}

/// @func ga_add_design_event(eventId, fields, mergeFields)
/// @desc fields/mergeFields are only forwarded on windows/mac/linux, where the
///       native addDesignEvent binding accepts them; android/ios/html ignore them.
/// @param {String} eventId
/// @param {String} fields
/// @param {Bool}   mergeFields
function ga_add_design_event(eventId, fields = "{}", mergeFields = false) {
    if (os_browser != browser_not_a_browser) {
        ga_add_design_event_html(eventId, fields, mergeFields);
    } else {
        switch (os_type) {
            case os_android: ga_add_design_event_android(eventId, fields, mergeFields); break;
            case os_ios: ga_add_design_event_ios(eventId, fields, mergeFields); break;
            case os_windows: addDesignEvent_windows(eventId, fields, mergeFields); break;
            case os_macosx: addDesignEvent_mac(eventId, fields, mergeFields); break;
            case os_linux: addDesignEvent_linux(eventId, fields, mergeFields); break;
        }
    }
}

/// @func ga_add_design_event_with_value(eventId, value, fields, mergeFields)
/// @desc fields/mergeFields are only forwarded on windows/mac/linux, where the
///       native addDesignEventWithValue binding accepts them; android/ios/html ignore them.
/// @param {String} eventId
/// @param {Real}   value
/// @param {String} fields
/// @param {Bool}   mergeFields
function ga_add_design_event_with_value(eventId, value, fields = "{}", mergeFields = false) {
    if (os_browser != browser_not_a_browser) {
        ga_add_design_event_value_html(eventId, value, fields, mergeFields);
    } else {
        switch (os_type) {
            case os_android: ga_add_design_event_value_android(eventId, value, fields, mergeFields); break;
            case os_ios: ga_add_design_event_value_ios(eventId, value, fields, mergeFields); break;
            case os_windows: addDesignEventWithValue_windows(eventId, value, fields, mergeFields); break;
            case os_macosx: addDesignEventWithValue_mac(eventId, value, fields, mergeFields); break;
            case os_linux: addDesignEventWithValue_linux(eventId, value, fields, mergeFields); break;
        }
    }
}

/// @func ga_add_error_event(severity, message, fields, mergeFields)
/// @desc fields/mergeFields are only forwarded on windows/mac/linux, where the
///       native addErrorEvent binding accepts them; android/ios/html ignore them.
/// @param {Real}   severity
/// @param {String} message
/// @param {String} fields
/// @param {Bool}   mergeFields
function ga_add_error_event(severity, message, fields = "{}", mergeFields = false) {
    if (os_browser != browser_not_a_browser) {
        ga_add_error_event_html(severity, message, fields, mergeFields);
    } else {
        switch (os_type) {
            case os_android: ga_add_error_event_android(severity, message, fields, mergeFields); break;
            case os_ios: ga_add_error_event_ios(severity, message, fields, mergeFields); break;
            case os_windows: addErrorEvent_windows(severity, message, fields, mergeFields); break;
            case os_macosx: addErrorEvent_mac(severity, message, fields, mergeFields); break;
            case os_linux: addErrorEvent_linux(severity, message, fields, mergeFields); break;
        }
    }
}

/// @func ga_add_ad_event(adAction, adType, adSdkName, adPlacement, fields, mergeFields)
/// @desc Implemented by the android/ios/html bindings. The desktop C++ SDK has
///       no ad event API, so this is a logged no-op there.
function ga_add_ad_event(adAction, adType, adSdkName, adPlacement, fields = "{}", mergeFields = false) {
    if (os_browser != browser_not_a_browser) {
        ga_add_ad_event_html(adAction, adType, adSdkName, adPlacement, fields, mergeFields);
        return;
    }
    switch (os_type) {
        case os_android: ga_add_ad_event_android(adAction, adType, adSdkName, adPlacement, fields, mergeFields); break;
        case os_ios:     ga_add_ad_event_ios(adAction, adType, adSdkName, adPlacement, fields, mergeFields);     break;
        default: __ga_unsupported("ga_add_ad_event"); break;
    }
}

/// @func ga_add_ad_event_with_duration(adAction, adType, adSdkName, adPlacement, duration, fields, mergeFields)
/// @desc No platform's extension binding in this SDK build implements ad event
///       tracking — safe no-op.
function ga_add_ad_event_with_duration(adAction, adType, adSdkName, adPlacement, duration, fields = "{}", mergeFields = false) {
    if (os_browser != browser_not_a_browser) {
        ga_add_ad_event_duration_html(adAction, adType, adSdkName, adPlacement, duration, fields, mergeFields);
        return;
    }
    switch (os_type) {
        case os_android: ga_add_ad_event_duration_android(adAction, adType, adSdkName, adPlacement, duration, fields, mergeFields); break;
        case os_ios:     ga_add_ad_event_duration_ios(adAction, adType, adSdkName, adPlacement, duration, fields, mergeFields);     break;
        default: __ga_unsupported("ga_add_ad_event_with_duration"); break;
    }
}

/// @func ga_add_ad_event_with_reason(adAction, adType, adSdkName, adPlacement, noAdReason, fields, mergeFields)
/// @desc No platform's extension binding in this SDK build implements ad event
///       tracking — safe no-op.
function ga_add_ad_event_with_reason(adAction, adType, adSdkName, adPlacement, noAdReason, fields = "{}", mergeFields = false) {
    if (os_browser != browser_not_a_browser) {
        ga_add_ad_event_reason_html(adAction, adType, adSdkName, adPlacement, noAdReason, fields, mergeFields);
        return;
    }
    switch (os_type) {
        case os_android: ga_add_ad_event_reason_android(adAction, adType, adSdkName, adPlacement, noAdReason, fields, mergeFields); break;
        case os_ios:     ga_add_ad_event_reason_ios(adAction, adType, adSdkName, adPlacement, noAdReason, fields, mergeFields);     break;
        default: __ga_unsupported("ga_add_ad_event_with_reason"); break;
    }
}

#endregion

#region HTTP bridge (desktop)

/// @func __ga_http_uses_gm_stack()
/// @desc True on the targets whose extension routes the SDK's HTTP through
///       GameMaker instead of linking cURL/OpenSSL into the native library.
/// @return {Bool}
function __ga_http_uses_gm_stack() {
    if (os_browser != browser_not_a_browser) return false;
    switch (os_type) {
        case os_macosx:
        case os_windows:
        case os_linux:
            return true;
    }
    return false;
}

/// @func ga_http_pump()
/// @desc Issues whatever request the SDK has queued, using GameMaker's own HTTP
///       stack.
///
///       You do not need to call this: ga_initialize() starts
///       obj_gameanalytics, which does it once per step. It stays public so a
///       game can drive the bridge itself — calling it as well is harmless,
///       because whichever caller comes first in a step claims the queued
///       request and the other finds nothing.
///
///       Harmless no-op on platforms whose native SDK does its own
///       networking.
function ga_http_pump() {
    if (!__ga_http_uses_gm_stack()) return -1;

    var _claimed = false;
    switch (os_type) {
        case os_windows: _claimed = gaHttpPump_windows(); break;
        case os_macosx:  _claimed = gaHttpPump_mac();     break;
        case os_linux:   _claimed = gaHttpPump_linux();   break;
    }
    if (!_claimed) return -1;

    var _url  = "";
    var _auth = "";
    var _body = "";
    switch (os_type) {
        case os_windows:
            _url  = gaHttpPendingUrl_windows();
            _auth = gaHttpPendingAuth_windows();
            _body = gaHttpPendingBody_windows();
            break;
        case os_macosx:
            _url  = gaHttpPendingUrl_mac();
            _auth = gaHttpPendingAuth_mac();
            _body = gaHttpPendingBody_mac();
            break;
        case os_linux:
            _url  = gaHttpPendingUrl_linux();
            _auth = gaHttpPendingAuth_linux();
            _body = gaHttpPendingBody_linux();
            break;
    }

    var _headers = ds_map_create();
    _headers[? "Content-Type"] = "application/json";
    if (_auth != "") _headers[? "Authorization"] = _auth;

    var _id = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);

    global.__ga_http_request_id = _id;
    return _id;
}

/// @func ga_http_handle_async()
/// @desc You do not need to call this: obj_gameanalytics handles it. Still
///       public so a game can host the Async HTTP event itself.
/// @desc Call from the Async HTTP event. Passes the response for the SDK's
///       in-flight request back to the SDK and leaves the game's own HTTP
///       traffic alone.
/// @return {Bool} true when the event belonged to the SDK
function ga_http_handle_async() {
    if (!__ga_http_uses_gm_stack()) return false;
    if (!__ga_http_has_pending()) return false;

    // Match on the id http_request handed back, so the game's own requests are
    // left alone.
    if (!variable_global_exists("__ga_http_request_id")) return false;
    if (async_load[? "id"] != global.__ga_http_request_id) return false;

    var _status = async_load[? "status"];
    if (is_real(_status) && _status > 0) return true;   // still in progress

    if (is_real(_status) && _status < 0) {
        __ga_http_deliver(-1, "");                      // transport failure
        return true;
    }

    var _code = async_load[? "http_status"];
    var _body = async_load[? "result"];
    __ga_http_deliver(is_real(_code) ? _code : -1, is_string(_body) ? _body : "");
    return true;
}

/// @func __ga_http_has_pending()
/// @return {Bool}
function __ga_http_has_pending() {
    switch (os_type) {
        case os_windows: return gaHttpHasPending_windows();
        case os_macosx:  return gaHttpHasPending_mac();
        case os_linux:   return gaHttpHasPending_linux();
    }
    return false;
}

/// @func __ga_http_deliver(status, body)
/// @param {Real} status
/// @param {String} body
function __ga_http_deliver(status, body) {
    switch (os_type) {
        case os_windows: gaHttpDeliver_windows(status, body); break;
        case os_macosx:  gaHttpDeliver_mac(status, body);     break;
        case os_linux:   gaHttpDeliver_linux(status, body);   break;
    }
}

/// @func ga_http_abort()
/// @desc You do not need to call this: obj_gameanalytics calls it at Game End.
///       Still public so a game can shut the bridge down itself.
/// @desc Fails the in-flight request instead of letting the SDK's worker thread
///       wait out its timeout. Call on game end, before ga_on_quit().
function ga_http_abort() {
    if (!__ga_http_uses_gm_stack()) return;
    switch (os_type) {
        case os_windows: gaHttpAbort_windows(); break;
        case os_macosx:  gaHttpAbort_mac();     break;
        case os_linux:   gaHttpAbort_linux();   break;
    }
}

#endregion

#region Identity getters

/// @func ga_get_user_id()
/// @desc The id the SDK is actually sending events under - the one configured
///       via ga_configure_user_id, or the device id it generated itself.
///       Bound on Windows, macOS and Linux; "" elsewhere.
/// @return {String}
function ga_get_user_id() {
    if (os_browser != browser_not_a_browser) return "";
    switch (os_type) {
        case os_macosx:  return getUserId_mac();
        case os_windows: return getUserId_windows();
        case os_linux:   return getUserId_linux();
    }
    return "";
}

/// @func ga_get_external_user_id()
/// @return {String}
function ga_get_external_user_id() {
    if (os_browser != browser_not_a_browser) return "";
    switch (os_type) {
        case os_macosx:  return getExternalUserId_mac();
        case os_windows: return getExternalUserId_windows();
        case os_linux:   return getExternalUserId_linux();
    }
    return "";
}

#endregion

#region Remote Configs

/// @func ga_get_remote_configs_value(key, defaultValue)
/// @param {String} key
/// @param {String} defaultValue
/// @return {String}
function ga_get_remote_configs_value(key, defaultValue = "") {
    if (os_browser != browser_not_a_browser) {
        return ga_remote_configs_value_html(key, defaultValue);
    } else {
        switch (os_type) {
            case os_android: return ga_remote_configs_value_android(key, defaultValue);
            case os_ios: return ga_remote_configs_value_ios(key, defaultValue);
            case os_windows: return getRemoteConfigsValueAsStringWithDefaultValue_windows(key, defaultValue);
            case os_macosx: return getRemoteConfigsValueAsStringWithDefaultValue_mac(key, defaultValue);
            case os_linux: return getRemoteConfigsValueAsStringWithDefaultValue_linux(key, defaultValue);
        }
    }
    return "";
}

/// @func ga_get_remote_configs_value_as_json(key)
/// @desc No platform exposes a per-key JSON getter in this SDK build — falls
///       back to the plain string getter for the same key.
/// @param {String} key
/// @return {String}
function ga_get_remote_configs_value_as_json(key) {
    if (os_browser != browser_not_a_browser) {
        return ga_remote_configs_json_html(key);
    } else {
        switch (os_type) {
            case os_android: return ga_remote_configs_json_android(key);
            case os_ios: return ga_remote_configs_json_ios(key);
            case os_windows: return getRemoteConfigsValueAsString_windows(key);
            case os_macosx: return getRemoteConfigsValueAsString_mac(key);
            case os_linux: return getRemoteConfigsValueAsString_linux(key);
        }
    }
    return "";
}

/// @func ga_get_remote_configs_content()
/// @return {String}
function ga_get_remote_configs_content() {
    if (os_browser != browser_not_a_browser) {
        return ga_remote_configs_content_html();
    } else {
        switch (os_type) {
            case os_android: return ga_remote_configs_content_android();
            case os_ios: return ga_remote_configs_content_ios();
            case os_windows: return getRemoteConfigsContentAsString_windows();
            case os_macosx: return getRemoteConfigsContentAsString_mac();
            case os_linux: return getRemoteConfigsContentAsString_linux();
        }
    }
    return "";
}

/// @func ga_is_remote_configs_ready()
/// @return {Bool}
function ga_is_remote_configs_ready() {
    if (os_browser != browser_not_a_browser) {
        return ga_remote_configs_ready_html();
    } else {
        switch (os_type) {
            case os_android: return ga_remote_configs_ready_android();
            case os_ios: return ga_remote_configs_ready_ios();
            case os_windows: return isRemoteConfigsReady_windows();
            case os_macosx: return isRemoteConfigsReady_mac();
            case os_linux: return isRemoteConfigsReady_linux();
        }
    }
    return false;
}

#endregion

#region A/B Testing

/// @func ga_get_ab_testing_id()
/// @desc Bound on windows/mac/linux (native getABTestingId). Not exposed by
///       the android/ios/html extension bindings in this build — returns "" there.
/// @return {String}
function ga_get_ab_testing_id() {
    if (os_browser != browser_not_a_browser) {
        return ga_ab_testing_id_html();
    } else {
        switch (os_type) {
            case os_android: return ga_ab_testing_id_android();
            case os_ios: return ga_ab_testing_id_ios();
            case os_windows: return getABTestingId_windows();
            case os_macosx: return getABTestingId_mac();
            case os_linux: return getABTestingId_linux();
        }
    }
    return "";
}

/// @func ga_get_ab_testing_variant_id()
/// @desc Bound on windows/mac/linux (native getABTestingVariantId). Not exposed
///       by the android/ios/html extension bindings in this build — returns "" there.
/// @return {String}
function ga_get_ab_testing_variant_id() {
    if (os_browser != browser_not_a_browser) {
        return ga_ab_testing_variant_id_html();
    } else {
        switch (os_type) {
            case os_android: return ga_ab_testing_variant_id_android();
            case os_ios: return ga_ab_testing_variant_id_ios();
            case os_windows: return getABTestingVariantId_windows();
            case os_macosx: return getABTestingVariantId_mac();
            case os_linux: return getABTestingVariantId_linux();
        }
    }
    return "";
}

#endregion
