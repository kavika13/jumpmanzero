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
    TexturePrisoner = 0,
    TextureTileStone = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    MeshChain = 0,
    TextureChain = 5,
    TextureLitFountain = 6,
    ScriptBullet = 0,
    ScriptChain = 1,
    MeshBullet1 = 1,
    MeshBullet2 = 2,
    TextureBullet = 7,
}
resources = read_only.make_table_read_only(resources);

-- TODO: Separate file?
local chain_properties = {
    ChainIInit = 0,
    ChainIMeshes = 1,
    ChainX1 = 32,
    ChainY1 = 33,
    ChainX2 = 34,
    ChainY2 = 35,
    ChainZ = 36,
    ChainLength = 37,
    ChainBNoUp = 38,
    ChainBNoDown = 39,
    ChainIPlayerAir = 40,
}
chain_properties = read_only.make_table_read_only(chain_properties);

-- TODO: Separate file?
local bullet_properties = {
    BulletIFiring = 0,
    BulletResMesh1 = 1,
    BulletResMesh2 = 2,
    BulletResTexture = 3,
    BulletIInit = 4,
    BulletIX = 5,
    BulletIY = 6,
    BulletIZ = 7,
    BulletIXV = 8,
    BulletIYV = 9,
    BulletIMesh1 = 10,
    BulletIMesh2 = 11,
    BulletISlow = 12,
    BulletIOut = 13,
    BulletISpin1 = 14,
    BulletISpin2 = 15,
    BulletWait = 16,
    BulletIMaxX = 17,
}
bullet_properties = read_only.make_table_read_only(bullet_properties);

local g_init_stage_index = 0;
local g_chain;
local g_chain_length;
local g_target_length;

function update()
    if g_init_stage_index == 1 then
        local iLoop = 1;

        while iLoop < 5
        do
            local iTemp = spawn_object(resources.ScriptBullet);
            set_object_global_data(iTemp, bullet_properties.BulletResMesh1, resources.MeshBullet1);
            set_object_global_data(iTemp, bullet_properties.BulletResMesh2, resources.MeshBullet2);
            set_object_global_data(iTemp, bullet_properties.BulletResTexture, resources.TextureBullet);
            iLoop = iLoop + 1;
        end

        g_init_stage_index = 2;

        select_picture(1);
        prioritize_object();

        select_picture(100);
        prioritize_object();
    end

    if g_init_stage_index == 0 then
        g_init_stage_index = 1;
        g_chain_length = 10;
        g_target_length = 20;
        g_chain = spawn_object(resources.ScriptChain);
    end

    SetChainLength();
end

function SetChainLength()
    if g_chain_length < g_target_length then
        g_chain_length = g_chain_length + 1;
    end

    set_object_global_data(g_chain, chain_properties.ChainLength, g_chain_length);
end

function on_collect_donut()
    g_target_length = g_target_length + get_script_event_data_1();
end

function reset()
    set_player_current_position_x(70);
    set_player_current_position_y(62);
    set_player_current_position_z(2);
    set_player_current_state(player_state.JSNORMAL);
end
