/// @description Draw the sample GUI: header, action buttons, SDK info, log

var _gui_w = display_get_gui_width();
var _gui_h = display_get_gui_height();
var _mx    = device_mouse_x_to_gui(0);
var _my    = device_mouse_y_to_gui(0);
var _info  = global.__ga_info;

var _right_x1 = GA_UI_RIGHT_X;
var _right_x2 = _gui_w - GA_UI_PAD;

// Text metrics drive the row spacing so nothing collides if the runtime's
// built-in font is taller or wider than the layout minimums assume.
var _row_h  = ga_sample_ui_line_h(GA_UI_ROW_H);
var _line_h = ga_sample_ui_line_h(GA_UI_LINE_H);

draw_set_halign(fa_left);
draw_set_valign(fa_top);

// ── Background ──────────────────────────────────────────────────────────────
draw_set_color(GA_COL_BG);
draw_rectangle(0, 0, _gui_w, _gui_h, false);

// ── Header ──────────────────────────────────────────────────────────────────
draw_set_color(GA_COL_PANEL_HEAD);
draw_rectangle(0, 0, _gui_w, GA_UI_HEADER_H, false);
draw_line_color(0, GA_UI_HEADER_H, _gui_w, GA_UI_HEADER_H, GA_COL_ACCENT, GA_COL_ACCENT);

ga_sample_ui_text(GA_UI_PAD, 12, "GameAnalytics", GA_COL_ACCENT, 1.7);
ga_sample_ui_text(GA_UI_PAD, 40, "GameMaker SDK sample", GA_COL_DIM, 1.1);

draw_set_halign(fa_right);
ga_sample_ui_text(_gui_w - GA_UI_PAD, 14,
    _info.initialized ? "SDK initialized" : "SDK not initialized",
    _info.initialized ? GA_COL_OK : GA_COL_WARN, 1.1);
ga_sample_ui_text(_gui_w - GA_UI_PAD, 36,
    ga_sample_platform_name() + "  |  build " + _info.build, GA_COL_DIM, 1);
ga_sample_ui_text(_gui_w - GA_UI_PAD, 52,
    "info refreshed " + _info.refreshed_at, GA_COL_DIM, 1);
draw_set_halign(fa_left);

// ── Setup screen: game keys ─────────────────────────────────────────────────
if (!_info.initialized) {
    var _card_x1 = (_gui_w - GA_UI_FIELD_W) * 0.5 - 32;
    var _card_x2 = (_gui_w + GA_UI_FIELD_W) * 0.5 + 32;
    ga_sample_ui_panel(_card_x1, 100, _card_x2, GA_UI_LOG_Y1 - 24, "CONNECT TO GAMEANALYTICS");

    ga_sample_ui_text(_card_x1 + 32, 140,
        "Paste the keys from your game's Settings page on gameanalytics.com.",
        GA_COL_DIM, 1.05);

    for (var _i = 0; _i < ga_sample_input_count(); _i++) {
        ga_sample_ui_draw_field(ga_sample_input_field(_i), global.__ga_focus == _i);
    }

    var _setup = global.__ga_setup_buttons;
    for (var _i = 0; _i < array_length(_setup); _i++) {
        var _btn   = _setup[_i];
        var _ready = ga_sample_input_is_complete();
        ga_sample_ui_draw_button(_btn, _ready && ga_sample_ui_hit(_btn, _mx, _my));
        if (!_ready) {
            // dim the button until both keys are the right length
            draw_set_alpha(0.55);
            draw_set_color(GA_COL_BG);
            draw_rectangle(_btn.x + 1, _btn.y + 1, _btn.x + _btn.w - 1, _btn.y + _btn.h - 1, false);
            draw_set_alpha(1);
        }
    }

    ga_sample_ui_text(_card_x1 + 32, GA_UI_LOG_Y1 - 62,
        "Tab switches fields, Cmd/Ctrl+V pastes, Enter initializes.", GA_COL_DIM, 1);

    // The log panel stays visible so validation messages have somewhere to go.
    var _log_y = ga_sample_ui_panel(GA_UI_PAD, GA_UI_LOG_Y1, _gui_w - GA_UI_PAD, _gui_h - GA_UI_PAD,
        "EVENT LOG  (newest first)");
    var _log_x = GA_UI_PAD + 12;
    var _log_w = (_gui_w - GA_UI_PAD - 12) - _log_x;
    var _log_gutter = string_width("00:00:00") + 14;
    var _log_count = ga_sample_log_count();
    var _log_max = floor(((_gui_h - GA_UI_PAD - 8) - _log_y) / _line_h);
    for (var _i = 0; _i < min(_log_count, _log_max); _i++) {
        var _entry = ga_sample_log_get(_i);
        var _y = _log_y + _i * _line_h;
        ga_sample_ui_text(_log_x, _y, _entry.time, GA_COL_DIM, 1);
        ga_sample_ui_text(_log_x + _log_gutter, _y,
            ga_sample_ui_ellipsize(_entry.msg, _log_w - _log_gutter),
            ga_sample_ui_log_color(_entry.kind), 1);
    }

    draw_set_color(c_white);
    exit;
}

// ── Action buttons ──────────────────────────────────────────────────────────
var _buttons = global.__ga_buttons;
for (var _i = 0; _i < array_length(_buttons); _i++) {
    var _btn = _buttons[_i];
    ga_sample_ui_draw_button(_btn, ga_sample_ui_hit(_btn, _mx, _my));
}

// ── Identity / A/B panel ────────────────────────────────────────────────────
var _row_y   = ga_sample_ui_panel(_right_x1, GA_UI_INFO_Y1, _right_x2, GA_UI_INFO_Y2,
    "IDENTITY & A/B TESTING");
var _row_x   = _right_x1 + 12;
var _label_w = string_width("Custom dimension 01") + 20;
var _row_w   = (_right_x2 - 12) - _row_x;

ga_sample_ui_row(_row_x, _row_y, "User ID",
    _info.user_id + (_info.user_id_from_sdk ? "   (from SDK)" : "   (configured)"),
    _label_w, _row_w);
_row_y += _row_h;

ga_sample_ui_row(_row_x, _row_y, "External user ID",
    _info.ext_user_id + (_info.ext_user_id_from_sdk ? "   (from SDK)"
        : (_info.ext_user_id_supported ? "   (configured)" : "   (not supported on this platform)")),
    _label_w, _row_w,
    (_info.ext_user_id_from_sdk || _info.ext_user_id_supported) ? GA_COL_VALUE : GA_COL_WARN);
_row_y += _row_h;

var _ab_note = _info.ab_supported ? "not assigned" : "not exposed on " + ga_sample_platform_name();
var _ab_col  = _info.ab_supported ? GA_COL_DIM : GA_COL_WARN;

ga_sample_ui_row(_row_x, _row_y, "A/B test ID",
    _info.ab_test_id == "" ? _ab_note : _info.ab_test_id, _label_w, _row_w,
    _info.ab_test_id == "" ? _ab_col : GA_COL_VALUE);
_row_y += _row_h;

ga_sample_ui_row(_row_x, _row_y, "A/B variant ID",
    _info.ab_variant_id == "" ? _ab_note : _info.ab_variant_id, _label_w, _row_w,
    _info.ab_variant_id == "" ? _ab_col : GA_COL_VALUE);
_row_y += _row_h;

ga_sample_ui_row(_row_x, _row_y, "Custom dimension 01", _info.dimension_01, _label_w, _row_w);
_row_y += _row_h;

ga_sample_ui_row(_row_x, _row_y, "Game key", ga_sample_mask(_info.game_key, 8), _label_w, _row_w);
_row_y += _row_h + 4;

ga_sample_ui_text(_row_x, _row_y, ga_sample_ui_ellipsize(
    "Ids marked (from SDK) are read back live; (configured) means Create_0 set them.", _row_w),
    GA_COL_DIM, 1);

// ── Remote configs panel ────────────────────────────────────────────────────
var _cfg_y = ga_sample_ui_panel(_right_x1, GA_UI_CFG_Y1, _right_x2, GA_UI_CFG_Y2, "REMOTE CONFIGS");

draw_set_halign(fa_right);
ga_sample_ui_text(_right_x2 - 12, GA_UI_CFG_Y1 + 7,
    _info.remote_ready ? "ready" : "not ready",
    _info.remote_ready ? GA_COL_OK : GA_COL_WARN, 1);
draw_set_halign(fa_left);

var _rows      = _info.remote_rows;
var _row_count = array_length(_rows);
var _cfg_max   = floor(((GA_UI_CFG_Y2 - 10) - _cfg_y) / _row_h) - 1;
var _cfg_shown = min(_row_count, _cfg_max);

if (_row_count == 0) {
    ga_sample_ui_text(_row_x, _cfg_y,
        _info.remote_ready ? "Ready, but the payload is empty - no configs are live for this build."
                           : "Waiting for the SDK to fetch remote configs...", GA_COL_DIM, 1);
    _cfg_y += _row_h;
    ga_sample_ui_text(_row_x, _cfg_y,
        "Values become readable once the SDK is initialized with real game keys.", GA_COL_DIM, 1);
} else {
    var _key_w = 0;
    for (var _i = 0; _i < _cfg_shown; _i++) {
        _key_w = max(_key_w, string_width(_rows[_i].key));
    }
    _key_w = min(_key_w + 20, _row_w * 0.5);

    for (var _i = 0; _i < _cfg_shown; _i++) {
        ga_sample_ui_row(_row_x, _cfg_y, _rows[_i].key, _rows[_i].value, _key_w, _row_w);
        _cfg_y += _row_h;
    }
    if (_row_count > _cfg_shown) {
        ga_sample_ui_text(_row_x, _cfg_y,
            "+ " + string(_row_count - _cfg_shown) + " more key(s) - see the log or debug output",
            GA_COL_DIM, 1);
    }
}

// ── Log console ─────────────────────────────────────────────────────────────
var _log_y = ga_sample_ui_panel(GA_UI_PAD, GA_UI_LOG_Y1, _gui_w - GA_UI_PAD, _gui_h - GA_UI_PAD,
    "EVENT LOG  (newest first)");
var _log_x = GA_UI_PAD + 12;
var _log_w = (_gui_w - GA_UI_PAD - 12) - _log_x;
var _log_count = ga_sample_log_count();

// Measured, not assumed: the built-in font's width varies with the runtime, and
// a hardcoded gutter here runs the message into the timestamp.
var _log_gutter = string_width("00:00:00") + 14;

if (_log_count == 0) {
    ga_sample_ui_text(_log_x, _log_y, "No events fired yet.", GA_COL_DIM, 1);
} else {
    var _log_max = floor(((_gui_h - GA_UI_PAD - 8) - _log_y) / _line_h);
    for (var _i = 0; _i < min(_log_count, _log_max); _i++) {
        var _entry = ga_sample_log_get(_i);
        var _y     = _log_y + _i * _line_h;
        ga_sample_ui_text(_log_x, _y, _entry.time, GA_COL_DIM, 1);
        ga_sample_ui_text(_log_x + _log_gutter, _y,
            ga_sample_ui_ellipsize(_entry.msg, _log_w - _log_gutter),
            ga_sample_ui_log_color(_entry.kind), 1);
    }
}

draw_set_color(c_white);
