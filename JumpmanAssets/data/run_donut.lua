local read_only = require "data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.SpawnCallback = nil;
Module.KillCallback = nil;

Module.MoveMeshResourceIndices = {};
Module.HatchMeshResourceIndices = {};
Module.TextureResourceIndex = 0;
Module.ChompSoundResourceIndex = 0;

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

local animation_frame = {
    MOVE_1 = 1,
    MOVE_2 = 2,
    MOVE_3 = 3,
    MOVE_4 = 4,

    HATCH_1 = 5,
    HATCH_2 = 6,
    HATCH_3 = 7,
    HATCH_4 = 8,
    HATCH_5 = 9,
};
animation_frame = read_only.make_table_read_only(animation_frame);

local g_run_donut_mesh = nil;
local g_animation_mesh_indices = {};
local g_animation_current_frame = animation_frame.MOVE_1;
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
    if math.random(0, 400) > 395 then
        g_move_direction_x = 0;
    end

    local iHit1, iPlat1 = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y, 7, 2);

    if iPlat1 ~= -1 then
        g_current_pos_z = Module.GameLogic.get_platform(iPlat1).pos_z + 1;
    end

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

    local iHit2, iPlat2 = Module.GameLogic.find_platform(g_current_pos_x + g_move_direction_x, g_current_pos_y, 7, 2);

    if iPlat1 ~= iPlat2 and iHit2 < (iHit1 - 5) and g_current_pos_y < g_initial_pos_y - 5 then
        g_move_direction_x = -g_move_direction_x;
    end

    iHit2, iPlat2 = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y + 17, 7, 0 - 5);

    if iPlat1 ~= iPlat2 and g_current_pos_y < g_initial_pos_y - 5 and iHit2 > iHit1 then
        g_current_status = status_type.JUMP;
        g_current_status_counter = 0;
        g_current_velocity_y = 6;
    end
end

local function ChangeDirections_(all_run_donuts)
    local iPX = Module.GameLogic.get_player_current_position_x();
    local iPY = Module.GameLogic.get_player_current_position_y();

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

    if math.random(1, 500) > 497 and g_initial_pos_y < g_current_pos_y + 20 then
        g_current_status = status_type.JUMP;
        g_current_status_counter = 0;
        g_current_velocity_y = 5;
        return 0;
    end

    local iRnd = math.random(1, 500);

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

    iRnd = math.random(0, 100);
    g_move_direction_x = -1;

    if iRnd > 50 then
        g_move_direction_x = 1;
    end
end

local function AdjustY_()
    local iHit1, iPlat1 = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y, 7, 2);

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
        g_animation_current_frame = animation_frame.HATCH_1;
        return 0;
    end

    if g_current_status_counter < 40 then
        g_animation_current_frame = animation_frame.HATCH_2;
        return 0;
    end

    if g_current_status_counter < 60 then
        g_animation_current_frame = animation_frame.HATCH_3;
        return 0;
    end

    if g_current_status_counter < 80 then
        g_animation_current_frame = animation_frame.HATCH_4;
        return 0;
    end

    if g_current_status_counter < 100 then
        g_animation_current_frame = animation_frame.HATCH_5;
        return 0;
    end

    g_current_status = status_type.NORMAL;
end

local function DestroyMe_()
    g_current_status = status_type.DEAD;
    delete_mesh(g_run_donut_mesh);
    Module.KillCallback(Module);
end

local function Move_()
    g_current_pos_x = g_current_pos_x + g_move_direction_x * 3 / 4;;
end

local function Jump_()
    if g_current_status_counter < 20 then
        g_current_status_counter = g_current_status_counter + 1;
        g_animation_frame_counter = 0;
        g_animation_current_frame = animation_frame.MOVE_1;
        return 0;
    end

    g_current_velocity_y = g_current_velocity_y - 0.2;
    g_current_pos_y = g_current_pos_y + g_current_velocity_y / 3;

    local iHit, iPlat = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y, 5, 2);

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
        g_animation_current_frame = animation_frame.HATCH_5;

        if g_current_status_counter == 60 then
            g_current_run_donut_count = #all_run_donuts;

            if g_current_run_donut_count < 40 then
                local new_run_donut = Module.SpawnCallback();
                new_run_donut.InitialPosX = math.random(20, 140);
                new_run_donut.InitialPosy = math.random(7, 180);
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
                Module.GameLogic.win();
            end

            DestroyMe_();
        end
    end
end

function Module.initialize()
    g_time_since_spawn = 0;

    g_animation_mesh_indices[animation_frame.MOVE_1] = Module.MoveMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.MOVE_2] = Module.MoveMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.MOVE_3] = Module.MoveMeshResourceIndices[3];
    g_animation_mesh_indices[animation_frame.MOVE_4] = Module.MoveMeshResourceIndices[2];

    g_animation_mesh_indices[animation_frame.HATCH_1] = Module.HatchMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.HATCH_2] = Module.HatchMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.HATCH_3] = Module.HatchMeshResourceIndices[3];
    g_animation_mesh_indices[animation_frame.HATCH_4] = Module.HatchMeshResourceIndices[4];
    g_animation_mesh_indices[animation_frame.HATCH_5] = Module.HatchMeshResourceIndices[5];

    g_run_donut_mesh = new_mesh(g_animation_mesh_indices[animation_frame.MOVE_1]);
    set_mesh_texture(g_run_donut_mesh, Module.TextureResourceIndex);

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

function Module.update(all_run_donuts)
    g_time_since_spawn = g_time_since_spawn + 1;

    if g_current_status == status_type.NORMAL or g_current_status == status_type.JUMP or
            g_current_status == status_type.HATCHING or g_current_status == status_type.LAYING_EGG then
        local iCollide = Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 3, g_current_pos_y,
            g_current_pos_x + 3, g_current_pos_y + 6);

        if iCollide then
            play_sound_effect(Module.ChompSoundResourceIndex);
            g_current_status = status_type.CAUGHT;
            g_current_velocity_y = 2.1;
            g_current_velocity_x = (math.random(0, 20) - 10) / 10;
        end
    end

    g_animation_frame_counter = g_animation_frame_counter + 1;

    if g_animation_frame_counter > 4 then
        g_animation_frame_counter = 0;
        g_animation_current_frame = g_animation_current_frame + 1;

        if g_animation_current_frame > animation_frame.MOVE_4 then  -- TODO: Use count/last frame num instaed of hard-coding highest index
            g_animation_current_frame = animation_frame.MOVE_1;
        end
    end

    MoveDonut_(all_run_donuts);

    if g_current_status > status_type.DEAD then
        set_mesh_to_mesh(g_run_donut_mesh, g_animation_mesh_indices[g_animation_current_frame]);
        set_identity_mesh_matrix(g_run_donut_mesh);
        scale_mesh_matrix(g_run_donut_mesh, 0.6, 0.6, 1);
        rotate_z_mesh_matrix(g_run_donut_mesh, g_current_rotation_z);
        translate_mesh_matrix(g_run_donut_mesh, g_current_pos_x, g_current_pos_y + 3, g_current_pos_z);
        set_mesh_is_visible(g_run_donut_mesh, true);
    else
        set_mesh_is_visible(g_run_donut_mesh, false);
    end
end

function Module.set_current_pos(new_x, new_y, new_z)
    -- TODO: Why must pos_x, pos_y, pos_z be set even tho InitialPosX and InitialPosY are set, when hatched?
    g_current_pos_x, g_current_pos_y, g_current_pos_z = new_x, new_y, new_z;
end

return Module;
