local Module = {};

Module.GameLogic = nil;

Module.DropMeshResourceIndex = 0;
Module.DropTextureResourceIndices = {};

Module.IsTooCloseToOtherDropsCallback = nil;
Module.FramesToWait = 0;

local g_is_initialized = false;

local g_frames_to_wait_before_start = 0;

local g_drop_1_mesh_index;
local g_drop_2_mesh_index;

local g_current_pos_x = 0;
local g_current_pos_y = 0;

local g_animation_frame = 0;
local g_animation_timer = 0;

local function ResetMyPos()
    local is_done = false;
    local object_count = get_script_object_count();

    g_current_pos_x = get_player_current_position_x();
    g_current_pos_y = 0;

    while not is_done do
        g_current_pos_x = g_current_pos_x + math.random(0, 60) - 30;

        if g_current_pos_x > 150 then
            g_current_pos_x = 150;
        end

        if g_current_pos_x < 10 then
            g_current_pos_x = 10;
        end

        is_done = not (Module.IsTooCloseToOtherDropsCallback and Module.IsTooCloseToOtherDropsCallback(Module));
    end

    g_current_pos_y = 220;
    g_animation_frame = 0;
    g_animation_timer = 0;
end

function Module.update()
    if not g_is_initialized then
        g_is_initialized = true;
        g_drop_2_mesh_index = new_mesh(Module.DropMeshResourceIndex);
        g_drop_1_mesh_index = new_mesh(Module.DropMeshResourceIndex);
        g_frames_to_wait_before_start = Module.FramesToWait;
        ResetMyPos();
    end

    if g_frames_to_wait_before_start > 0 then
        g_frames_to_wait_before_start = g_frames_to_wait_before_start - 1;
        return;
    end

    if g_animation_frame == 0 then
        g_current_pos_y = g_current_pos_y - 0.55;
        local iHit, iPlat = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y + 5, 8, 3);
        abs_platform(iPlat);
        local iPlatZ = get_script_selected_level_object_z1();

        if iHit + 8 > g_current_pos_y and iPlatZ < 11 then
            g_animation_frame = 1;
        end

        select_object_mesh(g_drop_1_mesh_index);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_translate_matrix(g_current_pos_x, g_current_pos_y, 8);
        set_object_visual_data(Module.DropTextureResourceIndices[1], 1);

        select_object_mesh(g_drop_2_mesh_index);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_translate_matrix(g_current_pos_x, g_current_pos_y, 9);
        set_object_visual_data(Module.DropTextureResourceIndices[1], 1);
    end

    if g_animation_frame > 0 then
        g_animation_timer = g_animation_timer + 1;

        if g_animation_timer > 4 then
            g_animation_timer = 0;
            g_animation_frame = g_animation_frame + 1;
        end

        if g_animation_frame > 3 then
            ResetMyPos();
        end

        select_object_mesh(g_drop_1_mesh_index);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_translate_matrix(g_current_pos_x, g_current_pos_y, 8);
        set_object_visual_data(Module.DropTextureResourceIndices[1 + g_animation_frame], 1);

        select_object_mesh(g_drop_2_mesh_index);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_translate_matrix(g_current_pos_x, g_current_pos_y, 9);
        set_object_visual_data(Module.DropTextureResourceIndices[1 + g_animation_frame], 1);
    end

    if g_animation_frame < 1 then
        if Module.GameLogic.is_player_colliding_with_rect(
                g_current_pos_x - 3, g_current_pos_y - 6,
                g_current_pos_x + 3, g_current_pos_y) then
            kill();
        end
    end
end

function Module.get_current_pos_x()
    return g_current_pos_x;
end

function Module.get_current_pos_y()
    return g_current_pos_y;
end

return Module;
