local read_only = require "Data/read_only";
local baboon_module = loadfile("Data/baboon.lua");

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
}
resources = read_only.make_table_read_only(resources);

local g_is_initialized = false;
local baboons = {};

local g_hang_animation_current_frame;
local g_hang_animation_next_frame_counter = 0;
local iHangMesh = {};

local function StartBaboon(iX, iY);
    local new_baboon = baboon_module();
    new_baboon.StartX = iX - 2.5;
    new_baboon.StartY = iY;
    table.insert(baboons, new_baboon);
end

local function CheckHanging(game_input)
    for iDraw = 0, 19 do
        if iHangMesh[iDraw] and iHangMesh[iDraw] > 0 then
            select_object_mesh(iHangMesh[iDraw]);
            set_object_visual_data(0, 0);
        end
    end

    if get_player_current_state() == player_state.JSVINE or get_player_current_state() == player_state.JSLADDER then
        set_player_is_visible(1);
        return;
    end

    local iPlat = get_script_event_data_2();
    abs_platform(iPlat);

    if get_script_selected_level_object_extra() == 3 then
        if get_player_current_state() == player_state.JSROLL then
            set_player_current_state(player_state.JSNORMAL);
        end

        if get_player_current_state() == player_state.JSFALLING and get_player_current_state_frame_count() < 40 then
            set_player_current_state(player_state.JSNORMAL);
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
        script_selected_mesh_translate_matrix(get_player_current_position_x(), get_player_current_position_y() + 2, get_player_current_position_z() + 1.5);
        set_object_visual_data(resources.TextureJumpman, 1);
    else
        set_player_is_visible(1);
    end
end

local function FixHangPlatforms()
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

function update(game_input)
    if not g_is_initialized then
        g_is_initialized = true;
        g_hang_animation_current_frame = 1;

        FixHangPlatforms();

        set_level_extent_x(260);

        StartBaboon(76, 170);
        StartBaboon(207, 90);
        StartBaboon(138, 70);
        StartBaboon(187, 30);
        StartBaboon(227, 60);
        StartBaboon(177, 120);
        StartBaboon(32, 160);

        StartBaboon(64, 60);
        StartBaboon(84, 70);
    end

    CheckHanging(game_input);

    for _, baboon in ipairs(baboons) do
        baboon.update();
    end
end

function reset()
    set_player_current_position_x(15);
    set_player_current_position_y(6);
    set_player_current_position_z(3);
    set_player_current_state(player_state.JSNORMAL);
end
