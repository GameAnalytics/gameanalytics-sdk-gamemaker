/// GA_SampleLog — tiny in-game log console used by the sample UI.
///
/// Entries are kept in a global array, newest first, so any script or object
/// event can push a line without having to reach an instance variable.

#macro GA_LOG_MAX 12

#macro GA_LOG_INFO   0
#macro GA_LOG_EVENT  1
#macro GA_LOG_CONFIG 2
#macro GA_LOG_WARN   3

/// @func ga_sample_log_init()
/// @desc Creates the log's backing array. Call once from Create.
function ga_sample_log_init() {
    global.__ga_log = [];
}

/// @func ga_sample_log(msg, [kind])
/// @desc Pushes a timestamped entry to the front of the log, trimming the
///       oldest entries once GA_LOG_MAX is exceeded. Also mirrors the line to
///       the debug output so it shows up in the IDE / console.
/// @param {String} msg
/// @param {Real} [kind] one of the GA_LOG_* constants (defaults to GA_LOG_EVENT)
function ga_sample_log(msg, kind = GA_LOG_EVENT) {
    var _dt = date_current_datetime();
    var _time = ga_sample_pad2(date_get_hour(_dt)) + ":"
              + ga_sample_pad2(date_get_minute(_dt)) + ":"
              + ga_sample_pad2(date_get_second(_dt));

    array_insert(global.__ga_log, 0, { time: _time, msg: string(msg), kind: kind });

    while (array_length(global.__ga_log) > GA_LOG_MAX) {
        array_delete(global.__ga_log, array_length(global.__ga_log) - 1, 1);
    }

    show_debug_message("[GA Sample] " + msg);
}

/// @func ga_sample_log_clear()
function ga_sample_log_clear() {
    global.__ga_log = [];
    ga_sample_log("Log cleared", GA_LOG_INFO);
}

/// @func ga_sample_log_count()
/// @return {Real}
function ga_sample_log_count() {
    return array_length(global.__ga_log);
}

/// @func ga_sample_log_get(index)
/// @param {Real} index 0 == newest entry
/// @return {Struct}
function ga_sample_log_get(index) {
    return global.__ga_log[index];
}

/// @func ga_sample_pad2(value)
/// @desc Zero-pads a number to two digits, for clock formatting.
/// @param {Real} value
/// @return {String}
function ga_sample_pad2(value) {
    return (value < 10 ? "0" : "") + string(value);
}
