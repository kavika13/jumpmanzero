local read_only = require "Data/read_only";

-- TODO: Move this into a shared file, split into separate tables by type. Or inject from engine?
local menu_type = {
    MENU_MAIN = 1,
    MENU_OPTIONS = 2,
    MENU_SELECTGAME = 3,
    MENU_SELECTLEVEL = 4,
};
menu_type = read_only.make_table_read_only(menu_type);

-- TODO: Move this into a shared file, split into separate tables by type. Or inject from engine?
local menu_music_type = {
    CONTINUE_PLAYING_TRACK = 0,
    INTRO_TRACK = 1,
    MAIN_LOOP_TRACK = 2,
};
menu_music_type = read_only.make_table_read_only(menu_music_type);

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureMenuBack = 0,
    TextureBoringBlue = 1,
    TextureRachBlue = 2,
    SoundSelect = 0,
    SoundFire = 1,
};
resources = read_only.make_table_read_only(resources);

local g_is_initialized = false;

local g_option_letter_title_indices = {};
local g_option_letter_mesh_ids = {};
local g_title_count = 0;

local g_is_game_selected = false;

local g_option_selected_index = 1;
local g_option_previous_selected_index = 1;

local g_time_since_current_selection = 0;
local g_time_of_previous_selection = 0;

local g_flash_animation_current_menu_option_index = -1;
local g_flash_animation_timer = 0;

local function GetTitleWidth_(target_title_index)
    local iLen = 0;

    for _, current_option_letter_title_index in ipairs(g_option_letter_title_indices) do
        if current_option_letter_title_index == target_title_index then
            iLen = iLen + 1;
        end
    end

    return iLen;
end

local function ClearLetters_()
    for _, current_option_letter_mesh_id in ipairs(g_option_letter_mesh_ids) do
        if current_option_letter_mesh_id > -1 then
            delete_mesh(current_option_letter_mesh_id);
        end
    end

    g_option_letter_mesh_ids = {};
    g_option_letter_title_indices = {};
    g_title_count = 0;
end

local function InitializeLetters_()
    if g_is_initialized then
        ClearLetters_();
    end

    local menu_options = {
        "Up    :" .. get_config_option_string(0),
        "Down  :" .. get_config_option_string(1),
        "Left  :" .. get_config_option_string(2),
        "Right :" .. get_config_option_string(3),
        "Jump  :" .. get_config_option_string(4),
        "Secret:" .. " ^  ",
        "Sound :" .. get_config_option_string(32),
        "Music :" .. get_config_option_string(33),
        "Back",
    };
    g_title_count = #menu_options;

    for iTit, current_option in ipairs(menu_options) do
        for iChar = 1, #current_option do
            table.insert(g_option_letter_mesh_ids, new_char_mesh(menu_options[iTit]:sub(iChar, iChar):byte(1, -1)));
            table.insert(g_option_letter_title_indices, iTit);
        end
    end
end

local function GetInput_(game_input)
    if g_is_game_selected then
        return;
    end

    if game_input.select_action.just_pressed then
        if g_option_selected_index == 9 then
            play_sound_effect(resources.SoundFire);
            g_is_game_selected = true;
            g_time_since_current_selection = 0;
        elseif g_option_selected_index == 7 then
            local iOn;

            if get_is_sound_enabled() then
                iOn = 0;
            else
                iOn = 1;
            end

            set_config_option(32, iOn);
            InitializeLetters_();
        elseif g_option_selected_index == 8 then
            local iOn;

            if get_is_music_enabled() then
                iOn = 0;
            else
                iOn = 1;
            end

            set_config_option(33, iOn);
            InitializeLetters_();
        else
            g_flash_animation_current_menu_option_index = g_option_selected_index;
        end

        return;
    end

    local iOldSelected = g_option_selected_index;

    if game_input.move_up_action.just_pressed then
        g_option_selected_index = g_option_selected_index - 1;

        if g_option_selected_index == 6 then
            g_option_selected_index = 5;
        end
    end

    if game_input.move_down_action.just_pressed then
        g_option_selected_index = g_option_selected_index + 1;

        if g_option_selected_index == 6 then
            g_option_selected_index = 7;
        end
    end

    if g_option_selected_index < 1 then
        g_option_selected_index = g_title_count;
    end

    if g_option_selected_index > g_title_count then
        g_option_selected_index = 1;
    end

    if g_option_selected_index ~= iOldSelected then
        play_sound_effect(resources.SoundSelect);
        g_option_previous_selected_index = iOldSelected;
        g_time_of_previous_selection = g_time_since_current_selection;
        g_time_since_current_selection = 0;
    end
end

local function ShowLetters_()
    local iX = 0;
    local iFirstX = 0;
    local iY = 0;
    local iCharWidth = 0;
    local previous_letter_title_index = -1;

    for current_letter_index, current_letter_title_index in ipairs(g_option_letter_title_indices) do
        if current_letter_title_index ~= previous_letter_title_index then
            local iWidth = GetTitleWidth_(current_letter_title_index);
            iCharWidth = 7.1;
            local iScreenWidth = iCharWidth * iWidth;
            iX = 80 - (iScreenWidth / 2);
            iX = iX + (iCharWidth / 2);
            iX = iX - 1;
            iFirstX = iX;
            iY = 112 - ((current_letter_title_index - 1) * 8);
            previous_letter_title_index = current_letter_title_index;
        end

        local current_letter_mesh_id = g_option_letter_mesh_ids[current_letter_index];
        local iHide = false;

        if current_letter_mesh_id > 0 then
            if g_flash_animation_current_menu_option_index == current_letter_title_index and iX > 80 and g_flash_animation_timer > 6 then
                iHide = true;
                select_object_mesh(current_letter_mesh_id);
                set_object_visual_data(0, 0);
            end
        end

        if current_letter_mesh_id > 0 and not iHide then
            select_object_mesh(current_letter_mesh_id);
            set_identity_mesh_matrix(current_letter_mesh_id);
            scale_mesh_matrix(current_letter_mesh_id, 1, 0.7, 1);

            if g_is_game_selected then
                if g_option_selected_index == current_letter_title_index then
                    local iDZ = -5;
                    local iDX = iX;
                    local iDY = iY;
                    local iTempTime = (g_time_since_current_selection * 4) - (iX * 4) + (iFirstX * 4) + 10;

                    if iTempTime > 0 and iTempTime < 360 then
                        rotate_x_mesh_matrix(current_letter_mesh_id, iTempTime);
                    end

                    script_selected_mesh_translate_matrix(iDX, iDY, iDZ);
                    set_object_visual_data(resources.TextureBoringBlue, 1);
                else
                    local iDZ = 0 + g_time_since_current_selection / 15;
                    local iDX = iX + ((g_time_since_current_selection / 100) * math.sin((iY * 10 + iX * 27) * math.pi / 180.0) * 50);
                    local iDY = iY + ((g_time_since_current_selection / 100) * math.sin((iY * 10 + iX * 59) * math.pi / 180.0) * 50);
                    script_selected_mesh_rotate_matrix_z(g_time_since_current_selection + iX);
                    script_selected_mesh_translate_matrix(iDX, iDY, iDZ);
                    set_object_visual_data(resources.TextureRachBlue, 1);
                end
            elseif g_option_selected_index == current_letter_title_index then
                local iMoveScale;

                if g_time_since_current_selection > 50 then
                    iMoveScale = 1;
                else
                    iMoveScale = g_time_since_current_selection / 50;
                end

                local iDZ = -5 * iMoveScale;
                local iDX = iX;
                local iDY = iY;

                script_selected_mesh_translate_matrix(iDX, iDY, iDZ);
                set_object_visual_data(resources.TextureBoringBlue, 1);
            elseif g_option_previous_selected_index == current_letter_title_index then
                local iTempTime = (50 - g_time_since_current_selection);

                if g_time_of_previous_selection < 50 then
                    iTempTime = iTempTime - (50 - g_time_of_previous_selection);
                end

                local iMoveScale;

                if iTempTime < 0 then
                    iMoveScale = 0;
                else
                    iMoveScale = iTempTime / 50;
                end

                local iDZ = -5 * iMoveScale;
                local iDX = iX;
                local iDY = iY;

                script_selected_mesh_translate_matrix(iDX, iDY, iDZ);
                set_object_visual_data(resources.TextureRachBlue, 1);
            else
                script_selected_mesh_translate_matrix(iX, iY, 0);
                set_object_visual_data(resources.TextureRachBlue, 1);
            end
        end

        iX = iX + iCharWidth;
    end
end

function update(game_input)
    if not g_is_initialized then
        InitializeLetters_();
        g_is_initialized = true;
        g_flash_animation_current_menu_option_index = -1;
    end

    if g_flash_animation_current_menu_option_index == -1 then
        GetInput_(game_input);
    else
        g_flash_animation_timer = g_flash_animation_timer + 1;

        if g_flash_animation_timer == 10 then
            g_flash_animation_timer = 0;
        end

        local iKey = get_last_key_pressed();

        if iKey ~= 257 and (iKey ~= 32 or g_flash_animation_current_menu_option_index == 5) then
            if set_config_option(g_flash_animation_current_menu_option_index - 1, iKey) then
                g_flash_animation_current_menu_option_index = -1;
                InitializeLetters_();
            end
        end
    end

    g_time_since_current_selection = g_time_since_current_selection + 5;
    ShowLetters_();

    select_picture(100);  -- TODO: Use constant for num
    local backdrop_mesh_index = find_backdrop_mesh_index(100);  -- TODO: Use constant for num
    scroll_texture_on_mesh(backdrop_mesh_index, 0.01, 0.01);

    if g_is_game_selected and g_time_since_current_selection > 250 and g_option_selected_index == 9 then
        save_config_options();
        load_menu(menu_type.MENU_MAIN, menu_music_type.CONTINUE_PLAYING_TRACK);
    end

    return true;
end
