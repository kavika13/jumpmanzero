local Module = {};

local kBlastParticleCount = 20;

Module.GameLogic = nil;

Module.PlayAreaCircumference = 0;
Module.DonutNum = 0;
Module.DonutTextureResourceIndex = 0;
Module.LightningTextureResourceIndex = 0;
Module.BlastParticleMeshResourceIndex = 0;
Module.BlastSoundResourceIndex = 0;
Module.ShipPosX = 0;
Module.ShipPosY = 0;
Module.IsLongFinalBlast = false;

local g_donut = nil;

local g_animation_frames_since_launched = 0;

local g_blast_particle_mesh_indices = {};
local g_blast_particle_transform_indices = {};
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
        local transform_indices = g_blast_particle_transform_indices[iTemp];
        transform_set_to_identity(transform_indices[1]);
        transform_set_scale(transform_indices[1], iSize, iSize, 1);
        transform_set_rotation_z(transform_indices[1], iBR);

        if iTemp > 10 then
            transform_set_translation(transform_indices[1], 0, 0, -10);
            transform_set_rotation_x(transform_indices[2], math.random(1, 90));
            transform_set_translation(transform_indices[2], 0, 0, 10);
        else
            transform_clear_translation(transform_indices[1]);
            transform_set_to_identity(transform_indices[2]);
        end

        transform_set_translation(transform_indices[3], iBX, iBY, iBZ);
        set_mesh_is_visible(mesh_index, true);
        skip_next_mesh_interpolation(mesh_index);
    end
end

function Module.initialize()
    for iTemp = 0, kBlastParticleCount - 1 do
        g_blast_particle_mesh_indices[iTemp] = new_mesh(Module.BlastParticleMeshResourceIndex);
        g_blast_particle_transform_indices[iTemp] = { transform_create(), transform_create(), transform_create() };
        mesh_set_transform(g_blast_particle_mesh_indices[iTemp], g_blast_particle_transform_indices[iTemp][1]);
        transform_set_parent(g_blast_particle_transform_indices[iTemp][1], g_blast_particle_transform_indices[iTemp][2]);
        transform_set_parent(g_blast_particle_transform_indices[iTemp][2], g_blast_particle_transform_indices[iTemp][3]);
        set_mesh_texture(g_blast_particle_mesh_indices[iTemp], Module.LightningTextureResourceIndex);
    end

    g_donut = Module.GameLogic.find_donut_by_number(Module.DonutNum);
    g_donut_transform_indices = { transform_create(), transform_create() };
    mesh_set_transform(g_donut.mesh_index, g_donut_transform_indices[1]);
    transform_set_parent(g_donut_transform_indices[1], g_donut_transform_indices[2]);
end

function Module.update(skip_next_interpolation)
    if g_animation_frames_since_launched == 100 then
        return;
    end

    if g_animation_frames_since_launched < 65 then
        set_mesh_is_visible(g_donut.mesh_index, true);
        g_animation_frames_since_launched = g_animation_frames_since_launched + 1;
    else
        Module.GameLogic.set_donut_is_collected(g_donut.index, true);
        set_mesh_is_visible(g_donut.mesh_index, false);

        DoBlasting();
        g_animation_frames_since_blast_started = g_animation_frames_since_blast_started + 1;

        if g_animation_frames_since_blast_started == 1 then
            play_sound_effect(Module.BlastSoundResourceIndex);
        end

        if g_animation_frames_since_blast_started == 35 and not Module.IsLongFinalBlast then;
            for iTemp = 0, kBlastParticleCount - 1 do
                set_mesh_is_visible(g_blast_particle_mesh_indices[iTemp], false);
            end

            g_animation_frames_since_launched = 100;
        end
    end

    local iZ = 60 * g_animation_frames_since_launched;
    iZ = iZ + 75 * (65 - g_animation_frames_since_launched);
    iZ = iZ / 65;

    Module.ShipPosY = Module.ShipPosY + 8;

    local iY = (65 - g_animation_frames_since_launched) * g_donut.pos[2];
    iY = iY + (g_animation_frames_since_launched * Module.ShipPosY);
    iY = iY / 65;

    local iDist = 75 - g_animation_frames_since_launched;
    local iPX = Module.GameLogic.get_player_current_position_x();

    local iX = g_donut.pos[1];

    -- TODO: Any reason to keep this code if the donut becomes invisible?
    --       Check through the motion code, and make sure it doesn't affect the blasting particles.
    --       If not, move up into the top of the `if` above
    transform_set_scale(g_donut_transform_indices[1], 1, 1, 5);
    transform_set_translation(g_donut_transform_indices[1], 0 - iX, 0, 0 - iDist);
    transform_set_rotation_y(g_donut_transform_indices[2], (iPX - iX) * 360 / Module.PlayAreaCircumference);
    transform_set_translation(g_donut_transform_indices[2], iPX, iY - g_donut.pos[2], iZ);

    if skip_next_interpolation then
        skip_next_mesh_interpolation(g_donut.mesh_index);
    end
end

return Module;
