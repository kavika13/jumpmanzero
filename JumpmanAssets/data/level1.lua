local read_only = require "data/read_only";
local level1_data_module = assert(loadfile("data/level1_data.lua"));
local game_logic_module = assert(loadfile("data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("data/hud_overlay.lua"));
local bullet_module = assert(loadfile("data/bullet.lua"));

local Module = {};

Module.MenuLogic = nil;

-- TODO: Move this into a shared file, split into separate tables by type. Or inject from engine?
local player_state = {
    JSNORMAL = 0,
    JSJUMPING = 1,
    JSRIGHT = 2,
    JSLEFT = 4,
    JSFALLING = 8,
    JSLADDER = 16,
    JSKICK = 32,
    JSROLL = 64,
    JSPUNCH = 128,
    JSDYING = 256,
    JSVINE = 1024,
};
player_state = read_only.make_table_read_only(player_state);

-- TODO: Move this into a shared file, split into separate tables by type
local camera_mode = {
    PerspectiveNormal = 0,
    PerspectiveCloseUp = 1,
    PerspectiveFar = 2,
    PerspectiveWide = 3,
    PerspectiveFollow = 4,
    PerspectiveFixed = 5,
};
camera_mode = read_only.make_table_read_only(camera_mode);

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureJumpman = 0,
    TextureClassicPlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureBullet = 4,
    TextureSky = 5,
    ScriptBullet = 0,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
};
resources = read_only.make_table_read_only(resources);

local kLADDER_ANIMATION_FRAME_STEP = 1;
local kTRAP_DOOR_ANIMATION_FRAME_STEP = 3;

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_bullets = {};

local g_is_left_trap_door_moving = false;
local g_left_trap_door_animation_frame = 0;

local g_is_right_trap_door_moving = false;
local g_right_trap_door_animation_frame = 0;

local g_is_left_ladder_moving = false;
local g_left_ladder_animation_frame = 0;

local g_is_right_ladder_moving = false;
local g_right_ladder_animation_frame = 0;

local function MoveLadder_(ladder_num, iPos)
    local current_ladder = g_game_logic.find_ladder_by_number(ladder_num);
    local iX = current_ladder.pos_x + 508;
    local iY = (current_ladder.pos_y_bottom + current_ladder.pos_y_top) / 2;
    local iZ = current_ladder.pos_z[1];

    set_identity_mesh_matrix(current_ladder.mesh_index);
    translate_mesh_matrix(current_ladder.mesh_index, 0 - iX, 0 - iY, 0 - iZ);
    rotate_z_mesh_matrix(current_ladder.mesh_index, iPos * 2);
    rotate_x_mesh_matrix(current_ladder.mesh_index, iPos);
    translate_mesh_matrix(current_ladder.mesh_index, iX, iY, iZ - iPos);
    skip_next_mesh_interpolation(current_ladder.mesh_index);
end

local function MovePlatform_(platform_num, iRotate, iTran, pos_property_name)
    local current_platform = g_game_logic.find_platform_by_number(platform_num);
    local iPlatX = current_platform[pos_property_name][1];
    local iPlatY = current_platform[pos_property_name][2];

    set_identity_mesh_matrix(current_platform.mesh_index);
    translate_mesh_matrix(current_platform.mesh_index, 0 - iPlatX, 0 - iPlatY, 0);
    rotate_z_mesh_matrix(current_platform.mesh_index, iRotate);
    translate_mesh_matrix(current_platform.mesh_index, iPlatX + iTran, iPlatY, 0);
    skip_next_mesh_interpolation(current_platform.mesh_index);
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    if g_is_left_trap_door_moving then
        g_left_trap_door_animation_frame = g_left_trap_door_animation_frame + kTRAP_DOOR_ANIMATION_FRAME_STEP;

        -- TODO: Use constant for num
        MovePlatform_(1, 0 - g_left_trap_door_animation_frame, 1, "pos_upper_left");
        MovePlatform_(2, g_left_trap_door_animation_frame, 0 - 1, "pos_lower_right");
        -- TODO: There is an engine function for this, but it is not exposed. Seems to be automatically called?
        -- setext(#compose, 1);

        if g_left_trap_door_animation_frame > 56 then
            g_is_left_trap_door_moving = false;

            local current_platform = g_game_logic.find_platform_by_number(1);  -- TODO: Use constant for num
            current_platform.set_pos_y(500, 500);

            current_platform = g_game_logic.find_platform_by_number(2);  -- TODO: Use constant for num
            current_platform.set_pos_y(500, 500);
        end
    end

    if g_is_right_trap_door_moving then
        g_right_trap_door_animation_frame = g_right_trap_door_animation_frame + kTRAP_DOOR_ANIMATION_FRAME_STEP;

        -- TODO: Use constant for num
        MovePlatform_(3, 0 - g_right_trap_door_animation_frame, 1, "pos_upper_left");
        MovePlatform_(4, g_right_trap_door_animation_frame, 0 - 1, "pos_lower_right");
        -- TODO: There is an engine function for this, but it is not exposed. Seems to be automatically called?
        -- setext(#compose, 1);

        if g_right_trap_door_animation_frame > 56 then
            g_right_trap_door_animation_frame = 56;
            g_is_right_trap_door_moving = false;

            local current_platform = g_game_logic.find_platform_by_number(3);  -- TODO: Use constant for num
            current_platform.set_pos_y(500, 500);

            current_platform = g_game_logic.find_platform_by_number(4);  -- TODO: Use constant for num
            current_platform.set_pos_y(500, 500);
        end
    end

    if g_is_left_ladder_moving then
        g_left_ladder_animation_frame = g_left_ladder_animation_frame + kLADDER_ANIMATION_FRAME_STEP;

        MoveLadder_(1, g_left_ladder_animation_frame);  -- TODO: Use constant for num
        -- TODO: There is an engine function for this, but it is not exposed. Seems to be automatically called?
        -- setext(#compose, 1);

        if g_left_ladder_animation_frame == 80 then
            g_is_left_ladder_moving = false;
            local mesh_index = g_game_logic.find_ladder_by_number(1).mesh_index;  -- TODO: Use constant for num
            translate_mesh_matrix(mesh_index, 1000, 0, 0);
        end
    end

    if g_is_right_ladder_moving then
        g_right_ladder_animation_frame = g_right_ladder_animation_frame + kLADDER_ANIMATION_FRAME_STEP;

        MoveLadder_(2, g_right_ladder_animation_frame);  -- TODO: Use constant for num
        -- TODO: There is an engine function for this, but it is not exposed. Seems to be automatically called?
        -- setext(#compose, 1);

        if g_right_ladder_animation_frame == 80 then
            g_is_right_ladder_moving = false;
            local mesh_index = g_game_logic.find_ladder_by_number(2).mesh_index;  -- TODO: Use constant for num
            translate_mesh_matrix(mesh_index, 1000, 0, 0);
        end
    end

    for _, bullet in ipairs(g_bullets) do
        bullet.update();
    end

    g_game_logic.update_player_graphics();
end

function Module.initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = level1_data_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.OnCollectDonutCallback = Module.on_collect_donut;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.MenuLogic = Module.MenuLogic;
    g_hud_overlay.GameLogic = g_game_logic;

    local iTemp = bullet_module();
    iTemp.GameLogic = g_game_logic;
    iTemp.FramesToWait = 100;
    iTemp.Mesh1Index = resources.MeshBullet1;
    iTemp.Mesh2Index = resources.MeshBullet2;
    iTemp.TextureIndex = resources.TextureBullet;
    iTemp.FireSoundIndex = resources.SoundFire;
    iTemp.initialize();
    table.insert(g_bullets, iTemp);

    iTemp = bullet_module();
    iTemp.GameLogic = g_game_logic;
    iTemp.FramesToWait = 30;
    iTemp.Mesh1Index = resources.MeshBullet1;
    iTemp.Mesh2Index = resources.MeshBullet2;
    iTemp.TextureIndex = resources.TextureBullet;
    iTemp.FireSoundIndex = resources.SoundFire;
    iTemp.initialize();
    table.insert(g_bullets, iTemp);

    Module.reset();

    -- Make sure staged initialization has happened, and Jumpman has floated to the floor
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
end

function Module.update(game_input)
    if not g_title_is_done_scrolling then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return;
    end

    ProgressLevel_(game_input);
end

function Module.pre_draw(seconds_per_update_timestep, seconds_since_previous_update, time_scale)
    if player_won then
        return false;
    end

    local interpolation_scale = time_scale * seconds_since_previous_update / seconds_per_update_timestep;

    if g_is_left_trap_door_moving then
        -- TODO: Use constant for num
        MovePlatform_(1, 0 - (g_left_trap_door_animation_frame + interpolation_scale * kTRAP_DOOR_ANIMATION_FRAME_STEP), 1, "pos_upper_left");
        MovePlatform_(2, g_left_trap_door_animation_frame + interpolation_scale * kTRAP_DOOR_ANIMATION_FRAME_STEP, 0 - 1, "pos_lower_right");
    end

    if g_is_right_trap_door_moving then
        -- TODO: Use constant for num
        MovePlatform_(3, 0 - (g_right_trap_door_animation_frame + interpolation_scale * kTRAP_DOOR_ANIMATION_FRAME_STEP), 1, "pos_upper_left");
        MovePlatform_(4, g_right_trap_door_animation_frame + interpolation_scale * kTRAP_DOOR_ANIMATION_FRAME_STEP, 0 - 1, "pos_lower_right");
    end

    if g_is_left_ladder_moving then
        MoveLadder_(1, g_left_ladder_animation_frame + interpolation_scale * kLADDER_ANIMATION_FRAME_STEP);  -- TODO: Use constant for num
    end

    if g_is_right_ladder_moving then
        MoveLadder_(2, g_right_ladder_animation_frame + interpolation_scale * kLADDER_ANIMATION_FRAME_STEP);  -- TODO: Use constant for num
    end

    return false;  -- TODO: Should this ever be returned true?
end

function Module.on_collect_donut(game_input, donut_num)
    if donut_num == 1 then  -- TODO: Use constant for num
        g_is_left_trap_door_moving = true;
        iPosition1 = 0;
    end

    if donut_num == 2 then  -- TODO: Use constant for num
        g_is_right_trap_door_moving = true;
        iPosition2 = 0;
    end

    if donut_num == 3 then  -- TODO: Use constant for num
        g_is_left_ladder_moving = true;
        iPosition3 = 0;
        local current_ladder = g_game_logic.find_ladder_by_number(1);  -- TODO: Use constant for num
        current_ladder.set_pos_x(current_ladder.pos_x - 500);
    end

    if donut_num == 4 then  -- TODO: Use constant for num
        g_is_right_ladder_moving = true;
        iPosition4 = 0;
        local current_ladder = g_game_logic.find_ladder_by_number(2);  -- TODO: Use constant for num
        current_ladder.set_pos_x(current_ladder.pos_x - 500);
    end
end

function Module.reset()
    g_game_logic.set_player_current_position_x(80);
    g_game_logic.set_player_current_position_y(65);
    g_game_logic.set_player_current_position_z(9);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);

    for _, bullet in ipairs(g_bullets) do
        bullet.reset_pos();
    end
end

return Module;
