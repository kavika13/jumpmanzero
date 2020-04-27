local Module = {};

Module.GameLogic = nil;

Module.LeftMeshResourceIndices = {};
Module.RightMeshResourceIndices = {};
Module.TextureResourceIndex = 0;

local g_dino_mesh = nil;
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
        g_animation_current_frame = g_flapping_animation_current_frame;
    else
        g_animation_current_frame = 0;  -- TODO: Use constants instead of these hard-coded frame numbers
    end

    if g_current_velocity_x < 0 then
        g_animation_current_frame = g_animation_current_frame + 10;  -- TODO: Use constants instead of these hard-coded frame numbers
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
    g_animation_mesh_indices[0] = Module.LeftMeshResourceIndices[1];
    g_animation_mesh_indices[1] = Module.LeftMeshResourceIndices[2];
    g_animation_mesh_indices[2] = Module.LeftMeshResourceIndices[3];
    g_animation_mesh_indices[3] = Module.LeftMeshResourceIndices[4];

    g_animation_mesh_indices[10] = Module.RightMeshResourceIndices[1];
    g_animation_mesh_indices[11] = Module.RightMeshResourceIndices[2];
    g_animation_mesh_indices[12] = Module.RightMeshResourceIndices[3];
    g_animation_mesh_indices[13] = Module.RightMeshResourceIndices[4];

    g_dino_mesh = new_mesh(g_animation_mesh_indices[0]);
    set_mesh_texture(g_dino_mesh, Module.TextureResourceIndex);
    set_mesh_is_visible(g_dino_mesh, true);

    g_animation_current_frame = g_animation_mesh_indices[0];
end

function Module.update()
    Animate_();
    SetFrame_();
    Move_();

    set_mesh_to_mesh(g_dino_mesh, g_animation_mesh_indices[g_animation_current_frame]);
    set_identity_mesh_matrix(g_dino_mesh);
    translate_mesh_matrix(g_dino_mesh, g_current_pos_x, g_current_pos_y, 3);

    if Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 8, g_current_pos_y - 3,
            g_current_pos_x + 8, g_current_pos_y + 3) then
        Module.GameLogic.kill();
    end
end

return Module;
