local read_only = require "Data/read_only";
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local ninja_module = assert(loadfile("Data/ninja.lua"));

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

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureJumpman = 0,
    TextureClassicPlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureBullet = 4,
    TextureSky = 5,
    TextureNinja = 6,
    TexturePillar = 7,
    TextureCarpet5 = 8,
    TextureWoodPlatform = 9,
    TextureEvenWood = 10,
    ScriptNinja = 0,
    MeshNjRight1 = 0,
    MeshNjRight2 = 1,
    MeshNjJR = 2,
    MeshNjKR = 3,
    MeshNjRR1 = 4,
    MeshNjRR2 = 5,
    MeshNjRR3 = 6,
    MeshNjRR4 = 7,
    MeshNjLeft1 = 8,
    MeshNjLeft2 = 9,
    MeshNjJL = 10,
    MeshNjKL = 11,
    MeshNjRL1 = 12,
    MeshNjRL2 = 13,
    MeshNjRL3 = 14,
    MeshNjRL4 = 15,
    MeshNjDead = 16,
    MeshNjW1 = 17,
    MeshNjW2 = 18,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
};
resources = read_only.make_table_read_only(resources);

-- TODO: Separate file?
local ninja_properties = {
    NinjaStartX = 0,
    NinjaStartY = 1,
    NinjaIInit = 2,
    NinjaIX = 3,
    NinjaIY = 4,
    NinjaIZ = 5,
    NinjaIFixDonut = 6,
    NinjaISlow = 7,
    NinjaIAnimate = 8,
    NinjaIFrame = 9,
    NinjaIDir = 10,
    NinjaIATime = 11,
    NinjaIMeshes = 12,
    NinjaIStatus = 43,
    NinjaICount = 44,
};
ninja_properties = read_only.make_table_read_only(ninja_properties);

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_ninjas = {};

local g_is_trap_door_triggering = false;
local g_trap_door_fall_progress = 0;

local function MovePlatform_(platform_index, iRotate, iTran)
    local iPlatX = get_platform_x2(platform_index);
    local iPlatY = get_platform_y2(platform_index);

    local platform_mesh_index = get_platform_mesh_index(platform_index);
    set_identity_mesh_matrix(platform_mesh_index);
    translate_mesh_matrix(platform_mesh_index, 0 - iPlatX, 0 - iPlatY, 0);
    rotate_z_mesh_matrix(platform_mesh_index, iRotate);
    translate_mesh_matrix(platform_mesh_index, iPlatX + iTran, iPlatY, 0);
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    if g_is_trap_door_triggering then
        g_trap_door_fall_progress = g_trap_door_fall_progress + 3;

        local platform_index = find_platform_index(1);  -- TODO: Use constant for num
        MovePlatform_(platform_index, g_trap_door_fall_progress, 0);

        -- TODO: There is an engine function for this, but it is not exposed. Seems to be automatically called?
        -- setext(#compose, 1);

        set_platform_y1(platform_index, get_platform_y1(platform_index) - 3);

        if g_trap_door_fall_progress >= 90 then
            set_platform_y1(platform_index, 500);
            set_platform_y2(platform_index, 500);
            g_is_trap_door_triggering = false;
        end
    end

    for _, ninja in ipairs(g_ninjas) do
        ninja.update();
    end

    g_game_logic.update_player_graphics();
end

local function SpawnNinja_(pos_x, pos_y)
    new_ninja = ninja_module();

    new_ninja.GameLogic = g_game_logic;

    new_ninja.MoveRightMeshResourceIndices = { resources.MeshNjRight1, resources.MeshNjRight2 };
    new_ninja.JumpRightMeshResourceIndex = resources.MeshNjJR;
    new_ninja.KickRightMeshResourceIndex = resources.MeshNjKR;
    new_ninja.RollRightMeshResourceIndices = {
        resources.MeshNjRR1, resources.MeshNjRR2, resources.MeshNjRR3, resources.MeshNjRR4,
    };
    new_ninja.MoveLeftMeshResourceIndices = { resources.MeshNjLeft1, resources.MeshNjLeft2 };
    new_ninja.JumpLeftMeshResourceIndex = resources.MeshNjJL;
    new_ninja.KickLeftMeshResourceIndex = resources.MeshNjKL;
    new_ninja.RollLeftMeshResourceIndices = {
        resources.MeshNjRL1, resources.MeshNjRL2, resources.MeshNjRL3, resources.MeshNjRL4,
    };
    new_ninja.DeadMeshResourceIndex = resources.MeshNjDead;
    new_ninja.FixDonutMeshResourceIndices = { resources.MeshNjW1, resources.MeshNjW2 };
    new_ninja.TextureResourceIndex = resources.TextureNinja;

    new_ninja.InitialPosX = pos_x;
    new_ninja.InitialPosY = pos_y;

    new_ninja.initialize();

    table.insert(g_ninjas, new_ninja);
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.ResetPlayerCallback = reset;
    g_game_logic.OnCollectDonutCallback = on_collect_donut;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();

    SpawnNinja_(120, 8);
    SpawnNinja_(70, 40);
    SpawnNinja_(30, 120);
    SpawnNinja_(110, 80);

    reset();

    -- Make sure staged initialization has happened, and Jumpman has floated to the floor
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
end

function update(game_input)
    if not g_title_is_done_scrolling then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return;
    end

    ProgressLevel_(game_input);
end

function on_collect_donut(game_input, iDonut)
    if iDonut == 1 then
        g_is_trap_door_triggering = true;
    end
end

function reset()
    g_game_logic.set_player_current_position_x(20);
    g_game_logic.set_player_current_position_y(7);
    g_game_logic.set_player_current_position_z(1);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);

    for _, ninja in ipairs(g_ninjas) do
        ninja.reset_pos();
    end
end
