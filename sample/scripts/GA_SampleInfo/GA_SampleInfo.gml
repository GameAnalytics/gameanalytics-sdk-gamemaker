/// GA_SampleInfo — collects the live SDK state the sample UI displays:
/// identity (user id / external user id), A/B test assignment and the full
/// remote-config payload.
///
/// Identity: the rebuilt desktop binary exposes ga_get_user_id() and
/// ga_get_external_user_id(), so the panel shows what the SDK is actually
/// sending under — including the device id it generates when the game doesn't
/// configure one. Platforms still on the old binaries have no getter, so the
/// values Create_0 configured are shown there instead.

/// @func ga_sample_info_init()
/// @desc Creates the info state struct. Call once from Create, before
///       ga_sample_info_refresh().
function ga_sample_info_init() {
    global.__ga_info = {
        game_key: "",
        user_id: "",
        user_id_from_sdk: false,
        ext_user_id: "",
        ext_user_id_from_sdk: false,
        ext_user_id_supported: false,
        build: "",
        dimension_01: "",
        initialized: false,
        ab_test_id: "",
        ab_variant_id: "",
        ab_supported: true,
        remote_ready: false,
        remote_rows: [],
        remote_raw: "",
        refreshed_at: "never",
    };
}

/// @func ga_sample_info_refresh()
/// @desc Re-reads everything the SDK can report right now. Cheap enough to
///       call on a timer (the sample calls it once a second) and from the
///       "Refresh info" button.
function ga_sample_info_refresh() {
    var _info = global.__ga_info;

    var _sdk_user_id = ga_get_user_id();
    if (_sdk_user_id != "") {
        _info.user_id          = _sdk_user_id;
        _info.user_id_from_sdk = true;
    }

    var _sdk_ext_user_id = ga_get_external_user_id();
    if (_sdk_ext_user_id != "") {
        _info.ext_user_id          = _sdk_ext_user_id;
        _info.ext_user_id_from_sdk = true;
    }

    _info.remote_ready   = (ga_is_remote_configs_ready() == true);
    _info.ab_test_id     = ga_sample_info_string(ga_get_ab_testing_id());
    _info.ab_variant_id  = ga_sample_info_string(ga_get_ab_testing_variant_id());
    _info.remote_raw     = ga_sample_info_string(ga_get_remote_configs_content());
    _info.remote_rows    = ga_sample_info_parse_configs(_info.remote_raw);

    var _dt = date_current_datetime();
    _info.refreshed_at = ga_sample_pad2(date_get_hour(_dt)) + ":"
                       + ga_sample_pad2(date_get_minute(_dt)) + ":"
                       + ga_sample_pad2(date_get_second(_dt));
}

/// @func ga_sample_info_string(value)
/// @desc Extension calls return "" — or, when a binding is missing entirely,
///       0/undefined. Normalises any of those to a plain string.
/// @param {Any} value
/// @return {String}
function ga_sample_info_string(value) {
    if (is_string(value)) return value;
    if (is_undefined(value)) return "";
    return string(value);
}

/// @func ga_sample_info_value_to_string(value)
/// @desc Renders one parsed JSON value as a single display line.
/// @param {Any} value
/// @return {String}
function ga_sample_info_value_to_string(value) {
    if (is_string(value))    return value;
    if (is_undefined(value)) return "undefined";
    if (is_bool(value))      return value ? "true" : "false";
    if (is_real(value))      return string(value);
    if (is_struct(value) || is_array(value)) return json_stringify(value);
    return string(value);
}

/// @func ga_sample_info_parse_configs(raw)
/// @desc Turns the remote-config JSON payload into a sorted array of
///       { key, value } display rows. Never throws — an unparseable payload is
///       returned as a single raw row so the UI still shows something useful.
/// @param {String} raw
/// @return {Array<Struct>}
function ga_sample_info_parse_configs(raw) {
    var _rows = [];
    // Platforms report "no payload yet" inconsistently: "" on some, the literal
    // string "null" on macOS/Windows, and 0 when a binding is missing entirely.
    if (raw == "" || raw == "0" || raw == "null" || raw == "undefined") return _rows;

    var _parsed = undefined;
    try {
        _parsed = json_parse(raw);
    } catch (_ex) {
        array_push(_rows, { key: "(raw)", value: raw });
        return _rows;
    }

    if (is_struct(_parsed)) {
        var _names = struct_get_names(_parsed);
        array_sort(_names, true);
        for (var _i = 0; _i < array_length(_names); _i++) {
            var _key = _names[_i];
            array_push(_rows, {
                key: _key,
                value: ga_sample_info_value_to_string(variable_struct_get(_parsed, _key)),
            });
        }
    } else if (is_array(_parsed)) {
        for (var _i = 0; _i < array_length(_parsed); _i++) {
            array_push(_rows, {
                key: "[" + string(_i) + "]",
                value: ga_sample_info_value_to_string(_parsed[_i]),
            });
        }
    } else if (!is_undefined(_parsed)) {
        array_push(_rows, { key: "(value)", value: ga_sample_info_value_to_string(_parsed) });
    }

    return _rows;
}

/// @func ga_sample_platform_name()
/// @return {String}
function ga_sample_platform_name() {
    if (os_browser != browser_not_a_browser) return "HTML5";
    switch (os_type) {
        case os_windows: return "Windows";
        case os_macosx:  return "macOS";
        case os_linux:   return "Linux";
        case os_android: return "Android";
        case os_ios:     return "iOS";
        default:         return "Unknown (" + string(os_type) + ")";
    }
}

/// @func ga_sample_ab_supported()
/// @desc The A/B getters are only bound on the desktop extension builds —
///       used by the UI to explain an empty value instead of just showing "-".
/// @return {Bool}
function ga_sample_ab_supported() {
    if (os_browser != browser_not_a_browser) return false;
    switch (os_type) {
        case os_windows:
        case os_macosx:
        case os_linux:
            return true;
    }
    return false;
}
