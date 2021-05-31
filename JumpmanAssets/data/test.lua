local Module = {};

local g_texture_index = -1;
local g_mesh_index = -1;

function Module.initialize(initial_level_name)
    unload_all_resources();  -- TODO: This must be called to set transforms all to -1. Should fix that
    set_perspective(0, 0, -50, 0, 0, 0);  -- TODO: What is up with the default camera? Does it actually make sense?

    begin_loading_3d_data();  -- TODO: Should be able to add new 3D data whenever we want, appending to a buffer. Having to synchronize that is not good, and I believe SOKOL has ways to make it work (once per frame? maybe needs to go to a temp buffer? not sure)
    g_texture_index = load_texture("data/jumpman.bmp", 0, false);  -- TODO: Load a default texture that the rendering pipeline starts with. Errors out otherwise. Also, need to initialize all textures to -1 not 0 by default
    g_mesh_index = load_mesh("data/stand.msh");  -- TODO: Should be able to run without a default mesh as well. Maybe fixing the default texture will fix that?
    set_mesh_is_visible(g_mesh_index, true);
    end_and_commit_loading_3d_data();

    -- TODO: Why does it crash when we tab out of the game? But only when full-screen for some reason, and only with this test script...
end

function Module.update(game_input)
end

function Module.on_exit_requested()
end

return Module
