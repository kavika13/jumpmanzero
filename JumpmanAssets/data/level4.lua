local read_only = require "data/read_only";
local level4_data_module = assert(loadfile("data/level4_data.lua"));
local game_logic_module = assert(loadfile("data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("data/hud_overlay.lua"));
local ninja_module = assert(loadfile("data/ninja.lua"));

local Module = {};

Module.MenuLogic = nil;

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

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_ninjas = {};

local g_is_trap_door_triggering = false;
local g_trap_door_platform = nil;
local g_trap_door_platform_transform_indices = nil;
local g_trap_door_fall_progress = 0;

local function MovePlatform_(current_platform, iRotate, iTran, platform_transform_indices)
    local iPlatX = current_platform.pos_lower_right[1];
    local iPlatY = current_platform.pos_lower_right[2];

    transform_set_translation(platform_transform_indices[1], 0 - iPlatX, 0 - iPlatY, 0);
    transform_set_rotation_z(platform_transform_indices[2], iRotate);
    transform_set_translation(platform_transform_indices[2], iPlatX + iTran, iPlatY, 0);
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    if g_is_trap_door_triggering then
        g_trap_door_fall_progress = g_trap_door_fall_progress + 3;

        MovePlatform_(g_trap_door_platform, g_trap_door_fall_progress, 0, g_trap_door_platform_transform_indices);
        g_trap_door_platform.set_pos_y_top(g_trap_door_platform.pos_upper_left[2] - 3);  -- TODO: Why not setting bottom?

        if g_trap_door_fall_progress >= 90 then
            g_trap_door_platform.set_pos_y(500, 500);
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

function Module.initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = level4_data_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.OnCollectDonutCallback = Module.on_collect_donut;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.MenuLogic = Module.MenuLogic;
    g_hud_overlay.GameLogic = g_game_logic;

    SpawnNinja_(120, 8);
    SpawnNinja_(70, 40);
    SpawnNinja_(30, 120);
    SpawnNinja_(110, 80);

    local setup_object_two_transforms = function(mesh_index)
        local result = { transform_create(), transform_create() };
        mesh_set_transform(mesh_index, result[1]);
        transform_set_parent(result[1], result[2]);
        return result;
    end

    g_trap_door_platform = g_game_logic.find_platform_by_number(1);  -- TODO: Use constant for num
    g_trap_door_platform_transform_indices = setup_object_two_transforms(g_trap_door_platform.mesh_index);

    Module.reset();

    -- Make sure staged initialization has happened, and Jumpman has floated to the floor
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
end

function Module.update(game_input)
    if not g_title_is_done_scrolling then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return;
    end

    ProgressLevel_(game_input);
end

function Module.on_collect_donut(game_input, iDonut)
    if iDonut == 1 then
        g_is_trap_door_triggering = true;
        skip_next_mesh_interpolation(g_trap_door_platform.mesh_index);
    end
end

function Module.reset()
    g_game_logic.set_player_current_position_x(20);
    g_game_logic.set_player_current_position_y(7);
    g_game_logic.set_player_current_position_z(1);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);

    for _, ninja in ipairs(g_ninjas) do
        ninja.reset_pos();
    end
end

return Module;
