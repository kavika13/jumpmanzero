local read_only = require "data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.LeftStandMeshResourceIndex = 0;
Module.RightStandMeshResourceIndex = 0;
Module.LeftWalkMeshResourceIndices = {};
Module.RightWalkMeshResourceIndices = {};
Module.LeftYellMeshResourceIndices = {};
Module.RightYellMeshResourceIndices = {};
Module.RoarSoundResourceIndex = 0;
Module.TextureResourceIndex = 0;

local animation_frame = {
    STAND_LEFT = 0,
    WALK_LEFT_1 = 1,
    WALK_LEFT_2 = 2,
    WALK_LEFT_3 = 3,
    WALK_LEFT_4 = 4,
    YELL_LEFT_1 = 5,
    YELL_LEFT_2 = 6,
    YELL_LEFT_3 = 7,
    YELL_LEFT_4 = 8,
    YELL_LEFT_5 = 9,
    META_FACE_RIGHT = 10,  -- Not an actual animation frame
    STAND_RIGHT = 10,
    WALK_RIGHT_1 = 11,
    WALK_RIGHT_2 = 12,
    WALK_RIGHT_3 = 13,
    WALK_RIGHT_4 = 14,
    YELL_RIGHT_1 = 15,
    YELL_RIGHT_2 = 16,
    YELL_RIGHT_3 = 17,
    YELL_RIGHT_4 = 18,
    YELL_RIGHT_5 = 19,
};
animation_frame = read_only.make_table_read_only(animation_frame);

local kYELLING_LEFT = 1;
local kYELLING_RIGHT = 2;
local kMOVING_LEFT = 3;
local kMOVING_RIGHT = 4;

local g_dino_mesh_index = -1;
local g_dino_transform_index = -1;
local g_animation_mesh_indices = {};
local g_animation_current_frame;

local g_has_yelled = false;

local g_current_pos_x;
local g_current_pos_y;

local g_current_state;
local g_frames_since_state_change;
local g_current_state_animation_frame = 0;
local g_current_state_animation_counter = 0;

local function Move_()
    local iMotion;
    local iHit, iPlat = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y, 5, 2);

    if iHit > g_current_pos_y + 1 then
        g_current_pos_y = g_current_pos_y + 1;
    elseif iHit < g_current_pos_y - 1 then
        g_current_pos_y = g_current_pos_y - 1;
    else
        g_current_pos_y = iHit;
    end

    local iPX = Module.GameLogic.get_player_current_position_x();
    local iPY = Module.GameLogic.get_player_current_position_y();

    if g_current_state == kMOVING_LEFT or g_current_state == kMOVING_RIGHT then
        if g_current_state == kMOVING_LEFT then
            if not g_has_yelled then
                if iPY < g_current_pos_y + 40 and iPX < g_current_pos_x - 10 and iPX > g_current_pos_x - 60 then
                    play_sound_effect(Module.RoarSoundResourceIndex);
                    g_current_state = kYELLING_LEFT;
                    g_frames_since_state_change = 0;
                end
            end

            iMotion = -0.75;
        else
            if not g_has_yelled then
                if iPY < g_current_pos_y + 40 and iPX > g_current_pos_x + 10 and iPX < g_current_pos_x + 60 then
                    play_sound_effect(Module.RoarSoundResourceIndex);
                    g_current_state = kYELLING_RIGHT;
                    g_frames_since_state_change = 0;
                end
            end

            iMotion = 0.75;
        end

        g_current_pos_x = g_current_pos_x + iMotion;

        if g_has_yelled then
            g_current_pos_x = g_current_pos_x + iMotion;
        end

        if g_current_pos_x < 10 and g_current_state == kMOVING_LEFT then
            g_current_state = kMOVING_RIGHT;
            g_has_yelled = false;
            g_frames_since_state_change = 0;
        end

        if g_current_pos_x > 150 and g_current_state == kMOVING_RIGHT then
            g_current_state = kMOVING_LEFT;
            g_has_yelled = false;
            g_frames_since_state_change = 0;
        end
    end

    if g_current_state == kYELLING_LEFT or g_current_state == kYELLING_RIGHT then
        if g_frames_since_state_change > 100 then
            g_frames_since_state_change = 0;

            if g_current_state == kYELLING_LEFT then
                g_current_state = kMOVING_LEFT;
            else
                g_current_state = kMOVING_RIGHT;
            end

            g_has_yelled = true;
        end
    end
end

local function SetFrame_()
    g_frames_since_state_change = g_frames_since_state_change + 1;

    if g_current_state == kYELLING_LEFT or g_current_state == kYELLING_RIGHT then
        g_animation_current_frame = animation_frame.YELL_LEFT_2 + g_current_state_animation_frame;

        if g_frames_since_state_change < 15 or g_frames_since_state_change > 85 then
            g_animation_current_frame = animation_frame.YELL_LEFT_1;
        end

        if g_frames_since_state_change < 10 or g_frames_since_state_change > 90 then
            g_animation_current_frame = animation_frame.STAND_LEFT;
        end

        if g_current_state == kYELLING_RIGHT then
            g_animation_current_frame = animation_frame.META_FACE_RIGHT + g_animation_current_frame;
        end
    elseif g_current_state == kMOVING_LEFT then
        g_animation_current_frame = animation_frame.WALK_LEFT_1 + g_current_state_animation_frame;
    elseif g_current_state == kMOVING_RIGHT then
        g_animation_current_frame = animation_frame.WALK_RIGHT_1 + g_current_state_animation_frame;
    end
end

local function Animate_()
    g_current_state_animation_counter = g_current_state_animation_counter + 1;

    if g_current_state_animation_counter > 3 or (g_current_state_animation_counter > 1 and g_has_yelled) then
        g_current_state_animation_counter = 0;
        g_current_state_animation_frame = g_current_state_animation_frame + 1;

        if g_current_state_animation_frame == 4 then
            g_current_state_animation_frame = 0;
        end
    end
end

function Module.initialize()
    g_current_pos_x = 140;
    g_current_pos_y = 2;
    g_current_state = kMOVING_LEFT;
    g_frames_since_state_change = 0;

    g_animation_mesh_indices[animation_frame.STAND_LEFT] = Module.LeftStandMeshResourceIndex;

    g_animation_mesh_indices[animation_frame.WALK_LEFT_1] = Module.LeftWalkMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.WALK_LEFT_2] = Module.LeftWalkMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.WALK_LEFT_3] = Module.LeftWalkMeshResourceIndices[3];
    g_animation_mesh_indices[animation_frame.WALK_LEFT_4] = Module.LeftWalkMeshResourceIndices[4];

    g_animation_mesh_indices[animation_frame.YELL_LEFT_1] = Module.LeftYellMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.YELL_LEFT_2] = Module.LeftYellMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.YELL_LEFT_3] = Module.LeftYellMeshResourceIndices[3];
    g_animation_mesh_indices[animation_frame.YELL_LEFT_4] = Module.LeftYellMeshResourceIndices[4];
    g_animation_mesh_indices[animation_frame.YELL_LEFT_5] = Module.LeftYellMeshResourceIndices[3];

    g_animation_mesh_indices[animation_frame.STAND_RIGHT] = Module.RightStandMeshResourceIndex;

    g_animation_mesh_indices[animation_frame.WALK_RIGHT_1] = Module.RightWalkMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.WALK_RIGHT_2] = Module.RightWalkMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.WALK_RIGHT_3] = Module.RightWalkMeshResourceIndices[3];
    g_animation_mesh_indices[animation_frame.WALK_RIGHT_4] = Module.RightWalkMeshResourceIndices[4];

    g_animation_mesh_indices[animation_frame.YELL_RIGHT_1] = Module.RightYellMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.YELL_RIGHT_2] = Module.RightYellMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.YELL_RIGHT_3] = Module.RightYellMeshResourceIndices[3];
    g_animation_mesh_indices[animation_frame.YELL_RIGHT_4] = Module.RightYellMeshResourceIndices[4];
    g_animation_mesh_indices[animation_frame.YELL_RIGHT_5] = Module.RightYellMeshResourceIndices[3];

    g_dino_mesh_index = new_mesh(g_animation_mesh_indices[animation_frame.STAND_LEFT]);
    g_dino_transform_index = transform_create();
    object_set_transform(g_dino_mesh_index, g_dino_transform_index);
    set_mesh_texture(g_dino_mesh_index, Module.TextureResourceIndex);
    set_mesh_is_visible(g_dino_mesh_index, true);

    g_animation_current_frame = animation_frame.STAND_LEFT;
end

function Module.update()
    Animate_();
    SetFrame_();
    Move_();

    set_mesh_to_mesh(g_dino_mesh_index, g_animation_mesh_indices[g_animation_current_frame]);
    transform_set_scale(g_dino_transform_index, 2, 2, 1.5);
    transform_set_translation(g_dino_transform_index, g_current_pos_x, g_current_pos_y + 19, 3);

    if g_current_state == kMOVING_LEFT or g_current_state == kYELLING_LEFT then
        if Module.GameLogic.is_player_colliding_with_rect(
                g_current_pos_x - 22, g_current_pos_y + 28,
                g_current_pos_x - 12, g_current_pos_y + 34) then
            Module.GameLogic.kill();
        end

        if Module.GameLogic.is_player_colliding_with_rect(
                g_current_pos_x - 10, g_current_pos_y + 0,
                g_current_pos_x + 10, g_current_pos_y + 23) then
            Module.GameLogic.kill();
        end
    end

    if g_current_state == kMOVING_RIGHT or g_current_state == kYELLING_RIGHT then
        if Module.GameLogic.is_player_colliding_with_rect(
                g_current_pos_x + 12, g_current_pos_y + 28,
                g_current_pos_x + 22, g_current_pos_y + 34) then
            Module.GameLogic.kill();
        end

        if Module.GameLogic.is_player_colliding_with_rect(
                g_current_pos_x - 10, g_current_pos_y + 0,
                g_current_pos_x + 10, g_current_pos_y + 23) then
            Module.GameLogic.kill();
        end
    end
end

return Module;
