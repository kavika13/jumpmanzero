local read_only = require "Data/read_only";
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

local function AnimateArrow_(iPic)
    local is_reversed = false;

    if g_arrow_rotation > 90 and g_arrow_rotation < 270 then
        is_reversed = true;
    end

    select_picture(iPic);
    local SY = get_script_selected_level_object_y1();
    local SX = get_script_selected_level_object_x1();
    set_object_visual_data(resources.TextureUpDown, 1);

    local backdrop_mesh_index = find_backdrop_mesh_index(iPic);
    set_identity_mesh_matrix(backdrop_mesh_index);
    script_selected_mesh_translate_matrix(0 - SX, 0 - SY, 0);

    if is_reversed then
        rotate_z_mesh_matrix(backdrop_mesh_index, 180);
        rotate_y_mesh_matrix(backdrop_mesh_index, 180);
    end

    rotate_x_mesh_matrix(backdrop_mesh_index, g_arrow_rotation);
    script_selected_mesh_translate_matrix(SX, SY, 0);

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
        g_arrow_cooldown_frames[iPic] = 300;
    end
end

local function SpinPlatform_(iPlat, iPY)
    abs_platform(iPlat);
    local platform_mesh_index = get_platform_mesh_index(iPlat);
    set_identity_mesh_matrix(platform_mesh_index);

    if g_level_flipping_state == 1 then
        script_selected_mesh_translate_matrix(0, 0 - g_player_y_when_starting_flip, 0);
        rotate_x_mesh_matrix(platform_mesh_index, g_level_flipping_rotation * 180 / 50);
        script_selected_mesh_translate_matrix(0, iPY, 0);
    end

    if g_level_flipping_state == 3 then
        script_selected_mesh_translate_matrix(0, 0 - 80, 0);
        rotate_x_mesh_matrix(platform_mesh_index, 180);
        script_selected_mesh_translate_matrix(0, 80, 6);

        script_selected_mesh_translate_matrix(0, 0 - g_player_y_when_starting_flip, 0);
        rotate_x_mesh_matrix(platform_mesh_index, g_level_flipping_rotation * 180 / 50);
        script_selected_mesh_translate_matrix(0, iPY, 0);
    end
end

local function SpinLadderDonutOrVine_(mesh_index, iPY)
    set_identity_mesh_matrix(mesh_index);

    if g_level_flipping_state == 1 then
        script_selected_mesh_translate_matrix(0, 0 - g_player_y_when_starting_flip, 0);
        rotate_x_mesh_matrix(mesh_index, g_level_flipping_rotation * 180 / 50);
        script_selected_mesh_translate_matrix(0, iPY, 0);
    end

    if g_level_flipping_state == 3 then
        script_selected_mesh_translate_matrix(0, 0 - 80, 0);
        rotate_x_mesh_matrix(mesh_index, 180);
        script_selected_mesh_translate_matrix(0, 80, 2);

        script_selected_mesh_translate_matrix(0, 0 - g_player_y_when_starting_flip, 0);
        rotate_x_mesh_matrix(mesh_index, g_level_flipping_rotation * 180 / 50);
        script_selected_mesh_translate_matrix(0, iPY, 0);
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

    for iPlat = 0, get_platform_object_count() - 1 do
        SpinPlatform_(iPlat, iPY);
    end

    for iLadder = 0, get_ladder_object_count() - 1 do
        abs_ladder(iLadder);
        local ladder_mesh_index = get_ladder_mesh_index(iLadder);
        SpinLadderDonutOrVine_(ladder_mesh_index, iPY);
    end

    for iDonut = 0, get_donut_object_count() - 1 do
        abs_donut(iDonut);
        local donut_mesh_index = get_donut_mesh_index(iDonut);
        SpinLadderDonutOrVine_(donut_mesh_index, iPY);
    end

    for iVine = 0, get_vine_object_count() - 1 do
        abs_vine(iVine);
        local vine_mesh_index = get_vine_mesh_index(iVine);
        SpinLadderDonutOrVine_(vine_mesh_index, iPY);
    end
end

local function EnableLadder_(ladder_num)  -- Note: Not ladder_index
    select_ladder(ladder_num);
    set_script_selected_level_object_x1(0 - get_script_selected_level_object_x1());
    local ladder_mesh_index = find_ladder_mesh_index(ladder_num);
    set_identity_mesh_matrix(ladder_mesh_index);
end

local function ReversePlatform_(iObj)
    abs_platform(iObj);
    local platform_mesh_index = get_platform_mesh_index(iObj);
    set_identity_mesh_matrix(platform_mesh_index);

    if g_level_flipping_state == 2 then
        script_selected_mesh_translate_matrix(0, 0 - 80, 0);
        rotate_x_mesh_matrix(platform_mesh_index, 180);
        script_selected_mesh_translate_matrix(0, 80, 6);
    end

    if g_level_flipping_state == 2 then
        local SY = get_script_selected_level_object_y1();
        set_script_selected_level_object_y1(163 - SY);
        SY = get_script_selected_level_object_y2();
        set_script_selected_level_object_y2(163 - SY);
    else
        local SY = get_script_selected_level_object_y1();
        set_script_selected_level_object_y1(163 - SY);
        SY = get_script_selected_level_object_y2();
        set_script_selected_level_object_y2(163 - SY);
    end
end

local function ReverseDonut_(iObj)
    abs_donut(iObj);
    local donut_mesh_index = get_donut_mesh_index(iObj);
    set_identity_mesh_matrix(donut_mesh_index);

    if g_level_flipping_state == 2 then
        script_selected_mesh_translate_matrix(0, 0 - 80, 0);
        rotate_x_mesh_matrix(donut_mesh_index, 180);
        script_selected_mesh_translate_matrix(0, 80, 2);
    end

    local SY = get_script_selected_level_object_y1();
    set_script_selected_level_object_y1(160 - SY);
end

local function ReverseLadderOrVine_(mesh_index)
    set_identity_mesh_matrix(mesh_index);

    if g_level_flipping_state == 2 then
        script_selected_mesh_translate_matrix(0, 0 - 80, 0);
        rotate_x_mesh_matrix(mesh_index, 180);
        script_selected_mesh_translate_matrix(0, 80, 2);
    end

    local SY1 = get_script_selected_level_object_y1();
    local SY2 = get_script_selected_level_object_y2();
    set_script_selected_level_object_y1(160 - SY2);
    set_script_selected_level_object_y2(160 - SY1);
end

local function ReverseLevel_()
    local iPY = (160 - g_player_y_when_starting_flip) - kPLAYER_DROP_AFTER_FLIP;
    g_game_logic.set_player_current_position_y(iPY);

    for iObj = 0, get_platform_object_count() - 1 do
        ReversePlatform_(iObj);
    end

    for iObj = 0, get_ladder_object_count() - 1 do
        abs_ladder(iObj);
        local ladder_mesh_index = get_ladder_mesh_index(iObj);
        ReverseLadderOrVine_(ladder_mesh_index);
    end

    for iObj = 0, get_donut_object_count() - 1 do
        ReverseDonut_(iObj);
    end

    for iObj = 0, get_vine_object_count() - 1 do
        abs_vine(iObj);
        local vine_mesh_index = get_vine_mesh_index(iObj);
        ReverseLadderOrVine_(vine_mesh_index);
    end
end

local function DisableLadder_(ladder_num)  -- Note: Not ladder_index
    select_ladder(ladder_num);
    set_script_selected_level_object_x1(0 - get_script_selected_level_object_x1());
    script_selected_mesh_translate_matrix(0, 0 - 500, 0);
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

    for iArrow = 1, 2 do
        if g_arrow_cooldown_frames[iArrow] > 0 then
            g_arrow_cooldown_frames[iArrow] = g_arrow_cooldown_frames[iArrow] - 1;
            select_picture(iArrow);
            set_object_visual_data(resources.TextureUpDown, 0);
        else
            AnimateArrow_(iArrow);
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
                EnableLadder_(9);
            else
                g_level_flipping_state = 0;
            end

            ReverseLevel_();

            if g_level_flipping_state == 0 then
                DisableLadder_(9);
            end
        end
    end

    for _, bullet in ipairs(g_bullets) do
        bullet.update();
    end

    g_game_logic.update_player_graphics();
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.ResetPlayerCallback = reset;

    g_hud_overlay = hud_overlay_module();

    g_game_logic.set_level_extent_x(200);
    DisableLadder_(9);

    StartBullet_(500);
    StartBullet_(1000);
    StartBullet_(100);
    StartBullet_(30);

    for iArrow = 1, 2 do
        g_arrow_cooldown_frames[iArrow] = 0;
    end

    reset();

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

function update(game_input)
    if not g_title_is_done_scrolling then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return;
    end

    ProgressLevel_(game_input);
end

function reset()
    g_game_logic.set_player_current_position_x(80);
    g_game_logic.set_player_current_position_y(8);
    g_game_logic.set_player_current_position_z(9);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);

    for _, bullet in ipairs(g_bullets) do
        bullet.reset_pos();
    end
end
