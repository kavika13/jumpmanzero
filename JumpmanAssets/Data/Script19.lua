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
    TextureConveyor = 1,
    TextureWaterBack = 2,
    TextureRedMetal = 3,
    TextureDarkSky = 4,
    SoundJump = 0,
    Soundchomp = 1,
    Soundbonk = 2,
    SoundFire = 3,
    ScriptBullet = 0,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    TextureBullet = 5,
    MeshWhomper = 2,
    Meshprop = 3,
    TextureBoringGray = 6,
    ScriptWhomper = 1,
    ScriptProp = 2,
    TextureConveyor = 7,
}
resources = make_read_only(resources);

-- TODO: Separate file?
local whomper_properties = {
    WhomperInit = 0,
    WhomperMesh = 1,
    WhomperX = 2,
    WhomperY = 3,
    WhomperR = 4,
    WhomperRV = 5,
}
whomper_properties = make_read_only(whomper_properties);

-- TODO: Separate file?
local propeller_properties = {
    PropInit = 0,
    PropMesh = 1,
    PropX = 2,
    PropY = 3,
    PropZ = 4,
    PropR = 5,
}
propeller_properties = make_read_only(propeller_properties);

local is_initialized = false;

function update()
    if not is_initialized then
        is_initialized = true;

        CreateWhomper(86, 28, 50, 3);
        CreateWhomper(100, 28, 0, 3);
        CreateWhomper(114, 28, 1, -3);
        CreateWhomper(128, 28, -90, 1);

        CreateWhomper(55, 143, 0, 3);
        CreateWhomper(73, 143, 50, 3);
        CreateWhomper(95, 143, -50, -3);

        CreateProp(34, 90, 80, 5);
        CreateProp(34, 90, 120, 5);

        CreateProp(60, 46, 90, 2);
        CreateProp(60, 56, 90, 2);

        CreateProp(120, 46, 335, 2);
        CreateProp(120, 46, 25, 2);

        CreateProp(99, 105, 80, 2);
        CreateProp(101, 97, 25, 2);
    end

    ConveyPlatform(1, 0.04);
    ConveyPlatform(2, -0.02);
    ConveyPlatform(3, 0.04);
    ConveyPlatform(4, -0.04);
end

function ConveyPlatform(iPlat, iDist)
    select_platform(iPlat)
    script_selected_mesh_scroll_texture(iDist * 16, 0)

    local iPN, iPX, iPY, iHit;

    iPX = get_player_current_position_x();
    iPY = get_player_current_position_y();

    if get_player_current_state() == player_state.JSJUMPING then
        return 0;
    end

    iPN = find_platform(iPX, iPY, 14, 2);
    iHit = get_script_event_data_4();

    abs_platform(iPN);

    if iPlat ~= get_script_selected_level_object_number() then
        return 0;
    end

    if get_script_event_data_2() == iPN then
        iPX = iPX - iDist * 15;

        if get_player_current_state() == 4096 then  -- TODO: Is this a custom state?
            set_player_current_state(player_state.JSFALLING);
            set_player_current_state_frame_count(0);
        end

        set_player_current_position_x(iPX);
    end

    -- if (iHit + 1) >= iPY then
    --     iPX = iPX - iDist * 15;
    --     set_player_current_position_x(iPX);
    -- end
end

function CreateProp(iX, iY, iR, iZ)
    local iProp = spawn_object(resources.ScriptProp);
    set_object_global_data(iProp, propeller_properties.PropX, iX);
    set_object_global_data(iProp, propeller_properties.PropY, iY);
    set_object_global_data(iProp, propeller_properties.PropR, iR);
    set_object_global_data(iProp, propeller_properties.PropZ, iZ);
end

function CreateWhomper(iX, iY, iR, iRV)
    local iWhomp = spawn_object(resources.ScriptWhomper);
    set_object_global_data(iWhomp, whomper_properties.WhomperX, iX);
    set_object_global_data(iWhomp, whomper_properties.WhomperY, iY);
    set_object_global_data(iWhomp, whomper_properties.WhomperR, iR);
    set_object_global_data(iWhomp, whomper_properties.WhomperRV, iRV);
end

function reset()
    set_player_current_position_x(20);
    set_player_current_position_y(21);
    set_player_current_position_z(3);
    set_player_current_state(player_state.JSNORMAL);
end
