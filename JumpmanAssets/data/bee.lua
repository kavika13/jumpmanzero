local read_only = require "data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.MoveLeftMeshResourceIndices = {};
Module.MoveRightMeshResourceIndices = {};
Module.TextureResourceIndex = 0;
Module.BuzzSoundResourceIndex = 0;

local animation_frame = {
    MOVE_LEFT_1 = 0,
    MOVE_LEFT_2 = 1,
    MOVE_RIGHT_1 = 2,
    MOVE_RIGHT_2 = 3,
};
animation_frame = read_only.make_table_read_only(animation_frame);

local g_bee_mesh_index = nil;
local g_bee_transform_index = nil;
local g_move_animation_mesh_indices = {};
local g_move_animation_current_frame_index = animation_frame.MOVE_LEFT_1;
local g_move_animation_counter = 0;

local g_current_pos_x = 0;
local g_current_pos_y = 0;
local g_current_velocity_x = 0;
local g_current_velocity_y = 0;

local g_vision_strength = 0;  -- TODO: Is this value inverted from how it is currently named?

local function Abs_(iNum)
    if iNum < 0 then
        return 0 - iNum;
    end

    return iNum;
end

local function MoveBee_()
    g_current_pos_x = g_current_pos_x + g_current_velocity_x * 3 / 4;
    g_current_pos_y = g_current_pos_y + g_current_velocity_y * 5 / 8;

    local iPX = Module.GameLogic.get_player_current_position_x();
    local iPY = Module.GameLogic.get_player_current_position_y();

    if g_current_pos_x < iPX - 110 then
        g_current_pos_x = iPX + 110;
        skip_next_mesh_interpolation(g_bee_mesh_index);
    elseif g_current_pos_x > iPX + 110 then
        g_current_pos_x = iPX - 110;
        skip_next_mesh_interpolation(g_bee_mesh_index);
    end

    if g_current_pos_y < iPY - 110 then
        g_current_pos_y = iPY + 110;
        skip_next_mesh_interpolation(g_bee_mesh_index);
    elseif g_current_pos_y > iPY + 110 then
        g_current_pos_y = iPY - 110;
        skip_next_mesh_interpolation(g_bee_mesh_index);
    end

    if g_current_velocity_x == 0 then
        g_current_pos_x = g_current_pos_x + 0.5 - math.random(0, 10) / 10;
    end

    if g_current_velocity_y == 0 and Abs_(iPX - g_current_pos_x) > 5 then
        g_current_pos_y = g_current_pos_y + 0.5 - math.random(0, 10) / 10;
    end

    if Abs_(iPY - g_current_pos_y) < 1 and Abs_(iPX - g_current_pos_x) > g_vision_strength and math.random(1, 20) > 7 then
        g_current_velocity_y = 0;

        if iPX < g_current_pos_x then
            g_current_velocity_x = -1;
        else
            g_current_velocity_x = 1;
        end
    end

    if Abs_(iPX - g_current_pos_x) < 1 and Abs_(iPY - g_current_pos_y) > g_vision_strength and math.random(1, 20) > 7 then
        g_current_velocity_x = 0;

        if iPY < g_current_pos_y then
            g_current_velocity_y = -1;
        else
            g_current_velocity_y = 1;
        end
    end
end

function Module.initialize()
    g_move_animation_mesh_indices[animation_frame.MOVE_LEFT_1] = Module.MoveLeftMeshResourceIndices[1];
    g_move_animation_mesh_indices[animation_frame.MOVE_LEFT_2] = Module.MoveLeftMeshResourceIndices[2];
    g_move_animation_mesh_indices[animation_frame.MOVE_RIGHT_1] = Module.MoveRightMeshResourceIndices[1];
    g_move_animation_mesh_indices[animation_frame.MOVE_RIGHT_2] = Module.MoveRightMeshResourceIndices[2];

    local setup_object_transform = function(mesh_index)
        local result = transform_create();
        object_set_transform(mesh_index, result);
        return result;
    end

    g_bee_mesh_index = new_mesh(g_move_animation_mesh_indices[animation_frame.MOVE_LEFT_1]);
    g_bee_transform_index = setup_object_transform(g_bee_mesh_index);
    set_mesh_texture(g_bee_mesh_index, Module.TextureResourceIndex);
    set_mesh_is_visible(g_bee_mesh_index, true);

    g_current_pos_x = Module.GameLogic.get_player_current_position_x() + 100;
    g_current_pos_y = Module.GameLogic.get_player_current_position_y();
    g_current_velocity_x = -1;
    g_current_velocity_y = 0;
    g_vision_strength = math.random(15, 30);
end

function Module.update()
    MoveBee_();

    g_move_animation_counter = g_move_animation_counter + 1;

    if g_move_animation_counter == 4 then
        g_move_animation_counter = 0;
    end

    if g_current_velocity_x < 0 or (g_current_velocity_x == 0 and Module.GameLogic.get_player_current_position_x() < g_current_pos_x) then
        g_move_animation_current_frame_index = (g_move_animation_counter < 2 and 1 or 0) + 2;
    else
        g_move_animation_current_frame_index = g_move_animation_counter < 2 and 1 or 0;
    end

    set_mesh_to_mesh(g_bee_mesh_index, g_move_animation_mesh_indices[g_move_animation_current_frame_index]);
    transform_set_translation(g_bee_transform_index, g_current_pos_x, g_current_pos_y + 6, 0);

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
        skip_next_mesh_interpolation(g_bee_mesh_index);
    end
end

return Module;
