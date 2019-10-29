local read_only = require "Data/read_only";
local level_level23_module = assert(loadfile("Data/level_level23.lua"));
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local claw_module = assert(loadfile("Data/claw.lua"));
local jumper_module = assert(loadfile("Data/jumper.lua"));

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
    TextureJumpman = 0,
    TextureBrick = 1,
    TextureConcrete = 2,
    TextureRedMetal = 3,
    Texturesky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    ScriptBullet = 0,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    TextureBullet = 5,
    MeshClaw = 2,
    MeshChain = 0,  -- TODO: Isn't defined in the level. Added here manually. Should fix level instead. Looks right tho
    TextureEvenWood = 6,
    ScriptClaw = 1,
    TextureBlack = 7,
    ScriptJumper = 2,
    TextureJumper = 8,
    MeshJumper1 = 4,
    MeshJumper2 = 5,
    MeshJumper3 = 6,
    MeshJuEyes = 7,
    TextureBoringGray = 9,
};
resources = read_only.make_table_read_only(resources);

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_claw = nil;
local g_jumpers = {};

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    g_claw.update(g_jumpers);

    for _, jumper in ipairs(g_jumpers) do
        jumper.update(g_jumpers);
    end

    g_game_logic.update_player_graphics();
end

local function SpawnJumper_(start_alive)
    local new_jumper = jumper_module();
    new_jumper.GameLogic = g_game_logic;
    new_jumper.AnimationMeshResourceIndices = { resources.MeshJumper1, resources.MeshJumper2, resources.MeshJumper3 };
    new_jumper.EyesMeshResourceIndex = resources.MeshJuEyes;
    new_jumper.TextureResourceIndex = resources.TextureJumper;
    new_jumper.StartAlive = start_alive;
    new_jumper.initialize();
    return new_jumper;
end

function Module.initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = level_level23_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.MenuLogic = Module.MenuLogic;
    g_hud_overlay.GameLogic = g_game_logic;

    g_claw = claw_module();
    g_claw.GameLogic = g_game_logic;
    g_claw.ClawMeshResourceIndex = resources.MeshClaw;
    g_claw.ChainMeshResourceIndex = resources.MeshChain;
    g_claw.DonutTextureResourceIndex = resources.TextureRedMetal;
    g_claw.ClawTextureResourceIndex = resources.TextureEvenWood;
    g_claw.ChainTextureResourceIndex = resources.TextureBoringGray;
    g_claw.initialize();

    table.insert(g_jumpers, SpawnJumper_(true));
    table.insert(g_jumpers, SpawnJumper_(false));
    table.insert(g_jumpers, SpawnJumper_(true));
    table.insert(g_jumpers, SpawnJumper_(false));
    table.insert(g_jumpers, SpawnJumper_(false));

    g_game_logic.set_current_camera_mode(camera_mode.PerspectiveWide);

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
    g_game_logic.set_player_current_position_x(10);
    g_game_logic.set_player_current_position_y(5);
    g_game_logic.set_player_current_position_z(2);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);

    for _, jumper in ipairs(g_jumpers) do
        jumper.reset_pos();
    end
end

return Module;
