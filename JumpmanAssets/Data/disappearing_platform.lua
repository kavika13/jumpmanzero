local read_only = require "Data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.ObjectIndex = 0;
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

local g_original_pos_z = 0;
local g_current_pos_offset_z = 0;

local g_current_state = 1;  -- TODO: Use enums for these states
local g_current_move_direction = 0;  -- TODO: Use enums for these states
local g_animation_frame_count = 0;

local function CheckForPlayer_()
    g_current_state = 1;

    local iPlat = Module.GameLogic.get_player_current_active_platform_index();

    if iPlat == Module.ObjectIndex then
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
    abs_platform(Module.ObjectIndex);

    set_script_selected_level_object_z1(g_original_pos_z + g_current_pos_offset_z);

    if g_original_pos_z + g_current_pos_offset_z > 10 and get_script_selected_level_object_y1() > 0 then
        set_script_selected_level_object_y1(0 - get_script_selected_level_object_y1());
        set_script_selected_level_object_y2(0 - get_script_selected_level_object_y2());
    end

    if g_original_pos_z + g_current_pos_offset_z < 10 and get_script_selected_level_object_y1() < 0 then
        set_script_selected_level_object_y1(0 - get_script_selected_level_object_y1());
        set_script_selected_level_object_y2(0 - get_script_selected_level_object_y2());
    end

    local platform_mesh_index = get_platform_mesh_index(Module.ObjectIndex);
    set_identity_mesh_matrix(platform_mesh_index);
    translate_mesh_matrix(platform_mesh_index, 0, 0, g_current_pos_offset_z);

    if g_current_move_direction == 0 then
        set_texture_on_mesh(platform_mesh_index, Module.GoodColorTextureResourceIndex);
    else
        set_texture_on_mesh(platform_mesh_index, Module.BadColorTextureResourceIndex);
    end
end

function Module.initialize()
    abs_platform(Module.ObjectIndex);
    g_original_pos_z = get_script_selected_level_object_z1();
end

function Module.update()
    if g_current_state ~= 0 then
        CheckForPlayer_();
        Progress_();
        DrawStatus_();
    end
end

return Module;
