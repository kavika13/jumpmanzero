local read_only = require "Data/read_only";
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local goo_module = assert(loadfile("Data/goo.lua"));

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
    ScriptGoo = 0,
    TextureJumpman = 0,
    TextureClassicPlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureDarkSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    MeshGoo = 0,
    TextureLava = 5,
    TextureFountain = 6,
    TextureLitFountain = 7,
    TextureStone = 8,
    TextureDesert = 9,
};
resources = read_only.make_table_read_only(resources);

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_goos = {};
local g_currently_spawning_goo = nil;

local g_frames_until_next_goo_spawn = -1;
local g_frames_until_ongoing_goo_spawn_finishes = 0;
local g_goo_spawn_point_object_num;
local g_goo_spawn_pos_x;
local g_goo_spawn_pos_y;

local function MovePyramid_()
    local iPic = 0;

    while iPic < 6 do
        local backdrop_mesh_index = find_backdrop_mesh_index(iPic + 200);  -- TODO: Use constant for num
        set_identity_mesh_matrix(backdrop_mesh_index);
        translate_mesh_matrix(backdrop_mesh_index, 0, -65, -35);
        iPic = iPic + 1;
    end
end

local function SetStartPos_()
    local iRnd = math.random(1, 7);

    if iRnd < 1 then  -- TODO: Use constant for min num
        iRnd = 1;
    end

    if iRnd > 6 then  -- TODO: Use constant for max num
        iRnd = 6;
    end

    local backdrop_mesh_index = find_backdrop_mesh_index(iRnd);
    set_mesh_texture(backdrop_mesh_index, resources.TextureLitFountain);
    g_goo_spawn_point_object_num = iRnd;

    local backdrop_index = find_backdrop_index(iRnd);
    g_goo_spawn_pos_x = get_backdrop_x1(backdrop_index);
    g_goo_spawn_pos_y = get_backdrop_y1(backdrop_index);
end

local function OnKillGoo_(goo)
    for index, value in ipairs(g_goos) do
        if value == goo then
            table.remove(g_goos, index);
            return;
        end
    end

    assert(false, "Was unable to find goo to remove");
end

local function OnSpawnGoo_()
    local new_goo = goo_module();
    new_goo.GameLogic = g_game_logic;
    new_goo.SpawnCallback = OnSpawnGoo_;
    new_goo.KillCallback = OnKillGoo_;
    new_goo.MeshResourceIndex = resources.MeshGoo;
    new_goo.TextureResourceIndex = resources.TextureLava;
    table.insert(g_goos, new_goo);
    return new_goo;
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    g_frames_until_next_goo_spawn = g_frames_until_next_goo_spawn - 1;

    if g_frames_until_next_goo_spawn == 0 then
        g_frames_until_ongoing_goo_spawn_finishes = 150;

        if math.random(1, 100) > 50 then
            g_frames_until_ongoing_goo_spawn_finishes = 100;
        end

        local new_goo = OnSpawnGoo_();
        new_goo.Type = 4;
        new_goo.InitialPosX[1] = g_goo_spawn_pos_x;
        new_goo.InitialPosX[2] = g_goo_spawn_pos_x;
        new_goo.InitialPosY[1] = g_goo_spawn_pos_y;
        new_goo.InitialPosY[2] = g_goo_spawn_pos_y;
        new_goo.InitialIsGrowing = true;
        new_goo.initialize();
        g_currently_spawning_goo = new_goo;
    end

    if g_frames_until_ongoing_goo_spawn_finishes > 0 then
        g_frames_until_ongoing_goo_spawn_finishes = g_frames_until_ongoing_goo_spawn_finishes - 1;

        if g_frames_until_ongoing_goo_spawn_finishes == 1 then
            local backdrop_mesh_index = find_backdrop_mesh_index(g_goo_spawn_point_object_num);
            set_mesh_texture(backdrop_mesh_index, resources.TextureFountain);
            g_currently_spawning_goo.stop_growing();
            g_currently_spawning_goo = nil;
            g_frames_until_next_goo_spawn = 50;
            SetStartPos_();
        end
    end

    for _, goo in ipairs(g_goos) do
        goo.update();
    end

    g_game_logic.update_player_graphics();
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.ResetPlayerCallback = reset;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();

    g_frames_until_next_goo_spawn = 5;

    SetStartPos_();
    MovePyramid_();

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

function reset()
    g_game_logic.set_player_current_position_x(140);
    g_game_logic.set_player_current_position_y(140);
    g_game_logic.set_player_current_position_z(9);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end
