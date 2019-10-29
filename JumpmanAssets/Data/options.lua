local read_only = require "Data/read_only";
local options_data_module = assert(loadfile("data/options_data.lua"));
local game_logic_module = assert(loadfile("Data/game_logic.lua"));

local Module = {};

Module.MenuLogic = nil;

-- Default setup is for returning from other menus
-- The first run of the main menu will alter these states before running the module
-- TODO: Wrangle menu music in main.lua script instead of in this script?
Module.StartMainMusicTrack = false;

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureMenuBack = 0,
    TextureBoringBlue = 1,
    TextureRachBlue = 2,
    SoundSelect = 0,
    SoundFire = 1,
};
resources = read_only.make_table_read_only(resources);

local g_game_logic = nil;

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
    ClearLetters_();

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
            table.insert(g_option_letter_mesh_ids, g_game_logic.new_char_mesh(menu_options[iTit]:sub(iChar, iChar):byte(1, -1)));
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
                stop_music_track_1();
            else
                iOn = 1;
                play_music_track_1(g_game_logic.LevelData.music_background_track_filename, 0, 0);
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
                set_mesh_is_visible(current_letter_mesh_id, false);
            end
        end

        if current_letter_mesh_id > 0 and not iHide then
            set_identity_mesh_matrix(current_letter_mesh_id);
            scale_mesh_matrix(current_letter_mesh_id, 1, 0.7, 1);
            set_mesh_is_visible(current_letter_mesh_id, true);

            if g_is_game_selected then
                if g_option_selected_index == current_letter_title_index then
                    local iDZ = -5;
                    local iDX = iX;
                    local iDY = iY;
                    local iTempTime = (g_time_since_current_selection * 4) - (iX * 4) + (iFirstX * 4) + 10;

                    if iTempTime > 0 and iTempTime < 360 then
                        rotate_x_mesh_matrix(current_letter_mesh_id, iTempTime);
                    end

                    translate_mesh_matrix(current_letter_mesh_id, iDX, iDY, iDZ);
                    set_mesh_texture(current_letter_mesh_id, resources.TextureBoringBlue);
                else
                    local iDZ = 0 + g_time_since_current_selection / 15;
                    local iDX = iX + ((g_time_since_current_selection / 100) * math.sin((iY * 10 + iX * 27) * math.pi / 180.0) * 50);
                    local iDY = iY + ((g_time_since_current_selection / 100) * math.sin((iY * 10 + iX * 59) * math.pi / 180.0) * 50);
                    rotate_z_mesh_matrix(current_letter_mesh_id, g_time_since_current_selection + iX);
                    translate_mesh_matrix(current_letter_mesh_id, iDX, iDY, iDZ);
                    set_mesh_texture(current_letter_mesh_id, resources.TextureRachBlue);
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

                translate_mesh_matrix(current_letter_mesh_id, iDX, iDY, iDZ);
                set_mesh_texture(current_letter_mesh_id, resources.TextureBoringBlue);
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

                translate_mesh_matrix(current_letter_mesh_id, iDX, iDY, iDZ);
                set_mesh_texture(current_letter_mesh_id, resources.TextureRachBlue);
            else
                translate_mesh_matrix(current_letter_mesh_id, iX, iY, 0);
                set_mesh_texture(current_letter_mesh_id, resources.TextureRachBlue);
            end
        end

        iX = iX + iCharWidth;
    end
end

function Module.initialize(game_input)
    g_game_logic = game_logic_module();  -- TODO: Shouldn't need to load this to get level data
    g_game_logic.LevelData = options_data_module();
    g_game_logic.initialize(true);

    InitializeLetters_();
    g_flash_animation_current_menu_option_index = -1;

    if Module.StartMainMusicTrack then
        play_music_track_1(
            g_game_logic.LevelData.music_background_track_filename,
            0,
            g_game_logic.LevelData.music_loop_start_music_time);
    end
end

function Module.update(game_input)
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

    local backdrop_mesh_index = g_game_logic.find_backdrop_by_number(100).mesh_index;  -- TODO: Use constant for num
    scroll_texture_on_mesh(backdrop_mesh_index, 0.01, 0.01);

    if g_is_game_selected and g_time_since_current_selection > 250 and g_option_selected_index == 9 then
        save_config_options();
        Module.MenuLogic.load_main_menu();
    end

    return true;
end

return Module;
