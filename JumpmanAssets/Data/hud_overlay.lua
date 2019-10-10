local Module = {};

local g_is_initialized = false;

local g_title_letter_mesh_indices = {};
local g_life_count_number_mesh_indices = {};
local g_fps_first_number_mesh_indices = {};
local g_fps_second_number_mesh_indices = {};
local g_fps_third_number_mesh_indices = {};
local g_jumpman_icon_mesh_index;
-- local g_jumpman_hud_background_icon;  -- TODO: Maybe re-add with a transparent texture?

local g_title_scroll_timer = 0;

local g_is_title_animation_complete = false;

local function InitializeLetters_()
    local current_level_title = get_current_level_title();

    for iChar = 1, #current_level_title do
        local char_mesh = new_char_mesh(current_level_title:sub(iChar, iChar):byte(1, -1));
        set_mesh_texture(char_mesh, get_loaded_texture_count() - 1);  -- Title letter tex always loaded last after level loaded - TODO: Don't hard-code that?
        table.insert(g_title_letter_mesh_indices, char_mesh);
    end
end

local function ShowRemaining_()
    -- set_mesh_is_visible(g_jumpman_hud_background_icon, true);
    -- set_identity_mesh_matrix(g_jumpman_hud_background_icon);
    -- scale_mesh_matrix(g_jumpman_hud_background_icon, 16, 8, 1);
    -- translate_mesh_matrix(g_jumpman_hud_background_icon, 44, -34, 92);
    -- undo_camera_perspective_on_mesh_matrix(g_jumpman_hud_background_icon);

    set_mesh_is_visible(g_jumpman_icon_mesh_index, true);
    set_identity_mesh_matrix(g_jumpman_icon_mesh_index);
    scale_mesh_matrix(g_jumpman_icon_mesh_index, 0.5, 0.5, 0.5);
    translate_mesh_matrix(g_jumpman_icon_mesh_index, 40, -34, 90);
    undo_camera_perspective_on_mesh_matrix(g_jumpman_icon_mesh_index);
end

local function ShowPerformance_(game_input, lives_remaining)
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

        if iNum == lives_remaining and lives_remaining > 0 then
            set_mesh_is_visible(life_count_digit_mesh_index, true);
            set_identity_mesh_matrix(life_count_digit_mesh_index);
            scale_mesh_matrix(life_count_digit_mesh_index, 0.5, 0.5, 0.2);
            translate_mesh_matrix(life_count_digit_mesh_index, 47, -33, 90);
            undo_camera_perspective_on_mesh_matrix(life_count_digit_mesh_index);
        else
            set_mesh_is_visible(life_count_digit_mesh_index, false);
        end

        local fps_first_number_mesh_index = g_fps_first_number_mesh_indices[iNum + 1];

        if iNum == fps_hundreds_digit and game_input.debug_action.is_pressed then
            set_mesh_is_visible(fps_first_number_mesh_index, true);
            set_identity_mesh_matrix(fps_first_number_mesh_index);
            translate_mesh_matrix(fps_first_number_mesh_index, -40, 30, 90);
            undo_camera_perspective_on_mesh_matrix(fps_first_number_mesh_index);
        else
            set_mesh_is_visible(fps_first_number_mesh_index, false);
        end

        local fps_second_number_mesh_index = g_fps_second_number_mesh_indices[iNum + 1];

        if iNum == fps_tens_digit and game_input.debug_action.is_pressed then
            set_mesh_is_visible(fps_second_number_mesh_index, true);
            set_identity_mesh_matrix(fps_second_number_mesh_index);
            translate_mesh_matrix(fps_second_number_mesh_index, -34, 30, 90);
            undo_camera_perspective_on_mesh_matrix(fps_second_number_mesh_index);
        else
            set_mesh_is_visible(fps_second_number_mesh_index, false);
        end

        local fps_third_number_mesh_index = g_fps_third_number_mesh_indices[iNum + 1];

        if iNum == fps_ones_digit and game_input.debug_action.is_pressed then
            set_mesh_is_visible(fps_third_number_mesh_index, true);
            set_identity_mesh_matrix(fps_third_number_mesh_index);
            translate_mesh_matrix(fps_third_number_mesh_index, -28, 30, 90);
            undo_camera_perspective_on_mesh_matrix(fps_third_number_mesh_index);
        else
            set_mesh_is_visible(fps_third_number_mesh_index, false);
        end
    end
end

local function ShowLevelTitleAnimation_(animation_time)
    -- Note: If the title is "" then the animation will immediately end
    local is_animation_still_active = false;

    local iLast = -1;
    local iCharWidth = 12;
    local iFullWidth = iCharWidth * #g_title_letter_mesh_indices;
    local iX = (iFullWidth / 2);
    iX = iX - (iFullWidth / 6);
    iX = iX - (animation_time * 3.2);

    for _, letter_mesh_index in ipairs(g_title_letter_mesh_indices) do
        if letter_mesh_index > 0 then
            if iX > -90 and iX < 90 then
                set_identity_mesh_matrix(letter_mesh_index);
                scale_mesh_matrix(letter_mesh_index, 0.16, 0.16, 0.16);
                translate_mesh_matrix(letter_mesh_index, 0, 0, 5);
                rotate_y_mesh_matrix(letter_mesh_index, iX);
                translate_mesh_matrix(letter_mesh_index, 0, 0, 8);
                undo_camera_perspective_on_mesh_matrix(letter_mesh_index);
                set_mesh_is_visible(letter_mesh_index, true);
                is_animation_still_active = true;
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

function Module.update(game_input)
    if not g_is_initialized then
        -- TODO: Separate initialize function?
        g_is_initialized = true;

        local letter_texture_resource_index = get_loaded_texture_count() - 1;  -- FPS and lives letter tex always loaded last after level loaded - TODO: Don't hard code?

        for iNum = 0, 9 do
            g_fps_first_number_mesh_indices[iNum + 1] = new_char_mesh(48 + iNum);
            set_mesh_texture(g_fps_first_number_mesh_indices[iNum + 1], letter_texture_resource_index);
            move_mesh_to_front(g_fps_first_number_mesh_indices[iNum + 1]);

            g_fps_second_number_mesh_indices[iNum + 1] = new_char_mesh(48 + iNum);
            set_mesh_texture(g_fps_second_number_mesh_indices[iNum + 1], letter_texture_resource_index);
            move_mesh_to_front(g_fps_second_number_mesh_indices[iNum + 1]);

            g_fps_third_number_mesh_indices[iNum + 1] = new_char_mesh(48 + iNum);
            set_mesh_texture(g_fps_third_number_mesh_indices[iNum + 1], letter_texture_resource_index);
            move_mesh_to_front(g_fps_third_number_mesh_indices[iNum + 1]);

            g_life_count_number_mesh_indices[iNum + 1] = new_char_mesh(48 + iNum);
            set_mesh_texture(g_life_count_number_mesh_indices[iNum + 1], letter_texture_resource_index);
            move_mesh_to_front(g_life_count_number_mesh_indices[iNum + 1]);
        end

        InitializeLetters_();

        g_jumpman_icon_mesh_index = new_char_mesh(94);
        set_mesh_texture(g_jumpman_icon_mesh_index, 0);  -- Jumpman texture always set to first index inside a level - TODO: Don't hard code that?

        -- g_jumpman_hud_background_icon = new_char_mesh(37);
        -- local square_icon_texture_resource_index = get_loaded_texture_count() - 2;  -- Hud BG texture always loaded second to last after a level loaded - TODO: Don't hard code that?
        -- set_mesh_texture(g_jumpman_hud_background_icon, square_icon_texture_resource_index);

        g_title_scroll_timer = 0;
    end

    g_title_scroll_timer = g_title_scroll_timer + 1;

    local lives_remaining = get_remaining_life_count();

    if lives_remaining > 0 then
        ShowRemaining_();
    end

    ShowPerformance_(game_input, lives_remaining);

    if not g_is_title_animation_complete then
        if g_title_scroll_timer < 1000 then
            ShowLevelTitleAnimation_(g_title_scroll_timer);
        end
    end

    return g_is_title_animation_complete;
end

return Module;
