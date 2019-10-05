local Module = {};

Module.AlienMeshResourceIndices = {};
Module.EyeMeshResourceIndex = 0;
Module.ShipBaseMeshResourceIndex = 0;
Module.ShipTopMeshResourceIndex = 0;
Module.EyeTextureResourceIndex = 0;
Module.AlienTextureResourceIndex = 0;
Module.ShipTextureResourceIndex = 0;
Module.GlassTextureResourceIndex = 0;

local g_frames_since_level_start = 0;

local g_ship_top_mesh_index = 0;
local g_ship_base_mesh_index = 0;
local g_alien_mesh_index = 0;
local g_eye_1_mesh_index = 0;
local g_eye_2_mesh_index = 0;

local g_current_pos_y = 0;
local g_current_velocity_y = 0;
local g_current_rotation_y = 0;

local g_eye_waggle_x1 = 0;
local g_eye_waggle_y1 = 0;
local g_eye_waggle_x2 = 0;
local g_eye_waggle_y2 = 0;

local function SetFacing_()
    g_current_rotation_y = g_current_rotation_y - 1.5;
end

local function AdjustEyeWaggling_(iValue)
    local iAdjust = (math.random(1, 100) - 50) / 300;
    local iFinal = iValue + iAdjust;

    if iFinal < -0.4 then
        iFinal = -0.4;
    end

    if iFinal > 0.4 then
        iFinal = 0.4;
    end

    return iFinal;
end

local function ShowAlien_()
    local iBaseZ = 35;
    local iBaseX = 132;
    local iTargetY = 0;

    if g_frames_since_level_start < 350 then
        iTargetY = 85 - math.sin(g_frames_since_level_start * math.pi / 180.0) * 10;
    else
        iTargetY = 150;
    end

    if iTargetY > g_current_pos_y then
        g_current_velocity_y = g_current_velocity_y + 0.06;
    end

    if iTargetY < g_current_pos_y then
        g_current_velocity_y = g_current_velocity_y - 0.06;
    end

    if g_current_velocity_y > 0.7 then
        g_current_velocity_y = 0.7;
    end

    if g_current_velocity_y < -0.7 then
        g_current_velocity_y = -0.7;
    end

    g_current_pos_y = g_current_pos_y + g_current_velocity_y;

    local iWiggleX = math.sin(g_frames_since_level_start * 3 / 2 * math.pi / 180.0) * 10;
    local iRotateZ = math.sin(g_frames_since_level_start * 3 / 2 * math.pi / 180.0) * 10;

    g_eye_waggle_x1 = AdjustEyeWaggling_(g_eye_waggle_x1);
    g_eye_waggle_x2 = AdjustEyeWaggling_(g_eye_waggle_x2);
    g_eye_waggle_y1 = AdjustEyeWaggling_(g_eye_waggle_y1);
    g_eye_waggle_y2 = AdjustEyeWaggling_(g_eye_waggle_y2);

    select_object_mesh(g_eye_1_mesh_index);
    set_identity_mesh_matrix(g_eye_1_mesh_index);
    scale_mesh_matrix(g_eye_1_mesh_index, 0.6, 0.6, 0.7);
    script_selected_mesh_translate_matrix(g_eye_waggle_x2 - 1, 0, 0);
    script_selected_mesh_rotate_matrix_z(iRotateZ);
    script_selected_mesh_translate_matrix(iBaseX + iWiggleX, g_current_pos_y + 10 + 1 + g_eye_waggle_y1, iBaseZ);
    set_object_visual_data(Module.EyeTextureResourceIndex, 1);

    select_object_mesh(g_eye_2_mesh_index);
    set_identity_mesh_matrix(g_eye_2_mesh_index);
    scale_mesh_matrix(g_eye_2_mesh_index, 0.6, 0.6, 0.7);
    script_selected_mesh_translate_matrix(1 + g_eye_waggle_x2, 0, 0);
    script_selected_mesh_rotate_matrix_z(iRotateZ);
    script_selected_mesh_translate_matrix(iBaseX + iWiggleX, g_current_pos_y + 10 + 1 + g_eye_waggle_y2, iBaseZ);
    set_object_visual_data(Module.EyeTextureResourceIndex, 1);

    select_object_mesh(g_alien_mesh_index);
    set_identity_mesh_matrix(g_alien_mesh_index);
    rotate_y_mesh_matrix(g_alien_mesh_index, 10);

    if g_frames_since_level_start & 8 then
        set_mesh_to_mesh(g_alien_mesh_index, Module.AlienMeshResourceIndices[1]);
    else
        set_mesh_to_mesh(g_alien_mesh_index, Module.AlienMeshResourceIndices[2]);
    end

    scale_mesh_matrix(g_alien_mesh_index, 0.55, 0.6, 0.7);
    script_selected_mesh_rotate_matrix_z(iRotateZ);
    script_selected_mesh_translate_matrix(iBaseX + iWiggleX, g_current_pos_y + 10, iBaseZ);
    set_object_visual_data(Module.AlienTextureResourceIndex, 1);

    select_object_mesh(g_ship_base_mesh_index);
    set_identity_mesh_matrix(g_ship_base_mesh_index);
    scale_mesh_matrix(g_ship_base_mesh_index, 11, 11, 11);
    rotate_y_mesh_matrix(g_ship_base_mesh_index, g_current_rotation_y);
    script_selected_mesh_rotate_matrix_z(iRotateZ);
    script_selected_mesh_translate_matrix(iBaseX + iWiggleX, g_current_pos_y, iBaseZ + 1);
    set_object_visual_data(Module.ShipTextureResourceIndex, 1);

    select_object_mesh(g_ship_top_mesh_index);
    set_identity_mesh_matrix(g_ship_top_mesh_index);
    scale_mesh_matrix(g_ship_top_mesh_index, 12, 14, 14);
    rotate_y_mesh_matrix(g_ship_top_mesh_index, g_current_rotation_y);
    script_selected_mesh_rotate_matrix_z(iRotateZ);
    script_selected_mesh_translate_matrix(iBaseX + iWiggleX, g_current_pos_y - 3, iBaseZ + 1);
    set_object_visual_data(Module.GlassTextureResourceIndex, 1);
end

function Module.initialize()
    g_alien_mesh_index = new_mesh(Module.AlienMeshResourceIndices[1]);
    g_eye_1_mesh_index = new_mesh(Module.EyeMeshResourceIndex);
    g_eye_2_mesh_index = new_mesh(Module.EyeMeshResourceIndex);
    g_ship_base_mesh_index = new_mesh(Module.ShipBaseMeshResourceIndex);
    g_ship_top_mesh_index = new_mesh(Module.ShipTopMeshResourceIndex);

    g_current_pos_y = 130;
end

function Module.update()
    g_frames_since_level_start = g_frames_since_level_start + 1;

    SetFacing_();
    ShowAlien_();
end

return Module;
