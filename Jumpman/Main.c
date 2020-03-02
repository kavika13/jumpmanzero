#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <glad/glad.h>

#if defined(__APPLE__)
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Weverything"
#endif
#define GLFW_INCLUDE_NONE
#include <GLFW/glfw3.h>
#if defined(__APPLE__)
    #pragma clang diagnostic pop
#endif

#if defined(__APPLE__)
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wconditional-uninitialized"
#elif defined(__GNUC__)
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wunused-parameter"
#endif
#define STB_SPRINTF_IMPLEMENTATION
#include <stb_sprintf.h>
#if defined(__APPLE__)
    #pragma clang diagnostic pop
#elif defined(__GNUC__)
    #pragma GCC diagnostic pop
#endif

#include "Basic3d.h"
#include "Input.h"
#include "Jumpman.h"
#include "Main.h"
#include "Music.h"
#include "Sound.h"
#include "SoundBuffer.h"
#include "Utilities.h"

typedef struct {
    GameInput current_input;
} GameState;

#define kFULLSCREEN_IS_ENABLED_DEFAULT ((bool)false)
#define kWINDOW_RESOLUTION_DEFAULT_X ((int32_t)640)
#define kWINDOW_RESOLUTION_DEFAULT_Y ((int32_t)480)
#define kWINDOW_RESOLUTION_MIN_X ((int32_t)320)
#define kWINDOW_RESOLUTION_MIN_Y ((int32_t)240)
#define kSOUND_EFFECTS_ARE_ENABLED_DEFAULT ((bool)false)
#define kMUSIC_IS_ENABLED_DEFAULT ((bool)false)

#define kFRAMES_PER_SECOND ((size_t)40)
#define kSLOWMO_RATIO ((double)16.0)
static const double kSECONDS_PER_FRAME = 1.0 / (double)kFRAMES_PER_SECOND;
static const double kSECONDS_PER_FRAME_SLOWMO = kSLOWMO_RATIO / (double)kFRAMES_PER_SECOND;
static double g_update_frame_times[kFRAMES_PER_SECOND] = { 0 };
static size_t g_update_frame_times_current_index = 0;

static char g_game_base_path[300];
static int32_t g_key_bindings[6];
static int32_t g_last_key_pressed = 0;
static bool g_fullscreen_is_enabled = kFULLSCREEN_IS_ENABLED_DEFAULT;
static int32_t g_window_resolution_x = kWINDOW_RESOLUTION_DEFAULT_X;
static int32_t g_window_resolution_y = kWINDOW_RESOLUTION_DEFAULT_Y;
static int32_t g_window_pos_x_backup = 0;
static int32_t g_window_pos_y_backup = 0;
static bool g_save_settings_is_queued = false;
static bool g_game_is_frozen = false;
static int32_t g_current_fps = 0;
static double g_current_max_update_frame_time = 0.0;
static double g_current_max_draw_and_swap_frame_time = 0.0;

static GLFWwindow* g_main_window = NULL;

static bool LoadSettings(bool* sound_is_initially_enabled, bool* music_is_initially_enabled) {
    char sTemp[30];
    char sFileName[300];

    stbsp_snprintf(sFileName, sizeof(sFileName), "%s/data/settings.dat", g_game_base_path);

    char* sData;
    size_t iLen = FileToString(sFileName, (unsigned char**)(&sData));

    // TODO: Handle file missing case without an error message - should create it and set defaults instead
    if(!iLen) {
        return false;
    }

    for(int32_t key_index = 0; key_index < 6; ++key_index) {
        if(GetFileLine(sTemp, sizeof(sTemp), sFileName, key_index)) {
            g_key_bindings[key_index] = atoi(sTemp);
        } else {
            g_key_bindings[key_index] = 0;
        }
    }

    *sound_is_initially_enabled = GetFileLine(sTemp, sizeof(sTemp), sFileName, 6)
        ? (atoi(sTemp) ? true : false)
        : false;

    *music_is_initially_enabled = GetFileLine(sTemp, sizeof(sTemp), sFileName, 7)
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

static bool SaveSettings_(void) {
    bool success = true;

    char sFile[300];
    stbsp_snprintf(sFile, sizeof(sFile), "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d",
        g_key_bindings[0],
        g_key_bindings[1],
        g_key_bindings[2],
        g_key_bindings[3],
        g_key_bindings[4],
        g_key_bindings[5],
        GetIsSoundEnabled() ? 1 : 0,
        GetIsMusicEnabled() ? 1 : 0,
        g_fullscreen_is_enabled ? 1 : 0,
        g_window_resolution_x,
        g_window_resolution_y);

    char sFileName[300];  // TODO: Is path long enough?
    stbsp_snprintf(sFileName, sizeof(sFileName), "%s/data/settings.dat", g_game_base_path);

    success = StringToFile(sFileName, sFile);

    return success;
}

static void SetFullscreen(bool enable_fullscreen) {
    g_fullscreen_is_enabled = enable_fullscreen;

    GLFWmonitor* monitor = NULL;
    int32_t target_pos_x = g_window_pos_x_backup;
    int32_t target_pos_y = g_window_pos_y_backup;
    int32_t target_width = g_window_resolution_x;
    int32_t target_height = g_window_resolution_y;

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

    glfwSetWindowMonitor(g_main_window, monitor, target_pos_x, target_pos_y, target_width, target_height, GLFW_DONT_CARE);

    if(enable_fullscreen) {
        glfwSetInputMode(g_main_window, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);
    } else {
        glfwSetInputMode(g_main_window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
    }

    SaveSettings();
}

static void ErrorCallback(int error, const char* description) {
    (void)error;  // Unused, but passed due to passing this function as a function pointer
    fprintf(stderr, "Error: %s\n", description);
}

static void KeyCallback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    (void)scancode;  // Unused, but passed due to passing this function as a function pointer
    GameState* game_state = glfwGetWindowUserPointer(window);
    GameInput* game_current_input = &game_state->current_input;

    switch(action) {
        case GLFW_PRESS: {
            switch(key) {
                case GLFW_KEY_GRAVE_ACCENT: {
                    game_current_input->debug_action.is_pressed = true;
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
                case GLFW_KEY_TAB: {
                    game_current_input->slowmo_action.is_pressed = true;
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
            if(key == g_key_bindings[0]) {
                game_current_input->move_up_action.is_pressed = true;
            }

            if(key == g_key_bindings[1]) {
                game_current_input->move_down_action.is_pressed = true;
            }

            if(key == g_key_bindings[2]) {
                game_current_input->move_left_action.is_pressed = true;
            }

            if(key == g_key_bindings[3]) {
                game_current_input->move_right_action.is_pressed = true;
            }

            if(key == g_key_bindings[4]) {
                game_current_input->jump_action.is_pressed = true;
                game_current_input->select_action.is_pressed = true;
            }

            if(key == g_key_bindings[5]) {
                game_current_input->attack_action.is_pressed = true;
            }

            g_last_key_pressed = key;
            break;
        }
        case GLFW_RELEASE: {
            switch(key) {
                case GLFW_KEY_GRAVE_ACCENT: {
                    game_current_input->debug_action.is_pressed = false;
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
                case GLFW_KEY_TAB: {
                    game_current_input->slowmo_action.is_pressed = false;
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
            if(key == g_key_bindings[0]) {
                game_current_input->move_up_action.is_pressed = false;
            }

            if(key == g_key_bindings[1]) {
                game_current_input->move_down_action.is_pressed = false;
            }

            if(key == g_key_bindings[2]) {
                game_current_input->move_left_action.is_pressed = false;
            }

            if(key == g_key_bindings[3]) {
                game_current_input->move_right_action.is_pressed = false;
            }

            if(key == g_key_bindings[4]) {
                game_current_input->jump_action.is_pressed = false;
                game_current_input->select_action.is_pressed = false;
            }

            if(key == g_key_bindings[5]) {
                game_current_input->attack_action.is_pressed = false;
            }

            g_last_key_pressed = key;
            break;
        }
    }
}

static void WindowFocusCallback(GLFWwindow* window, int is_focused) {
    (void)window;  // Unused, but passed due to passing this function as a function pointer

    if(is_focused) {
        g_game_is_frozen = false;
        Reset3d();
    } else {
        g_game_is_frozen = true;
    }
}

static void WindowSizeCallback(GLFWwindow* window, int width, int height) {
    (void)window;  // Unused, but passed due to passing this function as a function pointer

    if(!g_fullscreen_is_enabled) {
        g_window_resolution_x = width;
        g_window_resolution_y = height;
        SaveSettings();
    }
}

static void FramebufferSizeCallback(GLFWwindow* window, int width, int height) {
    (void)window;  // Unused, but passed due to passing this function as a function pointer
    ResizeViewport(width, height);
}

static void GetInput(GameInput* game_current_input, GameInput* game_prev_input) {
    // TODO: Move this over before this checkin
    for(int32_t i = GLFW_JOYSTICK_1; i <= GLFW_JOYSTICK_LAST; ++i) {
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
    game_current_input->slowmo_action.just_pressed = game_current_input->slowmo_action.is_pressed && !game_prev_input->slowmo_action.is_pressed;
    game_current_input->debug_action.just_pressed = game_current_input->debug_action.is_pressed && !game_prev_input->debug_action.is_pressed;
}

bool IsGameFrozen(void) {
    return g_game_is_frozen;
}

int32_t GetCurrentFps(void) {
    return g_current_fps;
}

double GetCurrentMaxUpdateFrameTime(void) {
    return g_current_max_update_frame_time;
}

double GetCurrentMaxDrawAndSwapFrameTime(void) {
    return g_current_max_draw_and_swap_frame_time;
}

int32_t GetLastKeyPressed(void) {
    return g_last_key_pressed;
}

int32_t GetKeyBinding(size_t binding_index) {
    return g_key_bindings[binding_index];
}

void SetKeyBinding(size_t binding_index, int32_t value) {
    g_key_bindings[binding_index] = value;
}

void SaveSettings(void) {
    g_save_settings_is_queued = true;
}

int main(int arguments_count, char* arguments[]) {
    GameState game_state = { 0 };

    if(!GetWorkingDirectoryPath(g_game_base_path)) {
        // TODO: Proper error handling
        exit(EXIT_FAILURE);
    }

    bool sound_is_initially_enabled = false;
    bool music_is_initially_enabled = false;

    if(!LoadSettings(&sound_is_initially_enabled, &music_is_initially_enabled)) {
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
    int32_t target_width = g_window_resolution_x;
    int32_t target_height = g_window_resolution_y;

    g_main_window = glfwCreateWindow(target_width, target_height, "Jumpman Zero", NULL, NULL);

    if(!g_main_window) {
        // TODO: Proper error handling
        glfwTerminate();
        exit(EXIT_FAILURE);
    }

    glfwSetWindowUserPointer(g_main_window, &game_state);

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
            music_is_initially_enabled = false;
        }

        if(!InitSound()) {
            sound_is_initially_enabled = false;
        }
    } else {
        music_is_initially_enabled = false;
        sound_is_initially_enabled = false;
    }

    if(music_is_initially_enabled) {
        SetIsMusicEnabled(true);
    }

    if(sound_is_initially_enabled) {
        SetIsSoundEnabled(true);
    }

    double previous_frame_time = glfwGetTime();
    srand((unsigned)previous_frame_time);  // TODO: Seed prng with something that will actually be unique

    if(arguments_count > 1 && strlen(arguments[1])) {
        InitGameDebugLevel(g_game_base_path, arguments[1]);
    } else {
        InitGameNormal(g_game_base_path);
    }

    int32_t frame_count_since_last_perf_update = 0;
    double last_perf_update_time = previous_frame_time;
    GameInput game_prev_input = game_state.current_input;

    while(!glfwWindowShouldClose(g_main_window)) {
        double current_time = glfwGetTime();

        if(current_time - previous_frame_time > (game_state.current_input.slowmo_action.is_pressed ? kSECONDS_PER_FRAME_SLOWMO : kSECONDS_PER_FRAME)) {
            previous_frame_time = current_time;
            GetInput(&game_state.current_input, &game_prev_input);
            GameInput processed_input = game_state.current_input;

            double update_begin_time = glfwGetTime();
            UpdateGame(&processed_input);
            double update_end_time = glfwGetTime();

            game_prev_input = game_state.current_input;

            g_update_frame_times[g_update_frame_times_current_index] = update_end_time - update_begin_time;
            ++g_update_frame_times_current_index;

            if(g_update_frame_times_current_index >= kFRAMES_PER_SECOND) {
               g_update_frame_times_current_index = 0;
            }
        }

        ++frame_count_since_last_perf_update;

        if(current_time - last_perf_update_time >= 1.0) {
            last_perf_update_time = current_time;
            g_current_fps = frame_count_since_last_perf_update;

            if(g_current_fps > 999) {
                g_current_fps = 999;
            }

            frame_count_since_last_perf_update = 0;
            double max_frame_time = 0.0;

            for(size_t i = 0; i < kFRAMES_PER_SECOND; ++i) {
               if(g_update_frame_times[i] > max_frame_time) {
                   max_frame_time = g_update_frame_times[i];
               }
            }

            g_current_max_update_frame_time = max_frame_time;

            // char update_frame_time[256];
            // stbsp_snprintf(
            //     update_frame_time, sizeof(update_frame_time),
            //     "Current max update frame time: %f\n", g_current_max_update_frame_time * 1000.0);
            // OutputDebugString(update_frame_time);
            // TODO: Make this visible in-game in some way

            // char draw_and_swap_frame_time[256];
            // stbsp_snprintf(
            //     draw_and_swap_frame_time, sizeof(draw_and_swap_frame_time),
            //     "Current max draw and swap frame time: %f\n", g_current_max_draw_and_swap_frame_time * 1000.0);
            // OutputDebugString(draw_and_swap_frame_time);
            // TODO: Make this visible in-game in some way

            g_current_max_draw_and_swap_frame_time = 0.0;  // Updates continuously
        }

        double draw_and_swap_begin_time = glfwGetTime();
        DrawGame();
        glfwSwapBuffers(g_main_window);
        double draw_and_swap_end_time = glfwGetTime();
        double current_draw_and_swap_frame_time = draw_and_swap_end_time - draw_and_swap_begin_time;

        if(current_draw_and_swap_frame_time > g_current_max_draw_and_swap_frame_time) {
            g_current_max_draw_and_swap_frame_time = current_draw_and_swap_frame_time;
        }

        glfwPollEvents();

        if(g_save_settings_is_queued) {
            if(!SaveSettings_()) {
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
