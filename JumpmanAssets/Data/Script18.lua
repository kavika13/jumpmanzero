local read_only = require "Data/read_only";

-- TODO: Move this into a shared file, split into separate tables by type. Or inject from engine?
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
};
player_state = read_only.make_table_read_only(player_state);

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    ScriptDABot = 0,
    TextureJumpman = 0,
    TextureBrick = 1,
    TextureNewMetal = 2,
    TextureBoringGray = 3,
    TextureDABack = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    MeshSquare = 0,
    MeshSquare = 1,
    TextureLaser = 5,
    TextureDisarming = 6,
    MeshDABotL = 2,
    MeshDABotT1 = 3,
    MeshDABotT2 = 4,
    MeshDABotT3 = 5,
    MeshDABotT4 = 6,
    MeshDABotT5 = 7,
    MeshDABotR = 8,
    TextureDABot = 7,
    TextureDABotO = 8,
    TextureDABotB = 9,
    MeshDABotLS1 = 9,
    MeshDABotLS2 = 10,
    MeshDABotRS1 = 11,
    MeshDABotRS2 = 12,
    TextureBoringGreen = 10,
    MeshJMWork1 = 13,
    MeshJMWork2 = 14,
};
resources = read_only.make_table_read_only(resources);

-- TODO: Separate file?
local d_a_bot_properties = {
    DABotStartX = 0,
    DABotStartY = 1,
    DABotFireTime = 2,
    DABotWaitTime = 3,
    DABotBehavior = 4,
    DABotTexture = 5,
    DABotIInit = 6,
    DABotIX = 7,
    DABotIY = 8,
    DABotIZ = 9,
    DABotIFrame = 10,
    DABotIStatus = 11,
    DABotIMeshes = 12,
    DABotITurnCount = 43,
    DABotIWait = 44,
    DABotILaser = 45,
    DABotIFiring = 46,
};
d_a_bot_properties = read_only.make_table_read_only(d_a_bot_properties);

local g_is_initialized = false;

local g_message_mesh_index;
local g_progress_bar_mesh_index;

local g_jumpman_work_1_mesh_index;
local g_jumpman_work_2_mesh_index;
local g_work_animation_frame = 0;

local g_is_disarm_hud_visible = false;
local g_disarm_progress = 0;

function update(game_input)
    if not g_is_initialized then
        g_is_initialized = true;

        g_jumpman_work_1_mesh_index = new_mesh(resources.MeshJMWork1);
        set_object_visual_data(0, 0);

        g_jumpman_work_2_mesh_index = new_mesh(resources.MeshJMWork2);
        set_object_visual_data(0, 0);

        g_message_mesh_index = new_mesh(0);
        g_progress_bar_mesh_index = new_mesh(0);
        prioritize_object();

        MoveDonuts();

        CreateDABot(120, 10, 1, resources.TextureDABot);
        CreateDABot(90, 85, 1, resources.TextureDABot);
        CreateDABot(40, 86, 1, resources.TextureDABot);

        CreateDABot(90, 45, 3, resources.TextureDABotO);
        CreateDABot(90, 118, 3, resources.TextureDABotO);

        CreateDABot(20, 150, 2, resources.TextureDABotB);
    end

    CollideDonuts(game_input);

    if g_is_disarm_hud_visible then
        select_object_mesh(g_message_mesh_index);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_scale_matrix(20, 20, 1);
        script_selected_mesh_translate_matrix(0 - 54, 0 - 39, 120);
        script_selected_mesh_set_perspective_matrix();
        set_object_visual_data(resources.TextureDisarming, 1);

        select_object_mesh(g_progress_bar_mesh_index);
        script_selected_mesh_set_identity_matrix();
        local iProg = (100 - g_disarm_progress) * 16.5 / 100;
        script_selected_mesh_scale_matrix(iProg, 3.8, 1);
        script_selected_mesh_translate_matrix((0 - 54) + (iProg / 2) - 8.25, 0 - 41.8, 120);
        script_selected_mesh_set_perspective_matrix();
        set_object_visual_data(resources.TextureBoringGreen, 1);
    else
        select_object_mesh(g_message_mesh_index);
        set_object_visual_data(0, 0);

        select_object_mesh(g_progress_bar_mesh_index);
        set_object_visual_data(0, 0);
    end
end

function CollideDonuts(game_input)
    set_player_is_visible(1);
    g_is_disarm_hud_visible = false;

    select_object_mesh(g_jumpman_work_1_mesh_index);
    set_object_visual_data(0, 0);

    select_object_mesh(g_jumpman_work_2_mesh_index);
    set_object_visual_data(0, 0);

    -- Skip any progress checks if player is moving or not otherwise standing still
    local iPStat = get_player_current_state();

    if iPStat ~= player_state.JSNORMAL then
        return;
    end

    if game_input.move_left_action.is_pressed or game_input.move_right_action.is_pressed then
        return;
    end

    local iCount = get_donut_object_count();

    for iObj = 0, iCount - 1 do
        abs_donut(iObj);
        local iDX = get_script_selected_level_object_x1();
        local iDY = get_script_selected_level_object_y1();

        if iDY < 0 then
            -- Get actual Y value to test against the player's pos rather than the temporary (-Y) value
            iDY = 0 - iDY;
        end

        if get_script_selected_level_object_visible() then
            if is_player_colliding_with_rect(iDX - 3, iDY - 5, iDX + 3, iDY + 5) then
                local iDN = get_script_selected_level_object_number();
                g_disarm_progress = iDN;
                g_is_disarm_hud_visible = true;

                ShowWorking(game_input, iDX);
                abs_donut(iObj);

                if rnd(0, 100) < 20 then
                    return;
                end

                if iDN > 1 then
                    set_script_selected_level_object_number(iDN - 1);
                else
                    iDN = 0;
                    -- Move object to actual positive Y value so it gets collected
                    set_script_selected_level_object_y1(iDY);
                    g_is_disarm_hud_visible = false;
                end

                return;
            end
        end
    end
end

function ShowWorking(game_input, iDX)
    set_player_is_visible(0);
    local iPX = get_player_current_position_x();
    local iPY = get_player_current_position_y();
    local iPZ = get_player_current_position_z();

    g_work_animation_frame = g_work_animation_frame + 1;

    if g_work_animation_frame == 10 then
        g_work_animation_frame = 0;
    end

    if g_work_animation_frame > 5 then
        select_object_mesh(g_jumpman_work_1_mesh_index);
    else
        select_object_mesh(g_jumpman_work_2_mesh_index);
    end

    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(iPX, iPY + 6, iPZ + 1);
    set_object_visual_data(resources.TextureJumpman, 1);
end

function MoveDonuts()
    -- Move all the donuts to their -Y value, logically speaking (not visually),
    -- so they aren't immediately collected on contact
    local donut_count = get_donut_object_count();

    for iDonut = 0, donut_count - 1 do
        abs_donut(iDonut);
        set_script_selected_level_object_y1(0 - get_script_selected_level_object_y1());
    end
end

function CreateDABot(iX, iY, iBehave, iTexture)
    local iTemp = spawn_object(resources.ScriptDABot);
    set_object_global_data(iTemp, d_a_bot_properties.DABotStartX, iX);
    set_object_global_data(iTemp, d_a_bot_properties.DABotStartY, iY);
    set_object_global_data(iTemp, d_a_bot_properties.DABotFireTime, 70);
    set_object_global_data(iTemp, d_a_bot_properties.DABotWaitTime, 50);
    set_object_global_data(iTemp, d_a_bot_properties.DABotBehavior, iBehave);
    set_object_global_data(iTemp, d_a_bot_properties.DABotTexture, iTexture);
end

function reset()
    set_player_current_position_x(10);
    set_player_current_position_y(4);
    set_player_current_position_z(2);
    set_player_current_state(player_state.JSNORMAL);
end
