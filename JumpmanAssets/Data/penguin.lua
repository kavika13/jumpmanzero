local Module = {};

Module.GameLogic = nil;

Module.StandMeshResourceIndex = 0;
Module.BackMeshResourceIndex = 0;
Module.MoveLeftMeshResourceIndices = {};
Module.MoveRightMeshResourceIndices = {};
Module.LadderClimbMeshResourceIndices = {};
Module.TextureResourceIndex = 0;

Module.CountOfTimesToPreAdvanceMovement = 0;

local g_is_initialized = false;

local g_animation_mesh_indices = {};
local g_animation_current_frame = 0;
local g_animation_frame_counter = 0;  -- Counts up until the next "alt frame" increment (every 6 frames increments alt)
local g_animation_alt_frame_counter = 0;  -- On 1 or 3 switches to an alt frame in the current animation
local g_animation_movement_direction = 4;  -- Used to find the base animation frame. 1, 2 == "LC". 3 = left. 4 = right

local g_current_pos_x = 0;
local g_current_pos_y = 0;
local g_current_pos_z = 0;
local g_closeby_ladder_pos_z = 0;

local function CheckForChange()
    if g_animation_movement_direction == 4 or g_animation_movement_direction == 3 then
        local iLad = find_ladder(g_current_pos_x, g_current_pos_y);

        if iLad >= 0 then
            abs_ladder(iLad);

            if g_current_pos_x == get_script_selected_level_object_x1() then
                g_closeby_ladder_pos_z = get_script_selected_level_object_z1();
                local iSign = get_script_selected_level_object_number();

                if iSign == 41 then
                    g_animation_movement_direction = 4;
                    set_script_selected_level_object_number(14);
                    return;
                end

                if iSign == 14 then
                    g_animation_movement_direction = 1;
                    set_script_selected_level_object_number(41);
                    return;
                end

                if iSign == 141 then
                    g_animation_movement_direction = 4;

                    if get_script_selected_level_object_y2() > g_current_pos_y - 5 then
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
        local iPlat = find_platform(g_current_pos_x, g_current_pos_y + 4, 4, 2);
        abs_platform(iPlat);
        local iHit = get_script_event_data_4();

        if iHit == g_current_pos_y then
            g_animation_movement_direction = get_script_selected_level_object_number();
            return;
        end
    end
end

local function ProgressPenguin()
    if g_animation_movement_direction == 1 then
        g_current_pos_y = g_current_pos_y + 0.5;
        g_animation_current_frame = 6;
    end

    if g_animation_movement_direction == 2 then
        g_current_pos_y = g_current_pos_y - 0.5;
        g_animation_current_frame = 6;
    end

    if g_animation_movement_direction == 3 then
        g_current_pos_x = g_current_pos_x - 0.5;
        g_animation_current_frame = 2;
    end

    if g_animation_movement_direction == 4 then
        g_current_pos_x = g_current_pos_x + 0.5;
        g_animation_current_frame = 4;
    end

    if g_animation_alt_frame_counter == 1 or g_animation_alt_frame_counter == 3 then
        g_animation_current_frame = g_animation_current_frame + 1;
    end
end

local function AdjustZ(target_platform_index)
    abs_platform(target_platform_index);
    local target_platform_pos_z = get_script_selected_level_object_z1();

    if g_current_pos_z < target_platform_pos_z then
        g_current_pos_z = g_current_pos_z + 1;
    end

    if g_current_pos_z > target_platform_pos_z + 2 then
        g_current_pos_z = g_current_pos_z - 1;
    end
end

local function MovePenguin()
    CheckForChange();
    ProgressPenguin();

    local iPlat = find_platform(g_current_pos_x, g_current_pos_y + 5, 4, 2);
    local iHit = get_script_event_data_4();

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
        AdjustZ(iPlat);
    end
end

local function AdvanceFrame()
    g_animation_frame_counter = g_animation_frame_counter + 1;

    if g_animation_frame_counter > 5 then
        g_animation_frame_counter = 0;
        g_animation_alt_frame_counter = g_animation_alt_frame_counter + 1;

        if g_animation_alt_frame_counter > 3 then
            g_animation_alt_frame_counter = 0;
        end
    end
end

local function Initialize()
    g_current_pos_x = 75;
    g_current_pos_y = 26;
    g_current_pos_z = 2;
    g_animation_movement_direction = 4;

    local counter = Module.CountOfTimesToPreAdvanceMovement;

    while counter > 0 do
        MovePenguin();
        counter = counter - 1;
    end

    g_animation_mesh_indices[0] = new_mesh(Module.StandMeshResourceIndex);
    g_animation_mesh_indices[1] = new_mesh(Module.BackMeshResourceIndex);

    g_animation_mesh_indices[2] = new_mesh(Module.MoveLeftMeshResourceIndices[1]);
    g_animation_mesh_indices[3] = new_mesh(Module.MoveLeftMeshResourceIndices[2]);

    g_animation_mesh_indices[4] = new_mesh(Module.MoveRightMeshResourceIndices[1]);
    g_animation_mesh_indices[5] = new_mesh(Module.MoveRightMeshResourceIndices[2]);

    g_animation_mesh_indices[6] = new_mesh(Module.LadderClimbMeshResourceIndices[1]);
    g_animation_mesh_indices[7] = new_mesh(Module.LadderClimbMeshResourceIndices[2]);
end

function Module.update()
    if not g_is_initialized then
        g_is_initialized = true;
        Initialize();
    end

    select_object_mesh(g_animation_mesh_indices[g_animation_current_frame]);
    set_object_visual_data(0, 0);

    AdvanceFrame();
    MovePenguin();

    -- Grabbing frame again because it may have changed
    select_object_mesh(g_animation_mesh_indices[g_animation_current_frame]);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(g_current_pos_x, g_current_pos_y + 8.5, g_current_pos_z - 0.5);
    set_object_visual_data(Module.TextureResourceIndex, 1);

    if Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 3, g_current_pos_y + 2,
            g_current_pos_x + 3, g_current_pos_y + 12) then
        kill();
    end
end

return Module;
