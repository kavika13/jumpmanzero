local Module = {};

Module.GameLogic = nil;  -- TODO: Shouldn't need this module just to get level/donut data

Module.MeshResourceIndex = 0;
Module.TextureResourceIndex = 0;
Module.PercentComplete = 0;

local g_particle_mesh_indices = {};
local g_particle_transform_indices = {};
local g_particle_current_pos_x = {};
local g_particle_current_pos_y = {};
local g_particle_target_pos_x = {};
local g_particle_target_pos_y = {};
local g_particle_count = 0;

local function DrawParticles_(skip_next_interpolation)
    for iBit = 1, g_particle_count do
        local particle_mesh_index = g_particle_mesh_indices[iBit];
        local particle_transform_index = g_particle_transform_indices[iBit];

        local iDX = g_particle_current_pos_x[iBit] * (100 - Module.PercentComplete);
        iDX = iDX + (g_particle_target_pos_x[iBit] * Module.PercentComplete);
        iDX = iDX / 100;

        local iDY = g_particle_current_pos_y[iBit] * (100 - Module.PercentComplete);
        iDY = iDY + (g_particle_target_pos_y[iBit] * Module.PercentComplete);
        iDY = iDY / 100;

        local iZ = (5 * Module.PercentComplete) - 500;

        transform_set_scale(particle_transform_index, 4, 4, 4);
        transform_set_rotation_y(particle_transform_index, (100 - Module.PercentComplete) * math.sin(iBit * math.pi / 180.0) * 10);
        transform_set_translation(particle_transform_index, iDX, iDY, iZ);
        set_mesh_is_visible(particle_mesh_index, true);

        if skip_next_interpolation then
            skip_next_mesh_interpolation(particle_mesh_index);
        end
    end
end

local function CreateParticle_(iSX, iSY)
    g_particle_count = g_particle_count + 1;
    g_particle_mesh_indices[g_particle_count] = new_mesh(Module.MeshResourceIndex);
    g_particle_target_pos_x[g_particle_count] = iSX;
    g_particle_target_pos_y[g_particle_count] = iSY;
    g_particle_current_pos_x[g_particle_count] = g_particle_target_pos_x[g_particle_count] + math.random(1, 200) - 100;
    g_particle_current_pos_y[g_particle_count] = g_particle_target_pos_y[g_particle_count] + math.random(1, 200) - 100;
    g_particle_transform_indices[g_particle_count] = transform_create();
    mesh_set_transform(g_particle_mesh_indices[g_particle_count], g_particle_transform_indices[g_particle_count]);
    set_mesh_texture(g_particle_mesh_indices[g_particle_count], Module.TextureResourceIndex);
end

function Module.initialize()
    local donut_count = Module.GameLogic.get_donut_object_count();

    for donut_index = 0, donut_count - 1 do
        local current_donut = Module.GameLogic.get_donut(donut_index);
        set_mesh_is_visible(current_donut.mesh_index, false);
        CreateParticle_(current_donut.pos[1], current_donut.pos[2] - 2);
    end
end

function Module.update(skip_next_interpolation)
    DrawParticles_(skip_next_interpolation);
end

return Module;
