local read_only = require "data/read_only";

local Module = {};

local behavior_type = {
    PERIODIC = 1,
    CHASE = 2,
    STAND = 3,
};
behavior_type = read_only.make_table_read_only(behavior_type);

local move_direction = {
    LEFT = 3,
    RIGHT = 4,
};
move_direction = read_only.make_table_read_only(move_direction);

local animation_frame = {
    MOVE_LEFT = 0,
    TURN_1 = 1,
    TURN_2 = 2,
    TURN_3 = 3,
    TURN_4 = 4,
    TURN_5 = 5,
    MOVE_RIGHT = 6,
    FIRE_LEFT_1 = 10,
    FIRE_LEFT_2 = 11,
    FIRE_RIGHT_1 = 16,
    FIRE_RIGHT_2 = 17,
};
animation_frame = read_only.make_table_read_only(animation_frame);

Module.GameLogic = nil;

Module.BotMoveLeftMeshResourceIndex = 0;
Module.BotMoveRightMeshResourceIndex = 0;
Module.BotTurnMeshResourceIndices = {};
Module.BotFireLeftMeshResourceIndices = {};
Module.BotFireRightMeshResourceIndices = {};
Module.LaserMeshResourceIndex = 0;
Module.BotTextureResourceIndex = 0;
Module.LaserTextureResourceIndex = 0;

Module.InitialPosX = 0;
Module.InitialPosY = 0;
Module.FireDuration = 0;
Module.WaitDuration = 0;
Module.BehaviorType = 0;

local kTURN_DURATION = 50;  -- TODO: Could make configurable. Would have to calculate frame thresholds, not hard-code

local g_zap_bot_mesh_index = -1;
local g_zap_bot_transform_index = -1;
local g_laser_mesh_index = -1;
local g_laser_transform_index = -1;

local g_animation_mesh_indices = {};
local g_animation_current_frame = 0;

local g_current_pos_x = 0;
local g_current_pos_y = 0;
local g_current_pos_z = 0;

local g_move_direction = move_direction.LEFT;

local g_is_firing = false;
local g_time_since_fire_start = 0;  -- Counts up from 1 to Module.FireDuration
local g_turn_time_remaining = 0;  -- Counts down from kTURN_DURATION to 0
local g_wait_time_remaining = 0;  -- Counts down from Module.WaitDuration to 0

local function Move_()
    if g_turn_time_remaining > 0 then
        g_turn_time_remaining = g_turn_time_remaining - 1;
        return;
    end

    if g_wait_time_remaining > 0 then
        g_wait_time_remaining = g_wait_time_remaining - 1;
    end

    if g_is_firing then
        g_time_since_fire_start = g_time_since_fire_start + 1;

        if g_time_since_fire_start == Module.FireDuration then
            g_is_firing = false;
            g_time_since_fire_start = 0;
            g_wait_time_remaining = Module.WaitDuration;
        end

        return;
    elseif g_wait_time_remaining == 0 and Module.BehaviorType == behavior_type.PERIODIC then
        g_is_firing = true;
        g_time_since_fire_start = 1;
        return;
    elseif Module.BehaviorType == behavior_type.STAND then
        local player_pos_x = Module.GameLogic.get_player_current_position_x();
        local player_pos_y = Module.GameLogic.get_player_current_position_y();

        if player_pos_y < g_current_pos_y + 6 and player_pos_y > g_current_pos_y - 6 then
            if player_pos_x < g_current_pos_x and g_move_direction == move_direction.LEFT then
                g_is_firing = true;
                g_time_since_fire_start = 1;
                return;
            end

            if player_pos_x > g_current_pos_x and g_move_direction == move_direction.RIGHT then
                g_is_firing = true;
                g_time_since_fire_start = 1;
                return;
            end
        end
    elseif Module.BehaviorType == behavior_type.CHASE then
        local player_pos_x = Module.GameLogic.get_player_current_position_x();
        local player_pos_y = Module.GameLogic.get_player_current_position_y();

        if player_pos_y < g_current_pos_y + 6 and player_pos_y > g_current_pos_y - 6 then
            if player_pos_x < g_current_pos_x and g_move_direction == move_direction.LEFT then
                if player_pos_x < g_current_pos_x - 35 then
                    g_current_pos_x = g_current_pos_x - 0.4;
                else
                    g_is_firing = true;
                    g_time_since_fire_start = 1;
                    return;
                end
            end

            if player_pos_x > g_current_pos_x and g_move_direction == move_direction.RIGHT then
                if player_pos_x > g_current_pos_x + 35 then
                    g_current_pos_x = g_current_pos_x + 0.4;
                else
                    g_is_firing = true;
                    g_time_since_fire_start = 1;
                    return;
                end
            end
        end
    end

    if g_move_direction == move_direction.LEFT or g_move_direction == move_direction.RIGHT then
        local iHit, platform_index = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y, 5, 2);
        g_current_pos_z = Module.GameLogic.get_platform(platform_index).pos_z;

        if iHit < g_current_pos_y - 1 then
            g_current_pos_y = g_current_pos_y - 1;
        elseif iHit > g_current_pos_y + 1 then
            g_current_pos_y = g_current_pos_y + 1;
        else
            g_current_pos_y = iHit;
        end
    end

    if g_move_direction == move_direction.LEFT then
        g_current_pos_x = g_current_pos_x - 0.7;

        local iHit, _ = Module.GameLogic.find_platform(g_current_pos_x - 7, g_current_pos_y, 5, 2);

        if iHit < g_current_pos_y - 6 then
            g_move_direction = move_direction.RIGHT;
            g_turn_time_remaining = kTURN_DURATION;
        end
    end

    if g_move_direction == move_direction.RIGHT then
        g_current_pos_x = g_current_pos_x + 0.7;

        local iHit, _ = Module.GameLogic.find_platform(g_current_pos_x + 7, g_current_pos_y, 5, 2);

        if iHit < g_current_pos_y - 6 then
            g_move_direction = move_direction.LEFT;
            g_turn_time_remaining = kTURN_DURATION;
        end
    end
end

local function SetFrame_()
    if g_move_direction == move_direction.LEFT then
        if g_turn_time_remaining == 0 then
            if not g_is_firing then
                g_animation_current_frame = animation_frame.MOVE_LEFT;
            elseif g_time_since_fire_start < 8 or g_time_since_fire_start > (Module.FireDuration - 8) then
                g_animation_current_frame = animation_frame.FIRE_LEFT_1;
            else
                g_animation_current_frame = animation_frame.FIRE_LEFT_2;
            end
        elseif g_turn_time_remaining > 40 then
            g_animation_current_frame = animation_frame.TURN_5;
        elseif g_turn_time_remaining > 30 then
            g_animation_current_frame = animation_frame.TURN_4;
        elseif g_turn_time_remaining > 20 then
            g_animation_current_frame = animation_frame.TURN_3;
        elseif g_turn_time_remaining > 10 then
            g_animation_current_frame = animation_frame.TURN_2;
        else
            g_animation_current_frame = animation_frame.TURN_1;
        end
    end

    if g_move_direction == move_direction.RIGHT then
        if g_turn_time_remaining == 0 then
            if not g_is_firing then
                g_animation_current_frame = animation_frame.MOVE_RIGHT;
            elseif g_time_since_fire_start < 8 or g_time_since_fire_start > (Module.FireDuration - 8) then
                g_animation_current_frame = animation_frame.FIRE_RIGHT_1;
            else
                g_animation_current_frame = animation_frame.FIRE_RIGHT_2;
            end
        elseif g_turn_time_remaining > 40 then
            g_animation_current_frame = animation_frame.TURN_1;
        elseif g_turn_time_remaining > 30 then
            g_animation_current_frame = animation_frame.TURN_2;
        elseif g_turn_time_remaining > 20 then
            g_animation_current_frame = animation_frame.TURN_3;
        elseif g_turn_time_remaining > 10 then
            g_animation_current_frame = animation_frame.TURN_4;
        else
            g_animation_current_frame = animation_frame.TURN_5;
        end
    end
end

function Module.initialize()
    g_current_pos_x = Module.InitialPosX;
    g_current_pos_y = Module.InitialPosY;
    g_move_direction = move_direction.LEFT;

    g_animation_mesh_indices[animation_frame.MOVE_LEFT] = Module.BotMoveLeftMeshResourceIndex;
    g_animation_mesh_indices[animation_frame.TURN_1] = Module.BotTurnMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.TURN_2] = Module.BotTurnMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.TURN_3] = Module.BotTurnMeshResourceIndices[3];
    g_animation_mesh_indices[animation_frame.TURN_4] = Module.BotTurnMeshResourceIndices[4];
    g_animation_mesh_indices[animation_frame.TURN_5] = Module.BotTurnMeshResourceIndices[5];
    g_animation_mesh_indices[animation_frame.MOVE_RIGHT] = Module.BotMoveRightMeshResourceIndex;

    g_animation_mesh_indices[animation_frame.FIRE_LEFT_1] = Module.BotFireLeftMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.FIRE_LEFT_2] = Module.BotFireLeftMeshResourceIndices[2];

    g_animation_mesh_indices[animation_frame.FIRE_RIGHT_1] = Module.BotFireRightMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.FIRE_RIGHT_2] = Module.BotFireRightMeshResourceIndices[2];

    g_zap_bot_mesh_index = new_mesh(g_animation_mesh_indices[animation_frame.MOVE_LEFT]);
    g_zap_bot_transform_index = transform_create();
    mesh_set_transform(g_zap_bot_mesh_index, g_zap_bot_transform_index);
    set_mesh_texture(g_zap_bot_mesh_index, Module.BotTextureResourceIndex);
    set_mesh_is_visible(g_zap_bot_mesh_index, true);

    g_wait_time_remaining = Module.WaitDuration;
    g_laser_mesh_index = new_mesh(Module.LaserMeshResourceIndex);
    g_laser_transform_index = transform_create();
    mesh_set_transform(g_laser_mesh_index, g_laser_transform_index);
    set_mesh_texture(g_laser_mesh_index, Module.LaserTextureResourceIndex);
end

function Module.update()
    set_mesh_is_visible(g_laser_mesh_index, false);

    SetFrame_();
    Move_();

    set_mesh_to_mesh(g_zap_bot_mesh_index, g_animation_mesh_indices[g_animation_current_frame]);
    transform_set_scale(g_zap_bot_transform_index, 0.7, 0.55, 1);
    transform_set_translation(g_zap_bot_transform_index, g_current_pos_x, g_current_pos_y + 5, g_current_pos_z + 2);

    local is_colliding = false;

    if g_move_direction == move_direction.LEFT and
            g_is_firing and g_time_since_fire_start > 15 and g_time_since_fire_start < Module.FireDuration - 15 then
        set_mesh_is_visible(g_laser_mesh_index, true);
        local iTemp = math.random(50, 100) * 0.1;
        iTemp = iTemp / 32;
        transform_set_scale(g_laser_transform_index, 35, 4, 0);
        transform_set_translation(g_laser_transform_index, g_current_pos_x - 19, g_current_pos_y + 8.6, g_current_pos_z + 2.2);
        scroll_texture_on_mesh(g_laser_mesh_index, iTemp, 0);
        is_colliding = Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 36, g_current_pos_y + 7.5,
            g_current_pos_x - 5, g_current_pos_y + 11);
    end

    if g_move_direction == move_direction.RIGHT and
            g_is_firing and g_time_since_fire_start > 15 and g_time_since_fire_start < Module.FireDuration - 15 then
        set_mesh_is_visible(g_laser_mesh_index, true);
        local iTemp = math.random(50, 100) * -0.1;
        iTemp = iTemp / 32;
        transform_set_scale(g_laser_transform_index, 35, 4, 0);
        transform_set_translation(g_laser_transform_index, g_current_pos_x + 20.5, g_current_pos_y + 8.6, g_current_pos_z + 2.2);
        scroll_texture_on_mesh(g_laser_mesh_index, iTemp, 0);
        is_colliding = Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x + 5, g_current_pos_y + 7.5,
            g_current_pos_x + 36, g_current_pos_y + 11);
    end

    if not is_colliding then
        is_colliding = Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 4, g_current_pos_y + 0,
            g_current_pos_x + 4, g_current_pos_y + 4);
    end

    if is_colliding then
        Module.GameLogic.kill();
    end
end

return Module;
