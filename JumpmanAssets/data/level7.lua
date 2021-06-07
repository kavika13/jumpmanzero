local read_only = require "data/read_only";
local level7_data_module = assert(loadfile("data/level7_data.lua"));
local game_logic_module = assert(loadfile("data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("data/hud_overlay.lua"));
local pause_wave_module = assert(loadfile("data/pause_wave.lua"));

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
    TextureSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    MeshClockHand = 0,
    TextureBlack = 5,
    Textureclockface = 6,
    ScriptPauseWave = 0,
    MeshWave = 1,
    MeshSea = 2,
    TextureWave2 = 7,
    TextureWave1 = 8,
    TextureSea = 9,
    TextureStopWatch = 10,
};
resources = read_only.make_table_read_only(resources);

local kTOP_WAVE_HEIGHT = 125;

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_wave;

local g_big_clock_backdrop_transform_index = -1;
local g_big_clock_hand_transform_index = -1;
local g_clock_num_frames_left = 0;

local g_small_clocks_backdrops = {};
local g_small_clocks_backdrop_transform_indices = {};
local g_small_clocks_current_rotation = 0;
local g_small_clocks_current_rotation_discontinuity = false;
local g_small_clocks_timers = {};
local kNumClockTimers = 5;

local g_blah_blah = -1;

local function SetClockPosition_(iPos)
    transform_set_translation(g_big_clock_backdrop_transform_index, 0 - 64, 0 - 48, 120);
    transform_set_parent_is_camera(g_big_clock_backdrop_transform_index, true);

    transform_set_rotation_z(g_big_clock_hand_transform_index, iPos);
    transform_set_translation(g_big_clock_hand_transform_index, 0 - 54, 0 - 38, 120);
    transform_set_parent_is_camera(g_big_clock_hand_transform_index, true);
end

local function SpinLittleClocks_()
    g_small_clocks_current_rotation = g_small_clocks_current_rotation + 5;
    g_small_clocks_current_rotation_discontinuity = false;

    if g_small_clocks_current_rotation == 90 then
        g_small_clocks_current_rotation = 270;
        g_small_clocks_current_rotation_discontinuity = true;
    end

    if g_small_clocks_current_rotation == 360 then
        g_small_clocks_current_rotation = 0;
        g_small_clocks_current_rotation_discontinuity = true;
    end
end

local function SpinClock_(clock_backdrop, transform_indices)
    local iObjX = clock_backdrop.pos[1];

    transform_set_translation(transform_indices[1], 0 - iObjX, 0, 0);
    transform_set_rotation_y(transform_indices[2], g_small_clocks_current_rotation);
    transform_set_translation(transform_indices[2], iObjX, 0, 7);
    set_mesh_is_visible(clock_backdrop.mesh_index, true);

    if g_small_clocks_current_rotation_discontinuity then
        skip_next_mesh_interpolation(clock_backdrop.mesh_index);
    end
end

local function CollideLittleClocks_()
    for clock_index = 1, kNumClockTimers do
        if g_small_clocks_timers[clock_index] and
                g_small_clocks_timers[clock_index] > 0 and
                g_small_clocks_timers[clock_index] < 10 then
            local current_backdrop = g_small_clocks_backdrops[clock_index];

            SpinClock_(current_backdrop, g_small_clocks_backdrop_transform_indices[clock_index]);

            local iClockX = current_backdrop.pos[1];
            local iClockY = current_backdrop.pos[2];
            local did_collide = g_game_logic.is_player_colliding_with_rect(
                iClockX - 3, iClockY - 4,
                iClockX + 4, iClockY - 1);

            if did_collide and g_small_clocks_timers[clock_index] == 1 then
                g_clock_num_frames_left = g_clock_num_frames_left + 140;
                g_small_clocks_timers[clock_index] = 500;
                set_mesh_is_visible(current_backdrop.mesh_index, false);
            end
        end

        if g_small_clocks_timers[clock_index] and g_small_clocks_timers[clock_index] > 1 then
            g_small_clocks_timers[clock_index] = g_small_clocks_timers[clock_index] - 1;
        end
    end
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    if g_clock_num_frames_left > 0 then
        g_clock_num_frames_left = g_clock_num_frames_left - 1;
        g_wave.TargetWaveHeight = 0 - 10;
    else
        g_wave.TargetWaveHeight = kTOP_WAVE_HEIGHT;
    end

    SetClockPosition_(0 - g_clock_num_frames_left);
    SpinLittleClocks_();
    CollideLittleClocks_();

    g_wave.update();

    g_game_logic.update_player_graphics();
end

function Module.initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = level7_data_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.MenuLogic = Module.MenuLogic;
    g_hud_overlay.GameLogic = g_game_logic;

    local big_clock_hand_mesh_index = new_mesh(resources.MeshClockHand);
    set_mesh_texture(big_clock_hand_mesh_index, resources.TextureBlack);
    set_mesh_is_visible(big_clock_hand_mesh_index, true);
    g_big_clock_hand_transform_index = transform_create();
    mesh_set_transform(big_clock_hand_mesh_index, g_big_clock_hand_transform_index);

    g_wave = pause_wave_module();
    g_wave.GameLogic = g_game_logic;
    g_wave.SeaMeshResourceIndex = resources.MeshSea;
    g_wave.WaveMeshResourceIndex = resources.MeshWave;
    g_wave.SeaTextureResourceIndex = resources.TextureSea;
    g_wave.Wave1TextureResourceIndex = resources.TextureWave1;
    g_wave.Wave2TextureResourceIndex = resources.TextureWave2;
    g_wave.TargetWaveHeight = kTOP_WAVE_HEIGHT;
    g_wave.initialize();

    local setup_object_two_transforms = function(mesh_index)
        local result = { transform_create(), transform_create() };
        mesh_set_transform(mesh_index, result[1]);
        transform_set_parent(result[1], result[2]);
        return result;
    end

    for clock_backdrop_num = 10, 10 + kNumClockTimers - 1 do  -- TODO: Use constant for base num
        local current_backdrop = g_game_logic.find_backdrop_by_number(clock_backdrop_num);
        table.insert(g_small_clocks_backdrops, current_backdrop);
        table.insert(g_small_clocks_backdrop_transform_indices, setup_object_two_transforms(current_backdrop.mesh_index));
        table.insert(g_small_clocks_timers, 1);
    end

    local big_clock_backdrop = g_game_logic.find_backdrop_by_number(1);  -- TODO: Use constant for num
    g_big_clock_backdrop_transform_index = transform_create();
    mesh_set_transform(big_clock_backdrop.mesh_index, g_big_clock_backdrop_transform_index);
    move_transparent_mesh_to_front(big_clock_backdrop.mesh_index);

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
    g_clock_num_frames_left = 0;

    for iLoop = 1, kNumClockTimers do
        if g_small_clocks_timers[iLoop] and g_small_clocks_timers[iLoop] > 1 then
            g_small_clocks_timers[iLoop] = 1;
        end
    end

    g_game_logic.set_player_current_position_x(20);
    g_game_logic.set_player_current_position_y(145);
    g_game_logic.set_player_current_position_z(9);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end

return Module;
