local read_only = require "data/read_only";
local level22_data_module = assert(loadfile("data/level22_data.lua"));
local game_logic_module = assert(loadfile("data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("data/hud_overlay.lua"));

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
    TextureBrick = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureFactory = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    ScriptBullet = 0,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    TextureBullet = 5,
    MeshSphere = 2,
    TextureBoringGray = 6,
    MeshGoo = 3,
    TextureHarle = 7,
    TextureDullGold = 8,
};
resources = read_only.make_table_read_only(resources);

local kPLATFORM_COUNT = 9;

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;

local g_platform_indices = {};
local g_platform_transform_indices = {};
local g_platforms_x1 = {};
local g_platforms_y1 = {};
local g_platforms_x2 = {};
local g_platforms_y2 = {};

local g_platforms_original_x1 = {};
local g_platforms_original_y1 = {};
local g_platforms_original_x2 = {};
local g_platforms_original_y2 = {};

local g_platforms_previous_x1 = {};
local g_platforms_previous_y1 = {};

local g_animation_frame = 0;

local g_small_gears_background_mesh_index = -1;
local g_small_gears_background_transform_index = -1;
local g_large_gears_background_mesh_index = -1;
local g_large_gears_background_transform_index = -1;

local function Cycle_(iCCount, iSpeed, iMin, iMax)
    local is_negative = false;

    if iCCount < 0 then
        is_negative = true;
        iCCount = 0 - iCCount;
    end

    local iCycle = iMax - iMin;
    local iCP = math.floor(iCCount * iSpeed) & 1023;
    local iPlace = ((iCP / 128) * iCycle) / 4;

    if is_negative then
        iPlace = iPlace + iCycle;

        if iPlace > iCycle * 2 then
            iPlace = iPlace - iCycle * 2;
        end
    end

    if iPlace > iCycle then
        iPlace = iCycle * 2 - iPlace;
    end

    iPlace = iPlace + iMin;

    return iPlace;
end

local function SetPosition_(iNum, iNX, iNY)
    local iLX;
    local iLY;

    iLX = g_platforms_original_x2[iNum] - g_platforms_original_x1[iNum];
    iLY = g_platforms_original_y2[iNum] - g_platforms_original_y1[iNum];

    g_platforms_x1[iNum] = iNX - iLX / 2;
    g_platforms_x2[iNum] = iNX + iLX / 2;

    g_platforms_y1[iNum] = iNY - iLY / 2;
    g_platforms_y2[iNum] = iNY + iLY / 2;
end

local function DisplayPlatform_(iNum)
    local current_platform = g_game_logic.get_platform(g_platform_indices[iNum]);
    current_platform.set_pos(
        g_platforms_x1[iNum], g_platforms_y1[iNum],
        g_platforms_x2[iNum], g_platforms_y2[iNum]);

    local iDX = g_platforms_x1[iNum] - g_platforms_original_x1[iNum];
    local iDY = g_platforms_y1[iNum] - g_platforms_original_y1[iNum];

    transform_set_translation(g_platform_transform_indices[iNum], iDX, iDY, 0);

    iDX = g_platforms_x1[iNum] - g_platforms_previous_x1[iNum];
    iDY = g_platforms_y1[iNum] - g_platforms_previous_y1[iNum];

    g_platforms_previous_x1[iNum] = g_platforms_x1[iNum];
    g_platforms_previous_y1[iNum] = g_platforms_y1[iNum];

    if g_game_logic.get_player_current_active_platform_index() == current_platform.index then
        local iPX = g_game_logic.get_player_current_position_x();
        local iPY = g_game_logic.get_player_current_position_y();
        g_game_logic.set_player_current_position_x(iPX + iDX);

        if g_game_logic.get_player_current_state() == player_state.JSNORMAL then
            local iHeight = g_platforms_y1[iNum];

            if iHeight > iPY - 1 and iHeight < iPY + 2 then
                g_game_logic.set_player_current_position_y(iHeight);
            end
        end
    end
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    g_animation_frame = g_animation_frame + 1;

    -- TODO: Pass in the angle, etc, to DisplayPlatform_ so the visuals can just use rotation interpolation instead of translation interpolation
    local iNX = math.cos(((g_animation_frame * 2 / 3) + 180) * math.pi / 180.0) * 43 + 80;
    local iNY = math.sin(((g_animation_frame * 2 / 3) + 180) * math.pi / 180.0) * 43 + 80;
    SetPosition_(6, iNX, iNY + 3);
    DisplayPlatform_(6);

    iNX = math.cos(g_animation_frame * 2 / 3 * math.pi / 180.0) * 43 + 80;
    iNY = math.sin(g_animation_frame * 2 / 3 * math.pi / 180.0) * 43 + 80;
    SetPosition_(1, iNX, iNY + 3);
    DisplayPlatform_(1);

    iNX = math.cos(((0 - g_animation_frame) + 180) * math.pi / 180.0) * 21 + 80;
    iNY = math.sin(((0 - g_animation_frame) + 180) * math.pi / 180.0) * 21 + 80;
    SetPosition_(7, iNX, iNY + 3);
    DisplayPlatform_(7);

    iNX = math.cos((0 - g_animation_frame) * math.pi / 180.0) * 21 + 80;
    iNY = math.sin((0 - g_animation_frame) * math.pi / 180.0) * 21 + 80;
    SetPosition_(2, iNX, iNY + 3);
    DisplayPlatform_(2);

    iNX = Cycle_(g_animation_frame, 5.5, 12, 76);
    iNY = Cycle_(g_animation_frame, 5.5, 175, 191);
    SetPosition_(8, iNX, iNY);
    DisplayPlatform_(8);

    iNX = Cycle_(g_animation_frame, 4.6, 97, 152);
    iNY = Cycle_(0 - g_animation_frame, 4.6, 188, 196);
    SetPosition_(9, iNX, iNY);
    DisplayPlatform_(9);

    iNX = 145;
    iNY = Cycle_(g_animation_frame, 3, 28, 113);
    SetPosition_(3, iNX, iNY);
    DisplayPlatform_(3);

    iNX = Cycle_(g_animation_frame, 4.9, 66, 125);
    iNY = 145;
    SetPosition_(4, iNX, iNY);
    DisplayPlatform_(4);

    iNX = Cycle_(g_animation_frame, 6, 4, 58);
    iNY = 155;
    SetPosition_(5, iNX, iNY);
    DisplayPlatform_(5);

    transform_set_scale(g_small_gears_background_transform_index, 25, 25, 2);
    transform_set_rotation_z(g_small_gears_background_transform_index, 0 - g_animation_frame);
    transform_set_translation(g_small_gears_background_transform_index, 80, 80, 7);
    set_mesh_is_visible(g_small_gears_background_mesh_index, true);

    transform_set_scale(g_large_gears_background_transform_index, 50, 50, 2);
    transform_set_rotation_z(g_large_gears_background_transform_index, g_animation_frame * 2 / 3);
    transform_set_translation(g_large_gears_background_transform_index, 80, 80, 9);
    set_mesh_is_visible(g_large_gears_background_mesh_index, true);

    g_game_logic.update_player_graphics();
end

local function SetPlatformData_(platform_num)
    local current_platform = g_game_logic.find_platform_by_number(platform_num);

    g_platform_transform_indices[platform_num] = transform_create();
    mesh_set_transform(current_platform.mesh_index, g_platform_transform_indices[platform_num]);

    g_platform_indices[platform_num] = current_platform.index;
    g_platforms_x1[platform_num] = current_platform.pos_upper_left[1];
    g_platforms_x2[platform_num] = current_platform.pos_lower_right[1];
    g_platforms_y1[platform_num] = current_platform.pos_upper_left[2];
    g_platforms_y2[platform_num] = current_platform.pos_lower_right[2];

    g_platforms_original_x1[platform_num] = current_platform.pos_upper_left[1];
    g_platforms_original_x2[platform_num] = current_platform.pos_lower_right[1];
    g_platforms_original_y1[platform_num] = current_platform.pos_upper_left[2];
    g_platforms_original_y2[platform_num] = current_platform.pos_lower_right[2];

    g_platforms_previous_x1[platform_num] = current_platform.pos_upper_left[1];
    g_platforms_previous_y1[platform_num] = current_platform.pos_upper_left[2];
end

function Module.initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = level22_data_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.MenuLogic = Module.MenuLogic;
    g_hud_overlay.GameLogic = g_game_logic;

    g_game_logic.set_level_extent_x(200);

    for platform_num = 1, kPLATFORM_COUNT do
        SetPlatformData_(platform_num);
    end

    g_small_gears_background_mesh_index = new_mesh(resources.MeshSphere);
    g_small_gears_background_transform_index = transform_create();
    mesh_set_transform(g_small_gears_background_mesh_index, g_small_gears_background_transform_index);
    set_mesh_texture(g_small_gears_background_mesh_index, resources.TextureBoringGray);

    g_large_gears_background_mesh_index = new_mesh(resources.MeshSphere);
    g_large_gears_background_transform_index = transform_create();
    mesh_set_transform(g_large_gears_background_mesh_index, g_large_gears_background_transform_index);
    set_mesh_texture(g_large_gears_background_mesh_index, resources.TextureBoringGray);

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

function Module.reset()
    g_game_logic.set_player_current_position_x(150);
    g_game_logic.set_player_current_position_y(7);
    g_game_logic.set_player_current_position_z(3);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end

return Module;
