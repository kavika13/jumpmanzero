local read_only = require "data/read_only";
local level6_data_module = assert(loadfile("data/level6_data.lua"));
local game_logic_module = assert(loadfile("data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("data/hud_overlay.lua"));
local ghost_module = assert(loadfile("data/ghost.lua"));

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
    TextureDarkWoodPlatform = 1,
    TextureYellowRope = 2,
    TextureRedMetal = 3,
    TextureBlack = 4,
    TextureDark = 5,
    ScriptGhost = 0,
    TextureRing = 6,
    TextureRing2 = 7,
    TextureWoodLadder = 8,
    MeshGhostLeft = 0,
    MeshGhostRight = 1,
    MeshGhostLeft2 = 2,
    MeshGhostRight2 = 3,
    TextureConcrete = 9,
    TextureGhostTexture = 10,
    TexturePillar = 11,
    SoundJump = 0,
    SoundCreak = 1,
    SoundBonk = 2,
    TexturePainting = 12,
    TexturePainting2 = 13,
};
resources = read_only.make_table_read_only(resources);

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_ghost;

local g_vignette_backdrop = nil;
local g_vignette_backdrop_transform_index = -1;
local g_black_border_top_backdrop = nil;
local g_black_border_top_backdrop_transform_index = -1;
local g_black_border_left_backdrop = nil;
local g_black_border_left_backdrop_transform_index = -1;
local g_black_border_right_backdrop = nil;
local g_black_border_right_backdrop_transform_index = -1;
local g_black_border_bottom_backdrop = nil;
local g_black_border_bottom_backdrop_transform_index = -1;
local g_donut_tomb_backdrop = nil;
local g_donut_tomb_backdrop_transform_index = -1;
local g_painting_with_eyes_backdrop = nil;

local g_donut_tomb_door_wall = nil;
local g_donut_tomb_door_wall_transform_index = -1;
local g_moving_wall_by_start = nil;
local g_moving_wall_by_start_transform_index = -1;

local g_moving_vine_top_left = nil;
local g_moving_vine_top_left_transform_index = -1;
local g_moving_vine_mid_right = nil;
local g_moving_vine_mid_right_transform_index = -1;

local g_is_wall_moving = false;
local g_wall_animation_frame = 0;
local g_spotlight_animation_frame = 0;
local g_painting_with_eyes_animation_frame = 0;

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    if g_is_wall_moving then
        g_wall_animation_frame = g_wall_animation_frame + 1;
        transform_set_translation(g_moving_wall_by_start_transform_index, 0, 0, g_wall_animation_frame / 10);

        if g_wall_animation_frame == 45 then
            g_moving_wall_by_start.set_pos_y1(-26);
            g_wall_animation_frame = 0;
            g_is_wall_moving = false;
        end
    end

    local iPX = g_game_logic.get_player_current_position_x() - 90;
    local iPY = g_game_logic.get_player_current_position_y() - 70;

    g_spotlight_animation_frame = g_spotlight_animation_frame + 1;

    if g_spotlight_animation_frame == 6 then
        g_spotlight_animation_frame = 0;
    end

    transform_set_translation(g_vignette_backdrop_transform_index, iPX, iPY, 0);

    if g_spotlight_animation_frame > 2 then
        set_mesh_texture(g_vignette_backdrop.mesh_index, resources.TextureRing2);
    else
        set_mesh_texture(g_vignette_backdrop.mesh_index, resources.TextureRing);
    end

    transform_set_translation(g_black_border_top_backdrop_transform_index, iPX, iPY, 0);
    transform_set_translation(g_black_border_left_backdrop_transform_index, iPX, iPY, 0);
    transform_set_translation(g_black_border_right_backdrop_transform_index, iPX, iPY, 0);
    transform_set_translation(g_black_border_bottom_backdrop_transform_index, iPX, iPY, 0);

    g_painting_with_eyes_animation_frame = g_painting_with_eyes_animation_frame + 1;

    set_mesh_texture(g_painting_with_eyes_backdrop.mesh_index, resources.TexturePainting);

    if g_painting_with_eyes_animation_frame > 10 then
        set_mesh_texture(g_painting_with_eyes_backdrop.mesh_index, resources.TexturePainting2);
    end

    if g_painting_with_eyes_animation_frame > 20 then
        g_painting_with_eyes_animation_frame = 0;
    end

    g_ghost.update();

    g_game_logic.update_player_graphics();
end

function Module.initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = level6_data_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.OnCollectDonutCallback = Module.on_collect_donut;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.MenuLogic = Module.MenuLogic;
    g_hud_overlay.GameLogic = g_game_logic;

    g_game_logic.set_current_camera_mode(camera_mode.PerspectiveCloseUp);

    g_ghost = ghost_module();
    g_ghost.GameLogic = g_game_logic;
    g_ghost.MoveRight1MeshResourceIndex = resources.MeshGhostRight;
    g_ghost.MoveRight2MeshResourceIndex = resources.MeshGhostRight2;
    g_ghost.MoveLeft1MeshResourceIndex = resources.MeshGhostLeft;
    g_ghost.MoveLeft2MeshResourceIndex = resources.MeshGhostLeft2;
    g_ghost.TextureResourceIndex = resources.TextureGhostTexture;
    g_ghost.initialize();

    local setup_object_transform = function(mesh_index)
        local result = transform_create();
        object_set_transform(mesh_index, result);
        return result;
    end

    g_vignette_backdrop = g_game_logic.find_backdrop_by_number(1);  -- TODO: Use constant for num
    g_vignette_backdrop_transform_index = setup_object_transform(g_vignette_backdrop.mesh_index);

    g_black_border_top_backdrop = g_game_logic.find_backdrop_by_number(2);  -- TODO: Use constant for num
    g_black_border_top_backdrop_transform_index = setup_object_transform(g_black_border_top_backdrop.mesh_index);

    g_black_border_left_backdrop = g_game_logic.find_backdrop_by_number(3);  -- TODO: Use constant for num
    g_black_border_left_backdrop_transform_index = setup_object_transform(g_black_border_left_backdrop.mesh_index);

    g_black_border_right_backdrop = g_game_logic.find_backdrop_by_number(4);  -- TODO: Use constant for num
    g_black_border_right_backdrop_transform_index = setup_object_transform(g_black_border_right_backdrop.mesh_index);

    g_black_border_bottom_backdrop = g_game_logic.find_backdrop_by_number(5);  -- TODO: Use constant for num
    g_black_border_bottom_backdrop_transform_index = setup_object_transform(g_black_border_bottom_backdrop.mesh_index);

    g_painting_with_eyes_backdrop = g_game_logic.find_backdrop_by_number(100);  -- TODO: Use constant for num
    -- Don't need transform for g_painting_with_eyes_backdrop

    g_donut_tomb_backdrop = g_game_logic.find_backdrop_by_number(12);  -- TODO: Use constant for num
    g_donut_tomb_backdrop_transform_index = setup_object_transform(g_donut_tomb_backdrop.mesh_index);

    g_donut_tomb_door_wall = g_game_logic.find_wall_by_number(2);  -- TODO: Use constant for num
    g_donut_tomb_door_wall_transform_index = setup_object_transform(g_donut_tomb_door_wall.mesh_index);

    g_moving_vine_top_left = g_game_logic.find_vine_by_number(2);  -- TODO: Use constant for num
    g_moving_vine_top_left_transform_index = setup_object_transform(g_moving_vine_top_left.mesh_index);

    g_moving_vine_mid_right = g_game_logic.find_vine_by_number(1);  -- TODO: Use constant for num
    g_moving_vine_mid_right_transform_index = setup_object_transform(g_moving_vine_mid_right.mesh_index);

    g_moving_wall_by_start = g_game_logic.find_wall_by_number(33);  -- TODO: Use constant for num
    g_moving_wall_by_start_transform_index = setup_object_transform(g_moving_wall_by_start.mesh_index);

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
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return;
    end

    ProgressLevel_(game_input);
end

function Module.on_collect_donut(game_input, iDonut)
    if iDonut == 1 then
        g_is_wall_moving = true;
        g_wall_animation_frame = 1;  -- TODO: Is this necessary to do here?
        g_moving_vine_mid_right.set_pos_y_bottom(g_moving_vine_mid_right.pos_y_bottom + 6);
        g_moving_vine_mid_right.set_pos_y_top(g_moving_vine_mid_right.pos_y_top + 6);
        transform_set_translation(g_moving_vine_mid_right_transform_index, 0, 6, 0);
    end

    if iDonut == 2 then
        g_moving_vine_top_left.set_pos_y_bottom(g_moving_vine_top_left.pos_y_bottom + 8);
        g_moving_vine_top_left.set_pos_y_top(g_moving_vine_top_left.pos_y_top + 8);
        transform_set_translation(g_moving_vine_top_left_transform_index, 0, 8, 0);
    end

    if iDonut == 3 then
        g_donut_tomb_door_wall.set_pos_y1(g_donut_tomb_door_wall.pos[1][2] - 26);
        transform_set_translation(g_donut_tomb_door_wall_transform_index, 0, 0 - 70, 0);
        transform_set_translation(g_donut_tomb_backdrop_transform_index, 0, 0 - 70, 0);
    end
end

function Module.reset()
    g_game_logic.set_player_current_position_x(96);
    g_game_logic.set_player_current_position_y(73);
    g_game_logic.set_player_current_position_z(9);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end

return Module;
