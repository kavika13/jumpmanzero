local read_only = require "Data/read_only";
local level_level15_module = assert(loadfile("Data/level_level15.lua"));
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

    local backdrop_mesh_index = g_game_logic.find_backdrop_by_number(5).mesh_index;  -- TODO: Use constant for num
    set_identity_mesh_matrix(backdrop_mesh_index);
    translate_mesh_matrix(backdrop_mesh_index, 0, 0, 10);
    scroll_texture_on_mesh(backdrop_mesh_index, 0, -0.15);

    for _, plat in ipairs(g_disappearing_platforms) do
        plat.update();
    end

    g_game_logic.update_player_graphics();
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.LevelData = level_level15_module();
    g_game_logic.ResetPlayerCallback = reset;
    g_game_logic.set_level_extent_x(180);
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.GameLogic = g_game_logic;

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
    g_game_logic.set_player_current_position_x(8);
    g_game_logic.set_player_current_position_y(7);
    g_game_logic.set_player_current_position_z(3);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end
