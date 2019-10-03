local Module = {};

Module.GameLogic = nil;

Module.MoveLeftMeshResourceIndices = {};
Module.MoveRightMeshResourceIndices = {};
Module.TextureResourceIndex = 0;
Module.BuzzSoundResourceIndex = 0;

local g_is_initialized = false;

-- TODO: Split left and right animations?
local g_move_animation_mesh_indices = {};
local g_move_animation_current_frame_index = 0;
local g_move_animation_counter = 0;

local g_current_pos_x = 0;
local g_current_pos_y = 0;
local g_current_velocity_x = 0;
local g_current_velocity_y = 0;

local g_vision_strength = 0;  -- TODO: Is this value inverted from how it is currently named?

local function Abs(iNum)
    if iNum < 0 then
        return 0 - iNum;
    end

    return iNum;
end

local function MoveBee()
    g_current_pos_x = g_current_pos_x + g_current_velocity_x * 3 / 4;
    g_current_pos_y = g_current_pos_y + g_current_velocity_y * 5 / 8;

    local iPX = get_player_current_position_x();
    local iPY = get_player_current_position_y();

    if g_current_pos_x < iPX - 110 then
        g_current_pos_x = iPX + 110;
    elseif g_current_pos_x > iPX + 110 then
        g_current_pos_x = iPX - 110;
    end

    if g_current_pos_y < iPY - 110 then
        g_current_pos_y = iPY + 110;
    elseif g_current_pos_y > iPY + 110 then
        g_current_pos_y = iPY - 110;
    end

    if g_current_velocity_x == 0 then
        g_current_pos_x = g_current_pos_x + 0.5 - math.random(0, 10) / 10;
    end

    if g_current_velocity_y == 0 and Abs(iPX - g_current_pos_x) > 5 then
        g_current_pos_y = g_current_pos_y + 0.5 - math.random(0, 10) / 10;
    end

    if Abs(iPY - g_current_pos_y) < 1 and Abs(iPX - g_current_pos_x) > g_vision_strength and math.random(1, 20) > 7 then
        g_current_velocity_y = 0;

        if iPX < g_current_pos_x then
            g_current_velocity_x = -1;
        else
            g_current_velocity_x = 1;
        end
    end

    if Abs(iPX - g_current_pos_x) < 1 and Abs(iPY - g_current_pos_y) > g_vision_strength and math.random(1, 20) > 7 then
        g_current_velocity_x = 0;

        if iPY < g_current_pos_y then
            g_current_velocity_y = -1;
        else
            g_current_velocity_y = 1;
        end
    end
end

function Module.update()
    if not g_is_initialized then
        g_is_initialized = true;
        g_move_animation_mesh_indices[0] = new_mesh(Module.MoveLeftMeshResourceIndices[1]);
        g_move_animation_mesh_indices[1] = new_mesh(Module.MoveLeftMeshResourceIndices[2]);
        g_move_animation_mesh_indices[2] = new_mesh(Module.MoveRightMeshResourceIndices[1]);
        g_move_animation_mesh_indices[3] = new_mesh(Module.MoveRightMeshResourceIndices[2]);
        g_current_pos_x = get_player_current_position_x() + 100;
        g_current_pos_y = get_player_current_position_y();
        g_current_velocity_x = -1;
        g_current_velocity_y = 0;
        g_vision_strength = math.random(15, 30);
    end

    select_object_mesh(g_move_animation_mesh_indices[g_move_animation_current_frame_index]);
    set_object_visual_data(0, 0);

    MoveBee();

    g_move_animation_counter = g_move_animation_counter + 1;

    if g_move_animation_counter == 4 then
        g_move_animation_counter = 0;
    end

    if g_current_velocity_x < 0 or (g_current_velocity_x == 0 and get_player_current_position_x() < g_current_pos_x) then
        g_move_animation_current_frame_index = (g_move_animation_counter < 2 and 1 or 0) + 2;
    else
        g_move_animation_current_frame_index = g_move_animation_counter < 2 and 1 or 0;
    end

    select_object_mesh(g_move_animation_mesh_indices[g_move_animation_current_frame_index]);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(g_current_pos_x, g_current_pos_y + 6, 0);
    set_object_visual_data(Module.TextureResourceIndex, 1);

    if Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 3, g_current_pos_y + 5,
            g_current_pos_x + 3, g_current_pos_y + 7) then
        play_sound_effect(Module.BuzzSoundResourceIndex);
        Module.GameLogic.kill();
    end
end

function Module.reset_pos()
    if g_current_pos_y < 120 then
        g_current_pos_y = 120;
    end
end

return Module;
