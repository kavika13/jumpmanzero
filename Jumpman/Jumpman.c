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
    kGameStatusLevelLoad = 3,
    kGameStatusNextLevelLoad = 4,
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

typedef struct {
    long X1, X2, X3, X4;
    long Y1, Y2, Y3, Y4;
    long Z1, Z2;
    long Num;
    char Func[10];
    long Extra;

    long MeshSize;
    long* Mesh;
    long MeshNumber;
    long Texture;
    int ObjectNumber;
} LevelObject;

static long LoadMesh(const char* base_path, const char* sFileName);
static void LoadPlayerMeshes(const char* base_path);

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
static char g_queued_level_load_filename[300];
static int g_remaining_life_count;

static int g_loaded_texture_count;
static int g_loaded_mesh_count;
static int g_loaded_sound_count;

#define MAX_SCRIPT_MESHES 300
#define MAX_LETTER_MESHES 300

static long g_player_mesh_indices[MAX_PLAYER_MESHES];
static long g_script_mesh_indices[MAX_SCRIPT_MESHES];
static long g_letter_mesh_indices[MAX_LETTER_MESHES];

// ------------------- LUA SCRIPT -------------------------------

static lua_State* g_script_level_script_lua_state = NULL;

// Potentially temporary engine functions, during refactor of game logic from out of engine into script

static bool lua_checkbool(lua_State* L, int arg) {
    luaL_checktype(L, arg, LUA_TBOOLEAN);
    int d = lua_toboolean(L, arg);
    return d;
}

static int load_next_level(lua_State* lua_state) {
    g_game_status = kGameStatusNextLevelLoad;
    return 0;
}

static int queue_level_load(lua_State* lua_state) {
    const char* level_name_arg = luaL_checkstring(lua_state, 1);
    stbsp_snprintf(g_queued_level_load_filename, sizeof(g_queued_level_load_filename), "Data/%s.DAT", level_name_arg);
    g_game_status = kGameStatusLevelLoad;
    return 0;
}

static int play_music_track_1(lua_State* lua_state) {
    // TODO: Error checking for filename?
    const char* new_music_track_arg = lua_tostring(lua_state, 1);
    lua_Integer song_start_music_time_arg = luaL_checkinteger(lua_state, 2);
    lua_Integer loop_start_music_time_arg = luaL_checkinteger(lua_state, 3);

    if(song_start_music_time_arg < 0) {
        luaL_argerror(lua_state, 2, "song_start_music_time must be 0 or greater");
    }

    NewTrack1(new_music_track_arg, (unsigned int)song_start_music_time_arg, (int)loop_start_music_time_arg);

    return 0;
}

static int stop_music_track_1(lua_State* lua_state) {
    StopMusic1();  // TODO: Error checking?
    return 0;
}

static int play_music_track_2(lua_State* lua_state) {
    // TODO: Error checking for filename?
    const char* new_music_track_arg = lua_tostring(lua_state, 1);
    NewTrack2(new_music_track_arg);
    return 0;
}

static int load_sound(lua_State* lua_state) {
    // TODO: Error checking for filename?
    const char* filename_arg = lua_tostring(lua_state, 1);

    char game_base_path[300];

    if(!GetWorkingDirectoryPath(game_base_path)) {
        // TODO: Proper error handling
        return 0;
    }

    char full_filename[300];  // TODO: Standardize path lengths? Bigger paths?
    stbsp_snprintf(full_filename, sizeof(full_filename), "%s/%s", game_base_path, filename_arg);

    LoadSound(full_filename, g_loaded_sound_count);
    lua_pushinteger(lua_state, g_loaded_sound_count);
    ++g_loaded_sound_count;

    return 1;
}

static int load_texture(lua_State* lua_state) {
    // TODO: Error checking for filename?
    const char* filename_arg = lua_tostring(lua_state, 1);
    lua_Integer image_type_arg = luaL_checkinteger(lua_state, 2);
    bool alpha_blend_arg = lua_checkbool(lua_state, 3);

    char game_base_path[300];

    if(!GetWorkingDirectoryPath(game_base_path)) {
        // TODO: Proper error handling
        return 0;
    }

    char full_filename[300];  // TODO: Standardize path lengths? Bigger paths?
    stbsp_snprintf(full_filename, sizeof(full_filename), "%s/%s", game_base_path, filename_arg);

    LoadTexture(g_loaded_texture_count, full_filename, (long)image_type_arg, alpha_blend_arg ? 1 : 0);
    lua_pushinteger(lua_state, g_loaded_texture_count);
    ++g_loaded_texture_count;

    return 1;
}

static int load_mesh(lua_State* lua_state) {
    // TODO: Error checking for filename?
    const char* filename_arg = lua_tostring(lua_state, 1);

    char game_base_path[300];

    if(!GetWorkingDirectoryPath(game_base_path)) {
        // TODO: Proper error handling
        return 0;
    }

    g_script_mesh_indices[g_loaded_mesh_count] = LoadMesh(game_base_path, filename_arg);
    lua_pushinteger(lua_state, g_loaded_mesh_count);
    ++g_loaded_mesh_count;

    return 1;
}

static int get_player_mesh_index(lua_State* lua_state) {
    lua_Integer player_mesh_arg = luaL_checkinteger(lua_state, 1);
    lua_pushinteger(lua_state, g_player_mesh_indices[player_mesh_arg]);
    return 1;
}

static int get_just_launched_game(lua_State* lua_state) {
    lua_pushboolean(lua_state, g_just_launched_game);
    return 1;
}

// script 3d object utility functions

static int set_mesh_to_mesh(lua_State* lua_state) {
    lua_Integer mesh_index_arg = luaL_checkinteger(lua_state, 1);
    lua_Integer new_mesh_index_arg = luaL_checkinteger(lua_state, 2);
    ChangeMesh((long)mesh_index_arg, g_script_mesh_indices[new_mesh_index_arg]);
    return 0;
}

static int set_identity_mesh_matrix(lua_State* lua_state) {
    lua_Integer mesh_index_arg = luaL_checkinteger(lua_state, 1);
    IdentityMatrix((long)mesh_index_arg);
    return 0;
}

static int undo_camera_perspective_on_mesh_matrix(lua_State* lua_state) {
    lua_Integer mesh_index_arg = luaL_checkinteger(lua_state, 1);
    PerspectiveMatrix((long)mesh_index_arg);
    return 0;
}

static int translate_mesh_matrix(lua_State* lua_state) {
    lua_Integer mesh_index_arg = luaL_checkinteger(lua_state, 1);
    double arg_x = luaL_checknumber(lua_state, 2);
    double arg_y = luaL_checknumber(lua_state, 3);
    double arg_z = luaL_checknumber(lua_state, 4);
    TranslateMatrix((long)mesh_index_arg, (float)arg_x, (float)arg_y, (float)arg_z);
    return 0;
}

static int scale_mesh_matrix(lua_State* lua_state) {
    lua_Integer mesh_index_arg = luaL_checkinteger(lua_state, 1);
    double arg_x = luaL_checknumber(lua_state, 2);
    double arg_y = luaL_checknumber(lua_state, 3);
    double arg_z = luaL_checknumber(lua_state, 4);
    ScaleMatrix((long)mesh_index_arg, (float)arg_x, (float)arg_y, (float)arg_z);
    return 0;
}

static int rotate_x_mesh_matrix(lua_State* lua_state) {
    lua_Integer mesh_index_arg = luaL_checkinteger(lua_state, 1);
    double arg_degrees = luaL_checknumber(lua_state, 2);
    RotateMatrixX((long)mesh_index_arg, (float)arg_degrees);
    return 0;
}

static int rotate_y_mesh_matrix(lua_State* lua_state) {
    lua_Integer mesh_index_arg = luaL_checkinteger(lua_state, 1);
    double arg_degrees = luaL_checknumber(lua_state, 2);
    RotateMatrixY((long)mesh_index_arg, (float)arg_degrees);
    return 0;
}

static int rotate_z_mesh_matrix(lua_State* lua_state) {
    lua_Integer mesh_index_arg = luaL_checkinteger(lua_state, 1);
    double arg_degrees = luaL_checknumber(lua_state, 2);
    RotateMatrixZ((long)mesh_index_arg, (float)arg_degrees);
    return 0;
}

static int scroll_texture_on_mesh(lua_State* lua_state) {
    lua_Integer mesh_index_arg = luaL_checkinteger(lua_state, 1);
    double arg_x = luaL_checknumber(lua_state, 2);
    double arg_y = luaL_checknumber(lua_state, 3);
    // TODO: Remove pre-multiplication from scripts, and divide from here
    ScrollTexture((long)mesh_index_arg, (float)arg_x / 16.0f, (float)arg_y / 16.0f);
    return 0;
}

// script global variable accessors (getters)

static int get_loaded_texture_count(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_loaded_texture_count);
    return 1;
}

static int get_remaining_life_count(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_remaining_life_count);
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

static int set_remaining_life_count(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);
    g_remaining_life_count = (int)arg1;
    return 0;
}

// script utility functions

static int create_mesh(lua_State* lua_state) {
    // Handle data in the format:
    // {
    //     { pos = { 137, 140, 15 }, normal = { 0, 0, -1 }, uv = { 0, 0 } },
    //     { pos = { 139, 140, 15 }, normal = { 0, 0, -1 }, uv = { 1, 0 } },
    //     ... more vertices here
    // }
    luaL_checktype(lua_state, 1, LUA_TTABLE);

    long texture_index_arg = (long)luaL_checkinteger(lua_state, 2);
    bool is_visible_arg = true;

    if(lua_isboolean(lua_state, 3)) {
        is_visible_arg = lua_toboolean(lua_state, 3) != 0;
    }

    size_t vertex_count = lua_rawlen(lua_state, 1);
    size_t triangle_count = vertex_count / 3;
    assert(triangle_count * 3 == vertex_count && "Vertex data passed in isn't divisible by 3 (triangles)");

    MeshVertex* new_mesh_vertices = (MeshVertex*)malloc(vertex_count * sizeof(MeshVertex));

    for(size_t vertex_index = 0; vertex_index < vertex_count; ++vertex_index) {
        lua_rawgeti(lua_state, 1, vertex_index + 1);  // Current vertex table. Lua indices are 1-based
        luaL_checktype(lua_state, -1, LUA_TTABLE);

        lua_getfield(lua_state, -1, "pos");
        size_t pos_size = lua_rawlen(lua_state, -1);
        assert(pos_size == 3 && "Expected pos field to have 3 entries, one each for x, y, and z");

        lua_rawgeti(lua_state, -1, 1);  // Lua indices are 1-based
        new_mesh_vertices[vertex_index].x = (float)luaL_checknumber(lua_state, -1);
        lua_pop(lua_state, 1);

        lua_rawgeti(lua_state, -1, 2);
        new_mesh_vertices[vertex_index].y = (float)luaL_checknumber(lua_state, -1);
        lua_pop(lua_state, 1);

        lua_rawgeti(lua_state, -1, 3);
        new_mesh_vertices[vertex_index].z = (float)luaL_checknumber(lua_state, -1);
        lua_pop(lua_state, 1);

        lua_pop(lua_state, 1);  // pos table

        lua_getfield(lua_state, -1, "normal");
        size_t normal_size = lua_rawlen(lua_state, -1);
        assert(normal_size == 3 && "Expected normal field to have 3 entries, one each for nx, ny, and nz");

        lua_rawgeti(lua_state, -1, 1);  // Lua indices are 1-based
        new_mesh_vertices[vertex_index].nx = (float)luaL_checknumber(lua_state, -1);
        lua_pop(lua_state, 1);

        lua_rawgeti(lua_state, -1, 2);
        new_mesh_vertices[vertex_index].ny = (float)luaL_checknumber(lua_state, -1);
        lua_pop(lua_state, 1);

        lua_rawgeti(lua_state, -1, 3);
        new_mesh_vertices[vertex_index].nz = (float)luaL_checknumber(lua_state, -1);
        lua_pop(lua_state, 1);

        lua_pop(lua_state, 1);  // normal table

        lua_getfield(lua_state, -1, "uv");
        size_t uv_size = lua_rawlen(lua_state, -1);
        assert(uv_size == 2 && "Expected uv field to have 2 entries, one each for tu, tv");

        lua_rawgeti(lua_state, -1, 1);  // Lua indices are 1-based
        new_mesh_vertices[vertex_index].tu = (float)luaL_checknumber(lua_state, -1);
        lua_pop(lua_state, 1);

        lua_rawgeti(lua_state, -1, 2);
        new_mesh_vertices[vertex_index].tv = (float)luaL_checknumber(lua_state, -1);
        lua_pop(lua_state, 1);

        lua_pop(lua_state, 1);  // uv table

        lua_pop(lua_state, 1);  // Current vertex table
    }

    size_t new_mesh_index = CreateMesh(new_mesh_vertices, vertex_count, texture_index_arg, is_visible_arg);

    lua_pushnumber(lua_state, new_mesh_index);

    return 1;
}

static int new_mesh(lua_State* lua_state) {
    double script_mesh_index = luaL_checknumber(lua_state, 1);
    long iNew;
    CopyObject(g_script_mesh_indices[(size_t)script_mesh_index], &iNew);
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
    } else {
        iNew = -1;
    }

    lua_pushnumber(lua_state, iNew);

    return 1;
}

static int set_mesh_texture(lua_State* lua_state) {
    lua_Integer mesh_index_arg = luaL_checkinteger(lua_state, 1);
    lua_Integer texture_index_arg = luaL_checkinteger(lua_state, 2);
    SetObjectTextureIndex((long)mesh_index_arg, (long)texture_index_arg);
    return 0;
}

static int set_mesh_is_visible(lua_State* lua_state) {
    lua_Integer mesh_index_arg = luaL_checkinteger(lua_state, 1);
    bool is_visible_arg = lua_checkbool(lua_state, 2);
    SetObjectIsVisible((long)mesh_index_arg, is_visible_arg);
    return 0;
}

static int move_mesh_to_front(lua_State* lua_state) {
    lua_Integer mesh_index_arg = luaL_checkinteger(lua_state, 1);
    MoveMeshToFront((long)mesh_index_arg);
    return 0;
}

static int move_mesh_to_back(lua_State* lua_state) {
    lua_Integer mesh_index_arg = luaL_checkinteger(lua_state, 1);
    MoveMeshToBack((long)mesh_index_arg);
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

    if(option_index_arg == 33) {
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

static int get_target_menu_selected_music(lua_State* lua_state) {
    lua_pushinteger(lua_state, g_target_menu_selected_music);
    return 1;
}

static int script_game_start(lua_State* lua_state) {
    lua_Integer title_index_arg = luaL_checkinteger(lua_state, 1);
    char game_base_path[300];

    if(!GetWorkingDirectoryPath(game_base_path)) {  // TODO: Should this be passed in from main.c somehow?
        // TODO: Proper error handling
        return 0;
    }

    char sFileName[300];
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

static int script_delete_mesh(lua_State* lua_state) {
    double mesh_index = luaL_checknumber(lua_state, 1);
    DeleteMesh((long)mesh_index);
    return 0;
}

static int script_set_perspective(lua_State* lua_state) {
    double camera_x_arg = luaL_checknumber(lua_state, 1);
    double camera_y_arg = luaL_checknumber(lua_state, 2);
    double camera_z_arg = luaL_checknumber(lua_state, 3);
    double look_at_x_arg = luaL_checknumber(lua_state, 4);
    double look_at_y_arg = luaL_checknumber(lua_state, 5);
    double look_at_z_arg = luaL_checknumber(lua_state, 6);
    SetPerspective(
        (float)camera_x_arg, (float)camera_y_arg, (float)camera_z_arg,
        (float)look_at_x_arg, (float)look_at_y_arg, (float)look_at_z_arg);
    return 0;
}

static int lua_error_handler(lua_State* lua_state) {
    const char* error_message = lua_tostring(lua_state, 1);

    if(error_message == NULL) {
        if (luaL_callmeta(lua_state, 1, "__tostring") && lua_type(lua_state, -1) == LUA_TSTRING) {
            // TODO: Is this part right?
            //       lua.c did something slightly different here, and I think didn't append a traceback?
            error_message = lua_tostring(lua_state, -1);
            lua_pop(lua_state, 1);
        } else {
            error_message = lua_pushfstring(lua_state, "(error object is a %s value)", luaL_typename(lua_state, 1));
        }
    }

    luaL_traceback(lua_state, lua_state, error_message, 1);
    // const char* full_error_message = lua_tostring(lua_state, -1);

    return 1;
}

static void RegisterLuaScriptFunctions(lua_State* lua_state) {
    // TODO: Add all engine functions to a (read-only) global table instead of directly exposing in the global context.
    //       List of remaining exposed functions will be lower-level at that point, so will be important to distinguish.

    // TODO: These are temporary, may be able to remove most of them soon, after level loading etc are in script
    lua_pushcfunction(lua_state, load_next_level);
    lua_setglobal(lua_state, "load_next_level");
    lua_pushcfunction(lua_state, queue_level_load);
    lua_setglobal(lua_state, "queue_level_load");
    lua_pushcfunction(lua_state, play_music_track_1);
    lua_setglobal(lua_state, "play_music_track_1");
    lua_pushcfunction(lua_state, stop_music_track_1);
    lua_setglobal(lua_state, "stop_music_track_1");
    lua_pushcfunction(lua_state, play_music_track_2);
    lua_setglobal(lua_state, "play_music_track_2");
    lua_pushcfunction(lua_state, load_sound);
    lua_setglobal(lua_state, "load_sound");
    lua_pushcfunction(lua_state, load_texture);
    lua_setglobal(lua_state, "load_texture");
    lua_pushcfunction(lua_state, load_mesh);
    lua_setglobal(lua_state, "load_mesh");
    lua_pushcfunction(lua_state, get_player_mesh_index);
    lua_setglobal(lua_state, "get_player_mesh_index");
    lua_pushcfunction(lua_state, get_just_launched_game);
    lua_setglobal(lua_state, "get_just_launched_game");

    lua_pushcfunction(lua_state, set_mesh_to_mesh);
    lua_setglobal(lua_state, "set_mesh_to_mesh");
    lua_pushcfunction(lua_state, set_identity_mesh_matrix);
    lua_setglobal(lua_state, "set_identity_mesh_matrix");
    lua_pushcfunction(lua_state, undo_camera_perspective_on_mesh_matrix);
    lua_setglobal(lua_state, "undo_camera_perspective_on_mesh_matrix");
    lua_pushcfunction(lua_state, translate_mesh_matrix);
    lua_setglobal(lua_state, "translate_mesh_matrix");
    lua_pushcfunction(lua_state, scale_mesh_matrix);
    lua_setglobal(lua_state, "scale_mesh_matrix");
    lua_pushcfunction(lua_state, rotate_x_mesh_matrix);
    lua_setglobal(lua_state, "rotate_x_mesh_matrix");
    lua_pushcfunction(lua_state, rotate_y_mesh_matrix);
    lua_setglobal(lua_state, "rotate_y_mesh_matrix");
    lua_pushcfunction(lua_state, rotate_z_mesh_matrix);
    lua_setglobal(lua_state, "rotate_z_mesh_matrix");
    lua_pushcfunction(lua_state, scroll_texture_on_mesh);
    lua_setglobal(lua_state, "scroll_texture_on_mesh");
    lua_pushcfunction(lua_state, set_mesh_texture);
    lua_setglobal(lua_state, "set_mesh_texture");
    lua_pushcfunction(lua_state, set_mesh_is_visible);
    lua_setglobal(lua_state, "set_mesh_is_visible");

    lua_pushcfunction(lua_state, get_loaded_texture_count);
    lua_setglobal(lua_state, "get_loaded_texture_count");
    lua_pushcfunction(lua_state, get_remaining_life_count);
    lua_setglobal(lua_state, "get_remaining_life_count");
    lua_pushcfunction(lua_state, get_is_sound_enabled);
    lua_setglobal(lua_state, "get_is_sound_enabled");
    lua_pushcfunction(lua_state, get_is_music_enabled);
    lua_setglobal(lua_state, "get_is_music_enabled");
    lua_pushcfunction(lua_state, get_last_key_pressed);
    lua_setglobal(lua_state, "get_last_key_pressed");
    lua_pushcfunction(lua_state, get_current_fps);
    lua_setglobal(lua_state, "get_current_fps");
    lua_pushcfunction(lua_state, set_remaining_life_count);
    lua_setglobal(lua_state, "set_remaining_life_count");

    lua_pushcfunction(lua_state, create_mesh);
    lua_setglobal(lua_state, "create_mesh");
    lua_pushcfunction(lua_state, new_mesh);
    lua_setglobal(lua_state, "new_mesh");
    lua_pushcfunction(lua_state, new_char_mesh);
    lua_setglobal(lua_state, "new_char_mesh");
    lua_pushcfunction(lua_state, move_mesh_to_front);
    lua_setglobal(lua_state, "move_mesh_to_front");
    lua_pushcfunction(lua_state, move_mesh_to_back);
    lua_setglobal(lua_state, "move_mesh_to_back");
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
    lua_pushcfunction(lua_state, get_target_menu_selected_music);
    lua_setglobal(lua_state, "get_target_menu_selected_music");
    lua_pushcfunction(lua_state, script_game_start);
    lua_setglobal(lua_state, "game_start");
    lua_pushcfunction(lua_state, get_credit_line);
    lua_setglobal(lua_state, "get_credit_line");
    lua_pushcfunction(lua_state, script_get_game_list);
    lua_setglobal(lua_state, "get_game_list");
    lua_pushcfunction(lua_state, play_sound_effect);
    lua_setglobal(lua_state, "play_sound_effect");

    lua_pushcfunction(lua_state, script_delete_mesh);
    lua_setglobal(lua_state, "delete_mesh");
    lua_pushcfunction(lua_state, script_set_perspective);
    lua_setglobal(lua_state, "set_perspective");
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

    int arg_count = 0;
    int error_handler_stack_pos = lua_gettop(new_state) - arg_count;
    lua_pushcfunction(new_state, lua_error_handler);
    lua_insert(new_state, error_handler_stack_pos);

    if (lua_pcall(new_state, 0, 0, error_handler_stack_pos) != 0) {
        const char* error_message = lua_tostring(new_state, -1);
        assert(false);  // TODO: Error handling
    }

    lua_remove(new_state, error_handler_stack_pos);

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

        int arg_count = 1;
        int error_handler_stack_pos = lua_gettop(lua_state) - arg_count;
        lua_pushcfunction(lua_state, lua_error_handler);
        lua_insert(lua_state, error_handler_stack_pos);

        if(lua_pcall(lua_state, arg_count, 0, error_handler_stack_pos) != 0) {
            const char* error_message = lua_tostring(lua_state, -1);
            assert(false);  // TODO: Error handling
        }

        lua_remove(lua_state, error_handler_stack_pos);
    } else {
        if(is_required) {
            assert(false);  // TODO: Error handling
        }
    }
}

static void InitializeLevelScript(void) {
    GameInput empty_game_input = { 0 };  // TODO: Don't even pass input to initialize
    CallLuaFunction(g_script_level_script_lua_state, "initialize", &empty_game_input, true);
}

static void ProgressGame(GameInput* game_input) {
    CallLuaFunction(g_script_level_script_lua_state, "update", game_input, true);
}

void DrawGame(void) {
    Render();
}

// ------------------- LEVEL LOADING AND GLOBAL GAME STATE  -------------------------------

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

    g_loaded_texture_count = 0;
    g_loaded_mesh_count = 0;
    g_loaded_sound_count = 0;

    if(g_script_level_script_lua_state != NULL) {
        lua_close(g_script_level_script_lua_state);
        g_script_level_script_lua_state = NULL;
    }

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

            if(iTemp == 2) {
            }

            if(iTemp == 7) {
            }

            if(iTemp == 3 || iTemp == 4 || iTemp == 6) {
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
            // Skip loading backdrops. This will be done in Lua instead
            iPlace += 10;
            iPlace += 20;
            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;
            iPlace += iData << 2;
        } else if(cData[iPlace] == 'L' && cData[iPlace + 1] == 0) {
            // Skip loading ladders. This will be done in Lua instead
            iPlace += 10;
            iPlace += 20;
            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;
            iPlace += iData << 2;
        } else if(cData[iPlace] == 'W' && cData[iPlace + 1] == 0) {
            // Skip loading walls. This will be done in Lua instead
            iPlace += 10;
            iPlace += 20;
            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;
            iPlace += iData << 2;
        } else if(cData[iPlace] == 'V' && cData[iPlace + 1] == 0) {
            // Skip loading vines. This will be done in Lua instead
            iPlace += 10;
            iPlace += 20;
            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;
            iPlace += iData << 2;
        } else if(cData[iPlace] == 'D' && cData[iPlace + 1] == 0) {
            // Skip loading donuts. This will be done in Lua instead
            iPlace += 10;
            iPlace += 20;
            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;
            iPlace += iData << 2;
        } else if(cData[iPlace] == 'P' && cData[iPlace + 1] == 0) {
            // Skip loading platforms. This will be done in Lua instead
            iPlace += 10;
            iPlace += 20;
            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;
            iPlace += iData << 2;
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
            stbsp_snprintf(sFile, sizeof(sFile), "data/char%s.msh", sChar);
            g_letter_mesh_indices[iChar] = LoadMesh(base_path, sFile);
        } else {
            g_letter_mesh_indices[iChar] = -1;
        }
    }
}

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

static void PrepLevel(const char* base_path, const char* level_filename) {
    Clear3dData();
    Begin3dLoad();

    SetFog(0, 0, 0, 0, 0);

    LoadPlayerMeshes(base_path);
    LoadLevel(base_path, level_filename);
    InitializeLevelScript();

    EndAndCommit3dLoad();
}

static void LoadNextLevel(const char* base_path) {
    if(g_debug_level_is_specified) {
        g_remaining_life_count = 5;
        PrepLevel(base_path, g_debug_level_filename);
    } else {
        char level_filename[200];
        char level_title[50];
        ++g_level_set_current_level_index;
        GetLevelInCurrentLevelSet(level_filename, sizeof(level_filename), level_title, sizeof(level_title), g_level_set_current_level_index);
        stbsp_snprintf(g_level_current_title, sizeof(g_level_current_title), "%s", level_title);
        PrepLevel(base_path, level_filename);
    }
}

void InitGameDebugLevel(const char* base_path, const char* level_name) {
    g_just_launched_game = false;
    g_debug_level_is_specified = true;
    stbsp_snprintf(g_debug_level_filename, sizeof(g_debug_level_filename), "Data/%s.DAT", level_name);
    LoadNextLevel(base_path);
    g_level_set_current_level_index = 0;
    g_game_status = kGameStatusInLevel;
}

void InitGameNormal(void) {
    g_just_launched_game = true;
    g_debug_level_is_specified = false;
    g_game_status = kGameStatusMenu;
    g_current_game_menu_state = kGameMenuStateNone;
    g_target_game_menu_state = kGameMenuStateMain;
    g_target_menu_selected_music = kGameMenuMusicStateIntroTrack;
}

void ExitGame(void) {
    g_game_status = kGameStatusExiting;
}

static void LoadJumpmanMenu(const char* base_path) {
    Clear3dData();
    Begin3dLoad();

    SetFog(0, 0, 0, 0, 0);

    if(g_target_game_menu_state == kGameMenuStateMain) {
        LoadLevel(base_path, "Data/MainMenu.DAT");
        InitializeLevelScript();
    }

    if(g_target_game_menu_state == kGameMenuStateOptions) {
        LoadLevel(base_path, "Data/Options.DAT");
        InitializeLevelScript();
    }

    if(g_target_game_menu_state == kGameMenuStateSelectGame) {
        LoadLevel(base_path, "Data/SelectGame.DAT");
        InitializeLevelScript();
    }

    g_current_game_menu_state = g_target_game_menu_state;

    EndAndCommit3dLoad();
}

void UpdateGame(const char* base_path, GameInput* game_input) {
    if(g_game_status == kGameStatusMenu) {
        if(g_current_game_menu_state != g_target_game_menu_state) {
            LoadJumpmanMenu(base_path);
        }

        CallLuaFunction(g_script_level_script_lua_state, "update", game_input, true);  // Not calling level update function
        SetPerspective(80.0f, 80.0f, -100.0f, 80.0f, 80.0f, 0.0f);

        if(g_game_status == kGameStatusInLevel) {
            g_level_set_current_level_index = 0;
            LoadNextLevel(base_path);
        }

        g_just_launched_game = false;
    }

    if(g_game_status == kGameStatusInLevel) {
        if(!IsGameFrozen()) {
            ProgressGame(game_input);
        }
    }

    if(g_game_status == kGameStatusLevelLoad) {
        // Loading levels frees the currently running script, so this can't be done in the API function itself
        PrepLevel(base_path, g_queued_level_load_filename);
        g_queued_level_load_filename[0] = '\0';
        g_game_status = kGameStatusInLevel;
    }

    if(g_game_status == kGameStatusNextLevelLoad) {
        // Loading levels frees the currently running script, so this can't be done in the API function itself
        LoadNextLevel(base_path);
        g_game_status = kGameStatusInLevel;
    }
}

// ------------------- MESH SETUP -------------------------------

long Init3D(void) {
    int iLoop = -1;

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

static long LoadMesh(const char* base_path, const char* sFileName) {
    unsigned char* cData;
    long* oData;
    char sFullFile[300];
    long iObjectNum;
    long iNums;

    stbsp_snprintf(sFullFile, sizeof(sFullFile), "%s/%s", base_path, sFileName);

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

static void LoadPlayerMeshes(const char* base_path) {
    g_player_mesh_indices[kPlayerMeshStand] = LoadMesh(base_path, "data/stand.msh");
    g_player_mesh_indices[kPlayerMeshLeft1] = LoadMesh(base_path, "data/left1.msh");
    g_player_mesh_indices[kPlayerMeshLeft2] = LoadMesh(base_path, "data/left2.msh");
    g_player_mesh_indices[kPlayerMeshRight1] = LoadMesh(base_path, "data/right1.msh");
    g_player_mesh_indices[kPlayerMeshRight2] = LoadMesh(base_path, "data/right2.msh");

    g_player_mesh_indices[kPlayerMeshJumpUp] = LoadMesh(base_path, "data/jumpup.msh");
    g_player_mesh_indices[kPlayerMeshJumpLeft] = LoadMesh(base_path, "data/jumpleft.msh");
    g_player_mesh_indices[kPlayerMeshJumpRight] = LoadMesh(base_path, "data/jumpright.msh");

    g_player_mesh_indices[kPlayerMeshVineClimb1] = LoadMesh(base_path, "data/ropeclimb1.msh");
    g_player_mesh_indices[kPlayerMeshVineClimb2] = LoadMesh(base_path, "data/ropeclimb2.msh");

    g_player_mesh_indices[kPlayerMeshLadderClimb1] = LoadMesh(base_path, "data/ladderclimb1.msh");
    g_player_mesh_indices[kPlayerMeshLadderClimb2] = LoadMesh(base_path, "data/ladderclimb2.msh");

    g_player_mesh_indices[kPlayerMeshKickLeft] = LoadMesh(base_path, "data/kickleft.msh");
    g_player_mesh_indices[kPlayerMeshKickRight] = LoadMesh(base_path, "data/kickright.msh");

    g_player_mesh_indices[kPlayerMeshDiveRight] = LoadMesh(base_path, "data/diveright.msh");
    g_player_mesh_indices[kPlayerMeshRollRight1] = LoadMesh(base_path, "data/rollright1.msh");
    g_player_mesh_indices[kPlayerMeshRollRight2] = LoadMesh(base_path, "data/rollright2.msh");
    g_player_mesh_indices[kPlayerMeshRollRight3] = LoadMesh(base_path, "data/rollright3.msh");
    g_player_mesh_indices[kPlayerMeshRollRight4] = LoadMesh(base_path, "data/rollright4.msh");

    g_player_mesh_indices[kPlayerMeshDiveLeft] = LoadMesh(base_path, "data/diveleft.msh");
    g_player_mesh_indices[kPlayerMeshRollLeft1] = LoadMesh(base_path, "data/rollleft1.msh");
    g_player_mesh_indices[kPlayerMeshRollLeft2] = LoadMesh(base_path, "data/rollleft2.msh");
    g_player_mesh_indices[kPlayerMeshRollLeft3] = LoadMesh(base_path, "data/rollleft3.msh");
    g_player_mesh_indices[kPlayerMeshRollLeft4] = LoadMesh(base_path, "data/rollleft4.msh");

    g_player_mesh_indices[kPlayerMeshPunchLeft] = LoadMesh(base_path, "data/punchleft.msh");
    g_player_mesh_indices[kPlayerMeshPunchRight] = LoadMesh(base_path, "data/punchright.msh");
    g_player_mesh_indices[kPlayerMeshPunchLeft2] = LoadMesh(base_path, "data/punchleft2.msh");
    g_player_mesh_indices[kPlayerMeshPunchRight2] = LoadMesh(base_path, "data/punchright2.msh");

    g_player_mesh_indices[kPlayerMeshDying] = LoadMesh(base_path, "data/dying.msh");
    g_player_mesh_indices[kPlayerMeshDead] = LoadMesh(base_path, "data/dead.msh");
    g_player_mesh_indices[kPlayerMeshStars] = LoadMesh(base_path, "data/stars.msh");

    g_player_mesh_indices[kPlayerMeshSlideR] = LoadMesh(base_path, "data/slider.msh");
    g_player_mesh_indices[kPlayerMeshSlideRB] = LoadMesh(base_path, "data/sliderb.msh");
    g_player_mesh_indices[kPlayerMeshSlideL] = LoadMesh(base_path, "data/slidel.msh");
    g_player_mesh_indices[kPlayerMeshSlideLB] = LoadMesh(base_path, "data/slidelb.msh");

    g_player_mesh_indices[kPlayerMeshBored1] = LoadMesh(base_path, "data/bored1.msh");
    g_player_mesh_indices[kPlayerMeshBored2] = LoadMesh(base_path, "data/bored2.msh");
    g_player_mesh_indices[kPlayerMeshBored3] = LoadMesh(base_path, "data/bored3.msh");
    g_player_mesh_indices[kPlayerMeshBored4] = LoadMesh(base_path, "data/bored4.msh");
    g_player_mesh_indices[kPlayerMeshBored5] = LoadMesh(base_path, "data/bored5.msh");
}
