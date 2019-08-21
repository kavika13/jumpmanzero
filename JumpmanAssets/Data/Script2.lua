-- TODO: Move this into a shared file, and check for other/better impls,
--       in case there are any (haven't looked)
function make_read_only(tbl)
    return setmetatable({}, {
        __index = tbl,
        __newindex = function(t, key, value)
            error("attempting to change constant " ..
                   tostring(key) .. " to " .. tostring(value), 2)
        end
    });
end

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
player_state = make_read_only(player_state);

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
resources = make_read_only(resources);

-- TODO: Separate file?
local drop_properties = {
    DropIInit = 0,
    DropIMesh1 = 1,
    DropIMesh2 = 2,
    DropIX = 3,
    DropIY = 4,
    DropWait = 5,
    DropIStatus = 6,
    DropIFrame = 7,
}
drop_properties = make_read_only(drop_properties);

local is_initialized = false;

function update()
    if not is_initialized then
        is_initialized = true;

        local iTemp = spawn_object(resources.ScriptDrop);
        set_object_global_data(iTemp, drop_properties.DropWait, 700);

        iTemp = spawn_object(resources.ScriptDrop);
        set_object_global_data(iTemp, drop_properties.DropWait, 600);

        iTemp = spawn_object(resources.ScriptDrop);
        set_object_global_data(iTemp, drop_properties.DropWait, 500);

        iTemp = spawn_object(resources.ScriptDrop);
        set_object_global_data(iTemp, drop_properties.DropWait, 400);

        iTemp = spawn_object(resources.ScriptDrop);
        set_object_global_data(iTemp, drop_properties.DropWait, 300);

        iTemp = spawn_object(resources.ScriptDrop);
        set_object_global_data(iTemp, drop_properties.DropWait, 200);

        iTemp = spawn_object(resources.ScriptDrop);
        set_object_global_data(iTemp, drop_properties.DropWait, 100);

        spawn_object(resources.ScriptWave);
    end
end

function reset()
    set_player_current_position_x(10);
    set_player_current_position_y(73);
    set_player_current_position_z(2);
    set_player_current_state(player_state.JSNORMAL);
end
