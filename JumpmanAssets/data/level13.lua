local read_only = require "data/read_only";
local level13_data_module = assert(loadfile("data/level13_data.lua"));
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

local kBACKGROUND_ANIMATION_FRAME_STEP = -0.5;
local kROTATING_BACKDROP_COUNT = 4;

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_bullets = {};

local g_rotating_backdrops_transform_indices = {};

local g_visibility_bitmask;
local g_visibility_change_frames_left = 0;
local g_background_rotation = 0;

local function RotateBack_(background_rotation)
    for backdrop_num = 1, kROTATING_BACKDROP_COUNT do
        transform_set_translation(g_rotating_backdrops_transform_indices[backdrop_num][1], -80, -40, 0);
        transform_set_scale(g_rotating_backdrops_transform_indices[backdrop_num][2], 1.1, 1.1, 1);
        transform_set_rotation_z(g_rotating_backdrops_transform_indices[backdrop_num][2], background_rotation);
        transform_set_translation(g_rotating_backdrops_transform_indices[backdrop_num][2], 80, 40, 0);
    end
end

local function SetConfig_()
    for platform_base_num = 256, 264, 2 do  -- TODO: Use constant for num
        local is_coin_flip_heads = math.random(0, 1000) < 500;
        local platform_to_hide;

        if is_coin_flip_heads then
            g_game_logic.find_platform_by_number(platform_base_num + 1).set_number(platform_base_num - 251);
            platform_to_hide = g_game_logic.find_platform_by_number(platform_base_num);
        else
            g_game_logic.find_platform_by_number(platform_base_num).set_number(platform_base_num - 247);
            platform_to_hide = g_game_logic.find_platform_by_number(platform_base_num + 1);
        end

        platform_to_hide.set_pos_y(500, 500);
        local transform_index = transform_create();
        mesh_set_transform(platform_to_hide.mesh_index, transform_index);
        transform_set_translation(transform_index, 0, 0, 2000);  -- Can't just set_mesh_is_visible because it will be undone by ResetVisible_
    end
end

local function ResetVisible_(visibility_bitmask)
    for platform_index = 0, g_game_logic.get_platform_object_count() - 1 do
        local current_platform = g_game_logic.get_platform(platform_index);

        if (current_platform.number & visibility_bitmask) ~= 0 then
            set_mesh_is_visible(current_platform.mesh_index, true);
        else
            set_mesh_is_visible(current_platform.mesh_index, false);
        end
    end

    for ladder_index = 0, g_game_logic.get_ladder_object_count() - 1 do
        local current_ladder = g_game_logic.get_ladder(ladder_index);

        if (current_ladder.number & visibility_bitmask) ~= 0 then
            set_mesh_is_visible(current_ladder.mesh_index, true);
        else
            set_mesh_is_visible(current_ladder.mesh_index, false);
        end
    end

    for vine_index = 0, g_game_logic.get_vine_object_count() - 1 do
        local current_vine = g_game_logic.get_vine(vine_index);

        if (current_vine.number & visibility_bitmask) ~= 0 then
            set_mesh_is_visible(current_vine.mesh_index, true);
        else
            set_mesh_is_visible(current_vine.mesh_index, false);
        end
    end

    for donut_index = 0, g_game_logic.get_donut_object_count() - 1 do
        local current_donut = g_game_logic.get_donut(donut_index);

        if visibility_bitmask == 1 or g_game_logic.get_donut_is_collected(donut_index) then
            set_mesh_is_visible(current_donut.mesh_index, false);
        else
            set_mesh_is_visible(current_donut.mesh_index, true);
        end
    end
end

local function NextNum_(iMove)
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

    g_background_rotation = g_background_rotation + kBACKGROUND_ANIMATION_FRAME_STEP;
    RotateBack_(g_background_rotation);

    for _, bullet in ipairs(g_bullets) do
        bullet.update();
    end

    g_game_logic.update_player_graphics();
end

function Module.initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = level13_data_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.OnCollectDonutCallback = Module.on_collect_donut;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.MenuLogic = Module.MenuLogic;
    g_hud_overlay.GameLogic = g_game_logic;

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

    for platform_index = 0, g_game_logic.get_platform_object_count() - 1 do
        set_mesh_texture(g_game_logic.get_platform(platform_index).mesh_index, resources.TextureClassicPlatform);
    end

    local setup_object_two_transforms = function(mesh_index)
        local result = { transform_create(), transform_create() };
        mesh_set_transform(mesh_index, result[1]);
        transform_set_parent(result[1], result[2]);
        return result;
    end

    for backdrop_num = 200, 200 + kROTATING_BACKDROP_COUNT - 1 do  -- TODO: Use constant for num
        local backdrop_mesh_index = g_game_logic.find_backdrop_by_number(backdrop_num).mesh_index;
        table.insert(g_rotating_backdrops_transform_indices, setup_object_two_transforms(backdrop_mesh_index));
    end

    Module.reset();

    -- Make sure staged initialization has happened, and Jumpman has floated to the floor
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);

    skip_next_camera_interpolation();  -- TODO: Should this always happen for every level?
end

function Module.update(game_input)
    if not g_title_is_done_scrolling then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return;
    end

    ProgressLevel_(game_input);
end

function Module.on_collect_donut()
    g_visibility_change_frames_left = 30;
end

function Module.reset()
    g_visibility_bitmask = 255;
    ResetVisible_(g_visibility_bitmask);
    g_game_logic.set_player_current_position_x(68);
    g_game_logic.set_player_current_position_y(81);
    g_game_logic.set_player_current_position_z(9);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);

    for _, bullet in ipairs(g_bullets) do
        bullet.reset_pos();
    end

    skip_next_camera_interpolation();  -- TODO: Should this always happen for every level?
end

return Module;
