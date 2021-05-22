local read_only = require "data/read_only";

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
local g_claw_transform_indices = {};
local g_chain_mesh_index = -1;
local g_chain_transform_indices = nil;

local g_claw_rotation = 0;
local g_claw_degrees_open = 0;
local g_anchor_pos_y = 0;

local g_claw_current_pos_x = 0;
local g_claw_current_pos_y = 0;
local g_claw_current_pos_z = 0;

local g_current_status = 0;
local g_time_until_next_grab = 0;

local g_rescued_donut = nil;
local g_rescued_donut_mesh_index_to_transform_index_map = {};
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
    local player_x = Module.GameLogic.get_player_current_position_x();
    local donut_count = Module.GameLogic.get_donut_object_count();

    for donut_index = 0, donut_count - 1 do
        local current_donut = Module.GameLogic.get_donut(donut_index);

        if Module.GameLogic.get_donut_is_collected(donut_index) then
            if current_donut.pos[1] > player_x - 60 and current_donut.pos[1] < player_x + 60 then
                g_rescued_donut = current_donut;
                if not g_rescued_donut_mesh_index_to_transform_index_map[g_rescued_donut.mesh_index] then
                    -- TODO: Should the game logic create these transforms? Get existing transform instead?
                    local new_transform_index = transform_create();
                    g_rescued_donut_mesh_index_to_transform_index_map[g_rescued_donut.mesh_index] = new_transform_index;
                    object_set_transform(g_rescued_donut.mesh_index, new_transform_index);
                end
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

        if g_claw_current_pos_x < g_rescued_donut.pos[1] - 1 then
            g_claw_current_pos_x = g_claw_current_pos_x + 1;
        elseif g_claw_current_pos_x > g_rescued_donut.pos[1] + 1 then
            g_claw_current_pos_x = g_claw_current_pos_x - 1;
        end

        if g_claw_current_pos_y < g_rescued_donut.pos[2] - 1 then
            g_claw_current_pos_y = g_claw_current_pos_y + 1;
        elseif g_claw_current_pos_y > g_rescued_donut.pos[2] + 1 then
            g_claw_current_pos_y = g_claw_current_pos_y - 1;
        end

        transform_set_translation(
            g_rescued_donut_mesh_index_to_transform_index_map[g_rescued_donut.mesh_index],
            g_claw_current_pos_x - g_rescued_donut.pos[1],
            g_claw_current_pos_y - g_rescued_donut.pos[2],
            0 - g_rescued_donut.pos[3]);
        set_mesh_is_visible(g_rescued_donut.mesh_index, true);

        if iOldX == g_claw_current_pos_x and iOldY == g_claw_current_pos_y then
            Module.GameLogic.set_donut_is_collected(g_rescued_donut.index, false);
            transform_clear_translation(g_rescued_donut_mesh_index_to_transform_index_map[g_rescued_donut.mesh_index]);
            g_current_status = status_type.GHOSTING_PLAYER;
            g_time_until_next_grab = 2;
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

local function DrawClaw_(claw_piece_index, iAngle, iSpread)
    local claw_piece_transform_indices = g_claw_transform_indices[claw_piece_index];
    transform_set_translation(claw_piece_transform_indices[1], 0, -5, 0);
    transform_set_rotation_z(claw_piece_transform_indices[1], iSpread);
    transform_concat_rotation_y(claw_piece_transform_indices[1], iAngle);
    transform_set_translation(claw_piece_transform_indices[2], g_claw_current_pos_x, g_claw_current_pos_y + 5, g_claw_current_pos_z);
    set_mesh_is_visible(g_claw_mesh_indices[claw_piece_index], true);
end

local function DrawChain_()
    transform_set_translation(g_chain_transform_indices[1], 0, -0.5, 0);
    transform_set_scale(g_chain_transform_indices[1], 0.4, (g_anchor_pos_y - g_claw_current_pos_y) - 4, 0.4);
    transform_set_translation(g_chain_transform_indices[2], g_claw_current_pos_x, g_anchor_pos_y, g_claw_current_pos_z);
    set_mesh_is_visible(g_chain_mesh_index, true);
end

function Module.initialize()
    g_claw_rotation = 55;
    g_claw_current_pos_x = 40;
    g_claw_current_pos_y = 80;
    g_claw_current_pos_z = -1;
    g_anchor_pos_y = 130;
    g_current_status = status_type.GHOSTING_PLAYER;

    g_claw_mesh_indices[1] = new_mesh(Module.ClawMeshResourceIndex);
    g_claw_mesh_indices[2] = new_mesh(Module.ClawMeshResourceIndex);
    g_claw_mesh_indices[3] = new_mesh(Module.ClawMeshResourceIndex);
    g_claw_mesh_indices[4] = new_mesh(Module.ClawMeshResourceIndex);

    for i = 1, 4 do
        g_claw_transform_indices[i] = { transform_create(), transform_create() };
        object_set_transform(g_claw_mesh_indices[i], g_claw_transform_indices[i][1]);
        transform_set_parent(g_claw_transform_indices[i][1], g_claw_transform_indices[i][2]);
        set_mesh_texture(g_claw_mesh_indices[i], Module.ClawTextureResourceIndex);
    end

    g_chain_mesh_index = new_mesh(Module.ChainMeshResourceIndex);
    g_chain_transform_indices = { transform_create(), transform_create() };
    object_set_transform(g_chain_mesh_index, g_chain_transform_indices[1]);
    transform_set_parent(g_chain_transform_indices[1], g_chain_transform_indices[2]);
    set_mesh_texture(g_chain_mesh_index, Module.ChainTextureResourceIndex);

    g_time_until_next_grab = 2;
end

function Module.update(all_jumpers)
    MoveChain_(all_jumpers);

    g_claw_rotation = g_claw_rotation + math.random(50, 90) / 300;

    DrawClaw_(1, 0 + g_claw_rotation, g_claw_degrees_open);
    DrawClaw_(2, 90 + g_claw_rotation, g_claw_degrees_open);
    DrawClaw_(3, 180 + g_claw_rotation, g_claw_degrees_open);
    DrawClaw_(4, 270 + g_claw_rotation, g_claw_degrees_open);
    DrawChain_();
end

return Module;
