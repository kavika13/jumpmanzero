#include <direct.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include "Basic3d.h"
#include "Input.h"
#include "Jumpman.h"
#include "Main.h"
#include "Music.h"
#include "Sound.h"
#include "SoundBuffer.h"
#include "Utilities.h"

#define kFULLSCREEN_IS_ENABLED_DEFAULT false
#define kWINDOW_RESOLUTION_DEFAULT_X 640
#define kWINDOW_RESOLUTION_DEFAULT_Y 480
#define kWINDOW_RESOLUTION_MIN_X 320
#define kWINDOW_RESOLUTION_MIN_Y 240
#define kSOUND_EFFECTS_ARE_ENABLED_DEFAULT false
#define kMUSIC_IS_ENABLED_DEFAULT false

static const double kSECONDS_PER_FRAME = 1.0 / 40.0;

// TODO: All these externally visible variables should be static. Maybe pass in state?
bool g_debug_is_enabled = false;

bool g_game_is_frozen;
long g_current_fps;

char g_game_base_path[300];  // TODO: Maybe expose path util?

bool g_sound_effects_are_enabled = kSOUND_EFFECTS_ARE_ENABLED_DEFAULT;
bool g_music_is_enabled = kMUSIC_IS_ENABLED_DEFAULT;
bool g_show_fps_is_enabled = false;

static bool g_fullscreen_is_enabled = kFULLSCREEN_IS_ENABLED_DEFAULT;
static int g_window_resolution_x = kWINDOW_RESOLUTION_DEFAULT_X;
static int g_window_resolution_y = kWINDOW_RESOLUTION_DEFAULT_Y;
static int g_window_pos_x_backup = 0;
static int g_window_pos_y_backup = 0;
static bool g_save_settings_is_queued = false;

static GLFWwindow* g_main_window = NULL;

static bool LoadSettings(GameRawInput* game_raw_input) {
    char sTemp[30];
    int iKey;
    char sFileName[300];

    sprintf_s(sFileName, sizeof(sFileName), "%s\\Data\\Settings.DAT", g_game_base_path);

    char* sData;
    long iLen;
    iLen = FileToString(sFileName, (unsigned char**)(&sData));

    // TODO: Handle file missing case without an error message - should create it and set defaults instead
    if(!iLen) {
        return false;
    }

    iKey = -1;

    while(++iKey < 6) {
        if(GetFileLine(sTemp, sizeof(sTemp), sFileName, iKey)) {
            game_raw_input->key_bindings[iKey] = atoi(sTemp);
        } else {
            game_raw_input->key_bindings[iKey] = 0;
        }
    }

    g_sound_effects_are_enabled = GetFileLine(sTemp, sizeof(sTemp), sFileName, 6)
        ? (atoi(sTemp) ? true : false)
        : false;

    g_music_is_enabled = GetFileLine(sTemp, sizeof(sTemp), sFileName, 7)
        ? (atoi(sTemp) ? true : false)
        : false;

    g_fullscreen_is_enabled = GetFileLine(sTemp, sizeof(sTemp), sFileName, 8)
        ? (atoi(sTemp) ? true : false)
        : false;

    g_window_resolution_x = GetFileLine(sTemp, sizeof(sTemp), sFileName, 9)
        ? atoi(sTemp)
        : kWINDOW_RESOLUTION_DEFAULT_X;

    if(g_window_resolution_x < kWINDOW_RESOLUTION_MIN_X) {
        g_window_resolution_x = kWINDOW_RESOLUTION_MIN_X;
    }

    g_window_resolution_y = GetFileLine(sTemp, sizeof(sTemp), sFileName, 10)
        ? atoi(sTemp)
        : kWINDOW_RESOLUTION_DEFAULT_Y;

    if(g_window_resolution_y < kWINDOW_RESOLUTION_MIN_Y) {
        g_window_resolution_y = kWINDOW_RESOLUTION_MIN_Y;
    }

    return true;
}

static bool SaveSettings_(GameRawInput* game_raw_input) {
    bool success = true;

    char sFile[300];
    sprintf_s(sFile, sizeof(sFile), "%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d",
        game_raw_input->key_bindings[0],
        game_raw_input->key_bindings[1],
        game_raw_input->key_bindings[2],
        game_raw_input->key_bindings[3],
        game_raw_input->key_bindings[4],
        game_raw_input->key_bindings[5],
        g_sound_effects_are_enabled ? 1 : 0,
        g_music_is_enabled ? 1 : 0,
        g_fullscreen_is_enabled ? 1 : 0,
        g_window_resolution_x,
        g_window_resolution_y);

    char sFileName[300];  // TODO: Is path long enough?
    sprintf_s(sFileName, sizeof(sFileName), "%s\\Data\\Settings.dat", g_game_base_path);

    success = StringToFile(sFileName, sFile);

    return success;
}

static void SetFullscreen(bool enable_fullscreen) {
    g_fullscreen_is_enabled = enable_fullscreen;

    GLFWmonitor* monitor = NULL;
    int target_pos_x = g_window_pos_x_backup;
    int target_pos_y = g_window_pos_y_backup;
    int target_width = g_window_resolution_x;
    int target_height = g_window_resolution_y;

    if(enable_fullscreen) {
        monitor = glfwGetPrimaryMonitor();

        glfwGetWindowPos(g_main_window, &g_window_pos_x_backup, &g_window_pos_y_backup);

        const GLFWvidmode* mode = glfwGetVideoMode(monitor);
        glfwWindowHint(GLFW_RED_BITS, mode->redBits);
        glfwWindowHint(GLFW_GREEN_BITS, mode->greenBits);
        glfwWindowHint(GLFW_BLUE_BITS, mode->blueBits);
        glfwWindowHint(GLFW_REFRESH_RATE, mode->refreshRate);

        target_pos_x = 0;
        target_pos_y = 0;
        target_width = mode->width;
        target_height = mode->height;
    }

    glfwSetWindowMonitor(g_main_window, monitor, target_pos_x, target_pos_y, target_width, target_height, 0);

    if(enable_fullscreen) {
        glfwSetInputMode(g_main_window, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);
    } else {
        glfwSetInputMode(g_main_window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
    }

    SaveSettings();
}

static void ErrorCallback(int error, const char* description) {
    fprintf(stderr, "Error: %s\n", description);
}

static void KeyCallback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    GameInput* game_current_input = glfwGetWindowUserPointer(window);

    switch (action) {
        case GLFW_PRESS: {
            switch (key) {
                case GLFW_KEY_GRAVE_ACCENT: {
                    g_show_fps_is_enabled = true;
                    break;
                }
                case GLFW_KEY_UP: {
                    game_current_input->move_up_action.is_pressed = true;
                    break;
                }
                case GLFW_KEY_DOWN: {
                    game_current_input->move_down_action.is_pressed = true;
                    break;
                }
                case GLFW_KEY_LEFT: {
                    game_current_input->move_left_action.is_pressed = true;
                    break;
                }
                case GLFW_KEY_RIGHT: {
                    game_current_input->move_right_action.is_pressed = true;
                    break;
                }
                case GLFW_KEY_SPACE: {
                    game_current_input->jump_action.is_pressed = true;
                    game_current_input->select_action.is_pressed = true;
                    break;
                }
                case GLFW_KEY_ENTER: {
                    if(mods & GLFW_MOD_ALT) {
                        SetFullscreen(!g_fullscreen_is_enabled);
                    } else {
                        game_current_input->select_action.is_pressed = true;
                    }
                    break;
                }
                case GLFW_KEY_F11:
                    SetFullscreen(!g_fullscreen_is_enabled);
                    break;
                case GLFW_KEY_ESCAPE: {
                    ExitGame();
                    glfwSetWindowShouldClose(window, GLFW_TRUE);
                    break;
                }
            }

            // Modifier keys
            if(mods & GLFW_MOD_CONTROL) {
                game_current_input->jump_action.is_pressed = true;
                game_current_input->select_action.is_pressed = true;
            }

            if(mods & GLFW_MOD_ALT) {
                if(key != GLFW_KEY_ENTER) {  // Ignore for alt + enter combo
                    game_current_input->attack_action.is_pressed = true;
                }
            }


            // Bound keys
            if(key == game_current_input->raw_input.key_bindings[0]) {
                game_current_input->move_up_action.is_pressed = true;
            }

            if(key == game_current_input->raw_input.key_bindings[1]) {
                game_current_input->move_down_action.is_pressed = true;
            }

            if(key == game_current_input->raw_input.key_bindings[2]) {
                game_current_input->move_left_action.is_pressed = true;
            }

            if(key == game_current_input->raw_input.key_bindings[3]) {
                game_current_input->move_right_action.is_pressed = true;
            }

            if(key == game_current_input->raw_input.key_bindings[4]) {
                game_current_input->jump_action.is_pressed = true;
                game_current_input->select_action.is_pressed = true;
            }

            if(key == game_current_input->raw_input.key_bindings[5]) {
                game_current_input->attack_action.is_pressed = true;
            }

            game_current_input->raw_input.last_key_pressed = key;
            break;
        }
        case GLFW_RELEASE: {
            switch (key) {
                case GLFW_KEY_GRAVE_ACCENT: {
                    g_show_fps_is_enabled = false;
                    break;
                }
                case GLFW_KEY_UP: {
                    game_current_input->move_up_action.is_pressed = false;
                    break;
                }
                case GLFW_KEY_DOWN: {
                    game_current_input->move_down_action.is_pressed = false;
                    break;
                }
                case GLFW_KEY_LEFT: {
                    game_current_input->move_left_action.is_pressed = false;
                    break;
                }
                case GLFW_KEY_RIGHT: {
                    game_current_input->move_right_action.is_pressed = false;
                    break;
                }
                case GLFW_KEY_SPACE: {
                    game_current_input->jump_action.is_pressed = false;
                    game_current_input->select_action.is_pressed = false;
                    break;
                }
                case GLFW_KEY_ENTER: {
                    game_current_input->select_action.is_pressed = false;
                    break;
                }
            }

            // Modifier keys
            if(!(mods & GLFW_MOD_CONTROL)) {
                game_current_input->jump_action.is_pressed = false;
                game_current_input->select_action.is_pressed = false;
            }

            if(!(mods & GLFW_MOD_ALT)) {
                game_current_input->attack_action.is_pressed = false;
            }

            // Bound keys
            if(key == game_current_input->raw_input.key_bindings[0]) {
                game_current_input->move_up_action.is_pressed = false;
            }

            if(key == game_current_input->raw_input.key_bindings[1]) {
                game_current_input->move_down_action.is_pressed = false;
            }

            if(key == game_current_input->raw_input.key_bindings[2]) {
                game_current_input->move_left_action.is_pressed = false;
            }

            if(key == game_current_input->raw_input.key_bindings[3]) {
                game_current_input->move_right_action.is_pressed = false;
            }

            if(key == game_current_input->raw_input.key_bindings[4]) {
                game_current_input->jump_action.is_pressed = false;
                game_current_input->select_action.is_pressed = false;
            }

            if(key == game_current_input->raw_input.key_bindings[5]) {
                game_current_input->attack_action.is_pressed = false;
            }

            game_current_input->raw_input.last_key_pressed = key;
            break;
        }
    }
}

static void WindowFocusCallback(GLFWwindow* window, int is_focused) {
    if(is_focused) {
        g_game_is_frozen = false;
        Reset3d();
    } else {
        g_game_is_frozen = true;
    }
}

static void WindowSizeCallback(GLFWwindow* window, int width, int height) {
    if(!g_fullscreen_is_enabled) {
        g_window_resolution_x = width;
        g_window_resolution_y = height;
        SaveSettings();
    }
}

static void FramebufferSizeCallback(GLFWwindow* window, int width, int height) {
    ResizeViewport(width, height);
}

static void GetInput(GameInput* game_current_input, GameInput* game_prev_input) {
    // TODO: Move this over before this checkin
    for(int i = GLFW_JOYSTICK_1; i <= GLFW_JOYSTICK_LAST; ++i) {
        if(glfwJoystickPresent(i) == GLFW_TRUE) {
            int axis_count;
            const float* axis_values = glfwGetJoystickAxes(i, &axis_count);

            if(axis_count > 0) {
                if(axis_values[0] <= -0.5f) {
                    game_current_input->move_left_action.is_pressed = true;
                }

                if(axis_values[0] >= 0.5f) {
                    game_current_input->move_right_action.is_pressed = true;
                }
            }

            if(axis_count > 1) {
                if(axis_values[1] <= -0.5f) {
                    game_current_input->move_up_action.is_pressed = true;
                }

                if(axis_values[1] >= 0.5f) {
                    game_current_input->move_down_action.is_pressed = true;
                }
            }

            int button_count;
            const unsigned char* button_values = glfwGetJoystickButtons(GLFW_JOYSTICK_1, &button_count);

            // Face buttons - PS4 values
            if(button_count > 1 && button_values[1] == GLFW_PRESS) {
                game_current_input->jump_action.is_pressed = true;
            }

            if(button_count > 0 && button_values[0] == GLFW_PRESS) {
                game_current_input->attack_action.is_pressed = true;
            }

            // D-Pad buttons - PS4 values
            // TODO: Need to map per controller type?
            if(button_count > 14 && button_values[14] == GLFW_PRESS) {
                game_current_input->move_up_action.is_pressed = true;
            }

            if(button_count > 15 && button_values[15] == GLFW_PRESS) {
                game_current_input->move_right_action.is_pressed = true;
            }

            if(button_count > 16 && button_values[16] == GLFW_PRESS) {
                game_current_input->move_down_action.is_pressed = true;
            }

            if(button_count > 17 && button_values[17] == GLFW_PRESS) {
                game_current_input->move_left_action.is_pressed = true;
            }
        }
    }

    game_current_input->move_left_action.just_pressed = game_current_input->move_left_action.is_pressed && !game_prev_input->move_left_action.is_pressed;
    game_current_input->move_right_action.just_pressed = game_current_input->move_right_action.is_pressed && !game_prev_input->move_right_action.is_pressed;
    game_current_input->move_down_action.just_pressed = game_current_input->move_down_action.is_pressed && !game_prev_input->move_down_action.is_pressed;
    game_current_input->move_up_action.just_pressed = game_current_input->move_up_action.is_pressed && !game_prev_input->move_up_action.is_pressed;
    game_current_input->jump_action.just_pressed = game_current_input->jump_action.is_pressed && !game_prev_input->jump_action.is_pressed;
    game_current_input->attack_action.just_pressed = game_current_input->attack_action.is_pressed && !game_prev_input->attack_action.is_pressed;
    game_current_input->select_action.just_pressed = game_current_input->select_action.is_pressed && !game_prev_input->select_action.is_pressed;
}

void SaveSettings() {
    g_save_settings_is_queued = true;
}

int main(int arguments_count, char* arguments[]) {
    GameInput game_current_input = { 0 };
    g_debug_is_enabled = true;

    if(!GetWorkingDirectoryPath(g_game_base_path)) {
        // TODO: Proper error handling
        exit(EXIT_FAILURE);
    }

    if(!LoadSettings(&game_current_input.raw_input)) {
        // TODO: Proper error handling
        exit(EXIT_FAILURE);
    }

    glfwSetErrorCallback(ErrorCallback);

    if(!glfwInit()) {
        // TODO: Proper error handling
        exit(EXIT_FAILURE);
    }

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    // Creating as window first to get OS default positioning, but setting correct dimensions for first time creation
    // Will revert back to selected window resolution instead of fullscreen res, even if started in fullscreen
    int target_width = g_window_resolution_x;
    int target_height = g_window_resolution_y;

    if(g_fullscreen_is_enabled) {
        GLFWmonitor* monitor = glfwGetPrimaryMonitor();
        const GLFWvidmode* mode = glfwGetVideoMode(monitor);
        target_width = mode->width;
        target_height = mode->height;
    }

    g_main_window = glfwCreateWindow(target_width, target_height, "Jumpman Zero", NULL, NULL);

    if(!g_main_window) {
        // TODO: Proper error handling
        glfwTerminate();
        exit(EXIT_FAILURE);
    }

    glfwSetWindowUserPointer(g_main_window, &game_current_input);

    // Now backup window position before switching to fullscreen (if fullscreen dims, will be in upper left, but not offscreen)
    glfwGetWindowPos(g_main_window, &g_window_pos_x_backup, &g_window_pos_y_backup);

    if(g_fullscreen_is_enabled) {
        SetFullscreen(true);
    }

    ResizeViewport(target_width, target_height);  // Callback not set up yet

    glfwSetWindowSizeLimits(g_main_window, 320, 240, GLFW_DONT_CARE, GLFW_DONT_CARE);
    glfwSetWindowFocusCallback(g_main_window, WindowFocusCallback);
    glfwSetWindowSizeCallback(g_main_window, WindowSizeCallback);
    glfwSetFramebufferSizeCallback(g_main_window, FramebufferSizeCallback);
    glfwSetKeyCallback(g_main_window, KeyCallback);
    glfwMakeContextCurrent(g_main_window);

    if(glfwExtensionSupported("WGL_EXT_swap_control_tear") == GLFW_TRUE || glfwExtensionSupported("GLX_EXT_swap_control_tear") == GLFW_TRUE) {
        glfwSwapInterval(-1);
    } else {
        glfwSwapInterval(1);
    }

    gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);

    g_game_is_frozen = false;

    if(!Init3D()) {
        // TODO: Proper error handling
        exit(EXIT_FAILURE);
    }

    if(InitSoundBuffer()) {
        if(!InitMusic()) {
            g_music_is_enabled = false;
        }

        if(!InitSound()) {
            g_sound_effects_are_enabled = false;
        }
    } else {
        g_music_is_enabled = false;
        g_sound_effects_are_enabled = false;
    }

    double previous_frame_time = glfwGetTime();
    srand((unsigned)previous_frame_time);  // TODO: Seed prng with something that will actually be unique

    int bDone = 0;

    if(arguments_count > 1 && strlen(arguments[1])) {
        InitGameDebugLevel(arguments[1], &game_current_input);
    } else {
        InitGameNormal();
    }

    long frame_count_since_last_perf_update = 0;
    double last_perf_update_time = previous_frame_time;
    GameInput game_prev_input = game_current_input;

    while(!glfwWindowShouldClose(g_main_window)) {
        double current_time = glfwGetTime();

        if(current_time - previous_frame_time > kSECONDS_PER_FRAME) {
            ++frame_count_since_last_perf_update;

            if(current_time - last_perf_update_time >= 1.0) {
                last_perf_update_time = current_time;
                g_current_fps = frame_count_since_last_perf_update;

                if(g_current_fps > 99) {
                    g_current_fps = 99;
                }

                frame_count_since_last_perf_update = 0;
            }

            previous_frame_time = current_time;

            GetInput(&game_current_input, &game_prev_input);
            GameInput processed_input = game_current_input;
            UpdateGame(&processed_input);
            game_prev_input = game_current_input;

            glfwSwapBuffers(g_main_window);
        }

        glfwPollEvents();

        if(g_save_settings_is_queued) {
            if(!SaveSettings_(&game_current_input.raw_input)) {
                // TODO: fprintf(stderr, "Failed to save config file\n");
            }

            g_save_settings_is_queued = false;
        }
    }

    // Just letting these drop, because we're quitting
    // CleanResources();
    // CleanUpMusic();
    // CleanUpSounds();
    // CleanupSoundBuffer();
    // DoCleanUp();

    // glfwDestroyWindow(g_main_window);
    // glfwTerminate();

    exit(EXIT_SUCCESS);
}
