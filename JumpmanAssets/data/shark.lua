local read_only = require "data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.MoveRightMeshResourceIndices = {};
Module.TurnRightMeshResourceIndices = {};
Module.MoveLeftMeshResourceIndices = {};
Module.TurnLeftMeshResourceIndices = {};
Module.TextureResourceIndex = 0;
Module.StartPosX = 0;
Module.StartPosY = 0;
Module.CurrentPosX = 0;
Module.CurrentPosY = 0;
Module.CurrentPosZ = 0;
Module.CurrentVelocityX = 0;
Module.CurrentVelocityY = 0;

local animation_frame = {
    SWIM_RIGHT_1 = 1,
    SWIM_RIGHT_2 = 2,
    SWIM_RIGHT_3 = 3,
    SWIM_RIGHT_4 = 4,

    TURN_RIGHT_1 = 5,
    TURN_RIGHT_2 = 6,
    TURN_RIGHT_3 = 7,

    SWIM_LEFT_1 = 11,
    SWIM_LEFT_2 = 12,
    SWIM_LEFT_3 = 13,
    SWIM_LEFT_4 = 14,

    TURN_LEFT_1 = 15,
    TURN_LEFT_2 = 16,
    TURN_LEFT_3 = 17,
};
animation_frame = read_only.make_table_read_only(animation_frame);

local g_shark_mesh = nil;
local g_animation_mesh_indices = {};
local g_current_animation_frame_index;
local g_move_animation_frame_index = 0;
local g_move_animation_frame_counter = 0;
local g_turn_animation_frame_counter = 0;
local g_turn_animation_is_active = false;

local function PlayerMoving_(game_input)
    if game_input.move_left_action.is_pressed or game_input.move_right_action.is_pressed then
        return true;
    end

    if game_input.move_up_action.is_pressed or game_input.move_down_action.is_pressed then
        return true;
    end

    return false;
end

local function MoveShark_(game_input)
    local player_current_pos_x = Module.GameLogic.get_player_current_position_x();
    local player_current_pos_y = Module.GameLogic.get_player_current_position_y();

    if player_current_pos_y < Module.CurrentPosY and Module.CurrentVelocityY > -1.2 then
        Module.CurrentVelocityY = Module.CurrentVelocityY - 0.09;
    elseif player_current_pos_y > Module.CurrentPosY and Module.CurrentVelocityY < 1.2 then
        Module.CurrentVelocityY = Module.CurrentVelocityY + 0.09;
    end

    local shark_can_see_player = false;

    if player_current_pos_x < Module.CurrentPosX - 2 and Module.CurrentVelocityX < 0 then
        shark_can_see_player = true;
    end

    if player_current_pos_x > Module.CurrentPosX + 2 and Module.CurrentVelocityX > 0 then
        shark_can_see_player = true;
    end

    if PlayerMoving_(game_input) == 0 or player_current_pos_y > 113 then
        shark_can_see_player = false;
    end

    local iYSpeed;

    if Module.CurrentVelocityX > 0 then
        iYSpeed = Module.CurrentVelocityX * Module.CurrentVelocityY;
    else
        iYSpeed = (0 - Module.CurrentVelocityX) * Module.CurrentVelocityY;
    end

    if shark_can_see_player then
        Module.CurrentPosY = Module.CurrentPosY + iYSpeed;
    elseif player_current_pos_y < Module.CurrentPosY - 20 or player_current_pos_y > Module.CurrentPosY + 20 or player_current_pos_y > 114 then
        Module.CurrentPosY = Module.CurrentPosY + iYSpeed / 3;
    else
        Module.CurrentPosY = Module.CurrentPosY + iYSpeed / 10;
    end

    if Module.CurrentPosY < 12 then
        Module.CurrentPosY = 12;
    elseif Module.CurrentPosY > 113 then
        Module.CurrentPosY = 113;
    end

    if g_turn_animation_is_active then
        g_turn_animation_frame_counter = g_turn_animation_frame_counter + 1;

        if Module.CurrentVelocityX < 0 then
            if g_turn_animation_frame_counter < 5 then
                g_current_animation_frame_index = animation_frame.TURN_LEFT_1;
            elseif g_turn_animation_frame_counter < 10 then
                g_current_animation_frame_index = animation_frame.TURN_LEFT_2;
            elseif g_turn_animation_frame_counter < 15 then
                g_current_animation_frame_index = animation_frame.TURN_LEFT_3;
            else
                g_turn_animation_frame_counter = 0;
                g_turn_animation_is_active = false;
                Module.CurrentVelocityX = 0.1;
            end
        else
            if g_turn_animation_frame_counter < 5 then
                g_current_animation_frame_index = animation_frame.TURN_RIGHT_1;
            elseif g_turn_animation_frame_counter < 10 then
                g_current_animation_frame_index = animation_frame.TURN_RIGHT_2;
            elseif g_turn_animation_frame_counter < 15 then
                g_current_animation_frame_index = animation_frame.TURN_RIGHT_3;
            else
                g_turn_animation_frame_counter = 0;
                g_turn_animation_is_active = false;
                Module.CurrentVelocityX = -0.1;
            end
        end

        return 0;
    end

    Module.CurrentPosX = Module.CurrentPosX + Module.CurrentVelocityX;

    if Module.CurrentPosX > 120 then
        Module.CurrentVelocityX = Module.CurrentVelocityX - 0.05;

        if Module.CurrentVelocityX < 0.1 and Module.CurrentVelocityX > -0.1 then
            g_turn_animation_frame_counter = 1;
            g_turn_animation_is_active = true;
        end

        if Module.CurrentVelocityX < -1 then
            Module.CurrentVelocityX = -1;
        end
    end

    if Module.CurrentPosX < 33 then
        Module.CurrentVelocityX = Module.CurrentVelocityX + 0.05;

        if Module.CurrentVelocityX > -0.1 and Module.CurrentVelocityX < 0.1 then
            g_turn_animation_frame_counter = 1;
            g_turn_animation_is_active = true;
        end

        if Module.CurrentVelocityX > 1 then
            Module.CurrentVelocityX = 1;
        end
    end

    if Module.CurrentVelocityX > 0 then
        g_current_animation_frame_index = animation_frame.SWIM_RIGHT_1 + g_move_animation_frame_index;
    else
        g_current_animation_frame_index = animation_frame.SWIM_LEFT_1 + g_move_animation_frame_index;
    end
end

function Module.initialize()
    g_animation_mesh_indices[animation_frame.SWIM_RIGHT_1] = Module.MoveRightMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.SWIM_RIGHT_2] = Module.MoveRightMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.SWIM_RIGHT_3] = Module.MoveRightMeshResourceIndices[3];
    g_animation_mesh_indices[animation_frame.SWIM_RIGHT_4] = Module.MoveRightMeshResourceIndices[4];

    g_animation_mesh_indices[animation_frame.TURN_RIGHT_1] = Module.TurnRightMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.TURN_RIGHT_2] = Module.TurnRightMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.TURN_RIGHT_3] = Module.TurnRightMeshResourceIndices[3];

    g_animation_mesh_indices[animation_frame.SWIM_LEFT_1] = Module.MoveLeftMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.SWIM_LEFT_2] = Module.MoveLeftMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.SWIM_LEFT_3] = Module.MoveLeftMeshResourceIndices[3];
    g_animation_mesh_indices[animation_frame.SWIM_LEFT_4] = Module.MoveLeftMeshResourceIndices[4];

    g_animation_mesh_indices[animation_frame.TURN_LEFT_1] = Module.TurnLeftMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.TURN_LEFT_2] = Module.TurnLeftMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.TURN_LEFT_3] = Module.TurnLeftMeshResourceIndices[3];

    g_shark_mesh = new_mesh(g_animation_mesh_indices[animation_frame.SWIM_RIGHT_1]);
    set_mesh_texture(g_shark_mesh, Module.TextureResourceIndex);
    set_mesh_is_visible(g_shark_mesh, true);

    Module.CurrentPosX = Module.StartPosX;
    Module.CurrentPosY = Module.StartPosY;
    Module.CurrentPosZ = 0.05;
    Module.CurrentVelocityX = 1;
    g_current_animation_frame_index = animation_frame.SWIM_RIGHT_1;
end

function Module.update(game_input)
    g_move_animation_frame_counter = g_move_animation_frame_counter + 1;

    if g_move_animation_frame_counter == 4 then
        g_move_animation_frame_index = g_move_animation_frame_index + 1;

        if g_move_animation_frame_index == 4 then
            g_move_animation_frame_index = 0;
        end

        g_move_animation_frame_counter = 0;
    end

    MoveShark_(game_input);

    set_mesh_to_mesh(g_shark_mesh, g_animation_mesh_indices[g_current_animation_frame_index]);
    set_identity_mesh_matrix(g_shark_mesh);
    translate_mesh_matrix(g_shark_mesh, Module.CurrentPosX, Module.CurrentPosY + 6, Module.CurrentPosZ);
end

return Module;
