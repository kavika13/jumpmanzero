local read_only = require "Data/read_only";
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local bullet_module = assert(loadfile("Data/bullet.lua"));
local chain_module = assert(loadfile("Data/chain.lua"));

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
    TexturePrisoner = 0,
    TextureTileStone = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    MeshChain = 0,
    TextureChain = 5,
    TextureLitFountain = 6,
    ScriptBullet = 0,
    ScriptChain = 1,
    MeshBullet1 = 1,
    MeshBullet2 = 2,
    TextureBullet = 7,
};
resources = read_only.make_table_read_only(resources);

local g_init_stage_index = 0;
local g_is_first_update_complete = false;
local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_bullets = {};

local g_chain;
local g_chain_length;
local g_target_length;

function update(game_input, is_initializing)
    if g_init_stage_index == 1 then
        for iLoop = 1, 4 do
            local iTemp = bullet_module();
            iTemp.GameLogic = g_game_logic;
            iTemp.Mesh1Index = resources.MeshBullet1;
            iTemp.Mesh2Index = resources.MeshBullet2;
            iTemp.TextureIndex = resources.TextureBullet;
            iTemp.FireSoundIndex = resources.SoundFire;
            table.insert(g_bullets, iTemp);
        end

        g_init_stage_index = 2;

        select_picture(1);
        prioritize_object();

        select_picture(100);
        prioritize_object();
    end

    if g_init_stage_index == 0 then
        g_init_stage_index = 1;
        g_chain_length = 10;
        g_target_length = 20;

        g_game_logic = game_logic_module();
        g_game_logic.ResetPlayerCallback = reset;
        g_game_logic.OnCollectDonutCallback = on_collect_donut;

        g_hud_overlay = hud_overlay_module();

        g_chain = chain_module();
        g_chain.GameLogic = g_game_logic;
        g_chain.LinkMeshResourceIndex = resources.MeshChain;
        g_chain.LinkTextureResourceIndex = resources.TextureChain;
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

    SetChainLength();

    g_chain.update();

    for _, bullet in ipairs(g_bullets) do
        bullet.update();
    end

    if not g_is_first_update_complete then
        if g_init_stage_index > 1 then
            g_is_first_update_complete = true;
        end

        return false;
    end

    return true;
end

function SetChainLength()
    if g_chain_length < g_target_length then
        g_chain_length = g_chain_length + 1;
    end

    g_chain.ChainLength = g_chain_length;
end

function on_collect_donut(game_input, iDonut)
    g_target_length = g_target_length + iDonut;
end

function reset()
    set_player_current_position_x(70);
    set_player_current_position_y(62);
    set_player_current_position_z(2);
    set_player_current_state(player_state.JSNORMAL);

    for _, bullet in ipairs(g_bullets) do
        bullet.reset_pos();
    end
end
