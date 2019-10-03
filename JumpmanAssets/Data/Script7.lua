local read_only = require "Data/read_only";
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local pause_wave_module = assert(loadfile("Data/pause_wave.lua"));

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
local g_clock_hand_mesh_index;
local g_clock_num_frames_left = 0;

local g_current_clock_hand_rotation = 0;
local g_clock_timers = {};
local kNumClockTimers = 20;

local function SetClockPosition_(iPos)
    select_picture(1);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(0 - 64, 0 - 48, 120);
    script_selected_mesh_set_perspective_matrix();

    select_object_mesh(g_clock_hand_mesh_index);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_rotate_matrix_z(iPos);
    script_selected_mesh_translate_matrix(0 - 54, 0 - 38, 120);
    script_selected_mesh_set_perspective_matrix();
end

local function SpinLittleClocks_()
    g_current_clock_hand_rotation = g_current_clock_hand_rotation + 5;

    if g_current_clock_hand_rotation == 90 then
        g_current_clock_hand_rotation = 270;
    end

    if g_current_clock_hand_rotation == 360 then
        g_current_clock_hand_rotation = 0;
    end
end

local function SpinClock_(iPic)
    select_picture(iPic);
    local iObjX = get_script_selected_level_object_x1();
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(0 - iObjX, 0, 0);
    script_selected_mesh_rotate_matrix_y(g_current_clock_hand_rotation);
    script_selected_mesh_translate_matrix(iObjX, 0, 7);
    set_object_visual_data(resources.TextureStopWatch, 1);
end

local function CollideLittleClocks_()
    local iLoop = 10;

    while iLoop < kNumClockTimers do
        if g_clock_timers[iLoop] and g_clock_timers[iLoop] > 0 and g_clock_timers[iLoop] < 10 then
            SpinClock_(iLoop);
            select_picture(iLoop);
            local iClockX = get_script_selected_level_object_x1();
            local iClockY = get_script_selected_level_object_y1();
            local did_collide = g_game_logic.is_player_colliding_with_rect(
                iClockX - 3, iClockY - 4,
                iClockX + 4, iClockY - 1);

            if did_collide and g_clock_timers[iLoop] == 1 then
                g_clock_num_frames_left = g_clock_num_frames_left + 140;
                g_clock_timers[iLoop] = 500;
                select_picture(iLoop);
                set_object_visual_data(resources.TextureStopWatch, 0);
            end
        end

        if g_clock_timers[iLoop] and g_clock_timers[iLoop] > 1 then
            g_clock_timers[iLoop] = g_clock_timers[iLoop] - 1;
        end

        iLoop = iLoop + 1;
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
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.ResetPlayerCallback = reset;

    g_hud_overlay = hud_overlay_module();

    g_clock_hand_mesh_index = new_mesh(resources.MeshClockHand);
    select_object_mesh(g_clock_hand_mesh_index);
    set_object_visual_data(resources.TextureBlack, 1);

    g_wave = pause_wave_module();
    g_wave.GameLogic = g_game_logic;
    g_wave.SeaMeshResourceIndex = resources.MeshSea;
    g_wave.WaveMeshResourceIndex = resources.MeshWave;
    g_wave.SeaTextureResourceIndex = resources.TextureSea;
    g_wave.Wave1TextureResourceIndex = resources.TextureWave1;
    g_wave.Wave2TextureResourceIndex = resources.TextureWave2;
    g_wave.TargetWaveHeight = kTOP_WAVE_HEIGHT;
    g_wave.initialize();

    g_clock_timers[10] = 1;
    g_clock_timers[11] = 1;
    g_clock_timers[12] = 1;
    g_clock_timers[13] = 1;
    g_clock_timers[14] = 1;

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
    g_clock_num_frames_left = 0;

    local iLoop = 10;

    while iLoop < kNumClockTimers do
        if g_clock_timers[iLoop] and g_clock_timers[iLoop] > 1 then
            g_clock_timers[iLoop] = 1;
        end

        iLoop = iLoop + 1;
    end

    set_player_current_position_x(20);
    set_player_current_position_y(145);
    set_player_current_position_z(9);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end
