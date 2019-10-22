local read_only = require "Data/read_only";
local level_level25_module = assert(loadfile("Data/level_level25.lua"));
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local shark_module = assert(loadfile("Data/shark.lua"));
local swim_collision_module = assert(loadfile("Data/swim_collision.lua"));

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

-- TODO: Separate file?
local shark_properties = {
    SharkIInit = 0,
    SharkIMeshes = 1,
    SharkIFrame = 32,
    SharkIX = 33,
    SharkIY = 34,
    SharkIZ = 35,
    SharkISlow = 36,
    SharkStartX = 37,
    SharkStartY = 38,
    SharkIAnimate = 39,
    SharkICycle = 40,
    SharkITurn = 41,
    SharkIXV = 42,
    SharkIYV = 43,
};
shark_properties = read_only.make_table_read_only(shark_properties);

-- TODO: Separate file?
local swim_coll_properties = {
    SwimCollInTank = 0,
    SwimCollSharkObj = 1,
    SwimCollFacing = 2,
};
swim_coll_properties = read_only.make_table_read_only(swim_coll_properties);

local kTOP_OF_POOL_Y = 114;

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_swim_collision;

local g_frames_since_level_start = 0;

local g_swim_animation_mesh_indices = {};
local g_swim_animation_frame;
local g_swim_rotation_angle;
local g_swim_death_spin_animation_frame;
local g_swim_time_in_pool_frames;

local g_splash_particle_mesh_indices = {};
local g_splash_particle_start_x = 0;
local g_splash_particle_start_y = 0;
local g_splash_particle_time = 0;
local g_splash_scale_x = 0;
local g_splash_scale_y = 0;

local function MoveSplashParticles_()
    local is_any_particle_visible = false;

    for iLoop = 1, 20 do
        local iScale;

        if iLoop & 1 then
            iScale = g_splash_scale_y * 0.95;
        else
            iScale = g_splash_scale_y;
        end

        local iDX = math.cos(((iLoop * 5) + 35) * math.pi / 180.0) * 40 * g_splash_particle_time * g_splash_scale_x;
        iDX = iDX + iLoop - 5.5;

        local iDY = math.sin(((iLoop * 5) + 35) * math.pi / 180.0) * 40 * g_splash_particle_time * iScale;
        local iDrag = g_splash_particle_time / 2;
        iDrag = iDrag * iDrag;
        iDY = iDY - iDrag;

        local mesh_index = g_splash_particle_mesh_indices[iLoop];

        if iDY < -1 then
            set_mesh_is_visible(mesh_index, false);
        else
            is_any_particle_visible = true;
            set_identity_mesh_matrix(mesh_index);

            if iLoop & 1 then
                scale_mesh_matrix(mesh_index, 3, 2, 1);
            else
                scale_mesh_matrix(mesh_index, 5, 3, 1);
            end

            translate_mesh_matrix(mesh_index, g_splash_particle_start_x + iDX / 200, g_splash_particle_start_y + iDY / 200, -1);
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
    local iUp = false;
    local iDown = false;
    local iLeft = false;
    local iRight = false;
    local iMX = 0;
    local iMY = 0;

    local iSpeed = 0.7;

    if game_input.move_left_action.is_pressed and not game_input.move_right_action.is_pressed then
        iLeft = true;
        iMX = iSpeed * -1;
    end

    if game_input.move_right_action.is_pressed and not game_input.move_left_action.is_pressed then
        iRight = true;
        iMX = iSpeed;
    end

    if game_input.move_up_action.is_pressed and not game_input.move_down_action.is_pressed then
        iUp = true;
        iMY = iSpeed;
    end

    if game_input.move_down_action.is_pressed and not game_input.move_up_action.is_pressed then
        iDown = true;
        iMY = iSpeed * -1;
    end

    if game_input.jump_action.is_pressed and iUp == false and iDown == false and (iLeft ~= iRight) then
        if g_swim_time_in_pool_frames < 2 then
            iDown = true;
            iMY = iSpeed * - 0.5;
        elseif g_swim_time_in_pool_frames > 9 then
            iUp = true;
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

    if iUp and iLeft then
        g_swim_animation_frame = Cycle_(g_frames_since_level_start, iSpeed, 11, 14);
        g_swim_rotation_angle = -45;
    elseif iUp and iRight then
        g_swim_animation_frame = Cycle_(g_frames_since_level_start, iSpeed, 21, 24);
        g_swim_rotation_angle = 45;
    elseif iDown and iLeft then
        g_swim_animation_frame = Cycle_(g_frames_since_level_start, iSpeed, 11, 14);
        g_swim_rotation_angle = 45;
    elseif iDown and iRight then
        g_swim_animation_frame = Cycle_(g_frames_since_level_start, iSpeed, 21, 24);
        g_swim_rotation_angle = -45;
    elseif iUp then
        g_swim_animation_frame = Cycle_(g_frames_since_level_start, iSpeed, 11, 14);
        g_swim_rotation_angle = -90;
    elseif iDown then
        g_swim_animation_frame = Cycle_(g_frames_since_level_start, iSpeed, 21, 24);
        g_swim_rotation_angle = -90;
    elseif iLeft then
        g_swim_animation_frame = Cycle_(g_frames_since_level_start, iSpeed, 11, 14);
        g_swim_rotation_angle = 0;
    elseif iRight then
        g_swim_animation_frame = Cycle_(g_frames_since_level_start, iSpeed, 21, 24);
        g_swim_rotation_angle = 0;
    else
        g_swim_animation_frame = Cycle_(g_frames_since_level_start, 22, 1, 3);
        g_swim_rotation_angle = math.sin(g_frames_since_level_start * 5 * math.pi / 180.0) * 5;
    end

    if g_swim_animation_frame > 9 then
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
    scroll_texture_on_mesh(backdrop_mesh_index, 0.025, 0.025);

    backdrop_mesh_index = g_game_logic.find_backdrop_by_number(6).mesh_index;  -- TODO: Use constant for num
    scroll_texture_on_mesh(backdrop_mesh_index, 0.04, 0.04);

    -- TODO: Looks like jumpman's last animation frame isn't disappearing anymore when the player jumps in water.
    --       The bug might be in game_logic.lua.update_player_graphics, or it might be here
    set_mesh_is_visible(g_swim_animation_mesh_indices[g_swim_animation_frame], false);

    if g_splash_particle_time > 0 then
        MoveSplashParticles_();
    end

    if InTank_() then
        g_swim_collision.IsInTank = true;

        if g_game_logic.get_player_current_state() == player_state.JSDYING then
            g_swim_death_spin_animation_frame = g_swim_death_spin_animation_frame + 1;
            g_swim_animation_frame = Cycle_(g_frames_since_level_start, 22, 1, 3);
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

        -- Simulate underwater currents, quantized to "pixel grid" boundaries
        if g_swim_animation_frame < 10 then
            iDrawX = iPX + math.floor(math.sin(g_frames_since_level_start * 6 * math.pi / 180.0) * 2);
            iDrawY = iPY + math.floor(math.sin(g_frames_since_level_start * 4 * math.pi / 180.0) * 2);
        else
            iDrawX = iPX + math.floor(math.sin(g_frames_since_level_start * 6 * math.pi / 180.0) * 2);
            iDrawY = iPY + math.floor(math.sin(g_frames_since_level_start * 4 * math.pi / 180.0) * 2);
        end

        local swim_anim_mesh_index = g_swim_animation_mesh_indices[g_swim_animation_frame];
        set_identity_mesh_matrix(swim_anim_mesh_index);
        rotate_z_mesh_matrix(swim_anim_mesh_index, g_swim_rotation_angle);
        translate_mesh_matrix(swim_anim_mesh_index, iDrawX, iDrawY + 5, 2);
        set_mesh_is_visible(swim_anim_mesh_index, true);

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
    for iLoop = 1, 20 do
        g_splash_particle_mesh_indices[iLoop] = new_mesh(resources.MeshSquare);
        set_mesh_texture(g_splash_particle_mesh_indices[iLoop], resources.TextureSBit);
    end

    g_splash_particle_time = 0;
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.LevelData = level_level25_module();
    g_game_logic.ResetPlayerCallback = reset;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
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
    g_swim_animation_mesh_indices[1] = new_mesh(resources.MeshGroove1);
    move_mesh_to_front(g_swim_animation_mesh_indices[1]);

    g_swim_animation_mesh_indices[2] = new_mesh(resources.MeshGroove2);
    move_mesh_to_front(g_swim_animation_mesh_indices[2]);

    g_swim_animation_mesh_indices[3] = new_mesh(resources.MeshGroove3);
    move_mesh_to_front(g_swim_animation_mesh_indices[3]);

    g_swim_animation_mesh_indices[11] = new_mesh(resources.MeshSwimL1);
    move_mesh_to_front(g_swim_animation_mesh_indices[11]);

    g_swim_animation_mesh_indices[12] = new_mesh(resources.MeshSwimL2);
    move_mesh_to_front(g_swim_animation_mesh_indices[12]);

    g_swim_animation_mesh_indices[13] = new_mesh(resources.MeshSwimL3);
    move_mesh_to_front(g_swim_animation_mesh_indices[13]);

    g_swim_animation_mesh_indices[14] = new_mesh(resources.MeshSwimL4);
    move_mesh_to_front(g_swim_animation_mesh_indices[14]);

    g_swim_animation_mesh_indices[21] = new_mesh(resources.MeshSwimR1);
    move_mesh_to_front(g_swim_animation_mesh_indices[21]);

    g_swim_animation_mesh_indices[22] = new_mesh(resources.MeshSwimR2);
    move_mesh_to_front(g_swim_animation_mesh_indices[22]);

    g_swim_animation_mesh_indices[23] = new_mesh(resources.MeshSwimR3);
    move_mesh_to_front(g_swim_animation_mesh_indices[23]);

    g_swim_animation_mesh_indices[24] = new_mesh(resources.MeshSwimR4);
    move_mesh_to_front(g_swim_animation_mesh_indices[24]);

    for i = 1, 3 do  -- TODO: Don't hard-code animation frame indices
        set_mesh_texture(g_swim_animation_mesh_indices[i], resources.TextureJumpman);
    end

    for i = 11, 14 do  -- TODO: Don't hard-code animation frame indices
        set_mesh_texture(g_swim_animation_mesh_indices[i], resources.TextureJumpman);
    end

    for i = 21, 24 do  -- TODO: Don't hard-code animation frame indices
        set_mesh_texture(g_swim_animation_mesh_indices[i], resources.TextureJumpman);
    end

    InitSplashParticles_();

    g_swim_animation_frame = 1;
    g_swim_time_in_pool_frames = 0;

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
    g_game_logic.set_player_current_position_x(130);
    g_game_logic.set_player_current_position_y(127);
    g_game_logic.set_player_current_position_z(3);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end
