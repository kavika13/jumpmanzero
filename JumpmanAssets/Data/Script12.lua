-- TODO: Move this into a shared file, and check for other/better impls,
--       in case there are any (haven't looked)
function make_read_only(tbl)
    return setmetatable({}, {
        __index = tbl,
        __newindex = function(t, key, value)
            error("attempting to change constant " ..
                   tostring(key) .. " to " .. tostring(value), 2)
        end
    })
end

-- TODO: Move this into a shared file, split into separate tables by type
local player_state = {
    JSNORMAL = 0,
    JSJUMPING = 1,
    JSRIGHT = 2,
    JSLEFT = 4,
    JSFALLING = 8 ,
    JSLADDER = 16,
    JSKICK = 32,
    JSROLL = 64,
    JSPUNCH = 128,
    JSDYING = 256,
    JSVINE = 1024,
}
player_state = make_read_only(player_state)

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureJumpman = 0,
    TexturePurpleHex = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    MeshBeeLeft1 = 0,
    MeshBeeLeft2 = 1,
    MeshBeeRight1 = 2,
    MeshBeeRight2 = 3,
    TextureBeeTexture = 5,
    ScriptBee = 0,
    TextureBigHive = 6,
    SoundBee = 4,
}
resources = make_read_only(resources)

local is_initialized, collected_donut_count = false, 0;

function update()
    if not is_initialized then
        is_initialized = true
        set_level_extent_x(220);
    end
end

function on_collect_donut()
    collected_donut_count = collected_donut_count + 1

    if collected_donut_count == 1 then
        play_sound_effect(resources.SoundBee);
        spawn_object(resources.ScriptBee);
    end

    if collected_donut_count == 4 then
        play_sound_effect(resources.SoundBee);
        spawn_object(resources.ScriptBee);
    end

    if collected_donut_count == 10 then
        play_sound_effect(resources.SoundBee);
        spawn_object(resources.ScriptBee);
    end

    if collected_donut_count == 15 then
        play_sound_effect(resources.SoundBee);
        spawn_object(resources.ScriptBee);
    end
end

function reset()
    set_player_current_position_x(80);
    set_player_current_position_y(7);
    set_player_current_position_z(2);
    set_player_current_state(player_state.JSNORMAL);
end
