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
local g_animation_frame_index = 0;  -- TODO: Use constants instead of these hard-coded frame numbers
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
    -- TODO: Use constants instead of these hard-coded frame numbers
    g_animation_mesh_indices[0] = new_mesh(Module.MoveRight1MeshResourceIndex);
    g_animation_mesh_indices[1] = new_mesh(Module.MoveRight2MeshResourceIndex);
    g_animation_mesh_indices[2] = new_mesh(Module.MoveLeft1MeshResourceIndex);
    g_animation_mesh_indices[3] = new_mesh(Module.MoveLeft2MeshResourceIndex);

    for i = 0, 3 do  -- TODO: Use constants instead of these hard-coded frame numbers
        set_mesh_texture(g_animation_mesh_indices[i], Module.TextureResourceIndex);
        move_mesh_to_front(g_animation_mesh_indices[i]);
    end
end

function Module.update()
    -- TODO: Animate through changemesh, instead of set_mesh_is_visible?
    set_mesh_is_visible(g_animation_mesh_indices[g_animation_frame_index], false);

    MoveGhost();

    g_animation_counter = g_animation_counter + 1;

    if g_animation_counter > 11 then
        g_animation_counter = 0;
    end

    if g_animation_counter > 5 then
        g_animation_frame_index = 1;  -- TODO: Use constants instead of these hard-coded frame numbers
    else
        g_animation_frame_index = 0;  -- TODO: Use constants instead of these hard-coded frame numbers
    end

    local iAdapt = 0 - 4.5;

    if g_current_velocity_x <= 0 then
        iAdapt = 4.5;
        g_animation_frame_index = g_animation_frame_index + 2;  -- TODO: Use constants instead of these hard-coded frame numbers
    end

    local anim_mesh_index = g_animation_mesh_indices[g_animation_frame_index];
    set_identity_mesh_matrix(anim_mesh_index);
    translate_mesh_matrix(anim_mesh_index, g_current_pos_x + iAdapt, g_current_pos_y + 5, 0 - 0.25);
    set_mesh_is_visible(anim_mesh_index, true);

    if Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x + iAdapt - 5, g_current_pos_y + 4,
            g_current_pos_x + iAdapt + 5, g_current_pos_y + 10) then
        Module.GameLogic.kill();
    end
end

return Module;
