local read_only = require "data/read_only";

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

local function DoCollide_(player_left_x, player_bottom_y, player_right_x, player_top_y)
    local donut_count = Module.GameLogic.get_donut_object_count();
    local is_win_detected = true;

    for donut_index = 0, donut_count - 1 do
        local current_donut = Module.GameLogic.get_donut(donut_index);

        if player_left_x < current_donut.pos[1] + 2 and player_right_x > current_donut.pos[1] - 2 then
            if player_bottom_y < current_donut.pos[2] + 2 and player_top_y > current_donut.pos[2] - 2 then
                if not Module.GameLogic.get_donut_is_collected(donut_index) then
                    play_sound_effect(Module.ChompSoundIndex);
                end

                Module.GameLogic.set_donut_is_collected(donut_index, true);
                set_mesh_is_visible(current_donut.mesh_index, false);
            end
        end

        if not Module.GameLogic.get_donut_is_collected(donut_index) then
            is_win_detected = false;
        end
    end

    if is_win_detected then
        Module.GameLogic.win();
        return;
    end

    if Module.GameLogic.get_player_current_state() == player_state.JSDYING then
        return;
    end

    local shark_pos_x = Module.SharkObject.CurrentPosX;
    local shark_pos_y = Module.SharkObject.CurrentPosY;

    if Module.SharkObject.CurrentVelocityX > 0 then
        if player_left_x < shark_pos_x + 7 and player_right_x > shark_pos_x + 1 then
            if player_bottom_y < shark_pos_y + 7 and player_top_y > shark_pos_y + 1 then
                -- TODO: Handle case where jumpman jumps out but gets crunched. Currently can still live
                play_sound_effect(Module.CrunchSoundIndex);
                Module.GameLogic.kill();
            end
        end
    else
        if player_left_x < shark_pos_x - 1 and player_right_x > shark_pos_x - 7 then
            if player_bottom_y < shark_pos_y + 7 and player_top_y > shark_pos_y + 1 then
                -- TODO: Handle case where jumpman jumps out but gets crunched. Currently can still live
                play_sound_effect(Module.CrunchSoundIndex);
                Module.GameLogic.kill();
            end
        end
    end
end

function Module.initialize()
    -- Nothing to do!
end

function Module.update()
    if not Module.IsInTank then
        return;
    end

    local player_pos_x = Module.GameLogic.get_player_current_position_x();
    local player_pos_y = Module.GameLogic.get_player_current_position_y();

    if Module.FacingDirection == 0 then
        DoCollide_(player_pos_x - 4, player_pos_y + 3, player_pos_x + 4, player_pos_y + 7);
    elseif Module.FacingDirection == 1 then
        DoCollide_(player_pos_x - 3, player_pos_y, player_pos_x + 3, player_pos_y + 10);
    elseif Module.FacingDirection == 2 then
        DoCollide_(player_pos_x - 8, player_pos_y + 6, player_pos_x - 2, player_pos_y + 8);
        DoCollide_(player_pos_x + 2, player_pos_y + 2, player_pos_x + 8, player_pos_y + 4);
    elseif Module.FacingDirection == 3 then
        DoCollide_(player_pos_x - 5, player_pos_y + 4, player_pos_x + 5, player_pos_y + 6);
    elseif Module.FacingDirection == 4 then
        DoCollide_(player_pos_x + 2, player_pos_y + 6, player_pos_x + 8, player_pos_y  +8);
        DoCollide_(player_pos_x - 8, player_pos_y + 2, player_pos_x - 2, player_pos_y + 4);
    end
end

return Module;
