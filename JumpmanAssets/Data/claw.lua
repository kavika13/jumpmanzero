local read_only = require "Data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.ClawMeshResourceIndex = 0;
Module.ChainMeshResourceIndex = 0;
Module.DonutTextureResourceIndex = 0;
Module.ClawTextureResourceIndex = 0;
Module.ChainTextureResourceIndex = 0;

local status_type = {
    GHOSTING_PLAYER = 1,
    RESCUING_STRANDED_JUMPER = 2,
    PLACING_RESCUED_JUMPER = 3,
    RESCUING_GRABBED_DONUT = 22,
    PLACING_RESCUED_DONUT = 23,
};
status_type = read_only.make_table_read_only(status_type);

-- TODO: Pull in from different file somehow?
local jumper_status_type = {
    CROUCHED = 0,
    JUMPING = 1,
    STRANDED = 10,
};
jumper_status_type = read_only.make_table_read_only(jumper_status_type);

local g_claw_mesh_indices = {};
local g_chain_mesh_index = 0;

local g_claw_rotation = 0;
local g_claw_degrees_open = 0;
local g_anchor_pos_y = 0;

local g_claw_current_pos_x = 0;
local g_claw_current_pos_y = 0;
local g_claw_current_pos_z = 0;

local g_current_status = 0;
local g_time_until_next_grab = 0;

local g_rescued_donut_index = -1;
local g_rescued_jumper = nil;

local function FindStranded_(all_jumpers)
    for _, jumper in ipairs(all_jumpers) do
        if jumper.get_current_status() == jumper_status_type.STRANDED then
            g_rescued_jumper = jumper;
            g_current_status = status_type.RESCUING_STRANDED_JUMPER;
            return 0;
        end
    end
end

local function FindDonut_()
    local iPX = Module.GameLogic.get_player_current_position_x();
    local iDonuts = get_donut_object_count();

    for iLoop = 0, iDonuts - 1 do
        abs_donut(iLoop);
        local iDX = get_script_selected_level_object_x1();

        if not get_script_selected_level_object_visible() then
            if iDX > iPX - 60 and iDX < iPX + 60 then
                g_rescued_donut_index = iLoop;
                g_current_status = status_type.RESCUING_GRABBED_DONUT;
                return;
            end
        end
    end
end

local function MoveChain_(all_jumpers)
    local iPX = Module.GameLogic.get_player_current_position_x();
    local iPY = Module.GameLogic.get_player_current_position_y();

    g_time_until_next_grab = g_time_until_next_grab + 1;

    if g_current_status == status_type.GHOSTING_PLAYER and g_time_until_next_grab > 170 then
        FindDonut_();
    end

    if g_current_status == status_type.GHOSTING_PLAYER and g_time_until_next_grab > 120 then
        FindStranded_(all_jumpers);
    end

    if g_current_status == status_type.RESCUING_STRANDED_JUMPER or
            g_current_status == status_type.RESCUING_GRABBED_DONUT then
        if g_claw_current_pos_y > -20 then
            g_claw_current_pos_y = g_claw_current_pos_y - 1;
        else
            if g_current_status == status_type.RESCUING_STRANDED_JUMPER then
                g_current_status = status_type.PLACING_RESCUED_JUMPER;
            else  -- g_current_status was status_type.RESCUING_GRABBED_DONUT
                g_current_status = status_type.PLACING_RESCUED_DONUT;
            end
        end

        if g_claw_current_pos_x < iPX then
            if g_claw_current_pos_x > iPX - 60 then
                g_claw_current_pos_x = g_claw_current_pos_x - 1;
            elseif g_claw_current_pos_x < iPX - 63 then
                g_claw_current_pos_x = g_claw_current_pos_x + 1;
            end
        else
            if g_claw_current_pos_x < iPX + 60 then
                g_claw_current_pos_x = g_claw_current_pos_x + 1;
            elseif g_claw_current_pos_x > iPX + 63 then
                g_claw_current_pos_x = g_claw_current_pos_x - 1;
            end
        end

        g_claw_degrees_open = 45;
    end

    if g_current_status == status_type.PLACING_RESCUED_DONUT then
        local iOldX = g_claw_current_pos_x;
        local iOldY = g_claw_current_pos_y;
        g_claw_degrees_open = 5;

        abs_donut(g_rescued_donut_index);

        if g_claw_current_pos_x < get_script_selected_level_object_x1() - 1 then
            g_claw_current_pos_x = g_claw_current_pos_x + 1;
        elseif g_claw_current_pos_x > get_script_selected_level_object_x1() + 1 then
            g_claw_current_pos_x = g_claw_current_pos_x - 1;
        end

        if g_claw_current_pos_y < get_script_selected_level_object_y1() - 1 then
            g_claw_current_pos_y = g_claw_current_pos_y + 1;
        elseif g_claw_current_pos_y > get_script_selected_level_object_y1() + 1 then
            g_claw_current_pos_y = g_claw_current_pos_y - 1;
        end

        local donut_mesh_index = get_donut_mesh_index(g_rescued_donut_index);
        set_identity_mesh_matrix(donut_mesh_index);
        script_selected_mesh_translate_matrix(
            g_claw_current_pos_x - get_script_selected_level_object_x1(),
            g_claw_current_pos_y - get_script_selected_level_object_y1(),
            0 - get_script_selected_level_object_z1());
        set_object_visual_data(Module.DonutTextureResourceIndex, 1);

        if iOldX == g_claw_current_pos_x and iOldY == g_claw_current_pos_y then
            set_script_selected_level_object_visible(1);
            set_identity_mesh_matrix(donut_mesh_index);
            g_current_status = status_type.GHOSTING_PLAYER;
            g_time_until_next_grab = 50;
        end
    end

    if g_current_status == status_type.PLACING_RESCUED_JUMPER then
        g_rescued_jumper.set_current_pos(g_claw_current_pos_x, g_claw_current_pos_y - 9);

        if g_claw_current_pos_y > iPY + 21 then
            g_rescued_jumper.set_current_status(jumper_status_type.JUMPING);

            if iPX < g_claw_current_pos_x then
                g_rescued_jumper.set_current_velocity(-0.7, 1);
            else
                g_rescued_jumper.set_current_velocity(0.7, 1);
            end

            g_current_status = status_type.GHOSTING_PLAYER;
            g_time_until_next_grab = 0;
        else
            g_claw_current_pos_y = g_claw_current_pos_y + 1;
        end

        if g_claw_current_pos_x < iPX then
            if g_claw_current_pos_x > iPX - 60 then
                g_claw_current_pos_x = g_claw_current_pos_x - 1;
            elseif g_claw_current_pos_x < iPX - 63 then
                g_claw_current_pos_x = g_claw_current_pos_x + 1;
            end
        else
            if g_claw_current_pos_x < iPX + 60 then
                g_claw_current_pos_x = g_claw_current_pos_x + 1;
            elseif g_claw_current_pos_x > iPX + 63 then
                g_claw_current_pos_x = g_claw_current_pos_x - 1;
            end
        end

        g_claw_degrees_open = 30;
    end

    if g_current_status == status_type.GHOSTING_PLAYER then
        if g_claw_current_pos_x < iPX - 5 then
            g_claw_current_pos_x = g_claw_current_pos_x + 0.7;
        elseif g_claw_current_pos_x > iPX + 5 then
            g_claw_current_pos_x = g_claw_current_pos_x - 0.7;
        end

        if g_claw_current_pos_y < iPY + 30 then
            g_claw_current_pos_y = g_claw_current_pos_y + 1;
        elseif g_claw_current_pos_y > iPY + 32 then
            g_claw_current_pos_y = g_claw_current_pos_y - 1;
        end

        g_claw_degrees_open = 25;
    end
end

local function DrawClaw_(current_animation_frame, iAngle, iSpread)
    local anim_mesh_index = g_claw_mesh_indices[current_animation_frame];
    select_object_mesh(anim_mesh_index);
    set_identity_mesh_matrix(anim_mesh_index);
    script_selected_mesh_translate_matrix(0, -5, 0);
    script_selected_mesh_rotate_matrix_z(iSpread);
    rotate_y_mesh_matrix(anim_mesh_index, iAngle);
    script_selected_mesh_translate_matrix(g_claw_current_pos_x, g_claw_current_pos_y + 5, g_claw_current_pos_z);
    set_object_visual_data(Module.ClawTextureResourceIndex, 1);
end

local function DrawChain_()
    select_object_mesh(g_chain_mesh_index);
    set_identity_mesh_matrix(g_chain_mesh_index);
    script_selected_mesh_translate_matrix(0, -0.5, 0);
    scale_mesh_matrix(g_chain_mesh_index, 0.4, (g_anchor_pos_y - g_claw_current_pos_y) - 4, 0.4);
    script_selected_mesh_translate_matrix(g_claw_current_pos_x, g_anchor_pos_y, g_claw_current_pos_z);
    set_object_visual_data(Module.ChainTextureResourceIndex, 1);
end

function Module.initialize()
    g_claw_rotation = 55;
    g_claw_current_pos_x = 40;
    g_claw_current_pos_y = 80;
    g_claw_current_pos_z = -1;
    g_anchor_pos_y = 130;
    g_current_status = status_type.GHOSTING_PLAYER;

    g_claw_mesh_indices[0] = new_mesh(Module.ClawMeshResourceIndex);
    g_claw_mesh_indices[1] = new_mesh(Module.ClawMeshResourceIndex);
    g_claw_mesh_indices[2] = new_mesh(Module.ClawMeshResourceIndex);
    g_claw_mesh_indices[3] = new_mesh(Module.ClawMeshResourceIndex);

    g_chain_mesh_index = new_mesh(Module.ChainMeshResourceIndex);

    g_time_until_next_grab = 120;
end

function Module.update(all_jumpers)
    MoveChain_(all_jumpers);

    g_claw_rotation = g_claw_rotation + math.random(50, 90) / 300;

    DrawClaw_(0, 0 + g_claw_rotation, g_claw_degrees_open);
    DrawClaw_(1, 90 + g_claw_rotation, g_claw_degrees_open);
    DrawClaw_(2, 180 + g_claw_rotation, g_claw_degrees_open);
    DrawClaw_(3, 270 + g_claw_rotation, g_claw_degrees_open);
    DrawChain_();
end

return Module;
