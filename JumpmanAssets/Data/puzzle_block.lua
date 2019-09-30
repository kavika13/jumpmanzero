local read_only = require "Data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.BlockPieceMeshResourceIndex = 0;
Module.BlockPieceTextureResourceIndex = 0;

Module.InitialBlockPiecePositionsX = {};
Module.InitialBlockPiecePositionsY = {};

local kNUM_BLOCK_PIECES = 4;
local kBLOCK_PIECE_WIDTH = 10;
local kBLOCK_PIECE_HEIGHT = 10;
local kTIME_TO_ANTICIPATE_FALL = 30;

local block_status = {
    INITIAL_POSITION = 0,
    PREPARING_TO_FALL = 5,
    FALLING = 10,
    FINISHED_FALLING = 20,
};
block_status = read_only.make_table_read_only(block_status);

local g_is_initialized = false;

local g_block_piece_mesh_indices = {};

local g_block_piece_positions_x = {};
local g_block_piece_positions_y = {};

local g_current_block_status = block_status.INITIAL_POSITION;
local g_prepare_to_fall_counter = 0;

local function TestCollide_(all_blocks, offset_y, count_unsettled_blocks)
    for _, other_puzzle_block in ipairs(all_blocks) do
        if other_puzzle_block ~= Module then
            if count_unsettled_blocks or
                    other_puzzle_block.get_current_status() == block_status.FINISHED_FALLING then
                for block_piece_index = 1, kNUM_BLOCK_PIECES do
                    if other_puzzle_block.is_intersecting_at_pos(
                            g_block_piece_positions_x[block_piece_index],
                            g_block_piece_positions_y[block_piece_index] - offset_y,
                            0) then
                        return true;
                    end
                end
            end
        end
    end

    return false;
end

local function OtherNearbyBlocksAlreadyFalling_(all_blocks)
    for _, other_puzzle_block in ipairs(all_blocks) do
        if other_puzzle_block ~= Module and other_puzzle_block.get_current_status() == block_status.FALLING then
            for block_piece_index = 1, kNUM_BLOCK_PIECES do
                if other_puzzle_block.is_intersecting_at_pos(
                        g_block_piece_positions_x[block_piece_index],
                        g_block_piece_positions_y[block_piece_index],
                        2) then
                    return true;
                end
            end
        end
    end

    return false;
end

local function MoveBlock_(all_blocks)
    if g_current_block_status == block_status.FALLING then
        for iLoop = 1, kNUM_BLOCK_PIECES do
            g_block_piece_positions_y[iLoop] = g_block_piece_positions_y[iLoop] - 0.125;

            if g_block_piece_positions_y[iLoop] == 0 then
                g_current_block_status = block_status.FINISHED_FALLING;
            end
        end

        if TestCollide_(all_blocks, 1, false) then
            g_current_block_status = block_status.FINISHED_FALLING;
        end
    end

    if g_current_block_status == block_status.PREPARING_TO_FALL then
        g_prepare_to_fall_counter = g_prepare_to_fall_counter + 1;

        if OtherNearbyBlocksAlreadyFalling_(all_blocks) then
            g_prepare_to_fall_counter = 0;
        end

        if g_prepare_to_fall_counter > kTIME_TO_ANTICIPATE_FALL then
            g_current_block_status = block_status.FALLING;
        end
    end

    if g_current_block_status == block_status.INITIAL_POSITION then
        for iLoop = 1, kNUM_BLOCK_PIECES do
            local iTestX = g_block_piece_positions_x[iLoop] * kBLOCK_PIECE_WIDTH + 41 + kBLOCK_PIECE_WIDTH / 2;
            local iTestY = g_block_piece_positions_y[iLoop] * kBLOCK_PIECE_HEIGHT + 4 + kBLOCK_PIECE_HEIGHT / 2;

            if Module.GameLogic.is_player_colliding_with_rect(iTestX - 4, iTestY - 4, iTestX + 4, iTestY + 4) then
                g_current_block_status = block_status.PREPARING_TO_FALL;
                g_prepare_to_fall_counter = 0;
            end
        end
    end
end

local function PutBlockInStartingPos_(all_blocks)
    for iLoop = 1, kNUM_BLOCK_PIECES do
        g_block_piece_positions_y[iLoop] = g_block_piece_positions_y[iLoop] + 4;
    end

    local found_good_starting_spot = false;

    while not found_good_starting_spot do
        for iLoop = 1, kNUM_BLOCK_PIECES do
            g_block_piece_positions_y[iLoop] = g_block_piece_positions_y[iLoop] + 1;
        end

        if not (TestCollide_(all_blocks, 0, true) or
                TestCollide_(all_blocks, -1, true) or
                TestCollide_(all_blocks, 1, true)) then
            found_good_starting_spot = true;
        end
    end

    for iLoop = 1, kNUM_BLOCK_PIECES do
        select_object_mesh(g_block_piece_mesh_indices[iLoop]);
        set_object_visual_data(Module.BlockPieceTextureResourceIndex, 1);
    end
end

local function DrawBlock_()
    local iShake = math.random(0, 10) - 5;

    for iLoop = 1, kNUM_BLOCK_PIECES do
        select_object_mesh(g_block_piece_mesh_indices[iLoop]);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_scale_matrix(kBLOCK_PIECE_WIDTH + 0.2, kBLOCK_PIECE_HEIGHT + 0.2, 3.8);

        if g_current_block_status == block_status.PREPARING_TO_FALL then
            -- TODO: Possible to rotate all shaking pieces as one?
            script_selected_mesh_rotate_matrix_z(iShake);
            script_selected_mesh_translate_matrix(
                g_block_piece_positions_x[iLoop] * kBLOCK_PIECE_WIDTH + 41 + kBLOCK_PIECE_WIDTH / 2 + math.random(0, 2) - 1,
                g_block_piece_positions_y[iLoop] * kBLOCK_PIECE_HEIGHT + 4,
                2.5);
        else
            script_selected_mesh_translate_matrix(
                g_block_piece_positions_x[iLoop] * kBLOCK_PIECE_WIDTH + 41 + kBLOCK_PIECE_WIDTH / 2,
                g_block_piece_positions_y[iLoop] * kBLOCK_PIECE_HEIGHT + 4,
                2.5);
        end
    end
end

local function InitializeBlock_()
    for block_piece_index = 1, kNUM_BLOCK_PIECES do
        g_block_piece_positions_x[block_piece_index] = Module.InitialBlockPiecePositionsX[block_piece_index];
        g_block_piece_positions_y[block_piece_index] = Module.InitialBlockPiecePositionsY[block_piece_index];
    end

    g_current_block_status = block_status.INITIAL_POSITION;
end

function Module.update(all_blocks)
    if not g_is_initialized then
        g_is_initialized = true;

        for i = 1, kNUM_BLOCK_PIECES do
            g_block_piece_mesh_indices[i] = new_mesh(Module.BlockPieceMeshResourceIndex);
        end

        InitializeBlock_();
        PutBlockInStartingPos_(all_blocks);
    end

    MoveBlock_(all_blocks);
    DrawBlock_();
end

function Module.reinitialize()
    -- TODO: Maybe pass the puzzle solution in, instead of using InitialBlockPiecePositions* vars
    InitializeBlock_();
end

function Module.reset_pos(all_blocks)
    PutBlockInStartingPos_(all_blocks);
end

function Module.is_above_the_board()
    for block_piece_index = 1, kNUM_BLOCK_PIECES do
        if g_block_piece_positions_y[block_piece_index] > 3 then
            return true;
        end
    end

    return false;
end

function Module.is_intersecting_at_pos(pos_x, pos_y, max_delta_y)
    for block_piece_index = 1, kNUM_BLOCK_PIECES do
        if g_block_piece_positions_x[block_piece_index] == pos_x and
                math.abs(g_block_piece_positions_y[block_piece_index] - pos_y) <= max_delta_y then
            return true;
        end
    end

    return false;
end

function Module.get_current_status()
    return g_current_block_status;
end

return Module;
