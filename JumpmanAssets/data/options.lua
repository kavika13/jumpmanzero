local read_only = require "data/read_only";
local options_data_module = assert(loadfile("data/options_data.lua"));
local game_logic_module = assert(loadfile("data/game_logic.lua"));

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

local menu_positions = {
    {
        left = 0.14,
        right = 0.66,
        top = 0.08,
        bottom = 0.17,
    },
    {
        left = 0.14,
        right = 0.66,
        top = 0.17,
        bottom = 0.265,
    },
    {
        left = 0.14,
        right = 0.66,
        top = 0.265,
        bottom = 0.36,
    },
    {
        left = 0.14,
        right = 0.66,
        top = 0.36,
        bottom = 0.455,
    },
    {
        left = 0.14,
        right = 0.66,
        top = 0.455,
        bottom = 0.55,
    },
    {
        left = 0.14,
        right = 0.77,
        top = 0.55,
        bottom = 0.65,
    },
    {
        left = 0.14,
        right = 0.81,
        top = 0.65,
        bottom = 0.75,
    },
    {
        left = 0.14,
        right = 0.81,
        top = 0.75,
        bottom = 0.84,
    },
    {
        left = 0.37,
        right = 0.62,
        top = 0.84,
        bottom = 0.93,
    },
};
menu_positions = read_only.make_table_read_only(menu_positions);

local g_game_logic = nil;

local g_option_letter_title_indices = {};
local g_option_letter_mesh_indices = {};
local g_option_letter_transform_indices = {};
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
    for _, current_option_letter_mesh_index in ipairs(g_option_letter_mesh_indices) do
        if current_option_letter_mesh_index > -1 then
            delete_mesh(current_option_letter_mesh_index);
        end
    end

    for _, current_option_letter_transform_index in ipairs(g_option_letter_transform_indices) do
        if current_option_letter_transform_index > -1 then
            transform_delete(current_option_letter_transform_index);
        end
    end

    g_option_letter_mesh_indices = {};
    g_option_letter_transform_indices = {};
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
            local char_mesh_index = g_game_logic.new_char_mesh(menu_options[iTit]:sub(iChar, iChar):byte(1, -1));
            table.insert(g_option_letter_mesh_indices, char_mesh_index);
            table.insert(g_option_letter_title_indices, iTit);

            local char_transform_index = -1;

            if char_mesh_index ~= -1 then
                char_transform_index = transform_create();
                mesh_set_transform(char_mesh_index, char_transform_index);
            end

            table.insert(g_option_letter_transform_indices, char_transform_index);
        end
    end
end

local function GetInput_(game_input)
    if g_is_game_selected then
        return;
    end

    local do_menu_select = function()
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
    end

    if game_input.select_action.just_pressed then
        do_menu_select();
        return;
    end

    local iOldSelected = g_option_selected_index;

    if game_input.cursor_is_on_screen then
        local is_option_hovered = false;

        for menu_item_index, menu_item_dims in ipairs(menu_positions) do
            if game_input.cursor_position.x >= menu_item_dims.left and game_input.cursor_position.x <= menu_item_dims.right and
                    game_input.cursor_position.y >= menu_item_dims.top and game_input.cursor_position.y <= menu_item_dims.bottom then
                g_option_selected_index = menu_item_index;
                is_option_hovered = true;
            end
        end

        if is_option_hovered and game_input.cursor_select_action.just_pressed then
            do_menu_select();
            return;
        end
    end

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

        local current_letter_mesh_index = g_option_letter_mesh_indices[current_letter_index];
        local current_letter_transform_index = g_option_letter_transform_indices[current_letter_index];
        local iHide = false;

        if current_letter_mesh_index > 0 then
            if g_flash_animation_current_menu_option_index == current_letter_title_index and iX > 80 and g_flash_animation_timer > 6 then
                iHide = true;
                set_mesh_is_visible(current_letter_mesh_index, false);
            end
        end

        if current_letter_mesh_index > 0 and not iHide then
            transform_set_scale(current_letter_transform_index, 1, 0.7, 1);
            set_mesh_is_visible(current_letter_mesh_index, true);

            if g_is_game_selected then
                if g_option_selected_index == current_letter_title_index then
                    local iDZ = -5;
                    local iDX = iX;
                    local iDY = iY;
                    local iTempTime = (g_time_since_current_selection * 4) - (iX * 4) + (iFirstX * 4) + 10;

                    if iTempTime > 0 and iTempTime < 360 then
                        transform_set_rotation_x(current_letter_transform_index, iTempTime);
                    end

                    transform_set_translation(current_letter_transform_index, iDX, iDY, iDZ);
                    set_mesh_texture(current_letter_mesh_index, resources.TextureBoringBlue);
                else
                    local iDZ = 0 + g_time_since_current_selection / 15;
                    local iDX = iX + ((g_time_since_current_selection / 100) * math.sin((iY * 10 + iX * 27) * math.pi / 180.0) * 50);
                    local iDY = iY + ((g_time_since_current_selection / 100) * math.sin((iY * 10 + iX * 59) * math.pi / 180.0) * 50);
                    transform_set_rotation_z(current_letter_transform_index, g_time_since_current_selection + iX);
                    transform_set_translation(current_letter_transform_index, iDX, iDY, iDZ);
                    set_mesh_texture(current_letter_mesh_index, resources.TextureRachBlue);
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

                transform_set_translation(current_letter_transform_index, iDX, iDY, iDZ);
                set_mesh_texture(current_letter_mesh_index, resources.TextureBoringBlue);
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

                transform_set_translation(current_letter_transform_index, iDX, iDY, iDZ);
                set_mesh_texture(current_letter_mesh_index, resources.TextureRachBlue);
            else
                transform_set_translation(current_letter_transform_index, iX, iY, 0);
                set_mesh_texture(current_letter_mesh_index, resources.TextureRachBlue);
            end
        end

        iX = iX + iCharWidth;
    end
end

local function PlaceCamera_()
    set_perspective(80.0, 80.0, -100.0, 80.0, 80.0, 0.0);
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

    PlaceCamera_();
    skip_next_camera_interpolation();
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
    scroll_texture_on_mesh(backdrop_mesh_index, 0.01 / 16.0, 0.01 / 16.0);

    if g_is_game_selected and g_time_since_current_selection > 250 and g_option_selected_index == 9 then
        save_config_options();
        Module.MenuLogic.load_main_menu();
    end

    PlaceCamera_();
end

return Module;
