local read_only = require "Data/read_only";

-- TODO: Move this into a shared file, split into separate tables by type
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
}
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
}
resources = read_only.make_table_read_only(resources);

local is_initialized = false;

function update()
    if not is_initialized then
        is_initialized = true;

        spawn_object(resources.ScriptTSaur);
        spawn_object(resources.ScriptTRSaur);
        spawn_object(resources.ScriptPSaur);
    end
end

function reset()
    set_player_current_position_x(70);
    set_player_current_position_y(52);
    set_player_current_position_z(7);
    set_player_current_state(player_state.JSNORMAL);
end
