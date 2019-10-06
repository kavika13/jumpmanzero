local Module = {};

local kBlastParticleCount = 20;

Module.GameLogic = nil;

Module.PlayAreaCircumference = 0;
Module.DonutIndex = 0;
Module.DonutTextureResourceIndex = 0;
Module.LightningTextureResourceIndex = 0;
Module.BlastParticleMeshResourceIndex = 0;
Module.BlastSoundResourceIndex = 0;
Module.ShipPosX = 0;
Module.ShipPosY = 0;
Module.IsLongFinalBlast = false;

local g_animation_frames_since_launched = 0;

local g_blast_particle_mesh_indices = {};
local g_animation_frames_since_blast_started = 0;

local function DoBlasting()
    local iShow = 10;

    if Module.IsLongFinalBlast then
        iShow = 20;
    end

    for iTemp = 0, iShow - 1 do
        local iBD = math.random(1, 10) * math.random(1, 10);
        iBD = (iBD / 6) + math.random(3, 15);
        local iBA = math.random(1, 360);

        local iBY = math.sin(iBA * math.pi / 180.0) * (iBD * 2 / 3) + Module.ShipPosY + 10;
        local iBX = math.cos(iBA * math.pi / 180.0) * iBD + Module.ShipPosX;
        local iBZ;

        if iTemp > 10 then
            iBY = iBY + 4;
            iBZ = 40;
        else
            iBZ = 30;
        end

        local iBR = math.random(1, 360);
        local iSize = math.random(10, 13);

        local mesh_index = g_blast_particle_mesh_indices[iTemp];
        select_object_mesh(mesh_index);

        set_identity_mesh_matrix(mesh_index);
        scale_mesh_matrix(mesh_index, iSize, iSize, 1);
        rotate_z_mesh_matrix(mesh_index, iBR);

        if iTemp > 10 then
            translate_mesh_matrix(mesh_index, 0, 0, -10);
            rotate_x_mesh_matrix(mesh_index, math.random(1, 90));
            translate_mesh_matrix(mesh_index, 0, 0, 10);
        end

        translate_mesh_matrix(mesh_index, iBX, iBY, iBZ);
        set_texture_and_is_visible_on_mesh(mesh_index, Module.LightningTextureResourceIndex, 1);
    end
end

function Module.initialize()
    for iTemp = 0, kBlastParticleCount - 1 do
        g_blast_particle_mesh_indices[iTemp] = new_mesh(Module.BlastParticleMeshResourceIndex);
    end
end

function Module.update()
    if g_animation_frames_since_launched == 100 then
        return;
    end

    select_donut(Module.DonutIndex);
    local donut_mesh_index = find_donut_mesh_index(Module.DonutIndex);

    if g_animation_frames_since_launched < 65 then
        g_animation_frames_since_launched = g_animation_frames_since_launched + 1;
    else
        set_texture_and_is_visible_on_mesh(donut_mesh_index, 0, 0);
        set_script_selected_level_object_visible(0);

        DoBlasting();
        g_animation_frames_since_blast_started = g_animation_frames_since_blast_started + 1;

        if g_animation_frames_since_blast_started == 1 then
            play_sound_effect(Module.BlastSoundResourceIndex);
        end

        if g_animation_frames_since_blast_started == 35 and not Module.IsLongFinalBlast then;
            for iTemp = 0, kBlastParticleCount - 1 do
                select_object_mesh(g_blast_particle_mesh_indices[iTemp]);
                set_texture_and_is_visible_on_mesh(g_blast_particle_mesh_indices[iTemp], 0, 0);
            end

            g_animation_frames_since_launched = 100;
        end
    end

    local iZ = 60 * g_animation_frames_since_launched;
    iZ = iZ + 75 * (65 - g_animation_frames_since_launched);
    iZ = iZ / 65;

    Module.ShipPosY = Module.ShipPosY + 8;

    local iY = (65 - g_animation_frames_since_launched) * get_script_selected_level_object_y1();
    iY = iY + (g_animation_frames_since_launched * Module.ShipPosY);
    iY = iY / 65;

    local iDist = 75 - g_animation_frames_since_launched;
    local iPX = Module.GameLogic.get_player_current_position_x();

    local iX = get_script_selected_level_object_x1();

    -- TODO: select_object_mesh is called above for blast particles, in DoBlasting(). Is this still the right object?
    --       It seems like it's leaving collected z-donuts visible now, because of the last line, which is not right
    set_identity_mesh_matrix(donut_mesh_index);
    scale_mesh_matrix(donut_mesh_index, 1, 1, 5);
    translate_mesh_matrix(donut_mesh_index, 0 - iX, 0, 0 - iDist);
    rotate_y_mesh_matrix(donut_mesh_index, (iPX - iX) * 360 / Module.PlayAreaCircumference);
    translate_mesh_matrix(donut_mesh_index, iPX, iY - get_script_selected_level_object_y1(), iZ);
    set_texture_and_is_visible_on_mesh(donut_mesh_index, Module.DonutTextureResourceIndex, 1);
end

return Module;
