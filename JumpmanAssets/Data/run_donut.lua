local read_only = require "Data/read_only";

local Module = {};

Module.MoveMeshResourceIndices = {};
Module.HatchMeshResourceIndices = {};
Module.TextureResourceIndex = 0;
Module.SpawnCallback = nil;
Module.KillCallback = nil;
Module.InitialPosX = 0;
Module.InitialPosY = 0;

local status_type = {
    DEAD = 0,
    NORMAL = 1,
    CAUGHT = 2,
    JUMP = 3,
    LAYING_EGG = 5,
    HATCHING = 10,
};
status_type = read_only.make_table_read_only(status_type);

local g_is_initialized = false;

local g_animation_mesh_indices = {};
local g_animation_current_frame = 0;
local g_animation_frame_counter = 0;

local g_initial_pos_y = 0;

local g_current_pos_x = 0;
local g_current_pos_y = 0;
local g_current_pos_z = 0;
local g_current_rotation_z = 0;
local g_current_velocity_x = 0;
local g_current_velocity_y = 0;

local g_current_status = status_type.DEAD;
local g_current_status_counter = 0;

local g_move_direction_x = 0;

local g_time_since_spawn = 0;

local g_current_run_donut_count = 0;

local function CheckForChange_()
    if rnd(0, 400) > 395 then
        g_move_direction_x = 0;
    end

    local iPlat1 = find_platform(g_current_pos_x, g_current_pos_y, 7, 2);
    local iHit1 = get_script_event_data_4();
    abs_platform(iPlat1);
    g_current_pos_z = get_script_selected_level_object_z1() + 1;

    if g_current_pos_y > iHit1 + 4 then
        g_current_status = status_type.JUMP;
        g_current_velocity_y = 0;
        g_current_status_counter = 17;
    end

    if g_current_pos_y < iHit1 + 1 and g_current_pos_y > iHit1 - 1 then
        g_current_pos_y = iHit1;
    end

    if g_current_pos_y < iHit1 then
        g_current_pos_y = g_current_pos_y + 1;
    end

    if g_current_pos_y > iHit1 then
        g_current_pos_y = g_current_pos_y - 1;
    end

    local iPlat2 = find_platform(g_current_pos_x + g_move_direction_x, g_current_pos_y, 7, 2);
    local iHit2 = get_script_event_data_4();

    if iPlat1 ~= iPlat2 and iHit2 < (iHit1 - 5) and g_current_pos_y < g_initial_pos_y - 5 then
        g_move_direction_x = -g_move_direction_x;
    end

    iPlat2 = find_platform(g_current_pos_x, g_current_pos_y + 17, 7, 0 - 5);
    iHit2 = get_script_event_data_4();

    if iPlat1 ~= iPlat2 and g_current_pos_y < g_initial_pos_y - 5 and iHit2 > iHit1 then
        g_current_status = status_type.JUMP;
        g_current_status_counter = 0;
        g_current_velocity_y = 6;
    end
end

local function ChangeDirections_(all_run_donuts)
    local iPX = get_player_current_position_x();
    local iPY = get_player_current_position_y();

    if iPY - 10 < g_current_pos_y and iPY + 10 > g_current_pos_y then
        if iPX < g_current_pos_x and iPX + 20 > g_current_pos_x then
            g_move_direction_x = 1;
        end

        if iPX > g_current_pos_x and iPX - 20 < g_current_pos_x then
            g_move_direction_x = -1;
        end
    end

    if g_current_pos_x < 5 then
        g_move_direction_x = 1;
    end

    if g_current_pos_x > 155 then
        g_move_direction_x = -1;
    end

    if rnd(1, 500) > 497 and g_initial_pos_y < g_current_pos_y + 20 then
        g_current_status = status_type.JUMP;
        g_current_status_counter = 0;
        g_current_velocity_y = 5;
        return 0;
    end

    local iRnd = rnd(1, 500);

    if iRnd > 490 and g_time_since_spawn > 200 then
        g_current_run_donut_count = #all_run_donuts;

        if g_current_run_donut_count < 10 then
            g_current_status = status_type.LAYING_EGG;
            g_current_status_counter = 0;
            return 0;
        end

        if g_current_run_donut_count < 35 and iRnd > 495 then
            g_current_status = status_type.LAYING_EGG;
            g_current_status_counter = 0;
            return 0;
        end
    end

    if g_move_direction_x ~= 0 then
        return 0;
    end

    iRnd = rnd(0, 100);
    g_move_direction_x = -1;

    if iRnd > 50 then
        g_move_direction_x = 1;
    end
end

local function AdjustY_()
    local iPlat1 = find_platform(g_current_pos_x, g_current_pos_y, 7, 2);
    local iHit1 = get_script_event_data_4();

    if g_current_pos_y < iHit1 + 1 and g_current_pos_y > iHit1 - 1 then
        g_current_pos_y = iHit1;
    end

    if g_current_pos_y < iHit1 then
        g_current_pos_y = g_current_pos_y + 1;
        g_current_status_counter = 0;
    end

    if g_current_pos_y > iHit1 then
        g_current_pos_y = g_current_pos_y - 1;
        g_current_status_counter = 0;
    end
end

local function ProgressHatch_()
    g_current_status_counter = g_current_status_counter + 1;

    if g_current_status_counter < 20 then
        g_animation_current_frame = 4;  -- TODO: Don't hard-code frame indices, since they're enum values
        return 0;
    end

    if g_current_status_counter < 40 then
        g_animation_current_frame = 5;  -- TODO: Don't hard-code frame indices
        return 0;
    end

    if g_current_status_counter < 60 then
        g_animation_current_frame = 6;  -- TODO: Don't hard-code frame indices
        return 0;
    end

    if g_current_status_counter < 80 then
        g_animation_current_frame = 7;  -- TODO: Don't hard-code frame indices
        return 0;
    end

    if g_current_status_counter < 100 then
        g_animation_current_frame = 8;  -- TODO: Don't hard-code frame indices
        return 0;
    end

    g_current_status = status_type.NORMAL;
end

local function DestroyMe_()
    g_current_status = status_type.DEAD;
    delete_mesh(g_animation_mesh_indices[0]);
    delete_mesh(g_animation_mesh_indices[1]);
    delete_mesh(g_animation_mesh_indices[2]);
    delete_mesh(g_animation_mesh_indices[4]);
    delete_mesh(g_animation_mesh_indices[5]);
    delete_mesh(g_animation_mesh_indices[6]);
    delete_mesh(g_animation_mesh_indices[7]);
    delete_mesh(g_animation_mesh_indices[8]);
    Module.KillCallback(Module);
end

local function Move_()
    g_current_pos_x = g_current_pos_x + g_move_direction_x * 3 / 4;;
end

local function Jump_()
    if g_current_status_counter < 20 then
        g_current_status_counter = g_current_status_counter + 1;
        g_animation_frame_counter = 0;
        g_animation_current_frame = 0;  -- TODO: Don't hard-code frame indices
        return 0;
    end

    g_current_velocity_y = g_current_velocity_y - 0.2;
    g_current_pos_y = g_current_pos_y + g_current_velocity_y / 3;

    local iPlat = find_platform(g_current_pos_x, g_current_pos_y, 5, 2);
    local iHit = get_script_event_data_4();

    if iHit > g_current_pos_y and g_current_velocity_y < 0 then
        g_current_status = status_type.NORMAL;
        g_move_direction_x = 0;
        g_current_pos_y = iHit;
    end
end

local function MoveDonut_(all_run_donuts)
    if g_current_status == status_type.NORMAL then
        CheckForChange_();
    end

    if g_current_status == status_type.NORMAL then
        ChangeDirections_(all_run_donuts);
    end

    if g_current_status == status_type.NORMAL then
        Move_();
    end

    if g_current_status == status_type.JUMP then
        Jump_();
    end

    if g_current_status == status_type.LAYING_EGG then
        g_current_status_counter = g_current_status_counter + 1;
        g_animation_current_frame = 8;  -- TODO: Don't hard-code frame indices

        if g_current_status_counter == 60 then
            g_current_run_donut_count = #all_run_donuts;

            if g_current_run_donut_count < 40 then
                local new_run_donut = Module.SpawnCallback();
                new_run_donut.InitialPosX = rnd(20, 140);
                new_run_donut.InitialPosy = rnd(7, 180);
                new_run_donut.set_current_pos(g_current_pos_x, g_current_pos_y, g_current_pos_z)
            end

            g_current_status = status_type.NORMAL;
            g_time_since_spawn = 0;
        end
    end

    if g_current_status == status_type.HATCHING then
        AdjustY_();
        ProgressHatch_();
    end

    if g_current_status == status_type.CAUGHT then
        g_current_rotation_z = g_current_rotation_z + 5;
        g_current_pos_x = g_current_pos_x + g_current_velocity_x;
        g_current_pos_y = g_current_pos_y + g_current_velocity_y;
        g_current_velocity_y = g_current_velocity_y - 0.15;
        g_current_pos_z = g_current_pos_z - 1.3;

        if g_current_pos_y < 0 - 50 then
            g_current_run_donut_count = #all_run_donuts;

            if g_current_run_donut_count == 1 then
                win();
            end

            DestroyMe_();
        end
    end
end

local function Initialize_()
    -- TODO: Don't hard-code frame indices
    g_animation_mesh_indices[0] = new_mesh(Module.MoveMeshResourceIndices[1]);
    g_animation_mesh_indices[1] = new_mesh(Module.MoveMeshResourceIndices[2]);
    g_animation_mesh_indices[2] = new_mesh(Module.MoveMeshResourceIndices[3]);
    g_animation_mesh_indices[3] = g_animation_mesh_indices[1];

    g_animation_mesh_indices[4] = new_mesh(Module.HatchMeshResourceIndices[1]);
    g_animation_mesh_indices[5] = new_mesh(Module.HatchMeshResourceIndices[2]);
    g_animation_mesh_indices[6] = new_mesh(Module.HatchMeshResourceIndices[3]);
    g_animation_mesh_indices[7] = new_mesh(Module.HatchMeshResourceIndices[4]);
    g_animation_mesh_indices[8] = new_mesh(Module.HatchMeshResourceIndices[5]);
end

function Module.update(all_run_donuts)
    if not g_is_initialized then
        g_is_initialized = true;

        g_time_since_spawn = 0;
        Initialize_();
        g_current_status = status_type.HATCHING;
        g_current_status_counter = 0;

        if Module.InitialPosX == 0 then
            Module.InitialPosX = 50;
            Module.InitialPosY = 2;
        end

        g_initial_pos_y = Module.InitialPosY;

        if g_current_pos_x == 0 then
            -- TODO: Why must pos_x, pos_y, pos_z be set even tho InitialPosX and InitialPosY are set, when hatched?
            g_current_pos_z = 5;
            g_current_pos_x = Module.InitialPosX;
            g_current_pos_y = Module.InitialPosY;
        end
    end

    g_time_since_spawn = g_time_since_spawn + 1;

    select_object_mesh(g_animation_mesh_indices[g_animation_current_frame]);
    set_object_visual_data(0, 0);

    if g_current_status == status_type.NORMAL or g_current_status == status_type.JUMP or
            g_current_status == status_type.HATCHING or g_current_status == status_type.LAYING_EGG then
        local iCollide = is_player_colliding_with_rect(
            g_current_pos_x - 3, g_current_pos_y,
            g_current_pos_x + 3, g_current_pos_y + 6);

        if iCollide then
            -- TODO: Sound when you catch them?
            g_current_status = status_type.CAUGHT;
            g_current_velocity_y = 2.1;
            g_current_velocity_x = (rnd(0, 20) - 10) / 10;
        end
    end

    g_animation_frame_counter = g_animation_frame_counter + 1;

    if g_animation_frame_counter > 4 then
        g_animation_frame_counter = 0;
        g_animation_current_frame = g_animation_current_frame + 1;

        if g_animation_current_frame > 3 then
            g_animation_current_frame = 0;  -- TODO: Don't hard-code frame indices
        end
    end

    MoveDonut_(all_run_donuts);

    if g_current_status > status_type.DEAD then
        select_object_mesh(g_animation_mesh_indices[g_animation_current_frame]);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_scale_matrix(0.6, 0.6, 1);
        script_selected_mesh_rotate_matrix_z(g_current_rotation_z);
        script_selected_mesh_translate_matrix(g_current_pos_x, g_current_pos_y + 3, g_current_pos_z);
        set_object_visual_data(Module.TextureResourceIndex, 1);
    end
end

function Module.set_current_pos(new_x, new_y, new_z)
    -- TODO: Why must pos_x, pos_y, pos_z be set even tho InitialPosX and InitialPosY are set, when hatched?
    g_current_pos_x, g_current_pos_y, g_current_pos_z = new_x, new_y, new_z;
end

return Module;