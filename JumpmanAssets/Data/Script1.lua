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
    TextureClassicPlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureBullet = 4,
    TextureSky = 5,
    ScriptBullet = 0,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
}
resources = make_read_only(resources);

-- TODO: Separate file?
local bullet_properties = {
    BulletIFiring = 0,
    BulletResMesh1 = 1,
    BulletResMesh2 = 2,
    BulletResTexture = 3,
    BulletIInit = 4,
    BulletIX = 5,
    BulletIY = 6,
    BulletIZ = 7,
    BulletIXV = 8,
    BulletIYV = 9,
    BulletIMesh1 = 10,
    BulletIMesh2 = 11,
    BulletISlow = 12,
    BulletIOut = 13,
    BulletISpin1 = 14,
    BulletISpin2 = 15,
    BulletWait = 16,
    BulletIMaxx = 17,
}
bullet_properties = make_read_only(bullet_properties);

local g_is_initialized = false;

local g_is_object_1_moving = false;
local g_object_1_animation_frame = 0;

local g_is_object_2_moving = false;
local g_object_2_animation_frame = 0;

local g_is_object_3_moving = false;
local g_object_3_animation_frame = 0;

local g_is_object_4_moving = false;
local g_object_4_animation_frame = 0;

function update()
    if not g_is_initialized then
        g_is_initialized = true;

        local iTemp = spawn_object(resources.ScriptBullet);
        set_object_global_data(iTemp, bullet_properties.BulletWait, 100);
        set_object_global_data(iTemp, bullet_properties.BulletResMesh1, resources.MeshBullet1);
        set_object_global_data(iTemp, bullet_properties.BulletResMesh2, resources.MeshBullet2);
        set_object_global_data(iTemp, bullet_properties.BulletResTexture, resources.TextureBullet);

        iTemp = spawn_object(resources.ScriptBullet);
        set_object_global_data(iTemp, bullet_properties.BulletWait, 30);
        set_object_global_data(iTemp, bullet_properties.BulletResMesh1, resources.MeshBullet1);
        set_object_global_data(iTemp, bullet_properties.BulletResMesh2, resources.MeshBullet2);
        set_object_global_data(iTemp, bullet_properties.BulletResTexture, resources.TextureBullet);
    end

    if g_is_object_1_moving then
        g_object_1_animation_frame = g_object_1_animation_frame + 3;

        MovePlatform(1, 0 - g_object_1_animation_frame, 1, get_script_selected_level_object_x1, get_script_selected_level_object_y1);
        MovePlatform(2, g_object_1_animation_frame, 0 - 1, get_script_selected_level_object_x2, get_script_selected_level_object_y2);
        -- TODO: This doesn't seem to do anything in the code, at least not for #compose
        --       Seems maybe should delete the line?
        -- setext(#compose, 1);

        if g_object_1_animation_frame > 56 then
            g_is_object_1_moving = false;

            select_platform(1);
            set_script_selected_level_object_y1(500);
            set_script_selected_level_object_y2(500);

            select_platform(2);
            set_script_selected_level_object_y1(500);
            set_script_selected_level_object_y2(500);
        end
    end

    if g_is_object_2_moving then
        g_object_2_animation_frame = g_object_2_animation_frame + 3;

        MovePlatform(3, 0 - g_object_2_animation_frame, 1, get_script_selected_level_object_x1, get_script_selected_level_object_y1);
        MovePlatform(4, g_object_2_animation_frame, 0 - 1, get_script_selected_level_object_x2, get_script_selected_level_object_y2);
        -- TODO: This doesn't seem to do anything in the code, at least not for #compose
        --       Seems maybe should delete the line?
        -- setext(#compose, 1);

        if g_object_2_animation_frame > 56 then
            g_object_2_animation_frame = 56;
            g_is_object_2_moving = false;

            select_platform(3);
            set_script_selected_level_object_y1(500);
            set_script_selected_level_object_y2(500);

            select_platform(4);
            set_script_selected_level_object_y1(500);
            set_script_selected_level_object_y2(500);
        end
    end

    if g_is_object_3_moving then
        g_object_3_animation_frame = g_object_3_animation_frame + 1;

        MoveLadder(1, g_object_3_animation_frame);
        -- TODO: This doesn't seem to do anything in the code, at least not for #compose
        --       Seems maybe should delete the line?
        -- setext(#compose, 1);

        if g_object_3_animation_frame == 80 then
            g_is_object_3_moving = false;
            select_ladder(1);
            script_selected_mesh_translate_matrix(1000, 0, 0);
        end
    end

    if g_is_object_4_moving then
        g_object_4_animation_frame = g_object_4_animation_frame + 1;

        MoveLadder(2, g_object_4_animation_frame);
        -- TODO: This doesn't seem to do anything in the code, at least not for #compose
        --       Seems maybe should delete the line?
        -- setext(#compose, 1);

        if g_object_4_animation_frame == 80 then
            g_is_object_4_moving = false;
            select_ladder(2);
            script_selected_mesh_translate_matrix(1000, 0, 0);
        end
    end
end

function MoveLadder(iLadder, iPos)
    select_ladder(iLadder);
    local iX = get_script_selected_level_object_x1() + 508;
    local iY = (get_script_selected_level_object_y1() + get_script_selected_level_object_y2()) / 2;
    local iZ = get_script_selected_level_object_z1();

    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(0 - iX, 0 - iY, 0 - iZ);
    script_selected_mesh_rotate_matrix_z(iPos * 2);
    script_selected_mesh_rotate_matrix_x(iPos);
    script_selected_mesh_translate_matrix(iX, iY, iZ - iPos);
end

function MovePlatform(iPlat, iRotate, iTran, get_platform_x_value, get_platform_y_value)
    select_platform(iPlat);
    local iPlatX = get_platform_x_value();
    local iPlatY = get_platform_y_value();
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(0 - iPlatX, 0 - iPlatY, 0);
    script_selected_mesh_rotate_matrix_z(iRotate);
    script_selected_mesh_translate_matrix(iPlatX + iTran, iPlatY, 0);
end

function on_collect_donut()
    local iDonut = get_script_event_data_1();

    if iDonut == 1 then
        g_is_object_1_moving = true;
        iPosition1 = 0;
    end

    if iDonut == 2 then
        g_is_object_2_moving = true;
        iPosition2 = 0;
    end

    if iDonut == 3 then
        g_is_object_3_moving = true;
        iPosition3 = 0;
        select_ladder(1);
        local iX = get_script_selected_level_object_x1();
        set_script_selected_level_object_x1(iX - 500);
    end

    if iDonut == 4 then
        g_is_object_4_moving = true;
        iPosition4 = 0;
        select_ladder(2);
        local iX = get_script_selected_level_object_x1();
        set_script_selected_level_object_x1(iX - 500);
    end
end

function reset()
    set_player_current_position_x(80);
    set_player_current_position_y(65);
    set_player_current_position_z(9);
    set_player_current_state(player_state.JSNORMAL);
end