local read_only = require "Data/read_only";
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local tyrannosaurus_module = assert(loadfile("Data/tyrannosaurus.lua"));
local triceratops_module = assert(loadfile("Data/triceratops.lua"));
local pterodactyl_module = assert(loadfile("Data/pterodactyl.lua"));

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
    TextureDAPlat = 1,
    TextureWoodLadder = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    SoundRoar = 4,
    MeshTSaurStandL = 0,
    MeshTSaurWalkL1 = 1,
    MeshTSaurWalkL2 = 2,
    MeshTSaurWalkL3 = 3,
    MeshTSaurWalkL4 = 4,
    MeshTSaurYL1 = 5,
    MeshTSaurYL2 = 6,
    MeshTSaurYL3 = 7,
    MeshTSaurYL4 = 8,
    ScriptTSaur = 0,
    TextureDinosaur = 5,
    MeshTSaurStandR = 9,
    MeshTSaurWalkR1 = 10,
    MeshTSaurWalkR2 = 11,
    MeshTSaurWalkR3 = 12,
    MeshTSaurWalkR4 = 13,
    ScriptTRSaur = 1,
    MeshTRSaurStandR = 14,
    MeshTRSaurWalkR1 = 15,
    MeshTRSaurWalkR2 = 16,
    MeshTRSaurStandL = 17,
    MeshTRSaurWalkL1 = 18,
    MeshTRSaurWalkL2 = 19,
    MeshTSaurStandR = 20,
    MeshTSaurYR1 = 21,
    MeshTSaurYR2 = 22,
    MeshTSaurYR3 = 23,
    MeshTSaurYR4 = 24,
    ScriptPSaur = 2,
    MeshPSaurL1 = 25,
    MeshPSaurL2 = 26,
    MeshPSaurL3 = 27,
    MeshPSaurL4 = 28,
    MeshPSaurR1 = 29,
    MeshPSaurR2 = 30,
    MeshPSaurR3 = 31,
    MeshPSaurR4 = 32,
};
resources = read_only.make_table_read_only(resources);

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_tyrannosaurus;
local g_triceratops;
local g_pterodactyl;

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    g_tyrannosaurus.update();
    g_triceratops.update();
    g_pterodactyl.update();
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.ResetPlayerCallback = reset;

    g_hud_overlay = hud_overlay_module();

    g_tyrannosaurus = tyrannosaurus_module();
    g_tyrannosaurus.GameLogic = g_game_logic;
    g_tyrannosaurus.LeftStandMeshResourceIndex = resources.MeshTSaurStandL;
    g_tyrannosaurus.RightStandMeshResourceIndex = resources.MeshTSaurStandR;
    g_tyrannosaurus.LeftWalkMeshResourceIndices = { resources.MeshTSaurWalkL1, resources.MeshTSaurWalkL2, resources.MeshTSaurWalkL3, resources.MeshTSaurWalkL4 };
    g_tyrannosaurus.RightWalkMeshResourceIndices = { resources.MeshTSaurWalkR1, resources.MeshTSaurWalkR2, resources.MeshTSaurWalkR3, resources.MeshTSaurWalkR4 };
    g_tyrannosaurus.LeftYellMeshResourceIndices = { resources.MeshTSaurYL1, resources.MeshTSaurYL2, resources.MeshTSaurYL3, resources.MeshTSaurYL4 };
    g_tyrannosaurus.RightYellMeshResourceIndices = { resources.MeshTSaurYR1, resources.MeshTSaurYR2, resources.MeshTSaurYR3, resources.MeshTSaurYR4 };
    g_tyrannosaurus.RoarSoundResourceIndex = resources.SoundRoar;
    g_tyrannosaurus.TextureResourceIndex = resources.TextureDinosaur;
    g_tyrannosaurus.initialize();

    g_triceratops = triceratops_module();
    g_triceratops.GameLogic = g_game_logic;
    g_triceratops.LeftStandMeshResourceIndex = resources.MeshTRSaurStandL;
    g_triceratops.RightStandMeshResourceIndex = resources.MeshTRSaurStandR;
    g_triceratops.LeftWalkMeshResourceIndices = { resources.MeshTRSaurWalkL1, resources.MeshTRSaurWalkL2 };
    g_triceratops.RightWalkMeshResourceIndices = { resources.MeshTRSaurWalkR1, resources.MeshTRSaurWalkR2 };
    g_triceratops.TextureResourceIndex = resources.TextureDinosaur;
    g_triceratops.initialize();

    g_pterodactyl = pterodactyl_module();
    g_pterodactyl.GameLogic = g_game_logic;
    g_pterodactyl.LeftMeshResourceIndices = { resources.MeshPSaurL1, resources.MeshPSaurL2, resources.MeshPSaurL3, resources.MeshPSaurL4 };
    g_pterodactyl.RightMeshResourceIndices = { resources.MeshPSaurR1, resources.MeshPSaurR2, resources.MeshPSaurR3, resources.MeshPSaurR4 };
    g_pterodactyl.TextureResourceIndex = resources.TextureDinosaur;
    g_pterodactyl.initialize();

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
    set_player_current_position_x(70);
    set_player_current_position_y(52);
    set_player_current_position_z(7);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end
