local Module = {};

Module.GameLogic = nil;

Module.PlayAreaCircumference = 0;
Module.BeamMeshResourceIndex = 0;
Module.BeamTextureResourceIndex = 0;
Module.BlastMeshResourceIndex = 0;
Module.BlastTextureResourceIndex = 0;
Module.BeamColorTextureResourceIndex = 0;
Module.BeamType = 0;
Module.ShipPosX = 0;
Module.ShipPosY = 0;
Module.ParmDir = 0;  -- TODO: Rename
Module.ShipSinkAmount = 0;

local g_frames_since_beam_started = 0;

local g_beam_1_mesh_index;
local g_beam_2_mesh_index;
local g_blast_mesh_index;

local g_ship_pos_z;

local iCollideDir;  -- TODO: Rename

local g_target_pos_x;
local g_target_pos_y;
local g_target_pos_z;
local g_gun_pos_x;
local g_gun_pos_y;
local g_gun_pos_z;
local g_gun_to_target_distance = 0;
local g_gun_pan_rotation = 0;
local g_gun_tilt_rotation = 0;

local g_previous_player_pos_x = 0;
local g_is_blast_visible = false;

local function SetTarget_()
    if Module.BeamType == 2 then
        g_target_pos_x = math.cos((Module.ParmDir + 10) * math.pi / 180.0) * 60 + Module.GameLogic.get_player_current_position_x();
        g_target_pos_y = 30 - math.sin(g_frames_since_beam_started * 2 * math.pi / 180.0) * 25;
        g_target_pos_z = math.sin((Module.ParmDir + 10) * math.pi / 180.0) * 60 + 60;
        iCollideDir = Module.ParmDir + 10;
    elseif Module.BeamType == 3 then
        g_target_pos_x = math.cos((Module.ParmDir - 10) * math.pi / 180.0) * 60 + Module.GameLogic.get_player_current_position_x();
        g_target_pos_y = 40 + math.sin(g_frames_since_beam_started * math.pi / 180.0) * 40;
        g_target_pos_z = math.sin((Module.ParmDir - 10) * math.pi / 180.0) * 60 + 60;
        iCollideDir = Module.ParmDir - 10;
    else
        g_target_pos_x = math.cos(Module.ParmDir * math.pi / 180.0) * 60 + Module.GameLogic.get_player_current_position_x();
        g_target_pos_y = 50 + math.sin(g_frames_since_beam_started * 2 * math.pi / 180.0) * 25;
        g_target_pos_z = math.sin(Module.ParmDir * math.pi / 180.0) * 60 + 60;
        iCollideDir = Module.ParmDir;
    end
end

local function SetGun_()
    local iDX = g_target_pos_x - Module.ShipPosX;
    local iDY = g_target_pos_y - Module.ShipPosY;
    local iDZ = g_target_pos_z - g_ship_pos_z;

    local iLengthXZ = math.sqrt(iDX * iDX + iDZ * iDZ);

    local iGX = iDX * 30 / iLengthXZ;
    local iGY = 0;
    local iRZ = math.sin(g_frames_since_beam_started * 3 / 2 * math.pi / 180.0) * 10;

    iGX = math.cos(iRZ * math.pi / 180.0) * iGX;
    iGY = math.sin(iRZ * math.pi / 180.0) * iGX;

    g_gun_pos_x = iGX + Module.ShipPosX;
    g_gun_pos_y = iGY + Module.ShipPosY;
    g_gun_pos_z = g_ship_pos_z + (iDZ * 30 / iLengthXZ);
end

local function SetFire_()
    local iDX = g_target_pos_x - g_gun_pos_x;
    local iDY = g_target_pos_y - g_gun_pos_y;
    local iDZ = g_target_pos_z - g_gun_pos_z;

    local iLengthXZ = math.sqrt(iDX * iDX + iDZ * iDZ);
    g_gun_pan_rotation = math.atan(0 - iDZ, iDX) * 180.0 / math.pi;
    g_gun_tilt_rotation = math.atan(iDY, iLengthXZ) * 180.0 / math.pi;
    g_gun_to_target_distance = math.sqrt(iDX * iDX + iDY * iDY + iDZ * iDZ);

    g_is_blast_visible = false;
    local iMin = Module.BeamType * 70;

    if g_frames_since_beam_started < iMin then
        g_gun_to_target_distance = 1;
    elseif g_frames_since_beam_started < iMin + 70 then
        g_gun_to_target_distance = g_gun_to_target_distance * ((g_frames_since_beam_started - iMin) / 70) * ((g_frames_since_beam_started - iMin) / 70);
    else
        g_is_blast_visible = true;
    end
end

local function DrawFire_()
    if g_is_blast_visible then
        local iBX = g_target_pos_x + math.random(1, 50) / 50;
        local iBY = g_target_pos_y + math.random(1, 50) / 50;

        select_object_mesh(g_blast_mesh_index);
        set_identity_mesh_matrix(g_blast_mesh_index);
        scale_mesh_matrix(g_blast_mesh_index, 8, 8, 1);

        if g_frames_since_beam_started & 4 ~= 0 then
            script_selected_mesh_rotate_matrix_z(180);
        end

        script_selected_mesh_translate_matrix(iBX - 0.5, iBY, g_target_pos_z - 2);
        set_object_visual_data(Module.BlastTextureResourceIndex, 1);
    end

    select_object_mesh(g_beam_1_mesh_index);
    set_identity_mesh_matrix(g_beam_1_mesh_index);
    script_selected_mesh_translate_matrix(0.5, 0, 0);
    scale_mesh_matrix(g_beam_1_mesh_index, g_gun_to_target_distance, 1, 1);
    script_selected_mesh_rotate_matrix_z(g_gun_tilt_rotation);
    script_selected_mesh_rotate_matrix_y(g_gun_pan_rotation);
    script_selected_mesh_translate_matrix(g_gun_pos_x, g_gun_pos_y, g_gun_pos_z);
    set_object_visual_data(Module.BeamColorTextureResourceIndex, 1);

    select_object_mesh(g_beam_2_mesh_index);
    set_identity_mesh_matrix(g_beam_2_mesh_index);
    script_selected_mesh_rotate_matrix_x(g_frames_since_beam_started * 34);
    script_selected_mesh_translate_matrix(0.5, 0, 0);
    scale_mesh_matrix(g_beam_2_mesh_index, g_gun_to_target_distance, 3, 2);
    script_selected_mesh_rotate_matrix_z(g_gun_tilt_rotation);
    script_selected_mesh_rotate_matrix_y(g_gun_pan_rotation);
    script_selected_mesh_translate_matrix(g_gun_pos_x, g_gun_pos_y, g_gun_pos_z);
    set_object_visual_data(Module.BeamTextureResourceIndex, 1);
end

function Module.initialize()
    -- TODO: For some reason these were initialized one frame apart before. Is that important/interesting for the animation? Or does it change nothing visually?
    g_beam_1_mesh_index = new_mesh(Module.BeamMeshResourceIndex);
    g_beam_2_mesh_index = new_mesh(Module.BeamMeshResourceIndex);

    g_blast_mesh_index = new_mesh(Module.BlastMeshResourceIndex);
    g_ship_pos_z = 60;
end

function Module.update()
    g_frames_since_beam_started = g_frames_since_beam_started + 1;

    local iPX = Module.GameLogic.get_player_current_position_x();

    if iPX > 150 and g_previous_player_pos_x < 100 then
        g_previous_player_pos_x = g_previous_player_pos_x + Module.PlayAreaCircumference;
    end

    if iPX < 100 and g_previous_player_pos_x > 150 then
        g_previous_player_pos_x = g_previous_player_pos_x - Module.PlayAreaCircumference;
    end

    if Module.ParmDir > 360 then
        Module.ParmDir = Module.ParmDir - 360;
    end

    Module.ParmDir = Module.ParmDir + 2 + g_previous_player_pos_x - iPX;
    g_previous_player_pos_x = iPX;

    if Module.ShipSinkAmount > 0 then
        select_object_mesh(g_blast_mesh_index);
        set_object_visual_data(0, 0);
        select_object_mesh(g_beam_1_mesh_index);
        set_object_visual_data(0, 0);
        select_object_mesh(g_beam_2_mesh_index);
        set_object_visual_data(0, 0);
        return;
    end

    SetTarget_();
    SetGun_();
    SetFire_();
    DrawFire_();

    if g_is_blast_visible then
        if iCollideDir > 267 and iCollideDir < 273 then
            if Module.GameLogic.is_player_colliding_with_rect(
                    iPX - 5, g_target_pos_y - 2,
                    iPX + 5, g_target_pos_y + 2) then
                Module.GameLogic.kill();
            end
        end
    end
end

return Module;
