local read_only = require "Data/read_only";
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

local g_is_initialized = false;
local g_goos = {};
local g_currently_spawning_goo = nil;

local g_frames_until_next_goo_spawn = -1;
local g_frames_until_ongoing_goo_spawn_finishes = 0;
local g_goo_spawn_point_object_index;
local g_goo_spawn_pos_x;
local g_goo_spawn_pos_y;

local function MovePyramid_()
    local iPic = 0;

    while iPic < 6 do
        select_picture(iPic + 200);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_translate_matrix(0, -65, -35);
        iPic = iPic + 1;
    end
end

local function SetStartPos_()
    local iRnd = rnd(1, 7);

    if iRnd < 1 then
        iRnd = 1;
    end

    if iRnd > 6 then
        iRnd = 6;
    end

    select_picture(iRnd);
    set_object_visual_data(resources.TextureLitFountain, 1);
    g_goo_spawn_point_object_index = iRnd;
    g_goo_spawn_pos_x = get_script_selected_level_object_x1();
    g_goo_spawn_pos_y = get_script_selected_level_object_y1();
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
    new_goo.SpawnCallback = OnSpawnGoo_;
    new_goo.KillCallback = OnKillGoo_;
    new_goo.MeshResourceIndex = resources.MeshGoo;
    new_goo.TextureResourceIndex = resources.TextureLava;
    table.insert(g_goos, new_goo);
    return new_goo;
end

function update()
    if not g_is_initialized then
        g_is_initialized = true;
        g_frames_until_next_goo_spawn = 5;
        SetStartPos_();
        MovePyramid_();
    end

    g_frames_until_next_goo_spawn = g_frames_until_next_goo_spawn - 1;

    if g_frames_until_next_goo_spawn == 0 then
        g_frames_until_ongoing_goo_spawn_finishes = 150;

        if rnd(1, 100) > 50 then
            g_frames_until_ongoing_goo_spawn_finishes = 100;
        end

        local new_goo = OnSpawnGoo_();
        new_goo.Type = 4;
        new_goo.InitialPosX[1] = g_goo_spawn_pos_x;
        new_goo.InitialPosX[2] = g_goo_spawn_pos_x;
        new_goo.InitialPosY[1] = g_goo_spawn_pos_y;
        new_goo.InitialPosY[2] = g_goo_spawn_pos_y;
        new_goo.InitialIsGrowing = true;
        g_currently_spawning_goo = new_goo;
    end

    if g_frames_until_ongoing_goo_spawn_finishes > 0 then
        g_frames_until_ongoing_goo_spawn_finishes = g_frames_until_ongoing_goo_spawn_finishes - 1;

        if g_frames_until_ongoing_goo_spawn_finishes == 1 then
            select_picture(g_goo_spawn_point_object_index);
            set_object_visual_data(resources.TextureFountain, 1);
            g_currently_spawning_goo.stop_growing();
            g_currently_spawning_goo = nil;
            g_frames_until_next_goo_spawn = 50;
            SetStartPos_();
        end
    end

    for _, goo in ipairs(g_goos) do
        goo.update();
    end
end

function reset()
    set_player_current_position_x(140);
    set_player_current_position_y(140);
    set_player_current_position_z(9);
    set_player_current_state(player_state.JSNORMAL);
end
