#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#define WIN32_LEAN_AND_MEAN 1
#include <windows.h>
#include "glad/glad.h"
#include "GLFW/glfw3.h"
#include "Basic3d.h"
#include "Jumpman.h"
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

// TODO: All these externally visible variables should be static. Maybe pass in state?
bool g_debug_is_enabled = false;

bool g_game_is_frozen;
long g_game_time_inactive;
long g_current_fps;

char g_game_base_path[300];  // TODO: Maybe expose path util?

bool g_sound_effects_are_enabled = kSOUND_EFFECTS_ARE_ENABLED_DEFAULT;
bool g_music_is_enabled = kMUSIC_IS_ENABLED_DEFAULT;
bool g_save_settings_is_queued = false;  // TODO: Maybe provide API?

int GameKeys[10];
long iLastKey;  // TODO: Might be harder to map this, since a script uses it
int iShowFPS;
int iKeyLeft, iTappedLeft, iTKeyLeft;
int iKeyRight, iTappedRight, iTKeyRight;
int iKeyDown, iTappedDown, iTKeyDown;
int iKeyUp, iTappedUp, iTKeyUp;
int iKeyJump, iTappedJump, iTKeyAttack;
int iKeyAttack, iTappedAttack, iTKeyJump;
int iKeySelect;

static bool g_fullscreen_is_enabled = kFULLSCREEN_IS_ENABLED_DEFAULT;
static int g_window_resolution_x = kWINDOW_RESOLUTION_DEFAULT_X;
static int g_window_resolution_y = kWINDOW_RESOLUTION_DEFAULT_Y;
static int g_window_pos_x_backup = 0;
static int g_window_pos_y_backup = 0;

static GLFWwindow* g_main_window = NULL;
static LARGE_INTEGER iTime;

static bool LoadSettings() {
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
            GameKeys[iKey] = atoi(sTemp);
        } else {
            GameKeys[iKey] = 0;
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

static bool SaveSettings() {
    bool success = true;

    char sFile[300];
    sprintf_s(sFile, sizeof(sFile), "%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d",
        GameKeys[0],
        GameKeys[1],
        GameKeys[2],
        GameKeys[3],
        GameKeys[4],
        GameKeys[5],
        g_sound_effects_are_enabled ? 1 : 0,
        g_music_is_enabled ? 1 : 0,
        g_fullscreen_is_enabled ? 1 : 0,
        g_window_resolution_x,
        g_window_resolution_y);

    char sFileName[300];  // TODO: Is path long enough?
    sprintf_s(sFileName, sizeof(sFileName), "%s\\Data\\Settings.dat", g_game_base_path);

    // TODO: Error handling
    HANDLE hFile = CreateFile(sFileName, GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);

    DWORD iWritten;
    WriteFile(hFile, sFile, (long)(strlen(sFile)), &iWritten, NULL);
    CloseHandle(hFile);

    return success;
}

static void SetFullscreen(bool enable_fullscreen) {
    g_fullscreen_is_enabled = enable_fullscreen;

    GLFWmonitor* monitor = NULL;
    int target_pos_x = g_window_pos_x_backup;
    int target_pos_y = g_window_pos_y_backup;
    int target_width = g_window_resolution_x;
    int target_height = g_window_resolution_y;

    if (enable_fullscreen) {
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

    if (enable_fullscreen) {
        glfwSetInputMode(g_main_window, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);
    }
    else {
        glfwSetInputMode(g_main_window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
    }

    g_save_settings_is_queued = true;
}

static void ErrorCallback(int error, const char* description) {
    fprintf(stderr, "Error: %s\n", description);
}

static void KeyCallback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    switch (action) {
        case GLFW_PRESS: {
            switch (key) {
                case GLFW_KEY_GRAVE_ACCENT: {
                    iShowFPS = 1;
                    break;
                }
                case GLFW_KEY_UP: {
                    iTappedUp = iKeyUp = 1;
                    break;
                }
                case GLFW_KEY_DOWN: {
                    iTappedDown = iKeyDown = 1;
                    break;
                }
                case GLFW_KEY_LEFT: {
                    iTappedLeft = iKeyLeft = 1;
                    break;
                }
                case GLFW_KEY_RIGHT: {
                    iTappedRight = iKeyRight = 1;
                    break;
                }
                case GLFW_KEY_SPACE: {
                    iTappedJump = iKeyJump = 1;
                    iKeySelect = 1;
                    break;
                }
                case GLFW_KEY_ENTER: {
                    if(mods & GLFW_MOD_ALT) {
                        SetFullscreen(!g_fullscreen_is_enabled);
                    } else {
                        iKeySelect = 1;
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
            if (mods & GLFW_MOD_CONTROL) {
                iTappedJump = iKeyJump = 1;
                iKeySelect = 1;
            }

            if(mods & GLFW_MOD_ALT) {
                if(key != GLFW_KEY_ENTER) {  // Ignore for alt + enter combo
                    iTappedAttack = iKeyAttack = 1;
                }
            }


            // Bound keys
            if (key == GameKeys[0]) {
                iTappedUp = iKeyUp = 1;
            }

            if (key == GameKeys[1]) {
                iTappedDown = iKeyDown = 1;
            }

            if (key == GameKeys[2]) {
                iTappedLeft = iKeyLeft = 1;
            }

            if (key == GameKeys[3]) {
                iTappedRight = iKeyRight = 1;
            }

            if (key == GameKeys[4]) {
                iTappedJump = iKeyJump = 1;
                iKeySelect = 1;
            }

            if (key == GameKeys[5]) {
                iTappedAttack = iKeyAttack = 1;
            }

            iLastKey = key;
            break;
        }
        case GLFW_RELEASE: {
            switch (key) {
                case GLFW_KEY_GRAVE_ACCENT: {
                    iShowFPS = 0;
                    break;
                }
                case GLFW_KEY_UP: {
                    iKeyUp = 0;
                    break;
                }
                case GLFW_KEY_DOWN: {
                    iKeyDown = 0;
                    break;
                }
                case GLFW_KEY_LEFT: {
                    iKeyLeft = 0;
                    break;
                }
                case GLFW_KEY_RIGHT: {
                    iKeyRight = 0;
                    break;
                }
                case GLFW_KEY_SPACE: {
                    iKeyJump = 0;
                    iKeySelect = 0;
                    break;
                }
                case GLFW_KEY_ENTER: {
                    iKeySelect = 0;
                    break;
                }
            }

            // Modifier keys
            if (!(mods & GLFW_MOD_CONTROL)) {
                iKeyJump = 0;
                iKeySelect = 0;
            }

            if (!(mods & GLFW_MOD_ALT)) {
                iKeyAttack = 0;
            }

            // Bound keys
            if (key == GameKeys[0]) {
                iKeyUp = 0;
            }

            if (key == GameKeys[1]) {
                iKeyDown = 0;
            }

            if (key == GameKeys[2]) {
                iKeyLeft = 0;
            }

            if (key == GameKeys[3]) {
                iKeyRight = 0;
            }

            if (key == GameKeys[4]) {
                iKeyJump = 0;
                iKeySelect = 0;
            }

            if (key == GameKeys[5]) {
                iKeyAttack = 0;
            }

            iLastKey = key;
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
        g_save_settings_is_queued = true;
    }
}

static void FramebufferSizeCallback(GLFWwindow* window, int width, int height) {
    ResizeViewport(width, height);
}

static void GetInput() {
    iTKeyLeft = iKeyLeft || iTappedLeft; iTappedLeft = 0;
    iTKeyRight = iKeyRight || iTappedRight;
    iTappedRight = 0;
    iTKeyUp = iKeyUp || iTappedUp;
    iTappedUp = 0;
    iTKeyDown = iKeyDown || iTappedDown;
    iTappedDown = 0;
    iTKeyJump = iKeyJump || iTappedJump;
    iTappedJump = 0;
    iTKeyAttack = iKeyAttack || iTappedAttack;
    iTappedAttack = 0;

    // TODO: Move this over before this checkin
    for (int i = GLFW_JOYSTICK_1; i <= GLFW_JOYSTICK_LAST; ++i) {
        if (glfwJoystickPresent(i) == GLFW_TRUE) {
            int axis_count;
            const float* axis_values = glfwGetJoystickAxes(i, &axis_count);

            if (axis_count > 0) {
                if (axis_values[0] <= -0.5f) {
                    iTKeyLeft = 1;
                }

                if (axis_values[0] >= 0.5f) {
                    iTKeyRight = 1;
                }
            }

            if (axis_count > 1) {
                if (axis_values[1] <= -0.5f) {
                    iTKeyUp = 1;
                }

                if (axis_values[1] >= 0.5f) {
                    iTKeyDown = 1;
                }
            }

            int button_count;
            const unsigned char* button_values = glfwGetJoystickButtons(GLFW_JOYSTICK_1, &button_count);

            // Face buttons - PS4 values
            if (button_count > 1 && button_values[1] == GLFW_PRESS) {
                iTKeyJump = 1;
            }

            if (button_count > 0 && button_values[0] == GLFW_PRESS) {
                iTKeyAttack = 1;
            }

            // D-Pad buttons - PS4 values
            // TODO: Need to map per controller type?
            if (button_count > 14 && button_values[14] == GLFW_PRESS) {
                iTKeyUp = 1;
            }

            if (button_count > 15 && button_values[15] == GLFW_PRESS) {
                iTKeyRight = 1;
            }

            if (button_count > 16 && button_values[16] == GLFW_PRESS) {
                iTKeyDown = 1;
            }

            if (button_count > 17 && button_values[17] == GLFW_PRESS) {
                iTKeyLeft = 1;
            }
        }
    }

    ++g_game_time_inactive;

    // TODO: Move this check to Jumpman.h? Is it based on input actions, or whether they're actually valid actions at the time?
    if(iTKeyLeft + iTKeyRight + iTKeyUp + iTKeyDown + iTKeyJump) {
        g_game_time_inactive = 0;
    }

    iTKeyAttack = 0;
}

int main(int arguments_count, char* arguments[]) {
    g_debug_is_enabled = true;

    GetCurrentDirectory(200, g_game_base_path);

    if(!LoadSettings()) {
        exit(EXIT_FAILURE);
    }

    glfwSetErrorCallback(ErrorCallback);

    if(!glfwInit()) {
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
        glfwTerminate();
        exit(EXIT_FAILURE);
    }

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

    LARGE_INTEGER LI;
    QueryPerformanceFrequency(&LI);
    unsigned long iFrameTime = LI.LowPart / 40;

    QueryPerformanceCounter(&iTime);
    srand((unsigned)(iTime.LowPart));

    int bDone = 0;

    if(arguments_count > 1 && strlen(arguments[1])) {
        InitGameDebugLevel(arguments[1]);
    } else {
        InitGameNormal();
    }

    long iPerfCount;
    unsigned long iPerfTime;

    iPerfTime = 0;
    iPerfCount = 0;

    while(!glfwWindowShouldClose(g_main_window)) {
        LARGE_INTEGER tTime;
        QueryPerformanceCounter(&tTime);

        if(tTime.LowPart - iTime.LowPart > iFrameTime || tTime.LowPart < iTime.LowPart) {
            ++iPerfCount;

            if(((unsigned long)(tTime.LowPart) - iPerfTime) > (iFrameTime * 40) || (unsigned long)(tTime.LowPart) < iPerfTime) {
                iPerfTime = (long)(tTime.LowPart);
                g_current_fps = iPerfCount;

                if(g_current_fps > 99) {
                    g_current_fps = 99;
                }

                iPerfCount = 0;
            }


            iTime = tTime;

            GetInput();
            UpdateGame();

            glfwSwapBuffers(g_main_window);
        }

        glfwPollEvents();

        if(g_save_settings_is_queued) {
            SaveSettings();
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