local read_only = require "Data/read_only";

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

local g_is_game_selected = false;

local g_letter_mesh_ids = {};
local g_letter_title_indices = {};  -- 1:1 mapping with g_letter_mesh_ids

local g_title_count = 0;
local g_title_selected_index = 1;
local g_title_previous_selected_index = 1;

local g_time_since_current_selection = 0;
local g_time_of_previous_selection = 0;

local function GetInput_(game_input)
    if g_is_game_selected then
        return;
    end

    if game_input.select_action.just_pressed then
        play_sound_effect(resources.SoundFire);
        g_is_game_selected = true;
        g_time_since_current_selection = 0;
        return;
    end

    local iOldSelected = g_title_selected_index;

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

        local current_letter_mesh_id = g_letter_mesh_ids[current_letter_index];

        if current_letter_mesh_id > 0 then
            set_identity_mesh_matrix(current_letter_mesh_id);
            set_mesh_is_visible(current_letter_mesh_id, true);

            if g_is_game_selected then
                if g_title_selected_index == current_letter_title_index then
                    local iDZ = -15;
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

                translate_mesh_matrix(current_letter_mesh_id, iDX, iDY, iDZ);
                set_mesh_texture(current_letter_mesh_id, resources.TextureBoringBlue);
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

local function InitializeLetters_()
    local game_list = get_game_list();
    g_title_count = #game_list;

    for iTit, current_title in ipairs(game_list) do
        for iChar = 1, #current_title do
            table.insert(g_letter_mesh_ids, new_char_mesh(game_list[iTit]:sub(iChar, iChar):byte(1, -1)));
            table.insert(g_letter_title_indices, iTit);
        end
    end
end

function initialize(game_input)
    InitializeLetters_();
    g_title_selected_index = 1;
    g_title_previous_selected_index = 1;
    g_time_since_current_selection = 0;
    g_is_game_selected = false;
end

function update(game_input)
    GetInput_(game_input);

    g_time_since_current_selection = g_time_since_current_selection + 5;
    ShowLetters_();

    local backdrop_mesh_index = find_backdrop_mesh_index(100);  -- TODO: Use constant for num
    scroll_texture_on_mesh(backdrop_mesh_index, 0.01, 0.01);

    if g_is_game_selected and g_time_since_current_selection > 450 then
        set_remaining_life_count(7);  -- TODO: This doesn't seem like the best place for this?
        game_start(g_title_selected_index - 1);  -- Expects 0-based title index
    end

    return true;
end
