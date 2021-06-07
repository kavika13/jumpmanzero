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

local g_ship_top_mesh_index = -1;
local g_ship_top_transform_index = -1;
local g_ship_base_mesh_index = -1;
local g_ship_base_transform_index = -1;
local g_alien_mesh_index = -1;
local g_alien_transform_indices = nil;
local g_eye_1_mesh_index = -1;
local g_eye_1_transform_indices = nil;
local g_eye_2_mesh_index = -1;
local g_eye_2_transform_indices = nil;

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

    transform_set_scale(g_eye_1_transform_indices[1], 0.6, 0.6, 0.7);
    transform_set_translation(g_eye_1_transform_indices[1], g_eye_waggle_x2 - 1, 0, 0);
    transform_set_rotation_z(g_eye_1_transform_indices[2], iRotateZ);
    transform_set_translation(g_eye_1_transform_indices[2], iBaseX + iWiggleX, g_current_pos_y + 10 + 1 + g_eye_waggle_y1, iBaseZ);
    set_mesh_is_visible(g_eye_1_mesh_index, true);

    transform_set_scale(g_eye_2_transform_indices[1], 0.6, 0.6, 0.7);
    transform_set_translation(g_eye_2_transform_indices[1], 1 + g_eye_waggle_x2, 0, 0);
    transform_set_rotation_z(g_eye_2_transform_indices[2], iRotateZ);
    transform_set_translation(g_eye_2_transform_indices[2], iBaseX + iWiggleX, g_current_pos_y + 10 + 1 + g_eye_waggle_y2, iBaseZ);
    set_mesh_is_visible(g_eye_2_mesh_index, true);

    transform_set_rotation_y(g_alien_transform_indices[1], 10);

    if g_frames_since_level_start & 8 then
        set_mesh_to_mesh(g_alien_mesh_index, Module.AlienMeshResourceIndices[1]);
    else
        set_mesh_to_mesh(g_alien_mesh_index, Module.AlienMeshResourceIndices[2]);
    end

    transform_set_scale(g_alien_transform_indices[2], 0.55, 0.6, 0.7);
    transform_set_rotation_z(g_alien_transform_indices[2], iRotateZ);
    transform_set_translation(g_alien_transform_indices[2], iBaseX + iWiggleX, g_current_pos_y + 10, iBaseZ);
    set_mesh_is_visible(g_alien_mesh_index, true);

    transform_set_scale(g_ship_base_transform_index, 11, 11, 11);
    transform_set_rotation_y(g_ship_base_transform_index, g_current_rotation_y);
    transform_concat_rotation_z(g_ship_base_transform_index, iRotateZ);
    transform_set_translation(g_ship_base_transform_index, iBaseX + iWiggleX, g_current_pos_y, iBaseZ + 1);
    set_mesh_is_visible(g_ship_base_mesh_index, true);

    transform_set_scale(g_ship_top_transform_index, 12, 14, 14);
    transform_set_rotation_y(g_ship_top_transform_index, g_current_rotation_y);
    transform_concat_rotation_z(g_ship_top_transform_index, iRotateZ);
    transform_set_translation(g_ship_top_transform_index, iBaseX + iWiggleX, g_current_pos_y - 3, iBaseZ + 1);
    set_mesh_is_visible(g_ship_top_mesh_index, true);
end

function Module.initialize()
    local setup_mesh_transform = function(mesh_index)
        local transform_index = transform_create();
        mesh_set_transform(mesh_index, transform_index);
        return transform_index;
    end

    g_alien_mesh_index = new_mesh(Module.AlienMeshResourceIndices[1]);
    g_alien_transform_indices = { setup_mesh_transform(g_alien_mesh_index), transform_create() };
    transform_set_parent(g_alien_transform_indices[1], g_alien_transform_indices[2]);
    set_mesh_texture(g_alien_mesh_index, Module.AlienTextureResourceIndex);

    g_eye_1_mesh_index = new_mesh(Module.EyeMeshResourceIndex);
    g_eye_1_transform_indices = { setup_mesh_transform(g_eye_1_mesh_index), transform_create() };
    transform_set_parent(g_eye_1_transform_indices[1], g_eye_1_transform_indices[2]);
    set_mesh_texture(g_eye_1_mesh_index, Module.EyeTextureResourceIndex);

    g_eye_2_mesh_index = new_mesh(Module.EyeMeshResourceIndex);
    g_eye_2_transform_indices = { setup_mesh_transform(g_eye_2_mesh_index), transform_create() };
    transform_set_parent(g_eye_2_transform_indices[1], g_eye_2_transform_indices[2]);
    set_mesh_texture(g_eye_2_mesh_index, Module.EyeTextureResourceIndex);

    g_ship_base_mesh_index = new_mesh(Module.ShipBaseMeshResourceIndex);
    g_ship_base_transform_index = setup_mesh_transform(g_ship_base_mesh_index);
    set_mesh_texture(g_ship_base_mesh_index, Module.ShipTextureResourceIndex);

    g_ship_top_mesh_index = new_mesh(Module.ShipTopMeshResourceIndex);
    g_ship_top_transform_index = setup_mesh_transform(g_ship_top_mesh_index);
    set_mesh_texture(g_ship_top_mesh_index, Module.GlassTextureResourceIndex);

    g_current_pos_y = 130;
end

function Module.update()
    g_frames_since_level_start = g_frames_since_level_start + 1;

    SetFacing_();
    ShowAlien_();
end

return Module;
