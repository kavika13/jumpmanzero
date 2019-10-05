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
        select_object_mesh(g_blast_particle_mesh_indices[iTemp]);
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

        set_identity_mesh_matrix(g_blast_particle_mesh_indices[iTemp]);
        scale_mesh_matrix(g_blast_particle_mesh_indices[iTemp], iSize, iSize, 1);
        script_selected_mesh_rotate_matrix_z(iBR);

        if iTemp > 10 then
            script_selected_mesh_translate_matrix(0, 0, -10);
            script_selected_mesh_rotate_matrix_x(math.random(1, 90));
            script_selected_mesh_translate_matrix(0, 0, 10);
        end

        script_selected_mesh_translate_matrix(iBX, iBY, iBZ);
        set_object_visual_data(Module.LightningTextureResourceIndex, 1);
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

    if g_animation_frames_since_launched < 65 then
        g_animation_frames_since_launched = g_animation_frames_since_launched + 1;
    else
        set_object_visual_data(0, 0);
        set_script_selected_level_object_visible(0);

        DoBlasting();
        g_animation_frames_since_blast_started = g_animation_frames_since_blast_started + 1;

        if g_animation_frames_since_blast_started == 1 then
            play_sound_effect(Module.BlastSoundResourceIndex);
        end

        if g_animation_frames_since_blast_started == 35 and not Module.IsLongFinalBlast then;
            for iTemp = 0, kBlastParticleCount - 1 do
                select_object_mesh(g_blast_particle_mesh_indices[iTemp]);
                set_object_visual_data(0, 0);
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
    local donut_mesh_index = find_donut_mesh_index(Module.DonutIndex);
    set_identity_mesh_matrix(donut_mesh_index);  -- TODO: select_object_mesh is called above for blast particles. Is this still the right object?
    scale_mesh_matrix(donut_mesh_index, 1, 1, 5);
    script_selected_mesh_translate_matrix(0 - iX, 0, 0 - iDist);
    script_selected_mesh_rotate_matrix_y((iPX - iX) * 360 / Module.PlayAreaCircumference);
    script_selected_mesh_translate_matrix(iPX, iY - get_script_selected_level_object_y1(), iZ);
    set_object_visual_data(Module.DonutTextureResourceIndex, 1);
end

return Module;
