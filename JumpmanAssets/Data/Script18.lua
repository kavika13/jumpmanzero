local read_only = require "Data/read_only";
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local zap_bot_module = assert(loadfile("Data/zap_bot.lua"));

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
    MeshLaser = 1,  -- TODO: Isn't defined in the level. Added here manually. Should fix level instead. Looks right tho
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

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_zap_bots = {};

local g_message_mesh_index;
local g_progress_bar_mesh_index;

local g_jumpman_work_1_mesh_index;
local g_jumpman_work_2_mesh_index;
local g_work_animation_frame = 0;

local g_is_disarm_hud_visible = false;
local g_disarm_progress = 0;

local function ShowWorking_(game_input)
    g_game_logic.set_player_is_visible(false);
    local iPX = g_game_logic.get_player_current_position_x();
    local iPY = g_game_logic.get_player_current_position_y();
    local iPZ = g_game_logic.get_player_current_position_z();

    g_work_animation_frame = g_work_animation_frame + 1;

    if g_work_animation_frame == 10 then
        g_work_animation_frame = 0;
    end

    local mesh_index;

    if g_work_animation_frame > 5 then
        mesh_index = g_jumpman_work_1_mesh_index;
    else
        mesh_index = g_jumpman_work_2_mesh_index;
    end

    select_object_mesh(mesh_index);
    set_identity_mesh_matrix(mesh_index);
    translate_mesh_matrix(mesh_index, iPX, iPY + 6, iPZ + 1);
    set_texture_and_is_visible_on_mesh(mesh_index, resources.TextureJumpman, 1);
end

local function CollideDonuts_(game_input)
    g_game_logic.set_player_is_visible(true);
    g_is_disarm_hud_visible = false;

    select_object_mesh(g_jumpman_work_1_mesh_index);
    set_texture_and_is_visible_on_mesh(g_jumpman_work_1_mesh_index, 0, 0);

    select_object_mesh(g_jumpman_work_2_mesh_index);
    set_texture_and_is_visible_on_mesh(g_jumpman_work_2_mesh_index, 0, 0);

    -- Skip any progress checks if player is moving or not otherwise standing still
    local iPStat = g_game_logic.get_player_current_state();

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
            if g_game_logic.is_player_colliding_with_rect(iDX - 3, iDY - 5, iDX + 3, iDY + 5) then
                local iDN = get_script_selected_level_object_number();
                g_disarm_progress = iDN;
                g_is_disarm_hud_visible = true;

                ShowWorking_(game_input);
                abs_donut(iObj);

                if math.random(0, 100) < 20 then
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

local function CreateDABot_(initial_pos_x, initial_pos_y, behavior_type, texture_resource_index)
    local new_bot = zap_bot_module();

    new_bot.GameLogic = g_game_logic;

    new_bot.BotMoveLeftMeshResourceIndex = resources.MeshDABotL;
    new_bot.BotMoveRightMeshResourceIndex = resources.MeshDABotR;
    new_bot.BotTurnMeshResourceIndices = {
        resources.MeshDABotT1,
        resources.MeshDABotT2,
        resources.MeshDABotT3,
        resources.MeshDABotT4,
        resources.MeshDABotT5,
    };
    new_bot.BotFireLeftMeshResourceIndices = { resources.MeshDABotLS1, resources.MeshDABotLS2 };
    new_bot.BotFireRightMeshResourceIndices = { resources.MeshDABotRS1, resources.MeshDABotRS2 };
    new_bot.LaserMeshResourceIndex = resources.MeshLaser;
    new_bot.BotTextureResourceIndex = texture_resource_index;
    new_bot.LaserTextureResourceIndex = resources.TextureLaser;

    new_bot.InitialPosX = initial_pos_x;
    new_bot.InitialPosY = initial_pos_y;
    new_bot.FireDuration = 70;
    new_bot.WaitDuration = 50;
    new_bot.BehaviorType = behavior_type;

    new_bot.initialize();

    return new_bot;
end

function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    CollideDonuts_(game_input);

    if g_is_disarm_hud_visible then
        select_object_mesh(g_message_mesh_index);
        set_identity_mesh_matrix(g_message_mesh_index);
        scale_mesh_matrix(g_message_mesh_index, 20, 20, 1);
        translate_mesh_matrix(g_message_mesh_index, 0 - 54, 0 - 39, 120);
        undo_camera_perspective_on_mesh_matrix(g_message_mesh_index);
        set_texture_and_is_visible_on_mesh(g_message_mesh_index, resources.TextureDisarming, 1);

        select_object_mesh(g_progress_bar_mesh_index);
        set_identity_mesh_matrix(g_progress_bar_mesh_index);
        local iProg = (100 - g_disarm_progress) * 16.5 / 100;
        scale_mesh_matrix(g_progress_bar_mesh_index, iProg, 3.8, 1);
        translate_mesh_matrix(g_progress_bar_mesh_index, (0 - 54) + (iProg / 2) - 8.25, 0 - 41.8, 120);
        undo_camera_perspective_on_mesh_matrix(g_progress_bar_mesh_index);
        set_texture_and_is_visible_on_mesh(g_progress_bar_mesh_index, resources.TextureBoringGreen, 1);
    else
        select_object_mesh(g_message_mesh_index);
        set_texture_and_is_visible_on_mesh(g_message_mesh_index, 0, 0);

        select_object_mesh(g_progress_bar_mesh_index);
        set_texture_and_is_visible_on_mesh(g_progress_bar_mesh_index, 0, 0);
    end

    for _, zap_bot in ipairs(g_zap_bots) do
        zap_bot.update();
    end

    g_game_logic.update_player_graphics();
end

local function MoveDonuts_()
    -- Move all the donuts to their -Y value, logically speaking (not visually),
    -- so they aren't immediately collected on contact
    local donut_count = get_donut_object_count();

    for iDonut = 0, donut_count - 1 do
        abs_donut(iDonut);
        set_script_selected_level_object_y1(0 - get_script_selected_level_object_y1());
    end
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.ResetPlayerCallback = reset;

    g_hud_overlay = hud_overlay_module();

    g_jumpman_work_1_mesh_index = new_mesh(resources.MeshJMWork1);
    set_texture_and_is_visible_on_mesh(g_jumpman_work_1_mesh_index, 0, 0);

    g_jumpman_work_2_mesh_index = new_mesh(resources.MeshJMWork2);
    set_texture_and_is_visible_on_mesh(g_jumpman_work_2_mesh_index, 0, 0);

    g_message_mesh_index = new_mesh(0);
    g_progress_bar_mesh_index = new_mesh(0);
    prioritize_object();

    MoveDonuts_();

    -- TODO: Use behavior enum from zap_bot module instead of hard-coded numbers for 3rd parameter
    table.insert(g_zap_bots, CreateDABot_(120, 10, 1, resources.TextureDABot));
    table.insert(g_zap_bots, CreateDABot_(90, 85, 1, resources.TextureDABot));
    table.insert(g_zap_bots, CreateDABot_(40, 86, 1, resources.TextureDABot));

    table.insert(g_zap_bots, CreateDABot_(90, 45, 3, resources.TextureDABotO));
    table.insert(g_zap_bots, CreateDABot_(90, 118, 3, resources.TextureDABotO));

    table.insert(g_zap_bots, CreateDABot_(20, 150, 2, resources.TextureDABotB));

    reset();

    -- Make sure staged initialization has happened, and Jumpman has floated to the floor
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
end

function update(game_input)
    if not g_title_is_done_scrolling then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return;
    end

    ProgressLevel_(game_input);
end

function reset()
    g_game_logic.set_player_current_position_x(10);
    g_game_logic.set_player_current_position_y(4);
    g_game_logic.set_player_current_position_z(2);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end
