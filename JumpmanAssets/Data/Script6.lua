-- TODO: Move this into a shared file, and check for other/better impls,
--       in case there are any (haven't looked)
function make_read_only(tbl)
    return setmetatable({}, {
        __index = tbl,
        __newindex = function(t, key, value)
            error("attempting to change constant " ..
                   tostring(key) .. " to " .. tostring(value), 2)
        end
    });
end

-- TODO: Move this into a shared file, split into separate tables by type
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
}
player_state = make_read_only(player_state);

-- TODO: Move this into a shared file, split into separate tables by type
local camera_mode = {
    PerspectiveNormal = 0,
    PerspectiveCloseUp = 1,
    PerspectiveFar = 2,
    PerspectiveWide = 3,
    PerspectiveFollow = 4,
    PerspectiveFixed = 5,
}
camera_mode = make_read_only(camera_mode);

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureJumpman = 0,
    TextureDarkWoodPlatform = 1,
    TextureYellowRope = 2,
    TextureRedMetal = 3,
    TextureBlack = 4,
    TextureDark = 5,
    ScriptGhost = 0,
    TextureRing = 6,
    TextureRing2 = 7,
    TextureWoodLadder = 8,
    MeshGhostLeft = 0,
    MeshGhostRight = 1,
    MeshGhostLeft2 = 2,
    MeshGhostRight2 = 3,
    TextureConcrete = 9,
    TextureGhostTexture = 10,
    TexturePillar = 11,
    SoundJump = 0,
    SoundCreak = 1,
    SoundBonk = 2,
    TexturePainting = 12,
    TexturePainting2 = 13,
}
resources = make_read_only(resources);

local g_is_initialized = false;
local g_is_wall_moving = false;
local g_wall_animation_frame = 0;
local g_spotlight_animation_frame = 0;
local g_painting_with_eyes_animation_frame = 0;

function update()
    if not g_is_initialized then
        g_is_initialized = true;
        set_current_camera_mode(camera_mode.PerspectiveCloseUp);
        spawn_object(resources.ScriptGhost);
    end

    if g_is_wall_moving then
        g_wall_animation_frame = g_wall_animation_frame + 1;
        select_wall(33);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_translate_matrix(0, 0, g_wall_animation_frame / 10);

        if g_wall_animation_frame == 45 then
            select_wall(33);
            set_script_selected_level_object_y1(0 - 26);
            g_wall_animation_frame = 0;
            g_is_wall_moving = false;
        end
    end

    local iPX = get_player_current_position_x() - 90;
    local iPY = get_player_current_position_y() - 70;

    g_spotlight_animation_frame = g_spotlight_animation_frame + 1;

    if g_spotlight_animation_frame == 6 then
        g_spotlight_animation_frame = 0;
    end

    select_picture(1);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(iPX, iPY, 0);

    if g_spotlight_animation_frame > 2 then
        set_script_selected_level_object_texture(resources.TextureRing2);
    else
        set_script_selected_level_object_texture(resources.TextureRing);
    end

    select_picture(2)
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(iPX, iPY, 0);

    select_picture(3);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(iPX, iPY, 0);

    select_picture(4);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(iPX, iPY, 0);

    select_picture(5);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(iPX, iPY, 0);

    g_painting_with_eyes_animation_frame = g_painting_with_eyes_animation_frame + 1;

    select_picture(100);
    set_object_visual_data(resources.TexturePainting, 1);

    if g_painting_with_eyes_animation_frame > 10 then
        set_object_visual_data(resources.TexturePainting2, 1);
    end

    if g_painting_with_eyes_animation_frame > 20 then
        g_painting_with_eyes_animation_frame = 0;
    end
end

function on_collect_donut()
    local iDonut = get_script_event_data_1();

    if iDonut == 1 then
        g_is_wall_moving = true;
        g_wall_animation_frame = 1;  -- TODO: Is this necessary to do here?
        select_vine(1);
        set_script_selected_level_object_y2(get_script_selected_level_object_y2() + 6);
        set_script_selected_level_object_y1(get_script_selected_level_object_y1() + 6);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_translate_matrix(0, 6, 0);
        -- TODO: This doesn't seem to do anything in the code, at least not for #compose
        --       Seems maybe should delete the line?
        -- setext(#compose, 1);
    end

    if iDonut == 2 then
        select_vine(2);
        set_script_selected_level_object_y2(get_script_selected_level_object_y2() + 8);
        set_script_selected_level_object_y1(get_script_selected_level_object_y1() + 8);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_translate_matrix(0, 8, 0);
        -- TODO: This doesn't seem to do anything in the code, at least not for #compose
        --       Seems maybe should delete the line?
        -- setext(#compose, 1);
    end

    if iDonut == 3 then
        select_wall(2);
        set_script_selected_level_object_y1(get_script_selected_level_object_y1() - 26);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_translate_matrix(0, 0 - 70, 0);

        select_picture(12);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_translate_matrix(0, 0 - 70, 0);
        -- TODO: This doesn't seem to do anything in the code, at least not for #compose
        --       Seems maybe should delete the line?
        -- setext(#compose, 1);
    end
end

function reset()
    set_player_current_position_x(96);
    set_player_current_position_y(73);
    set_player_current_position_z(9);
    set_player_current_state(player_state.JSNORMAL);
end