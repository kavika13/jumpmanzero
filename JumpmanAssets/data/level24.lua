local read_only = require "data/read_only";
local level24_data_module = assert(loadfile("data/level24_data.lua"));
local game_logic_module = assert(loadfile("data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("data/hud_overlay.lua"));
local baboon_module = assert(loadfile("data/baboon.lua"));

local Module = {};

Module.MenuLogic = nil;

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
            set_mesh_is_visible(iHangMesh[iDraw], false);
        end
    end

    if g_game_logic.get_player_current_state() == player_state.JSVINE or
            g_game_logic.get_player_current_state() == player_state.JSLADDER then
        g_game_logic.set_player_is_visible(true);
        return;
    end

    local platform_index = g_game_logic.get_player_current_active_platform_index();

    if platform_index ~= -1 then
        local player_platform = g_game_logic.get_platform(platform_index);

        if player_platform.extra == 3 then
            if g_game_logic.get_player_current_state() == player_state.JSROLL then
                g_game_logic.set_player_current_state(player_state.JSNORMAL);
            end

            if g_game_logic.get_player_current_state() == player_state.JSFALLING and
                    g_game_logic.get_player_current_state_frame_count() < 40 then
                g_game_logic.set_player_current_state(player_state.JSNORMAL);
            end

            g_game_logic.set_player_is_visible(false);
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
                if g_game_logic.get_player_current_position_x() > player_platform.pos_lower_right[1] - 3 then
                    g_game_logic.set_player_current_position_x(g_game_logic.get_player_current_position_x() - 1);
                else
                    iDraw = g_hang_animation_current_frame;
                end
            elseif game_input.move_left_action.is_pressed then
                if g_game_logic.get_player_current_position_x() < player_platform.pos_upper_left[1] + 2 then
                    g_game_logic.set_player_current_position_x(g_game_logic.get_player_current_position_x() + 1);
                else
                    iDraw = g_hang_animation_current_frame + 10;
                end
            end

            set_identity_mesh_matrix(iHangMesh[iDraw]);
            translate_mesh_matrix(
                iHangMesh[iDraw],
                g_game_logic.get_player_current_position_x() + 0,
                g_game_logic.get_player_current_position_y() + 2,
                g_game_logic.get_player_current_position_z() + 1.5);
            set_mesh_is_visible(iHangMesh[iDraw], true);

            return;
        end
    end

    g_game_logic.set_player_is_visible(true);  -- Player is not hanging
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

    g_game_logic.update_player_graphics();
end

local function FixHangPlatforms_()
    local platform_count = g_game_logic.get_platform_object_count();

    for platform_index = 0, platform_count - 1 do
        local current_platform = g_game_logic.get_platform(platform_index);

        if current_platform.extra == 3 then
            current_platform.set_pos_y(current_platform.pos_lower_right[2] - 11, current_platform.pos_upper_left[2] - 11);
        end
    end

    iHangMesh[0] = new_mesh(resources.MeshHang);
    move_mesh_to_front(iHangMesh[0]);

    iHangMesh[1] = new_mesh(resources.MeshHang1);
    move_mesh_to_front(iHangMesh[1]);

    iHangMesh[2] = new_mesh(resources.MeshHang2);
    move_mesh_to_front(iHangMesh[2]);

    iHangMesh[3] = new_mesh(resources.MeshHang3);
    move_mesh_to_front(iHangMesh[3]);

    iHangMesh[4] = new_mesh(resources.MeshHang4);
    move_mesh_to_front(iHangMesh[4]);

    iHangMesh[11] = new_mesh(resources.MeshHangL1);
    move_mesh_to_front(iHangMesh[11]);

    iHangMesh[12] = new_mesh(resources.MeshHangL2);
    move_mesh_to_front(iHangMesh[12]);

    iHangMesh[13] = new_mesh(resources.MeshHangL3);
    move_mesh_to_front(iHangMesh[13]);

    iHangMesh[14] = new_mesh(resources.MeshHangL4);
    move_mesh_to_front(iHangMesh[14]);

    for i = 0, 4 do  -- TODO: Don't hard-code animation frame indices
        set_mesh_texture(iHangMesh[i], resources.TextureJumpman);
    end

    for i = 11, 14 do  -- TODO: Don't hard-code animation frame indices
        set_mesh_texture(iHangMesh[i], resources.TextureJumpman);
    end
end

local function StartBaboon_(initial_pos_x, initial_pos_y);
    local new_baboon = baboon_module();
    new_baboon.GameLogic = g_game_logic;
    new_baboon.StartX = initial_pos_x - 2.5;
    new_baboon.StartY = initial_pos_y;
    new_baboon.initialize();
    table.insert(baboons, new_baboon);
end

function Module.initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = level24_data_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.MenuLogic = Module.MenuLogic;
    g_hud_overlay.GameLogic = g_game_logic;

    g_hang_animation_current_frame = 1;

    FixHangPlatforms_();

    g_game_logic.set_level_extent_x(260);

    StartBaboon_(76, 170);
    StartBaboon_(207, 90);
    StartBaboon_(138, 70);
    StartBaboon_(187, 30);
    StartBaboon_(227, 60);
    StartBaboon_(177, 120);
    StartBaboon_(32, 160);

    StartBaboon_(64, 60);
    StartBaboon_(84, 70);

    Module.reset();

    -- Make sure staged initialization has happened, and Jumpman has floated to the floor
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
end

function Module.update(game_input)
    if not g_title_is_done_scrolling then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return;
    end

    ProgressLevel_(game_input);
end

function Module.reset()
    g_game_logic.set_player_current_position_x(15);
    g_game_logic.set_player_current_position_y(6);
    g_game_logic.set_player_current_position_z(3);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end

return Module;