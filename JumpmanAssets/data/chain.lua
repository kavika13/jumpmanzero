local read_only = require "data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.LinkMeshResourceIndex = 0;
Module.LinkTextureResourceIndex = 0;

Module.ChainLength = 30;

local kCHAIN_LINK_COUNT = 30;

-- TODO: Move this into a shared file, split into separate tables by type. Or inject from engine?
local player_state = {
    JSNORMAL = 0,
    JSJUMPING = 1,
    JSRIGHT = 2,
    JSLEFT = 4,
    JSFALLING = 8,
    JSLADDER = 16,
    JSKICK = 32,
    JSROLL = 64,
    JSPUNCH = 128,
    JSDYING = 256,
    JSVINE = 1024,
};
player_state = read_only.make_table_read_only(player_state);

local kPLAYER_CHAIN_OFFSET_Y = 6;
local kPLAYER_CHAIN_OFFSET_Z = 2;

local g_link_mesh_indices = {};
local g_link_transform_indices = {};

local g_chain_anchor_pos_x = 80;
local g_chain_anchor_pos_y = 80;

local g_dont_pull_player_up = false;
local g_dont_pull_player_down = false;
local g_player_air = 0;  -- TODO: Return this from the function instead of making it global?

local function PositionChain_()
    local player_x = Module.GameLogic.get_player_current_position_x();
    local player_y = Module.GameLogic.get_player_current_position_y() + kPLAYER_CHAIN_OFFSET_Y;
    local player_z = Module.GameLogic.get_player_current_position_z() + kPLAYER_CHAIN_OFFSET_Z;

    local distance_x_chain_anchor_to_player = math.abs(g_chain_anchor_pos_x - player_x);
    local distance_y_chain_anchor_to_player = math.abs(g_chain_anchor_pos_y - player_y);

    local distance_chain_anchor_to_player = math.floor(math.sqrt(distance_x_chain_anchor_to_player * distance_x_chain_anchor_to_player + distance_y_chain_anchor_to_player * distance_y_chain_anchor_to_player));
    local SagLength = Module.ChainLength - distance_chain_anchor_to_player;
    local SagDrop = SagLength / 2;

    if SagDrop < 0 then
        SagDrop = 0;
    end

    local link_x_prev = g_chain_anchor_pos_x;
    local link_y_prev = g_chain_anchor_pos_y;

    for link_index = 1, kCHAIN_LINK_COUNT do
        -- TODO: Align links better with anchor point. They seem to wiggle around, probably due to math starting at 1
        local link_x_curr = ((player_x * link_index) + (g_chain_anchor_pos_x * (30 - link_index))) / 30;
        local link_y_curr = ((player_y * link_index) + (g_chain_anchor_pos_y * (30 - link_index))) / 30;
        local ToCenter = math.abs(15 - link_index) / 15;
        ToCenter = ToCenter * ToCenter * SagDrop;
        link_y_curr = link_y_curr - SagDrop + ToCenter;

        local Angle = math.atan(link_y_prev - link_y_curr, distance_x_chain_anchor_to_player / 30) * 180.0 / math.pi;

        if player_x > g_chain_anchor_pos_x then
            Angle = 0 - Angle;
        end

        local distance_link_prev_to_curr = math.floor(math.sqrt((link_y_curr - link_y_prev) * (link_y_curr - link_y_prev) + (link_x_curr - link_x_prev) * (link_x_curr - link_x_prev)));

        if distance_link_prev_to_curr < 0.5 then
            distance_link_prev_to_curr = 0.5;
        end

        local transform_index = g_link_transform_indices[link_index];
        transform_set_scale(transform_index, distance_link_prev_to_curr * 1.6, 1, 1);
        transform_set_rotation_z(transform_index, Angle);
        transform_set_translation(transform_index, link_x_curr, link_y_curr, player_z);

        link_x_prev = link_x_curr;
        link_y_prev = link_y_curr;
    end
end

local function PlayerGrounded_()
    local iPX = Module.GameLogic.get_player_current_position_x();
    local iPY = Module.GameLogic.get_player_current_position_y();
    local iHit, iPlat = Module.GameLogic.find_platform(iPX, iPY, 12, 2);

    g_player_air = iPY - iHit;

    if iHit >= iPY then
        return true;
    end

    return false;
end

local function PlayerInBounds_()
    local player_x = Module.GameLogic.get_player_current_position_x();
    local player_y = Module.GameLogic.get_player_current_position_y() + kPLAYER_CHAIN_OFFSET_Y;

    local distance = math.floor(math.sqrt(  -- Original function call truncated, so truncating here
        (g_chain_anchor_pos_x - player_x) * (g_chain_anchor_pos_x - player_x) +
        (g_chain_anchor_pos_y - player_y) * (g_chain_anchor_pos_y - player_y)));

    if distance > Module.ChainLength then
        return false;
    end

    return true;
end

local function AllowLongJumps_()
    if Module.GameLogic.get_player_current_state() ~= player_state.JSJUMPING then
        return;
    end

    if PlayerInBounds_() then
        return;
    end

    if PlayerGrounded_() then
        return;
    end

    local iPX = Module.GameLogic.get_player_current_position_x();
    local iPY = Module.GameLogic.get_player_current_position_y();

    if Module.GameLogic.get_player_current_state_frame_count() > 20 then
        Module.GameLogic.set_player_current_state_frame_count(
            Module.GameLogic.get_player_current_state_frame_count() + 3);
    end

    if Module.GameLogic.get_player_current_state_frame_count() > 45 and iPY < g_chain_anchor_pos_y then
        g_dont_pull_player_up = true;
        Module.GameLogic.set_player_current_state_frame_count(45);
    end
end

local function AllowLongRoll_()
    if Module.GameLogic.get_player_current_state() ~= player_state.JSROLL then
        return;
    end

    if PlayerInBounds_() then
        return;
    end

    if PlayerGrounded_() then
        return;
    end

    local iPX = Module.GameLogic.get_player_current_position_x();
    local iPY = Module.GameLogic.get_player_current_position_y();

    if Module.GameLogic.get_player_current_state_frame_count() > 8 and iPY < g_chain_anchor_pos_y then
        g_dont_pull_player_up = true;
        Module.GameLogic.set_player_current_state_frame_count(8);
    end
end

local function DisallowBadJumps_()
    if Module.GameLogic.get_player_current_state() ~= player_state.JSJUMPING and
            Module.GameLogic.get_player_current_state() ~= player_state.JSROLL then
        return;
    end

    if PlayerInBounds_() then
        return;
    end

    if Module.GameLogic.get_player_current_position_y() < g_chain_anchor_pos_y then
        return;
    end

    if PlayerGrounded_() then
        g_dont_pull_player_down = true;
    end
end

local function EnforceMovement_()
    if PlayerInBounds_() then
        return;
    end

    local player_x = Module.GameLogic.get_player_current_position_x();
    local player_y = Module.GameLogic.get_player_current_position_y();

    if player_x < g_chain_anchor_pos_x - 1 then
        Module.GameLogic.set_player_current_position_x(player_x + 1);
    elseif player_x > g_chain_anchor_pos_x + 1 then
        Module.GameLogic.set_player_current_position_x(player_x - 1);
    end

    if not PlayerGrounded_() then
        if g_player_air < 2 then
            Module.GameLogic.set_player_current_position_y(player_y - 1);
            return;
        end
    end

    if (player_y + kPLAYER_CHAIN_OFFSET_Y) < g_chain_anchor_pos_y and not g_dont_pull_player_up then
        Module.GameLogic.set_player_current_position_y(player_y + 1);

        if Module.GameLogic.get_player_current_state() == player_state.JSFALLING then
            Module.GameLogic.set_player_current_state_frame_count(5);
        end
    end

    if (player_y + kPLAYER_CHAIN_OFFSET_Y) > g_chain_anchor_pos_y and not g_dont_pull_player_down then
        Module.GameLogic.set_player_current_position_y(player_y - 1);
    end
end

function Module.initialize()
    for iLoop = 1, kCHAIN_LINK_COUNT do
        g_link_mesh_indices[iLoop] = new_mesh(Module.LinkMeshResourceIndex);
        g_link_transform_indices[iLoop] = transform_create();
        mesh_set_transform(g_link_mesh_indices[iLoop], g_link_transform_indices[iLoop]);
        set_mesh_texture(g_link_mesh_indices[iLoop], Module.LinkTextureResourceIndex);
        set_mesh_is_visible(g_link_mesh_indices[iLoop], true);
    end
end

function Module.update()
    PositionChain_();

    g_dont_pull_player_up = false;
    g_dont_pull_player_down = false;

    if Module.GameLogic.get_player_current_state() == player_state.JSDYING then
        return;
    end

    if PlayerGrounded_() then
        g_dont_pull_player_up = true;
    end

    AllowLongJumps_();
    AllowLongRoll_();
    DisallowBadJumps_();

    EnforceMovement_();
    EnforceMovement_();
end

return Module;
