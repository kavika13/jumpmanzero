local read_only = require "data/read_only";

local Module = {};

-- TODO: Get from game logic module
local navigation_type = {
    LADDER = 1,
    PLATFORM = 2,
    PLATFORM_FALL_LEFT = 3,
    PLATFORM_FALL_RIGHT = 4,
};
navigation_type = read_only.make_table_read_only(navigation_type);

Module.GameLogic = nil;

Module.StandRightMeshResourceIndex = 0;
Module.MoveRightMeshResourceIndices = {};
Module.FallRightMeshResourceIndices = {};
Module.RestRightMeshResourceIndex = 0;
Module.ShakeRightMeshResourceIndices = {};
Module.StandLeftMeshResourceIndex = 0;
Module.MoveLeftMeshResourceIndices = {};
Module.FallLeftMeshResourceIndices = {};
Module.RestLeftMeshResourceIndex = 0;
Module.ShakeLeftMeshResourceIndices = {};
Module.ClimbMeshResourceIndices = {};
Module.TextureResourceIndex = 0;

local status_type = {
    NORMAL = 0,
    FALLING = 1,
    STUNNED = 2,
    SHAKING = 3,
};
status_type = read_only.make_table_read_only(status_type);

local move_direction = {
    NONE = 0,
    UP = 1,
    DOWN = 2,
    LEFT = 3,
    RIGHT = 4,
};
move_direction = read_only.make_table_read_only(move_direction);

local animation_frame = {
    MOVE_RIGHT_1 = 0,
    MOVE_RIGHT_2 = 1,
    MOVE_RIGHT_3 = 2,
    MOVE_RIGHT_4 = 3,
    FALL_RIGHT_1 = 4,
    FALL_RIGHT_2 = 5,
    REST_RIGHT_1 = 6,
    SHAKE_RIGHT_1 = 7,
    SHAKE_RIGHT_2 = 8,
    SHAKE_RIGHT_3 = 9,
    SHAKE_RIGHT_4 = 10,
    MOVE_LEFT_1 = 11,
    MOVE_LEFT_2 = 12,
    MOVE_LEFT_3 = 13,
    MOVE_LEFT_4 = 14,
    FALL_LEFT_1 = 15,
    FALL_LEFT_2 = 16,
    REST_LEFT_1 = 17,
    SHAKE_LEFT_1 = 18,
    SHAKE_LEFT_2 = 19,
    SHAKE_LEFT_3 = 20,
    SHAKE_LEFT_4 = 21,
    CLIMB_1 = 22,
    CLIMB_2 = 23,
};
animation_frame = read_only.make_table_read_only(animation_frame);

local g_bear_mesh_index = -1;
local g_bear_transform_index = -1;

local g_animation_mesh_indices = {};
local g_animation_current_frame = animation_frame.MOVE_RIGHT_1;
local g_animation_frame_increment_timer = 0;  -- Ticks 0 through 5, then increases g_animation_frame_counter
local g_animation_frame_counter = 0;  -- Frame offset of most animations. Max value depends on current animation/state
local g_shake_animation_frame_increment_timer = 0;  -- Ticks 0 through 2, then increases g_shake_animation_frame_counter
local g_shake_animation_frame_counter = 0;  -- Frame offset of shake animation, 0 through 3

local g_current_pos_x = 0;
local g_current_pos_y = 0;
local g_current_pos_z = 0;
local g_current_velocity_x = 0;

local g_current_status = status_type.NORMAL;
local g_current_status_counter = 0;

local g_current_move_direction = move_direction.NONE;
local g_previous_move_direction = move_direction.NONE;

local g_current_ladder = nil;

local function AdvanceFrame_()
    g_current_status_counter = g_current_status_counter + 1;
    g_shake_animation_frame_increment_timer = g_shake_animation_frame_increment_timer + 1;

    if g_shake_animation_frame_increment_timer > 2 then
        g_shake_animation_frame_increment_timer = 0;
        g_shake_animation_frame_counter = g_shake_animation_frame_counter + 1;

        if g_shake_animation_frame_counter > 3 then
            g_shake_animation_frame_counter = 0;
        end
    end

    g_animation_frame_increment_timer = g_animation_frame_increment_timer + 1;

    if g_animation_frame_increment_timer > 5 then
        g_animation_frame_increment_timer = 0;
        g_animation_frame_counter = g_animation_frame_counter + 1;

        if g_animation_frame_counter > 3 then
            g_animation_frame_counter = 0;
        end
    end
end

local function CheckForHalt_()
    if g_current_move_direction == move_direction.RIGHT or g_current_move_direction == move_direction.LEFT then
        g_current_ladder = nil;
        local _, ladder_index = Module.GameLogic.find_ladder(g_current_pos_x + 1, g_current_pos_y);

        if ladder_index >= 0 then
            g_current_ladder = Module.GameLogic.get_ladder(ladder_index);
            g_current_move_direction = move_direction.NONE;
            return;
        end
    end

    if g_current_move_direction == move_direction.UP or g_current_move_direction == move_direction.DOWN then
        local iHit, _ = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y + 3, 4, 2);

        if iHit == g_current_pos_y then
            g_current_move_direction = move_direction.NONE;
        end

        return;
    end

    if g_current_move_direction == move_direction.RIGHT then
        local _, iPlat1 = Module.GameLogic.find_platform(g_current_pos_x + 6, g_current_pos_y + 5, 4, 2);
        local iHit, iPlat2 = Module.GameLogic.find_platform(g_current_pos_x + 7, g_current_pos_y + 5, 4, 2);

        if iPlat1 == iPlat2 then
            return;
        end

        if iHit < 0 then
            g_current_move_direction = move_direction.LEFT;
            g_current_velocity_x = -1;
        elseif iHit < g_current_pos_y - 4 then
            g_current_move_direction = move_direction.NONE;
        end

        return;
    end

    if g_current_move_direction == move_direction.LEFT then
        local _, iPlat1 = Module.GameLogic.find_platform(g_current_pos_x - 6, g_current_pos_y + 5, 4, 2);
        local iHit, iPlat2 = Module.GameLogic.find_platform(g_current_pos_x - 7, g_current_pos_y + 5, 4, 2);

        if iPlat1 == iPlat2 then
            return;
        end

        if iHit < 0 then
            g_current_move_direction = move_direction.RIGHT;
            g_current_velocity_x = 1.0;
        elseif iHit < g_current_pos_y - 4 then
            g_current_move_direction = move_direction.NONE;
        end

        return;
    end
end

local function CheckForOptions_()
    if g_current_move_direction ~= move_direction.NONE or g_current_status ~= status_type.NORMAL then
        return;
    end

    local player_pos_x = Module.GameLogic.get_player_current_position_x();
    local player_pos_y = Module.GameLogic.get_player_current_position_y();
    local _, player_platform_index = Module.GameLogic.find_platform(player_pos_x, player_pos_y, 3, 2);
    local _, self_platform_index = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y, 3, 2);

    if player_platform_index == self_platform_index then
        if player_pos_x < g_current_pos_x then
            g_current_move_direction = move_direction.LEFT;
            g_current_velocity_x = -1;
            return;
        end

        if player_pos_x > g_current_pos_x then
            g_current_move_direction = move_direction.RIGHT;
            g_current_velocity_x = 1;
            return;
        end

        if g_current_ladder ~= nil then
            if g_current_ladder.pos_y_top > g_current_pos_y + 7 and
                    g_current_pos_y + 5 < Module.GameLogic.get_player_current_position_y() then
                g_current_move_direction = move_direction.UP;
                g_current_velocity_x = 0;
            end

            if g_current_ladder.pos_y_bottom < g_current_pos_y - 7 and
                    g_current_pos_y - 5 > Module.GameLogic.get_player_current_position_y() then
                g_current_move_direction = move_direction.DOWN;
                g_current_velocity_x = 0;
            end
        end

        if g_current_move_direction == move_direction.NONE then
            g_current_status = status_type.SHAKING;
            g_current_status_counter = 0;
        end

        return;
    end

    local iChoice = Module.GameLogic.get_navigation_dir(
        self_platform_index, player_platform_index, navigation_type.PLATFORM, navigation_type.PLATFORM);

    if iChoice < 0 then
        g_current_status = status_type.SHAKING;
        g_current_status_counter = 0;
        return;
    end

    if iChoice > 999 and iChoice < 2000 then
        local chosen_ladder = Module.GameLogic.get_ladder(iChoice - 1000);

        if chosen_ladder.index == g_current_ladder.index then
            if chosen_ladder.pos_y_top > g_current_pos_y + 7 then
                g_current_move_direction = move_direction.UP;
                g_current_velocity_x = 0;
            end

            if chosen_ladder.pos_y_bottom < g_current_pos_y - 7 then
                g_current_move_direction = move_direction.DOWN;
                g_current_velocity_x = 0;
            end
        elseif g_current_pos_x < chosen_ladder.pos_x + 7 then
            g_current_move_direction = move_direction.RIGHT;
        elseif g_current_pos_x > chosen_ladder.pos_x + 7 then
            g_current_move_direction = move_direction.LEFT;
        end
    end

    if iChoice > 2999 then
        g_current_move_direction = move_direction.RIGHT;
    elseif iChoice > 1999 then
        g_current_move_direction = move_direction.LEFT;
    elseif iChoice < 1000 then
        local chosen_platform = Module.GameLogic.get_platform(iChoice);

        if chosen_platform.pos_upper_left[1] < g_current_pos_x then
            g_current_move_direction = move_direction.LEFT;
        else
            g_current_move_direction = move_direction.RIGHT;
        end
    end

    if g_current_move_direction == move_direction.LEFT then
        g_current_velocity_x = -1;
    end

    if g_current_move_direction == move_direction.RIGHT then
        g_current_velocity_x = 1;
    end
end

local function ProgressBear_()
    if g_current_move_direction == move_direction.NONE then
        g_animation_current_frame = animation_frame.SHAKE_RIGHT_4;
    end

    if g_current_move_direction == move_direction.RIGHT or g_current_move_direction == move_direction.LEFT then
        g_current_pos_x = g_current_pos_x + g_current_velocity_x;
        g_animation_current_frame = g_animation_frame_counter;
    end

    if g_current_move_direction == move_direction.UP then
        g_current_pos_y = g_current_pos_y + 1;
        g_animation_current_frame = animation_frame.CLIMB_2;

        if g_animation_frame_counter < 2 then
            g_animation_current_frame = animation_frame.CLIMB_1;
        end
    end

    if g_current_move_direction == move_direction.DOWN then
        g_current_pos_y = g_current_pos_y - 1;
        g_animation_current_frame = animation_frame.CLIMB_2;

        if g_animation_frame_counter < 2 then
            g_animation_current_frame = animation_frame.CLIMB_1;
        end
    end
end

local function FallBear_()
    g_animation_current_frame = animation_frame.FALL_RIGHT_2;

    if g_current_status_counter < 10 then
        g_current_pos_x = g_current_pos_x + g_current_velocity_x;
        g_animation_current_frame = animation_frame.FALL_RIGHT_1;
    elseif g_current_status_counter < 20 then
        g_current_pos_y = g_current_pos_y - 0.7;
        g_current_pos_x = g_current_pos_x + g_current_velocity_x / 2;
    elseif g_current_status_counter < 40 then
        g_current_pos_y = g_current_pos_y - 0.9;
        g_current_pos_x = g_current_pos_x + g_current_velocity_x / 4;
    else
        g_current_pos_y = g_current_pos_y - 1;
    end
end

local function AdjustZ_(platform_index)
    if platform_index ~= -1 then
        local iPlatZ = Module.GameLogic.get_platform(platform_index).pos_z;

        if g_current_pos_z < iPlatZ then
            g_current_pos_z = g_current_pos_z + 1;
        end

        if g_current_pos_z > iPlatZ + 2 then
            g_current_pos_z = g_current_pos_z - 1;
        end
    end
end

local function MoveBear_()
    if g_current_status == status_type.NORMAL then
        g_previous_move_direction = g_current_move_direction;
        CheckForHalt_();
        CheckForOptions_();
        ProgressBear_();
    end

    if g_current_status == status_type.FALLING then
        FallBear_();
    end

    local iHit, platform_index = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y + 5, 4, 2);

    if g_current_status == status_type.NORMAL and
            (g_current_move_direction == move_direction.UP or g_current_move_direction == move_direction.DOWN) then
        g_current_pos_z = g_current_ladder.pos_z[1];
    else
        AdjustZ_(platform_index);
    end

    if g_current_status == status_type.FALLING and iHit >= g_current_pos_y + 3 then
        g_current_pos_y = iHit;
        g_current_status = status_type.STUNNED;
        g_current_status_counter = 0;
    end

    if g_current_status == status_type.NORMAL and
            (g_current_move_direction == move_direction.LEFT or g_current_move_direction == move_direction.RIGHT) and
            iHit > g_current_pos_y then
        g_current_pos_y = g_current_pos_y + 0.5;

        if g_current_pos_y > iHit then
            g_current_pos_y = iHit;
        end
    end

    if g_current_status == status_type.NORMAL and
            (g_current_move_direction == move_direction.LEFT or g_current_move_direction == move_direction.RIGHT) and
            iHit < g_current_pos_y - 3 then
        g_current_status = status_type.FALLING;
        g_current_status_counter = 0;
        g_shake_animation_frame_counter = 0;
    end

    if g_current_status == status_type.NORMAL and
            (g_current_move_direction == move_direction.LEFT or g_current_move_direction == move_direction.RIGHT) and
            iHit < g_current_pos_y then
        g_current_pos_y = g_current_pos_y - 0.5;
        g_animation_frame_counter = 4;
    end

    if g_current_status == status_type.STUNNED then
        if g_current_status_counter > 30 then
            g_current_status = status_type.SHAKING;
            g_current_status_counter = 0;
            g_shake_animation_frame_counter = 0;
        end

        g_animation_current_frame = animation_frame.REST_RIGHT_1;
    end

    if g_current_status == status_type.SHAKING then
        if g_current_status_counter > 40 then
            g_current_status = status_type.NORMAL;
            g_current_move_direction = move_direction.NONE;
        end

        g_animation_current_frame = animation_frame.SHAKE_RIGHT_1 + g_shake_animation_frame_counter;

        if g_current_status_counter > 30 then
            g_animation_current_frame = animation_frame.MOVE_RIGHT_2;
        end
    end

    if g_current_velocity_x < 0 then
        g_animation_current_frame = animation_frame.MOVE_LEFT_1 + g_animation_current_frame;
    end
end

function Module.initialize()
    Module.reset_pos();

    g_animation_mesh_indices[animation_frame.MOVE_RIGHT_1] = Module.MoveRightMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.MOVE_RIGHT_2] = Module.StandRightMeshResourceIndex;
    g_animation_mesh_indices[animation_frame.MOVE_RIGHT_3] = Module.MoveRightMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.MOVE_RIGHT_4] = Module.StandRightMeshResourceIndex;

    g_animation_mesh_indices[animation_frame.FALL_RIGHT_1] = Module.FallRightMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.FALL_RIGHT_2] = Module.FallRightMeshResourceIndices[2];

    g_animation_mesh_indices[animation_frame.REST_RIGHT_1] = Module.RestRightMeshResourceIndex;

    g_animation_mesh_indices[animation_frame.SHAKE_RIGHT_1] = Module.ShakeRightMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.SHAKE_RIGHT_2] = Module.StandRightMeshResourceIndex;
    g_animation_mesh_indices[animation_frame.SHAKE_RIGHT_3] = Module.ShakeRightMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.SHAKE_RIGHT_4] = Module.StandRightMeshResourceIndex;

    g_animation_mesh_indices[animation_frame.MOVE_LEFT_1] = Module.MoveLeftMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.MOVE_LEFT_2] = Module.StandLeftMeshResourceIndex;
    g_animation_mesh_indices[animation_frame.MOVE_LEFT_3] = Module.MoveLeftMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.MOVE_LEFT_4] = Module.StandLeftMeshResourceIndex;

    g_animation_mesh_indices[animation_frame.FALL_LEFT_1] = Module.FallLeftMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.FALL_LEFT_2] = Module.FallLeftMeshResourceIndices[2];

    g_animation_mesh_indices[animation_frame.REST_LEFT_1] = Module.RestLeftMeshResourceIndex;

    g_animation_mesh_indices[animation_frame.SHAKE_LEFT_1] = Module.ShakeLeftMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.SHAKE_LEFT_2] = Module.StandLeftMeshResourceIndex;
    g_animation_mesh_indices[animation_frame.SHAKE_LEFT_3] = Module.ShakeLeftMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.SHAKE_LEFT_4] = Module.StandLeftMeshResourceIndex;

    g_animation_mesh_indices[animation_frame.CLIMB_1] = Module.ClimbMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.CLIMB_2] = Module.ClimbMeshResourceIndices[2];

    g_bear_mesh_index = new_mesh(g_animation_mesh_indices[animation_frame.MOVE_RIGHT_1]);
    g_bear_transform_index = transform_create();
    mesh_set_transform(g_bear_mesh_index, g_bear_transform_index);
    set_mesh_texture(g_bear_mesh_index, Module.TextureResourceIndex);
    set_mesh_is_visible(g_bear_mesh_index, true);

    g_current_status = status_type.NORMAL;
end

function Module.update()
    if g_current_pos_y < 0 then
        Module.reset_pos();
    end

    AdvanceFrame_();
    MoveBear_();

    set_mesh_to_mesh(g_bear_mesh_index, g_animation_mesh_indices[g_animation_current_frame]);
    transform_set_translation(g_bear_transform_index, g_current_pos_x, g_current_pos_y + 11, g_current_pos_z - 0.5);

    local is_colliding = false;

    if g_current_status == status_type.NORMAL or g_current_status == status_type.FALLING then
        if g_current_move_direction == move_direction.LEFT then
            is_colliding = Module.GameLogic.is_player_colliding_with_rect(
                g_current_pos_x - 12, g_current_pos_y + 5,
                g_current_pos_x + 7, g_current_pos_y + 12);
        end

        if g_current_move_direction == move_direction.RIGHT then
            is_colliding = Module.GameLogic.is_player_colliding_with_rect(
                g_current_pos_x - 7, g_current_pos_y + 5,
                g_current_pos_x + 12, g_current_pos_y + 12);
        end

        if g_current_move_direction == move_direction.UP or g_current_move_direction == move_direction.DOWN then
            is_colliding = Module.GameLogic.is_player_colliding_with_rect(
                g_current_pos_x - 4, g_current_pos_y + 0,
                g_current_pos_x + 4, g_current_pos_y + 20);
        end

        if is_colliding then
            Module.GameLogic.kill();
        end
    end
end

function Module.reset_pos()
    g_current_pos_x = 120;
    g_current_pos_y = 74;
    g_current_pos_z = 2;
    g_current_move_direction = move_direction.NONE;
    g_current_status = status_type.NORMAL;
    g_current_ladder = nil;
end

return Module;
