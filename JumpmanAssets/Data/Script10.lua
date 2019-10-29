local read_only = require "Data/read_only";
local level_level10_module = assert(loadfile("Data/level_level10.lua"));
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local run_donut_module = assert(loadfile("Data/run_donut.lua"));
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
    TextureBullet = 4,
    Texturesky = 5,
    ScriptBullet = 0,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    SoundJump = 0,
    Soundchomp = 1,
    Soundbonk = 2,
    SoundFire = 3,
    MeshRunDonut1 = 2,
    MeshRunDonut2 = 3,
    MeshRunDonut3 = 4,
    TextureRunDonut = 6,
    ScriptRunDonut = 1,
    MeshRunDonutHatch1 = 5,
    MeshRunDonutHatch2 = 6,
    MeshRunDonutHatch3 = 7,
    MeshRunDonutHatch4 = 8,
    MeshRunDonutHatch5 = 9,
};
resources = read_only.make_table_read_only(resources);

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_run_donuts = {};
local g_bullets = {};

local function OnKillRunDonut_(run_donut)
    for index, value in ipairs(g_run_donuts) do
        if value == run_donut then
            table.remove(g_run_donuts, index);
            return;
        end
    end

    assert(false, "Was unable to find run donut to remove");
end

local OnSpawnRunDonut_ = nil;

local function CreateRunDonut_()
    local new_run_donut = run_donut_module();
    new_run_donut.GameLogic = g_game_logic;
    new_run_donut.MoveMeshResourceIndices = {
        resources.MeshRunDonut1, resources.MeshRunDonut2, resources.MeshRunDonut3,
    };
    new_run_donut.HatchMeshResourceIndices = {
        resources.MeshRunDonutHatch1, resources.MeshRunDonutHatch2, resources.MeshRunDonutHatch3,
        resources.MeshRunDonutHatch4, resources.MeshRunDonutHatch5,
    };
    new_run_donut.TextureResourceIndex = resources.TextureRunDonut;
    new_run_donut.SpawnCallback = OnSpawnRunDonut_;
    new_run_donut.KillCallback = OnKillRunDonut_;
    return new_run_donut;
end

OnSpawnRunDonut_ = function()
    local new_run_donut = CreateRunDonut_();
    new_run_donut.initialize();
    table.insert(g_run_donuts, new_run_donut);
    return new_run_donut;
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    for _, run_donut in ipairs(g_run_donuts) do
        run_donut.update(g_run_donuts);
    end

    for _, bullet in ipairs(g_bullets) do
        bullet.update();
    end

    g_game_logic.update_player_graphics();
end

function Module.initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = level_level10_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
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

    local iX = 40;

    while iX < 150 do
        local iY = 20;

        while iY < 180 do
            local new_run_donut = CreateRunDonut_();
            new_run_donut.InitialPosX = iX + iY / 8;
            new_run_donut.InitialPosY = iY;
            new_run_donut.initialize();
            table.insert(g_run_donuts, new_run_donut);
            iY = iY + 30;
        end

        iX = iX + 20;
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

function Module.reset()
    g_game_logic.set_player_current_position_x(20);
    g_game_logic.set_player_current_position_y(4);
    g_game_logic.set_player_current_position_z(2);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);

    for _, bullet in ipairs(g_bullets) do
        bullet.reset_pos();
    end
end

return Module;
