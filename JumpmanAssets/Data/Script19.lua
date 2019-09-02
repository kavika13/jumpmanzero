local read_only = require "Data/read_only";
local prop_module = assert(loadfile("Data/prop.lua"));
local whomper_module = assert(loadfile("Data/whomper.lua"));

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

local is_initialized = false;
local propellers = {};
local whompers = {};

local function ConveyPlatform(iPlat, iDist)
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

local function CreateProp(iX, iY, iR, iZ)
    local new_prop = prop_module();
    new_prop.iX = iX;
    new_prop.iY = iY;
    new_prop.iR = iR;
    new_prop.iZ = iZ;
    table.insert(propellers, new_prop);
end

local function CreateWhomper(iX, iY, iR, iRV)
    local new_whomper = whomper_module();
    new_whomper.iX = iX;
    new_whomper.iY = iY;
    new_whomper.iR = iR;
    new_whomper.iRV = iRV;
    table.insert(whompers, new_whomper);
end

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

    for _, propeller in ipairs(propellers) do
        propeller.update();
    end

    for _, whomper in ipairs(whompers) do
        whomper.update();
    end
end

function reset()
    set_player_current_position_x(20);
    set_player_current_position_y(21);
    set_player_current_position_z(3);
    set_player_current_state(player_state.JSNORMAL);
end
