local read_only = require "Data/read_only";

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

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureJumpman = 0,
    TextureYellowPlatform = 1,
    TextureBoringGray = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    ScriptBullet = 0,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    TextureBullet = 5,
    ScriptZPlat = 1,
    TextureRedPlatform = 6,
    TextureFence = 7,
    TextureClassicPlatform = 8,
}
resources = read_only.make_table_read_only(resources);

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
    BulletIMaxX = 17,
}
bullet_properties = read_only.make_table_read_only(bullet_properties);

-- TODO: Separate file?
local z_plat_properties = {
    ZPlatICount = 0,
    ZPlatStatus = 1,
    ZPlatPlatform = 2,
    ZPlatBadColor = 3,
    ZPlatGoodColor = 4,
    ZPlatIMode = 5,
    ZPlatIPos = 6,
    ZPlatIOriginalZ = 7,
    ZPlatIInit = 8,
}
z_plat_properties = read_only.make_table_read_only(z_plat_properties);

local is_initialized = false;
local iBlow = 0;

function update()
    iBlow = iBlow - 0.6;

    if iBlow < 0 then
        iBlow = 110;
    end

    select_picture(5);  -- TODO: What is this constant, 5? How do we know it is this one? Hard-coded into the .lvl file?
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(0, iBlow, 10);

    if not is_initialized then
        is_initialized = true;
        set_level_extent_x(180);
        InitPlatforms();
    end
end

function InitPlatforms()
    local iPlat = 0;

    while iPlat < get_platform_object_count()
    do
        abs_platform(iPlat);

        if get_script_selected_level_object_number() ~= 0 then
            local iNew = spawn_object(resources.ScriptZPlat);
            set_object_global_data(iNew, z_plat_properties.ZPlatStatus, 1);
            set_object_global_data(iNew, z_plat_properties.ZPlatPlatform, iPlat);
            set_object_global_data(iNew, z_plat_properties.ZPlatGoodColor, resources.TextureYellowPlatform);
            set_object_global_data(iNew, z_plat_properties.ZPlatBadColor, resources.TextureRedPlatform);
        end

        iPlat = iPlat + 1;
    end
end

function reset()
    set_player_current_position_x(8);
    set_player_current_position_y(7);
    set_player_current_position_z(3);
    set_player_current_state(player_state.JSNORMAL);
end
