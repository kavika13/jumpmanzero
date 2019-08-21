-- TODO: Move this into a shared file, and check for other/better impls,
--       in case there are any (haven't looked)
function make_read_only(tbl)
    return setmetatable({}, {
        __index = tbl,
        __newindex = function(t, key, value)
            error("attempting to change constant " ..
                   tostring(key) .. " to " .. tostring(value), 2)
        end
    });
end

-- TODO: Move this into a shared file, split into separate tables by type
local player_state = {
    JSNORMAL = 0,
    JSJUMPING = 1,
    JSRIGHT = 2,
    JSLEFT = 4,
    JSFALLING = 8,
    JSLADDER = 16,
    JSKICK = 32,
    JSROLL = 64,
    JSPUNCH = 128,
    JSDYING = 256,
    JSVINE = 1024,
}
player_state = make_read_only(player_state);

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureJumpman = 0,
    TextureClassicPlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureBullet = 4,
    TextureSky = 5,
    TextureNinja = 6,
    TexturePillar = 7,
    TextureCarpet5 = 8,
    TextureWoodPlatform = 9,
    TextureEvenWood = 10,
    ScriptNinja = 0,
    MeshNjRight1 = 0,
    MeshNjRight2 = 1,
    MeshNjJR = 2,
    MeshNjKR = 3,
    MeshNjRR1 = 4,
    MeshNjRR2 = 5,
    MeshNjRR3 = 6,
    MeshNjRR4 = 7,
    MeshNjLeft1 = 8,
    MeshNjLeft2 = 9,
    MeshNjJL = 10,
    MeshNjKL = 11,
    MeshNjRL1 = 12,
    MeshNjRL2 = 13,
    MeshNjRL3 = 14,
    MeshNjRL4 = 15,
    MeshNjDead = 16,
    MeshNjW1 = 17,
    MeshNjW2 = 18,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
}
resources = make_read_only(resources);

-- TODO: Separate file?
local ninja_properties = {
    NinjaStartX = 0,
    NinjaStartY = 1,
    NinjaIInit = 2,
    NinjaIX = 3,
    NinjaIY = 4,
    NinjaIZ = 5,
    NinjaIFixDonut = 6,
    NinjaISlow = 7,
    NinjaIAnimate = 8,
    NinjaIFrame = 9,
    NinjaIDir = 10,
    NinjaIATime = 11,
    NinjaIMeshes = 12,
    NinjaIStatus = 43,
    NinjaICount = 44,
}
ninja_properties = make_read_only(ninja_properties);

local g_is_initialized = false;
local g_is_trap_door_triggering = false;
local g_trap_door_fall_progress = 0;

function update()
    if not g_is_initialized then
        g_is_initialized = true;

        local iTemp = spawn_object(resources.ScriptNinja);
        set_object_global_data(iTemp, ninja_properties.NinjaStartX, 120);
        set_object_global_data(iTemp, ninja_properties.NinjaStartY, 8);

        iTemp = spawn_object(resources.ScriptNinja);
        set_object_global_data(iTemp, ninja_properties.NinjaStartX, 70);
        set_object_global_data(iTemp, ninja_properties.NinjaStartY, 40);

        iTemp = spawn_object(resources.ScriptNinja);
        set_object_global_data(iTemp, ninja_properties.NinjaStartX, 30);
        set_object_global_data(iTemp, ninja_properties.NinjaStartY, 120);

        iTemp = spawn_object(resources.ScriptNinja);
        set_object_global_data(iTemp, ninja_properties.NinjaStartX, 110);
        set_object_global_data(iTemp, ninja_properties.NinjaStartY, 80);
    end

    if g_is_trap_door_triggering then
        -- TODO: When the trap falls the game bugs out
        g_trap_door_fall_progress = g_trap_door_fall_progress + 3;
        MovePlatform(1, g_trap_door_fall_progress, 0);
        -- TODO: This doesn't seem to do anything in the code, at least not for #compose
        --       Seems maybe should delete the line?
        -- setext(#compose, 1);
        select_platform(1);
        set_script_selected_level_object_y1(get_script_selected_level_object_y1() - 3);

        if g_trap_door_fall_progress >= 90 then
            set_script_selected_level_object_y1(500);
            set_script_selected_level_object_y2(500);
            g_is_trap_door_triggering = false;
        end
    end
end

function MovePlatform(iPlat, iRotate, iTran)
    select_platform(iPlat);
    local iPlatX = get_script_selected_level_object_x2();
    local iPlatY = get_script_selected_level_object_y2();
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(0 - iPlatX, 0 - iPlatY, 0);
    script_selected_mesh_rotate_matrix_z(iRotate);
    script_selected_mesh_translate_matrix(iPlatX + iTran, iPlatY, 0);
end

function on_collect_donut()
    if get_script_event_data_1() == 1 then
        g_is_trap_door_triggering = true;
    end
end

function reset()
    set_player_current_position_x(20);
    set_player_current_position_y(7);
    set_player_current_position_z(1);
    set_player_current_state(player_state.JSNORMAL);
end
