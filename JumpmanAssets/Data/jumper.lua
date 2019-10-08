local read_only = require "Data/read_only";

local Module = {};

Module.GameLogic = nil;

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

    local iPX = Module.GameLogic.get_player_current_position_x();
    local iPY = Module.GameLogic.get_player_current_position_y();

    local iHit, platform_index = Module.GameLogic.find_platform(g_current_pos_x, g_curret_pos_y, 1, 1);

    if g_current_status == status_type.JUMPING then
        local iOHit = iHit;
        local orig_platform_index = platform_index;

        if math.random(1, 100) > 70 then
            iHit, platform_index = Module.GameLogic.find_platform(g_current_pos_x, iHit - 4, 1, 1);
        elseif g_is_dodging and iPY < g_curret_pos_y - 2 then
            iHit, platform_index = Module.GameLogic.find_platform(g_current_pos_x, iHit - 4, 1, 1);
        end

        if iHit < 0 then
            platform_index = orig_platform_index;
            iHit = iOHit;
        end
    end

    local iNewZ;

    if iHit < 1 then
        iHit = -100;
        iNewZ = 0;
    else
        iNewZ = get_platform_z1(platform_index) - 1;
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

function Module.initialize()
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

function Module.update(all_jumpers)
    -- TODO: Animate through changemesh, instead of set_texture_and_is_visible_on_mesh?
    select_object_mesh(g_animation_mesh_indices[g_animation_current_frame]);  -- Previous frame
    set_texture_and_is_visible_on_mesh(g_animation_mesh_indices[g_animation_current_frame], 0, 0);

    MoveJumper_(all_jumpers);

    local anim_mesh_index = g_animation_mesh_indices[g_animation_current_frame];
    select_object_mesh(anim_mesh_index);
    set_identity_mesh_matrix(anim_mesh_index);
    translate_mesh_matrix(anim_mesh_index, g_current_pos_x, g_curret_pos_y + 9, g_current_pos_z);
    set_texture_and_is_visible_on_mesh(anim_mesh_index, Module.TextureResourceIndex, 1);

    local iEyeX = (Module.GameLogic.get_player_current_position_x() - g_current_pos_x) / 85;
    local iEyeX = iEyeX - 0.5;

    iEyeY = (Module.GameLogic.get_player_current_position_y() - g_curret_pos_y) / 85;
    iEyeY = iEyeY + 9.2 + g_eye_offset_y;

    select_object_mesh(g_eye_mesh_index);
    set_identity_mesh_matrix(g_eye_mesh_index);
    translate_mesh_matrix(g_eye_mesh_index, g_current_pos_x + iEyeX, g_curret_pos_y + iEyeY, g_current_pos_z);
    set_texture_and_is_visible_on_mesh(g_eye_mesh_index, Module.TextureResourceIndex, 1);

    if g_current_status == status_type.JUMPING then
        if Module.GameLogic.is_player_colliding_with_rect(
                g_current_pos_x - 2, g_curret_pos_y + 4,
                g_current_pos_x + 2, g_curret_pos_y + 10) then
            Module.GameLogic.kill();
        end
    end

    if g_current_status == status_type.CROUCHED then
        if Module.GameLogic.is_player_colliding_with_rect(
                g_current_pos_x - 2, g_curret_pos_y + 1,
                g_current_pos_x + 2, g_curret_pos_y + 3) then
            Module.GameLogic.kill();
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
