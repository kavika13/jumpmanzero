local read_only = require "Data/read_only";
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));

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
    TextureBrick = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureFactory = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    ScriptBullet = 0,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    TextureBullet = 5,
    MeshSphere = 2,
    TextureBoringGray = 6,
    MeshGoo = 3,
    TextureHarle = 7,
    TextureDullGold = 8,
};
resources = read_only.make_table_read_only(resources);

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;

local g_platform_numbers = {};
local g_platforms_x1 = {};
local g_platforms_y1 = {};
local g_platforms_x2 = {};
local g_platforms_y2 = {};

local g_platforms_original_x1 = {};
local g_platforms_original_y1 = {};
local g_platforms_original_x2 = {};
local g_platforms_original_y2 = {};

local g_platforms_previous_x1 = {};
local g_platforms_previous_y1 = {};

local g_animation_frame = 0;

local g_small_gears_background_mesh_index;
local g_large_gears_background_mesh_index;

function Cycle_(iCCount, iSpeed, iMin, iMax)
    local is_negative = false;

    if iCCount < 0 then
        is_negative = true;
        iCCount = 0 - iCCount;
    end

    local iCycle = iMax - iMin;
    local iCP = math.floor(iCCount * iSpeed) & 1023;
    local iPlace = ((iCP / 128) * iCycle) / 4;

    if is_negative then
        iPlace = iPlace + iCycle;

        if iPlace > iCycle * 2 then
            iPlace = iPlace - iCycle * 2;
        end
    end

    if iPlace > iCycle then
        iPlace = iCycle * 2 - iPlace;
    end

    iPlace = iPlace + iMin;

    return iPlace;
end

function SetPosition_(iNum, iNX, iNY)
    local iLX;
    local iLY;

    iLX = g_platforms_original_x2[iNum] - g_platforms_original_x1[iNum];
    iLY = g_platforms_original_y2[iNum] - g_platforms_original_y1[iNum];

    g_platforms_x1[iNum] = iNX - iLX / 2;
    g_platforms_x2[iNum] = iNX + iLX / 2;

    g_platforms_y1[iNum] = iNY - iLY / 2;
    g_platforms_y2[iNum] = iNY + iLY / 2;
end

local function DisplayPlatform_(iNum)
    abs_platform(g_platform_numbers[iNum]);
    set_script_selected_level_object_x1(g_platforms_x1[iNum]);
    set_script_selected_level_object_x2(g_platforms_x2[iNum]);
    set_script_selected_level_object_y1(g_platforms_y1[iNum]);
    set_script_selected_level_object_y2(g_platforms_y2[iNum]);

    local iDX = g_platforms_x1[iNum] - g_platforms_original_x1[iNum];
    local iDY = g_platforms_y1[iNum] - g_platforms_original_y1[iNum];

    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_translate_matrix(iDX, iDY, 0);

    iDX = g_platforms_x1[iNum] - g_platforms_previous_x1[iNum];
    iDY = g_platforms_y1[iNum] - g_platforms_previous_y1[iNum];

    g_platforms_previous_x1[iNum] = g_platforms_x1[iNum];
    g_platforms_previous_y1[iNum] = g_platforms_y1[iNum];

    if g_game_logic.get_player_current_active_platform_index() == g_platform_numbers[iNum] then
        local iPX = g_game_logic.get_player_current_position_x();
        local iPY = g_game_logic.get_player_current_position_y();
        g_game_logic.set_player_current_position_x(iPX + iDX);

        if g_game_logic.get_player_current_state() == player_state.JSNORMAL then
            local iHeight = g_platforms_y1[iNum];

            if iHeight > iPY - 1 and iHeight < iPY + 2 then
                g_game_logic.set_player_current_position_y(iHeight);
            end
        end
    end
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    g_animation_frame = g_animation_frame + 1;

    local iNX = math.cos(((g_animation_frame * 2 / 3) + 180) * math.pi / 180.0) * 43 + 80;
    local iNY = math.sin(((g_animation_frame * 2 / 3) + 180) * math.pi / 180.0) * 43 + 80;
    SetPosition_(6, iNX, iNY + 3);
    DisplayPlatform_(6);

    iNX = math.cos(g_animation_frame * 2 / 3 * math.pi / 180.0) * 43 + 80;
    iNY = math.sin(g_animation_frame * 2 / 3 * math.pi / 180.0) * 43 + 80;
    SetPosition_(1, iNX, iNY + 3);
    DisplayPlatform_(1);

    iNX = math.cos(((0 - g_animation_frame) + 180) * math.pi / 180.0) * 21 + 80;
    iNY = math.sin(((0 - g_animation_frame) + 180) * math.pi / 180.0) * 21 + 80;
    SetPosition_(7, iNX, iNY + 3);
    DisplayPlatform_(7);

    iNX = math.cos((0 - g_animation_frame) * math.pi / 180.0) * 21 + 80;
    iNY = math.sin((0 - g_animation_frame) * math.pi / 180.0) * 21 + 80;
    SetPosition_(2, iNX, iNY + 3);
    DisplayPlatform_(2);

    iNX = Cycle_(g_animation_frame, 5.5, 12, 76);
    iNY = Cycle_(g_animation_frame, 5.5, 175, 191);
    SetPosition_(8, iNX, iNY);
    DisplayPlatform_(8);

    iNX = Cycle_(g_animation_frame, 4.6, 97, 152);
    iNY = Cycle_(0 - g_animation_frame, 4.6, 188, 196);
    SetPosition_(9, iNX, iNY);
    DisplayPlatform_(9);

    iNX = 145;
    iNY = Cycle_(g_animation_frame, 3, 28, 113);
    SetPosition_(3, iNX, iNY);
    DisplayPlatform_(3);

    iNX = Cycle_(g_animation_frame, 4.9, 66, 125);
    iNY = 145;
    SetPosition_(4, iNX, iNY);
    DisplayPlatform_(4);

    iNX = Cycle_(g_animation_frame, 6, 4, 58);
    iNY = 155;
    SetPosition_(5, iNX, iNY);
    DisplayPlatform_(5);

    select_object_mesh(g_small_gears_background_mesh_index);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_rotate_matrix_z(0 - g_animation_frame);
    script_selected_mesh_scale_matrix(25, 25, 2);
    script_selected_mesh_translate_matrix(80, 80, 7);
    set_object_visual_data(resources.TextureBoringGray, 1);

    select_object_mesh(g_large_gears_background_mesh_index);
    script_selected_mesh_set_identity_matrix();
    script_selected_mesh_rotate_matrix_z(g_animation_frame * 2 / 3);
    script_selected_mesh_scale_matrix(50, 50, 2);
    script_selected_mesh_translate_matrix(80, 80, 9);
    set_object_visual_data(resources.TextureBoringGray, 1);

    g_game_logic.update_player_graphics();
end

function SetPlatformData_(iNum)
    g_platform_numbers[iNum] = get_script_selected_level_object_this();
    g_platforms_x1[iNum] = get_script_selected_level_object_x1();
    g_platforms_x2[iNum] = get_script_selected_level_object_x2();
    g_platforms_y1[iNum] = get_script_selected_level_object_y1();
    g_platforms_y2[iNum] = get_script_selected_level_object_y2();

    g_platforms_original_x1[iNum] = get_script_selected_level_object_x1();
    g_platforms_original_y1[iNum] = get_script_selected_level_object_y1();
    g_platforms_original_x2[iNum] = get_script_selected_level_object_x2();
    g_platforms_original_y2[iNum] = get_script_selected_level_object_y2();

    g_platforms_previous_x1[iNum] = get_script_selected_level_object_x1();
    g_platforms_previous_y1[iNum] = get_script_selected_level_object_y1();
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.ResetPlayerCallback = reset;

    g_hud_overlay = hud_overlay_module();

    set_level_extent_x(200);

    for iLoop = 1, 9 do
        select_platform(iLoop);
        SetPlatformData_(iLoop);
    end

    g_small_gears_background_mesh_index = new_mesh(resources.MeshSphere);
    g_large_gears_background_mesh_index = new_mesh(resources.MeshSphere);

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
    g_game_logic.set_player_current_position_x(150);
    g_game_logic.set_player_current_position_y(7);
    g_game_logic.set_player_current_position_z(3);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end
