local read_only = require "data/read_only";
local selectgame_data_module = assert(loadfile("data/selectgame_data.lua"));
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
    TextureBoringGreen = 2,
    TextureRachBlue = 3,
    SoundSelect = 0,
    SoundFire = 1,
};
resources = read_only.make_table_read_only(resources);

local menu_positions = {
    {
        left = 0.23,
        right = 0.76,
        top = 0.16,
        bottom = 0.34,
    },
    {
        left = 0.17,
        right = 0.83,
        top = 0.34,
        bottom = 0.54,
    },
    {
        left = 0.27,
        right = 0.72,
        top = 0.54,
        bottom = 0.68,
    },
};
menu_positions = read_only.make_table_read_only(menu_positions);

local g_game_logic = nil;

local g_is_game_selected = false;

local g_letter_mesh_indices = {};
local g_letter_transform_indices = {};
local g_letter_title_indices = {};  -- 1:1 mapping with g_letter_mesh_indices

local g_title_count = 0;
local g_title_selected_index = 1;
local g_title_previous_selected_index = 1;

local g_time_since_current_selection = 0;
local g_time_of_previous_selection = 0;

local function GetInput_(game_input)
    if g_is_game_selected then
        return;
    end

    local do_menu_select = function()
        play_sound_effect(resources.SoundFire);
        g_is_game_selected = true;
        g_time_since_current_selection = 0;
    end

    if game_input.select_action.just_pressed then
        do_menu_select();
        return;
    end

    local iOldSelected = g_title_selected_index;

    if game_input.cursor_is_on_screen then
        local is_option_hovered = false;

        for menu_item_index, menu_item_dims in ipairs(menu_positions) do
            if game_input.cursor_position.x >= menu_item_dims.left and game_input.cursor_position.x <= menu_item_dims.right and
                    game_input.cursor_position.y >= menu_item_dims.top and game_input.cursor_position.y <= menu_item_dims.bottom then
                g_title_selected_index = menu_item_index;
                is_option_hovered = true;
            end
        end

        if is_option_hovered and game_input.cursor_select_action.just_pressed then
            do_menu_select();
            return;
        end
    end

    if game_input.move_up_action.just_pressed then
        g_title_selected_index = g_title_selected_index - 1;
    end

    if game_input.move_down_action.just_pressed then
        g_title_selected_index = g_title_selected_index + 1;
    end

    if g_title_selected_index < 1 then
        g_title_selected_index = g_title_count;
    end

    if g_title_selected_index > g_title_count then
        g_title_selected_index = 1;
    end

    if g_title_selected_index ~= iOldSelected then
        g_title_previous_selected_index = iOldSelected;
        g_time_of_previous_selection = g_time_since_current_selection;
        g_time_since_current_selection = 0;
        play_sound_effect(resources.SoundSelect);
    end
end

local function GetTitleWidth_(target_title_index)
    local iLen = 0;

    for _, current_letter_title_index in ipairs(g_letter_title_indices) do
        if current_letter_title_index == target_title_index then
            iLen = iLen + 1;
        end
    end

    return iLen;
end

local function ShowLetters_()
    local iX = 0;
    local iFirstX = 0;
    local iY = 0;
    local iCharWidth = 0;
    local previous_letter_title_index = -1;

    for current_letter_index, current_letter_title_index in ipairs(g_letter_title_indices) do
        if current_letter_title_index ~= previous_letter_title_index then
            local iWidth = GetTitleWidth_(current_letter_title_index);
            iCharWidth = 110 / iWidth;

            if iCharWidth > 6.1 then
                iCharWidth = 6.1;
            end

            local iScreenWidth = iCharWidth * iWidth;
            iX = 80 - (iScreenWidth / 2);
            iX = iX + (iCharWidth / 2);
            iX = iX - 1;
            iFirstX = iX;
            iY = 100 - ((current_letter_title_index - 1) * 15);
            previous_letter_title_index = current_letter_title_index;
        end

        local current_letter_mesh_index = g_letter_mesh_indices[current_letter_index];
        local current_letter_transform_index = g_letter_transform_indices[current_letter_index];

        if current_letter_mesh_index > 0 then
            set_mesh_is_visible(current_letter_mesh_index, true);

            if g_is_game_selected then
                if g_title_selected_index == current_letter_title_index then
                    local iDZ = -15;
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
                    local iDX = iX + ((g_time_since_current_selection / 100) * math.sin(iX * 27 * math.pi / 180.0) * 50);
                    local iDY = iY + ((g_time_since_current_selection / 100) * math.sin(iX * 59 * math.pi / 180.0) * 50);
                    transform_set_rotation_z(current_letter_transform_index, g_time_since_current_selection + iX);
                    transform_set_translation(current_letter_transform_index, iDX, iDY, iDZ);
                    set_mesh_texture(current_letter_mesh_index, resources.TextureRachBlue);
                end
            elseif g_title_selected_index == current_letter_title_index then
                local iMoveScale;

                if g_time_since_current_selection > 50 then
                    iMoveScale = 1;
                else
                    iMoveScale = g_time_since_current_selection / 50;
                end

                local iDZ = -15 * iMoveScale;
                local iDX = iX;
                local iDY = iY;

                transform_set_translation(current_letter_transform_index, iDX, iDY, iDZ);
                set_mesh_texture(current_letter_mesh_index, resources.TextureBoringBlue);
            elseif g_title_previous_selected_index == current_letter_title_index then
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

                local iDZ = -15 * iMoveScale;
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

local function InitializeLetters_()
    local game_list = { "Beginner", "Intermediate", "Advanced" };  -- TODO: Dynamically load this?
    g_title_count = #game_list;

    for iTit, current_title in ipairs(game_list) do
        for iChar = 1, #current_title do
            local char_mesh_index = g_game_logic.new_char_mesh(game_list[iTit]:sub(iChar, iChar):byte(1, -1));
            table.insert(g_letter_mesh_indices, char_mesh_index);
            table.insert(g_letter_title_indices, iTit);

            local char_transform_index = -1;

            if char_mesh_index ~= -1 then
                char_transform_index = transform_create();
                object_set_transform(char_mesh_index, char_transform_index);
            end

            table.insert(g_letter_transform_indices, char_transform_index);
        end
    end
end

local function PlaceCamera_()
    set_perspective(80.0, 80.0, -100.0, 80.0, 80.0, 0.0);
end

function Module.initialize(game_input)
    g_game_logic = game_logic_module();  -- TODO: Shouldn't need to load this to get level data
    g_game_logic.LevelData = selectgame_data_module();
    g_game_logic.initialize(true);

    InitializeLetters_();
    g_title_selected_index = 1;
    g_title_previous_selected_index = 1;
    g_time_since_current_selection = 0;
    g_is_game_selected = false;

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
    GetInput_(game_input);

    g_time_since_current_selection = g_time_since_current_selection + 5;
    ShowLetters_();

    local scrolling_background = g_game_logic.find_backdrop_by_number(100);  -- TODO: Use constant for num
    scroll_texture_on_mesh(scrolling_background.mesh_index, 0.01, 0.01);

    if g_is_game_selected and g_time_since_current_selection > 450 then
        Module.MenuLogic.game_start(g_title_selected_index);
    end

    PlaceCamera_();
end

return Module;
