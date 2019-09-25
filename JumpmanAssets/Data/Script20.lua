local read_only = require "Data/read_only";
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local follower_sheep_module = assert(loadfile("Data/follower_sheep.lua"));
local leader_sheep_module = assert(loadfile("Data/leader_sheep.lua"));

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
    TextureClassicPlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundGoat = 3,
    MeshCopter = 0,
    TextureSheep = 5,
    ScriptLSheep = 0,
    MeshSheepFL1 = 1,
    MeshSheepFL2 = 2,
    MeshSheepFL3 = 3,
    MeshSheepFR1 = 4,
    MeshSheepFR2 = 5,
    MeshSheepFR3 = 6,
    MeshSheepJL1 = 7,
    MeshSheepJL2 = 8,
    MeshSheepJL3 = 9,
    MeshSheepJR1 = 10,
    MeshSheepJR2 = 11,
    MeshSheepJR3 = 12,
    MeshSheepL1 = 13,
    MeshSheepL2 = 14,
    MeshSheepR1 = 15,
    MeshSheepR2 = 16,
    TextureBoringRed = 6,
    ScriptFSheep = 1,
    TextureLSheep = 7,
};
resources = read_only.make_table_read_only(resources);

local g_init_stage_index = 0;
local g_is_first_update_complete = false;

local g_hud_overlay;
local g_leader_sheep = nil;
local g_follower_sheep = {};

local g_delay = 0;

function SetResourceProperties_(sheep, sheep_texture)
    sheep.SheepMoveLeftMeshResourceIndices = { resources.MeshSheepL1, resources.MeshSheepL2 };
    sheep.SheepJumpLeftMeshResourceIndices = { resources.MeshSheepJL1, resources.MeshSheepJL2, resources.MeshSheepJL3 };
    sheep.SheepFlyLeftMeshResourceIndices = { resources.MeshSheepFL1, resources.MeshSheepFL2, resources.MeshSheepFL3 };
    sheep.SheepMoveRightMeshResourceIndices = { resources.MeshSheepR1, resources.MeshSheepR2 };
    sheep.SheepJumpRightMeshResourceIndices = { resources.MeshSheepJR1, resources.MeshSheepJR2, resources.MeshSheepJR3 };
    sheep.SheepFlyRightMeshResourceIndices = { resources.MeshSheepFR1, resources.MeshSheepFR2, resources.MeshSheepFR3 };
    sheep.CopterMeshResourceIndex = resources.MeshCopter;
    sheep.SheepTextureResourceIndex = sheep_texture;
    sheep.CopterTextureResourceIndex = resources.TextureBoringRed;
    sheep.KillSoundResourceIndex = resources.SoundGoat;
end

function CreateSheep_()
    g_delay = g_delay + 30;

    local new_follower_sheep = follower_sheep_module();

    SetResourceProperties_(new_follower_sheep, resources.TextureSheep);
    new_follower_sheep.SpawnCooldownTimer = g_delay;
    new_follower_sheep.copy_leader_properties(g_leader_sheep);

    table.insert(g_follower_sheep, new_follower_sheep);
end

function update(game_input)
    if g_init_stage_index == 1 then
        g_init_stage_index = 2;

        for iLoop = 0, 5 do
            CreateSheep_();
        end
    end

    if g_init_stage_index == 0 then
        g_init_stage_index = 1;

        g_hud_overlay = hud_overlay_module();

        g_leader_sheep = leader_sheep_module();
        SetResourceProperties_(g_leader_sheep, resources.TextureLSheep);

        set_level_extent_x(270);
    end

    if not g_hud_overlay.update(game_input) and g_is_first_update_complete then
        return false;
    end

    g_leader_sheep.update(g_follower_sheep);

    for _, follower_sheep in ipairs(g_follower_sheep) do
        follower_sheep.update();
    end

    if not g_is_first_update_complete then
        if g_init_stage_index > 1 then
            g_is_first_update_complete = true;
        end

        return false;
    end

    return true;
end

function reset()
    set_player_current_position_x(15);
    set_player_current_position_y(94);
    set_player_current_position_z(2);
    set_player_current_state(player_state.JSNORMAL);
end
