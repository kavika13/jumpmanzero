local Module = {};

Module.MenuLogic = nil;
Module.GameLogic = nil;

local g_is_initialized = false;

local g_title_letter_mesh_indices = {};
local g_title_letter_transform_indices = {};
local g_life_count_number_mesh_indices = {};
local g_life_count_number_transform_indices = {};
local g_fps_first_number_mesh_indices = {};
local g_fps_first_number_transform_indices = {};
local g_fps_second_number_mesh_indices = {};
local g_fps_second_number_transform_indices = {};
local g_fps_third_number_mesh_indices = {};
local g_fps_third_number_transform_indices = {};
local g_jumpman_icon_mesh_index = -1;
local g_jumpman_icon_transform_index = -1;
-- local g_jumpman_hud_background_icon_mesh_index;  -- TODO: Maybe re-add with a transparent texture?

local g_title_scroll_timer = 0;

local g_is_title_animation_complete = false;

local function InitializeLetters_()
    local current_level_title = Module.MenuLogic.get_current_level_title();

    for iChar = 1, #current_level_title do
        local char_mesh_index = Module.GameLogic.new_char_mesh(current_level_title:sub(iChar, iChar):byte(1, -1));
        table.insert(g_title_letter_mesh_indices, char_mesh_index);

        local transform_indices = {};
        if char_mesh_index ~= -1 then
            set_mesh_texture(char_mesh_index, get_loaded_texture_count() - 1);  -- Title letter tex always loaded last after level loaded - TODO: Don't hard-code that?
            transform_indices = { transform_create(), transform_create() };
            mesh_set_transform(char_mesh_index, transform_indices[1]);
            transform_set_parent(transform_indices[1], transform_indices[2]);
        end

        table.insert(g_title_letter_transform_indices, transform_indices);
    end
end

local function ShowRemaining_(skip_next_interpolation)
    -- set_mesh_is_visible(g_jumpman_hud_background_icon_mesh_index, true);
    -- transform_set_scale(g_jumpman_hud_background_icon_transform_index, 16, 8, 1);
    -- transform_set_translation(g_jumpman_hud_background_icon_transform_index, 44, -34, 92);
    -- transform_set_parent_is_camera(g_jumpman_hud_background_icon_transform_index, true);

    set_mesh_is_visible(g_jumpman_icon_mesh_index, true);
    transform_set_scale(g_jumpman_icon_transform_index, 0.5, 0.5, 0.5);
    transform_set_translation(g_jumpman_icon_transform_index, 40, -34, 90);
    transform_set_parent_is_camera(g_jumpman_icon_transform_index, true);
    -- TODO: Skip interpolation on these frame after death because of camera jump

    if skip_next_interpolation then
        skip_next_mesh_interpolation(g_jumpman_icon_mesh_index);
    end
end

local function ShowPerformance_(game_input, lives_remaining, skip_next_interpolation)
    local fps_count = get_current_fps();

    local fps_hundreds_digit = 0;

    while fps_count > 99 do
        fps_hundreds_digit = fps_hundreds_digit + 1;
        fps_count = fps_count - 100;
    end

    local fps_tens_digit = 0;

    while fps_count > 9 do
        fps_tens_digit = fps_tens_digit + 1;
        fps_count = fps_count - 10;
    end

    local fps_ones_digit = fps_count;

    for iNum = 0, 9 do
        local life_count_digit_mesh_index = g_life_count_number_mesh_indices[iNum + 1];
        local life_count_digit_transform_index = g_life_count_number_transform_indices[iNum + 1];

        -- TODO: Skip interpolation on these frame after death because of camera jump? Or will set_mesh_to_mesh instead of set_mesh_is_visible fix it
        -- TODO: Swap mesh instead of set visible?
        if iNum == lives_remaining and lives_remaining > 0 then
            set_mesh_is_visible(life_count_digit_mesh_index, true);
            transform_set_scale(life_count_digit_transform_index, 0.5, 0.5, 0.2);
            transform_set_translation(life_count_digit_transform_index, 47, -33, 90);
            transform_set_parent_is_camera(life_count_digit_transform_index, true);

            if skip_next_interpolation then
                skip_next_mesh_interpolation(life_count_digit_mesh_index);
            end
        else
            set_mesh_is_visible(life_count_digit_mesh_index, false);
        end

        local fps_first_number_mesh_index = g_fps_first_number_mesh_indices[iNum + 1];
        local fps_first_number_transform_index = g_fps_first_number_transform_indices[iNum + 1];

        if iNum == fps_hundreds_digit and game_input.debug_action.is_pressed then
            set_mesh_is_visible(fps_first_number_mesh_index, true);
            transform_set_translation(fps_first_number_transform_index, -40, 30, 90);
            transform_set_parent_is_camera(fps_first_number_transform_index, true);

            if skip_next_interpolation then
                skip_next_mesh_interpolation(fps_first_number_mesh_index);
            end
        else
            set_mesh_is_visible(fps_first_number_mesh_index, false);
        end

        local fps_second_number_mesh_index = g_fps_second_number_mesh_indices[iNum + 1];
        local fps_second_number_transform_index = g_fps_second_number_transform_indices[iNum + 1];

        if iNum == fps_tens_digit and game_input.debug_action.is_pressed then
            set_mesh_is_visible(fps_second_number_mesh_index, true);
            transform_set_translation(fps_second_number_transform_index, -34, 30, 90);
            transform_set_parent_is_camera(fps_second_number_transform_index, true);

            if skip_next_interpolation then
                skip_next_mesh_interpolation(fps_second_number_mesh_index);
            end
        else
            set_mesh_is_visible(fps_second_number_mesh_index, false);
        end

        local fps_third_number_mesh_index = g_fps_third_number_mesh_indices[iNum + 1];
        local fps_third_number_transform_index = g_fps_third_number_transform_indices[iNum + 1];

        if iNum == fps_ones_digit and game_input.debug_action.is_pressed then
            set_mesh_is_visible(fps_third_number_mesh_index, true);
            transform_set_translation(fps_third_number_transform_index, -28, 30, 90);
            transform_set_parent_is_camera(fps_third_number_transform_index, true);

            if skip_next_interpolation then
                skip_next_mesh_interpolation(fps_third_number_mesh_index);
            end
        else
            set_mesh_is_visible(fps_third_number_mesh_index, false);
        end
    end
end

local function ShowLevelTitleAnimation_(animation_time, skip_next_interpolation)
    -- Note: If the title is "" then the animation will immediately end
    local is_animation_still_active = false;

    local iLast = -1;
    local iCharWidth = 12;
    local iFullWidth = iCharWidth * #g_title_letter_mesh_indices;
    local iX = (iFullWidth / 2);
    iX = iX - (iFullWidth / 6);
    iX = iX - (animation_time * 3.2);

    for letter_index, letter_mesh_index in ipairs(g_title_letter_mesh_indices) do
        if letter_mesh_index > 0 then
            local transform_indices = g_title_letter_transform_indices[letter_index];

            if iX > -90 and iX < 90 then
                transform_set_scale(transform_indices[1], 0.16, 0.16, 0.16);
                transform_set_translation(transform_indices[1], 0, 0, 5);
                transform_set_rotation_y(transform_indices[2], iX);
                transform_set_translation(transform_indices[2], 0, 0, 8);
                transform_set_parent_is_camera(transform_indices[2], true);
                set_mesh_is_visible(letter_mesh_index, true);
                is_animation_still_active = true;

                if skip_next_interpolation then
                    skip_next_mesh_interpolation(letter_mesh_index);
                end
            else
                set_mesh_is_visible(letter_mesh_index, false);
            end
        end

        iX = iX + iCharWidth;
    end

    if not is_animation_still_active then
        g_is_title_animation_complete = true;
    end
end

function Module.update(game_input, skip_next_interpolation)
    if not g_is_initialized then
        -- TODO: Separate initialize function?
        g_is_initialized = true;

        local letter_texture_resource_index = get_loaded_texture_count() - 1;  -- FPS and lives letter tex always loaded last after level loaded - TODO: Don't hard code?

        for iNum = 0, 9 do
            g_fps_first_number_mesh_indices[iNum + 1] = Module.GameLogic.new_char_mesh(48 + iNum);
            g_fps_first_number_transform_indices[iNum + 1] = transform_create();
            mesh_set_transform(g_fps_first_number_mesh_indices[iNum + 1], g_fps_first_number_transform_indices[iNum + 1]);
            set_mesh_texture(g_fps_first_number_mesh_indices[iNum + 1], letter_texture_resource_index);

            g_fps_second_number_mesh_indices[iNum + 1] = Module.GameLogic.new_char_mesh(48 + iNum);
            g_fps_second_number_transform_indices[iNum + 1] = transform_create();
            mesh_set_transform(g_fps_second_number_mesh_indices[iNum + 1], g_fps_second_number_transform_indices[iNum + 1]);
            set_mesh_texture(g_fps_second_number_mesh_indices[iNum + 1], letter_texture_resource_index);

            g_fps_third_number_mesh_indices[iNum + 1] = Module.GameLogic.new_char_mesh(48 + iNum);
            g_fps_third_number_transform_indices[iNum + 1] = transform_create();
            mesh_set_transform(g_fps_third_number_mesh_indices[iNum + 1], g_fps_third_number_transform_indices[iNum + 1]);
            set_mesh_texture(g_fps_third_number_mesh_indices[iNum + 1], letter_texture_resource_index);

            g_life_count_number_mesh_indices[iNum + 1] = Module.GameLogic.new_char_mesh(48 + iNum);
            g_life_count_number_transform_indices[iNum + 1] = transform_create();
            mesh_set_transform(g_life_count_number_mesh_indices[iNum + 1], g_life_count_number_transform_indices[iNum + 1]);
            set_mesh_texture(g_life_count_number_mesh_indices[iNum + 1], letter_texture_resource_index);
        end

        InitializeLetters_();

        g_jumpman_icon_mesh_index = Module.GameLogic.new_char_mesh(94);
        g_jumpman_icon_transform_index = transform_create();
        mesh_set_transform(g_jumpman_icon_mesh_index, g_jumpman_icon_transform_index);
        set_mesh_texture(g_jumpman_icon_mesh_index, 0);  -- Jumpman texture always set to first index inside a level - TODO: Don't hard code that?

        -- g_jumpman_hud_background_icon_mesh_index = Module.GameLogic.new_char_mesh(37);
        -- local square_icon_texture_resource_index = get_loaded_texture_count() - 2;  -- Hud BG texture always loaded second to last after a level loaded - TODO: Don't hard code that?
        -- set_mesh_texture(g_jumpman_hud_background_icon_mesh_index, square_icon_texture_resource_index);

        g_title_scroll_timer = 0;
    end

    g_title_scroll_timer = g_title_scroll_timer + 1;

    local lives_remaining = Module.MenuLogic.get_remaining_life_count();

    if lives_remaining > 0 then
        ShowRemaining_(skip_next_interpolation);
    end

    ShowPerformance_(game_input, lives_remaining, skip_next_interpolation);

    if game_input.cheat_action.just_pressed then  -- TODO: Only enable this if the right command line is passed in. Or maybe in a debug build?
        Module.GameLogic.win_with_no_delay_debug();
    end

    if not g_is_title_animation_complete then
        if g_title_scroll_timer < 1000 then
            ShowLevelTitleAnimation_(g_title_scroll_timer, skip_next_interpolation);
        end
    end

    return g_is_title_animation_complete;
end

return Module;
