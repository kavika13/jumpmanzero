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
}
resources = read_only.make_table_read_only(resources);

-- TODO: Separate file?
local penguin_properties = {
    PenguinAdvance = 0,
    PenguinIInit = 1,
    PenguinIX = 2,
    PenguinIY = 3,
    PenguinIZ = 4,
    PenguinIDir = 5,
    PenguinISlow = 6,
    PenguinIAnimate = 7,
    PenguinILadderz = 8,
    PenguinIFrame = 9,
    PenguinIMeshes = 10,
}
penguin_properties = read_only.make_table_read_only(penguin_properties);

local is_initialized = false;

function update()
    if not is_initialized then
        is_initialized = true;
        local iLoop = 0;

        while iLoop < 12
        do
            local iTemp = spawn_object(resources.ScriptPenguin);
            set_object_global_data(iTemp, penguin_properties.PenguinAdvance, iLoop * 66);
            iLoop = iLoop + 1;
        end
    end
end

function reset()
    set_player_current_position_x(38);
    set_player_current_position_y(25);
    set_player_current_position_z(2);
    set_player_current_state(player_state.JSNORMAL);
end
