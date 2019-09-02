local read_only = require "Data/read_only";
local disappearing_platform_module = assert(loadfile("Data/disappearing_platform.lua"));

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

local is_initialized = false;
local g_disappearing_platforms = {};
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

    for _, plat in ipairs(g_disappearing_platforms) do
        plat.update();
    end
end

function InitPlatforms()
    local iPlat = 0;

    for iPlat = 0, get_platform_object_count() - 1 do
        abs_platform(iPlat);

        if get_script_selected_level_object_number() ~= 0 then
            local iNew = disappearing_platform_module();
            iNew.ObjectIndex = iPlat;
            iNew.GoodColorTextureResourceIndex = resources.TextureYellowPlatform;
            iNew.BadColorTextureResourceIndex = resources.TextureRedPlatform;
            table.insert(g_disappearing_platforms, iNew);
        end
    end
end

function reset()
    set_player_current_position_x(8);
    set_player_current_position_y(7);
    set_player_current_position_z(3);
    set_player_current_state(player_state.JSNORMAL);
end
