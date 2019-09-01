local Module = {};

Module.FramesToWait = 0;  -- TODO: Separate "initial" wait, so it can be reset?
Module.Mesh1Index = 0;
Module.Mesh2Index = 0;
Module.TextureIndex = 0;
Module.FireSoundIndex = -1;

local g_is_initialized = false;

local g_mesh_index_1;
local g_mesh_index_2;

local g_maximum_pos_x;

local g_is_firing = false;
local g_frames_since_restarted = 0;

local g_current_pos_x = 0;
local g_current_pos_y = 0;
local g_current_pos_z = 0;
local g_current_velocity_x = 0;
local g_current_velocity_y = 0;
local g_current_rotation_x = 0;
local g_current_rotation_z = 0;
local g_pos_z_correction_current_frame_index = 0;

local function CheckFire()
    g_frames_since_restarted = g_frames_since_restarted + 1;

    local player_x = get_player_current_position_x();
    local player_y = get_player_current_position_y() + 6;

    if player_x + 1 > g_current_pos_x and player_x <= g_current_pos_x and g_frames_since_restarted > 100 then
        g_is_firing = true;

        if Module.FireSoundIndex >= 0 then
            play_sound_effect(Module.FireSoundIndex);
        end

        g_current_velocity_x = 0;

        if player_y > g_current_pos_y then
            g_current_velocity_y = 1;
        else
            g_current_velocity_y = 0 - 1;
        end
    end

    if player_y + 1 > g_current_pos_y and player_y <= g_current_pos_y and not g_is_firing and g_frames_since_restarted > 100 then
        g_is_firing = true;

        if Module.FireSoundIndex >= 0 then
            play_sound_effect(Module.FireSoundIndex);
        end

        g_current_velocity_y = 0;

        if player_x > g_current_pos_x then
            g_current_velocity_x = 1;
        else
            g_current_velocity_x = 0 - 1;
        end
    end
end

local function RestartBullet()
    local iSupp = 0;
    local iVel = 0;

    select_object_mesh(g_mesh_index_1);
    set_object_visual_data(0, 0);

    select_object_mesh(g_mesh_index_2);
    set_object_visual_data(0, 0);

    local iType = rnd(1, 100);

    if iType < 50 then
        iVel = 0.35;
        iSupp = iVel;
    else
        iVel = 0.5;
    end

    g_is_firing = false;
    g_frames_since_restarted = 0;

    local player_x = get_player_current_position_x();
    local player_y = get_player_current_position_y();

    iType = rnd(1, 100);

    if iType < 50 then
        g_current_pos_x = rnd(30, 130);

        if (iType < 25 and player_y > 60) or player_y > 100 then
            g_current_pos_y = 0 - 10;
            g_current_velocity_y = iVel;
        end

        if (iType >= 25 and player_y <= 100) or player_y <= 60 then
            g_current_pos_y = 170;
            g_current_velocity_y = 0 - iVel;
        end

        g_current_velocity_x = 0 - iSupp;

        if g_current_pos_x < 80 then
            g_current_velocity_x = iSupp;
        end

        g_current_pos_x = g_current_pos_x - (iSupp * 5);
    end

    if iType >= 50 then
        g_current_pos_y = rnd(30, 130);

        if (iType < 75 and player_x > 60) or player_x > 100 then
            g_current_pos_x = 0 - 10;
            g_current_velocity_x = iVel;
        end

        if (iType >= 75 and player_x <= 100) or player_x <= 60 then
            g_current_pos_x = g_maximum_pos_x;
            g_current_velocity_x = 0 - iVel;
        end

        g_current_velocity_y = 0 - iSupp;

        if g_current_pos_y < 80 then
            g_current_velocity_y = iSupp;
        end

        g_current_pos_y = g_current_pos_y - (iSupp * 5);
    end
end

local function CheckOOB()
    if g_current_pos_x < 0 - 40 or g_current_pos_x > g_maximum_pos_x or g_current_pos_y < 0 - 70 or g_current_pos_y > 190 then
        RestartBullet();
    end
end

function Module.update()
    if not g_is_initialized then
        g_is_initialized = true;
        g_mesh_index_1 = new_mesh(Module.Mesh1Index);
        g_mesh_index_2 = new_mesh(Module.Mesh2Index);
        g_maximum_pos_x = get_level_extent_x() + 40;
        RestartBullet();
    end

    if Module.FramesToWait > 0 then
        Module.FramesToWait = Module.FramesToWait - 1;
        return;
    end

    if get_player_freeze_cooldown_frame_count() ~= 0 then
        RestartBullet();
    end

    g_pos_z_correction_current_frame_index = g_pos_z_correction_current_frame_index + 1;

    if g_pos_z_correction_current_frame_index == 5 then
        g_pos_z_correction_current_frame_index = 0;
    end

    g_current_pos_x = g_current_pos_x + g_current_velocity_x;
    g_current_pos_y = g_current_pos_y + g_current_velocity_y;

    if not g_is_firing then
        CheckFire();
    end

    CheckOOB();

    local iPlat1 = find_platform(g_current_pos_x, g_current_pos_y, 8, 4);
    abs_platform(iPlat1);
    iPlat1 = get_script_selected_level_object_z1();

    local iPlat2 = find_platform(g_current_pos_x + g_current_velocity_x * 6, (g_current_pos_y) + (g_current_velocity_y * 6), 8, 4);
    abs_platform(iPlat2);
    iPlat2 = get_script_selected_level_object_z1();

    local iBest = (iPlat1 + iPlat2) / 2;

    if g_pos_z_correction_current_frame_index == 2 then
        if iBest > g_current_pos_z then
            g_current_pos_z = g_current_pos_z + 1;
        end

        if iBest < g_current_pos_z then
            g_current_pos_z = g_current_pos_z - 1;
        end
    end

    if not g_is_firing then
        g_current_rotation_z = g_current_rotation_z + 3;
        g_current_rotation_x = g_current_rotation_x + 3;
    elseif g_current_velocity_y == 0 then
        g_current_rotation_z = g_current_rotation_z + 7;
    else
        g_current_rotation_x = g_current_rotation_x + 7;
    end

    if is_player_colliding_with_rect(g_current_pos_x - 1, g_current_pos_y - 1, g_current_pos_x + 1, g_current_pos_y + 1) then
        kill();
    end

    select_object_mesh(g_mesh_index_1);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_rotate_matrix_x(g_current_rotation_x);
    script_selected_mesh_rotate_matrix_z(g_current_rotation_z);
    script_selected_mesh_translate_matrix(g_current_pos_x, g_current_pos_y, g_current_pos_z - 2);
    set_object_visual_data(Module.TextureIndex, 1);

    select_object_mesh(g_mesh_index_2);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_rotate_matrix_y(90);
    script_selected_mesh_rotate_matrix_x(g_current_rotation_x);
    script_selected_mesh_rotate_matrix_z(g_current_rotation_z);
    script_selected_mesh_translate_matrix(g_current_pos_x, g_current_pos_y, g_current_pos_z - 2);
    set_object_visual_data(Module.TextureIndex, 1);
end

function Module.reset_pos()
    Module.FramesToWait = rnd(50, 200);
    RestartBullet();
end

return Module;
