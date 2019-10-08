local Module = {};

Module.GameLogic = nil;

Module.DropMeshResourceIndex = 0;
Module.DropTextureResourceIndices = {};

Module.IsTooCloseToOtherDropsCallback = nil;
Module.FramesToWait = 0;

local g_frames_to_wait_before_start = 0;

local g_drop_1_mesh_index;
local g_drop_2_mesh_index;

local g_current_pos_x = 0;
local g_current_pos_y = 0;

local g_animation_frame = 0;
local g_animation_timer = 0;

local function ResetMyPos_()
    local is_done = false;

    g_current_pos_x = Module.GameLogic.get_player_current_position_x();
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

function Module.initialize()
    g_drop_2_mesh_index = new_mesh(Module.DropMeshResourceIndex);
    g_drop_1_mesh_index = new_mesh(Module.DropMeshResourceIndex);
    g_frames_to_wait_before_start = Module.FramesToWait;
    ResetMyPos_();
end

function Module.update()
    if g_frames_to_wait_before_start > 0 then
        g_frames_to_wait_before_start = g_frames_to_wait_before_start - 1;
        return;
    end

    if g_animation_frame == 0 then
        g_current_pos_y = g_current_pos_y - 0.55;
        local iHit, platform_index = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y + 5, 8, 3);
        local iPlatZ = get_platform_z1(platform_index);

        if iHit + 8 > g_current_pos_y and iPlatZ < 11 then
            g_animation_frame = 1;
        end

        set_identity_mesh_matrix(g_drop_1_mesh_index);
        translate_mesh_matrix(g_drop_1_mesh_index, g_current_pos_x, g_current_pos_y, 8);
        set_texture_and_is_visible_on_mesh(g_drop_1_mesh_index, Module.DropTextureResourceIndices[1], 1);

        set_identity_mesh_matrix(g_drop_2_mesh_index);
        translate_mesh_matrix(g_drop_2_mesh_index, g_current_pos_x, g_current_pos_y, 9);
        set_texture_and_is_visible_on_mesh(g_drop_2_mesh_index, Module.DropTextureResourceIndices[1], 1);
    end

    if g_animation_frame > 0 then
        g_animation_timer = g_animation_timer + 1;

        if g_animation_timer > 4 then
            g_animation_timer = 0;
            g_animation_frame = g_animation_frame + 1;
        end

        if g_animation_frame > 3 then
            ResetMyPos_();
        end

        set_identity_mesh_matrix(g_drop_1_mesh_index);
        translate_mesh_matrix(g_drop_1_mesh_index, g_current_pos_x, g_current_pos_y, 8);
        set_texture_and_is_visible_on_mesh(g_drop_1_mesh_index, Module.DropTextureResourceIndices[1 + g_animation_frame], 1);

        set_identity_mesh_matrix(g_drop_2_mesh_index);
        translate_mesh_matrix(g_drop_2_mesh_index, g_current_pos_x, g_current_pos_y, 9);
        set_texture_and_is_visible_on_mesh(g_drop_2_mesh_index, Module.DropTextureResourceIndices[1 + g_animation_frame], 1);
    end

    if g_animation_frame < 1 then
        if Module.GameLogic.is_player_colliding_with_rect(
                g_current_pos_x - 3, g_current_pos_y - 6,
                g_current_pos_x + 3, g_current_pos_y) then
            Module.GameLogic.kill();
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
