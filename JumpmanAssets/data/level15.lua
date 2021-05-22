local read_only = require "data/read_only";
local level15_data_module = assert(loadfile("data/level15_data.lua"));
local game_logic_module = assert(loadfile("data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("data/hud_overlay.lua"));
local disappearing_platform_module = assert(loadfile("data/disappearing_platform.lua"));

local Module = {};

Module.MenuLogic = nil;

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

local kWATERFALL_ANIMATION_FRAME_STEP = -0.15;

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;

local g_waterfall_backdrop_mesh_index = -1;
local g_disappearing_platforms = {};
local iBlow = 0;  -- TODO: Add changing blowing horizontal wind effect to this level? Might be cool... This variable name sucks tho lol

local function InitPlatforms_()
    for platform_index = 0, g_game_logic.get_platform_object_count() - 1 do
        if g_game_logic.get_platform(platform_index).number ~= 0 then
            local new_disappearing_platform = disappearing_platform_module();
            new_disappearing_platform.GameLogic = g_game_logic;
            new_disappearing_platform.PlatformIndex = platform_index;
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

    scroll_texture_on_mesh(g_waterfall_backdrop_mesh_index, 0, kWATERFALL_ANIMATION_FRAME_STEP);

    for _, plat in ipairs(g_disappearing_platforms) do
        plat.update();
    end

    g_game_logic.update_player_graphics();
end

function Module.initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = level15_data_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.set_level_extent_x(180);
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.MenuLogic = Module.MenuLogic;
    g_hud_overlay.GameLogic = g_game_logic;

    InitPlatforms_();

    g_waterfall_backdrop_mesh_index = g_game_logic.find_backdrop_by_number(5).mesh_index;  -- TODO: Use constant for num

    Module.reset();

    -- Make sure staged initialization has happened, and Jumpman has floated to the floor
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
end

function Module.update(game_input)
    if not g_title_is_done_scrolling then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return;
    end

    ProgressLevel_(game_input);
end

function Module.reset()
    g_game_logic.set_player_current_position_x(8);
    g_game_logic.set_player_current_position_y(7);
    g_game_logic.set_player_current_position_z(3);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end

return Module;
