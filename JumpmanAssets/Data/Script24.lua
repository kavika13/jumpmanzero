local read_only = require "Data/read_only";
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local baboon_module = assert(loadfile("Data/baboon.lua"));

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
    TextureJumpman = 0,
    TextureWoodPlatform = 1,
    TextureYellowRope = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    MeshBaboon = 0,
    MeshBaboon1 = 1,
    MeshBaboon2 = 2,
    MeshBaboon3 = 3,
    MeshBaboon4 = 4,
    TextureBaboon = 5,
    TextureBark = 6,
    ScriptBaboon = 0,
    MeshHang = 5,
    MeshHang1 = 6,
    MeshHang2 = 7,
    MeshHang3 = 8,
    MeshHang4 = 9,
    MeshHangL1 = 10,
    MeshHangL2 = 11,
    MeshHangL3 = 12,
    MeshHangL4 = 13,
    TextureHangVine = 7,
};
resources = read_only.make_table_read_only(resources);

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local baboons = {};

local g_hang_animation_current_frame;
local g_hang_animation_next_frame_counter = 0;
local iHangMesh = {};

local function CheckHanging_(game_input)
    for iDraw = 0, 19 do
        if iHangMesh[iDraw] and iHangMesh[iDraw] > 0 then
            select_object_mesh(iHangMesh[iDraw]);
            set_object_visual_data(0, 0);
        end
    end

    if g_game_logic.get_player_current_state() == player_state.JSVINE or
            g_game_logic.get_player_current_state() == player_state.JSLADDER then
        set_player_is_visible(1);
        return;
    end

    local iPlat = g_game_logic.get_player_current_active_platform_index();
    abs_platform(iPlat);

    if get_script_selected_level_object_extra() == 3 then
        if g_game_logic.get_player_current_state() == player_state.JSROLL then
            g_game_logic.set_player_current_state(player_state.JSNORMAL);
        end

        if g_game_logic.get_player_current_state() == player_state.JSFALLING and
                g_game_logic.get_player_current_state_frame_count() < 40 then
            g_game_logic.set_player_current_state(player_state.JSNORMAL);
        end

        set_player_is_visible(0);
        g_hang_animation_next_frame_counter = g_hang_animation_next_frame_counter + 1;

        if g_hang_animation_next_frame_counter > 4 then
            g_hang_animation_next_frame_counter = 0;
            g_hang_animation_current_frame = g_hang_animation_current_frame + 1;

            if g_hang_animation_current_frame > 4 then
                g_hang_animation_current_frame = 1;
            end
        end

        local iDraw = 0;

        if game_input.move_right_action.is_pressed then
            if get_player_current_position_x() > get_script_selected_level_object_x2() - 3 then
                set_player_current_position_x(get_player_current_position_x() - 1);
            else
                iDraw = g_hang_animation_current_frame;
            end
        elseif game_input.move_left_action.is_pressed then
            if get_player_current_position_x() < get_script_selected_level_object_x1() + 2 then
                set_player_current_position_x(get_player_current_position_x() + 1);
            else
                iDraw = g_hang_animation_current_frame + 10;
            end
        end

        select_object_mesh(iHangMesh[iDraw]);
        script_selected_mesh_set_identity_matrix();
        script_selected_mesh_translate_matrix(
            get_player_current_position_x() + 0,
            get_player_current_position_y() + 2,
            get_player_current_position_z() + 1.5);
        set_object_visual_data(resources.TextureJumpman, 1);
    else
        set_player_is_visible(1);
    end
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    CheckHanging_(game_input);

    for _, baboon in ipairs(baboons) do
        baboon.update();
    end
end

local function FixHangPlatforms_()
    local platform_count = get_platform_object_count();

    for iPlat = 0, platform_count - 1 do
        abs_platform(iPlat);

        if get_script_selected_level_object_extra() == 3 then
            local iY = get_script_selected_level_object_y1();
            set_script_selected_level_object_y1(iY - 11);
            iY = get_script_selected_level_object_y2();
            set_script_selected_level_object_y2(iY - 11);
        end
    end

    iHangMesh[0] = new_mesh(resources.MeshHang);
    prioritize_object();

    iHangMesh[1] = new_mesh(resources.MeshHang1);
    prioritize_object();

    iHangMesh[2] = new_mesh(resources.MeshHang2);
    prioritize_object();

    iHangMesh[3] = new_mesh(resources.MeshHang3);
    prioritize_object();

    iHangMesh[4] = new_mesh(resources.MeshHang4);
    prioritize_object();

    iHangMesh[11] = new_mesh(resources.MeshHangL1);
    prioritize_object();

    iHangMesh[12] = new_mesh(resources.MeshHangL2);
    prioritize_object();

    iHangMesh[13] = new_mesh(resources.MeshHangL3);
    prioritize_object();

    iHangMesh[14] = new_mesh(resources.MeshHangL4);
    prioritize_object();
end

local function StartBaboon_(initial_pos_x, initial_pos_y);
    local new_baboon = baboon_module();
    new_baboon.GameLogic = g_game_logic;
    new_baboon.StartX = initial_pos_x - 2.5;
    new_baboon.StartY = initial_pos_y;
    new_baboon.initialize();
    table.insert(baboons, new_baboon);
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.ResetPlayerCallback = reset;

    g_hud_overlay = hud_overlay_module();

    g_hang_animation_current_frame = 1;

    FixHangPlatforms_();

    set_level_extent_x(260);

    StartBaboon_(76, 170);
    StartBaboon_(207, 90);
    StartBaboon_(138, 70);
    StartBaboon_(187, 30);
    StartBaboon_(227, 60);
    StartBaboon_(177, 120);
    StartBaboon_(32, 160);

    StartBaboon_(64, 60);
    StartBaboon_(84, 70);

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
    set_player_current_position_x(15);
    set_player_current_position_y(6);
    set_player_current_position_z(3);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end
