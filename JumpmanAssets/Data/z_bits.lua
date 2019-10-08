local Module = {};

Module.MeshResourceIndex = 0;
Module.TextureResourceIndex = 0;
Module.PercentComplete = 0;

local g_particle_mesh_indices = {};
local g_particle_current_pos_x = {};
local g_particle_current_pos_y = {};
local g_particle_target_pos_x = {};
local g_particle_target_pos_y = {};
local g_particle_count = 0;

local function DrawParticles_()
    for iBit = 1, g_particle_count do
        local particle_mesh_index = g_particle_mesh_indices[iBit];

        local iDX = g_particle_current_pos_x[iBit] * (100 - Module.PercentComplete);
        iDX = iDX + (g_particle_target_pos_x[iBit] * Module.PercentComplete);
        iDX = iDX / 100;

        local iDY = g_particle_current_pos_y[iBit] * (100 - Module.PercentComplete);
        iDY = iDY + (g_particle_target_pos_y[iBit] * Module.PercentComplete);
        iDY = iDY / 100;

        local iZ = (5 * Module.PercentComplete) - 500;

        select_object_mesh(particle_mesh_index);
        set_identity_mesh_matrix(particle_mesh_index);
        rotate_y_mesh_matrix(particle_mesh_index, (100 - Module.PercentComplete) * math.sin(iBit * math.pi / 180.0) * 10);
        scale_mesh_matrix(particle_mesh_index, 4, 4, 4);
        translate_mesh_matrix(particle_mesh_index, iDX, iDY, iZ);
        set_texture_and_is_visible_on_mesh(particle_mesh_index, Module.TextureResourceIndex, 1);
    end
end

local function CreateParticle_(iSX, iSY)
    g_particle_count = g_particle_count + 1;
    g_particle_mesh_indices[g_particle_count] = new_mesh(Module.MeshResourceIndex);
    g_particle_target_pos_x[g_particle_count] = iSX;
    g_particle_target_pos_y[g_particle_count] = iSY;
    g_particle_current_pos_x[g_particle_count] = g_particle_target_pos_x[g_particle_count] + math.random(1, 200) - 100;
    g_particle_current_pos_y[g_particle_count] = g_particle_target_pos_y[g_particle_count] + math.random(1, 200) - 100;
end

function Module.initialize()
    local iDonuts = get_donut_object_count();

    for donut_index = 0, iDonuts - 1 do
        abs_donut(donut_index);
        local iDX = get_script_selected_level_object_x1();
        local iDY = get_script_selected_level_object_y1() - 2;
        local donut_mesh_index = get_donut_mesh_index(donut_index);
        set_mesh_is_visible(donut_mesh_index, false);
        CreateParticle_(iDX, iDY);
    end
end

function Module.update()
    DrawParticles_();
end

return Module;
