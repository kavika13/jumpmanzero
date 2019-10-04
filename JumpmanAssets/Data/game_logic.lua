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

-- TODO: Expose this to callers?
local camera_mode = {
    -- TODO: Rename these?
    PerspectiveNormal = 0,
    PerspectiveCloseUp = 1,
    PerspectiveFar = 2,
    PerspectiveWide = 3,
    PerspectiveFollow = 4,
    PerspectiveFixed = 5,
    PerspectiveAbove = 20,
    PerspectiveFlat = 21,
    PerspectiveFarAbove = 22,
};
camera_mode = read_only.make_table_read_only(camera_mode);

-- TODO: Expose this to callers?
local navigation_type = {
    LADDER = 1,
    PLATFORM = 2,
    PLATFORM_FALL_LEFT = 3,
    PLATFORM_FALL_RIGHT = 4,
};
navigation_type = read_only.make_table_read_only(navigation_type);

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

local g_game_time_inactive = 0;

-- TODO: Do we have to initialize all these?
local g_player_current_state = player_state.JSNORMAL;
local g_player_current_state_frame_count = 0;
local g_player_absolute_frame_count = 0;
local g_player_current_mesh = 0;
local g_player_previous_mesh = 0;
local g_player_is_visible = true;
local g_player_current_position_x = 0;
local g_player_current_position_y = 0;
local g_player_current_position_z = 0;
local g_player_current_velocity_x = 0;
local g_player_old_position_x = 0;
local g_player_old_position_y = 0;
local g_player_current_rotation_x_radians = 0;
local g_player_current_direction = 0;  -- TODO: This isn't in the enum. Add it?
local g_player_current_special_action = player_special_action.NONE;
local g_is_already_on_ladder = false;
local g_player_dying_animation_state = -1;
local g_player_dying_animation_state_frame_count = -1;
local g_player_no_roll_cooldown_frame_count = 0
local g_player_freeze_cooldown_frame_count = 0;

local g_player_current_close_ladder_index = -1;
local g_player_current_exact_ladder_index = -1;
local g_player_current_platform_index = -1;
local g_player_current_active_platform_index = -1;  -- Masked out if player is dead or if player is below it
local g_player_current_platform_y = 0;
local g_player_current_close_vine_index = -1;
local g_player_current_exact_vine_index = -1;

local g_level_extent_x = 160;

local g_current_camera_mode = camera_mode.PerspectiveNormal;
local g_camera_current_pos_x = 0;
local g_camera_current_pos_y = 0;
local g_camera_track_player_pos_x = 0;
local g_camera_track_player_pos_y = 0;

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

    if (g_player_current_state & player_state.JSJUMPING) ~= 0 and g_player_current_state_frame_count < 12 then
        iFloor = 4;
    end

    return iFloor;
end

local function PlayerHeight_()
    local iHeight = 14;

    if (g_player_current_state & player_state.JSROLL) ~= 0 then
        iHeight = 7;
    end

    if (g_player_current_state & player_state.JSPUNCH) ~= 0 then
        iHeight = 9;
    end

    if (g_player_current_state & player_state.JSDYING) ~= 0 then
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

                if g_player_current_state == player_state.JSROLL and g_player_current_state_frame_count < 6 then
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

local function BuildNavigation_()
    for ladder_index = 0, get_ladder_object_count() - 1 do
        set_ladder_nav_count(ladder_index, 0);
    end

    for platform_index = 0, get_platform_object_count() - 1 do
        set_platform_nav_count(platform_index, 0);

        local platform_x1 = get_platform_x1(platform_index);
        local platform_y1 = get_platform_y1(platform_index);
        local next_platform_y, next_platform_index = FindPlatform_(platform_x1 - 4, platform_y1, 4, 2);

        if next_platform_index >= 0 then
            local nav_type = navigation_type.PLATFORM;

            if next_platform_y < platform_y1 - 4 then
                nav_type = navigation_type.PLATFORM_FALL_LEFT;
            end

            add_platform_nav_to(platform_index, nav_type, next_platform_index);
        end

        local platform_x2 = get_platform_x2(platform_index);
        local platform_y2 = get_platform_y2(platform_index);
        next_platform_y, next_platform_index = FindPlatform_(platform_x2 + 4, platform_y2, 4, 2);

        if next_platform_index >= 0 then
            local nav_type = navigation_type.PLATFORM;

            if next_platform_y < platform_y2 - 4 then
                nav_type = navigation_type.PLATFORM_FALL_RIGHT;
            end

            add_platform_nav_to(platform_index, nav_type, next_platform_index);
        end

        for ladder_index = 0, get_ladder_object_count() - 1 do
            local ladder_pos_x = get_ladder_x1(ladder_index);

            if platform_x1 < ladder_pos_x and platform_x2 > ladder_pos_x then
                local platform_length = platform_x2 - platform_x1;

                -- TODO: The platform_height variable name might not be quite correct.
                --       Seems to correlate ladder's position with platform height and platform length,
                --          then compare to ladder bottom/top
                local platform_height =
                    platform_y1 * math.abs(math.floor(platform_x2 - ladder_pos_x)) +
                    platform_y2 * math.abs(math.floor(platform_x1 - ladder_pos_x));
                platform_height = platform_height / platform_length;

                local ladder_y1 = get_ladder_y1(ladder_index);
                local ladder_y2 = get_ladder_y2(ladder_index);

                if platform_height < ladder_y1 + 2 and platform_height > ladder_y2 - 2 then
                    add_platform_nav_to(platform_index, navigation_type.LADDER, ladder_index);
                    add_ladder_nav_to(ladder_index, navigation_type.PLATFORM, platform_index);
                end
            end
        end
    end
end

local function GetNavDir_(from_object_index, to_object_index, nav_from_type, nav_to_type)
    for platform_index = 0, get_platform_object_count() - 1 do
        set_platform_nav_distance(platform_index, 5000);
    end

    for ladder_index = 0, get_ladder_object_count() - 1 do
        set_ladder_nav_distance(ladder_index, 5000);
    end

    if from_object_index < 0 or to_object_index < 0 then
        return -1;
    end

    if nav_from_type == navigation_type.LADDER then
        set_ladder_nav_distance(from_object_index, 0);
    end

    if nav_from_type == navigation_type.PLATFORM then
        set_platform_nav_distance(from_object_index, 0);
    end

    local is_done = false;

    for repeat_count = 0, 49 do  -- TODO: Use constant
        if not is_done then
            for ladder_index = 0, get_ladder_object_count() - 1 do
                if get_ladder_nav_distance(ladder_index) < 5000 then
                    for nav_index = 0, get_ladder_nav_count(ladder_index) - 1 do
                        local ladder_nav_to_type, nav_to_object_index = get_ladder_nav_to(ladder_index, nav_index);
                        local ladder_nav_distance = get_ladder_nav_distance(ladder_index);

                        if ladder_nav_to_type == navigation_type.PLATFORM then
                            if get_platform_nav_distance(nav_to_object_index) > ladder_nav_distance + 1 then
                                set_platform_nav_distance(nav_to_object_index, ladder_nav_distance + 1);
                                set_platform_nav_choice(nav_to_object_index, get_ladder_nav_choice(ladder_index));

                                if ladder_nav_distance == 0 then
                                    set_platform_nav_choice(nav_to_object_index, nav_to_object_index);
                                end
                            end
                        end
                    end
                end
            end

            for platform_index = 0, get_platform_object_count() - 1 do
                if get_platform_nav_distance(platform_index) < 5000 then
                    for nav_index = 0, get_platform_nav_count(platform_index) - 1 do
                        local platform_nav_to_type, nav_to_object_index = get_platform_nav_to(platform_index, nav_index);
                        -- Get platform_index nav distance each time in case it gets modified inside the loop
                        local platform_nav_distance = get_platform_nav_distance(platform_index);

                        if platform_nav_to_type ~= navigation_type.LADDER then
                            if get_platform_nav_distance(nav_to_object_index) > platform_nav_distance + 1 then
                                set_platform_nav_distance(nav_to_object_index, platform_nav_distance + 1);
                                set_platform_nav_choice(nav_to_object_index, get_platform_nav_choice(platform_index));

                                -- Re-get platform_index nav distance in case it gets modified just above this
                                if get_platform_nav_distance(platform_index) == 0 then
                                    if platform_nav_to_type == navigation_type.PLATFORM then
                                        set_platform_nav_choice(nav_to_object_index, nav_to_object_index);
                                    end

                                    if platform_nav_to_type == navigation_type.PLATFORM_FALL_LEFT then
                                        set_platform_nav_choice(nav_to_object_index, nav_to_object_index + 2000);
                                    end

                                    if platform_nav_to_type == navigation_type.PLATFORM_FALL_RIGHT then
                                        set_platform_nav_choice(nav_to_object_index, nav_to_object_index + 3000);
                                    end
                                end
                            end
                        end

                        if platform_nav_to_type == navigation_type.LADDER then
                            if get_ladder_nav_distance(nav_to_object_index) > platform_nav_distance + 1 then
                                set_ladder_nav_distance(nav_to_object_index, platform_nav_distance + 1);
                                set_ladder_nav_choice(nav_to_object_index, get_platform_nav_choice(platform_index));

                                if platform_nav_distance == 0 then
                                    set_ladder_nav_choice(nav_to_object_index, nav_to_object_index + 1000);
                                end
                            end
                        end
                    end
                end
            end

            if nav_to_type == navigation_type.LADDER and get_ladder_nav_distance(to_object_index) < 5000 then
                is_done = true;
            end

            if nav_to_type ~= navigation_type.LADDER and get_platform_nav_distance(to_object_index) < 5000 then
                is_done = true;
            end
        end
    end

    if not is_done then
        return -1;
    end

    local nav_choice = 0;

    if nav_to_type == navigation_type.LADDER then
        nav_choice = get_ladder_nav_choice(to_object_index);
    end

    if nav_to_type ~= navigation_type.LADDER then
        nav_choice = get_platform_nav_choice(to_object_index);
    end

    return nav_choice;
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
    local player_pos_x = g_player_current_position_x;
    local player_pos_y = g_player_current_position_y;
    local is_player_jumping = (g_player_current_state & player_state.JSJUMPING) ~= 0;
    local is_player_rolling = (g_player_current_state & player_state.JSROLL) ~= 0;

    if is_player_jumping then
        if player_pos_x + 4 > x1 and player_pos_y + 9 > y1 and player_pos_x - 4 < x2 and player_pos_y + 4 < y2 then
            return true;
        end
    elseif is_player_rolling and g_player_absolute_frame_count < 12 then
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
        g_player_current_position_x, g_player_current_position_y);

    g_player_current_close_ladder_index, g_player_current_exact_ladder_index = FindLadder_(
        g_player_current_position_x, g_player_current_position_y);

    g_player_current_platform_y, g_player_current_platform_index = FindPlatform_(
        g_player_current_position_x, g_player_current_position_y, PlayerHeight_(), 2);
    g_player_current_platform_y = g_player_current_platform_y - PlayerFloor_();

    g_player_current_active_platform_index = -1;

    if g_player_current_platform_y >= g_player_current_position_y then
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

    g_player_current_special_action = player_special_action.NONE;
    g_player_current_state_frame_count = 0;

    play_sound_effect(0);

    MoveJumpmanJumping_(game_input);

    return true;
end

local function CheckWalkOff_(iCenter, game_input)
    if g_player_current_position_x < iCenter and game_input.move_right_action.is_pressed then
        return false;
    end

    if g_player_current_position_x > iCenter and game_input.move_left_action.is_pressed then
        return false;
    end

    if game_input.move_down_action.is_pressed and g_player_current_position_y < g_player_current_platform_y - 2 then
        return false;
    end

    if g_player_current_position_y <= g_player_current_platform_y and
            (game_input.move_left_action.is_pressed ~= game_input.move_right_action.is_pressed) then
        MoveJumpmanNormal_(game_input);
        return true;
    end

    return false;
end

local function AdjustPlayerZ_(iTargetZ, iTime)
    -- TODO: Might have some  oscillation problems if these end up being floating point values
    if iTime < math.abs(iTargetZ - g_player_current_position_z) then
        if iTargetZ < g_player_current_position_z then
            g_player_current_position_z = g_player_current_position_z - 1;
        end

        if iTargetZ > g_player_current_position_z then
            g_player_current_position_z = g_player_current_position_z + 1;
        end
    end
end

MoveJumpmanVine_ = function(game_input)
    g_player_current_state = player_state.JSVINE;
    g_player_current_special_action = player_special_action.NONE;

    if g_player_current_close_vine_index == -1 then
        g_player_current_state = player_state.JSNORMAL;
        return;
    end

    if CheckJumpStart_(1, 0, 1, game_input) then
        return;
    end

    if CheckWalkOff_(get_vine_x1(g_player_current_close_vine_index), game_input) then
        return;
    end

    g_player_current_mesh = (g_player_absolute_frame_count & 2) ~= 0
        and player_mesh.VINE_CLIMB_1
        or player_mesh.VINE_CLIMB_2;
    AdjustPlayerZ_(get_vine_z1(g_player_current_close_vine_index) - 3, 0);

    if get_vine_y2(g_player_current_close_vine_index) < g_player_current_platform_y - 2 or
            g_player_current_position_y > g_player_current_platform_y - 1 then
        g_player_current_position_y = g_player_current_position_y - 1;
    else
        MoveJumpmanNormal_(game_input);
        return;
    end

    local iVinX = get_vine_x1(g_player_current_close_vine_index);

    if (g_player_absolute_frame_count & 1) ~= 0 then
        if g_player_current_position_x + 1 > iVinX and g_player_current_position_x - 1 < iVinX then
            g_player_current_position_x = iVinX;
        elseif g_player_current_position_x < iVinX then
            g_player_current_position_x = g_player_current_position_x + 1;
        elseif g_player_current_position_x > iVinX then
            g_player_current_position_x = g_player_current_position_x - 1;
        end
    end
end

MoveJumpmanLadder_ = function(game_input)
    g_player_current_state = player_state.JSLADDER;
    g_player_current_special_action = player_special_action.NONE;
    g_is_already_on_ladder = true;

    if g_player_current_close_ladder_index == -1 then
        g_player_current_state = player_state.JSNORMAL;
        return;
    end

    if g_player_current_platform_y >= g_player_current_position_y or
            (get_ladder_x1(g_player_current_close_ladder_index) < g_player_current_position_x + 2 and
                get_ladder_x1(g_player_current_close_ladder_index) > g_player_current_position_x - 2) then
        if CheckJumpStart_(1, 0, 1, game_input) then
            return;
        end
    end

    if CheckWalkOff_(get_ladder_x1(g_player_current_close_ladder_index), game_input) then
        return;
    end

    g_player_current_mesh = player_mesh.JUMP_UP;
    AdjustPlayerZ_(get_ladder_z1(g_player_current_close_ladder_index) - 3, 0);

    if game_input.move_up_action.is_pressed and
            get_ladder_y1(g_player_current_close_ladder_index) - 5 > g_player_current_position_y then
        g_player_current_position_y = g_player_current_position_y + 1;
        g_player_current_mesh = (g_player_absolute_frame_count & 2) ~= 0
            and player_mesh.LADDER_CLIMB_2
            or player_mesh.LADDER_CLIMB_1;
    elseif game_input.move_up_action.is_pressed and not game_input.move_down_action.is_pressed then
        g_player_current_mesh = (g_player_absolute_frame_count & 2) ~= 0
            and player_mesh.LADDER_CLIMB_2
            or player_mesh.LADDER_CLIMB_1;
    end

    if game_input.move_down_action.is_pressed and
            (get_ladder_y2(g_player_current_close_ladder_index) < g_player_current_platform_y - 3 or
                g_player_current_position_y > g_player_current_platform_y) then
        g_player_current_position_y = g_player_current_position_y - 1;
        g_player_current_mesh = (g_player_absolute_frame_count & 2) ~= 0
            and player_mesh.LADDER_CLIMB_2
            or player_mesh.LADDER_CLIMB_1;

        if get_ladder_y2(g_player_current_close_ladder_index) >= g_player_current_platform_y - 3 and
                g_player_current_position_y < g_player_current_platform_y then
            g_player_current_position_y = g_player_current_platform_y;
        end
    end

    local iLadderX = get_ladder_x1(g_player_current_close_ladder_index);

    if g_player_current_position_x < iLadderX + 1 and g_player_current_position_x > iLadderX - 1 then
        g_player_current_position_x = iLadderX;
    elseif g_player_current_position_x < iLadderX then
        g_player_current_position_x = g_player_current_position_x + 1;
    elseif g_player_current_position_x > iLadderX then
        g_player_current_position_x = g_player_current_position_x - 1;
    end
end

MoveJumpmanNormal_ = function(game_input)
    g_player_current_state = player_state.JSNORMAL;
    g_player_current_special_action = player_special_action.NONE;

    AdjustPlayerZ_(
        get_platform_z1(g_player_current_platform_index) - 2,
        g_player_current_position_y - g_player_current_platform_y);

    if g_player_current_close_vine_index ~= -1 and
            not game_input.move_left_action.is_pressed and
            not game_input.move_right_action.is_pressed and
            (get_vine_y2(g_player_current_close_vine_index) < g_player_current_platform_y - 2 or
                g_player_current_position_y > g_player_current_platform_y) then
        MoveJumpmanVine_(game_input);
        return;
    end

    if g_player_current_platform_y > g_player_current_position_y - 2 and
            (get_platform_extra(g_player_current_platform_index) == 1 or
                get_platform_extra(g_player_current_platform_index) == 2) then
        MoveJumpmanSlide_(game_input);
        return;
    end

    if g_player_current_close_ladder_index ~= -1 and not g_is_already_on_ladder and
            (game_input.move_up_action.is_pressed ~= game_input.move_down_action.is_pressed) then
        if (not game_input.move_right_action.is_pressed or
                g_player_current_position_x < get_ladder_x1(g_player_current_close_ladder_index) + 1) and
                (not game_input.move_left_action.is_pressed or
                    g_player_current_position_x > get_ladder_x1(g_player_current_close_ladder_index) - 1) then
            if game_input.move_up_action.is_pressed and
                    get_ladder_y1(g_player_current_close_ladder_index) - 5 > g_player_current_position_y then
                MoveJumpmanLadder_(game_input);
                return;
            end

            if game_input.move_down_action.is_pressed and
                    (get_ladder_y2(g_player_current_close_ladder_index) < g_player_current_platform_y - 3 or
                        g_player_current_platform_y < g_player_current_position_y - 1) then
                MoveJumpmanLadder_(game_input);
                return;
            end
        end
    end

    if g_player_current_position_y <= g_player_current_platform_y + 1 then
        if CheckJumpStart_(1, 1, 1, game_input) then
            return;
        end
    end

    if game_input.move_left_action.is_pressed and not game_input.move_right_action.is_pressed then
        g_player_current_mesh = (g_player_absolute_frame_count & 2) ~= 0
            and player_mesh.LEFT_1
            or player_mesh.LEFT_2;
        g_player_current_position_x = g_player_current_position_x - 1;
    end

    if game_input.move_right_action.is_pressed and not game_input.move_left_action.is_pressed then
        g_player_current_mesh = (g_player_absolute_frame_count & 2) ~= 0
            and player_mesh.RIGHT_1
            or player_mesh.RIGHT_2;
        g_player_current_position_x = g_player_current_position_x + 1;
    end

    local is_climbing = false;

    if g_player_current_platform_y < g_player_current_position_y + 1 and
            g_player_current_platform_y > g_player_current_position_y - 1 then
        g_player_current_position_y = g_player_current_platform_y;
    elseif g_player_current_platform_y < g_player_current_position_y - 4 then
        g_player_current_state_frame_count = 0;
        MoveJumpmanFalling_(game_input);
        return;
    elseif g_player_current_platform_y < g_player_current_position_y - 1 then
        g_player_current_position_y = g_player_current_position_y - 1;
    elseif g_player_current_platform_y > g_player_current_position_y + 3 then
        g_player_current_mesh = (g_player_absolute_frame_count & 2) ~= 0
            and player_mesh.VINE_CLIMB_1
            or player_mesh.VINE_CLIMB_2;
        g_player_current_position_y = g_player_current_position_y + 1;
        is_climbing = true;
    elseif g_player_current_platform_y > g_player_current_position_y + 1 then
        g_player_current_position_y = g_player_current_position_y + 1;
        is_climbing = true;
    else
        g_player_current_position_y = g_player_current_platform_y;
    end

    UpdateSituation_();

    if g_player_current_platform_y < g_player_current_position_y - 5 and is_climbing then
        g_player_current_position_x = g_player_old_position_x;
    end

    if get_platform_extra(g_player_current_platform_index) == 2 then
        if g_player_current_position_x > g_player_old_position_x then
            g_player_current_position_x = g_player_old_position_x;
        end

        if g_player_current_position_y > g_player_old_position_y then
            g_player_current_position_y = g_player_old_position_y;
        end
    end

    if get_platform_extra(g_player_current_platform_index) == 1 then
        if g_player_current_position_x < g_player_old_position_x then
            g_player_current_position_x = g_player_old_position_x;
        end

        if g_player_current_position_y > g_player_old_position_y then
            g_player_current_position_y = g_player_old_position_y;
        end
    end
end

local function DoDeathBounce_()
    stop_music_track_1();
    g_player_current_state = player_state.JSDYING;
    g_player_dying_animation_state = player_dying_animation_state.FALLING;
    g_player_dying_animation_state_frame_count = 0;
    g_player_current_velocity_x = 0;
    g_player_absolute_frame_count = g_player_current_state_frame_count;
    g_player_current_state_frame_count = 1000;

    local iRand = math.random(0, 0x7fff);

    if (iRand & 7) == 1 and g_player_current_position_x > 30 then
        g_player_current_velocity_x = -1;
    end

    if (iRand & 7) == 2 and g_player_current_position_x < 130 then
        g_player_current_velocity_x = 1;
    end
end

MoveJumpmanFalling_ = function(game_input)
    g_player_current_state = player_state.JSFALLING;
    g_player_current_special_action = player_special_action.NONE;

    g_player_current_position_y = g_player_current_position_y - 1;
    g_player_current_state_frame_count = g_player_current_state_frame_count + 1;
    g_player_current_rotation_x_radians = g_player_current_state_frame_count / -10.0;
    g_player_current_mesh = player_mesh.JUMP_UP;

    if g_player_current_state_frame_count > 10 then
        g_player_current_position_y = g_player_current_position_y - 0.5;
    end

    if g_player_current_state_frame_count > 20 then
        g_player_current_position_y = g_player_current_position_y - 0.5;
    end

    if g_player_current_position_y <= g_player_current_platform_y and
            get_platform_extra(g_player_current_platform_index) ~= 3 then
        if g_player_current_state_frame_count < 10 then
            MoveJumpmanNormal_(game_input);
            return;
        else
            g_player_current_special_action = player_special_action.NONE;
            DoDeathBounce_();
            return;
        end
    end
end

MoveJumpmanJumping_ = function(game_input)
    g_player_current_state = player_state.JSJUMPING;

    if g_player_current_special_action ~= player_special_action.KICK and
            game_input.attack_action.is_pressed and (
                g_player_current_direction == player_movement_direction.DIR_RIGHT or
                g_player_current_direction == player_movement_direction.DIR_LEFT) then
        g_player_current_special_action = player_special_action.KICK;
    end

    if g_player_current_exact_ladder_index ~= -1 and
            not game_input.attack_action.is_pressed and (
                g_player_current_state_frame_count > 15 or
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
                g_player_current_state_frame_count > 10 or
                not game_input.jump_action.is_pressed or
                (g_player_current_direction == player_movement_direction.DIR_RIGHT and
                    game_input.move_left_action.is_pressed) or
                (g_player_current_direction == player_movement_direction.DIR_LEFT and
                    game_input.move_right_action.is_pressed)) then
        MoveJumpmanVine_(game_input);
        return;
    end

    if g_player_current_state_frame_count > 50 then
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

    if g_player_current_position_y < g_player_current_platform_y and
            g_player_current_state_frame_count > 6 and
            (not game_input.jump_action.is_pressed or g_player_current_state_frame_count > 12) then
        MoveJumpmanNormal_(game_input);
        return;
    end

    g_player_current_state_frame_count = g_player_current_state_frame_count + 1;

    if g_player_current_state_frame_count == 1 then
        g_player_current_position_y = g_player_current_position_y + 1;
    end

    if g_player_current_state_frame_count < 5 or
            g_player_current_state_frame_count == 6 or
            g_player_current_state_frame_count == 8 or
            g_player_current_state_frame_count == 10 or
            g_player_current_state_frame_count == 12 then
        g_player_current_position_y = g_player_current_position_y + 1;
    end

    if g_player_current_state_frame_count > 26 or
            g_player_current_state_frame_count == 25 or
            g_player_current_state_frame_count == 23 or
            g_player_current_state_frame_count == 20 or
            g_player_current_state_frame_count == 17 then
        g_player_current_position_y = g_player_current_position_y - 1;
    end

    g_player_current_mesh = player_mesh.JUMP_UP;

    if g_player_current_direction == player_movement_direction.DIR_LEFT then
        g_player_current_position_x = g_player_current_position_x - 1;
        g_player_current_mesh = g_player_current_special_action == player_special_action.KICK
            and player_mesh.KICK_LEFT
            or player_mesh.JUMP_LEFT;
    end

    if g_player_current_direction == player_movement_direction.DIR_RIGHT then
        g_player_current_position_x = g_player_current_position_x + 1;
        g_player_current_mesh = g_player_current_special_action == player_special_action.KICK
            and player_mesh.KICK_RIGHT
            or player_mesh.JUMP_RIGHT;
    end

    if game_input.move_down_action.is_pressed and
            g_player_no_roll_cooldown_frame_count == 0 and
            (g_player_current_direction == player_movement_direction.DIR_RIGHT or
                g_player_current_direction == player_movement_direction.DIR_LEFT) then
        g_player_current_state_frame_count = 0;
        MoveJumpmanRoll_(game_input);
    end
end

MoveJumpmanSlide_ = function(game_input)
    g_player_current_state = player_state.JSSLIDE;
    g_player_current_special_action = player_special_action.NONE;

    local iExtra = get_platform_extra(g_player_current_platform_index);

    if iExtra == 0 and g_player_current_position_y <= g_player_current_platform_y then
        MoveJumpmanNormal_(game_input);
        return;
    end

    if g_player_current_position_y > g_player_current_platform_y + 3 then
        g_player_current_state_frame_count = g_player_current_state_frame_count + 1;

        if g_player_current_state_frame_count > 30 then
            MoveJumpmanNormal_(game_input);
            return;
        end
    else
        g_player_current_state_frame_count = 0;
    end

    if g_player_current_position_y < g_player_current_platform_y + 1 then
        if iExtra == 1 then
            if CheckJumpStart_(0, 0, 1, game_input) then
                return;
            end

            g_player_current_position_x = g_player_current_position_x + 1;
            g_player_current_direction = player_movement_direction.DIR_RIGHT;
        end

        if iExtra == 2 then
            if CheckJumpStart_(1, 0, 0, game_input) then
                return;
            end

            g_player_current_position_x = g_player_current_position_x - 1;
            g_player_current_direction = player_movement_direction.DIR_LEFT;
        end
    else
        if g_player_current_direction == player_movement_direction.DIR_RIGHT then
            if g_player_current_state_frame_count < 6 then
                if CheckJumpStart_(0, 0, 1, game_input) then
                    return;
                end
            end

            g_player_current_position_x = g_player_current_position_x +
                ((30 - g_player_current_state_frame_count) / 60.0 + 0.5);
        end

        if g_player_current_direction == player_movement_direction.DIR_LEFT then
            if g_player_current_state_frame_count < 6 then
                if CheckJumpStart_(1, 0, 0, game_input) then
                    return;
                end
            end

            g_player_current_position_x = g_player_current_position_x -
                ((30 - g_player_current_state_frame_count) / 60.0 + 0.5);
        end
    end

    if g_player_current_direction == player_movement_direction.DIR_RIGHT then
        g_player_current_mesh = player_mesh.SLIDE_RIGHT;

        if (g_player_absolute_frame_count & 7) == 1 or
                (g_player_absolute_frame_count & 7) == 2 or
                (g_player_absolute_frame_count & 7) == 4 or
                (g_player_absolute_frame_count & 7) == 5 then
            g_player_current_mesh = player_mesh.SLIDE_RIGHT_B;
        end
    else
        g_player_current_mesh = player_mesh.SLIDE_LEFT;

        if (g_player_absolute_frame_count & 7) == 1 or
                (g_player_absolute_frame_count & 7) == 2 or
                (g_player_absolute_frame_count & 7) == 4 or
                (g_player_absolute_frame_count & 7) == 5 then
            g_player_current_mesh = player_mesh.SLIDE_LEFT_B;
        end
    end

    if g_player_current_position_y < g_player_current_platform_y + 2 and
            g_player_current_position_y > g_player_current_platform_y - 2 then
        g_player_current_position_y = g_player_current_platform_y;
    end

    if g_player_current_position_y < g_player_current_platform_y then
        g_player_current_position_y = g_player_current_position_y + 1;
    end

    if g_player_current_position_y < g_player_current_platform_y then
        g_player_current_position_y = g_player_current_position_y + 1;
    end

    if g_player_current_position_y > g_player_current_platform_y then
        g_player_current_position_y = g_player_current_position_y - 1;
    end

    if g_player_current_position_y > g_player_current_platform_y then
        g_player_current_position_y = g_player_current_position_y - 1;
    end
end

MoveJumpmanRoll_ = function(game_input)
    g_player_current_state = player_state.JSROLL;
    g_player_current_special_action = player_special_action.NONE;

    if g_player_current_state_frame_count < 7 or
            g_player_current_position_y > g_player_current_platform_y + 1 then
        g_player_current_state_frame_count = g_player_current_state_frame_count + 1;

        if g_player_current_state_frame_count > 50 then
            MoveJumpmanNormal_(game_input);
            return;
        end
    else
        g_player_current_state_frame_count = 7;
    end

    if g_player_current_position_y <= g_player_current_platform_y and (
            get_platform_extra(g_player_current_platform_index) == 1 or
            get_platform_extra(g_player_current_platform_index) == 2) then
        MoveJumpmanSlide_(game_input);
        return;
    end

    if g_player_current_position_y <= g_player_current_platform_y then
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
            g_player_current_position_y <= g_player_current_platform_y + 0.1 and
            game_input.attack_action.is_pressed then
        g_player_current_state_frame_count = 0;
        MoveJumpmanPunch_(game_input);
        return;
    end

    if g_player_current_exact_ladder_index ~= -1 and
            g_player_current_platform_y < g_player_current_position_y and
            g_player_current_state_frame_count > 10 then
        MoveJumpmanLadder_(game_input);
        return;
    end

    if g_player_current_exact_vine_index ~= -1 and
            g_player_current_platform_y < g_player_current_position_y and
            g_player_current_state_frame_count > 10 then
        MoveJumpmanVine_(game_input);
        return;
    end

    AdjustPlayerZ_(
        get_platform_z1(g_player_current_platform_index) - 2,
        g_player_current_position_y - g_player_current_platform_y);

    local iVel = 1.3;

    if g_player_current_state_frame_count > 8 then
        iVel = 1;
    end

    if g_player_current_state_frame_count > 25 then
        iVel = 0.7;
    end

    if g_player_current_state_frame_count > 38 then
        iVel = 0.3;
    end

    if g_player_current_direction == player_movement_direction.DIR_LEFT then
        g_player_current_position_x = g_player_current_position_x - iVel;
        g_player_current_mesh = player_mesh.ROLL_LEFT_1 + ((g_player_absolute_frame_count & 6) >> 1);

        if g_player_current_state_frame_count < 6 then
            g_player_current_mesh = player_mesh.DIVE_LEFT;
        end
    end

    if g_player_current_direction == player_movement_direction.DIR_RIGHT then
        g_player_current_position_x = g_player_current_position_x + iVel;
        g_player_current_mesh = player_mesh.ROLL_RIGHT_1 + ((g_player_absolute_frame_count & 6) >> 1);

        if g_player_current_state_frame_count < 6 then
            g_player_current_mesh = player_mesh.DIVE_RIGHT;
        end
    end

    UpdateSituation_();

    if g_player_current_platform_y < g_player_current_position_y + 1 and
            g_player_current_platform_y > g_player_current_position_y - 1 then
        g_player_current_position_y = g_player_current_platform_y;
    elseif g_player_current_platform_y < g_player_current_position_y then
        g_player_current_position_y = g_player_current_position_y - 1;
    elseif g_player_current_platform_y > g_player_current_position_y then
        g_player_current_position_y = g_player_current_position_y + 1;
    end
end

MoveJumpmanPunch_ = function(game_input)
    g_player_current_state = player_state.JSPUNCH;
    g_player_current_special_action = player_special_action.PUNCH;

    if g_player_current_state_frame_count > 20 or
            (g_player_current_state_frame_count < 12 and
                g_player_current_position_y < g_player_current_platform_y - 2) or
            (g_player_current_state_frame_count > 11 and
                g_player_current_position_y <= g_player_current_platform_y) then
        MoveJumpmanNormal_(game_input);
        return;
    end

    g_player_current_state_frame_count = g_player_current_state_frame_count + 1;

    if g_player_current_state_frame_count < 3 then
        g_player_current_mesh = g_player_current_direction == player_movement_direction.DIR_RIGHT
            and player_mesh.PUNCH_RIGHT_1
            or player_mesh.PUNCH_LEFT_1;
    else
        g_player_current_mesh = g_player_current_direction == player_movement_direction.DIR_RIGHT
            and player_mesh.PUNCH_RIGHT_2
            or player_mesh.PUNCH_LEFT_2;
    end

    if g_player_current_state_frame_count < 11 and g_player_current_state_frame_count ~= 9 then
        g_player_current_position_y = g_player_current_position_y + 1;
    end

    if g_player_current_state_frame_count > 12 and g_player_current_state_frame_count ~= 14 then
        g_player_current_position_y = g_player_current_position_y - 1;
    end

    if g_player_current_state_frame_count < 4 or
            g_player_current_state_frame_count == 5 or
            g_player_current_state_frame_count == 7 then
        g_player_current_position_x = g_player_current_position_x +
            (g_player_current_direction == player_movement_direction.DIR_RIGHT and 1 or -1);
    end
end

local function MoveJumpman_(game_input)
    g_player_old_position_x = g_player_current_position_x;
    g_player_old_position_y = g_player_current_position_y;
    g_is_already_on_ladder = false;

    UpdateSituation_();

    if (g_player_current_state == player_state.JSVINE) then
        MoveJumpmanVine_(game_input);
    elseif (g_player_current_state == player_state.JSLADDER) then
        MoveJumpmanLadder_(game_input);
    elseif (g_player_current_state == player_state.JSNORMAL) then
        MoveJumpmanNormal_(game_input);
    elseif (g_player_current_state == player_state.JSFALLING) then
        MoveJumpmanFalling_(game_input);
    elseif (g_player_current_state == player_state.JSJUMPING) then
        MoveJumpmanJumping_(game_input);
    elseif (g_player_current_state == player_state.JSSLIDE) then
        MoveJumpmanSlide_(game_input);
    elseif (g_player_current_state == player_state.JSROLL) then
        MoveJumpmanRoll_(game_input);
    elseif (g_player_current_state == player_state.JSPUNCH) then
        MoveJumpmanPunch_(game_input);
    end

    if (g_player_current_position_y < 0) then
        g_player_current_special_action = player_special_action.NONE;
        DoDeathBounce_();
        return;
    end

    for iRep = 0, 1 do
        local iCollide = CollideWall_(
            g_player_current_position_x - 2, g_player_current_position_y + 11,
            g_player_current_position_x + 2, g_player_current_position_y + 9);

        if iCollide == 1 then
            g_player_current_position_y = g_player_current_position_y - 1;

            if g_player_current_state == player_state.JSJUMPING and g_player_current_state_frame_count < 15 then
                g_player_current_state_frame_count = 15;
            end
        end

        iCollide = CollideWall_(
            g_player_current_position_x - 3, g_player_current_position_y + 9,
            g_player_current_position_x + 3, g_player_current_position_y + 3);

        if iCollide == 3 then
            g_player_current_position_x = g_player_current_position_x + 1;

            if g_player_current_state == player_state.JSJUMPING and g_player_current_state_frame_count < 15 then
                g_player_current_state_frame_count = 16;
            end

            if g_player_current_state ~= player_state.JSJUMPING and
                    g_player_current_position_y > g_player_current_platform_y - 1 and
                    g_player_current_position_y >= g_player_old_position_y then
                g_player_current_position_y = g_player_current_position_y - 1;
            end
        end

        if iCollide == 4 then
            g_player_current_position_x = g_player_current_position_x - 1;

            if g_player_current_state == player_state.JSJUMPING and g_player_current_state_frame_count < 15 then
                g_player_current_state_frame_count = 16;
            end

            if g_player_current_state ~= player_state.JSJUMPING and
                    g_player_current_position_y > g_player_current_platform_y - 1 and
                    g_player_current_position_y >= g_player_old_position_y then
                g_player_current_position_y = g_player_current_position_y - 1;
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
            g_player_current_state_frame_count = 0;
            g_player_current_state = player_state.JSDONE;
        else
            play_sound_effect(1);
        end
    end
end

local function AnimateDying_(game_input)
    g_player_current_active_platform_index = -1;

    if g_player_dying_animation_state == player_dying_animation_state.BOUNCING then
        g_player_current_mesh = player_mesh.JUMP_UP;
        g_player_dying_animation_state_frame_count = g_player_dying_animation_state_frame_count + 1;
        local dying_anim_frame_count = g_player_dying_animation_state_frame_count;

        if dying_anim_frame_count < 5 or dying_anim_frame_count == 6 then
            g_player_current_position_y = g_player_current_position_y + 1;
        end

        if dying_anim_frame_count > 10 or dying_anim_frame_count == 8 then
            g_player_current_position_y = g_player_current_position_y - 1;
        end

        if dying_anim_frame_count > 15 then
            g_player_dying_animation_state = player_dying_animation_state.FALLING;
        end

        g_player_absolute_frame_count = g_player_absolute_frame_count + 1;

        if g_player_current_state_frame_count < 10 then
            g_player_absolute_frame_count = g_player_absolute_frame_count + 1;
        end

        if g_player_current_state_frame_count < 5 then
            g_player_absolute_frame_count = g_player_absolute_frame_count + 1;
        end

        if g_player_current_state_frame_count < 0 then
            g_player_absolute_frame_count = g_player_absolute_frame_count + 1;
            g_player_current_mesh = player_mesh.DEAD;
        end

        g_player_current_rotation_x_radians = g_player_absolute_frame_count / -10.0;

        if (g_player_absolute_frame_count & 1) ~= 0 then
            g_player_current_position_x = g_player_current_position_x + g_player_current_velocity_x;
        end
    end

    if g_player_dying_animation_state == player_dying_animation_state.FALLING then
        g_player_current_mesh = player_mesh.JUMP_UP;
        g_player_absolute_frame_count = g_player_absolute_frame_count + 1;
        g_player_current_position_y = g_player_current_position_y - 2;
        g_player_current_rotation_x_radians = g_player_absolute_frame_count / -10.0;

        local iSupport, iPlatform = FindPlatform_(
            g_player_current_position_x, g_player_current_position_y, 8, 2);
        iSupport = iSupport - PlayerFloor_();

        local bGrounded = g_player_current_position_y + 4 <= iSupport;
        AdjustPlayerZ_(get_platform_z1(iPlatform) - 2, g_player_current_position_y - iSupport);

        if bGrounded and g_player_current_position_y > -5 and iSupport < g_player_current_state_frame_count then
            g_player_current_velocity_x = 0;
            local iRand = math.random(0, 0x7fff);

            if (iRand & 3) == 1 and g_player_current_position_y > 30 and g_player_current_position_x > 30 then
                g_player_current_velocity_x = -1;
            end

            if (iRand & 3) == 2 and g_player_current_position_y > 30 and g_player_current_position_x < 130 then
                g_player_current_velocity_x = 1;
            end

            g_player_current_state_frame_count = iSupport - 3;
            g_player_dying_animation_state = player_dying_animation_state.BOUNCING;
            g_player_dying_animation_state_frame_count = 0;

            play_sound_effect(2);

            local _;
            _, iPlatform = FindPlatform_(g_player_current_position_x, g_player_current_position_y - 8, 8, 2);

            if iPlatform == -1 then
                g_player_dying_animation_state = player_dying_animation_state.FINAL_BOUNCE;
                g_player_dying_animation_state_frame_count = 0;
                g_player_absolute_frame_count = 0;
            end
        end

        if g_player_current_position_y < -2 and
                g_player_dying_animation_state == player_dying_animation_state.FALLING then
            g_player_dying_animation_state = player_dying_animation_state.FINAL_BOUNCE;
            g_player_absolute_frame_count = 0;
        end
    end

    if g_player_dying_animation_state == player_dying_animation_state.FINAL_BOUNCE then
        g_player_current_mesh = player_mesh.DEAD;
        g_player_dying_animation_state_frame_count = g_player_dying_animation_state_frame_count + 1;
        local dying_anim_frame_count = g_player_dying_animation_state_frame_count;

        if dying_anim_frame_count < 10 or dying_anim_frame_count == 12 or dying_anim_frame_count == 14 then
            g_player_current_position_y = g_player_current_position_y + 1;
        end

        if dying_anim_frame_count > 20 or dying_anim_frame_count == 18 or dying_anim_frame_count == 16 then
            g_player_current_position_y = g_player_current_position_y - 1;
        end

        if dying_anim_frame_count == 10 or dying_anim_frame_count == 12 or
                dying_anim_frame_count == 17 or dying_anim_frame_count == 20 then
            g_player_current_position_z = g_player_current_position_z - 1;
        end

        if dying_anim_frame_count == 25 then
            play_death_music_track();
        end

        g_player_absolute_frame_count = g_player_absolute_frame_count + 4;
        g_player_current_rotation_x_radians = g_player_absolute_frame_count / -10.0;

        if dying_anim_frame_count > 30 then
            g_player_dying_animation_state = player_dying_animation_state.SPINNING_STARS;
            g_player_absolute_frame_count = 0;
            g_player_current_rotation_x_radians = 0;
        end
    end

    if g_player_dying_animation_state == player_dying_animation_state.SPINNING_STARS then
        select_object_mesh(get_player_mesh_index(player_mesh.STARS));
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_rotate_matrix_y(g_player_absolute_frame_count * 180.0 / 50.0);
        script_selected_mesh_translate_matrix(
            g_player_current_position_x, g_player_current_position_y + 12, g_player_current_position_z + 1);
        set_object_visual_data(0, 1);

        g_player_absolute_frame_count = g_player_absolute_frame_count + 1;
        g_player_current_rotation_x_radians = 0.1;
        g_player_current_mesh = player_mesh.DEAD;

        if g_player_absolute_frame_count == 85 then
            set_object_visual_data(0, 0);
            set_remaining_life_count(get_remaining_life_count() - 1);

            if get_remaining_life_count() == 0 then
                queue_level_load("GameOver");
            else
                g_player_dying_animation_state = -1;
                g_player_dying_animation_state_frame_count = -1;

                if Module.ResetPlayerCallback then
                    Module.ResetPlayerCallback(game_input);
                end

                restart_music_track_1();
            end
        end
    end
end

function Module.initialize()
    -- Nothing here for now!
end

-- Required if you want to use get_navigation_dir function. Otherwise don't call it, to speed up level load
function Module.build_navigation()
    BuildNavigation_();
end

-- Returns true if player won
function Module.progress_game(game_input)
    g_game_time_inactive = g_game_time_inactive + 1;

    if game_input.move_left_action.is_pressed or game_input.move_right_action.is_pressed or
            game_input.move_up_action.is_pressed or game_input.move_down_action.is_pressed or
            game_input.jump_action.is_pressed then
        g_game_time_inactive = 0;
    end

    if (g_player_current_state & player_state.JSDONE) == 0 then
        if g_player_freeze_cooldown_frame_count ~= 0 then
            g_player_freeze_cooldown_frame_count = g_player_freeze_cooldown_frame_count - 1;
        end

        if g_player_no_roll_cooldown_frame_count ~= 0 then
            g_player_no_roll_cooldown_frame_count = g_player_no_roll_cooldown_frame_count - 1;
        end

        if (g_player_current_state & player_state.JSDYING) == 0 and g_player_freeze_cooldown_frame_count == 0 then
            g_player_absolute_frame_count = g_player_absolute_frame_count + 1;
            g_player_current_rotation_x_radians = 0;
            g_player_current_mesh = player_mesh.STAND;
            MoveJumpman_(game_input);

            if g_player_current_mesh == player_mesh.STAND and
                    g_player_is_visible and
                    g_game_time_inactive > 400 then
                local iTemp = math.floor((g_game_time_inactive % 400) / 6);
                iTemp = iTemp > 10 and 2 or (iTemp & 1);
                g_player_current_mesh = player_mesh.BORED_1 + iTemp;
            end

            GrabDonuts_(game_input);
        end

        if (g_player_current_state & player_state.JSDYING) ~= 0 and g_player_freeze_cooldown_frame_count == 0 then
            AnimateDying_(game_input);
            GrabDonuts_(game_input);
        end

        Module.reset_perspective();

        return false;
    else
        g_player_current_state_frame_count = g_player_current_state_frame_count + 1;

        if g_player_current_state_frame_count == 30 then
            play_win_music_track();
        end

        if g_player_current_state_frame_count == 300 then
            load_next_level();
        end

        return true;
    end
end

function Module.update_player_graphics()
    -- TODO: Is this breaking the swim level, or is the swim level itself broken? (script25)
    -- TODO: Also the baboon level looks a bit strange when jumping on horizontal climb vines/platforms (script24)
    local current_player_mesh_index = get_player_mesh_index(g_player_current_mesh);

    select_object_mesh(current_player_mesh_index);

    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_rotate_matrix_x(g_player_current_rotation_x_radians * 180.0 / 3.14);
    script_selected_mesh_translate_matrix(
        g_player_current_position_x, g_player_current_position_y + 6, g_player_current_position_z + 1);

    if g_player_is_visible then
        set_object_visual_data(0, 1);  -- TODO: Don't hard-code texture index?
    end

    if g_player_current_mesh ~= g_player_previous_mesh then
        select_object_mesh(get_player_mesh_index(g_player_previous_mesh))
        set_object_visual_data(0, 0);
        g_player_previous_mesh = g_player_current_mesh;
    end
end

function Module.reset_perspective()
    if g_player_current_position_x > -50 then
        g_camera_track_player_pos_x = g_player_current_position_x;
    end

    g_camera_track_player_pos_y = g_player_current_position_y;

    local target_pos_x = g_camera_track_player_pos_x / 2 + g_level_extent_x / 4;
    local target_pos_y = g_camera_track_player_pos_y;

    if target_pos_x < 35 then
        target_pos_x = 35;
    end

    if target_pos_x > g_level_extent_x - 45 then
        target_pos_x = g_level_extent_x - 45;
    end

    g_camera_current_pos_x = (g_camera_current_pos_x + target_pos_x) / 2;
    g_camera_current_pos_y = (g_camera_current_pos_y + target_pos_y) / 2;

    if g_camera_current_pos_x < target_pos_x - 10 or g_camera_current_pos_x > target_pos_x + 10 then
        g_camera_current_pos_x = target_pos_x;
    end

    if g_camera_current_pos_y < target_pos_y - 10 or g_camera_current_pos_y > target_pos_y + 10 then
        g_camera_current_pos_y = target_pos_y;
    end

    if g_current_camera_mode == camera_mode.PerspectiveNormal then
        set_perspective(
            g_camera_current_pos_x, g_camera_current_pos_y + 40.0, -115.0,
            g_camera_current_pos_x, g_camera_current_pos_y, 0.0);
    end

    if g_current_camera_mode == camera_mode.PerspectiveCloseUp then
        set_perspective(
            g_player_current_position_x, g_camera_current_pos_y + 35.0, -95.0,
            g_player_current_position_x, g_camera_current_pos_y + 7, 0.0);
    end

    if g_current_camera_mode == camera_mode.PerspectiveFar then
        set_perspective(80, g_camera_current_pos_y + 50, -195.0, 80, g_camera_current_pos_y, 0);
    end

    if g_current_camera_mode == camera_mode.PerspectiveWide then
        set_perspective(
            g_player_current_position_x, g_camera_current_pos_y / 2 + 60.0, -110,
            g_player_current_position_x, g_camera_current_pos_y / 2 + 32.0, 0);
    end

    if g_current_camera_mode == camera_mode.PerspectiveFollow then
        set_perspective(
            g_player_current_position_x, g_camera_current_pos_y / 2 + 60.0, -110,
            g_player_current_position_x, g_camera_current_pos_y / 2 + 32.0, 0);
    end

    if g_current_camera_mode == camera_mode.PerspectiveFixed then
        set_perspective(70, 110, -60, 100, 90, 0);
    end

    if g_current_camera_mode == camera_mode.PerspectiveAbove then
        set_perspective(80, 150, 0.0, 80, 80, 30);
    end

    if g_current_camera_mode == camera_mode.PerspectiveFlat then
        set_perspective(
            g_player_current_position_x, g_player_current_position_y, -75.0,
            g_player_current_position_x, g_player_current_position_y, 0.0);
    end

    if g_current_camera_mode == camera_mode.PerspectiveFarAbove then
        set_perspective(
            g_player_current_position_x, g_player_current_position_y + 60, -95.0,
            g_player_current_position_x, g_player_current_position_y, 0.0);
    end
end

function Module.kill()
    if (g_player_current_state & player_state.JSDYING) == 0 then
        stop_music_track_1();
        g_player_current_state = player_state.JSDYING;
        g_player_current_special_action = player_special_action.NONE;
        g_player_dying_animation_state = player_dying_animation_state.FALLING;
        g_player_dying_animation_state_frame_count = 0;
        g_player_current_velocity_x = 0;
        g_player_absolute_frame_count = g_player_current_state_frame_count;
        g_player_current_state_frame_count = 1000;
    end
end

function Module.win()
    stop_music_track_1();
    g_player_current_state_frame_count = 0;
    g_player_current_state = player_state.JSDONE;
end

function Module.get_player_current_state()
    return g_player_current_state;
end

function Module.set_player_current_state(new_state)
    g_player_current_state = new_state;
end

function Module.get_player_current_state_frame_count()
    return g_player_current_state_frame_count;
end

function Module.set_player_current_state_frame_count(new_frame_count)
    g_player_current_state_frame_count = new_frame_count;
end

function Module.set_player_is_visible(new_is_visible)
    g_player_is_visible = new_is_visible
end

function Module.get_player_current_position_x()
    return g_player_current_position_x;
end

function Module.set_player_current_position_x(new_pos_x)
    g_player_current_position_x = new_pos_x;
end

function Module.get_player_current_position_y()
    return g_player_current_position_y;
end

function Module.set_player_current_position_y(new_pos_y)
    g_player_current_position_y = new_pos_y;
end

function Module.get_player_current_position_z()
    return g_player_current_position_z;
end

function Module.set_player_current_position_z(new_pos_z)
    g_player_current_position_z = new_pos_z;
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

function Module.get_player_current_special_action()
    return g_player_current_special_action;
end

function Module.set_player_current_special_action(new_special_action)
    g_player_current_special_action = new_special_action;
end

function Module.get_player_no_roll_cooldown_frame_count()
    return g_player_no_roll_cooldown_frame_count;
end

function Module.set_player_no_roll_cooldown_frame_count(new_frame_count)
    g_player_no_roll_cooldown_frame_count = new_frame_count;
end

function Module.get_player_freeze_cooldown_frame_count()
    return g_player_freeze_cooldown_frame_count;
end

function Module.set_player_freeze_cooldown_frame_count(new_frame_count)
    g_player_freeze_cooldown_frame_count = new_frame_count;
end

function Module.set_current_camera_mode(new_camera_mode)
    g_current_camera_mode = new_camera_mode;
end

function Module.get_level_extent_x()
    return g_level_extent_x;
end

function Module.set_level_extent_x(new_level_extent_x)
    g_level_extent_x = new_level_extent_x;
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
    return PlayerCollide_(x1, y1, x2, y2) and g_player_current_state ~= player_state.JSDYING;
end

function Module.get_navigation_dir(from_object_index, to_object_index, nav_from_type, nav_to_type)
    return GetNavDir_(from_object_index, to_object_index, nav_from_type, nav_to_type);
end

return Module;
