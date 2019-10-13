local read_only = require "Data/read_only";
local level_level3_module = assert(loadfile("Data/level_level3.lua"));
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local bear_module = assert(loadfile("Data/bear2.lua"));

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
    TextureRedGirder = 1,
    TextureRedStone = 2,
    TextureNewMetal = 3,
    Texturesky = 4,
    ScriptBear2 = 0,
    TextureFur = 5,
    MeshFyStand = 0,
    MeshFyRight1 = 1,
    MeshFyRight2 = 2,
    MeshFyFR1 = 3,
    MeshFyFR2 = 4,
    MeshFyFlopR = 5,
    MeshFySR1 = 6,
    MeshFySR2 = 7,
    MeshFyStandL = 8,
    MeshFyLeft1 = 9,
    MeshFyLeft2 = 10,
    MeshFyFL1 = 11,
    MeshFyFL2 = 12,
    MeshFyFlopL = 13,
    MeshFySL1 = 14,
    MeshFySL2 = 15,
    MeshFyLC1 = 16,
    MeshFyLC2 = 17,
    SoundJump = 0,
    Soundchomp = 1,
    Soundbonk = 2,
    TextureStone = 6,
};
resources = read_only.make_table_read_only(resources);

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_bear = nil;

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    g_bear.update();

    g_game_logic.update_player_graphics();
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.LevelData = level_level3_module();
    g_game_logic.ResetPlayerCallback = reset;
    g_game_logic.initialize();
    g_game_logic.build_navigation();

    g_hud_overlay = hud_overlay_module();

    g_bear = bear_module();
    g_bear.GameLogic = g_game_logic;
    g_bear.StandRightMeshResourceIndex = resources.MeshFyStand;
    g_bear.MoveRightMeshResourceIndices = { resources.MeshFyRight1, resources.MeshFyRight2 };
    g_bear.FallRightMeshResourceIndices = { resources.MeshFyFR1, resources.MeshFyFR2 };
    g_bear.RestRightMeshResourceIndex = resources.MeshFyFlopR;
    g_bear.ShakeRightMeshResourceIndices = { resources.MeshFySR1, resources.MeshFySR2 };
    g_bear.StandLeftMeshResourceIndex = resources.MeshFyStandL;
    g_bear.MoveLeftMeshResourceIndices = { resources.MeshFyLeft1, resources.MeshFyLeft2 };
    g_bear.FallLeftMeshResourceIndices = { resources.MeshFyFL1, resources.MeshFyFL2 };
    g_bear.RestLeftMeshResourceIndex = resources.MeshFyFlopL;
    g_bear.ShakeLeftMeshResourceIndices = { resources.MeshFySL1, resources.MeshFySL2 };
    g_bear.ClimbMeshResourceIndices = { resources.MeshFyLC1, resources.MeshFyLC2 };
    g_bear.TextureResourceIndex = resources.TextureFur;
    g_bear.initialize();

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
    g_game_logic.set_player_current_position_x(6);
    g_game_logic.set_player_current_position_y(7);
    g_game_logic.set_player_current_position_z(3);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);

    if g_bear then
        g_bear.reset_pos();
    end
end
