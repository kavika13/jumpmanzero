const std = @import("std");
const lua = @import("lua");
const basic_3d = @import("basic_3d.zig");
const jumpman_main_c = @cImport({
    @cInclude("Input.h");
    @cInclude("Main.h");
    @cInclude("Music.h");
    @cInclude("Sound.h");
    @cInclude("SoundBuffer.h");
    @cInclude("Utilities.h");
});

const LuaModuleScriptContext = struct {
    lua_state: ?*lua.lua_State,
    module_table_registry_index: i32,
};

var g_game_base_path: []const u8 = undefined;

var g_loaded_texture_count: i32 = undefined;
var g_loaded_sound_count: i32 = undefined;

const kMAX_SCRIPT_MESHES: usize = 600;

var g_main_script_context: LuaModuleScriptContext = .{ null, -1 };

// ------------------- LUA SCRIPT API -------------------------------

fn lua_checkbool(L: *lua.lua_State, arg: i32) bool {
    lua.luaL_checktype(L, arg, lua.LUA_TBOOLEAN);
    const d: i32 = lua.lua_toboolean(L, arg);
    return d;
}

fn unload_all_resources(_: *lua.lua_State) i32 {
    basic_3d.Clear3dData();

    g_loaded_texture_count = 0;
    g_loaded_sound_count = 0;

    return 0;
}

fn begin_loading_3d_data(_: *lua.lua_State) i32 {
    basic_3d.Begin3dLoad();
    return 0;
}

fn end_and_commit_loading_3d_data(_: *lua.lua_State) i32 {
    basic_3d.EndAndCommit3dLoad();
    return 0;
}

fn play_music_track_1(lua_state: *lua.lua_State) i32 {
    // TODO: Error checking for filename?
    const new_music_track_arg: []const u8 = lua.lua_tostring(lua_state, 1);
    const song_start_music_time_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 2);
    const loop_start_music_time_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 3);

    if (song_start_music_time_arg < 0) {
        lua.luaL_argerror(lua_state, 2, "song_start_music_time must be 0 or greater");
    }

    jumpman_main_c.NewTrack1(new_music_track_arg, song_start_music_time_arg, loop_start_music_time_arg);

    return 0;
}

fn stop_music_track_1(_: *lua.lua_State) i32 {
    jumpman_main_c.StopMusic1(); // TODO: Error checking?
    return 0;
}

fn play_music_track_2(lua_state: *lua.lua_State) i32 {
    // TODO: Error checking for filename?
    const new_music_track_arg: []const u8 = lua.lua_tostring(lua_state, 1);
    jumpman_main_c.NewTrack2(new_music_track_arg);
    return 0;
}

fn load_sound(lua_state: *lua.lua_State) i32 {
    // TODO: Error checking for filename?
    const filename_arg: []const u8 = lua.lua_tostring(lua_state, 1);
    const full_filename: [300]u8 = undefined; // TODO: Standardize path lengths? Bigger paths?
    std.fmt.bufPrint(full_filename, "{s}/{s}", .{ g_game_base_path, filename_arg });

    jumpman_main_c.LoadSound(full_filename, g_loaded_sound_count);
    lua.lua_pushinteger(lua_state, g_loaded_sound_count);
    g_loaded_sound_count += 1;

    return 1;
}

fn load_texture(lua_state: *lua.lua_State) i32 {
    // TODO: Error checking for filename?
    const filename_arg: []const u8 = lua.lua_tostring(lua_state, 1);
    const image_type_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 2);
    const is_alpha_blend_enabled_arg: bool = lua_checkbool(lua_state, 3);
    const full_filename: [300]u8 = undefined; // TODO: Standardize path lengths? Bigger paths?
    std.fmt.bufPrint(full_filename, "{s}/{s}", .{ g_game_base_path, filename_arg });

    basic_3d.LoadTexture(g_loaded_texture_count, full_filename, image_type_arg, is_alpha_blend_enabled_arg);
    lua.lua_pushinteger(lua_state, g_loaded_texture_count);
    g_loaded_texture_count += 1;

    return 1;
}

// TODO: Take allocator as param
fn LoadMesh(base_path: []const u8, sFileName: []const u8) i32 {
    const sFullFile: [300]u8 = undefined;
    std.fmt.bufPrint(sFullFile, "{s}/{s}", .{ base_path, sFileName });

    var cData: []u8 = null;
    const vertex_component_count: i32 = jumpman_main_c.FileToString(sFullFile, &cData);
    defer std.heap.raw_c_allocator.free(cData);
    vertex_component_count = vertex_component_count / 4;

    const vertex_components: []i32 = std.heap.c_allocator.alloc(i32, vertex_component_count) catch @panic("failed to allocate"); // TODO: Better error handling
    defer std.heap.raw_c_allocator.free(vertex_components);

    for (0..vertex_component_count) |component_index| {
        vertex_components[component_index] = jumpman_main_c.StringToLong(&cData[component_index << 2]);
    }

    const result_mesh_handle_index: i32 = basic_3d.MeshCreateFromVertexComponents(vertex_components, vertex_component_count / 9);

    return result_mesh_handle_index;
}

fn load_mesh(lua_state: *lua.lua_State) i32 {
    // TODO: Error checking for filename?
    const filename_arg: []const u8 = lua.lua_tostring(lua_state, 1);
    const loaded_mesh_handle_index: i32 = LoadMesh(g_game_base_path, filename_arg);
    lua.lua_pushinteger(lua_state, loaded_mesh_handle_index);
    return 1;
}

fn set_mesh_to_mesh(lua_state: *lua.lua_State) i32 {
    const target_mesh_handle_index_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const source_mesh_handle_index_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 2);
    basic_3d.MeshReplaceWithCopy(target_mesh_handle_index_arg, source_mesh_handle_index_arg);
    return 0;
}

fn transform_create(lua_state: *lua.lua_State) i32 {
    const new_transform_index: i32 = basic_3d.TransformCreate();
    lua.lua_pushinteger(lua_state, new_transform_index);
    return 1;
}

fn transform_delete(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    basic_3d.TransformDelete(arg_transform_index);
    return 0;
}

fn transform_get_parent(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const parent_transform_index: i32 = basic_3d.TransformGetParent(arg_transform_index);
    lua.lua_pushinteger(lua_state, parent_transform_index);
    return 1;
}

fn transform_set_parent(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const arg_new_parent_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 2);
    basic_3d.TransformSetParent(arg_transform_index, arg_new_parent_index);
    return 0;
}

fn transform_clear_parent(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    basic_3d.TransformClearParent(arg_transform_index);
    return 0;
}

fn transform_get_parent_is_camera(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const is_parent_camera: bool = basic_3d.TransformGetParentIsCamera(arg_transform_index);
    lua.lua_pushboolean(lua_state, is_parent_camera);
    return 1;
}

fn transform_set_parent_is_camera(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const arg_is_parent_camera: bool = lua_checkbool(lua_state, 2);
    basic_3d.TransformSetParentIsCamera(arg_transform_index, arg_is_parent_camera);
    return 0;
}

fn mesh_get_transform(lua_state: *lua.lua_State) i32 {
    const arg_mesh_handle_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const transform_index: i32 = basic_3d.MeshGetTransform(arg_mesh_handle_index);
    lua.lua_pushinteger(lua_state, transform_index);
    return 1;
}

fn mesh_set_transform(lua_state: *lua.lua_State) i32 {
    const arg_mesh_handle_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 2);
    basic_3d.MeshSetTransform(arg_mesh_handle_index, arg_transform_index);
    return 0;
}

fn mesh_clear_transform(lua_state: *lua.lua_State) i32 {
    const arg_mesh_handle_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    basic_3d.MeshClearTransform(arg_mesh_handle_index);
    return 0;
}

fn transform_set_to_identity(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    basic_3d.TransformSetToIdentity(arg_transform_index);
    return 0;
}

fn transform_set_translation(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const arg_x: f64 = lua.luaL_checknumber(lua_state, 2);
    const arg_y: f64 = lua.luaL_checknumber(lua_state, 3);
    const arg_z: f64 = lua.luaL_checknumber(lua_state, 4);
    basic_3d.TransformSetTranslation(arg_transform_index, arg_x, arg_y, arg_z);
    return 0;
}

fn transform_clear_translation(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    basic_3d.TransformClearTranslation(arg_transform_index);
    return 0;
}

fn transform_set_rotation_x(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const arg_angle_in_degrees: f64 = lua.luaL_checknumber(lua_state, 2);
    basic_3d.TransformSetRotationX(arg_transform_index, arg_angle_in_degrees);
    return 0;
}

fn transform_set_rotation_y(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const arg_angle_in_degrees: f64 = lua.luaL_checknumber(lua_state, 2);
    basic_3d.TransformSetRotationY(arg_transform_index, arg_angle_in_degrees);
    return 0;
}

fn transform_set_rotation_z(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const arg_angle_in_degrees: f64 = lua.luaL_checknumber(lua_state, 2);
    basic_3d.TransformSetRotationZ(arg_transform_index, arg_angle_in_degrees);
    return 0;
}

fn transform_concat_rotation_x(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const arg_angle_in_degrees: f64 = lua.luaL_checknumber(lua_state, 2);
    basic_3d.TransformConcatRotationX(arg_transform_index, arg_angle_in_degrees);
    return 0;
}

fn transform_concat_rotation_y(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const arg_angle_in_degrees: f64 = lua.luaL_checknumber(lua_state, 2);
    basic_3d.TransformConcatRotationY(arg_transform_index, arg_angle_in_degrees);
    return 0;
}

fn transform_concat_rotation_z(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const arg_angle_in_degrees: f64 = lua.luaL_checknumber(lua_state, 2);
    basic_3d.TransformConcatRotationZ(arg_transform_index, arg_angle_in_degrees);
    return 0;
}

fn transform_clear_rotation(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    basic_3d.TransformClearRotation(arg_transform_index);
    return 0;
}

fn transform_set_scale(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const arg_x: f64 = lua.luaL_checknumber(lua_state, 2);
    const arg_y: f64 = lua.luaL_checknumber(lua_state, 3);
    const arg_z: f64 = lua.luaL_checknumber(lua_state, 4);
    basic_3d.TransformSetScale(arg_transform_index, arg_x, arg_y, arg_z);
    return 0;
}

fn transform_clear_scale(lua_state: *lua.lua_State) i32 {
    const arg_transform_index: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    basic_3d.TransformClearScale(arg_transform_index);
    return 0;
}

fn scroll_texture_on_mesh(lua_state: *lua.lua_State) i32 {
    const mesh_handle_index_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const translate_x_arg: f64 = lua.luaL_checknumber(lua_state, 2);
    const argtranslate_y_arg: f64 = lua.luaL_checknumber(lua_state, 3);
    basic_3d.MeshScrollTexture(mesh_handle_index_arg, translate_x_arg, argtranslate_y_arg);
    return 0;
}

fn skip_next_mesh_interpolation(lua_state: *lua.lua_State) i32 {
    const mesh_handle_index_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    basic_3d.MeshSetIsAnimationContinuous(mesh_handle_index_arg, false);
    return 0;
}

fn skip_next_camera_interpolation(_: *lua.lua_State) i32 {
    basic_3d.SetCameraIsAnimationContinuous(false);
    return 0;
}

fn get_loaded_texture_count(lua_state: *lua.lua_State) i32 {
    lua.lua_pushnumber(lua_state, g_loaded_texture_count);
    return 1;
}

fn get_is_sound_enabled(lua_state: *lua.lua_State) i32 {
    lua.lua_pushboolean(lua_state, jumpman_main_c.GetIsSoundEnabled());
    return 1;
}

fn get_is_music_enabled(lua_state: *lua.lua_State) i32 {
    lua.lua_pushboolean(lua_state, jumpman_main_c.GetIsMusicEnabled());
    return 1;
}

fn get_last_key_pressed(lua_state: *lua.lua_State) i32 {
    lua.lua_pushnumber(lua_state, jumpman_main_c.GetLastKeyPressed());
    return 1;
}

fn get_current_fps(lua_state: *lua.lua_State) i32 {
    lua.lua_pushnumber(lua_state, jumpman_main_c.GetCurrentFps());
    return 1;
}

fn create_mesh(lua_state: *lua.lua_State) i32 {
    // Handle data in the format:
    // {
    //     { pos = { 137, 140, 15 }, normal = { 0, 0, -1 }, uv = { 0, 0 } },
    //     { pos = { 139, 140, 15 }, normal = { 0, 0, -1 }, uv = { 1, 0 } },
    //     ... more vertices here
    // }
    lua.luaL_checktype(lua_state, 1, lua.LUA_TTABLE);

    const texture_index_arg: i32 = lua.luaL_checkinteger(lua_state, 2);
    var is_visible_arg: bool = true;

    if (lua.lua_isboolean(lua_state, 3)) {
        is_visible_arg = lua.lua_toboolean(lua_state, 3) != 0;
    }

    const vertex_count: usize = lua.lua_rawlen(lua_state, 1);
    const triangle_count: usize = vertex_count / 3;
    std.debug.assert(triangle_count * 3 == vertex_count); // "Vertex data passed in isn't divisible by 3 (triangles)"

    const new_mesh_vertices: [*]basic_3d.MeshVertex = std.heap.c_allocator.alloc(basic_3d.MeshVertex, vertex_count) catch @panic("failed to allocate"); // TODO: Better error handling

    for (0..vertex_count) |vertex_index| {
        lua.lua_rawgeti(lua_state, 1, vertex_index + 1); // Current vertex table. Lua indices are 1-based
        lua.luaL_checktype(lua_state, -1, lua.LUA_TTABLE);

        lua.lua_getfield(lua_state, -1, "pos");
        const pos_size: usize = lua.lua_rawlen(lua_state, -1);
        std.debug.assert(pos_size == 3); // "Expected pos field to have 3 entries, one each for x, y, and z";

        lua.lua_rawgeti(lua_state, -1, 1); // Lua indices are 1-based
        new_mesh_vertices[vertex_index].x = lua.luaL_checknumber(lua_state, -1);
        lua.lua_pop(lua_state, 1);

        lua.lua_rawgeti(lua_state, -1, 2);
        new_mesh_vertices[vertex_index].y = lua.luaL_checknumber(lua_state, -1);
        lua.lua_pop(lua_state, 1);

        lua.lua_rawgeti(lua_state, -1, 3);
        new_mesh_vertices[vertex_index].z = lua.luaL_checknumber(lua_state, -1);
        lua.lua_pop(lua_state, 1);

        lua.lua_pop(lua_state, 1); // pos table

        lua.lua_getfield(lua_state, -1, "normal");
        const normal_size: usize = lua.lua_rawlen(lua_state, -1);
        std.debug.assert(normal_size == 3); // "Expected normal field to have 3 entries, one each for nx, ny, and nz"

        lua.lua_rawgeti(lua_state, -1, 1); // Lua indices are 1-based
        new_mesh_vertices[vertex_index].nx = lua.luaL_checknumber(lua_state, -1);
        lua.lua_pop(lua_state, 1);

        lua.lua_rawgeti(lua_state, -1, 2);
        new_mesh_vertices[vertex_index].ny = lua.luaL_checknumber(lua_state, -1);
        lua.lua_pop(lua_state, 1);

        lua.lua_rawgeti(lua_state, -1, 3);
        new_mesh_vertices[vertex_index].nz = lua.luaL_checknumber(lua_state, -1);
        lua.lua_pop(lua_state, 1);

        lua.lua_pop(lua_state, 1); // normal table

        lua.lua_getfield(lua_state, -1, "uv");
        const uv_size: usize = lua.lua_rawlen(lua_state, -1);
        std.debug.assert(uv_size == 2); // "Expected uv field to have 2 entries, one each for tu, tv"

        lua.lua_rawgeti(lua_state, -1, 1); // Lua indices are 1-based
        new_mesh_vertices[vertex_index].tu = lua.luaL_checknumber(lua_state, -1);
        lua.lua_pop(lua_state, 1);

        lua.lua_rawgeti(lua_state, -1, 2);
        new_mesh_vertices[vertex_index].tv = lua.luaL_checknumber(lua_state, -1);
        lua.lua_pop(lua_state, 1);

        lua.lua_pop(lua_state, 1); // uv table

        lua.lua_pop(lua_state, 1); // Current vertex table
    }

    const new_mesh_handle_index: i32 = basic_3d.MeshCreateFromVertices(new_mesh_vertices, vertex_count, texture_index_arg, is_visible_arg);

    lua.lua_pushnumber(lua_state, new_mesh_handle_index);

    return 1;
}

fn new_mesh(lua_state: *lua.lua_State) i32 {
    const script_mesh_index_arg: f64 = lua.luaL_checknumber(lua_state, 1); // TODO: luaL_checkinteger?
    const new_mesh_handle_index: i32 = basic_3d.MeshCreateFromCopy(script_mesh_index_arg);
    lua.lua_pushnumber(lua_state, new_mesh_handle_index);
    return 1;
}

fn set_mesh_texture(lua_state: *lua.lua_State) i32 {
    const mesh_handle_index_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const texture_index_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 2);
    basic_3d.MeshSetTextureIndex(mesh_handle_index_arg, texture_index_arg);
    return 0;
}

fn set_mesh_is_visible(lua_state: *lua.lua_State) i32 {
    const mesh_handle_index_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const is_visible_arg: bool = lua_checkbool(lua_state, 2);
    basic_3d.MeshSetIsVisible(mesh_handle_index_arg, is_visible_arg);
    return 0;
}

fn move_transparent_mesh_to_front(lua_state: *lua.lua_State) i32 {
    const mesh_handle_index_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    basic_3d.MeshMoveToFrontForTransparentDrawing(mesh_handle_index_arg);
    return 0;
}

fn move_transparent_mesh_to_back(lua_state: *lua.lua_State) i32 {
    const mesh_handle_index_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    basic_3d.MeshMoveToBackForTransparentDrawing(mesh_handle_index_arg);
    return 0;
}

fn set_fog(lua_state: *lua.lua_State) i32 {
    const fog_start_arg: lua.lua_Number = lua.luaL_checknumber(lua_state, 1);
    const fog_end_arg: lua.lua_Number = lua.luaL_checknumber(lua_state, 2);
    const red_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 3);
    const green_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 4);
    const blue_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 5);
    basic_3d.SetFog(fog_start_arg, fog_end_arg, red_arg & 0xFF, green_arg & 0xFF, blue_arg & 0xFF);
    return 0;
}

fn get_config_option_string(lua_state: *lua.lua_State) i32 { // TODO: Might be able to move to Lua?
    const sName: [100]u8 = undefined;
    const option_index_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);

    if (option_index_arg >= 0 and option_index_arg <= 5) {
        const iKey: i32 = jumpman_main_c.GetKeyBinding(option_index_arg);

        if (iKey >= 'A' and iKey <= 'Z') {
            std.fmt.bufPrint(sName, "{}   ", .{iKey});
        } else if (iKey >= '0' and iKey <= '9') {
            std.fmt.bufPrint(sName, "{}   ", .{iKey});
        } else if (iKey == 38) {
            std.mem.copyForwards(u8, sName, "UP  ");
        } else if (iKey == 40) {
            std.mem.copyForwards(u8, sName, "DOWN");
        } else if (iKey == 37) {
            std.mem.copyForwards(u8, sName, "LEFT");
        } else if (iKey == 39) {
            std.mem.copyForwards(u8, sName, "RGHT");
        } else if (iKey == 32) {
            std.mem.copyForwards(u8, sName, "SPC ");
        } else if (iKey == 58) {
            std.mem.copyForwards(u8, sName, ":   ");
        } else if (iKey == 46) {
            std.mem.copyForwards(u8, sName, ".   ");
        } else if (iKey == 45) {
            std.mem.copyForwards(u8, sName, "-   ");
        }
    } else if (option_index_arg == 32 or option_index_arg == 33) {
        const iKey: i32 = undefined;

        if (option_index_arg == 32) {
            iKey = @intFromBool(jumpman_main_c.GetIsSoundEnabled());
        } else {
            iKey = @intFromBool(jumpman_main_c.GetIsMusicEnabled());
        }

        if (iKey) {
            std.mem.copyForwards(u8, sName, "ON  ");
        } else {
            std.mem.copyForwards(u8, sName, "OFF ");
        }
    }

    lua.lua_pushstring(lua_state, sName);

    return 1;
}

fn set_config_option(lua_state: *lua.lua_State) i32 { // TODO: Might be able to move to Lua?
    const option_index_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 1);
    const key_arg: lua.lua_Integer = lua.luaL_checkinteger(lua_state, 2);

    var is_key_good: bool = false;

    if (option_index_arg >= 0 and option_index_arg <= 5) {
        const iKey: i32 = key_arg;

        if (iKey == 38 and option_index_arg == 0) {
            is_key_good = true;
        }

        if (iKey == 40 and option_index_arg == 1) {
            is_key_good = true;
        }

        if (iKey == 37 and option_index_arg == 2) {
            is_key_good = true;
        }

        if (iKey == 39 and option_index_arg == 3) {
            is_key_good = true;
        }

        if (iKey == 32 and option_index_arg == 4) {
            is_key_good = true;
        }

        if (iKey >= 'A' and iKey <= 'Z') {
            is_key_good = true;
        }

        if (iKey >= '0' and iKey <= '9') {
            is_key_good = true;
        }

        for (0..6) |iLoop| {
            if (option_index_arg != iLoop and jumpman_main_c.GetKeyBinding(iLoop) == iKey) {
                is_key_good = false;
            }
        }

        if (is_key_good) {
            jumpman_main_c.SetKeyBinding(option_index_arg, iKey);
        }
    }

    if (option_index_arg == 32) {
        jumpman_main_c.SetIsSoundEnabled(key_arg != 0);
        is_key_good = true;
    }

    if (option_index_arg == 33) {
        jumpman_main_c.SetIsMusicEnabled(key_arg != 0);
        is_key_good = true;
    }

    lua.lua_pushboolean(lua_state, is_key_good);

    return 1;
}

fn save_config_options(_: *lua.lua_State) i32 { // TODO: Might be able to move to Lua?
    jumpman_main_c.SaveSettings();
    return 0;
}

fn play_sound_effect(lua_state: *lua.lua_State) i32 {
    const arg1: f64 = lua.luaL_checknumber(lua_state, 1); // TODO: luaL_checkinteger?
    jumpman_main_c.PlaySoundEffect(arg1);
    return 0;
}

fn delete_mesh(lua_state: *lua.lua_State) i32 {
    const mesh_handle_index_arg: f64 = lua.luaL_checknumber(lua_state, 1); // TODO: luaL_checkinteger?
    basic_3d.MeshDelete(@intFromFloat(mesh_handle_index_arg));
    return 0;
}

fn set_perspective(lua_state: *lua.lua_State) i32 {
    const camera_x_arg: f64 = lua.luaL_checknumber(lua_state, 1);
    const camera_y_arg: f64 = lua.luaL_checknumber(lua_state, 2);
    const camera_z_arg: f64 = lua.luaL_checknumber(lua_state, 3);
    const look_at_x_arg: f64 = lua.luaL_checknumber(lua_state, 4);
    const look_at_y_arg: f64 = lua.luaL_checknumber(lua_state, 5);
    const look_at_z_arg: f64 = lua.luaL_checknumber(lua_state, 6);
    basic_3d.SetPerspective(camera_x_arg, camera_y_arg, camera_z_arg, look_at_x_arg, look_at_y_arg, look_at_z_arg);
    return 0;
}

fn lua_error_handler(lua_state: *lua.lua_State) i32 {
    const error_message: []const u8 = lua.lua_tostring(lua_state, 1);

    if (error_message == null) {
        if (lua.luaL_callmeta(lua_state, 1, "__tostring") and lua.lua_type(lua_state, -1) == lua.LUA_TSTRING) {
            // TODO: Is this part right?
            //       lua.c did something slightly different here, and I think didn't append a traceback?
            error_message = lua.lua_tostring(lua_state, -1);
            lua.lua_pop(lua_state, 1);
        } else {
            error_message = lua.lua_pushfstring(lua_state, "(error object is a %s value)", lua.luaL_typename(lua_state, 1));
        }
    }

    lua.luaL_traceback(lua_state, lua_state, error_message, 1);
    // const full_error_message: []const u8 = lua.lua_tostring(lua_state, -1);

    return 1;
}

fn RegisterLuaScriptFunctions(lua_state: *lua.lua_State) void {
    // TODO: Add all engine functions to a (read-only) global table instead of directly exposing in the global context.
    //       List of remaining exposed functions will be lower-level at that point, so will be important to distinguish.

    lua.lua_pushcfunction(lua_state, unload_all_resources);
    lua.lua_setglobal(lua_state, "unload_all_resources");
    lua.lua_pushcfunction(lua_state, begin_loading_3d_data);
    lua.lua_setglobal(lua_state, "begin_loading_3d_data");
    lua.lua_pushcfunction(lua_state, end_and_commit_loading_3d_data);
    lua.lua_setglobal(lua_state, "end_and_commit_loading_3d_data");

    lua.lua_pushcfunction(lua_state, play_music_track_1);
    lua.lua_setglobal(lua_state, "play_music_track_1");
    lua.lua_pushcfunction(lua_state, stop_music_track_1);
    lua.lua_setglobal(lua_state, "stop_music_track_1");
    lua.lua_pushcfunction(lua_state, play_music_track_2);
    lua.lua_setglobal(lua_state, "play_music_track_2");
    lua.lua_pushcfunction(lua_state, load_sound);
    lua.lua_setglobal(lua_state, "load_sound");
    lua.lua_pushcfunction(lua_state, load_texture);
    lua.lua_setglobal(lua_state, "load_texture");
    lua.lua_pushcfunction(lua_state, load_mesh);
    lua.lua_setglobal(lua_state, "load_mesh");

    lua.lua_pushcfunction(lua_state, set_mesh_to_mesh);
    lua.lua_setglobal(lua_state, "set_mesh_to_mesh");
    lua.lua_pushcfunction(lua_state, scroll_texture_on_mesh);
    lua.lua_setglobal(lua_state, "scroll_texture_on_mesh");
    lua.lua_pushcfunction(lua_state, skip_next_mesh_interpolation);
    lua.lua_setglobal(lua_state, "skip_next_mesh_interpolation");
    lua.lua_pushcfunction(lua_state, skip_next_camera_interpolation);
    lua.lua_setglobal(lua_state, "skip_next_camera_interpolation");
    lua.lua_pushcfunction(lua_state, set_mesh_texture);
    lua.lua_setglobal(lua_state, "set_mesh_texture");
    lua.lua_pushcfunction(lua_state, set_mesh_is_visible);
    lua.lua_setglobal(lua_state, "set_mesh_is_visible");

    lua.lua_pushcfunction(lua_state, transform_create);
    lua.lua_setglobal(lua_state, "transform_create");
    lua.lua_pushcfunction(lua_state, transform_delete);
    lua.lua_setglobal(lua_state, "transform_delete");
    lua.lua_pushcfunction(lua_state, transform_get_parent);
    lua.lua_setglobal(lua_state, "transform_get_parent");
    lua.lua_pushcfunction(lua_state, transform_set_parent);
    lua.lua_setglobal(lua_state, "transform_set_parent");
    lua.lua_pushcfunction(lua_state, transform_clear_parent);
    lua.lua_setglobal(lua_state, "transform_clear_parent");
    lua.lua_pushcfunction(lua_state, transform_set_parent_is_camera);
    lua.lua_setglobal(lua_state, "transform_set_parent_is_camera");
    lua.lua_pushcfunction(lua_state, mesh_get_transform);
    lua.lua_setglobal(lua_state, "mesh_get_transform");
    lua.lua_pushcfunction(lua_state, mesh_set_transform);
    lua.lua_setglobal(lua_state, "mesh_set_transform");
    lua.lua_pushcfunction(lua_state, mesh_clear_transform);
    lua.lua_setglobal(lua_state, "mesh_clear_transform");
    lua.lua_pushcfunction(lua_state, transform_set_to_identity);
    lua.lua_setglobal(lua_state, "transform_set_to_identity");
    lua.lua_pushcfunction(lua_state, transform_set_translation);
    lua.lua_setglobal(lua_state, "transform_set_translation");
    lua.lua_pushcfunction(lua_state, transform_clear_translation);
    lua.lua_setglobal(lua_state, "transform_clear_translation");
    lua.lua_pushcfunction(lua_state, transform_set_rotation_x);
    lua.lua_setglobal(lua_state, "transform_set_rotation_x");
    lua.lua_pushcfunction(lua_state, transform_set_rotation_y);
    lua.lua_setglobal(lua_state, "transform_set_rotation_y");
    lua.lua_pushcfunction(lua_state, transform_set_rotation_z);
    lua.lua_setglobal(lua_state, "transform_set_rotation_z");
    lua.lua_pushcfunction(lua_state, transform_concat_rotation_x);
    lua.lua_setglobal(lua_state, "transform_concat_rotation_x");
    lua.lua_pushcfunction(lua_state, transform_concat_rotation_y);
    lua.lua_setglobal(lua_state, "transform_concat_rotation_y");
    lua.lua_pushcfunction(lua_state, transform_concat_rotation_z);
    lua.lua_setglobal(lua_state, "transform_concat_rotation_z");
    lua.lua_pushcfunction(lua_state, transform_clear_rotation);
    lua.lua_setglobal(lua_state, "transform_clear_rotation");
    lua.lua_pushcfunction(lua_state, transform_set_scale);
    lua.lua_setglobal(lua_state, "transform_set_scale");
    lua.lua_pushcfunction(lua_state, transform_clear_scale);
    lua.lua_setglobal(lua_state, "transform_clear_scale");

    lua.lua_pushcfunction(lua_state, get_loaded_texture_count);
    lua.lua_setglobal(lua_state, "get_loaded_texture_count");
    lua.lua_pushcfunction(lua_state, get_is_sound_enabled);
    lua.lua_setglobal(lua_state, "get_is_sound_enabled");
    lua.lua_pushcfunction(lua_state, get_is_music_enabled);
    lua.lua_setglobal(lua_state, "get_is_music_enabled");
    lua.lua_pushcfunction(lua_state, get_last_key_pressed);
    lua.lua_setglobal(lua_state, "get_last_key_pressed");
    lua.lua_pushcfunction(lua_state, get_current_fps);
    lua.lua_setglobal(lua_state, "get_current_fps");

    lua.lua_pushcfunction(lua_state, create_mesh);
    lua.lua_setglobal(lua_state, "create_mesh");
    lua.lua_pushcfunction(lua_state, new_mesh);
    lua.lua_setglobal(lua_state, "new_mesh");
    lua.lua_pushcfunction(lua_state, move_transparent_mesh_to_front);
    lua.lua_setglobal(lua_state, "move_transparent_mesh_to_front");
    lua.lua_pushcfunction(lua_state, move_transparent_mesh_to_back);
    lua.lua_setglobal(lua_state, "move_transparent_mesh_to_back");
    lua.lua_pushcfunction(lua_state, set_fog);
    lua.lua_setglobal(lua_state, "set_fog");
    lua.lua_pushcfunction(lua_state, get_config_option_string);
    lua.lua_setglobal(lua_state, "get_config_option_string");
    lua.lua_pushcfunction(lua_state, set_config_option);
    lua.lua_setglobal(lua_state, "set_config_option");
    lua.lua_pushcfunction(lua_state, save_config_options);
    lua.lua_setglobal(lua_state, "save_config_options");
    lua.lua_pushcfunction(lua_state, play_sound_effect);
    lua.lua_setglobal(lua_state, "play_sound_effect");

    lua.lua_pushcfunction(lua_state, delete_mesh);
    lua.lua_setglobal(lua_state, "delete_mesh");
    lua.lua_pushcfunction(lua_state, set_perspective);
    lua.lua_setglobal(lua_state, "set_perspective");
}

fn LoadLuaScript(filename: []const u8, new_script_context: *LuaModuleScriptContext) void {
    std.debug.assert(new_script_context != null); // TODO: Error handling

    if (new_script_context.lua_state != null) {
        lua.lua_close(new_script_context.lua_state);
    }

    const full_filename: [300]u8 = undefined; // TODO: Standardize path lengths? Bigger paths?
    std.fmt.bufPrint(full_filename, "{s}/{s}", .{ g_game_base_path, filename });

    const new_state: *lua.lua_State = lua.luaL_newstate();
    std.debug.assert(new_state != null); // TODO: Error handling

    lua.luaL_openlibs(new_state);

    const load_file_result: i32 = lua.luaL_loadfile(new_state, full_filename);
    if (load_file_result != 0) {
        const error_message: []const u8 = lua.lua_tostring(new_state, -1);
        std.log.err("Error while loading script: {s}\n{s}", .{ full_filename, error_message });
        std.debug.assert(false); // TODO: Error handling
    }

    RegisterLuaScriptFunctions(new_state);

    const arg_count: i32 = 0;
    const error_handler_stack_pos: i32 = lua.lua_gettop(new_state) - arg_count;

    lua.lua_pushcfunction(new_state, lua_error_handler);
    lua.lua_insert(new_state, error_handler_stack_pos);

    if (lua.lua_pcall(new_state, 0, 1, error_handler_stack_pos) != 0) {
        const error_message: []const u8 = lua.lua_tostring(new_state, -1);
        std.log.err("Error while initially running script module: {s}\n{s}", .{ full_filename, error_message });
        std.debug.assert(false); // TODO: Error handling
    }

    std.debug.assert(lua.lua_istable(new_state, -1)); // "Expected loaded script file to return a module table"

    lua.lua_remove(new_state, error_handler_stack_pos);

    new_script_context.module_table_registry_index = lua.luaL_ref(new_state, lua.LUA_REGISTRYINDEX);
    new_script_context.lua_state = new_state;
}

fn PushGameActionAsTable(lua_state: *lua.lua_State, game_action: *const jumpman_main_c.GameAction) void {
    lua.lua_newtable(lua_state);
    lua.lua_pushboolean(lua_state, game_action.is_pressed);
    lua.lua_setfield(lua_state, -2, "is_pressed");
    lua.lua_pushboolean(lua_state, game_action.just_pressed);
    lua.lua_setfield(lua_state, -2, "just_pressed");
}

fn PushGameInputAsTable(lua_state: *lua.lua_State, game_input: *const jumpman_main_c.GameInput) void {
    lua.lua_newtable(lua_state);
    PushGameActionAsTable(lua_state, &game_input.move_left_action);
    lua.lua_setfield(lua_state, -2, "move_left_action");
    PushGameActionAsTable(lua_state, &game_input.move_right_action);
    lua.lua_setfield(lua_state, -2, "move_right_action");
    PushGameActionAsTable(lua_state, &game_input.move_down_action);
    lua.lua_setfield(lua_state, -2, "move_down_action");
    PushGameActionAsTable(lua_state, &game_input.move_up_action);
    lua.lua_setfield(lua_state, -2, "move_up_action");
    PushGameActionAsTable(lua_state, &game_input.jump_action);
    lua.lua_setfield(lua_state, -2, "jump_action");
    PushGameActionAsTable(lua_state, &game_input.attack_action);
    lua.lua_setfield(lua_state, -2, "attack_action");
    PushGameActionAsTable(lua_state, &game_input.select_action);
    lua.lua_setfield(lua_state, -2, "select_action");
    PushGameActionAsTable(lua_state, &game_input.debug_action);
    lua.lua_setfield(lua_state, -2, "debug_action");
    PushGameActionAsTable(lua_state, &game_input.cheat_action);
    lua.lua_setfield(lua_state, -2, "cheat_action");
    PushGameActionAsTable(lua_state, &game_input.cursor_select_action);
    lua.lua_setfield(lua_state, -2, "cursor_select_action");

    lua.lua_newtable(lua_state);
    lua.lua_pushnumber(lua_state, game_input.cursor_position.x);
    lua.lua_setfield(lua_state, -2, "x");
    lua.lua_pushnumber(lua_state, game_input.cursor_position.y);
    lua.lua_setfield(lua_state, -2, "y");
    lua.lua_setfield(lua_state, -2, "cursor_position");

    lua.lua_pushboolean(lua_state, game_input.cursor_is_on_screen);
    lua.lua_setfield(lua_state, -2, "cursor_is_on_screen");
}

fn CallLuaModuleFunction(script_context: *LuaModuleScriptContext, function_name: []const u8, game_input: *const jumpman_main_c.GameInput, pushed_arg_count: i32, expected_result_count: i32, optional: bool) bool {
    var result: bool = false;

    std.debug.assert(script_context != null); // TODO: Error handling

    const lua_state: *lua.lua_State = script_context.lua_state;
    const module_function_stack_pos: i32 = lua.lua_gettop(lua_state) - pushed_arg_count + 1; // 1-based indexing

    lua.lua_rawgeti(lua_state, lua.LUA_REGISTRYINDEX, script_context.module_table_registry_index);
    std.debug.assert(lua.lua_type(lua_state, -1) == lua.LUA_TTABLE); // "Unable to retrieve module table from registry"
    lua.lua_getfield(lua_state, -1, function_name);

    if (lua.lua_isfunction(lua_state, -1) != 0) {
        const arg_count: i32 = pushed_arg_count;

        // Move the module function just under the previously pushed args
        lua.lua_insert(lua_state, module_function_stack_pos);
        lua.lua_pop(lua_state, 1); // Remove module table from stack

        // Push input arg, if passed in
        if (game_input != null) {
            PushGameInputAsTable(lua_state, game_input);
            arg_count += 1;
        }

        // Place error handler just under module function
        const error_handler_stack_pos: i32 = module_function_stack_pos;
        lua.lua_pushcfunction(lua_state, lua_error_handler);
        lua.lua_insert(lua_state, error_handler_stack_pos);

        if (lua.lua_pcall(lua_state, arg_count, expected_result_count, error_handler_stack_pos) != 0) {
            const error_message: []const u8 = lua.lua_tostring(lua_state, -1);
            std.log.err("Error while calling Lua function in main script: {s}\n{s}", .{ function_name, error_message });
            std.debug.assert(false); // TODO: Error handling
        } else {
            result = true;
        }

        lua.lua_remove(lua_state, error_handler_stack_pos);
    } else {
        std.debug.assert(optional); // TODO: Error handling

        lua.lua_pop(lua_state, 1); // Remove nil function from stack
        lua.lua_pop(lua_state, 1); // Remove module table from stack
        lua.lua_pop(lua_state, pushed_arg_count); // Remove pushed args from stack
    }

    return result;
}

// ------------------- API FOR PLATFORM LAYER -------------------------------

export fn Init3D() bool {
    if (!basic_3d.InitializeAll()) {
        return 0;
    }

    return 1;
}

export fn InitGameDebugScript(base_path: []const u8, script_name: []const u8) void {
    g_game_base_path = base_path;
    const relative_script_filename: [300]u8 = undefined; // TODO: Standardize path lengths? Bigger paths?
    std.fmt.bufPrint(relative_script_filename, "data/{s}", .{script_name});
    LoadLuaScript(relative_script_filename, &g_main_script_context);
    CallLuaModuleFunction(&g_main_script_context, "initialize", null, 0, 0, false);
}

export fn InitGameDebugLevel(base_path: []const u8, level_name: []const u8) void {
    g_game_base_path = base_path;
    LoadLuaScript("data/main.lua", &g_main_script_context);
    lua.lua_pushstring(g_main_script_context.lua_state, level_name);
    CallLuaModuleFunction(&g_main_script_context, "initialize", null, 1, 0, false);
}

export fn InitGameNormal(base_path: []const u8) void {
    g_game_base_path = base_path;
    LoadLuaScript("data/main.lua", &g_main_script_context);
    CallLuaModuleFunction(&g_main_script_context, "initialize", null, 0, 0, false);
}

export fn UpdateGame(game_input: *const basic_3d.GameInput, seconds_per_update_timestep: f64) void {
    if (!jumpman_main_c.IsGameFrozen()) {
        basic_3d.RendererPreUpdate(seconds_per_update_timestep);
        CallLuaModuleFunction(&g_main_script_context, "update", game_input, 0, 0, false);
        basic_3d.RendererPostUpdate();
    }
}

export fn DrawGame(seconds_per_update_timestep: f64, seconds_since_previous_update: f64, time_scale: f64) void {
    // TODO: Just push interpolation_scale?
    lua.lua_pushnumber(g_main_script_context.lua_state, seconds_per_update_timestep);
    lua.lua_pushnumber(g_main_script_context.lua_state, seconds_since_previous_update);
    lua.lua_pushnumber(g_main_script_context.lua_state, time_scale);

    const pre_draw_function_existed: bool = CallLuaModuleFunction(&g_main_script_context, "pre_draw", null, 3, 1, true);

    var do_interpolation: bool = true;
    if (pre_draw_function_existed) {
        do_interpolation = !lua_checkbool(g_main_script_context.lua_state, -1);
        lua.lua_pop(g_main_script_context.lua_state, 1);
    }

    const interpolation_scale: f32 = time_scale * seconds_since_previous_update / seconds_per_update_timestep;
    basic_3d.RendererDraw(do_interpolation, interpolation_scale);
}

export fn ExitGame() void {
    CallLuaModuleFunction(&g_main_script_context, "on_exit_requested", null, 0, 0, false);
}
