local read_only = require "Data/read_only";
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local penguin_module = assert(loadfile("Data/penguin.lua"));

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
    TextureHarle = 0,
    TextureIcyPlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    Texturesky = 4,
    TexturePenguinTexture = 5,
    MeshPenguinRight1 = 0,
    MeshPenguinRight2 = 1,
    MeshPenguinLeft1 = 2,
    MeshPenguinLeft2 = 3,
    MeshPenguinBack = 4,
    MeshPenguinLC1 = 5,
    MeshPenguinLC2 = 6,
    MeshPenguinStand = 7,
    ScriptPenguin = 0,
    SoundJump = 0,
    Soundchomp = 1,
    Soundbonk = 2,
};
resources = read_only.make_table_read_only(resources);

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_penguins = {};

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    for _, penguin in ipairs(g_penguins) do
        penguin.update();
    end

    g_game_logic.update_player_graphics();
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.ResetPlayerCallback = reset;

    g_hud_overlay = hud_overlay_module();

    for iLoop = 0, 11 do
        local new_penguin = penguin_module();
        new_penguin.GameLogic = g_game_logic;
        new_penguin.StandMeshResourceIndex = resources.MeshPenguinStand;
        new_penguin.BackMeshResourceIndex = resources.MeshPenguinBack;
        new_penguin.MoveLeftMeshResourceIndices = { resources.MeshPenguinLeft1, resources.MeshPenguinLeft2 };
        new_penguin.MoveRightMeshResourceIndices = { resources.MeshPenguinRight1, resources.MeshPenguinRight2 };
        new_penguin.LadderClimbMeshResourceIndices = { resources.MeshPenguinLC1, resources.MeshPenguinLC2};
        new_penguin.TextureResourceIndex = resources.TexturePenguinTexture;
        new_penguin.CountOfTimesToPreAdvanceMovement = iLoop * 66;
        new_penguin.initialize();
        table.insert(g_penguins, new_penguin);
    end

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
    g_game_logic.set_player_current_position_x(38);
    g_game_logic.set_player_current_position_y(25);
    g_game_logic.set_player_current_position_z(2);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end
