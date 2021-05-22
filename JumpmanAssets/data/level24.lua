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

local jumpman_hang_animation_frame = {
    HANG_NEUTRAL = 0,

    HANG_RIGHT_META_BASE = 0,  -- Not an actual frame
    HANG_RIGHT_1 = 1,
    HANG_RIGHT_2 = 2,
    HANG_RIGHT_3 = 3,
    HANG_RIGHT_4 = 4,

    HANG_LEFT_META_BASE = 10,  -- Not an actual frame
    HANG_LEFT_1 = 11,
    HANG_LEFT_2 = 12,
    HANG_LEFT_3 = 13,
    HANG_LEFT_4 = 14,
};
jumpman_hang_animation_frame = read_only.make_table_read_only(jumpman_hang_animation_frame);

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local baboons = {};

local g_hang_animation_current_frame;
local g_hang_animation_next_frame_counter = 0;
local g_jumpman_hang_animation_mesh_indices = {};
local g_jumpman_hang_mesh_index = -1;
local g_jumpman_hang_transform_index = -1;

local function CheckHanging_(game_input)
    -- TODO: Animate base player mesh instead of hiding the player mesh and displaying an alternate one?
    set_mesh_is_visible(g_jumpman_hang_mesh_index, false);

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
                    g_hang_animation_current_frame = jumpman_hang_animation_frame.HANG_RIGHT_META_BASE + 1;
                end
            end

            local actual_hang_animation_frame = jumpman_hang_animation_frame.HANG_NEUTRAL;

            if game_input.move_right_action.is_pressed then
                if g_game_logic.get_player_current_position_x() > player_platform.pos_lower_right[1] - 3 then
                    g_game_logic.set_player_current_position_x(g_game_logic.get_player_current_position_x() - 1);
                else
                    actual_hang_animation_frame = g_hang_animation_current_frame;
                end
            elseif game_input.move_left_action.is_pressed then
                if g_game_logic.get_player_current_position_x() < player_platform.pos_upper_left[1] + 2 then
                    g_game_logic.set_player_current_position_x(g_game_logic.get_player_current_position_x() + 1);
                else
                    actual_hang_animation_frame = jumpman_hang_animation_frame.HANG_LEFT_META_BASE + g_hang_animation_current_frame;
                end
            end

            set_mesh_to_mesh(g_jumpman_hang_mesh_index, g_jumpman_hang_animation_mesh_indices[actual_hang_animation_frame]);
            transform_set_translation(
                g_jumpman_transform_index,
                g_game_logic.get_player_current_position_x() + 0,
                g_game_logic.get_player_current_position_y() + 2,
                g_game_logic.get_player_current_position_z() + 1.5);
            set_mesh_is_visible(g_jumpman_hang_mesh_index, true);

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

    g_jumpman_hang_animation_mesh_indices[jumpman_hang_animation_frame.HANG_NEUTRAL] = resources.MeshHang;
    g_jumpman_hang_animation_mesh_indices[jumpman_hang_animation_frame.HANG_RIGHT_1] = resources.MeshHang1;
    g_jumpman_hang_animation_mesh_indices[jumpman_hang_animation_frame.HANG_RIGHT_2] = resources.MeshHang2;
    g_jumpman_hang_animation_mesh_indices[jumpman_hang_animation_frame.HANG_RIGHT_3] = resources.MeshHang3;
    g_jumpman_hang_animation_mesh_indices[jumpman_hang_animation_frame.HANG_RIGHT_4] = resources.MeshHang4;
    g_jumpman_hang_animation_mesh_indices[jumpman_hang_animation_frame.HANG_LEFT_1] = resources.MeshHangL1;
    g_jumpman_hang_animation_mesh_indices[jumpman_hang_animation_frame.HANG_LEFT_2] = resources.MeshHangL2;
    g_jumpman_hang_animation_mesh_indices[jumpman_hang_animation_frame.HANG_LEFT_3] = resources.MeshHangL3;
    g_jumpman_hang_animation_mesh_indices[jumpman_hang_animation_frame.HANG_LEFT_4] = resources.MeshHangL4;

    g_jumpman_hang_mesh_index = new_mesh(g_jumpman_hang_animation_mesh_indices[jumpman_hang_animation_frame.HANG_NEUTRAL]);
    g_jumpman_transform_index = transform_create();
    object_set_transform(g_jumpman_hang_mesh_index, g_jumpman_transform_index);
    set_mesh_texture(g_jumpman_hang_mesh_index, resources.TextureJumpman);
end

local function StartBaboon_(initial_pos_x, initial_pos_y);
    local new_baboon = baboon_module();
    new_baboon.GameLogic = g_game_logic;
    new_baboon.BaboonClimbMeshResourceIndices = {
        resources.MeshBaboon, resources.MeshBaboon1, resources.MeshBaboon2, resources.MeshBaboon3, resources.MeshBaboon4,
    };
    new_baboon.BaboonTextureResourceIndex = resources.TextureBaboon;
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

    g_hang_animation_current_frame = jumpman_hang_animation_frame.HANG_RIGHT_1;

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
