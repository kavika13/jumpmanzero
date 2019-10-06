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

    local is_player_visible = false;  -- TODO: Is this the right variable name?

    if player_current_pos_x < Module.CurrentPosX - 2 and Module.CurrentVelocityX < 0 then
        is_player_visible = true;
    end

    if player_current_pos_x > Module.CurrentPosX + 2 and Module.CurrentVelocityX > 0 then
        is_player_visible = true;
    end

    if PlayerMoving_(game_input) == 0 or player_current_pos_y > 113 then
        is_player_visible = false;
    end

    local iYSpeed;

    if Module.CurrentVelocityX > 0 then
        iYSpeed = Module.CurrentVelocityX * Module.CurrentVelocityY;
    else
        iYSpeed = (0 - Module.CurrentVelocityX) * Module.CurrentVelocityY;
    end

    if is_player_visible then
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
                g_current_animation_frame_index = 15;
            elseif g_turn_animation_frame_counter < 10 then
                g_current_animation_frame_index = 16;
            elseif g_turn_animation_frame_counter < 15 then
                g_current_animation_frame_index = 17;
            else
                g_turn_animation_frame_counter = 0;
                g_turn_animation_is_active = false;
                Module.CurrentVelocityX = 0.1;
            end
        else
            if g_turn_animation_frame_counter < 5 then
                g_current_animation_frame_index = 5;
            elseif g_turn_animation_frame_counter < 10 then
                g_current_animation_frame_index = 6;
            elseif g_turn_animation_frame_counter < 15 then
                g_current_animation_frame_index = 7;
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
        g_current_animation_frame_index = 1 + g_move_animation_frame_index;
    else
        g_current_animation_frame_index = 11 + g_move_animation_frame_index;
    end
end

function Module.initialize()
    g_animation_mesh_indices[1] = new_mesh(Module.MoveRightMeshResourceIndices[1]);
    move_mesh_to_front(g_animation_mesh_indices[1]);
    g_animation_mesh_indices[2] = new_mesh(Module.MoveRightMeshResourceIndices[2]);
    move_mesh_to_front(g_animation_mesh_indices[2]);
    g_animation_mesh_indices[3] = new_mesh(Module.MoveRightMeshResourceIndices[3]);
    move_mesh_to_front(g_animation_mesh_indices[3]);
    g_animation_mesh_indices[4] = new_mesh(Module.MoveRightMeshResourceIndices[4]);
    move_mesh_to_front(g_animation_mesh_indices[4]);

    g_animation_mesh_indices[5] = new_mesh(Module.TurnRightMeshResourceIndices[1]);
    move_mesh_to_front(g_animation_mesh_indices[5]);
    g_animation_mesh_indices[6] = new_mesh(Module.TurnRightMeshResourceIndices[2]);
    move_mesh_to_front(g_animation_mesh_indices[6]);
    g_animation_mesh_indices[7] = new_mesh(Module.TurnRightMeshResourceIndices[3]);
    move_mesh_to_front(g_animation_mesh_indices[7]);

    g_animation_mesh_indices[11] = new_mesh(Module.MoveLeftMeshResourceIndices[1]);
    move_mesh_to_front(g_animation_mesh_indices[11]);
    g_animation_mesh_indices[12] = new_mesh(Module.MoveLeftMeshResourceIndices[2]);
    move_mesh_to_front(g_animation_mesh_indices[12]);
    g_animation_mesh_indices[13] = new_mesh(Module.MoveLeftMeshResourceIndices[3]);
    move_mesh_to_front(g_animation_mesh_indices[13]);
    g_animation_mesh_indices[14] = new_mesh(Module.MoveLeftMeshResourceIndices[4]);
    move_mesh_to_front(g_animation_mesh_indices[14]);

    g_animation_mesh_indices[15] = new_mesh(Module.TurnLeftMeshResourceIndices[1]);
    move_mesh_to_front(g_animation_mesh_indices[15]);
    g_animation_mesh_indices[16] = new_mesh(Module.TurnLeftMeshResourceIndices[2]);
    move_mesh_to_front(g_animation_mesh_indices[16]);
    g_animation_mesh_indices[17] = new_mesh(Module.TurnLeftMeshResourceIndices[3]);
    move_mesh_to_front(g_animation_mesh_indices[17]);

    Module.CurrentPosX = Module.StartPosX;
    Module.CurrentPosY = Module.StartPosY;
    Module.CurrentPosZ = 0.05;
    Module.CurrentVelocityX = 1;
    g_current_animation_frame_index = 1;
end

function Module.update(game_input)
    -- TODO: Animate through changemesh, instead of set_texture_and_is_visible_on_mesh?
    select_object_mesh(g_animation_mesh_indices[g_current_animation_frame_index]);  -- Previous frame
    set_texture_and_is_visible_on_mesh(g_animation_mesh_indices[g_current_animation_frame_index], 0, 0);

    g_move_animation_frame_counter = g_move_animation_frame_counter + 1;

    if g_move_animation_frame_counter == 4 then
        g_move_animation_frame_index = g_move_animation_frame_index + 1;

        if g_move_animation_frame_index == 4 then
            g_move_animation_frame_index = 0;
        end

        g_move_animation_frame_counter = 0;
    end

    MoveShark_(game_input);

    local anim_mesh_index = g_animation_mesh_indices[g_current_animation_frame_index];
    select_object_mesh(anim_mesh_index);
    set_identity_mesh_matrix(anim_mesh_index);
    translate_mesh_matrix(anim_mesh_index, Module.CurrentPosX, Module.CurrentPosY + 6, Module.CurrentPosZ);
    set_texture_and_is_visible_on_mesh(anim_mesh_index, Module.TextureResourceIndex, 1);
end

return Module;
