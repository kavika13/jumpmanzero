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
        local wall_mesh_index = find_wall_mesh_index(33);  -- TODO: Use constant for num
        set_identity_mesh_matrix(wall_mesh_index);
        translate_mesh_matrix(wall_mesh_index, 0, 0, g_wall_animation_frame / 10);

        if g_wall_animation_frame == 45 then
            local wall_index = find_wall_index(33);  -- TODO: Use constant for num
            set_wall_y1(wall_index, 0 - 26);
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

    local backdrop_mesh_index = find_backdrop_mesh_index(1);  -- TODO: Use constant for num
    set_identity_mesh_matrix(backdrop_mesh_index);
    translate_mesh_matrix(backdrop_mesh_index, iPX, iPY, 0);

    if g_spotlight_animation_frame > 2 then
        set_mesh_texture(backdrop_mesh_index, resources.TextureRing2);
    else
        set_mesh_texture(backdrop_mesh_index, resources.TextureRing);
    end

    backdrop_mesh_index = find_backdrop_mesh_index(2);  -- TODO: Use constant for num
    set_identity_mesh_matrix(backdrop_mesh_index);
    translate_mesh_matrix(backdrop_mesh_index, iPX, iPY, 0);

    backdrop_mesh_index = find_backdrop_mesh_index(3);  -- TODO: Use constant for num
    set_identity_mesh_matrix(backdrop_mesh_index);
    translate_mesh_matrix(backdrop_mesh_index, iPX, iPY, 0);

    backdrop_mesh_index = find_backdrop_mesh_index(4);  -- TODO: Use constant for num
    set_identity_mesh_matrix(backdrop_mesh_index);
    translate_mesh_matrix(backdrop_mesh_index, iPX, iPY, 0);

    backdrop_mesh_index = find_backdrop_mesh_index(5);  -- TODO: Use constant for num
    set_identity_mesh_matrix(backdrop_mesh_index);
    translate_mesh_matrix(backdrop_mesh_index, iPX, iPY, 0);

    g_painting_with_eyes_animation_frame = g_painting_with_eyes_animation_frame + 1;

    backdrop_mesh_index = find_backdrop_mesh_index(100);  -- TODO: Use constant for num
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
        local vine_index = find_vine_index(1);  -- TODO: Use constant for num
        set_vine_y2(vine_index, get_vine_y2(vine_index) + 6);
        set_vine_y1(vine_index, get_vine_y1(vine_index) + 6);
        local vine_mesh_index = find_vine_mesh_index(1);  -- TODO: Use constant for num
        set_identity_mesh_matrix(vine_mesh_index);
        translate_mesh_matrix(vine_mesh_index, 0, 6, 0);
        -- TODO: There is an engine function for this, but it is not exposed. Seems to be automatically called?
        -- setext(#compose, 1);
    end

    if iDonut == 2 then
        local vine_index = find_vine_index(2);  -- TODO: Use constant for num
        set_vine_y2(vine_index, get_vine_y2(vine_index) + 8);
        set_vine_y1(vine_index, get_vine_y1(vine_index) + 8);
        local vine_mesh_index = find_vine_mesh_index(2);  -- TODO: Use constant for num
        set_identity_mesh_matrix(vine_mesh_index);
        translate_mesh_matrix(vine_mesh_index, 0, 8, 0);
        -- TODO: There is an engine function for this, but it is not exposed. Seems to be automatically called?
        -- setext(#compose, 1);
    end

    if iDonut == 3 then
        local wall_index = find_wall_index(2);  -- TODO: Use constant for num
        set_wall_y1(wall_index, get_wall_y1(wall_index) - 26);
        local wall_mesh_index = find_wall_mesh_index(2);  -- TODO: Use constant for num
        set_identity_mesh_matrix(wall_mesh_index);
        translate_mesh_matrix(wall_mesh_index, 0, 0 - 70, 0);

        local backdrop_mesh_index = find_backdrop_mesh_index(12);  -- TODO: Use constant for num
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
