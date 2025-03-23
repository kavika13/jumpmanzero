const std = @import("std");
usingnamespace @import("sound.zig"); // TODO: Is there some other way to get the exports to show to C?
usingnamespace @import("sound_buffer.zig"); // TODO: Is there some other way to get the exports to show to C?
const jumpman_main_c = @cImport({
    @cDefine("ZIG_DEFINES_MAIN", {});
    @cDefine("GLFW_INCLUDE_NONE", {});
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
    @cInclude("Basic3d.h");
    @cInclude("Input.h");
    @cInclude("Jumpman.h");
    @cInclude("Main.h");
    @cInclude("Music.h");
    @cInclude("Sound.h");
    @cInclude("SoundBuffer.h");
    @cInclude("Utilities.h");
    @cInclude("logging.h");
});

const kFULLSCREEN_IS_ENABLED_DEFAULT: bool = false;
const kWINDOW_RESOLUTION_DEFAULT_X: i32 = 640;
const kWINDOW_RESOLUTION_DEFAULT_Y: i32 = 480;
const kWINDOW_RESOLUTION_MIN_X: i32 = 320;
const kWINDOW_RESOLUTION_MIN_Y: i32 = 240;
const kSOUND_EFFECTS_ARE_ENABLED_DEFAULT: bool = false;
const kMUSIC_IS_ENABLED_DEFAULT: bool = false;

const kFRAMES_PER_SECOND: f64 = 40;
const kSLOWMO_RATIO: f64 = 16;
const kSECONDS_PER_FRAME: f64 = 1.0 / kFRAMES_PER_SECOND;
const kSECONDS_PER_FRAME_SLOWMO: f64 = kSLOWMO_RATIO / kFRAMES_PER_SECOND;

var g_update_frame_times = std.mem.zeroes([kFRAMES_PER_SECOND]f64);
var g_update_frame_times_current_index: usize = 0;

var g_game_base_path = std.mem.zeroes([300:0]u8);
var g_key_bindings = std.mem.zeroes([6]i32);
var g_last_key_pressed: i32 = 0;
var g_fullscreen_is_enabled: bool = kFULLSCREEN_IS_ENABLED_DEFAULT;
var g_window_resolution_x: i32 = kWINDOW_RESOLUTION_DEFAULT_X;
var g_window_resolution_y: i32 = kWINDOW_RESOLUTION_DEFAULT_Y;
var g_window_pos_x_backup: i32 = 0;
var g_window_pos_y_backup: i32 = 0;
var g_save_settings_is_queued: bool = false;
var g_game_is_frozen: bool = false;
var g_current_fps: i32 = 0;
var g_current_max_update_frame_time: f64 = 0.0;
var g_current_max_draw_and_swap_frame_time: f64 = 0.0;

var g_main_window: ?*jumpman_main_c.GLFWwindow = null;

const GameState = struct {
    current_input: jumpman_main_c.GameInput,
};

fn LoadSettings(sound_is_initially_enabled: *bool, music_is_initially_enabled: *bool) bool {
    var sTemp = std.mem.zeroes([30]u8);
    var sFileNameBuffer = std.mem.zeroes([300]u8); // TODO: Is path long enough?
    _ = std.fmt.bufPrintZ(
        &sFileNameBuffer,
        "{s}/data/settings.dat",
        .{@as([*:0]const u8, &g_game_base_path)},
    ) catch {
        return false;
    };

    var sData: ?[*:0]u8 = null;
    const iLen = jumpman_main_c.FileToString(&sFileNameBuffer, @ptrCast(&sData)); // TODO: Zig native equivalent

    // TODO: Handle file missing case without an error message - should create it and set defaults instead
    if (iLen == 0) {
        return false;
    }

    for (0..6) |key_index| {
        g_key_bindings[key_index] = if (jumpman_main_c.GetFileLine(&sTemp, sTemp.len, &sFileNameBuffer, @intCast(key_index)))
            jumpman_main_c.atoi(&sTemp)
        else
            0;
    }

    sound_is_initially_enabled.* = if (jumpman_main_c.GetFileLine(&sTemp, sTemp.len, &sFileNameBuffer, 6))
        jumpman_main_c.atoi(&sTemp) != 0
    else
        false;

    music_is_initially_enabled.* = if (jumpman_main_c.GetFileLine(&sTemp, sTemp.len, &sFileNameBuffer, 7))
        jumpman_main_c.atoi(&sTemp) != 0
    else
        false;

    g_fullscreen_is_enabled = if (jumpman_main_c.GetFileLine(&sTemp, sTemp.len, &sFileNameBuffer, 8))
        jumpman_main_c.atoi(&sTemp) != 0
    else
        false;

    g_window_resolution_x = if (jumpman_main_c.GetFileLine(&sTemp, sTemp.len, &sFileNameBuffer, 9))
        jumpman_main_c.atoi(&sTemp)
    else
        kWINDOW_RESOLUTION_DEFAULT_X;

    if (g_window_resolution_x < kWINDOW_RESOLUTION_MIN_X) {
        g_window_resolution_x = kWINDOW_RESOLUTION_MIN_X;
    }

    g_window_resolution_y = if (jumpman_main_c.GetFileLine(&sTemp, sTemp.len, &sFileNameBuffer, 10))
        jumpman_main_c.atoi(&sTemp)
    else
        kWINDOW_RESOLUTION_DEFAULT_Y;

    if (g_window_resolution_y < kWINDOW_RESOLUTION_MIN_Y) {
        g_window_resolution_y = kWINDOW_RESOLUTION_MIN_Y;
    }

    return true;
}

fn save_settings() bool {
    var success = true;

    var sFileBuffer = std.mem.zeroes([300]u8);
    _ = std.fmt.bufPrintZ(
        &sFileBuffer,
        "{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}\n{}",
        .{
            g_key_bindings[0],
            g_key_bindings[1],
            g_key_bindings[2],
            g_key_bindings[3],
            g_key_bindings[4],
            g_key_bindings[5],
            @as(c_int, if (jumpman_main_c.GetIsSoundEnabled()) 1 else 0),
            @as(c_int, if (jumpman_main_c.GetIsMusicEnabled()) 1 else 0),
            @as(c_int, if (g_fullscreen_is_enabled) 1 else 0), // TODO: Report bug that if I don't use @as here, the compiler errors out without a message
            g_window_resolution_x,
            g_window_resolution_y,
        },
    ) catch {
        return false;
    };

    var sFileNameBuffer = std.mem.zeroes([300]u8); // TODO: Is path long enough?
    _ = std.fmt.bufPrintZ(
        &sFileNameBuffer,
        "{s}/data/settings.dat",
        .{@as([*:0]const u8, &g_game_base_path)},
    ) catch {
        return false;
    };

    success = jumpman_main_c.StringToFile(&sFileNameBuffer, &sFileBuffer);

    return success;
}

fn SetFullscreen(enable_fullscreen: bool, new_width: ?*i32, new_height: ?*i32) void {
    g_fullscreen_is_enabled = enable_fullscreen;

    var monitor: ?*jumpman_main_c.GLFWmonitor = null;
    var target_pos_x: i32 = g_window_pos_x_backup;
    var target_pos_y: i32 = g_window_pos_y_backup;
    var target_width: i32 = g_window_resolution_x;
    var target_height: i32 = g_window_resolution_y;

    if (enable_fullscreen) {
        monitor = jumpman_main_c.glfwGetPrimaryMonitor();

        jumpman_main_c.glfwGetWindowPos(g_main_window, &g_window_pos_x_backup, &g_window_pos_y_backup);

        const mode: ?*const jumpman_main_c.GLFWvidmode = jumpman_main_c.glfwGetVideoMode(monitor);
        jumpman_main_c.glfwWindowHint(jumpman_main_c.GLFW_RED_BITS, mode.?.*.redBits);
        jumpman_main_c.glfwWindowHint(jumpman_main_c.GLFW_GREEN_BITS, mode.?.*.greenBits);
        jumpman_main_c.glfwWindowHint(jumpman_main_c.GLFW_BLUE_BITS, mode.?.*.blueBits);
        jumpman_main_c.glfwWindowHint(jumpman_main_c.GLFW_REFRESH_RATE, mode.?.*.refreshRate);

        target_pos_x = 0;
        target_pos_y = 0;
        target_width = mode.?.*.width;
        target_height = mode.?.*.height;
    }

    jumpman_main_c.glfwSetWindowMonitor(g_main_window, monitor, target_pos_x, target_pos_y, target_width, target_height, jumpman_main_c.GLFW_DONT_CARE);

    if (enable_fullscreen) {
        jumpman_main_c.glfwSetInputMode(g_main_window, jumpman_main_c.GLFW_CURSOR, jumpman_main_c.GLFW_CURSOR_HIDDEN);
    } else {
        jumpman_main_c.glfwSetInputMode(g_main_window, jumpman_main_c.GLFW_CURSOR, jumpman_main_c.GLFW_CURSOR_NORMAL);
    }

    if (new_width != null) {
        new_width.?.* = target_width;
    }

    if (new_height != null) {
        new_height.?.* = target_height;
    }

    SaveSettings();
}

fn ErrorCallback(_: c_int, description: ?[*:0]const u8) callconv(.C) void {
    _ = jumpman_main_c.debug_log("Error: %s\n", description);
}

fn KeyCallback(window: ?*jumpman_main_c.GLFWwindow, key: c_int, _: c_int, action: c_int, mods: c_int) callconv(.C) void {
    const game_state: ?*GameState = @ptrCast(@alignCast(jumpman_main_c.glfwGetWindowUserPointer(window)));
    const game_current_input = &game_state.?.*.current_input;

    switch (action) {
        jumpman_main_c.GLFW_PRESS => {
            switch (key) {
                jumpman_main_c.GLFW_KEY_GRAVE_ACCENT => {
                    game_current_input.*.debug_action.is_pressed = true;
                },
                jumpman_main_c.GLFW_KEY_F1 => {
                    game_current_input.*.cheat_action.is_pressed = true;
                },
                jumpman_main_c.GLFW_KEY_UP => {
                    game_current_input.*.move_up_action.is_pressed = true;
                },
                jumpman_main_c.GLFW_KEY_DOWN => {
                    game_current_input.*.move_down_action.is_pressed = true;
                },
                jumpman_main_c.GLFW_KEY_LEFT => {
                    game_current_input.*.move_left_action.is_pressed = true;
                },
                jumpman_main_c.GLFW_KEY_RIGHT => {
                    game_current_input.*.move_right_action.is_pressed = true;
                },
                jumpman_main_c.GLFW_KEY_SPACE => {
                    game_current_input.*.jump_action.is_pressed = true;
                    game_current_input.*.select_action.is_pressed = true;
                },
                jumpman_main_c.GLFW_KEY_ENTER => {
                    if (mods & jumpman_main_c.GLFW_MOD_ALT != 0) {
                        SetFullscreen(!g_fullscreen_is_enabled, null, null);
                    } else {
                        game_current_input.*.select_action.is_pressed = true;
                    }
                },
                jumpman_main_c.GLFW_KEY_TAB => {
                    game_current_input.*.slowmo_action.is_pressed = true;
                },
                jumpman_main_c.GLFW_KEY_F11 => {
                    SetFullscreen(!g_fullscreen_is_enabled, null, null);
                },
                jumpman_main_c.GLFW_KEY_ESCAPE => {
                    jumpman_main_c.ExitGame();
                    jumpman_main_c.glfwSetWindowShouldClose(window, jumpman_main_c.GLFW_TRUE);
                },
                else => {},
            }

            // Modifier keys
            if (mods & jumpman_main_c.GLFW_MOD_CONTROL != 0) {
                game_current_input.*.jump_action.is_pressed = true;
                game_current_input.*.select_action.is_pressed = true;
            }

            if (mods & jumpman_main_c.GLFW_MOD_ALT != 0) {
                if (key != jumpman_main_c.GLFW_KEY_ENTER) { // Ignore for alt + enter combo
                    game_current_input.*.attack_action.is_pressed = true;
                }
            }

            // Bound keys
            if (key == g_key_bindings[0]) {
                game_current_input.*.move_up_action.is_pressed = true;
            }

            if (key == g_key_bindings[1]) {
                game_current_input.*.move_down_action.is_pressed = true;
            }

            if (key == g_key_bindings[2]) {
                game_current_input.*.move_left_action.is_pressed = true;
            }

            if (key == g_key_bindings[3]) {
                game_current_input.*.move_right_action.is_pressed = true;
            }

            if (key == g_key_bindings[4]) {
                game_current_input.*.jump_action.is_pressed = true;
                game_current_input.*.select_action.is_pressed = true;
            }

            if (key == g_key_bindings[5]) {
                game_current_input.*.attack_action.is_pressed = true;
            }

            g_last_key_pressed = key;
        },
        jumpman_main_c.GLFW_RELEASE => {
            switch (key) {
                jumpman_main_c.GLFW_KEY_GRAVE_ACCENT => {
                    game_current_input.*.debug_action.is_pressed = false;
                },
                jumpman_main_c.GLFW_KEY_F1 => {
                    game_current_input.*.cheat_action.is_pressed = false;
                },
                jumpman_main_c.GLFW_KEY_UP => {
                    game_current_input.*.move_up_action.is_pressed = false;
                },
                jumpman_main_c.GLFW_KEY_DOWN => {
                    game_current_input.*.move_down_action.is_pressed = false;
                },
                jumpman_main_c.GLFW_KEY_LEFT => {
                    game_current_input.*.move_left_action.is_pressed = false;
                },
                jumpman_main_c.GLFW_KEY_RIGHT => {
                    game_current_input.*.move_right_action.is_pressed = false;
                },
                jumpman_main_c.GLFW_KEY_SPACE => {
                    game_current_input.*.jump_action.is_pressed = false;
                    game_current_input.*.select_action.is_pressed = false;
                },
                jumpman_main_c.GLFW_KEY_ENTER => {
                    game_current_input.*.select_action.is_pressed = false;
                },
                jumpman_main_c.GLFW_KEY_TAB => {
                    game_current_input.*.slowmo_action.is_pressed = false;
                },
                else => {},
            }

            // Modifier keys
            if (mods & jumpman_main_c.GLFW_MOD_CONTROL == 0) {
                game_current_input.*.jump_action.is_pressed = false;
                game_current_input.*.select_action.is_pressed = false;
            }

            if (mods & jumpman_main_c.GLFW_MOD_ALT == 0) {
                game_current_input.*.attack_action.is_pressed = false;
            }

            // Bound keys
            if (key == g_key_bindings[0]) {
                game_current_input.*.move_up_action.is_pressed = false;
            }

            if (key == g_key_bindings[1]) {
                game_current_input.*.move_down_action.is_pressed = false;
            }

            if (key == g_key_bindings[2]) {
                game_current_input.*.move_left_action.is_pressed = false;
            }

            if (key == g_key_bindings[3]) {
                game_current_input.*.move_right_action.is_pressed = false;
            }

            if (key == g_key_bindings[4]) {
                game_current_input.*.jump_action.is_pressed = false;
                game_current_input.*.select_action.is_pressed = false;
            }

            if (key == g_key_bindings[5]) {
                game_current_input.*.attack_action.is_pressed = false;
            }

            g_last_key_pressed = key;
        },
        else => {},
    }
}

fn MouseButtonCallback(window: ?*jumpman_main_c.GLFWwindow, button: c_int, action: c_int, _: c_int) callconv(.C) void {
    const game_state: ?*GameState = @ptrCast(@alignCast(jumpman_main_c.glfwGetWindowUserPointer(window)));
    const game_current_input = &game_state.?.*.current_input;

    switch (action) {
        jumpman_main_c.GLFW_PRESS => {
            if (button == jumpman_main_c.GLFW_MOUSE_BUTTON_LEFT) {
                game_current_input.*.cursor_select_action.is_pressed = true;
            }
        },
        jumpman_main_c.GLFW_RELEASE => {
            if (button == jumpman_main_c.GLFW_MOUSE_BUTTON_LEFT) {
                game_current_input.*.cursor_select_action.is_pressed = false;
            }
        },
        else => {},
    }
}

fn CursorEnterCallback(window: ?*jumpman_main_c.GLFWwindow, is_entering: c_int) callconv(.C) void {
    const game_state: ?*GameState = @ptrCast(@alignCast(jumpman_main_c.glfwGetWindowUserPointer(window)));
    const game_current_input = &game_state.?.*.current_input; // TODO: Does this just panic if it's null?
    game_current_input.*.cursor_is_on_screen = is_entering != 0; // TODO: Does this get wiped out every frame?
}

fn WindowFocusCallback(_: ?*jumpman_main_c.GLFWwindow, is_focused: c_int) callconv(.C) void {
    if (is_focused != 0) {
        g_game_is_frozen = false;
        jumpman_main_c.Reset3d();
    } else {
        g_game_is_frozen = true;
    }
}

fn WindowSizeCallback(_: ?*jumpman_main_c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    if (!g_fullscreen_is_enabled) {
        g_window_resolution_x = width;
        g_window_resolution_y = height;
        SaveSettings();
    }
}

fn FramebufferSizeCallback(_: ?*jumpman_main_c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    jumpman_main_c.ResizeViewport(width, height);
}

fn GetInput(game_current_input: *jumpman_main_c.GameInput, game_prev_input: *jumpman_main_c.GameInput) void {
    // TODO: Move this over before this checkin
    // TODO: Dead zone?
    var i: c_int = jumpman_main_c.GLFW_JOYSTICK_1;
    while (i <= jumpman_main_c.GLFW_JOYSTICK_LAST) : (i += 1) {
        if (jumpman_main_c.glfwJoystickPresent(i) == jumpman_main_c.GLFW_TRUE) {
            var axis_count: c_int = undefined;
            const axis_values: [*]const f32 = jumpman_main_c.glfwGetJoystickAxes(i, &axis_count);

            if (axis_count > 0) {
                if (axis_values[0] <= -0.5) {
                    game_current_input.*.move_left_action.is_pressed = true;
                }

                if (axis_values[0] >= 0.5) {
                    game_current_input.*.move_right_action.is_pressed = true;
                }
            }

            if (axis_count > 1) {
                if (axis_values[1] <= -0.5) {
                    game_current_input.*.move_up_action.is_pressed = true;
                }

                if (axis_values[1] >= 0.5) {
                    game_current_input.*.move_down_action.is_pressed = true;
                }
            }

            var button_count: c_int = undefined;
            const button_values: [*]const u8 = jumpman_main_c.glfwGetJoystickButtons(jumpman_main_c.GLFW_JOYSTICK_1, &button_count);

            // Face buttons - PS4 values
            if (button_count > 1 and button_values[1] == jumpman_main_c.GLFW_PRESS) {
                game_current_input.*.jump_action.is_pressed = true;
            }

            if (button_count > 0 and button_values[0] == jumpman_main_c.GLFW_PRESS) {
                game_current_input.*.attack_action.is_pressed = true;
            }

            // D-Pad buttons - PS4 values
            // TODO: Need to map per controller type?
            if (button_count > 14 and button_values[14] == jumpman_main_c.GLFW_PRESS) {
                game_current_input.*.move_up_action.is_pressed = true;
            }

            if (button_count > 15 and button_values[15] == jumpman_main_c.GLFW_PRESS) {
                game_current_input.*.move_right_action.is_pressed = true;
            }

            if (button_count > 16 and button_values[16] == jumpman_main_c.GLFW_PRESS) {
                game_current_input.*.move_down_action.is_pressed = true;
            }

            if (button_count > 17 and button_values[17] == jumpman_main_c.GLFW_PRESS) {
                game_current_input.*.move_left_action.is_pressed = true;
            }
        }
    }

    var cursor_pos_x: f64 = undefined;
    var cursor_pos_y: f64 = undefined;
    jumpman_main_c.glfwGetCursorPos(g_main_window, &cursor_pos_x, &cursor_pos_y);

    var cursor_pos_x_f: f32 = @floatCast(cursor_pos_x);
    var cursor_pos_y_f: f32 = @floatCast(cursor_pos_y);
    jumpman_main_c.GetViewportMousePos(&cursor_pos_x_f, &cursor_pos_y_f);

    game_current_input.*.cursor_position.x = cursor_pos_x_f;
    game_current_input.*.cursor_position.y = cursor_pos_y_f;

    game_current_input.*.move_left_action.just_pressed = game_current_input.*.move_left_action.is_pressed and !game_prev_input.*.move_left_action.is_pressed;
    game_current_input.*.move_right_action.just_pressed = game_current_input.*.move_right_action.is_pressed and !game_prev_input.*.move_right_action.is_pressed;
    game_current_input.*.move_down_action.just_pressed = game_current_input.*.move_down_action.is_pressed and !game_prev_input.*.move_down_action.is_pressed;
    game_current_input.*.move_up_action.just_pressed = game_current_input.*.move_up_action.is_pressed and !game_prev_input.*.move_up_action.is_pressed;
    game_current_input.*.jump_action.just_pressed = game_current_input.*.jump_action.is_pressed and !game_prev_input.*.jump_action.is_pressed;
    game_current_input.*.attack_action.just_pressed = game_current_input.*.attack_action.is_pressed and !game_prev_input.*.attack_action.is_pressed;
    game_current_input.*.select_action.just_pressed = game_current_input.*.select_action.is_pressed and !game_prev_input.*.select_action.is_pressed;
    game_current_input.*.slowmo_action.just_pressed = game_current_input.*.slowmo_action.is_pressed and !game_prev_input.*.slowmo_action.is_pressed;
    game_current_input.*.debug_action.just_pressed = game_current_input.*.debug_action.is_pressed and !game_prev_input.*.debug_action.is_pressed;
    game_current_input.*.cheat_action.just_pressed = game_current_input.*.cheat_action.is_pressed and !game_prev_input.*.cheat_action.is_pressed;
    game_current_input.*.cursor_select_action.just_pressed = game_current_input.*.cursor_select_action.is_pressed and !game_prev_input.*.cursor_select_action.is_pressed;
}

export fn IsGameFrozen() bool {
    return g_game_is_frozen;
}

export fn GetCurrentFps() i32 {
    return g_current_fps;
}

export fn GetCurrentMaxUpdateFrameTime() f64 {
    return g_current_max_update_frame_time;
}

export fn GetCurrentMaxDrawAndSwapFrameTime() f64 {
    return g_current_max_draw_and_swap_frame_time;
}

export fn GetLastKeyPressed() i32 {
    return g_last_key_pressed;
}

export fn GetKeyBinding(binding_index: usize) i32 {
    return g_key_bindings[binding_index];
}

export fn SetKeyBinding(binding_index: usize, value: i32) void {
    g_key_bindings[binding_index] = value;
}

export fn SaveSettings() void {
    g_save_settings_is_queued = true;
}

pub fn main() u8 {
    const arguments = std.os.argv;
    var game_state = std.mem.zeroes(GameState);

    if (!jumpman_main_c.GetWorkingDirectoryPath(&g_game_base_path)) { // TODO: Zig os substitute?
        return jumpman_main_c.EXIT_FAILURE;
    }

    var sound_is_initially_enabled: bool = false;
    var music_is_initially_enabled: bool = false;

    if (!LoadSettings(&sound_is_initially_enabled, &music_is_initially_enabled)) {
        return jumpman_main_c.EXIT_FAILURE;
    }

    _ = jumpman_main_c.glfwSetErrorCallback(&ErrorCallback);

    if (jumpman_main_c.glfwInit() == 0) {
        return jumpman_main_c.EXIT_FAILURE;
    }

    jumpman_main_c.glfwWindowHint(jumpman_main_c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    jumpman_main_c.glfwWindowHint(jumpman_main_c.GLFW_CONTEXT_VERSION_MINOR, 3);
    jumpman_main_c.glfwWindowHint(jumpman_main_c.GLFW_OPENGL_FORWARD_COMPAT, jumpman_main_c.GL_TRUE);
    jumpman_main_c.glfwWindowHint(jumpman_main_c.GLFW_OPENGL_PROFILE, jumpman_main_c.GLFW_OPENGL_CORE_PROFILE);

    // Creating as window first to get OS default positioning, but setting correct dimensions for first time creation
    // Will revert back to selected window resolution instead of fullscreen res, even if started in fullscreen
    var target_width: i32 = g_window_resolution_x;
    var target_height: i32 = g_window_resolution_y;

    g_main_window = jumpman_main_c.glfwCreateWindow(target_width, target_height, "Jumpman Zero", null, null);

    if (g_main_window == null) {
        jumpman_main_c.glfwTerminate();
        return jumpman_main_c.EXIT_FAILURE;
    }

    jumpman_main_c.glfwSetWindowUserPointer(g_main_window, &game_state);

    // Now backup window position before switching to fullscreen (if fullscreen dims, will be in upper left, but not offscreen)
    jumpman_main_c.glfwGetWindowPos(g_main_window, &g_window_pos_x_backup, &g_window_pos_y_backup);

    if (g_fullscreen_is_enabled) {
        SetFullscreen(true, &target_width, &target_height);
    }

    jumpman_main_c.ResizeViewport(target_width, target_height); // Callback not set up yet

    jumpman_main_c.glfwSetWindowSizeLimits(g_main_window, 320, 240, jumpman_main_c.GLFW_DONT_CARE, jumpman_main_c.GLFW_DONT_CARE);
    _ = jumpman_main_c.glfwSetWindowFocusCallback(g_main_window, &WindowFocusCallback);
    _ = jumpman_main_c.glfwSetWindowSizeCallback(g_main_window, &WindowSizeCallback);
    _ = jumpman_main_c.glfwSetFramebufferSizeCallback(g_main_window, &FramebufferSizeCallback);
    _ = jumpman_main_c.glfwSetKeyCallback(g_main_window, &KeyCallback);
    _ = jumpman_main_c.glfwSetMouseButtonCallback(g_main_window, &MouseButtonCallback);
    _ = jumpman_main_c.glfwSetCursorEnterCallback(g_main_window, &CursorEnterCallback);
    jumpman_main_c.glfwMakeContextCurrent(g_main_window);

    if (jumpman_main_c.glfwExtensionSupported("WGL_EXT_swap_control_tear") == jumpman_main_c.GLFW_TRUE or
        jumpman_main_c.glfwExtensionSupported("GLX_EXT_swap_control_tear") == jumpman_main_c.GLFW_TRUE)
    {
        jumpman_main_c.glfwSwapInterval(-1);
    } else {
        jumpman_main_c.glfwSwapInterval(1);
    }

    _ = jumpman_main_c.gladLoadGLLoader(@as(jumpman_main_c.GLADloadproc, @ptrCast(@alignCast(&jumpman_main_c.glfwGetProcAddress))));

    g_game_is_frozen = false;

    if (!jumpman_main_c.Init3D()) {
        // TODO: Proper error handling
        return jumpman_main_c.EXIT_FAILURE;
    }

    if (jumpman_main_c.InitSoundBuffer()) {
        if (!jumpman_main_c.InitMusic()) {
            music_is_initially_enabled = false;
        }

        if (!jumpman_main_c.InitSound()) {
            sound_is_initially_enabled = false;
        }
    } else {
        music_is_initially_enabled = false;
        sound_is_initially_enabled = false;
    }

    if (music_is_initially_enabled) {
        jumpman_main_c.SetIsMusicEnabled(true);
    }

    if (sound_is_initially_enabled) {
        jumpman_main_c.SetIsSoundEnabled(true);
    }

    var previous_frame_time: f64 = jumpman_main_c.glfwGetTime();
    jumpman_main_c.srand(@intFromFloat(previous_frame_time)); // TODO: Seed zig's random instead?
    var previous_update_time: f64 = previous_frame_time;

    var is_debug_init: bool = false;
    if (arguments.len > 1) {
        const arg_length: usize = std.mem.len(arguments[1]);
        if (arg_length > 4 and std.mem.eql(u8, arguments[1][arg_length - 4 .. arg_length], ".lua")) { // TODO: Check this is correct and see if there's something more idiomatic
            //if (arg_length > 4 and arguments[1][arg_length - 4] == '.' and arguments[1][arg_length - 3] == 'l' and arguments[1][arg_length - 2] == 'u' and arguments[1][arg_length - 1] == 'a') { // TODO: If string ends with ".lua"
            jumpman_main_c.InitGameDebugScript(&g_game_base_path, arguments[1]);
            is_debug_init = true;
        } else if (arg_length > 0) {
            jumpman_main_c.InitGameDebugLevel(&g_game_base_path, arguments[1]);
            is_debug_init = true;
        }
    }

    if (!is_debug_init) {
        jumpman_main_c.InitGameNormal(&g_game_base_path);
    }

    var frame_count_since_last_perf_update: i32 = 0;
    var last_perf_update_time: f64 = previous_frame_time;
    var game_prev_input: jumpman_main_c.GameInput = game_state.current_input;

    while (jumpman_main_c.glfwWindowShouldClose(g_main_window) == 0) {
        const current_time: f64 = jumpman_main_c.glfwGetTime();
        const current_draw_time: f64 = current_time;
        const current_update_duration: f64 = if (game_state.current_input.slowmo_action.is_pressed) kSECONDS_PER_FRAME_SLOWMO else kSECONDS_PER_FRAME;
        const time_scale: f64 = if (g_game_is_frozen)
            0.0
        else if (game_state.current_input.slowmo_action.is_pressed)
            1.0 / kSLOWMO_RATIO
        else
            1.0;

        if (current_time - previous_frame_time > current_update_duration) {
            previous_frame_time = current_time;
            GetInput(&game_state.current_input, &game_prev_input);
            var processed_input: jumpman_main_c.GameInput = game_state.current_input;

            const update_begin_time = jumpman_main_c.glfwGetTime();
            jumpman_main_c.UpdateGame(&processed_input, kSECONDS_PER_FRAME);
            const update_end_time = jumpman_main_c.glfwGetTime();
            previous_update_time = update_end_time;

            game_prev_input = game_state.current_input;

            g_update_frame_times[g_update_frame_times_current_index] = update_end_time - update_begin_time;
            g_update_frame_times_current_index += 1;

            if (g_update_frame_times_current_index >= g_update_frame_times.len) {
                g_update_frame_times_current_index = 0;
            }
        }

        frame_count_since_last_perf_update += 1;

        if ((current_time - last_perf_update_time) >= 1.0) {
            last_perf_update_time = current_time;
            g_current_fps = frame_count_since_last_perf_update;

            if (g_current_fps > 999) {
                g_current_fps = 999;
            }

            frame_count_since_last_perf_update = 0;
            var max_frame_time: f64 = 0.0;

            {
                var i: usize = 0;
                while (i < kFRAMES_PER_SECOND) : (i += 1) {
                    if (g_update_frame_times[i] > max_frame_time) {
                        max_frame_time = g_update_frame_times[i];
                    }
                }
            }

            g_current_max_update_frame_time = max_frame_time;

            g_current_max_draw_and_swap_frame_time = 0.0; // Updates continuously
        }

        const draw_and_swap_begin_time = jumpman_main_c.glfwGetTime();
        jumpman_main_c.DrawGame(kSECONDS_PER_FRAME, current_draw_time - previous_update_time, time_scale);
        jumpman_main_c.glfwSwapBuffers(g_main_window);
        const draw_and_swap_end_time = jumpman_main_c.glfwGetTime();
        const current_draw_and_swap_frame_time = draw_and_swap_end_time - draw_and_swap_begin_time;

        if (current_draw_and_swap_frame_time > g_current_max_draw_and_swap_frame_time) {
            g_current_max_draw_and_swap_frame_time = current_draw_and_swap_frame_time;
        }

        jumpman_main_c.glfwPollEvents();

        if (g_save_settings_is_queued) {
            if (!save_settings()) {
                // TODO: debug_log("Failed to save config file\n");
            }

            g_save_settings_is_queued = false;
        }
    }

    return jumpman_main_c.EXIT_SUCCESS;
}
