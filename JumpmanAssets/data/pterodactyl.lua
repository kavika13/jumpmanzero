local read_only = require "data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.LeftMeshResourceIndices = {};
Module.RightMeshResourceIndices = {};
Module.TextureResourceIndex = 0;

local animation_frame = {
    FLY_LEFT_1 = 0,
    FLY_LEFT_2 = 1,
    FLY_LEFT_3 = 2,
    FLY_LEFT_4 = 3,
    FLY_RIGHT_1 = 10,
    FLY_RIGHT_2 = 11,
    FLY_RIGHT_3 = 12,
    FLY_RIGHT_4 = 13,
    META_FACE_RIGHT = 10,  -- Not an actual animation frame
    META_FLY_ANIM_COUNT = 4,  -- Not an actual animation frame
};
animation_frame = read_only.make_table_read_only(animation_frame);

local g_dino_mesh = nil;
local g_dino_transform_index = nil;
local g_animation_mesh_indices = {};
local g_animation_current_frame;
local g_flapping_animation_current_frame = 0;
local g_flapping_animation_counter = 0;

local g_current_pos_x;
local g_current_pos_y;
local g_current_velocity_x;
local g_current_velocity_y;
local g_current_acceleration_direction_y;

local function Move_()
    if g_current_acceleration_direction_y == 1 then
        g_current_velocity_y = g_current_velocity_y + 0.035;

        if g_current_velocity_y > 1 then
            g_current_acceleration_direction_y = -1;
        end
    else
        g_current_velocity_y = g_current_velocity_y - 0.035;

        if g_current_velocity_y < -1 then
            g_current_acceleration_direction_y = 1;
        end
    end

    g_current_pos_x = g_current_pos_x + g_current_velocity_x;
    g_current_pos_y = g_current_pos_y + g_current_velocity_y;

    if g_current_pos_x > 200 or g_current_pos_x < -40 then
        g_current_velocity_x = 0 - g_current_velocity_x;
        g_current_pos_x = g_current_pos_x + g_current_velocity_x;
        g_current_pos_y = (g_current_pos_y + 120) / 2;
    end
end

local function SetFrame_()
    if g_current_acceleration_direction_y >= 0 then
        g_animation_current_frame = animation_frame.FLY_LEFT_1 + g_flapping_animation_current_frame;
    else
        g_animation_current_frame = animation_frame.FLY_LEFT_1;
    end

    if g_current_velocity_x < 0 then
        g_animation_current_frame = animation_frame.META_FACE_RIGHT + g_animation_current_frame;
    end
end

local function Animate_()
    g_flapping_animation_counter = g_flapping_animation_counter + 1;

    if g_flapping_animation_counter > 3 then
        g_flapping_animation_counter = 0;
        g_flapping_animation_current_frame = g_flapping_animation_current_frame + 1;

        if g_flapping_animation_current_frame == animation_frame.META_FLY_ANIM_COUNT then
            g_flapping_animation_current_frame = 0;
        end
    end
end

function Module.initialize()
    g_current_velocity_y = 0;
    g_current_acceleration_direction_y = 1;
    g_current_velocity_x = 0.8;

    g_current_pos_x = -10;
    g_current_pos_y = 120;

    g_animation_mesh_indices[animation_frame.FLY_LEFT_1] = Module.LeftMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.FLY_LEFT_2] = Module.LeftMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.FLY_LEFT_3] = Module.LeftMeshResourceIndices[3];
    g_animation_mesh_indices[animation_frame.FLY_LEFT_4] = Module.LeftMeshResourceIndices[4];

    g_animation_mesh_indices[animation_frame.FLY_RIGHT_1] = Module.RightMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.FLY_RIGHT_2] = Module.RightMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.FLY_RIGHT_3] = Module.RightMeshResourceIndices[3];
    g_animation_mesh_indices[animation_frame.FLY_RIGHT_4] = Module.RightMeshResourceIndices[4];

    local setup_object_transform = function(mesh_index)
        local result = transform_create();
        object_set_transform(mesh_index, result);
        return result;
    end

    g_dino_mesh = new_mesh(g_animation_mesh_indices[animation_frame.FLY_LEFT_1]);
    g_dino_transform_index = setup_object_transform(g_dino_mesh);
    set_mesh_texture(g_dino_mesh, Module.TextureResourceIndex);
    set_mesh_is_visible(g_dino_mesh, true);

    g_animation_current_frame = animation_frame.FLY_LEFT_1;
end

function Module.update()
    Animate_();
    SetFrame_();
    Move_();

    set_mesh_to_mesh(g_dino_mesh, g_animation_mesh_indices[g_animation_current_frame]);
    transform_set_translation(g_dino_transform_index, g_current_pos_x, g_current_pos_y, 3);

    if Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 8, g_current_pos_y - 3,
            g_current_pos_x + 8, g_current_pos_y + 3) then
        Module.GameLogic.kill();
    end
end

return Module;
