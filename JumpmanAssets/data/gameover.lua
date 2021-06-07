local read_only = require "data/read_only";
local gameover_data_module = assert(loadfile("data/gameover_data.lua"));
local game_logic_module = assert(loadfile("data/game_logic.lua"));

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

-- TODO: Move this into a shared file, split into separate tables by type. Or inject from engine?
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
    TextureClassicPlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureSpaceBack = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    MeshDead = 0,
    MeshStars = 1,
    TextureBoringGray = 5,
    TextureNewMetal = 6,
};
resources = read_only.make_table_read_only(resources);

local g_game_logic;

local g_jumpman_mesh_index = -1;
local g_jumpman_transform_index = -1;
local g_game_over_letter_mesh_indices = {};
local g_game_over_letter_transform_indices = {};
local g_game_over_message_visible = false;
local g_camera_pan_animation_timer = 0;
local g_letter_drop_animation_timer = 0;
local g_animation_skipped = 0;

local function ProgressLevel_(game_input)
    g_game_logic.set_player_freeze_cooldown_frame_count(100);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
    g_game_logic.progress_game(game_input);

    set_fog(100, 200, 0, 0, 0);
    g_game_logic.set_current_camera_mode(camera_mode.PerspectiveCloseUp);
    g_game_logic.set_player_is_visible(false);

    if g_camera_pan_animation_timer > 25 then
        g_camera_pan_animation_timer = g_camera_pan_animation_timer - 0.5;
    elseif g_camera_pan_animation_timer > 10 then
        g_camera_pan_animation_timer = g_camera_pan_animation_timer - 0.3;
    elseif g_camera_pan_animation_timer > 0 then
        g_camera_pan_animation_timer = g_camera_pan_animation_timer - 0.2;
    else
        g_camera_pan_animation_timer = 0;
    end

    if not g_game_over_message_visible and g_camera_pan_animation_timer == 0 then
        local game_over_message = "gameover";

        for iLet = 1, #game_over_message do
            g_game_over_letter_mesh_indices[iLet] = g_game_logic.new_char_mesh(game_over_message:sub(iLet, iLet):byte(1, -1));
            g_game_over_letter_transform_indices[iLet] = transform_create();
            mesh_set_transform(g_game_over_letter_mesh_indices[iLet], g_game_over_letter_transform_indices[iLet]);
            set_mesh_texture(g_game_over_letter_mesh_indices[iLet], resources.TextureNewMetal);
        end

        g_game_over_message_visible = true;

        if g_letter_drop_animation_timer ~= 1 then
            g_letter_drop_animation_timer = 115;
        end
    end

    if g_letter_drop_animation_timer > 0 then
        g_letter_drop_animation_timer = g_letter_drop_animation_timer - 3;

        for letter_index, current_mesh_index in ipairs(g_game_over_letter_mesh_indices) do
            local current_transform_index = g_game_over_letter_transform_indices[letter_index];
            transform_set_scale(current_transform_index, 2, 2, 1);

            local iTemp = g_letter_drop_animation_timer + letter_index * 5 - 50;

            if iTemp < 0 then
                iTemp = 0;
            end

            iTemp = iTemp + 60;
            local iX = 18 + letter_index * 13;

            if letter_index > 4 then
                iX = iX + 5;
            end

            transform_set_translation(current_transform_index, iX, iTemp, 0);
            set_mesh_is_visible(current_mesh_index, true);
        end
    end

    set_fog(80, 150 + g_camera_pan_animation_timer * 3, 0, 0, 0);

    g_game_logic.set_player_current_position_x(80);
    g_game_logic.set_player_current_position_y(70 + g_camera_pan_animation_timer);

    transform_set_scale(g_jumpman_transform_index, 3, 3, 3);
    transform_set_translation(g_jumpman_transform_index, 80, 80, 0);
    set_mesh_is_visible(g_jumpman_mesh_index, true);

    if g_animation_skipped > 0 and g_animation_skipped < 3 then  -- TODO: why all these skips required for camera?
        skip_next_mesh_interpolation(g_jumpman_mesh_index);
        skip_next_camera_interpolation();
        g_animation_skipped = g_animation_skipped + 1;
    end

    local is_select_action_pressed = game_input.select_action.just_pressed;

    if is_select_action_pressed and g_letter_drop_animation_timer < 0 then
        Module.MenuLogic.load_next_level_from_set();
    end

    if is_select_action_pressed and g_camera_pan_animation_timer > 0 then
        g_camera_pan_animation_timer = 0;
        g_letter_drop_animation_timer = 1;
        g_animation_skipped = 1;
    end

    g_game_logic.update_player_graphics();
end

function Module.initialize(game_input)
    -- TODO: Figure out how to get player not to blink in on first frame. Is it due to camera interpolation?
    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = gameover_data_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.initialize();

    g_jumpman_mesh_index = new_mesh(resources.MeshDead);
    g_jumpman_transform_index = transform_create();
    mesh_set_transform(g_jumpman_mesh_index, g_jumpman_transform_index);
    set_mesh_texture(g_jumpman_mesh_index, resources.TextureJumpman);

    local platform_mesh_index = g_game_logic.find_platform_by_number(1).mesh_index;  -- TODO: Use constant for num
    local platform_transform_index = transform_create();
    mesh_set_transform(platform_mesh_index, platform_transform_index);
    transform_set_scale(platform_transform_index, 30, 3, 3);
    g_game_over_message_visible = false;
    g_camera_pan_animation_timer = 100;

    Module.reset();

    -- Make sure staged initialization has happened, and Jumpman has floated to the floor
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);

    skip_next_camera_interpolation();
end

function Module.update(game_input)
    ProgressLevel_(game_input);
end

function Module.reset()
    g_game_logic.set_player_current_position_x(0);
    g_game_logic.set_player_current_position_y(0);
    g_game_logic.set_player_current_position_z(0);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end

return Module;
