local read_only = require "Data/read_only";

local Module = {};

Module.AnimationMeshResourceIndices = {};
Module.EyesMeshResourceIndex = 0;
Module.TextureResourceIndex = 0;
Module.StartAlive = false;

local status_type = {
    CROUCHED = 0,
    JUMPING = 1,
    STRANDED = 10,
};
status_type = read_only.make_table_read_only(status_type);

local g_is_initialized = false;

local g_animation_mesh_indices = {};
local g_animation_current_frame = 0;

local g_eye_mesh_index;

local g_current_status = status_type.CROUCHED;
local g_time_crouching = 0;
local g_is_dodging = false;  -- TODO: Is player "dodging", or is jumper "dodging"

local g_current_pos_x = 0;
local g_curret_pos_y = 0;
local g_current_pos_z = 0;
local g_current_velocity_x = 0;
local g_current_velocity_y = 0;

local g_eye_offset_y = 0;

local function CheckForNearbyJumpers_(all_jumpers)
    for _, other_jumper in ipairs(all_jumpers) do
        if other_jumper.get_current_status() == status_type.JUMPING then
            local iOX, iOY = other_jumper.get_current_pos();

            if (iOX - g_current_pos_x) < 40 and (iOX - g_current_pos_x) > -40 then
                if (iOY - g_curret_pos_y) < 50 and (iOY - g_curret_pos_y) > -50 then
                    return true;
                end
            end
        end
    end

    return false;
end

local function MoveJumper_(all_jumpers)
    if g_curret_pos_y < -50 then
        g_current_status = status_type.STRANDED;
        g_curret_pos_y = -50;
        g_current_pos_x = 0;
        return 0;
    end

    if g_current_status == status_type.STRANDED then
        g_animation_current_frame = 1;
        return 0;
    end

    local iPY = get_player_current_position_y();
    local iPX = get_player_current_position_x();

    local iPlat = find_platform(g_current_pos_x, g_curret_pos_y, 1, 1);
    local iHit = get_script_event_data_4();

    if g_current_status == status_type.JUMPING then
        local iOHit = iHit;
        local iOPlat = iPlat;

        if math.random(1, 100) > 70 then
            iPlat = find_platform(g_current_pos_x, iHit - 4, 1, 1);
            iHit = get_script_event_data_4();
        elseif g_is_dodging and iPY < g_curret_pos_y - 2 then
            iPlat = find_platform(g_current_pos_x, iHit - 4, 1, 1);
            iHit = get_script_event_data_4();
        end

        if iHit < 0 then
            iPlat = iOPlat;
            iHit = iOHit;
        end
    end

    local iNewZ;

    if iHit < 1 then
        iHit = -100;
        iNewZ = 0;
    else
        abs_platform(iPlat);
        iNewZ = get_script_selected_level_object_z1() - 1;
    end

    if g_current_status == status_type.CROUCHED or iNewZ < g_current_pos_z then
        if g_current_pos_z < iNewZ then
            g_current_pos_z = g_current_pos_z + 1;
        elseif g_current_pos_z > iNewZ then
            g_current_pos_z = g_current_pos_z - 1;
        end
    end

    if g_current_status == status_type.CROUCHED then
        g_time_crouching = g_time_crouching + 1;

        if CheckForNearbyJumpers_(all_jumpers) and g_time_crouching > 12 and g_time_crouching < 30 then
            g_time_crouching = 12;
        end

        g_curret_pos_y = iHit;

        if g_time_crouching < 5 then
            g_animation_current_frame = 2;
            g_eye_offset_y = -4;
        elseif g_time_crouching < 30 then
            g_animation_current_frame = 3;
            g_eye_offset_y = -6;
        elseif g_time_crouching < 35 then
            g_animation_current_frame = 2;
            g_eye_offset_y = -4;
        else
            g_current_status = status_type.JUMPING;

            if iPY < g_curret_pos_y - 7 then
                g_is_dodging = true;
                g_current_velocity_y = math.random(50, 70) / 100;
            else
                g_is_dodging = false;
                g_current_velocity_y = math.random(130, 170) / 100;
            end

            if g_current_pos_x < iPX - 110 then
                g_current_pos_x = iPX - 110;
            elseif g_current_pos_x > iPX + 110 then
                g_current_pos_x = iPX + 110;
            end

            if iPX < g_current_pos_x - 6 then
                g_current_velocity_x = -0.6;
            elseif iPX > g_current_pos_x + 6 then
                g_current_velocity_x = 0.6;
            else
                g_current_velocity_x = 0;
            end
        end
    end

    if g_current_status == status_type.CROUCHED then
        return 0;
    end

    g_animation_current_frame = 1;
    g_eye_offset_y = 0;

    local iAir = g_curret_pos_y - iHit;

    if iAir < 2 and g_current_velocity_y < 0 then
        g_current_status = status_type.CROUCHED;
        g_time_crouching = 0;
        return 0;
    end

    g_current_velocity_y = g_current_velocity_y - 0.04;

    if g_current_velocity_y < -1.1 then
        g_current_velocity_y = -1.1;
    end

    g_current_pos_x = g_current_pos_x + g_current_velocity_x;
    g_curret_pos_y = g_curret_pos_y + g_current_velocity_y;
end

function Module.update(all_jumpers)
    if not g_is_initialized then
        g_is_initialized = true;

        g_animation_mesh_indices[1] = new_mesh(Module.AnimationMeshResourceIndices[1]);
        g_animation_mesh_indices[2] = new_mesh(Module.AnimationMeshResourceIndices[2]);
        g_animation_mesh_indices[3] = new_mesh(Module.AnimationMeshResourceIndices[3]);
        g_eye_mesh_index = new_mesh(Module.EyesMeshResourceIndex);

        if not Module.StartAlive then
            g_current_pos_x = -50;
            g_curret_pos_y = -50;
            g_current_velocity_y = -1;
            g_animation_current_frame = 1;
            g_current_status = status_type.STRANDED;
        else
            g_current_pos_x = 200;
            g_curret_pos_y = math.random(20, 80);
            g_current_velocity_y = -1;
            g_animation_current_frame = 1;
            g_current_status = status_type.JUMPING;
        end
    end

    select_object_mesh(g_animation_mesh_indices[g_animation_current_frame]);
    set_object_visual_data(0, 0);

    MoveJumper_(all_jumpers);

    select_object_mesh(g_animation_mesh_indices[g_animation_current_frame]);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(g_current_pos_x, g_curret_pos_y + 9, g_current_pos_z);
    set_object_visual_data(Module.TextureResourceIndex, 1);

    local iEyeX = (get_player_current_position_x() - g_current_pos_x) / 85;
    local iEyeX = iEyeX - 0.5;

    iEyeY = (get_player_current_position_y() - g_curret_pos_y) / 85;
    iEyeY = iEyeY + 9.2 + g_eye_offset_y;

    select_object_mesh(g_eye_mesh_index);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(g_current_pos_x + iEyeX, g_curret_pos_y + iEyeY, g_current_pos_z);
    set_object_visual_data(Module.TextureResourceIndex, 1);

    if g_current_status == status_type.JUMPING then
        if is_player_colliding_with_rect(g_current_pos_x - 2, g_curret_pos_y + 4, g_current_pos_x + 2, g_curret_pos_y + 10) then
            kill();
        end
    end

    if g_current_status == status_type.CROUCHED then
        if is_player_colliding_with_rect(g_current_pos_x - 2, g_curret_pos_y + 1, g_current_pos_x + 2, g_curret_pos_y + 3) then
            kill();
        end
    end
end

function Module.reset_pos()
    if g_current_pos_x < 100 then
        g_current_status = status_type.STRANDED;
        g_curret_pos_y = -50;
        g_current_pos_x = 0;
    end
end

function Module.get_current_pos()
    return g_current_pos_x, g_curret_pos_y;
end

function Module.get_current_status()
    return g_current_status;
end

function Module.set_current_pos(pos_x, pos_y)
    g_current_pos_x, g_curret_pos_y = pos_x, pos_y;
end

function Module.set_current_velocity(vel_x, vel_y)
    g_current_velocity_x, g_curret_velocity_y = vel_x, vel_y;
end

function Module.set_current_status(new_status)
    g_current_status = new_status;
end

return Module;
