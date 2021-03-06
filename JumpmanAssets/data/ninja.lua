local read_only = require "data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.MoveRightMeshResourceIndices = {};
Module.JumpRightMeshResourceIndex = 0;
Module.KickRightMeshResourceIndex = 0;
Module.RollRightMeshResourceIndices = {};
Module.MoveLeftMeshResourceIndices = {};
Module.JumpLeftMeshResourceIndex = 0;
Module.KickLeftMeshResourceIndex = 0;
Module.RollLeftMeshResourceIndices = {};
Module.DeadMeshResourceIndex = 0;
Module.FixDonutMeshResourceIndices = {};
Module.TextureResourceIndex = 0;

Module.InitialPosX = 0;
Module.InitialPosY = 0;

-- TODO: Move this into a shared file, split into separate tables by type. Or inject from engine?
local player_movement_direction = {
    DIR_UP = 1,
    DIR_DOWN = 2,
    DIR_LEFT = 3,
    DIR_RIGHT = 4,
};
player_movement_direction = read_only.make_table_read_only(player_movement_direction);

-- TODO: Move this into a shared file, split into separate tables by type. Or inject from engine?
local player_special_action = {
    ACT_KICK = 1,
    ACT_PUNCH = 2,
};
player_special_action = read_only.make_table_read_only(player_special_action);

local status_type = {
    NORMAL = 0,
    JUMP_KICK = 1,
    LOW_RAGDOLL = 2,
    DEAD = 3,
    HIGH_RAGDOLL = 4,
    FIX_DONUT = 20,
};
status_type = read_only.make_table_read_only(status_type);

local animation_frame = {
    MOVE_RIGHT_1 = 0,
    MOVE_RIGHT_2 = 1,
    JUMP_RIGHT_1 = 2,
    KICK_RIGHT_1 = 3,
    ROLL_RIGHT_1 = 4,
    ROLL_RIGHT_2 = 5,
    ROLL_RIGHT_3 = 6,
    ROLL_RIGHT_4 = 7,
    MOVE_LEFT_1 = 8,
    MOVE_LEFT_2 = 9,
    JUMP_LEFT_1 = 10,
    KICK_LEFT_1 = 11,
    ROLL_LEFT_1 = 12,
    ROLL_LEFT_2 = 13,
    ROLL_LEFT_3 = 14,
    ROLL_LEFT_4 = 15,
    DEAD_1 = 16,
    FIX_DONUT_1 = 17,
    FIX_DONUT_2 = 18,
};
animation_frame = read_only.make_table_read_only(animation_frame);

local g_ninja_mesh_index = -1;
local g_ninja_transform_index = -1;
local g_animation_mesh_indices = {};
local g_animation_current_frame = animation_frame.MOVE_RIGHT_1;
local g_animation_frame_counter = 0;  -- The current alt frame in the current animation. Counts 0 - 3
local g_animation_sub_frame_counter = 0;  -- Counts to ..._sub_frames_per_frame and increments g_animation_frame_counter
local g_animation_sub_frames_per_frame = 3;

local g_current_pos_x = 0;
local g_current_pos_y = 0;
local g_current_pos_z = 0;
local g_current_velocity_x = 0;

local g_current_status = status_type.NORMAL;
local g_current_status_counter = 0;

local g_current_donut_to_fix = nil;

local function CheckForDonut_()
    local num_donuts = Module.GameLogic.get_donut_object_count();

    for donut_index = 0, num_donuts - 1 do
        local current_donut = Module.GameLogic.get_donut(donut_index);

        if Module.GameLogic.get_donut_is_collected(donut_index) and
                current_donut.pos[1] < g_current_pos_x + 1 and current_donut.pos[1] > g_current_pos_x - 1 and
                current_donut.pos[2] > g_current_pos_y + 0 and current_donut.pos[2] < g_current_pos_y + 15 then
            g_current_status = status_type.FIX_DONUT;
            g_current_status_counter = 0;
            g_current_donut_to_fix = current_donut;
        end
    end
end

local function AdvanceFrame_()
    g_current_status_counter = g_current_status_counter + 1;
    g_animation_sub_frame_counter = g_animation_sub_frame_counter + 1;

    if g_animation_sub_frame_counter > g_animation_sub_frames_per_frame then
        g_animation_sub_frame_counter = 0;
        g_animation_frame_counter = g_animation_frame_counter + 1;

        if g_animation_frame_counter > 3 then
            g_animation_frame_counter = 0;
        end
    end
end

local function MoveNinja_()
    local iCollideWall = Module.GameLogic.collide_wall(
        g_current_pos_x - 1, g_current_pos_y + 0,
        g_current_pos_x + 1, g_current_pos_y + 8);

    if iCollideWall == 1 then
        g_current_pos_y = g_current_pos_y - 1.25;
    end

    iCollideWall = Module.GameLogic.collide_wall(
        g_current_pos_x - 3, g_current_pos_y + 0,
        g_current_pos_x + 3, g_current_pos_y + 6);

    if iCollideWall == 3 then
        g_current_pos_x = g_current_pos_x + 1;

        if g_current_velocity_x < 0 then
            g_current_velocity_x = 0 - (g_current_velocity_x / 4);
        end
    end

    if iCollideWall == 4 then
        g_current_pos_x = g_current_pos_x - 1;

        if g_current_velocity_x > 0 then
            g_current_velocity_x = 0 - (g_current_velocity_x / 4);
        end
    end

    if g_current_status == status_type.NORMAL then
        g_animation_sub_frames_per_frame = 3;
        g_animation_current_frame = animation_frame.MOVE_RIGHT_1;

        if g_animation_frame_counter == 0 or g_animation_frame_counter == 2 then
            g_animation_current_frame = animation_frame.MOVE_RIGHT_2;
        end

        local iHit, iPlat2 = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y, 5, 2);

        if iHit > g_current_pos_y + 0.2 then
            g_current_pos_y = g_current_pos_y + 0.5;
        end

        if iHit < g_current_pos_y then
            g_current_pos_y = g_current_pos_y - 0.5;

            if iHit < g_current_pos_y - 4 then
                g_current_status = status_type.LOW_RAGDOLL;
                g_current_status_counter = 5;
                g_current_velocity_x = 0;
            end
        end
    end

    if g_current_status == status_type.NORMAL then
        if g_current_velocity_x ~= 0.6 and g_current_velocity_x ~= -0.6 then
            if g_current_velocity_x > 0 then
                g_current_velocity_x = 0.6;
            end

            if g_current_velocity_x < 0 then
                g_current_velocity_x = -0.6;
            end

            if g_current_velocity_x == 0 then
                if g_current_pos_x < Module.GameLogic.get_player_current_position_x() then
                    g_current_velocity_x = 0.6;
                end

                if g_current_pos_x > Module.GameLogic.get_player_current_position_x() then
                    g_current_velocity_x = -0.6;
                end
            end
        end

        local iHit, iPlat2 = Module.GameLogic.find_platform(g_current_pos_x + g_current_velocity_x * 10, g_current_pos_y + 6, 5, 2);

        if iHit < g_current_pos_y - 7 or iPlat2 < 0 then
            g_current_velocity_x = -g_current_velocity_x;
        end

        g_current_pos_x = g_current_pos_x + g_current_velocity_x;

        local iDif = (g_current_pos_x + 44 * g_current_velocity_x) - Module.GameLogic.get_player_current_position_x();
        local player_pos_y = Module.GameLogic.get_player_current_position_y();

        if iDif > 0 - 2 and iDif < 2 and g_current_status_counter > 20 then
            if player_pos_y > g_current_pos_y - 15 and player_pos_y <= g_current_pos_y then
                g_current_status = status_type.JUMP_KICK;
                g_current_status_counter = 0;
            end
        end
    end

    if g_current_status == status_type.NORMAL and g_current_status_counter > 160 then
        CheckForDonut_();
    end

    if g_current_status == status_type.JUMP_KICK then
        local iC = g_current_status_counter;

        if g_current_velocity_x > 0 then
            g_current_pos_x = g_current_pos_x + 0.7;
        end

        if g_current_velocity_x < 0 then
            g_current_pos_x = g_current_pos_x - 0.7;
        end

        if iC < 5 or iC == 7 or iC == 10 or iC == 14 or iC == 18 then
            g_current_pos_y = g_current_pos_y + 1;
        end

        if iC > 41 or iC == 39 or iC == 36 or iC == 32 or iC == 28 then
            g_current_pos_y = g_current_pos_y - 1;
        end

        local iHit, iPlat2 = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y, 5, 2);

        if iHit > g_current_pos_y + 1 then
            g_current_status = status_type.NORMAL;
            g_current_pos_y = iHit;
        end

        g_animation_current_frame = animation_frame.JUMP_RIGHT_1;

        if iC > 10 then
            g_animation_current_frame = animation_frame.KICK_RIGHT_1;
        end
    end

    if g_current_status == status_type.LOW_RAGDOLL then
        g_animation_sub_frames_per_frame = 5;
        g_current_pos_x = g_current_pos_x + g_current_velocity_x;

        if g_current_status_counter < 5 or g_current_status_counter == 7 or g_current_status_counter == 9 then
            g_current_pos_y = g_current_pos_y + 1;
        end

        if g_current_status_counter == 12 or g_current_status_counter == 15 or
                g_current_status_counter == 17 or g_current_status_counter > 20 then
            g_current_pos_y = g_current_pos_y - 1;
        end

        local iHit, iPlat2 = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y, 5, 2);

        if iHit > g_current_pos_y then
            if g_current_status_counter > 10 then
                g_current_status = status_type.DEAD;
                g_current_status_counter = 0;
            end

            g_current_pos_y = iHit;
        end

        g_animation_current_frame = animation_frame.ROLL_RIGHT_1 + g_animation_frame_counter;
    end

    if g_current_status == status_type.HIGH_RAGDOLL then
        g_animation_sub_frames_per_frame = 5;
        g_current_pos_x = g_current_pos_x + g_current_velocity_x;

        if g_current_status_counter < 5 or g_current_status_counter == 7 or
                g_current_status_counter == 10 or g_current_status_counter == 15 then
            g_current_pos_y = g_current_pos_y + 1;
        end

        if g_current_status_counter > 30 or g_current_status_counter == 28 or
                g_current_status_counter == 25 or g_current_status_counter == 20 then
            g_current_pos_y = g_current_pos_y - 1;
        end

        local iHit, iPlat2 = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y, 2, 2);

        if iHit > g_current_pos_y then
            g_current_status = status_type.DEAD;
            g_current_pos_y = iHit;
            g_current_status_counter = 0;
        end

        g_animation_current_frame = animation_frame.ROLL_RIGHT_1 + g_animation_frame_counter;
    end

    if g_current_status == status_type.DEAD then
        g_current_velocity_x = 0;
        g_animation_current_frame = animation_frame.DEAD_1;

        if g_current_status_counter == 200 then
            g_current_status = status_type.NORMAL;
            g_current_status_counter = 0;
        end
    end

    if g_current_velocity_x < 0 then
        g_animation_current_frame = animation_frame.MOVE_LEFT_1 + g_animation_current_frame;
    end

    if g_current_status == status_type.FIX_DONUT then
        g_animation_current_frame = animation_frame.FIX_DONUT_1;

        if g_animation_frame_counter > 1 then
            g_animation_current_frame = animation_frame.FIX_DONUT_2;
        end

        if g_current_status_counter == 100 then
            g_current_status = status_type.NORMAL;
            Module.GameLogic.set_donut_is_collected(g_current_donut_to_fix.index, false);
            set_mesh_is_visible(g_current_donut_to_fix.mesh_index, true);
        end
    end
end

local function CollidePlayer_()
    if g_current_status == status_type.LOW_RAGDOLL then
        return;
    end

    if g_current_status == status_type.DEAD then
        return;
    end

    local current_player_special_action = Module.GameLogic.get_player_current_special_action();
    local iWin = 0;

    if g_current_status ~= status_type.FIX_DONUT and g_current_status ~= status_type.HIGH_RAGDOLL then
        iWin = 1;
    end

    if current_player_special_action == player_special_action.ACT_PUNCH then
        iWin = -1;
    end

    if current_player_special_action == player_special_action.ACT_KICK then
        if g_current_status ~= status_type.JUMP_KICK then
            iWin = -1;
        end

        if Module.GameLogic.get_player_current_position_y() >= g_current_pos_y - 2 then
            iWin = -1;
        end
    end

    if iWin == 0 then
        return;
    end

    local is_colliding = false;

    if iWin == 1 and g_current_status == status_type.JUMP_KICK and g_current_velocity_x < 0 then
        is_colliding = Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 4, g_current_pos_y + 1,
            g_current_pos_x, g_current_pos_y + 9);
    elseif iWin == 1 and g_current_status == status_type.JUMP_KICK and g_current_velocity_x >= 0 then
        is_colliding = Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x, g_current_pos_y + 1,
            g_current_pos_x + 4, g_current_pos_y + 9);
    elseif iWin == 1 then
        is_colliding = Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 2, g_current_pos_y + 5,
            g_current_pos_x + 2, g_current_pos_y + 7);
    else
        is_colliding = Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 5, g_current_pos_y + 5,
            g_current_pos_x + 5, g_current_pos_y + 10);
    end

    if not is_colliding then
        return;
    end

    if iWin == 1 then
        Module.GameLogic.kill();
        return;
    end

    local previous_status = g_current_status;

    g_current_status = status_type.LOW_RAGDOLL;

    if previous_status == status_type.JUMP_KICK then
        g_current_status_counter = 0;
    end

    if previous_status == status_type.NORMAL or previous_status == status_type.FIX_DONUT then
        g_current_status_counter = 5;
    end

    g_current_velocity_x = -1.5;

    if Module.GameLogic.get_player_current_direction() == player_movement_direction.DIR_RIGHT then
        g_current_velocity_x = 1.5;
    end

    if previous_status == status_type.HIGH_RAGDOLL then
        g_current_status = status_type.HIGH_RAGDOLL;
        g_current_status_counter = 0;
    end

    if current_player_special_action == player_special_action.ACT_PUNCH then
        g_current_status = status_type.HIGH_RAGDOLL;
        g_current_velocity_x = 0;
    end
end

local function SetPos_()
    g_current_pos_x = Module.InitialPosX;
    g_current_pos_y = Module.InitialPosY;
    g_current_pos_z = 2;
    g_current_status = status_type.NORMAL;
    g_animation_sub_frames_per_frame = 3;
    g_current_velocity_x = 0;
end

function Module.initialize()
    SetPos_();

    g_animation_mesh_indices[animation_frame.MOVE_RIGHT_1] = Module.MoveRightMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.MOVE_RIGHT_2] = Module.MoveRightMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.JUMP_RIGHT_1] = Module.JumpRightMeshResourceIndex;
    g_animation_mesh_indices[animation_frame.KICK_RIGHT_1] = Module.KickRightMeshResourceIndex;
    g_animation_mesh_indices[animation_frame.ROLL_RIGHT_1] = Module.RollRightMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.ROLL_RIGHT_2] = Module.RollRightMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.ROLL_RIGHT_3] = Module.RollRightMeshResourceIndices[3];
    g_animation_mesh_indices[animation_frame.ROLL_RIGHT_4] = Module.RollRightMeshResourceIndices[4];

    g_animation_mesh_indices[animation_frame.MOVE_LEFT_1] = Module.MoveLeftMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.MOVE_LEFT_2] = Module.MoveLeftMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.JUMP_LEFT_1] = Module.JumpLeftMeshResourceIndex;
    g_animation_mesh_indices[animation_frame.KICK_LEFT_1] = Module.KickLeftMeshResourceIndex;
    g_animation_mesh_indices[animation_frame.ROLL_LEFT_1] = Module.RollLeftMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.ROLL_LEFT_2] = Module.RollLeftMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.ROLL_LEFT_3] = Module.RollLeftMeshResourceIndices[3];
    g_animation_mesh_indices[animation_frame.ROLL_LEFT_4] = Module.RollLeftMeshResourceIndices[4];

    g_animation_mesh_indices[animation_frame.DEAD_1] = Module.DeadMeshResourceIndex;

    g_animation_mesh_indices[animation_frame.FIX_DONUT_1] = Module.FixDonutMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.FIX_DONUT_2] = Module.FixDonutMeshResourceIndices[2];

    g_ninja_mesh_index = new_mesh(g_animation_mesh_indices[animation_frame.MOVE_RIGHT_1]);
    g_ninja_transform_index = transform_create();
    mesh_set_transform(g_ninja_mesh_index, g_ninja_transform_index);
    set_mesh_texture(g_ninja_mesh_index, Module.TextureResourceIndex);
    set_mesh_is_visible(g_ninja_mesh_index, true);
end

function Module.update()
    if g_current_pos_y < 0 then
        g_current_pos_y = 0 - 5;
        g_current_status = status_type.DEAD;
        g_current_status_counter = 0;
    end

    AdvanceFrame_();
    MoveNinja_();
    CollidePlayer_();

    set_mesh_to_mesh(g_ninja_mesh_index, g_animation_mesh_indices[g_animation_current_frame]);
    transform_set_translation(g_ninja_transform_index, g_current_pos_x, g_current_pos_y + 5, g_current_pos_z - 0.5);
end


function Module.reset_pos()
    if g_current_status == status_type.DEAD then
        g_current_status_counter = 0 - 40;
    else
        SetPos_();
    end
end

return Module;
