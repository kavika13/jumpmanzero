local Module = {};

Module.GameLogic = nil;

Module.StandMeshResourceIndex = 0;
Module.BackMeshResourceIndex = 0;
Module.MoveLeftMeshResourceIndices = {};
Module.MoveRightMeshResourceIndices = {};
Module.LadderClimbMeshResourceIndices = {};
Module.TextureResourceIndex = 0;

Module.CountOfTimesToPreAdvanceMovement = 0;

local g_animation_mesh_indices = {};
local g_animation_current_frame = 0;  -- TODO: Use constants instead of these hard-coded frame numbers
local g_animation_frame_counter = 0;  -- Counts up until the next "alt frame" increment (every 6 frames increments alt)
local g_animation_alt_frame_counter = 0;  -- On 1 or 3 switches to an alt frame in the current animation
local g_animation_movement_direction = 4;  -- Used to find the base animation frame. 1, 2 == "LC". 3 = left. 4 = right

local g_current_pos_x = 0;
local g_current_pos_y = 0;
local g_current_pos_z = 0;
local g_closeby_ladder_pos_z = 0;

local function CheckForChange_()
    if g_animation_movement_direction == 4 or g_animation_movement_direction == 3 then
        local _, ladder_index = Module.GameLogic.find_ladder(g_current_pos_x, g_current_pos_y);

        if ladder_index >= 0 then
            local current_ladder = Module.GameLogic.get_ladder(ladder_index);

            if g_current_pos_x == current_ladder.pos_x then
                g_closeby_ladder_pos_z = current_ladder.pos_z[1];
                local iSign = current_ladder.number;

                if iSign == 41 then  -- TODO: Use constant for num?
                    g_animation_movement_direction = 4;
                    current_ladder.set_number(14);  -- TODO: Use constant for num?
                    return;
                end

                if iSign == 14 then  -- TODO: Use constant for num?
                    g_animation_movement_direction = 1;
                    current_ladder.set_number(41);  -- TODO: Use constant for num?
                    return;
                end

                if iSign == 141 then  -- TODO: Use constant for num?
                    g_animation_movement_direction = 4;

                    if current_ladder.pos_y_bottom > g_current_pos_y - 5 then
                        g_animation_movement_direction = 1;
                    end

                    return;
                end

                g_animation_movement_direction = iSign;
                return;
            end
        end
    end

    if g_animation_movement_direction == 1 or g_animation_movement_direction == 2 then
        local iHit, platform_index = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y + 4, 4, 2);

        if iHit == g_current_pos_y then
            g_animation_movement_direction = get_platform_number(platform_index);
            return;
        end
    end
end

local function ProgressPenguin_()
    if g_animation_movement_direction == 1 then
        g_current_pos_y = g_current_pos_y + 0.5;
        g_animation_current_frame = 6;  -- TODO: Use constants instead of these hard-coded frame numbers
    end

    if g_animation_movement_direction == 2 then
        g_current_pos_y = g_current_pos_y - 0.5;
        g_animation_current_frame = 6;  -- TODO: Use constants instead of these hard-coded frame numbers
    end

    if g_animation_movement_direction == 3 then
        g_current_pos_x = g_current_pos_x - 0.5;
        g_animation_current_frame = 2;  -- TODO: Use constants instead of these hard-coded frame numbers
    end

    if g_animation_movement_direction == 4 then
        g_current_pos_x = g_current_pos_x + 0.5;
        g_animation_current_frame = 4;  -- TODO: Use constants instead of these hard-coded frame numbers
    end

    if g_animation_alt_frame_counter == 1 or g_animation_alt_frame_counter == 3 then
        g_animation_current_frame = g_animation_current_frame + 1;
    end
end

local function AdjustZ_(target_platform_index)
    local target_platform_pos_z = get_platform_z1(target_platform_index);

    if g_current_pos_z < target_platform_pos_z then
        g_current_pos_z = g_current_pos_z + 1;
    end

    if g_current_pos_z > target_platform_pos_z + 2 then
        g_current_pos_z = g_current_pos_z - 1;
    end
end

local function MovePenguin_()
    CheckForChange_();
    ProgressPenguin_();

    local iHit, iPlat = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y + 5, 4, 2);

    if g_animation_movement_direction == 3 or g_animation_movement_direction == 4 then
        if iHit < g_current_pos_y then
            g_current_pos_y = g_current_pos_y - 0.5;
        end

        if iHit > g_current_pos_y + 0.4 then
            g_current_pos_y = g_current_pos_y + 0.5;
        end
    end

    if g_animation_movement_direction == 1 or g_animation_movement_direction == 2 then
        g_current_pos_z = g_closeby_ladder_pos_z;
    else
        AdjustZ_(iPlat);
    end
end

local function AdvanceFrame_()
    g_animation_frame_counter = g_animation_frame_counter + 1;

    if g_animation_frame_counter > 5 then
        g_animation_frame_counter = 0;
        g_animation_alt_frame_counter = g_animation_alt_frame_counter + 1;

        if g_animation_alt_frame_counter > 3 then
            g_animation_alt_frame_counter = 0;
        end
    end
end

function Module.initialize()
    g_current_pos_x = 75;
    g_current_pos_y = 26;
    g_current_pos_z = 2;
    g_animation_movement_direction = 4;

    local counter = Module.CountOfTimesToPreAdvanceMovement;

    while counter > 0 do
        MovePenguin_();
        counter = counter - 1;
    end

    -- TODO: Use constants instead of these hard-coded frame numbers
    g_animation_mesh_indices[0] = new_mesh(Module.StandMeshResourceIndex);
    g_animation_mesh_indices[1] = new_mesh(Module.BackMeshResourceIndex);

    g_animation_mesh_indices[2] = new_mesh(Module.MoveLeftMeshResourceIndices[1]);
    g_animation_mesh_indices[3] = new_mesh(Module.MoveLeftMeshResourceIndices[2]);

    g_animation_mesh_indices[4] = new_mesh(Module.MoveRightMeshResourceIndices[1]);
    g_animation_mesh_indices[5] = new_mesh(Module.MoveRightMeshResourceIndices[2]);

    g_animation_mesh_indices[6] = new_mesh(Module.LadderClimbMeshResourceIndices[1]);
    g_animation_mesh_indices[7] = new_mesh(Module.LadderClimbMeshResourceIndices[2]);

    for i = 0, 7 do  -- TODO: Use constants instead of these hard-coded frame numbers
        set_mesh_texture(g_animation_mesh_indices[i], Module.TextureResourceIndex);
    end
end

function Module.update()
    -- TODO: Animate through changemesh, instead of set_mesh_is_visible?
    set_mesh_is_visible(g_animation_mesh_indices[g_animation_current_frame], false);

    AdvanceFrame_();
    MovePenguin_();

    -- Grabbing frame again because it may have changed
    local anim_mesh_index = g_animation_mesh_indices[g_animation_current_frame];
    set_identity_mesh_matrix(anim_mesh_index);
    translate_mesh_matrix(anim_mesh_index, g_current_pos_x, g_current_pos_y + 8.5, g_current_pos_z - 0.5);
    set_mesh_is_visible(anim_mesh_index, true);

    if Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 3, g_current_pos_y + 2,
            g_current_pos_x + 3, g_current_pos_y + 12) then
        Module.GameLogic.kill();
    end
end

return Module;
