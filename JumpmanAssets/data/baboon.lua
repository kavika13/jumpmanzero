local read_only = require "data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.StartX = 0;
Module.StartY = 0;

-- TODO: Inject resource constants from level
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

local g_climb_animation_mesh_indices = {};
local g_climb_animation_current_mesh_index;
local g_climb_animation_frame_index = 0;
local g_climb_animation_meta_frame_index = 0;

local g_current_pos_x;
local g_current_pos_y;
local g_current_pos_z;
local g_current_velocity_y;

local function MoveBaboon_()
    -- TODO: A more clear way to write this frame selection code, if possible. Probably enums?
    g_climb_animation_frame_index = g_climb_animation_frame_index + 1;

    if g_climb_animation_frame_index > 3 then
        g_climb_animation_meta_frame_index = g_climb_animation_meta_frame_index + 4;
        g_climb_animation_frame_index = 0;
    end

    if (g_climb_animation_meta_frame_index & 28) == 0 then
        g_climb_animation_current_mesh_index = 1;  -- TODO: Use constants instead of these hard-coded frame numbers
    elseif (g_climb_animation_meta_frame_index & 28) == 4 or (g_climb_animation_meta_frame_index & 28) == 28 then
        g_climb_animation_current_mesh_index = 2;  -- TODO: Use constants instead of these hard-coded frame numbers
    elseif (g_climb_animation_meta_frame_index & 28) == 8 or (g_climb_animation_meta_frame_index & 28) == 24 then
        g_climb_animation_current_mesh_index = 3;  -- TODO: Use constants instead of these hard-coded frame numbers
    elseif (g_climb_animation_meta_frame_index & 28) == 12 or (g_climb_animation_meta_frame_index & 28) == 20 then
        g_climb_animation_current_mesh_index = 4;  -- TODO: Use constants instead of these hard-coded frame numbers
    elseif (g_climb_animation_meta_frame_index & 28) == 16 then
        g_climb_animation_current_mesh_index = 5;  -- TODO: Use constants instead of these hard-coded frame numbers
    end

    local iOldY = g_current_pos_y;
    g_current_pos_y = g_current_pos_y + g_current_velocity_y;

    local vine_index, _ = Module.GameLogic.find_vine(g_current_pos_x + 3, g_current_pos_y);

    if vine_index < 0 then
        g_current_pos_y = iOldY;
        g_current_velocity_y = g_current_velocity_y * -1;
    else
        local close_vine = Module.GameLogic.get_vine(vine_index);

        if g_current_pos_y < close_vine.pos_y_bottom + 3 then
            g_current_pos_y = iOldY;
            g_current_velocity_y = g_current_velocity_y * -1;
        end

        if g_current_pos_y > close_vine.pos_y_top - 7 then
            g_current_pos_y = iOldY;
            g_current_velocity_y = g_current_velocity_y * -1;
        end
    end
end

function Module.initialize()
    -- TODO: Use constants instead of these hard-coded frame numbers
    g_climb_animation_mesh_indices[1] = new_mesh(resources.MeshBaboon4);
    g_climb_animation_mesh_indices[2] = new_mesh(resources.MeshBaboon);
    g_climb_animation_mesh_indices[3] = new_mesh(resources.MeshBaboon2);
    g_climb_animation_mesh_indices[4] = new_mesh(resources.MeshBaboon1);
    g_climb_animation_mesh_indices[5] = new_mesh(resources.MeshBaboon3);

    for i = 1, 5 do  -- TODO: Use constants instead of these hard-coded frame numbers
        set_mesh_texture(g_climb_animation_mesh_indices[i], resources.TextureBaboon);
    end

    g_current_pos_x = Module.StartX;
    g_current_pos_y = Module.StartY;
    g_current_pos_z = 0;
    g_current_velocity_y = -0.5;
    g_climb_animation_current_mesh_index = 1;  -- TODO: Use constants instead of these hard-coded frame numbers
end

function Module.update()
    -- TODO: Animate through changemesh, instead of set_mesh_is_visible?
    set_mesh_is_visible(g_climb_animation_mesh_indices[g_climb_animation_current_mesh_index], false);

    MoveBaboon_();

    local anim_mesh_index = g_climb_animation_mesh_indices[g_climb_animation_current_mesh_index];
    set_identity_mesh_matrix(anim_mesh_index);
    translate_mesh_matrix(anim_mesh_index, g_current_pos_x, g_current_pos_y + 6, g_current_pos_z);
    set_mesh_is_visible(anim_mesh_index, true);

    if Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 2, g_current_pos_y + 2,
            g_current_pos_x + 2, g_current_pos_y + 10) then
        Module.GameLogic.kill();
    end
end

return Module;