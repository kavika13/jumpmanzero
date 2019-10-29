local read_only = require "Data/read_only";
local level_level17_module = assert(loadfile("Data/level_level17.lua"));
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local bullet_module = assert(loadfile("Data/bullet.lua"));

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

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureJumpman = 0,
    TextureClassicPlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    ScriptBullet = 0,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    TextureBullet = 5,
    TextureUpDown = 6,
};
resources = read_only.make_table_read_only(resources);

local kPLAYER_DROP_AFTER_FLIP = 12;

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_bullets = {};

local g_arrow_cooldown_frames = {};
local g_arrow_rotation = 0;

local g_level_flipping_state = 0;
local g_level_flipping_rotation = 0;
local g_level_flipping_pause_frames_remaining = 0;
local g_player_y_when_starting_flip = 0;

local function AnimateArrow_(backdrop_num)
    local is_reversed = false;

    if g_arrow_rotation > 90 and g_arrow_rotation < 270 then
        is_reversed = true;
    end

    local current_backdrop = g_game_logic.find_backdrop_by_number(backdrop_num);
    local SY = current_backdrop.pos[2];
    local SX = current_backdrop.pos[1];

    set_mesh_is_visible(current_backdrop.mesh_index, true);
    set_identity_mesh_matrix(current_backdrop.mesh_index);
    translate_mesh_matrix(current_backdrop.mesh_index, 0 - SX, 0 - SY, 0);

    if is_reversed then
        rotate_z_mesh_matrix(current_backdrop.mesh_index, 180);
        rotate_y_mesh_matrix(current_backdrop.mesh_index, 180);
    end

    rotate_x_mesh_matrix(current_backdrop.mesh_index, g_arrow_rotation);
    translate_mesh_matrix(current_backdrop.mesh_index, SX, SY, 0);

    if g_game_logic.is_player_colliding_with_rect(SX - 3, SY - 4, SX + 3, SY + 4) and
            (g_level_flipping_state == 0 or g_level_flipping_state == 2) then
        g_level_flipping_pause_frames_remaining = 25;
        g_game_logic.set_player_freeze_cooldown_frame_count(75);

        if g_level_flipping_state == 0 then
            g_level_flipping_state = 1;
        end

        if g_level_flipping_state == 2 then
            g_level_flipping_state = 3;
        end

        g_level_flipping_rotation = 0;
        g_player_y_when_starting_flip = g_game_logic.get_player_current_position_y();
        g_arrow_cooldown_frames[backdrop_num] = 300;
    end
end

local function SpinPlatform_(platform_index, iPY)
    local platform_mesh_index = g_game_logic.get_platform(platform_index).mesh_index;
    set_identity_mesh_matrix(platform_mesh_index);

    if g_level_flipping_state == 1 then
        translate_mesh_matrix(platform_mesh_index, 0, 0 - g_player_y_when_starting_flip, 0);
        rotate_x_mesh_matrix(platform_mesh_index, g_level_flipping_rotation * 180 / 50);
        translate_mesh_matrix(platform_mesh_index, 0, iPY, 0);
    end

    if g_level_flipping_state == 3 then
        translate_mesh_matrix(platform_mesh_index, 0, 0 - 80, 0);
        rotate_x_mesh_matrix(platform_mesh_index, 180);
        translate_mesh_matrix(platform_mesh_index, 0, 80, 6);

        translate_mesh_matrix(platform_mesh_index, 0, 0 - g_player_y_when_starting_flip, 0);
        rotate_x_mesh_matrix(platform_mesh_index, g_level_flipping_rotation * 180 / 50);
        translate_mesh_matrix(platform_mesh_index, 0, iPY, 0);
    end
end

local function SpinLadderDonutOrVine_(mesh_index, iPY)
    set_identity_mesh_matrix(mesh_index);

    if g_level_flipping_state == 1 then
        translate_mesh_matrix(mesh_index, 0, 0 - g_player_y_when_starting_flip, 0);
        rotate_x_mesh_matrix(mesh_index, g_level_flipping_rotation * 180 / 50);
        translate_mesh_matrix(mesh_index, 0, iPY, 0);
    end

    if g_level_flipping_state == 3 then
        translate_mesh_matrix(mesh_index, 0, 0 - 80, 0);
        rotate_x_mesh_matrix(mesh_index, 180);
        translate_mesh_matrix(mesh_index, 0, 80, 2);

        translate_mesh_matrix(mesh_index, 0, 0 - g_player_y_when_starting_flip, 0);
        rotate_x_mesh_matrix(mesh_index, g_level_flipping_rotation * 180 / 50);
        translate_mesh_matrix(mesh_index, 0, iPY, 0);
    end
end

local function SpinLevel_()
    local iNewY = 160 - g_player_y_when_starting_flip;
    iNewY = iNewY - kPLAYER_DROP_AFTER_FLIP;

    local iPY = 0;
    iPY = iPY + g_player_y_when_starting_flip * (50 - g_level_flipping_rotation) + iNewY * g_level_flipping_rotation;
    iPY = math.floor(iPY / 50) & 255;
    g_game_logic.set_player_current_position_y(iPY);

    iNewY = 160 - g_player_y_when_starting_flip;
    iPY = 0;
    iPY = iPY + g_player_y_when_starting_flip * (50 - g_level_flipping_rotation) + iNewY * g_level_flipping_rotation;
    iPY = math.floor(iPY / 50) & 255;

    for platform_index = 0, g_game_logic.get_platform_object_count() - 1 do
        SpinPlatform_(platform_index, iPY);
    end

    for ladder_index = 0, g_game_logic.get_ladder_object_count() - 1 do
        local ladder_mesh_index = g_game_logic.get_ladder(ladder_index).mesh_index;
        SpinLadderDonutOrVine_(ladder_mesh_index, iPY);
    end

    for donut_index = 0, g_game_logic.get_donut_object_count() - 1 do
        local current_donut = g_game_logic.get_donut(donut_index);
        SpinLadderDonutOrVine_(current_donut.mesh_index, iPY);
    end

    for vine_index = 0, g_game_logic.get_vine_object_count() - 1 do
        local vine_mesh_index = g_game_logic.get_vine(vine_index).mesh_index;
        SpinLadderDonutOrVine_(vine_mesh_index, iPY);
    end
end

local function EnableLadder_(ladder_num)
    local current_ladder = g_game_logic.find_ladder_by_number(ladder_num);
    current_ladder.set_pos_x(-current_ladder.pos_x);
    set_identity_mesh_matrix(current_ladder.mesh_index);
end

local function ReversePlatform_(platform_index)
    local current_platform = g_game_logic.get_platform(platform_index);
    set_identity_mesh_matrix(current_platform.mesh_index);

    if g_level_flipping_state == 2 then
        translate_mesh_matrix(current_platform.mesh_index, 0, 0 - 80, 0);
        rotate_x_mesh_matrix(current_platform.mesh_index, 180);
        translate_mesh_matrix(current_platform.mesh_index, 0, 80, 6);
    end

    -- TODO: Aren't these the exact same logic for both cases?
    -- TODO: Why are these 163, but for donuts, ladders, vines it is 160? Shouldn't they be consistent?
    if g_level_flipping_state == 2 then
        current_platform.set_pos_y(163 - current_platform.pos_lower_right[2], 163 - current_platform.pos_upper_left[2]);
    else
        current_platform.set_pos_y(163 - current_platform.pos_lower_right[2], 163 - current_platform.pos_upper_left[2]);
    end
end

local function ReverseDonut_(donut_index)
    local current_donut = g_game_logic.get_donut(donut_index);
    set_identity_mesh_matrix(current_donut.mesh_index);

    if g_level_flipping_state == 2 then
        translate_mesh_matrix(current_donut.mesh_index, 0, 0 - 80, 0);
        rotate_x_mesh_matrix(current_donut.mesh_index, 180);
        translate_mesh_matrix(current_donut.mesh_index, 0, 80, 2);
    end

    current_donut.set_pos_y(160 - current_donut.pos[2]);
end

local function ReverseLadder_(ladder_index)
    local current_ladder = g_game_logic.get_ladder(ladder_index);
    set_identity_mesh_matrix(current_ladder.mesh_index);

    if g_level_flipping_state == 2 then
        translate_mesh_matrix(current_ladder.mesh_index, 0, 0 - 80, 0);
        rotate_x_mesh_matrix(current_ladder.mesh_index, 180);
        translate_mesh_matrix(current_ladder.mesh_index, 0, 80, 2);
    end

    local old_y_bottom = current_ladder.pos_y_bottom;
    local old_y_top = current_ladder.pos_y_top;
    current_ladder.set_pos_y_bottom(160 - old_y_top);
    current_ladder.set_pos_y_top(160 - old_y_bottom);
end

local function ReverseVine_(vine_index)
    local current_vine = g_game_logic.get_vine(vine_index);
    set_identity_mesh_matrix(current_vine.mesh_index);

    if g_level_flipping_state == 2 then
        translate_mesh_matrix(current_vine.mesh_index, 0, 0 - 80, 0);
        rotate_x_mesh_matrix(current_vine.mesh_index, 180);
        translate_mesh_matrix(current_vine.mesh_index, 0, 80, 2);
    end

    local old_y_bottom = current_vine.pos_y_bottom;
    local old_y_top = current_vine.pos_y_top;
    current_vine.set_pos_y_bottom(160 - old_y_top);
    current_vine.set_pos_y_top(160 - old_y_bottom);
end

local function ReverseLevel_()
    local iPY = (160 - g_player_y_when_starting_flip) - kPLAYER_DROP_AFTER_FLIP;
    g_game_logic.set_player_current_position_y(iPY);

    for platform_index = 0, g_game_logic.get_platform_object_count() - 1 do
        ReversePlatform_(platform_index);
    end

    for ladder_index = 0, g_game_logic.get_ladder_object_count() - 1 do
        ReverseLadder_(ladder_index);
    end

    for donut_index = 0, g_game_logic.get_donut_object_count() - 1 do
        ReverseDonut_(donut_index);
    end

    for vine_index = 0, g_game_logic.get_vine_object_count() - 1 do
        ReverseVine_(vine_index);
    end
end

local function DisableLadder_(ladder_num)
    local current_ladder = g_game_logic.find_ladder_by_number(ladder_num);
    current_ladder.set_pos_x(-current_ladder.pos_x);
    translate_mesh_matrix(current_ladder.mesh_index, 0, 0 - 500, 0);
end

local function StartBullet_(frame_to_wait)
    local new_bullet = bullet_module();
    new_bullet.GameLogic = g_game_logic;
    new_bullet.FramesToWait = frame_to_wait;
    new_bullet.Mesh1Index = resources.MeshBullet1;
    new_bullet.Mesh2Index = resources.MeshBullet2;
    new_bullet.TextureIndex = resources.TextureBullet;
    new_bullet.FireSoundIndex = resources.SoundFire;
    new_bullet.initialize();
    table.insert(g_bullets, new_bullet);
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    g_arrow_rotation = g_arrow_rotation + 5;

    if g_arrow_rotation > 360 then
        g_arrow_rotation = 0;
    end

    for arrow_num = 1, 2 do  -- TODO: Use constant for num
        if g_arrow_cooldown_frames[arrow_num] > 0 then
            g_arrow_cooldown_frames[arrow_num] = g_arrow_cooldown_frames[arrow_num] - 1;
            local backdrop_mesh_index = g_game_logic.find_backdrop_by_number(arrow_num).mesh_index;
            set_mesh_is_visible(backdrop_mesh_index, false);
        else
            AnimateArrow_(arrow_num);
        end
    end

    if g_level_flipping_pause_frames_remaining > 0 then
        g_level_flipping_pause_frames_remaining = g_level_flipping_pause_frames_remaining - 1;
        return;
    end

    if g_level_flipping_state == 1 or g_level_flipping_state == 3 then
        g_level_flipping_rotation = g_level_flipping_rotation + 2;
        SpinLevel_();

        if g_level_flipping_rotation == 50 then
            if g_level_flipping_state == 1 then
                g_level_flipping_state = 2;
                EnableLadder_(9);  -- TODO: Use constant for num
            else
                g_level_flipping_state = 0;
            end

            ReverseLevel_();

            if g_level_flipping_state == 0 then
                DisableLadder_(9);  -- TODO: Use constant for num
            end
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
    g_game_logic.LevelData = level_level17_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.MenuLogic = Module.MenuLogic;
    g_hud_overlay.GameLogic = g_game_logic;

    g_game_logic.set_level_extent_x(200);
    DisableLadder_(9);  -- TODO: Use constant for num

    StartBullet_(500);
    StartBullet_(1000);
    StartBullet_(100);
    StartBullet_(30);

    for iArrow = 1, 2 do  -- TODO: Use constant for num
        g_arrow_cooldown_frames[iArrow] = 0;
    end

    Module.reset();

    -- Make sure staged initialization has happened, and Jumpman has floated to the floor
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);

    -- TODO: Apparently this level takes 10 updates to fully settle jumpman... maybe he should be repositioned...
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

function Module.reset()
    g_game_logic.set_player_current_position_x(80);
    g_game_logic.set_player_current_position_y(8);
    g_game_logic.set_player_current_position_z(9);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);

    for _, bullet in ipairs(g_bullets) do
        bullet.reset_pos();
    end
end

return Module;
