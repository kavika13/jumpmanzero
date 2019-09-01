local read_only = require "Data/read_only";
local bullet_module = loadfile("Data/bullet.lua");

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
    TextureBullet = 4,
    Texturesky = 5,
    ScriptBullet = 0,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    SoundJump = 0,
    Soundchomp = 1,
    Soundbonk = 2,
    SoundFire = 3,
    MeshRunDonut1 = 2,
    MeshRunDonut2 = 3,
    MeshRunDonut3 = 4,
    TextureRunDonut = 6,
    ScriptRunDonut = 1,
    MeshRunDonutHatch1 = 5,
    MeshRunDonutHatch2 = 6,
    MeshRunDonutHatch3 = 7,
    MeshRunDonutHatch4 = 8,
    MeshRunDonutHatch5 = 9,
}
resources = read_only.make_table_read_only(resources);

-- TODO: Separate file?
local run_donut_properties = {
    RunDonutStartX = 0,
    RunDonutStartY = 1,
    RunDonutITimeAlive = 2,
    RunDonutIdCount = 3,
    RunDonutIStatus = 4,
    RunDonutICount = 5,
    RunDonutIDir = 6,
    RunDonutIFrame = 7,
    RunDonutIInit = 8,
    RunDonutIMeshes = 9,
    RunDonutIX = 20,
    RunDonutIY = 21,
    RunDonutIZ = 22,
    RunDonutISlow = 23,
    RunDonutIRotate = 24,
    RunDonutIXV = 25,
    RunDonutIYV = 26,
}
run_donut_properties = read_only.make_table_read_only(run_donut_properties);

local is_initialized = false;
local g_bullets = {};

function update()
    if not is_initialized then
        is_initialized = true;

        local iTemp = bullet_module();
        iTemp.FramesToWait = 100;
        iTemp.Mesh1Index = resources.MeshBullet1;
        iTemp.Mesh2Index = resources.MeshBullet2;
        iTemp.TextureIndex = resources.TextureBullet;
        iTemp.FireSoundIndex = resources.SoundFire;
        table.insert(g_bullets, iTemp);

        local iX = 40;

        while iX < 150
        do
            local iY = 20;

            while iY < 180
            do
                iTemp = spawn_object(resources.ScriptRunDonut);
                set_object_global_data(iTemp, run_donut_properties.RunDonutStartX, iX + iY / 8);
                set_object_global_data(iTemp, run_donut_properties.RunDonutStartY, iY);
                iY = iY + 30;
            end

            iX = iX + 20;
        end
    end

    for _, bullet in ipairs(g_bullets) do
        bullet.update();
    end
end

function reset()
    set_player_current_position_x(20);
    set_player_current_position_y(4);
    set_player_current_position_z(2);
    set_player_current_state(player_state.JSNORMAL);

    for _, bullet in ipairs(g_bullets) do
        bullet.reset_pos();
    end
end
