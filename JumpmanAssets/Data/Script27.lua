local read_only = require "Data/read_only";

-- TODO: Move this into a shared file, split into separate tables by type. Or inject from engine?
local player_state = {
    JSNORMAL = 0,
    JSJUMPING = 1,
    JSRIGHT = 2,
    JSLEFT = 4,
    JSFALLING = 8,
    JSLADDER = 16,
    JSKICK = 32,
    JSROLL = 64,
    JSPUNCH = 128,
    JSDYING = 256,
    JSVINE = 1024,
}
player_state = read_only.make_table_read_only(player_state);

-- TODO: Move this into a shared file, split into separate tables by type
local camera_mode = {
    PerspectiveNormal = 0,
    PerspectiveCloseUp = 1,
    PerspectiveFar = 2,
    PerspectiveWide = 3,
    PerspectiveFollow = 4,
    PerspectiveFixed = 5,
}
camera_mode = read_only.make_table_read_only(camera_mode);

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureJumpman = 0,
    TextureSpacePlatform = 1,
    TextureEvenWood = 2,
    TextureRedMetal = 3,
    TextureSpaceBack = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    MeshShipBase = 0,
    MeshShipTop = 1,
    TextureShipMetal = 5,
    TextureShipGlass = 6,
    TextureAlien = 7,
    MeshAlien1 = 2,
    MeshAlien2 = 3,
    MeshCube = 4,
    MeshSquare = 5,
    ScriptBeam = 0,
    MeshBeam = 6,
    TextureBeam = 8,
    TextureBlast1 = 9,
    TextureBrightRed = 10,
    TextureBrightGreen = 11,
    TextureBrightBlue = 12,
    MeshBlob1 = 7,
    MeshBlob2 = 8,
    MeshBlob3 = 9,
    MeshBlob4 = 10,
    MeshBlob2L = 11,
    MeshBlob3L = 12,
    ScriptBlob = 1,
    ScriptZDonut = 2,
    SoundClasBomb = 4,
    TextureLightning = 13,
    TextureClearBlue = 14,
}
resources = read_only.make_table_read_only(resources);

-- TODO: Separate file?
local blob_properties = {
    BlobIInit = 0,
    BlobIBlob = 1,
    BlobIX = 2,
    BlobIY = 3,
    BlobIXV = 4,
    BlobISlow = 5,
    BlobIFrame = 6,
    BlobIAngle = 7,
}
blob_properties = read_only.make_table_read_only(blob_properties);

-- TODO: Separate file?
z_donut_properties = {
    ZDonutIShipX = 0,
    ZDonutIShipY = 1,
    ZDonutISinking = 2,
    ZDonutDonut = 3,
    ZDonutITime = 4,
    ZDonutIX = 5,
    ZDonutIY = 6,
    ZDonutIDT = 7,
    ZDonutIInit = 8,
    ZDonutIBlasts = 9,
    ZDonutIBlastTime = 30,
    ZDonutNoStop = 31,
}
z_donut_properties = read_only.make_table_read_only(z_donut_properties);

-- TODO: Separate file?
local beam_properties = {
    BeamIShipX = 0,
    BeamIShipY = 1,
    BeamISinking = 2,
    BeamIShipZ = 3,
    BeamIBeamColor = 4,
    BeamIBeamType = 5,
    BeamIInit = 6,
    BeamIBeam1 = 7,
    BeamIBeam2 = 8,
    BeamITime = 9,
    BeamIBlast1 = 10,
    BeamIBlast2 = 11,
    BeamIParmDir = 12,
    BeamITargetX = 13,
    BeamITargetY = 14,
    BeamITargetZ = 15,
    BeamIGunX = 16,
    BeamIGunY = 17,
    BeamIGunZ = 18,
    BeamIFireDir = 19,
    BeamIFireAngle = 20,
    BeamIFireLength = 21,
    BeamIOldPX = 22,
    BeamIBT = 23,
    BeamIShowBlast = 24,
    BeamICollideDir = 25,
}
beam_properties = read_only.make_table_read_only(beam_properties);

local kPLAY_AREA_CIRCUMFERENCE = 281;

local g_init_stage_index = 0;

local g_frames_since_level_start = 0;

local g_ship_top_mesh_index;
local g_ship_base_mesh_index;
local g_alien_mesh_index;
local g_eye_1_mesh_index;
local g_eye_2_mesh_index;

local g_previous_player_position_x = 0;

local g_donuts_to_collect_count;

local g_ship_y_rotation = 0;
local g_ship_y_position = 0;
local g_ship_y_velocity = 0;
local g_ship_draw_position_x = 0;
local g_ship_draw_position_y = 0;
local g_ship_sink_amount = 0;
local g_ship_sink_delay_timer = 0;

local g_eye_waggle_x1 = 0;
local g_eye_waggle_y1 = 0;
local g_eye_waggle_x2 = 0;
local g_eye_waggle_y2 = 0;

local g_beams_deployed = false;
local g_beam_1_object_index;
local g_beam_2_object_index;
local g_beam_3_object_index;

local g_z_donut_count = 0;
local g_z_donut_object_indices = {};

local g_beam_count = 0;
local g_beam_object_indices = {};

function update()
    g_frames_since_level_start = g_frames_since_level_start + 1;

    if g_init_stage_index == 1 then
        g_init_stage_index = 2;
        g_ship_top_mesh_index = new_mesh(resources.MeshShipTop);
    end

    if g_init_stage_index == 0 then
        g_init_stage_index = 1;

        g_donuts_to_collect_count = 20;

        set_fog(90, 400, 0, 0, 0);
        set_current_camera_mode(camera_mode.PerspectiveFollow);

        g_alien_mesh_index = new_mesh(resources.MeshAlien1);
        g_eye_1_mesh_index = new_mesh(resources.MeshCube);
        g_eye_2_mesh_index = new_mesh(resources.MeshCube);
        g_ship_base_mesh_index = new_mesh(resources.MeshShipBase);

        g_ship_y_position = 40;

        local iBlob = spawn_object(resources.ScriptBlob);
        set_object_global_data(iBlob, blob_properties.BlobIX, 118);
        set_object_global_data(iBlob, blob_properties.BlobIY, 35);

        iBlob = spawn_object(resources.ScriptBlob);
        set_object_global_data(iBlob, blob_properties.BlobIX, 77);
        set_object_global_data(iBlob, blob_properties.BlobIY, 58);

        iBlob = spawn_object(resources.ScriptBlob);
        set_object_global_data(iBlob, blob_properties.BlobIX, 260);
        set_object_global_data(iBlob, blob_properties.BlobIY, 80);

        iBlob = spawn_object(resources.ScriptBlob);
        set_object_global_data(iBlob, blob_properties.BlobIX, 160);
        set_object_global_data(iBlob, blob_properties.BlobIY, 75);
    end

    RingPlatforms();

    if g_donuts_to_collect_count > 10 then
        g_ship_y_position = 150;
    end

    SetFacing();
    ShowAlien();
    BeginBeams();

    for iItem = 0, g_z_donut_count - 1 do
        set_object_global_data(g_z_donut_object_indices[iItem], z_donut_properties.ZDonutIShipX, g_ship_draw_position_x);
        set_object_global_data(g_z_donut_object_indices[iItem], z_donut_properties.ZDonutIShipY, g_ship_draw_position_y);
        set_object_global_data(g_z_donut_object_indices[iItem], z_donut_properties.ZDonutISinking, g_ship_sink_amount + g_ship_sink_delay_timer);
    end

    for iItem = 0, g_beam_count - 1 do
        set_object_global_data(g_beam_object_indices[iItem], beam_properties.BeamIShipX, g_ship_draw_position_x);
        set_object_global_data(g_beam_object_indices[iItem], beam_properties.BeamIShipY, g_ship_draw_position_y);
        set_object_global_data(g_beam_object_indices[iItem], beam_properties.BeamISinking, g_ship_sink_amount + g_ship_sink_delay_timer);
    end
end

function BeginBeams()
    if g_donuts_to_collect_count > 8 then
        return;
    end

    if g_beams_deployed then
        return;
    end

    local iPoint = get_player_current_position_x() * 360 / kPLAY_AREA_CIRCUMFERENCE;
    iPoint = math.floor(iPoint) & 511;

    g_beam_3_object_index = spawn_object(resources.ScriptBeam);
    set_object_global_data(g_beam_3_object_index, beam_properties.BeamIBeamColor, resources.TextureBrightGreen);
    set_object_global_data(g_beam_3_object_index, beam_properties.BeamIBeamType, 3);
    set_object_global_data(g_beam_3_object_index, beam_properties.BeamITime, g_frames_since_level_start);
    set_object_global_data(g_beam_3_object_index, beam_properties.BeamIParmDir, iPoint);

    g_beam_1_object_index = spawn_object(resources.ScriptBeam);
    set_object_global_data(g_beam_1_object_index, beam_properties.BeamIBeamColor, resources.TextureBrightBlue);
    set_object_global_data(g_beam_1_object_index, beam_properties.BeamIBeamType, 1);
    set_object_global_data(g_beam_1_object_index, beam_properties.BeamITime, g_frames_since_level_start);
    set_object_global_data(g_beam_1_object_index, beam_properties.BeamIParmDir, iPoint);

    g_beam_2_object_index = spawn_object(resources.ScriptBeam);
    set_object_global_data(g_beam_2_object_index, beam_properties.BeamIBeamColor, resources.TextureBrightRed);
    set_object_global_data(g_beam_2_object_index, beam_properties.BeamIBeamType, 2);
    set_object_global_data(g_beam_2_object_index, beam_properties.BeamITime, g_frames_since_level_start);
    set_object_global_data(g_beam_2_object_index, beam_properties.BeamIParmDir, iPoint);

    g_beam_object_indices[g_beam_count] = g_beam_1_object_index;
    g_beam_count = g_beam_count + 1;

    g_beam_object_indices[g_beam_count] = g_beam_2_object_index;
    g_beam_count = g_beam_count + 1;

    g_beam_object_indices[g_beam_count] = g_beam_3_object_index;
    g_beam_count = g_beam_count + 1;

    g_beams_deployed = true;
end

function RefreshDonut(iNumber)
    select_donut(iNumber);
    set_script_selected_level_object_visible(1);
    set_object_visual_data(resources.TextureRedMetal, 1);
end

function SetFacing()
    local iPX = get_player_current_position_x();

    if iPX > 150 and g_previous_player_position_x < 100 then
        g_previous_player_position_x = g_previous_player_position_x + kPLAY_AREA_CIRCUMFERENCE;
    end

    if iPX < 100 and g_previous_player_position_x > 150 then
        g_previous_player_position_x = g_previous_player_position_x - kPLAY_AREA_CIRCUMFERENCE;
    end

    g_ship_y_rotation = g_ship_y_rotation - (1.5 + g_previous_player_position_x - iPX);
    g_previous_player_position_x = iPX;
end

function ShowAlien()
    local iTargetY = get_player_current_position_y() + 30;

    if iTargetY > 80 then
        iTargetY = get_player_current_position_y() - 40;
    end

    if g_ship_sink_delay_timer > 0 then
        g_ship_sink_delay_timer = g_ship_sink_delay_timer - 1;

        if g_ship_sink_delay_timer == 0 then
            g_ship_sink_amount = 0.5;
        end
    end

    if g_ship_sink_amount > 170 then
        win();
    elseif g_ship_sink_amount > 40 then
        g_ship_y_position = g_ship_y_position - 0.2;
        iTargetY= 0 - 100;
        g_ship_sink_amount = g_ship_sink_amount + 0.7;
    elseif g_ship_sink_amount > 20 then
        g_ship_y_position = g_ship_y_position - 0.1;
        iTargetY= 0 - 100;
        g_ship_sink_amount = g_ship_sink_amount + 0.5;
    elseif g_ship_sink_amount > 0 then
        g_ship_y_position = g_ship_y_position - 0.05;
        iTargetY= 0 - 100;
        g_ship_sink_amount = g_ship_sink_amount + 0.3;
    end

    if iTargetY > g_ship_y_position then
        g_ship_y_velocity = g_ship_y_velocity + 0.03;
    end

    if iTargetY < g_ship_y_position then
        g_ship_y_velocity = g_ship_y_velocity - 0.03;
    end

    if g_ship_y_velocity > 0.5 then
        g_ship_y_velocity = 0.5;
    end

    if g_ship_y_velocity < -0.5 then
        g_ship_y_velocity = 0 - 0.5;
    end

    g_ship_y_position = g_ship_y_position + g_ship_y_velocity;

    local iWiggleX = sin(g_frames_since_level_start * 3 / 2) * 200 / 20;
    local iRotateZ = sin(g_frames_since_level_start * 3 / 2) * 200 / 20;

    g_eye_waggle_x1 = AdjustEyeWaggling(g_eye_waggle_x1);
    g_eye_waggle_x2 = AdjustEyeWaggling(g_eye_waggle_x2);
    g_eye_waggle_y1 = AdjustEyeWaggling(g_eye_waggle_y1);
    g_eye_waggle_y2 = AdjustEyeWaggling(g_eye_waggle_y2);

    iWiggleX = iWiggleX - g_ship_sink_amount / 2;
    iRotateZ = iRotateZ + g_ship_sink_amount;

    select_object_mesh(g_eye_1_mesh_index);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_scale_matrix(0.6, 0.6, 0.7);
    script_selected_mesh_translate_matrix(g_eye_waggle_x2 - 1, 0, 0);
    script_selected_mesh_rotate_matrix_z(iRotateZ);
    script_selected_mesh_translate_matrix(get_player_current_position_x() + iWiggleX, g_ship_y_position + 10 + 1 + g_eye_waggle_y1, 59);
    set_object_visual_data(resources.TextureBrightRed, 1);;

    select_object_mesh(g_eye_2_mesh_index);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_scale_matrix(0.6, 0.6, 0.7);
    script_selected_mesh_translate_matrix(1 + g_eye_waggle_x2, 0, 0);
    script_selected_mesh_rotate_matrix_z(iRotateZ);
    script_selected_mesh_translate_matrix(get_player_current_position_x() + iWiggleX, g_ship_y_position + 10 + 1 + g_eye_waggle_y2, 59);
    set_object_visual_data(resources.TextureBrightRed, 1);

    select_object_mesh(g_alien_mesh_index);
    script_selected_mesh_set_identity_matrix();

    if g_frames_since_level_start & 8 then
        script_selected_mesh_change_mesh(resources.MeshAlien1);
    else
        script_selected_mesh_change_mesh(resources.MeshAlien2);
    end

    script_selected_mesh_scale_matrix(0.55, 0.6, 0.7);
    script_selected_mesh_rotate_matrix_z(iRotateZ);
    script_selected_mesh_translate_matrix(get_player_current_position_x() + iWiggleX, g_ship_y_position + 10, 59);
    set_object_visual_data(resources.TextureAlien, 1);

    iWiggleX = iWiggleX + g_ship_sink_amount / 2;

    select_object_mesh(g_ship_base_mesh_index);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_scale_matrix(11, 11, 11);
    script_selected_mesh_rotate_matrix_y(g_ship_y_rotation);
    script_selected_mesh_rotate_matrix_z(iRotateZ);
    script_selected_mesh_translate_matrix(get_player_current_position_x() + iWiggleX, g_ship_y_position, 60);
    set_object_visual_data(resources.TextureShipMetal, 1);

    g_ship_draw_position_x = get_player_current_position_x() + iWiggleX;
    g_ship_draw_position_y = g_ship_y_position;

    if g_init_stage_index == 1 then
        return;
    end

    iWiggleX = iWiggleX - g_ship_sink_amount;

    select_object_mesh(g_ship_top_mesh_index);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_scale_matrix(12, 14, 14);
    script_selected_mesh_rotate_matrix_y(g_ship_y_rotation);
    script_selected_mesh_rotate_matrix_z(iRotateZ);
    script_selected_mesh_translate_matrix(get_player_current_position_x() + iWiggleX, g_ship_sink_amount + g_ship_y_position - 3, 60 - g_ship_sink_amount);
    set_object_visual_data(resources.TextureShipGlass, 1);
end

function AdjustEyeWaggling(iValue)
    local iAdjust = (rnd(1, 100) - 50) / 300;
    local iFinal = iValue + iAdjust;

    if iFinal < -0.4 then
        iFinal= -0.4;
    end

    if iFinal > 0.4 then
        iFinal = 0.4;
    end

    return iFinal;
end

function RingPlatforms()
    local iPX = get_player_current_position_x();

    if iPX < 0 then
        iPX = iPX + kPLAY_AREA_CIRCUMFERENCE;
        set_player_current_position_x(iPX);
        reset_perspective();
    elseif iPX >= kPLAY_AREA_CIRCUMFERENCE then
        iPX = iPX - kPLAY_AREA_CIRCUMFERENCE;
        set_player_current_position_x(iPX);
        reset_perspective();
    end

    select_picture(100);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(iPX - 80, 0, 0);

    local iPlats = get_platform_object_count();

    for iPlat = 0, iPlats - 1 do
        abs_platform(iPlat);
        local x1 = get_script_selected_level_object_x1();
        local x2 = get_script_selected_level_object_x2();
        local iAve = (x1 + x2) / 2;

        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_translate_matrix(0 - iAve, 0, -75);
        script_selected_mesh_scale_matrix(1.64, 1, 1);
        script_selected_mesh_rotate_matrix_y((iPX - iAve) * 360 / kPLAY_AREA_CIRCUMFERENCE);
        script_selected_mesh_translate_matrix(iPX, 0, 75);
    end

    iPlats = get_vine_object_count();

    for iPlat = 0, iPlats - 1 do
        abs_vine(iPlat);
        local iAve = get_script_selected_level_object_x1();

        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_translate_matrix(0 - iAve, 0, -75);
        script_selected_mesh_rotate_matrix_y((iPX - iAve) * 360 / kPLAY_AREA_CIRCUMFERENCE);
        script_selected_mesh_translate_matrix(iPX, 0, 75);
    end

    iPlats = get_ladder_object_count();

    for iPlat = 0, iPlats - 1 do
        abs_ladder(iPlat);
        local iAve = get_script_selected_level_object_x1();

        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_translate_matrix(0 - iAve, 0, -75);
        script_selected_mesh_rotate_matrix_y((iPX - iAve) * 360 / kPLAY_AREA_CIRCUMFERENCE);
        script_selected_mesh_translate_matrix(iPX, 0, 75);
    end

    iPlats = get_donut_object_count();

    for iPlat = 0, iPlats - 1 do
        abs_donut(iPlat);
        local iAve = get_script_selected_level_object_x1();

        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_translate_matrix(0 - iAve, 0, -75);
        script_selected_mesh_rotate_matrix_y((iPX - iAve) * 360 / kPLAY_AREA_CIRCUMFERENCE);
        script_selected_mesh_translate_matrix(iPX, 0, 75);
    end
end

function on_collect_donut()
    local iGot = get_script_event_data_1();

    if g_donuts_to_collect_count < 11 then
        local iFly = spawn_object(resources.ScriptZDonut);
        set_object_global_data(iFly, z_donut_properties.ZDonutDonut, iGot);

        if g_donuts_to_collect_count == 1 then
            set_object_global_data(iFly, z_donut_properties.ZDonutNoStop, 1);
            g_ship_sink_delay_timer = 110;
        end

        g_z_donut_object_indices[g_z_donut_count] = iFly;
        g_z_donut_count = g_z_donut_count + 1;
    end

    g_donuts_to_collect_count = g_donuts_to_collect_count - 1;

    if g_donuts_to_collect_count == 0 then
        g_donuts_to_collect_count = 0;
    elseif g_donuts_to_collect_count < 11 then
        RefreshDonut(11 - g_donuts_to_collect_count);
    end
end

function reset()
    set_player_current_position_x(145);
    set_player_current_position_y(10);
    set_player_current_position_z(3);
    set_player_current_state(player_state.JSNORMAL);
end
