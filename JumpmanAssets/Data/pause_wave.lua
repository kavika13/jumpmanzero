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
    for platform_index = 0, get_platform_object_count() - 1 do
        local platform_mesh_index = get_platform_mesh_index(platform_index);
        move_mesh_to_front(platform_mesh_index);
    end

    for ladder_index = 0, Module.GameLogic.get_ladder_object_count() - 1 do
        local ladder_mesh_index = Module.GameLogic.get_ladder(ladder_index).mesh_index;
        move_mesh_to_front(ladder_mesh_index);
    end
end

function Module.initialize()
    g_current_pos_y = Module.TargetWaveHeight;

    g_wave_1_mesh_index =  new_mesh(Module.WaveMeshResourceIndex);
    set_mesh_texture(g_wave_1_mesh_index, Module.Wave1TextureResourceIndex);
    move_mesh_to_front(g_wave_1_mesh_index);

    g_wave_2_mesh_index = new_mesh(Module.WaveMeshResourceIndex);
    set_mesh_texture(g_wave_2_mesh_index, Module.Wave2TextureResourceIndex);
    move_mesh_to_front(g_wave_2_mesh_index);

    g_sea_mesh_index = new_mesh(Module.SeaMeshResourceIndex);
    set_mesh_texture(g_sea_mesh_index, Module.SeaTextureResourceIndex);
    move_mesh_to_front(g_sea_mesh_index);

    PrioritizeLevelObjects();

    local backdrop_mesh_index = find_backdrop_mesh_index(100);  -- TODO: Use constant for num
    move_mesh_to_front(backdrop_mesh_index);

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

    set_identity_mesh_matrix(g_wave_1_mesh_index);
    translate_mesh_matrix(g_wave_1_mesh_index, g_current_pos_x1 + iAdj1, g_current_pos_y + iHeight1 / 5, 0 - 0.1);
    set_mesh_is_visible(g_wave_1_mesh_index, true);

    set_identity_mesh_matrix(g_sea_mesh_index);
    scale_mesh_matrix(g_sea_mesh_index, 1, 1.5, 1);
    translate_mesh_matrix(g_sea_mesh_index, g_current_pos_x1 + iAdj1, g_current_pos_y + iHeight1 / 5, 0 - 0.1);
    set_mesh_is_visible(g_sea_mesh_index, true);

    set_identity_mesh_matrix(g_wave_2_mesh_index);
    translate_mesh_matrix(g_wave_2_mesh_index, g_current_pos_x2 + iAdj2, g_current_pos_y + iHeight2 / 5, 6.5);
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
