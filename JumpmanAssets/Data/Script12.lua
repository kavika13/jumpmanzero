local read_only = require "Data/read_only";
local level_level12_module = assert(loadfile("Data/level_level12.lua"));
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local bee_module = assert(loadfile("Data/bee.lua"));

-- TODO: Move this into a shared file, split into separate tables by type. Or inject from engine?
local player_state = {
    JSNORMAL = 0,
    JSJUMPING = 1,
    JSRIGHT = 2,
    JSLEFT = 4,
    JSFALLING = 8 ,
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
    TexturePurpleHex = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    MeshBeeLeft1 = 0,
    MeshBeeLeft2 = 1,
    MeshBeeRight1 = 2,
    MeshBeeRight2 = 3,
    TextureBeeTexture = 5,
    ScriptBee = 0,
    TextureBigHive = 6,
    SoundBee = 4,
};
resources = read_only.make_table_read_only(resources);

local g_is_first_update_complete = false;
local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_bees = {};
local g_collected_donut_count = 0;

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    for _, bee in ipairs(g_bees) do
        bee.update();
    end

    g_game_logic.update_player_graphics();
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.LevelData = level_level12_module();
    g_game_logic.ResetPlayerCallback = reset;
    g_game_logic.OnCollectDonutCallback = on_collect_donut;
    g_game_logic.set_level_extent_x(220);
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.GameLogic = g_game_logic;

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

local function SpawnBee_()
    local bee = bee_module();
    bee.GameLogic = g_game_logic;
    bee.MoveLeftMeshResourceIndices = { resources.MeshBeeLeft1, resources.MeshBeeLeft2 };
    bee.MoveRightMeshResourceIndices = { resources.MeshBeeRight1, resources.MeshBeeRight2 };
    bee.TextureResourceIndex = resources.TextureBeeTexture;
    bee.BuzzSoundResourceIndex = resources.SoundBee;
    bee.initialize();
    return bee;
end

function on_collect_donut()
    g_collected_donut_count = g_collected_donut_count + 1;

    if g_collected_donut_count == 1 then
        play_sound_effect(resources.SoundBee);
        table.insert(g_bees, SpawnBee_());
    end

    if g_collected_donut_count == 4 then
        play_sound_effect(resources.SoundBee);
        table.insert(g_bees, SpawnBee_());
    end

    if g_collected_donut_count == 10 then
        play_sound_effect(resources.SoundBee);
        table.insert(g_bees, SpawnBee_());
    end

    if g_collected_donut_count == 15 then
        play_sound_effect(resources.SoundBee);
        table.insert(g_bees, SpawnBee_());
    end
end

function reset()
    g_game_logic.set_player_current_position_x(80);
    g_game_logic.set_player_current_position_y(7);
    g_game_logic.set_player_current_position_z(2);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);

    for _, bee in ipairs(g_bees) do
        bee.reset_pos();
    end
end
