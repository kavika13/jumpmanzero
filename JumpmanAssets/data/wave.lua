local Module = {};

-- TODO: Can this be combined with pause_wave.lua somehow?

Module.GameLogic = nil;

Module.SeaMeshResourceIndex = 0;
Module.WaveMeshResourceIndex = 0;
Module.SeaTextureResourceIndex = 0;
Module.Wave1TextureResourceIndex = 0;
Module.Wave2TextureResourceIndex = 0;

local g_wave_1_mesh_index = -1;
local g_wave_1_transform_index = -1;
local g_wave_2_mesh_index = -1;
local g_wave_2_transform_index = -1;
local g_sea_mesh_index = -1;
local g_sea_transform_index = -1;

local g_current_pos_y = 0;
local g_current_pos_x1 = 0;
local g_current_pos_x2 = 0;
local g_current_velocity_y = 0.2;

local g_wave_animation_cycle_degrees = 0;

function Module.initialize()
    g_wave_2_mesh_index = new_mesh(Module.WaveMeshResourceIndex);
    g_wave_2_transform_index = transform_create();
    mesh_set_transform(g_wave_2_mesh_index, g_wave_2_transform_index);
    set_mesh_texture(g_wave_2_mesh_index, Module.Wave2TextureResourceIndex);

    g_wave_1_mesh_index = new_mesh(Module.WaveMeshResourceIndex);
    g_wave_1_transform_index = transform_create();
    mesh_set_transform(g_wave_1_mesh_index, g_wave_1_transform_index);
    set_mesh_texture(g_wave_1_mesh_index, Module.Wave1TextureResourceIndex);

    g_sea_mesh_index = new_mesh(Module.SeaMeshResourceIndex);
    g_sea_transform_index = transform_create();
    mesh_set_transform(g_sea_mesh_index, g_sea_transform_index);
    set_mesh_texture(g_sea_mesh_index, Module.SeaTextureResourceIndex);
end

function Module.update()
    g_current_pos_y = g_current_pos_y + g_current_velocity_y;

    if g_current_pos_y > 64 then
        g_current_velocity_y = 0 - 0.3;
    end

    if g_current_pos_y < 0 - 6 then
        g_current_velocity_y = 0.2;
    end

    g_current_pos_x2 = g_current_pos_x2 + 0.15;

    if g_current_pos_x2 > 26.5 then
        g_current_pos_x2 = 0;
        skip_next_mesh_interpolation(g_wave_2_mesh_index);  -- TODO: Use texture movement instead?
    end

    g_current_pos_x1 = g_current_pos_x1 + 0.2;

    if g_current_pos_x1 > 26.5 then
        g_current_pos_x1 = 0;
        skip_next_mesh_interpolation(g_wave_1_mesh_index);  -- TODO: Use texture movement instead?
    end

    g_wave_animation_cycle_degrees = g_wave_animation_cycle_degrees + 3;

    if g_wave_animation_cycle_degrees > 360 then
        g_wave_animation_cycle_degrees = 0;
    end

    local iHeight1 = math.sin((g_wave_animation_cycle_degrees - 45) * math.pi / 180.0) * 512 / 200;
    local iHeight2 = math.sin(g_wave_animation_cycle_degrees * math.pi / 180.0) * 512 / 200 - 0.3;
    local iAdj1 = math.cos((g_wave_animation_cycle_degrees - 90) * math.pi / 180.0) * 512 / 300 - 13;
    local iAdj2 = math.cos(g_wave_animation_cycle_degrees * math.pi / 180.0) * 512 / 300 - 13;

    transform_set_translation(g_wave_1_transform_index, g_current_pos_x1 + iAdj1, g_current_pos_y + iHeight1, 0 - 0.1);
    set_mesh_is_visible(g_wave_1_mesh_index, true);

    transform_set_translation(g_sea_transform_index, g_current_pos_x1 + iAdj1, g_current_pos_y + iHeight1, 0 - 0.1);
    set_mesh_is_visible(g_sea_mesh_index, true);

    transform_set_translation(g_wave_2_transform_index, g_current_pos_x2 + iAdj2, g_current_pos_y + iHeight2, 6.5);
    set_mesh_is_visible(g_wave_2_mesh_index, true);

    if Module.GameLogic.is_player_colliding_with_rect(
            0 - 500, g_current_pos_y - 500,
            0 + 500, g_current_pos_y + 3) then
        Module.GameLogic.kill();

        if Module.GameLogic.get_player_current_position_y() < g_current_pos_y - 2 then
            Module.GameLogic.set_player_current_position_x(0 - 100);
        end
    end
end

return Module;
