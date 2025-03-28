local Module = {};

Module.GameLogic = nil;

Module.DropMeshResourceIndex = 0;
Module.DropTextureResourceIndices = {};

Module.IsTooCloseToOtherDropsCallback = nil;
Module.FramesToWait = 0;

local g_frames_to_wait_before_start = 0;

local g_drop_1_mesh_index = -1;
local g_drop_1_transform_index = -1;
local g_drop_2_mesh_index = -1;
local g_drop_2_transform_index = -1;

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
    skip_next_mesh_interpolation(g_drop_1_mesh_index);
    skip_next_mesh_interpolation(g_drop_2_mesh_index);
end

function Module.initialize()
    -- TODO: Use meshes instead of textures
    g_drop_1_mesh_index = new_mesh(Module.DropMeshResourceIndex);
    g_drop_1_transform_index = transform_create();
    mesh_set_transform(g_drop_1_mesh_index, g_drop_1_transform_index);
    g_drop_2_mesh_index = new_mesh(Module.DropMeshResourceIndex);

    g_drop_2_transform_index = transform_create();
    mesh_set_transform(g_drop_2_mesh_index, g_drop_2_transform_index);
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
        local iPlatZ = Module.GameLogic.get_platform(platform_index).pos_z;

        if iHit + 8 > g_current_pos_y and iPlatZ < 11 then
            g_animation_frame = 1;
        end

        -- TODO: Use meshes instead of textures for animation. Only need to draw once in that case
        transform_set_translation(g_drop_1_transform_index, g_current_pos_x, g_current_pos_y, 8);
        set_mesh_texture(g_drop_1_mesh_index, Module.DropTextureResourceIndices[1]);
        set_mesh_is_visible(g_drop_1_mesh_index, true);

        transform_set_translation(g_drop_2_transform_index, g_current_pos_x, g_current_pos_y, 9);
        set_mesh_texture(g_drop_2_mesh_index, Module.DropTextureResourceIndices[1]);
        set_mesh_is_visible(g_drop_2_mesh_index, true);
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

        transform_set_translation(g_drop_1_transform_index, g_current_pos_x, g_current_pos_y, 8);
        set_mesh_texture(g_drop_1_mesh_index, Module.DropTextureResourceIndices[1 + g_animation_frame]);
        set_mesh_is_visible(g_drop_1_mesh_index, true);

        transform_set_translation(g_drop_2_transform_index, g_current_pos_x, g_current_pos_y, 9);
        set_mesh_texture(g_drop_2_mesh_index, Module.DropTextureResourceIndices[1 + g_animation_frame]);
        set_mesh_is_visible(g_drop_2_mesh_index, true);
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
