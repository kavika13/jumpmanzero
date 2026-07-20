const std = @import("std");
const basic_3d = @import("basic_3d.zig");
const main = @import("main.zig");
const music = @import("music.zig");
const sound = @import("sound.zig");
const lua_c = @import("lua_c");

const LuaModuleScriptContext = struct {
    lua_state: ?*lua_c.lua_State,
    module_table_registry_index: i32,
};

var g_loaded_texture_count: usize = undefined;
var g_loaded_sound_count: i32 = undefined;

const kMAX_SCRIPT_MESHES: usize = 600;

var g_main_script_context: LuaModuleScriptContext = .{ .lua_state = null, .module_table_registry_index = -1 };

var g_io: std.Io = .failing;
var g_gpa: std.mem.Allocator = .failing;

// ------------------- LUA SCRIPT API -------------------------------

fn lua_checkbool(L: *lua_c.lua_State, arg: i32) bool {
    lua_c.luaL_checktype(L, arg, lua_c.LUA_TBOOLEAN);
    const d = lua_c.lua_toboolean(L, arg);
    return d != 0;
}

fn unload_all_resources(_: ?*lua_c.lua_State) callconv(.c) c_int {
    basic_3d.clear3dData();

    g_loaded_texture_count = 0;
    g_loaded_sound_count = 0;

    return 0;
}

fn begin_loading_3d_data(_: ?*lua_c.lua_State) callconv(.c) c_int {
    basic_3d.begin3dLoad(g_gpa);
    return 0;
}

fn end_and_commit_loading_3d_data(_: ?*lua_c.lua_State) callconv(.c) c_int {
    basic_3d.endAndCommit3dLoad(g_gpa);
    return 0;
}

fn play_music_track_1(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    // TODO: Error checking for filename?
    const new_music_track_arg = lua_c.lua_tolstring(lua_state, 1, null);
    const song_start_music_time_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 2);
    const loop_start_music_time_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 3);

    if (song_start_music_time_arg < 0) {
        _ = lua_c.luaL_argerror(lua_state, 2, "song_start_music_time must be 0 or greater"); // TODO: Don't ignore return type?
    }

    music.newTrack1(std.mem.span(new_music_track_arg), @intCast(song_start_music_time_arg), @intCast(loop_start_music_time_arg));

    return 0;
}

fn stop_music_track_1(_: ?*lua_c.lua_State) callconv(.c) c_int {
    music.stopMusic1(); // TODO: Error checking?
    return 0;
}

fn play_music_track_2(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    // TODO: Error checking for filename?
    const new_music_track_arg = lua_c.lua_tolstring(lua_state, 1, null);
    music.newTrack2(std.mem.span(new_music_track_arg));
    return 0;
}

fn load_sound(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    // TODO: Error checking for filename?
    const filename_arg = lua_c.lua_tolstring(lua_state, 1, null);
    var full_filename_buf = std.mem.zeroes([std.fs.max_path_bytes:0]u8);
    _ = std.Io.Dir.cwd().realPathFile(g_io, std.mem.span(filename_arg), &full_filename_buf) catch @panic("Failed to print to buffer"); // TODO: Error handling?

    _ = sound.loadSound(&full_filename_buf, @intCast(g_loaded_sound_count)); // TODO: Handle return value/error
    lua_c.lua_pushinteger(lua_state, g_loaded_sound_count);
    g_loaded_sound_count += 1;

    return 1;
}

fn load_texture(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    // TODO: Error checking for filename?
    const filename_arg = lua_c.lua_tolstring(lua_state.?, 1, null);
    const image_type_arg = lua_c.luaL_checkinteger(lua_state.?, 2);
    const is_alpha_blend_enabled_arg: bool = lua_checkbool(lua_state.?, 3);
    var full_filename_buf = std.mem.zeroes([std.fs.max_path_bytes:0]u8);
    _ = std.Io.Dir.cwd().realPathFile(g_io, std.mem.span(filename_arg), &full_filename_buf) catch @panic("Failed to print to buffer"); // TODO: Error handling?

    basic_3d.loadTexture(g_loaded_texture_count, &full_filename_buf, @truncate(image_type_arg), is_alpha_blend_enabled_arg);
    lua_c.lua_pushinteger(lua_state, @intCast(g_loaded_texture_count));
    g_loaded_texture_count += 1;

    return 1;
}

fn stringToLong(text: []const u8) i32 {
    const fTemp: f32 = @as(f32, @floatFromInt(text[1])) * 256.0 + @as(f32, @floatFromInt(text[2])) + @as(f32, @floatFromInt(text[3])) / 256.0;

    if (text[0] != 0) {
        return @intFromFloat(fTemp * -1.0);
    } else {
        return @intFromFloat(fTemp);
    }
}

fn LoadMesh(sFileName: [:0]const u8) i32 {
    const cData: []u8 = std.Io.Dir.cwd().readFileAlloc(g_io, sFileName, g_gpa, .unlimited) catch |err| err: {
        switch (err) {
            error.FileNotFound => break :err "",
            else => return -1, // TODO: Panic?
        }
    };
    defer g_gpa.free(cData);

    const vertex_component_count = cData.len / 4;

    const vertex_components: []i32 = g_gpa.alloc(i32, vertex_component_count) catch @panic("failed to allocate"); // TODO: Better error handling
    defer g_gpa.free(vertex_components);

    for (0..vertex_component_count) |component_index| {
        const index = component_index << 2;
        vertex_components[component_index] = stringToLong(cData[index .. index + 4]);
    }

    const result_mesh_handle_index: i32 = basic_3d.meshCreateFromVertexComponents(vertex_components, vertex_components.len / 9);

    return result_mesh_handle_index;
}

fn load_mesh(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    // TODO: Error checking for filename?
    const filename_arg = lua_c.lua_tolstring(lua_state, 1, null);
    const loaded_mesh_handle_index: i32 = LoadMesh(std.mem.span(filename_arg));
    lua_c.lua_pushinteger(lua_state, loaded_mesh_handle_index);
    return 1;
}

fn set_mesh_to_mesh(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const target_mesh_handle_index_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const source_mesh_handle_index_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 2);
    basic_3d.meshReplaceWithCopy(@truncate(target_mesh_handle_index_arg), @truncate(source_mesh_handle_index_arg));
    return 0;
}

fn transform_create(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const new_transform_index: i32 = basic_3d.transformCreate();
    lua_c.lua_pushinteger(lua_state, new_transform_index);
    return 1;
}

fn transform_delete(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    basic_3d.transformDelete(@truncate(arg_transform_index));
    return 0;
}

fn transform_get_parent(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const parent_transform_index: i32 = basic_3d.transformGetParent(@truncate(arg_transform_index));
    lua_c.lua_pushinteger(lua_state, parent_transform_index);
    return 1;
}

fn transform_set_parent(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const arg_new_parent_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 2);
    basic_3d.transformSetParent(@truncate(arg_transform_index), @truncate(arg_new_parent_index));
    return 0;
}

fn transform_clear_parent(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    basic_3d.transformClearParent(@truncate(arg_transform_index));
    return 0;
}

fn transform_get_parent_is_camera(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const is_parent_camera: bool = basic_3d.transformGetParentIsCamera(@truncate(arg_transform_index));
    lua_c.lua_pushboolean(lua_state, is_parent_camera);
    return 1;
}

fn transform_set_parent_is_camera(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const arg_is_parent_camera: bool = lua_checkbool(lua_state.?, 2);
    basic_3d.transformSetParentIsCamera(@truncate(arg_transform_index), arg_is_parent_camera);
    return 0;
}

fn mesh_get_transform(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_mesh_handle_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const transform_index: i32 = basic_3d.meshGetTransform(@truncate(arg_mesh_handle_index));
    lua_c.lua_pushinteger(lua_state, transform_index);
    return 1;
}

fn mesh_set_transform(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_mesh_handle_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 2);
    basic_3d.meshSetTransform(@truncate(arg_mesh_handle_index), @truncate(arg_transform_index));
    return 0;
}

fn mesh_clear_transform(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_mesh_handle_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    basic_3d.meshClearTransform(@truncate(arg_mesh_handle_index));
    return 0;
}

fn transform_set_to_identity(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    basic_3d.transformSetToIdentity(@truncate(arg_transform_index));
    return 0;
}

fn transform_set_translation(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const arg_x: f64 = lua_c.luaL_checknumber(lua_state, 2);
    const arg_y: f64 = lua_c.luaL_checknumber(lua_state, 3);
    const arg_z: f64 = lua_c.luaL_checknumber(lua_state, 4);
    basic_3d.transformSetTranslation(@truncate(arg_transform_index), @floatCast(arg_x), @floatCast(arg_y), @floatCast(arg_z));
    return 0;
}

fn transform_clear_translation(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    basic_3d.transformClearTranslation(@truncate(arg_transform_index));
    return 0;
}

fn transform_set_rotation_x(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const arg_angle_in_degrees: f64 = lua_c.luaL_checknumber(lua_state, 2);
    basic_3d.transformSetRotationX(@truncate(arg_transform_index), @floatCast(arg_angle_in_degrees));
    return 0;
}

fn transform_set_rotation_y(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const arg_angle_in_degrees: f64 = lua_c.luaL_checknumber(lua_state, 2);
    basic_3d.transformSetRotationY(@truncate(arg_transform_index), @floatCast(arg_angle_in_degrees));
    return 0;
}

fn transform_set_rotation_z(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const arg_angle_in_degrees: f64 = lua_c.luaL_checknumber(lua_state, 2);
    basic_3d.transformSetRotationZ(@truncate(arg_transform_index), @floatCast(arg_angle_in_degrees));
    return 0;
}

fn transform_concat_rotation_x(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const arg_angle_in_degrees: f64 = lua_c.luaL_checknumber(lua_state, 2);
    basic_3d.transformConcatRotationX(@truncate(arg_transform_index), @floatCast(arg_angle_in_degrees));
    return 0;
}

fn transform_concat_rotation_y(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const arg_angle_in_degrees: f64 = lua_c.luaL_checknumber(lua_state, 2);
    basic_3d.transformConcatRotationY(@truncate(arg_transform_index), @floatCast(arg_angle_in_degrees));
    return 0;
}

fn transform_concat_rotation_z(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const arg_angle_in_degrees: f64 = lua_c.luaL_checknumber(lua_state, 2);
    basic_3d.transformConcatRotationZ(@truncate(arg_transform_index), @floatCast(arg_angle_in_degrees));
    return 0;
}

fn transform_clear_rotation(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    basic_3d.transformClearRotation(@truncate(arg_transform_index));
    return 0;
}

fn transform_set_scale(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const arg_x: f64 = lua_c.luaL_checknumber(lua_state, 2);
    const arg_y: f64 = lua_c.luaL_checknumber(lua_state, 3);
    const arg_z: f64 = lua_c.luaL_checknumber(lua_state, 4);
    basic_3d.transformSetScale(@truncate(arg_transform_index), @floatCast(arg_x), @floatCast(arg_y), @floatCast(arg_z));
    return 0;
}

fn transform_clear_scale(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg_transform_index: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    basic_3d.transformClearScale(@truncate(arg_transform_index));
    return 0;
}

fn scroll_texture_on_mesh(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const mesh_handle_index_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const translate_x_arg: f64 = lua_c.luaL_checknumber(lua_state, 2);
    const argtranslate_y_arg: f64 = lua_c.luaL_checknumber(lua_state, 3);
    basic_3d.meshScrollTexture(@truncate(mesh_handle_index_arg), @floatCast(translate_x_arg), @floatCast(argtranslate_y_arg));
    return 0;
}

fn skip_next_mesh_interpolation(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const mesh_handle_index_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    basic_3d.meshSetIsAnimationContinuous(@truncate(mesh_handle_index_arg), false);
    return 0;
}

fn skip_next_camera_interpolation(_: ?*lua_c.lua_State) callconv(.c) c_int {
    basic_3d.setCameraIsAnimationContinuous(false);
    return 0;
}

fn get_loaded_texture_count(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    lua_c.lua_pushnumber(lua_state, @floatFromInt(g_loaded_texture_count));
    return 1;
}

fn get_is_sound_enabled(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    lua_c.lua_pushboolean(lua_state, @intFromBool(sound.getIsSoundEnabled()));
    return 1;
}

fn get_is_music_enabled(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    lua_c.lua_pushboolean(lua_state, @intFromBool(music.getIsMusicEnabled()));
    return 1;
}

fn get_last_key_pressed(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    lua_c.lua_pushnumber(lua_state, @floatFromInt(main.getLastKeyPressed()));
    return 1;
}

fn get_current_fps(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    lua_c.lua_pushnumber(lua_state, @floatFromInt(main.getCurrentFps()));
    return 1;
}

fn create_mesh(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    // Handle data in the format:
    // {
    //     { pos = { 137, 140, 15 }, normal = { 0, 0, -1 }, uv = { 0, 0 } },
    //     { pos = { 139, 140, 15 }, normal = { 0, 0, -1 }, uv = { 1, 0 } },
    //     ... more vertices here
    // }
    lua_c.luaL_checktype(lua_state, 1, lua_c.LUA_TTABLE);

    const texture_index_arg = lua_c.luaL_checkinteger(lua_state, 2);
    var is_visible_arg: bool = true;

    if (lua_c.lua_isboolean(lua_state, 3)) {
        is_visible_arg = lua_c.lua_toboolean(lua_state, 3) != 0;
    }

    const vertex_count: usize = lua_c.lua_rawlen(lua_state, 1);
    const triangle_count: usize = vertex_count / 3;
    std.debug.assert(triangle_count * 3 == vertex_count); // "Vertex data passed in isn't divisible by 3 (triangles)"

    var new_mesh_vertices = g_gpa.alloc(basic_3d.MeshVertex, vertex_count) catch @panic("failed to allocate"); // TODO: Better error handling
    defer g_gpa.free(new_mesh_vertices);

    for (0..vertex_count) |vertex_index| {
        _ = lua_c.lua_rawgeti(lua_state, 1, @intCast(vertex_index + 1)); // Current vertex table. Lua indices are 1-based - TODO: Don't ignore result
        lua_c.luaL_checktype(lua_state, -1, lua_c.LUA_TTABLE);

        _ = lua_c.lua_getfield(lua_state, -1, "pos"); // TODO: Don't ignore result
        const pos_size: usize = lua_c.lua_rawlen(lua_state, -1);
        std.debug.assert(pos_size == 3); // "Expected pos field to have 3 entries, one each for x, y, and z";

        _ = lua_c.lua_rawgeti(lua_state, -1, 1); // Lua indices are 1-based - TODO: Don't ignore result
        new_mesh_vertices[vertex_index].x = @floatCast(lua_c.luaL_checknumber(lua_state, -1));
        lua_c.lua_pop(lua_state, 1);

        _ = lua_c.lua_rawgeti(lua_state, -1, 2); // TODO: Don't ignore result
        new_mesh_vertices[vertex_index].y = @floatCast(lua_c.luaL_checknumber(lua_state, -1));
        lua_c.lua_pop(lua_state, 1);

        _ = lua_c.lua_rawgeti(lua_state, -1, 3); // TODO: Don't ignore result
        new_mesh_vertices[vertex_index].z = @floatCast(lua_c.luaL_checknumber(lua_state, -1));
        lua_c.lua_pop(lua_state, 1);

        lua_c.lua_pop(lua_state, 1); // pos table

        _ = lua_c.lua_getfield(lua_state, -1, "normal"); // TODO: Don't ignore result
        const normal_size: usize = lua_c.lua_rawlen(lua_state, -1);
        std.debug.assert(normal_size == 3); // "Expected normal field to have 3 entries, one each for nx, ny, and nz"

        _ = lua_c.lua_rawgeti(lua_state, -1, 1); // Lua indices are 1-based - TODO: Don't ignore result
        new_mesh_vertices[vertex_index].nx = @floatCast(lua_c.luaL_checknumber(lua_state, -1));
        lua_c.lua_pop(lua_state, 1);

        _ = lua_c.lua_rawgeti(lua_state, -1, 2); // TODO: Don't ignore result
        new_mesh_vertices[vertex_index].ny = @floatCast(lua_c.luaL_checknumber(lua_state, -1));
        lua_c.lua_pop(lua_state, 1);

        _ = lua_c.lua_rawgeti(lua_state, -1, 3); // TODO: Don't ignore result
        new_mesh_vertices[vertex_index].nz = @floatCast(lua_c.luaL_checknumber(lua_state, -1));
        lua_c.lua_pop(lua_state, 1);

        lua_c.lua_pop(lua_state, 1); // normal table

        _ = lua_c.lua_getfield(lua_state, -1, "uv"); // TODO: Don't ignore result
        const uv_size: usize = lua_c.lua_rawlen(lua_state, -1);
        std.debug.assert(uv_size == 2); // "Expected uv field to have 2 entries, one each for tu, tv"

        _ = lua_c.lua_rawgeti(lua_state, -1, 1); // Lua indices are 1-based - TODO: Don't ignore result
        new_mesh_vertices[vertex_index].tu = @floatCast(lua_c.luaL_checknumber(lua_state, -1));
        lua_c.lua_pop(lua_state, 1);

        _ = lua_c.lua_rawgeti(lua_state, -1, 2); // TODO: Don't ignore result
        new_mesh_vertices[vertex_index].tv = @floatCast(lua_c.luaL_checknumber(lua_state, -1));
        lua_c.lua_pop(lua_state, 1);

        lua_c.lua_pop(lua_state, 1); // uv table

        lua_c.lua_pop(lua_state, 1); // Current vertex table
    }

    const new_mesh_handle_index: i32 = basic_3d.meshCreateFromVertices(new_mesh_vertices.ptr, vertex_count, @truncate(texture_index_arg), is_visible_arg);

    lua_c.lua_pushnumber(lua_state, @floatFromInt(new_mesh_handle_index));

    return 1;
}

fn new_mesh(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const script_mesh_index_arg: f64 = lua_c.luaL_checknumber(lua_state, 1); // TODO: luaL_checkinteger?
    const new_mesh_handle_index: i32 = basic_3d.meshCreateFromCopy(@intFromFloat(script_mesh_index_arg));
    lua_c.lua_pushnumber(lua_state, @floatFromInt(new_mesh_handle_index));
    return 1;
}

fn set_mesh_texture(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const mesh_handle_index_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const texture_index_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 2);
    basic_3d.meshSetTextureIndex(@truncate(mesh_handle_index_arg), @truncate(texture_index_arg));
    return 0;
}

fn set_mesh_is_visible(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const mesh_handle_index_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const is_visible_arg: bool = lua_checkbool(lua_state.?, 2);
    basic_3d.meshSetIsVisible(@truncate(mesh_handle_index_arg), is_visible_arg);
    return 0;
}

fn move_transparent_mesh_to_front(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const mesh_handle_index_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    basic_3d.meshMoveToFrontForTransparentDrawing(@truncate(mesh_handle_index_arg));
    return 0;
}

fn move_transparent_mesh_to_back(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const mesh_handle_index_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    basic_3d.meshMoveToBackForTransparentDrawing(@truncate(mesh_handle_index_arg));
    return 0;
}

fn set_fog(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const fog_start_arg: lua_c.lua_Number = lua_c.luaL_checknumber(lua_state, 1);
    const fog_end_arg: lua_c.lua_Number = lua_c.luaL_checknumber(lua_state, 2);
    const red_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 3);
    const green_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 4);
    const blue_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 5);
    basic_3d.setFog(@floatCast(fog_start_arg), @floatCast(fog_end_arg), @intCast(red_arg & 0xFF), @intCast(green_arg & 0xFF), @intCast(blue_arg & 0xFF));
    return 0;
}

fn get_config_option_string(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    var sNameBuf: [100:0]u8 = undefined;
    var sName: []u8 = undefined;
    const option_index_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);

    if (option_index_arg >= 0 and option_index_arg <= 5) {
        const iKey: i32 = main.getKeyBinding(@intCast(option_index_arg));
        const key_as_char = @as(*const [1]u8, &@as(u8, @intCast(iKey)));

        if (iKey >= 'A' and iKey <= 'Z') {
            sName = std.fmt.bufPrintZ(&sNameBuf, "{s}   ", .{key_as_char}) catch @panic("Failed to print to buffer"); // TODO: Error handling?
        } else if (iKey >= '0' and iKey <= '9') {
            sName = std.fmt.bufPrintZ(&sNameBuf, "{s}   ", .{key_as_char}) catch @panic("Failed to print to buffer"); // TODO: Error handling?
        } else if (iKey == 38) {
            sName = std.fmt.bufPrintZ(&sNameBuf, "UP  ", .{}) catch @panic("Failed to print to buffer"); // TODO: Error handling?
        } else if (iKey == 40) {
            sName = std.fmt.bufPrintZ(&sNameBuf, "DOWN", .{}) catch @panic("Failed to print to buffer"); // TODO: Error handling?
        } else if (iKey == 37) {
            sName = std.fmt.bufPrintZ(&sNameBuf, "LEFT", .{}) catch @panic("Failed to print to buffer"); // TODO: Error handling?
        } else if (iKey == 39) {
            sName = std.fmt.bufPrintZ(&sNameBuf, "RGHT", .{}) catch @panic("Failed to print to buffer"); // TODO: Error handling?
        } else if (iKey == 32) {
            sName = std.fmt.bufPrintZ(&sNameBuf, "SPC ", .{}) catch @panic("Failed to print to buffer"); // TODO: Error handling?
        } else if (iKey == 58) {
            sName = std.fmt.bufPrintZ(&sNameBuf, ":   ", .{}) catch @panic("Failed to print to buffer"); // TODO: Error handling?
        } else if (iKey == 46) {
            sName = std.fmt.bufPrintZ(&sNameBuf, ".   ", .{}) catch @panic("Failed to print to buffer"); // TODO: Error handling?
        } else if (iKey == 45) {
            sName = std.fmt.bufPrintZ(&sNameBuf, "-   ", .{}) catch @panic("Failed to print to buffer"); // TODO: Error handling?
        }
    } else if (option_index_arg == 32 or option_index_arg == 33) {
        var is_enabled: bool = undefined;

        if (option_index_arg == 32) {
            is_enabled = sound.getIsSoundEnabled();
        } else {
            is_enabled = music.getIsMusicEnabled();
        }

        if (is_enabled) {
            sName = std.fmt.bufPrintZ(&sNameBuf, "ON  ", .{}) catch @panic("Failed to print to buffer"); // TODO: Error handling?
        } else {
            sName = std.fmt.bufPrintZ(&sNameBuf, "OFF ", .{}) catch @panic("Failed to print to buffer"); // TODO: Error handling?
        }
    }

    _ = lua_c.lua_pushstring(lua_state, sName.ptr); // TODO: Don't ignore result

    return 1;
}

fn set_config_option(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const option_index_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 1);
    const key_arg: lua_c.lua_Integer = lua_c.luaL_checkinteger(lua_state, 2);

    var is_key_good: bool = false;

    if (option_index_arg >= 0 and option_index_arg <= 5) {
        const iKey: i32 = @truncate(key_arg);

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
            if (option_index_arg != iLoop and main.getKeyBinding(iLoop) == iKey) {
                is_key_good = false;
            }
        }

        if (is_key_good) {
            main.setKeyBinding(@intCast(option_index_arg), iKey);
        }
    }

    if (option_index_arg == 32) {
        sound.setIsSoundEnabled(key_arg != 0);
        is_key_good = true;
    }

    if (option_index_arg == 33) {
        music.setIsMusicEnabled(key_arg != 0);
        is_key_good = true;
    }

    lua_c.lua_pushboolean(lua_state, @intFromBool(is_key_good));

    return 1;
}

fn save_config_options(_: ?*lua_c.lua_State) callconv(.c) c_int { // TODO: Might be able to move to Lua?
    main.saveSettings();
    return 0;
}

fn play_sound_effect(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const arg1: f64 = lua_c.luaL_checknumber(lua_state, 1); // TODO: luaL_checkinteger?
    sound.playSoundEffect(@intFromFloat(arg1));
    return 0;
}

fn delete_mesh(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const mesh_handle_index_arg: f64 = lua_c.luaL_checknumber(lua_state, 1); // TODO: luaL_checkinteger?
    basic_3d.meshDelete(@intFromFloat(mesh_handle_index_arg));
    return 0;
}

fn set_perspective(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    const camera_x_arg: f64 = lua_c.luaL_checknumber(lua_state, 1);
    const camera_y_arg: f64 = lua_c.luaL_checknumber(lua_state, 2);
    const camera_z_arg: f64 = lua_c.luaL_checknumber(lua_state, 3);
    const look_at_x_arg: f64 = lua_c.luaL_checknumber(lua_state, 4);
    const look_at_y_arg: f64 = lua_c.luaL_checknumber(lua_state, 5);
    const look_at_z_arg: f64 = lua_c.luaL_checknumber(lua_state, 6);
    basic_3d.setPerspective(@floatCast(camera_x_arg), @floatCast(camera_y_arg), @floatCast(camera_z_arg), @floatCast(look_at_x_arg), @floatCast(look_at_y_arg), @floatCast(look_at_z_arg));
    return 0;
}

fn lua_error_handler(lua_state: ?*lua_c.lua_State) callconv(.c) c_int {
    var error_message = lua_c.lua_tolstring(lua_state, 1, null);

    if (error_message == null) {
        if (lua_c.luaL_callmeta(lua_state, 1, "__tostring") != 0 and lua_c.lua_type(lua_state, -1) == lua_c.LUA_TSTRING) {
            // TODO: Is this part right?
            //       lua_c.c did something slightly different here, and I think didn't append a traceback?
            error_message = lua_c.lua_tolstring(lua_state, -1, null);
            lua_c.lua_pop(lua_state, 1);
        } else {
            error_message = lua_c.lua_pushfstring(lua_state, "(error object is a %s value)", lua_c.luaL_typename(lua_state, 1));
        }
    }

    lua_c.luaL_traceback(lua_state, lua_state, error_message, 1);
    // const full_error_message = lua_c.lua_tolstring(lua_state, -1 , null);

    return 1;
}

fn RegisterLuaScriptFunctions(lua_state: *lua_c.lua_State) void {
    // TODO: Add all engine functions to a (read-only) global table instead of directly exposing in the global context.
    //       List of remaining exposed functions will be lower-level at that point, so will be important to distinguish.

    // TODO: Rename all these functions to more zig-friendly names (on the zig implementation side only)
    lua_c.lua_pushcclosure(lua_state, unload_all_resources, 0);
    lua_c.lua_setglobal(lua_state, "unload_all_resources");
    lua_c.lua_pushcclosure(lua_state, begin_loading_3d_data, 0);
    lua_c.lua_setglobal(lua_state, "begin_loading_3d_data");
    lua_c.lua_pushcclosure(lua_state, end_and_commit_loading_3d_data, 0);
    lua_c.lua_setglobal(lua_state, "end_and_commit_loading_3d_data");

    lua_c.lua_pushcclosure(lua_state, play_music_track_1, 0);
    lua_c.lua_setglobal(lua_state, "play_music_track_1");
    lua_c.lua_pushcclosure(lua_state, stop_music_track_1, 0);
    lua_c.lua_setglobal(lua_state, "stop_music_track_1");
    lua_c.lua_pushcclosure(lua_state, play_music_track_2, 0);
    lua_c.lua_setglobal(lua_state, "play_music_track_2");
    lua_c.lua_pushcclosure(lua_state, load_sound, 0);
    lua_c.lua_setglobal(lua_state, "load_sound");
    lua_c.lua_pushcclosure(lua_state, load_texture, 0);
    lua_c.lua_setglobal(lua_state, "load_texture");
    lua_c.lua_pushcclosure(lua_state, load_mesh, 0);
    lua_c.lua_setglobal(lua_state, "load_mesh");

    lua_c.lua_pushcclosure(lua_state, set_mesh_to_mesh, 0);
    lua_c.lua_setglobal(lua_state, "set_mesh_to_mesh");
    lua_c.lua_pushcclosure(lua_state, scroll_texture_on_mesh, 0);
    lua_c.lua_setglobal(lua_state, "scroll_texture_on_mesh");
    lua_c.lua_pushcclosure(lua_state, skip_next_mesh_interpolation, 0);
    lua_c.lua_setglobal(lua_state, "skip_next_mesh_interpolation");
    lua_c.lua_pushcclosure(lua_state, skip_next_camera_interpolation, 0);
    lua_c.lua_setglobal(lua_state, "skip_next_camera_interpolation");
    lua_c.lua_pushcclosure(lua_state, set_mesh_texture, 0);
    lua_c.lua_setglobal(lua_state, "set_mesh_texture");
    lua_c.lua_pushcclosure(lua_state, set_mesh_is_visible, 0);
    lua_c.lua_setglobal(lua_state, "set_mesh_is_visible");

    lua_c.lua_pushcclosure(lua_state, transform_create, 0);
    lua_c.lua_setglobal(lua_state, "transform_create");
    lua_c.lua_pushcclosure(lua_state, transform_delete, 0);
    lua_c.lua_setglobal(lua_state, "transform_delete");
    lua_c.lua_pushcclosure(lua_state, transform_get_parent, 0);
    lua_c.lua_setglobal(lua_state, "transform_get_parent");
    lua_c.lua_pushcclosure(lua_state, transform_set_parent, 0);
    lua_c.lua_setglobal(lua_state, "transform_set_parent");
    lua_c.lua_pushcclosure(lua_state, transform_clear_parent, 0);
    lua_c.lua_setglobal(lua_state, "transform_clear_parent");
    lua_c.lua_pushcclosure(lua_state, transform_set_parent_is_camera, 0);
    lua_c.lua_setglobal(lua_state, "transform_set_parent_is_camera");
    lua_c.lua_pushcclosure(lua_state, mesh_get_transform, 0);
    lua_c.lua_setglobal(lua_state, "mesh_get_transform");
    lua_c.lua_pushcclosure(lua_state, mesh_set_transform, 0);
    lua_c.lua_setglobal(lua_state, "mesh_set_transform");
    lua_c.lua_pushcclosure(lua_state, mesh_clear_transform, 0);
    lua_c.lua_setglobal(lua_state, "mesh_clear_transform");
    lua_c.lua_pushcclosure(lua_state, transform_set_to_identity, 0);
    lua_c.lua_setglobal(lua_state, "transform_set_to_identity");
    lua_c.lua_pushcclosure(lua_state, transform_set_translation, 0);
    lua_c.lua_setglobal(lua_state, "transform_set_translation");
    lua_c.lua_pushcclosure(lua_state, transform_clear_translation, 0);
    lua_c.lua_setglobal(lua_state, "transform_clear_translation");
    lua_c.lua_pushcclosure(lua_state, transform_set_rotation_x, 0);
    lua_c.lua_setglobal(lua_state, "transform_set_rotation_x");
    lua_c.lua_pushcclosure(lua_state, transform_set_rotation_y, 0);
    lua_c.lua_setglobal(lua_state, "transform_set_rotation_y");
    lua_c.lua_pushcclosure(lua_state, transform_set_rotation_z, 0);
    lua_c.lua_setglobal(lua_state, "transform_set_rotation_z");
    lua_c.lua_pushcclosure(lua_state, transform_concat_rotation_x, 0);
    lua_c.lua_setglobal(lua_state, "transform_concat_rotation_x");
    lua_c.lua_pushcclosure(lua_state, transform_concat_rotation_y, 0);
    lua_c.lua_setglobal(lua_state, "transform_concat_rotation_y");
    lua_c.lua_pushcclosure(lua_state, transform_concat_rotation_z, 0);
    lua_c.lua_setglobal(lua_state, "transform_concat_rotation_z");
    lua_c.lua_pushcclosure(lua_state, transform_clear_rotation, 0);
    lua_c.lua_setglobal(lua_state, "transform_clear_rotation");
    lua_c.lua_pushcclosure(lua_state, transform_set_scale, 0);
    lua_c.lua_setglobal(lua_state, "transform_set_scale");
    lua_c.lua_pushcclosure(lua_state, transform_clear_scale, 0);
    lua_c.lua_setglobal(lua_state, "transform_clear_scale");

    lua_c.lua_pushcclosure(lua_state, get_loaded_texture_count, 0);
    lua_c.lua_setglobal(lua_state, "get_loaded_texture_count");
    lua_c.lua_pushcclosure(lua_state, get_is_sound_enabled, 0);
    lua_c.lua_setglobal(lua_state, "get_is_sound_enabled");
    lua_c.lua_pushcclosure(lua_state, get_is_music_enabled, 0);
    lua_c.lua_setglobal(lua_state, "get_is_music_enabled");
    lua_c.lua_pushcclosure(lua_state, get_last_key_pressed, 0);
    lua_c.lua_setglobal(lua_state, "get_last_key_pressed");
    lua_c.lua_pushcclosure(lua_state, get_current_fps, 0);
    lua_c.lua_setglobal(lua_state, "get_current_fps");

    lua_c.lua_pushcclosure(lua_state, create_mesh, 0);
    lua_c.lua_setglobal(lua_state, "create_mesh");
    lua_c.lua_pushcclosure(lua_state, new_mesh, 0);
    lua_c.lua_setglobal(lua_state, "new_mesh");
    lua_c.lua_pushcclosure(lua_state, move_transparent_mesh_to_front, 0);
    lua_c.lua_setglobal(lua_state, "move_transparent_mesh_to_front");
    lua_c.lua_pushcclosure(lua_state, move_transparent_mesh_to_back, 0);
    lua_c.lua_setglobal(lua_state, "move_transparent_mesh_to_back");
    lua_c.lua_pushcclosure(lua_state, set_fog, 0);
    lua_c.lua_setglobal(lua_state, "set_fog");
    lua_c.lua_pushcclosure(lua_state, get_config_option_string, 0);
    lua_c.lua_setglobal(lua_state, "get_config_option_string");
    lua_c.lua_pushcclosure(lua_state, set_config_option, 0);
    lua_c.lua_setglobal(lua_state, "set_config_option");
    lua_c.lua_pushcclosure(lua_state, save_config_options, 0);
    lua_c.lua_setglobal(lua_state, "save_config_options");
    lua_c.lua_pushcclosure(lua_state, play_sound_effect, 0);
    lua_c.lua_setglobal(lua_state, "play_sound_effect");

    lua_c.lua_pushcclosure(lua_state, delete_mesh, 0);
    lua_c.lua_setglobal(lua_state, "delete_mesh");
    lua_c.lua_pushcclosure(lua_state, set_perspective, 0);
    lua_c.lua_setglobal(lua_state, "set_perspective");
}

fn LoadLuaScript(filename: [:0]const u8, new_script_context: *LuaModuleScriptContext) void {
    if (new_script_context.lua_state != null) {
        lua_c.lua_close(new_script_context.lua_state);
    }

    var full_filename_buf = std.mem.zeroes([std.fs.max_path_bytes:0]u8);
    _ = std.Io.Dir.cwd().realPathFile(g_io, filename, &full_filename_buf) catch @panic("Failed to print to buffer"); // TODO: Error handling?

    const new_state: ?*lua_c.lua_State = lua_c.luaL_newstate();
    std.debug.assert(new_state != null); // TODO: Error handling

    lua_c.luaL_openlibs(new_state);

    const load_file_result: i32 = lua_c.luaL_loadfilex(new_state, &full_filename_buf, null);
    if (load_file_result != 0) {
        const error_message = lua_c.lua_tolstring(new_state, -1, null);
        std.log.err("Error while loading script: {s}\n{s}", .{ full_filename_buf, error_message });
        std.debug.assert(false); // TODO: Error handling
    }

    RegisterLuaScriptFunctions(new_state.?);

    const arg_count: i32 = 0;
    const error_handler_stack_pos: i32 = lua_c.lua_gettop(new_state) - arg_count;

    lua_c.lua_pushcclosure(new_state, lua_error_handler, 0);
    lua_c.lua_insert(new_state, error_handler_stack_pos);

    if (lua_c.lua_pcallk(new_state, 0, 1, error_handler_stack_pos, 0, null) != 0) {
        const error_message = lua_c.lua_tolstring(new_state, -1, null);
        std.log.err("Error while initially running script module: {s}\n{s}", .{ full_filename_buf, error_message });
        std.debug.assert(false); // TODO: Error handling
    }

    std.debug.assert(lua_c.lua_istable(new_state, -1)); // "Expected loaded script file to return a module table"

    lua_c.lua_remove(new_state, error_handler_stack_pos);

    new_script_context.module_table_registry_index = lua_c.luaL_ref(new_state, lua_c.LUA_REGISTRYINDEX);
    new_script_context.lua_state = new_state;
}

fn PushGameActionAsTable(lua_state: *lua_c.lua_State, game_action: *const GameAction) void {
    lua_c.lua_newtable(lua_state);
    lua_c.lua_pushboolean(lua_state, @intFromBool(game_action.is_pressed));
    lua_c.lua_setfield(lua_state, -2, "is_pressed");
    lua_c.lua_pushboolean(lua_state, @intFromBool(game_action.just_pressed));
    lua_c.lua_setfield(lua_state, -2, "just_pressed");
}

fn PushGameInputAsTable(lua_state: *lua_c.lua_State, game_input: *const GameInput) void {
    lua_c.lua_newtable(lua_state);
    PushGameActionAsTable(lua_state, &game_input.move_left_action);
    lua_c.lua_setfield(lua_state, -2, "move_left_action");
    PushGameActionAsTable(lua_state, &game_input.move_right_action);
    lua_c.lua_setfield(lua_state, -2, "move_right_action");
    PushGameActionAsTable(lua_state, &game_input.move_down_action);
    lua_c.lua_setfield(lua_state, -2, "move_down_action");
    PushGameActionAsTable(lua_state, &game_input.move_up_action);
    lua_c.lua_setfield(lua_state, -2, "move_up_action");
    PushGameActionAsTable(lua_state, &game_input.jump_action);
    lua_c.lua_setfield(lua_state, -2, "jump_action");
    PushGameActionAsTable(lua_state, &game_input.attack_action);
    lua_c.lua_setfield(lua_state, -2, "attack_action");
    PushGameActionAsTable(lua_state, &game_input.select_action);
    lua_c.lua_setfield(lua_state, -2, "select_action");
    PushGameActionAsTable(lua_state, &game_input.debug_action);
    lua_c.lua_setfield(lua_state, -2, "debug_action");
    PushGameActionAsTable(lua_state, &game_input.cheat_action);
    lua_c.lua_setfield(lua_state, -2, "cheat_action");
    PushGameActionAsTable(lua_state, &game_input.cursor_select_action);
    lua_c.lua_setfield(lua_state, -2, "cursor_select_action");

    lua_c.lua_newtable(lua_state);
    lua_c.lua_pushnumber(lua_state, game_input.cursor_position.x);
    lua_c.lua_setfield(lua_state, -2, "x");
    lua_c.lua_pushnumber(lua_state, game_input.cursor_position.y);
    lua_c.lua_setfield(lua_state, -2, "y");
    lua_c.lua_setfield(lua_state, -2, "cursor_position");

    lua_c.lua_pushboolean(lua_state, @intFromBool(game_input.cursor_is_on_screen));
    lua_c.lua_setfield(lua_state, -2, "cursor_is_on_screen");
}

fn CallLuaModuleFunction(script_context: *LuaModuleScriptContext, function_name: []const u8, game_input: ?*const GameInput, pushed_arg_count: i32, expected_result_count: i32, optional: bool) bool {
    var result: bool = false;

    const lua_state: ?*lua_c.lua_State = script_context.lua_state;
    const module_function_stack_pos: i32 = lua_c.lua_gettop(lua_state) - pushed_arg_count + 1; // 1-based indexing

    _ = lua_c.lua_rawgeti(lua_state, lua_c.LUA_REGISTRYINDEX, script_context.module_table_registry_index); // TODO: Don't ignore result
    std.debug.assert(lua_c.lua_type(lua_state, -1) == lua_c.LUA_TTABLE); // "Unable to retrieve module table from registry"
    _ = lua_c.lua_getfield(lua_state, -1, function_name.ptr); // TODO: Don't ignore result

    if (lua_c.lua_isfunction(lua_state, -1)) {
        var arg_count: i32 = pushed_arg_count;

        // Move the module function just under the previously pushed args
        lua_c.lua_insert(lua_state, module_function_stack_pos);
        lua_c.lua_pop(lua_state, 1); // Remove module table from stack

        // Push input arg, if passed in
        if (game_input != null) {
            PushGameInputAsTable(lua_state.?, game_input.?);
            arg_count += 1;
        }

        // Place error handler just under module function
        const error_handler_stack_pos: i32 = module_function_stack_pos;
        lua_c.lua_pushcclosure(lua_state, lua_error_handler, 0);
        lua_c.lua_insert(lua_state, error_handler_stack_pos);

        if (lua_c.lua_pcallk(lua_state, arg_count, expected_result_count, error_handler_stack_pos, 0, null) != 0) {
            const error_message = lua_c.lua_tolstring(lua_state, -1, null);
            std.log.err("Error while calling Lua function in main script: {s}\n{s}", .{ function_name, error_message });
            std.debug.assert(false); // TODO: Error handling
        } else {
            result = true;
        }

        lua_c.lua_remove(lua_state, error_handler_stack_pos);
    } else {
        std.debug.assert(optional); // TODO: Error handling

        lua_c.lua_pop(lua_state, 1); // Remove nil function from stack
        lua_c.lua_pop(lua_state, 1); // Remove module table from stack
        lua_c.lua_pop(lua_state, pushed_arg_count); // Remove pushed args from stack
    }

    return result;
}

// ------------------- API FOR PLATFORM LAYER -------------------------------

pub const GameAction = extern struct { // TODO: Make it not extern struct?
    is_pressed: bool,
    just_pressed: bool,

    const default: GameAction = .{ .is_pressed = false, .just_pressed = false };
};

pub const GameCursorPosition = extern struct { // TODO: Make it not extern struct?
    x: f32,
    y: f32,

    const zero: GameCursorPosition = .{ .x = 0, .y = 0 };
};

pub const GameInput = extern struct { // TODO: Make it not extern struct?
    move_left_action: GameAction = .default,
    move_right_action: GameAction = .default,
    move_down_action: GameAction = .default,
    move_up_action: GameAction = .default,
    jump_action: GameAction = .default,
    attack_action: GameAction = .default,
    select_action: GameAction = .default,
    slowmo_action: GameAction = .default,
    debug_action: GameAction = .default,
    cheat_action: GameAction = .default,
    cursor_select_action: GameAction = .default,
    cursor_position: GameCursorPosition = .zero,
    cursor_is_on_screen: bool = false,
};

pub fn initZig(io: std.Io, gpa: std.mem.Allocator) void {
    g_io = io;
    g_gpa = gpa;
}

pub fn Init3D() bool {
    if (!basic_3d.initializeAll()) {
        return false;
    }

    return true;
}

pub fn InitGameDebugScript(script_name: [:0]const u8) void {
    var relative_script_filename_buf = std.mem.zeroes([std.fs.max_path_bytes:0]u8);
    // TODO: Use path-specific concatenation? one that can just use the relative_script_filename_buf buffer
    const relative_script_filename = std.fmt.bufPrintZ(&relative_script_filename_buf, "data/{s}", .{script_name}) catch @panic("Failed to print to buffer"); // TODO: Error handling?
    LoadLuaScript(relative_script_filename, &g_main_script_context);
    _ = CallLuaModuleFunction(&g_main_script_context, "initialize", null, 0, 0, false); // TODO: Don't ignore result
}

pub fn InitGameDebugLevel(level_name: [*:0]const u8) void {
    LoadLuaScript("data/main.lua", &g_main_script_context);
    _ = lua_c.lua_pushstring(g_main_script_context.lua_state, level_name); // TODO: Don't ignore result
    _ = CallLuaModuleFunction(&g_main_script_context, "initialize", null, 1, 0, false); // TODO: Don't ignore result
}

pub fn InitGameNormal() void {
    LoadLuaScript("data/main.lua", &g_main_script_context);
    _ = CallLuaModuleFunction(&g_main_script_context, "initialize", null, 0, 0, false); // TODO: Don't ignore result
}

pub fn UpdateGame(game_input: *const GameInput, seconds_per_update_timestep: f64) void {
    if (!main.isGameFrozen()) {
        basic_3d.rendererPreUpdate(seconds_per_update_timestep);
        _ = CallLuaModuleFunction(&g_main_script_context, "update", game_input, 0, 0, false); // TODO: Don't ignore result
        basic_3d.rendererPostUpdate();
    }
}

pub fn DrawGame(seconds_per_update_timestep: f64, seconds_since_previous_update: f64, time_scale: f64) void {
    // TODO: Just push interpolation_scale?
    lua_c.lua_pushnumber(g_main_script_context.lua_state, seconds_per_update_timestep);
    lua_c.lua_pushnumber(g_main_script_context.lua_state, seconds_since_previous_update);
    lua_c.lua_pushnumber(g_main_script_context.lua_state, time_scale);

    const pre_draw_function_existed: bool = CallLuaModuleFunction(&g_main_script_context, "pre_draw", null, 3, 1, true);

    var do_interpolation: bool = true;
    if (pre_draw_function_existed) {
        do_interpolation = !lua_checkbool(g_main_script_context.lua_state.?, -1);
        lua_c.lua_pop(g_main_script_context.lua_state, 1);
    }

    const interpolation_scale: f32 = @floatCast(time_scale * seconds_since_previous_update / seconds_per_update_timestep);
    basic_3d.rendererDraw(do_interpolation, interpolation_scale);
}

pub fn ExitGame() void {
    _ = CallLuaModuleFunction(&g_main_script_context, "on_exit_requested", null, 0, 0, false); // TODO: Don't ignore result
}
