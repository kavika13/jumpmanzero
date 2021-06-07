local Module = {};

Module.GameLogic = nil;

Module.MeshResourceIndex = -1;
Module.TextureResourceIndex = -1;
Module.iX = 0;  -- TODO: Rename?
Module.iY = 0;  -- TODO: Rename?
Module.iR = 0;  -- TODO: Rename?
Module.iRV = 0;  -- TODO: Rename?

local g_whomper_mesh_index = -1;
local g_whomper_transform_indices = nil;

function Module.initialize()
    g_whomper_mesh_index = new_mesh(Module.MeshResourceIndex);
    g_whomper_transform_indices = { transform_create(), transform_create() };
    mesh_set_transform(g_whomper_mesh_index, g_whomper_transform_indices[1]);
    transform_set_parent(g_whomper_transform_indices[1], g_whomper_transform_indices[2]);
    set_mesh_texture(g_whomper_mesh_index, Module.TextureResourceIndex);
end

function Module.update()
    if Module.iR > 10 then
        Module.iRV = Module.iRV - 0.02;
    end

    if Module.iR > 15 then
        Module.iRV = Module.iRV - 0.02;
    end

    if Module.iR > 20 then
        Module.iRV = Module.iRV - 0.02;
    end

    if Module.iR > 25 then
        Module.iRV = Module.iRV - 0.02;
    end

    if Module.iR > 30 then
        Module.iRV = Module.iRV - 0.02;
    end

    if Module.iR < -10 then
        Module.iRV = Module.iRV + 0.02;
    end

    if Module.iR < -15 then
        Module.iRV = Module.iRV + 0.02;
    end

    if Module.iR < -20 then
        Module.iRV = Module.iRV + 0.02;
    end

    if Module.iR < -25 then
        Module.iRV = Module.iRV + 0.02;
    end

    if Module.iR < -30 then
        Module.iRV = Module.iRV + 0.02;
    end

    Module.iR = Module.iR + Module.iRV;

    transform_set_scale(g_whomper_transform_indices[1], 8, 8, 8);
    transform_set_translation(g_whomper_transform_indices[1], 0, -12, 0);
    transform_set_rotation_x(g_whomper_transform_indices[2], Module.iR);
    transform_set_translation(g_whomper_transform_indices[2], Module.iX, Module.iY, 2);
    set_mesh_is_visible(g_whomper_mesh_index, true);

    if Module.GameLogic.is_player_colliding_with_rect(
            Module.iX - 4.5, Module.iY - 25,
            Module.iX + 4.5, Module.iY - 4) then
        if Module.iRV > 0 then
            if Module.iR < 0 and Module.iR > -20 then
                Module.GameLogic.kill();
            end
        else
            if Module.iR < 20 and Module.iR > 0 then
                Module.GameLogic.kill();
            end
        end
    end
end

return Module;
