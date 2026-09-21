/// @description Handle input, and keep the SDK's HTTP and info panels moving

// Draw_64 is the Draw GUI event, so everything lives in GUI space — hit-test
// with the GUI-space mouse, not mouse_x/mouse_y, or clicks break as soon as the
// window is scaled.
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);

if (!global.__ga_info.initialized) {
    // ── Setup screen: key entry ─────────────────────────────────────────────
    if (mouse_check_button_pressed(mb_left)) {
        if (!ga_sample_input_click(_mx, _my)) {
            var _setup = global.__ga_setup_buttons;
            for (var _i = 0; _i < array_length(_setup); _i++) {
                if (ga_sample_ui_hit(_setup[_i], _mx, _my)) {
                    ga_sample_trigger(_setup[_i].id);
                    break;
                }
            }
        }
    }

    ga_sample_input_step();

    // Enter submits, whether or not a field has focus.
    if (keyboard_check_pressed(vk_enter)) {
        ga_sample_trigger("initialize");
    }
} else {
    // ── Dashboard: action buttons ───────────────────────────────────────────
    if (mouse_check_button_pressed(mb_left)) {
        var _buttons = global.__ga_buttons;
        for (var _i = 0; _i < array_length(_buttons); _i++) {
            if (ga_sample_ui_hit(_buttons[_i], _mx, _my)) {
                ga_sample_trigger(_buttons[_i].id);
                break;
            }
        }
    }
}

// Desktop routes the SDK's HTTP through GameMaker, so its queued requests are
// issued from here and answered in the Async HTTP event.
ga_http_pump();

ga_sample_ui_fade_flashes();

refresh_countdown--;
if (refresh_countdown <= 0) {
    refresh_countdown = game_get_speed(gamespeed_fps);
    if (global.__ga_info.initialized) ga_sample_info_refresh();
}
