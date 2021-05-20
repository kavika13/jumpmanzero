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

local g_player_won = false;
local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_bullets = {};

local g_is_left_trap_door_moving = false;
local g_left_trap_door_platforms = nil;
local g_left_trap_door_platform_transform_indices = nil;
local g_left_trap_door_animation_frame = 0;

local g_is_right_trap_door_moving = false;
local g_right_trap_door_platforms = nil;
local g_right_trap_door_platform_transform_indices = nil;
local g_right_trap_door_animation_frame = 0;

local g_is_left_ladder_moving = false;
local g_left_ladder = nil;
local g_left_ladder_transform_indices = {};
local g_left_ladder_animation_frame = 0;

local g_is_right_ladder_moving = false;
local g_right_ladder = nil;
local g_right_ladder_transform_indices = {};
local g_right_ladder_animation_frame = 0;

local function MoveLadder_(current_ladder, iPos, ladder_transform_indices)
    local iX = current_ladder.pos_x + 508;
    local iY = (current_ladder.pos_y_bottom + current_ladder.pos_y_top) / 2;
    local iZ = current_ladder.pos_z[1];

    transform_set_translation(ladder_transform_indices[1], 0 - iX, 0 - iY, 0 - iZ);
    transform_set_rotation_z(ladder_transform_indices[1], iPos * 2);
    transform_concat_rotation_x(ladder_transform_indices[1], iPos);
    transform_set_translation(ladder_transform_indices[2], iX, iY, iZ - iPos);
end

local function MovePlatform_(current_platform, iRotate, iTran, pos_property_name, platform_transform_indices)
    local iPlatX = current_platform[pos_property_name][1];
    local iPlatY = current_platform[pos_property_name][2];

    transform_set_translation(platform_transform_indices[1], 0 - iPlatX, 0 - iPlatY, 0);
    transform_set_rotation_z(platform_transform_indices[1], iRotate);
    transform_set_translation(platform_transform_indices[2], iPlatX + iTran, iPlatY, 0);
end

local function ProgressLevel_(game_input)
    g_player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if g_player_won then
        return;
    end

    if g_is_left_trap_door_moving then
        g_left_trap_door_animation_frame = g_left_trap_door_animation_frame + kTRAP_DOOR_ANIMATION_FRAME_STEP;

        MovePlatform_(g_left_trap_door_platforms[1], 0 - g_left_trap_door_animation_frame, 1, "pos_upper_left", g_left_trap_door_platform_transform_indices[1]);
        MovePlatform_(g_left_trap_door_platforms[2], g_left_trap_door_animation_frame, 0 - 1, "pos_lower_right", g_left_trap_door_platform_transform_indices[2]);

        if g_left_trap_door_animation_frame > 56 then
            g_is_left_trap_door_moving = false;
            g_left_trap_door_platforms[1].set_pos_y(500, 500);
            g_left_trap_door_platforms[2].set_pos_y(500, 500);
        end
    end

    if g_is_right_trap_door_moving then
        g_right_trap_door_animation_frame = g_right_trap_door_animation_frame + kTRAP_DOOR_ANIMATION_FRAME_STEP;

        MovePlatform_(g_right_trap_door_platforms[1], 0 - g_right_trap_door_animation_frame, 1, "pos_upper_left", g_right_trap_door_platform_transform_indices[1]);
        MovePlatform_(g_right_trap_door_platforms[2], g_right_trap_door_animation_frame, 0 - 1, "pos_lower_right", g_right_trap_door_platform_transform_indices[2]);

        if g_right_trap_door_animation_frame > 56 then
            g_right_trap_door_animation_frame = 56;
            g_is_right_trap_door_moving = false;
            g_right_trap_door_platforms[1].set_pos_y(500, 500);
            g_right_trap_door_platforms[2].set_pos_y(500, 500);
        end
    end

    if g_is_left_ladder_moving then
        g_left_ladder_animation_frame = g_left_ladder_animation_frame + kLADDER_ANIMATION_FRAME_STEP;

        MoveLadder_(g_left_ladder, g_left_ladder_animation_frame, g_left_ladder_transform_indices);

        if g_left_ladder_animation_frame == 80 then
            g_is_left_ladder_moving = false;
            set_mesh_is_visible(g_left_ladder.mesh_index, false);
        end
    end

    if g_is_right_ladder_moving then
        g_right_ladder_animation_frame = g_right_ladder_animation_frame + kLADDER_ANIMATION_FRAME_STEP;

        MoveLadder_(g_right_ladder, g_right_ladder_animation_frame, g_right_ladder_transform_indices);

        if g_right_ladder_animation_frame == 80 then
            g_is_right_ladder_moving = false;
            set_mesh_is_visible(g_right_ladder.mesh_index, false);
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

    local setup_object_two_transforms = function(mesh_index)
        local result = { transform_create(), transform_create() };
        object_set_transform(mesh_index, result[1]);
        transform_set_parent(result[1], result[2]);
        return result;
    end

    g_left_ladder = g_game_logic.find_ladder_by_number(1);  -- TODO: Use constant for num
    g_right_ladder = g_game_logic.find_ladder_by_number(2);  -- TODO: Use constant for num
    g_left_ladder_transform_indices = setup_object_two_transforms(g_left_ladder.mesh_index);
    g_right_ladder_transform_indices = setup_object_two_transforms(g_right_ladder.mesh_index);

    g_left_trap_door_platforms = {
        g_game_logic.find_platform_by_number(1),  -- TODO: Use constant for num
        g_game_logic.find_platform_by_number(2),  -- TODO: Use constant for num
    };
    g_right_trap_door_platforms = {
        g_game_logic.find_platform_by_number(3),  -- TODO: Use constant for num
        g_game_logic.find_platform_by_number(4),  -- TODO: Use constant for num
    };
    g_left_trap_door_platform_transform_indices = {
        setup_object_two_transforms(g_left_trap_door_platforms[1].mesh_index),
        setup_object_two_transforms(g_left_trap_door_platforms[2].mesh_index),
    };
    g_right_trap_door_platform_transform_indices = {
        setup_object_two_transforms(g_right_trap_door_platforms[1].mesh_index),
        setup_object_two_transforms(g_right_trap_door_platforms[2].mesh_index),
    };

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
        g_left_ladder.set_pos_x(g_left_ladder.pos_x - 500);
    end

    if donut_num == 4 then  -- TODO: Use constant for num
        g_is_right_ladder_moving = true;
        iPosition4 = 0;
        g_right_ladder.set_pos_x(g_right_ladder.pos_x - 500);
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
