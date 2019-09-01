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
}
resources = read_only.make_table_read_only(resources);

-- TODO: Separate file?
local saw_properties = {
    SawIInit = 0,
    SawISaw = 1,
    SawIX = 2,
    SawIY = 3,
    SawIDir = 4,
    SawISpin = 5,
    SawIAirTime = 6,
    SawIZ = 7,
    SawIInitialFlight = 8,
    SawILaddeRing = 9,
    SawILadderTime = 10,
}
saw_properties = read_only.make_table_read_only(saw_properties);

local g_is_initialized = false;
local g_frog_animation_meshes = {};
local g_frog_animation_current_mesh_index = 0;
local g_frog_animation_frame = 100;

function update()
    if not g_is_initialized then
        g_is_initialized = true;

        LoadFrogMeshes();

        local iTemp = spawn_object(resources.ScriptSaw);
        set_object_global_data(iTemp, saw_properties.SawIX, 80);
        set_object_global_data(iTemp, saw_properties.SawIY, 100);

        iTemp = spawn_object(resources.ScriptSaw);
        set_object_global_data(iTemp, saw_properties.SawIX, 75);
        set_object_global_data(iTemp, saw_properties.SawIY, 100);

        iTemp = spawn_object(resources.ScriptSaw);
        set_object_global_data(iTemp, saw_properties.SawIX, 85);
        set_object_global_data(iTemp, saw_properties.SawIY, 100);

        iTemp = spawn_object(resources.ScriptSaw);
        set_object_global_data(iTemp, saw_properties.SawIX, 100);
        set_object_global_data(iTemp, saw_properties.SawIY, 45);

        iTemp = spawn_object(resources.ScriptSaw);
        set_object_global_data(iTemp, saw_properties.SawIX, 105);
        set_object_global_data(iTemp, saw_properties.SawIY, 45);

        iTemp = spawn_object(resources.ScriptSaw);
        set_object_global_data(iTemp, saw_properties.SawIX, 110);
        set_object_global_data(iTemp, saw_properties.SawIY, 45);

        iTemp = spawn_object(resources.ScriptSaw);
        set_object_global_data(iTemp, saw_properties.SawIX, 115);
        set_object_global_data(iTemp, saw_properties.SawIY, 45);
    end

    select_object_mesh(g_frog_animation_meshes[g_frog_animation_current_mesh_index]);
    set_object_visual_data(0, 0);

    ControlFrog();

    select_object_mesh(g_frog_animation_meshes[g_frog_animation_current_mesh_index]);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_scale_matrix(2, 2, 2);
    script_selected_mesh_translate_matrix(23, 175, 18);
    set_object_visual_data(resources.TextureFrog, 1);
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
        spawn_object(resources.ScriptSaw);
        play_sound_effect(resources.SoundFrog);
        g_frog_animation_current_mesh_index = 5;
    elseif g_frog_animation_frame > 20 then
        g_frog_animation_current_mesh_index = 5;
    elseif g_frog_animation_frame > 16 then
        g_frog_animation_current_mesh_index = 4;
    elseif g_frog_animation_frame == 11 then
        g_frog_animation_current_mesh_index = 3;

        if rnd(1, 100) > 50 then
            g_frog_animation_frame = 38
        end
    elseif g_frog_animation_frame > 10 then
        g_frog_animation_current_mesh_index = 3;
    elseif g_frog_animation_frame > 5 then
        g_frog_animation_current_mesh_index = 2;
    elseif g_frog_animation_frame > 1 then
        g_frog_animation_current_mesh_index = 1;
    else
        g_frog_animation_frame = 95 + rnd(1, 40);
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
