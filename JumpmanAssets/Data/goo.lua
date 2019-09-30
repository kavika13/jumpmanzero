local Module = {};

Module.GameLogic = nil;

Module.SpawnCallback = nil;
Module.KillCallback = nil;

Module.MeshResourceIndex = 0;
Module.TextureResourceIndex = 0;

Module.Type = 0;
Module.InitialPosX = { 0, 0 };
Module.InitialPosY = { 0, 0 };
Module.InitialRotationZ = 0;
Module.InitialIsGrowing = false;
Module.InitialChildren = {};

local g_is_initialized = false;

local g_mesh_index = 0;
local g_wobble_animation_counter = 0;

local g_type = 0;  -- TODO: Don't hard-code type enum
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

    if iPlat1 == 0 - 1 then
        iHit = 0 - 70;
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
    local _, iPlat = Module.GameLogic.find_platform(pos_x1, pos_y1 + 1, 3, 0);
    abs_platform(iPlat);

    local iPX1 = get_script_selected_level_object_x1();
    local iPX2 = get_script_selected_level_object_x2();
    local iPY1 = get_script_selected_level_object_y1();
    local iPY2 = get_script_selected_level_object_y2();
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
            ProgressVert_(1, 0 - 0.5);
        end

        if ProgressVert_(2, 0 - 0.5) == 1 then
            if g_current_pos_y[2] > 0 then
                g_children[1] = SpawnHorizontal_(1, 1, g_current_pos_x[2], g_current_pos_y[2], g_current_pos_x[2], g_current_pos_y[2]);
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
            if ProgressVert_(1, 0 - 0.5) == 1 then
                g_type = 0;  -- TODO: Don't hard-code type enum

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
            g_children[2] = SpawnVertical_(g_current_pos_x[2] + 0.5, g_current_pos_y[2]);
            g_Outlet2 = true;
        end

        if iProgress == 2 then
            g_type = 7;  -- TODO: Don't hard-code type enum
        end

        if g_type == 1 then  -- TODO: Don't hard-code type enum
            local iProgress2 = ProgressHorz_(1, 0 - 0.5);

            if iProgress2 == 1 then
                g_type = 6;  -- TODO: Don't hard-code type enum
                g_children[1] = SpawnVertical_(g_current_pos_x[1] - 0.5, g_current_pos_y[1]);
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
            g_children[2] = SpawnVertical_(g_current_pos_x[2] + 0.5, g_current_pos_y[2]);
            g_Outlet2 = true;
        end

        if iProgress == 2 then
            g_type = 8;  -- TODO: Don't hard-code type enum
        end

        return;
    end

    if g_type == 7 then  -- TODO: Don't hard-code type enum
        local iProgress = ProgressHorz_(1, 0 - 0.5);

        if iProgress == 1 then
            g_type = 8;  -- TODO: Don't hard-code type enum
            g_children[1] = SpawnVertical_(g_current_pos_x[1] - 0.5, g_current_pos_y[1]);
            g_Outlet1 = true;
        end

        if iProgress == 2 then
            g_type = 8;  -- TODO: Don't hard-code type enum
        end

        return;
    end

    if g_type == 2 then  -- TODO: Don't hard-code type enum
        if ProgressHorz_(1, 0.5) == 1 then
            g_type = 0;  -- TODO: Don't hard-code type enum

            if g_children[2] ~= nil then
                g_children[2].stop_growing();
            end
        end

        return;
    end

    if g_type == 3 then  -- TODO: Don't hard-code type enum
        if ProgressHorz_(2, 0 - 0.5) == 1 then
            g_type = 0;  -- TODO: Don't hard-code type enum

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
    local iPX = get_player_current_position_x();
    local iPY = get_player_current_position_y();

    if iPX < g_current_pos_x[2] + 2 and iPX > g_current_pos_x[1] - 2 then
        local iPH, iPlat = Module.GameLogic.find_platform(iPX, iPY, 8, 2);

        if iPlat == g_current_platform_object_index and iPY < iPH + 1 then
            kill();
        end
    end

    select_object_mesh(g_mesh_index);
    script_selected_mesh_set_identity_matrix();

    local iDX = g_current_pos_x[2] - g_current_pos_x[1];
    local iDY = g_current_pos_y[2] - g_current_pos_y[1];
    local iLen = math.floor(math.sqrt(iDX * iDX + iDY * iDY)) + 1;

    script_selected_mesh_scale_matrix(iLen, 1, 3);
    script_selected_mesh_rotate_matrix_z(g_current_rotation_z);

    g_wobble_animation_counter = g_wobble_animation_counter + 1;

    if g_wobble_animation_counter > 4 then
        g_wobble_animation_counter = 0;
    end

    if g_type == 4 or g_type == 5 then  -- TODO: Don't hard-code type enum
        g_wobble_animation_counter = 0;
    end

    if g_wobble_animation_counter > 2 then
        script_selected_mesh_translate_matrix((g_current_pos_x[1] + g_current_pos_x[2]) / 2, (g_current_pos_y[1] + g_current_pos_y[2]) / 2 + 0.04, 5);
    else
        script_selected_mesh_translate_matrix((g_current_pos_x[1] + g_current_pos_x[2]) / 2, (g_current_pos_y[1] + g_current_pos_y[2]) / 2 - 0.04, 5);
    end
end

local function DrawVertical_()
    -- TODO: Why does vertical not kill the player, but collision detection is in here?
    local iCollide = Module.GameLogic.is_player_colliding_with_rect(
        g_current_pos_x[1] - 1, g_current_pos_y[2] + 1,
        g_current_pos_x[2] + 1, g_current_pos_y[1] - 1);

    if iCollide == 1 then
        kill();
    end

    select_object_mesh(g_mesh_index);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_scale_matrix(g_current_pos_y[1] - g_current_pos_y[2], 1.3, 3);
    script_selected_mesh_rotate_matrix_z(90);
    script_selected_mesh_translate_matrix(g_current_pos_x[1] + 0.3, (g_current_pos_y[1] + g_current_pos_y[2]) / 2, 5);
end

function Module.update()
    if not g_is_initialized then
        g_is_initialized = true;
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
        set_object_visual_data(Module.TextureResourceIndex, 1);
    end

    MoveGoo_();

    if g_type == 0 then  -- TODO: Don't hard-code type enum
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
