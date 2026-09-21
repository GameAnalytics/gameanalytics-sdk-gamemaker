/// GA_SampleInput — minimal text fields for the sample's key entry screen.
///
/// GameMaker has no built-in text widget, so this is the usual keyboard_string
/// approach: click a field to focus it, typed characters are drained from
/// keyboard_string each step, and Backspace / Tab / Enter / paste are handled
/// explicitly. Input is filtered to the characters GameAnalytics accepts in a
/// key (A-z 0-9), which also means a stray newline from a paste can't sneak in.

/// @func ga_sample_input_init()
/// @desc Creates the two key fields. Call once from Create.
function ga_sample_input_init() {
    global.__ga_fields = [
        {
            id: "game_key",
            label: "Game key",
            hint: "32 characters",
            value: "",
            max_len: 32,
        },
        {
            id: "game_secret",
            label: "Game secret",
            hint: "40 characters",
            value: "",
            max_len: 40,
        },
    ];
    global.__ga_focus = 0;   // index of the focused field, -1 for none
}

/// @func ga_sample_input_field(index)
/// @param {Real} index
/// @return {Struct}
function ga_sample_input_field(index) {
    return global.__ga_fields[index];
}

/// @func ga_sample_input_count()
/// @return {Real}
function ga_sample_input_count() {
    return array_length(global.__ga_fields);
}

/// @func ga_sample_input_value(id)
/// @param {String} id
/// @return {String}
function ga_sample_input_value(id) {
    for (var _i = 0; _i < array_length(global.__ga_fields); _i++) {
        if (global.__ga_fields[_i].id == id) return global.__ga_fields[_i].value;
    }
    return "";
}

/// @func ga_sample_input_set(id, value)
/// @param {String} id
/// @param {String} value
function ga_sample_input_set(id, value) {
    for (var _i = 0; _i < array_length(global.__ga_fields); _i++) {
        if (global.__ga_fields[_i].id == id) {
            global.__ga_fields[_i].value = string_copy(string(value), 1, global.__ga_fields[_i].max_len);
            return;
        }
    }
}

/// @func ga_sample_input_focused()
/// @desc True while a field has focus, which is when the action shortcuts must
///       stay out of the way so typing a key doesn't fire events.
/// @return {Bool}
function ga_sample_input_focused() {
    if (!variable_global_exists("__ga_focus")) return false;
    return (global.__ga_focus >= 0);
}

/// @func ga_sample_input_focus(index)
/// @param {Real} index -1 to clear focus
function ga_sample_input_focus(index) {
    global.__ga_focus = index;
    keyboard_string = "";
}

/// @func ga_sample_input_is_complete()
/// @desc True when both fields hold a plausibly-shaped key pair. The SDK checks
///       the same lengths and rejects the pair otherwise.
/// @return {Bool}
function ga_sample_input_is_complete() {
    return (string_length(ga_sample_input_value("game_key")) == 32)
        && (string_length(ga_sample_input_value("game_secret")) == 40);
}

/// @func ga_sample_input_filter(str)
/// @desc Keeps only the characters allowed in a key.
/// @param {String} str
/// @return {String}
function ga_sample_input_filter(str) {
    var _out = "";
    var _len = string_length(str);
    for (var _i = 1; _i <= _len; _i++) {
        var _ch = string_char_at(str, _i);
        var _ord = ord(_ch);
        var _is_digit = (_ord >= ord("0") && _ord <= ord("9"));
        var _is_upper = (_ord >= ord("A") && _ord <= ord("Z"));
        var _is_lower = (_ord >= ord("a") && _ord <= ord("z"));
        if (_is_digit || _is_upper || _is_lower) _out += _ch;
    }
    return _out;
}

/// @func ga_sample_input_step()
/// @desc Drains typed characters into the focused field and handles the editing
///       keys. Call once per step while the setup screen is up.
function ga_sample_input_step() {
    if (!ga_sample_input_focused()) {
        keyboard_string = "";
        return;
    }

    var _field = global.__ga_fields[global.__ga_focus];

    // Tab / Shift+Tab move between fields.
    if (keyboard_check_pressed(vk_tab)) {
        var _count = array_length(global.__ga_fields);
        var _step = keyboard_check(vk_shift) ? -1 : 1;
        ga_sample_input_focus((global.__ga_focus + _step + _count) % _count);
        return;
    }

    // Ctrl+V. GML has no constant for macOS's Cmd key, which is why each field
    // also gets a Paste button.
    var _ctrl = keyboard_check(vk_control) || keyboard_check(vk_lcontrol) || keyboard_check(vk_rcontrol);
    if (_ctrl && keyboard_check_pressed(ord("V"))) {
        ga_sample_input_paste(_field.id);
        keyboard_string = "";
        return;
    }

    if (keyboard_check_pressed(vk_backspace) && string_length(_field.value) > 0) {
        _field.value = string_copy(_field.value, 1, string_length(_field.value) - 1);
    }

    if (keyboard_string != "") {
        _field.value = string_copy(_field.value + ga_sample_input_filter(keyboard_string),
            1, _field.max_len);
        keyboard_string = "";
    }
}

/// @func ga_sample_input_paste(id)
/// @desc Appends the clipboard's text to a field, filtered to key characters.
/// @param {String} id
function ga_sample_input_paste(id) {
    if (!clipboard_has_text()) {
        ga_sample_log("clipboard is empty", GA_LOG_WARN);
        return;
    }
    for (var _i = 0; _i < array_length(global.__ga_fields); _i++) {
        var _field = global.__ga_fields[_i];
        if (_field.id != id) continue;
        _field.value = string_copy(_field.value + ga_sample_input_filter(clipboard_get_text()),
            1, _field.max_len);
        ga_sample_input_focus(_i);
        return;
    }
}

/// @func ga_sample_input_clear(id)
/// @param {String} id
function ga_sample_input_clear(id) {
    ga_sample_input_set(id, "");
}

/// @func ga_sample_input_click(mx, my)
/// @desc Focuses whichever field was clicked, clearing focus if none was.
/// @param {Real} mx GUI-space mouse x
/// @param {Real} my GUI-space mouse y
/// @return {Bool} whether a field was hit
function ga_sample_input_click(mx, my) {
    for (var _i = 0; _i < array_length(global.__ga_fields); _i++) {
        var _field = global.__ga_fields[_i];
        if (variable_struct_exists(_field, "x") && ga_sample_ui_hit(_field, mx, my)) {
            ga_sample_input_focus(_i);
            return true;
        }
    }
    ga_sample_input_focus(-1);
    return false;
}

#region Persistence

/// @func ga_sample_input_load()
/// @desc Reads back the keys entered on a previous run, so the sample isn't a
///       retyping exercise. They land in the game's own save area
///       (`ga_sample.ini`) in plain text — fine for a local dev sample, not a
///       pattern to copy into a shipped game.
function ga_sample_input_load() {
    ini_open("ga_sample.ini");
    ga_sample_input_set("game_key",    ini_read_string("keys", "game_key", ""));
    ga_sample_input_set("game_secret", ini_read_string("keys", "game_secret", ""));
    ini_close();
}

/// @func ga_sample_input_save()
function ga_sample_input_save() {
    ini_open("ga_sample.ini");
    ini_write_string("keys", "game_key",    ga_sample_input_value("game_key"));
    ini_write_string("keys", "game_secret", ga_sample_input_value("game_secret"));
    ini_close();
}

/// @func ga_sample_input_clear_saved()
function ga_sample_input_clear_saved() {
    ini_open("ga_sample.ini");
    ini_key_delete("keys", "game_key");
    ini_key_delete("keys", "game_secret");
    ini_close();
}

#endregion

/// @func ga_sample_mask(value, visible)
/// @desc Masks all but the first `visible` characters, for showing a secret
///       once it's in use.
/// @param {String} value
/// @param {Real} visible
/// @return {String}
function ga_sample_mask(value, visible) {
    var _len = string_length(value);
    if (_len == 0) return "";
    if (_len <= visible) return value;
    return string_copy(value, 1, visible) + string_repeat("*", _len - visible);
}
