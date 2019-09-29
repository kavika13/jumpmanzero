local read_only = require "Data/read_only";
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local run_donut_module = assert(loadfile("Data/run_donut.lua"));
local bullet_module = assert(loadfile("Data/bullet.lua"));

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
};
resources = read_only.make_table_read_only(resources);

local is_initialized = false;
local g_is_first_update_complete = false;

local g_hud_overlay;
local g_run_donuts = {};
local g_bullets = {};

local function OnKillRunDonut_(run_donut)
    for index, value in ipairs(g_run_donuts) do
        if value == run_donut then
            table.remove(g_run_donuts, index);
            return;
        end
    end

    assert(false, "Was unable to find run donut to remove");
end

local OnSpawnRunDonut_ = nil;

local function CreateRunDonut_()
    local new_run_donut = run_donut_module();
    new_run_donut.MoveMeshResourceIndices = {
        resources.MeshRunDonut1, resources.MeshRunDonut2, resources.MeshRunDonut3,
    };
    new_run_donut.HatchMeshResourceIndices = {
        resources.MeshRunDonutHatch1, resources.MeshRunDonutHatch2, resources.MeshRunDonutHatch3,
        resources.MeshRunDonutHatch4, resources.MeshRunDonutHatch5,
    };
    new_run_donut.TextureResourceIndex = resources.TextureRunDonut;
    new_run_donut.SpawnCallback = OnSpawnRunDonut_;
    new_run_donut.KillCallback = OnKillRunDonut_;
    return new_run_donut;
end

OnSpawnRunDonut_ = function()
    local new_run_donut = CreateRunDonut_();
    table.insert(g_run_donuts, new_run_donut);
    return new_run_donut;
end

function update(game_input, is_initialized)
    if not is_initialized then
        is_initialized = true;

        g_hud_overlay = hud_overlay_module();

        local iTemp = bullet_module();
        iTemp.FramesToWait = 100;
        iTemp.Mesh1Index = resources.MeshBullet1;
        iTemp.Mesh2Index = resources.MeshBullet2;
        iTemp.TextureIndex = resources.TextureBullet;
        iTemp.FireSoundIndex = resources.SoundFire;
        table.insert(g_bullets, iTemp);

        local iX = 40;

        while iX < 150 do
            local iY = 20;

            while iY < 180 do
                local new_run_donut = CreateRunDonut_();
                new_run_donut.InitialPosX = iX + iY / 8;
                new_run_donut.InitialPosY = iY;
                table.insert(g_run_donuts, new_run_donut);
                iY = iY + 30;
            end

            iX = iX + 20;
        end
    end

    if not g_hud_overlay.update(game_input) and g_is_first_update_complete then
        return false;
    end

    for _, run_donut in ipairs(g_run_donuts) do
        run_donut.update(g_run_donuts);
    end

    for _, bullet in ipairs(g_bullets) do
        bullet.update();
    end

    if not g_is_first_update_complete then
        g_is_first_update_complete = true;
        return false;
    end

    return true;
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
