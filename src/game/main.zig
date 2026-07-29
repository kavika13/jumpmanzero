const std = @import("std");
const basic_3d = @import("basic_3d.zig");
const jumpman = @import("jumpman.zig");
const music = @import("music.zig");
const sound = @import("sound.zig");
const sound_buffer = @import("sound_buffer.zig");
const glad_c = @import("glad_c");
const glfw_c = @import("glfw_c");

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

var g_main_window: ?*glfw_c.GLFWwindow = null;

const GameState = struct {
    current_input: jumpman.GameInput,
};

fn parseIntOrDefault(comptime T: type, line: ?[]const u8, default: T) T {
    const trimmed_line = if (line) |l| std.mem.trim(u8, l, "\t\r ") else return default;
    return std.fmt.parseInt(T, trimmed_line, 10) catch default;
}

fn loadSettings(sound_is_initially_enabled: *bool, music_is_initially_enabled: *bool, io: std.Io, gpa: std.mem.Allocator) !void {
    // Defaults match JumpmanAssets/data/settings.dat so a missing writable settings
    // file (pack-boot cwd is zig-out/) still has valid key bindings
    // and does not leave sound/music off unexpectedly.
    const default_keys = [_]i32{ 'I', 'K', 'J', 'L', 'E', 'R' };

    const sData = std.Io.Dir.cwd().readFileAlloc(io, "data/settings.dat", gpa, .unlimited) catch |err|
        switch (err) {
            error.FileNotFound => null,
            else => return err,
        };
    defer if (sData) |d| gpa.free(d);
    const settings_text = sData orelse "";

    var file_lines = std.mem.splitScalar(u8, settings_text, '\n');
    for (0..6) |key_index| {
        g_key_bindings[key_index] = parseIntOrDefault(i32, file_lines.next(), default_keys[key_index]);
    }
    sound_is_initially_enabled.* = parseIntOrDefault(i32, file_lines.next(), 1) != 0;
    music_is_initially_enabled.* = parseIntOrDefault(i32, file_lines.next(), 1) != 0;
    g_fullscreen_is_enabled = parseIntOrDefault(u8, file_lines.next(), @intFromBool(kFULLSCREEN_IS_ENABLED_DEFAULT)) != 0;
    g_window_resolution_x = parseIntOrDefault(i32, file_lines.next(), kWINDOW_RESOLUTION_DEFAULT_X);

    if (g_window_resolution_x < kWINDOW_RESOLUTION_MIN_X) {
        g_window_resolution_x = kWINDOW_RESOLUTION_MIN_X;
    }

    g_window_resolution_y = parseIntOrDefault(i32, file_lines.next(), kWINDOW_RESOLUTION_DEFAULT_Y);

    if (g_window_resolution_y < kWINDOW_RESOLUTION_MIN_Y) {
        g_window_resolution_y = kWINDOW_RESOLUTION_MIN_Y;
    }
}

fn saveSettingsImpl(io: std.Io) bool {
    var sFileBuffer = std.mem.zeroes([300]u8);
    const data_to_output = std.fmt.bufPrintZ(
        &sFileBuffer,
        "{}\r\n{}\r\n{}\r\n{}\r\n{}\r\n{}\r\n{}\r\n{}\r\n{}\r\n{}\r\n{}",
        .{
            g_key_bindings[0],
            g_key_bindings[1],
            g_key_bindings[2],
            g_key_bindings[3],
            g_key_bindings[4],
            g_key_bindings[5],
            @intFromBool(sound.getIsSoundEnabled()),
            @intFromBool(music.getIsMusicEnabled()),
            @intFromBool(g_fullscreen_is_enabled),
            g_window_resolution_x,
            g_window_resolution_y,
        },
    ) catch {
        return false;
    };

    // Writable overlay beside packs (cwd = install prefix); create data/ if needed.
    std.Io.Dir.cwd().createDirPath(io, "data") catch return false;
    const file = std.Io.Dir.cwd().createFile(io, "data/settings.dat", .{}) catch return false;
    defer file.close(io);
    file.writeStreamingAll(io, data_to_output) catch return false;

    return true;
}

fn setFullscreen(enable_fullscreen: bool, new_width: ?*i32, new_height: ?*i32) void {
    g_fullscreen_is_enabled = enable_fullscreen;

    var monitor: ?*glfw_c.GLFWmonitor = null;
    var target_pos_x: i32 = g_window_pos_x_backup;
    var target_pos_y: i32 = g_window_pos_y_backup;
    var target_width: i32 = g_window_resolution_x;
    var target_height: i32 = g_window_resolution_y;

    if (enable_fullscreen) {
        monitor = glfw_c.glfwGetPrimaryMonitor();

        glfw_c.glfwGetWindowPos(g_main_window, &g_window_pos_x_backup, &g_window_pos_y_backup);

        const mode: ?*const glfw_c.GLFWvidmode = glfw_c.glfwGetVideoMode(monitor);
        glfw_c.glfwWindowHint(glfw_c.GLFW_RED_BITS, mode.?.*.redBits);
        glfw_c.glfwWindowHint(glfw_c.GLFW_GREEN_BITS, mode.?.*.greenBits);
        glfw_c.glfwWindowHint(glfw_c.GLFW_BLUE_BITS, mode.?.*.blueBits);
        glfw_c.glfwWindowHint(glfw_c.GLFW_REFRESH_RATE, mode.?.*.refreshRate);

        target_pos_x = 0;
        target_pos_y = 0;
        target_width = mode.?.*.width;
        target_height = mode.?.*.height;
    }

    glfw_c.glfwSetWindowMonitor(g_main_window, monitor, target_pos_x, target_pos_y, target_width, target_height, glfw_c.GLFW_DONT_CARE);

    if (enable_fullscreen) {
        glfw_c.glfwSetInputMode(g_main_window, glfw_c.GLFW_CURSOR, glfw_c.GLFW_CURSOR_HIDDEN);
    } else {
        glfw_c.glfwSetInputMode(g_main_window, glfw_c.GLFW_CURSOR, glfw_c.GLFW_CURSOR_NORMAL);
    }

    if (new_width != null) {
        new_width.?.* = target_width;
    }

    if (new_height != null) {
        new_height.?.* = target_height;
    }

    saveSettings();
}

fn errorCallback(_: c_int, description: ?[*:0]const u8) callconv(.c) void {
    std.log.err("Error: {?s}\n", .{description});
}

fn keyCallback(window: ?*glfw_c.GLFWwindow, key: c_int, _: c_int, action: c_int, mods: c_int) callconv(.c) void {
    const game_state: ?*GameState = @ptrCast(@alignCast(glfw_c.glfwGetWindowUserPointer(window)));
    const game_current_input = &game_state.?.*.current_input;

    switch (action) {
        glfw_c.GLFW_PRESS => {
            switch (key) {
                glfw_c.GLFW_KEY_GRAVE_ACCENT => {
                    game_current_input.*.debug_action.is_pressed = true;
                },
                glfw_c.GLFW_KEY_F1 => {
                    game_current_input.*.cheat_action.is_pressed = true;
                },
                glfw_c.GLFW_KEY_UP => {
                    game_current_input.*.move_up_action.is_pressed = true;
                },
                glfw_c.GLFW_KEY_DOWN => {
                    game_current_input.*.move_down_action.is_pressed = true;
                },
                glfw_c.GLFW_KEY_LEFT => {
                    game_current_input.*.move_left_action.is_pressed = true;
                },
                glfw_c.GLFW_KEY_RIGHT => {
                    game_current_input.*.move_right_action.is_pressed = true;
                },
                glfw_c.GLFW_KEY_SPACE => {
                    game_current_input.*.jump_action.is_pressed = true;
                    game_current_input.*.select_action.is_pressed = true;
                },
                glfw_c.GLFW_KEY_ENTER => {
                    if (mods & glfw_c.GLFW_MOD_ALT != 0) {
                        setFullscreen(!g_fullscreen_is_enabled, null, null);
                    } else {
                        game_current_input.*.select_action.is_pressed = true;
                    }
                },
                glfw_c.GLFW_KEY_TAB => {
                    game_current_input.*.slowmo_action.is_pressed = true;
                },
                glfw_c.GLFW_KEY_F11 => {
                    setFullscreen(!g_fullscreen_is_enabled, null, null);
                },
                glfw_c.GLFW_KEY_ESCAPE => {
                    jumpman.ExitGame();
                    glfw_c.glfwSetWindowShouldClose(window, glfw_c.GLFW_TRUE);
                },
                else => {},
            }

            // Modifier keys
            if (mods & glfw_c.GLFW_MOD_CONTROL != 0) {
                game_current_input.*.jump_action.is_pressed = true;
                game_current_input.*.select_action.is_pressed = true;
            }

            if (mods & glfw_c.GLFW_MOD_ALT != 0) {
                if (key != glfw_c.GLFW_KEY_ENTER) { // Ignore for alt + enter combo
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
        glfw_c.GLFW_RELEASE => {
            switch (key) {
                glfw_c.GLFW_KEY_GRAVE_ACCENT => {
                    game_current_input.*.debug_action.is_pressed = false;
                },
                glfw_c.GLFW_KEY_F1 => {
                    game_current_input.*.cheat_action.is_pressed = false;
                },
                glfw_c.GLFW_KEY_UP => {
                    game_current_input.*.move_up_action.is_pressed = false;
                },
                glfw_c.GLFW_KEY_DOWN => {
                    game_current_input.*.move_down_action.is_pressed = false;
                },
                glfw_c.GLFW_KEY_LEFT => {
                    game_current_input.*.move_left_action.is_pressed = false;
                },
                glfw_c.GLFW_KEY_RIGHT => {
                    game_current_input.*.move_right_action.is_pressed = false;
                },
                glfw_c.GLFW_KEY_SPACE => {
                    game_current_input.*.jump_action.is_pressed = false;
                    game_current_input.*.select_action.is_pressed = false;
                },
                glfw_c.GLFW_KEY_ENTER => {
                    game_current_input.*.select_action.is_pressed = false;
                },
                glfw_c.GLFW_KEY_TAB => {
                    game_current_input.*.slowmo_action.is_pressed = false;
                },
                else => {},
            }

            // Modifier keys
            if (mods & glfw_c.GLFW_MOD_CONTROL == 0) {
                game_current_input.*.jump_action.is_pressed = false;
                game_current_input.*.select_action.is_pressed = false;
            }

            if (mods & glfw_c.GLFW_MOD_ALT == 0) {
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

fn mouseButtonCallback(window: ?*glfw_c.GLFWwindow, button: c_int, action: c_int, _: c_int) callconv(.c) void {
    const game_state: ?*GameState = @ptrCast(@alignCast(glfw_c.glfwGetWindowUserPointer(window)));
    const game_current_input = &game_state.?.*.current_input;

    switch (action) {
        glfw_c.GLFW_PRESS => {
            if (button == glfw_c.GLFW_MOUSE_BUTTON_LEFT) {
                game_current_input.*.cursor_select_action.is_pressed = true;
            }
        },
        glfw_c.GLFW_RELEASE => {
            if (button == glfw_c.GLFW_MOUSE_BUTTON_LEFT) {
                game_current_input.*.cursor_select_action.is_pressed = false;
            }
        },
        else => {},
    }
}

fn cursorEnterCallback(window: ?*glfw_c.GLFWwindow, is_entering: c_int) callconv(.c) void {
    const game_state: ?*GameState = @ptrCast(@alignCast(glfw_c.glfwGetWindowUserPointer(window)));
    const game_current_input = &game_state.?.*.current_input; // TODO: Does this just panic if it's null?
    game_current_input.*.cursor_is_on_screen = is_entering != 0; // TODO: Does this get wiped out every frame?
}

fn windowFocusCallback(_: ?*glfw_c.GLFWwindow, is_focused: c_int) callconv(.c) void {
    if (is_focused != 0) {
        g_game_is_frozen = false;
        basic_3d.reset3d();
    } else {
        g_game_is_frozen = true;
    }
}

fn windowSizeCallback(_: ?*glfw_c.GLFWwindow, width: c_int, height: c_int) callconv(.c) void {
    if (!g_fullscreen_is_enabled) {
        g_window_resolution_x = width;
        g_window_resolution_y = height;
        saveSettings();
    }
}

fn framebufferSizeCallback(_: ?*glfw_c.GLFWwindow, width: c_int, height: c_int) callconv(.c) void {
    basic_3d.resizeViewport(width, height);
}

fn getInput(game_current_input: *jumpman.GameInput, game_prev_input: *jumpman.GameInput) void {
    // TODO: Move this over before this checkin
    // TODO: Dead zone?
    var i: c_int = glfw_c.GLFW_JOYSTICK_1;
    while (i <= glfw_c.GLFW_JOYSTICK_LAST) : (i += 1) {
        if (glfw_c.glfwJoystickPresent(i) == glfw_c.GLFW_TRUE) {
            var axis_count: c_int = undefined;
            const axis_values: [*]const f32 = glfw_c.glfwGetJoystickAxes(i, &axis_count);

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
            const button_values: [*]const u8 = glfw_c.glfwGetJoystickButtons(glfw_c.GLFW_JOYSTICK_1, &button_count);

            // Face buttons - PS4 values
            if (button_count > 1 and button_values[1] == glfw_c.GLFW_PRESS) {
                game_current_input.*.jump_action.is_pressed = true;
            }

            if (button_count > 0 and button_values[0] == glfw_c.GLFW_PRESS) {
                game_current_input.*.attack_action.is_pressed = true;
            }

            // D-Pad buttons - PS4 values
            // TODO: Need to map per controller type?
            if (button_count > 14 and button_values[14] == glfw_c.GLFW_PRESS) {
                game_current_input.*.move_up_action.is_pressed = true;
            }

            if (button_count > 15 and button_values[15] == glfw_c.GLFW_PRESS) {
                game_current_input.*.move_right_action.is_pressed = true;
            }

            if (button_count > 16 and button_values[16] == glfw_c.GLFW_PRESS) {
                game_current_input.*.move_down_action.is_pressed = true;
            }

            if (button_count > 17 and button_values[17] == glfw_c.GLFW_PRESS) {
                game_current_input.*.move_left_action.is_pressed = true;
            }
        }
    }

    var cursor_pos_x: f64 = undefined;
    var cursor_pos_y: f64 = undefined;
    glfw_c.glfwGetCursorPos(g_main_window, &cursor_pos_x, &cursor_pos_y);

    var cursor_pos_x_f: f32 = @floatCast(cursor_pos_x);
    var cursor_pos_y_f: f32 = @floatCast(cursor_pos_y);
    basic_3d.getViewportMousePos(&cursor_pos_x_f, &cursor_pos_y_f);

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

pub fn isGameFrozen() bool {
    return g_game_is_frozen;
}

pub fn getCurrentFps() i32 {
    return g_current_fps;
}

pub fn getCurrentMaxUpdateFrameTime() f64 {
    return g_current_max_update_frame_time;
}

pub fn getCurrentMaxDrawAndSwapFrameTime() f64 {
    return g_current_max_draw_and_swap_frame_time;
}

pub fn getLastKeyPressed() i32 {
    return g_last_key_pressed;
}

pub fn getKeyBinding(binding_index: usize) i32 {
    return g_key_bindings[binding_index];
}

pub fn setKeyBinding(binding_index: usize, value: i32) void {
    g_key_bindings[binding_index] = value;
}

pub fn saveSettings() void {
    g_save_settings_is_queued = true;
}

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();

    const arguments = try init.minimal.args.toSlice(arena);
    var game_state = std.mem.zeroes(GameState);

    var sound_is_initially_enabled: bool = false;
    var music_is_initially_enabled: bool = false;

    try loadSettings(&sound_is_initially_enabled, &music_is_initially_enabled, init.io, init.gpa);

    _ = glfw_c.glfwSetErrorCallback(&errorCallback);

    if (glfw_c.glfwInit() == 0) {
        return error.InitGlfwFailed;
    }

    glfw_c.glfwWindowHint(glfw_c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfw_c.glfwWindowHint(glfw_c.GLFW_CONTEXT_VERSION_MINOR, 3);
    glfw_c.glfwWindowHint(glfw_c.GLFW_OPENGL_FORWARD_COMPAT, glad_c.GL_TRUE);
    glfw_c.glfwWindowHint(glfw_c.GLFW_OPENGL_PROFILE, glfw_c.GLFW_OPENGL_CORE_PROFILE);

    // Creating as window first to get OS default positioning, but setting correct dimensions for first time creation
    // Will revert back to selected window resolution instead of fullscreen res, even if started in fullscreen
    var target_width: i32 = g_window_resolution_x;
    var target_height: i32 = g_window_resolution_y;

    g_main_window = glfw_c.glfwCreateWindow(target_width, target_height, "Jumpman Zero", null, null);

    if (g_main_window == null) {
        glfw_c.glfwTerminate();
        return error.WindowCreationFailed;
    }

    glfw_c.glfwSetWindowUserPointer(g_main_window, &game_state);

    // Now backup window position before switching to fullscreen (if fullscreen dims, will be in upper left, but not offscreen)
    glfw_c.glfwGetWindowPos(g_main_window, &g_window_pos_x_backup, &g_window_pos_y_backup);

    if (g_fullscreen_is_enabled) {
        setFullscreen(true, &target_width, &target_height);
    }

    basic_3d.resizeViewport(target_width, target_height);

    glfw_c.glfwSetWindowSizeLimits(g_main_window, 320, 240, glfw_c.GLFW_DONT_CARE, glfw_c.GLFW_DONT_CARE);
    _ = glfw_c.glfwSetWindowFocusCallback(g_main_window, &windowFocusCallback);
    _ = glfw_c.glfwSetWindowSizeCallback(g_main_window, &windowSizeCallback);
    _ = glfw_c.glfwSetFramebufferSizeCallback(g_main_window, &framebufferSizeCallback);
    _ = glfw_c.glfwSetKeyCallback(g_main_window, &keyCallback);
    _ = glfw_c.glfwSetMouseButtonCallback(g_main_window, &mouseButtonCallback);
    _ = glfw_c.glfwSetCursorEnterCallback(g_main_window, &cursorEnterCallback);
    glfw_c.glfwMakeContextCurrent(g_main_window);

    if (glfw_c.glfwExtensionSupported("WGL_EXT_swap_control_tear") == glfw_c.GLFW_TRUE or
        glfw_c.glfwExtensionSupported("GLX_EXT_swap_control_tear") == glfw_c.GLFW_TRUE)
    {
        glfw_c.glfwSwapInterval(-1);
    } else {
        glfw_c.glfwSwapInterval(1);
    }

    _ = glad_c.gladLoadGLLoader(@as(glad_c.GLADloadproc, @ptrCast(@alignCast(&glfw_c.glfwGetProcAddress))));

    g_game_is_frozen = false;

    jumpman.initZig(init.io, init.gpa);

    if (!jumpman.Init3D()) {
        return error.Init3DFailed;
    }

    const init_sound_buffer_succeeded = sound_buffer.init(init.gpa);
    defer if (init_sound_buffer_succeeded) sound_buffer.cleanup();
    if (init_sound_buffer_succeeded) {
        if (!music.initMusic()) {
            music_is_initially_enabled = false;
        }

        if (!sound.init()) {
            sound_is_initially_enabled = false;
        }
    } else {
        music_is_initially_enabled = false;
        sound_is_initially_enabled = false;
    }

    if (music_is_initially_enabled) {
        music.setIsMusicEnabled(true);
    }

    if (sound_is_initially_enabled) {
        sound.setIsSoundEnabled(true);
    }

    var previous_frame_time: f64 = glfw_c.glfwGetTime();
    glad_c.srand(@intFromFloat(previous_frame_time)); // TODO: Seed zig's random instead?
    var previous_update_time: f64 = previous_frame_time;

    // Debug launch:
    //   jumpmanzero level7       - level via main.lua (MenuLogic + begin/commit wrap)
    //   jumpmanzero level7.lua   - same (`.lua` is stripped; levels are not host scripts)
    //   jumpmanzero --script test.lua - load a standalone host script as the main module
    var is_debug_init: bool = false;
    if (arguments.len > 1) {
        if (std.mem.eql(u8, arguments[1], "--script")) {
            if (arguments.len < 3 or arguments[2].len == 0) {
                std.log.err("--script requires a filename under data/ (e.g. test.lua)", .{});
                return error.InvalidArgs;
            }
            const script = try arena.dupeZ(u8, arguments[2]);
            jumpman.InitGameDebugScript(script);
            is_debug_init = true;
        } else if (arguments[1].len > 0) {
            const arg = arguments[1];
            const level_name = if (std.mem.endsWith(u8, arg, ".lua"))
                arg[0 .. arg.len - ".lua".len]
            else
                arg;
            const level_z = try arena.dupeZ(u8, level_name);
            jumpman.InitGameDebugLevel(level_z);
            is_debug_init = true;
        }
    }

    if (!is_debug_init) {
        jumpman.InitGameNormal();
    }

    var frame_count_since_last_perf_update: i32 = 0;
    var last_perf_update_time: f64 = previous_frame_time;
    var game_prev_input: jumpman.GameInput = game_state.current_input;

    while (glfw_c.glfwWindowShouldClose(g_main_window) == 0) {
        const current_time: f64 = glfw_c.glfwGetTime();
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
            getInput(&game_state.current_input, &game_prev_input);
            const processed_input: jumpman.GameInput = game_state.current_input;

            const update_begin_time = glfw_c.glfwGetTime();
            jumpman.UpdateGame(&processed_input, kSECONDS_PER_FRAME);
            const update_end_time = glfw_c.glfwGetTime();
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

        const draw_and_swap_begin_time = glfw_c.glfwGetTime();
        jumpman.DrawGame(kSECONDS_PER_FRAME, current_draw_time - previous_update_time, time_scale);
        glfw_c.glfwSwapBuffers(g_main_window);
        const draw_and_swap_end_time = glfw_c.glfwGetTime();
        const current_draw_and_swap_frame_time = draw_and_swap_end_time - draw_and_swap_begin_time;

        if (current_draw_and_swap_frame_time > g_current_max_draw_and_swap_frame_time) {
            g_current_max_draw_and_swap_frame_time = current_draw_and_swap_frame_time;
        }

        glfw_c.glfwPollEvents();

        if (g_save_settings_is_queued) {
            if (!saveSettingsImpl(init.io)) {
                std.log.err("Failed to save config file\n", .{});
            }

            g_save_settings_is_queued = false;
        }
    }
}
