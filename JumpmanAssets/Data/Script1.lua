local read_only = require "Data/read_only";
local level1_data_module = assert(loadfile("Data/level_level1.lua"));
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local bullet_module = assert(loadfile("Data/bullet.lua"));

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

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_bullets = {};

local g_is_object_1_moving = false;
local g_object_1_animation_frame = 0;

local g_is_object_2_moving = false;
local g_object_2_animation_frame = 0;

local g_is_object_3_moving = false;
local g_object_3_animation_frame = 0;

local g_is_object_4_moving = false;
local g_object_4_animation_frame = 0;

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
end

local function MovePlatform_(platform_num, iRotate, iTran, get_platform_x_value, get_platform_y_value)
    local platform_index = find_platform_index(platform_num);
    local iPlatX = get_platform_x_value(platform_index);
    local iPlatY = get_platform_y_value(platform_index);

    local platform_mesh_index = find_platform_mesh_index(platform_num);
    set_identity_mesh_matrix(platform_mesh_index);
    translate_mesh_matrix(platform_mesh_index, 0 - iPlatX, 0 - iPlatY, 0);
    rotate_z_mesh_matrix(platform_mesh_index, iRotate);
    translate_mesh_matrix(platform_mesh_index, iPlatX + iTran, iPlatY, 0);
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    if g_is_object_1_moving then
        g_object_1_animation_frame = g_object_1_animation_frame + 3;

        -- TODO: Use constant for num
        MovePlatform_(1, 0 - g_object_1_animation_frame, 1, get_platform_x1, get_platform_y1);
        MovePlatform_(2, g_object_1_animation_frame, 0 - 1, get_platform_x2, get_platform_y2);
        -- TODO: There is an engine function for this, but it is not exposed. Seems to be automatically called?
        -- setext(#compose, 1);

        if g_object_1_animation_frame > 56 then
            g_is_object_1_moving = false;

            local platform_index = find_platform_index(1);  -- TODO: Use constant for num
            set_platform_y1(platform_index, 500);
            set_platform_y2(platform_index, 500);

            platform_index = find_platform_index(2);  -- TODO: Use constant for num
            set_platform_y1(platform_index, 500);
            set_platform_y2(platform_index, 500);
        end
    end

    if g_is_object_2_moving then
        g_object_2_animation_frame = g_object_2_animation_frame + 3;

        -- TODO: Use constant for num
        MovePlatform_(3, 0 - g_object_2_animation_frame, 1, get_platform_x1, get_platform_y1);
        MovePlatform_(4, g_object_2_animation_frame, 0 - 1, get_platform_x2, get_platform_y2);
        -- TODO: There is an engine function for this, but it is not exposed. Seems to be automatically called?
        -- setext(#compose, 1);

        if g_object_2_animation_frame > 56 then
            g_object_2_animation_frame = 56;
            g_is_object_2_moving = false;

            local platform_index = find_platform_index(3);  -- TODO: Use constant for num
            set_platform_y1(platform_index, 500);
            set_platform_y2(platform_index, 500);

            platform_index = find_platform_index(4);  -- TODO: Use constant for num
            set_platform_y1(platform_index, 500);
            set_platform_y2(platform_index, 500);
        end
    end

    if g_is_object_3_moving then
        g_object_3_animation_frame = g_object_3_animation_frame + 1;

        MoveLadder_(1, g_object_3_animation_frame);  -- TODO: Use constant for num
        -- TODO: There is an engine function for this, but it is not exposed. Seems to be automatically called?
        -- setext(#compose, 1);

        if g_object_3_animation_frame == 80 then
            g_is_object_3_moving = false;
            local mesh_index = g_game_logic.find_ladder_by_number(1).mesh_index;  -- TODO: Use constant for num
            translate_mesh_matrix(mesh_index, 1000, 0, 0);
        end
    end

    if g_is_object_4_moving then
        g_object_4_animation_frame = g_object_4_animation_frame + 1;

        MoveLadder_(2, g_object_4_animation_frame);  -- TODO: Use constant for num
        -- TODO: There is an engine function for this, but it is not exposed. Seems to be automatically called?
        -- setext(#compose, 1);

        if g_object_4_animation_frame == 80 then
            g_is_object_4_moving = false;
            local mesh_index = g_game_logic.find_ladder_by_number(2).mesh_index;  -- TODO: Use constant for num
            translate_mesh_matrix(mesh_index, 1000, 0, 0);
        end
    end

    for _, bullet in ipairs(g_bullets) do
        bullet.update();
    end

    g_game_logic.update_player_graphics();
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.LevelData = level1_data_module();
    g_game_logic.ResetPlayerCallback = reset;
    g_game_logic.OnCollectDonutCallback = on_collect_donut;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();

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

    reset();

    -- Make sure staged initialization has happened, and Jumpman has floated to the floor
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
end

function update(game_input)
    if not g_title_is_done_scrolling then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return;
    end

    ProgressLevel_(game_input);
end

function on_collect_donut(game_input, donut_num)
    if donut_num == 1 then  -- TODO: Use constant for num
        g_is_object_1_moving = true;
        iPosition1 = 0;
    end

    if donut_num == 2 then  -- TODO: Use constant for num
        g_is_object_2_moving = true;
        iPosition2 = 0;
    end

    if donut_num == 3 then  -- TODO: Use constant for num
        g_is_object_3_moving = true;
        iPosition3 = 0;
        local current_ladder = g_game_logic.find_ladder_by_number(1);  -- TODO: Use constant for num
        current_ladder.set_pos_x(current_ladder.pos_x - 500);
    end

    if donut_num == 4 then  -- TODO: Use constant for num
        g_is_object_4_moving = true;
        iPosition4 = 0;
        local current_ladder = g_game_logic.find_ladder_by_number(2);  -- TODO: Use constant for num
        current_ladder.set_pos_x(current_ladder.pos_x - 500);
    end
end

function reset()
    g_game_logic.set_player_current_position_x(80);
    g_game_logic.set_player_current_position_y(65);
    g_game_logic.set_player_current_position_z(9);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);

    for _, bullet in ipairs(g_bullets) do
        bullet.reset_pos();
    end
end
