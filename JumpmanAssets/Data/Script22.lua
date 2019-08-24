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
}
resources = make_read_only(resources);

local g_is_initialized = false;

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

function update()
    if not g_is_initialized then
        g_is_initialized = true;

        set_level_extent_x(200);

        for iLoop = 1, 9 do
            select_platform(iLoop);
            SetPlatformData(iLoop);
        end

        g_small_gears_background_mesh_index = new_mesh(resources.MeshSphere);
        g_large_gears_background_mesh_index = new_mesh(resources.MeshSphere);
    end

    g_animation_frame = g_animation_frame + 1;

    local iNX = cos((g_animation_frame * 2 / 3) + 180) * 4300 / 100 + 80;
    local iNY = sin((g_animation_frame * 2 / 3) + 180) * 4300 / 100 + 80;
    SetPosition(6, iNX, iNY + 3);
    DisplayPlatform(6);

    iNX = cos(g_animation_frame * 2 / 3) * 4300 / 100 + 80;
    iNY = sin(g_animation_frame * 2 / 3) * 4300 / 100 + 80;
    SetPosition(1, iNX, iNY + 3);
    DisplayPlatform(1);

    iNX = cos((0 - g_animation_frame) + 180) * 2100 / 100 + 80;
    iNY = sin((0 - g_animation_frame) + 180) * 2100 / 100 + 80;
    SetPosition(7, iNX, iNY + 3);
    DisplayPlatform(7);

    iNX = cos(0 - g_animation_frame) * 2100 / 100 + 80;
    iNY = sin(0 - g_animation_frame) * 2100 / 100 + 80;
    SetPosition(2, iNX, iNY + 3);
    DisplayPlatform(2);

    iNX = Cycle(g_animation_frame, 5.5, 12, 76);
    iNY = Cycle(g_animation_frame, 5.5, 175, 191);
    SetPosition(8, iNX, iNY);
    DisplayPlatform(8);

    iNX = Cycle(g_animation_frame, 4.6, 97, 152);
    iNY = Cycle(0 - g_animation_frame, 4.6, 188, 196);
    SetPosition(9, iNX, iNY);
    DisplayPlatform(9);

    iNX = 145;
    iNY = Cycle(g_animation_frame, 3, 28, 113);
    SetPosition(3, iNX, iNY);
    DisplayPlatform(3);

    iNX = Cycle(g_animation_frame, 4.9, 66, 125);
    iNY = 145;
    SetPosition(4, iNX, iNY);
    DisplayPlatform(4);

    iNX = Cycle(g_animation_frame, 6, 4, 58);
    iNY = 155;
    SetPosition(5, iNX, iNY);
    DisplayPlatform(5);

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
end

function Cycle(iCCount, iSpeed, iMin, iMax)
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

function SetPosition(iNum, iNX, iNY)
    local iLX;
    local iLY;

    iLX = g_platforms_original_x2[iNum] - g_platforms_original_x1[iNum];
    iLY = g_platforms_original_y2[iNum] - g_platforms_original_y1[iNum];

    g_platforms_x1[iNum] = iNX - iLX / 2;
    g_platforms_x2[iNum] = iNX + iLX / 2;

    g_platforms_y1[iNum] = iNY - iLY / 2;
    g_platforms_y2[iNum] = iNY + iLY / 2;
end

function SetPlatformData(iNum)
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

function DisplayPlatform(iNum)
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

    if get_script_event_data_2() == g_platform_numbers[iNum] then
        local iPX = get_player_current_position_x();
        local iPY = get_player_current_position_y();
        set_player_current_position_x(iPX + iDX);

        if get_player_current_state() == player_state.JSNORMAL then
            local iHeight = g_platforms_y1[iNum];

            if iHeight > iPY - 1 and iHeight < iPY + 2 then
                set_player_current_position_y(iHeight);
            end
        end
    end
end

function reset()
    set_player_current_position_x(150);
    set_player_current_position_y(7);
    set_player_current_position_z(3);
    set_player_current_state(player_state.JSNORMAL);
end
