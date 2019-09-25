local read_only = require "Data/read_only";
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

local g_is_initialized = false;

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

function update(game_input)
    if not g_is_initialized then
        g_is_initialized = true;

        g_shark = shark_module();
        g_shark.MoveRightMeshResourceIndices = { resources.MeshShark1, resources.MeshShark2, resources.MeshShark1, resources.MeshShark3 };
        g_shark.TurnRightMeshResourceIndices = { resources.MeshSharkT1, resources.MeshSharkT2, resources.MeshSharkT3 };
        g_shark.MoveLeftMeshResourceIndices = { resources.MeshSharkL1, resources.MeshSharkL2, resources.MeshSharkL1, resources.MeshSharkL3 };
        g_shark.TurnLeftMeshResourceIndices = { resources.MeshSharkTL1, resources.MeshSharkTL2, resources.MeshSharkTL3 };
        g_shark.TextureResourceIndex = resources.TextureShark;
        g_shark.StartPosX = 80;
        g_shark.StartPosY = 80;

        g_swim_collision = swim_collision_module();
        g_swim_collision.ChompSoundIndex = resources.SoundChomp;
        g_swim_collision.CrunchSoundIndex = resources.SoundCrunch;
        g_swim_collision.SharkObject = g_shark;
        g_swim_collision.FacingDirection = 0;

        g_swim_animation_mesh_indices[1] = new_mesh(resources.MeshGroove1);
        prioritize_object();

        g_swim_animation_mesh_indices[2] = new_mesh(resources.MeshGroove2);
        prioritize_object();

        g_swim_animation_mesh_indices[3] = new_mesh(resources.MeshGroove3);
        prioritize_object();

        g_swim_animation_mesh_indices[11] = new_mesh(resources.MeshSwimL1);
        prioritize_object();

        g_swim_animation_mesh_indices[12] = new_mesh(resources.MeshSwimL2);
        prioritize_object();

        g_swim_animation_mesh_indices[13] = new_mesh(resources.MeshSwimL3);
        prioritize_object();

        g_swim_animation_mesh_indices[14] = new_mesh(resources.MeshSwimL4);
        prioritize_object();

        g_swim_animation_mesh_indices[21] = new_mesh(resources.MeshSwimR1);
        prioritize_object();

        g_swim_animation_mesh_indices[22] = new_mesh(resources.MeshSwimR2);
        prioritize_object();

        g_swim_animation_mesh_indices[23] = new_mesh(resources.MeshSwimR3);
        prioritize_object();

        g_swim_animation_mesh_indices[24] = new_mesh(resources.MeshSwimR4);
        prioritize_object();

        InitSplashParticles();

        g_swim_animation_frame = 1;
        g_swim_time_in_pool_frames = 0;
    end

    set_player_freeze_cooldown_frame_count(0);
    set_player_is_visible(1);

    g_frames_since_level_start = g_frames_since_level_start + 1;

    select_picture(1);
    script_selected_mesh_scroll_texture(0.025, 0.025);

    select_picture(6);
    script_selected_mesh_scroll_texture(0.04, 0.04);

    select_object_mesh(g_swim_animation_mesh_indices[g_swim_animation_frame]);
    set_object_visual_data(0, 0);

    if g_splash_particle_time > 0 then
        MoveSplashParticles();
    end

    if InTank() then
        g_swim_collision.IsInTank = true;

        if get_player_current_state() == player_state.JSDYING then
            g_swim_death_spin_animation_frame = g_swim_death_spin_animation_frame + 1;
            g_swim_animation_frame = Cycle(g_frames_since_level_start, 22, 1, 3);
            g_swim_rotation_angle = g_swim_death_spin_animation_frame * 12;
            g_swim_time_in_pool_frames = 100;
        else
            g_swim_death_spin_animation_frame = 0;
            Swim(game_input);
        end

        if g_swim_time_in_pool_frames == 0 then
            StartSplashParticles(get_player_current_position_x(), get_player_current_position_y());
        end

        g_swim_time_in_pool_frames = g_swim_time_in_pool_frames + 1;

        if g_swim_time_in_pool_frames > 15 then
            if CheckJump(game_input) then
                return;
            end
        end

        set_player_freeze_cooldown_frame_count(2);
        set_player_is_visible(0);

        local iPX = get_player_current_position_x();
        local iPY = get_player_current_position_y();
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

        select_object_mesh(g_swim_animation_mesh_indices[g_swim_animation_frame]);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_rotate_matrix_z(g_swim_rotation_angle);
        script_selected_mesh_translate_matrix(iDrawX, iDrawY + 5, 2);
        set_object_visual_data(resources.TextureJumpman, 1);

        if get_player_current_state() == player_state.JSDYING then
            set_player_freeze_cooldown_frame_count(0);
        end
    else
        if get_player_current_state() == 4096 then  -- TODO: Constant instead of hard coded number? What causes this state?
            set_player_current_state(player_state.JSFALLING);
        end

        g_swim_time_in_pool_frames = 0;
        g_swim_collision.IsInTank = false;
    end

    g_shark.update(game_input);
    g_swim_collision.update();
end

function MoveSplashParticles()
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

        if iDY < -1 then
            select_object_mesh(g_splash_particle_mesh_indices[iLoop]);
            set_object_visual_data(0, 0);
        else
            is_any_particle_visible = true;
            select_object_mesh(g_splash_particle_mesh_indices[iLoop]);
            script_selected_mesh_set_identity_matrix();

            if iLoop & 1 then
                script_selected_mesh_scale_matrix(3, 2, 1);
            else
                script_selected_mesh_scale_matrix(5, 3, 1);
            end

            script_selected_mesh_translate_matrix(g_splash_particle_start_x + iDX / 200, g_splash_particle_start_y + iDY / 200, -1);
            set_object_visual_data(resources.TextureSBit, 1);
        end
    end

    g_splash_particle_time = g_splash_particle_time + 4.6;

    if not is_any_particle_visible then
        g_splash_particle_time = 0;
    end
end

function StartSplashParticles(iX, iY)
    g_splash_particle_time = 17;
    g_splash_particle_start_x = iX;
    g_splash_particle_start_y = iY + 7;

    g_splash_scale_x = 1.4;
    g_splash_scale_y = 1.4;

    if get_player_current_state() == player_state.JSROLL then
        g_splash_scale_x = 0.5;
        g_splash_scale_y = 1.1;
    end

    if get_player_current_state() == player_state.JSJUMPING then
        g_splash_scale_x = 1;
        g_splash_scale_y = 1.2;
    end
end

function InitSplashParticles()
    for iLoop = 1, 20 do
        g_splash_particle_mesh_indices[iLoop] = new_mesh(resources.MeshSquare);
    end

    g_splash_particle_time = 0;
end

function CheckJump(game_input)
    if game_input.jump_action.is_pressed and get_player_current_position_y() > kTOP_OF_POOL_Y - 2 then
        set_player_current_position_y(kTOP_OF_POOL_Y + 1);
        set_player_current_state(player_state.JSJUMPING);

        if game_input.move_left_action.is_pressed then
            set_player_current_direction(player_movement_direction.DIR_LEFT);
        elseif game_input.move_right_action.is_pressed then
            set_player_current_direction(player_movement_direction.DIR_RIGHT);
        else
            set_player_current_direction(player_movement_direction.DIR_UP);
        end

        set_player_current_state_frame_count(2);
        set_player_current_special_action(0);

        return true;
    end

    return false;
end

function InTank()
    local iPX = get_player_current_position_x();
    local iPY = get_player_current_position_y();

    if iPY > 11 and iPX > 16 then
        if iPY < kTOP_OF_POOL_Y and iPX < 135 then
            return true;
        end
    end

    return false;
end

function Swim(game_input)
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

    local iOldPX = get_player_current_position_x();
    local iOldPY = get_player_current_position_y();

    set_player_current_position_x(iOldPX + iMX);

    if not InTank() then
        set_player_current_position_x(iOldPX);
    end

    set_player_current_position_y(iOldPY + iMY);

    if not InTank() then
        set_player_current_position_y(iOldPY);
    end

    iSpeed = 30;

    if iUp and iLeft then
        g_swim_animation_frame = Cycle(g_frames_since_level_start, iSpeed, 11, 14);
        g_swim_rotation_angle = -45;
    elseif iUp and iRight then
        g_swim_animation_frame = Cycle(g_frames_since_level_start, iSpeed, 21, 24);
        g_swim_rotation_angle = 45;
    elseif iDown and iLeft then
        g_swim_animation_frame = Cycle(g_frames_since_level_start, iSpeed, 11, 14);
        g_swim_rotation_angle = 45;
    elseif iDown and iRight then
        g_swim_animation_frame = Cycle(g_frames_since_level_start, iSpeed, 21, 24);
        g_swim_rotation_angle = -45;
    elseif iUp then
        g_swim_animation_frame = Cycle(g_frames_since_level_start, iSpeed, 11, 14);
        g_swim_rotation_angle = -90;
    elseif iDown then
        g_swim_animation_frame = Cycle(g_frames_since_level_start, iSpeed, 21, 24);
        g_swim_rotation_angle = -90;
    elseif iLeft then
        g_swim_animation_frame = Cycle(g_frames_since_level_start, iSpeed, 11, 14);
        g_swim_rotation_angle = 0;
    elseif iRight then
        g_swim_animation_frame = Cycle(g_frames_since_level_start, iSpeed, 21, 24);
        g_swim_rotation_angle = 0;
    else
        g_swim_animation_frame = Cycle(g_frames_since_level_start, 22, 1, 3);
        g_swim_rotation_angle = math.sin(g_frames_since_level_start * 5 * math.pi / 180.0) * 5;
    end

    if g_swim_animation_frame > 9 then
        g_swim_rotation_angle = g_swim_rotation_angle + math.sin(g_frames_since_level_start * 5 * math.pi / 180.0) * 2;
    end
end

function Cycle(iCCount, iSpeed, iMin, iMax)
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

function reset()
    set_player_current_position_x(130);
    set_player_current_position_y(127);
    set_player_current_position_z(3);
    set_player_current_state(player_state.JSNORMAL);
end
