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
    MeshFYFlopR = 5,
    MeshFYSR1 = 6,
    MeshFYSR2 = 7,
    MeshFyStandL = 8,
    MeshFyLeft1 = 9,
    MeshFyLeft2 = 10,
    MeshFyFL1 = 11,
    MeshFyFL2 = 12,
    MeshFYFlopL = 13,
    MeshFYSL1 = 14,
    MeshFYSL2 = 15,
    MeshFYLC1 = 16,
    MeshFYLC2 = 17,
    SoundJump = 0,
    Soundchomp = 1,
    Soundbonk = 2,
    TextureStone = 6,
}
resources = read_only.make_table_read_only(resources);

local is_initialized = false;

function update()
    if not is_initialized then
        is_initialized = true;

        spawn_object(resources.ScriptBear2);
    end
end

function reset()
    set_player_current_position_x(6);
    set_player_current_position_y(7);
    set_player_current_position_z(3);
    set_player_current_state(player_state.JSNORMAL);
end
