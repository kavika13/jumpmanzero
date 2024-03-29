local Module = {};

Module.GameLogic = nil;

Module.DestroyObjectCallback = nil;

Module.MeshResourceIndex = 0;
Module.TextureResourceIndex = 0;

Module.InitialPosX = 0;
Module.InitialPosY = 0;

local g_saw_mesh_index = -1;
local g_saw_transform_index = -1;
local g_is_initial_flight = false;

local g_current_pos_x = 0;
local g_current_pos_y = 0;
local g_current_pos_z = 0;
local g_current_rotation_z_degrees = 0;
local g_is_on_ladder = false;
local g_current_time_on_ladder = 0;
local g_current_time_in_air = 0;
local g_current_direction = 0;  -- TODO: Rename and refactor? Currently this is only 3 or 4, could be "direction_x" instead of something?

local function MoveSaw_()
    if not g_is_on_ladder then
        local ladder_index, _ = Module.GameLogic.find_ladder(g_current_pos_x, g_current_pos_y);

        if ladder_index > -1 then
            local current_ladder = Module.GameLogic.get_ladder(ladder_index);

            if current_ladder.pos_x > g_current_pos_x - 1 and current_ladder.pos_x < g_current_pos_x + 1 then
                if math.random(1, 100) > 74 and current_ladder.pos_y_bottom < g_current_pos_y - 5 then
                    g_current_pos_x = current_ladder.pos_x;
                    g_is_on_ladder = true;
                    g_current_pos_z = current_ladder.pos_z[1];
                    g_current_time_on_ladder = 0;
                end
            end
        end
    end

    if g_is_on_ladder then
        g_current_time_on_ladder = g_current_time_on_ladder + 1;
        g_current_pos_y = g_current_pos_y - 0.5;

        if g_current_time_on_ladder < 15 then
            return;
        end

        local iHit, _ = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y, 3, 4);

        if iHit > g_current_pos_y then
            g_is_on_ladder = false;
            g_current_pos_y = iHit;

            if g_current_direction == 4 then
                g_current_direction = 3;
            else
                g_current_direction = 4;
            end
        else
            return;
        end
    end

    local iHit, platform_index = Module.GameLogic.find_platform(g_current_pos_x, g_current_pos_y, 6, 4);
    local iTargetZ = g_current_pos_z;

    if platform_index ~= -1 then
        iTargetZ = Module.GameLogic.get_platform(platform_index).pos_z;
    end

    if iHit < 1 then
        iHit = -100;
        iTargetZ = 0;
    end

    if g_current_pos_z < iTargetZ then
        g_current_pos_z = g_current_pos_z + 1;
    elseif g_current_pos_z > iTargetZ then
        g_current_pos_z = g_current_pos_z - 1;
    end

    if iHit >= g_current_pos_y then
        g_current_pos_y = iHit;
        g_current_time_in_air = 0;
        g_is_initial_flight = false;
    elseif g_is_initial_flight then
        g_current_time_in_air = g_current_time_in_air + 1;
        g_current_pos_y = g_current_pos_y - g_current_time_in_air / 30;
    elseif iHit < g_current_pos_y - 2 then
        g_current_pos_y = g_current_pos_y - g_current_time_in_air / 20;

        if g_current_time_in_air < 21 then
            g_current_time_in_air = g_current_time_in_air + 1;
        end
    else
        g_current_pos_y = iHit;
        g_current_time_in_air = 0;
        g_is_initial_flight = false;
    end

    if g_current_time_in_air == 1 then
        if g_current_direction == 3 then
            g_current_direction = 4;
        else
            g_current_direction = 3;
        end
    end

    if g_current_time_in_air < 10 and g_is_initial_flight then
        if g_current_direction == 4 then
            g_current_pos_x = g_current_pos_x + 0.5;
        else
            g_current_pos_x = g_current_pos_x - 0.5;
        end
    elseif g_current_time_in_air < 5 and g_is_initial_flight then
        if g_current_direction == 4 then
            g_current_pos_x = g_current_pos_x + 0.3;
        else
            g_current_pos_x = g_current_pos_x - 0.3;
        end
    end

    if g_current_time_in_air < 1 or g_is_initial_flight then
        if g_current_direction == 4 then
            g_current_pos_x = g_current_pos_x + 0.7;
        else
            g_current_pos_x = g_current_pos_x - 0.7;
        end
    else
        if g_current_direction == 4 then
            g_current_pos_x = g_current_pos_x - 0.4 + g_current_time_in_air / 60;
        else
            g_current_pos_x = g_current_pos_x + 0.4 - g_current_time_in_air / 60;
        end
    end
end

function Module.initialize()
    g_saw_mesh_index = new_mesh(Module.MeshResourceIndex);
    g_saw_transform_index = transform_create();
    mesh_set_transform(g_saw_mesh_index, g_saw_transform_index);
    set_mesh_texture(g_saw_mesh_index, Module.TextureResourceIndex);

    g_current_pos_x = Module.InitialPosX;
    g_current_pos_y = Module.InitialPosY;

    if g_current_pos_x == 0 then
        g_current_pos_x = 31;
        g_current_pos_y = 173;
    end

    g_current_pos_z = 22;
    g_current_direction = 4;
    g_is_initial_flight = true;
    g_current_time_in_air = 1;
end

function Module.update()
    MoveSaw_();

    if g_current_pos_y < -60 then
        delete_mesh(g_saw_mesh_index);
        Module.DestroyObjectCallback(Module);
        return;
    end

    if g_is_initial_flight then
        g_current_rotation_z_degrees = g_current_rotation_z_degrees - 6;
    elseif (g_current_direction == 4 and g_current_time_in_air == 0) or
            (g_current_direction == 3 and g_current_time_in_air ~= 0) then
        g_current_rotation_z_degrees = g_current_rotation_z_degrees - 6;
    else
        g_current_rotation_z_degrees = g_current_rotation_z_degrees + 6;
    end

    transform_set_scale(g_saw_transform_index, 0.75, 0.75, 0.75);
    transform_set_rotation_z(g_saw_transform_index, g_current_rotation_z_degrees);
    transform_set_translation(g_saw_transform_index, g_current_pos_x, g_current_pos_y + 4, g_current_pos_z - 0.1);
    set_mesh_is_visible(g_saw_mesh_index, true);

    if Module.GameLogic.is_player_colliding_with_rect(
            g_current_pos_x - 3, g_current_pos_y + 1,
            g_current_pos_x + 3, g_current_pos_y + 3.5) then
        Module.GameLogic.kill();
    end
end

return Module;
