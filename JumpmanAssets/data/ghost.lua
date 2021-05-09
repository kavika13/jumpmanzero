local read_only = require "data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.MoveRight1MeshResourceIndex = 0;
Module.MoveRight2MeshResourceIndex = 0;
Module.MoveLeft1MeshResourceIndex = 0;
Module.MoveLeft2MeshResourceIndex = 0;
Module.TextureResourceIndex = 0;

local animation_frame = {
    MOVE_RIGHT_1 = 0,
    MOVE_RIGHT_2 = 1,
    MOVE_LEFT_1 = 2,
    MOVE_LEFT_2 = 3,
};
animation_frame = read_only.make_table_read_only(animation_frame);

local g_current_pos_x = 0;
local g_current_pos_y = 0;
local g_current_velocity_x = 0;
local g_current_velocity_y = 0;

local g_animation_mesh_indices = {};
local g_animation_frame_index = animation_frame.MOVE_RIGHT_1;
local g_animation_counter = 0;

local function MoveGhost()
    local ghost_acceleration = 0.03;
    local ghost_max_velocity = 0.65;

    local player_pos_x = Module.GameLogic.get_player_current_position_x();
    local player_pos_y = Module.GameLogic.get_player_current_position_y();

    if player_pos_x >= g_current_pos_x then
        g_current_velocity_x = g_current_velocity_x + ghost_acceleration;

        if g_current_velocity_x > ghost_max_velocity then
            g_current_velocity_x = ghost_max_velocity;
        end
    else
        g_current_velocity_x = g_current_velocity_x - ghost_acceleration;

        if g_current_velocity_x < (0 - ghost_max_velocity) then
            g_current_velocity_x = 0 - ghost_max_velocity;
        end
    end

    if player_pos_y >= g_current_pos_y then
        g_current_velocity_y = g_current_velocity_y + ghost_acceleration;

        if g_current_velocity_y > ghost_max_velocity then
            g_current_velocity_y = ghost_max_velocity;
        end
    else
        g_current_velocity_y = g_current_velocity_y - ghost_acceleration;

        if g_current_velocity_y < (0 - ghost_max_velocity) then
            g_current_velocity_y = 0 - ghost_max_velocity;
        end
    end

    g_current_pos_x = g_current_pos_x + g_current_velocity_x;
    g_current_pos_y = g_current_pos_y + g_current_velocity_y;
end

local function ResetPos()
    g_current_pos_x = 0;
    g_current_velocity_x = 1;
    g_current_pos_y = 0;
    g_current_velocity_y = 1;
end

function Module.initialize()
    g_animation_mesh_indices[animation_frame.MOVE_RIGHT_1] = Module.MoveRight1MeshResourceIndex;
    g_animation_mesh_indices[animation_frame.MOVE_RIGHT_2] = Module.MoveRight2MeshResourceIndex;
    g_animation_mesh_indices[animation_frame.MOVE_LEFT_1] = Module.MoveLeft1MeshResourceIndex;
    g_animation_mesh_indices[animation_frame.MOVE_LEFT_2] = Module.MoveLeft2MeshResourceIndex;

    g_ghost_mesh = new_mesh(g_animation_mesh_indices[animation_frame.MOVE_RIGHT_1]);
    set_mesh_texture(g_ghost_mesh, Module.TextureResourceIndex);
    set_mesh_is_visible(g_ghost_mesh, true);
end

function Module.update()
    MoveGhost();

    g_animation_counter = g_animation_counter + 1;

    if g_animation_counter > 11 then
        g_animation_counter = 0;
    end

    if g_animation_counter > 5 then
        g_animation_frame_index = animation_frame.MOVE_RIGHT_2;
    else
        g_animation_frame_index = animation_frame.MOVE_RIGHT_1;
    end

    local iAdapt = 0 - 4.5;

    if g_current_velocity_x <= 0 then
        iAdapt = 4.5;
        g_animation_frame_index = animation_frame.MOVE_LEFT_1 + g_animation_frame_index;  -- This works cause the indices are 0-based
    end

    set_mesh_to_mesh(g_ghost_mesh, g_animation_mesh_indices[g_animation_frame_index]);
    set_identity_mesh_matrix(g_ghost_mesh);
    translate_mesh_matrix(g_ghost_mesh, g_current_pos_x + iAdapt, g_current_pos_y + 5, 0 - 0.25);

    if Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x + iAdapt - 5, g_current_pos_y + 4,
            g_current_pos_x + iAdapt + 5, g_current_pos_y + 10) then
        Module.GameLogic.kill();
    end
end

return Module;
