local g_is_initialized = false;

local g_title_letter_mesh_indices = {};
local g_life_count_number_mesh_indices = {};
local g_fps_first_number_mesh_indices = {};
local g_fps_second_number_mesh_indices = {};
local g_jumpman_icon_mesh_index;
-- local g_jumpman_hud_background_icon;  -- TODO: Maybe re-add with a transparent texture?

local g_is_title_animation_complete = false;

local function InitializeLetters()
    local current_level_title = get_current_level_title();

    for iChar = 1, #current_level_title do
        table.insert(g_title_letter_mesh_indices, new_char_mesh(current_level_title:sub(iChar, iChar):byte(1, -1)));
    end
end

local function ShowRemaining()
    -- local square_icon_texture_resource_index = get_loaded_texture_count() - 2;  -- Hud BG texture always loaded second to last after a level loaded - TODO: Don't hard code that?

    -- select_object_mesh(g_jumpman_hud_background_icon);
    -- set_object_visual_data(square_icon_texture_resource_index, 0);
    -- script_selected_mesh_set_identity_matrix();
    -- script_selected_mesh_scale_matrix(16, 8, 1);
    -- script_selected_mesh_translate_matrix(44, -34, 92);
    -- script_selected_mesh_set_perspective_matrix();

    select_object_mesh(g_jumpman_icon_mesh_index);
    set_object_visual_data(0, 1);  -- Jumpman texture always set to first index inside a level - TODO: Don't hard code that?
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_scale_matrix(0.5, 0.5, 0.5);
    script_selected_mesh_translate_matrix(40, -34, 90);
    script_selected_mesh_set_perspective_matrix();
end

local function ShowPerformance(game_input, lives_remaining)
    local letter_texture_resource_index = get_loaded_texture_count() - 1;  -- FPS and lives letter tex always loaded last after level loaded - TODO: Don't hard code?
    local fps_count = get_current_fps();

    local fps_tens_digit = 0;

    while fps_count > 9 do
        fps_tens_digit = fps_tens_digit + 1;
        fps_count = fps_count - 10;
    end

    local fps_ones_digit = fps_count;

    for iNum = 0, 9 do
        select_object_mesh(g_life_count_number_mesh_indices[iNum + 1]);

        if iNum == lives_remaining and lives_remaining > 0 then
            set_object_visual_data(letter_texture_resource_index, 1);
            script_selected_mesh_set_identity_matrix();
            script_selected_mesh_scale_matrix(0.5, 0.5, 0.2);
            script_selected_mesh_translate_matrix(47, -33, 90);
            script_selected_mesh_set_perspective_matrix();
        else
            set_object_visual_data(0, 0);
        end

        select_object_mesh(g_fps_first_number_mesh_indices[iNum + 1]);

        if iNum == fps_tens_digit and game_input.debug_action.is_pressed then
            set_object_visual_data(letter_texture_resource_index, 1);
            script_selected_mesh_set_identity_matrix();
            script_selected_mesh_translate_matrix(-40, 30, 90);
            script_selected_mesh_set_perspective_matrix();
        else
            set_object_visual_data(0, 0);
        end

        select_object_mesh(g_fps_second_number_mesh_indices[iNum + 1]);

        if iNum == fps_ones_digit and game_input.debug_action.is_pressed then
            set_object_visual_data(letter_texture_resource_index, 1);
            script_selected_mesh_set_identity_matrix();
            script_selected_mesh_translate_matrix(-34, 30, 90);
            script_selected_mesh_set_perspective_matrix();
        else
            set_object_visual_data(0, 0);
        end
    end
end

local function ShowLevelTitleAnimation(animation_time)
    local is_animation_done = false;

    local iLast = -1;
    local iCharWidth = 12;
    local iFullWidth = iCharWidth * #g_title_letter_mesh_indices;
    local iX = (iFullWidth / 2);
    iX = iX - (iFullWidth / 6);
    iX = iX - (animation_time * 3.2);

    for _, letter_mesh_index in ipairs(g_title_letter_mesh_indices) do
        if letter_mesh_index > 0 then
            select_object_mesh(letter_mesh_index);

            if iX > -90 and iX < 90 then
                script_selected_mesh_set_identity_matrix();
                script_selected_mesh_scale_matrix(0.16, 0.16, 0.16);
                script_selected_mesh_translate_matrix(0, 0, 5);
                script_selected_mesh_rotate_matrix_y(iX);
                script_selected_mesh_translate_matrix(0, 0, 8);
                script_selected_mesh_set_perspective_matrix();
                set_object_visual_data(get_loaded_texture_count() - 1, 1);  -- Title letter tex always loaded last after level loaded - TODO: Don't hard-code that?
                is_animation_done = true;
            else
                set_object_visual_data(0, 0);
            end
        end

        iX = iX + iCharWidth;
    end

    if not is_animation_done then
        set_script_event_data_1(-100);
        g_is_title_animation_complete = true;
    end
end

function update(game_input)
    if not g_is_initialized then
        g_is_initialized = true;

        for iNum = 0, 9 do
            g_fps_first_number_mesh_indices[iNum + 1] = new_char_mesh(48 + iNum);
            g_fps_second_number_mesh_indices[iNum + 1] = new_char_mesh(48 + iNum);
            g_life_count_number_mesh_indices[iNum + 1] = new_char_mesh(48 + iNum);
        end

        prioritize_object();
        InitializeLetters();

        g_jumpman_icon_mesh_index = new_char_mesh(94);
        -- g_jumpman_hud_background_icon = new_char_mesh(37);
    end

    local lives_remaining = get_remaining_life_count();

    if lives_remaining > 0 then
        ShowRemaining();
    end

    ShowPerformance(game_input, lives_remaining);

    if not g_is_title_animation_complete then
        local animation_time = get_script_event_data_1();

        if animation_time < 1000 then
            ShowLevelTitleAnimation(animation_time);
        end
    end
end
