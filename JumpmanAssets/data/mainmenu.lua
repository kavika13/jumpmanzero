local read_only = require "data/read_only";
local mainmenu_data_module = assert(loadfile("data/mainmenu_data.lua"));
local game_logic_module = assert(loadfile("data/game_logic.lua"));
local z_bits_module = assert(loadfile("data/z_bits.lua"));

local Module = {};

Module.MenuLogic = nil;

-- Default setup is for returning from other menus
-- Game Launch and Game Over will alter these states before running the module
Module.SkipAnimation = true;
-- TODO: Wrangle menu music in main.lua script instead of in this script?
Module.StartIntroStingMusicTrack = false;
Module.StartMainMusicTrack = false;

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureMenuBack = 0,
    TextureBoringBlue = 1,
    TextureRachBlue = 2,
    ScriptZBits = 0,
    TextureBoringBlush = 3,
    MeshGoo = 0,
    TextureBlueMarble = 4,
    TextureZBit = 5,
    TextureBoringGreen = 6,
    TextureBoringOrange = 7,
    SoundSelect = 0,
    SoundFire = 1,
};
resources = read_only.make_table_read_only(resources);

local kNUM_MENU_OPTIONS = 2;
local kANIMATION_END_TIME = 4400;

local menu_positions = {
    {
        left = 0.25,
        right = 0.73,
        top = 0.66,
        bottom = 0.75,
    },
    {
        left = 0.33,
        right = 0.66,
        top = 0.75,
        bottom = 0.83,
    },
};
menu_positions = read_only.make_table_read_only(menu_positions);

local g_game_logic;
local g_z_bits;

local g_is_game_selected = false;
local g_title_animation_is_done = false;
local g_title_animation_counter = 0;

local g_title_letter_mesh_ids = {};
local g_option_letter_mesh_ids = {};
local g_option_letter_title_indices = {};  -- 1:1 mapping with g_option_letter_mesh_ids

local g_option_selected_index = 1;
local g_option_previous_selected_index = 1;

local g_time_since_current_selection = 0;
local g_time_of_previous_selection = 0;

local function ShowJMLetters_(skip_next_interpolation)
    local iHeight = 0;
    local percent_complete = (g_title_animation_counter / kANIMATION_END_TIME) * 100;

    g_z_bits.PercentComplete = percent_complete;

    local iThick = 0.2;

    if percent_complete > 71 then
        iThick = 10 / 4;
    elseif percent_complete > 61 then
        iThick = (percent_complete - 61) / 4;
    end

    for iChar = 1, #g_title_letter_mesh_ids do
        set_identity_mesh_matrix(g_title_letter_mesh_ids[iChar]);
        scale_mesh_matrix(g_title_letter_mesh_ids[iChar], 2, 0.8, iThick);

        local iX = iChar * 15 + 20;

        if iChar > 1 then
            iX = iX - 1;
        end

        if iChar > 4 then
            iX = iX - 2;
        end

        if iChar > 6 then
            iX = iX + 1;
        end

        local iY = 100;
        local iZ = 0;

        if iChar == 1 then
            iHeight = 22;
        elseif iChar == 5  then
            iHeight = 54;
        elseif iChar == 2 then
            iHeight = 76;
        elseif iChar == 3 then
            iHeight = 80;
        elseif iChar == 4 then
            iHeight = 84;
        elseif iChar == 7 then
            iHeight = 78;
        elseif iChar == 6 then
            iHeight = 82;
        end

        iHeight = (iHeight * 4 / 3) - (percent_complete * 2);

        if iHeight < 0 then
            iHeight = 0;
        end

        local iDX = iX;
        local iDY = iY + iHeight;
        local iDZ = iZ + iHeight;

        if iHeight > 3 then
            rotate_x_mesh_matrix(g_title_letter_mesh_ids[iChar], (iHeight - 3) * 10);
        end

        translate_mesh_matrix(g_title_letter_mesh_ids[iChar], iDX, iDY, iDZ);
        set_mesh_is_visible(g_title_letter_mesh_ids[iChar], true);

        if skip_next_interpolation then
            skip_next_mesh_interpolation(g_title_letter_mesh_ids[iChar]);
        end
    end
end

local function GetInput_(game_input)
    local skip_next_interpolation = false;

    if g_is_game_selected then
        return skip_next_interpolation;
    end

    local is_still_animating = g_title_animation_counter < kANIMATION_END_TIME;

    local do_menu_select = function()
        local is_done = false;

        if is_still_animating then
            g_title_animation_counter = kANIMATION_END_TIME;
            skip_next_interpolation = true;
        else
            play_sound_effect(resources.SoundFire);
            g_is_game_selected = true;
            g_time_since_current_selection = 0;
            is_done = true;
        end

        return is_done;
    end

    if game_input.select_action.just_pressed then
        if do_menu_select() then
            return skip_next_interpolation;
        end
    end

    if is_still_animating and game_input.cursor_is_on_screen and game_input.cursor_select_action.just_pressed then
        if do_menu_select() then
            return skip_next_interpolation;
        end
    end

    local iOldSelected = g_option_selected_index;

    if not g_title_animation_is_done then
        return skip_next_interpolation;
    end

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
            if do_menu_select() then
                return skip_next_interpolation;
            end
        end
    end

    if game_input.move_up_action.just_pressed then
        g_option_selected_index = g_option_selected_index - 1;
    end

    if game_input.move_down_action.just_pressed then
        g_option_selected_index = g_option_selected_index + 1;
    end

    if g_option_selected_index < 1 then
        g_option_selected_index = kNUM_MENU_OPTIONS;
    end

    if g_option_selected_index > kNUM_MENU_OPTIONS then
        g_option_selected_index = 1;
    end

    if g_option_selected_index ~= iOldSelected then
        g_option_previous_selected_index = iOldSelected;
        g_time_of_previous_selection = g_time_since_current_selection;
        g_time_since_current_selection = 0;
        play_sound_effect(resources.SoundSelect);
    end

    return skip_next_interpolation;
end

local function GetTitleWidth_(target_title_index)
    local iLen = 0;

    for _, current_option_letter_title_index in ipairs(g_option_letter_title_indices) do
        if current_option_letter_title_index == target_title_index then
            iLen = iLen + 1;
        end
    end

    return iLen;
end

local function ShowLetters_(skip_next_interpolation)
    local iX = 0;
    local iFirstX = 0;
    local iY = 0;
    local iCharWidth = 0;
    local previous_letter_title_index = -1;

    if not g_title_animation_is_done then
        return;
    end

    for current_letter_index, current_letter_title_index in ipairs(g_option_letter_title_indices) do
        if current_letter_title_index ~= previous_letter_title_index then
            local iWidth = GetTitleWidth_(current_letter_title_index);
            iCharWidth = 5;
            local iScreenWidth = iCharWidth * iWidth;
            iX = 80 - (iScreenWidth / 2);
            iX = iX + (iCharWidth / 2);
            iX = iX - 1;
            iFirstX = iX;
            iY = 64 - ((current_letter_title_index - 1) * 8);
            previous_letter_title_index = current_letter_title_index;
        end

        local current_letter_mesh_id = g_option_letter_mesh_ids[current_letter_index];

        if current_letter_mesh_id > 0 then
            set_identity_mesh_matrix(current_letter_mesh_id);
            scale_mesh_matrix(current_letter_mesh_id, 0.7, 0.7, 1);
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
                    local iDX = iX + ((g_time_since_current_selection / 100) * math.sin(iX * 27 * math.pi / 180.0) * 50);
                    local iDY = iY + ((g_time_since_current_selection / 100) * math.sin(iX * 59 * math.pi / 180.0) * 50);

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

            if skip_next_interpolation then
                skip_next_mesh_interpolation(current_letter_mesh_id);
            end
        end

        iX = iX + iCharWidth;
    end
end

local function InitializeLetters_()
    local title = "Jumpman";

    for iChar = 1, #title do
        local char_mesh = g_game_logic.new_char_mesh(title:sub(iChar, iChar):byte(1, -1));
        set_mesh_texture(char_mesh, resources.TextureBoringOrange);
        table.insert(g_title_letter_mesh_ids, char_mesh);
    end

    local menu_options = { "Start Game", "Options" };

    for iTit, current_option in ipairs(menu_options) do
        for iChar = 1, #current_option do
            table.insert(g_option_letter_mesh_ids, g_game_logic.new_char_mesh(menu_options[iTit]:sub(iChar, iChar):byte(1, -1)));
            table.insert(g_option_letter_title_indices, iTit);
        end
    end
end

local function PlaceCamera_()
    set_perspective(80.0, 80.0, -100.0, 80.0, 80.0, 0.0);
end

function Module.initialize(game_input)
    g_game_logic = game_logic_module();  -- TODO: Shouldn't need to load this to get level data
    g_game_logic.LevelData = mainmenu_data_module();
    g_game_logic.initialize(true);

    InitializeLetters_();

    if not Module.SkipAnimation then
        g_title_animation_counter = 0;
    else
        g_title_animation_counter = kANIMATION_END_TIME;
    end

    g_z_bits = z_bits_module();
    g_z_bits.GameLogic = g_game_logic;
    g_z_bits.MeshResourceIndex = resources.MeshGoo;
    g_z_bits.TextureResourceIndex = resources.TextureBoringGreen;
    g_z_bits.initialize();

    if Module.StartIntroStingMusicTrack then
        play_music_track_1(g_game_logic.LevelData.music_background_track_filename, 3000, -1);
    end

    if Module.StartMainMusicTrack then
        play_music_track_1(g_game_logic.LevelData.music_death_track_filename, 0, -1);
    end

    PlaceCamera_();
    skip_next_camera_interpolation();
end

function Module.update(game_input)
    local skip_next_interpolation = GetInput_(game_input);

    g_title_animation_counter = g_title_animation_counter + 20;

    if g_title_animation_counter > kANIMATION_END_TIME then
        g_title_animation_is_done = true;
        g_title_animation_counter = kANIMATION_END_TIME;
    end

    ShowJMLetters_(skip_next_interpolation);

    g_time_since_current_selection = g_time_since_current_selection + 5;
    ShowLetters_();

    local backdrop_mesh_index = g_game_logic.find_backdrop_by_number(100).mesh_index;  -- TODO: Use constant for num
    scroll_texture_on_mesh(backdrop_mesh_index, 0.01, 0.01);

    if g_is_game_selected and g_time_since_current_selection > 250 then
        if g_option_selected_index == 1 then
            Module.MenuLogic.load_select_game_menu();
        else
            Module.MenuLogic.load_options_menu();
        end
    end

    g_z_bits.update(skip_next_interpolation);

    PlaceCamera_();
end

return Module;
