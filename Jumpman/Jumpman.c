#define _CRT_SECURE_NO_WARNINGS
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define CUTE_FILES_IMPLEMENTATION
#include <cute_files.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <stb_sprintf.h>
#include "Basic3d.h"
#include "Jumpman.h"
#include "Main.h"
#include "Music.h"
#include "Sound.h"
#include "Utilities.h"

typedef enum {
    kGameStatusExiting = 0,
    kGameStatusMenu = 1,
    kGameStatusInLevel = 2,
} GameStatus;

typedef enum {
    kGameMenuStateNone = 0,
    kGameMenuStateMain = 1,
    kGameMenuStateOptions = 2,
    kGameMenuStateSelectGame = 3,
    kGameMenuStateSelectLevel = 4,
} GameMenuState;

typedef enum {
    kGameMenuMusicStateContinuePlayingTrack = 0,
    kGameMenuMusicStateIntroTrack = 1,
    kGameMenuMusicStateMainLoopTrack = 2,
} GameMenuMusicState;

typedef enum {
    kPlayerStateNormal = 0,
    kPlayerStateJumping = 1,
    kPlayerStateFalling = 8,
    kPlayerStateLadder = 16,
    kPlayerStateRoll = 64,
    kPlayerStatePunch = 128,
    kPlayerStateDying = 256,
    kPlayerStateDone = 512,
    kPlayerStateVine = 1024,
    kPlayerStateSlide = 2048,
} PlayerState;

typedef enum {
    kPlayerSpecialActionNone = 0,
    kPlayerSpecialActionKick = 1,
    kPlayerSpecialActionPunch = 2,
} PlayerSpecialAction;

#define MAX_PLAYER_MESHES 100

typedef enum {
    kPlayerMeshStand = 1,
    kPlayerMeshLeft1 = 2,
    kPlayerMeshLeft2 = 3,
    kPlayerMeshRight1 = 4,
    kPlayerMeshRight2 = 5,
    kPlayerMeshJumpLeft = 6,
    kPlayerMeshJumpRight = 7,
    kPlayerMeshJumpUp = 8,
    kPlayerMeshVineClimb1 = 9,
    kPlayerMeshVineClimb2 = 10,
    kPlayerMeshLadderClimb1 = 11,
    kPlayerMeshLadderClimb2 = 12,
    kPlayerMeshKickLeft = 13,
    kPlayerMeshKickRight = 14,

    kPlayerMeshDiveRight = 15,
    kPlayerMeshRollRight1 = 16,
    kPlayerMeshRollRight2 = 17,
    kPlayerMeshRollRight3 = 18,
    kPlayerMeshRollRight4 = 19,

    kPlayerMeshDiveLeft = 20,
    kPlayerMeshRollLeft1 = 21,
    kPlayerMeshRollLeft2 = 22,
    kPlayerMeshRollLeft3 = 23,
    kPlayerMeshRollLeft4 = 24,

    kPlayerMeshPunchLeft = 25,
    kPlayerMeshPunchRight = 26,
    kPlayerMeshPunchLeft2 = 27,
    kPlayerMeshPunchRight2 = 28,
    kPlayerMeshDying = 29,
    kPlayerMeshDead = 30,
    kPlayerMeshStars = 31,
    kPlayerMeshSlideR = 32,
    kPlayerMeshSlideRB = 33,
    kPlayerMeshSlideL = 34,
    kPlayerMeshSlideLB = 35,
    kPlayerMeshBored1 = 36,
    kPlayerMeshBored2 = 37,
    kPlayerMeshBored3 = 38,
    kPlayerMeshBored4 = 39,
    kPlayerMeshBored5 = 40,
} PlayerMesh;

typedef enum {
    kPlayerDyingAnimationStateBouncing = 0,
    kPlayerDyingAnimationStateFalling = 1,
    kPlayerDyingAnimationStateFinalBounce = 2,
    kPlayerDyingAnimationStateSpinningStars = 10,
} PlayerDyingAnimationState;

typedef enum {
    kNavigationTypeLadder = 1,
    kNavigationTypePlatform = 2,
    kNavigationTypePlatformFallLeft = 3,
    kNavigationTypePlatformFallRight = 4,
} NavigationType;

typedef enum {
    kCameraModeNormal = 0,
    kCameraModeCloseUp = 1,
    kCameraModeFar = 2,
    kCameraModeNotSureWhatThisIs = 3,  // TODO: What should this mode be named? When is it used?
    kCameraModeSpaceLevel = 4,
    kCameraModeEndingLevel = 5,
    kCameraModeAbove = 20,
    kCameraModeFlat = 21,
    kCameraModeFarAbove = 22,
} CameraMode;

typedef struct {
    long X1, X2, X3, X4;
    long Y1, Y2, Y3, Y4;
    long Z1, Z2;
    long Num;
    int Visible;
    char Func[10];
    long Extra;

    int Navs;
    long NavTo[10];
    NavigationType NavToType[10];
    int NavDist;
    long NavChoice;

    long MeshSize;
    long* Mesh;
    long MeshNumber;
    long Texture;
    int ObjectNumber;
} LevelObject;

static void PrepLevel(const char* base_path, const char* level_filename, GameInput* game_input);
static void LoadNextLevel(const char* base_path, GameInput* game_input);
static long LoadMesh(const char* base_path, char* sFileName);
static void LoadMeshes(const char* base_path);
static void SetGamePerspective(void);
static int FindObject(LevelObject* lObj, int iCount, int iFind);
static void GetNextPlatform(long iX, long iY, long iHeight, long iWide, float* iSupport, long* iPlatform);

static char g_level_set_current_set_filename[100];
static int g_level_set_current_level_index;
static char g_level_current_title[50];
static GameStatus g_game_status;
static GameMenuState g_current_game_menu_state;
static GameMenuState g_target_game_menu_state;
static GameMenuMusicState g_target_menu_selected_music;
static bool g_just_launched_game;
static bool g_debug_level_is_specified;
static char g_debug_level_filename[300];
static int g_remaining_life_count;
static long g_game_time_inactive;

static int g_music_loop_start_music_time;  // TODO: I think it gets specified in milliseconds, but it should be in music time, due to the API that was used before

static char g_music_background_track_filename[200];
static char g_music_death_track_filename[200];
static char g_music_win_track_filename[200];
static CameraMode g_current_camera_mode;

static int g_loaded_texture_count;
static int g_loaded_mesh_count;
static int g_loaded_script_count;

#define MAX_SCRIPT_MESHES 300
#define MAX_LETTER_MESHES 300

static long g_player_mesh_indices[MAX_PLAYER_MESHES];
static long g_script_mesh_indices[MAX_SCRIPT_MESHES];
static long g_letter_mesh_indices[MAX_LETTER_MESHES];

static float g_player_current_position_x;
static float g_player_current_position_y;
static float g_player_current_position_z;
static float g_player_current_rotation_x_radians;
static int g_player_velocity_x;
static PlayerMesh g_player_current_mesh;
static PlayerMesh g_player_previous_mesh;
static bool g_player_is_visible;

static PlayerState g_player_current_state;
static PlayerSpecialAction g_player_current_special_action;

static long g_player_absolute_frame_count;
static long g_player_current_state_frame_count;
static PlayerDyingAnimationState g_player_dying_animation_state;
static int g_player_dying_animation_state_frame_count;

static int g_player_no_roll_cooldown_frame_count;
static int g_player_freeze_cooldown_frame_count;

#define MAX_OBJECTSCRIPTS 5
#define MAX_SCRIPTOBJECTS 60

static int g_donut_object_count;
static LevelObject g_donut_objects[100];
static int g_ladder_object_count;
static LevelObject g_ladder_objects[50];
static int g_platform_object_count;
static LevelObject g_platform_objects[100];
static int g_vine_object_count;
static LevelObject g_vine_objects[50];
static int g_wall_object_count;
static LevelObject g_wall_objects[50];
static int g_backdrop_object_count;
static LevelObject g_backdrop_objects[30];

// SCRIPT
static LevelObject* g_script_selected_level_object;
static long g_script_selected_mesh_index;

static long g_level_extent_x;
static long g_level_extent_y;

static lua_State* g_script_level_script_lua_state = NULL;

// ------------------------------- BASIC GAME STUFF ----------------------------

static void BuildNavigation(void) {
    for(int ladder_index = 0; ladder_index < g_ladder_object_count; ++ladder_index) {
        g_ladder_objects[ladder_index].Navs = 0;
    }

    for(int platform_index = 0; platform_index < g_platform_object_count; ++platform_index) {
        g_platform_objects[platform_index].Navs = 0;

        float next_platform_y;
        long next_platform_index;
        GetNextPlatform(g_platform_objects[platform_index].X1 - 4, g_platform_objects[platform_index].Y1, 4, 2, &next_platform_y, &next_platform_index);

        if(next_platform_index >= 0) {
            NavigationType nav_type = kNavigationTypePlatform;

            if(next_platform_y < g_platform_objects[platform_index].Y1 - 4) {
                nav_type = kNavigationTypePlatformFallLeft;
            }

            g_platform_objects[platform_index].NavTo[g_platform_objects[platform_index].Navs] = next_platform_index;
            g_platform_objects[platform_index].NavToType[g_platform_objects[platform_index].Navs] = nav_type;
            ++g_platform_objects[platform_index].Navs;
        }

        GetNextPlatform(g_platform_objects[platform_index].X2 + 4, g_platform_objects[platform_index].Y2, 4, 2, &next_platform_y, &next_platform_index);

        if(next_platform_index >= 0) {
            NavigationType nav_type = kNavigationTypePlatform;

            if(next_platform_y < g_platform_objects[platform_index].Y2 - 4) {
                nav_type = kNavigationTypePlatformFallRight;
            }

            g_platform_objects[platform_index].NavTo[g_platform_objects[platform_index].Navs] = next_platform_index;
            g_platform_objects[platform_index].NavToType[g_platform_objects[platform_index].Navs] = nav_type;
            ++g_platform_objects[platform_index].Navs;
        }

        for(int ladder_index = 0; ladder_index < g_ladder_object_count; ++ladder_index) {
            if(g_platform_objects[platform_index].X1 < g_ladder_objects[ladder_index].X1 && g_platform_objects[platform_index].X2 > g_ladder_objects[ladder_index].X1) {
                long ladder_pos_x = g_ladder_objects[ladder_index].X1;
                long platform_length = g_platform_objects[platform_index].X2 - g_platform_objects[platform_index].X1;
                // TODO: the platform_height variable name might not be quite correct. Seems to correlate ladder's position with platform height and platform length, then compare to ladder bottom/top
                long platform_height = g_platform_objects[platform_index].Y1 * abs((int)(g_platform_objects[platform_index].X2 - ladder_pos_x)) + g_platform_objects[platform_index].Y2 * abs((int)(g_platform_objects[platform_index].X1 - ladder_pos_x));
                platform_height /= platform_length;

                if(platform_height < g_ladder_objects[ladder_index].Y1 + 2 && platform_height > g_ladder_objects[ladder_index].Y2 - 2) {
                    g_platform_objects[platform_index].NavTo[g_platform_objects[platform_index].Navs] = ladder_index;
                    g_platform_objects[platform_index].NavToType[g_platform_objects[platform_index].Navs] = kNavigationTypeLadder;
                    ++g_platform_objects[platform_index].Navs;

                    g_ladder_objects[ladder_index].NavTo[g_ladder_objects[ladder_index].Navs] = platform_index;
                    g_ladder_objects[ladder_index].NavToType[g_ladder_objects[ladder_index].Navs] = kNavigationTypePlatform;
                    ++g_ladder_objects[ladder_index].Navs;
                }
            }
        }
    }

    return;
}

static long GetNavDir(long iFrom, long iTo, NavigationType nav_from_type, NavigationType nav_to_type) {
    for(int platform_index = 0; platform_index < g_platform_object_count; ++platform_index) {
        g_platform_objects[platform_index].NavDist = 5000;
    }

    for(int ladder_index = 0; ladder_index < g_ladder_object_count; ++ladder_index) {
        g_ladder_objects[ladder_index].NavDist = 5000;
    }

    if(iFrom < 0 || iTo < 0) {
        return -1;
    }

    if(nav_from_type == kNavigationTypeLadder) {
        g_ladder_objects[iFrom].NavDist = 0;
    }

    if(nav_from_type == kNavigationTypePlatform) {
        g_platform_objects[iFrom].NavDist = 0;
    }

    bool is_done = false;

    for(int repeat_count = 0; repeat_count < 50 && !is_done; ++repeat_count) {
        for(int ladder_index = 0; ladder_index < g_ladder_object_count; ++ladder_index) {
            if(g_ladder_objects[ladder_index].NavDist < 5000) {
                for(int nav_index = 0; nav_index < g_ladder_objects[ladder_index].Navs; ++nav_index) {
                    if(g_ladder_objects[ladder_index].NavToType[nav_index] == kNavigationTypePlatform) {
                        long iNavTo = g_ladder_objects[ladder_index].NavTo[nav_index];

                        if(g_platform_objects[iNavTo].NavDist > g_ladder_objects[ladder_index].NavDist + 1) {
                            g_platform_objects[iNavTo].NavDist = g_ladder_objects[ladder_index].NavDist + 1;
                            g_platform_objects[iNavTo].NavChoice = g_ladder_objects[ladder_index].NavChoice;

                            if(g_ladder_objects[ladder_index].NavDist == 0) {
                                g_platform_objects[iNavTo].NavChoice = iNavTo;
                            }
                        }
                    }
                }
            }
        }

        for(int platform_index = 0; platform_index < g_platform_object_count; ++platform_index) {
            if(g_platform_objects[platform_index].NavDist < 5000) {
                NavigationType nav_type;

                for(int nav_index = 0; nav_index < g_platform_objects[platform_index].Navs; ++nav_index) {
                    nav_type = g_platform_objects[platform_index].NavToType[nav_index];

                    if(nav_type != kNavigationTypeLadder) {
                        long iNavTo = g_platform_objects[platform_index].NavTo[nav_index];

                        if(g_platform_objects[iNavTo].NavDist > g_platform_objects[platform_index].NavDist + 1) {
                            g_platform_objects[iNavTo].NavDist = g_platform_objects[platform_index].NavDist + 1;
                            g_platform_objects[iNavTo].NavChoice = g_platform_objects[platform_index].NavChoice;

                            if(g_platform_objects[platform_index].NavDist == 0) {
                                if(nav_type == kNavigationTypePlatform) {
                                    g_platform_objects[iNavTo].NavChoice = iNavTo;
                                }

                                if(nav_type == kNavigationTypePlatformFallLeft) {
                                    g_platform_objects[iNavTo].NavChoice = iNavTo + 2000;
                                }

                                if(nav_type == kNavigationTypePlatformFallRight) {
                                    g_platform_objects[iNavTo].NavChoice = iNavTo + 3000;
                                }
                            }
                        }
                    }

                    if(nav_type == kNavigationTypeLadder) {
                        long iNavTo = g_platform_objects[platform_index].NavTo[nav_index];

                        if(g_ladder_objects[iNavTo].NavDist > g_platform_objects[platform_index].NavDist + 1) {
                            g_ladder_objects[iNavTo].NavDist = g_platform_objects[platform_index].NavDist + 1;
                            g_ladder_objects[iNavTo].NavChoice = g_platform_objects[platform_index].NavChoice;

                            if(g_platform_objects[platform_index].NavDist == 0) {
                                g_ladder_objects[iNavTo].NavChoice = iNavTo + 1000;
                            }
                        }
                    }
                }
            }
        }

        if(nav_to_type == kNavigationTypeLadder && g_ladder_objects[iTo].NavDist < 5000) {
            is_done = true;
        }

        if(nav_to_type != kNavigationTypeLadder && g_platform_objects[iTo].NavDist < 5000) {
            is_done = true;
        }
    }

    if(!is_done) {
        return -1;
    }

    long iChoice = 0;

    if(nav_to_type == kNavigationTypeLadder) {
        iChoice = g_ladder_objects[iTo].NavChoice;
    }

    if(nav_to_type != kNavigationTypeLadder) {
        iChoice = g_platform_objects[iTo].NavChoice;
    }

    return iChoice;
}

static int FindObject(LevelObject* lObj, int iCount, int iFind) {
    int iLoop = -1;

    while(++iLoop < iCount) {
        if(lObj[iLoop].Num == iFind) {
            return iLoop;
        }
    }

    return -1;
}

static void ComposeObject(LevelObject* lObj, long* oData, long* iPlace) {
    int iCopy = -1;

    while(++iCopy < lObj->MeshSize) {
        oData[*iPlace] = lObj->Mesh[iCopy];
        ++*iPlace;
    }
}

// Potentially temporary engine functions, during refactor of game logic from out of engine into script

static int get_donut_mesh_number(lua_State* lua_state) {
    lua_Integer donut_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_donut_objects[donut_index].MeshNumber);
    return 1;
}

static int get_donut_number(lua_State* lua_state) {
    lua_Integer donut_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_donut_objects[donut_index].Num);
    return 1;
}

static int get_donut_texture_index(lua_State* lua_state) {
    lua_Integer donut_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_donut_objects[donut_index].Texture);
    return 1;
}

static int get_donut_is_visible(lua_State* lua_state) {
    lua_Integer donut_index = luaL_checkinteger(lua_state, 1);
    lua_pushboolean(lua_state, g_donut_objects[donut_index].Visible != 0);
    return 1;
}

static int get_donut_x1(lua_State* lua_state) {
    lua_Integer donut_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_donut_objects[donut_index].X1);
    return 1;
}

static int get_donut_y1(lua_State* lua_state) {
    lua_Integer donut_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_donut_objects[donut_index].Y1);
    return 1;
}

static int get_ladder_x1(lua_State* lua_state) {
    lua_Integer ladder_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_ladder_objects[ladder_index].X1);
    return 1;
}

static int get_ladder_y1(lua_State* lua_state) {
    lua_Integer ladder_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_ladder_objects[ladder_index].Y1);
    return 1;
}

static int get_ladder_y2(lua_State* lua_state) {
    lua_Integer ladder_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_ladder_objects[ladder_index].Y2);
    return 1;
}

static int get_ladder_z1(lua_State* lua_state) {
    lua_Integer ladder_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_ladder_objects[ladder_index].Z1);
    return 1;
}

static int get_vine_x1(lua_State* lua_state) {
    lua_Integer vine_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_vine_objects[vine_index].X1);
    return 1;
}

static int get_vine_y1(lua_State* lua_state) {
    lua_Integer vine_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_vine_objects[vine_index].Y1);
    return 1;
}

static int get_vine_y2(lua_State* lua_state) {
    lua_Integer vine_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_vine_objects[vine_index].Y2);
    return 1;
}

static int get_vine_z1(lua_State* lua_state) {
    lua_Integer vine_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_vine_objects[vine_index].Z1);
    return 1;
}

static int get_platform_extra(lua_State* lua_state) {
    lua_Integer platform_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_platform_objects[platform_index].Extra);
    return 1;
}

static int get_platform_x1(lua_State* lua_state) {
    lua_Integer platform_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_platform_objects[platform_index].X1);
    return 1;
}

static int get_platform_x2(lua_State* lua_state) {
    lua_Integer platform_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_platform_objects[platform_index].X2);
    return 1;
}

static int get_platform_y1(lua_State* lua_state) {
    lua_Integer platform_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_platform_objects[platform_index].Y1);
    return 1;
}

static int get_platform_y2(lua_State* lua_state) {
    lua_Integer platform_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_platform_objects[platform_index].Y2);
    return 1;
}

static int get_platform_z1(lua_State* lua_state) {
    lua_Integer platform_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_platform_objects[platform_index].Z1);
    return 1;
}

static int get_wall_x1(lua_State* lua_state) {
    lua_Integer wall_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_wall_objects[wall_index].X1);
    return 1;
}

static int get_wall_x2(lua_State* lua_state) {
    lua_Integer wall_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_wall_objects[wall_index].X2);
    return 1;
}

static int get_wall_x3(lua_State* lua_state) {
    lua_Integer wall_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_wall_objects[wall_index].X3);
    return 1;
}

static int get_wall_x4(lua_State* lua_state) {
    lua_Integer wall_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_wall_objects[wall_index].X4);
    return 1;
}

static int get_wall_y1(lua_State* lua_state) {
    lua_Integer wall_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_wall_objects[wall_index].Y1);
    return 1;
}

static int get_wall_y2(lua_State* lua_state) {
    lua_Integer wall_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_wall_objects[wall_index].Y2);
    return 1;
}

static int get_wall_y3(lua_State* lua_state) {
    lua_Integer wall_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_wall_objects[wall_index].Y3);
    return 1;
}

static int get_wall_y4(lua_State* lua_state) {
    lua_Integer wall_index = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_wall_objects[wall_index].Y4);
    return 1;
}

static int game_over(lua_State* lua_state) {
    char game_base_path[300];

    if (!GetWorkingDirectoryPath(game_base_path)) {  // TODO: Should this be passed in from main.c somehow?
        // TODO: Proper error handling
        return 0;
    }

    g_player_current_state = kPlayerStateNormal;
    stbsp_snprintf(g_level_current_title, sizeof(g_level_current_title), "%s", "");
    PrepLevel(game_base_path, "Data/GameOver.DAT", NULL);  // TODO: Need to pass in game_input? Get null reference otherwise
    return 0;
}

static int restart_music_track_1(lua_State* lua_state) {
    if(g_music_loop_start_music_time != 5550) {
        // TODO: Error checking?
        NewTrack1(g_music_background_track_filename, g_music_loop_start_music_time, g_music_loop_start_music_time);
    }

    return 0;
}

static int play_death_music_track(lua_State* lua_state) {
    NewTrack2(g_music_death_track_filename);  // TODO: Error checking?
    return 0;
}

static int stop_music_track_1(lua_State* lua_state) {
    StopMusic1();  // TODO: Error checking?
    return 0;
}

static int get_game_time_inactive(lua_State* lua_state) {
    lua_pushinteger(lua_state, g_game_time_inactive);
    return 1;
}

static int get_player_absolute_frame_count(lua_State* lua_state) {
    lua_pushinteger(lua_state, g_player_absolute_frame_count);
    return 1;
}

static int set_player_absolute_frame_count(lua_State* lua_state) {
    lua_Integer new_frame_count_arg = luaL_checkinteger(lua_state, 1);
    g_player_absolute_frame_count = (long)new_frame_count_arg;
    return 0;
}

static int get_player_current_mesh(lua_State* lua_state) {
    lua_pushinteger(lua_state, g_player_current_mesh);
    return 1;
}

static int set_player_current_mesh(lua_State* lua_state) {
    lua_Integer new_mesh_index_arg = luaL_checkinteger(lua_state, 1);
    g_player_current_mesh = (PlayerMesh)new_mesh_index_arg;
    return 0;
}

static int set_player_current_rotation_x_radians(lua_State* lua_state) {
    double new_rotation_x_radians = luaL_checknumber(lua_state, 1);
    g_player_current_rotation_x_radians = (float)new_rotation_x_radians;
    return 0;
}

static int get_player_dying_animation_state(lua_State* lua_state) {
    lua_pushinteger(lua_state, g_player_dying_animation_state);
    return 1;
}

static int set_player_dying_animation_state(lua_State* lua_state) {
    lua_Integer new_dying_animation_state_arg = luaL_checkinteger(lua_state, 1);
    g_player_dying_animation_state = (PlayerDyingAnimationState)new_dying_animation_state_arg;
    return 0;
}

static int get_player_dying_animation_state_frame_count(lua_State* lua_state) {
    lua_pushinteger(lua_state, g_player_dying_animation_state_frame_count);
    return 1;
}

static int set_player_dying_animation_state_frame_count(lua_State* lua_state) {
    lua_Integer new_frame_count_arg = luaL_checkinteger(lua_state, 1);
    g_player_dying_animation_state_frame_count = (int)new_frame_count_arg;
    return 0;
}

static int get_player_mesh_index(lua_State* lua_state) {
    lua_Integer player_mesh_arg = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_player_mesh_indices[player_mesh_arg]);
    return 1;
}

static int get_player_no_roll_cooldown_frame_count(lua_State* lua_state) {
    lua_pushinteger(lua_state, g_player_no_roll_cooldown_frame_count);
    return 1;
}

static int get_player_current_velocity_x(lua_State* lua_state) {
    lua_pushinteger(lua_state, g_player_velocity_x);
    return 1;
}

static int set_player_current_velocity_x(lua_State* lua_state) {
    lua_Integer new_velocity_x_arg = luaL_checkinteger(lua_state, 1);
    g_player_velocity_x = (int)new_velocity_x_arg;
    return 0;
}

static int get_just_launched_game(lua_State* lua_state) {
    lua_pushboolean(lua_state, g_just_launched_game);
    return 1;
}

// script 3d object utility functions

static int script_selected_mesh_change_mesh(lua_State* lua_state) {
    double new_mesh_index_arg = luaL_checknumber(lua_state, 1);
    ChangeMesh(g_script_selected_mesh_index, g_script_mesh_indices[(size_t)new_mesh_index_arg]);
    return 0;
}

static int script_selected_mesh_set_identity_matrix(lua_State* lua_state) {
    IdentityMatrix(g_script_selected_mesh_index);
    return 0;
}

static int script_selected_mesh_set_perspective_matrix(lua_State* lua_state) {
    PerspectiveMatrix(g_script_selected_mesh_index);
    return 0;
}

static int script_selected_mesh_translate_matrix(lua_State* lua_state) {
    double arg_x = luaL_checknumber(lua_state, 1);
    double arg_y = luaL_checknumber(lua_state, 2);
    double arg_z = luaL_checknumber(lua_state, 3);
    TranslateMatrix(g_script_selected_mesh_index, (float)arg_x, (float)arg_y, (float)arg_z);
    return 0;
}

static int script_selected_mesh_scale_matrix(lua_State* lua_state) {
    double arg_x = luaL_checknumber(lua_state, 1);
    double arg_y = luaL_checknumber(lua_state, 2);
    double arg_z = luaL_checknumber(lua_state, 3);
    ScaleMatrix(g_script_selected_mesh_index, (float)arg_x, (float)arg_y, (float)arg_z);
    return 0;
}

static int script_selected_mesh_rotate_matrix_x(lua_State* lua_state) {
    double arg_degrees = luaL_checknumber(lua_state, 1);
    RotateMatrixX(g_script_selected_mesh_index, (float)arg_degrees);
    return 0;
}

static int script_selected_mesh_rotate_matrix_y(lua_State* lua_state) {
    double arg_degrees = luaL_checknumber(lua_state, 1);
    RotateMatrixY(g_script_selected_mesh_index, (float)arg_degrees);
    return 0;
}

static int script_selected_mesh_rotate_matrix_z(lua_State* lua_state) {
    double arg_degrees = luaL_checknumber(lua_state, 1);
    RotateMatrixZ(g_script_selected_mesh_index, (float)arg_degrees);
    return 0;
}

static int script_selected_mesh_scroll_texture(lua_State* lua_state) {
    double arg_x = luaL_checknumber(lua_state, 1);
    double arg_y = luaL_checknumber(lua_state, 2);
    // TODO: Remove pre-multiplication from scripts, and divide from here
    ScrollTexture(g_script_selected_mesh_index, (float)arg_x / 16.0f, (float)arg_y / 16.0f);
    return 0;
}

static int get_navigation_dir(lua_State* lua_state) {
    lua_Integer arg_from_object_abs_index = luaL_checkinteger(lua_state, 1);
    lua_Integer arg_to_object_abs_index = luaL_checkinteger(lua_state, 2);
    lua_Integer arg_from_object_type = luaL_checkinteger(lua_state, 3);
    lua_Integer arg_to_object_type = luaL_checkinteger(lua_state, 4);
    long result = GetNavDir(
        (long)arg_from_object_abs_index, (long)arg_to_object_abs_index,
        (NavigationType)arg_from_object_type, (NavigationType)arg_to_object_type);
    lua_pushinteger(lua_state, result);
    return 1;
}

// script script_selected_level_object accessors (getters)
// TODO: Maybe pass in the id instead of global "selected" state for all these

static int get_script_selected_level_object_extra(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_script_selected_level_object->Extra);
    return 1;
}

static int get_script_selected_level_object_number(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_script_selected_level_object->Num);
    return 1;
}

static int get_script_selected_level_object_this(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_script_selected_level_object->ObjectNumber);
    return 1;
}

static int get_script_selected_level_object_visible(lua_State* lua_state) {
    lua_pushboolean(lua_state, g_script_selected_level_object->Visible);
    return 1;
}

static int get_script_selected_level_object_x1(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_script_selected_level_object->X1);
    return 1;
}

static int get_script_selected_level_object_x2(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_script_selected_level_object->X2);
    return 1;
}

static int get_script_selected_level_object_y1(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_script_selected_level_object->Y1);
    return 1;
}

static int get_script_selected_level_object_y2(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_script_selected_level_object->Y2);
    return 1;
}

static int get_script_selected_level_object_z1(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_script_selected_level_object->Z1);
    return 1;
}

static int get_script_selected_level_object_z2(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_script_selected_level_object->Z2);
    return 1;
}

// script script_selected_level_object accessors (setters)
// TODO: Maybe pass in the id instead of global "selected" state for all these

static int set_script_selected_level_object_number(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_script_selected_level_object->Num = (int)arg1;
    return 0;
}

static int set_script_selected_level_object_texture(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_script_selected_level_object->Texture = (int)arg1;
    SetObjectData(g_script_selected_mesh_index, g_script_selected_level_object->Texture, g_script_selected_level_object->Visible);
    return 0;
}

static int set_script_selected_level_object_visible(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_script_selected_level_object->Visible = (int)arg1;
    SetObjectData(g_script_selected_mesh_index, g_script_selected_level_object->Texture, g_script_selected_level_object->Visible);
    return 0;
}

static int set_script_selected_level_object_x1(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_script_selected_level_object->X1 = (int)arg1;
    return 0;
}

static int set_script_selected_level_object_x2(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_script_selected_level_object->X2 = (int)arg1;
    return 0;
}

static int set_script_selected_level_object_y1(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_script_selected_level_object->Y1 = (int)arg1;
    return 0;
}

static int set_script_selected_level_object_y2(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_script_selected_level_object->Y2 = (int)arg1;
    return 0;
}

static int set_script_selected_level_object_z1(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_script_selected_level_object->Z1 = (int)arg1;
    return 0;
}

static int set_script_selected_level_object_z2(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_script_selected_level_object->Z2 = (int)arg1;
    return 0;
}

// script global variable accessors (getters)

static int get_current_camera_mode(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_current_camera_mode);
    return 1;
}

static int get_donut_object_count(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_donut_object_count);
    return 1;
}

static int get_ladder_object_count(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_ladder_object_count);
    return 1;
}

static int get_level_extent_x(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_level_extent_x);
    return 1;
}

static int get_loaded_texture_count(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_loaded_texture_count);
    return 1;
}

static int get_platform_object_count(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_platform_object_count);
    return 1;
}

static int get_player_current_position_x(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_player_current_position_x);
    return 1;
}

static int get_player_current_position_y(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_player_current_position_y);
    return 1;
}

static int get_player_current_position_z(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_player_current_position_z);
    return 1;
}

static int get_player_current_special_action(lua_State* lua_state) {
    lua_pushinteger(lua_state, g_player_current_special_action);
    return 1;
}

static int get_player_current_state(lua_State* lua_state) {
    lua_pushinteger(lua_state, g_player_current_state);
    return 1;
}

static int get_player_current_state_frame_count(lua_State* lua_state) {
    lua_pushinteger(lua_state, g_player_current_state_frame_count);
    return 1;
}

static int get_player_freeze_cooldown_frame_count(lua_State* lua_state) {
    lua_pushinteger(lua_state, g_player_freeze_cooldown_frame_count);
    return 1;
}

static int get_player_is_visible(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_player_is_visible);
    return 1;
}

static int get_remaining_life_count(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_remaining_life_count);
    return 1;
}

static int get_vine_object_count(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_vine_object_count);
    return 1;
}

static int get_wall_object_count(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_wall_object_count);
    return 1;
}

static int get_script_object_count(lua_State* lua_state) {
    lua_pushnumber(lua_state, MAX_SCRIPTOBJECTS);
    return 1;
}

static int get_is_sound_enabled(lua_State* lua_state) {
    lua_pushboolean(lua_state, GetIsSoundEnabled());
    return 1;
}

static int get_is_music_enabled(lua_State* lua_state) {
    lua_pushboolean(lua_state, GetIsMusicEnabled());
    return 1;
}

static int get_last_key_pressed(lua_State* lua_state) {
    lua_pushnumber(lua_state, GetLastKeyPressed());
    return 1;
}

static int get_current_fps(lua_State* lua_state) {
    lua_pushnumber(lua_state, GetCurrentFps());
    return 1;
}

// script global variable accessors (setters)

static int set_current_camera_mode(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_current_camera_mode = (CameraMode)arg1;
    return 0;
}

static int set_level_extent_x(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_level_extent_x = (int)arg1;
    return 0;
}

static int set_player_current_position_x(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_player_current_position_x = (float)arg1;
    return 0;
}

static int set_player_current_position_y(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_player_current_position_y = (float)arg1;
    return 0;
}

static int set_player_current_position_z(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_player_current_position_z = (float)arg1;
    return 0;
}

static int set_player_current_special_action(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_player_current_special_action = arg1;
    return 0;
}

static int set_player_current_state(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_player_current_state = arg1;
    return 0;
}

static int set_player_current_state_frame_count(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_player_current_state_frame_count = (long)arg1;
    return 0;
}

static int set_player_freeze_cooldown_frame_count(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_player_freeze_cooldown_frame_count = (int)arg1;
    return 0;
}

static int set_player_is_visible(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_player_is_visible = arg1;
    return 0;
}

static int set_player_no_roll_cooldown_frame_count(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_player_no_roll_cooldown_frame_count = (int)arg1;
    return 0;
}

static int set_remaining_life_count(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_remaining_life_count = (int)arg1;
    return 0;
}

// script utility functions

static int new_mesh(lua_State* lua_state) {
    double script_mesh_index = luaL_checknumber(lua_state, 1);
    long iNew;
    CopyObject(g_script_mesh_indices[(size_t)script_mesh_index], &iNew);
    g_script_selected_mesh_index = iNew;
    lua_pushnumber(lua_state, iNew);
    return 1;
}

static int new_char_mesh(lua_State* lua_state) {
    lua_Integer ascii_value_arg = luaL_checkinteger(lua_state, 1);
    long iNew;

    if(ascii_value_arg >= 97) {
        ascii_value_arg += 65 - 97;
    }

    if(g_letter_mesh_indices[ascii_value_arg] >= 0) {
        CopyObject(g_letter_mesh_indices[ascii_value_arg], &iNew);
        g_script_selected_mesh_index = iNew;
    } else {
        iNew = -1;
    }

    lua_pushnumber(lua_state, iNew);

    return 1;
}

static int set_object_visual_data(lua_State* lua_state) {
    double texture_index = luaL_checknumber(lua_state, 1);
    double is_visible = luaL_checknumber(lua_state, 2);
    SetObjectData(g_script_selected_mesh_index, (long)texture_index, (int)is_visible);
    return 0;
}

static int prioritize_object(lua_State* lua_state) {
    PrioritizeObject(g_script_selected_mesh_index);
    return 0;
}

// TODO: Rename these abs functions. They select an object and mesh?  Do other things select the same object, but not the mesh?
//       I believe they select by absolute index in that object type, so you can loop through all of them
//       So maybe it should be "select_xyz_at_index" or something, and the other should be called "select_xyz_with_object_num"?
//       Or maybe we should get rid of these "selection" things to begin with, and just have functions to query the right index, then manipulate objects via index
// TODO: Maybe return the id instead of global "selected" state for all these
static int script_abs_platform(lua_State* lua_state) {
    double platform_index = luaL_checknumber(lua_state, 1);
    g_script_selected_level_object = &g_platform_objects[(size_t)platform_index];
    g_script_selected_mesh_index = g_script_selected_level_object->MeshNumber;
    return 0;
}

static int script_abs_ladder(lua_State* lua_state) {
    double ladder_index = luaL_checknumber(lua_state, 1);
    g_script_selected_level_object = &g_ladder_objects[(size_t)ladder_index];
    g_script_selected_mesh_index = g_script_selected_level_object->MeshNumber;
    return 0;
}

static int script_abs_donut(lua_State* lua_state) {
    double donut_index = luaL_checknumber(lua_state, 1);
    g_script_selected_level_object = &g_donut_objects[(size_t)donut_index];
    g_script_selected_mesh_index = g_script_selected_level_object->MeshNumber;
    return 0;
}

static int script_abs_vine(lua_State* lua_state) {
    double vine_index = luaL_checknumber(lua_state, 1);
    g_script_selected_level_object = &g_vine_objects[(size_t)vine_index];
    g_script_selected_mesh_index = g_script_selected_level_object->MeshNumber;
    return 0;
}

static int script_set_fog(lua_State* lua_state) {
    lua_Number fog_start_arg = luaL_checknumber(lua_state, 1);
    lua_Number fog_end_arg = luaL_checknumber(lua_state, 2);
    lua_Integer red_arg = luaL_checkinteger(lua_state, 3);
    lua_Integer green_arg = luaL_checkinteger(lua_state, 4);
    lua_Integer blue_arg = luaL_checkinteger(lua_state, 5);
    SetFog((float)fog_start_arg, (float)fog_end_arg, red_arg & 0xFF, green_arg & 0xFF, blue_arg & 0xFF);
    return 0;
}

static int script_get_current_level_title(lua_State* lua_state) {
    lua_pushstring(lua_state, g_level_current_title);
    return 1;
}

static int get_config_option_string(lua_State* lua_state) {
    char sName[100];
    lua_Integer option_index_arg = luaL_checkinteger(lua_state, 1);

    if(option_index_arg >= 0 && option_index_arg <= 5) {
        int iKey = GetKeyBinding((size_t)option_index_arg);

        if(iKey >= 'A' && iKey <= 'Z') {
            stbsp_snprintf(sName, sizeof(sName), "%c   ", iKey);
        } else if(iKey >= '0' && iKey <= '9') {
            stbsp_snprintf(sName, sizeof(sName), "%c   ", iKey);
        } else if(iKey == 38) {
            stbsp_snprintf(sName, sizeof(sName), "UP  ");
        } else if(iKey == 40) {
            stbsp_snprintf(sName, sizeof(sName), "DOWN");
        } else if(iKey == 37) {
            stbsp_snprintf(sName, sizeof(sName), "LEFT");
        } else if(iKey == 39) {
            stbsp_snprintf(sName, sizeof(sName), "RGHT");
        } else if(iKey == 32) {
            stbsp_snprintf(sName, sizeof(sName), "SPC ");
        } else if(iKey == 58) {
            stbsp_snprintf(sName, sizeof(sName), ":   ");
        } else if(iKey == 46) {
            stbsp_snprintf(sName, sizeof(sName), ".   ");
        } else if(iKey == 45) {
            stbsp_snprintf(sName, sizeof(sName), "-   ");
        }
    } else if(option_index_arg == 32 || option_index_arg == 33) {
        int iKey;

        if(option_index_arg == 32) {
            iKey = GetIsSoundEnabled() ? 1 : 0;
        } else {
            iKey = GetIsMusicEnabled() ? 1 : 0;
        }

        if(iKey) {
            stbsp_snprintf(sName, sizeof(sName), "ON  ");
        } else {
            stbsp_snprintf(sName, sizeof(sName), "OFF ");
        }
    }

    lua_pushstring(lua_state, sName);

    return 1;
}

static int set_config_option(lua_State* lua_state) {
    lua_Integer option_index_arg = luaL_checkinteger(lua_state, 1);
    lua_Integer key_arg = luaL_checkinteger(lua_state, 2);

    bool is_key_good = false;

    if(option_index_arg >= 0 && option_index_arg <= 5) {
        int iKey = (int)key_arg;

        if(iKey == 38 && option_index_arg == 0) {
            is_key_good = true;
        }

        if(iKey == 40 && option_index_arg == 1) {
            is_key_good = true;
        }

        if(iKey == 37 && option_index_arg == 2) {
            is_key_good = true;
        }

        if(iKey == 39 && option_index_arg == 3) {
            is_key_good = true;
        }

        if(iKey == 32 && option_index_arg == 4) {
            is_key_good = true;
        }

        if(iKey >= 'A' && iKey <= 'Z') {
            is_key_good = true;
        }

        if(iKey >= '0' && iKey <= '9') {
            is_key_good = true;
        }

        long iLoop = -1;

        while(++iLoop < 6) {
            if(option_index_arg != iLoop && GetKeyBinding(iLoop) == iKey) {
                is_key_good = false;
            }
        }

        if(is_key_good) {
            SetKeyBinding((size_t)option_index_arg, iKey);
        }
    }

    if(option_index_arg == 32) {
        SetIsSoundEnabled(key_arg ? true : false);
        is_key_good = true;
    }

    if(option_index_arg == 33 && (GetIsMusicEnabled() ? 1 : 0) != key_arg) {
        if(key_arg == 0) {
            StopMusic1();
        } else {
            NewTrack1(g_music_background_track_filename, 0, 0);
        }

        SetIsMusicEnabled(key_arg ? true : false);
        is_key_good = true;
    }

    lua_pushboolean(lua_state, is_key_good);

    return 1;
}

static int save_config_options(lua_State* lua_state) {
    SaveSettings();
    return 0;
}

static int script_load_menu(lua_State* lua_state) {
    lua_Integer menu_type_arg = luaL_checkinteger(lua_state, 1);

    g_game_status = kGameStatusMenu;
    g_target_game_menu_state = (GameMenuState)menu_type_arg;

    if (menu_type_arg == kGameMenuStateMain) {
        lua_Integer track_type_arg = luaL_checkinteger(lua_state, 2);
        g_target_menu_selected_music = (GameMenuMusicState)track_type_arg;
    }

    return 0;
}

static int script_game_start(lua_State* lua_state) {
    lua_Integer title_index_arg = luaL_checkinteger(lua_state, 1);
    char game_base_path[300];

    if(!GetWorkingDirectoryPath(game_base_path)) {  // TODO: Should this be passed in from main.c somehow?
        // TODO: Proper error handling
        return 0;
    }

    char sFileName[300];
    g_remaining_life_count = 7;  // TODO: Setting this value should probably be elsewhere
    stbsp_snprintf(sFileName, sizeof(sFileName), "%s/Data", game_base_path);

    cf_dir_t dir;
    cf_dir_open(&dir, sFileName);

    cf_file_t file;

    // TODO: Error checking.
    // Error shouldn't happen since .jmg files are queried before this is run,
    // but could if file or dir was deleted/locked after campaign menu displayed, but before selected

    while(dir.has_next) {  // Find first result
        cf_file_t first_file;
        cf_read_file(&dir, &first_file);
        cf_dir_next(&dir);

        if(cf_match_ext(&first_file, ".jmg")) {
            file = first_file;
            break;
        }
    }

    int iTitle = 0;

    while(dir.has_next && iTitle < title_index_arg) {
        cf_read_file(&dir, &file);

        if(cf_match_ext(&file, ".jmg")) {
            iTitle = iTitle + 1;
        }

        cf_dir_next(&dir);
    }

    stbsp_snprintf(g_level_set_current_set_filename, sizeof(g_level_set_current_set_filename), "%s/Data/%s", game_base_path, file.name);
    g_game_status = kGameStatusInLevel;

    return 0;
}

static int get_credit_line(lua_State* lua_state) {
    char game_base_path[300];

    if (!GetWorkingDirectoryPath(game_base_path)) {  // TODO: Should this be passed in from main.c somehow?
        // TODO: Proper error handling
        return 0;
    }

    char sFileName[300];
    char sName[100];

    lua_Integer arg_line_index = luaL_checkinteger(lua_state, 1);

    stbsp_snprintf(sFileName, sizeof(sFileName), "%s/Data/credits.txt", game_base_path);

    if(GetFileLine(sName, sizeof(sName), sFileName, (int)arg_line_index)) {
        lua_pushboolean(lua_state, true);
        lua_pushstring(lua_state, sName);
        return 2;
    } else {
        lua_pushboolean(lua_state, false);
        return 1;
    }
}

static int script_get_game_list(lua_State* lua_state) {
    char game_base_path[300];

    if(!GetWorkingDirectoryPath(game_base_path)) {  // TODO: Should this be passed in from main.c somehow?
        // TODO: Proper error handling
        return 0;
    }

    char sFileName[300];
    stbsp_snprintf(sFileName, sizeof(sFileName), "%s/Data", game_base_path);

    cf_dir_t dir;
    cf_dir_open(&dir, sFileName);

    lua_newtable(lua_state);
    int iTitle = 0;

    while(dir.has_next) {
        cf_file_t file = { 0 };
        cf_read_file(&dir, &file);

        if(cf_match_ext(&file, ".jmg")) {
            char sFile[300];
            char sName[100];

            stbsp_snprintf(sFile, sizeof(sFile), "%s/Data/%s", game_base_path, file.name);
            GetFileLine(sName, sizeof(sName), sFile, 0);
            lua_pushstring(lua_state, sName);
            lua_rawseti(lua_state, -2, 1 + iTitle);
            ++iTitle;
        }

        cf_dir_next(&dir);
    }

    return 1;
}

static int play_sound_effect(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    PlaySoundEffect((size_t)arg1);
    return 0;
}

static int script_kill(lua_State* lua_state) {
    if(!(g_player_current_state & kPlayerStateDying)) {
        StopMusic1();
        g_player_current_state = kPlayerStateDying;
        g_player_current_special_action = kPlayerSpecialActionNone;
        g_player_dying_animation_state = kPlayerDyingAnimationStateFalling;
        g_player_dying_animation_state_frame_count = 0;
        g_player_velocity_x = 0;
        g_player_absolute_frame_count = g_player_current_state_frame_count;
        g_player_current_state_frame_count = 1000;
    }

    return 0;
}

static int script_win(lua_State* lua_state) {
    StopMusic1();
    g_player_current_state_frame_count = 0;
    g_player_current_state = kPlayerStateDone;
    return 0;
}

// TODO: Maybe return the id instead of global "selected" state for this
static int script_select_object_mesh(lua_State* lua_state) {
    double mesh_index = luaL_checknumber(lua_state, 1);
    g_script_selected_mesh_index = (long)mesh_index;
    return 0;
}

static int script_delete_mesh(lua_State* lua_state) {
    double mesh_index = luaL_checknumber(lua_state, 1);
    DeleteMesh((long)mesh_index);
    return 0;
}

static int script_reset_perspective(lua_State* lua_state) {
    SetGamePerspective();
    return 0;
}

// TODO: Maybe return the id instead of global "selected" state for all these
static int script_select_platform(lua_State* lua_state) {
    double new_object_index = luaL_checknumber(lua_state, 1);
    int object_index = FindObject(g_platform_objects, g_platform_object_count, (int)new_object_index);
    g_script_selected_level_object = &g_platform_objects[object_index];
    g_script_selected_mesh_index = g_script_selected_level_object->MeshNumber;
    return 0;
}

static int script_select_ladder(lua_State* lua_state) {
    double new_object_index = luaL_checknumber(lua_state, 1);
    int object_index = FindObject(g_ladder_objects, g_ladder_object_count, (int)new_object_index);
    g_script_selected_level_object = &g_ladder_objects[object_index];
    g_script_selected_mesh_index = g_script_selected_level_object->MeshNumber;
    return 0;
}

static int script_select_donut(lua_State* lua_state) {
    double new_object_index = luaL_checknumber(lua_state, 1);
    int object_index = FindObject(g_donut_objects, g_donut_object_count, (int)new_object_index);
    g_script_selected_level_object = &g_donut_objects[object_index];
    g_script_selected_mesh_index = g_script_selected_level_object->MeshNumber;
    return 0;
}

static int script_select_vine(lua_State* lua_state) {
    double new_object_index = luaL_checknumber(lua_state, 1);
    int object_index = FindObject(g_vine_objects, g_vine_object_count, (int)new_object_index);
    g_script_selected_level_object = &g_vine_objects[object_index];
    g_script_selected_mesh_index = g_script_selected_level_object->MeshNumber;
    return 0;
}

static int script_select_picture(lua_State* lua_state) {
    double new_object_index = luaL_checknumber(lua_state, 1);
    int object_index = FindObject(g_backdrop_objects, g_backdrop_object_count, (int)new_object_index);
    g_script_selected_level_object = &g_backdrop_objects[object_index];
    g_script_selected_mesh_index = g_script_selected_level_object->MeshNumber;
    return 0;
}

static int script_select_wall(lua_State* lua_state) {
    double new_object_index = luaL_checknumber(lua_state, 1);
    int object_index = FindObject(g_wall_objects, g_wall_object_count, (int)new_object_index);
    g_script_selected_level_object = &g_wall_objects[object_index];
    g_script_selected_mesh_index = g_script_selected_level_object->MeshNumber;
    return 0;
}

static void RegisterLuaScriptFunctions(lua_State* lua_state) {
    // TODO: Add all engine functions to a (read-only) global table instead of directly exposing in the global context.
    //       List of remaining exposed functions will be lower-level at that point, so will be important to distinguish.

    // TODO: These are temporary, may be able to remove most of them soon, after level loading etc are in script
    lua_pushcfunction(lua_state, get_donut_mesh_number);
    lua_setglobal(lua_state, "get_donut_mesh_number");
    lua_pushcfunction(lua_state, get_donut_number);
    lua_setglobal(lua_state, "get_donut_number");
    lua_pushcfunction(lua_state, get_donut_texture_index);
    lua_setglobal(lua_state, "get_donut_texture_index");
    lua_pushcfunction(lua_state, get_donut_is_visible);
    lua_setglobal(lua_state, "get_donut_is_visible");
    lua_pushcfunction(lua_state, get_donut_x1);
    lua_setglobal(lua_state, "get_donut_x1");
    lua_pushcfunction(lua_state, get_donut_y1);
    lua_setglobal(lua_state, "get_donut_y1");
    lua_pushcfunction(lua_state, get_ladder_x1);
    lua_setglobal(lua_state, "get_ladder_x1");
    lua_pushcfunction(lua_state, get_ladder_y1);
    lua_setglobal(lua_state, "get_ladder_y1");
    lua_pushcfunction(lua_state, get_ladder_y2);
    lua_setglobal(lua_state, "get_ladder_y2");
    lua_pushcfunction(lua_state, get_ladder_z1);
    lua_setglobal(lua_state, "get_ladder_z1");
    lua_pushcfunction(lua_state, get_vine_x1);
    lua_setglobal(lua_state, "get_vine_x1");
    lua_pushcfunction(lua_state, get_vine_y1);
    lua_setglobal(lua_state, "get_vine_y1");
    lua_pushcfunction(lua_state, get_vine_y2);
    lua_setglobal(lua_state, "get_vine_y2");
    lua_pushcfunction(lua_state, get_vine_z1);
    lua_setglobal(lua_state, "get_vine_z1");
    lua_pushcfunction(lua_state, get_platform_extra);
    lua_setglobal(lua_state, "get_platform_extra");
    lua_pushcfunction(lua_state, get_platform_x1);
    lua_setglobal(lua_state, "get_platform_x1");
    lua_pushcfunction(lua_state, get_platform_x2);
    lua_setglobal(lua_state, "get_platform_x2");
    lua_pushcfunction(lua_state, get_platform_y1);
    lua_setglobal(lua_state, "get_platform_y1");
    lua_pushcfunction(lua_state, get_platform_y2);
    lua_setglobal(lua_state, "get_platform_y2");
    lua_pushcfunction(lua_state, get_platform_z1);
    lua_setglobal(lua_state, "get_platform_z1");
    lua_pushcfunction(lua_state, get_wall_x1);
    lua_setglobal(lua_state, "get_wall_x1");
    lua_pushcfunction(lua_state, get_wall_x2);
    lua_setglobal(lua_state, "get_wall_x2");
    lua_pushcfunction(lua_state, get_wall_x3);
    lua_setglobal(lua_state, "get_wall_x3");
    lua_pushcfunction(lua_state, get_wall_x4);
    lua_setglobal(lua_state, "get_wall_x4");
    lua_pushcfunction(lua_state, get_wall_y1);
    lua_setglobal(lua_state, "get_wall_y1");
    lua_pushcfunction(lua_state, get_wall_y2);
    lua_setglobal(lua_state, "get_wall_y2");
    lua_pushcfunction(lua_state, get_wall_y3);
    lua_setglobal(lua_state, "get_wall_y3");
    lua_pushcfunction(lua_state, get_wall_y4);
    lua_setglobal(lua_state, "get_wall_y4");
    lua_pushcfunction(lua_state, game_over);
    lua_setglobal(lua_state, "game_over");
    lua_pushcfunction(lua_state, restart_music_track_1);
    lua_setglobal(lua_state, "restart_music_track_1");
    lua_pushcfunction(lua_state, play_death_music_track);
    lua_setglobal(lua_state, "play_death_music_track");
    lua_pushcfunction(lua_state, stop_music_track_1);
    lua_setglobal(lua_state, "stop_music_track_1");
    lua_pushcfunction(lua_state, get_game_time_inactive);
    lua_setglobal(lua_state, "get_game_time_inactive");
    lua_pushcfunction(lua_state, get_player_absolute_frame_count);
    lua_setglobal(lua_state, "get_player_absolute_frame_count");
    lua_pushcfunction(lua_state, set_player_absolute_frame_count);
    lua_setglobal(lua_state, "set_player_absolute_frame_count");
    lua_pushcfunction(lua_state, get_player_current_mesh);
    lua_setglobal(lua_state, "get_player_current_mesh");
    lua_pushcfunction(lua_state, set_player_current_mesh);
    lua_setglobal(lua_state, "set_player_current_mesh");
    lua_pushcfunction(lua_state, set_player_current_rotation_x_radians);
    lua_setglobal(lua_state, "set_player_current_rotation_x_radians");
    lua_pushcfunction(lua_state, get_player_dying_animation_state);
    lua_setglobal(lua_state, "get_player_dying_animation_state");
    lua_pushcfunction(lua_state, set_player_dying_animation_state);
    lua_setglobal(lua_state, "set_player_dying_animation_state");
    lua_pushcfunction(lua_state, get_player_dying_animation_state_frame_count);
    lua_setglobal(lua_state, "get_player_dying_animation_state_frame_count");
    lua_pushcfunction(lua_state, set_player_dying_animation_state_frame_count);
    lua_setglobal(lua_state, "set_player_dying_animation_state_frame_count");
    lua_pushcfunction(lua_state, get_player_mesh_index);
    lua_setglobal(lua_state, "get_player_mesh_index");
    lua_pushcfunction(lua_state, get_player_no_roll_cooldown_frame_count);
    lua_setglobal(lua_state, "get_player_no_roll_cooldown_frame_count");
    lua_pushcfunction(lua_state, get_player_current_velocity_x);
    lua_setglobal(lua_state, "get_player_current_velocity_x");
    lua_pushcfunction(lua_state, set_player_current_velocity_x);
    lua_setglobal(lua_state, "set_player_current_velocity_x");
    lua_pushcfunction(lua_state, get_just_launched_game);
    lua_setglobal(lua_state, "get_just_launched_game");

    // TODO: Remove the word "script" when exposing these functions?
    lua_pushcfunction(lua_state, script_selected_mesh_change_mesh);
    lua_setglobal(lua_state, "script_selected_mesh_change_mesh");
    lua_pushcfunction(lua_state, script_selected_mesh_set_identity_matrix);
    lua_setglobal(lua_state, "script_selected_mesh_set_identity_matrix");
    lua_pushcfunction(lua_state, script_selected_mesh_set_perspective_matrix);
    lua_setglobal(lua_state, "script_selected_mesh_set_perspective_matrix");
    lua_pushcfunction(lua_state, script_selected_mesh_translate_matrix);
    lua_setglobal(lua_state, "script_selected_mesh_translate_matrix");
    lua_pushcfunction(lua_state, script_selected_mesh_scale_matrix);
    lua_setglobal(lua_state, "script_selected_mesh_scale_matrix");
    lua_pushcfunction(lua_state, script_selected_mesh_rotate_matrix_x);
    lua_setglobal(lua_state, "script_selected_mesh_rotate_matrix_x");
    lua_pushcfunction(lua_state, script_selected_mesh_rotate_matrix_y);
    lua_setglobal(lua_state, "script_selected_mesh_rotate_matrix_y");
    lua_pushcfunction(lua_state, script_selected_mesh_rotate_matrix_z);
    lua_setglobal(lua_state, "script_selected_mesh_rotate_matrix_z");
    lua_pushcfunction(lua_state, script_selected_mesh_scroll_texture);
    lua_setglobal(lua_state, "script_selected_mesh_scroll_texture");
    lua_pushcfunction(lua_state, get_navigation_dir);
    lua_setglobal(lua_state, "get_navigation_dir");

    lua_pushcfunction(lua_state, get_script_selected_level_object_extra);
    lua_setglobal(lua_state, "get_script_selected_level_object_extra");
    lua_pushcfunction(lua_state, get_script_selected_level_object_number);
    lua_setglobal(lua_state, "get_script_selected_level_object_number");
    lua_pushcfunction(lua_state, get_script_selected_level_object_this);
    lua_setglobal(lua_state, "get_script_selected_level_object_this");
    lua_pushcfunction(lua_state, get_script_selected_level_object_visible);
    lua_setglobal(lua_state, "get_script_selected_level_object_visible");
    lua_pushcfunction(lua_state, get_script_selected_level_object_x1);
    lua_setglobal(lua_state, "get_script_selected_level_object_x1");
    lua_pushcfunction(lua_state, get_script_selected_level_object_x2);
    lua_setglobal(lua_state, "get_script_selected_level_object_x2");
    lua_pushcfunction(lua_state, get_script_selected_level_object_y1);
    lua_setglobal(lua_state, "get_script_selected_level_object_y1");
    lua_pushcfunction(lua_state, get_script_selected_level_object_y2);
    lua_setglobal(lua_state, "get_script_selected_level_object_y2");
    lua_pushcfunction(lua_state, get_script_selected_level_object_z1);
    lua_setglobal(lua_state, "get_script_selected_level_object_z1");
    lua_pushcfunction(lua_state, get_script_selected_level_object_z2);
    lua_setglobal(lua_state, "get_script_selected_level_object_z2");
    lua_pushcfunction(lua_state, set_script_selected_level_object_number);
    lua_setglobal(lua_state, "set_script_selected_level_object_number");
    lua_pushcfunction(lua_state, set_script_selected_level_object_texture);
    lua_setglobal(lua_state, "set_script_selected_level_object_texture");
    lua_pushcfunction(lua_state, set_script_selected_level_object_visible);
    lua_setglobal(lua_state, "set_script_selected_level_object_visible");
    lua_pushcfunction(lua_state, set_script_selected_level_object_x1);
    lua_setglobal(lua_state, "set_script_selected_level_object_x1");
    lua_pushcfunction(lua_state, set_script_selected_level_object_x2);
    lua_setglobal(lua_state, "set_script_selected_level_object_x2");
    lua_pushcfunction(lua_state, set_script_selected_level_object_y1);
    lua_setglobal(lua_state, "set_script_selected_level_object_y1");
    lua_pushcfunction(lua_state, set_script_selected_level_object_y2);
    lua_setglobal(lua_state, "set_script_selected_level_object_y2");
    lua_pushcfunction(lua_state, set_script_selected_level_object_z1);
    lua_setglobal(lua_state, "set_script_selected_level_object_z1");
    lua_pushcfunction(lua_state, set_script_selected_level_object_z2);
    lua_setglobal(lua_state, "set_script_selected_level_object_z2");

    lua_pushcfunction(lua_state, get_current_camera_mode);
    lua_setglobal(lua_state, "get_current_camera_mode");
    lua_pushcfunction(lua_state, get_donut_object_count);
    lua_setglobal(lua_state, "get_donut_object_count");
    lua_pushcfunction(lua_state, get_ladder_object_count);
    lua_setglobal(lua_state, "get_ladder_object_count");
    lua_pushcfunction(lua_state, get_level_extent_x);
    lua_setglobal(lua_state, "get_level_extent_x");
    lua_pushcfunction(lua_state, get_loaded_texture_count);
    lua_setglobal(lua_state, "get_loaded_texture_count");
    lua_pushcfunction(lua_state, get_platform_object_count);
    lua_setglobal(lua_state, "get_platform_object_count");
    lua_pushcfunction(lua_state, get_player_current_position_x);
    lua_setglobal(lua_state, "get_player_current_position_x");
    lua_pushcfunction(lua_state, get_player_current_position_y);
    lua_setglobal(lua_state, "get_player_current_position_y");
    lua_pushcfunction(lua_state, get_player_current_position_z);
    lua_setglobal(lua_state, "get_player_current_position_z");
    lua_pushcfunction(lua_state, get_player_current_special_action);
    lua_setglobal(lua_state, "get_player_current_special_action");
    lua_pushcfunction(lua_state, get_player_current_state);
    lua_setglobal(lua_state, "get_player_current_state");
    lua_pushcfunction(lua_state, get_player_current_state_frame_count);
    lua_setglobal(lua_state, "get_player_current_state_frame_count");
    lua_pushcfunction(lua_state, get_player_freeze_cooldown_frame_count);
    lua_setglobal(lua_state, "get_player_freeze_cooldown_frame_count");
    lua_pushcfunction(lua_state, get_player_is_visible);
    lua_setglobal(lua_state, "get_player_is_visible");
    lua_pushcfunction(lua_state, get_remaining_life_count);
    lua_setglobal(lua_state, "get_remaining_life_count");
    lua_pushcfunction(lua_state, get_vine_object_count);
    lua_setglobal(lua_state, "get_vine_object_count");
    lua_pushcfunction(lua_state, get_wall_object_count);
    lua_setglobal(lua_state, "get_wall_object_count");
    lua_pushcfunction(lua_state, get_script_object_count);
    lua_setglobal(lua_state, "get_script_object_count");
    lua_pushcfunction(lua_state, get_is_sound_enabled);
    lua_setglobal(lua_state, "get_is_sound_enabled");
    lua_pushcfunction(lua_state, get_is_music_enabled);
    lua_setglobal(lua_state, "get_is_music_enabled");
    lua_pushcfunction(lua_state, get_last_key_pressed);
    lua_setglobal(lua_state, "get_last_key_pressed");
    lua_pushcfunction(lua_state, get_current_fps);
    lua_setglobal(lua_state, "get_current_fps");
    lua_pushcfunction(lua_state, set_current_camera_mode);
    lua_setglobal(lua_state, "set_current_camera_mode");
    lua_pushcfunction(lua_state, set_level_extent_x);
    lua_setglobal(lua_state, "set_level_extent_x");
    lua_pushcfunction(lua_state, set_player_current_position_x);
    lua_setglobal(lua_state, "set_player_current_position_x");
    lua_pushcfunction(lua_state, set_player_current_position_y);
    lua_setglobal(lua_state, "set_player_current_position_y");
    lua_pushcfunction(lua_state, set_player_current_position_z);
    lua_setglobal(lua_state, "set_player_current_position_z");
    lua_pushcfunction(lua_state, set_player_current_special_action);
    lua_setglobal(lua_state, "set_player_current_special_action");
    lua_pushcfunction(lua_state, set_player_current_state);
    lua_setglobal(lua_state, "set_player_current_state");
    lua_pushcfunction(lua_state, set_player_current_state_frame_count);
    lua_setglobal(lua_state, "set_player_current_state_frame_count");
    lua_pushcfunction(lua_state, set_player_freeze_cooldown_frame_count);
    lua_setglobal(lua_state, "set_player_freeze_cooldown_frame_count");
    lua_pushcfunction(lua_state, set_player_is_visible);
    lua_setglobal(lua_state, "set_player_is_visible");
    lua_pushcfunction(lua_state, set_player_no_roll_cooldown_frame_count);
    lua_setglobal(lua_state, "set_player_no_roll_cooldown_frame_count");
    lua_pushcfunction(lua_state, set_remaining_life_count);
    lua_setglobal(lua_state, "set_remaining_life_count");

    lua_pushcfunction(lua_state, new_mesh);
    lua_setglobal(lua_state, "new_mesh");
    lua_pushcfunction(lua_state, new_char_mesh);
    lua_setglobal(lua_state, "new_char_mesh");
    lua_pushcfunction(lua_state, set_object_visual_data);
    lua_setglobal(lua_state, "set_object_visual_data");
    lua_pushcfunction(lua_state, prioritize_object);
    lua_setglobal(lua_state, "prioritize_object");
    lua_pushcfunction(lua_state, script_abs_platform);
    lua_setglobal(lua_state, "abs_platform");
    lua_pushcfunction(lua_state, script_abs_ladder);
    lua_setglobal(lua_state, "abs_ladder");
    lua_pushcfunction(lua_state, script_abs_donut);
    lua_setglobal(lua_state, "abs_donut");
    lua_pushcfunction(lua_state, script_abs_vine);
    lua_setglobal(lua_state, "abs_vine");
    lua_pushcfunction(lua_state, script_set_fog);
    lua_setglobal(lua_state, "set_fog");
    lua_pushcfunction(lua_state, script_get_current_level_title);
    lua_setglobal(lua_state, "get_current_level_title");
    lua_pushcfunction(lua_state, get_config_option_string);
    lua_setglobal(lua_state, "get_config_option_string");
    lua_pushcfunction(lua_state, set_config_option);
    lua_setglobal(lua_state, "set_config_option");
    lua_pushcfunction(lua_state, save_config_options);
    lua_setglobal(lua_state, "save_config_options");
    lua_pushcfunction(lua_state, script_load_menu);
    lua_setglobal(lua_state, "load_menu");
    lua_pushcfunction(lua_state, script_game_start);
    lua_setglobal(lua_state, "game_start");
    lua_pushcfunction(lua_state, get_credit_line);
    lua_setglobal(lua_state, "get_credit_line");
    lua_pushcfunction(lua_state, script_get_game_list);
    lua_setglobal(lua_state, "get_game_list");
    lua_pushcfunction(lua_state, play_sound_effect);
    lua_setglobal(lua_state, "play_sound_effect");
    lua_pushcfunction(lua_state, script_kill);
    lua_setglobal(lua_state, "kill");
    lua_pushcfunction(lua_state, script_win);
    lua_setglobal(lua_state, "win");
    lua_pushcfunction(lua_state, script_select_object_mesh);
    lua_setglobal(lua_state, "select_object_mesh");
    lua_pushcfunction(lua_state, script_delete_mesh);
    lua_setglobal(lua_state, "delete_mesh");
    lua_pushcfunction(lua_state, script_reset_perspective);
    lua_setglobal(lua_state, "reset_perspective");
    lua_pushcfunction(lua_state, script_select_platform);
    lua_setglobal(lua_state, "select_platform");
    lua_pushcfunction(lua_state, script_select_ladder);
    lua_setglobal(lua_state, "select_ladder");
    lua_pushcfunction(lua_state, script_select_donut);
    lua_setglobal(lua_state, "select_donut");
    lua_pushcfunction(lua_state, script_select_vine);
    lua_setglobal(lua_state, "select_vine");
    lua_pushcfunction(lua_state, script_select_picture);
    lua_setglobal(lua_state, "select_picture");
    lua_pushcfunction(lua_state, script_select_wall);
    lua_setglobal(lua_state, "select_wall");
}

static void LoadLuaScript(const char* base_path, const char* filename, lua_State** new_lua_state) {
    assert(new_lua_state != NULL);  // TODO: Error handling

    if(*new_lua_state != NULL) {
        lua_close(*new_lua_state);
    }

    char full_filename[300];  // TODO: Standardize path lengths? Bigger paths?
    stbsp_snprintf(full_filename, sizeof(full_filename), "%s/%s", base_path, filename);

    lua_State* new_state;
    new_state = luaL_newstate();
    assert(new_state != NULL);  // TODO: Error handling

    luaL_openlibs(new_state);
    int load_file_result = luaL_loadfile(new_state, full_filename);
    if(load_file_result != 0) {
        const char* error_message = lua_tostring(new_state, -1);
        assert(false);  // TODO: Error handling
    }

    RegisterLuaScriptFunctions(new_state);

    if (lua_pcall(new_state, 0, 0, 0) != 0) {
        const char* error_message = lua_tostring(new_state, -1);
        assert(false);  // TODO: Error handling
    }

    *new_lua_state = new_state;
}

static void PushGameActionAsTable(lua_State* lua_state, GameAction* game_action) {
    lua_newtable(lua_state);
    lua_pushboolean(lua_state, game_action->is_pressed);
    lua_setfield(lua_state, -2, "is_pressed");
    lua_pushboolean(lua_state, game_action->just_pressed);
    lua_setfield(lua_state, -2, "just_pressed");
}

static void PushGameInputAsTable(lua_State* lua_state, GameInput* game_input) {
    lua_newtable(lua_state);
    PushGameActionAsTable(lua_state, &game_input->move_left_action);
    lua_setfield(lua_state, -2, "move_left_action");
    PushGameActionAsTable(lua_state, &game_input->move_right_action);
    lua_setfield(lua_state, -2, "move_right_action");
    PushGameActionAsTable(lua_state, &game_input->move_down_action);
    lua_setfield(lua_state, -2, "move_down_action");
    PushGameActionAsTable(lua_state, &game_input->move_up_action);
    lua_setfield(lua_state, -2, "move_up_action");
    PushGameActionAsTable(lua_state, &game_input->jump_action);
    lua_setfield(lua_state, -2, "jump_action");
    PushGameActionAsTable(lua_state, &game_input->attack_action);
    lua_setfield(lua_state, -2, "attack_action");
    PushGameActionAsTable(lua_state, &game_input->select_action);
    lua_setfield(lua_state, -2, "select_action");
    PushGameActionAsTable(lua_state, &game_input->debug_action);
    lua_setfield(lua_state, -2, "debug_action");
}

static void CallLuaFunction(lua_State* lua_state, const char* function_name, GameInput* game_input, bool is_required) {
    lua_getglobal(lua_state, function_name);

    if(lua_isfunction(lua_state, -1) != 0) {
        PushGameInputAsTable(lua_state, game_input);

        if(lua_pcall(lua_state, 1, 0, 0) != 0) {
            const char* error_message = lua_tostring(lua_state, -1);
            assert(false);  // TODO: Error handling
        }
    } else {
        if(is_required) {
            assert(false);  // TODO: Error handling
        }
    }
}

static void CallLuaGameUpdate(lua_State* lua_state, GameInput* game_input, bool is_initializing) {
    lua_getglobal(lua_state, "update");

    if(lua_isfunction(lua_state, -1) != 0) {
        if(is_initializing) {
            // Don't pass real input to initialization "Update" calls
            GameInput empty_input = { 0 };
            PushGameInputAsTable(lua_state, &empty_input);
        } else {
            PushGameInputAsTable(lua_state, game_input);
        }

        lua_pushboolean(lua_state, is_initializing);

        if(lua_pcall(lua_state, 2, 0, 0) != 0) {
            const char* error_message = lua_tostring(lua_state, -1);
            assert(false);  // TODO: Error handling
        }
    } else {
        // Function is required
        assert(false);  // TODO: Error handling
    }
}

static void LoadLevel(const char* base_path, const char* filename) {
    char full_path[300];
    stbsp_snprintf(full_path, sizeof(full_path), "%s/%s", base_path, filename);

    unsigned char* cData;

    char sTemp[300];

    long iLen;
    int iPlace;
    long iData;
    char sBuild[200];
    long iTemp;
    long iArg1;
    long iArg2;

    long* oData;
    long iMPlace;
    int iSounds;

    g_player_freeze_cooldown_frame_count = 0;
    g_player_no_roll_cooldown_frame_count = 0;
    g_player_is_visible = true;

    g_level_extent_x = 160;
    g_level_extent_y = 160;

    g_current_camera_mode = kCameraModeNormal;
    g_loaded_texture_count = 0;
    g_loaded_mesh_count = 0;
    g_loaded_script_count = 0;
    iSounds = 0;

    if(g_script_level_script_lua_state != NULL) {
        lua_close(g_script_level_script_lua_state);
        g_script_level_script_lua_state = NULL;
    }

    g_platform_object_count = 0;
    g_ladder_object_count = 0;
    g_donut_object_count = 0;
    g_vine_object_count = 0;
    g_wall_object_count = 0;
    g_backdrop_object_count = 0;

    cData = NULL;
    iLen = FileToString(full_path, &cData);

    iPlace = 0;

    while(iPlace < iLen) {
        sTemp[8] = 0;

        if(cData[iPlace] == 'R' && cData[iPlace + 1] == 0) {
            iPlace += 2;
            int iLoop = -1;

            while(++iLoop < 30) {
                sTemp[iLoop] = cData[iPlace + iLoop];
            }

            iPlace += 30;

            iTemp = StringToInt(&cData[iPlace + 0]);
            iArg1 = StringToInt(&cData[iPlace + 2]);
            iArg2 = StringToInt(&cData[iPlace + 4]);

            if(iTemp == 1) {
                stbsp_snprintf(sBuild, sizeof(sBuild), "%s/Sound/%s.MID", base_path, sTemp);

                if(iArg1 == 1) {
                    stbsp_snprintf(g_music_background_track_filename, sizeof(g_music_background_track_filename), "%s", sBuild);
                    g_music_loop_start_music_time = (int)iArg2 * 10;
                }

                if(iArg1 == 2) {
                    stbsp_snprintf(g_music_death_track_filename, sizeof(g_music_death_track_filename), "%s", sBuild);
                }

                if(iArg1 == 3) {
                    stbsp_snprintf(g_music_win_track_filename, sizeof(g_music_win_track_filename), "%s", sBuild);
                }
            }

            if(iTemp == 2) {
                stbsp_snprintf(sBuild, sizeof(sBuild), "%s.MSH", sTemp);
                g_script_mesh_indices[g_loaded_mesh_count] = LoadMesh(base_path, sBuild);
                ++g_loaded_mesh_count;
            }

            if(iTemp == 7) {
                stbsp_snprintf(sBuild, sizeof(sBuild), "%s/Sound/%s.WAV", base_path, sTemp);
                LoadSound(sBuild, iSounds);
                ++iSounds;
            }

            if(iTemp == 3 || iTemp == 4 || iTemp == 6) {
                stbsp_snprintf(sBuild, sizeof(sBuild), "%s/Data/%s", base_path, sTemp);

                if(iTemp == 3) {
                    stbsp_snprintf(sBuild, sizeof(sBuild), "%s%s", sBuild, ".BMP");
                }

                if(iTemp == 4) {
                    stbsp_snprintf(sBuild, sizeof(sBuild), "%s%s", sBuild, ".JPG");
                }

                if(iTemp == 6) {
                    stbsp_snprintf(sBuild, sizeof(sBuild), "%s%s", sBuild, ".PNG");
                }

                LoadTexture(g_loaded_texture_count, sBuild, iArg1, (iTemp == 6) || (iTemp == 3 && iArg1 == 1));
                ++g_loaded_texture_count;
            }

            if(iTemp == 5) {
                if(iArg1 == 1) {
                    assert(false);  // "Trying to load a JMS level script. Should not be the case in any existing level."
                } else if(iArg1 == 2) {
                    // TODO: No-op for now
                    // assert(false, "Trying to load a JMS level script. Should not be the case in any existing level.");
                } else if(iArg1 == 3) {
                    stbsp_snprintf(sBuild, sizeof(sBuild), "Data/%s.LUA", sTemp);
                    // TODO: Should it auto-unload the old script?
                    LoadLuaScript(base_path, sBuild, &g_script_level_script_lua_state);
                } else if(iArg1 == 4) {
                    // TODO: No-op for now. These are managed inside level scripts, so no need to load them separately
                } else {
                    // TODO: Log error, do something to signal to game that it can't load the level
                }
            }

            iPlace += 8;
        } else if(cData[iPlace] == 'A' && cData[iPlace + 1] == 0) {
            iPlace += 10;

            g_backdrop_objects[g_backdrop_object_count].Texture = StringToInt(&cData[iPlace + 0]);
            g_backdrop_objects[g_backdrop_object_count].X1 = StringToInt(&cData[iPlace + 2]);
            g_backdrop_objects[g_backdrop_object_count].Y1 = StringToInt(&cData[iPlace + 4]);
            g_backdrop_objects[g_backdrop_object_count].Num = StringToInt(&cData[iPlace + 6]);
            g_backdrop_objects[g_backdrop_object_count].Visible = 1;
            iPlace += 20;

            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            g_backdrop_objects[g_backdrop_object_count].Mesh = (long*)(malloc(iData * sizeof(long)));
            g_backdrop_objects[g_backdrop_object_count].MeshSize = iData;
            g_backdrop_objects[g_backdrop_object_count].ObjectNumber = g_backdrop_object_count;

            long iNum = -1;

            while(++iNum < iData) {
                g_backdrop_objects[g_backdrop_object_count].Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            oData = (long*)(malloc(g_backdrop_objects[g_backdrop_object_count].MeshSize * sizeof(long)));
            iMPlace = 0;
            ComposeObject(&g_backdrop_objects[g_backdrop_object_count], oData, &iMPlace);
            CreateObject(oData, iMPlace / 9, &iNum);
            SetObjectData(iNum, g_backdrop_objects[g_backdrop_object_count].Texture, g_backdrop_objects[g_backdrop_object_count].Visible);

            g_backdrop_objects[g_backdrop_object_count].MeshNumber = iNum;
            free(oData);

            ++g_backdrop_object_count;
        } else if(cData[iPlace] == 'L' && cData[iPlace + 1] == 0) {
            int iLoop = -1;

            while(++iLoop < 8) {
                g_ladder_objects[g_ladder_object_count].Func[iLoop] = cData[iPlace + 2 + iLoop];
            }

            iPlace += 10;

            g_ladder_objects[g_ladder_object_count].Visible = 1;
            g_ladder_objects[g_ladder_object_count].X1 = StringToInt(&cData[iPlace + 0]);
            g_ladder_objects[g_ladder_object_count].Y1 = StringToInt(&cData[iPlace + 2]);
            g_ladder_objects[g_ladder_object_count].Y2 = StringToInt(&cData[iPlace + 4]);
            g_ladder_objects[g_ladder_object_count].Z1 = StringToInt(&cData[iPlace + 6]);
            g_ladder_objects[g_ladder_object_count].Z2 = StringToInt(&cData[iPlace + 8]);
            g_ladder_objects[g_ladder_object_count].Num = StringToInt(&cData[iPlace + 10]);
            g_ladder_objects[g_ladder_object_count].Texture = StringToInt(&cData[iPlace + 12]);
            iPlace += 20;

            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            g_ladder_objects[g_ladder_object_count].Mesh = (long*)(malloc(iData * sizeof(long)));
            g_ladder_objects[g_ladder_object_count].MeshSize = iData;
            g_ladder_objects[g_ladder_object_count].ObjectNumber = g_ladder_object_count;

            long iNum = -1;

            while(++iNum < iData) {
                g_ladder_objects[g_ladder_object_count].Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            oData = (long*)(malloc(g_ladder_objects[g_ladder_object_count].MeshSize * sizeof(long)));
            iMPlace = 0;
            ComposeObject(&g_ladder_objects[g_ladder_object_count], oData, &iMPlace);
            CreateObject(oData, iMPlace / 9, &iNum);
            SetObjectData(iNum, g_ladder_objects[g_ladder_object_count].Texture, g_ladder_objects[g_ladder_object_count].Visible);
            g_ladder_objects[g_ladder_object_count].MeshNumber = iNum;
            free(oData);

            ++g_ladder_object_count;
        } else if(cData[iPlace] == 'W' && cData[iPlace + 1] == 0) {
            int iLoop = -1;

            while(++iLoop < 8) {
                g_wall_objects[g_wall_object_count].Func[iLoop] = cData[iPlace + 2 + iLoop];
            }

            iPlace += 10;

            g_wall_objects[g_wall_object_count].Visible = 1;
            g_wall_objects[g_wall_object_count].X1 = StringToInt(&cData[iPlace + 0]);
            g_wall_objects[g_wall_object_count].Y1 = StringToInt(&cData[iPlace + 2]);
            g_wall_objects[g_wall_object_count].X2 = StringToInt(&cData[iPlace + 4]);
            g_wall_objects[g_wall_object_count].Y2 = StringToInt(&cData[iPlace + 6]);
            g_wall_objects[g_wall_object_count].X3 = StringToInt(&cData[iPlace + 8]);
            g_wall_objects[g_wall_object_count].Y3 = StringToInt(&cData[iPlace + 10]);
            g_wall_objects[g_wall_object_count].X4 = StringToInt(&cData[iPlace + 12]);
            g_wall_objects[g_wall_object_count].Y4 = StringToInt(&cData[iPlace + 14]);

            g_wall_objects[g_wall_object_count].Num = StringToInt(&cData[iPlace + 16]);
            g_wall_objects[g_wall_object_count].Texture = StringToInt(&cData[iPlace + 18]);

            iPlace += 20;

            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            g_wall_objects[g_wall_object_count].Mesh = (long*)(malloc(iData * sizeof(long)));
            g_wall_objects[g_wall_object_count].MeshSize = iData;
            g_wall_objects[g_wall_object_count].ObjectNumber = g_wall_object_count;

            long iNum = -1;

            while(++iNum < iData) {
                g_wall_objects[g_wall_object_count].Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            oData = (long*)(malloc(g_wall_objects[g_wall_object_count].MeshSize * sizeof(long)));
            iMPlace = 0;
            ComposeObject(&g_wall_objects[g_wall_object_count], oData, &iMPlace);
            CreateObject(oData, iMPlace / 9, &iNum);
            SetObjectData(iNum, g_wall_objects[g_wall_object_count].Texture, g_wall_objects[g_wall_object_count].Visible);
            g_wall_objects[g_wall_object_count].MeshNumber = iNum;
            free(oData);

            ++g_wall_object_count;
        } else if(cData[iPlace] == 'V' && cData[iPlace + 1] == 0) {
            int iLoop = -1;

            while(++iLoop < 8) {
                g_vine_objects[g_vine_object_count].Func[iLoop] = cData[iPlace + 2 + iLoop];
            }

            iPlace += 10;

            g_vine_objects[g_vine_object_count].Visible = 1;
            g_vine_objects[g_vine_object_count].X1 = StringToInt(&cData[iPlace + 0]);
            g_vine_objects[g_vine_object_count].Y1 = StringToInt(&cData[iPlace + 2]);
            g_vine_objects[g_vine_object_count].Y2 = StringToInt(&cData[iPlace + 4]);
            g_vine_objects[g_vine_object_count].Z1 = StringToInt(&cData[iPlace + 6]);
            g_vine_objects[g_vine_object_count].Z2 = StringToInt(&cData[iPlace + 8]);
            g_vine_objects[g_vine_object_count].Num = StringToInt(&cData[iPlace + 10]);
            g_vine_objects[g_vine_object_count].Texture = StringToInt(&cData[iPlace + 12]);
            iPlace += 20;

            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            g_vine_objects[g_vine_object_count].Mesh = (long*)(malloc(iData * sizeof(long)));
            g_vine_objects[g_vine_object_count].MeshSize = iData;
            g_vine_objects[g_vine_object_count].ObjectNumber = g_vine_object_count;

            long iNum = -1;

            while(++iNum < iData) {
                g_vine_objects[g_vine_object_count].Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            oData = (long*)(malloc(g_vine_objects[g_vine_object_count].MeshSize * sizeof(long)));
            iMPlace = 0;
            ComposeObject(&g_vine_objects[g_vine_object_count], oData, &iMPlace);
            CreateObject(oData, iMPlace / 9, &iNum);
            SetObjectData(iNum, g_vine_objects[g_vine_object_count].Texture, g_vine_objects[g_vine_object_count].Visible);
            g_vine_objects[g_vine_object_count].MeshNumber = iNum;
            free(oData);

            ++g_vine_object_count;
        } else if(cData[iPlace] == 'D' && cData[iPlace + 1] == 0) {
            int iLoop = -1;

            while(++iLoop < 8) {
                g_donut_objects[g_donut_object_count].Func[iLoop] = cData[iPlace + 2 + iLoop];
            }

            iPlace += 10;

            g_donut_objects[g_donut_object_count].Visible = 1;
            g_donut_objects[g_donut_object_count].X1 = StringToInt(&cData[iPlace + 0]);
            g_donut_objects[g_donut_object_count].Y1 = StringToInt(&cData[iPlace + 2]);
            g_donut_objects[g_donut_object_count].Z1 = StringToInt(&cData[iPlace + 4]);
            g_donut_objects[g_donut_object_count].Num = StringToInt(&cData[iPlace + 6]);
            g_donut_objects[g_donut_object_count].Texture = StringToInt(&cData[iPlace + 8]);
            iPlace += 20;

            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            g_donut_objects[g_donut_object_count].Mesh = (long*)(malloc(iData * sizeof(long)));
            g_donut_objects[g_donut_object_count].MeshSize = iData;
            g_donut_objects[g_donut_object_count].ObjectNumber = g_donut_object_count;

            long iNum = -1;

            while(++iNum < iData) {
                g_donut_objects[g_donut_object_count].Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            oData = (long*)(malloc(g_donut_objects[g_donut_object_count].MeshSize * sizeof(long)));
            iMPlace = 0;
            ComposeObject(&g_donut_objects[g_donut_object_count], oData, &iMPlace);
            CreateObject(oData, iMPlace / 9, &iNum);
            SetObjectData(iNum, g_donut_objects[g_donut_object_count].Texture, g_donut_objects[g_donut_object_count].Visible);
            g_donut_objects[g_donut_object_count].MeshNumber = iNum;
            free(oData);

            ++g_donut_object_count;
        } else if(cData[iPlace] == 'P' && cData[iPlace + 1] == 0) {
            int iLoop = -1;

            while(++iLoop < 8) {
                g_platform_objects[g_platform_object_count].Func[iLoop] = cData[iPlace + 2 + iLoop];
            }

            iPlace += 10;

            g_platform_objects[g_platform_object_count].Visible = 1;
            g_platform_objects[g_platform_object_count].X1 = StringToInt(&cData[iPlace + 0]);
            g_platform_objects[g_platform_object_count].Y1 = StringToInt(&cData[iPlace + 2]);
            g_platform_objects[g_platform_object_count].X2 = StringToInt(&cData[iPlace + 4]);
            g_platform_objects[g_platform_object_count].Y2 = StringToInt(&cData[iPlace + 6]);
            g_platform_objects[g_platform_object_count].Z1 = StringToInt(&cData[iPlace + 8]);
            g_platform_objects[g_platform_object_count].Extra = StringToInt(&cData[iPlace + 10]);
            g_platform_objects[g_platform_object_count].Num = StringToInt(&cData[iPlace + 12]);
            g_platform_objects[g_platform_object_count].Texture = StringToInt(&cData[iPlace + 14]);
            iPlace += 20;

            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            g_platform_objects[g_platform_object_count].Mesh = (long*)(malloc(iData * sizeof(long)));
            g_platform_objects[g_platform_object_count].MeshSize = iData;
            g_platform_objects[g_platform_object_count].ObjectNumber = g_platform_object_count;

            long iNum = -1;

            while(++iNum < iData) {
                g_platform_objects[g_platform_object_count].Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            oData = (long*)(malloc(g_platform_objects[g_platform_object_count].MeshSize * sizeof(long)));
            iMPlace = 0;
            ComposeObject(&g_platform_objects[g_platform_object_count], oData, &iMPlace);
            CreateObject(oData, iMPlace / 9, &iNum);
            SetObjectData(iNum, g_platform_objects[g_platform_object_count].Texture, g_platform_objects[g_platform_object_count].Visible);
            g_platform_objects[g_platform_object_count].MeshNumber = iNum;
            free(oData);

            ++g_platform_object_count;
        } else {
            return;
        }
    }

    free(cData);

    int iChar;
    char sFile[100];
    char sChar[10];
    int bGood;

    iChar = -1;

    while(++iChar < MAX_LETTER_MESHES) {
        bGood = 1;

        if((iChar >= 'A' && iChar <= 'Z') || (iChar >= '0' && iChar <= '9')) {
            stbsp_snprintf(sChar, sizeof(sChar), "%c", iChar);
        } else if(iChar == '.') {
            stbsp_snprintf(sChar, sizeof(sChar), "Period");
        } else if(iChar == '\'') {
            stbsp_snprintf(sChar, sizeof(sChar), "Apos");
        } else if(iChar == '-') {
            stbsp_snprintf(sChar, sizeof(sChar), "Dash");
        } else if(iChar == ':') {
            stbsp_snprintf(sChar, sizeof(sChar), "Colon");
        } else if(iChar == '%') {
            stbsp_snprintf(sChar, sizeof(sChar), "Square");
        } else if(iChar == '^') {
            stbsp_snprintf(sChar, sizeof(sChar), "Jump");
        } else {
            bGood = 0;
        }

        if(bGood) {
            stbsp_snprintf(sFile, sizeof(sFile), "Char%s.MSH", sChar);
            g_letter_mesh_indices[iChar] = LoadMesh(base_path, sFile);
        } else {
            g_letter_mesh_indices[iChar] = -1;
        }
    }

    stbsp_snprintf(sTemp, sizeof(sTemp), "%s/Data/panel.bmp", base_path);
    LoadTexture(g_loaded_texture_count, sTemp, 0, 0);
    ++g_loaded_texture_count;

    stbsp_snprintf(sTemp, sizeof(sTemp), "%s/Data/Titles.png", base_path);
    LoadTexture(g_loaded_texture_count, sTemp, 0, 0);
    ++g_loaded_texture_count;
}

static void GetNextPlatform(long iX, long iY, long iHeight, long iWide, float* iSupport, long* iPlatform) {
    long iP;
    float iH;
    long iLen;
    long iEX;
    long iExtra;
    int bGood;

    *iPlatform = -1;
    *iSupport = -1;

    iP = -1;
    iExtra = 0;

    while(++iP < g_platform_object_count) {
        if(g_platform_objects[iP].X1 <= iX + iWide && g_platform_objects[iP].X2 >= iX - iWide) {
            iEX = iX;

            if(iEX < g_platform_objects[iP].X1) {
                iEX = g_platform_objects[iP].X1;
            }

            if(iEX > g_platform_objects[iP].X2) {
                iEX = g_platform_objects[iP].X2;
            }

            iLen = g_platform_objects[iP].X2 - g_platform_objects[iP].X1;
            iH = (float)(g_platform_objects[iP].Y1) * abs((int)(g_platform_objects[iP].X2 - iEX)) + (float)(g_platform_objects[iP].Y2) * abs((int)(g_platform_objects[iP].X1 - iEX));
            iH /= iLen;

            bGood = 0;

            if(g_platform_objects[iP].Extra == 3) {
                if(iH < iY + 1.5 && iH >= iY) {
                    bGood = 1;
                }

                // This function is only used for navigation now, so don't need to check this state
                // if(g_player_current_state == kPlayerStateRoll && g_player_current_state_frame_count < 6) {
                //     bGood = 0;
                // }
            } else {
                if(iH < iY + iHeight) {
                    bGood = 1;
                }
            }

            if(bGood && (iH > *iSupport || (iH == *iSupport && (iExtra == 1 || iExtra == 2)))) {
                *iSupport = iH;
                *iPlatform = iP;
                iExtra = g_platform_objects[iP].Extra;
            }
        }
    }
}

static void ResetPlayer(int iNewLevel, GameInput* game_input) {
    // TODO: Pass boolean iNewLevel to function?
    CallLuaFunction(g_script_level_script_lua_state, "reset", game_input, false);
}

static void ProgressGame(const char* base_path, GameInput* game_input, bool is_initializing) {
    if(!(g_player_current_state & kPlayerStateDone)) {
        CallLuaGameUpdate(g_script_level_script_lua_state, game_input, is_initializing);
    } else {
        ++g_player_current_state_frame_count;

        if(g_player_current_state_frame_count == 30) {
            NewTrack2(g_music_win_track_filename);
        }

        if(g_player_current_state_frame_count == 300) {
            LoadNextLevel(base_path, game_input);
        }
    }
}

static void SetGamePerspective(void) {
    static float iCamX, iCamY;
    static float iPX, iPY;
    float iTX, iTY;

    if(g_player_current_position_x > -50) {
        iPX = g_player_current_position_x;
    }

    iPY = g_player_current_position_y;

    iTX = iPX / 2 + g_level_extent_x / 4;
    iTY = iPY;

    if(iTX < 35) {
        iTX = 35;
    }

    if(iTX > g_level_extent_x - 45) {
        iTX = (float)(g_level_extent_x - 45);
    }

    iCamX = (iCamX + iTX) / 2;
    iCamY = (iCamY + iTY) / 2;

    if(iCamX < iTX - 10 || iCamX > iTX + 10) {
        iCamX = iTX;
    }

    if(iCamY < iTY - 10 || iCamY > iTY + 10) {
        iCamY = iTY;
    }

    if(g_current_camera_mode == kCameraModeNormal) {
        SetPerspective(iCamX, iCamY + 40.0f, -115.0f, iCamX, iCamY, 0.0f);
    }

    if(g_current_camera_mode == kCameraModeCloseUp) {
        SetPerspective(g_player_current_position_x, iCamY + 35.0f, -95.0f, g_player_current_position_x, iCamY + 7, 0.0f);
    }

    if(g_current_camera_mode == kCameraModeFar) {
        SetPerspective(80, iCamY + 50, -195.0f, 80, iCamY, 0);
    }

    if(g_current_camera_mode == kCameraModeNotSureWhatThisIs) {
        // TODO: What should this mode be named? When is it used?
        //       Old comment - SetPerspective(0, 0.0f, -185.0f, 0, 0, 0.0f);  - Should this be ignored?
        SetPerspective(g_player_current_position_x, iCamY / 2 + 60.0f, -110, g_player_current_position_x, iCamY / 2 + 32.0f, 0);
    }

    if(g_current_camera_mode == kCameraModeSpaceLevel) {
        SetPerspective(g_player_current_position_x, iCamY / 2 + 60.0f, -110, g_player_current_position_x, iCamY / 2 + 32.0f, 0);
    }

    if(g_current_camera_mode == kCameraModeEndingLevel) {
        SetPerspective(70, 110, -60, 100, 90, 0);
    }

    if(g_current_camera_mode == kCameraModeAbove) {
        SetPerspective(80, 150, 0.0f, 80, 80, 30);
    }

    if(g_current_camera_mode == kCameraModeFlat) {
        SetPerspective(g_player_current_position_x, g_player_current_position_y, -75.0f, g_player_current_position_x, g_player_current_position_y, 0.0f);
    }

    if(g_current_camera_mode == kCameraModeFarAbove) {
        SetPerspective(g_player_current_position_x, g_player_current_position_y + 60, -95.0f, g_player_current_position_x, g_player_current_position_y, 0.0f);
    }
}

static void UpdatePlayerGraphics(void) {
    IdentityMatrix(g_player_mesh_indices[g_player_current_mesh]);
    RotateMatrixX(g_player_mesh_indices[g_player_current_mesh], g_player_current_rotation_x_radians * 180.0f / 3.14f);
    TranslateMatrix(g_player_mesh_indices[g_player_current_mesh], g_player_current_position_x, g_player_current_position_y + 6, g_player_current_position_z + 1);

    if(g_player_is_visible) {
        SetObjectData(g_player_mesh_indices[g_player_current_mesh], 0, 1);
    }

    if(g_player_current_mesh != g_player_previous_mesh) {
        SetObjectData(g_player_mesh_indices[g_player_previous_mesh], 0, 0);
        g_player_previous_mesh = g_player_current_mesh;
    }
}

void DrawGame(void) {
    Render();
}

// ------------------- OTHER STUFF -------------------------------

static void GetLevelInCurrentLevelSet(char* level_filename, size_t level_filename_size, char* level_title, size_t level_title_size, int level_set_index) {
    long iLen;
    char sTemp[20] = { 0 };
    char* sData;

    iLen = FileToString(g_level_set_current_set_filename, (unsigned char**)(&sData));
    // TODO: Verify the line was found and return false from here if so, true otherwise, and add error handling outside function.
    //       Return error if we exceed buffer lengths (maybe same check)
    TextLine(sData, iLen, sTemp, 20, level_set_index * 2 - 1);
    TextLine(sData, iLen, level_title, level_title_size, level_set_index * 2);
    stbsp_snprintf(level_filename, (int)level_filename_size, "Data/%s.DAT", sTemp);
    free(sData);
}

static void PrepLevel(const char* base_path, const char* level_filename, GameInput* game_input) {
    Clear3dData();
    Begin3dLoad();

    SetFog(0, 0, 0, 0, 0);

    LoadMeshes(base_path);
    LoadLevel(base_path, level_filename);

    EndAndCommit3dLoad();

    BuildNavigation();
    ResetPlayer(1, game_input);
    g_game_time_inactive = 0;

    ProgressGame(base_path, game_input, true);
    ProgressGame(base_path, game_input, true);
    ProgressGame(base_path, game_input, true);
    ProgressGame(base_path, game_input, true);
    ProgressGame(base_path, game_input, true);

    if(g_music_loop_start_music_time != 5550) {
        NewTrack1(g_music_background_track_filename, 0, g_music_loop_start_music_time);
    }
}

static void LoadNextLevel(const char* base_path, GameInput* game_input) {
    if(g_debug_level_is_specified) {
        g_remaining_life_count = 5;
        PrepLevel(base_path, g_debug_level_filename, game_input);
    } else {
        char level_filename[200];
        char level_title[50];
        ++g_level_set_current_level_index;
        GetLevelInCurrentLevelSet(level_filename, sizeof(level_filename), level_title, sizeof(level_title), g_level_set_current_level_index);
        stbsp_snprintf(g_level_current_title, sizeof(g_level_current_title), "%s", level_title);
        PrepLevel(base_path, level_filename, game_input);
    }
}

void InitGameDebugLevel(const char* base_path, const char* level_name, GameInput* game_input) {
    g_just_launched_game = false;
    g_debug_level_is_specified = true;
    stbsp_snprintf(g_debug_level_filename, sizeof(g_debug_level_filename), "Data/%s.DAT", level_name);
    g_debug_level_is_specified = true;
    LoadNextLevel(base_path, game_input);
    g_level_set_current_level_index = 0;
    g_game_status = kGameStatusInLevel;
}

void InitGameNormal(void) {
    g_just_launched_game = true;
    g_game_status = kGameStatusMenu;
    g_current_game_menu_state = kGameMenuStateNone;
    g_target_game_menu_state = kGameMenuStateMain;
    g_target_menu_selected_music = kGameMenuMusicStateIntroTrack;
    g_debug_level_is_specified = false;
}

void ExitGame(void) {
    g_game_status = kGameStatusExiting;
}

static void LoadJumpmanMenu(const char* base_path) {
    if(g_current_game_menu_state == g_target_game_menu_state) {
        return;
    }

    Clear3dData();
    Begin3dLoad();

    SetFog(0, 0, 0, 0, 0);

    if(g_target_game_menu_state == kGameMenuStateMain) {
        LoadLevel(base_path, "Data/MainMenu.DAT");

        if(g_target_menu_selected_music == kGameMenuMusicStateIntroTrack) {
            NewTrack1(g_music_background_track_filename, 3000, -1);
        }

        if(g_target_menu_selected_music == kGameMenuMusicStateMainLoopTrack) {
            NewTrack1(g_music_death_track_filename, 0, -1);
        }
    }

    if(g_target_game_menu_state == kGameMenuStateOptions) {
        LoadLevel(base_path, "Data/Options.DAT");

        if(g_target_menu_selected_music == kGameMenuMusicStateIntroTrack) {
            NewTrack1(g_music_background_track_filename, 0, g_music_loop_start_music_time);
        }
    }

    if(g_target_game_menu_state == kGameMenuStateSelectGame) {
        LoadLevel(base_path, "Data/SelectGame.DAT");

        if(g_target_menu_selected_music == kGameMenuMusicStateIntroTrack) {
            NewTrack1(g_music_background_track_filename, 0, g_music_loop_start_music_time);
        }
    }

    g_current_game_menu_state = g_target_game_menu_state;

    EndAndCommit3dLoad();
}

static void InteractMenu(GameInput* game_input) {
    CallLuaFunction(g_script_level_script_lua_state, "update", game_input, true);  // Not calling level update function
    SetPerspective(80.0f, 80.0f, -100.0f, 80.0f, 80.0f, 0.0f);
}

void UpdateGame(const char* base_path, GameInput* game_input) {
    ++g_game_time_inactive;

    if(game_input->move_left_action.is_pressed + game_input->move_right_action.is_pressed || game_input->move_up_action.is_pressed || game_input->move_down_action.is_pressed || game_input->jump_action.is_pressed) {
        g_game_time_inactive = 0;
    }

    if(g_game_status == kGameStatusMenu) {
        LoadJumpmanMenu(base_path);
        InteractMenu(game_input);

        if(g_game_status == kGameStatusInLevel) {
            g_level_set_current_level_index = 0;
            LoadNextLevel(base_path, game_input);
        }

        g_just_launched_game = false;
    }

    if(g_game_status == kGameStatusInLevel) {
        if(!IsGameFrozen()) {
            ProgressGame(base_path, game_input, false);
            UpdatePlayerGraphics();
        }
    }
}

long Init3D(void) {
    int iLoop;

    g_player_current_state = 0;
    g_player_current_state_frame_count = 0;

    g_player_current_rotation_x_radians = 0;

    iLoop = -1;

    while(++iLoop < MAX_PLAYER_MESHES) {
        g_player_mesh_indices[iLoop] = 0;
    }

    iLoop = -1;

    while(++iLoop < MAX_SCRIPT_MESHES) {
        g_script_mesh_indices[iLoop] = 0;
    }

    if(!InitializeAll()) {
        return 0;
    }

    return 1;
}

static long LoadMesh(const char* base_path, char* sFileName) {
    unsigned char* cData;
    long* oData;
    char sFullFile[300];
    long iObjectNum;
    long iNums;

    stbsp_snprintf(sFullFile, sizeof(sFullFile), "%s/Data/%s", base_path, sFileName);

    cData = NULL;
    iNums = FileToString(sFullFile, &cData);
    iNums = iNums / 4;

    oData = (long*)(malloc(iNums * sizeof(long)));

    long iNum;

    iNum = -1;

    while(++iNum < iNums) {
        oData[iNum] = StringToLong(&cData[iNum << 2]);
    }

    CreateObject(oData, iNum / 9, &iObjectNum);

    free(cData);
    free(oData);

    return iObjectNum;
}

static void LoadMeshes(const char* base_path) {
    g_player_mesh_indices[kPlayerMeshStand] = LoadMesh(base_path, "Stand.MSH");
    g_player_mesh_indices[kPlayerMeshLeft1] = LoadMesh(base_path, "Left1.MSH");
    g_player_mesh_indices[kPlayerMeshLeft2] = LoadMesh(base_path, "Left2.MSH");
    g_player_mesh_indices[kPlayerMeshRight1] = LoadMesh(base_path, "Right1.MSH");
    g_player_mesh_indices[kPlayerMeshRight2] = LoadMesh(base_path, "Right2.MSH");

    g_player_mesh_indices[kPlayerMeshJumpUp] = LoadMesh(base_path, "JumpUp.MSH");
    g_player_mesh_indices[kPlayerMeshJumpLeft] = LoadMesh(base_path, "JumpLeft.MSH");
    g_player_mesh_indices[kPlayerMeshJumpRight] = LoadMesh(base_path, "JumpRight.MSH");

    g_player_mesh_indices[kPlayerMeshVineClimb1] = LoadMesh(base_path, "RopeClimb1.MSH");
    g_player_mesh_indices[kPlayerMeshVineClimb2] = LoadMesh(base_path, "RopeClimb2.MSH");

    g_player_mesh_indices[kPlayerMeshLadderClimb1] = LoadMesh(base_path, "LadderClimb1.MSH");
    g_player_mesh_indices[kPlayerMeshLadderClimb2] = LoadMesh(base_path, "LadderClimb2.MSH");

    g_player_mesh_indices[kPlayerMeshKickLeft] = LoadMesh(base_path, "KickLeft.MSH");
    g_player_mesh_indices[kPlayerMeshKickRight] = LoadMesh(base_path, "KickRight.MSH");

    g_player_mesh_indices[kPlayerMeshDiveRight] = LoadMesh(base_path, "DiveRight.MSH");
    g_player_mesh_indices[kPlayerMeshRollRight1] = LoadMesh(base_path, "RollRight1.MSH");
    g_player_mesh_indices[kPlayerMeshRollRight2] = LoadMesh(base_path, "RollRight2.MSH");
    g_player_mesh_indices[kPlayerMeshRollRight3] = LoadMesh(base_path, "RollRight3.MSH");
    g_player_mesh_indices[kPlayerMeshRollRight4] = LoadMesh(base_path, "RollRight4.MSH");

    g_player_mesh_indices[kPlayerMeshDiveLeft] = LoadMesh(base_path, "DiveLeft.MSH");
    g_player_mesh_indices[kPlayerMeshRollLeft1] = LoadMesh(base_path, "RollLEFT1.MSH");
    g_player_mesh_indices[kPlayerMeshRollLeft2] = LoadMesh(base_path, "RollLEFT2.MSH");
    g_player_mesh_indices[kPlayerMeshRollLeft3] = LoadMesh(base_path, "RollLEFT3.MSH");
    g_player_mesh_indices[kPlayerMeshRollLeft4] = LoadMesh(base_path, "RollLEFT4.MSH");

    g_player_mesh_indices[kPlayerMeshPunchLeft] = LoadMesh(base_path, "PunchLeft.MSH");
    g_player_mesh_indices[kPlayerMeshPunchRight] = LoadMesh(base_path, "PunchRight.MSH");
    g_player_mesh_indices[kPlayerMeshPunchLeft2] = LoadMesh(base_path, "PunchLeft2.MSH");
    g_player_mesh_indices[kPlayerMeshPunchRight2] = LoadMesh(base_path, "PunchRight2.MSH");

    g_player_mesh_indices[kPlayerMeshDying] = LoadMesh(base_path, "Dying.MSH");
    g_player_mesh_indices[kPlayerMeshDead] = LoadMesh(base_path, "Dead.MSH");
    g_player_mesh_indices[kPlayerMeshStars] = LoadMesh(base_path, "Stars.MSH");

    g_player_mesh_indices[kPlayerMeshSlideR] = LoadMesh(base_path, "SlideR.MSH");
    g_player_mesh_indices[kPlayerMeshSlideRB] = LoadMesh(base_path, "SlideRB.MSH");
    g_player_mesh_indices[kPlayerMeshSlideL] = LoadMesh(base_path, "SlideL.MSH");
    g_player_mesh_indices[kPlayerMeshSlideLB] = LoadMesh(base_path, "SlideLB.MSH");

    g_player_mesh_indices[kPlayerMeshBored1] = LoadMesh(base_path, "BORED1.MSH");
    g_player_mesh_indices[kPlayerMeshBored2] = LoadMesh(base_path, "BORED2.MSH");
    g_player_mesh_indices[kPlayerMeshBored3] = LoadMesh(base_path, "BORED3.MSH");
    g_player_mesh_indices[kPlayerMeshBored4] = LoadMesh(base_path, "BORED4.MSH");
    g_player_mesh_indices[kPlayerMeshBored5] = LoadMesh(base_path, "BORED5.MSH");
}
