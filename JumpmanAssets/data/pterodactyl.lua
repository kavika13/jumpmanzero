local Module = {};

Module.GameLogic = nil;

Module.LeftMeshResourceIndices = {};
Module.RightMeshResourceIndices = {};
Module.TextureResourceIndex = 0;

local g_animation_mesh_indices = {};
local g_current_animation_frame = 0;
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
        g_current_animation_frame = g_flapping_animation_current_frame;
    else
        g_current_animation_frame = 0;  -- TODO: Use constants instead of these hard-coded frame numbers
    end

    if g_current_velocity_x < 0 then
        g_current_animation_frame = g_current_animation_frame + 10;  -- TODO: Use constants instead of these hard-coded frame numbers
    end
end

local function Animate_()
    g_flapping_animation_counter = g_flapping_animation_counter + 1;

    if g_flapping_animation_counter > 3 then
        g_flapping_animation_counter = 0;
        g_flapping_animation_current_frame = g_flapping_animation_current_frame + 1;

        if g_flapping_animation_current_frame == 4 then  -- TODO: Use constants instead of these hard-coded frame numbers
            g_flapping_animation_current_frame = 0;  -- TODO: Use constants instead of these hard-coded frame numbers
        end
    end
end

function Module.initialize()
    g_current_velocity_y = 0;
    g_current_acceleration_direction_y = 1;
    g_current_velocity_x = 0.8;

    g_current_pos_x = -10;
    g_current_pos_y = 120;

    -- TODO: Use constants instead of these hard-coded frame numbers
    g_animation_mesh_indices[0] = new_mesh(Module.LeftMeshResourceIndices[1]);
    g_animation_mesh_indices[1] = new_mesh(Module.LeftMeshResourceIndices[2]);
    g_animation_mesh_indices[2] = new_mesh(Module.LeftMeshResourceIndices[3]);
    g_animation_mesh_indices[3] = new_mesh(Module.LeftMeshResourceIndices[4]);

    g_animation_mesh_indices[10] = new_mesh(Module.RightMeshResourceIndices[1]);
    g_animation_mesh_indices[11] = new_mesh(Module.RightMeshResourceIndices[2]);
    g_animation_mesh_indices[12] = new_mesh(Module.RightMeshResourceIndices[3]);
    g_animation_mesh_indices[13] = new_mesh(Module.RightMeshResourceIndices[4]);

    for i = 0, 3 do  -- TODO: Use constants instead of these hard-coded frame numbers
        set_mesh_texture(g_animation_mesh_indices[i], Module.TextureResourceIndex);
    end

    for i = 10, 13 do  -- TODO: Use constants instead of these hard-coded frame numbers
        set_mesh_texture(g_animation_mesh_indices[i], Module.TextureResourceIndex);
    end
end

function Module.update()
    -- TODO: Animate through changemesh, instead of set_mesh_is_visible?
    set_mesh_is_visible(g_animation_mesh_indices[g_current_animation_frame], false);

    Animate_();
    SetFrame_();
    Move_();

    local anim_mesh_index = g_animation_mesh_indices[g_current_animation_frame];
    set_identity_mesh_matrix(anim_mesh_index);
    translate_mesh_matrix(anim_mesh_index, g_current_pos_x, g_current_pos_y, 3);
    set_mesh_is_visible(anim_mesh_index, true);

    if Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 8, g_current_pos_y - 3,
            g_current_pos_x + 8, g_current_pos_y + 3) then
        Module.GameLogic.kill();
    end
end

return Module;