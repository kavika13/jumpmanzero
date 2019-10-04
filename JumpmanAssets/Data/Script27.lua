local read_only = require "Data/read_only";
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local beam_module = assert(loadfile("Data/beam.lua"));
local blob_module = assert(loadfile("Data/blob.lua"));
local z_donut_module = assert(loadfile("Data/z_donut.lua"));  -- TODO: Rename?

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
};
player_state = read_only.make_table_read_only(player_state);

-- TODO: Move this into a shared file, split into separate tables by type
local camera_mode = {
    PerspectiveNormal = 0,
    PerspectiveCloseUp = 1,
    PerspectiveFar = 2,
    PerspectiveWide = 3,
    PerspectiveFollow = 4,
    PerspectiveFixed = 5,
};
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
};
resources = read_only.make_table_read_only(resources);

local kPLAY_AREA_CIRCUMFERENCE = 281;

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_blobs = {};
local g_beams = {};
local g_z_donut_objects = {};

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

local g_are_beams_deployed = false;

local function RingPlatforms_()
    local iPX = get_player_current_position_x();

    if iPX < 0 then
        iPX = iPX + kPLAY_AREA_CIRCUMFERENCE;
        set_player_current_position_x(iPX);
        g_game_logic.reset_perspective();
    elseif iPX >= kPLAY_AREA_CIRCUMFERENCE then
        iPX = iPX - kPLAY_AREA_CIRCUMFERENCE;
        set_player_current_position_x(iPX);
        g_game_logic.reset_perspective();
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

local function SetFacing_()
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

local function AdjustEyeWaggling_(iValue)
    local iAdjust = (math.random(1, 100) - 50) / 300;
    local iFinal = iValue + iAdjust;

    if iFinal < -0.4 then
        iFinal= -0.4;
    end

    if iFinal > 0.4 then
        iFinal = 0.4;
    end

    return iFinal;
end

local function ShowAlien_()
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
        g_game_logic.win();
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

    local iWiggleX = math.sin(g_frames_since_level_start * 3 / 2 * math.pi / 180.0) * 10;
    local iRotateZ = math.sin(g_frames_since_level_start * 3 / 2 * math.pi / 180.0) * 10;

    g_eye_waggle_x1 = AdjustEyeWaggling_(g_eye_waggle_x1);
    g_eye_waggle_x2 = AdjustEyeWaggling_(g_eye_waggle_x2);
    g_eye_waggle_y1 = AdjustEyeWaggling_(g_eye_waggle_y1);
    g_eye_waggle_y2 = AdjustEyeWaggling_(g_eye_waggle_y2);

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

    iWiggleX = iWiggleX - g_ship_sink_amount;

    select_object_mesh(g_ship_top_mesh_index);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_scale_matrix(12, 14, 14);
    script_selected_mesh_rotate_matrix_y(g_ship_y_rotation);
    script_selected_mesh_rotate_matrix_z(iRotateZ);
    script_selected_mesh_translate_matrix(get_player_current_position_x() + iWiggleX, g_ship_sink_amount + g_ship_y_position - 3, 60 - g_ship_sink_amount);
    set_object_visual_data(resources.TextureShipGlass, 1);
end

local function CreateBeam_(beam_type, beam_color_texture_resource_index, parm_dir)
    local new_beam = beam_module();
    new_beam.GameLogic = g_game_logic;
    new_beam.PlayAreaCircumference = kPLAY_AREA_CIRCUMFERENCE;
    new_beam.BeamMeshResourceIndex = resources.MeshBeam;
    new_beam.BeamTextureResourceIndex = resources.TextureBeam;
    new_beam.BlastMeshResourceIndex = resources.MeshSquare;
    new_beam.BlastTextureResourceIndex = resources.TextureBlast1;
    new_beam.BeamColorTextureResourceIndex = beam_color_texture_resource_index;
    new_beam.BeamType = beam_type;
    new_beam.ParmDir = parm_dir;
    new_beam.initialize();
    return new_beam;
end

local function BeginBeams_()
    local iPoint = get_player_current_position_x() * 360 / kPLAY_AREA_CIRCUMFERENCE;
    iPoint = math.floor(iPoint) & 511;

    local beam_3 = CreateBeam_(3, resources.TextureBrightGreen, iPoint);
    local beam_1 = CreateBeam_(1, resources.TextureBrightBlue, iPoint);
    local beam_2 = CreateBeam_(2, resources.TextureBrightRed, iPoint);
    table.insert(g_beams, beam_1);
    table.insert(g_beams, beam_2);
    table.insert(g_beams, beam_3);
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    g_frames_since_level_start = g_frames_since_level_start + 1;

    RingPlatforms_();

    if g_donuts_to_collect_count > 10 then
        g_ship_y_position = 150;
    end

    SetFacing_();
    ShowAlien_();

    if g_donuts_to_collect_count <= 8 and not g_are_beams_deployed then
        g_are_beams_deployed = true;
        BeginBeams_();
    end

    for _, blob in ipairs(g_blobs) do
        blob.update();
    end

    for _, z_donut in ipairs(g_z_donut_objects) do
        z_donut.ShipPosX = g_ship_draw_position_x;
        z_donut.ShipPosY = g_ship_draw_position_y;
        z_donut.update();
    end

    for _, beam in ipairs(g_beams) do
        beam.ShipPosX = g_ship_draw_position_x;
        beam.ShipPosY = g_ship_draw_position_y;
        beam.ShipSinkAmount = g_ship_sink_amount + g_ship_sink_delay_timer;
        beam.update();
    end
end

local function CreateBlob_(start_pos_x, start_pos_y)
    local new_blob = blob_module();
    new_blob.GameLogic = g_game_logic;
    new_blob.PlayAreaCircumference = kPLAY_AREA_CIRCUMFERENCE;
    new_blob.StartPosX = start_pos_x;
    new_blob.StartPosY = start_pos_y;
    new_blob.MoveRightMeshResourceIndices = { resources.MeshBlob1, resources.MeshBlob2, resources.MeshBlob3, resources.MeshBlob4 };
    new_blob.MoveLeftMeshResourceIndices = { resources.MeshBlob4, resources.MeshBlob2L, resources.MeshBlob3L, resources.MeshBlob1 };
    new_blob.TextureResourceIndex = resources.TextureAlien;
    new_blob.initialize();
    return new_blob;
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.ResetPlayerCallback = reset;
    g_game_logic.OnCollectDonutCallback = on_collect_donut;

    g_hud_overlay = hud_overlay_module();

    g_donuts_to_collect_count = 20;

    set_fog(90, 400, 0, 0, 0);
    g_game_logic.set_current_camera_mode(camera_mode.PerspectiveFollow);

    g_alien_mesh_index = new_mesh(resources.MeshAlien1);
    g_eye_1_mesh_index = new_mesh(resources.MeshCube);
    g_eye_2_mesh_index = new_mesh(resources.MeshCube);
    g_ship_base_mesh_index = new_mesh(resources.MeshShipBase);

    g_ship_y_position = 40;

    local new_blob = CreateBlob_(118, 35);
    table.insert(g_blobs, new_blob);

    new_blob = CreateBlob_(77, 58);
    table.insert(g_blobs, new_blob);

    new_blob = CreateBlob_(260, 80);
    table.insert(g_blobs, new_blob);

    new_blob = CreateBlob_(160, 75);
    table.insert(g_blobs, new_blob);

    g_ship_top_mesh_index = new_mesh(resources.MeshShipTop);

    reset();

    -- Make sure staged initialization has happened, and Jumpman has floated to the floor
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
end

function update(game_input)
    if not g_title_is_done_scrolling then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return;
    end

    ProgressLevel_(game_input);
end

local function RefreshDonut_(donut_index)
    select_donut(donut_index);
    set_script_selected_level_object_visible(1);
    set_object_visual_data(resources.TextureRedMetal, 1);
end

function on_collect_donut(game_input, iGot)
    if g_donuts_to_collect_count < 11 then
        local new_z_donut = z_donut_module();
        new_z_donut.PlayAreaCircumference = kPLAY_AREA_CIRCUMFERENCE;
        new_z_donut.DonutIndex = iGot;
        new_z_donut.DonutTextureResourceIndex = resources.TextureRedMetal;
        new_z_donut.LightningTextureResourceIndex = resources.TextureLightning;
        new_z_donut.BlastParticleMeshResourceIndex = resources.MeshSquare;
        new_z_donut.BlastSoundResourceIndex = resources.SoundClasBomb;

        if g_donuts_to_collect_count == 1 then
            new_z_donut.IsLongFinalBlast = true;
            g_ship_sink_delay_timer = 110;
        end

        new_z_donut.initialize();

        table.insert(g_z_donut_objects, new_z_donut);
    end

    g_donuts_to_collect_count = g_donuts_to_collect_count - 1;

    if g_donuts_to_collect_count == 0 then
        g_donuts_to_collect_count = 0;
    elseif g_donuts_to_collect_count < 11 then
        RefreshDonut_(11 - g_donuts_to_collect_count);
    end
end

function reset()
    set_player_current_position_x(145);
    set_player_current_position_y(10);
    set_player_current_position_z(3);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end
