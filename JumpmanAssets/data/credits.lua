local Module = {};

Module.GameLogic = nil;

Module.TextureResourceIndex = 0;

local g_letter_mesh_indices = {};
local g_letter_transform_indices = {};
local g_letter_pos_x = {};
local g_letter_pos_y = {};

local g_animation_counter = 0;
local g_time_remaining_before_freeze = 0;

local g_current_line_count = 0;

local g_credits = {
    "original game   ",
    "    randy glover",
    "                ",
    "programming     ",
    "   Dave Campbell",
    "        Merlyn  ",
    "   Morgan-Graham",
    "                ",
    "music           ",
    "     Andrew Doss",
    "                ",
    "sound           ",
    "      Jon Hadidi",
    "    Anvil Studio",
    "  lots of people",
    "                ",
    "art             ",
    "        THE GIMP",
    "                ",
    "modelling       ",
    "  Aztec 3d tools",
    "                ",
    "patience        ",
    " Rachel Campbell",
    "                ",
    "help and ideas  ",
    "           Matty",
    "  James Meszaros",
    " Martin Meszaros",
    "         sBartok",
    "         A White",
    "   davis sickmon",
    "  Lots of others",
    "                ",
    "Special thanks  ",
    "    randy glover",
    " willow software",
    "  Phillip Martin",
    "  Dave Eccleston",
    "                ",
    "                ",
    "   Thanks for   ",
    "     playing    ",
};

local function get_credit_line(line_index)
    local credit_line = g_credits[line_index + 1];
    return credit_line ~= nil, credit_line;
end

local function StartLine_(iLine)
    local has_new_line, credit_line = get_credit_line(iLine);

    if not has_new_line then
        g_time_remaining_before_freeze = 220;
        return;
    end

    for iChar = 1, #credit_line do
        local char_mesh_index = Module.GameLogic.new_char_mesh(credit_line:sub(iChar, iChar):byte(1, -1));

        if char_mesh_index > 0 then
            local char_transform_index = transform_create();
            mesh_set_transform(char_mesh_index, char_transform_index);
            set_mesh_texture(char_mesh_index, Module.TextureResourceIndex);

            table.insert(g_letter_mesh_indices, char_mesh_index);
            table.insert(g_letter_transform_indices, char_transform_index);
            table.insert(g_letter_pos_y, -50);
            table.insert(g_letter_pos_x, 55 + iChar * 11);
        end
    end
end

local function ShowChars_()
    local char_count = #g_letter_mesh_indices;
    local to_delete = {};

    for current_char_i, current_char_mesh_index in ipairs(g_letter_mesh_indices) do
        transform_set_scale(g_letter_transform_indices[current_char_i], 1.8, 2, 2);
        transform_set_translation(g_letter_transform_indices[current_char_i], g_letter_pos_x[current_char_i], g_letter_pos_y[current_char_i], 70);
        set_mesh_is_visible(current_char_mesh_index, true);
        g_letter_pos_y[current_char_i] = g_letter_pos_y[current_char_i] + 0.4;

        if g_letter_pos_y[current_char_i] > 140 then
            table.insert(to_delete, current_char_i);
        end
    end

    for to_delete_index = #to_delete, 1, -1 do
        local actual_index = to_delete[to_delete_index];
        delete_mesh(g_letter_mesh_indices[actual_index]);
        transform_delete(g_letter_transform_indices[actual_index]);
        table.remove(g_letter_mesh_indices, actual_index);
        table.remove(g_letter_transform_indices, actual_index);
        table.remove(g_letter_pos_x, actual_index);
        table.remove(g_letter_pos_y, actual_index);
    end
end

function Module.initialize()
    -- Nothing to do here
end

function Module.update()
    if g_time_remaining_before_freeze == 1 then
        return true;
    end

    g_animation_counter = g_animation_counter + 1;

    if g_animation_counter == 60 then
        g_animation_counter = 0;
    end

    if g_animation_counter == 1 and g_time_remaining_before_freeze == 0 then
        StartLine_(g_current_line_count);
        g_current_line_count = g_current_line_count + 1;
    end

    if g_time_remaining_before_freeze > 0 then
        g_time_remaining_before_freeze = g_time_remaining_before_freeze - 1;
    end

    ShowChars_();

    return false;
end

return Module;
