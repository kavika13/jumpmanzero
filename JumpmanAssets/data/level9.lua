local read_only = require "data/read_only";
local level9_data_module = assert(loadfile("data/level9_data.lua"));
local game_logic_module = assert(loadfile("data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("data/hud_overlay.lua"));
local bullet_module = assert(loadfile("data/bullet.lua"));
local chain_module = assert(loadfile("data/chain.lua"));

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
    TexturePrisoner = 0,
    TextureTileStone = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    MeshChain = 0,
    TextureChain = 5,
    TextureLitFountain = 6,
    ScriptBullet = 0,
    ScriptChain = 1,
    MeshBullet1 = 1,
    MeshBullet2 = 2,
    TextureBullet = 7,
};
resources = read_only.make_table_read_only(resources);

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_bullets = {};

local g_chain;
local g_chain_length;
local g_target_length;

local function SetChainLength_()
    if g_chain_length < g_target_length then
        g_chain_length = g_chain_length + 1;
    end

    g_chain.ChainLength = g_chain_length;
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    SetChainLength_();

    g_chain.update();

    for _, bullet in ipairs(g_bullets) do
        bullet.update();
    end

    g_game_logic.update_player_graphics();
end

function Module.initialize(game_input)
    g_chain_length = 10;
    g_target_length = 20;

    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = level9_data_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.OnCollectDonutCallback = Module.on_collect_donut;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.MenuLogic = Module.MenuLogic;
    g_hud_overlay.GameLogic = g_game_logic;

    g_chain = chain_module();
    g_chain.GameLogic = g_game_logic;
    g_chain.LinkMeshResourceIndex = resources.MeshChain;
    g_chain.LinkTextureResourceIndex = resources.TextureChain;
    g_chain.initialize();

    for iLoop = 1, 4 do
        local new_bullet = bullet_module();
        new_bullet.GameLogic = g_game_logic;
        new_bullet.Mesh1Index = resources.MeshBullet1;
        new_bullet.Mesh2Index = resources.MeshBullet2;
        new_bullet.TextureIndex = resources.TextureBullet;
        new_bullet.FireSoundIndex = resources.SoundFire;
        new_bullet.initialize();
        table.insert(g_bullets, new_bullet);
    end

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

function Module.on_collect_donut(game_input, iDonut)
    g_target_length = g_target_length + iDonut;
end

function Module.reset()
    g_game_logic.set_player_current_position_x(70);
    g_game_logic.set_player_current_position_y(62);
    g_game_logic.set_player_current_position_z(2);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);

    for _, bullet in ipairs(g_bullets) do
        bullet.reset_pos();
    end
end

return Module;
