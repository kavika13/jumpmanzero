local read_only = require "Data/read_only";

-- TODO: Just merge this module back into Script25?
local Module = {};

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

Module.GameLogic = nil;

Module.ChompSoundIndex = 0;
Module.CrunchSoundIndex = 0;

Module.IsInTank = false;
Module.SharkObject = nil;
Module.FacingDirection = 0;  -- TODO: This doesn't get set to anything but 0 by the parent module. Is it the shark's facing direction or the players? Maybe just simplify the code?

local function DoCollide(iX1, iY1, iX2, iY2)
    local iDonuts = get_donut_object_count();
    local is_win_detected = true;

    for iObj = 0, iDonuts - 1 do
        abs_donut(iObj);

        local iDX = get_script_selected_level_object_x1();
        local iDY = get_script_selected_level_object_y1();

        if iX1 < iDX + 2 and iX2 > iDX - 2 then
            if iY1 < iDY + 2 and iY2 > iDY - 2 then
                if get_script_selected_level_object_visible() then
                    play_sound_effect(Module.ChompSoundIndex);
                end

                set_script_selected_level_object_visible(0);
            end
        end

        if get_script_selected_level_object_visible() then
            is_win_detected = false;
        end
    end

    if is_win_detected then
        Module.GameLogic.win();
        return;
    end

    if get_player_current_state() == player_state.JSDYING then
        return;
    end

    local iDX = Module.SharkObject.CurrentPosX;
    local iDY = Module.SharkObject.CurrentPosY;

    if Module.SharkObject.CurrentVelocityX > 0 then
        if iX1 < iDX + 7 and iX2 > iDX + 1 then
            if iY1 < iDY + 7 and iY2 > iDY + 1 then
                play_sound_effect(Module.CrunchSoundIndex);
                Module.GameLogic.kill();
            end
        end
    else
        if iX1 < iDX - 1 and iX2 > iDX - 7 then
            if iY1 < iDY + 7 and iY2 > iDY + 1 then
                play_sound_effect(Module.CrunchSoundIndex);
                Module.GameLogic.kill();
            end
        end
    end
end

function Module.update()
    if not Module.IsInTank then
        return;
    end

    local iPX = get_player_current_position_x();
    local iPY = get_player_current_position_y();

    if Module.FacingDirection == 0 then
        DoCollide(iPX - 4, iPY + 3, iPX + 4, iPY + 7);
    elseif Module.FacingDirection == 1 then
        DoCollide(iPX - 3, iPY, iPX + 3, iPY + 10);
    elseif Module.FacingDirection == 2 then
        DoCollide(iPX - 8, iPY + 6, iPX - 2, iPY + 8);
        DoCollide(iPX + 2, iPY + 2, iPX + 8, iPY + 4);
    elseif Module.FacingDirection == 3 then
        DoCollide(iPX - 5, iPY + 4, iPX + 5, iPY + 6);
    elseif Module.FacingDirection == 4 then
        DoCollide(iPX + 2, iPY + 6, iPX + 8, iPY  +8);
        DoCollide(iPX - 8, iPY + 2, iPX - 2, iPY + 4);
    end
end

return Module;
