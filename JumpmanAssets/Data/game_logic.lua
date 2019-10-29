local read_only = require "Data/read_only";

local Module = {};

Module.MenuLogic = nil;
Module.LevelData = nil;
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
    LADDER = 1,  -- Can mount this ladder
    PLATFORM = 2,  -- Can walk onto this other platform
    PLATFORM_FALL_LEFT = 3,  -- Can fall off the current platform to the left to reach this platform
    PLATFORM_FALL_RIGHT = 4,  -- Can fall off the current platform to the right to reach this platform
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

local g_player_mesh_indices = {};
local g_letter_mesh_indices = {};

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

local g_win_with_no_delay = false;  -- Used for debugging

local g_level_extent_x = 160;

local g_donut_is_collected = {};

local g_current_camera_mode = camera_mode.PerspectiveNormal;
local g_camera_current_pos_x = 0;
local g_camera_current_pos_y = 0;
local g_camera_track_player_pos_x = 0;
local g_camera_track_player_pos_y = 0;

-- Nav To (Object that specifies a way to navigate off the current object, to the specified object_index)
-- {
--     type: (the type of exit to take from this object. See navigation_type above),
--     object_index: (the object index you will arrive at after leaving this object)
-- }
local g_ladder_nav_to_entries = {};  -- Map ladder index to list of Nav To entries
local g_platform_nav_to_entries = {};  -- Map platform index to list of Nav To entries

-- TODO: Refactor this to not encode object type + object index + navigation type together
-- Nav Select (Object that specifies the currently selected method of navigation. Can be modified while navigating)
-- {
--     distance: (the distance to the selected navigation choice),
--     encoded_object_index: (the object that is currently chosen to navigate to, plus the method to navigate to it)
-- }
local g_ladder_nav_select = {};  -- Map of ladder index to single Nav Select entry
local g_platform_nav_select = {};  -- Map of platform index to single Nav Select entry

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

    for vine_index = 0, #Module.LevelData.vines - 1 do
        local current_vine = Module.LevelData.vines[vine_index + 1];

        if iAbout == -1 or Module.LevelData.vines[vine_index + 1].y_top < current_vine.y_top then
            if current_vine.y_top - 3 > iY and current_vine.y_bottom - 9 < iY then
                if current_vine.x_pos - 3 < iX and current_vine.x_pos + 3 > iX then
                    iAbout = vine_index;

                    if current_vine.x_pos == iX then
                        iExact = vine_index;
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

    for ladder_index = 0, #Module.LevelData.ladders - 1 do
        local current_ladder = Module.LevelData.ladders[ladder_index + 1];

        if iAbout == -1 or Module.LevelData.ladders[iAbout + 1].y_top < current_ladder.y_top then
            if current_ladder.y_top - 3 > iY and current_ladder.y_bottom - 9 < iY then
                iDiff = current_ladder.x_pos - iX;

                if iDiff < 0 then
                    iDiff = iDiff * -1;
                end

                if iDiff < 8 and iDiff <= iBestDif then
                    iBestDif = iDiff;
                    iAbout = ladder_index;

                    if iDiff == 0 then
                        iExact = ladder_index;
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

    for platform_index = 0, #Module.LevelData.platforms - 1 do
        local current_platform = Module.LevelData.platforms[platform_index + 1];

        if current_platform.pos_upper_left[1] <= iX + iWide and current_platform.pos_lower_right[1] >= iX - iWide then
            local iEX = iX;

            if iEX < current_platform.pos_upper_left[1] then
                iEX = current_platform.pos_upper_left[1];
            end

            if iEX > current_platform.pos_lower_right[1] then
                iEX = current_platform.pos_lower_right[1];
            end

            local iLen = current_platform.pos_lower_right[1] - current_platform.pos_upper_left[1];
            local iH = current_platform.pos_upper_left[2] * math.abs(math.floor(current_platform.pos_lower_right[1] - iEX)) +  -- TODO: Floor necessary?
                current_platform.pos_lower_right[2] * math.abs(math.floor(current_platform.pos_upper_left[1] - iEX));  -- TODO: Floor necessary?
            iH = iH / iLen;

            local bGood = false;

            if current_platform.extra == 3 then
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
                iPlatform = platform_index;
                iExtra = current_platform.extra;
            end
        end
    end

    return iSupport, iPlatform;
end

local function BuildNavigation_()
    for ladder_index = 0, #Module.LevelData.ladders - 1 do
        g_ladder_nav_to_entries[ladder_index] = {};
    end

    for platform_index = 0, #Module.LevelData.platforms - 1 do
        g_platform_nav_to_entries[platform_index] = {};
        local current_platform = Module.LevelData.platforms[platform_index + 1];

        local platform_x1 = current_platform.pos_upper_left[1];
        local platform_y1 = current_platform.pos_upper_left[2];
        local next_platform_y, next_platform_index = FindPlatform_(platform_x1 - 4, platform_y1, 4, 2);

        if next_platform_index >= 0 then
            local nav_type = navigation_type.PLATFORM;

            if next_platform_y < platform_y1 - 4 then
                nav_type = navigation_type.PLATFORM_FALL_LEFT;
            end

            table.insert(g_platform_nav_to_entries[platform_index], {
                type = nav_type,
                object_index = next_platform_index
            });
        end

        local platform_x2 = current_platform.pos_lower_right[1];
        local platform_y2 = current_platform.pos_lower_right[2];
        next_platform_y, next_platform_index = FindPlatform_(platform_x2 + 4, platform_y2, 4, 2);

        if next_platform_index >= 0 then
            local nav_type = navigation_type.PLATFORM;

            if next_platform_y < platform_y2 - 4 then
                nav_type = navigation_type.PLATFORM_FALL_RIGHT;
            end

            table.insert(g_platform_nav_to_entries[platform_index], {
                type = nav_type,
                object_index = next_platform_index
            });
        end

        for ladder_index = 0, #Module.LevelData.ladders - 1 do
            local current_ladder = Module.LevelData.ladders[ladder_index + 1];

            if platform_x1 < current_ladder.x_pos and platform_x2 > current_ladder.x_pos then
                local platform_length = platform_x2 - platform_x1;

                -- TODO: The platform_height variable name might not be quite correct.
                --       Seems to correlate ladder's position with platform height and platform length,
                --          then compare to ladder bottom/top
                local platform_height =
                    platform_y1 * math.abs(math.floor(platform_x2 - current_ladder.x_pos)) +
                    platform_y2 * math.abs(math.floor(platform_x1 - current_ladder.x_pos));
                platform_height = platform_height / platform_length;

                if platform_height < current_ladder.y_top + 2 and platform_height > current_ladder.y_bottom - 2 then
                    table.insert(g_platform_nav_to_entries[platform_index], {
                        type = navigation_type.LADDER,
                        object_index = ladder_index
                    });
                    table.insert(g_ladder_nav_to_entries[ladder_index], {
                        type = navigation_type.PLATFORM,
                        object_index = platform_index
                    });
                end
            end
        end
    end
end

local function GetNavDir_(from_object_index, to_object_index, nav_from_type, nav_to_type)
    -- note that this function doesn't get called if enemy determine they're already on the same platform as player.
    --
    -- it also always gets called with nav_from_type = platform and nav_to_type = platform, for now
    --    however, I think that's just "closest platform to the player", and it might try to figure out ladders still
    --    TODO: Dig into that hypothesis
    --
    -- current result integer ranges:
    --   -1 = null (5000 internally)
    --   0 - 999 = platform target
    --   1000 - 1999 = ladder target
    --   2000 - 2999 = fall left (off current platform, onto target platform)
    --   3000 - 3999 = fall right (off current platform, onto target platform)
    --
    -- TODO: Refactor to return separate { object_index, object_type, navigation_method } fields,
    --       instead of encoding the result in integer ranges

    for platform_index = 0, #Module.LevelData.platforms - 1 do
        g_platform_nav_select[platform_index] = { distance = 5000, encoded_object_index = -1 };  -- TODO: Is -1 valid here?
    end

    for ladder_index = 0, #Module.LevelData.ladders - 1 do
        g_ladder_nav_select[ladder_index] = { distance = 5000, encoded_object_index = -1 };  -- TODO: Is -1 valid here?
    end

    if from_object_index < 0 or to_object_index < 0 then
        return -1;
    end

    if nav_from_type == navigation_type.LADDER then
        g_ladder_nav_select[from_object_index].distance = 0;
    end

    if nav_from_type == navigation_type.PLATFORM then
        g_platform_nav_select[from_object_index].distance = 0;
    end

    local is_done = false;

    for repeat_count = 0, 49 do  -- TODO: Use constant
        if not is_done then
            for ladder_index = 0, #Module.LevelData.ladders - 1 do
                if g_ladder_nav_select[ladder_index].distance < 5000 then
                    for nav_to_index = 1, #g_ladder_nav_to_entries[ladder_index] do
                        local ladder_nav_to_type = g_ladder_nav_to_entries[ladder_index][nav_to_index].type;
                        local nav_to_object_index = g_ladder_nav_to_entries[ladder_index][nav_to_index].object_index;
                        local ladder_nav_distance = g_ladder_nav_select[ladder_index].distance;

                        if ladder_nav_to_type == navigation_type.PLATFORM then
                            if g_platform_nav_select[nav_to_object_index].distance > ladder_nav_distance + 1 then
                                g_platform_nav_select[nav_to_object_index].distance = ladder_nav_distance + 1;
                                g_platform_nav_select[nav_to_object_index].encoded_object_index = g_ladder_nav_select[ladder_index].encoded_object_index;

                                if ladder_nav_distance == 0 then
                                    g_platform_nav_select[nav_to_object_index].encoded_object_index = nav_to_object_index;
                                end
                            end
                        end
                    end
                end
            end

            for platform_index = 0, #Module.LevelData.platforms - 1 do
                if g_platform_nav_select[platform_index].distance < 5000 then
                    for nav_index = 1, #g_platform_nav_to_entries[platform_index] do
                        local platform_nav_to_type = g_platform_nav_to_entries[platform_index][nav_index].type;
                        local nav_to_object_index = g_platform_nav_to_entries[platform_index][nav_index].object_index;
                        -- Get platform_index nav distance each time in case it gets modified inside the loop
                        local platform_nav_distance = g_platform_nav_select[platform_index].distance;

                        if platform_nav_to_type ~= navigation_type.LADDER then
                            if g_platform_nav_select[nav_to_object_index].distance > platform_nav_distance + 1 then
                                g_platform_nav_select[nav_to_object_index].distance = platform_nav_distance + 1;
                                g_platform_nav_select[nav_to_object_index].encoded_object_index = g_platform_nav_select[platform_index].encoded_object_index;

                                -- Re-get platform_index nav distance in case it gets modified just above this
                                if g_platform_nav_select[platform_index].distance == 0 then
                                    if platform_nav_to_type == navigation_type.PLATFORM then
                                        g_platform_nav_select[nav_to_object_index].encoded_object_index = nav_to_object_index;
                                    end

                                    if platform_nav_to_type == navigation_type.PLATFORM_FALL_LEFT then
                                        g_platform_nav_select[nav_to_object_index].encoded_object_index = nav_to_object_index + 2000;
                                    end

                                    if platform_nav_to_type == navigation_type.PLATFORM_FALL_RIGHT then
                                        g_platform_nav_select[nav_to_object_index].encoded_object_index = nav_to_object_index + 3000;
                                    end
                                end
                            end
                        end

                        if platform_nav_to_type == navigation_type.LADDER then
                            if g_ladder_nav_select[nav_to_object_index].distance > platform_nav_distance + 1 then
                                g_ladder_nav_select[nav_to_object_index].distance = platform_nav_distance + 1;
                                g_ladder_nav_select[nav_to_object_index].encoded_object_index = g_platform_nav_select[platform_index].encoded_object_index;

                                if platform_nav_distance == 0 then
                                    g_ladder_nav_select[nav_to_object_index].encoded_object_index = nav_to_object_index + 1000;
                                end
                            end
                        end
                    end
                end
            end

            if nav_to_type == navigation_type.LADDER and g_ladder_nav_select[to_object_index].distance < 5000 then
                is_done = true;
            end

            if nav_to_type ~= navigation_type.LADDER and g_platform_nav_select[to_object_index].distance < 5000 then
                is_done = true;
            end
        end
    end

    if not is_done then
        return -1;
    end

    local nav_choice = 0;

    if nav_to_type == navigation_type.LADDER then
        nav_choice = g_ladder_nav_select[to_object_index].encoded_object_index;
    end

    if nav_to_type ~= navigation_type.LADDER then
        nav_choice = g_platform_nav_select[to_object_index].encoded_object_index;
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

    for wall_index = 0, #Module.LevelData.walls - 1 do
        local current_wall = Module.LevelData.walls[wall_index + 1];
        local wall_x1 = current_wall.pos[1][1];
        local wall_x2 = current_wall.pos[2][1];
        local wall_x3 = current_wall.pos[3][1];
        local wall_x4 = current_wall.pos[4][1];
        local wall_y1 = current_wall.pos[1][2];
        local wall_y2 = current_wall.pos[2][2];
        local wall_y3 = current_wall.pos[3][2];
        local wall_y4 = current_wall.pos[4][2];

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

    local close_vine = Module.get_vine(g_player_current_close_vine_index);

    if CheckWalkOff_(close_vine.pos_x, game_input) then
        return;
    end

    g_player_current_mesh = (g_player_absolute_frame_count & 2) ~= 0
        and player_mesh.VINE_CLIMB_1
        or player_mesh.VINE_CLIMB_2;
    AdjustPlayerZ_(close_vine.pos_z[1] - 3, 0);

    if close_vine.pos_y_bottom < g_player_current_platform_y - 2 or
            g_player_current_position_y > g_player_current_platform_y - 1 then
        g_player_current_position_y = g_player_current_position_y - 1;
    else
        MoveJumpmanNormal_(game_input);
        return;
    end

    local iVinX = close_vine.pos_x;

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

    local close_ladder = Module.get_ladder(g_player_current_close_ladder_index);

    if g_player_current_platform_y >= g_player_current_position_y or
            (close_ladder.pos_x < g_player_current_position_x + 2 and
                close_ladder.pos_x > g_player_current_position_x - 2) then
        if CheckJumpStart_(1, 0, 1, game_input) then
            return;
        end
    end

    if CheckWalkOff_(close_ladder.pos_x, game_input) then
        return;
    end

    g_player_current_mesh = player_mesh.JUMP_UP;
    AdjustPlayerZ_(close_ladder.pos_z[1] - 3, 0);

    if game_input.move_up_action.is_pressed and close_ladder.pos_y_top - 5 > g_player_current_position_y then
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
            (close_ladder.pos_y_bottom < g_player_current_platform_y - 3 or
                g_player_current_position_y > g_player_current_platform_y) then
        g_player_current_position_y = g_player_current_position_y - 1;
        g_player_current_mesh = (g_player_absolute_frame_count & 2) ~= 0
            and player_mesh.LADDER_CLIMB_2
            or player_mesh.LADDER_CLIMB_1;

        if close_ladder.pos_y_bottom >= g_player_current_platform_y - 3 and
                g_player_current_position_y < g_player_current_platform_y then
            g_player_current_position_y = g_player_current_platform_y;
        end
    end

    local iLadderX = close_ladder.pos_x;

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

    local player_platform = Module.LevelData.platforms[g_player_current_platform_index + 1];

    if player_platform then
        AdjustPlayerZ_(player_platform.pos_z - 2, g_player_current_position_y - g_player_current_platform_y);
    end

    if g_player_current_close_vine_index ~= -1 and
            not game_input.move_left_action.is_pressed and not game_input.move_right_action.is_pressed then
        local close_vine = Module.LevelData.vines[g_player_current_close_vine_index + 1];

        if (close_vine.y_bottom < g_player_current_platform_y - 2 or
                g_player_current_position_y > g_player_current_platform_y) then
            MoveJumpmanVine_(game_input);
            return;
        end
    end

    if g_player_current_platform_y > g_player_current_position_y - 2 and
            player_platform and (player_platform.extra == 1 or player_platform.extra == 2) then
        MoveJumpmanSlide_(game_input);
        return;
    end

    if g_player_current_close_ladder_index ~= -1 and not g_is_already_on_ladder and
            (game_input.move_up_action.is_pressed ~= game_input.move_down_action.is_pressed) then
        local close_ladder = Module.LevelData.ladders[g_player_current_close_ladder_index + 1];

        if (not game_input.move_right_action.is_pressed or g_player_current_position_x < close_ladder.x_pos + 1) and
                (not game_input.move_left_action.is_pressed or
                    g_player_current_position_x > close_ladder.x_pos - 1) then
            if game_input.move_up_action.is_pressed and close_ladder.y_top - 5 > g_player_current_position_y then
                MoveJumpmanLadder_(game_input);
                return;
            end

            if game_input.move_down_action.is_pressed and
                    (close_ladder.y_bottom < g_player_current_platform_y - 3 or
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

    if player_platform and player_platform.extra == 2 then
        if g_player_current_position_x > g_player_old_position_x then
            g_player_current_position_x = g_player_old_position_x;
        end

        if g_player_current_position_y > g_player_old_position_y then
            g_player_current_position_y = g_player_old_position_y;
        end
    end

    if player_platform and player_platform.extra == 1 then
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

    local player_platform = Module.LevelData.platforms[g_player_current_platform_index + 1];

    if g_player_current_position_y <= g_player_current_platform_y and
            player_platform and player_platform.extra ~= 3 then
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

    local player_platform = Module.LevelData.platforms[g_player_current_platform_index + 1];
    local iExtra = -1;

    if player_platform then
        iExtra = player_platform.extra;
    end

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

    local player_platform = Module.LevelData.platforms[g_player_current_platform_index + 1];

    if g_player_current_position_y <= g_player_current_platform_y and
            player_platform and (player_platform.extra == 1 or player_platform.extra == 2) then
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

    if player_platform then
        AdjustPlayerZ_(player_platform.pos_z - 2, g_player_current_position_y - g_player_current_platform_y);
    end

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
    local donut_count = #Module.LevelData.donuts;

    for donut_index = 0, donut_count - 1 do
        local current_donut = Module.get_donut(donut_index);

        if not g_donut_is_collected[donut_index] and
                PlayerCollide_(
                    current_donut.pos[1] - 3, current_donut.pos[2] - 4,
                    current_donut.pos[1] + 3, current_donut.pos[2] + 2) then
            g_donut_is_collected[donut_index] = true;
            set_mesh_is_visible(current_donut.mesh_index, false);
            iGot = true;

            if Module.OnCollectDonutCallback then
                Module.OnCollectDonutCallback(game_input, current_donut.number);
            end
        end
    end

    if iGot then
        local iWon = true;

        for iCheck = 0, donut_count - 1 do
            if not g_donut_is_collected[iCheck] then
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

        local iSupport, iPlatform = FindPlatform_(g_player_current_position_x, g_player_current_position_y, 8, 2);
        iSupport = iSupport - PlayerFloor_();

        if iPlatform ~= -1 then
            AdjustPlayerZ_(Module.LevelData.platforms[iPlatform + 1].pos_z - 2, g_player_current_position_y - iSupport);
        end

        local bGrounded = g_player_current_position_y + 4 <= iSupport;

        if bGrounded and g_player_current_position_y > -5 and iSupport < g_player_current_state_frame_count then
            g_player_current_velocity_x = 0;
            local iRand = math.random(0, 0x7fff);

            if (iRand & 3) == 1 and g_player_current_position_y > 30 and g_player_current_position_x > 30 then
                g_player_current_velocity_x = -1;
            end

            if (iRand & 3) == 2 and g_player_current_position_y > 30 and g_player_current_position_x < 130 then
                g_player_current_velocity_x = 1;
            end

            g_player_current_state_frame_count = math.floor(iSupport - 3);  -- frame count must stay an integer value
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
            play_music_track_2(Module.LevelData.music_death_track_filename);
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
        local stars_mesh_index = g_player_mesh_indices[player_mesh.STARS];
        set_identity_mesh_matrix(stars_mesh_index);
        rotate_y_mesh_matrix(stars_mesh_index, g_player_absolute_frame_count * 180.0 / 50.0);
        translate_mesh_matrix(
            stars_mesh_index,
            g_player_current_position_x, g_player_current_position_y + 12, g_player_current_position_z + 1);
        set_mesh_is_visible(stars_mesh_index, true);

        g_player_absolute_frame_count = g_player_absolute_frame_count + 1;
        g_player_current_rotation_x_radians = 0.1;
        g_player_current_mesh = player_mesh.DEAD;

        if g_player_absolute_frame_count == 85 then
            set_mesh_is_visible(stars_mesh_index, false);
            Module.MenuLogic.set_remaining_life_count(Module.MenuLogic.get_remaining_life_count() - 1);

            if Module.MenuLogic.get_remaining_life_count() == 0 then
                Module.MenuLogic.load_game_over();
            else
                g_player_dying_animation_state = -1;
                g_player_dying_animation_state_frame_count = -1;

                if Module.ResetPlayerCallback then
                    Module.ResetPlayerCallback(game_input);
                end

                if Module.LevelData.music_loop_start_music_time ~= 5550 then
                    play_music_track_1(
                        Module.LevelData.music_background_track_filename,
                        Module.LevelData.music_loop_start_music_time,
                        Module.LevelData.music_loop_start_music_time);
                end
            end
        end
    end
end

function Module.initialize(skip_play_level_music)
    -- TODO: This all might get moved to level loading code?
    for _, texture in ipairs(Module.LevelData.textures) do
        load_texture(texture.filename, texture.type, texture.alpha_blend or false);
    end

    -- TODO: These shouldn't be hard-coded to these positions in other scripts
    load_texture("data/panel.bmp", 0, false);
    load_texture("data/titles.png", 0, false);

    for _, mesh in ipairs(Module.LevelData.meshes) do
        load_mesh(mesh.filename);
    end

    for _, sound in ipairs(Module.LevelData.sounds) do
        load_sound(sound.filename);
    end

    -- Loading these after script meshes, so script mesh index not messed up
    g_player_mesh_indices[player_mesh.STAND] = load_mesh("data/stand.msh");
    g_player_mesh_indices[player_mesh.LEFT_1] = load_mesh("data/left1.msh");
    g_player_mesh_indices[player_mesh.LEFT_2] = load_mesh("data/left2.msh");
    g_player_mesh_indices[player_mesh.RIGHT_1] = load_mesh("data/right1.msh");
    g_player_mesh_indices[player_mesh.RIGHT_2] = load_mesh("data/right2.msh");

    g_player_mesh_indices[player_mesh.JUMP_UP] = load_mesh("data/jumpup.msh");
    g_player_mesh_indices[player_mesh.JUMP_LEFT] = load_mesh("data/jumpleft.msh");
    g_player_mesh_indices[player_mesh.JUMP_RIGHT] = load_mesh("data/jumpright.msh");

    g_player_mesh_indices[player_mesh.VINE_CLIMB_1] = load_mesh("data/ropeclimb1.msh");
    g_player_mesh_indices[player_mesh.VINE_CLIMB_2] = load_mesh("data/ropeclimb2.msh");

    g_player_mesh_indices[player_mesh.LADDER_CLIMB_1] = load_mesh("data/ladderclimb1.msh");
    g_player_mesh_indices[player_mesh.LADDER_CLIMB_2] = load_mesh("data/ladderclimb2.msh");

    g_player_mesh_indices[player_mesh.KICK_LEFT] = load_mesh("data/kickleft.msh");
    g_player_mesh_indices[player_mesh.KICK_RIGHT] = load_mesh("data/kickright.msh");

    g_player_mesh_indices[player_mesh.DIVE_RIGHT] = load_mesh("data/diveright.msh");
    g_player_mesh_indices[player_mesh.ROLL_RIGHT_1] = load_mesh("data/rollright1.msh");
    g_player_mesh_indices[player_mesh.ROLL_RIGHT_2] = load_mesh("data/rollright2.msh");
    g_player_mesh_indices[player_mesh.ROLL_RIGHT_3] = load_mesh("data/rollright3.msh");
    g_player_mesh_indices[player_mesh.ROLL_RIGHT_4] = load_mesh("data/rollright4.msh");

    g_player_mesh_indices[player_mesh.DIVE_LEFT] = load_mesh("data/diveleft.msh");
    g_player_mesh_indices[player_mesh.ROLL_LEFT_1] = load_mesh("data/rollleft1.msh");
    g_player_mesh_indices[player_mesh.ROLL_LEFT_2] = load_mesh("data/rollleft2.msh");
    g_player_mesh_indices[player_mesh.ROLL_LEFT_3] = load_mesh("data/rollleft3.msh");
    g_player_mesh_indices[player_mesh.ROLL_LEFT_4] = load_mesh("data/rollleft4.msh");

    g_player_mesh_indices[player_mesh.PUNCH_LEFT_1] = load_mesh("data/punchleft.msh");
    g_player_mesh_indices[player_mesh.PUNCH_RIGHT_1] = load_mesh("data/punchright.msh");
    g_player_mesh_indices[player_mesh.PUNCH_LEFT_2] = load_mesh("data/punchleft2.msh");
    g_player_mesh_indices[player_mesh.PUNCH_RIGHT_2] = load_mesh("data/punchright2.msh");

    g_player_mesh_indices[player_mesh.DYING] = load_mesh("data/dying.msh");
    g_player_mesh_indices[player_mesh.DEAD] = load_mesh("data/dead.msh");
    g_player_mesh_indices[player_mesh.STARS] = load_mesh("data/stars.msh");

    g_player_mesh_indices[player_mesh.SLIDE_RIGHT] = load_mesh("data/slider.msh");
    g_player_mesh_indices[player_mesh.SLIDE_RIGHT_B] = load_mesh("data/sliderb.msh");
    g_player_mesh_indices[player_mesh.SLIDE_LEFT] = load_mesh("data/slidel.msh");
    g_player_mesh_indices[player_mesh.SLIDE_LEFT_B] = load_mesh("data/slidelb.msh");

    g_player_mesh_indices[player_mesh.BORED_1] = load_mesh("data/bored1.msh");
    g_player_mesh_indices[player_mesh.BORED_2] = load_mesh("data/bored2.msh");
    g_player_mesh_indices[player_mesh.BORED_3] = load_mesh("data/bored3.msh");
    g_player_mesh_indices[player_mesh.BORED_4] = load_mesh("data/bored4.msh");
    g_player_mesh_indices[player_mesh.BORED_5] = load_mesh("data/bored5.msh");

    -- Load character meshes
    for iChar = 0, 299 do
        local is_good = true;
        local character;

        if (iChar >= string.byte("A") and iChar <= string.byte("Z")) or
                (iChar >= string.byte("0") and iChar <= string.byte("9")) then
            character = string.char(iChar);
        elseif iChar == string.byte(".") then
            character = "period";
        elseif iChar == string.byte("'") then
            character = "apos";
        elseif iChar == string.byte("-") then
            character = "dash";
        elseif iChar == string.byte(":") then
            character = "colon";
        elseif iChar == string.byte("%") then
            character = "square";
        elseif iChar == string.byte("^") then
            character = "jump";
        else
            is_good = false;
        end

        if is_good then
            g_letter_mesh_indices[iChar] = load_mesh("data/char" .. character .. ".msh");
        else
            g_letter_mesh_indices[iChar] = -1;
        end
    end

    if not skip_play_level_music and Module.LevelData.music_loop_start_music_time ~= 5550 then
        play_music_track_1(
            Module.LevelData.music_background_track_filename, 0, Module.LevelData.music_loop_start_music_time);
    end

    for donut_index = 0, #Module.LevelData.donuts - 1 do
        g_donut_is_collected[donut_index] = false;

        local current_donut = Module.LevelData.donuts[donut_index + 1];
        local new_mesh_index = create_mesh(current_donut.mesh, current_donut.texture_index);
        current_donut.mesh_index = new_mesh_index;
    end

    for vine_index = 0, #Module.LevelData.vines - 1 do
        local current_vine = Module.LevelData.vines[vine_index + 1];
        local new_mesh_index = create_mesh(current_vine.mesh, current_vine.texture_index);
        current_vine.mesh_index = new_mesh_index;
    end

    for ladder_index = 0, #Module.LevelData.ladders - 1 do
        local current_ladder = Module.LevelData.ladders[ladder_index + 1];
        local new_mesh_index = create_mesh(current_ladder.mesh, current_ladder.texture_index);
        current_ladder.mesh_index = new_mesh_index;
    end

    for platform_index = 0, #Module.LevelData.platforms - 1 do
        local current_platform = Module.LevelData.platforms[platform_index + 1];
        local new_mesh_index = create_mesh(current_platform.mesh, current_platform.texture_index);
        current_platform.mesh_index = new_mesh_index;
    end

    for wall_index = 0, #Module.LevelData.walls - 1 do
        local current_wall = Module.LevelData.walls[wall_index + 1];
        local new_mesh_index = create_mesh(current_wall.mesh, current_wall.texture_index);
        current_wall.mesh_index = new_mesh_index;
    end

    for backdrop_index = 0, #Module.LevelData.backdrops - 1 do
        local current_backdrop = Module.LevelData.backdrops[backdrop_index + 1];
        local new_mesh_index = create_mesh(current_backdrop.mesh, current_backdrop.texture_index);
        current_backdrop.mesh_index = new_mesh_index;
    end
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
            play_music_track_2(Module.LevelData.music_win_track_filename);
        end

        if g_win_with_no_delay or g_player_current_state_frame_count == 300 then
            Module.MenuLogic.load_next_level_from_set();
        end

        return true;
    end
end

function Module.update_player_graphics()
    -- TODO: Is this breaking the swim level, or is the swim level itself broken? (script25)
    -- TODO: Also the baboon level looks a bit strange when jumping on horizontal climb vines/platforms (script24)
    local current_player_mesh_index = g_player_mesh_indices[g_player_current_mesh] or 0;

    set_identity_mesh_matrix(current_player_mesh_index);
    rotate_x_mesh_matrix(current_player_mesh_index, g_player_current_rotation_x_radians * 180.0 / 3.14);
    translate_mesh_matrix(
        current_player_mesh_index,
        g_player_current_position_x, g_player_current_position_y + 6, g_player_current_position_z + 1);

    if g_player_is_visible then
        set_mesh_is_visible(current_player_mesh_index, true);
    end

    if g_player_current_mesh ~= g_player_previous_mesh then
        set_mesh_is_visible(g_player_mesh_indices[g_player_previous_mesh] or 0, false);
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

function Module.win_with_no_delay_debug()
    g_win_with_no_delay = true;
    Module.win();
end

function Module.new_char_mesh(ascii_value)
    local result = -1;

    if ascii_value >= 97 then
        ascii_value = ascii_value + 65 - 97;
    end

    if g_letter_mesh_indices[ascii_value] >= 0 then
        result = new_mesh(g_letter_mesh_indices[ascii_value]);
    end

    return result;
end

function Module.get_player_current_state()
    return g_player_current_state;
end

function Module.set_player_current_state(new_state)
    g_player_current_state = new_state;
end

function Module.get_player_current_state_frame_count()
    return math.floor(g_player_current_state_frame_count);
end

function Module.set_player_current_state_frame_count(new_frame_count)
    g_player_current_state_frame_count = math.floor(new_frame_count);
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

function Module.get_donut_is_collected(donut_index)
    return g_donut_is_collected[donut_index];
end

function Module.set_donut_is_collected(donut_index, is_collected)
    g_donut_is_collected[donut_index] = is_collected;
end

function Module.get_donut_object_count()
    return #Module.LevelData.donuts;
end

function Module.get_donut(donut_index)
    assert(type(donut_index) == "number", "donut_index must be a number");
    assert(
        donut_index >= 0 and donut_index < #Module.LevelData.donuts,
        "donut_index not within valid range: " .. donut_index);
    local donut_info = Module.LevelData.donuts[donut_index + 1];
    local result = {
        index = donut_index,
        number = donut_info.number,
        texture_index = donut_info.texture_index,
        pos = { donut_info.pos[1], donut_info.pos[2], donut_info.pos[3] },
        mesh_index = donut_info.mesh_index,
    };

    -- TODO: Take self as first param in these setter functions
    result.set_number = function(new_number)
        assert(type(new_number) == "number", "new_number must be a number");
        assert(new_number == math.floor(new_number), "new_number must be an integer");
        donut_info.number = new_number;
        result.number = new_number;
    end;

    result.set_pos_x = function(new_pos_x)
        assert(type(new_pos_x) == "number", "new_pos_x must be a number");
        donut_info.pos[1] = new_pos_x;
        result.pos[1] = new_pos_x;
    end;

    result.set_pos_y = function(new_pos_y)
        assert(type(new_pos_y) == "number", "new_pos_y must be a number");
        donut_info.pos[2] = new_pos_y;
        result.pos[2] = new_pos_y;
    end;

    result.set_pos_z = function(new_pos_z)
        assert(type(new_pos_z) == "number", "new_pos_z must be a number");
        donut_info.pos[3] = new_pos_z;
        result.pos[3] = new_pos_z;
    end;

    return result;
end

function Module.find_donut_by_number(donut_number)
    for donut_index = 0, #Module.LevelData.donuts - 1 do
        local current_donut = Module.LevelData.donuts[donut_index + 1];

        if current_donut.number == donut_number then
            return Module.get_donut(donut_index);
        end
    end

    return nil;
end

function Module.get_ladder_object_count()
    return #Module.LevelData.ladders;
end

function Module.get_ladder(ladder_index)
    assert(type(ladder_index) == "number", "ladder_index must be a number");
    assert(
        ladder_index >= 0 and ladder_index < #Module.LevelData.ladders,
        "ladder_index not within valid range: " .. ladder_index);
    local ladder_info = Module.LevelData.ladders[ladder_index + 1];
    local result = {
        index = ladder_index,
        number = ladder_info.number,
        texture_index = ladder_info.texture_index,
        pos_x = ladder_info.x_pos,
        pos_y_bottom = ladder_info.y_bottom,
        pos_y_top = ladder_info.y_top,
        pos_z = { ladder_info.z_front, ladder_info.z_back },
        mesh_index = ladder_info.mesh_index,
    };

    -- TODO: Take self as first param in these setter functions
    result.set_number = function(new_number)
        assert(type(new_number) == "number", "new_number must be a number");
        assert(new_number == math.floor(new_number), "new_number must be an integer");
        ladder_info.number = new_number;
        result.number = new_number;
    end;

    result.set_pos_x = function(new_pos_x)
        assert(type(new_pos_x) == "number", "new_pos_x must be a number");
        ladder_info.x_pos = new_pos_x;
        result.pos_x = new_pos_x;
    end;

    result.set_pos_y_bottom = function(new_y_bottom)
        assert(type(new_y_bottom) == "number", "new_y_bottom must be a number");
        ladder_info.y_bottom = new_y_bottom;
        result.pos_y_bottom = new_y_bottom;
    end;

    result.set_pos_y_top = function(new_y_top)
        assert(type(new_y_top) == "number", "new_y_top must be a number");
        ladder_info.y_top = new_y_top;
        result.pos_y_top = new_y_top;
    end;

    return result;
end

function Module.find_ladder_by_number(ladder_number)
    for ladder_index = 0, #Module.LevelData.ladders - 1 do
        local current_ladder = Module.LevelData.ladders[ladder_index + 1];

        if current_ladder.number == ladder_number then
            return Module.get_ladder(ladder_index);
        end
    end

    return nil;
end

function Module.get_vine_object_count()
    return #Module.LevelData.vines;
end

function Module.get_vine(vine_index)
    assert(type(vine_index) == "number", "vine_index must be a number");
    assert(
        vine_index >= 0 and vine_index < #Module.LevelData.vines,
        "vine_index not within valid range: " .. vine_index);
    local vine_info = Module.LevelData.vines[vine_index + 1];
    local result = {
        index = vine_index,
        number = vine_info.number,
        texture_index = vine_info.texture_index,
        pos_x = vine_info.x_pos,
        pos_y_bottom = vine_info.y_bottom,
        pos_y_top = vine_info.y_top,
        pos_z = { vine_info.z_front, vine_info.z_back },
        mesh_index = vine_info.mesh_index,
    };

    -- TODO: Take self as first param in these setter functions
    result.set_number = function(new_number)
        assert(type(new_number) == "number", "new_number must be a number");
        assert(new_number == math.floor(new_number), "new_number must be an integer");
        vine_info.number = new_number;
        result.number = new_number;
    end;

    result.set_pos_x = function(new_pos_x)
        assert(type(new_pos_x) == "number", "new_pos_x must be a number");
        vine_info.x_pos = new_pos_x;
        result.pos_x = new_pos_x;
    end;

    result.set_pos_y_bottom = function(new_y_bottom)
        assert(type(new_y_bottom) == "number", "new_y_bottom must be a number");
        vine_info.y_bottom = new_y_bottom;
        result.pos_y_bottom = new_y_bottom;
    end;

    result.set_pos_y_top = function(new_y_top)
        assert(type(new_y_top) == "number", "new_y_top must be a number");
        vine_info.y_top = new_y_top;
        result.pos_y_top = new_y_top;
    end;

    return result;
end

function Module.find_vine_by_number(vine_number)
    for vine_index = 0, #Module.LevelData.vines - 1 do
        local current_vine = Module.LevelData.vines[vine_index + 1];

        if current_vine.number == vine_number then
            return Module.get_vine(vine_index);
        end
    end

    return nil;
end

function Module.get_platform_object_count()
    return #Module.LevelData.platforms;
end

function Module.get_platform(platform_index)
    assert(type(platform_index) == "number", "platform_index must be a number");
    assert(
        platform_index >= 0 and platform_index < #Module.LevelData.platforms,
        "platform_index not within valid range: " .. platform_index);
    local platform_info = Module.LevelData.platforms[platform_index + 1];
    local result = {
        index = platform_index,
        number = platform_info.number,
        extra = platform_info.extra,
        texture_index = platform_info.texture_index,
        -- TODO: Rename "upper" -> "top" and "lower" -> "bottom"
        pos_upper_left = { platform_info.pos_upper_left[1], platform_info.pos_upper_left[2] },
        pos_lower_right = { platform_info.pos_lower_right[1], platform_info.pos_lower_right[2] },
        pos_z = platform_info.pos_z,
        mesh_index = platform_info.mesh_index,
    };

    -- TODO: Take self as first param in these setter functions
    result.set_number = function(new_number)
        assert(type(new_number) == "number", "new_number must be a number");
        assert(new_number == math.floor(new_number), "new_number must be an integer");
        platform_info.number = new_number;
        result.number = new_number;
    end;

    result.set_pos = function(new_pos_x_left, new_pos_y_top, new_pos_x_right, new_pos_y_bottom)
        assert(type(new_pos_x_left) == "number", "new_pos_x_left must be a number");
        assert(type(new_pos_y_top) == "number", "new_pos_y_top must be a number");
        assert(type(new_pos_x_right) == "number", "new_pos_x_right must be a number");
        assert(type(new_pos_y_bottom) == "number", "new_pos_y_bottom must be a number");
        platform_info.pos_upper_left = { new_pos_x_left, new_pos_y_top };
        platform_info.pos_lower_right = { new_pos_x_right, new_pos_y_bottom };
        result.pos_upper_left = { new_pos_x_left, new_pos_y_top };
        result.pos_lower_right = { new_pos_x_right, new_pos_y_bottom };
    end;

    result.set_pos_y = function(new_pos_y_bottom, new_pos_y_top)
        assert(type(new_pos_y_bottom) == "number", "new_pos_y_bottom must be a number");
        assert(type(new_pos_y_top) == "number", "new_pos_y_top must be a number");
        platform_info.pos_lower_right[2] = new_pos_y_bottom;
        platform_info.pos_upper_left[2] = new_pos_y_top;
        result.pos_lower_right[2] = new_pos_y_bottom;
        result.pos_upper_left[2] = new_pos_y_top;
    end;

    result.set_pos_y_top = function(new_pos_y_top)
        assert(type(new_pos_y_top) == "number", "new_pos_y_top must be a number");
        platform_info.pos_upper_left[2] = new_pos_y_top;
        result.pos_upper_left[2] = new_pos_y_top;
    end;

    result.set_pos_z = function(new_pos_z)
        assert(type(new_pos_z) == "number", "new_pos_z must be a number");
        platform_info.pos_z = new_pos_z;
        result.pos_z = new_pos_z;
    end;

    return result;
end

function Module.find_platform_by_number(platform_number)
    for platform_index = 0, #Module.LevelData.platforms - 1 do
        local current_platform = Module.LevelData.platforms[platform_index + 1];

        if current_platform.number == platform_number then
            return Module.get_platform(platform_index);
        end
    end

    return nil;
end

function Module.get_wall_object_count()
    return #Module.LevelData.walls;
end

function Module.get_wall(wall_index)
    assert(type(wall_index) == "number", "wall_index must be a number");
    assert(
        wall_index >= 0 and wall_index < #Module.LevelData.walls,
        "wall_index not within valid range: " .. wall_index);
    local wall_info = Module.LevelData.walls[wall_index + 1];
    local result = {
        index = wall_index,
        number = wall_info.number,
        texture_index = wall_info.texture_index,
        -- TODO: Rename these pos properties, if possible?
        -- TODO: There is a pos-z, but it's embedded in the mesh. Level extractor should extract it
        pos = {
            { wall_info.pos[1][1], wall_info.pos[1][2] },
            { wall_info.pos[2][1], wall_info.pos[2][2] },
            { wall_info.pos[3][1], wall_info.pos[3][2] },
            { wall_info.pos[4][1], wall_info.pos[4][2] },
        },
        mesh_index = wall_info.mesh_index,
    };

    -- TODO: Take self as first param in these setter functions
    result.set_number = function(new_number)
        assert(type(new_number) == "number", "new_number must be a number");
        assert(new_number == math.floor(new_number), "new_number must be an integer");
        wall_info.number = new_number;
        result.number = new_number;
    end;

    -- TODO: Rename this setter, if possible?
    result.set_pos_y1 = function(new_pos_y1)
        assert(type(new_pos_y1) == "number", "new_pos_y1 must be a number");
        wall_info.pos[1][2] = new_pos_y1;
        result.pos[1][2] = new_pos_y1;
    end;

    return result;
end

function Module.find_wall_by_number(wall_number)
    for wall_index = 0, #Module.LevelData.walls - 1 do
        local current_wall = Module.LevelData.walls[wall_index + 1];

        if current_wall.number == wall_number then
            return Module.get_wall(wall_index);
        end
    end

    return nil;
end

function Module.get_backdrop_object_count()
    return #Module.LevelData.backdrops;
end

function Module.get_backdrop(backdrop_index)
    assert(type(backdrop_index) == "number", "backdrop_index must be a number");
    assert(
        backdrop_index >= 0 and backdrop_index < #Module.LevelData.backdrops,
        "backdrop_index not within valid range: " .. backdrop_index);
    local backdrop_info = Module.LevelData.backdrops[backdrop_index + 1];
    local result = {
        index = backdrop_index,
        number = backdrop_info.number,
        texture_index = backdrop_info.texture_index,
        -- TODO: There is a pos-z, but it's embedded in the mesh. Level extractor should extract it
        pos = { backdrop_info.pos[1], backdrop_info.pos[2] },
        mesh_index = backdrop_info.mesh_index,
    };

    -- TODO: Take self as first param in these setter functions
    result.set_number = function(new_number)
        assert(type(new_number) == "number", "new_number must be a number");
        assert(new_number == math.floor(new_number), "new_number must be an integer");
        backdrop_info.number = new_number;
        result.number = new_number;
    end;

    result.set_pos_x = function(new_pos_x)
        assert(type(new_pos_x) == "number", "new_pos_x must be a number");
        backdrop_info.pos[1] = new_pos_x;
        result.pos[1] = new_pos_x;
    end;

    result.set_pos_y = function(new_pos_y)
        assert(type(new_pos_y) == "number", "new_pos_y must be a number");
        backdrop_info.pos[2] = new_pos_y;
        result.pos[2] = new_pos_y;
    end;

    -- TODO: There is a pos-z, but it's embedded in the mesh. Level extractor should extract it
    -- result.set_pos_z = function(new_pos_z)
    --     assert(type(new_pos_z) == "number", "new_pos_z must be a number");
    --     backdrop_info.pos[3] = new_pos_z;
    --     result.pos[3] = new_pos_z;
    -- end;

    return result;
end

function Module.find_backdrop_by_number(backdrop_number)
    for backdrop_index = 0, #Module.LevelData.backdrops - 1 do
        local current_backdrop = Module.LevelData.backdrops[backdrop_index + 1];

        if current_backdrop.number == backdrop_number then
            return Module.get_backdrop(backdrop_index);
        end
    end

    return nil;
end

function Module.find_vine(iX, iY)
    -- TODO: Figure out what "iX", "iY" mean, and change names to reflect that
    return FindVine_(iX, iY);
end

-- Get the ladder_index of the closest ladder to the specified coordinates.
--
-- Returns: ladder_index_near, ladder_index_exact
--
-- ladder_index_near will be -1 if there is no ladder close by
-- ladder_index_exact will be -1 if the nearest ladder is not an exact match (fairly common)
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
