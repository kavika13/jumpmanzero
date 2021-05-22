local read_only = require "data/read_only";
local level21_data_module = assert(loadfile("data/level21_data.lua"));
local game_logic_module = assert(loadfile("data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("data/hud_overlay.lua"));
local saw_module = assert(loadfile("data/saw.lua"));

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
    TextureGirder = 1,
    TextureBoringBlush = 2,
    TextureRedMetal = 3,
    TextureDark = 4,
    SoundJump = 0,
    Soundchomp = 1,
    Soundbonk = 2,
    SoundFrog = 3,
    MeshFrogL = 0,
    TextureFrog = 5,
    MeshSaw = 1,
    TextureBoringGray = 6,
    ScriptSaw = 0,
    MeshFrogB1 = 2,
    MeshFrogB2 = 3,
    MeshFrogB3 = 4,
    MeshFrogB4 = 5,
    MeshFrogB5 = 6,
    TextureOilDrum = 7,
    TextureBoringGray = 8,
    TextureBoringBlue = 9,
};
resources = read_only.make_table_read_only(resources);

local frog_animation_frame = {
    IDLE = 1,
    CROAK_1 = 2,
    CROAK_2 = 3,
    CROAK_3 = 4,
    CROAK_4 = 5,
    CROAK_5 = 6,
};
frog_animation_frame = read_only.make_table_read_only(frog_animation_frame);

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_saws = {};
local g_frog_mesh_index = -1;
local g_frog_transform_indices = nil;
local g_frog_animation_mesh_indices = {};
local g_frog_animation_current_mesh_index = frog_animation_frame.IDLE;
local g_frog_animation_frame = 100;

local function RemoveSaw_(saw)
    for index, value in ipairs(g_saws) do
        if value == saw then
            table.remove(g_saws, index);
            return;
        end
    end

    assert(false, "Was unable to find saw to remove");
end

local function SpawnSaw_(initial_pos_x, initial_pos_y)
    local new_saw = saw_module();
    new_saw.GameLogic = g_game_logic;
    new_saw.DestroyObjectCallback = RemoveSaw_;
    new_saw.InitialPosX = initial_pos_x;
    new_saw.InitialPosY = initial_pos_y;
    new_saw.MeshResourceIndex = resources.MeshSaw;
    new_saw.TextureResourceIndex = resources.TextureBoringGray;
    new_saw.initialize();
    return new_saw;
end

local function ControlFrog_()
    g_frog_animation_frame = g_frog_animation_frame - 1;

    if g_frog_animation_frame > 75 then
        g_frog_animation_current_mesh_index = frog_animation_frame.IDLE;
    elseif g_frog_animation_frame > 65 then
        g_frog_animation_current_mesh_index = frog_animation_frame.CROAK_1;
    elseif g_frog_animation_frame > 42 then
        g_frog_animation_current_mesh_index = frog_animation_frame.CROAK_2;
    elseif g_frog_animation_frame > 38 then
        g_frog_animation_current_mesh_index = frog_animation_frame.CROAK_3;
    elseif g_frog_animation_frame > 34 then
        g_frog_animation_current_mesh_index = frog_animation_frame.CROAK_4;
    elseif g_frog_animation_frame > 30 then
        g_frog_animation_current_mesh_index = frog_animation_frame.CROAK_5;
    elseif g_frog_animation_frame == 30 then
        table.insert(g_saws, SpawnSaw_(0, 0));
        play_sound_effect(resources.SoundFrog);
        g_frog_animation_current_mesh_index = frog_animation_frame.CROAK_5;
    elseif g_frog_animation_frame > 20 then
        g_frog_animation_current_mesh_index = frog_animation_frame.CROAK_5;
    elseif g_frog_animation_frame > 16 then
        g_frog_animation_current_mesh_index = frog_animation_frame.CROAK_4;
    elseif g_frog_animation_frame == 11 then
        g_frog_animation_current_mesh_index = frog_animation_frame.CROAK_3;

        if math.random(1, 100) > 50 then
            g_frog_animation_frame = 38;
        end
    elseif g_frog_animation_frame > 10 then
        g_frog_animation_current_mesh_index = frog_animation_frame.CROAK_3;
    elseif g_frog_animation_frame > 5 then
        g_frog_animation_current_mesh_index = frog_animation_frame.CROAK_2;
    elseif g_frog_animation_frame > 1 then
        g_frog_animation_current_mesh_index = frog_animation_frame.CROAK_1;
    else
        g_frog_animation_frame = 95 + math.random(1, 40);
        g_frog_animation_current_mesh_index = frog_animation_frame.CROAK_1;
    end
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    set_mesh_to_mesh(g_frog_mesh_index, g_frog_animation_mesh_indices[g_frog_animation_current_mesh_index]);

    ControlFrog_();

    transform_set_scale(g_frog_transform_indices[1], 2, 2, 2);
    transform_set_translation(g_frog_transform_indices[2], 23, 175, 18);

    for _, saw in ipairs(g_saws) do
        saw.update();
    end

    g_game_logic.update_player_graphics();
end

local function LoadFrogMeshes_()
    g_frog_animation_mesh_indices[frog_animation_frame.IDLE] = resources.MeshFrogL;
    g_frog_animation_mesh_indices[frog_animation_frame.CROAK_1] = resources.MeshFrogB1;
    g_frog_animation_mesh_indices[frog_animation_frame.CROAK_2] = resources.MeshFrogB2;
    g_frog_animation_mesh_indices[frog_animation_frame.CROAK_3] = resources.MeshFrogB3;
    g_frog_animation_mesh_indices[frog_animation_frame.CROAK_4] = resources.MeshFrogB4;
    g_frog_animation_mesh_indices[frog_animation_frame.CROAK_5] = resources.MeshFrogB5;

    g_frog_mesh_index = new_mesh(g_frog_animation_mesh_indices[frog_animation_frame.IDLE]);
    g_frog_transform_indices = { transform_create(), transform_create() };
    object_set_transform(g_frog_mesh_index, g_frog_transform_indices[1]);
    transform_set_parent(g_frog_transform_indices[1], g_frog_transform_indices[2]);
    set_mesh_texture(g_frog_mesh_index, resources.TextureFrog);
    set_mesh_is_visible(g_frog_mesh_index, true);
end

function Module.initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = level21_data_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.MenuLogic = Module.MenuLogic;
    g_hud_overlay.GameLogic = g_game_logic;

    LoadFrogMeshes_();

    table.insert(g_saws, SpawnSaw_(80, 100));
    table.insert(g_saws, SpawnSaw_(75, 100));
    table.insert(g_saws, SpawnSaw_(85, 100));
    table.insert(g_saws, SpawnSaw_(100, 45));
    table.insert(g_saws, SpawnSaw_(105, 45));
    table.insert(g_saws, SpawnSaw_(110, 45));
    table.insert(g_saws, SpawnSaw_(115, 45));

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

function Module.reset()
    g_game_logic.set_player_current_position_x(14);
    g_game_logic.set_player_current_position_y(17);
    g_game_logic.set_player_current_position_z(3);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end

return Module;
