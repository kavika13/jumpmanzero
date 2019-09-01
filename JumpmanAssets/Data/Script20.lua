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
    TextureClassicPlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundGOAT = 3,
    MeshCopter = 0,
    TextureSheep = 5,
    ScriptLSheep = 0,
    MeshSheepFL1 = 1,
    MeshSheepFL2 = 2,
    MeshSheepFL3 = 3,
    MeshSheepFR1 = 4,
    MeshSheepFR2 = 5,
    MeshSheepFR3 = 6,
    MeshSheepJL1 = 7,
    MeshSheepJL2 = 8,
    MeshSheepJL3 = 9,
    MeshSheepJR1 = 10,
    MeshSheepJR2 = 11,
    MeshSheepJR3 = 12,
    MeshSheepL1 = 13,
    MeshSheepL2 = 14,
    MeshSheepR1 = 15,
    MeshSheepR2 = 16,
    TextureBoringRed = 6,
    ScriptFSheep = 1,
    TextureLSheep = 7,
}
resources = read_only.make_table_read_only(resources);

-- TODO: Separate file?
local l_sheep_properties = {
    LSheepIInit = 0,
    LSheepIX = 1,
    LSheepIY = 2,
    LSheepIZ = 3,
    LSheepIDir = 4,
    LSheepISlow = 5,
    LSheepIAnimate = 6,
    LSheepILadderZ = 7,
    LSheepIFrame = 8,
    LSheepIMeshes = 9,
    LSheepICopter = 40,
    LSheepICount = 41,
    LSheepISpin = 42,
    LSheepIFlyDir = 43,
    LSheepICopterSize = 44,
    LSheepIAirTime = 45,
    LSheepBPassDir = 46,
}
l_sheep_properties = read_only.make_table_read_only(l_sheep_properties);

-- TODO: Separate file?
local f_sheep_properties = {
    FSheepIInit = 0,
    FSheepIX = 1,
    FSheepIY = 2,
    FSheepIZ = 3,
    FSheepIDir = 4,
    FSheepISlow = 5,
    FSheepIAnimate = 6,
    FSheepILadderZ = 7,
    FSheepIFrame = 8,
    FSheepIMeshes = 9,
    FSheepICopter = 40,
    FSheepICount = 41,
    FSheepISpin = 42,
    FSheepIFlyDir = 43,
    FSheepICopterSize = 44,
    FSheepIAirTime = 45,
    FSheepIDelay = 46,
    FSheepQueueLength = 47,
    FSheepQueue = 48,
}
f_sheep_properties = read_only.make_table_read_only(f_sheep_properties);

local g_init_stage_index = 0;
local g_leader_sheep_object_index;
local g_delay = 0;

function update()
    if g_init_stage_index == 1 then
        g_init_stage_index = 2;
        local iLoop = 0;

        while iLoop < 6
        do
            CreateSheep();
            iLoop = iLoop + 1;
        end
    end

    if g_init_stage_index == 0 then
        g_init_stage_index = 1;
        g_leader_sheep_object_index = spawn_object(resources.ScriptLSheep);
        set_level_extent_x(270);
    end
end

function CreateSheep()
    g_delay = g_delay + 30;

    local follower_sheep = spawn_object(resources.ScriptFSheep);
    set_object_global_data(follower_sheep, f_sheep_properties.FSheepIDelay, g_delay);

    local iTemp = get_object_global_data(g_leader_sheep_object_index, l_sheep_properties.LSheepIX);
    set_object_global_data(follower_sheep, f_sheep_properties.FSheepIX, iTemp);

    iTemp = get_object_global_data(g_leader_sheep_object_index, l_sheep_properties.LSheepIY);
    set_object_global_data(follower_sheep, f_sheep_properties.FSheepIY, iTemp);

    iTemp = get_object_global_data(g_leader_sheep_object_index, l_sheep_properties.LSheepIZ);
    set_object_global_data(follower_sheep, f_sheep_properties.FSheepIZ, iTemp);

    iTemp = get_object_global_data(g_leader_sheep_object_index, l_sheep_properties.LSheepIFrame);
    set_object_global_data(follower_sheep, f_sheep_properties.FSheepIFrame, iTemp);

    iTemp = get_object_global_data(g_leader_sheep_object_index, l_sheep_properties.LSheepIDir);
    set_object_global_data(follower_sheep, f_sheep_properties.FSheepIDir, iTemp);

    iTemp = get_object_global_data(g_leader_sheep_object_index, l_sheep_properties.LSheepIAirTime);
    set_object_global_data(follower_sheep, f_sheep_properties.FSheepIAirTime, iTemp);

    iTemp = get_object_global_data(g_leader_sheep_object_index, l_sheep_properties.LSheepICount);
    set_object_global_data(follower_sheep, f_sheep_properties.FSheepICount, iTemp);

    iTemp = get_object_global_data(g_leader_sheep_object_index, l_sheep_properties.LSheepILadderZ);
    set_object_global_data(follower_sheep, f_sheep_properties.FSheepILadderZ, iTemp);
end

function reset()
    set_player_current_position_x(15);
    set_player_current_position_y(94);
    set_player_current_position_z(2);
    set_player_current_state(player_state.JSNORMAL);
end
