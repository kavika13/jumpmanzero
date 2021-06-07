#define _CRT_SECURE_NO_WARNINGS
#include <math.h>
#include <malloc.h>

#if defined(__APPLE__)
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wstrict-prototypes"
    #pragma clang diagnostic ignored "-Wshorten-64-to-32"
#endif
#define CUTE_FILES_IMPLEMENTATION
#include <cute_files.h>
#if defined(__APPLE__)
    #pragma clang diagnostic pop
#endif

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
#include "logging.h"

typedef struct LuaModuleScriptContext {
    lua_State* lua_state;
    int module_table_registry_index;
} LuaModuleScriptContext;

static const char* g_game_base_path;

static int g_loaded_texture_count;
static int g_loaded_mesh_count;
static int g_loaded_sound_count;

#define kMAX_SCRIPT_MESHES ((size_t)600)

static int g_script_mesh_handle_indices[kMAX_SCRIPT_MESHES];  // TODO: Shouldn't need this mapping. If delete/create are set up correctly in Basic3D, can skip

static LuaModuleScriptContext g_main_script_context = { 0, -1 };

// ------------------- LUA SCRIPT API -------------------------------

static bool lua_checkbool(lua_State* L, int arg) {
    luaL_checktype(L, arg, LUA_TBOOLEAN);
    int d = lua_toboolean(L, arg);
    return d;
}

static int unload_all_resources(lua_State* lua_state) {
    (void)(lua_state);  // Unused, but passed due to passing this function as a function pointer
    Clear3dData();

    g_loaded_texture_count = 0;
    g_loaded_mesh_count = 0;
    g_loaded_sound_count = 0;

    return 0;
}

static int begin_loading_3d_data(lua_State* lua_state) {
    (void)(lua_state);  // Unused, but passed due to passing this function as a function pointer
    Begin3dLoad();
    return 0;
}

static int end_and_commit_loading_3d_data(lua_State* lua_state) {
    (void)(lua_state);  // Unused, but passed due to passing this function as a function pointer
    EndAndCommit3dLoad();
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
    (void)(lua_state);  // Unused, but passed due to passing this function as a function pointer
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
    char full_filename[300];  // TODO: Standardize path lengths? Bigger paths?
    stbsp_snprintf(full_filename, sizeof(full_filename), "%s/%s", g_game_base_path, filename_arg);

    LoadSound(full_filename, g_loaded_sound_count);
    lua_pushinteger(lua_state, g_loaded_sound_count);
    ++g_loaded_sound_count;

    return 1;
}

static int load_texture(lua_State* lua_state) {
    // TODO: Error checking for filename?
    const char* filename_arg = lua_tostring(lua_state, 1);
    lua_Integer image_type_arg = luaL_checkinteger(lua_state, 2);
    bool is_alpha_blend_enabled_arg = lua_checkbool(lua_state, 3);
    char full_filename[300];  // TODO: Standardize path lengths? Bigger paths?
    stbsp_snprintf(full_filename, sizeof(full_filename), "%s/%s", g_game_base_path, filename_arg);

    LoadTexture(g_loaded_texture_count, full_filename, (int)image_type_arg, is_alpha_blend_enabled_arg);
    lua_pushinteger(lua_state, g_loaded_texture_count);
    ++g_loaded_texture_count;

    return 1;
}

static int LoadMesh(const char* base_path, const char* sFileName) {
    unsigned char* cData;
    long* vertex_components;
    char sFullFile[300];
    int result_mesh_handle_index;
    int vertex_component_count;

    stbsp_snprintf(sFullFile, sizeof(sFullFile), "%s/%s", base_path, sFileName);

    cData = NULL;
    vertex_component_count = FileToString(sFullFile, &cData);
    vertex_component_count = vertex_component_count / 4;

    vertex_components = (long*)(malloc(vertex_component_count * sizeof(long)));

    for(int component_index = 0; component_index < vertex_component_count; ++component_index) {
        vertex_components[component_index] = StringToLong(&cData[component_index << 2]);
    }

    MeshCreateFromVertexComponents(vertex_components, vertex_component_count / 9, &result_mesh_handle_index);

    free(cData);
    free(vertex_components);

    return result_mesh_handle_index;
}

static int load_mesh(lua_State* lua_state) {
    // TODO: Error checking for filename?
    const char* filename_arg = lua_tostring(lua_state, 1);

    assert(g_loaded_mesh_count < kMAX_SCRIPT_MESHES);
    int loaded_mesh_handle_index = LoadMesh(g_game_base_path, filename_arg);
    g_script_mesh_handle_indices[g_loaded_mesh_count] = loaded_mesh_handle_index;
    lua_pushinteger(lua_state, loaded_mesh_handle_index);
    ++g_loaded_mesh_count;

    return 1;
}

static int set_mesh_to_mesh(lua_State* lua_state) {
    lua_Integer target_mesh_handle_index_arg = luaL_checkinteger(lua_state, 1);
    lua_Integer source_mesh_handle_index_arg = luaL_checkinteger(lua_state, 2);
    MeshReplaceWithCopy((int)target_mesh_handle_index_arg, g_script_mesh_handle_indices[(int)source_mesh_handle_index_arg]);
    return 0;
}


static int transform_create(lua_State* lua_state) {
    int new_transform_index = TransformCreate();
    lua_pushinteger(lua_state, new_transform_index);
    return 1;
}

static int transform_delete(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    TransformDelete((int)arg_transform_index);
    return 0;
}

static int transform_get_parent(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    int parent_transform_index = TransformGetParent((int)arg_transform_index);
    lua_pushinteger(lua_state, parent_transform_index);
    return 1;
}

static int transform_set_parent(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    lua_Integer arg_new_parent_index = luaL_checkinteger(lua_state, 2);
    TransformSetParent((int)arg_transform_index, (int)arg_new_parent_index);
    return 0;
}

static int transform_clear_parent(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    TransformClearParent((int)arg_transform_index);
    return 0;
}

static int transform_get_parent_is_camera(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    bool is_parent_camera = TransformGetParentIsCamera((int)arg_transform_index);
    lua_pushboolean(lua_state, is_parent_camera);
    return 1;
}

static int transform_set_parent_is_camera(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    bool arg_is_parent_camera = lua_checkbool(lua_state, 2);
    TransformSetParentIsCamera((int)arg_transform_index, arg_is_parent_camera);
    return 0;
}

static int mesh_get_transform(lua_State* lua_state) {
    lua_Integer arg_mesh_handle_index = luaL_checkinteger(lua_state, 1);
    int transform_index = MeshGetTransform((int)arg_mesh_handle_index);
    lua_pushinteger(lua_state, transform_index);
    return 1;
}

static int mesh_set_transform(lua_State* lua_state) {
    lua_Integer arg_mesh_handle_index = luaL_checkinteger(lua_state, 1);
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 2);
    MeshSetTransform((int)arg_mesh_handle_index, (int)arg_transform_index);
    return 0;
}

static int mesh_clear_transform(lua_State* lua_state) {
    lua_Integer arg_mesh_handle_index = luaL_checkinteger(lua_state, 1);
    MeshClearTransform((int)arg_mesh_handle_index);
    return 0;
}

static int transform_set_to_identity(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    TransformSetToIdentity((int)arg_transform_index);
    return 0;
}

static int transform_set_translation(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    double arg_x = luaL_checknumber(lua_state, 2);
    double arg_y = luaL_checknumber(lua_state, 3);
    double arg_z = luaL_checknumber(lua_state, 4);
    TransformSetTranslation((int)arg_transform_index, (float)arg_x, (float)arg_y, (float)arg_z);
    return 0;
}

static int transform_clear_translation(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    TransformClearTranslation((int)arg_transform_index);
    return 0;
}

static int transform_set_rotation_x(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    double arg_angle_in_degrees = luaL_checknumber(lua_state, 2);
    TransformSetRotationX((int)arg_transform_index, (float)arg_angle_in_degrees);
    return 0;
}

static int transform_set_rotation_y(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    double arg_angle_in_degrees = luaL_checknumber(lua_state, 2);
    TransformSetRotationY((int)arg_transform_index, (float)arg_angle_in_degrees);
    return 0;
}

static int transform_set_rotation_z(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    double arg_angle_in_degrees = luaL_checknumber(lua_state, 2);
    TransformSetRotationZ((int)arg_transform_index, (float)arg_angle_in_degrees);
    return 0;
}

static int transform_concat_rotation_x(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    double arg_angle_in_degrees = luaL_checknumber(lua_state, 2);
    TransformConcatRotationX((int)arg_transform_index, (float)arg_angle_in_degrees);
    return 0;
}

static int transform_concat_rotation_y(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    double arg_angle_in_degrees = luaL_checknumber(lua_state, 2);
    TransformConcatRotationY((int)arg_transform_index, (float)arg_angle_in_degrees);
    return 0;
}

static int transform_concat_rotation_z(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    double arg_angle_in_degrees = luaL_checknumber(lua_state, 2);
    TransformConcatRotationZ((int)arg_transform_index, (float)arg_angle_in_degrees);
    return 0;
}

static int transform_clear_rotation(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    TransformClearRotation((int)arg_transform_index);
    return 0;
}

static int transform_set_scale(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    double arg_x = luaL_checknumber(lua_state, 2);
    double arg_y = luaL_checknumber(lua_state, 3);
    double arg_z = luaL_checknumber(lua_state, 4);
    TransformSetScale((int)arg_transform_index, (float)arg_x, (float)arg_y, (float)arg_z);
    return 0;
}

static int transform_clear_scale(lua_State* lua_state) {
    lua_Integer arg_transform_index = luaL_checkinteger(lua_state, 1);
    TransformClearScale((int)arg_transform_index);
    return 0;
}


static int scroll_texture_on_mesh(lua_State* lua_state) {
    lua_Integer mesh_handle_index_arg = luaL_checkinteger(lua_state, 1);
    double translate_x_arg = luaL_checknumber(lua_state, 2);
    double argtranslate_y_arg = luaL_checknumber(lua_state, 3);
    // TODO: Remove pre-multiplication from scripts, and divide from here
    MeshScrollTexture((int)mesh_handle_index_arg, (float)translate_x_arg / 16.0f, (float)argtranslate_y_arg / 16.0f);
    return 0;
}

static int skip_next_mesh_interpolation(lua_State* lua_state) {
    lua_Integer mesh_handle_index_arg = luaL_checkinteger(lua_state, 1);
    MeshSetIsAnimationContinuous((int)mesh_handle_index_arg, false);
    return 0;
}

static int skip_next_camera_interpolation(lua_State* lua_state) {
    SetCameraIsAnimationContinuous(false);
    return 0;
}

static int get_loaded_texture_count(lua_State* lua_state) {
    lua_pushnumber(lua_state, g_loaded_texture_count);
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

static int create_mesh(lua_State* lua_state) {
    // Handle data in the format:
    // {
    //     { pos = { 137, 140, 15 }, normal = { 0, 0, -1 }, uv = { 0, 0 } },
    //     { pos = { 139, 140, 15 }, normal = { 0, 0, -1 }, uv = { 1, 0 } },
    //     ... more vertices here
    // }
    luaL_checktype(lua_state, 1, LUA_TTABLE);

    int texture_index_arg = (int)luaL_checkinteger(lua_state, 2);
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

    assert(g_loaded_mesh_count < kMAX_SCRIPT_MESHES);
    int new_mesh_handle_index = MeshCreateFromVertices(new_mesh_vertices, (int)vertex_count, texture_index_arg, is_visible_arg);
    g_script_mesh_handle_indices[g_loaded_mesh_count] = new_mesh_handle_index;
    ++g_loaded_mesh_count;

    lua_pushnumber(lua_state, (lua_Number)new_mesh_handle_index);

    return 1;
}

static int new_mesh(lua_State* lua_state) {
    double script_mesh_index_arg = luaL_checknumber(lua_state, 1);  // TODO: luaL_checkinteger?
    assert(g_loaded_mesh_count < kMAX_SCRIPT_MESHES);
    int new_mesh_handle_index;
    MeshCreateFromCopy(g_script_mesh_handle_indices[(int)script_mesh_index_arg], &new_mesh_handle_index);
    g_script_mesh_handle_indices[g_loaded_mesh_count] = new_mesh_handle_index;
    ++g_loaded_mesh_count;
    lua_pushnumber(lua_state, new_mesh_handle_index);
    return 1;
}

static int set_mesh_texture(lua_State* lua_state) {
    lua_Integer mesh_handle_index_arg = luaL_checkinteger(lua_state, 1);
    lua_Integer texture_index_arg = luaL_checkinteger(lua_state, 2);
    MeshSetTextureIndex((int)mesh_handle_index_arg, (int)texture_index_arg);
    return 0;
}

static int set_mesh_is_visible(lua_State* lua_state) {
    lua_Integer mesh_handle_index_arg = luaL_checkinteger(lua_state, 1);
    bool is_visible_arg = lua_checkbool(lua_state, 2);
    MeshSetIsVisible((int)mesh_handle_index_arg, is_visible_arg);
    return 0;
}

static int move_transparent_mesh_to_front(lua_State* lua_state) {
    lua_Integer mesh_handle_index_arg = luaL_checkinteger(lua_state, 1);
    MeshMoveToFrontForTransparentDrawing((int)mesh_handle_index_arg);
    return 0;
}

static int move_transparent_mesh_to_back(lua_State* lua_state) {
    lua_Integer mesh_handle_index_arg = luaL_checkinteger(lua_state, 1);
    MeshMoveToBackForTransparentDrawing((int)mesh_handle_index_arg);
    return 0;
}

static int set_fog(lua_State* lua_state) {
    lua_Number fog_start_arg = luaL_checknumber(lua_state, 1);
    lua_Number fog_end_arg = luaL_checknumber(lua_state, 2);
    lua_Integer red_arg = luaL_checkinteger(lua_state, 3);
    lua_Integer green_arg = luaL_checkinteger(lua_state, 4);
    lua_Integer blue_arg = luaL_checkinteger(lua_state, 5);
    SetFog((float)fog_start_arg, (float)fog_end_arg, red_arg & 0xFF, green_arg & 0xFF, blue_arg & 0xFF);
    return 0;
}

static int get_config_option_string(lua_State* lua_state) {  // TODO: Might be able to move to Lua?
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

static int set_config_option(lua_State* lua_state) {  // TODO: Might be able to move to Lua?
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

        for(int iLoop = 0; iLoop < 6; ++iLoop) {
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

static int save_config_options(lua_State* lua_state) {  // TODO: Might be able to move to Lua?
    (void)(lua_state);  // Unused, but passed due to passing this function as a function pointer
    SaveSettings();
    return 0;
}

static int play_sound_effect(lua_State* lua_state) {
    double arg1 = luaL_checknumber(lua_state, 1);  // TODO: luaL_checkinteger?
    PlaySoundEffect((size_t)arg1);
    return 0;
}

static int delete_mesh(lua_State* lua_state) {
    double mesh_handle_index_arg = luaL_checknumber(lua_state, 1);  // TODO: luaL_checkinteger?
    // TODO: Does this assert make sense? assert(mesh_index < g_loaded_mesh_count);
    MeshDelete((int)mesh_handle_index_arg);
    // TODO: Need to decrement the mesh counter here, but can't without messing with future mesh index allocations
    //       Is there a way to just rely on Basic3D to handle the mesh tracking stuff somehow?
    return 0;
}

static int set_perspective(lua_State* lua_state) {
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
        if(luaL_callmeta(lua_state, 1, "__tostring") && lua_type(lua_state, -1) == LUA_TSTRING) {
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

    lua_pushcfunction(lua_state, unload_all_resources);
    lua_setglobal(lua_state, "unload_all_resources");
    lua_pushcfunction(lua_state, begin_loading_3d_data);
    lua_setglobal(lua_state, "begin_loading_3d_data");
    lua_pushcfunction(lua_state, end_and_commit_loading_3d_data);
    lua_setglobal(lua_state, "end_and_commit_loading_3d_data");

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

    lua_pushcfunction(lua_state, set_mesh_to_mesh);
    lua_setglobal(lua_state, "set_mesh_to_mesh");
    lua_pushcfunction(lua_state, scroll_texture_on_mesh);
    lua_setglobal(lua_state, "scroll_texture_on_mesh");
    lua_pushcfunction(lua_state, skip_next_mesh_interpolation);
    lua_setglobal(lua_state, "skip_next_mesh_interpolation");
    lua_pushcfunction(lua_state, skip_next_camera_interpolation);
    lua_setglobal(lua_state, "skip_next_camera_interpolation");
    lua_pushcfunction(lua_state, set_mesh_texture);
    lua_setglobal(lua_state, "set_mesh_texture");
    lua_pushcfunction(lua_state, set_mesh_is_visible);
    lua_setglobal(lua_state, "set_mesh_is_visible");

    lua_pushcfunction(lua_state, transform_create);
    lua_setglobal(lua_state, "transform_create");
    lua_pushcfunction(lua_state, transform_delete);
    lua_setglobal(lua_state, "transform_delete");
    lua_pushcfunction(lua_state, transform_get_parent);
    lua_setglobal(lua_state, "transform_get_parent");
    lua_pushcfunction(lua_state, transform_set_parent);
    lua_setglobal(lua_state, "transform_set_parent");
    lua_pushcfunction(lua_state, transform_clear_parent);
    lua_setglobal(lua_state, "transform_clear_parent");
    lua_pushcfunction(lua_state, transform_set_parent_is_camera);
    lua_setglobal(lua_state, "transform_set_parent_is_camera");
    lua_pushcfunction(lua_state, mesh_get_transform);
    lua_setglobal(lua_state, "mesh_get_transform");
    lua_pushcfunction(lua_state, mesh_set_transform);
    lua_setglobal(lua_state, "mesh_set_transform");
    lua_pushcfunction(lua_state, mesh_clear_transform);
    lua_setglobal(lua_state, "mesh_clear_transform");
    lua_pushcfunction(lua_state, transform_set_to_identity);
    lua_setglobal(lua_state, "transform_set_to_identity");
    lua_pushcfunction(lua_state, transform_set_translation);
    lua_setglobal(lua_state, "transform_set_translation");
    lua_pushcfunction(lua_state, transform_clear_translation);
    lua_setglobal(lua_state, "transform_clear_translation");
    lua_pushcfunction(lua_state, transform_set_rotation_x);
    lua_setglobal(lua_state, "transform_set_rotation_x");
    lua_pushcfunction(lua_state, transform_set_rotation_y);
    lua_setglobal(lua_state, "transform_set_rotation_y");
    lua_pushcfunction(lua_state, transform_set_rotation_z);
    lua_setglobal(lua_state, "transform_set_rotation_z");
    lua_pushcfunction(lua_state, transform_concat_rotation_x);
    lua_setglobal(lua_state, "transform_concat_rotation_x");
    lua_pushcfunction(lua_state, transform_concat_rotation_y);
    lua_setglobal(lua_state, "transform_concat_rotation_y");
    lua_pushcfunction(lua_state, transform_concat_rotation_z);
    lua_setglobal(lua_state, "transform_concat_rotation_z");
    lua_pushcfunction(lua_state, transform_clear_rotation);
    lua_setglobal(lua_state, "transform_clear_rotation");
    lua_pushcfunction(lua_state, transform_set_scale);
    lua_setglobal(lua_state, "transform_set_scale");
    lua_pushcfunction(lua_state, transform_clear_scale);
    lua_setglobal(lua_state, "transform_clear_scale");

    lua_pushcfunction(lua_state, get_loaded_texture_count);
    lua_setglobal(lua_state, "get_loaded_texture_count");
    lua_pushcfunction(lua_state, get_is_sound_enabled);
    lua_setglobal(lua_state, "get_is_sound_enabled");
    lua_pushcfunction(lua_state, get_is_music_enabled);
    lua_setglobal(lua_state, "get_is_music_enabled");
    lua_pushcfunction(lua_state, get_last_key_pressed);
    lua_setglobal(lua_state, "get_last_key_pressed");
    lua_pushcfunction(lua_state, get_current_fps);
    lua_setglobal(lua_state, "get_current_fps");

    lua_pushcfunction(lua_state, create_mesh);
    lua_setglobal(lua_state, "create_mesh");
    lua_pushcfunction(lua_state, new_mesh);
    lua_setglobal(lua_state, "new_mesh");
    lua_pushcfunction(lua_state, move_transparent_mesh_to_front);
    lua_setglobal(lua_state, "move_transparent_mesh_to_front");
    lua_pushcfunction(lua_state, move_transparent_mesh_to_back);
    lua_setglobal(lua_state, "move_transparent_mesh_to_back");
    lua_pushcfunction(lua_state, set_fog);
    lua_setglobal(lua_state, "set_fog");
    lua_pushcfunction(lua_state, get_config_option_string);
    lua_setglobal(lua_state, "get_config_option_string");
    lua_pushcfunction(lua_state, set_config_option);
    lua_setglobal(lua_state, "set_config_option");
    lua_pushcfunction(lua_state, save_config_options);
    lua_setglobal(lua_state, "save_config_options");
    lua_pushcfunction(lua_state, play_sound_effect);
    lua_setglobal(lua_state, "play_sound_effect");

    lua_pushcfunction(lua_state, delete_mesh);
    lua_setglobal(lua_state, "delete_mesh");
    lua_pushcfunction(lua_state, set_perspective);
    lua_setglobal(lua_state, "set_perspective");
}

static void LoadLuaScript(const char* filename, LuaModuleScriptContext* new_script_context) {
    assert(new_script_context != NULL);  // TODO: Error handling

    if(new_script_context->lua_state != NULL) {
        lua_close(new_script_context->lua_state);
    }

    char full_filename[300];  // TODO: Standardize path lengths? Bigger paths?
    stbsp_snprintf(full_filename, sizeof(full_filename), "%s/%s", g_game_base_path, filename);

    lua_State* new_state;
    new_state = luaL_newstate();
    assert(new_state != NULL);  // TODO: Error handling

    luaL_openlibs(new_state);

    int load_file_result = luaL_loadfile(new_state, full_filename);
    if(load_file_result != 0) {
        const char* error_message = lua_tostring(new_state, -1);
        debug_log("Error while loading script: %s\n%s", full_filename, error_message);
        assert(false);  // TODO: Error handling
    }

    RegisterLuaScriptFunctions(new_state);

    int arg_count = 0;
    int error_handler_stack_pos = lua_gettop(new_state) - arg_count;

    lua_pushcfunction(new_state, lua_error_handler);
    lua_insert(new_state, error_handler_stack_pos);

    if(lua_pcall(new_state, 0, 1, error_handler_stack_pos) != 0) {
        const char* error_message = lua_tostring(new_state, -1);
        debug_log("Error while initially running script module: %s\n%s", full_filename, error_message);
        assert(false);  // TODO: Error handling
    }

    assert(lua_istable(new_state, -1) && "Expected loaded script file to return a module table");

    lua_remove(new_state, error_handler_stack_pos);

    new_script_context->module_table_registry_index = luaL_ref(new_state, LUA_REGISTRYINDEX);
    new_script_context->lua_state = new_state;
}

static void PushGameActionAsTable(lua_State* lua_state, const GameAction* game_action) {
    lua_newtable(lua_state);
    lua_pushboolean(lua_state, game_action->is_pressed);
    lua_setfield(lua_state, -2, "is_pressed");
    lua_pushboolean(lua_state, game_action->just_pressed);
    lua_setfield(lua_state, -2, "just_pressed");
}

static void PushGameInputAsTable(lua_State* lua_state, const GameInput* game_input) {
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
    PushGameActionAsTable(lua_state, &game_input->cheat_action);
    lua_setfield(lua_state, -2, "cheat_action");
    PushGameActionAsTable(lua_state, &game_input->cursor_select_action);
    lua_setfield(lua_state, -2, "cursor_select_action");

    lua_newtable(lua_state);
    lua_pushnumber(lua_state, game_input->cursor_position.x);
    lua_setfield(lua_state, -2, "x");
    lua_pushnumber(lua_state, game_input->cursor_position.y);
    lua_setfield(lua_state, -2, "y");
    lua_setfield(lua_state, -2, "cursor_position");

    lua_pushboolean(lua_state, game_input->cursor_is_on_screen);
    lua_setfield(lua_state, -2, "cursor_is_on_screen");
}

static bool CallLuaModuleFunction(LuaModuleScriptContext* script_context, const char* function_name, const GameInput* game_input, int pushed_arg_count, int expected_result_count, bool optional) {
    bool result = false;

    assert(script_context != NULL);  // TODO: Error handling

    lua_State* lua_state = script_context->lua_state;
    int module_function_stack_pos = lua_gettop(lua_state) - pushed_arg_count + 1;  // 1-based indexing

    lua_rawgeti(lua_state, LUA_REGISTRYINDEX, script_context->module_table_registry_index);
    assert(lua_type(lua_state, -1) == LUA_TTABLE && "Unable to retrieve module table from registry");
    lua_getfield(lua_state, -1, function_name);

    if(lua_isfunction(lua_state, -1) != 0) {
        int arg_count = pushed_arg_count;

        // Move the module function just under the previously pushed args
        lua_insert(lua_state, module_function_stack_pos);
        lua_pop(lua_state, 1);  // Remove module table from stack

        // Push input arg, if passed in
        if(game_input != NULL) {
            PushGameInputAsTable(lua_state, game_input);
            ++arg_count;
        }

        // Place error handler just under module function
        int error_handler_stack_pos = module_function_stack_pos;
        lua_pushcfunction(lua_state, lua_error_handler);
        lua_insert(lua_state, error_handler_stack_pos);

        if(lua_pcall(lua_state, arg_count, expected_result_count, error_handler_stack_pos) != 0) {
            const char* error_message = lua_tostring(lua_state, -1);
            debug_log("Error while calling Lua function in main script: %s\n%s", function_name, error_message);
            assert(false);  // TODO: Error handling
        }
        else
        {
            result = true;
        }

        lua_remove(lua_state, error_handler_stack_pos);
    } else {
        assert(optional);  // TODO: Error handling

        lua_pop(lua_state, 1);  // Remove nil function from stack
        lua_pop(lua_state, 1);  // Remove module table from stack
        lua_pop(lua_state, pushed_arg_count);  // Remove pushed args from stack
    }

    return result;
}

// ------------------- API FOR PLATFORM LAYER -------------------------------

bool Init3D(void) {
    for(int mesh_index = 0; mesh_index < kMAX_SCRIPT_MESHES; ++mesh_index) {
        g_script_mesh_handle_indices[mesh_index] = -1;
    }

    if(!InitializeAll()) {
        return 0;
    }

    return 1;
}

void InitGameDebugScript(const char* base_path, const char* script_name) {
    g_game_base_path = base_path;
    char relative_script_filename[300];  // TODO: Standardize path lengths? Bigger paths?
    stbsp_snprintf(relative_script_filename, sizeof(relative_script_filename), "data/%s", script_name);
    LoadLuaScript(relative_script_filename, &g_main_script_context);
    CallLuaModuleFunction(&g_main_script_context, "initialize", NULL, 0, 0, false);
}

void InitGameDebugLevel(const char* base_path, const char* level_name) {
    g_game_base_path = base_path;
    LoadLuaScript("data/main.lua", &g_main_script_context);
    lua_pushstring(g_main_script_context.lua_state, level_name);
    CallLuaModuleFunction(&g_main_script_context, "initialize", NULL, 1, 0, false);
}

void InitGameNormal(const char* base_path) {
    g_game_base_path = base_path;
    LoadLuaScript("data/main.lua", &g_main_script_context);
    CallLuaModuleFunction(&g_main_script_context, "initialize", NULL, 0, 0, false);
}

void UpdateGame(const GameInput* game_input, double seconds_per_update_timestep) {
    if(!IsGameFrozen()) {
        RendererPreUpdate(seconds_per_update_timestep);
        CallLuaModuleFunction(&g_main_script_context, "update", game_input, 0, 0, false);
        RendererPostUpdate();
    }
}

void DrawGame(double seconds_per_update_timestep, double seconds_since_previous_update, double time_scale) {
    // TODO: Just push interpolation_scale?
    lua_pushnumber(g_main_script_context.lua_state, seconds_per_update_timestep);
    lua_pushnumber(g_main_script_context.lua_state, seconds_since_previous_update);
    lua_pushnumber(g_main_script_context.lua_state, time_scale);

    bool pre_draw_function_existed = CallLuaModuleFunction(&g_main_script_context, "pre_draw", NULL, 3, 1, true);

    bool do_interpolation = true;
    if(pre_draw_function_existed) {
        do_interpolation = !lua_checkbool(g_main_script_context.lua_state, -1);
        lua_pop(g_main_script_context.lua_state, 1);
    }

    float interpolation_scale = (float)(time_scale * seconds_since_previous_update / seconds_per_update_timestep);
    RendererDraw(do_interpolation, interpolation_scale);
}

void ExitGame(void) {
    CallLuaModuleFunction(&g_main_script_context, "on_exit_requested", NULL, 0, 0, false);
}
