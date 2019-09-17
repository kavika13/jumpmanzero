local read_only = require "Data/read_only";

local Module = {};

Module.SheepMoveLeftMeshResourceIndices = {};
Module.SheepJumpLeftMeshResourceIndices = {};
Module.SheepFlyLeftMeshResourceIndices = {};
Module.SheepMoveRightMeshResourceIndices = {};
Module.SheepJumpRightMeshResourceIndices = {};
Module.SheepFlyRightMeshResourceIndices = {};
Module.CopterMeshResourceIndex = 0;
Module.SheepTextureResourceIndex = 0;
Module.CopterTextureResourceIndex = 0;
Module.KillSoundResourceIndex = 0;

local animation_frame = {
    MOVE_LEFT_1 = 0,
    MOVE_LEFT_2 = 1,
    JUMP_LEFT_1 = 2,
    JUMP_LEFT_2 = 3,
    JUMP_LEFT_3 = 4,
    FLY_LEFT_1 = 5,
    FLY_LEFT_2 = 6,
    FLY_LEFT_3 = 7,
    MOVE_RIGHT_1 = 10,
    MOVE_RIGHT_2 = 11,
    JUMP_RIGHT_1 = 12,
    JUMP_RIGHT_2 = 13,
    JUMP_RIGHT_3 = 14,
    FLY_RIGHT_1 = 15,
    FLY_RIGHT_2 = 16,
    FLY_RIGHT_3 = 17,
};
animation_frame = read_only.make_table_read_only(animation_frame);

local move_direction = {
    UP = 1,
    DOWN = 2,
    LEFT = 3,
    RIGHT = 4,
};
move_direction = read_only.make_table_read_only(move_direction);

local g_is_initialized = false;

local g_animation_mesh_indices = {};
local g_animation_current_frame = 0;
local g_animation_frame_counter = 0;  -- Counts up until the next "alt frame" increment (every 3 frames increments alt)
local g_animation_alt_frame_counter = 0;  -- On 1 or 3 switches to an alt frame in the current animation
local g_jump_animation_time = 0;

local g_copter_mesh_index = 0;

local g_current_pos_x = 0;
local g_current_pos_y = 0;
local g_current_pos_z = 0;
local g_copter_current_rotation_y = 0;
local g_copter_current_scale = 0;

local g_current_move_direction = 0;
local g_current_fly_direction = 0;

local g_current_ladder_pos_z = 0;

local g_time_until_next_direction_change = 0;  -- TODO: Is this name correct?
local g_will_queue_direction_change_for_followers = false;

local function CheckForChange_()
    g_will_queue_direction_change_for_followers = false;

    if g_time_until_next_direction_change > 0 then
        g_time_until_next_direction_change = g_time_until_next_direction_change - 1;
        return;
    end

    local iLadderX = 0;
    local bUp = false;
    local bDown = false;
    local bLeft = false;
    local bRight = false;

    if g_current_move_direction == move_direction.RIGHT or g_current_move_direction == move_direction.LEFT then
        find_ladder(g_current_pos_x, g_current_pos_y);
        local iLad = get_script_event_data_4();

        if iLad < 0 then
            return;
        end

        abs_ladder(iLad);
        iLadderX = get_script_selected_level_object_x1();
        g_current_ladder_pos_z = get_script_selected_level_object_z1();
        local iY1 = get_script_selected_level_object_y1();
        local iY2 = get_script_selected_level_object_y2();

        if g_current_pos_x < (iLadderX - 0.5) or g_current_pos_x > (iLadderX + 0.5) then
            return;
        end

        g_will_queue_direction_change_for_followers = true;

        if iY1 > g_current_pos_y + 12 and g_jump_animation_time == 0 then
            bUp = true;
        end

        if iY2 < g_current_pos_y - 12 and g_jump_animation_time == 0 then
            bDown = true;
        end

        local iPlat = find_platform(g_current_pos_x, g_current_pos_y + 4, 4, 2);
        abs_platform(iPlat);
        local iX1 = get_script_selected_level_object_x1();
        local iX2 = get_script_selected_level_object_x2();

        if g_current_move_direction == move_direction.LEFT and iX1 < g_current_pos_x - 10 then
            bLeft = true;
        end

        if g_current_move_direction == move_direction.RIGHT and iX2 > g_current_pos_x + 10 then
            bRight = true;
        end
    end

    if g_current_move_direction == move_direction.UP or g_current_move_direction == move_direction.DOWN then
        local iLad = find_ladder(g_current_pos_x, g_current_pos_y);
        abs_ladder(iLad);
        local iY1 = get_script_selected_level_object_y1();
        local iY2 = get_script_selected_level_object_y2();

        if iY1 > g_current_pos_y + 10 and g_current_move_direction ~= move_direction.DOWN then
            bUp = true;
        end

        if iY2 < g_current_pos_y - 10 and g_current_move_direction ~= move_direction.UP then
            bDown = true;
        end

        local iPlat = find_platform(g_current_pos_x, g_current_pos_y + 4, 4, 2);
        abs_platform(iPlat);
        local iHit = get_script_event_data_4();

        if iHit == g_current_pos_y then
            g_will_queue_direction_change_for_followers = true;
            local iX1 = get_script_selected_level_object_x1();
            local iX2 = get_script_selected_level_object_x2();

            if iX1 < g_current_pos_x - 10 then
                bLeft = true;
            end

            if iX2 > g_current_pos_x + 10 then
                bRight = true;
            end
        else
            return;
        end
    end

    local player_pos_x = get_player_current_position_x();
    local player_pos_y = get_player_current_position_y();
    local iNewDir = 0;

    if bUp and player_pos_y > g_current_pos_y + 10 then
        iNewDir = 1;
    elseif bDown and player_pos_y < g_current_pos_y - 10 then
        iNewDir = 2;
    elseif bLeft and player_pos_x < g_current_pos_x - 10 then
        iNewDir = 3;
    elseif bRight and player_pos_x > g_current_pos_x + 10 then
        iNewDir = 4;
    elseif bLeft and player_pos_x < g_current_pos_x then
        iNewDir = 3;
    elseif bRight then
        iNewDir = 4;
    elseif bLeft then
        iNewDir = 3;
    elseif bUp then
        iNewDir = 1;
    elseif bDown then
        iNewDir = 2;
    end

    if iNewDir == 0 then
        return;
    end

    if iNewDir == 1 or iNewDir == 2 then
        if g_current_move_direction == move_direction.LEFT or g_current_move_direction == move_direction.RIGHT then
            g_time_until_next_direction_change = 15;
            g_current_fly_direction = g_current_move_direction;
            g_jump_animation_time = 0;
            g_current_pos_x = iLadderX;
        end
    else
        if g_current_move_direction == move_direction.UP or g_current_move_direction == move_direction.DOWN then
            g_time_until_next_direction_change = 15;
            g_jump_animation_time = 0;
        end
    end

    g_current_move_direction = iNewDir;
end

local function PassDirections_(follower_sheep, iPassDir)
    for _, follower in ipairs(follower_sheep) do
        follower.queue_direction_change(iPassDir);
    end
end

local function AnimateCopter_(iTime)
    if iTime < 5 then
        g_animation_current_frame = animation_frame.FLY_LEFT_3;
    elseif iTime < 10 then
        g_animation_current_frame = animation_frame.FLY_LEFT_2;
    else
        g_animation_current_frame = animation_frame.FLY_LEFT_1;
    end

    if g_current_fly_direction == move_direction.RIGHT then
        g_animation_current_frame = g_animation_current_frame + 10;
    end

    g_copter_current_scale = (15 - iTime) / 15;
end

local function ProgressSheep_()
    if g_current_move_direction == move_direction.UP or g_current_move_direction == move_direction.DOWN then
        if g_time_until_next_direction_change > 0 then
            AnimateCopter_(g_time_until_next_direction_change);
            return;
        end

        if g_current_move_direction == move_direction.UP then
            g_current_pos_y = g_current_pos_y + 1;
        else
            g_current_pos_y = g_current_pos_y - 1;
        end

        if g_current_fly_direction == move_direction.LEFT then
            g_animation_current_frame = animation_frame.FLY_LEFT_3;
        else
            g_animation_current_frame = animation_frame.FLY_RIGHT_3;
        end

        g_copter_current_scale = 1;
    end

    if g_current_move_direction == move_direction.LEFT or g_current_move_direction == move_direction.RIGHT then
        if g_time_until_next_direction_change > 0 then
            AnimateCopter_(15 - g_time_until_next_direction_change);
            return;
        end

        if g_current_move_direction == move_direction.LEFT then
            g_current_pos_x = g_current_pos_x - 0.85;
            g_animation_current_frame = animation_frame.MOVE_LEFT_1;

            if g_animation_alt_frame_counter == 1 or g_animation_alt_frame_counter == 3 then
                g_animation_current_frame = animation_frame.MOVE_LEFT_2;
            end
        end

        if g_current_move_direction == move_direction.RIGHT then
            g_current_pos_x = g_current_pos_x + 0.85;
            g_animation_current_frame = animation_frame.MOVE_RIGHT_1;

            if g_animation_alt_frame_counter == 1 or g_animation_alt_frame_counter == 3 then
                g_animation_current_frame = animation_frame.MOVE_RIGHT_2;
            end
        end
    end
end

local function AdvanceFrame_()
    g_animation_frame_counter = g_animation_frame_counter + 1;

    if g_animation_frame_counter > 2 then
        g_animation_frame_counter = 0;
        g_animation_alt_frame_counter = g_animation_alt_frame_counter + 1;

        if g_animation_alt_frame_counter > 3 then
            g_animation_alt_frame_counter = 0;
        end
    end
end

local function AdjustZ_(iPlatNum)
    abs_platform(iPlatNum);
    local iPlatZ = get_script_selected_level_object_z1();

    if g_current_pos_z < iPlatZ then
        g_current_pos_z = g_current_pos_z + 1;
    end

    if g_current_pos_z > iPlatZ + 2 then
        g_current_pos_z = g_current_pos_z - 1;
    end
end

local function MoveSheep_(follower_sheep)
    CheckForChange_();

    if g_will_queue_direction_change_for_followers then
        PassDirections_(follower_sheep, g_current_move_direction);
    end

    ProgressSheep_();

    local iPlat = find_platform(g_current_pos_x, g_current_pos_y + 5, 4, 2);
    local iHit = get_script_event_data_4();

    if g_current_move_direction == move_direction.LEFT or g_current_move_direction == move_direction.RIGHT then
        if iHit < g_current_pos_y then
            g_current_pos_y = g_current_pos_y - 0.5;
            g_jump_animation_time = g_jump_animation_time + 1;
        else
            g_jump_animation_time = 0;
        end

        if g_jump_animation_time > 30 then
            g_animation_current_frame = animation_frame.JUMP_LEFT_3;
            g_current_pos_y = g_current_pos_y - 0.5;
        elseif g_jump_animation_time > 15 then
            g_animation_current_frame = animation_frame.JUMP_LEFT_3;
        elseif g_jump_animation_time > 8 then
            g_current_pos_y = g_current_pos_y + 0.5;
            g_animation_current_frame = animation_frame.JUMP_LEFT_2;
        elseif g_jump_animation_time > 0 then
            g_current_pos_y = g_current_pos_y + 1;
            g_animation_current_frame = animation_frame.JUMP_LEFT_1;
        end

        if g_jump_animation_time > 0 and g_current_move_direction == move_direction.RIGHT then
            g_animation_current_frame = g_animation_current_frame + 10;
        end

        if iHit > g_current_pos_y + 0.4 then
            g_current_pos_y = g_current_pos_y + 0.5;
        end
    end

    if g_current_move_direction == move_direction.UP or g_current_move_direction == move_direction.DOWN then
        g_current_pos_z = g_current_ladder_pos_z;
    else
        AdjustZ_(iPlat);
    end
end

local function Initialize_()
    g_current_pos_x = 250;
    g_current_pos_y = 115;
    g_current_pos_z = 2;
    g_current_move_direction = move_direction.LEFT;

    g_animation_mesh_indices[animation_frame.MOVE_LEFT_1] = new_mesh(Module.SheepMoveLeftMeshResourceIndices[1]);
    g_animation_mesh_indices[animation_frame.MOVE_LEFT_2] = new_mesh(Module.SheepMoveLeftMeshResourceIndices[2]);
    g_animation_mesh_indices[animation_frame.JUMP_LEFT_1] = new_mesh(Module.SheepJumpLeftMeshResourceIndices[1]);
    g_animation_mesh_indices[animation_frame.JUMP_LEFT_2] = new_mesh(Module.SheepJumpLeftMeshResourceIndices[2]);
    g_animation_mesh_indices[animation_frame.JUMP_LEFT_3] = new_mesh(Module.SheepJumpLeftMeshResourceIndices[3]);
    g_animation_mesh_indices[animation_frame.FLY_LEFT_1] = new_mesh(Module.SheepFlyLeftMeshResourceIndices[1]);
    g_animation_mesh_indices[animation_frame.FLY_LEFT_2] = new_mesh(Module.SheepFlyLeftMeshResourceIndices[2]);
    g_animation_mesh_indices[animation_frame.FLY_LEFT_3] = new_mesh(Module.SheepFlyLeftMeshResourceIndices[3]);

    g_animation_mesh_indices[animation_frame.MOVE_RIGHT_1] = new_mesh(Module.SheepMoveRightMeshResourceIndices[1]);
    g_animation_mesh_indices[animation_frame.MOVE_RIGHT_2] = new_mesh(Module.SheepMoveRightMeshResourceIndices[2]);
    g_animation_mesh_indices[animation_frame.JUMP_RIGHT_1] = new_mesh(Module.SheepJumpRightMeshResourceIndices[1]);
    g_animation_mesh_indices[animation_frame.JUMP_RIGHT_2] = new_mesh(Module.SheepJumpRightMeshResourceIndices[2]);
    g_animation_mesh_indices[animation_frame.JUMP_RIGHT_3] = new_mesh(Module.SheepJumpRightMeshResourceIndices[3]);
    g_animation_mesh_indices[animation_frame.FLY_RIGHT_1] = new_mesh(Module.SheepFlyRightMeshResourceIndices[1]);
    g_animation_mesh_indices[animation_frame.FLY_RIGHT_2] = new_mesh(Module.SheepFlyRightMeshResourceIndices[2]);
    g_animation_mesh_indices[animation_frame.FLY_RIGHT_3] = new_mesh(Module.SheepFlyRightMeshResourceIndices[3]);

    g_copter_mesh_index = new_mesh(Module.CopterMeshResourceIndex);
end

function Module.update(follower_sheep)
    if not g_is_initialized then
        g_is_initialized = true;
        Initialize_();
    end

    select_object_mesh(g_animation_mesh_indices[g_animation_current_frame]);
    set_object_visual_data(0, 0);

    g_copter_current_scale = 0;

    AdvanceFrame_();
    MoveSheep_(follower_sheep);

    select_object_mesh(g_animation_mesh_indices[g_animation_current_frame]);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(g_current_pos_x, g_current_pos_y + 6.5, g_current_pos_z - 0.5);
    set_object_visual_data(Module.SheepTextureResourceIndex, 1);

    if g_copter_current_scale > 0 then
        g_copter_current_rotation_y = g_copter_current_rotation_y + 35;
        select_object_mesh(g_copter_mesh_index);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_rotate_matrix_x(270);
        script_selected_mesh_rotate_matrix_y(g_copter_current_rotation_y);
        script_selected_mesh_translate_matrix(0, 4, 0);
        script_selected_mesh_scale_matrix(g_copter_current_scale, g_copter_current_scale, g_copter_current_scale);
        script_selected_mesh_translate_matrix(g_current_pos_x, g_current_pos_y + 8.5, g_current_pos_z - 0.5);
        set_object_visual_data(Module.CopterTextureResourceIndex, 1);
    else
        select_object_mesh(g_copter_mesh_index);
        set_object_visual_data(0, 0);
    end

    if is_player_colliding_with_rect(
            g_current_pos_x - 6, g_current_pos_y + 1,
            g_current_pos_x + 6, g_current_pos_y + 9) then
        kill();
        play_sound_effect(Module.KillSoundResourceIndex);
    end
end

function Module.get_movement_properties()
    return g_current_pos_x, g_current_pos_y, g_current_pos_z, g_current_move_direction;
end

function Module.get_animation_properties()
    -- TODO: Do these need to be copied out?
    return g_animation_current_frame, g_jump_animation_time, g_time_until_next_direction_change, g_current_ladder_pos_z;
end

return Module;
