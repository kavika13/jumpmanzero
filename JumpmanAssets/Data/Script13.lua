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
    ScriptGoo = 0,
    TextureJumpman = 0,
    TextureInvisible = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureCrazySky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    TextureStone = 5,
    TextureClassicPlatform = 6,
    ScriptBullet = 1,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    TextureBullet = 7,
};
resources = read_only.make_table_read_only(resources);

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_bullets = {};

local g_visibility_bitmask;
local g_visibility_change_frames_left = 0;
local g_background_rotation = 0;

local function RotateBack_()
    g_background_rotation = g_background_rotation - 0.5;

    for iBackdropNum = 200, 203 do  -- TODO: Use constants
        select_picture(iBackdropNum);
        local backdrop_mesh_index = find_backdrop_mesh_index(iBackdropNum);
        set_identity_mesh_matrix(backdrop_mesh_index);
        translate_mesh_matrix(backdrop_mesh_index, -80, -40, 0);
        scale_mesh_matrix(backdrop_mesh_index, 1.1, 1.1, 1);
        rotate_z_mesh_matrix(backdrop_mesh_index, g_background_rotation);
        translate_mesh_matrix(backdrop_mesh_index, 80, 40, 0);
    end
end

local function SetConfig_()
    for iLoop = 256, 264, 2 do
        local iRnd = math.random(0, 1000) < 500;
        local mesh_index;

        if iRnd then
            select_platform(iLoop + 1);
            set_script_selected_level_object_number(iLoop - 251);
            select_platform(iLoop);
            mesh_index = find_platform_mesh_index(iLoop);
        else
            select_platform(iLoop);
            set_script_selected_level_object_number(iLoop - 247);
            select_platform(iLoop + 1);
            mesh_index = find_platform_mesh_index(iLoop + 1);
        end

        set_script_selected_level_object_y1(500);
        set_script_selected_level_object_y2(500);
        translate_mesh_matrix(mesh_index, 0, 0, 2000);
    end
end

local function ResetVisible_(visibility_bitmask)
    for platform_index = 0, get_platform_object_count() - 1 do
        abs_platform(platform_index);
        local iPlat = get_script_selected_level_object_number();
        local mesh_index = get_platform_mesh_index(platform_index);

        if (iPlat & visibility_bitmask) ~= 0 then
            set_texture_and_is_visible_on_mesh(mesh_index, resources.TextureClassicPlatform, 1);
        else
            set_texture_and_is_visible_on_mesh(mesh_index, resources.TextureInvisible, 1);
        end
    end

    for ladder_index = 0, get_ladder_object_count() - 1 do
        abs_ladder(ladder_index);
        local iPlat = get_script_selected_level_object_number();
        local mesh_index = get_ladder_mesh_index(ladder_index);

        if (iPlat & visibility_bitmask) ~= 0 then
            set_texture_and_is_visible_on_mesh(mesh_index, resources.TextureBlueMarble, 1);
        else
            set_texture_and_is_visible_on_mesh(mesh_index, resources.TextureInvisible, 1);
        end
    end

    for vine_index = 0, get_vine_object_count() - 1 do
        abs_vine(vine_index);
        local iPlat = get_script_selected_level_object_number();
        local mesh_index = get_vine_mesh_index(vine_index);

        if (iPlat & visibility_bitmask) ~= 0 then
            set_texture_and_is_visible_on_mesh(mesh_index, resources.TextureBlueMarble, 1);
        else
            set_texture_and_is_visible_on_mesh(mesh_index, resources.TextureInvisible, 1);
        end
    end

    for donut_index = 0, get_donut_object_count() - 1 do
        abs_donut(donut_index);
        local iPlat = get_script_selected_level_object_number();
        local mesh_index = get_donut_mesh_index(donut_index);

        -- TODO: Does this just want to set the texture? Should it do just that instead?
        if visibility_bitmask == 1 then
            set_texture_and_is_visible_on_mesh(mesh_index, resources.TextureInvisible, g_game_logic.get_donut_is_collected(donut_index) and 0 or 1);
        else
            set_texture_and_is_visible_on_mesh(mesh_index, resources.TextureRedMetal, g_game_logic.get_donut_is_collected(donut_index) and 0 or 1);
        end
    end
end

function NextNum_(iMove)
    if iMove == 255 then
        -- Original code set g_visibility_bitmask = 1 here, like is currently being done
        -- This guarantees the donuts always flash after a death on first donut grab, but I *think* they will never disappear after that flash?
        -- Otherwise they only blink every 6th donut grab without dying (and *can* disappear at that time)

        -- TODO: Maybe they should have a chance of disppearing on first grab after reset, or always disappear on reset?
        g_visibility_bitmask = 1;
    end

    iMove = iMove * 2;

    if iMove == 64 then
        iMove = 1;
    end

    return iMove;
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    if g_visibility_change_frames_left > 0 then
        g_visibility_change_frames_left = g_visibility_change_frames_left - 1;

        if math.random(1, 30) < g_visibility_change_frames_left then
            ResetVisible_(g_visibility_bitmask);
        else
            local iTemp = NextNum_(g_visibility_bitmask);
            ResetVisible_(iTemp);
        end

        if g_visibility_change_frames_left == 0 then
            g_visibility_bitmask = NextNum_(g_visibility_bitmask);
            ResetVisible_(g_visibility_bitmask);
        end
    end

    RotateBack_();

    for _, bullet in ipairs(g_bullets) do
        bullet.update();
    end

    g_game_logic.update_player_graphics();
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.ResetPlayerCallback = reset;
    g_game_logic.OnCollectDonutCallback = on_collect_donut;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();

    local iTemp = bullet_module();
    iTemp.GameLogic = g_game_logic;
    iTemp.FramesToWait = 300;
    iTemp.Mesh1Index = resources.MeshBullet1;
    iTemp.Mesh2Index = resources.MeshBullet2;
    iTemp.TextureIndex = resources.TextureBullet;
    iTemp.FireSoundIndex = resources.SoundFire;
    iTemp.initialize();
    table.insert(g_bullets, iTemp);

    SetConfig_();
    g_visibility_bitmask = 1;  -- Guarantee on first start that donuts are invisible
    ResetVisible_(g_visibility_bitmask);

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

function on_collect_donut()
    g_visibility_change_frames_left = 30;
end

function reset()
    g_visibility_bitmask = 255;
    ResetVisible_(g_visibility_bitmask);
    g_game_logic.set_player_current_position_x(68);
    g_game_logic.set_player_current_position_y(81);
    g_game_logic.set_player_current_position_z(9);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);

    for _, bullet in ipairs(g_bullets) do
        bullet.reset_pos();
    end
end
