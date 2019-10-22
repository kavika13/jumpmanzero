local read_only = require "Data/read_only";
local level_level6_module = assert(loadfile("Data/level_level6.lua"));
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local ghost_module = assert(loadfile("Data/ghost.lua"));

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
        local current_wall = g_game_logic.find_wall_by_number(33);  -- TODO: Use constant for num
        set_identity_mesh_matrix(current_wall.mesh_index);
        translate_mesh_matrix(current_wall.mesh_index, 0, 0, g_wall_animation_frame / 10);

        if g_wall_animation_frame == 45 then
            current_wall.set_pos_y1(-26);
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

    local backdrop_mesh_index = g_game_logic.find_backdrop_by_number(1).mesh_index;  -- TODO: Use constant for num
    set_identity_mesh_matrix(backdrop_mesh_index);
    translate_mesh_matrix(backdrop_mesh_index, iPX, iPY, 0);

    if g_spotlight_animation_frame > 2 then
        set_mesh_texture(backdrop_mesh_index, resources.TextureRing2);
    else
        set_mesh_texture(backdrop_mesh_index, resources.TextureRing);
    end

    backdrop_mesh_index = g_game_logic.find_backdrop_by_number(2).mesh_index;  -- TODO: Use constant for num
    set_identity_mesh_matrix(backdrop_mesh_index);
    translate_mesh_matrix(backdrop_mesh_index, iPX, iPY, 0);

    backdrop_mesh_index = g_game_logic.find_backdrop_by_number(3).mesh_index;  -- TODO: Use constant for num
    set_identity_mesh_matrix(backdrop_mesh_index);
    translate_mesh_matrix(backdrop_mesh_index, iPX, iPY, 0);

    backdrop_mesh_index = g_game_logic.find_backdrop_by_number(4).mesh_index;  -- TODO: Use constant for num
    set_identity_mesh_matrix(backdrop_mesh_index);
    translate_mesh_matrix(backdrop_mesh_index, iPX, iPY, 0);

    backdrop_mesh_index = g_game_logic.find_backdrop_by_number(5).mesh_index;  -- TODO: Use constant for num
    set_identity_mesh_matrix(backdrop_mesh_index);
    translate_mesh_matrix(backdrop_mesh_index, iPX, iPY, 0);

    g_painting_with_eyes_animation_frame = g_painting_with_eyes_animation_frame + 1;

    backdrop_mesh_index = g_game_logic.find_backdrop_by_number(100).mesh_index;  -- TODO: Use constant for num
    set_mesh_texture(backdrop_mesh_index, resources.TexturePainting);

    if g_painting_with_eyes_animation_frame > 10 then
        set_mesh_texture(backdrop_mesh_index, resources.TexturePainting2);
    end

    if g_painting_with_eyes_animation_frame > 20 then
        g_painting_with_eyes_animation_frame = 0;
    end

    g_ghost.update();

    g_game_logic.update_player_graphics();
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.LevelData = level_level6_module();
    g_game_logic.ResetPlayerCallback = reset;
    g_game_logic.OnCollectDonutCallback = on_collect_donut;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
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

function on_collect_donut(game_input, iDonut)
    if iDonut == 1 then
        g_is_wall_moving = true;
        g_wall_animation_frame = 1;  -- TODO: Is this necessary to do here?
        local current_vine = g_game_logic.find_vine_by_number(1);  -- TODO: Use constant for num
        current_vine.set_pos_y_bottom(current_vine.pos_y_bottom + 6);
        current_vine.set_pos_y_top(current_vine.pos_y_top + 6);
        set_identity_mesh_matrix(current_vine.mesh_index);
        translate_mesh_matrix(current_vine.mesh_index, 0, 6, 0);
        -- TODO: There is an engine function for this, but it is not exposed. Seems to be automatically called?
        -- setext(#compose, 1);
    end

    if iDonut == 2 then
        local current_vine = g_game_logic.find_vine_by_number(2);  -- TODO: Use constant for num
        current_vine.set_pos_y_bottom(current_vine.pos_y_bottom + 8);
        current_vine.set_pos_y_top(current_vine.pos_y_top + 8);
        set_identity_mesh_matrix(current_vine.mesh_index);
        translate_mesh_matrix(current_vine.mesh_index, 0, 8, 0);
        -- TODO: There is an engine function for this, but it is not exposed. Seems to be automatically called?
        -- setext(#compose, 1);
    end

    if iDonut == 3 then
        local current_wall = g_game_logic.find_wall_by_number(2);  -- TODO: Use constant for num
        current_wall.set_pos_y1(current_wall.pos[1][2] - 26);
        set_identity_mesh_matrix(current_wall.mesh_index);
        translate_mesh_matrix(current_wall.mesh_index, 0, 0 - 70, 0);

        local backdrop_mesh_index = g_game_logic.find_backdrop_by_number(12).mesh_index;  -- TODO: Use constant for num
        set_identity_mesh_matrix(backdrop_mesh_index);
        translate_mesh_matrix(backdrop_mesh_index, 0, 0 - 70, 0);
        -- TODO: There is an engine function for this, but it is not exposed. Seems to be automatically called?
        -- setext(#compose, 1);
    end
end

function reset()
    g_game_logic.set_player_current_position_x(96);
    g_game_logic.set_player_current_position_y(73);
    g_game_logic.set_player_current_position_z(9);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end
