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

-- TODO: Move this into a shared file, split into separate tables by type. Or inject from engine?
local camera_mode = {
        PerspectiveNormal = 0,
        PerspectiveCloseUp = 1,
        PerspectiveFar = 2,
        PerspectiveWide = 3,
        PerspectiveFollow = 4,
        PerspectiveFixed = 5,
}
camera_mode = read_only.make_table_read_only(camera_mode);

-- TODO: Move this into a shared file, split into separate tables by type. Or inject from engine?
local service_type = {
    SERVICE_GAMELIST = 128,
    SERVICE_STARTGAME = 129,
    SERVICE_LOADMENU = 130,

    SERVICE_OPTIONSTRING = 142,
    SERVICE_SETOPTION = 143,
    SERVICE_SAVEOPTIONS = 144,

    SERVICE_LEVELTITLE = 154,
    SERVICE_CREDITLINE = 155,
}
service_type = read_only.make_table_read_only(service_type);

-- TODO: Move this into a shared file, split into separate tables by type. Or inject from engine?
local menu_type = {
    MENU_MAIN = 1,
    MENU_OPTIONS = 2,
    MENU_SELECTGAME = 3,
    MENU_SELECTLEVEL = 4,
}
menu_type = read_only.make_table_read_only(menu_type);

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
}
resources = read_only.make_table_read_only(resources);

local g_is_initialized = false;

local g_jumpman_mesh_index;
local g_game_over_letter_mesh_indices = {};
local g_game_over_message_visible = false;
local g_camera_pan_animation_timer = 0;
local g_letter_drop_animation_timer = 0;

function update(game_input)
    set_player_freeze_cooldown_frame_count(100);
    set_player_current_state(0);

    if not g_is_initialized then
        g_is_initialized = true;

        g_jumpman_mesh_index = new_mesh(resources.MeshDead);
        select_platform(1);
        script_selected_mesh_scale_matrix(30, 3, 3);
        g_game_over_message_visible = false;
        g_camera_pan_animation_timer = 100;
    end

    set_fog(100, 200, 0, 0, 0);
    set_current_camera_mode(camera_mode.PerspectiveCloseUp);
    set_player_is_visible(0);

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
            g_game_over_letter_mesh_indices[iLet] = new_char_mesh(game_over_message:sub(iLet, iLet):byte(1, -1));
        end

        g_game_over_message_visible = true;

        if g_letter_drop_animation_timer ~= 1 then
            g_letter_drop_animation_timer = 115;
        end
    end

    if g_letter_drop_animation_timer > 0 then
        g_letter_drop_animation_timer = g_letter_drop_animation_timer - 3;

        for letter_index, current_mesh_index in ipairs(g_game_over_letter_mesh_indices) do
            select_object_mesh(current_mesh_index);
            script_selected_mesh_set_identity_matrix();
            script_selected_mesh_scale_matrix(2, 2, 1);

            local iTemp = g_letter_drop_animation_timer + letter_index * 5 - 50;

            if iTemp < 0 then
                iTemp = 0;
            end

            iTemp = iTemp + 60;
            local iX = 18 + letter_index * 13;

            if letter_index > 4 then
                iX = iX + 5;
            end

            script_selected_mesh_translate_matrix(iX, iTemp, 0);
            set_object_visual_data(resources.TextureNewMetal, 1);
        end
    end

    set_fog(80, 150 + g_camera_pan_animation_timer * 3, 0, 0, 0);

    set_player_current_position_x(80);
    set_player_current_position_y(70 + g_camera_pan_animation_timer);

    select_object_mesh(g_jumpman_mesh_index);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_scale_matrix(3, 3, 3);
    script_selected_mesh_translate_matrix(80, 80, 0);
    set_object_visual_data(resources.TextureJumpman, 1)

    local is_select_action_pressed = game_input.select_action.just_pressed;

    if is_select_action_pressed and g_letter_drop_animation_timer < 0 then
        set_script_event_data_1(101);
        service_function(service_type.SERVICE_LOADMENU, menu_type.MENU_MAIN);
    end

    if is_select_action_pressed and g_camera_pan_animation_timer > 0 then
        g_camera_pan_animation_timer = 0;
        g_letter_drop_animation_timer = 1;
    end
end

function reset()
    set_player_current_position_x(0);
    set_player_current_position_y(0);
    set_player_current_position_z(0);
    set_player_current_state(player_state.JSNORMAL);
end
