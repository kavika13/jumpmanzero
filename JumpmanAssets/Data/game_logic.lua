local read_only = require "Data/read_only";

local Module = {};

Module.ResetPlayerCallback = nil;  -- TODO: Do we have to inject this function?
Module.OnCollectDonutCallback = nil;  -- TODO: Do we have to inject this function?

-- TODO: Expose this to callers?
local player_state = {
    -- TODO: Rename these
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
    JSDONE = 512,
    JSVINE = 1024,
    JSSLIDE = 2048,
};
player_state = read_only.make_table_read_only(player_state);

-- TODO: Expose this to callers?
local player_movement_direction = {
    -- TODO: Rename these
    DIR_UP = 1,
    DIR_DOWN = 2,
    DIR_LEFT = 3,
    DIR_RIGHT = 4,
};
player_movement_direction = read_only.make_table_read_only(player_movement_direction);

-- TODO: Expose this to callers?
local player_special_action = {
    NONE = 0,
    KICK = 1,
    PUNCH = 2,
};
player_special_action = read_only.make_table_read_only(player_special_action);

local player_mesh = {
    STAND = 1,
    LEFT_1 = 2,
    LEFT_2 = 3,
    RIGHT_1 = 4,
    RIGHT_2 = 5,
    JUMP_LEFT = 6,
    JUMP_RIGHT = 7,
    JUMP_UP = 8,
    VINE_CLIMB_1 = 9,
    VINE_CLIMB_2 = 10,
    LADDER_CLIMB_1 = 11,
    LADDER_CLIMB_2 = 12,
    KICK_LEFT = 13,
    KICK_RIGHT = 14,

    DIVE_RIGHT = 15,
    ROLL_RIGHT_1 = 16,
    ROLL_RIGHT_2 = 17,
    ROLL_RIGHT_3 = 18,
    ROLL_RIGHT_4 = 19,

    DIVE_LEFT = 20,
    ROLL_LEFT_1 = 21,
    ROLL_LEFT_2 = 22,
    ROLL_LEFT_3 = 23,
    ROLL_LEFT_4 = 24,

    PUNCH_LEFT_1 = 25,
    PUNCH_RIGHT_1 = 26,
    PUNCH_LEFT_2 = 27,
    PUNCH_RIGHT_2 = 28,
    DYING = 29,
    DEAD = 30,
    STARS = 31,
    SLIDE_RIGHT = 32,
    SLIDE_RIGHT_B = 33,
    SLIDE_LEFT = 34,
    SLIDE_LEFT_B = 35,
    BORED_1 = 36,
    BORED_2 = 37,
    BORED_3 = 38,
    BORED_4 = 39,
    BORED_5 = 40,
};
player_mesh = read_only.make_table_read_only(player_mesh);

local player_dying_animation_state = {
    BOUNCING = 0,
    FALLING = 1,
    FINAL_BOUNCE = 2,
    SPINNING_STARS = 10,
};
player_dying_animation_state = read_only.make_table_read_only(player_dying_animation_state);

-- TODO: Do we have to initialize all these?
local g_player_old_position_x = 0;
local g_player_old_position_y = 0;
local g_player_current_direction = 0;
local g_is_already_on_ladder = false;

local g_player_current_close_ladder_index = -1;
local g_player_current_exact_ladder_index = -1;
local g_player_current_platform_index = -1;
local g_player_current_active_platform_index = -1;  -- Masked out if player is dead or if player is below it
local g_player_current_platform_y = 0;
local g_player_current_close_vine_index = -1;
local g_player_current_exact_vine_index = -1;

-- Movement function calls are almost cyclic, so there's no perfect function order. Pre-declaring them here instead
local MoveJumpmanVine_ = nil;
local MoveJumpmanLadder_ = nil;
local MoveJumpmanJumping_ = nil;
local MoveJumpmanNormal_ = nil;
local MoveJumpmanFalling_ = nil;
local MoveJumpmanSlide_ = nil;
local MoveJumpmanRoll_ = nil;
local MoveJumpmanPunch_ = nil;

local function PlayerFloor_()
    local iFloor = 0;

    if (get_player_current_state() & player_state.JSJUMPING) ~= 0 and get_player_current_state_frame_count() < 12 then
        iFloor = 4;
    end

    return iFloor;
end

local function PlayerHeight_()
    local iHeight = 14;

    if (get_player_current_state() & player_state.JSROLL) ~= 0 then
        iHeight = 7;
    end

    if (get_player_current_state() & player_state.JSPUNCH) ~= 0 then
        iHeight = 9;
    end

    if (get_player_current_state() & player_state.JSDYING) ~= 0 then
        iHeight = 7;
    end

    return iHeight;
end

local function FindVine_(iX, iY)
    -- TODO: Figure out what "iX", "iY" mean, and change names to reflect that
    local iAbout = -1;
    local iExact = -1;

    iX = math.floor(iX);
    iY = math.floor(iY);

    for iV = 0, get_vine_object_count() - 1 do
        if iAbout == -1 or get_vine_y1(iAbout) < get_vine_y1(iV) then
            if get_vine_y1(iV) - 3 > iY and get_vine_y2(iV) - 9 < iY then
                if get_vine_x1(iV) - 3 < iX and get_vine_x1(iV) + 3 > iX then
                    iAbout = iV;

                    if get_vine_x1(iV) == iX then
                        iExact = iV;
                    end
                end
            end
        end
    end

    return iAbout, iExact;
end

local function FindLadder_(iX, iY)
    -- TODO: Figure out what "iX", "iY" mean, and change names to reflect that
    local iAbout = -1;
    local iExact = -1;
    local iBestDif = 1000;

    iX = math.floor(iX);
    iY = math.floor(iY);

    for iL = 0, get_ladder_object_count() - 1 do
        if iAbout == -1 or get_ladder_y1(iAbout) < get_ladder_y1(iL) then
            if get_ladder_y1(iL) - 3 > iY and get_ladder_y2(iL) - 9 < iY then
                iDiff = get_ladder_x1(iL) - iX;

                if iDiff < 0 then
                    iDiff = iDiff * -1;
                end

                if iDiff < 8 and iDiff <= iBestDif then
                    iBestDif = iDiff;
                    iAbout = iL;

                    if iDiff == 0 then
                        iExact = iL;
                    end
                end
            end
        end
    end

    return iAbout, iExact;
end

local function FindPlatform_(iX, iY, iHeight, iWide)
    -- TODO: Figure out what "iX", "iY" mean, and change names to reflect that
    local iPlatform = -1;
    local iSupport = -1;
    local iExtra = 0;

    iX = math.floor(iX);
    iY = math.floor(iY);

    for iP = 0, get_platform_object_count() - 1 do
        if get_platform_x1(iP) <= iX + iWide and get_platform_x2(iP) >= iX - iWide then
            local iEX = iX;

            if iEX < get_platform_x1(iP) then
                iEX = get_platform_x1(iP);
            end

            if iEX > get_platform_x2(iP) then
                iEX = get_platform_x2(iP);
            end

            local iLen = get_platform_x2(iP) - get_platform_x1(iP);
            local iH = get_platform_y1(iP) * math.abs(math.floor(get_platform_x2(iP) - iEX)) +  -- TODO: Floor necessary?
                get_platform_y2(iP) * math.abs(math.floor(get_platform_x1(iP) - iEX));  -- TODO: Floor necessary?
            iH = iH / iLen;

            local bGood = false;

            if get_platform_extra(iP) == 3 then
                if iH < iY + 1.5 and iH >= iY then
                    bGood = true;
                end

                if get_player_current_state() == player_state.JSROLL and get_player_current_state_frame_count() < 6 then
                    bGood = false;
                end
            else
                if iH < iY + iHeight then
                    bGood = true;
                end
            end

            if bGood and (iH > iSupport or (iH == iSupport and (iExtra == 1 or iExtra == 2))) then
                iSupport = iH;
                iPlatform = iP;
                iExtra = get_platform_extra(iP);
            end
        end
    end

    return iSupport, iPlatform;
end

local function PointInQuad_(iX0, iY0, iX1, iY1, iX2, iY2, iX3, iY3, iX4, iY4)
    -- TODO: Figure out what "iX0", "iY0", etc mean, and change names to reflect that
    local total = 0;

    local iBX = iX2 - iX1;
    local iBY = iY2 - iY1;
    local iSX = iX0 - iX1;
    local iSY = iY0 - iY1;
    local det = iBX * iSY - iBY * iSX;

    if det <= 0 then
        total = total + 1;
    end

    iBX = iX3 - iX2;
    iBY = iY3 - iY2;
    iSX = iX0 - iX2;
    iSY = iY0 - iY2;
    det = iBX * iSY - iBY * iSX;

    if det <= 0 then
        total = total + 1;
    end

    iBX = iX4 - iX3;
    iBY = iY4 - iY3;
    iSX = iX0 - iX3;
    iSY = iY0 - iY3;
    det = iBX * iSY - iBY * iSX;

    if det <= 0 then
        total = total + 1;
    end

    iBX = iX1 - iX4;
    iBY = iY1 - iY4;
    iSX = iX0 - iX4;
    iSY = iY0 - iY4;
    det = iBX * iSY - iBY * iSX;

    if det <= 0 then
        total = total + 1;
    end

    if total == 4 then
        return true;
    end

    return false;
end

local function CollideWall_(x1, y1, x2, y2)
    -- TODO: Figure out what "x1", "y1", "x2", "y2" mean, and change names to reflect that
    local iLeft = 0;
    local iRight = 0;
    local iTop = 0;
    local iBottom = 0;

    x1 = math.floor(x1);
    y1 = math.floor(y1);
    x2 = math.floor(x2);
    y2 = math.floor(y2);

    for iW = 0, get_wall_object_count() - 1 do
        local wall_x1 = get_wall_x1(iW);
        local wall_x2 = get_wall_x2(iW);
        local wall_x3 = get_wall_x3(iW);
        local wall_x4 = get_wall_x4(iW);
        local wall_y1 = get_wall_y1(iW);
        local wall_y2 = get_wall_y2(iW);
        local wall_y3 = get_wall_y3(iW);
        local wall_y4 = get_wall_y4(iW);

        if PointInQuad_(x1, y1, wall_x1, wall_y1, wall_x2, wall_y2, wall_x3, wall_y3, wall_x4, wall_y4) then
            iLeft = iLeft + 1;
            iTop = iTop + 1;
        end

        if PointInQuad_(x2, y1, wall_x1, wall_y1, wall_x2, wall_y2, wall_x3, wall_y3, wall_x4, wall_y4) then
            iRight = iRight + 1;
            iTop = iTop + 1;
        end

        if PointInQuad_(x1, y2, wall_x1, wall_y1, wall_x2, wall_y2, wall_x3, wall_y3, wall_x4, wall_y4) then
            iLeft = iLeft + 1;
            iBottom = iBottom + 1;
        end

        if PointInQuad_(x2, y2, wall_x1, wall_y1, wall_x2, wall_y2, wall_x3, wall_y3, wall_x4, wall_y4) then
            iRight = iRight + 1;
            iBottom = iBottom + 1;
        end
    end

    if iTop > 1 then
        return 1;
    end

    if iLeft > 0 then
        return 3;
    end

    if iRight > 0 then
        return 4;
    end

    return 0;
end

local function PlayerCollide_(x1, y1, x2, y2)
    -- TODO: Figure out what "x1", "y1", "x2", "y2" mean, and change names to reflect that
    local player_pos_x = get_player_current_position_x();
    local player_pos_y = get_player_current_position_y();
    local is_player_jumping = (get_player_current_state() & player_state.JSJUMPING) ~= 0;
    local is_player_rolling = (get_player_current_state() & player_state.JSROLL) ~= 0;

    if is_player_jumping then
        if player_pos_x + 4 > x1 and player_pos_y + 9 > y1 and player_pos_x - 4 < x2 and player_pos_y + 4 < y2 then
            return true;
        end
    elseif is_player_rolling and get_player_absolute_frame_count() < 12 then
        if player_pos_x + 4 > x1 and player_pos_y + 7 > y1 and player_pos_x - 4 < x2 and player_pos_y + 3 < y2 then
            return true;
        end
    elseif is_player_rolling then
        if player_pos_x + 3 > x1 and player_pos_y + 7 > y1 and player_pos_x - 3 < x2 and player_pos_y < y2 then
            return true;
        end
    else
        if player_pos_x + 2 > x1 and player_pos_y + 9 > y1 and player_pos_x - 2 < x2 and player_pos_y + 2 < y2 then
            return true;
        end
    end

    return false;
end

local function UpdateSituation_()
    g_player_current_close_vine_index, g_player_current_exact_vine_index = FindVine_(
        get_player_current_position_x(), get_player_current_position_y());

    g_player_current_close_ladder_index, g_player_current_exact_ladder_index = FindLadder_(
        get_player_current_position_x(), get_player_current_position_y());

    g_player_current_platform_y, g_player_current_platform_index = FindPlatform_(
        get_player_current_position_x(), get_player_current_position_y(), PlayerHeight_(), 2);
    g_player_current_platform_y = g_player_current_platform_y - PlayerFloor_();

    g_player_current_active_platform_index = -1;

    if g_player_current_platform_y >= get_player_current_position_y() then
        g_player_current_active_platform_index = g_player_current_platform_index;
    end
end

local function CheckJumpStart_(iLeft, iUp, iRight, game_input)
    if not game_input.jump_action.is_pressed then
        return false;
    end

    if iLeft and game_input.move_left_action.is_pressed and not game_input.move_right_action.is_pressed then
        g_player_current_direction = player_movement_direction.DIR_LEFT;
    elseif iRight and game_input.move_right_action.is_pressed and not game_input.move_left_action.is_pressed then
        g_player_current_direction = player_movement_direction.DIR_RIGHT;
    elseif iUp then
        g_player_current_direction = player_movement_direction.DIR_UP;
    else
        return false;
    end

    set_player_current_special_action(player_special_action.NONE);
    set_player_current_state_frame_count(0);

    play_sound_effect(0);

    MoveJumpmanJumping_(game_input);

    return true;
end

local function CheckWalkOff_(iCenter, game_input)
    if get_player_current_position_x() < iCenter and game_input.move_right_action.is_pressed then
        return false;
    end

    if get_player_current_position_x() > iCenter and game_input.move_left_action.is_pressed then
        return false;
    end

    if game_input.move_down_action.is_pressed and get_player_current_position_y() < g_player_current_platform_y - 2 then
        return false;
    end

    if get_player_current_position_y() <= g_player_current_platform_y and
            (game_input.move_left_action.is_pressed ~= game_input.move_right_action.is_pressed) then
        MoveJumpmanNormal_(game_input);
        return true;
    end

    return false;
end

local function AdjustPlayerZ_(iTargetZ, iTime)
    -- TODO: Might have some  oscillation problems if these end up being floating point values
    if iTime < math.abs(iTargetZ - get_player_current_position_z()) then
        if iTargetZ < get_player_current_position_z() then
            set_player_current_position_z(get_player_current_position_z() - 1);
        end

        if iTargetZ > get_player_current_position_z() then
            set_player_current_position_z(get_player_current_position_z() + 1);
        end
    end
end

MoveJumpmanVine_ = function(game_input)
    set_player_current_state(player_state.JSVINE);
    set_player_current_special_action(player_special_action.NONE);

    if g_player_current_close_vine_index == -1 then
        set_player_current_state(player_state.JSNORMAL);
        return;
    end

    if CheckJumpStart_(1, 0, 1, game_input) then
        return;
    end

    if CheckWalkOff_(get_vine_x1(g_player_current_close_vine_index), game_input) then
        return;
    end

    set_player_current_mesh(
        (get_player_absolute_frame_count() & 2) ~= 0 and player_mesh.VINE_CLIMB_1 or player_mesh.VINE_CLIMB_2);
    AdjustPlayerZ_(get_vine_z1(g_player_current_close_vine_index) - 3, 0);

    if get_vine_y2(g_player_current_close_vine_index) < g_player_current_platform_y - 2 or
            get_player_current_position_y() > g_player_current_platform_y - 1 then
        set_player_current_position_y(get_player_current_position_y() - 1);
    else
        MoveJumpmanNormal_(game_input);
        return;
    end

    local iVinX = get_vine_x1(g_player_current_close_vine_index);

    if (get_player_absolute_frame_count() & 1) ~= 0 then
        if get_player_current_position_x() + 1 > iVinX and get_player_current_position_x() - 1 < iVinX then
            set_player_current_position_x(iVinX);
        elseif get_player_current_position_x() < iVinX then
            set_player_current_position_x(get_player_current_position_x() + 1);
        elseif get_player_current_position_x() > iVinX then
            set_player_current_position_x(get_player_current_position_x() - 1);
        end
    end
end

MoveJumpmanLadder_ = function(game_input)
    set_player_current_state(player_state.JSLADDER);
    set_player_current_special_action(player_special_action.NONE);
    g_is_already_on_ladder = true;

    if g_player_current_close_ladder_index == -1 then
        set_player_current_state(player_state.JSNORMAL);
        return;
    end

    if g_player_current_platform_y >= get_player_current_position_y() or
            (get_ladder_x1(g_player_current_close_ladder_index) < get_player_current_position_x() + 2 and
                get_ladder_x1(g_player_current_close_ladder_index) > get_player_current_position_x() - 2) then
        if CheckJumpStart_(1, 0, 1, game_input) then
            return;
        end
    end

    if CheckWalkOff_(get_ladder_x1(g_player_current_close_ladder_index), game_input) then
        return;
    end

    set_player_current_mesh(player_mesh.JUMP_UP);
    AdjustPlayerZ_(get_ladder_z1(g_player_current_close_ladder_index) - 3, 0);

    if game_input.move_up_action.is_pressed and
            get_ladder_y1(g_player_current_close_ladder_index) - 5 > get_player_current_position_y() then
        set_player_current_position_y(get_player_current_position_y() + 1);
        set_player_current_mesh(
            (get_player_absolute_frame_count() & 2) ~= 0 and player_mesh.LADDER_CLIMB_2 or player_mesh.LADDER_CLIMB_1);
    elseif game_input.move_up_action.is_pressed and not game_input.move_down_action.is_pressed then
        set_player_current_mesh(
            (get_player_absolute_frame_count() & 2) ~= 0 and player_mesh.LADDER_CLIMB_2 or player_mesh.LADDER_CLIMB_1);
    end

    if game_input.move_down_action.is_pressed and
            (get_ladder_y2(g_player_current_close_ladder_index) < g_player_current_platform_y - 3 or
                get_player_current_position_y() > g_player_current_platform_y) then
        set_player_current_position_y(get_player_current_position_y() - 1);
        set_player_current_mesh(
            (get_player_absolute_frame_count() & 2) ~= 0 and player_mesh.LADDER_CLIMB_2 or player_mesh.LADDER_CLIMB_1);

        if get_ladder_y2(g_player_current_close_ladder_index) >= g_player_current_platform_y - 3 and
                get_player_current_position_y() < g_player_current_platform_y then
            set_player_current_position_y(g_player_current_platform_y);
        end
    end

    local iLadderX = get_ladder_x1(g_player_current_close_ladder_index);

    if get_player_current_position_x() < iLadderX + 1 and get_player_current_position_x() > iLadderX - 1 then
        set_player_current_position_x(iLadderX);
    elseif get_player_current_position_x() < iLadderX then
        set_player_current_position_x(get_player_current_position_x() + 1);
    elseif get_player_current_position_x() > iLadderX then
        set_player_current_position_x(get_player_current_position_x() - 1);
    end
end

MoveJumpmanNormal_ = function(game_input)
    set_player_current_state(player_state.JSNORMAL);
    set_player_current_special_action(player_special_action.NONE);

    AdjustPlayerZ_(
        get_platform_z1(g_player_current_platform_index) - 2,
        get_player_current_position_y() - g_player_current_platform_y);

    if g_player_current_close_vine_index ~= -1 and
            not game_input.move_left_action.is_pressed and
            not game_input.move_right_action.is_pressed and
            (get_vine_y2(g_player_current_close_vine_index) < g_player_current_platform_y - 2 or
                get_player_current_position_y() > g_player_current_platform_y) then
        MoveJumpmanVine_(game_input);
        return;
    end

    if g_player_current_platform_y > get_player_current_position_y() - 2 and
            (get_platform_extra(g_player_current_platform_index) == 1 or
                get_platform_extra(g_player_current_platform_index) == 2) then
        MoveJumpmanSlide_(game_input);
        return;
    end

    if g_player_current_close_ladder_index ~= -1 and not g_is_already_on_ladder and
            (game_input.move_up_action.is_pressed ~= game_input.move_down_action.is_pressed) then
        if (not game_input.move_right_action.is_pressed or
                get_player_current_position_x() < get_ladder_x1(g_player_current_close_ladder_index) + 1) and
                (not game_input.move_left_action.is_pressed or
                    get_player_current_position_x() > get_ladder_x1(g_player_current_close_ladder_index) - 1) then
            if game_input.move_up_action.is_pressed and
                    get_ladder_y1(g_player_current_close_ladder_index) - 5 > get_player_current_position_y() then
                MoveJumpmanLadder_(game_input);
                return;
            end

            if game_input.move_down_action.is_pressed and
                    (get_ladder_y2(g_player_current_close_ladder_index) < g_player_current_platform_y - 3 or
                        g_player_current_platform_y < get_player_current_position_y() - 1) then
                MoveJumpmanLadder_(game_input);
                return;
            end
        end
    end

    if get_player_current_position_y() <= g_player_current_platform_y + 1 then
        if CheckJumpStart_(1, 1, 1, game_input) then
            return;
        end
    end

    if game_input.move_left_action.is_pressed and not game_input.move_right_action.is_pressed then
        set_player_current_mesh(
            (get_player_absolute_frame_count() & 2) ~= 0 and player_mesh.LEFT_1 or player_mesh.LEFT_2);
        set_player_current_position_x(get_player_current_position_x() - 1);
    end

    if game_input.move_right_action.is_pressed and not game_input.move_left_action.is_pressed then
        set_player_current_mesh(
            (get_player_absolute_frame_count() & 2) ~= 0 and player_mesh.RIGHT_1 or player_mesh.RIGHT_2);
        set_player_current_position_x(get_player_current_position_x() + 1);
    end

    local is_climbing = false;

    if g_player_current_platform_y < get_player_current_position_y() + 1 and
            g_player_current_platform_y > get_player_current_position_y() - 1 then
        set_player_current_position_y(g_player_current_platform_y);
    elseif g_player_current_platform_y < get_player_current_position_y() - 4 then
        set_player_current_state_frame_count(0);
        MoveJumpmanFalling_(game_input);
        return;
    elseif g_player_current_platform_y < get_player_current_position_y() - 1 then
        set_player_current_position_y(get_player_current_position_y() - 1);
    elseif g_player_current_platform_y > get_player_current_position_y() + 3 then
        set_player_current_mesh(
            (get_player_absolute_frame_count() & 2) ~= 0 and player_mesh.VINE_CLIMB_1 or player_mesh.VINE_CLIMB_2);
        set_player_current_position_y(get_player_current_position_y() + 1);
        is_climbing = true;
    elseif g_player_current_platform_y > get_player_current_position_y() + 1 then
        set_player_current_position_y(get_player_current_position_y() + 1);
        is_climbing = true;
    else
        set_player_current_position_y(g_player_current_platform_y);
    end

    UpdateSituation_();

    if g_player_current_platform_y < get_player_current_position_y() - 5 and is_climbing then
        set_player_current_position_x(g_player_old_position_x);
    end

    if get_platform_extra(g_player_current_platform_index) == 2 then
        if get_player_current_position_x() > g_player_old_position_x then
            set_player_current_position_x(g_player_old_position_x);
        end

        if get_player_current_position_y() > g_player_old_position_y then
            set_player_current_position_y(g_player_old_position_y);
        end
    end

    if get_platform_extra(g_player_current_platform_index) == 1 then
        if get_player_current_position_x() < g_player_old_position_x then
            set_player_current_position_x(g_player_old_position_x);
        end

        if get_player_current_position_y() > g_player_old_position_y then
            set_player_current_position_y(g_player_old_position_y);
        end
    end
end

local function DoDeathBounce_()
    stop_music_track_1();
    set_player_current_state(player_state.JSDYING);
    set_player_dying_animation_state(player_dying_animation_state.FALLING);
    set_player_dying_animation_state_frame_count(0);
    set_player_current_velocity_x(0);
    set_player_absolute_frame_count(get_player_current_state_frame_count());
    set_player_current_state_frame_count(1000);

    local iRand = math.random(0, 0x7fff);

    if (iRand & 7) == 1 and get_player_current_position_x() > 30 then
        set_player_current_velocity_x(-1);
    end

    if (iRand & 7) == 2 and get_player_current_position_x() < 130 then
        set_player_current_velocity_x(1);
    end
end

MoveJumpmanFalling_ = function(game_input)
    set_player_current_state(player_state.JSFALLING);
    set_player_current_special_action(player_special_action.NONE);

    set_player_current_position_y(get_player_current_position_y() - 1);
    set_player_current_state_frame_count(get_player_current_state_frame_count() + 1);
    set_player_current_rotation_x_radians(get_player_current_state_frame_count() / -10.0);
    set_player_current_mesh(player_mesh.JUMP_UP);

    if get_player_current_state_frame_count() > 10 then
        set_player_current_position_y(get_player_current_position_y() - 0.5);
    end

    if get_player_current_state_frame_count() > 20 then
        set_player_current_position_y(get_player_current_position_y() - 0.5);
    end

    if get_player_current_position_y() <= g_player_current_platform_y and
            get_platform_extra(g_player_current_platform_index) ~= 3 then
        if get_player_current_state_frame_count() < 10 then
            MoveJumpmanNormal_(game_input);
            return;
        else
            set_player_current_special_action(player_special_action.NONE);
            DoDeathBounce_();
            return;
        end
    end
end

MoveJumpmanJumping_ = function(game_input)
    set_player_current_state(player_state.JSJUMPING);

    if get_player_current_special_action() ~= player_special_action.KICK and
            game_input.attack_action.is_pressed and (
                g_player_current_direction == player_movement_direction.DIR_RIGHT or
                g_player_current_direction == player_movement_direction.DIR_LEFT) then
        set_player_current_special_action(player_special_action.KICK);
    end

    if g_player_current_exact_ladder_index ~= -1 and
            not game_input.attack_action.is_pressed and (
                get_player_current_state_frame_count() > 15 or
                not game_input.jump_action.is_pressed or
                (g_player_current_direction == player_movement_direction.DIR_RIGHT and
                    game_input.move_left_action.is_pressed) or
                (g_player_current_direction == player_movement_direction.DIR_LEFT and
                    game_input.move_right_action.is_pressed)) then
        MoveJumpmanLadder_(game_input);
        return;
    end

    if g_player_current_exact_vine_index ~= -1 and
            not game_input.attack_action.is_pressed and (
                get_player_current_state_frame_count() > 10 or
                not game_input.jump_action.is_pressed or
                (g_player_current_direction == player_movement_direction.DIR_RIGHT and
                    game_input.move_left_action.is_pressed) or
                (g_player_current_direction == player_movement_direction.DIR_LEFT and
                    game_input.move_right_action.is_pressed)) then
        MoveJumpmanVine_(game_input);
        return;
    end

    if get_player_current_state_frame_count() > 50 then
        if g_player_current_close_ladder_index ~= -1 then
            MoveJumpmanLadder_(game_input);
            return;
        end

        if g_player_current_close_vine_index ~= -1 then
            MoveJumpmanVine_(game_input);
            return;
        end

        MoveJumpmanNormal_(game_input);
        return;
    end

    if get_player_current_position_y() < g_player_current_platform_y and
            get_player_current_state_frame_count() > 6 and
            (not game_input.jump_action.is_pressed or get_player_current_state_frame_count() > 12) then
        MoveJumpmanNormal_(game_input);
        return;
    end

    set_player_current_state_frame_count(get_player_current_state_frame_count() + 1);

    if get_player_current_state_frame_count() == 1 then
        set_player_current_position_y(get_player_current_position_y() + 1);
    end

    if get_player_current_state_frame_count() < 5 or
            get_player_current_state_frame_count() == 6 or
            get_player_current_state_frame_count() == 8 or
            get_player_current_state_frame_count() == 10 or
            get_player_current_state_frame_count() == 12 then
        set_player_current_position_y(get_player_current_position_y() + 1);
    end

    if get_player_current_state_frame_count() > 26 or
            get_player_current_state_frame_count() == 25 or
            get_player_current_state_frame_count() == 23 or
            get_player_current_state_frame_count() == 20 or
            get_player_current_state_frame_count() == 17 then
        set_player_current_position_y(get_player_current_position_y() - 1);
    end

    set_player_current_mesh(player_mesh.JUMP_UP);

    if g_player_current_direction == player_movement_direction.DIR_LEFT then
        set_player_current_position_x(get_player_current_position_x() - 1);
        set_player_current_mesh(
            get_player_current_special_action() == player_special_action.KICK and player_mesh.KICK_LEFT or player_mesh.JUMP_LEFT);
    end

    if g_player_current_direction == player_movement_direction.DIR_RIGHT then
        set_player_current_position_x(get_player_current_position_x() + 1);
        set_player_current_mesh(
            get_player_current_special_action() == player_special_action.KICK and player_mesh.KICK_RIGHT or player_mesh.JUMP_RIGHT);
    end

    if game_input.move_down_action.is_pressed and
            get_player_no_roll_cooldown_frame_count() == 0 and
            (g_player_current_direction == player_movement_direction.DIR_RIGHT or
                g_player_current_direction == player_movement_direction.DIR_LEFT) then
        set_player_current_state_frame_count(0);
        MoveJumpmanRoll_(game_input);
    end
end

MoveJumpmanSlide_ = function(game_input)
    set_player_current_state(player_state.JSSLIDE);
    set_player_current_special_action(player_special_action.NONE);

    local iExtra = get_platform_extra(g_player_current_platform_index);

    if iExtra == 0 and get_player_current_position_y() <= g_player_current_platform_y then
        MoveJumpmanNormal_(game_input);
        return;
    end

    if get_player_current_position_y() > g_player_current_platform_y + 3 then
        set_player_current_state_frame_count(get_player_current_state_frame_count() + 1);

        if get_player_current_state_frame_count() > 30 then
            MoveJumpmanNormal_(game_input);
            return;
        end
    else
        set_player_current_state_frame_count(0);
    end

    if get_player_current_position_y() < g_player_current_platform_y + 1 then
        if iExtra == 1 then
            if CheckJumpStart_(0, 0, 1, game_input) then
                return;
            end

            set_player_current_position_x(get_player_current_position_x() + 1);
            g_player_current_direction = player_movement_direction.DIR_RIGHT;
        end

        if iExtra == 2 then
            if CheckJumpStart_(1, 0, 0, game_input) then
                return;
            end

            set_player_current_position_x(get_player_current_position_x() - 1);
            g_player_current_direction = player_movement_direction.DIR_LEFT;
        end
    else
        if g_player_current_direction == player_movement_direction.DIR_RIGHT then
            if get_player_current_state_frame_count() < 6 then
                if CheckJumpStart_(0, 0, 1, game_input) then
                    return;
                end
            end

            set_player_current_position_x(get_player_current_position_x() +
                ((30 - get_player_current_state_frame_count()) / 60.0 + 0.5));
        end

        if g_player_current_direction == player_movement_direction.DIR_LEFT then
            if get_player_current_state_frame_count() < 6 then
                if CheckJumpStart_(1, 0, 0, game_input) then
                    return;
                end
            end

            set_player_current_position_x(get_player_current_position_x() -
                ((30 - get_player_current_state_frame_count()) / 60.0 + 0.5));
        end
    end

    if g_player_current_direction == player_movement_direction.DIR_RIGHT then
        set_player_current_mesh(player_mesh.SLIDE_RIGHT);

        if (get_player_absolute_frame_count() & 7) == 1 or
                (get_player_absolute_frame_count() & 7) == 2 or
                (get_player_absolute_frame_count() & 7) == 4 or
                (get_player_absolute_frame_count() & 7) == 5 then
            set_player_current_mesh(player_mesh.SLIDE_RIGHT_B);
        end
    else
        set_player_current_mesh(player_mesh.SLIDE_LEFT);

        if (get_player_absolute_frame_count() & 7) == 1 or
                (get_player_absolute_frame_count() & 7) == 2 or
                (get_player_absolute_frame_count() & 7) == 4 or
                (get_player_absolute_frame_count() & 7) == 5 then
            set_player_current_mesh(player_mesh.SLIDE_LEFT_B);
        end
    end

    if get_player_current_position_y() < g_player_current_platform_y + 2 and
            get_player_current_position_y() > g_player_current_platform_y - 2 then
        set_player_current_position_y(g_player_current_platform_y);
    end

    if get_player_current_position_y() < g_player_current_platform_y then
        set_player_current_position_y(get_player_current_position_y() + 1);
    end

    if get_player_current_position_y() < g_player_current_platform_y then
        set_player_current_position_y(get_player_current_position_y() + 1);
    end

    if get_player_current_position_y() > g_player_current_platform_y then
        set_player_current_position_y(get_player_current_position_y() - 1);
    end

    if get_player_current_position_y() > g_player_current_platform_y then
        set_player_current_position_y(get_player_current_position_y() - 1);
    end
end

MoveJumpmanRoll_ = function(game_input)
    set_player_current_state(player_state.JSROLL);
    set_player_current_special_action(player_special_action.NONE);

    if get_player_current_state_frame_count() < 7 or
            get_player_current_position_y() > g_player_current_platform_y + 1 then
        set_player_current_state_frame_count(get_player_current_state_frame_count() + 1);

        if get_player_current_state_frame_count() > 50 then
            MoveJumpmanNormal_(game_input);
            return;
        end
    else
        set_player_current_state_frame_count(7);
    end

    if get_player_current_position_y() <= g_player_current_platform_y and (
            get_platform_extra(g_player_current_platform_index) == 1 or
            get_platform_extra(g_player_current_platform_index) == 2) then
        MoveJumpmanSlide_(game_input);
        return;
    end

    if get_player_current_position_y() <= g_player_current_platform_y then
        if g_player_current_direction == player_movement_direction.DIR_RIGHT and
                not game_input.move_right_action.is_pressed then
            MoveJumpmanNormal_(game_input);
            return;
        end

        if g_player_current_direction == player_movement_direction.DIR_LEFT and
                not game_input.move_left_action.is_pressed then
            MoveJumpmanNormal_(game_input);
            return;
        end

        if not game_input.move_down_action.is_pressed then
            if CheckJumpStart_(1, 1, 1, game_input) then
                return;
            end
        end
    end

    if not game_input.jump_action.is_pressed and
            get_player_current_position_y() <= g_player_current_platform_y + 0.1 and
            game_input.attack_action.is_pressed then
        set_player_current_state_frame_count(0);
        MoveJumpmanPunch_(game_input);
        return;
    end

    if g_player_current_exact_ladder_index ~= -1 and
            g_player_current_platform_y < get_player_current_position_y() and
            get_player_current_state_frame_count() > 10 then
        MoveJumpmanLadder_(game_input);
        return;
    end

    if g_player_current_exact_vine_index ~= -1 and
            g_player_current_platform_y < get_player_current_position_y() and
            get_player_current_state_frame_count() > 10 then
        MoveJumpmanVine_(game_input);
        return;
    end

    AdjustPlayerZ_(
        get_platform_z1(g_player_current_platform_index) - 2,
        get_player_current_position_y() - g_player_current_platform_y);

    local iVel = 1.3;

    if get_player_current_state_frame_count() > 8 then
        iVel = 1;
    end

    if get_player_current_state_frame_count() > 25 then
        iVel = 0.7;
    end

    if get_player_current_state_frame_count() > 38 then
        iVel = 0.3;
    end

    if g_player_current_direction == player_movement_direction.DIR_LEFT then
        set_player_current_position_x(get_player_current_position_x() - iVel);
        set_player_current_mesh(player_mesh.ROLL_LEFT_1 + ((get_player_absolute_frame_count() & 6) >> 1));

        if get_player_current_state_frame_count() < 6 then
            set_player_current_mesh(player_mesh.DIVE_LEFT);
        end
    end

    if g_player_current_direction == player_movement_direction.DIR_RIGHT then
        set_player_current_position_x(get_player_current_position_x() + iVel);
        set_player_current_mesh(player_mesh.ROLL_RIGHT_1 + ((get_player_absolute_frame_count() & 6) >> 1));

        if get_player_current_state_frame_count() < 6 then
            set_player_current_mesh(player_mesh.DIVE_RIGHT);
        end
    end

    UpdateSituation_();

    if g_player_current_platform_y < get_player_current_position_y() + 1 and
            g_player_current_platform_y > get_player_current_position_y() - 1 then
        set_player_current_position_y(g_player_current_platform_y);
    elseif g_player_current_platform_y < get_player_current_position_y() then
        set_player_current_position_y(get_player_current_position_y() - 1);
    elseif g_player_current_platform_y > get_player_current_position_y() then
        set_player_current_position_y(get_player_current_position_y() + 1);
    end
end

MoveJumpmanPunch_ = function(game_input)
    set_player_current_state(player_state.JSPUNCH);
    set_player_current_special_action(player_special_action.PUNCH);

    if get_player_current_state_frame_count() > 20 or
            (get_player_current_state_frame_count() < 12 and
                get_player_current_position_y() < g_player_current_platform_y - 2) or
            (get_player_current_state_frame_count() > 11 and
                get_player_current_position_y() <= g_player_current_platform_y) then
        MoveJumpmanNormal_(game_input);
        return;
    end

    set_player_current_state_frame_count(get_player_current_state_frame_count() + 1);

    if get_player_current_state_frame_count() < 3 then
        set_player_current_mesh(
            g_player_current_direction == player_movement_direction.DIR_RIGHT and player_mesh.PUNCH_RIGHT_1 or player_mesh.PUNCH_LEFT_1);
    else
        set_player_current_mesh(
            g_player_current_direction == player_movement_direction.DIR_RIGHT and player_mesh.PUNCH_RIGHT_2 or player_mesh.PUNCH_LEFT_2);
    end

    if get_player_current_state_frame_count() < 11 and get_player_current_state_frame_count() ~= 9 then
        set_player_current_position_y(get_player_current_position_y() + 1);
    end

    if get_player_current_state_frame_count() > 12 and get_player_current_state_frame_count() ~= 14 then
        set_player_current_position_y(get_player_current_position_y() - 1);
    end

    if get_player_current_state_frame_count() < 4 or
            get_player_current_state_frame_count() == 5 or
            get_player_current_state_frame_count() == 7 then
        set_player_current_position_x(
            get_player_current_position_x() +
            (g_player_current_direction == player_movement_direction.DIR_RIGHT and 1 or -1));
    end
end

local function MoveJumpman_(game_input)
    g_player_old_position_x = get_player_current_position_x();
    g_player_old_position_y = get_player_current_position_y();
    g_is_already_on_ladder = false;

    UpdateSituation_();

    if (get_player_current_state() == player_state.JSVINE) then
        MoveJumpmanVine_(game_input);
    elseif (get_player_current_state() == player_state.JSLADDER) then
        MoveJumpmanLadder_(game_input);
    elseif (get_player_current_state() == player_state.JSNORMAL) then
        MoveJumpmanNormal_(game_input);
    elseif (get_player_current_state() == player_state.JSFALLING) then
        MoveJumpmanFalling_(game_input);
    elseif (get_player_current_state() == player_state.JSJUMPING) then
        MoveJumpmanJumping_(game_input);
    elseif (get_player_current_state() == player_state.JSSLIDE) then
        MoveJumpmanSlide_(game_input);
    elseif (get_player_current_state() == player_state.JSROLL) then
        MoveJumpmanRoll_(game_input);
    elseif (get_player_current_state() == player_state.JSPUNCH) then
        MoveJumpmanPunch_(game_input);
    end

    if (get_player_current_position_y() < 0) then
        set_player_current_special_action(player_special_action.NONE);
        DoDeathBounce_();
        return;
    end

    for iRep = 0, 1 do
        local iCollide = CollideWall_(
            get_player_current_position_x() - 2, get_player_current_position_y() + 11,
            get_player_current_position_x() + 2, get_player_current_position_y() + 9);

        if iCollide == 1 then
            set_player_current_position_y(get_player_current_position_y() - 1);

            if get_player_current_state() == player_state.JSJUMPING and get_player_current_state_frame_count() < 15 then
                set_player_current_state_frame_count(15);
            end
        end

        iCollide = CollideWall_(
            get_player_current_position_x() - 3, get_player_current_position_y() + 9,
            get_player_current_position_x() + 3, get_player_current_position_y() + 3);

        if iCollide == 3 then
            set_player_current_position_x(get_player_current_position_x() + 1);

            if get_player_current_state() == player_state.JSJUMPING and get_player_current_state_frame_count() < 15 then
                set_player_current_state_frame_count(16);
            end

            if get_player_current_state() ~= player_state.JSJUMPING and
                    get_player_current_position_y() > g_player_current_platform_y - 1 and
                    get_player_current_position_y() >= g_player_old_position_y then
                set_player_current_position_y(get_player_current_position_y() - 1);
            end
        end

        if iCollide == 4 then
            set_player_current_position_x(get_player_current_position_x() - 1);

            if get_player_current_state() == player_state.JSJUMPING and get_player_current_state_frame_count() < 15 then
                set_player_current_state_frame_count(16);
            end

            if get_player_current_state() ~= player_state.JSJUMPING and
                    get_player_current_position_y() > g_player_current_platform_y - 1 and
                    get_player_current_position_y() >= g_player_old_position_y then
                set_player_current_position_y(get_player_current_position_y() - 1);
            end
        end
    end

    UpdateSituation_();
end

local function GrabDonuts_(game_input)
    local iGot = false;

    for iLoop = 0, get_donut_object_count() - 1 do
        if get_donut_is_visible(iLoop) and
                PlayerCollide_(
                    get_donut_x1(iLoop) - 3, get_donut_y1(iLoop) - 4,
                    get_donut_x1(iLoop) + 3, get_donut_y1(iLoop) + 2) then
            abs_donut(iLoop);
            set_script_selected_level_object_visible(0);
            set_object_visual_data(get_donut_texture_index(iLoop), 0);
            iGot = true;

            if Module.OnCollectDonutCallback then
                Module.OnCollectDonutCallback(game_input, get_donut_number(iLoop));
            end
        end
    end

    if iGot then
        local iWon = true;

        for iCheck = 0, get_donut_object_count() - 1 do
            if get_donut_is_visible(iCheck) then
                iWon = false;
            end
        end

        if iWon then
            stop_music_track_1();
            set_player_current_state_frame_count(0);
            set_player_current_state(player_state.JSDONE);
        else
            play_sound_effect(1);
        end
    end
end

local function AnimateDying_(game_input)
    g_player_current_active_platform_index = -1;

    if get_player_dying_animation_state() == player_dying_animation_state.BOUNCING then
        set_player_current_mesh(player_mesh.JUMP_UP);
        set_player_dying_animation_state_frame_count(get_player_dying_animation_state_frame_count() + 1);
        local dying_anim_frame_count = get_player_dying_animation_state_frame_count();

        if dying_anim_frame_count < 5 or dying_anim_frame_count == 6 then
            set_player_current_position_y(get_player_current_position_y() + 1);
        end

        if dying_anim_frame_count > 10 or dying_anim_frame_count == 8 then
            set_player_current_position_y(get_player_current_position_y() - 1);
        end

        if dying_anim_frame_count > 15 then
            set_player_dying_animation_state(player_dying_animation_state.FALLING);
        end

        set_player_absolute_frame_count(get_player_absolute_frame_count() + 1);

        if get_player_current_state_frame_count() < 10 then
            set_player_absolute_frame_count(get_player_absolute_frame_count() + 1);
        end

        if get_player_current_state_frame_count() < 5 then
            set_player_absolute_frame_count(get_player_absolute_frame_count() + 1);
        end

        if get_player_current_state_frame_count() < 0 then
            set_player_absolute_frame_count(get_player_absolute_frame_count() + 1);
            set_player_current_mesh(player_mesh.DEAD);
        end

        set_player_current_rotation_x_radians(get_player_absolute_frame_count() / -10.0);

        if (get_player_absolute_frame_count() & 1) ~= 0 then
            set_player_current_position_x(get_player_current_position_x() + get_player_current_velocity_x());
        end
    end

    if get_player_dying_animation_state() == player_dying_animation_state.FALLING then
        set_player_current_mesh(player_mesh.JUMP_UP);
        set_player_absolute_frame_count(get_player_absolute_frame_count() + 1);
        set_player_current_position_y(get_player_current_position_y() - 2);
        set_player_current_rotation_x_radians(get_player_absolute_frame_count() / -10.0);

        local iSupport, iPlatform = FindPlatform_(
            get_player_current_position_x(), get_player_current_position_y(), 8, 2);
        iSupport = iSupport - PlayerFloor_();

        local bGrounded = get_player_current_position_y() + 4 <= iSupport;
        AdjustPlayerZ_(get_platform_z1(iPlatform) - 2, get_player_current_position_y() - iSupport);

        if bGrounded and get_player_current_position_y() > -5 and iSupport < get_player_current_state_frame_count() then
            set_player_current_velocity_x(0);
            local iRand = math.random(0, 0x7fff);

            if (iRand & 3) == 1 and get_player_current_position_y() > 30 and get_player_current_position_x() > 30 then
                set_player_current_velocity_x(-1);
            end

            if (iRand & 3) == 2 and get_player_current_position_y() > 30 and get_player_current_position_x() < 130 then
                set_player_current_velocity_x(1);
            end

            set_player_current_state_frame_count(iSupport - 3);
            set_player_dying_animation_state(player_dying_animation_state.BOUNCING);
            set_player_dying_animation_state_frame_count(0);

            play_sound_effect(2);

            local _;
            _, iPlatform = FindPlatform_(get_player_current_position_x(), get_player_current_position_y() - 8, 8, 2);

            if iPlatform == -1 then
                set_player_dying_animation_state(player_dying_animation_state.FINAL_BOUNCE);
                set_player_dying_animation_state_frame_count(0);
                set_player_absolute_frame_count(0);
            end
        end

        if get_player_current_position_y() < -2 and
                get_player_dying_animation_state() == player_dying_animation_state.FALLING then
            set_player_dying_animation_state(player_dying_animation_state.FINAL_BOUNCE);
            set_player_absolute_frame_count(0);
        end
    end

    if get_player_dying_animation_state() == player_dying_animation_state.FINAL_BOUNCE then
        set_player_current_mesh(player_mesh.DEAD);
        set_player_dying_animation_state_frame_count(get_player_dying_animation_state_frame_count() + 1);
        local dying_anim_frame_count = get_player_dying_animation_state_frame_count();

        if dying_anim_frame_count < 10 or dying_anim_frame_count == 12 or dying_anim_frame_count == 14 then
            set_player_current_position_y(get_player_current_position_y() + 1);
        end

        if dying_anim_frame_count > 20 or dying_anim_frame_count == 18 or dying_anim_frame_count == 16 then
            set_player_current_position_y(get_player_current_position_y() - 1);
        end

        if dying_anim_frame_count == 10 or dying_anim_frame_count == 12 or
                dying_anim_frame_count == 17 or dying_anim_frame_count == 20 then
            set_player_current_position_z(get_player_current_position_z() - 1);
        end

        if dying_anim_frame_count == 25 then
            play_death_music_track();
        end

        set_player_absolute_frame_count(get_player_absolute_frame_count() + 4);
        set_player_current_rotation_x_radians(get_player_absolute_frame_count() / -10.0);

        if dying_anim_frame_count > 30 then
            set_player_dying_animation_state(player_dying_animation_state.SPINNING_STARS);
            set_player_absolute_frame_count(0);
            set_player_current_rotation_x_radians(0);
        end
    end

    if get_player_dying_animation_state() == player_dying_animation_state.SPINNING_STARS then
        select_object_mesh(get_player_mesh_index(player_mesh.STARS));
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_rotate_matrix_y(get_player_absolute_frame_count() * 180.0 / 50.0);
        script_selected_mesh_translate_matrix(
            get_player_current_position_x(), get_player_current_position_y() + 12, get_player_current_position_z() + 1);
        set_object_visual_data(0, 1);

        set_player_absolute_frame_count(get_player_absolute_frame_count() + 1);
        set_player_current_rotation_x_radians(0.1);
        set_player_current_mesh(player_mesh.DEAD);

        if get_player_absolute_frame_count() == 85 then
            set_object_visual_data(0, 0);
            set_remaining_life_count(get_remaining_life_count() - 1);

            if get_remaining_life_count() == 0 then
                game_over();
            else
                if Module.ResetPlayerCallback then
                    Module.ResetPlayerCallback(game_input);
                end

                restart_music_track_1();
            end
        end
    end
end

function Module.progress_game(game_input)
    if get_player_freeze_cooldown_frame_count() ~= 0 then
        set_player_freeze_cooldown_frame_count(get_player_freeze_cooldown_frame_count() - 1);
    end

    if get_player_no_roll_cooldown_frame_count() ~= 0 then
        set_player_no_roll_cooldown_frame_count(get_player_no_roll_cooldown_frame_count() - 1);
    end

    if (get_player_current_state() & player_state.JSDYING) == 0 and get_player_freeze_cooldown_frame_count() == 0 then
        set_player_absolute_frame_count(get_player_absolute_frame_count() + 1);
        set_player_current_rotation_x_radians(0);
        set_player_current_mesh(player_mesh.STAND);
        MoveJumpman_(game_input);

        if get_player_current_mesh() == player_mesh.STAND and
                get_player_is_visible() and
                get_game_time_inactive() > 400 then
            local iTemp = math.floor((get_game_time_inactive() % 400) / 6);
            iTemp = iTemp > 10 and 2 or (iTemp & 1);
            set_player_current_mesh(player_mesh.BORED_1 + iTemp);
        end

        GrabDonuts_(game_input);
    end

    if (get_player_current_state() & player_state.JSDYING) ~= 0 and get_player_freeze_cooldown_frame_count() == 0 then
        AnimateDying_(game_input);
        GrabDonuts_(game_input);
    end

    reset_perspective();
end

function Module.get_player_current_active_platform_index()
    return g_player_current_active_platform_index;
end

function Module.get_player_current_direction()
    return g_player_current_direction;
end

function Module.set_player_current_direction(new_direction)
    g_player_current_direction = new_direction;
end

function Module.find_vine(iX, iY)
    -- TODO: Figure out what "iX", "iY" mean, and change names to reflect that
    return FindVine_(iX, iY);
end

function Module.find_ladder(iX, iY)
    -- TODO: Figure out what "iX", "iY" mean, and change names to reflect that
    return FindLadder_(iX, iY);
end

function Module.find_platform(iX, iY, iHeight, iWide)
    -- TODO: Figure out what "iX", "iY" mean, and change names to reflect that
    return FindPlatform_(iX, iY, iHeight, iWide);
end

function Module.collide_wall(x1, y1, x2, y2)
    -- TODO: Figure out what "x1", "y1", "x2", "y2" mean, and change names to reflect that
    return CollideWall_(x1, y1, x2, y2);
end

function Module.is_player_colliding_with_rect(x1, y1, x2, y2)
    -- TODO: Figure out what "x1", "y1", "x2", "y2" mean, and change names to reflect that
    return PlayerCollide_(x1, y1, x2, y2) and get_player_current_state() ~= player_state.JSDYING;
end

return Module;