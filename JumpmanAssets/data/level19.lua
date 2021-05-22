local read_only = require "data/read_only";
local level19_data_module = assert(loadfile("data/level19_data.lua"));
local game_logic_module = assert(loadfile("data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("data/hud_overlay.lua"));
local prop_module = assert(loadfile("data/prop.lua"));
local whomper_module = assert(loadfile("data/whomper.lua"));

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
    TextureConveyor = 1,
    TextureWaterBack = 2,
    TextureRedMetal = 3,
    TextureDarkSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    ScriptBullet = 0,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    TextureBullet = 5,
    MeshWhomper = 2,
    MeshProp = 3,
    TextureBoringGray = 6,
    ScriptWhomper = 1,
    ScriptProp = 2,
    TextureConveyor = 7,
};
resources = read_only.make_table_read_only(resources);

local g_title_is_done_scrolling = false;

local g_hud_overlay;
local propellers = {};
local whompers = {};

local function ConveyPlatform_(platform_num, iDist)
    local platform_mesh_index = g_game_logic.find_platform_by_number(platform_num).mesh_index;
    scroll_texture_on_mesh(platform_mesh_index, iDist * 16, 0);

    if g_game_logic.get_player_current_state() == player_state.JSJUMPING then
        return;
    end

    local iPX = g_game_logic.get_player_current_position_x();
    local iPY = g_game_logic.get_player_current_position_y();

    local _, platform_index = g_game_logic.find_platform(iPX, iPY, 14, 2);

    if platform_index ~= -1 and platform_num ~= g_game_logic.get_platform(platform_index).number then
        return;
    end

    if g_game_logic.get_player_current_active_platform_index() == platform_index then
        iPX = iPX - iDist * 15;

        if g_game_logic.get_player_current_state() == 4096 then  -- TODO: Is this a custom state?
            g_game_logic.set_player_current_state(player_state.JSFALLING);
            g_game_logic.set_player_current_state_frame_count(0);
        end

        g_game_logic.set_player_current_position_x(iPX);
    end
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    ConveyPlatform_(1, 0.04);  -- TODO: Use constant for num
    ConveyPlatform_(2, -0.02);  -- TODO: Use constant for num
    ConveyPlatform_(3, 0.04);  -- TODO: Use constant for num
    ConveyPlatform_(4, -0.04);  -- TODO: Use constant for num

    for _, propeller in ipairs(propellers) do
        propeller.update();
    end

    for _, whomper in ipairs(whompers) do
        whomper.update();
    end

    g_game_logic.update_player_graphics();
end

local function CreateProp_(iX, iY, iR, iZ)
    local new_prop = prop_module();
    new_prop.GameLogic = g_game_logic;
    new_prop.MeshResourceIndex = resources.MeshProp;
    new_prop.TextureResourceIndex = resources.TextureBoringGray;
    new_prop.iX = iX;
    new_prop.iY = iY;
    new_prop.iR = iR;
    new_prop.iZ = iZ;
    new_prop.initialize();
    table.insert(propellers, new_prop);
end

local function CreateWhomper_(iX, iY, iR, iRV)
    local new_whomper = whomper_module();
    new_whomper.GameLogic = g_game_logic;
    new_whomper.MeshResourceIndex = resources.MeshWhomper;
    new_whomper.TextureResourceIndex = resources.TextureBoringGray;
    new_whomper.iX = iX;
    new_whomper.iY = iY;
    new_whomper.iR = iR;
    new_whomper.iRV = iRV;
    new_whomper.initialize();
    table.insert(whompers, new_whomper);
end

function Module.initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = level19_data_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.MenuLogic = Module.MenuLogic;
    g_hud_overlay.GameLogic = g_game_logic;

    CreateWhomper_(86, 28, 50, 3);
    CreateWhomper_(100, 28, 0, 3);
    CreateWhomper_(114, 28, 1, -3);
    CreateWhomper_(128, 28, -90, 1);

    CreateWhomper_(55, 143, 0, 3);
    CreateWhomper_(73, 143, 50, 3);
    CreateWhomper_(95, 143, -50, -3);

    CreateProp_(34, 90, 80, 5);
    CreateProp_(34, 90, 120, 5);

    CreateProp_(60, 46, 90, 2);
    CreateProp_(60, 56, 90, 2);

    CreateProp_(120, 46, 335, 2);
    CreateProp_(120, 46, 25, 2);

    CreateProp_(99, 105, 80, 2);
    CreateProp_(101, 97, 25, 2);

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
    g_game_logic.set_player_current_position_x(20);
    g_game_logic.set_player_current_position_y(21);
    g_game_logic.set_player_current_position_z(3);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end

return Module;
