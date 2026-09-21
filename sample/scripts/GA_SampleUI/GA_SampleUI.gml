/// GA_SampleUI — layout, palette and drawing helpers for the sample's GUI.
///
/// Everything is drawn with flat rectangles and the built-in font, so the
/// sample needs no sprite or font assets. All coordinates are GUI-layer
/// coordinates (obj_controller draws in the Draw GUI event), which means the
/// UI keeps its pixel size no matter how the window is scaled — the matching
/// hit-testing in Step_0 therefore uses device_mouse_*_to_gui().

#region Palette

#macro GA_COL_BG        make_color_rgb(18,  20,  26)
#macro GA_COL_PANEL     make_color_rgb(30,  33,  41)
#macro GA_COL_PANEL_HEAD make_color_rgb(38, 42,  52)
#macro GA_COL_BORDER    make_color_rgb(58,  63,  75)
#macro GA_COL_ACCENT    make_color_rgb(255, 138, 48)
#macro GA_COL_TEXT      make_color_rgb(232, 236, 244)
#macro GA_COL_DIM       make_color_rgb(140, 148, 164)
#macro GA_COL_VALUE     make_color_rgb(126, 200, 255)
#macro GA_COL_OK        make_color_rgb(120, 220, 150)
#macro GA_COL_WARN      make_color_rgb(240, 190, 90)
#macro GA_COL_BTN       make_color_rgb(45,  52,  66)
#macro GA_COL_BTN_HOVER make_color_rgb(64,  74,  94)
#macro GA_COL_BTN_FLASH make_color_rgb(255, 138, 48)

#endregion

#region Layout

#macro GA_UI_PAD        16
#macro GA_UI_HEADER_H   64
#macro GA_UI_BTN_X      16
#macro GA_UI_BTN_W      300
#macro GA_UI_BTN_Y0     80
#macro GA_UI_BTN_H      42
#macro GA_UI_BTN_GAP    8
#macro GA_UI_RIGHT_X    332

#macro GA_UI_INFO_Y1    80
#macro GA_UI_INFO_Y2    276
#macro GA_UI_CFG_Y1     284
#macro GA_UI_CFG_Y2     472
#macro GA_UI_LOG_Y1     484

#macro GA_UI_FIELD_W    620
#macro GA_UI_FIELD_H    34
#macro GA_UI_ROW_H      21
#macro GA_UI_LINE_H     18
#macro GA_UI_TITLE_H    26

#endregion

#region Buttons

/// @func ga_sample_ui_build_buttons()
/// @desc Builds the single source of truth for the button column: both
///       Step_0 (hit-testing) and Draw_64 (rendering) read this array, and the
///       ids are what ga_sample_trigger() dispatches on.
function ga_sample_ui_build_buttons() {
    if (!variable_global_exists("__ga_setup_buttons")) global.__ga_setup_buttons = [];

    var _defs = [
        { id: "business", label: "Business event",     key: "Enter" },
        { id: "level",    label: "Complete level",     key: "Space" },
        { id: "design",   label: "Design event",       key: "D" },
        { id: "error",    label: "Error event",        key: "E" },
        { id: "ad",       label: "Ad events",          key: "A" },
        { id: "config",   label: "Read remote config", key: "R" },
        { id: "refresh",  label: "Refresh SDK info",   key: "F" },
        { id: "clear",    label: "Clear log",          key: "C" },
    ];

    global.__ga_buttons = [];
    for (var _i = 0; _i < array_length(_defs); _i++) {
        var _def = _defs[_i];
        array_push(global.__ga_buttons, {
            id:    _def.id,
            label: _def.label,
            key:   _def.key,
            flash: 0,
            x:     GA_UI_BTN_X,
            y:     GA_UI_BTN_Y0 + _i * (GA_UI_BTN_H + GA_UI_BTN_GAP),
            w:     GA_UI_BTN_W,
            h:     GA_UI_BTN_H,
        });
    }
}

/// @func ga_sample_ui_flash(id)
/// @desc Lights a button up briefly — called for keyboard shortcuts too, so
///       pressing a key visibly highlights the matching button.
/// @param {String} id
function ga_sample_ui_flash(id) {
    var _lists = [global.__ga_buttons, global.__ga_setup_buttons];
    for (var _l = 0; _l < array_length(_lists); _l++) {
        var _buttons = _lists[_l];
        for (var _i = 0; _i < array_length(_buttons); _i++) {
            if (_buttons[_i].id == id) {
                _buttons[_i].flash = 10;
                return;
            }
        }
    }
}

/// @func ga_sample_ui_fade_flashes()
/// @desc Ticks the flash timers down. Call once per step.
function ga_sample_ui_fade_flashes() {
    var _lists = [global.__ga_buttons, global.__ga_setup_buttons];
    for (var _l = 0; _l < array_length(_lists); _l++) {
        var _buttons = _lists[_l];
        for (var _i = 0; _i < array_length(_buttons); _i++) {
            if (_buttons[_i].flash > 0) _buttons[_i].flash--;
        }
    }
}

/// @func ga_sample_ui_hit(btn, mx, my)
/// @param {Struct} btn
/// @param {Real} mx GUI-space mouse x
/// @param {Real} my GUI-space mouse y
/// @return {Bool}
function ga_sample_ui_hit(btn, mx, my) {
    return (mx >= btn.x && mx <= btn.x + btn.w && my >= btn.y && my <= btn.y + btn.h);
}

/// @func ga_sample_ui_draw_button(btn, hover)
/// @param {Struct} btn
/// @param {Bool} hover
function ga_sample_ui_draw_button(btn, hover) {
    var _fill = GA_COL_BTN;
    if (hover) _fill = GA_COL_BTN_HOVER;
    if (btn.flash > 0) _fill = GA_COL_BTN_FLASH;

    draw_set_color(_fill);
    draw_rectangle(btn.x, btn.y, btn.x + btn.w, btn.y + btn.h, false);
    draw_set_color(hover || btn.flash > 0 ? GA_COL_ACCENT : GA_COL_BORDER);
    draw_rectangle(btn.x, btn.y, btn.x + btn.w, btn.y + btn.h, true);

    var _label_col = (btn.flash > 0) ? GA_COL_BG : GA_COL_TEXT;
    var _key_col   = (btn.flash > 0) ? GA_COL_BG : GA_COL_DIM;

    var _key_text  = (btn.key == "") ? "" : "[" + btn.key + "]";
    var _label_max = btn.w - 28 - string_width(_key_text) - (_key_text == "" ? 0 : 10);

    draw_set_valign(fa_middle);
    draw_set_halign(fa_left);
    ga_sample_ui_text(btn.x + 14, btn.y + btn.h * 0.5,
        ga_sample_ui_ellipsize(btn.label, _label_max, 1.15), _label_col, 1.15);

    draw_set_halign(fa_right);
    ga_sample_ui_text(btn.x + btn.w - 14, btn.y + btn.h * 0.5, _key_text, _key_col, 1);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

#endregion

#region Setup screen (key entry)

/// @func ga_sample_ui_build_setup()
/// @desc Lays out the two key fields and the Initialize button, centred. Both
///       hit-testing (Step) and drawing (Draw GUI) read these.
/// @param {Real} gui_w
/// @param {Real} gui_h
function ga_sample_ui_build_setup(gui_w, gui_h) {
    var _x = (gui_w - GA_UI_FIELD_W) * 0.5;
    var _y = 190;

    var _paste_w = 84;
    var _field_w = GA_UI_FIELD_W - _paste_w - 8;

    global.__ga_setup_buttons = [];

    for (var _i = 0; _i < ga_sample_input_count(); _i++) {
        var _field = ga_sample_input_field(_i);
        _field.x = _x;
        _field.y = _y + _i * (GA_UI_FIELD_H + 34);
        _field.w = _field_w;
        _field.h = GA_UI_FIELD_H;

        // Paste button, because GML cannot see macOS's Cmd key.
        array_push(global.__ga_setup_buttons, {
            id:    "paste_" + _field.id,
            label: "Paste",
            key:   "",
            flash: 0,
            x:     _x + _field_w + 8,
            y:     _field.y,
            w:     _paste_w,
            h:     GA_UI_FIELD_H,
        });
    }

    var _button_y = _y + ga_sample_input_count() * (GA_UI_FIELD_H + 34) + 12;
    array_push(global.__ga_setup_buttons, {
        id:    "initialize",
        label: "Initialize GameAnalytics",
        key:   "Enter",
        flash: 0,
        x:     _x,
        y:     _button_y,
        w:     GA_UI_FIELD_W,
        h:     GA_UI_BTN_H,
    });
}

/// @func ga_sample_ui_draw_field(field, focused)
/// @param {Struct} field
/// @param {Bool} focused
function ga_sample_ui_draw_field(field, focused) {
    var _len      = string_length(field.value);
    var _complete = (_len == field.max_len);

    draw_set_valign(fa_top);
    draw_set_halign(fa_left);
    ga_sample_ui_text(field.x, field.y - 20, field.label, GA_COL_TEXT, 1.05);

    // character counter, green once the length is right
    draw_set_halign(fa_right);
    ga_sample_ui_text(field.x + field.w, field.y - 18,
        string(_len) + "/" + string(field.max_len) + "  " + field.hint,
        _complete ? GA_COL_OK : GA_COL_DIM, 1);
    draw_set_halign(fa_left);

    draw_set_color(GA_COL_PANEL);
    draw_rectangle(field.x, field.y, field.x + field.w, field.y + field.h, false);
    draw_set_color(focused ? GA_COL_ACCENT : (_complete ? GA_COL_OK : GA_COL_BORDER));
    draw_rectangle(field.x, field.y, field.x + field.w, field.y + field.h, true);

    draw_set_valign(fa_middle);
    var _text_y = field.y + field.h * 0.5;
    if (_len == 0) {
        ga_sample_ui_text(field.x + 10, _text_y, "click here and paste your " + field.label, GA_COL_DIM, 1);
    } else {
        ga_sample_ui_text(field.x + 10, _text_y,
            ga_sample_ui_ellipsize(field.value, field.w - 24), GA_COL_TEXT, 1);
    }

    // caret
    if (focused && ((current_time div 500) % 2 == 0)) {
        var _caret_x = field.x + 10 + string_width(field.value);
        if (_caret_x < field.x + field.w - 8) {
            draw_set_color(GA_COL_ACCENT);
            draw_line_width(_caret_x + 1, field.y + 7, _caret_x + 1, field.y + field.h - 7, 2);
        }
    }

    draw_set_valign(fa_top);
}

#endregion

#region Primitives

/// @func ga_sample_ui_text(x, y, str, col, [scale])
/// @param {Real} x
/// @param {Real} y
/// @param {String} str
/// @param {Constant.Color} col
/// @param {Real} [scale]
function ga_sample_ui_text(x, y, str, col, scale = 1) {
    draw_set_color(col);
    draw_text_transformed(x, y, str, scale, scale, 0);
}

/// @func ga_sample_ui_line_h(minimum)
/// @desc Row height for text lines: the design minimum, or whatever the
///       runtime's built-in font actually needs, whichever is larger.
/// @param {Real} minimum
/// @return {Real}
function ga_sample_ui_line_h(minimum) {
    return max(minimum, string_height("Ay") + 5);
}

/// @func ga_sample_ui_panel(x1, y1, x2, y2, title)
/// @desc Draws a bordered panel with a title bar and returns the y coordinate
///       where its content should start.
/// @param {Real} x1
/// @param {Real} y1
/// @param {Real} x2
/// @param {Real} y2
/// @param {String} title
/// @return {Real}
function ga_sample_ui_panel(x1, y1, x2, y2, title) {
    draw_set_color(GA_COL_PANEL);
    draw_rectangle(x1, y1, x2, y2, false);
    draw_set_color(GA_COL_PANEL_HEAD);
    draw_rectangle(x1, y1, x2, y1 + GA_UI_TITLE_H, false);
    draw_set_color(GA_COL_BORDER);
    draw_rectangle(x1, y1, x2, y2, true);
    draw_line_color(x1, y1 + GA_UI_TITLE_H, x2, y1 + GA_UI_TITLE_H, GA_COL_BORDER, GA_COL_BORDER);

    ga_sample_ui_text(x1 + 12, y1 + 6, title, GA_COL_ACCENT, 1.1);

    return y1 + GA_UI_TITLE_H + 10;
}

/// @func ga_sample_ui_ellipsize(str, max_width, [scale])
/// @desc Trims a string until it fits max_width pixels, appending "..." when
///       anything was cut. Keeps long ids and JSON blobs inside their panel.
/// @param {String} str
/// @param {Real} max_width
/// @param {Real} [scale]
/// @return {String}
function ga_sample_ui_ellipsize(str, max_width, scale = 1) {
    var _text = string(str);
    if (string_width(_text) * scale <= max_width) return _text;

    var _len = string_length(_text);
    while (_len > 1 && string_width(string_copy(_text, 1, _len) + "...") * scale > max_width) {
        _len--;
    }
    return string_copy(_text, 1, _len) + "...";
}

/// @func ga_sample_ui_row(x, y, label, value, label_w, max_w, [value_col])
/// @desc Draws one "Label   value" line, ellipsizing the value to fit.
/// @param {Real} x
/// @param {Real} y
/// @param {String} label
/// @param {String} value
/// @param {Real} label_w column width reserved for the label
/// @param {Real} max_w total width available for the row
/// @param {Constant.Color} [value_col]
function ga_sample_ui_row(x, y, label, value, label_w, max_w, value_col = GA_COL_VALUE) {
    ga_sample_ui_text(x, y, ga_sample_ui_ellipsize(label, label_w - 10), GA_COL_DIM, 1);
    ga_sample_ui_text(x + label_w, y, ga_sample_ui_ellipsize(value, max_w - label_w), value_col, 1);
}

/// @func ga_sample_ui_log_color(kind)
/// @param {Real} kind one of the GA_LOG_* constants
/// @return {Constant.Color}
function ga_sample_ui_log_color(kind) {
    switch (kind) {
        case GA_LOG_INFO:   return GA_COL_DIM;
        case GA_LOG_CONFIG: return GA_COL_VALUE;
        case GA_LOG_WARN:   return GA_COL_WARN;
        default:            return GA_COL_TEXT;
    }
}

#endregion
