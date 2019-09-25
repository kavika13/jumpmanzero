local read_only = require "Data/read_only";
local z_bits_module = assert(loadfile("Data/z_bits.lua"));

-- TODO: Move this into a shared file, split into separate tables by type. Or inject from engine?
local menu_type = {
    MENU_MAIN = 1,
    MENU_OPTIONS = 2,
    MENU_SELECTGAME = 3,
    MENU_SELECTLEVEL = 4,
};
menu_type = read_only.make_table_read_only(menu_type);

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

local g_is_initialized = false;

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

local function ShowJMLetters()
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
        select_object_mesh(g_title_letter_mesh_ids[iChar]);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_scale_matrix(2, 0.8, iThick);

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
            script_selected_mesh_rotate_matrix_x((iHeight - 3) * 10);
        end

        script_selected_mesh_translate_matrix(iDX, iDY, iDZ);
        set_object_visual_data(resources.TextureBoringOrange, 1);
    end
end

local function GetInput(game_input)
    if g_is_game_selected then
        return;
    end

    if game_input.select_action.just_pressed then
        if g_title_animation_counter < kANIMATION_END_TIME then
            g_title_animation_counter = kANIMATION_END_TIME;
        else
            play_sound_effect(resources.SoundFire);
            g_is_game_selected = true;
            g_time_since_current_selection = 0;
            return;
        end
    end

    local iOldSelected = g_option_selected_index;

    if not g_title_animation_is_done then
        return;
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
end

local function GetTitleWidth(target_title_index)
    local iLen = 0;

    for _, current_option_letter_title_index in ipairs(g_option_letter_title_indices) do
        if current_option_letter_title_index == target_title_index then
            iLen = iLen + 1;
        end
    end

    return iLen;
end

local function ShowLetters()
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
            local iWidth = GetTitleWidth(current_letter_title_index);
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
            select_object_mesh(current_letter_mesh_id);
            script_selected_mesh_set_identity_matrix();
            script_selected_mesh_scale_matrix(0.7, 0.7, 1);

            if g_is_game_selected then
                if g_option_selected_index == current_letter_title_index then
                    local iDZ = -5;
                    local iDX = iX;
                    local iDY = iY;

                    local iTempTime = (g_time_since_current_selection * 4) - (iX * 4) + (iFirstX * 4) + 10;

                    if iTempTime > 0 and iTempTime < 360 then
                        script_selected_mesh_rotate_matrix_x(iTempTime);
                    end

                    script_selected_mesh_translate_matrix(iDX, iDY, iDZ);
                    set_object_visual_data(resources.TextureBoringBlue, 1);
                else
                    local iDZ = 0 + g_time_since_current_selection / 15;
                    local iDX = iX + ((g_time_since_current_selection / 100) * math.sin(iX * 27 * math.pi / 180.0) * 50);
                    local iDY = iY + ((g_time_since_current_selection / 100) * math.sin(iX * 59 * math.pi / 180.0) * 50);

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

local function InitializeLetters()
    local title = "Jumpman";

    for iChar = 1, #title do
        table.insert(g_title_letter_mesh_ids, new_char_mesh(title:sub(iChar, iChar):byte(1, -1)));
    end

    local menu_options = { "Start Game", "Options" };

    for iTit, current_option in ipairs(menu_options) do
        for iChar = 1, #current_option do
            table.insert(g_option_letter_mesh_ids, new_char_mesh(menu_options[iTit]:sub(iChar, iChar):byte(1, -1)));
            table.insert(g_option_letter_title_indices, iTit);
        end
    end
end

function update(game_input)
    if not g_is_initialized then
        g_is_initialized = true;
        InitializeLetters();

        if get_script_event_data_1() == 10 then
            g_title_animation_counter = 0;
        else
            g_title_animation_counter = kANIMATION_END_TIME;
        end

        g_z_bits = z_bits_module();
        g_z_bits.MeshResourceIndex = resources.MeshGoo;
        g_z_bits.TextureResourceIndex = resources.TextureBoringGreen;
    end

    GetInput(game_input);

    g_title_animation_counter = g_title_animation_counter + 20;

    if g_title_animation_counter > kANIMATION_END_TIME then
        g_title_animation_is_done = true;
        g_title_animation_counter = kANIMATION_END_TIME;
    end

    ShowJMLetters();

    g_time_since_current_selection = g_time_since_current_selection + 5;
    ShowLetters();

    select_picture(100);
    script_selected_mesh_scroll_texture(0.01, 0.01);

    if g_is_game_selected and g_time_since_current_selection > 250 then
        if g_option_selected_index == 1 then
            load_menu(menu_type.MENU_SELECTGAME);
        else
            load_menu(menu_type.MENU_OPTIONS);
        end
    end

    g_z_bits.update();
end
