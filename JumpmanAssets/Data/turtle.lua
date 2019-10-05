local read_only = require "Data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.MoveRightMeshResourceIndices = {};
Module.MoveLeftMeshResourceIndices = {};
Module.HideMeshResourceIndices = {};
Module.TextureResourceIndex = 0;
Module.InitialPosX = 0;
Module.InitialPosY = 0;

local status_type = {
    MOVE_LEFT = 3,
    MOVE_RIGHT = 4,
    HIDE_LEFT = 1,
    HIDE_RIGHT = 2,
};
status_type = read_only.make_table_read_only(status_type);

local animation_frame = {
    MOVE_RIGHT_1 = 0,
    MOVE_RIGHT_2 = 1,
    MOVE_LEFT_1 = 10,
    MOVE_LEFT_2 = 11,
    HIDE_LEFT = 5,
    HIDE_RIGHT = 6,  -- TODO: Possibly should be renamed hide-partial-recovery? For some reason when moving right, sets this temporarily? But then I think it immediately gets overwritten anyway. Might want to implement a slow-mo to test this sort of thing.
};
animation_frame = read_only.make_table_read_only(animation_frame);

-- TODO: Move this into a shared file, split into separate tables by type. Or inject from engine?
local player_state = {
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
    JSVINE = 1024,
};
player_state = read_only.make_table_read_only(player_state);

-- TODO: Move this into a shared file, split into separate tables by type
local player_movement_direction = {
    DIR_UP = 1,
    DIR_DOWN = 2,
    DIR_LEFT = 3,
    DIR_RIGHT = 4,
};
player_movement_direction = read_only.make_table_read_only(player_movement_direction);

local g_move_animation_frames = {};
local g_move_animation_current_frame = 0;
local g_move_animation_current_alt_frame = 0;  -- Alternates between 0 and 1. Offset applied to current frame
local g_move_animation_counter = 0;  -- Counts up until the next alt frame

local g_current_pos_x = 0;
local g_current_pos_y = 0;
local g_current_rotation_z = 0;

local g_current_status = status_type.MOVE_LEFT;
local g_current_status_counter = 0;

local function SetAngle_()
    local iHit1, _ = Module.GameLogic.find_platform(g_current_pos_x - 5, g_current_pos_y, 7, 2);
    local iHit2, _ = Module.GameLogic.find_platform(g_current_pos_x + 5, g_current_pos_y, 7, 2);
    g_current_rotation_z = math.atan(iHit2 - iHit1, 14) * 180.0 / math.pi;
end

local function CheckCollide_(all_turtles)
    for _, other_turtle in ipairs(all_turtles) do
        if other_turtle ~= Module then
            local other_pos_x, other_pos_y = other_turtle.get_current_pos();

            if other_pos_x < g_current_pos_x + 10 and other_pos_x > g_current_pos_x - 10 then
                if other_pos_y < g_current_pos_y + 10 and other_pos_y > g_current_pos_y - 10 then
                    if other_pos_x > g_current_pos_x then
                        g_current_status = status_type.MOVE_LEFT;
                    else
                        g_current_status = status_type.MOVE_RIGHT;
                    end
                end
            end
        end
    end
end

local function Move_(all_turtles)
    if g_current_status == status_type.MOVE_LEFT or g_current_status == status_type.MOVE_RIGHT then
        local iHit, iPlat = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y, 5, 2);

        if iHit < g_current_pos_y - 1 then
            g_current_pos_y = g_current_pos_y - 1;
        elseif iHit > g_current_pos_y + 1 then
            g_current_pos_y = g_current_pos_y + 1;
        else
            g_current_pos_y = iHit;
        end
    end

    if g_current_status == status_type.MOVE_LEFT then
        g_current_pos_x = g_current_pos_x - 0.25;
        local iHit, iPlat = Module.GameLogic.find_platform(g_current_pos_x - 7, g_current_pos_y, 5, 2);

        if iHit < g_current_pos_y - 6 then
            g_current_status = status_type.MOVE_RIGHT;
            g_current_status_counter = 0;
        end

        CheckCollide_(all_turtles);
    end

    if g_current_status == status_type.MOVE_RIGHT then
        g_current_pos_x = g_current_pos_x + 0.25;
        local iHit, iPlat = Module.GameLogic.find_platform(g_current_pos_x + 7, g_current_pos_y, 5, 2);

        if iHit < g_current_pos_y - 6 then
            g_current_status = status_type.MOVE_LEFT;
            g_current_status_counter = 0;
        end

        CheckCollide_(all_turtles);
    end
end

local function SetFrame_()
    g_current_status_counter = g_current_status_counter + 1;

    if g_current_status == status_type.MOVE_LEFT then
        g_move_animation_current_frame = animation_frame.MOVE_LEFT_1 + g_move_animation_current_alt_frame;
    end

    if g_current_status == status_type.MOVE_RIGHT then
        g_move_animation_current_frame = animation_frame.MOVE_RIGHT_1 + g_move_animation_current_alt_frame;
    end

    if g_current_status == status_type.HIDE_LEFT or g_current_status == status_type.HIDE_RIGHT then
        g_current_status_counter = g_current_status_counter + 1;
        g_move_animation_current_frame = animation_frame.HIDE_RIGHT;

        if g_current_status_counter < 8 or g_current_status_counter > 280 then
            g_move_animation_current_frame = animation_frame.HIDE_LEFT;
        end

        if g_current_status_counter > 300 then
            if g_current_status == status_type.HIDE_LEFT then
                g_current_status = status_type.MOVE_LEFT;
            else
                g_current_status = status_type.MOVE_RIGHT;
            end
        end
    end
end

local function Animate_()
    g_move_animation_counter = g_move_animation_counter + 1;

    if g_move_animation_counter > 5 then
        g_move_animation_counter = 0;
        g_move_animation_current_alt_frame = g_move_animation_current_alt_frame + 1;

        if g_move_animation_current_alt_frame > 1 then
            g_move_animation_current_alt_frame = 0;
        end
    end
end

function Module.initialize()
    g_current_pos_x = Module.InitialPosX;
    g_current_pos_y = Module.InitialPosY;
    g_current_status = status_type.MOVE_LEFT;
    g_current_status_counter = 0;

    g_move_animation_frames[animation_frame.MOVE_RIGHT_1] = new_mesh(Module.MoveRightMeshResourceIndices[1]);
    g_move_animation_frames[animation_frame.MOVE_RIGHT_2] = new_mesh(Module.MoveRightMeshResourceIndices[2]);

    g_move_animation_frames[animation_frame.MOVE_LEFT_1] = new_mesh(Module.MoveLeftMeshResourceIndices[1]);
    g_move_animation_frames[animation_frame.MOVE_LEFT_2] = new_mesh(Module.MoveLeftMeshResourceIndices[2]);

    g_move_animation_frames[animation_frame.HIDE_LEFT] = new_mesh(Module.HideMeshResourceIndices[1]);
    g_move_animation_frames[animation_frame.HIDE_RIGHT] = new_mesh(Module.HideMeshResourceIndices[2]);
end

function Module.update(game_input, all_turtles)
    select_object_mesh(g_move_animation_frames[g_move_animation_current_frame]);
    set_object_visual_data(0, 0);

    Animate_();
    SetFrame_();
    Move_(all_turtles);
    SetAngle_();

    select_object_mesh(g_move_animation_frames[g_move_animation_current_frame]);
    set_identity_mesh_matrix(g_move_animation_frames[g_move_animation_current_frame]);
    script_selected_mesh_rotate_matrix_z(g_current_rotation_z);
    script_selected_mesh_translate_matrix(g_current_pos_x, g_current_pos_y + 4.4, 2);
    set_object_visual_data(Module.TextureResourceIndex, 2);

    local is_colliding = true;

    local iPX = Module.GameLogic.get_player_current_position_x();
    local iPY = Module.GameLogic.get_player_current_position_y();
    local iPStat = Module.GameLogic.get_player_current_state();

    if iPStat & player_state.JSDYING ~= 0 then
        is_colliding = false;
    elseif iPY < g_current_pos_y + 2 and g_current_status == status_type.MOVE_LEFT then
        is_colliding = Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 4, g_current_pos_y,
            g_current_pos_x, g_current_pos_y + 4);
    elseif iPY < g_current_pos_y + 2 and g_current_status == status_type.MOVE_RIGHT then
        is_colliding = Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x, g_current_pos_y,
            g_current_pos_x + 4, g_current_pos_y + 4);
    else
        is_colliding = Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 6, g_current_pos_y,
            g_current_pos_x + 6, g_current_pos_y + 10);
    end

    if iPY > g_current_pos_y + 4 then
        is_colliding = false;
    end

    if g_current_status == status_type.HIDE_LEFT or g_current_status == status_type.HIDE_RIGHT then
        is_colliding = false;
    end

    if is_colliding then
        if iPY < g_current_pos_y + 2 then
            Module.GameLogic.kill();
        else
            g_current_status_counter = 0;

            if game_input.move_left_action.is_pressed then
                Module.GameLogic.set_player_current_state(player_state.JSJUMPING);
                Module.GameLogic.set_player_current_direction(player_movement_direction.DIR_LEFT);
            elseif game_input.move_right_action.is_pressed then
                Module.GameLogic.set_player_current_state(player_state.JSJUMPING);
                Module.GameLogic.set_player_current_direction(player_movement_direction.DIR_RIGHT);
            else
                Module.GameLogic.set_player_current_state(player_state.JSJUMPING);
                Module.GameLogic.set_player_current_direction(player_movement_direction.DIR_UP);
            end

            Module.GameLogic.set_player_current_state_frame_count(0);
            Module.GameLogic.set_player_no_roll_cooldown_frame_count(10);

            if g_current_status == status_type.MOVE_LEFT then
                g_current_status = status_type.HIDE_LEFT;
            else
                g_current_status = status_type.HIDE_RIGHT;
            end
        end
    end
end

function Module.get_current_pos()
    return g_current_pos_x, g_current_pos_y;
end

return Module;
