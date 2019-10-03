local read_only = require "Data/read_only";
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
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
};
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
};
resources = read_only.make_table_read_only(resources);

local g_is_initialized = false;
local g_is_first_update_complete = false;
local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_disappearing_platforms = {};
local iBlow = 0;

function update(game_input, is_initializing)
    if not g_is_initialized then
        g_is_initialized = true;
        g_game_logic = game_logic_module();
        g_game_logic.ResetPlayerCallback = reset;
        g_hud_overlay = hud_overlay_module();
        set_level_extent_x(180);
        InitPlatforms();
    end

    -- TODO: Can probably make a parent meta script that calls into this and into hud_overlay.
    --       That should simplify this logic drastically.
    --       Probably best to do that with the level loader refactor?
    if is_initializing or g_title_is_done_scrolling then
        local continue_update = g_game_logic.progress_game(game_input);
        g_hud_overlay.update(game_input);

        if not continue_update then
            return true;
        end
    elseif g_is_first_update_complete then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return false;
    end

    select_picture(5);  -- TODO: This is the waterfall backdrop. Use a constant, or get from resources
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(0, 0, 10);
    script_selected_mesh_scroll_texture(0, -0.15);

    for _, plat in ipairs(g_disappearing_platforms) do
        plat.update();
    end

    if not g_is_first_update_complete then
        g_is_first_update_complete = true;
        return false;
    end

    return true;
end

function InitPlatforms()
    local iPlat = 0;

    for iPlat = 0, get_platform_object_count() - 1 do
        abs_platform(iPlat);

        if get_script_selected_level_object_number() ~= 0 then
            local iNew = disappearing_platform_module();
            iNew.GameLogic = g_game_logic;
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
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end
