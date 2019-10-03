local read_only = require "Data/read_only";

local Module = {};

Module.GameLogic = nil;

Module.iX = 0;  -- TODO: Rename?
Module.iY = 0;  -- TODO: Rename?
Module.iR = 0;  -- TODO: Rename?
Module.iRV = 0;  -- TODO: Rename?

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureJumpman = 0,
    TextureConveyor = 1,
    TextureWaterBack = 2,
    TextureRedMetal = 3,
    TextureDarkSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    ScriptBullet = 0,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    TextureBullet = 5,
    MeshWhomper = 2,
    MeshProp = 3,
    TextureBoringGray = 6,
    ScriptWhomper = 1,
    ScriptProp = 2,
    TextureConveyor = 7,
};
resources = read_only.make_table_read_only(resources);

local g_is_initialized = false;
local g_whomper_mesh_index;

function Module.update()
    if not g_is_initialized then
        g_is_initialized = true;
        g_whomper_mesh_index = new_mesh(resources.MeshWhomper);
    end

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

    select_object_mesh(g_whomper_mesh_index);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_scale_matrix(8, 8, 8);
    script_selected_mesh_translate_matrix(0, -12, 0);
    script_selected_mesh_rotate_matrix_x(Module.iR);
    script_selected_mesh_translate_matrix(Module.iX, Module.iY, 2);
    set_object_visual_data(resources.TextureBoringGray, 1);

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
