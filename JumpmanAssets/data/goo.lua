local read_only = require "data/read_only";

local Module = {};

-- TODO: Refactor so this module doesn't have to be instantiated, and export this variable on Module
local goo_type = {
    -- TODO: Figure out and fill out rest
    TO_REMOVE = 0,
};
goo_type = read_only.make_table_read_only(goo_type);

Module.GameLogic = nil;

Module.SpawnCallback = nil;
Module.KillCallback = nil;

Module.MeshResourceIndex = 0;
Module.TextureResourceIndex = 0;

Module.Type = goo_type.TO_REMOVE;
Module.InitialPosX = { 0, 0 };
Module.InitialPosY = { 0, 0 };
Module.InitialRotationZ = 0;
Module.InitialIsGrowing = false;
Module.InitialChildren = {};

local g_mesh_index = 0;
local g_wobble_animation_counter = 0;

local g_type = goo_type.TO_REMOVE;
local g_children = {};

local g_is_growing = false;

local g_current_pos_x = {};  -- Keeps track of both sides of object at g_current_pos_x[1] and g_current_pos_x[2]
local g_current_pos_y = {};
local g_current_rotation_z = 0;

local g_Outlet1 = false;  -- TODO: Rename
local g_Outlet2 = false;  -- TODO: Rename

local g_current_platform_object_index = -1;

local function ProgressVert_(iHead, iYV)
    g_current_pos_y[iHead] = g_current_pos_y[iHead] + iYV;

    local iHit, iPlat1 = Module.GameLogic.find_platform(g_current_pos_x[iHead], g_current_pos_y[iHead], 8, 0);

    if iPlat1 == -1 then
        iHit = -70;
    end

    if iHit >= g_current_pos_y[iHead] + iYV then
        g_current_pos_y[iHead] = iHit;
        return 1;
    end

    return 0;
end

local function SpawnVertical_(iNewX, iNewY)
    local new_goo = Module.SpawnCallback();
    new_goo.Type = 4;
    new_goo.InitialPosX[1] = iNewX;
    new_goo.InitialPosX[2] = iNewX;
    new_goo.InitialPosY[1] = iNewY;
    new_goo.InitialPosY[2] = iNewY;
    new_goo.InitialIsGrowing = true;
    return new_goo;
end

local function ProgressHorz_(iHead, velocity_x)
    g_current_pos_x[iHead] = g_current_pos_x[iHead] + velocity_x;

    local iHit1, iPlat1 = Module.GameLogic.find_platform(g_current_pos_x[iHead], g_current_pos_y[iHead], 4, 0);
    local iHit2, iPlat2 = Module.GameLogic.find_platform(g_current_pos_x[iHead] + velocity_x, g_current_pos_y[iHead], 4, 0);

    g_current_platform_object_index = iPlat1;

    if iHit1 > g_current_pos_y[iHead] then
        return 2;
    end

    if iPlat1 ~= iPlat2 then
        if iHit2 <= iHit1 then
            return 1;
        end

        return 0;
    end

    g_current_pos_y[iHead] = (iHit1 + g_current_pos_y[iHead]) / 2;
    return 0;
end

local function SpawnHorizontal_(goo_type, iNFrom, pos_x1, pos_y1, pos_x2, pos_y2)
    -- TODO: Remove iNFrom parameter? Or is it useful for debuggin?
    local _, platform_index = Module.GameLogic.find_platform(pos_x1, pos_y1 + 1, 3, 0);
    local current_platform = Module.GameLogic.get_platform(platform_index);

    local iPX1 = current_platform.pos_upper_left[1];
    local iPY1 = current_platform.pos_upper_left[2];
    local iPX2 = current_platform.pos_lower_right[1];
    local iPY2 = current_platform.pos_lower_right[2];
    local iAngle = math.atan(iPY2 - iPY1, iPX2 - iPX1) * 180.0 / math.pi;

    local new_goo = Module.SpawnCallback();
    new_goo.Type = goo_type;
    new_goo.InitialPosX[1] = pos_x1;
    new_goo.InitialPosX[2] = pos_x2;
    new_goo.InitialPosY[1] = pos_y1;
    new_goo.InitialPosY[2] = pos_y2;
    new_goo.InitialRotationZ = iAngle;
    new_goo.InitialIsGrowing = true;

    return new_goo;
end

local function MoveGoo_()
    if g_type == 4 then  -- TODO: Don't hard-code type enum
        if not g_is_growing then
            ProgressVert_(1, -0.5);
        end

        if ProgressVert_(2, -0.5) == 1 then
            if g_current_pos_y[2] > 0 then
                local new_goo = SpawnHorizontal_(1, 1, g_current_pos_x[2], g_current_pos_y[2], g_current_pos_x[2], g_current_pos_y[2]);
                new_goo.initialize();
                g_children[1] = new_goo;
                g_type = 5;  -- TODO: Don't hard-code type enum
            end

            if not g_is_growing then
                g_type = 5;  -- TODO: Don't hard-code type enum
            end
        end

        return;
    end

    if g_type == 5 then  -- TODO: Don't hard-code type enum
        if not g_is_growing then
            if ProgressVert_(1, -0.5) == 1 then
                g_type = goo_type.TO_REMOVE;

                if g_children[1] ~= nil then
                    g_children[1].stop_growing();
                end
            end
        end

        return;
    end

    if g_type == 1 then  -- TODO: Don't hard-code type enum
        local iProgress = ProgressHorz_(2, 0.5);

        if iProgress == 1 then
            g_type = 7;  -- TODO: Don't hard-code type enum
            local new_goo = SpawnVertical_(g_current_pos_x[2] + 0.5, g_current_pos_y[2]);
            new_goo.initialize();
            g_children[2] = new_goo;
            g_Outlet2 = true;
        end

        if iProgress == 2 then
            g_type = 7;  -- TODO: Don't hard-code type enum
        end

        if g_type == 1 then  -- TODO: Don't hard-code type enum
            local iProgress2 = ProgressHorz_(1, -0.5);

            if iProgress2 == 1 then
                g_type = 6;  -- TODO: Don't hard-code type enum
                local new_goo = SpawnVertical_(g_current_pos_x[1] - 0.5, g_current_pos_y[1]);
                new_goo.initialize();
                g_children[1] = new_goo;
                g_Outlet1 = true;
            end

            if iProgress2 == 2 then
                g_type = 6;  -- TODO: Don't hard-code type enum
            end
        end

        return;
    end

    if g_type == 6 then  -- TODO: Don't hard-code type enum
        local iProgress = ProgressHorz_(2, 0.5);

        if iProgress == 1 then
            g_type = 8;  -- TODO: Don't hard-code type enum
            local new_goo = SpawnVertical_(g_current_pos_x[2] + 0.5, g_current_pos_y[2]);
            new_goo.initialize();
            g_children[2] = new_goo;
            g_Outlet2 = true;
        end

        if iProgress == 2 then
            g_type = 8;  -- TODO: Don't hard-code type enum
        end

        return;
    end

    if g_type == 7 then  -- TODO: Don't hard-code type enum
        local iProgress = ProgressHorz_(1, -0.5);

        if iProgress == 1 then
            g_type = 8;  -- TODO: Don't hard-code type enum
            local new_goo = SpawnVertical_(g_current_pos_x[1] - 0.5, g_current_pos_y[1]);
            new_goo.initialize();
            g_children[1] = new_goo;
            g_Outlet1 = true;
        end

        if iProgress == 2 then
            g_type = 8;  -- TODO: Don't hard-code type enum
        end

        return;
    end

    if g_type == 2 then  -- TODO: Don't hard-code type enum
        if ProgressHorz_(1, 0.5) == 1 then
            g_type = goo_type.TO_REMOVE;

            if g_children[2] ~= nil then
                g_children[2].stop_growing();
            end
        end

        return;
    end

    if g_type == 3 then  -- TODO: Don't hard-code type enum
        if ProgressHorz_(2, -0.5) == 1 then
            g_type = goo_type.TO_REMOVE;

            if g_children[1] ~= nil then
                g_children[1].stop_growing();
            end
        end

        return;
    end

    if g_type == 8 and not g_is_growing then  -- TODO: Don't hard-code type enum
        if g_Outlet1 and g_Outlet2 then
            local iNewX = (g_current_pos_x[1] + g_current_pos_x[2]) / 2;
            local iNewY = (g_current_pos_y[1] + g_current_pos_y[2]) / 2;
            local new_goo = SpawnHorizontal_(2, 3, iNewX, iNewY, g_current_pos_x[2], g_current_pos_y[2]);
            new_goo.InitialChildren[2] = g_children[2];
            new_goo.initialize();
            g_current_pos_x[2] = iNewX;
            g_current_pos_y[2] = iNewY;
            g_type = 3;  -- TODO: Don't hard-code type enum
        end

        if g_Outlet1 and not g_Outlet2 then
            g_type = 3;  -- TODO: Don't hard-code type enum
        end

        if not g_Outlet1 and g_Outlet2 then
            g_type = 2;  -- TODO: Don't hard-code type enum
        end

        return;
    end
end

local function DrawHorizontal_()
    -- TODO: Why does horizontal kill the player, but no collision detection is in here?
    local iPX = Module.GameLogic.get_player_current_position_x();
    local iPY = Module.GameLogic.get_player_current_position_y();

    if iPX < g_current_pos_x[2] + 2 and iPX > g_current_pos_x[1] - 2 then
        local iPH, iPlat = Module.GameLogic.find_platform(iPX, iPY, 8, 2);

        if iPlat == g_current_platform_object_index and iPY < iPH + 1 then
            Module.GameLogic.kill();
        end
    end

    set_identity_mesh_matrix(g_mesh_index);

    local iDX = g_current_pos_x[2] - g_current_pos_x[1];
    local iDY = g_current_pos_y[2] - g_current_pos_y[1];
    local iLen = math.floor(math.sqrt(iDX * iDX + iDY * iDY)) + 1;

    scale_mesh_matrix(g_mesh_index, iLen, 1, 3);
    rotate_z_mesh_matrix(g_mesh_index, g_current_rotation_z);

    g_wobble_animation_counter = g_wobble_animation_counter + 1;

    if g_wobble_animation_counter > 4 then
        g_wobble_animation_counter = 0;
    end

    if g_type == 4 or g_type == 5 then  -- TODO: Don't hard-code type enum
        g_wobble_animation_counter = 0;
    end

    if g_wobble_animation_counter > 2 then
        translate_mesh_matrix(g_mesh_index, (g_current_pos_x[1] + g_current_pos_x[2]) / 2, (g_current_pos_y[1] + g_current_pos_y[2]) / 2 + 0.04, 5);
    else
        translate_mesh_matrix(g_mesh_index, (g_current_pos_x[1] + g_current_pos_x[2]) / 2, (g_current_pos_y[1] + g_current_pos_y[2]) / 2 - 0.04, 5);
    end
end

local function DrawVertical_()
    -- TODO: Why does vertical not kill the player, but collision detection is in here?
    local iCollide = Module.GameLogic.is_player_colliding_with_rect(
        g_current_pos_x[1] - 1, g_current_pos_y[2] + 1,
        g_current_pos_x[2] + 1, g_current_pos_y[1] - 1);

    if iCollide == 1 then
        Module.GameLogic.kill();
    end

    set_identity_mesh_matrix(g_mesh_index);
    scale_mesh_matrix(g_mesh_index, g_current_pos_y[1] - g_current_pos_y[2], 1.3, 3);
    rotate_z_mesh_matrix(g_mesh_index, 90);
    translate_mesh_matrix(g_mesh_index, g_current_pos_x[1] + 0.3, (g_current_pos_y[1] + g_current_pos_y[2]) / 2, 5);
end

function Module.initialize()
    g_type = Module.Type;
    g_current_pos_x[1] = Module.InitialPosX[1];
    g_current_pos_x[2] = Module.InitialPosX[2];
    g_current_pos_y[1] = Module.InitialPosY[1];
    g_current_pos_y[2] = Module.InitialPosY[2];
    g_current_rotation_z = Module.InitialRotationZ;
    g_is_growing = Module.InitialIsGrowing;
    g_children[1] = Module.InitialChildren[1];
    g_children[2] = Module.InitialChildren[2];
    g_mesh_index = new_mesh(Module.MeshResourceIndex);
    set_mesh_texture(g_mesh_index, Module.TextureResourceIndex);
    set_mesh_is_visible(g_mesh_index, true);
end

function Module.update()
    MoveGoo_();

    if g_type == goo_type.TO_REMOVE then
        delete_mesh(g_mesh_index);
        Module.KillCallback(Module);
        return;
    end

    local GT = g_type;

    if GT == 1 or GT == 2 or GT == 3 or GT == 6 or GT == 7 or GT == 8 then  -- TODO: Don't hard-code type enum
        DrawHorizontal_();
    end

    if GT == 4 or GT == 5 then  -- TODO: Don't hard-code type enum
        DrawVertical_();
    end
end

function Module.stop_growing()
    g_is_growing = false;
end

return Module;
