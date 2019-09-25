local read_only = require "Data/read_only";
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local saw_module = assert(loadfile("Data/saw.lua"));

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
    TextureGirder = 1,
    TextureBoringBlush = 2,
    TextureRedMetal = 3,
    TextureDark = 4,
    SoundJump = 0,
    Soundchomp = 1,
    Soundbonk = 2,
    SoundFrog = 3,
    MeshFrogL = 0,
    TextureFrog = 5,
    MeshSaw = 1,
    TextureBoringGray = 6,
    ScriptSaw = 0,
    MeshFrogB1 = 2,
    MeshFrogB2 = 3,
    MeshFrogB3 = 4,
    MeshFrogB4 = 5,
    MeshFrogB5 = 6,
    TextureOilDrum = 7,
    TextureBoringGray = 8,
    TextureBoringBlue = 9,
};
resources = read_only.make_table_read_only(resources);

local g_is_initialized = false;
local g_is_first_update_complete = false;

local g_hud_overlay;
local g_saws = {};
local g_frog_animation_meshes = {};
local g_frog_animation_current_mesh_index = 0;
local g_frog_animation_frame = 100;

local function RemoveSaw_(saw)
    for index, value in ipairs(g_saws) do
        if value == saw then
            table.remove(g_saws, index);
            return;
        end
    end

    assert(false, "Was unable to find saw to remove");
end

local function SpawnSaw_(initial_pos_x, initial_pos_y)
    local saw = saw_module();
    saw.DestroyObjectCallback = RemoveSaw_;
    saw.InitialPosX = initial_pos_x;
    saw.InitialPosY = initial_pos_y;
    saw.MeshResourceIndex = resources.MeshSaw;
    saw.TextureResourceIndex = resources.TextureBoringGray;
    return saw;
end

function update(game_input)
    if not g_is_initialized then
        g_is_initialized = true;

        g_hud_overlay = hud_overlay_module();

        LoadFrogMeshes();

        table.insert(g_saws, SpawnSaw_(80, 100));
        table.insert(g_saws, SpawnSaw_(75, 100));
        table.insert(g_saws, SpawnSaw_(85, 100));
        table.insert(g_saws, SpawnSaw_(100, 45));
        table.insert(g_saws, SpawnSaw_(105, 45));
        table.insert(g_saws, SpawnSaw_(110, 45));
        table.insert(g_saws, SpawnSaw_(115, 45));
    end

    if not g_hud_overlay.update(game_input) and g_is_first_update_complete then
        return false;
    end

    select_object_mesh(g_frog_animation_meshes[g_frog_animation_current_mesh_index]);
    set_object_visual_data(0, 0);

    ControlFrog();

    select_object_mesh(g_frog_animation_meshes[g_frog_animation_current_mesh_index]);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_scale_matrix(2, 2, 2);
    script_selected_mesh_translate_matrix(23, 175, 18);
    set_object_visual_data(resources.TextureFrog, 1);

    for _, saw in ipairs(g_saws) do
        saw.update();
    end

    if not g_is_first_update_complete then
        g_is_first_update_complete = true;
        return false;
    end

    return true;
end

function ControlFrog()
    g_frog_animation_frame = g_frog_animation_frame - 1;

    if g_frog_animation_frame > 75 then
        g_frog_animation_current_mesh_index = 0;
    elseif g_frog_animation_frame > 65 then
        g_frog_animation_current_mesh_index = 1;
    elseif g_frog_animation_frame > 42 then
        g_frog_animation_current_mesh_index = 2;
    elseif g_frog_animation_frame > 38 then
        g_frog_animation_current_mesh_index = 3;
    elseif g_frog_animation_frame > 34 then
        g_frog_animation_current_mesh_index = 4;
    elseif g_frog_animation_frame > 30 then
        g_frog_animation_current_mesh_index = 5;
    elseif g_frog_animation_frame == 30 then
        table.insert(g_saws, SpawnSaw_(0, 0));
        play_sound_effect(resources.SoundFrog);
        g_frog_animation_current_mesh_index = 5;
    elseif g_frog_animation_frame > 20 then
        g_frog_animation_current_mesh_index = 5;
    elseif g_frog_animation_frame > 16 then
        g_frog_animation_current_mesh_index = 4;
    elseif g_frog_animation_frame == 11 then
        g_frog_animation_current_mesh_index = 3;

        if math.random(1, 100) > 50 then
            g_frog_animation_frame = 38;
        end
    elseif g_frog_animation_frame > 10 then
        g_frog_animation_current_mesh_index = 3;
    elseif g_frog_animation_frame > 5 then
        g_frog_animation_current_mesh_index = 2;
    elseif g_frog_animation_frame > 1 then
        g_frog_animation_current_mesh_index = 1;
    else
        g_frog_animation_frame = 95 + math.random(1, 40);
        g_frog_animation_current_mesh_index = 1;
    end
end

function LoadFrogMeshes()
    g_frog_animation_meshes[0] = new_mesh(resources.MeshFrogL);
    g_frog_animation_meshes[1] = new_mesh(resources.MeshFrogB1);
    g_frog_animation_meshes[2] = new_mesh(resources.MeshFrogB2);
    g_frog_animation_meshes[3] = new_mesh(resources.MeshFrogB3);
    g_frog_animation_meshes[4] = new_mesh(resources.MeshFrogB4);
    g_frog_animation_meshes[5] = new_mesh(resources.MeshFrogB5);
end

function reset()
    set_player_current_position_x(14);
    set_player_current_position_y(17);
    set_player_current_position_z(3);
    set_player_current_state(player_state.JSNORMAL);
end
