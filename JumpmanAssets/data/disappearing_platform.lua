local read_only = require "data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.PlatformIndex = 0;
Module.GoodColorTextureResourceIndex = 0;
Module.BadColorTextureResourceIndex = 0;

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

local g_platform = nil;
local g_platform_transform_index = -1;

local g_original_pos_z = 0;
local g_current_pos_offset_z = 0;

local g_current_state = 1;  -- TODO: Use enums for these states
local g_current_move_direction = 0;  -- TODO: Use enums for these states
local g_animation_frame_count = 0;

local function CheckForPlayer_()
    g_current_state = 1;

    local player_platform_index = Module.GameLogic.get_player_current_active_platform_index();

    if player_platform_index == g_platform.index then
        if Module.GameLogic.get_player_current_state() == player_state.JSLADDER then
            return;
        end

        if Module.GameLogic.get_player_current_state() == player_state.JSVINE then
            return;
        end

        g_current_state = 2;
    end
end

local function Progress_()
    if g_current_move_direction == 0 then
        g_current_pos_offset_z = 0;

        if g_current_state == 2 then
            g_current_move_direction = 1;
            g_animation_frame_count = 0;
        end
    end

    if g_current_move_direction == 1 then
        g_animation_frame_count = g_animation_frame_count + 1;
        g_current_pos_offset_z = g_animation_frame_count * 10 / 100;

        if g_animation_frame_count == 100 then
            g_current_move_direction = 2;
            g_animation_frame_count = 0;
        end
    end

    if g_current_move_direction == 2 then
        g_animation_frame_count = g_animation_frame_count + 1;
        g_current_pos_offset_z = 10;

        if g_animation_frame_count == 50 then
            g_current_move_direction = 3;
            g_animation_frame_count = 100;
        end
    end

    if g_current_move_direction == 3 then
        g_animation_frame_count = g_animation_frame_count - 1;
        g_current_pos_offset_z = g_animation_frame_count * 10 / 100;

        if g_animation_frame_count == 0 then
            g_current_move_direction = 0;
            g_animation_frame_count = 0;
        end
    end
end

local function DrawStatus_()
    g_platform.set_pos_z(g_original_pos_z + g_current_pos_offset_z);

    if g_original_pos_z + g_current_pos_offset_z > 10 and g_platform.pos_upper_left[2] > 0 then
        g_platform.set_pos_y(-g_platform.pos_lower_right[2], -g_platform.pos_upper_left[2]);
    end

    if g_original_pos_z + g_current_pos_offset_z < 10 and g_platform.pos_upper_left[2] < 0 then
        g_platform.set_pos_y(-g_platform.pos_lower_right[2], -g_platform.pos_upper_left[2]);
    end

    transform_set_translation(g_platform_transform_index, 0, 0, g_current_pos_offset_z);

    if g_current_move_direction == 0 then
        set_mesh_texture(g_platform.mesh_index, Module.GoodColorTextureResourceIndex);
    else
        set_mesh_texture(g_platform.mesh_index, Module.BadColorTextureResourceIndex);
    end
end

function Module.initialize()
    g_platform = Module.GameLogic.get_platform(Module.PlatformIndex);
    g_platform_transform_index = transform_create();
    object_set_transform(g_platform.mesh_index, g_platform_transform_index);
    g_original_pos_z = g_platform.pos_z;
end

function Module.update()
    if g_current_state ~= 0 then
        CheckForPlayer_();
        Progress_();
        DrawStatus_();
    end
end

return Module;
