local read_only = require "Data/read_only";
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
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
};
player_state = read_only.make_table_read_only(player_state);

local g_is_initialized = false;
local g_is_first_update_complete = false;

local g_hud_overlay;
local propellers = {};
local whompers = {};

local function ConveyPlatform(iPlat, iDist)
    select_platform(iPlat);
    script_selected_mesh_scroll_texture(iDist * 16, 0);

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

    if g_game_logic.get_player_current_active_platform_index() == iPN then
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

function update(game_input, is_initializing)
    if not g_is_initialized then
        g_is_initialized = true;

        g_game_logic = game_logic_module();
        g_game_logic.ResetPlayerCallback = reset;

        g_hud_overlay = hud_overlay_module();

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

    -- TODO: Can probably make a parent meta script that calls into this and into hud_overlay.
    --       That should simplify this logic drastically.
    --       Probably best to do that with the level loader refactor?
    if is_initializing or g_title_is_done_scrolling then
        g_game_logic.progress_game(game_input);
        g_hud_overlay.update(game_input);
    elseif g_is_first_update_complete then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return false;
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

    if not g_is_first_update_complete then
        g_is_first_update_complete = true;
        return false;
    end

    return true;
end

function reset()
    set_player_current_position_x(20);
    set_player_current_position_y(21);
    set_player_current_position_z(3);
    set_player_current_state(player_state.JSNORMAL);
end
