local Module = {};

Module.GameLogic = nil;

Module.MeshResourceIndex = -1;
Module.TextureResourceIndex = -1;
Module.iX = 0;  -- TODO: Rename?
Module.iY = 0;  -- TODO: Rename?
Module.iZ = 0;  -- TODO: Rename?
Module.iR = 0;  -- TODO: Rename?

local g_propeller_mesh_index = -1;
local g_propeller_transform_index = -1;
local g_current_rotation = 0;

function Module.initialize()
    g_propeller_mesh_index = new_mesh(Module.MeshResourceIndex);
    g_propeller_transform_index = transform_create();
    object_set_transform(g_propeller_mesh_index, g_propeller_transform_index);
    set_mesh_texture(g_propeller_mesh_index, Module.TextureResourceIndex);
end

function Module.update()
    g_current_rotation = g_current_rotation + 4;

    if g_current_rotation >= 360 then
        g_current_rotation = 0;
    end

    transform_set_scale(g_propeller_transform_index, 6, 8, 2);
    transform_set_rotation_x(g_propeller_transform_index, 90);
    transform_concat_rotation_y(g_propeller_transform_index, g_current_rotation + Module.iR);
    transform_set_translation(g_propeller_transform_index, Module.iX, Module.iY, Module.iZ);
    set_mesh_is_visible(g_propeller_mesh_index, true);

    local iPX = Module.GameLogic.get_player_current_position_x();
    local current_rotation = Module.iR + g_current_rotation;

    if (current_rotation > 85 and current_rotation < 95) or (current_rotation > 265 and current_rotation < 275) then
        if Module.GameLogic.is_player_colliding_with_rect(
                Module.iX - 35, Module.iY - 1,
                Module.iX - 5, Module.iY + 1) then
            Module.GameLogic.kill();
        end

        if Module.GameLogic.is_player_colliding_with_rect(
                Module.iX + 5, Module.iY - 1,
                Module.iX + 35, Module.iY + 1) then
            Module.GameLogic.kill();
        end
    end
end

return Module;
