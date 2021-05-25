local read_only = require "data/read_only";
local level27_data_module = assert(loadfile("data/level27_data.lua"));
local game_logic_module = assert(loadfile("data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("data/hud_overlay.lua"));
local beam_module = assert(loadfile("data/beam.lua"));
local blob_module = assert(loadfile("data/blob.lua"));
local z_donut_module = assert(loadfile("data/z_donut.lua"));  -- TODO: Rename?

local Module = {};

Module.MenuLogic = nil;

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

local g_platform_transform_indices = {};
local g_vine_transform_indices = {};
local g_ladder_transform_indices = {};
local g_donut_transform_indices = {};

local g_player_just_respawned = false;

local g_blobs = {};
local g_beams = {};
local g_z_donut_objects = {};

local g_frames_since_level_start = 0;

local g_backdrop_mesh_index = -1;
local g_backdrop_transform_index = -1;

local g_ship_top_mesh_index = -1;
local g_ship_top_transform_index = -1;
local g_ship_base_mesh_index = -1;
local g_ship_base_transform_index = -1;
local g_alien_mesh_index = -1;
local g_alien_transform_index = -1;
local g_eye_1_mesh_index = -1;
local g_eye_1_transform_indices = nil;
local g_eye_2_mesh_index = -1;
local g_eye_2_transform_indices = nil;

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
    local skip_next_interpolation = false;

    local iPX = g_game_logic.get_player_current_position_x();

    if iPX < 0 then
        iPX = iPX + kPLAY_AREA_CIRCUMFERENCE;
        g_game_logic.set_player_current_position_x(iPX);
        g_game_logic.reset_perspective();
        g_game_logic.skip_player_next_mesh_interpolation();
        skip_next_camera_interpolation();
        skip_next_interpolation = true;
    elseif iPX >= kPLAY_AREA_CIRCUMFERENCE then
        iPX = iPX - kPLAY_AREA_CIRCUMFERENCE;
        g_game_logic.set_player_current_position_x(iPX);
        g_game_logic.reset_perspective();
        g_game_logic.skip_player_next_mesh_interpolation();
        skip_next_camera_interpolation();
        skip_next_interpolation = true;
    end

    if g_player_just_respawned then
        g_player_just_respawned = false;
        skip_next_camera_interpolation();
        skip_next_interpolation = true;
    end

    transform_set_translation(g_backdrop_transform_index, iPX - 80, 0, 0);

    if skip_next_interpolation then
        skip_next_mesh_interpolation(g_backdrop_mesh_index);
    end

    local platform_count = g_game_logic.get_platform_object_count();

    for platform_index = 0, platform_count - 1 do
        local current_platform = g_game_logic.get_platform(platform_index);
        local x1 = current_platform.pos_upper_left[1];
        local x2 = current_platform.pos_lower_right[1];
        local iAve = (x1 + x2) / 2;

        transform_set_translation(g_platform_transform_indices[platform_index][1], 0 - iAve, 0, -75);
        transform_set_scale(g_platform_transform_indices[platform_index][2], 1.64, 1, 1);
        transform_set_rotation_y(g_platform_transform_indices[platform_index][2], (iPX - iAve) * 360 / kPLAY_AREA_CIRCUMFERENCE);
        transform_set_translation(g_platform_transform_indices[platform_index][2], iPX, 0, 75);

        if skip_next_interpolation then
            skip_next_mesh_interpolation(current_platform.mesh_index);
        end
    end

    local vine_count = g_game_logic.get_vine_object_count();

    for vine_index = 0, vine_count - 1 do
        local current_vine = g_game_logic.get_vine(vine_index);
        local iAve = current_vine.pos_x;

        transform_set_translation(g_vine_transform_indices[vine_index][1], 0 - iAve, 0, -75);
        transform_set_rotation_y(g_vine_transform_indices[vine_index][2], (iPX - iAve) * 360 / kPLAY_AREA_CIRCUMFERENCE);
        transform_set_translation(g_vine_transform_indices[vine_index][2], iPX, 0, 75);

        if skip_next_interpolation then
            skip_next_mesh_interpolation(current_vine.mesh_index);
        end
    end

    local ladder_count = g_game_logic.get_ladder_object_count();

    for ladder_index = 0, ladder_count - 1 do
        local current_ladder = g_game_logic.get_ladder(ladder_index);
        local iAve = current_ladder.pos_x;

        transform_set_translation(g_ladder_transform_indices[ladder_index][1], 0 - iAve, 0, -75);
        transform_set_rotation_y(g_ladder_transform_indices[ladder_index][2], (iPX - iAve) * 360 / kPLAY_AREA_CIRCUMFERENCE);
        transform_set_translation(g_ladder_transform_indices[ladder_index][2], iPX, 0, 75);

        if skip_next_interpolation then
            skip_next_mesh_interpolation(current_ladder.mesh_index);
        end
    end

    local donut_count = g_game_logic.get_donut_object_count();

    for donut_index = 0, donut_count - 1 do
        local current_donut = g_game_logic.get_donut(donut_index);
        local iAve = current_donut.pos[1];

        transform_set_translation(g_donut_transform_indices[donut_index][1], 0 - iAve, 0, -75);
        transform_set_rotation_y(g_donut_transform_indices[donut_index][2], (iPX - iAve) * 360 / kPLAY_AREA_CIRCUMFERENCE);
        transform_set_translation(g_donut_transform_indices[donut_index][2], iPX, 0, 75);

        if skip_next_interpolation then
            skip_next_mesh_interpolation(current_donut.mesh_index);
        end
    end

    return skip_next_interpolation;
end

local function SetFacing_()
    local iPX = g_game_logic.get_player_current_position_x();

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

local function ShowAlien_(skip_next_interpolation)
    local iTargetY = g_game_logic.get_player_current_position_y() + 30;

    if iTargetY > 80 then
        iTargetY = g_game_logic.get_player_current_position_y() - 40;
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

    transform_set_scale(g_eye_1_transform_indices[1], 0.6, 0.6, 0.7);
    transform_set_translation(g_eye_1_transform_indices[1], g_eye_waggle_x2 - 1, 0, 0);
    transform_set_rotation_z(g_eye_1_transform_indices[2], iRotateZ);
    transform_set_translation(g_eye_1_transform_indices[2], g_game_logic.get_player_current_position_x() + iWiggleX, g_ship_y_position + 10 + 1 + g_eye_waggle_y1, 59);
    set_mesh_texture(g_eye_1_mesh_index, resources.TextureBrightRed);
    set_mesh_is_visible(g_eye_1_mesh_index, true);

    if skip_next_interpolation then
        skip_next_mesh_interpolation(g_eye_1_mesh_index);
    end

    transform_set_scale(g_eye_2_transform_indices[1], 0.6, 0.6, 0.7);
    transform_set_translation(g_eye_2_transform_indices[1], 1 + g_eye_waggle_x2, 0, 0);
    transform_set_rotation_z(g_eye_2_transform_indices[2], iRotateZ);
    transform_set_translation(g_eye_2_transform_indices[2], g_game_logic.get_player_current_position_x() + iWiggleX, g_ship_y_position + 10 + 1 + g_eye_waggle_y2, 59);
    set_mesh_texture(g_eye_2_mesh_index, resources.TextureBrightRed);
    set_mesh_is_visible(g_eye_2_mesh_index, true);

    if skip_next_interpolation then
        skip_next_mesh_interpolation(g_eye_2_mesh_index);
    end

    if g_frames_since_level_start & 8 then
        set_mesh_to_mesh(g_alien_mesh_index, resources.MeshAlien1);
    else
        set_mesh_to_mesh(g_alien_mesh_index, resources.MeshAlien2);
    end

    transform_set_scale(g_alien_transform_index, 0.55, 0.6, 0.7);
    transform_set_rotation_z(g_alien_transform_index, iRotateZ);
    transform_set_translation(g_alien_transform_index, g_game_logic.get_player_current_position_x() + iWiggleX, g_ship_y_position + 10, 59);
    set_mesh_texture(g_alien_mesh_index, resources.TextureAlien);
    set_mesh_is_visible(g_alien_mesh_index, true);

    if skip_next_interpolation then
        skip_next_mesh_interpolation(g_alien_mesh_index);
    end

    iWiggleX = iWiggleX + g_ship_sink_amount / 2;

    transform_set_scale(g_ship_base_transform_index, 11, 11, 11);
    transform_set_rotation_y(g_ship_base_transform_index, g_ship_y_rotation);
    transform_concat_rotation_z(g_ship_base_transform_index, iRotateZ);
    transform_set_translation(g_ship_base_transform_index, g_game_logic.get_player_current_position_x() + iWiggleX, g_ship_y_position, 60);
    set_mesh_texture(g_ship_base_mesh_index, resources.TextureShipMetal);
    set_mesh_is_visible(g_ship_base_mesh_index, true);

    if skip_next_interpolation then
        skip_next_mesh_interpolation(g_ship_base_mesh_index);
    end

    g_ship_draw_position_x = g_game_logic.get_player_current_position_x() + iWiggleX;
    g_ship_draw_position_y = g_ship_y_position;

    iWiggleX = iWiggleX - g_ship_sink_amount;

    transform_set_scale(g_ship_top_transform_index, 12, 14, 14);
    transform_set_rotation_y(g_ship_top_transform_index, g_ship_y_rotation);
    transform_concat_rotation_z(g_ship_top_transform_index, iRotateZ);
    transform_set_translation(g_ship_top_transform_index, g_game_logic.get_player_current_position_x() + iWiggleX, g_ship_sink_amount + g_ship_y_position - 3, 60 - g_ship_sink_amount);
    set_mesh_texture(g_ship_top_mesh_index, resources.TextureShipGlass);
    set_mesh_is_visible(g_ship_top_mesh_index, true);

    if skip_next_interpolation then
        skip_next_mesh_interpolation(g_ship_top_mesh_index);
    end
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
    local iPoint = g_game_logic.get_player_current_position_x() * 360 / kPLAY_AREA_CIRCUMFERENCE;
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

    if player_won then
        g_hud_overlay.update(game_input, false);
        return;
    end

    g_frames_since_level_start = g_frames_since_level_start + 1;

    local skip_next_interpolation = RingPlatforms_();
    g_hud_overlay.update(game_input, skip_next_interpolation);

    if g_donuts_to_collect_count > 10 then
        g_ship_y_position = 150;
    end

    SetFacing_();
    ShowAlien_(skip_next_interpolation);

    if g_donuts_to_collect_count <= 8 and not g_are_beams_deployed then
        g_are_beams_deployed = true;
        BeginBeams_();
    end

    for _, blob in ipairs(g_blobs) do
        blob.update(skip_next_interpolation);
    end

    for _, z_donut in ipairs(g_z_donut_objects) do
        z_donut.ShipPosX = g_ship_draw_position_x;
        z_donut.ShipPosY = g_ship_draw_position_y;
        z_donut.update(skip_next_interpolation);
    end

    for _, beam in ipairs(g_beams) do
        beam.ShipPosX = g_ship_draw_position_x;
        beam.ShipPosY = g_ship_draw_position_y;
        beam.ShipSinkAmount = g_ship_sink_amount + g_ship_sink_delay_timer;
        beam.update(skip_next_interpolation);
    end

    g_game_logic.update_player_graphics();
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

function Module.initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = level27_data_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.OnCollectDonutCallback = Module.on_collect_donut;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.MenuLogic = Module.MenuLogic;
    g_hud_overlay.GameLogic = g_game_logic;

    g_donuts_to_collect_count = 20;

    set_fog(90, 400, 0, 0, 0);
    g_game_logic.set_current_camera_mode(camera_mode.PerspectiveFollow);

    local setup_mesh_transform = function(mesh_index)
        local transform_index = transform_create();
        object_set_transform(mesh_index, transform_index);
        return transform_index;
    end

    local setup_two_mesh_transforms = function(mesh_index)
        local transform_indices = { setup_mesh_transform(mesh_index), transform_create() };
        transform_set_parent(transform_indices[1], transform_indices[2]);
        return transform_indices;
    end

    local platform_count = g_game_logic.get_platform_object_count();

    for platform_index = 0, platform_count - 1 do
        local current_platform = g_game_logic.get_platform(platform_index);
        g_platform_transform_indices[platform_index] = setup_two_mesh_transforms(current_platform.mesh_index);
    end

    local vine_count = g_game_logic.get_vine_object_count();

    for vine_index = 0, vine_count - 1 do
        local current_vine = g_game_logic.get_vine(vine_index);
        g_vine_transform_indices[vine_index] = setup_two_mesh_transforms(current_vine.mesh_index);
    end

    local ladder_count = g_game_logic.get_ladder_object_count();

    for ladder_index = 0, ladder_count - 1 do
        local current_ladder = g_game_logic.get_ladder(ladder_index);
        g_ladder_transform_indices[ladder_index] = setup_two_mesh_transforms(current_ladder.mesh_index);
    end

    local donut_count = g_game_logic.get_donut_object_count();

    for donut_index = 0, donut_count - 1 do
        local current_donut = g_game_logic.get_donut(donut_index);
        g_donut_transform_indices[donut_index] = setup_two_mesh_transforms(current_donut.mesh_index);
    end

    g_backdrop_mesh_index = g_game_logic.find_backdrop_by_number(100).mesh_index;  -- TODO: Use constant
    g_backdrop_transform_index = setup_mesh_transform(g_backdrop_mesh_index);

    g_alien_mesh_index = new_mesh(resources.MeshAlien1);
    g_alien_transform_index = setup_mesh_transform(g_alien_mesh_index);

    g_eye_1_mesh_index = new_mesh(resources.MeshCube);
    g_eye_1_transform_indices = setup_two_mesh_transforms(g_eye_1_mesh_index);

    g_eye_2_mesh_index = new_mesh(resources.MeshCube);
    g_eye_2_transform_indices = setup_two_mesh_transforms(g_eye_2_mesh_index);

    g_ship_base_mesh_index = new_mesh(resources.MeshShipBase);
    g_ship_base_transform_index = setup_mesh_transform(g_ship_base_mesh_index);

    g_ship_top_mesh_index = new_mesh(resources.MeshShipTop);
    g_ship_top_transform_index = setup_mesh_transform(g_ship_top_mesh_index);

    g_ship_y_position = 40;

    local new_blob = CreateBlob_(118, 35);
    table.insert(g_blobs, new_blob);

    new_blob = CreateBlob_(77, 58);
    table.insert(g_blobs, new_blob);

    new_blob = CreateBlob_(260, 80);
    table.insert(g_blobs, new_blob);

    new_blob = CreateBlob_(160, 75);
    table.insert(g_blobs, new_blob);

    Module.reset();

    -- Make sure staged initialization has happened, and Jumpman has floated to the floor
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
end

function Module.update(game_input)
    if not g_title_is_done_scrolling then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input, false);
        return;
    end

    ProgressLevel_(game_input);
end

local function RefreshDonut_(donut_num)
    local current_donut = g_game_logic.find_donut_by_number(donut_num);
    g_game_logic.set_donut_is_collected(current_donut.index, false);
    set_mesh_is_visible(current_donut.mesh_index, true);
end

function Module.on_collect_donut(game_input, donut_num)
    if g_donuts_to_collect_count < 11 then
        local new_z_donut = z_donut_module();
        new_z_donut.GameLogic = g_game_logic;
        new_z_donut.PlayAreaCircumference = kPLAY_AREA_CIRCUMFERENCE;
        new_z_donut.DonutNum = donut_num;
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

function Module.reset()
    g_game_logic.set_player_current_position_x(145);
    g_game_logic.set_player_current_position_y(10);
    g_game_logic.set_player_current_position_z(3);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
    g_player_just_respawned = true;
end

return Module;
