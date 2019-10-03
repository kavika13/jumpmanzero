local Module = {};

Module.TextureResourceIndex = 0;

local g_letter_mesh_indices = {};
local g_letter_pos_x = {};
local g_letter_pos_y = {};

local g_animation_counter = 0;
local g_time_remaining_before_freeze = 0;

local g_current_line_count = 0;

local function StartLine_(iLine)
    local has_new_line, credit_line = get_credit_line(iLine);

    if not has_new_line then
        g_time_remaining_before_freeze = 220;
        return;
    end

    for iChar = 1, #credit_line do
        local iMesh = new_char_mesh(credit_line:sub(iChar, iChar):byte(1, -1));

        if iMesh > 0 then
            table.insert(g_letter_mesh_indices, iMesh);
            table.insert(g_letter_pos_y, -50);
            table.insert(g_letter_pos_x, 55 + iChar * 11);
        end
    end
end

local function ShowChars_()
    local char_count = #g_letter_mesh_indices;
    local to_delete = {};

    for current_char_i, current_char_mesh_index in ipairs(g_letter_mesh_indices) do
        select_object_mesh(current_char_mesh_index);

        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_scale_matrix(1.8, 2, 2);
        script_selected_mesh_translate_matrix(g_letter_pos_x[current_char_i], g_letter_pos_y[current_char_i], 70);
        set_object_visual_data(Module.TextureResourceIndex, 1);
        g_letter_pos_y[current_char_i] = g_letter_pos_y[current_char_i] + 0.4;

        if g_letter_pos_y[current_char_i] > 140 then
            table.insert(to_delete, current_char_i);
        end
    end

    for to_delete_index = #to_delete, 1, -1 do
        local actual_index = to_delete[to_delete_index];
        delete_mesh(g_letter_mesh_indices[actual_index]);
        table.remove(g_letter_mesh_indices, actual_index);
        table.remove(g_letter_pos_x, actual_index);
        table.remove(g_letter_pos_y, actual_index);
    end
end

function Module.initialize()
    -- Nothing to do here
end

function Module.update()
    if g_time_remaining_before_freeze == 1 then
        return;
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
end

return Module;
