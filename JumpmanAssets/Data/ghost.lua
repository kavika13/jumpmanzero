local Module = {};

Module.GameLogic = nil;

Module.MoveRight1MeshResourceIndex = 0;
Module.MoveRight2MeshResourceIndex = 0;
Module.MoveLeft1MeshResourceIndex = 0;
Module.MoveLeft2MeshResourceIndex = 0;
Module.TextureResourceIndex = 0;

local g_current_pos_x = 0;
local g_current_pos_y = 0;
local g_current_velocity_x = 0;
local g_current_velocity_y = 0;

local g_animation_mesh_indices = {};
local g_animation_frame_index = 0;
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
    g_animation_mesh_indices[0] = new_mesh(Module.MoveRight1MeshResourceIndex);
    prioritize_object();

    g_animation_mesh_indices[1] = new_mesh(Module.MoveRight2MeshResourceIndex);
    prioritize_object();

    g_animation_mesh_indices[2] = new_mesh(Module.MoveLeft1MeshResourceIndex);
    prioritize_object();

    g_animation_mesh_indices[3] = new_mesh(Module.MoveLeft2MeshResourceIndex);
    prioritize_object();
end

function Module.update()
    -- TODO: Animate through changemesh, instead of set_texture_and_is_visible_on_mesh?
    select_object_mesh(g_animation_mesh_indices[g_animation_frame_index]);  -- Previous frame
    set_texture_and_is_visible_on_mesh(g_animation_mesh_indices[g_animation_frame_index], 0, 0);

    MoveGhost();

    g_animation_counter = g_animation_counter + 1;

    if g_animation_counter > 11 then
        g_animation_counter = 0;
    end

    if g_animation_counter > 5 then
        g_animation_frame_index = 1;
    else
        g_animation_frame_index = 0;
    end

    local iAdapt = 0 - 4.5;

    if g_current_velocity_x <= 0 then
        iAdapt = 4.5;
        g_animation_frame_index = g_animation_frame_index + 2;
    end

    local anim_mesh_index = g_animation_mesh_indices[g_animation_frame_index];
    select_object_mesh(anim_mesh_index);
    set_identity_mesh_matrix(anim_mesh_index);
    translate_mesh_matrix(anim_mesh_index, g_current_pos_x + iAdapt, g_current_pos_y + 5, 0 - 0.25);
    set_texture_and_is_visible_on_mesh(anim_mesh_index, Module.TextureResourceIndex, 1);

    if Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x + iAdapt - 5, g_current_pos_y + 4,
            g_current_pos_x + iAdapt + 5, g_current_pos_y + 10) then
        Module.GameLogic.kill();
    end
end

return Module;
