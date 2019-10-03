local read_only = require "Data/read_only";
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local bullet_module = assert(loadfile("Data/bullet.lua"));
local puzzle_block_module = assert(loadfile("Data/puzzle_block.lua"));
local puzzle_solution_module = assert(loadfile("Data/puzzle_solution.lua"));

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

-- TODO: Move this into a shared file, split into separate tables by type
local camera_mode = {
    PerspectiveNormal = 0,
    PerspectiveCloseUp = 1,
    PerspectiveFar = 2,
    PerspectiveWide = 3,
    PerspectiveFollow = 4,
    PerspectiveFixed = 5,
};
camera_mode = read_only.make_table_read_only(camera_mode);

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureJumpman = 0,
    TextureClassicPlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    ScriptBullet = 0,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    TextureBullet = 5,
    TextureGrid = 6,
    ScriptBlock = 1,
    MeshGoo = 2,
    ScriptBFormat = 2,
    TextureBoringBlue = 7,
    TextureBoringBlush = 8,
    TextureBoringGray = 9,
    TextureBoringGreen = 10,
    TextureBoringOrange = 11,
    TextureBoringPink = 12,
    TextureBoringPurple = 13,
    TextureBoringRed = 14,
    TextureBoringYellow = 15,
};
resources = read_only.make_table_read_only(resources);

local g_is_initialized = false;
local g_is_first_update_complete = false;
local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_puzzle_solution;
local g_puzzle_blocks = {};
local g_bullet;

local g_block_object_indices = {};
local kNUM_BLOCKS = 9;

local function GetColor(iNum)
    return resources.TextureBoringBlue + iNum - 1;
end

local function AssignBlockPieceInitialPositions_(puzzle_solution, block, iNum)
    -- TODO: It might be simpler to just pass g_puzzle_solution into the blocks
    local iPartNum = 1;

    for iX = 1, 9 do
        for iY = 1, 4 do
            local iCol = puzzle_solution.get_color_at_pos(iX, iY);

            if iCol == iNum then
                block.InitialBlockPiecePositionsX[iPartNum] = iX - 1;
                block.InitialBlockPiecePositionsY[iPartNum] = iY - 1;
                iPartNum = iPartNum + 1;
            end
        end
    end
end

local function CreateBlock_(iNum)
    local new_block = puzzle_block_module();
    new_block.GameLogic = g_game_logic;
    new_block.BlockPieceMeshResourceIndex = resources.MeshGoo;
    new_block.BlockPieceTextureResourceIndex = GetColor(iNum);
    AssignBlockPieceInitialPositions_(g_puzzle_solution, new_block, iNum);
    return new_block;
end

local function InitializeBlocks_()
    for iTemp = 1, kNUM_BLOCKS do
        table.insert(g_puzzle_blocks, CreateBlock_(iTemp));
    end
end

local function ResetBlocks_()
    -- TODO: It might be simpler to just pass g_puzzle_solution into the blocks
    --       Still would require a 2-stage reset, but be able to expose less variables of blocks
    for iTemp = 1, kNUM_BLOCKS do
        AssignBlockPieceInitialPositions_(g_puzzle_solution, g_puzzle_blocks[iTemp], iTemp);
        g_puzzle_blocks[iTemp].reinitialize();
    end

    -- Need to reset block pos after all pieces have their initial positions set again, so they spread correctly
    for iTemp = 1, kNUM_BLOCKS do
        g_puzzle_blocks[iTemp].reset_pos(g_puzzle_blocks);
    end
end

function update(game_input, is_initializing)
    if not g_is_initialized then
        g_is_initialized = true;

        g_game_logic = game_logic_module();
        g_game_logic.ResetPlayerCallback = reset;
        g_game_logic.OnCollectDonutCallback = on_collect_donut;

        g_hud_overlay = hud_overlay_module();

        set_current_camera_mode(camera_mode.PerspectiveFar);

        select_donut(2);
        set_script_selected_level_object_visible(0);

        g_puzzle_solution = puzzle_solution_module();
        g_puzzle_solution.find_new_layout();

        InitializeBlocks_();

        g_bullet = bullet_module();
        g_bullet.GameLogic = g_game_logic;
        g_bullet.FramesToWait = 100;
        g_bullet.Mesh1Index = resources.MeshBullet1;
        g_bullet.Mesh2Index = resources.MeshBullet2;
        g_bullet.TextureIndex = resources.TextureBullet;
        g_bullet.FireSoundIndex = resources.SoundFire;
    end

    -- TODO: Can probably make a parent meta script that calls into this and into hud_overlay.
    --       That should simplify this logic drastically.
    --       Probably best to do that with the level loader refactor?
    if is_initializing or g_title_is_done_scrolling then
        local continue_update = g_game_logic.progress_game(game_input);
        g_hud_overlay.update(game_input);

        if not continue_update then
            return true;
        end
    elseif g_is_first_update_complete then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return false;
    end

    for _, puzzle_block in ipairs(g_puzzle_blocks) do
        puzzle_block.update(g_puzzle_blocks);
    end

    g_bullet.update();

    -- TODO: Change donut visual state when win imminent? Particles, dancing, glowing?
    -- TODO: Change donut visual state when reset is necessary? Greying out, animation, different "reset" mesh?

    if not g_is_first_update_complete then
        g_is_first_update_complete = true;
        return false;
    end

    return true;
end

local function CheckForWin()
    for _, puzzle_block in ipairs(g_puzzle_blocks) do
        if puzzle_block.is_above_the_board() then
            return false;
        end
    end

    return true;
end

function on_collect_donut(game_input, iDonut)
    if CheckForWin() then
        g_game_logic.win();
        return;
    end

    if iDonut == 1 then
        select_donut(2);
        set_script_selected_level_object_visible(1);
    end

    if iDonut == 2 then
        select_donut(1);
        set_script_selected_level_object_visible(1);
    end

    g_puzzle_solution.find_new_layout();
    ResetBlocks_();
end

function reset()
    set_player_current_position_x(8);
    set_player_current_position_y(5);
    set_player_current_position_z(3);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);

    if g_is_initialized then
        g_bullet.reset_pos();
    end
end
