local read_only = require "Data/read_only";
local level_level2_module = assert(loadfile("Data/level_level2.lua"));
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local wave_module = assert(loadfile("Data/wave.lua"));
local drop_module = assert(loadfile("Data/drop.lua"));

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
    TextureWoodPlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    ScriptWave = 0,
    ScriptDrop = 1,
    TextureSea = 5,
    TextureWave1 = 6,
    TextureWave2 = 7,
    TextureDrop = 8,
    TextureSplash1 = 9,
    TextureSplash2 = 10,
    TextureSplash3 = 11,
    MeshSea = 0,
    MeshWave = 1,
    MeshDrop = 2,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
};
resources = read_only.make_table_read_only(resources);

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_drop_objects = {};
local g_wave_object;

local function IsDropTooCloseToOtherDrops_(current_drop)
    local current_x = current_drop.get_current_pos_x();

    for _, other_drop in ipairs(g_drop_objects) do
        if other_drop ~= current_drop then
            local other_x = other_drop.get_current_pos_x();
            local other_y = other_drop.get_current_pos_y();

            if other_y > 120 and other_x < (current_x + 10) and other_x > (current_x - 10) then
                return true;
            end
        end
    end

    return false;
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    for _, drop in ipairs(g_drop_objects) do
        drop.update();
    end

    g_wave_object.update();

    g_game_logic.update_player_graphics();
end

local function CreateDropObject_(frames_to_wait)
    local new_drop_object = drop_module();
    new_drop_object.GameLogic = g_game_logic;
    new_drop_object.IsTooCloseToOtherDropsCallback = IsDropTooCloseToOtherDrops_;
    new_drop_object.FramesToWait = frames_to_wait;
    new_drop_object.DropMeshResourceIndex = resources.MeshDrop;
    new_drop_object.DropTextureResourceIndices = { resources.TextureDrop, resources.TextureSplash1, resources.TextureSplash2, resources.TextureSplash3 };
    new_drop_object.initialize();
    return new_drop_object;
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.LevelData = level_level2_module();
    g_game_logic.ResetPlayerCallback = reset;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.GameLogic = g_game_logic;

    table.insert(g_drop_objects, CreateDropObject_(700));
    table.insert(g_drop_objects, CreateDropObject_(600));
    table.insert(g_drop_objects, CreateDropObject_(500));
    table.insert(g_drop_objects, CreateDropObject_(400));
    table.insert(g_drop_objects, CreateDropObject_(300));
    table.insert(g_drop_objects, CreateDropObject_(200));
    table.insert(g_drop_objects, CreateDropObject_(100));

    g_wave_object = wave_module();
    g_wave_object.GameLogic = g_game_logic;
    g_wave_object.SeaMeshResourceIndex = resources.MeshSea;
    g_wave_object.WaveMeshResourceIndex = resources.MeshWave;
    g_wave_object.SeaTextureResourceIndex = resources.TextureSea;
    g_wave_object.Wave1TextureResourceIndex = resources.TextureWave1;
    g_wave_object.Wave2TextureResourceIndex = resources.TextureWave2;
    g_wave_object.initialize();

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

function reset()
    g_game_logic.set_player_current_position_x(10);
    g_game_logic.set_player_current_position_y(73);
    g_game_logic.set_player_current_position_z(2);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end
