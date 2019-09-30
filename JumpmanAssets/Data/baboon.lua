local read_only = require "Data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.StartX = 0;
Module.StartY = 0;

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureJumpman = 0,
    TextureWoodPlatform = 1,
    TextureYellowRope = 2,
    TextureRedMetal = 3,
    Texturesky = 4,
    SoundJump = 0,
    Soundchomp = 1,
    Soundbonk = 2,
    SoundFire = 3,
    MeshBaboon = 0,
    MeshBaboon1 = 1,
    MeshBaboon2 = 2,
    MeshBaboon3 = 3,
    MeshBaboon4 = 4,
    TextureBaboon = 5,
    TextureBark = 6,
    ScriptBaboon = 0,
    MeshHang = 5,
    MeshHang1 = 6,
    MeshHang2 = 7,
    MeshHang3 = 8,
    MeshHang4 = 9,
    MeshHangL1 = 10,
    MeshHangL2 = 11,
    MeshHangL3 = 12,
    MeshHangL4 = 13,
    TextureHangVine = 7,
};
resources = read_only.make_table_read_only(resources);

local g_is_initialized = false;
local g_climb_animation_mesh_indices = {};
local g_climb_animation_current_mesh_index;
local g_climb_animation_frame_index = 0;
local g_climb_animation_meta_frame_index = 0;

local g_current_pos_x;
local g_current_pos_y;
local g_current_pos_z;
local g_current_velocity_y;

local function MoveBaboon()
    -- TODO: A more clear way to write this frame selection code, if possible
    g_climb_animation_frame_index = g_climb_animation_frame_index + 1;

    if g_climb_animation_frame_index > 3 then
        g_climb_animation_meta_frame_index = g_climb_animation_meta_frame_index + 4;
        g_climb_animation_frame_index = 0;
    end

    if (g_climb_animation_meta_frame_index & 28) == 0 then
        g_climb_animation_current_mesh_index = 1;
    elseif (g_climb_animation_meta_frame_index & 28) == 4 or (g_climb_animation_meta_frame_index & 28) == 28 then
        g_climb_animation_current_mesh_index = 2;
    elseif (g_climb_animation_meta_frame_index & 28) == 8 or (g_climb_animation_meta_frame_index & 28) == 24 then
        g_climb_animation_current_mesh_index = 3;
    elseif (g_climb_animation_meta_frame_index & 28) == 12 or (g_climb_animation_meta_frame_index & 28) == 20 then
        g_climb_animation_current_mesh_index = 4;
    elseif (g_climb_animation_meta_frame_index & 28) == 16 then
        g_climb_animation_current_mesh_index = 5;
    end

    local iOldY = g_current_pos_y;
    g_current_pos_y = g_current_pos_y + g_current_velocity_y;

    find_vine(g_current_pos_x + 3, g_current_pos_y);
    local iVin = get_script_event_data_4();

    if iVin < 0 then
        g_current_pos_y = iOldY;
        g_current_velocity_y = g_current_velocity_y * -1;
    else
        abs_vine(iVin);

        if g_current_pos_y < get_script_selected_level_object_y2() + 3 then
            g_current_pos_y = iOldY;
            g_current_velocity_y = g_current_velocity_y * -1;
        end

        if g_current_pos_y > get_script_selected_level_object_y1() - 7 then
            g_current_pos_y = iOldY;
            g_current_velocity_y = g_current_velocity_y * -1;
        end
    end
end

function Module.update()
    if not g_is_initialized then
        g_is_initialized = true;
        g_climb_animation_mesh_indices[1] = new_mesh(resources.MeshBaboon4);
        g_climb_animation_mesh_indices[2] = new_mesh(resources.MeshBaboon);
        g_climb_animation_mesh_indices[3] = new_mesh(resources.MeshBaboon2);
        g_climb_animation_mesh_indices[4] = new_mesh(resources.MeshBaboon1);
        g_climb_animation_mesh_indices[5] = new_mesh(resources.MeshBaboon3);
        g_current_pos_x = Module.StartX;
        g_current_pos_y = Module.StartY;
        g_current_pos_z = 0;
        g_current_velocity_y = -0.5;
        g_climb_animation_current_mesh_index = 1;
    end

    select_object_mesh(g_climb_animation_mesh_indices[g_climb_animation_current_mesh_index]);
    set_object_visual_data(0, 0);

    MoveBaboon();

    select_object_mesh(g_climb_animation_mesh_indices[g_climb_animation_current_mesh_index]);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(g_current_pos_x, g_current_pos_y + 6, g_current_pos_z);
    set_object_visual_data(resources.TextureBaboon, 1);

    if Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 2, g_current_pos_y + 2,
            g_current_pos_x + 2, g_current_pos_y + 10) then
        kill();
    end
end

return Module;
