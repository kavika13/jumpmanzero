local read_only = require "Data/read_only";
local wave_module = assert(loadfile("Data/wave.lua"));
local drop_module = assert(loadfile("Data/drop.lua"));

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
}
player_state = read_only.make_table_read_only(player_state);

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureJumpman = 0,
    TextureWoodPlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    ScriptWave = 0,
    ScriptDrop = 1,
    TextureSea = 5,
    TextureWave1 = 6,
    TextureWave2 = 7,
    TextureDrop = 8,
    TextureSplash1 = 9,
    TextureSplash2 = 10,
    TextureSplash3 = 11,
    MeshSea = 0,
    MeshWave = 1,
    MeshDrop = 2,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
}
resources = read_only.make_table_read_only(resources);

local is_initialized = false;
local g_drop_objects = {};
local g_wave_object;

local function IsDropTooCloseToOtherDrops(current_drop)
    local current_x = current_drop.get_current_pos_x();

    for _, other_drop in ipairs(g_drop_objects) do
        if other_drop ~= current_drop then
            local other_x = other_drop.get_current_pos_x();
            local other_y = other_drop.get_current_pos_y();

            if other_y > 120 and other_x < (current_x + 10) and other_x > (current_x - 10) then
                return true;
            end
        end
    end

    return false;
end

local function CreateDropObject(frames_to_wait)
    local new_drop_object = drop_module();
    new_drop_object.IsTooCloseToOtherDropsCallback = IsDropTooCloseToOtherDrops;
    new_drop_object.FramesToWait = frames_to_wait;
    new_drop_object.DropMeshResourceIndex = resources.MeshDrop;
    new_drop_object.DropTextureResourceIndices = { resources.TextureDrop, resources.TextureSplash1, resources.TextureSplash2, resources.TextureSplash3 };
    return new_drop_object;
end

function update()
    if not is_initialized then
        is_initialized = true;

        table.insert(g_drop_objects, CreateDropObject(700));
        table.insert(g_drop_objects, CreateDropObject(600));
        table.insert(g_drop_objects, CreateDropObject(500));
        table.insert(g_drop_objects, CreateDropObject(400));
        table.insert(g_drop_objects, CreateDropObject(300));
        table.insert(g_drop_objects, CreateDropObject(200));
        table.insert(g_drop_objects, CreateDropObject(100));

        local new_wave_object = wave_module();
        new_wave_object.SeaMeshResourceIndex = resources.MeshSea;
        new_wave_object.WaveMeshResourceIndex = resources.MeshWave;
        new_wave_object.SeaTextureResourceIndex = resources.TextureSea;
        new_wave_object.Wave1TextureResourceIndex = resources.TextureWave1;
        new_wave_object.Wave2TextureResourceIndex = resources.TextureWave2;
        g_wave_object = new_wave_object;
    end

    for _, drop in ipairs(g_drop_objects) do
        drop.update();
    end

    g_wave_object.update();
end

function reset()
    set_player_current_position_x(10);
    set_player_current_position_y(73);
    set_player_current_position_z(2);
    set_player_current_state(player_state.JSNORMAL);
end
