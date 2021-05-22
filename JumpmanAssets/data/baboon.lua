local read_only = require "data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.BaboonClimbMeshResourceIndices = {};
Module.BaboonTextureResourceIndex = 0;

Module.StartX = 0;
Module.StartY = 0;

local animation_frame = {
    CLIMB_1 = 1,
    CLIMB_1 = 1,
    CLIMB_2 = 2,
    CLIMB_3 = 3,
    CLIMB_4 = 4,
    CLIMB_5 = 5,
};
animation_frame = read_only.make_table_read_only(animation_frame);

local g_baboon_mesh_index = -1;
local g_baboon_transform_index = -1;
local g_climb_animation_mesh_indices = {};
local g_climb_animation_current_mesh_index;
local g_climb_animation_frame_index = 0;
local g_climb_animation_meta_frame_index = 0;

local g_current_pos_x;
local g_current_pos_y;
local g_current_pos_z;
local g_current_velocity_y;

local function MoveBaboon_()
    -- TODO: A more clear way to write this frame selection code, if possible. Probably enums?
    g_climb_animation_frame_index = g_climb_animation_frame_index + 1;

    if g_climb_animation_frame_index > 3 then
        g_climb_animation_meta_frame_index = g_climb_animation_meta_frame_index + 4;
        g_climb_animation_frame_index = 0;
    end

    -- TODO: Modulo instead of `& 28`?
    if (g_climb_animation_meta_frame_index & 28) == 0 then
        g_climb_animation_current_mesh_index = animation_frame.CLIMB_1;
    elseif (g_climb_animation_meta_frame_index & 28) == 4 or (g_climb_animation_meta_frame_index & 28) == 28 then
        g_climb_animation_current_mesh_index = animation_frame.CLIMB_2;
    elseif (g_climb_animation_meta_frame_index & 28) == 8 or (g_climb_animation_meta_frame_index & 28) == 24 then
        g_climb_animation_current_mesh_index = animation_frame.CLIMB_3;
    elseif (g_climb_animation_meta_frame_index & 28) == 12 or (g_climb_animation_meta_frame_index & 28) == 20 then
        g_climb_animation_current_mesh_index = animation_frame.CLIMB_4;
    elseif (g_climb_animation_meta_frame_index & 28) == 16 then
        g_climb_animation_current_mesh_index = animation_frame.CLIMB_5;
    end

    local iOldY = g_current_pos_y;
    g_current_pos_y = g_current_pos_y + g_current_velocity_y;

    local vine_index, _ = Module.GameLogic.find_vine(g_current_pos_x + 3, g_current_pos_y);

    if vine_index < 0 then
        g_current_pos_y = iOldY;
        g_current_velocity_y = g_current_velocity_y * -1;
    else
        local close_vine = Module.GameLogic.get_vine(vine_index);

        if g_current_pos_y < close_vine.pos_y_bottom + 3 then
            g_current_pos_y = iOldY;
            g_current_velocity_y = g_current_velocity_y * -1;
        end

        if g_current_pos_y > close_vine.pos_y_top - 7 then
            g_current_pos_y = iOldY;
            g_current_velocity_y = g_current_velocity_y * -1;
        end
    end
end

function Module.initialize()
    g_climb_animation_mesh_indices[animation_frame.CLIMB_1] = Module.BaboonClimbMeshResourceIndices[5];
    g_climb_animation_mesh_indices[animation_frame.CLIMB_2] = Module.BaboonClimbMeshResourceIndices[1];
    g_climb_animation_mesh_indices[animation_frame.CLIMB_3] = Module.BaboonClimbMeshResourceIndices[3];
    g_climb_animation_mesh_indices[animation_frame.CLIMB_4] = Module.BaboonClimbMeshResourceIndices[2];
    g_climb_animation_mesh_indices[animation_frame.CLIMB_5] = Module.BaboonClimbMeshResourceIndices[4];

    g_baboon_mesh_index = new_mesh(g_climb_animation_mesh_indices[animation_frame.CLIMB_1]);
    g_baboon_transform_index = transform_create();
    object_set_transform(g_baboon_mesh_index, g_baboon_transform_index);
    set_mesh_texture(g_baboon_mesh_index, Module.BaboonTextureResourceIndex);
    set_mesh_is_visible(g_baboon_mesh_index, true);

    g_current_pos_x = Module.StartX;
    g_current_pos_y = Module.StartY;
    g_current_pos_z = 0;
    g_current_velocity_y = -0.5;
    g_climb_animation_current_mesh_index = animation_frame.CLIMB_1;
end

function Module.update()
    MoveBaboon_();

    set_mesh_to_mesh(g_baboon_mesh_index, g_climb_animation_mesh_indices[g_climb_animation_current_mesh_index]);
    transform_set_translation(g_baboon_transform_index, g_current_pos_x, g_current_pos_y + 6, g_current_pos_z);

    if Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 2, g_current_pos_y + 2,
            g_current_pos_x + 2, g_current_pos_y + 10) then
        Module.GameLogic.kill();
    end
end

return Module;
