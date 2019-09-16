local read_only = require "Data/read_only";

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
    Soundchomp = 1,
    Soundbonk = 2,
    SoundFire = 3,
    ScriptBullet = 0,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    TextureBullet = 5,
    MeshClaw = 2,
    TextureEvenWood = 6,
    ScriptClaw = 1,
    Meshgoo = 3,
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

-- TODO: Separate file?
local claw_properties = {
    ClawIInit = 0,
    ClawIX = 1,
    ClawIY = 2,
    ClawIZ = 3,
    ClawITop = 4,
    ClawICycle = 5,
    ClawIOpen = 6,
    ClawISpin = 7,
    ClawIMeshes = 8,
    ClawIChain = 19,
    ClawIStatus = 20,
    ClawIRescueObj = 21,
    ClawIWait = 22,
};
claw_properties = read_only.make_table_read_only(claw_properties);

-- TODO: Separate file?
local jumper_properties = {
    JumperIInit = 0,
    JumperIX = 1,
    JumperIY = 2,
    JumperIZ = 3,
    JumperIFrame = 4,
    JumperIYV = 5,
    JumperIXV = 6,
    JumperIMeshes = 7,
    JumperIMeshEyes = 38,
    JumperIEyeAdjust = 39,
    JumperIStatus = 40,
    JumperISC = 41,
    JumperIDodge = 42,
    JumperIStartAlive = 43,
};
jumper_properties = read_only.make_table_read_only(jumper_properties);

local is_initialized = false;

function update()
    if not is_initialized then
        is_initialized = true;

        local iClaw = spawn_object(resources.ScriptClaw);

        local iJumper = spawn_object(resources.ScriptJumper);
        set_object_global_data(iJumper, jumper_properties.JumperIStartAlive, 1);

        iJumper = spawn_object(resources.ScriptJumper);

        iJumper = spawn_object(resources.ScriptJumper);
        set_object_global_data(iJumper, jumper_properties.JumperIStartAlive, 1);

        iJumper = spawn_object(resources.ScriptJumper);
        iJumper = spawn_object(resources.ScriptJumper);

        set_current_camera_mode(camera_mode.PerspectiveWide);
    end
end

function reset()
    set_player_current_position_x(10);
    set_player_current_position_y(5);
    set_player_current_position_z(2);
    set_player_current_state(player_state.JSNORMAL);
end
