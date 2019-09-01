local read_only = require "Data/read_only";
local bullet_module = loadfile("Data/bullet.lua");

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
player_state = read_only.make_table_read_only(player_state);

-- TODO: Move this into a shared file, split into separate tables by type
local camera_mode = {
    PerspectiveNormal = 0,
    PerspectiveCloseUp = 1,
    PerspectiveFar = 2,
    PerspectiveWide = 3,
    PerspectiveFollow = 4,
    PerspectiveFixed = 5,
}
camera_mode = read_only.make_table_read_only(camera_mode);

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    ScriptGoo = 0,
    TextureJumpman = 0,
    TextureInvisible = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureCrazySky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    TextureStone = 5,
    TextureClassicPlatform = 6,
    ScriptBullet = 1,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    TextureBullet = 7,
}
resources = read_only.make_table_read_only(resources);

local g_is_initialized = false;
local g_bullets = {};

local g_visibility_bitmask;
local g_visibility_change_frames_left = 0;
local g_background_rotation = 0;

function update()
    if not g_is_initialized then
        g_is_initialized = true;

        local iTemp = bullet_module();
        iTemp.FramesToWait = 300;
        iTemp.Mesh1Index = resources.MeshBullet1;
        iTemp.Mesh2Index = resources.MeshBullet2;
        iTemp.TextureIndex = resources.TextureBullet;
        iTemp.FireSoundIndex = resources.SoundFire;
        table.insert(g_bullets, iTemp);

        SetConfig();
        g_visibility_bitmask = 1;  -- Guarantee on first start that donuts are invisible
        ResetVisible(g_visibility_bitmask);
    end

    if g_visibility_change_frames_left > 0 then
        g_visibility_change_frames_left = g_visibility_change_frames_left - 1;

        if rnd(1, 30) < g_visibility_change_frames_left then
            ResetVisible(g_visibility_bitmask);
        else
            local iTemp = NextNum(g_visibility_bitmask);
            ResetVisible(iTemp);
        end

        if g_visibility_change_frames_left == 0 then
            g_visibility_bitmask = NextNum(g_visibility_bitmask);
            ResetVisible(g_visibility_bitmask);
        end
    end

    RotateBack();

    for _, bullet in ipairs(g_bullets) do
        bullet.update();
    end
end

function RotateBack()
    g_background_rotation = g_background_rotation - 0.5;

    for iPic = 200, 203 do
        select_picture(iPic);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_translate_matrix(-80, -40, 0);
        script_selected_mesh_scale_matrix(1.1, 1.1, 1);
        script_selected_mesh_rotate_matrix_z(g_background_rotation);
        script_selected_mesh_translate_matrix(80, 40, 0);
    end
end

function SetConfig()
    for iLoop = 256, 264, 2 do
        local iRnd = rnd(0, 1000) < 500;

        if iRnd then
            select_platform(iLoop + 1);
            set_script_selected_level_object_number(iLoop - 251);
            select_platform(iLoop);
        else
            select_platform(iLoop);
            set_script_selected_level_object_number(iLoop - 247);
            select_platform(iLoop + 1);
        end

        set_script_selected_level_object_y1(500);
        set_script_selected_level_object_y2(500);
        script_selected_mesh_translate_matrix(0, 0, 2000);
    end
end

function ResetVisible(visibility_bitmask)
    for iObj = 0, get_platform_object_count() - 1 do
        abs_platform(iObj);
        local iPlat = get_script_selected_level_object_number();

        if (iPlat & visibility_bitmask) ~= 0 then
            set_object_visual_data(resources.TextureClassicPlatform, 1);
        else
            set_object_visual_data(resources.TextureInvisible, 1);
        end
    end

    for iObj = 0, get_ladder_object_count() - 1 do
        abs_ladder(iObj);
        local iPlat = get_script_selected_level_object_number();

        if (iPlat & visibility_bitmask) ~= 0 then
            set_object_visual_data(resources.TextureBlueMarble, 1);
        else
            set_object_visual_data(resources.TextureInvisible, 1);
        end
    end

    for iObj = 0, get_vine_object_count() - 1 do
        abs_vine(iObj);
        local iPlat = get_script_selected_level_object_number();

        if (iPlat & visibility_bitmask) ~= 0 then
            set_object_visual_data(resources.TextureBlueMarble, 1);
        else
            set_object_visual_data(resources.TextureInvisible, 1);
        end
    end

    for iObj = 0, get_donut_object_count() - 1 do
        abs_donut(iObj);
        local iPlat = get_script_selected_level_object_number();

        if visibility_bitmask == 1 then
            set_object_visual_data(resources.TextureInvisible, get_script_selected_level_object_visible() and 1 or 0);
        else
            set_object_visual_data(resources.TextureRedMetal, get_script_selected_level_object_visible() and 1 or 0);
        end
    end
end

function NextNum(iMove)
    if iMove == 255 then
        -- Original code set g_visibility_bitmask = 1 here, like is currently being done
        -- This guarantees the donuts always flash after a death on first donut grab, but I *think* they will never disappear after that flash?
        -- Otherwise they only blink every 6th donut grab without dying (and *can* disappear at that time)

        -- TODO: Maybe they should have a chance of disppearing on first grab after reset, or always disappear on reset?
        g_visibility_bitmask = 1;
    end

    iMove = iMove * 2;

    if iMove == 64 then
        iMove = 1;
    end

    return iMove;
end

function on_collect_donut()
    g_visibility_change_frames_left = 30;
end

function reset()
    g_visibility_bitmask = 255;
    ResetVisible(g_visibility_bitmask);
    set_player_current_position_x(68);
    set_player_current_position_y(81);
    set_player_current_position_z(9);
    set_player_current_state(player_state.JSNORMAL);

    for _, bullet in ipairs(g_bullets) do
        bullet.reset_pos();
    end
end
