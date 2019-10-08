local read_only = require "Data/read_only";

local Module = {};

Module.GameLogic = nil;

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

Module.SpawnCooldownTimer = 0;

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

local g_spawn_cooldown_timer = 0;

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
local g_direction_change_queue_length = 0;
local g_direction_change_queue = {};

local function PopQueue_()
    -- TODO: Built-in way to do this in Lua?
    for iLoop = 1, g_direction_change_queue_length - 1 do
        g_direction_change_queue[iLoop] = g_direction_change_queue[iLoop + 1];
    end

    g_direction_change_queue_length = g_direction_change_queue_length - 1;
end

local function CheckForChange_()
    if g_time_until_next_direction_change > 0 then
        g_time_until_next_direction_change = g_time_until_next_direction_change - 1;
        return;
    end

    local iLadderX = 0;
    local bNewDir = false;

    if g_current_move_direction == move_direction.RIGHT or g_current_move_direction == move_direction.LEFT then
        local ladder_index, _ = Module.GameLogic.find_ladder(g_current_pos_x, g_current_pos_y);

        if ladder_index < 0 then
            return;
        end

        iLadderX = get_ladder_x1(ladder_index);
        g_current_ladder_pos_z = get_ladder_z1(ladder_index);

        if g_current_pos_x < (iLadderX - 0.5) or g_current_pos_x > (iLadderX + 0.5) then
            return;
        end

        bNewDir = true;
    end

    if g_current_move_direction == move_direction.UP or g_current_move_direction == move_direction.DOWN then
        local iHit, _ = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y + 4, 4, 2);

        if iHit == g_current_pos_y then
            bNewDir = true;
        else
            return;
        end
    end

    local iNewDir = 0;

    if bNewDir then
        iNewDir = g_direction_change_queue[1];
        PopQueue_();
    end

    if iNewDir == 0 then
        return;
    end

    if iNewDir == 1 or iNewDir == 2 then
        if g_current_move_direction == move_direction.LEFT or g_current_move_direction == move_direction.RIGHT then
            g_current_pos_x = iLadderX;
            g_time_until_next_direction_change = 15;
            g_current_fly_direction = g_current_move_direction;
            g_jump_animation_time = 0;
        end
    else
        if g_current_move_direction == move_direction.UP or g_current_move_direction == move_direction.DOWN then
            g_time_until_next_direction_change = 15;
            g_jump_animation_time = 0;
        end
    end

    g_current_move_direction = iNewDir;
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

local function AdjustZ_(platform_index)
    local iPlatZ = get_platform_z1(platform_index);

    if g_current_pos_z < iPlatZ then
        g_current_pos_z = g_current_pos_z + 1;
    end

    if g_current_pos_z > iPlatZ + 2 then
        g_current_pos_z = g_current_pos_z - 1;
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

local function MoveSheep_()
    CheckForChange_();
    ProgressSheep_();

    local iHit, platform_index = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y + 5, 4, 2);

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
        AdjustZ_(platform_index);
    end
end

function Module.copy_leader_properties(leader_sheep)
    local iX, iY, iZ, dir = leader_sheep.get_movement_properties();
    g_current_pos_x = iX;
    g_current_pos_y = iY;
    g_current_pos_z = iZ;
    g_current_move_direction = dir;

    -- TODO: Do these need to be copied?
    local frame, air_time, count, ladder_z = leader_sheep.get_animation_properties();
    g_animation_current_frame = frame;
    g_jump_animation_time = air_time;
    g_time_until_next_direction_change = count;
    g_current_ladder_pos_z = ladder_z;
end

function Module.initialize()
    g_spawn_cooldown_timer = Module.SpawnCooldownTimer;

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

function Module.update()
    if g_spawn_cooldown_timer > 0 then
        g_spawn_cooldown_timer = g_spawn_cooldown_timer - 1;

        local mesh_index = g_animation_mesh_indices[g_animation_current_frame];
        select_object_mesh(mesh_index);

        if (g_spawn_cooldown_timer & 2) and (g_spawn_cooldown_timer < 50) then
            set_identity_mesh_matrix(mesh_index);
            translate_mesh_matrix(mesh_index, g_current_pos_x, g_current_pos_y + 6.5, g_current_pos_z - 0.5);
            set_texture_and_is_visible_on_mesh(mesh_index, Module.SheepTextureResourceIndex, 1);
        else
            set_texture_and_is_visible_on_mesh(mesh_index, 0, 0);
        end

        return;
    end

    -- TODO: Animate through changemesh, instead of set_texture_and_is_visible_on_mesh?
    select_object_mesh(g_animation_mesh_indices[g_animation_current_frame]);  -- Previous frame
    set_texture_and_is_visible_on_mesh(g_animation_mesh_indices[g_animation_current_frame], 0, 0);

    g_copter_current_scale = 0;
    AdvanceFrame_();
    MoveSheep_();

    local anim_mesh_index = g_animation_mesh_indices[g_animation_current_frame];
    select_object_mesh(anim_mesh_index);
    set_identity_mesh_matrix(anim_mesh_index);
    translate_mesh_matrix(anim_mesh_index, g_current_pos_x, g_current_pos_y + 6.5, g_current_pos_z - 0.5);
    set_texture_and_is_visible_on_mesh(anim_mesh_index, Module.SheepTextureResourceIndex, 1);

    if g_copter_current_scale > 0 then
        g_copter_current_rotation_y = g_copter_current_rotation_y + 35;
        select_object_mesh(g_copter_mesh_index);
        set_identity_mesh_matrix(g_copter_mesh_index);
        rotate_x_mesh_matrix(g_copter_mesh_index, 270);
        rotate_y_mesh_matrix(g_copter_mesh_index, g_copter_current_rotation_y);
        translate_mesh_matrix(g_copter_mesh_index, 0, 4, 0);
        scale_mesh_matrix(g_copter_mesh_index, g_copter_current_scale, g_copter_current_scale, g_copter_current_scale);
        translate_mesh_matrix(g_copter_mesh_index, g_current_pos_x, g_current_pos_y + 8.5, g_current_pos_z - 0.5);
        set_texture_and_is_visible_on_mesh(g_copter_mesh_index, Module.CopterTextureResourceIndex, 1);
    else
        select_object_mesh(g_copter_mesh_index);
        set_texture_and_is_visible_on_mesh(g_copter_mesh_index, 0, 0);
    end

    if Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 6, g_current_pos_y + 1,
            g_current_pos_x + 6, g_current_pos_y + 9) then
        play_sound_effect(Module.KillSoundResourceIndex);
        Module.GameLogic.kill();
    end
end

function Module.queue_direction_change(direction_change_to_queue)
    -- TODO: Built-in way to do this in Lua?
    g_direction_change_queue_length = g_direction_change_queue_length + 1;
    g_direction_change_queue[g_direction_change_queue_length] = direction_change_to_queue;
end

return Module;
