local Module = {};

Module.LeftMeshResourceIndices = {};
Module.RightMeshResourceIndices = {};
Module.TextureResourceIndex = 0;

local g_is_initialized = false;

local g_animation_mesh_indices = {};
local g_current_animation_frame = 0;
local g_flapping_animation_current_frame = 0;
local g_flapping_animation_counter = 0;

local g_current_pos_x;
local g_current_pos_y;
local g_current_velocity_x;
local g_current_velocity_y;
local g_current_acceleration_direction_y;

local function Move()
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

local function SetFrame()
    if g_current_acceleration_direction_y >= 0 then
        g_current_animation_frame = g_flapping_animation_current_frame;
    else
        g_current_animation_frame = 0;
    end

    if g_current_velocity_x < 0 then
        g_current_animation_frame = g_current_animation_frame + 10;
    end
end

local function Animate()
    g_flapping_animation_counter = g_flapping_animation_counter + 1;

    if g_flapping_animation_counter > 3 then
        g_flapping_animation_counter = 0;
        g_flapping_animation_current_frame = g_flapping_animation_current_frame + 1;

        if g_flapping_animation_current_frame == 4 then
            g_flapping_animation_current_frame = 0;
        end
    end
end

local function Initialize()
    g_is_initialized = true;

    g_current_velocity_y = 0;
    g_current_acceleration_direction_y = 1;
    g_current_velocity_x = 0.8;

    g_current_pos_x = -10;
    g_current_pos_y = 120;

    g_animation_mesh_indices[0] = new_mesh(Module.LeftMeshResourceIndices[1]);
    g_animation_mesh_indices[1] = new_mesh(Module.LeftMeshResourceIndices[2]);
    g_animation_mesh_indices[2] = new_mesh(Module.LeftMeshResourceIndices[3]);
    g_animation_mesh_indices[3] = new_mesh(Module.LeftMeshResourceIndices[4]);

    g_animation_mesh_indices[10] = new_mesh(Module.RightMeshResourceIndices[1]);
    g_animation_mesh_indices[11] = new_mesh(Module.RightMeshResourceIndices[2]);
    g_animation_mesh_indices[12] = new_mesh(Module.RightMeshResourceIndices[3]);
    g_animation_mesh_indices[13] = new_mesh(Module.RightMeshResourceIndices[4]);
end

function Module.update()
    if not g_is_initialized then
        Initialize();
    end

    select_object_mesh(g_animation_mesh_indices[g_current_animation_frame]);
    set_object_visual_data(0, 0);

    Animate();
    SetFrame();
    Move();

    select_object_mesh(g_animation_mesh_indices[g_current_animation_frame]);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(g_current_pos_x, g_current_pos_y, 3);
    set_object_visual_data(Module.TextureResourceIndex, 2);

    if is_player_colliding_with_rect(g_current_pos_x - 8, g_current_pos_y - 3, g_current_pos_x + 8, g_current_pos_y + 3) then
        kill();
    end
end

return Module;