local read_only = require "data/read_only";
local level25_data_module = assert(loadfile("data/level25_data.lua"));
local game_logic_module = assert(loadfile("data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("data/hud_overlay.lua"));
local shark_module = assert(loadfile("data/shark.lua"));
local swim_collision_module = assert(loadfile("data/swim_collision.lua"));

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

-- TODO: Move this into a shared file, split into separate tables by type
local player_movement_direction = {
    DIR_UP = 1,
    DIR_DOWN = 2,
    DIR_LEFT = 3,
    DIR_RIGHT = 4,
};
player_movement_direction = read_only.make_table_read_only(player_movement_direction);

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureJumpman = 0,
    TextureWoodPlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    SoundCrunch = 4,
    MeshGroove1 = 0,
    MeshGroove2 = 1,
    MeshGroove3 = 2,
    MeshSwimL1 = 3,
    MeshSwimL2 = 4,
    MeshSwimL3 = 5,
    MeshSwimL4 = 6,
    MeshSwimR1 = 7,
    MeshSwimR2 = 8,
    MeshSwimR3 = 9,
    MeshSwimR4 = 10,
    TextureSea = 5,
    TextureWater = 6,
    TextureWave1 = 7,
    MeshSquare = 11,
    TextureSBit = 8,
    MeshShark1 = 12,
    MeshShark2 = 13,
    MeshShark3 = 14,
    ScriptShark = 0,
    TextureShark = 9,
    MeshSharkL1 = 15,
    MeshSharkL2 = 16,
    MeshSharkL3 = 17,
    MeshSharkTL1 = 18,
    MeshSharkTL2 = 19,
    MeshSharkTL3 = 20,
    MeshSharkT1 = 21,
    MeshSharkT2 = 22,
    MeshSharkT3 = 23,
    ScriptSwimColl = 1,
    TextureWaterBack = 10,
};
resources = read_only.make_table_read_only(resources);

local swim_animation_frame = {
    SWIM_TREAD_WATER_1 = 1,
    SWIM_TREAD_WATER_2 = 2,
    SWIM_TREAD_WATER_3 = 3,
    SWIM_LEFT_1 = 11,
    SWIM_LEFT_2 = 12,
    SWIM_LEFT_3 = 13,
    SWIM_LEFT_4 = 14,
    SWIM_RIGHT_1 = 21,
    SWIM_RIGHT_2 = 22,
    SWIM_RIGHT_3 = 23,
    SWIM_RIGHT_4 = 24,
};
swim_animation_frame = read_only.make_table_read_only(swim_animation_frame);

local kTOP_OF_POOL_Y = 114;

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_swim_collision;

local g_frames_since_level_start = 0;

local g_jumpman_swim_mesh_index = -1;
local g_jumpman_swim_transform_index = -1;
local g_swim_animation_mesh_indices = {};
local g_swim_animation_current_mesh_index;
local g_swim_rotation_angle;
local g_swim_death_spin_animation_frame;
local g_swim_time_in_pool_frames;

local g_splash_particle_mesh_indices = {};
local g_splash_particle_transform_indices = {};
local g_splash_particle_start_x = 0;
local g_splash_particle_start_y = 0;
local g_splash_particle_time = 0;
local g_splash_scale_x = 0;
local g_splash_scale_y = 0;

local function MoveSplashParticles_()
    local is_any_particle_visible = false;

    for particle_index = 1, 20 do
        local iScale;

        if particle_index & 1 then
            iScale = g_splash_scale_y * 0.95;
        else
            iScale = g_splash_scale_y;
        end

        local iDX = math.cos(((particle_index * 5) + 35) * math.pi / 180.0) * 40 * g_splash_particle_time * g_splash_scale_x;
        iDX = iDX + particle_index - 5.5;

        local iDY = math.sin(((particle_index * 5) + 35) * math.pi / 180.0) * 40 * g_splash_particle_time * iScale;
        local iDrag = g_splash_particle_time / 2;
        iDrag = iDrag * iDrag;
        iDY = iDY - iDrag;

        local mesh_index = g_splash_particle_mesh_indices[particle_index];
        local transform_index = g_splash_particle_transform_indices[particle_index];

        if iDY < -1 then
            set_mesh_is_visible(mesh_index, false);
        else
            is_any_particle_visible = true;

            if particle_index & 1 then
                transform_set_scale(transform_index, 3, 2, 1);
            else
                transform_set_scale(transform_index, 5, 3, 1);
            end

            transform_set_translation(transform_index, g_splash_particle_start_x + iDX / 200, g_splash_particle_start_y + iDY / 200, -1);
            set_mesh_is_visible(mesh_index, true);
        end
    end

    g_splash_particle_time = g_splash_particle_time + 4.6;

    if not is_any_particle_visible then
        g_splash_particle_time = 0;
    end
end

local function InTank_()
    local iPX = g_game_logic.get_player_current_position_x();
    local iPY = g_game_logic.get_player_current_position_y();

    if iPY > 11 and iPX > 16 then
        if iPY < kTOP_OF_POOL_Y and iPX < 135 then
            return true;
        end
    end

    return false;
end

local function Cycle_(iCCount, iSpeed, iMin, iMax)
    local is_negative = false;

    if iCCount < 0 then
        is_negative = true;
        iCCount = 0 - iCCount;
    end

    local iCycle = (iMax - iMin);
    local iCP = (iCCount * iSpeed) & 1023;
    local iPlace = math.floor(((iCP / 128) * iCycle) / 4);

    if is_negative then
        iPlace = iPlace + iCycle;

        if iPlace > iCycle * 2 then
            iPlace = iPlace - iCycle * 2;
        end
    end

    if iPlace > iCycle then
        iPlace = iCycle * 2 - iPlace;
        iPlace = iPlace + 1;
    end

    iPlace = iPlace + iMin;

    if iPlace > iMax then
        iPlace = iMax;
    end

    return iPlace;
end

local function Swim_(game_input)
    local is_swimming_up = false;
    local is_swimming_down = false;
    local is_swimming_left = false;
    local is_swimming_right = false;
    local iMX = 0;
    local iMY = 0;

    local iSpeed = 0.7;

    if game_input.move_left_action.is_pressed and not game_input.move_right_action.is_pressed then
        is_swimming_left = true;
        iMX = iSpeed * -1;
    end

    if game_input.move_right_action.is_pressed and not game_input.move_left_action.is_pressed then
        is_swimming_right = true;
        iMX = iSpeed;
    end

    if game_input.move_up_action.is_pressed and not game_input.move_down_action.is_pressed then
        is_swimming_up = true;
        iMY = iSpeed;
    end

    if game_input.move_down_action.is_pressed and not game_input.move_up_action.is_pressed then
        is_swimming_down = true;
        iMY = iSpeed * -1;
    end

    if game_input.jump_action.is_pressed and not is_swimming_up and not is_player_moving_down and (is_swimming_left ~= is_swimming_right) then
        if g_swim_time_in_pool_frames < 2 then
            is_player_moving_down = true;
            iMY = iSpeed * - 0.5;
        elseif g_swim_time_in_pool_frames > 9 then
            is_swimming_up = true;
            iMY = iSpeed * 0.5;
        end
    end

    if iMX ~= 0 and iMY ~= 0 then
        iMX = iMX / 1.4;
        iMY = iMY / 1.4;
    end

    local iOldPX = g_game_logic.get_player_current_position_x();
    local iOldPY = g_game_logic.get_player_current_position_y();

    g_game_logic.set_player_current_position_x(iOldPX + iMX);

    if not InTank_() then
        g_game_logic.set_player_current_position_x(iOldPX);
    end

    g_game_logic.set_player_current_position_y(iOldPY + iMY);

    if not InTank_() then
        g_game_logic.set_player_current_position_y(iOldPY);
    end

    iSpeed = 30;

    if is_swimming_up and is_swimming_left then
        g_swim_animation_current_mesh_index = Cycle_(g_frames_since_level_start, iSpeed, swim_animation_frame.SWIM_LEFT_1, swim_animation_frame.SWIM_LEFT_4);
        g_swim_rotation_angle = -45;
    elseif is_swimming_up and is_swimming_right then
        g_swim_animation_current_mesh_index = Cycle_(g_frames_since_level_start, iSpeed, swim_animation_frame.SWIM_RIGHT_1, swim_animation_frame.SWIM_RIGHT_4);
        g_swim_rotation_angle = 45;
    elseif is_player_moving_down and is_swimming_left then
        g_swim_animation_current_mesh_index = Cycle_(g_frames_since_level_start, iSpeed, swim_animation_frame.SWIM_LEFT_1, swim_animation_frame.SWIM_LEFT_4);
        g_swim_rotation_angle = 45;
    elseif is_player_moving_down and is_swimming_right then
        g_swim_animation_current_mesh_index = Cycle_(g_frames_since_level_start, iSpeed, swim_animation_frame.SWIM_RIGHT_1, swim_animation_frame.SWIM_RIGHT_4);
        g_swim_rotation_angle = -45;
    elseif is_swimming_up then
        g_swim_animation_current_mesh_index = Cycle_(g_frames_since_level_start, iSpeed, swim_animation_frame.SWIM_LEFT_1, swim_animation_frame.SWIM_LEFT_4);
        g_swim_rotation_angle = -90;
    elseif is_player_moving_down then
        g_swim_animation_current_mesh_index = Cycle_(g_frames_since_level_start, iSpeed, swim_animation_frame.SWIM_RIGHT_1, swim_animation_frame.SWIM_RIGHT_4);
        g_swim_rotation_angle = -90;
    elseif is_swimming_left then
        g_swim_animation_current_mesh_index = Cycle_(g_frames_since_level_start, iSpeed, swim_animation_frame.SWIM_LEFT_1, swim_animation_frame.SWIM_LEFT_4);
        g_swim_rotation_angle = 0;
    elseif is_swimming_right then
        g_swim_animation_current_mesh_index = Cycle_(g_frames_since_level_start, iSpeed, swim_animation_frame.SWIM_RIGHT_1, swim_animation_frame.SWIM_RIGHT_4);
        g_swim_rotation_angle = 0;
    else
        g_swim_animation_current_mesh_index = Cycle_(g_frames_since_level_start, 22, swim_animation_frame.SWIM_TREAD_WATER_1, swim_animation_frame.SWIM_TREAD_WATER_3);
        g_swim_rotation_angle = math.sin(g_frames_since_level_start * 5 * math.pi / 180.0) * 5;
    end

    if g_swim_animation_current_mesh_index >= swim_animation_frame.SWIM_LEFT_1 then
        g_swim_rotation_angle = g_swim_rotation_angle + math.sin(g_frames_since_level_start * 5 * math.pi / 180.0) * 2;
    end
end

local function StartSplashParticles_(iX, iY)
    g_splash_particle_time = 17;
    g_splash_particle_start_x = iX;
    g_splash_particle_start_y = iY + 7;

    g_splash_scale_x = 1.4;
    g_splash_scale_y = 1.4;

    if g_game_logic.get_player_current_state() == player_state.JSROLL then
        g_splash_scale_x = 0.5;
        g_splash_scale_y = 1.1;
    end

    if g_game_logic.get_player_current_state() == player_state.JSJUMPING then
        g_splash_scale_x = 1;
        g_splash_scale_y = 1.2;
    end
end

local function CheckJump_(game_input)
    if game_input.jump_action.is_pressed and g_game_logic.get_player_current_position_y() > kTOP_OF_POOL_Y - 2 then
        g_game_logic.set_player_current_position_y(kTOP_OF_POOL_Y + 1);
        g_game_logic.set_player_current_state(player_state.JSJUMPING);

        if game_input.move_left_action.is_pressed then
            g_game_logic.set_player_current_direction(player_movement_direction.DIR_LEFT);
        elseif game_input.move_right_action.is_pressed then
            g_game_logic.set_player_current_direction(player_movement_direction.DIR_RIGHT);
        else
            g_game_logic.set_player_current_direction(player_movement_direction.DIR_UP);
        end

        g_game_logic.set_player_current_state_frame_count(2);
        g_game_logic.set_player_current_special_action(0);  -- TODO: Don't hard-code enum

        return true;
    end

    return false;
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    g_game_logic.set_player_freeze_cooldown_frame_count(0);
    g_game_logic.set_player_is_visible(true);

    g_frames_since_level_start = g_frames_since_level_start + 1;

    local backdrop_mesh_index = g_game_logic.find_backdrop_by_number(1).mesh_index;  -- TODO: Use constant for num
    scroll_texture_on_mesh(backdrop_mesh_index, 0.025 / 16.0, 0.025 / 16.0);

    backdrop_mesh_index = g_game_logic.find_backdrop_by_number(6).mesh_index;  -- TODO: Use constant for num
    scroll_texture_on_mesh(backdrop_mesh_index, 0.04 / 16.0, 0.04 / 16.0);

    set_mesh_is_visible(g_jumpman_swim_mesh_index, false);

    if g_splash_particle_time > 0 then
        MoveSplashParticles_();
    end

    if InTank_() then
        g_swim_collision.IsInTank = true;

        if g_game_logic.get_player_current_state() == player_state.JSDYING then
            -- TODO: Handle case where jumpman jumps out but gets crunched. Currently can still live
            g_swim_death_spin_animation_frame = g_swim_death_spin_animation_frame + 1;
            g_swim_animation_current_mesh_index = Cycle_(g_frames_since_level_start, 22, swim_animation_frame.SWIM_TREAD_WATER_1, swim_animation_frame.SWIM_TREAD_WATER_3);
            g_swim_rotation_angle = g_swim_death_spin_animation_frame * 12;
            g_swim_time_in_pool_frames = 100;
        else
            g_swim_death_spin_animation_frame = 0;
            Swim_(game_input);
        end

        if g_swim_time_in_pool_frames == 0 then
            StartSplashParticles_(
                g_game_logic.get_player_current_position_x(), g_game_logic.get_player_current_position_y());
        end

        g_swim_time_in_pool_frames = g_swim_time_in_pool_frames + 1;

        if g_swim_time_in_pool_frames > 15 then
            if CheckJump_(game_input) then
                return;
            end
        end

        g_game_logic.set_player_freeze_cooldown_frame_count(2);
        g_game_logic.set_player_is_visible(false);

        local iPX = g_game_logic.get_player_current_position_x();
        local iPY = g_game_logic.get_player_current_position_y();
        local iDrawY;
        local iDrawX;

        -- Simulate underwater currents
        if g_swim_animation_current_mesh_index < swim_animation_frame.SWIM_LEFT_1 then
            iDrawX = iPX + math.sin(g_frames_since_level_start * 6 * math.pi / 180.0) * 2;
            iDrawY = iPY + math.sin(g_frames_since_level_start * 4 * math.pi / 180.0) * 2;
        else
            iDrawX = iPX + math.sin(g_frames_since_level_start * 6 * math.pi / 180.0) * 2;
            iDrawY = iPY + math.sin(g_frames_since_level_start * 4 * math.pi / 180.0) * 2;
        end

        set_mesh_to_mesh(g_jumpman_swim_mesh_index, g_swim_animation_mesh_indices[g_swim_animation_current_mesh_index]);
        transform_set_rotation_z(g_jumpman_swim_transform_index, g_swim_rotation_angle);
        transform_set_translation(g_jumpman_swim_transform_index, iDrawX, iDrawY + 5, 2);
        set_mesh_is_visible(g_jumpman_swim_mesh_index, true);

        if g_game_logic.get_player_current_state() == player_state.JSDYING then
            g_game_logic.set_player_freeze_cooldown_frame_count(0);
        end
    else
        if g_game_logic.get_player_current_state() == 4096 then  -- TODO: Constant instead of hard coded number? What causes this state?
            g_game_logic.set_player_current_state(player_state.JSFALLING);
        end

        g_swim_time_in_pool_frames = 0;
        g_swim_collision.IsInTank = false;
    end

    g_shark.update(game_input);
    g_swim_collision.update();

    g_game_logic.update_player_graphics();
end

local function InitSplashParticles_()
    for particle_index = 1, 20 do
        g_splash_particle_mesh_indices[particle_index] = new_mesh(resources.MeshSquare);
        g_splash_particle_transform_indices[particle_index] = transform_create();
        mesh_set_transform(g_splash_particle_mesh_indices[particle_index], g_splash_particle_transform_indices[particle_index]);
        set_mesh_texture(g_splash_particle_mesh_indices[particle_index], resources.TextureSBit);
    end

    g_splash_particle_time = 0;
end

function Module.initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = level25_data_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.MenuLogic = Module.MenuLogic;
    g_hud_overlay.GameLogic = g_game_logic;

    g_shark = shark_module();
    g_shark.GameLogic = g_game_logic;
    g_shark.MoveRightMeshResourceIndices = { resources.MeshShark1, resources.MeshShark2, resources.MeshShark1, resources.MeshShark3 };
    g_shark.TurnRightMeshResourceIndices = { resources.MeshSharkT1, resources.MeshSharkT2, resources.MeshSharkT3 };
    g_shark.MoveLeftMeshResourceIndices = { resources.MeshSharkL1, resources.MeshSharkL2, resources.MeshSharkL1, resources.MeshSharkL3 };
    g_shark.TurnLeftMeshResourceIndices = { resources.MeshSharkTL1, resources.MeshSharkTL2, resources.MeshSharkTL3 };
    g_shark.TextureResourceIndex = resources.TextureShark;
    g_shark.StartPosX = 80;
    g_shark.StartPosY = 80;
    g_shark.initialize();

    g_swim_collision = swim_collision_module();  -- TODO: Merge swim collision module back into this script?
    g_swim_collision.GameLogic = g_game_logic;
    g_swim_collision.ChompSoundIndex = resources.SoundChomp;
    g_swim_collision.CrunchSoundIndex = resources.SoundCrunch;
    g_swim_collision.SharkObject = g_shark;
    g_swim_collision.FacingDirection = 0;
    g_swim_collision.initialize();

    -- TODO: Don't hard-code animation frame indices
    g_swim_animation_mesh_indices[swim_animation_frame.SWIM_TREAD_WATER_1] = resources.MeshGroove1;
    g_swim_animation_mesh_indices[swim_animation_frame.SWIM_TREAD_WATER_2] = resources.MeshGroove2;
    g_swim_animation_mesh_indices[swim_animation_frame.SWIM_TREAD_WATER_3] = resources.MeshGroove3;
    g_swim_animation_mesh_indices[swim_animation_frame.SWIM_LEFT_1] = resources.MeshSwimL1;
    g_swim_animation_mesh_indices[swim_animation_frame.SWIM_LEFT_2] = resources.MeshSwimL2;
    g_swim_animation_mesh_indices[swim_animation_frame.SWIM_LEFT_3] = resources.MeshSwimL3;
    g_swim_animation_mesh_indices[swim_animation_frame.SWIM_LEFT_4] = resources.MeshSwimL4;
    g_swim_animation_mesh_indices[swim_animation_frame.SWIM_RIGHT_1] = resources.MeshSwimR1;
    g_swim_animation_mesh_indices[swim_animation_frame.SWIM_RIGHT_2] = resources.MeshSwimR2;
    g_swim_animation_mesh_indices[swim_animation_frame.SWIM_RIGHT_3] = resources.MeshSwimR3;
    g_swim_animation_mesh_indices[swim_animation_frame.SWIM_RIGHT_4] = resources.MeshSwimR4;

    g_jumpman_swim_mesh_index = new_mesh(g_swim_animation_mesh_indices[swim_animation_frame.SWIM_TREAD_WATER_1]);
    g_jumpman_swim_transform_index = transform_create();
    mesh_set_transform(g_jumpman_swim_mesh_index, g_jumpman_swim_transform_index);
    set_mesh_texture(g_jumpman_swim_mesh_index, resources.TextureJumpman);

    InitSplashParticles_();

    g_swim_animation_current_mesh_index = swim_animation_frame.SWIM_TREAD_WATER_1;
    g_swim_time_in_pool_frames = 0;

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
    g_game_logic.set_player_current_position_x(130);
    g_game_logic.set_player_current_position_y(127);
    g_game_logic.set_player_current_position_z(3);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end

return Module;
