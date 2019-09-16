local read_only = require "Data/read_only";

local Module = {};

Module.iX = 0;  -- TODO: Rename?
Module.iY = 0;  -- TODO: Rename?
Module.iZ = 0;  -- TODO: Rename?
Module.iR = 0;  -- TODO: Rename?

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
local g_propeller_mesh_index;
local g_current_rotation = 0;

function Module.update()
    if not g_is_initialized then
        g_is_initialized = true;
        g_propeller_mesh_index = new_mesh(resources.MeshProp);
    end

    g_current_rotation = g_current_rotation + 4;

    if g_current_rotation >= 360 then
        g_current_rotation = 0;
    end

    select_object_mesh(g_propeller_mesh_index);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_scale_matrix(6, 8, 2);
    script_selected_mesh_rotate_matrix_x(90);
    script_selected_mesh_rotate_matrix_y(g_current_rotation + Module.iR);
    script_selected_mesh_translate_matrix(Module.iX, Module.iY, Module.iZ);
    set_object_visual_data(resources.TextureBoringGray, 1);

    local iPX = get_player_current_position_x();
    local current_rotation = Module.iR + g_current_rotation;

    if (current_rotation > 85 and current_rotation < 95) or (current_rotation > 265 and current_rotation < 275) then
        if is_player_colliding_with_rect(Module.iX - 35, Module.iY - 1, Module.iX - 5, Module.iY + 1) then
            kill();
        end

        if is_player_colliding_with_rect(Module.iX + 5, Module.iY - 1, Module.iX + 35, Module.iY + 1) then
            kill();
        end
    end
end

return Module;
