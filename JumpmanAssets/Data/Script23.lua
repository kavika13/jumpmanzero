local read_only = require "Data/read_only";
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local claw_module = assert(loadfile("Data/claw.lua"));
local jumper_module = assert(loadfile("Data/jumper.lua"));

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

local g_is_initialized = false;
local g_is_first_update_complete = false;
local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_claw = nil;
local g_jumpers = {};

function SpawnJumper_(start_alive)
    local new_jumper = jumper_module();
    new_jumper.GameLogic = g_game_logic;
    new_jumper.AnimationMeshResourceIndices = { resources.MeshJumper1, resources.MeshJumper2, resources.MeshJumper3 };
    new_jumper.EyesMeshResourceIndex = resources.MeshJuEyes;
    new_jumper.TextureResourceIndex = resources.TextureJumper;
    new_jumper.StartAlive = start_alive;
    return new_jumper;
end

function update(game_input, is_initializing)
    if not g_is_initialized then
        g_is_initialized = true;

        g_game_logic = game_logic_module();
        g_game_logic.ResetPlayerCallback = reset;

        g_hud_overlay = hud_overlay_module();

        g_claw = claw_module();
        g_claw.ClawMeshResourceIndex = resources.MeshClaw;
        g_claw.ChainMeshResourceIndex = resources.MeshChain;
        g_claw.DonutTextureResourceIndex = resources.TextureRedMetal;
        g_claw.ClawTextureResourceIndex = resources.TextureEvenWood;
        g_claw.ChainTextureResourceIndex = resources.TextureBoringGray;

        table.insert(g_jumpers, SpawnJumper_(true));
        table.insert(g_jumpers, SpawnJumper_(false));
        table.insert(g_jumpers, SpawnJumper_(true));
        table.insert(g_jumpers, SpawnJumper_(false));
        table.insert(g_jumpers, SpawnJumper_(false));

        set_current_camera_mode(camera_mode.PerspectiveWide);
    end

    -- TODO: Can probably make a parent meta script that calls into this and into hud_overlay.
    --       That should simplify this logic drastically.
    --       Probably best to do that with the level loader refactor?
    if is_initializing or g_title_is_done_scrolling then
        local continue_update = g_game_logic.progress_game(game_input);
        g_hud_overlay.update(game_input);

        if not continue_update then
            return true;
        end
    elseif g_is_first_update_complete then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return false;
    end

    g_claw.update(g_jumpers);

    for _, jumper in ipairs(g_jumpers) do
        jumper.update(g_jumpers);
    end

    if not g_is_first_update_complete then
        g_is_first_update_complete = true;
        return false;
    end

    return true;
end

function reset()
    set_player_current_position_x(10);
    set_player_current_position_y(5);
    set_player_current_position_z(2);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);

    for _, jumper in ipairs(g_jumpers) do
        jumper.reset_pos();
    end
end
