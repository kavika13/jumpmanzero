local Module = {};

Module.GameLogic = nil;

Module.MoveRightMeshResourceIndices = {};
Module.MoveLeftMeshResourceIndices = {};
Module.TextureResourceIndex = 0;

Module.PlayAreaCircumference = 0;
Module.StartPosX = 0;
Module.StartPosY = 0;

local g_blob_mesh_index;
local g_animation_counter = 0;
local g_animation_current_frame = 0;

local g_current_pos_x = 0;
local g_current_pos_y = 0;
local g_current_velocity_x = 0.3;
local g_current_rotation_z = 0;

local function Animate_()
    g_animation_counter = g_animation_counter + 1;

    if g_animation_counter == 4 then
        g_animation_current_frame = g_animation_current_frame + 1;
        g_animation_counter = 0;
    end

    local frame_index = (g_animation_current_frame & 3) + 1;

    if g_current_velocity_x < 0 then
        frame_index = Module.MoveLeftMeshResourceIndices[frame_index];
    else
        frame_index = Module.MoveRightMeshResourceIndices[frame_index];
    end

    select_object_mesh(g_blob_mesh_index);
    script_selected_mesh_change_mesh(frame_index);
end

local function MoveBlob_()
    g_current_pos_x = g_current_pos_x + g_current_velocity_x;

    local iHit, iPlat = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y, 5, 1);

    g_current_pos_y = (iHit + g_current_pos_y) / 2;

    iHit, iPlat = Module.GameLogic.find_platform(g_current_pos_x + g_current_velocity_x * 20, g_current_pos_y, 5, 5);

    if iHit < g_current_pos_y - 5 then
        g_current_pos_x = g_current_pos_x - g_current_velocity_x;
        g_current_velocity_x = g_current_velocity_x * -1;
    end

    local iHit1, _ = Module.GameLogic.find_platform(g_current_pos_x - g_current_velocity_x * 15, g_current_pos_y, 5, 5);
    local iHit2, _ = Module.GameLogic.find_platform(g_current_pos_x + g_current_velocity_x * 15, g_current_pos_y, 5, 5);

    g_current_rotation_z = math.atan(iHit2 - iHit1, g_current_velocity_x * 30) * 180.0 / math.pi;

    if g_current_velocity_x < 0 then
        -- Undo 180 degree rotation done by atan function when second arg is negative
        if iHit2 >= iHit1 then
            g_current_rotation_z = g_current_rotation_z - 180;
        else
            g_current_rotation_z = g_current_rotation_z + 180;
        end
    end
end

local function ShowBlob_()
    local iPX = Module.GameLogic.get_player_current_position_x();
    select_object_mesh(g_blob_mesh_index);
    set_identity_mesh_matrix(g_blob_mesh_index);
    scale_mesh_matrix(g_blob_mesh_index, 0.6, 0.5, 0.8);
    script_selected_mesh_rotate_matrix_z(g_current_rotation_z);
    script_selected_mesh_translate_matrix(0, 0, -75);
    script_selected_mesh_rotate_matrix_y((iPX - g_current_pos_x) * 360 / Module.PlayAreaCircumference);
    script_selected_mesh_translate_matrix(iPX, g_current_pos_y - 0.6, 75.3);
    set_object_visual_data(Module.TextureResourceIndex, 1);
end

function Module.initialize()
    g_blob_mesh_index = new_mesh(Module.MoveRightMeshResourceIndices[1]);
    g_current_pos_x = Module.StartPosX;
    g_current_pos_y = Module.StartPosY;
end

function Module.update()
    Animate_();
    MoveBlob_();
    ShowBlob_();

    if Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 2, g_current_pos_y + 1,
            g_current_pos_x + 2, g_current_pos_y + 3) then
        Module.GameLogic.kill();
    end
end

return Module;
