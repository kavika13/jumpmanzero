local Module = {};

Module.MeshResourceIndex = 0;
Module.TextureResourceIndex = 0;
Module.PercentComplete = 0;

local g_is_initialized = false;

local g_particle_mesh_indices = {};
local g_particle_current_pos_x = {};
local g_particle_current_pos_y = {};
local g_particle_target_pos_x = {};
local g_particle_target_pos_y = {};
local g_particle_count = 0;

local function DrawParticles()
    for iBit = 1, g_particle_count do
        local iDM = g_particle_mesh_indices[iBit];

        local iDX = g_particle_current_pos_x[iBit] * (100 - Module.PercentComplete);
        iDX = iDX + (g_particle_target_pos_x[iBit] * Module.PercentComplete);
        iDX = iDX / 100;

        local iDY = g_particle_current_pos_y[iBit] * (100 - Module.PercentComplete);
        iDY = iDY + (g_particle_target_pos_y[iBit] * Module.PercentComplete);
        iDY = iDY / 100;

        local iZ = (5 * Module.PercentComplete) - 500;

        select_object_mesh(iDM);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_rotate_matrix_y((100 - Module.PercentComplete) * sin(iBit) * 10);
        script_selected_mesh_scale_matrix(4, 4, 4);
        script_selected_mesh_translate_matrix(iDX, iDY, iZ);
        set_object_visual_data(Module.TextureResourceIndex, 1);
    end
end

local function CreateParticle(iSX, iSY)
    g_particle_count = g_particle_count + 1;
    g_particle_mesh_indices[g_particle_count] = new_mesh(Module.MeshResourceIndex);
    g_particle_target_pos_x[g_particle_count] = iSX;
    g_particle_target_pos_y[g_particle_count] = iSY;
    g_particle_current_pos_x[g_particle_count] = g_particle_target_pos_x[g_particle_count] + rnd(1, 200) - 100;
    g_particle_current_pos_y[g_particle_count] = g_particle_target_pos_y[g_particle_count] + rnd(1, 200) - 100;
end

local function InitParticles()
    local iDonuts = get_donut_object_count();

    for iObj = 0, iDonuts - 1 do
        abs_donut(iObj);
        local iDX = get_script_selected_level_object_x1();
        local iDY = get_script_selected_level_object_y1() - 2;
        set_script_selected_level_object_visible(0);
        CreateParticle(iDX, iDY);
    end
end

function Module.update()
    if not g_is_initialized then
        g_is_initialized = true;
        InitParticles();
    end

    DrawParticles();
end

return Module;
