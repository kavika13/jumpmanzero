local read_only = require "Data/read_only";

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

local g_is_initialized = false;

local g_animation_mesh_indices = {};
local g_animation_current_frame = 0;

local g_laser_mesh_index = 0;

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
        local player_pos_x = get_player_current_position_x();
        local player_pos_y = get_player_current_position_y();

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
        local player_pos_x = get_player_current_position_x();
        local player_pos_y = get_player_current_position_y();

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
        local iPlat = find_platform(g_current_pos_x, g_current_pos_y, 5, 2);
        local iHit = get_script_event_data_4();
        abs_platform(iPlat);
        g_current_pos_z = get_script_selected_level_object_z1();

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

        local iPlat = find_platform(g_current_pos_x - 7, g_current_pos_y, 5, 2);
        local iHit = get_script_event_data_4();

        if iHit < g_current_pos_y - 6 then
            g_move_direction = move_direction.RIGHT
            g_turn_time_remaining = kTURN_DURATION;
        end
    end

    if g_move_direction == move_direction.RIGHT then
        g_current_pos_x = g_current_pos_x + 0.7;

        local iPlat = find_platform(g_current_pos_x + 7, g_current_pos_y, 5, 2);
        local iHit = get_script_event_data_4();

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

local function Initialize_()
    g_current_pos_x = Module.InitialPosX;
    g_current_pos_y = Module.InitialPosY;
    g_move_direction = move_direction.LEFT;

    g_animation_mesh_indices[animation_frame.MOVE_LEFT] = new_mesh(Module.BotMoveLeftMeshResourceIndex);
    g_animation_mesh_indices[animation_frame.TURN_1] = new_mesh(Module.BotTurnMeshResourceIndices[1]);
    g_animation_mesh_indices[animation_frame.TURN_2] = new_mesh(Module.BotTurnMeshResourceIndices[2]);
    g_animation_mesh_indices[animation_frame.TURN_3] = new_mesh(Module.BotTurnMeshResourceIndices[3]);
    g_animation_mesh_indices[animation_frame.TURN_4] = new_mesh(Module.BotTurnMeshResourceIndices[4]);
    g_animation_mesh_indices[animation_frame.TURN_5] = new_mesh(Module.BotTurnMeshResourceIndices[5]);
    g_animation_mesh_indices[animation_frame.MOVE_RIGHT] = new_mesh(Module.BotMoveRightMeshResourceIndex);

    g_animation_mesh_indices[animation_frame.FIRE_LEFT_1] = new_mesh(Module.BotFireLeftMeshResourceIndices[1]);
    g_animation_mesh_indices[animation_frame.FIRE_LEFT_2] = new_mesh(Module.BotFireLeftMeshResourceIndices[2]);

    g_animation_mesh_indices[animation_frame.FIRE_RIGHT_1] = new_mesh(Module.BotFireRightMeshResourceIndices[1]);
    g_animation_mesh_indices[animation_frame.FIRE_RIGHT_2] = new_mesh(Module.BotFireRightMeshResourceIndices[2]);
end

function Module.update()
    if not g_is_initialized then
        g_is_initialized = true;
        Initialize_();
        g_wait_time_remaining = Module.WaitDuration;
        g_laser_mesh_index = new_mesh(Module.LaserMeshResourceIndex);
    end

    select_object_mesh(g_laser_mesh_index);
    set_object_visual_data(Module.LaserTextureResourceIndex, 0);

    select_object_mesh(g_animation_mesh_indices[g_animation_current_frame]);
    set_object_visual_data(0, 0);

    SetFrame_();
    Move_();

    select_object_mesh(g_animation_mesh_indices[g_animation_current_frame]);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_scale_matrix(0.7, 0.55, 1);
    script_selected_mesh_translate_matrix(g_current_pos_x, g_current_pos_y + 5, g_current_pos_z + 2);
    set_object_visual_data(Module.BotTextureResourceIndex, 1);

    local is_colliding = false;

    if g_move_direction == move_direction.LEFT and
            g_is_firing and g_time_since_fire_start > 15 and g_time_since_fire_start < Module.FireDuration - 15 then
        select_object_mesh(g_laser_mesh_index);
        set_object_visual_data(Module.LaserTextureResourceIndex, 1);
        script_selected_mesh_set_identity_matrix();
        local iTemp = rnd(50, 100) * 0.1;
        iTemp = iTemp / 2;
        script_selected_mesh_scale_matrix(35, 4, 0);
        script_selected_mesh_scroll_texture(iTemp, 0);
        script_selected_mesh_translate_matrix(g_current_pos_x - 19, g_current_pos_y + 8.6, g_current_pos_z + 2.2);
        is_colliding = is_player_colliding_with_rect(
            g_current_pos_x - 36, g_current_pos_y + 7.5,
            g_current_pos_x - 5, g_current_pos_y + 11);
    end

    if g_move_direction == move_direction.RIGHT and
            g_is_firing and g_time_since_fire_start > 15 and g_time_since_fire_start < Module.FireDuration - 15 then
        select_object_mesh(g_laser_mesh_index);
        set_object_visual_data(Module.LaserTextureResourceIndex, 1);
        script_selected_mesh_set_identity_matrix();
        local iTemp = rnd(50, 100) * -0.1;
        iTemp = iTemp / 2;
        script_selected_mesh_scale_matrix(35, 4, 0);
        script_selected_mesh_scroll_texture(iTemp, 0);
        script_selected_mesh_translate_matrix(g_current_pos_x + 20.5, g_current_pos_y + 8.6, g_current_pos_z + 2.2);
        is_colliding = is_player_colliding_with_rect(
            g_current_pos_x + 5, g_current_pos_y + 7.5,
            g_current_pos_x + 36, g_current_pos_y + 11);
    end

    if not is_colliding then
        is_colliding = is_player_colliding_with_rect(
            g_current_pos_x - 4, g_current_pos_y,
            g_current_pos_x + 4, g_current_pos_y + 4);
    end

    if is_colliding then
        kill();
    end
end

return Module;
