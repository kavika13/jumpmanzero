local read_only = require "data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.LeftStandMeshResourceIndex = 0;
Module.RightStandMeshResourceIndex = 0;
Module.LeftWalkMeshResourceIndices = {};
Module.RightWalkMeshResourceIndices = {};
Module.TextureResourceIndex = 0;

local animation_frame = {
    WALK_LEFT_1 = 0,
    WALK_LEFT_2 = 1,
    WALK_LEFT_3 = 2,
    WALK_LEFT_4 = 3,
    WALK_RIGHT_1 = 10,
    WALK_RIGHT_2 = 11,
    WALK_RIGHT_3 = 12,
    WALK_RIGHT_4 = 13,
    META_WALK_ANIM_COUNT = 4,  -- Not an actual animation frame
};
animation_frame = read_only.make_table_read_only(animation_frame);

local kMOVING_LEFT = 3;
local kMOVING_RIGHT = 4;

local g_dino_mesh_index = nil;
local g_dino_transform_index = -1;
local g_animation_mesh_indices = {};
local g_animation_current_frame;

local g_current_pos_x;
local g_current_pos_y;
local g_current_rotation_z;

local g_current_state;
local g_frames_since_state_change;
local g_current_state_animation_frame = 0;
local g_current_state_animation_counter = 0;

local function SetAngle_()
    local iHit1, _ = Module.GameLogic.find_platform(g_current_pos_x - 7, g_current_pos_y, 7, 2);
    iHit1 = (iHit1 / 256) * 256;

    local iHit2, _ = Module.GameLogic.find_platform(g_current_pos_x + 7, g_current_pos_y, 7, 2);
    iHit2 = (iHit2 / 256) * 256;

    g_current_rotation_z = math.atan(iHit2 - iHit1, 14) * 180.0 / math.pi;
end

local function Move_()
    if g_current_state == kMOVING_LEFT or g_current_state == kMOVING_RIGHT then
        local iHit, iPlat = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y, 5, 2);

        if iHit < g_current_pos_y - 1 then
            g_current_pos_y = g_current_pos_y - 1;
        elseif iHit > g_current_pos_y + 1 then
            g_current_pos_y = g_current_pos_y + 1;
        else
            g_current_pos_y = iHit;
        end
    end

    if g_current_state == kMOVING_LEFT then
        g_current_pos_x = g_current_pos_x - 0.5;

        if g_current_pos_x < 10 then
            g_current_state = kMOVING_RIGHT;
            g_frames_since_state_change = 0;
        end
    end

    if g_current_state == kMOVING_RIGHT then
        g_current_pos_x = g_current_pos_x + 0.5;

        if g_current_pos_x > 150 then
            g_current_state = kMOVING_LEFT;
            g_frames_since_state_change = 0;
        end
    end
end

local function SetFrame_()
    g_frames_since_state_change = g_frames_since_state_change + 1;

    if g_current_state == kMOVING_LEFT then
        g_animation_current_frame = animation_frame.WALK_RIGHT_1 + g_current_state_animation_frame;
    end

    if g_current_state == kMOVING_RIGHT then
        g_animation_current_frame = animation_frame.WALK_LEFT_1 + g_current_state_animation_frame;
    end
end

local function Animate_()
    g_current_state_animation_counter = g_current_state_animation_counter + 1;

    if g_current_state_animation_counter > 3 then
        g_current_state_animation_counter = 0;
        g_current_state_animation_frame = g_current_state_animation_frame + 1;

        if g_current_state_animation_frame == animation_frame.META_WALK_ANIM_COUNT then
            g_current_state_animation_frame = 0;
        end
    end
end

function Module.initialize()
    g_current_pos_x = 140;
    g_current_pos_y = 65;
    g_current_rotation_z = 0;
    g_current_state = kMOVING_LEFT;
    g_frames_since_state_change = 0;

    g_animation_mesh_indices[animation_frame.WALK_LEFT_1] = Module.RightWalkMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.WALK_LEFT_2] = Module.RightStandMeshResourceIndex;
    g_animation_mesh_indices[animation_frame.WALK_LEFT_3] = Module.RightWalkMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.WALK_LEFT_4] = Module.RightStandMeshResourceIndex;

    g_animation_mesh_indices[animation_frame.WALK_RIGHT_1] = Module.LeftWalkMeshResourceIndices[1];
    g_animation_mesh_indices[animation_frame.WALK_RIGHT_2] = Module.LeftStandMeshResourceIndex;
    g_animation_mesh_indices[animation_frame.WALK_RIGHT_3] = Module.LeftWalkMeshResourceIndices[2];
    g_animation_mesh_indices[animation_frame.WALK_RIGHT_4] = Module.LeftStandMeshResourceIndex;

    g_dino_mesh_index = new_mesh(g_animation_mesh_indices[animation_frame.WALK_LEFT_1]);
    g_dino_transform_index = transform_create();
    mesh_set_transform(g_dino_mesh_index, g_dino_transform_index);
    set_mesh_texture(g_dino_mesh_index, Module.TextureResourceIndex);
    set_mesh_is_visible(g_dino_mesh_index, true);

    g_animation_current_frame = animation_frame.WALK_LEFT_1;
end

function Module.update()
    Animate_();
    SetFrame_();
    Move_();
    SetAngle_();

    set_mesh_to_mesh(g_dino_mesh_index, g_animation_mesh_indices[g_animation_current_frame]);
    transform_set_rotation_z(g_dino_transform_index, g_current_rotation_z);
    transform_set_scale(g_dino_transform_index, 1.5, 1.5, 1.5);
    transform_set_translation(g_dino_transform_index, g_current_pos_x, g_current_pos_y + 13, 9);

    if g_current_state == kMOVING_LEFT then
        if Module.GameLogic.is_player_colliding_with_rect(
                g_current_pos_x - 14, g_current_pos_y + 4,
                g_current_pos_x + 10, g_current_pos_y + 16) then
            Module.GameLogic.kill();
        end
    end

    if g_current_state == kMOVING_RIGHT then
        if Module.GameLogic.is_player_colliding_with_rect(
                g_current_pos_x - 10, g_current_pos_y + 4,
                g_current_pos_x + 14, g_current_pos_y + 16) then
            Module.GameLogic.kill();
        end
    end
end

return Module;
