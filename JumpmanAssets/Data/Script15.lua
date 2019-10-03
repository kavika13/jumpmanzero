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

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_disappearing_platforms = {};
local iBlow = 0;

local function InitPlatforms_()
    local iPlat = 0;

    for iPlat = 0, get_platform_object_count() - 1 do
        abs_platform(iPlat);

        if get_script_selected_level_object_number() ~= 0 then
            local new_disappearing_platform = disappearing_platform_module();
            new_disappearing_platform.GameLogic = g_game_logic;
            new_disappearing_platform.ObjectIndex = iPlat;
            new_disappearing_platform.GoodColorTextureResourceIndex = resources.TextureYellowPlatform;
            new_disappearing_platform.BadColorTextureResourceIndex = resources.TextureRedPlatform;
            new_disappearing_platform.initialize();
            table.insert(g_disappearing_platforms, new_disappearing_platform);
        end
    end
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    select_picture(5);  -- TODO: This is the waterfall backdrop. Use a constant, or get from resources
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(0, 0, 10);
    script_selected_mesh_scroll_texture(0, -0.15);

    for _, plat in ipairs(g_disappearing_platforms) do
        plat.update();
    end
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.ResetPlayerCallback = reset;
    g_hud_overlay = hud_overlay_module();
    set_level_extent_x(180);
    InitPlatforms_();

    reset();

    -- Make sure staged initialization has happened, and Jumpman has floated to the floor
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
end

function update(game_input)
    if not g_title_is_done_scrolling then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return;
    end

    ProgressLevel_(game_input);
end

function reset()
    set_player_current_position_x(8);
    set_player_current_position_y(7);
    set_player_current_position_z(3);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end
