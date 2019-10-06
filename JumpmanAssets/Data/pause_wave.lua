local Module = {};

-- TODO: Can this be combined with wave.lua somehow?

Module.GameLogic = nil;

Module.SeaMeshResourceIndex = 0;
Module.WaveMeshResourceIndex = 0;
Module.SeaTextureResourceIndex = 0;
Module.Wave1TextureResourceIndex = 0;
Module.Wave2TextureResourceIndex = 0;

Module.TargetWaveHeight = 0;

local g_wave_1_mesh_index;
local g_wave_2_mesh_index;
local g_sea_mesh_index;

local g_current_pos_x1 = 0;
local g_current_pos_x2 = 0;
local g_current_pos_y = 125;

local g_wave_animation_cycle_degrees = 0;

local function PrioritizeLevelObjects()
    for iLoop = 0, get_platform_object_count() - 1 do
        abs_platform(iLoop);
        prioritize_object();
    end

    for iLoop = 0, get_ladder_object_count() - 1 do
        abs_ladder(iLoop);
        prioritize_object();
    end
end

function Module.initialize()
    g_current_pos_y = Module.TargetWaveHeight;

    g_wave_1_mesh_index =  new_mesh(Module.WaveMeshResourceIndex);
    prioritize_object();
    g_wave_2_mesh_index = new_mesh(Module.WaveMeshResourceIndex);
    prioritize_object();
    g_sea_mesh_index = new_mesh(Module.SeaMeshResourceIndex);
    prioritize_object();

    PrioritizeLevelObjects();

    select_picture(100);  -- TODO: Pass this constant in? Also, which object is this? It makes the wave screw up transparency if not doing this
    prioritize_object();

    Pause = 1;  -- TODO: This variable doesn't exist? What was it in pausewave.jms?
end

function Module.update()
    if g_current_pos_y < Module.TargetWaveHeight then
        g_current_pos_y = g_current_pos_y + 0.7;

        if g_current_pos_y < 10 then
            g_current_pos_y = g_current_pos_y - 0.3;
        end

        if g_current_pos_y < 20 then
            g_current_pos_y = g_current_pos_y - 0.2;
        end

        if g_current_pos_y > (Module.TargetWaveHeight - 20) then
            g_current_pos_y = g_current_pos_y - 0.3;
        end

        if g_current_pos_y > (Module.TargetWaveHeight - 10) then
            g_current_pos_y = g_current_pos_y - 0.3;
        end
    end

    if g_current_pos_y > Module.TargetWaveHeight + 1 then
        g_current_pos_y = g_current_pos_y - 0.7;
    end

    g_current_pos_x2 = g_current_pos_x2 + 0.3;

    if g_current_pos_x2 > 26.5 then
        g_current_pos_x2 = 0;
    end

    g_current_pos_x1 = g_current_pos_x1 + 0.4;

    if g_current_pos_x1 > 26.5 then
        g_current_pos_x1 = 0;
    end

    g_wave_animation_cycle_degrees = g_wave_animation_cycle_degrees + 3;

    if g_wave_animation_cycle_degrees > 360 then
        g_wave_animation_cycle_degrees = 0;
    end

    local iHeight1 = math.sin((g_wave_animation_cycle_degrees - 45) * math.pi / 180.0) * 512 / 200;
    local iHeight2 = math.sin(g_wave_animation_cycle_degrees * math.pi / 180.0) * 512 / 200 - 0.3;
    local iAdj1 = math.cos((g_wave_animation_cycle_degrees - 90) * math.pi / 180.0) * 512 / 300 - 13;
    local iAdj2 = math.cos(g_wave_animation_cycle_degrees * math.pi / 180.0) * 512 / 300 - 13;

    select_object_mesh(g_wave_1_mesh_index);
    set_identity_mesh_matrix(g_wave_1_mesh_index);
    translate_mesh_matrix(g_wave_1_mesh_index, g_current_pos_x1 + iAdj1, g_current_pos_y + iHeight1 / 5, 0 - 0.1);
    set_texture_and_is_visible_on_mesh(g_wave_1_mesh_index, Module.Wave1TextureResourceIndex, 1);

    select_object_mesh(g_sea_mesh_index);
    set_identity_mesh_matrix(g_sea_mesh_index);
    scale_mesh_matrix(g_sea_mesh_index, 1, 1.5, 1);
    translate_mesh_matrix(g_sea_mesh_index, g_current_pos_x1 + iAdj1, g_current_pos_y + iHeight1 / 5, 0 - 0.1);
    set_texture_and_is_visible_on_mesh(g_sea_mesh_index, Module.SeaTextureResourceIndex, 1);

    select_object_mesh(g_wave_2_mesh_index);
    set_identity_mesh_matrix(g_wave_2_mesh_index);
    translate_mesh_matrix(g_wave_2_mesh_index, g_current_pos_x2 + iAdj2, g_current_pos_y + iHeight2 / 5, 6.5);
    set_texture_and_is_visible_on_mesh(g_wave_2_mesh_index, Module.Wave2TextureResourceIndex, 1);

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
