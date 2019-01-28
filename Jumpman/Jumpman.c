#define _CRT_SECURE_NO_WARNINGS
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define CUTE_FILES_IMPLEMENTATION
#include <cute_files.h>
#include "Basic3d.h"
#include "Jumpman.h"
#include "Main.h"
#include "Music.h"
#include "Script.h"
#include "Sound.h"
#include "Utilities.h"

#define NT_Ladder 1
#define NT_Platform 2
#define NT_PlatformFallLeft 3
#define NT_PlatformFallRight 4

#define EFPRINT 1
#define EFSET 2
#define EFSETSEL 3
#define EFGET 8
#define EFGETSEL 9
#define EFGETNAVDIR 10
#define EFSTRCOPY 11
#define EFSTRCAT 12

#define EFSELECT_PLATFORM 32
#define EFSELECT_LADDER 33
#define EFSELECT_DONUT 34
#define EFABS_PLATFORM 35
#define EFCOLLIDE 36
#define EFKILL 37
#define EFSELECT_VINE 38
#define EFABS_LADDER 39
#define EFSPAWN 40
#define EFNEWMESH 41
#define EFSETOBJECT 42
#define EFSOUND 43
#define EFSETDATA 44
#define EFGETDATA 45
#define EFABS_DONUT 46
#define EFCOLLIDE_WALL 47
#define EFSELECT_PICTURE 48
#define EFPRIORITIZE_OBJECT 49
#define EFSELECT_WALL 51
#define EFSELECT_OBJECT_MESH 52
#define EFDELETE_MESH 53
#define EFDELETE_OBJECT 54
#define EFWIN 55
#define EFABS_VINE 56
#define EFSERVICE 57
#define EFNEWCHARMESH 58
#define EFRESETPERSPECTIVE 59

#define EFROTATEX 64
#define EFROTATEY 65
#define EFROTATEZ 66
#define EFTRANSLATE 67
#define EFIDENTITY 70
#define EFPERSPECTIVE 71
#define EFSCALE 72
#define EFSCROLLTEXTURE 73

#define EFRND 80
#define EFFINDPLATFORM 81
#define EFSIN 82
#define EFCOS 83
#define EFFINDLADDER 84
#define EFATAN 85
#define EFSQR 86
#define EFFINDVINE 87
#define EFSETFOG 88
#define EFCHANGEMESH 89

#define EFV_PX 1
#define EFV_PY 2
#define EFV_PZ 3
#define EFV_PSTAT 4
#define EFV_PSC 5
#define EFV_PVISIBLE 6
#define EFV_PDIR 7
#define EFV_PACT 8

#define EFV_INPUTLEFT 16
#define EFV_INPUTRIGHT 17
#define EFV_INPUTUP 18
#define EFV_INPUTDOWN 19
#define EFV_INPUTJUMP 20
#define EFV_INPUTATTACK 21
#define EFV_INPUTSELECT 22
#define EFV_LASTKEY 23

#define EFV_NOROLL 32
#define EFV_FREEZE 33
#define EFV_SOUNDON 34
#define EFV_MUSICON 35
#define EFV_PERFORMANCE 36
#define EFV_SHOWFPS 37
#define EFV_LIVESREMAINING 38

#define EFV_DONUTS 64
#define EFV_PLATFORMS 65
#define EFV_LADDERS 66
#define EFV_VINES 67
#define EFV_WALLS 68
#define EFV_TEXTURES 69

#define EFV_EVENT1 128
#define EFV_EVENT2 129
#define EFV_EVENT3 130
#define EFV_EVENT4 131
#define EFV_COMPOSE 132
#define EFV_OBJECTS 133
#define EFV_DEBUG 134
#define EFV_PERSPECTIVE 135
#define EFV_LEVELEXTENTX 136
#define EFV_THIS 137

#define EFS_SX1 1
#define EFS_SX2 2
#define EFS_SY1 3
#define EFS_SY2 4
#define EFS_SZ1 5
#define EFS_SZ2 6
#define EFS_VISIBLE 7
#define EFS_NUMBER 8
#define EFS_TEXTURE 9
#define EFS_EXTRA 10
#define EFS_THIS 137

#define SERVICE_GAMELIST 128
#define SERVICE_GAMESTART 129
#define SERVICE_LOADMENU 130
#define SERVICE_OPTIONSTRING 142
#define SERVICE_SETOPTION 143
#define SERVICE_SAVEOPTIONS 144
#define SERVICE_LEVELTITLE 154
#define SERVICE_CREDITLINE 155

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
    kPlayerDirectionUp = 1,
    kPlayerDirectionDown = 2,
    kPlayerDirectionLeft = 3,
    kPlayerDirectionRight = 4,
} PlayerDirection;

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
    int X1, X2, X3, X4;
    int Y1, Y2, Y3, Y4;
    int Z1, Z2;
    int Num;
    int Visible;
    char Func[10];
    int Extra;

    int Navs;
    int NavTo[10];
    int NavToType[10];
    int NavDist;
    int NavChoice;

    int MeshSize;
    long* Mesh;
    long MeshNumber;
    int Texture;
    int ObjectNumber;
} LevelObject;

static void PrepLevel(const char* base_path, const char* level_filename, GameInput* game_input);
static void LoadNextLevel(const char* base_path, GameInput* game_input);
static long LoadMesh(const char* base_path, char* sFileName);
static void LoadMeshes(const char* base_path);
static void SetGamePerspective();
static int FindObject(LevelObject* lObj, int iCount, int iFind);
static void FindVine(long iX, long iY, long* iAbout, long* iExact);
static void FindLadder(long iX, long iY, long* iAbout, long* iExact);
static void GetNextPlatform(long iX, long iY, long iHeight, long iWide, float* iSupport, long* iPlatform);
static void MoveJumpman(GameInput* game_input);

static char g_level_set_current_set_filename[100];
static int g_level_set_current_level_index;
static char g_level_current_title[50];
static GameStatus g_game_status;
static GameMenuState g_current_game_menu_state;
static GameMenuState g_target_game_menu_state;
static bool g_debug_level_is_specified;
static char g_debug_level_filename[300];
static int g_remaining_life_count;
static long g_game_time_inactive;

static long g_player_current_close_vine_index;
static long g_player_current_exact_vine_index;
static long g_player_current_close_ladder_index;
static long g_player_current_exact_ladder_index;
static long g_player_current_platform_index;
static float g_player_current_platform_y;

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
static float g_player_old_position_x;
static float g_player_old_position_y;

static float g_player_current_position_z;
static float g_player_current_rotation_x_radians;
static int g_player_velocity_x;
static PlayerMesh g_player_current_mesh;
static bool g_player_is_visible;

static PlayerState g_player_current_state;
static PlayerDirection g_player_current_direction;
static PlayerSpecialAction g_player_current_special_action;

static int g_player_absolute_frame_count;
static long g_player_current_state_frame_count;
static PlayerDyingAnimationState g_player_dying_animation_state;
static int g_player_dying_animation_state_frame_count;

static int g_player_no_roll_cooldown_frame_count;
static int g_player_freeze_cooldown_frame_count;
static int g_level_scroll_title_animation_frame_count;

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
static int g_script_main_subroutine_handle, g_script_donut_subroutine_handle;

static long g_script_event_data_1, g_script_event_data_2, g_script_event_data_3, g_script_event_data_4;
static LevelObject* g_script_selected_level_object;
static long g_script_selected_mesh_index;

static long g_level_extent_x;
static long g_level_extent_y;

static ScriptCode g_script_level_script_code;
static ScriptContext g_script_level_script_context;
static ScriptCode g_script_title_script_code;
static ScriptContext g_script_title_script_context;

static ScriptCode g_script_object_script_codes[5];
static ScriptContext g_script_object_script_contexts[MAX_SCRIPTOBJECTS];

// ------------------------------- BASIC GAME STUFF ----------------------------

static long CollideWall(long iX1, long iY1, long iX2, long iY2) {
    long iW;
    int iLeft, iRight, iTop, iBottom;

    iW = -1;
    iLeft = 0;
    iRight = 0;
    iTop = 0;
    iBottom = 0;

    while(++iW < g_wall_object_count) {
        if(PointInQuad(iX1, iY1, g_wall_objects[iW].X1, g_wall_objects[iW].Y1, g_wall_objects[iW].X2, g_wall_objects[iW].Y2, g_wall_objects[iW].X3, g_wall_objects[iW].Y3, g_wall_objects[iW].X4, g_wall_objects[iW].Y4)) {
            ++iLeft;
            ++iTop;
        }

        if(PointInQuad(iX2, iY1, g_wall_objects[iW].X1, g_wall_objects[iW].Y1, g_wall_objects[iW].X2, g_wall_objects[iW].Y2, g_wall_objects[iW].X3, g_wall_objects[iW].Y3, g_wall_objects[iW].X4, g_wall_objects[iW].Y4)) {
            ++iRight;
            ++iTop;
        }

        if(PointInQuad(iX1, iY2, g_wall_objects[iW].X1, g_wall_objects[iW].Y1, g_wall_objects[iW].X2, g_wall_objects[iW].Y2, g_wall_objects[iW].X3, g_wall_objects[iW].Y3, g_wall_objects[iW].X4, g_wall_objects[iW].Y4)) {
            ++iLeft;
            ++iBottom;
        }

        if(PointInQuad(iX2, iY2, g_wall_objects[iW].X1, g_wall_objects[iW].Y1, g_wall_objects[iW].X2, g_wall_objects[iW].Y2, g_wall_objects[iW].X3, g_wall_objects[iW].Y3, g_wall_objects[iW].X4, g_wall_objects[iW].Y4)) {
            ++iRight;
            ++iBottom;
        }
    }

    if(iTop > 1) {
        return 1;
    }

    if(iLeft) {
        return 3;
    }

    if(iRight) {
        return 4;
    }

    return 0;
}

static void BuildNavigation() {
    int iLoop;
    int iTest;
    int iType;
    float iHeight;
    long iPlatform;
    long iEX;
    long iLen;
    long iH;

    iLoop = -1;

    while(++iLoop < g_ladder_object_count) {
        g_ladder_objects[iLoop].Navs = 0;
    }

    iLoop = -1;

    while(++iLoop < g_platform_object_count) {
        g_platform_objects[iLoop].Navs = 0;

        GetNextPlatform(g_platform_objects[iLoop].X1 - 4, g_platform_objects[iLoop].Y1, 4, 2, &iHeight, &iPlatform);

        if(iPlatform >= 0) {
            iType = NT_Platform;

            if(iHeight < g_platform_objects[iLoop].Y1 - 4) {
                iType = NT_PlatformFallLeft;
            }

            g_platform_objects[iLoop].NavTo[g_platform_objects[iLoop].Navs] = iPlatform;
            g_platform_objects[iLoop].NavToType[g_platform_objects[iLoop].Navs] = iType;
            ++g_platform_objects[iLoop].Navs;
        }

        GetNextPlatform(g_platform_objects[iLoop].X2 + 4, g_platform_objects[iLoop].Y2, 4, 2, &iHeight, &iPlatform);

        if(iPlatform >= 0) {
            iType = NT_Platform;

            if(iHeight < g_platform_objects[iLoop].Y2 - 4) {
                iType = NT_PlatformFallRight;
            }

            g_platform_objects[iLoop].NavTo[g_platform_objects[iLoop].Navs] = iPlatform;
            g_platform_objects[iLoop].NavToType[g_platform_objects[iLoop].Navs] = iType;
            ++g_platform_objects[iLoop].Navs;
        }

        iTest = -1;

        while(++iTest < g_ladder_object_count) {
            if(g_platform_objects[iLoop].X1 < g_ladder_objects[iTest].X1 && g_platform_objects[iLoop].X2 > g_ladder_objects[iTest].X1) {
                iEX = g_ladder_objects[iTest].X1;
                iLen = g_platform_objects[iLoop].X2 - g_platform_objects[iLoop].X1;
                iH = g_platform_objects[iLoop].Y1 * abs(g_platform_objects[iLoop].X2 - iEX) + g_platform_objects[iLoop].Y2 * abs(g_platform_objects[iLoop].X1 - iEX);
                iH /= iLen;

                if(iH < g_ladder_objects[iTest].Y1 + 2 && iH > g_ladder_objects[iTest].Y2 - 2) {
                    g_platform_objects[iLoop].NavTo[g_platform_objects[iLoop].Navs] = iTest;
                    g_platform_objects[iLoop].NavToType[g_platform_objects[iLoop].Navs] = NT_Ladder;
                    ++g_platform_objects[iLoop].Navs;

                    g_ladder_objects[iTest].NavTo[g_ladder_objects[iTest].Navs] = iLoop;
                    g_ladder_objects[iTest].NavToType[g_ladder_objects[iTest].Navs] = NT_Platform;
                    ++g_ladder_objects[iTest].Navs;
                }
            }
        }
    }

    return;
}

static long PlayerCollide(int iArg1, int iArg2, int iArg3, int iArg4) {
    if(g_player_current_state & kPlayerStateJumping) {
        if(g_player_current_position_x + 4 > iArg1 && g_player_current_position_y + 9 > iArg2 && g_player_current_position_x - 4 < iArg3 && g_player_current_position_y + 4 < iArg4) {
            return 1;
        }
    } else if((g_player_current_state & kPlayerStateRoll) && g_player_absolute_frame_count < 12) {
        if(g_player_current_position_x + 4 > iArg1 && g_player_current_position_y + 7 > iArg2 && g_player_current_position_x - 4 < iArg3 && g_player_current_position_y + 3 < iArg4) {
            return 1;
        }
    } else if(g_player_current_state & kPlayerStateRoll) {
        if(g_player_current_position_x + 3 > iArg1 && g_player_current_position_y + 7 > iArg2 && g_player_current_position_x - 3 < iArg3 && g_player_current_position_y < iArg4) {
            return 1;
        }
    } else {
        if(g_player_current_position_x + 2 > iArg1 && g_player_current_position_y + 9 > iArg2 && g_player_current_position_x - 2 < iArg3 && g_player_current_position_y + 2 < iArg4) {
            return 1;
        }
    }

    return 0;
}

static long GetNavDir(long iFrom, long iTo, long iFromType, long iToType) {
    int iLoop;

    iLoop = -1;

    while(++iLoop < g_platform_object_count) {
        g_platform_objects[iLoop].NavDist = 5000;
    }

    iLoop = -1;

    while(++iLoop < g_ladder_object_count) {
        g_ladder_objects[iLoop].NavDist = 5000;
    }

    if(iFrom < 0 || iTo < 0) {
        return -1;
    }

    if(iFromType == NT_Ladder) {
        g_ladder_objects[iFrom].NavDist = 0;
    }

    if(iFromType == NT_Platform) {
        g_platform_objects[iFrom].NavDist = 0;
    }

    int iRep;
    int iNav;
    int iDone;
    int iNavTo;
    int iChoice;

    iDone = 0;
    iRep = -1;

    while(++iRep < 50 && !iDone) {
        iLoop = -1;

        while(++iLoop < g_ladder_object_count) {
            if(g_ladder_objects[iLoop].NavDist < 5000) {
                iNav = -1;

                while(++iNav < g_ladder_objects[iLoop].Navs) {
                    if(g_ladder_objects[iLoop].NavToType[iNav] == NT_Platform) {
                        iNavTo = g_ladder_objects[iLoop].NavTo[iNav];

                        if(g_platform_objects[iNavTo].NavDist > g_ladder_objects[iLoop].NavDist + 1) {
                            g_platform_objects[iNavTo].NavDist = g_ladder_objects[iLoop].NavDist + 1;
                            g_platform_objects[iNavTo].NavChoice = g_ladder_objects[iLoop].NavChoice;

                            if(g_ladder_objects[iLoop].NavDist == 0) {
                                g_platform_objects[iNavTo].NavChoice = iNavTo;
                            }
                        }
                    }
                }
            }
        }

        iLoop = -1;

        while(++iLoop < g_platform_object_count) {
            if(g_platform_objects[iLoop].NavDist < 5000) {
                int iNavType;
                iNav = -1;

                while(++iNav < g_platform_objects[iLoop].Navs) {
                    iNavType = g_platform_objects[iLoop].NavToType[iNav];

                    if(iNavType != NT_Ladder) {
                        iNavTo = g_platform_objects[iLoop].NavTo[iNav];

                        if(g_platform_objects[iNavTo].NavDist > g_platform_objects[iLoop].NavDist + 1) {
                            g_platform_objects[iNavTo].NavDist = g_platform_objects[iLoop].NavDist + 1;
                            g_platform_objects[iNavTo].NavChoice = g_platform_objects[iLoop].NavChoice;

                            if(g_platform_objects[iLoop].NavDist == 0) {
                                if(iNavType == NT_Platform) {
                                    g_platform_objects[iNavTo].NavChoice = iNavTo;
                                }

                                if(iNavType == NT_PlatformFallLeft) {
                                    g_platform_objects[iNavTo].NavChoice = iNavTo + 2000;
                                }

                                if(iNavType == NT_PlatformFallRight) {
                                    g_platform_objects[iNavTo].NavChoice = iNavTo + 3000;
                                }
                            }
                        }
                    }

                    if(iNavType == NT_Ladder) {
                        iNavTo = g_platform_objects[iLoop].NavTo[iNav];

                        if(g_ladder_objects[iNavTo].NavDist > g_platform_objects[iLoop].NavDist + 1) {
                            g_ladder_objects[iNavTo].NavDist = g_platform_objects[iLoop].NavDist + 1;
                            g_ladder_objects[iNavTo].NavChoice = g_platform_objects[iLoop].NavChoice;

                            if(g_platform_objects[iLoop].NavDist == 0) {
                                g_ladder_objects[iNavTo].NavChoice = iNavTo + 1000;
                            }
                        }
                    }
                }
            }
        }

        if(iToType == NT_Ladder && g_ladder_objects[iTo].NavDist < 5000) {
            iDone = 1;
        }

        if(iToType != NT_Ladder && g_platform_objects[iTo].NavDist < 5000) {
            iDone = 1;
        }
    }

    if(iDone == 0) {
        return -1;
    }

    if(iToType == NT_Ladder) {
        iChoice = g_ladder_objects[iTo].NavChoice;
    }

    if(iToType != NT_Ladder) {
        iChoice = g_platform_objects[iTo].NavChoice;
    }

    return iChoice;
}

long ExtFunction(long iFunc, ScriptContext* SC, GameInput* game_input) {
    long iArg1, iArg2, iArg3, iArg4;
    long rArg1, rArg2, rArg3, rArg4;
    long iLoop;
    char sFileName[300];

    rArg1 = SC->Stack[SC->BP + 0];
    iArg1 = rArg1 / 256;
    rArg2 = SC->Stack[SC->BP + 1];
    iArg2 = rArg2 / 256;
    rArg3 = SC->Stack[SC->BP + 2];
    iArg3 = rArg3 / 256;
    rArg4 = SC->Stack[SC->BP + 3];
    iArg4 = rArg4 / 256;

    if(iFunc == EFCHANGEMESH) {
        ChangeMesh(g_script_selected_mesh_index, g_script_mesh_indices[iArg1]);
    }

    if(iFunc == EFIDENTITY) {
        IdentityMatrix(g_script_selected_mesh_index);
    }

    if(iFunc == EFPERSPECTIVE) {
        PerspectiveMatrix(g_script_selected_mesh_index);
    }

    if(iFunc == EFTRANSLATE) {
        TranslateMatrix(g_script_selected_mesh_index, rArg1 / 256.0f, rArg2 / 256.0f, rArg3 / 256.0f);
    }

    if(iFunc == EFSCALE) {
        ScaleMatrix(g_script_selected_mesh_index, rArg1 / 256.0f, rArg2 / 256.0f, rArg3 / 256.0f);
    }

    if(iFunc == EFROTATEX) {
        RotateMatrixX(g_script_selected_mesh_index, rArg1 / 256.0f);
    }

    if(iFunc == EFROTATEY) {
        RotateMatrixY(g_script_selected_mesh_index, rArg1 / 256.0f);
    }

    if(iFunc == EFROTATEZ) {
        RotateMatrixZ(g_script_selected_mesh_index, rArg1 / 256.0f);
    }

    if(iFunc == EFSCROLLTEXTURE) {
        ScrollTexture(g_script_selected_mesh_index, rArg1 / 4096.0f, rArg2 / 4096.0f);
    }

    if(iFunc == EFSETSEL) {
        if(iArg1 == EFS_SX1) {
            g_script_selected_level_object->X1 = iArg2;
        } else if(iArg1 == EFS_SX2) {
            g_script_selected_level_object->X2 = iArg2;
        } else if(iArg1 == EFS_SY1) {
            g_script_selected_level_object->Y1 = iArg2;
        } else if(iArg1 == EFS_SY2) {
            g_script_selected_level_object->Y2 = iArg2;
        } else if(iArg1 == EFS_SZ1) {
            g_script_selected_level_object->Z1 = iArg2;
        } else if(iArg1 == EFS_SZ2) {
            g_script_selected_level_object->Z2 = iArg2;
        } else if(iArg1 == EFS_VISIBLE) {
            g_script_selected_level_object->Visible = iArg2;
        } else if(iArg1 == EFS_NUMBER) {
            g_script_selected_level_object->Num = iArg2;
        } else if(iArg1 == EFS_TEXTURE) {
            g_script_selected_level_object->Texture = iArg2;
        } else if(iArg1 == EFS_EXTRA) {
            g_script_selected_level_object->Extra = iArg2;
        }

        SetObjectData(g_script_selected_mesh_index, g_script_selected_level_object->Texture, g_script_selected_level_object->Visible);
    }

    if(iFunc == EFGETSEL) {
        if(iArg1 == EFS_SX1) {
            return g_script_selected_level_object->X1;
        } else if(iArg1 == EFS_SX2) {
            return g_script_selected_level_object->X2;
        } else if(iArg1 == EFS_SY1) {
            return g_script_selected_level_object->Y1;
        } else if(iArg1 == EFS_SY2) {
            return g_script_selected_level_object->Y2;
        } else if(iArg1 == EFS_SZ1) {
            return g_script_selected_level_object->Z1;
        } else if(iArg1 == EFS_SZ2) {
            return g_script_selected_level_object->Z2;
        } else if(iArg1 == EFS_VISIBLE) {
            return g_script_selected_level_object->Visible;
        } else if(iArg1 == EFS_NUMBER) {
            return g_script_selected_level_object->Num;
        } else if(iArg1 == EFS_TEXTURE) {
            return g_script_selected_level_object->Texture;
        } else if(iArg1 == EFS_EXTRA) {
            return g_script_selected_level_object->Extra;
        } else if(iArg1 == EFS_THIS) {
            return g_script_selected_level_object->ObjectNumber;
        }
    }

    if(iFunc == EFGETNAVDIR) {
        return GetNavDir(iArg1, iArg2, iArg3, iArg4);
    }

    if(iFunc == EFSTRCOPY) {
        iLoop = -1;

        while(++iLoop <= iArg2) {
            SC->Globals[iArg1 + iLoop] = SC->Stack[SC->SP + iLoop + 1];
        }
    }

    int iLen1;
    int iLen2;

    if(iFunc == EFSTRCAT) {
        iLen1 = SC->Globals[iArg1] / 256;
        iLen2 = SC->Globals[iArg2] / 256;
        SC->Globals[iArg1] = (iLen1 + iLen2) * 256;
        iLoop = 0;

        while(++iLoop <= iLen2) {
            SC->Globals[iArg1 + iLen1 + iLoop] = SC->Globals[iArg2 + iLoop];
        }
    }

    if(iFunc == EFGET) {
        if(iArg1 == EFV_PX) {
            return (long)(g_player_current_position_x * 256.0f);
        } else if(iArg1 == EFV_PY) {
            return (long)(g_player_current_position_y * 256.0f);
        } else if(iArg1 == EFV_PZ) {
            return (long)(g_player_current_position_z * 256.0f);
        } else if(iArg1 == EFV_PSTAT) {
            return g_player_current_state * 256;
        } else if(iArg1 == EFV_PSC) {
            return g_player_current_state_frame_count * 256;
        } else if(iArg1 == EFV_PDIR) {
            return g_player_current_direction * 256;
        } else if(iArg1 == EFV_PACT) {
            return g_player_current_special_action * 256;
        } else if(iArg1 == EFV_SHOWFPS) {
            return game_input->debug_action.is_pressed ? 256 : 0;
        } else if(iArg1 == EFV_LIVESREMAINING) {
            return g_remaining_life_count * 256;
        } else if(iArg1 == EFV_EVENT1) {
            return g_script_event_data_1 * 256;
        } else if(iArg1 == EFV_EVENT2) {
            return g_script_event_data_2 * 256;
        } else if(iArg1 == EFV_EVENT3) {
            return g_script_event_data_3;
        } else if(iArg1 == EFV_EVENT4) {
            return g_script_event_data_4;
        } else if(iArg1 == EFV_DEBUG) {
            return IsDebugEnabled() ? 256 : 0;
        } else if(iArg1 == EFV_PERSPECTIVE) {
            return g_current_camera_mode * 256;
        } else if(iArg1 == EFV_OBJECTS) {
            return MAX_SCRIPTOBJECTS * 256;
        } else if(iArg1 == EFV_DONUTS) {
            return g_donut_object_count * 256;
        } else if(iArg1 == EFV_TEXTURES) {
            return g_loaded_texture_count * 256;
        } else if(iArg1 == EFV_PLATFORMS) {
            return g_platform_object_count * 256;
        } else if(iArg1 == EFV_LADDERS) {
            return g_ladder_object_count * 256;
        } else if(iArg1 == EFV_VINES) {
            return g_vine_object_count * 256;
        } else if(iArg1 == EFV_WALLS) {
            return g_wall_object_count * 256;
        } else if(iArg1 == EFV_LEVELEXTENTX) {
            return g_level_extent_x * 256;
        } else if(iArg1 == EFV_THIS) {
            return SC->ScriptReference * 256;
        } else if(iArg1 == EFV_INPUTLEFT) {
            return game_input->move_left_action.is_pressed ? 256 : 0;
        } else if(iArg1 == EFV_INPUTRIGHT) {
            return game_input->move_right_action.is_pressed ? 256 : 0;
        } else if(iArg1 == EFV_INPUTUP) {
            return game_input->move_up_action.is_pressed ? 256 : 0;
        } else if(iArg1 == EFV_INPUTDOWN) {
            return game_input->move_down_action.is_pressed ? 256 : 0;
        } else if(iArg1 == EFV_INPUTJUMP) {
            return game_input->jump_action.is_pressed ? 256 : 0;
        } else if(iArg1 == EFV_INPUTATTACK) {
            return game_input->attack_action.is_pressed ? 256 : 0;
        } else if(iArg1 == EFV_INPUTSELECT) {
            return game_input->select_action.is_pressed ? 256 : 0;
        } else if(iArg1 == EFV_FREEZE) {
            return g_player_freeze_cooldown_frame_count * 256;
        } else if(iArg1 == EFV_SOUNDON) {
            return GetIsSoundEnabled() ? 256 : 0;
        } else if(iArg1 == EFV_MUSICON) {
            return GetIsMusicEnabled() ? 256 : 0;
        } else if(iArg1 == EFV_LASTKEY) {
            return GetLastKeyPressed() * 256;
        } else if(iArg1 == EFV_PERFORMANCE) {
            return GetCurrentFps() * 256;
        }
    }

    if(iFunc == EFSET) {
        if(iArg1 == EFV_PX) {
            g_player_current_position_x = (float)(rArg2) / 256;
        } else if(iArg1 == EFV_PY) {
            g_player_current_position_y = (float)(rArg2) / 256;
        } else if(iArg1 == EFV_PZ) {
            g_player_current_position_z = (float)(iArg2);
        } else if(iArg1 == EFV_PSTAT) {
            g_player_current_state = iArg2;
        } else if(iArg1 == EFV_PSC) {
            g_player_current_state_frame_count = iArg2;
        } else if(iArg1 == EFV_PDIR) {
            g_player_current_direction = iArg2;
        } else if(iArg1 == EFV_PACT) {
            g_player_current_special_action = iArg2;
        } else if(iArg1 == EFV_EVENT1) {
            g_script_event_data_1 = iArg2;
        } else if(iArg1 == EFV_EVENT2) {
            g_script_event_data_2 = iArg2;
        } else if(iArg1 == EFV_EVENT3) {
            g_script_event_data_3 = iArg2;
        } else if(iArg1 == EFV_EVENT4) {
            g_script_event_data_4 = iArg2;
        } else if(iArg1 == EFV_PERSPECTIVE) {
            g_current_camera_mode = iArg2;
        } else if(iArg1 == EFV_DEBUG) {
            SetDebugEnabled(iArg2 ? true : false);
        } else if(iArg1 == EFV_LEVELEXTENTX) {
            g_level_extent_x = iArg2;
        } else if(iArg1 == EFV_NOROLL) {
            g_player_no_roll_cooldown_frame_count = iArg2;
        } else if(iArg1 == EFV_FREEZE) {
            g_player_freeze_cooldown_frame_count = iArg2;
        } else if(iArg1 == EFV_PVISIBLE) {
            g_player_is_visible = iArg2 == 1 ? true : false;
        } else if(iArg1 == EFV_LIVESREMAINING) {
            g_remaining_life_count = iArg2;
        }

        return 0;
    }

    if(iFunc == EFSPAWN) {
        long iNewObject = -1;
        iLoop = -1;

        while(++iLoop < MAX_SCRIPTOBJECTS) {
            if(!g_script_object_script_contexts[iLoop].Active && iNewObject == -1) {
                iNewObject = iLoop;
            }
        }

        if(iNewObject < 0) {
            iNewObject = 0;
        }

        ResetContext(&g_script_object_script_contexts[iNewObject], SC->game_base_path);
        g_script_object_script_contexts[iNewObject].Script = &g_script_object_script_codes[iArg1];
        g_script_object_script_contexts[iNewObject].ScriptNumber = iArg1;
        g_script_object_script_contexts[iNewObject].ScriptReference = iNewObject;
        g_script_object_script_contexts[iNewObject].Active = 2;

        return iNewObject;
    }

    if(iFunc == EFNEWMESH) {
        long iNew;
        CopyObject(g_script_mesh_indices[iArg1], &iNew);
        g_script_selected_mesh_index = iNew;
        return iNew;
    }

    if(iFunc == EFNEWCHARMESH) {
        long iNew;

        if(iArg1 >= 97) {
            iArg1 += 65 - 97;
        }

        if(g_letter_mesh_indices[iArg1] >= 0) {
            CopyObject(g_letter_mesh_indices[iArg1], &iNew);
            g_script_selected_mesh_index = iNew;
            return iNew;
        } else {
            return -1;
        }
    }

    if(iFunc == EFSETOBJECT) {
        SetObjectData(g_script_selected_mesh_index, iArg1, iArg2);
    }

    if(iFunc == EFPRIORITIZE_OBJECT) {
        PrioritizeObject(g_script_selected_mesh_index);
    }

    if(iFunc == EFSETDATA) {
        g_script_object_script_contexts[iArg1].Globals[iArg2] = rArg3;
    }

    if(iFunc == EFGETDATA) {
        if(iArg2 == 1000) {
            if(g_script_object_script_contexts[iArg1].Active) {
                return g_script_object_script_contexts[iArg1].ScriptNumber * 256;
            } else {
                return -256;
            }
        }

        return g_script_object_script_contexts[iArg1].Globals[iArg2];
    }

    if(iFunc == EFRND) {
        long iRand;
        iRand = (rand() & 16383) * (iArg2 - iArg1) / 16383 + iArg1;
        return iRand;
    }

    if(iFunc == EFFINDLADDER) {
        long iLadA, iLadE;
        FindLadder(iArg1, iArg2, &iLadA, &iLadE);
        g_script_event_data_4 = iLadA * 256;
        return iLadE;
    }

    if(iFunc == EFFINDVINE) {
        long iVinAp, iVinEx;
        FindVine(iArg1, iArg2, &iVinAp, &iVinEx);
        g_script_event_data_4 = iVinAp * 256;

        return iVinEx;
    }

    if(iFunc == EFFINDPLATFORM) {
        float iFind;
        long iPlat;
        GetNextPlatform(iArg1, iArg2, iArg3, iArg4, &iFind, &iPlat);
        g_script_event_data_4 = (long)(iFind) * 256;
        return iPlat;
    }

    long iVal;

    if(iFunc == EFSIN) {
        iVal = (long)(sin(rArg1 * 3.1415f / 180.0f / 256.0f) * iArg2);
        return iVal;
    }

    if(iFunc == EFCOS) {
        iVal = (long)(cos(rArg1 * 3.1415f / 180.0f / 256.0f) * iArg2);
        return iVal;
    }

    if(iFunc == EFATAN) {
        if(rArg2 == 0) {
            iVal = (rArg1 > 0 ? 90 : 270);
        } else {
            iVal = (long)(atan((double)(rArg1) / (double)(rArg2)) * 180.0f / 3.1415f);
        }

        return iVal;
    }

    if(iFunc == EFSQR) {
        iVal = (long)(sqrt(rArg1 / 256.0f));
        return iVal;
    }

    if(iFunc == EFABS_PLATFORM) {
        g_script_selected_level_object = &g_platform_objects[iArg1];
        g_script_selected_mesh_index = g_script_selected_level_object->MeshNumber;
        return 0;
    }

    if(iFunc == EFABS_LADDER) {
        g_script_selected_level_object = &g_ladder_objects[iArg1];
        g_script_selected_mesh_index = g_script_selected_level_object->MeshNumber;
        return 0;
    }

    if(iFunc == EFABS_DONUT) {
        g_script_selected_level_object = &g_donut_objects[iArg1];
        g_script_selected_mesh_index = g_script_selected_level_object->MeshNumber;
        return 0;
    }

    if(iFunc == EFABS_VINE) {
        g_script_selected_level_object = &g_vine_objects[iArg1];
        g_script_selected_mesh_index = g_script_selected_level_object->MeshNumber;
        return 0;
    }

    if(iFunc == EFCOLLIDE_WALL) {
        return CollideWall(iArg1, iArg2, iArg3, iArg4);
    }

    if(iFunc == EFSETFOG) {
        SetFog((float)iArg1, (float)iArg2, SC->Stack[SC->BP + 2] & 0xFF, SC->Stack[SC->BP + 3] & 0xFF, SC->Stack[SC->BP + 4] & 0xFF);
    }

    int iTitle;
    int iChar;
    char sName[100];
    char sFile[300];
    int iKey;
    int iKeyGood;

    if(iFunc == EFSERVICE) {
        if(iArg1 == SERVICE_LEVELTITLE) {
            SC->Globals[iArg2] = (long)(strlen(g_level_current_title)) * 256;
            iLoop = 0;

            while(++iLoop <= (long)(strlen(g_level_current_title))) {
                SC->Globals[iArg2 + iLoop] = g_level_current_title[iLoop - 1] * 256;
            }
        }

        if(iArg1 == SERVICE_SAVEOPTIONS) {
            SaveSettings();
        }

        if(iArg1 == SERVICE_SETOPTION) {
            if(iArg3 >= 0 && iArg3 <= 5) {
                iKeyGood = 0;
                iKey = iArg2;

                if(iKey == 38 && iArg3 == 0) {
                    iKeyGood = 1;
                }

                if(iKey == 40 && iArg3 == 1) {
                    iKeyGood = 1;
                }

                if(iKey == 37 && iArg3 == 2) {
                    iKeyGood = 1;
                }

                if(iKey == 39 && iArg3 == 3) {
                    iKeyGood = 1;
                }

                if(iKey == 32 && iArg3 == 4) {
                    iKeyGood = 1;
                }

                if(iKey >= 'A' && iKey <= 'Z') {
                    iKeyGood = 1;
                }

                if(iKey >= '0' && iKey <= '9') {
                    iKeyGood = 1;
                }

                iLoop = -1;

                while(++iLoop < 6) {
                    if(iArg2 != iLoop && GetKeyBinding(iLoop) == iKey) {
                        iKeyGood = 0;
                    }
                }

                if(iKeyGood) {
                    SetKeyBinding(iArg3, iKey);
                }
            }

            if(iArg3 == 32) {
                SetIsSoundEnabled(iArg2 ? true : false);
            }

            if(iArg3 == 33 && (GetIsMusicEnabled() ? 1 : 0) != iArg2) {
                if(iArg2 == 0) {
                    StopMusic1();
                } else {
                    NewTrack1(g_music_background_track_filename, 0, 0);
                }

                SetIsMusicEnabled(iArg2 ? true : false);
            }
        }

        if(iArg1 == SERVICE_OPTIONSTRING) {
            if(iArg3 >= 0 && iArg3 <= 5) {
                iKey = GetKeyBinding(iArg3);

                if(iKey >= 'A' && iKey <= 'Z') {
                    sprintf_s(sName, sizeof(sName), "%c   ", iKey);
                } else if(iKey >= '0' && iKey <= '9') {
                    sprintf_s(sName, sizeof(sName), "%c   ", iKey);
                } else if(iKey == 38) {
                    sprintf_s(sName, sizeof(sName), "UP  ");
                } else if(iKey == 40) {
                    sprintf_s(sName, sizeof(sName), "DOWN");
                } else if(iKey == 37) {
                    sprintf_s(sName, sizeof(sName), "LEFT");
                } else if(iKey == 39) {
                    sprintf_s(sName, sizeof(sName), "RGHT");
                } else if(iKey == 32) {
                    sprintf_s(sName, sizeof(sName), "SPC ");
                } else if(iKey == 58) {
                    sprintf_s(sName, sizeof(sName), ":   ");
                } else if(iKey == 46) {
                    sprintf_s(sName, sizeof(sName), ".   ");
                } else if(iKey == 45) {
                    sprintf_s(sName, sizeof(sName), "-   ");
                }
            } else if(iArg3 == 32 || iArg3 == 33) {
                if(iArg3 == 32) {
                    iKey = GetIsSoundEnabled() ? 1 : 0;
                } else {
                    iKey = GetIsMusicEnabled() ? 1 : 0;
                }

                if(iKey) {
                    sprintf_s(sName, sizeof(sName), "ON  ");
                } else {
                    sprintf_s(sName, sizeof(sName), "OFF ");
                }
            }

            SC->Globals[iArg2] = 1024;
            SC->Globals[iArg2 + 1] = sName[0] * 256;
            SC->Globals[iArg2 + 2] = sName[1] * 256;
            SC->Globals[iArg2 + 3] = sName[2] * 256;
            SC->Globals[iArg2 + 4] = sName[3] * 256;
        }

        if(iArg1 == SERVICE_LOADMENU) {
            g_script_event_data_1 = g_script_event_data_1 - 1;
            g_game_status = kGameStatusMenu;
            g_target_game_menu_state = iArg2;
        }

        if(iArg1 == SERVICE_GAMESTART) {
            iTitle = 0;
            g_remaining_life_count = 7;
            sprintf_s(sFileName, sizeof(sFileName), "%s\\Data", SC->game_base_path);

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

            while(dir.has_next && iTitle < iArg2) {
                cf_read_file(&dir, &file);

                if(cf_match_ext(&file, ".jmg")) {
                    iTitle = iTitle + 1;
                }

                cf_dir_next(&dir);
            }

            sprintf_s(g_level_set_current_set_filename, sizeof(g_level_set_current_set_filename), "%s\\Data\\%s", SC->game_base_path, file.name);
            g_game_status = kGameStatusInLevel;
        }

        if(iArg1 == SERVICE_CREDITLINE) {
            sprintf_s(sFileName, sizeof(sFileName), "%s\\Data\\credits.txt", SC->game_base_path);
            GetFileLine(sName, sizeof(sName), sFileName, iArg2);
            iChar = -1;

            while(sName[++iChar] != 0 && iChar < 18) {
                SC->Globals[iArg3 + iChar + 1] = sName[iChar] * 256;
            }

            SC->Globals[iArg3] = iChar * 256;
        }

        if(iArg1 == SERVICE_GAMELIST) {
            iTitle = 0;
            sprintf_s(sFileName, sizeof(sFileName), "%s\\Data", SC->game_base_path);

            cf_dir_t dir;
            cf_dir_open(&dir, sFileName);

            while(dir.has_next) {
                cf_file_t file;
                cf_read_file(&dir, &file);

                if(cf_match_ext(&file, ".jmg")) {
                    iChar = -1;
                    sprintf_s(sFile, sizeof(sFile), "%s\\Data\\%s", SC->game_base_path, file.name);
                    GetFileLine(sName, sizeof(sName), sFile, 0);

                    while(sName[++iChar] != 0 && iChar < 18) {
                        SC->Globals[iArg2 + iTitle * 20 + iChar + 1] = sName[iChar] * 256;
                    }

                    SC->Globals[iArg2 + iTitle * 20] = iChar * 256;
                    iTitle = iTitle + 1;
                }

                cf_dir_next(&dir);
            }

            return iTitle;
        }
    }

    if(iFunc == EFSOUND) {
        PlaySoundEffect(iArg1);
    }

    if(iFunc == EFCOLLIDE) {
        return PlayerCollide(iArg1, iArg2, iArg3, iArg4) && !(g_player_current_state == kPlayerStateDying);
    }

    if(iFunc == EFKILL && !(g_player_current_state & kPlayerStateDying)) {
        StopMusic1();
        g_player_current_state = kPlayerStateDying;
        g_player_current_special_action = kPlayerSpecialActionNone;
        g_player_dying_animation_state = kPlayerDyingAnimationStateFalling;
        g_player_dying_animation_state_frame_count = 0;
        g_player_velocity_x = 0;
        g_player_absolute_frame_count = g_player_current_state_frame_count;
        g_player_current_state_frame_count = 1000;
    }

    if(iFunc == EFPRINT && IsDebugEnabled()) {
        char sNum[100];

        if(iArg1 == -1) {
            sprintf_s(sNum, sizeof(sNum), "\n");
        } else if(iArg1 == -2) {
            sprintf_s(sNum, sizeof(sNum), " ");
        } else {
            sprintf_s(sNum, sizeof(sNum), "%.0f", rArg1 / 256.0f);
        }

        fprintf(stdout, "%s", sNum);
    }

    if(iFunc == EFWIN) {
        StopMusic1();
        g_player_current_state_frame_count = 0;
        g_player_current_state = kPlayerStateDone;
    }

    if(iFunc == EFSELECT_OBJECT_MESH) {
        g_script_selected_mesh_index = iArg1;
    }

    if(iFunc == EFDELETE_MESH) {
        DeleteMesh(iArg1);
    }

    if(iFunc == EFDELETE_OBJECT) {
        if(iArg1 == 1000) {
            SC->Active = 0;
        } else {
            g_script_object_script_contexts[iArg1].Active = 0;
        }
    }

    if(iFunc == EFRESETPERSPECTIVE) {
        SetGamePerspective();
    }

    if(iFunc == EFSELECT_PLATFORM || iFunc == EFSELECT_LADDER || iFunc == EFSELECT_DONUT || iFunc == EFSELECT_VINE || iFunc == EFSELECT_PICTURE || iFunc == EFSELECT_WALL) {
        int iObj;

        if(iFunc == EFSELECT_WALL) {
            iObj = FindObject(g_wall_objects, g_wall_object_count, iArg1);
            g_script_selected_level_object = &g_wall_objects[iObj];
        }

        if(iFunc == EFSELECT_PLATFORM) {
            iObj = FindObject(g_platform_objects, g_platform_object_count, iArg1);
            g_script_selected_level_object = &g_platform_objects[iObj];
        }

        if(iFunc == EFSELECT_VINE) {
            iObj = FindObject(g_vine_objects, g_vine_object_count, iArg1);
            g_script_selected_level_object = &g_vine_objects[iObj];
        }

        if(iFunc == EFSELECT_LADDER) {
            iObj = FindObject(g_ladder_objects, g_ladder_object_count, iArg1);
            g_script_selected_level_object = &g_ladder_objects[iObj];
        }

        if(iFunc == EFSELECT_DONUT) {
            iObj = FindObject(g_donut_objects, g_donut_object_count, iArg1);
            g_script_selected_level_object = &g_donut_objects[iObj];
        }

        if(iFunc == EFSELECT_PICTURE) {
            iObj = FindObject(g_backdrop_objects, g_backdrop_object_count, iArg1);
            g_script_selected_level_object = &g_backdrop_objects[iObj];
        }

        g_script_selected_mesh_index = g_script_selected_level_object->MeshNumber;

        if(iObj < 0) {
            return -1;
        }
    }

    return -1;
}

static int FindObject(LevelObject* lObj, int iCount, int iFind) {
    int iLoop;
    iLoop = -1;

    while(++iLoop < iCount) {
        if(lObj[iLoop].Num == iFind) {
            return iLoop;
        }
    }

    return -1;
}

static void CleanResources() {
    int iLoop;

    iLoop = -1;

    while(++iLoop < g_platform_object_count) {
        free(g_platform_objects[iLoop].Mesh);
    }

    iLoop = -1;

    while(++iLoop < g_ladder_object_count) {
        free(g_ladder_objects[iLoop].Mesh);
    }

    iLoop = -1;

    while(++iLoop < g_donut_object_count) {
        free(g_donut_objects[iLoop].Mesh);
    }

    iLoop = -1;

    while(++iLoop < g_vine_object_count) {
        free(g_vine_objects[iLoop].Mesh);
    }

    iLoop = -1;

    while(++iLoop < g_wall_object_count) {
        free(g_wall_objects[iLoop].Mesh);
    }

    iLoop = -1;

    while(++iLoop < g_backdrop_object_count) {
        free(g_backdrop_objects[iLoop].Mesh);
    }
}

static void ComposeObject(LevelObject* lObj, long* oData, long* iPlace) {
    int iCopy;

    iCopy = -1;

    while(++iCopy < lObj->MeshSize) {
        oData[*iPlace] = lObj->Mesh[iCopy];
        ++*iPlace;
    }
}

static void LoadLevel(const char* base_path, const char* filename) {
    char full_path[300];
    sprintf_s(full_path, sizeof(full_path), "%s\\%s", base_path, filename);

    unsigned char* cData;

    char sTemp[300];

    int iLen;
    int iPlace;
    int iLoop;
    int iData;
    char sBuild[200];
    long iTemp;
    long iArg1;
    long iArg2;
    long iNum;

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

    iLoop = -1;

    while(++iLoop < MAX_SCRIPTOBJECTS) {
        g_script_object_script_contexts[iLoop].Active = 0;
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
            iLoop = -1;

            while(++iLoop < 30) {
                sTemp[iLoop] = cData[iPlace + iLoop];
            }

            iPlace += 30;

            iTemp = StringToInt(&cData[iPlace + 0]);
            iArg1 = StringToInt(&cData[iPlace + 2]);
            iArg2 = StringToInt(&cData[iPlace + 4]);

            if(iTemp == 1) {
                sprintf_s(sBuild, sizeof(sBuild), "%s\\Sound\\%s.MID", base_path, sTemp);

                if(iArg1 == 1) {
                    strcpy_s(g_music_background_track_filename, sizeof(g_music_background_track_filename), sBuild);
                    g_music_loop_start_music_time = iArg2 * 10;
                }

                if(iArg1 == 2) {
                    strcpy_s(g_music_death_track_filename, sizeof(g_music_death_track_filename), sBuild);
                }

                if(iArg1 == 3) {
                    strcpy_s(g_music_win_track_filename, sizeof(g_music_win_track_filename), sBuild);
                }
            }

            if(iTemp == 2) {
                sprintf_s(sBuild, sizeof(sBuild), "%s.MSH", sTemp);
                g_script_mesh_indices[g_loaded_mesh_count] = LoadMesh(base_path, sBuild);
                ++g_loaded_mesh_count;
            }

            if(iTemp == 7) {
                sprintf_s(sBuild, sizeof(sBuild), "%s\\Sound\\%s.WAV", base_path, sTemp);
                LoadSound(sBuild, iSounds);
                ++iSounds;
            }

            if(iTemp == 3 || iTemp == 4 || iTemp == 6) {
                sprintf_s(sBuild, sizeof(sBuild), "%s\\Data\\%s", base_path, sTemp);

                if(iTemp == 3) {
                    strcat_s(sBuild, sizeof(sBuild), ".BMP");
                }

                if(iTemp == 4) {
                    strcat_s(sBuild, sizeof(sBuild), ".JPG");
                }

                if(iTemp == 6) {
                    strcat_s(sBuild, sizeof(sBuild), ".PNG");
                }

                LoadTexture(g_loaded_texture_count, sBuild, iArg1, (iTemp == 6) || (iTemp == 3 && iArg1 == 1));
                ++g_loaded_texture_count;
            }

            if(iTemp == 5) {
                sprintf_s(sBuild, sizeof(sBuild), "Data\\%s.BIN", sTemp);

                if(iArg1 == 1) {
                    LoadScript(base_path, sBuild, &g_script_level_script_code);
                    ResetContext(&g_script_level_script_context, base_path);
                    g_script_level_script_context.Script = &g_script_level_script_code;
                    g_script_main_subroutine_handle = FindScript(&g_script_level_script_context, "main");
                    g_script_donut_subroutine_handle = FindScript(&g_script_level_script_context, "donut");
                } else {
                    LoadScript(base_path, sBuild, &g_script_object_script_codes[g_loaded_script_count]);
                    ++g_loaded_script_count;
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

            iNum = -1;

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
            iLoop = -1;

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

            iNum = -1;

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
            iLoop = -1;

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

            long iNum;

            iNum = -1;

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
            iLoop = -1;

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

            long iNum;

            iNum = -1;

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
            iLoop = -1;

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

            long iNum;

            iNum = -1;

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
            iLoop = -1;

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

            long iNum;

            iNum = -1;

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
            sprintf_s(sChar, sizeof(sChar), "%c", iChar);
        } else if(iChar == '.') {
            sprintf_s(sChar, sizeof(sChar), "Period");
        } else if(iChar == '\'') {
            sprintf_s(sChar, sizeof(sChar), "Apos");
        } else if(iChar == '-') {
            sprintf_s(sChar, sizeof(sChar), "Dash");
        } else if(iChar == ':') {
            sprintf_s(sChar, sizeof(sChar), "Colon");
        } else if(iChar == '%') {
            sprintf_s(sChar, sizeof(sChar), "Square");
        } else if(iChar == '^') {
            sprintf_s(sChar, sizeof(sChar), "Jump");
        } else {
            bGood = 0;
        }

        if(bGood) {
            sprintf_s(sFile, sizeof(sFile), "Char%s.MSH", sChar);
            g_letter_mesh_indices[iChar] = LoadMesh(base_path, sFile);
        } else {
            g_letter_mesh_indices[iChar] = -1;
        }
    }

    sprintf_s(sTemp, sizeof(sTemp), "%s\\Data\\panel.bmp", base_path);
    LoadTexture(g_loaded_texture_count, sTemp, 0, 0);
    ++g_loaded_texture_count;

    sprintf_s(sTemp, sizeof(sTemp), "%s\\Data\\Titles.png", base_path);
    LoadTexture(g_loaded_texture_count, sTemp, 0, 0);
    ++g_loaded_texture_count;
}

static void FindVine(long iX, long iY, long* iAbout, long* iExact) {
    long iV;

    *iAbout = -1;
    *iExact = -1;

    iV = -1;

    while(++iV < g_vine_object_count) {
        if(*iAbout == -1 || g_vine_objects[*iAbout].Y1 < g_vine_objects[iV].Y1) {
            if(g_vine_objects[iV].Y1 - 3 > iY && g_vine_objects[iV].Y2 - 9 < iY) {
                if(g_vine_objects[iV].X1 - 3 < iX && g_vine_objects[iV].X1 + 3 > iX) {
                    *iAbout = iV;

                    if(g_vine_objects[iV].X1 == iX) {
                        *iExact = iV;
                    }
                }
            }
        }
    }
}

static void FindLadder(long iX, long iY, long* iAbout, long* iExact) {
    long iL;
    long iDiff;
    long iBestDif;

    *iAbout = -1;
    *iExact = -1;

    iBestDif = 1000;
    iL = -1;

    while(++iL < g_ladder_object_count) {
        if(*iAbout == -1 || g_ladder_objects[*iAbout].Y1 < g_ladder_objects[iL].Y1) {
            if(g_ladder_objects[iL].Y1 - 3 > iY && g_ladder_objects[iL].Y2 - 9 < iY) {
                iDiff = g_ladder_objects[iL].X1 - iX;

                if(iDiff < 0) {
                    iDiff *= -1;
                }

                if(iDiff < 8 && iDiff <= iBestDif) {
                    iBestDif = iDiff;
                    *iAbout = iL;

                    if(iDiff == 0) {
                        *iExact = iL;
                    }
                }
            }
        }
    }
}

static long PlayerFloor() {
    long iFloor;
    iFloor = 0;

    if((g_player_current_state & kPlayerStateJumping) && (g_player_current_state_frame_count < 12)) {
        iFloor = 4;
    }

    return iFloor;
}

static long PlayerHeight() {
    long iHeight;
    iHeight = 14;

    if((g_player_current_state & kPlayerStateRoll)) {
        iHeight = 7;
    }

    if((g_player_current_state & kPlayerStatePunch)) {
        iHeight = 9;
    }

    if((g_player_current_state & kPlayerStateDying)) {
        iHeight = 7;
    }

    return iHeight;
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
    g_script_event_data_3 = 0;

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
            iH = (float)(g_platform_objects[iP].Y1) * abs(g_platform_objects[iP].X2 - iEX) + (float)(g_platform_objects[iP].Y2) * abs(g_platform_objects[iP].X1 - iEX);
            iH /= iLen;

            bGood = 0;

            if(g_platform_objects[iP].Extra == 3) {
                if(iH < iY + 1.5 && iH >= iY) {
                    bGood = 1;
                }

                if(g_player_current_state == kPlayerStateRoll && g_player_current_state_frame_count < 6) {
                    bGood = 0;
                }
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

static void GrabDonuts(GameInput* game_input) {
    int iLoop;
    int iCheck;
    int iWon;
    int iGot;

    iLoop = -1;
    iGot = 0;

    while(++iLoop < g_donut_object_count) {
        if(g_donut_objects[iLoop].Visible && PlayerCollide(g_donut_objects[iLoop].X1 - 3, g_donut_objects[iLoop].Y1 - 4, g_donut_objects[iLoop].X1 + 3, g_donut_objects[iLoop].Y1 + 2)) {
            g_donut_objects[iLoop].Visible = 0;
            SetObjectData(g_donut_objects[iLoop].MeshNumber, g_donut_objects[iLoop].Texture, 0);
            iGot = 1;

            g_script_event_data_1 = g_donut_objects[iLoop].Num;
            RunScript(&g_script_level_script_context, g_script_donut_subroutine_handle, game_input);
        }
    }

    if(iGot) {
        iCheck = -1;
        iWon = 1;

        while(++iCheck < g_donut_object_count) {
            if(g_donut_objects[iCheck].Visible) {
                iWon = 0;
            }
        }

        if(iWon) {
            StopMusic1();
            g_player_current_state_frame_count = 0;
            g_player_current_state = kPlayerStateDone;
        } else {
            PlaySoundEffect(1);
        }
    }
}

static void AdjustPlayerZ(int iTargetZ, int iTime) {
    if(iTime < abs(iTargetZ - (int)(g_player_current_position_z))) {
        if(iTargetZ < g_player_current_position_z) {
            --g_player_current_position_z;
        }

        if(iTargetZ > g_player_current_position_z) {
            ++g_player_current_position_z;
        }
    }
}

static void ResetPlayer(int iNewLevel, GameInput* game_input) {
    long iResetScript;

    iResetScript = FindScript(&g_script_level_script_context, "reset");
    RunScript(&g_script_level_script_context, iResetScript, game_input);

    int iObj;
    iObj = -1;

    while(++iObj < MAX_SCRIPTOBJECTS) {
        if(g_script_object_script_contexts[iObj].Active) {
            iResetScript = FindScript(&g_script_object_script_contexts[iObj], "resetpos");
            RunScript(&g_script_object_script_contexts[iObj], iResetScript, game_input);
        }
    }
}

static void AnimateDying(GameInput* game_input, const char* base_path) {
    float iSupport;
    long iPlatform;
    int bGrounded;

    g_script_event_data_2 = -1;

    if(g_player_dying_animation_state == kPlayerDyingAnimationStateBouncing) {
        g_player_current_mesh = kPlayerMeshJumpUp;

        ++g_player_dying_animation_state_frame_count;

        if(g_player_dying_animation_state_frame_count < 5 || g_player_dying_animation_state_frame_count == 6) {
            ++g_player_current_position_y;
        }

        if(g_player_dying_animation_state_frame_count > 10 || g_player_dying_animation_state_frame_count == 8) {
            --g_player_current_position_y;
        }

        if(g_player_dying_animation_state_frame_count > 15) {
            g_player_dying_animation_state = kPlayerDyingAnimationStateFalling;
        }

        ++g_player_absolute_frame_count;

        if(g_player_current_state_frame_count < 10) {
            ++g_player_absolute_frame_count;
        }

        if(g_player_current_state_frame_count < 5) {
            ++g_player_absolute_frame_count;
        }

        if(g_player_current_state_frame_count < 0) {
            ++g_player_absolute_frame_count;
            g_player_current_mesh = kPlayerMeshDead;
        }

        g_player_current_rotation_x_radians = g_player_absolute_frame_count / -10.0f;

        if(g_player_absolute_frame_count & 1) {
            g_player_current_position_x += g_player_velocity_x;
        }
    }

    if(g_player_dying_animation_state == kPlayerDyingAnimationStateFalling) {
        g_player_current_mesh = kPlayerMeshJumpUp;
        ++g_player_absolute_frame_count;
        g_player_current_position_y -= 2;
        g_player_current_rotation_x_radians = g_player_absolute_frame_count / -10.0f;

        GetNextPlatform((long)(g_player_current_position_x), (long)(g_player_current_position_y), 8, 2, &iSupport, &iPlatform);
        iSupport -= PlayerFloor();
        bGrounded = (g_player_current_position_y + 4 <= iSupport);
        AdjustPlayerZ(g_platform_objects[iPlatform].Z1 - 2, (int)(g_player_current_position_y - iSupport));

        if(bGrounded && g_player_current_position_y > -5 && iSupport < g_player_current_state_frame_count) {
            g_player_velocity_x = 0;
            int iRand;
            iRand = rand();

            if((iRand & 3) == 1 && g_player_current_position_y > 30 && g_player_current_position_x > 30) {
                g_player_velocity_x = -1;
            }

            if((iRand & 3) == 2 && g_player_current_position_y > 30 && g_player_current_position_x < 130) {
                g_player_velocity_x = 1;
            }

            g_player_current_state_frame_count = (long)(iSupport) - 3;
            g_player_dying_animation_state = kPlayerDyingAnimationStateBouncing;
            g_player_dying_animation_state_frame_count = 0;

            PlaySoundEffect(2);

            GetNextPlatform((long)(g_player_current_position_x), (long)(g_player_current_position_y) - 8, 8, 2, &iSupport, &iPlatform);

            if(iPlatform == -1) {
                g_player_dying_animation_state = kPlayerDyingAnimationStateFinalBounce;
                g_player_dying_animation_state_frame_count = 0;
                g_player_absolute_frame_count = 0;
            }
        }

        if(g_player_current_position_y < -2 && g_player_dying_animation_state == kPlayerDyingAnimationStateFalling) {
            g_player_dying_animation_state = kPlayerDyingAnimationStateFinalBounce;
            g_player_absolute_frame_count = 0;
        }
    }

    if(g_player_dying_animation_state == kPlayerDyingAnimationStateFinalBounce) {
        g_player_current_mesh = kPlayerMeshDead;

        ++g_player_dying_animation_state_frame_count;

        if(g_player_dying_animation_state_frame_count < 10 || g_player_dying_animation_state_frame_count == 12 || g_player_dying_animation_state_frame_count == 14) {
            ++g_player_current_position_y;
        }

        if(g_player_dying_animation_state_frame_count > 20 || g_player_dying_animation_state_frame_count == 18 || g_player_dying_animation_state_frame_count == 16) {
            --g_player_current_position_y;
        }

        if(g_player_dying_animation_state_frame_count == 10 || g_player_dying_animation_state_frame_count == 12 || g_player_dying_animation_state_frame_count == 17 || g_player_dying_animation_state_frame_count == 20) {
            --g_player_current_position_z;
        }

        if(g_player_dying_animation_state_frame_count == 25) {
            NewTrack2(g_music_death_track_filename);
        }

        g_player_absolute_frame_count += 4;
        g_player_current_rotation_x_radians = g_player_absolute_frame_count / -10.0f;

        if(g_player_dying_animation_state_frame_count > 30) {
            g_player_dying_animation_state = kPlayerDyingAnimationStateSpinningStars;
            g_player_absolute_frame_count = 0;
            g_player_current_rotation_x_radians = 0;
        }
    }

    if(g_player_dying_animation_state == kPlayerDyingAnimationStateSpinningStars) {
        IdentityMatrix(g_player_mesh_indices[kPlayerMeshStars]);
        RotateMatrixY(g_player_mesh_indices[kPlayerMeshStars], g_player_absolute_frame_count * 180.0f / 50.0f);
        TranslateMatrix(g_player_mesh_indices[kPlayerMeshStars], g_player_current_position_x, g_player_current_position_y + 12, g_player_current_position_z + 1);
        SetObjectData(g_player_mesh_indices[kPlayerMeshStars], 0, 1);

        ++g_player_absolute_frame_count;
        g_player_current_rotation_x_radians = 0.1f;
        g_player_current_mesh = kPlayerMeshDead;

        if(g_player_absolute_frame_count == 85) {
            SetObjectData(g_player_mesh_indices[kPlayerMeshStars], 0, 0);
            g_remaining_life_count = g_remaining_life_count - 1;

            if(g_remaining_life_count == 0) {
                g_player_current_state = kPlayerStateNormal;
                strcpy_s(g_level_current_title, sizeof(g_level_current_title), "");
                PrepLevel(base_path, "Data\\GameOver.DAT", game_input);
            } else {
                ResetPlayer(0, game_input);

                if(g_music_loop_start_music_time != 5550) {
                    NewTrack1(g_music_background_track_filename, g_music_loop_start_music_time, g_music_loop_start_music_time);
                }
            }
        }
    }
}

static void ProgressGame(const char* base_path, GameInput* game_input) {
    int iObject;
    int iTemp;

    if(!(g_player_current_state & kPlayerStateDone)) {
        if(g_player_freeze_cooldown_frame_count) {
            --g_player_freeze_cooldown_frame_count;
        }

        if(g_player_no_roll_cooldown_frame_count) {
            --g_player_no_roll_cooldown_frame_count;
        }

        if(!(g_player_current_state & kPlayerStateDying) && g_player_freeze_cooldown_frame_count == 0) {
            ++g_player_absolute_frame_count;
            g_player_current_rotation_x_radians = 0;
            g_player_current_mesh = kPlayerMeshStand;
            MoveJumpman(game_input);

            if(g_player_current_mesh == kPlayerMeshStand && g_player_is_visible && g_game_time_inactive > 400) {
                iTemp = (g_game_time_inactive % 400) / 6;
                iTemp = iTemp > 10 ? 2 : iTemp & 1;
                g_player_current_mesh = kPlayerMeshBored1 + iTemp;
            }

            GrabDonuts(game_input);
        }

        if((g_player_current_state & kPlayerStateDying) && g_player_freeze_cooldown_frame_count == 0) {
            AnimateDying(game_input, base_path);
            GrabDonuts(game_input);
        }

        SetGamePerspective();

        RunScript(&g_script_level_script_context, g_script_main_subroutine_handle, game_input);

        for(iObject = 0; iObject < MAX_SCRIPTOBJECTS; ++iObject) {
            if(g_script_object_script_contexts[iObject].Active == 1) {
                RunScript(&g_script_object_script_contexts[iObject], 1, game_input);
            }
        }

        for(iObject = 0; iObject < MAX_SCRIPTOBJECTS; ++iObject) {
            if(g_script_object_script_contexts[iObject].Active == 2) {
                RunScript(&g_script_object_script_contexts[iObject], 1, game_input);
                g_script_object_script_contexts[iObject].Active = 1;
            }
        }
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

static void SetGamePerspective() {
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

static void DrawGame() {
    IdentityMatrix(g_player_mesh_indices[g_player_current_mesh]);
    RotateMatrixX(g_player_mesh_indices[g_player_current_mesh], g_player_current_rotation_x_radians * 180.0f / 3.14f);
    TranslateMatrix(g_player_mesh_indices[g_player_current_mesh], g_player_current_position_x, g_player_current_position_y + 6, g_player_current_position_z + 1);

    if(g_player_is_visible) {
        SetObjectData(g_player_mesh_indices[g_player_current_mesh], 0, 1);
    }

    Render();

    SetObjectData(g_player_mesh_indices[g_player_current_mesh], 0, 0);
}

// ------------------- OTHER STUFF -------------------------------

static void GetLevelInCurrentLevelSet(char* level_filename, size_t level_filename_size, char* level_title, size_t level_title_size, int level_set_index) {
    int iLen;
    char sTemp[20] = { 0 };
    char* sData;

    iLen = FileToString(g_level_set_current_set_filename, (unsigned char**)(&sData));
    // TODO: Verify the line was found and return false from here if so, true otherwise, and add error handling outside function.
    //       Return error if we exceed buffer lengths (maybe same check)
    TextLine(sData, iLen, sTemp, 20, level_set_index * 2 - 1);
    TextLine(sData, iLen, level_title, level_title_size, level_set_index * 2);
    sprintf_s(level_filename, level_filename_size, "Data\\%s.DAT", sTemp);
    free(sData);
}

static void PrepLevel(const char* base_path, const char* level_filename, GameInput* game_input) {
    Clear3dData();
    Begin3dLoad();

    SetFog(0, 0, 0, 0, 0);

    g_script_event_data_1 = 0;

    LoadMeshes(base_path);
    LoadLevel(base_path, level_filename);

    EndAndCommit3dLoad();

    BuildNavigation();
    ResetPlayer(1, game_input);
    g_game_time_inactive = 0;

    ProgressGame(base_path, game_input);
    ProgressGame(base_path, game_input);
    ProgressGame(base_path, game_input);
    ProgressGame(base_path, game_input);
    ProgressGame(base_path, game_input);

    LoadScript(base_path, "Data\\Title.BIN", &g_script_title_script_code);
    ResetContext(&g_script_title_script_context, base_path);
    g_script_title_script_context.Script = &g_script_title_script_code;

    g_level_scroll_title_animation_frame_count = 1;

    Render();

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
        strcpy_s(g_level_current_title, sizeof(g_level_current_title), level_title);
        PrepLevel(base_path, level_filename, game_input);
    }
}

void InitGameDebugLevel(const char* base_path, const char* level_name, GameInput* game_input) {
    g_debug_level_is_specified = true;
    sprintf_s(g_debug_level_filename, sizeof(g_debug_level_filename), "Data\\%s.DAT", level_name);
    g_debug_level_is_specified = true;
    LoadNextLevel(base_path, game_input);
    g_level_set_current_level_index = 0;
    g_game_status = kGameStatusInLevel;
}

void InitGameNormal() {
    g_script_event_data_1 = 10;
    g_game_status = kGameStatusMenu;
    g_current_game_menu_state = kGameMenuStateNone;
    g_target_game_menu_state = kGameMenuStateMain;
    g_debug_level_is_specified = false;
}

void ExitGame() {
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
        LoadLevel(base_path, "Data\\MainMenu.DAT");

        if(g_script_event_data_1 == 10) {
            NewTrack1(g_music_background_track_filename, 3000, -1);
        }

        if(g_script_event_data_1 == 100) {
            NewTrack1(g_music_death_track_filename, 0, -1);
        }
    }

    if(g_target_game_menu_state == kGameMenuStateOptions) {
        LoadLevel(base_path, "Data\\Options.DAT");

        if(g_script_event_data_1 == 9) {
            NewTrack1(g_music_background_track_filename, 0, g_music_loop_start_music_time);
        }
    }

    if(g_target_game_menu_state == kGameMenuStateSelectGame) {
        LoadLevel(base_path, "Data\\SelectGame.DAT");

        if(g_script_event_data_1 == 9) {
            NewTrack1(g_music_background_track_filename, 0, g_music_loop_start_music_time);
        }
    }

    g_current_game_menu_state = g_target_game_menu_state;

    EndAndCommit3dLoad();
}

static void InteractMenu(GameInput* game_input) {
    long iObject;
    RunScript(&g_script_level_script_context, g_script_main_subroutine_handle, game_input);

    for(iObject = 0; iObject < MAX_SCRIPTOBJECTS; ++iObject) {
        if(g_script_object_script_contexts[iObject].Active == 1) {
            RunScript(&g_script_object_script_contexts[iObject], 1, game_input);
        }
    }

    for(iObject = 0; iObject < MAX_SCRIPTOBJECTS; ++iObject) {
        if(g_script_object_script_contexts[iObject].Active == 2) {
            RunScript(&g_script_object_script_contexts[iObject], 1, game_input);
            g_script_object_script_contexts[iObject].Active = 1;
        }
    }

    SetPerspective(80.0f, 80.0f, -100.0f, 80.0f, 80.0f, 0.0f);
    Render();
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
    }

    if(g_game_status == kGameStatusInLevel) {
        if(g_level_scroll_title_animation_frame_count > 0) {
            if(g_script_event_data_1 == -100) {
                g_level_scroll_title_animation_frame_count = 1000;
            }

            ++g_level_scroll_title_animation_frame_count;
            g_script_event_data_1 = g_level_scroll_title_animation_frame_count;
            RunScript(&g_script_title_script_context, 1, game_input);

            if(g_level_scroll_title_animation_frame_count > 600) {
                g_level_scroll_title_animation_frame_count = 0;
            }
        } else {
            if(!IsGameFrozen()) {
                ProgressGame(base_path, game_input);
            }

            RunScript(&g_script_title_script_context, 1, game_input);
        }

        if(!IsGameFrozen()) {
            DrawGame();
        }
    }
}

long Init3D() {
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
    int iNums;

    sprintf_s(sFullFile, sizeof(sFullFile), "%s\\Data\\%s", base_path, sFileName);

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


























static void MoveJumpmanPunch();
static void MoveJumpmanSlide();
static void MoveJumpmanFalling();
static void MoveJumpmanRoll();
static void MoveJumpmanJumping();
static void MoveJumpmanNormal();

static int iIgnoreLadders;

static void DoDeathBounce() {
    StopMusic1();
    g_player_current_state = kPlayerStateDying;
    g_player_dying_animation_state = kPlayerDyingAnimationStateFalling;
    g_player_dying_animation_state_frame_count = 0;
    g_player_velocity_x = 0;
    g_player_absolute_frame_count = g_player_current_state_frame_count;
    g_player_current_state_frame_count = 1000;

    int iRand;
    iRand = rand();

    if((iRand & 7) == 1 && g_player_current_position_x > 30) {
        g_player_velocity_x = -1;
    }

    if((iRand & 7) == 2 && g_player_current_position_x < 130) {
        g_player_velocity_x = 1;
    }
}

static int CheckWalkOff(int iCenter, GameInput* game_input) {
    if(g_player_current_position_x < iCenter && game_input->move_right_action.is_pressed) {
        return 0;
    }

    if(g_player_current_position_x > iCenter && game_input->move_left_action.is_pressed) {
        return 0;
    }

    if(game_input->move_down_action.is_pressed && g_player_current_position_y < g_player_current_platform_y - 2) {
        return 0;
    }

    if(g_player_current_position_y <= g_player_current_platform_y && (game_input->move_left_action.is_pressed != game_input->move_right_action.is_pressed)) {
        MoveJumpmanNormal(game_input);
        return 1;
    }

    return 0;
}

static int CheckJumpStart(int iLeft, int iUp, int iRight, GameInput* game_input) {
    if(!game_input->jump_action.is_pressed) {
        return 0;
    }

    if(iLeft && game_input->move_left_action.is_pressed && !game_input->move_right_action.is_pressed) {
        g_player_current_direction = kPlayerDirectionLeft;
    } else if(iRight && game_input->move_right_action.is_pressed && !game_input->move_left_action.is_pressed) {
        g_player_current_direction = kPlayerDirectionRight;
    } else if(iUp) {
        g_player_current_direction = kPlayerDirectionUp;
    } else {
        return 0;
    }

    g_player_current_special_action = kPlayerSpecialActionNone;
    g_player_current_state_frame_count = 0;

    PlaySoundEffect(0);

    MoveJumpmanJumping(game_input);

    return 1;
}

static void UpdateSituation() {
    FindVine((long)(g_player_current_position_x), (long)(g_player_current_position_y), &g_player_current_close_vine_index, &g_player_current_exact_vine_index);
    FindLadder((long)(g_player_current_position_x), (long)(g_player_current_position_y), &g_player_current_close_ladder_index, &g_player_current_exact_ladder_index);
    GetNextPlatform((long)(g_player_current_position_x), (long)(g_player_current_position_y), PlayerHeight(), 2, &g_player_current_platform_y, &g_player_current_platform_index);
    g_player_current_platform_y -= PlayerFloor();

    g_script_event_data_2 = -1;

    if(g_player_current_platform_y >= g_player_current_position_y) {
        g_script_event_data_2 = g_player_current_platform_index;
    }
}

static void MoveJumpmanVine(GameInput* game_input) {
    g_player_current_state = kPlayerStateVine;
    g_player_current_special_action = kPlayerSpecialActionNone;

    if(g_player_current_close_vine_index == -1) {
        g_player_current_state = kPlayerStateNormal;
        return;
    }

    if(CheckJumpStart(1, 0, 1, game_input)) {
        return;
    }

    if(CheckWalkOff(g_vine_objects[g_player_current_close_vine_index].X1, game_input)) {
        return;
    }

    g_player_current_mesh = (g_player_absolute_frame_count & 2) ? kPlayerMeshVineClimb1 : kPlayerMeshVineClimb2;
    AdjustPlayerZ(g_vine_objects[g_player_current_close_vine_index].Z1 - 3, 0);

    if(g_vine_objects[g_player_current_close_vine_index].Y2 < g_player_current_platform_y - 2 || g_player_current_position_y > g_player_current_platform_y - 1) {
        --g_player_current_position_y;
    } else {
        MoveJumpmanNormal(game_input);
        return;
    }

    long iVinX;

    iVinX = g_vine_objects[g_player_current_close_vine_index].X1;

    if(g_player_absolute_frame_count & 1) {
        if(g_player_current_position_x + 1 > iVinX && g_player_current_position_x - 1 < iVinX) {
            g_player_current_position_x = (float)(iVinX);
        } else if(g_player_current_position_x < iVinX) {
            ++g_player_current_position_x;
        } else if(g_player_current_position_x > iVinX) {
            --g_player_current_position_x;
        }
    }
}

static void MoveJumpmanLadder(GameInput* game_input) {
    g_player_current_state = kPlayerStateLadder;
    g_player_current_special_action = kPlayerSpecialActionNone;
    iIgnoreLadders = 1;

    if(g_player_current_close_ladder_index == -1) {
        g_player_current_state = kPlayerStateNormal;
        return;
    }

    if(g_player_current_platform_y >= g_player_current_position_y || (g_ladder_objects[g_player_current_close_ladder_index].X1 < g_player_current_position_x + 2 && g_ladder_objects[g_player_current_close_ladder_index].X1 > g_player_current_position_x - 2)) {
        if(CheckJumpStart(1, 0, 1, game_input)) {
            return;
        }
    }

    if(CheckWalkOff(g_ladder_objects[g_player_current_close_ladder_index].X1, game_input)) {
        return;
    }

    g_player_current_mesh = kPlayerMeshJumpUp;
    AdjustPlayerZ(g_ladder_objects[g_player_current_close_ladder_index].Z1 - 3, 0);

    if(game_input->move_up_action.is_pressed && g_ladder_objects[g_player_current_close_ladder_index].Y1 - 5 > g_player_current_position_y) {
        ++g_player_current_position_y;
        g_player_current_mesh = (g_player_absolute_frame_count & 2) ? kPlayerMeshLadderClimb2 : kPlayerMeshLadderClimb1;
    } else if(game_input->move_up_action.is_pressed && !game_input->move_down_action.is_pressed) {
        g_player_current_mesh = (g_player_absolute_frame_count & 2) ? kPlayerMeshLadderClimb2 : kPlayerMeshLadderClimb1;
    }

    if(game_input->move_down_action.is_pressed && (g_ladder_objects[g_player_current_close_ladder_index].Y2 < g_player_current_platform_y - 3 || g_player_current_position_y > g_player_current_platform_y)) {
        --g_player_current_position_y;
        g_player_current_mesh = (g_player_absolute_frame_count & 2) ? kPlayerMeshLadderClimb2 : kPlayerMeshLadderClimb1;

        if(g_ladder_objects[g_player_current_close_ladder_index].Y2 >= g_player_current_platform_y - 3 && g_player_current_position_y < g_player_current_platform_y) {
            g_player_current_position_y = g_player_current_platform_y;
        }
    }

    long iLadderX;

    iLadderX = g_ladder_objects[g_player_current_close_ladder_index].X1;

    if(g_player_current_position_x < iLadderX + 1 && g_player_current_position_x > iLadderX - 1) {
        g_player_current_position_x = (float)(iLadderX);
    } else if(g_player_current_position_x < iLadderX) {
        g_player_current_position_x += 1;
    } else if(g_player_current_position_x > iLadderX) {
        g_player_current_position_x -= 1;
    }
}

static void MoveJumpmanNormal(GameInput* game_input) {
    g_player_current_state = kPlayerStateNormal;
    g_player_current_special_action = kPlayerSpecialActionNone;

    AdjustPlayerZ(g_platform_objects[g_player_current_platform_index].Z1 - 2, (int)(g_player_current_position_y - g_player_current_platform_y));

    if(g_player_current_close_vine_index != -1 && !game_input->move_left_action.is_pressed && !game_input->move_right_action.is_pressed && (g_vine_objects[g_player_current_close_vine_index].Y2 < g_player_current_platform_y - 2 || g_player_current_position_y > g_player_current_platform_y)) {
        MoveJumpmanVine(game_input);
        return;
    }

    if(g_player_current_platform_y > g_player_current_position_y - 2 && (g_platform_objects[g_player_current_platform_index].Extra == 1 || g_platform_objects[g_player_current_platform_index].Extra == 2)) {
        MoveJumpmanSlide(game_input);
        return;
    }

    if(g_player_current_close_ladder_index != -1 && !iIgnoreLadders && (game_input->move_up_action.is_pressed != game_input->move_down_action.is_pressed)) {
        if((!game_input->move_right_action.is_pressed || g_player_current_position_x < g_ladder_objects[g_player_current_close_ladder_index].X1 + 1) && (!game_input->move_left_action.is_pressed || g_player_current_position_x > g_ladder_objects[g_player_current_close_ladder_index].X1 - 1)) {
            if(game_input->move_up_action.is_pressed && g_ladder_objects[g_player_current_close_ladder_index].Y1 - 5 > g_player_current_position_y) {
                MoveJumpmanLadder(game_input);
                return;
            }

            if(game_input->move_down_action.is_pressed && (g_ladder_objects[g_player_current_close_ladder_index].Y2 < g_player_current_platform_y - 3 || g_player_current_platform_y < g_player_current_position_y - 1)) {
                MoveJumpmanLadder(game_input);
                return;
            }
        }
    }

    if(g_player_current_position_y <= g_player_current_platform_y + 1) {
        if(CheckJumpStart(1, 1, 1, game_input)) {
            return;
        }
    }

    if(game_input->move_left_action.is_pressed && !game_input->move_right_action.is_pressed) {
        g_player_current_mesh = (g_player_absolute_frame_count & 2) ? kPlayerMeshLeft1 : kPlayerMeshLeft2;
        --g_player_current_position_x;
    }

    if(game_input->move_right_action.is_pressed && !game_input->move_left_action.is_pressed) {
        g_player_current_mesh = (g_player_absolute_frame_count & 2) ? kPlayerMeshRight1 : kPlayerMeshRight2;
        ++g_player_current_position_x;
    }

    int iClimbing;

    iClimbing = 0;

    if(g_player_current_platform_y < g_player_current_position_y + 1 && g_player_current_platform_y > g_player_current_position_y - 1) {
        g_player_current_position_y = g_player_current_platform_y;
    } else if(g_player_current_platform_y < g_player_current_position_y - 4) {
        g_player_current_state_frame_count = 0;
        MoveJumpmanFalling(game_input);
        return;
    } else if(g_player_current_platform_y < g_player_current_position_y - 1) {
        --g_player_current_position_y;
    } else if(g_player_current_platform_y > g_player_current_position_y + 3) {
        g_player_current_mesh = (g_player_absolute_frame_count & 2) ? kPlayerMeshVineClimb1 : kPlayerMeshVineClimb2;
        ++g_player_current_position_y;
        iClimbing = 1;
    } else if(g_player_current_platform_y > g_player_current_position_y + 1) {
        ++g_player_current_position_y;
        iClimbing = 1;
    } else {
        g_player_current_position_y = g_player_current_platform_y;
    }

    UpdateSituation();

    if(g_player_current_platform_y < g_player_current_position_y - 5 && iClimbing) {
        g_player_current_position_x = g_player_old_position_x;
    }

    if(g_platform_objects[g_player_current_platform_index].Extra == 2) {
        if(g_player_current_position_x > g_player_old_position_x) {
            g_player_current_position_x = g_player_old_position_x;
        }

        if(g_player_current_position_y > g_player_old_position_y) {
            g_player_current_position_y = g_player_old_position_y;
        }
    }

    if(g_platform_objects[g_player_current_platform_index].Extra == 1) {
        if(g_player_current_position_x < g_player_old_position_x) {
            g_player_current_position_x = g_player_old_position_x;
        }

        if(g_player_current_position_y > g_player_old_position_y) {
            g_player_current_position_y = g_player_old_position_y;
        }
    }
}

static void MoveJumpmanFalling(GameInput* game_input) {
    g_player_current_state = kPlayerStateFalling;
    g_player_current_special_action = kPlayerSpecialActionNone;

    --g_player_current_position_y;
    ++g_player_current_state_frame_count;
    g_player_current_rotation_x_radians = g_player_current_state_frame_count / -10.0f;
    g_player_current_mesh = kPlayerMeshJumpUp;

    if(g_player_current_state_frame_count > 10) {
        g_player_current_position_y -= .5;
    }

    if(g_player_current_state_frame_count > 20) {
        g_player_current_position_y -= .5;
    }

    if(g_player_current_position_y <= g_player_current_platform_y && g_platform_objects[g_player_current_platform_index].Extra != 3) {
        if(g_player_current_state_frame_count < 10) {
            MoveJumpmanNormal(game_input);
            return;
        } else {
            g_player_current_special_action = kPlayerSpecialActionNone;
            DoDeathBounce();
            return;
        }
    }
}

static void MoveJumpmanJumping(GameInput* game_input) {
    g_player_current_state = kPlayerStateJumping;

    if(g_player_current_special_action != kPlayerSpecialActionKick && game_input->attack_action.is_pressed && ((g_player_current_direction == kPlayerDirectionRight) || (g_player_current_direction == kPlayerDirectionLeft))) {
        g_player_current_special_action = kPlayerSpecialActionKick;
    }

    if(g_player_current_exact_ladder_index != -1 && !game_input->attack_action.is_pressed && (g_player_current_state_frame_count > 15 || !game_input->jump_action.is_pressed || ((g_player_current_direction == kPlayerDirectionRight) && game_input->move_left_action.is_pressed) || ((g_player_current_direction == kPlayerDirectionLeft) && game_input->move_right_action.is_pressed) )) {
        MoveJumpmanLadder(game_input);
        return;
    }

    if(g_player_current_exact_vine_index != -1 && !game_input->attack_action.is_pressed && (g_player_current_state_frame_count > 10 || !game_input->jump_action.is_pressed || ((g_player_current_direction == kPlayerDirectionRight) && game_input->move_left_action.is_pressed) || ((g_player_current_direction == kPlayerDirectionLeft) && game_input->move_right_action.is_pressed) )) {
        MoveJumpmanVine(game_input);
        return;
    }

    if(g_player_current_state_frame_count > 50) {
        if(g_player_current_close_ladder_index != -1) {
            MoveJumpmanLadder(game_input);
            return;
        }

        if(g_player_current_close_vine_index != -1) {
            MoveJumpmanVine(game_input);
            return;
        }

        MoveJumpmanNormal(game_input);
        return;
    }

    if(g_player_current_position_y < g_player_current_platform_y && g_player_current_state_frame_count > 6 && (!game_input->jump_action.is_pressed || g_player_current_state_frame_count > 12)) {
        MoveJumpmanNormal(game_input);
        return;
    }

    ++g_player_current_state_frame_count;

    if(g_player_current_state_frame_count == 1) {
        g_player_current_position_y += 1;
    }

    if(g_player_current_state_frame_count < 5 || g_player_current_state_frame_count == 6 || g_player_current_state_frame_count == 8 || g_player_current_state_frame_count == 10 || g_player_current_state_frame_count == 12) {
        g_player_current_position_y += 1;
    }

    if(g_player_current_state_frame_count > 26 || g_player_current_state_frame_count == 25 || g_player_current_state_frame_count == 23 || g_player_current_state_frame_count == 20 || g_player_current_state_frame_count == 17) {
        g_player_current_position_y -= 1;
    }

    g_player_current_mesh = kPlayerMeshJumpUp;

    if(g_player_current_direction == kPlayerDirectionLeft) {
        --g_player_current_position_x;
        g_player_current_mesh = (g_player_current_special_action == kPlayerSpecialActionKick) ? kPlayerMeshKickLeft : kPlayerMeshJumpLeft;
    }

    if(g_player_current_direction == kPlayerDirectionRight) {
        ++g_player_current_position_x;
        g_player_current_mesh = (g_player_current_special_action == kPlayerSpecialActionKick) ? kPlayerMeshKickRight : kPlayerMeshJumpRight;
    }

    if(game_input->move_down_action.is_pressed && g_player_no_roll_cooldown_frame_count == 0 && (g_player_current_direction == kPlayerDirectionRight || g_player_current_direction == kPlayerDirectionLeft)) {
        g_player_current_state_frame_count = 0;
        MoveJumpmanRoll(game_input);
    }
}

static void MoveJumpmanSlide(GameInput* game_input) {
    g_player_current_state = kPlayerStateSlide;
    g_player_current_special_action = kPlayerSpecialActionNone;

    long iExtra = g_platform_objects[g_player_current_platform_index].Extra;

    if(!iExtra && g_player_current_position_y <= g_player_current_platform_y) {
        MoveJumpmanNormal(game_input);
        return;
    }

    if(g_player_current_position_y > g_player_current_platform_y + 3) {
        ++g_player_current_state_frame_count;

        if(g_player_current_state_frame_count > 30) {
            MoveJumpmanNormal(game_input);
            return;
        }
    } else {
        g_player_current_state_frame_count = 0;
    }

    if(g_player_current_position_y < g_player_current_platform_y + 1) {
        if(iExtra == 1) {
            if(CheckJumpStart(0, 0, 1, game_input)) {
                return;
            }

            ++g_player_current_position_x;
            g_player_current_direction = kPlayerDirectionRight;
        }

        if(iExtra == 2) {
            if(CheckJumpStart(1, 0, 0, game_input)) {
                return;
            }

            --g_player_current_position_x;
            g_player_current_direction = kPlayerDirectionLeft;
        }
    } else {
        if(g_player_current_direction == kPlayerDirectionRight) {
            if(g_player_current_state_frame_count < 6) {
                if(CheckJumpStart(0, 0, 1, game_input)) {
                    return;
                }
            }

            g_player_current_position_x += (float)(30 - g_player_current_state_frame_count) / 60.0f + 0.5f;
        }

        if(g_player_current_direction == kPlayerDirectionLeft) {
            if(g_player_current_state_frame_count < 6) {
                if(CheckJumpStart(1, 0, 0, game_input)) {
                    return;
                }
            }

            g_player_current_position_x -= (float)(30 - g_player_current_state_frame_count) / 60.0f + 0.5f;
        }
    }

    if(g_player_current_direction == kPlayerDirectionRight) {
        g_player_current_mesh = kPlayerMeshSlideR;

        if(((g_player_absolute_frame_count & 7) == 1) || ((g_player_absolute_frame_count & 7) == 2) || ((g_player_absolute_frame_count & 7) == 4) || ((g_player_absolute_frame_count & 7) == 5)) {
            g_player_current_mesh = kPlayerMeshSlideRB;
        }
    } else {
        g_player_current_mesh = kPlayerMeshSlideL;

        if(((g_player_absolute_frame_count & 7) == 1) || ((g_player_absolute_frame_count & 7) == 2) || ((g_player_absolute_frame_count & 7) == 4) || ((g_player_absolute_frame_count & 7) == 5)) {
            g_player_current_mesh = kPlayerMeshSlideLB;
        }
    }

    if(g_player_current_position_y < g_player_current_platform_y + 2 && g_player_current_position_y > g_player_current_platform_y - 2) {
        g_player_current_position_y = g_player_current_platform_y;
    }

    if(g_player_current_position_y < g_player_current_platform_y) {
        ++g_player_current_position_y;
    }

    if(g_player_current_position_y < g_player_current_platform_y) {
        ++g_player_current_position_y;
    }

    if(g_player_current_position_y > g_player_current_platform_y) {
        --g_player_current_position_y;
    }

    if(g_player_current_position_y > g_player_current_platform_y) {
        --g_player_current_position_y;
    }
}

static void MoveJumpmanRoll(GameInput* game_input) {
    g_player_current_state = kPlayerStateRoll;
    g_player_current_special_action = kPlayerSpecialActionNone;

    if(g_player_current_state_frame_count < 7 || g_player_current_position_y > g_player_current_platform_y + 1) {
        ++g_player_current_state_frame_count;

        if(g_player_current_state_frame_count > 50) {
            MoveJumpmanNormal(game_input);
            return;
        }
    } else {
        g_player_current_state_frame_count = 7;
    }

    if(g_player_current_position_y <= g_player_current_platform_y && (g_platform_objects[g_player_current_platform_index].Extra == 1 || g_platform_objects[g_player_current_platform_index].Extra == 2)) {
        MoveJumpmanSlide(game_input);
        return;
    }

    if(g_player_current_position_y <= g_player_current_platform_y) {
        if(g_player_current_direction == kPlayerDirectionRight && !game_input->move_right_action.is_pressed) {
            MoveJumpmanNormal(game_input);
            return;
        }

        if(g_player_current_direction == kPlayerDirectionLeft && !game_input->move_left_action.is_pressed) {
            MoveJumpmanNormal(game_input);
            return;
        }

        if(!game_input->move_down_action.is_pressed) {
            if(CheckJumpStart(1, 1, 1, game_input)) {
                return;
            }
        }
    }

    if((!game_input->jump_action.is_pressed) && (g_player_current_position_y <= g_player_current_platform_y + 0.1) && game_input->attack_action.is_pressed) {
        g_player_current_state_frame_count = 0;
        MoveJumpmanPunch(game_input);
        return;
    }

    if(g_player_current_exact_ladder_index != -1 && g_player_current_platform_y < g_player_current_position_y && (g_player_current_state_frame_count > 10)) {
        MoveJumpmanLadder(game_input);
        return;
    }

    if(g_player_current_exact_vine_index != -1 && g_player_current_platform_y < g_player_current_position_y && (g_player_current_state_frame_count > 10)) {
        MoveJumpmanVine(game_input);
        return;
    }

    AdjustPlayerZ(g_platform_objects[g_player_current_platform_index].Z1 - 2, (int)(g_player_current_position_y - g_player_current_platform_y));

    float iVel;
    iVel = 1.3f;

    if(g_player_current_state_frame_count > 8) {
        iVel = 1;
    }

    if(g_player_current_state_frame_count > 25) {
        iVel = .7f;
    }

    if(g_player_current_state_frame_count > 38) {
        iVel = .3f;
    }

    if(g_player_current_direction == kPlayerDirectionLeft) {
        g_player_current_position_x -= iVel;
        g_player_current_mesh = kPlayerMeshRollLeft1 + ((g_player_absolute_frame_count & 6) >> 1);

        if(g_player_current_state_frame_count < 6) {
            g_player_current_mesh = kPlayerMeshDiveLeft;
        }
    }

    if(g_player_current_direction == kPlayerDirectionRight) {
        g_player_current_position_x += iVel;
        g_player_current_mesh = kPlayerMeshRollRight1 + ((g_player_absolute_frame_count & 6) >> 1);

        if(g_player_current_state_frame_count < 6) {
            g_player_current_mesh = kPlayerMeshDiveRight;
        }
    }

    UpdateSituation();

    if(g_player_current_platform_y < g_player_current_position_y + 1 && g_player_current_platform_y > g_player_current_position_y - 1) {
        g_player_current_position_y = g_player_current_platform_y;
    } else if(g_player_current_platform_y < g_player_current_position_y) {
        --g_player_current_position_y;
    } else if(g_player_current_platform_y > g_player_current_position_y) {
        ++g_player_current_position_y;
    }
}

static void MoveJumpmanPunch(GameInput* game_input) {
    g_player_current_state = kPlayerStatePunch;
    g_player_current_special_action = kPlayerSpecialActionPunch;

    if(g_player_current_state_frame_count > 20 || (g_player_current_state_frame_count < 12 && g_player_current_position_y < g_player_current_platform_y - 2) || (g_player_current_state_frame_count > 11 && g_player_current_position_y <= g_player_current_platform_y)) {
        MoveJumpmanNormal(game_input);
        return;
    }

    ++g_player_current_state_frame_count;

    if(g_player_current_state_frame_count < 3) {
        g_player_current_mesh = (g_player_current_direction == kPlayerDirectionRight) ? kPlayerMeshPunchRight : kPlayerMeshPunchLeft;
    } else {
        g_player_current_mesh = (g_player_current_direction == kPlayerDirectionRight) ? kPlayerMeshPunchRight2 : kPlayerMeshPunchLeft2;
    }

    if(g_player_current_state_frame_count < 11 && g_player_current_state_frame_count != 9) {
        ++g_player_current_position_y;
    }

    if(g_player_current_state_frame_count > 12 && g_player_current_state_frame_count != 14) {
        --g_player_current_position_y;
    }

    if(g_player_current_state_frame_count < 4 || g_player_current_state_frame_count == 5 || g_player_current_state_frame_count == 7) {
        g_player_current_position_x += (g_player_current_direction == kPlayerDirectionRight) ? 1 : -1;
    }
}

static void MoveJumpman(GameInput* game_input) {
    g_player_old_position_x = g_player_current_position_x;
    g_player_old_position_y = g_player_current_position_y;

    iIgnoreLadders = 0;

    UpdateSituation();

    if(g_player_current_state == kPlayerStateVine) {
        MoveJumpmanVine(game_input);
    } else if(g_player_current_state == kPlayerStateLadder) {
        MoveJumpmanLadder(game_input);
    } else if(g_player_current_state == kPlayerStateNormal) {
        MoveJumpmanNormal(game_input);
    } else if(g_player_current_state == kPlayerStateFalling) {
        MoveJumpmanFalling(game_input);
    } else if(g_player_current_state == kPlayerStateJumping) {
        MoveJumpmanJumping(game_input);
    } else if(g_player_current_state == kPlayerStateSlide) {
        MoveJumpmanSlide(game_input);
    } else if(g_player_current_state == kPlayerStateRoll) {
        MoveJumpmanRoll(game_input);
    } else if(g_player_current_state == kPlayerStatePunch) {
        MoveJumpmanPunch(game_input);
    }

    if(g_player_current_position_y < 0) {
        g_player_current_special_action = kPlayerSpecialActionNone;
        DoDeathBounce();
        return;
    }

    long iCollide;
    long iRep;

    iRep = -1;

    while(++iRep < 2) {
        iCollide = CollideWall((long)(g_player_current_position_x) - 2, (long)(g_player_current_position_y) + 11, (long)(g_player_current_position_x) + 2, (long)(g_player_current_position_y) + 9);

        if(iCollide == 1) {
            g_player_current_position_y -= 1;

            if((g_player_current_state == kPlayerStateJumping) && g_player_current_state_frame_count < 15) {
                g_player_current_state_frame_count = 15;
            }
        }

        iCollide = CollideWall((long)(g_player_current_position_x) - 3, (long)(g_player_current_position_y) + 9, (long)(g_player_current_position_x) + 3, (long)(g_player_current_position_y) + 3);

        if(iCollide == 3) {
            ++g_player_current_position_x;

            if(g_player_current_state == kPlayerStateJumping && g_player_current_state_frame_count < 15) {
                g_player_current_state_frame_count = 16;
            }

            if(g_player_current_state != kPlayerStateJumping && g_player_current_position_y > g_player_current_platform_y - 1 && g_player_current_position_y >= g_player_old_position_y) {
                --g_player_current_position_y;
            }
        }

        if(iCollide == 4) {
            --g_player_current_position_x;

            if(g_player_current_state == kPlayerStateJumping && g_player_current_state_frame_count < 15) {
                g_player_current_state_frame_count = 16;
            }

            if(g_player_current_state != kPlayerStateJumping && g_player_current_position_y > g_player_current_platform_y - 1 && g_player_current_position_y >= g_player_old_position_y) {
                --g_player_current_position_y;
            }
        }
    }

    UpdateSituation();
}
