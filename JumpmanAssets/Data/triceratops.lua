local Module = {};

Module.GameLogic = nil;

Module.LeftStandMeshResourceIndex = 0;
Module.RightStandMeshResourceIndex = 0;
Module.LeftWalkMeshResourceIndices = {};
Module.RightWalkMeshResourceIndices = {};
Module.TextureResourceIndex = 0;

local kMOVING_LEFT = 3;
local kMOVING_RIGHT = 4;

local g_is_initialized = false;

local g_animation_mesh_indices = {};
local g_animation_current_frame = 0;

local g_current_pos_x;
local g_current_pos_y;
local g_current_rotation_z;

local g_current_state;
local g_frames_since_state_change;
local g_current_state_animation_frame = 0;
local g_current_state_animation_counter = 0;

local function SetAngle()
    find_platform(g_current_pos_x - 7, g_current_pos_y, 7, 2);
    local iHit1 = get_script_event_data_4();
    iHit1 = (iHit1 / 256) * 256;

    find_platform(g_current_pos_x + 7, g_current_pos_y, 7, 2);
    local iHit2 = get_script_event_data_4();
    iHit2 = (iHit2 / 256) * 256;

    g_current_rotation_z = math.atan(iHit2 - iHit1, 14) * 180.0 / math.pi;
end

local function Move()
    if g_current_state == kMOVING_LEFT or g_current_state == kMOVING_RIGHT then
        local iPlat = find_platform(g_current_pos_x, g_current_pos_y, 5, 2);
        local iHit = get_script_event_data_4();

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

local function SetFrame()
    g_frames_since_state_change = g_frames_since_state_change + 1;

    if g_current_state == kMOVING_LEFT then
        g_animation_current_frame = 10 + g_current_state_animation_frame;
    end

    if g_current_state == kMOVING_RIGHT then
        g_animation_current_frame = 0 + g_current_state_animation_frame;
    end
end

local function Animate()
    g_current_state_animation_counter = g_current_state_animation_counter + 1;

    if g_current_state_animation_counter > 3 then
        g_current_state_animation_counter = 0;
        g_current_state_animation_frame = g_current_state_animation_frame + 1;

        if g_current_state_animation_frame == 4 then
            g_current_state_animation_frame = 0;
        end
    end
end

local function Initialize()
    g_is_initialized = true;

    g_current_pos_x = 140;
    g_current_pos_y = 65;
    g_current_rotation_z = 0;
    g_current_state = kMOVING_LEFT;
    g_frames_since_state_change = 0;

    g_animation_mesh_indices[0] = new_mesh(Module.RightWalkMeshResourceIndices[1]);
    g_animation_mesh_indices[1] = new_mesh(Module.RightStandMeshResourceIndex);
    g_animation_mesh_indices[2] = new_mesh(Module.RightWalkMeshResourceIndices[2]);
    g_animation_mesh_indices[3] = g_animation_mesh_indices[1];

    g_animation_mesh_indices[10] = new_mesh(Module.LeftWalkMeshResourceIndices[1]);
    g_animation_mesh_indices[11] = new_mesh(Module.LeftStandMeshResourceIndex);
    g_animation_mesh_indices[12] = new_mesh(Module.LeftWalkMeshResourceIndices[2]);
    g_animation_mesh_indices[13] = g_animation_mesh_indices[11];
end

function Module.update()
    if not g_is_initialized then
        Initialize();
    end

    select_object_mesh(g_animation_mesh_indices[g_animation_current_frame]);
    set_object_visual_data(0, 0);

    Animate();
    SetFrame();
    Move();
    SetAngle();

    select_object_mesh(g_animation_mesh_indices[g_animation_current_frame]);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_rotate_matrix_z(g_current_rotation_z);
    script_selected_mesh_scale_matrix(1.5, 1.5, 1.5);
    script_selected_mesh_translate_matrix(g_current_pos_x, g_current_pos_y + 13, 9);
    set_object_visual_data(Module.TextureResourceIndex, 2);

    if g_current_state == kMOVING_LEFT then
        if Module.GameLogic.is_player_colliding_with_rect(
                g_current_pos_x - 14, g_current_pos_y + 4,
                g_current_pos_x + 10, g_current_pos_y + 16) then
            kill();
        end
    end

    if g_current_state == kMOVING_RIGHT then
        if Module.GameLogic.is_player_colliding_with_rect(
                g_current_pos_x - 10, g_current_pos_y + 4,
                g_current_pos_x + 14, g_current_pos_y + 16) then
            kill();
        end
    end
end

return Module;
