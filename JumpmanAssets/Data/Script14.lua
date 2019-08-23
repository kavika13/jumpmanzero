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

-- TODO: Move this into a shared file, split into separate tables by type
local camera_mode = {
    PerspectiveNormal = 0,
    PerspectiveCloseUp = 1,
    PerspectiveFar = 2,
    PerspectiveWide = 3,
    PerspectiveFollow = 4,
    PerspectiveFixed = 5,
}
camera_mode = make_read_only(camera_mode);

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureJumpman = 0,
    TextureClassicPlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    ScriptBullet = 0,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    TextureBullet = 5,
    TextureGrid = 6,
    ScriptBlock = 1,
    MeshGoo = 2,
    ScriptBFormat = 2,
    TextureBoringBlue = 7,
    TextureBoringBlush = 8,
    TextureBoringGray = 9,
    TextureBoringGreen = 10,
    TextureBoringOrange = 11,
    TextureBoringPink = 12,
    TextureBoringPurple = 13,
    TextureBoringRed = 14,
    TextureBoringYellow = 15,
}
resources = make_read_only(resources);

-- TODO: Separate file?
local block_properties = {
    BlockIInit = 0,
    BlockTexture = 1,
    BlockIMesh = 2,
    BlockIX = 8,
    BlockIY = 14,
    BlockIMyPlat = 20,
    BlockIStatus = 21,
    BlockHung = 22,
    BlockICount = 23,
}
block_properties = make_read_only(block_properties);

-- TODO: Separate file?
-- TODO: Rename this struct and the properties to something less confusing
local puzzle_properties = {
    BFormatGenerated = 0,
    BFormatColor = 1,
    BFormatCopy = 57,
    BFormatTemp = 113,
    BFormatITWidth = 130,
    BFormatITHeight = 131,
    BFormatIBlockNumber = 132,
}
puzzle_properties = make_read_only(puzzle_properties);

-- TODO: Separate file?
local bullet_properties = {
    BulletIFiring = 0,
    BulletResMesh1 = 1,
    BulletResMesh2 = 2,
    BulletResTexture = 3,
    BulletIInit = 4,
    BulletIX = 5,
    BulletIY = 6,
    BulletIZ = 7,
    BulletIXV = 8,
    BulletIYV = 9,
    BulletIMesh1 = 10,
    BulletIMesh2 = 11,
    BulletISlow = 12,
    BulletIOut = 13,
    BulletISpin1 = 14,
    BulletISpin2 = 15,
    BulletWait = 16,
    BulletIMaxx = 17,
}
bullet_properties = make_read_only(bullet_properties);

local g_init_stage_index = 0;
local g_puzzle_object_index;  -- TODO: What is "b format"?
local g_block_object_indices = {};
local kNUM_BLOCKS = 9;

function update()
    if g_init_stage_index == 3 then
        g_init_stage_index = 4;
        ResetBlocks();
    end

    if g_init_stage_index == 2 then
        g_init_stage_index = 3;
        select_donut(2);
        set_script_selected_level_object_visible(0);
        g_puzzle_object_index = spawn_object(resources.ScriptBFormat);

        local bullet_object_index = spawn_object(resources.ScriptBullet);
        set_object_global_data(bullet_object_index, bullet_properties.BulletWait, 100);
        set_object_global_data(bullet_object_index, bullet_properties.BulletResMesh1, resources.MeshBullet1);
        set_object_global_data(bullet_object_index, bullet_properties.BulletResMesh2, resources.MeshBullet2);
        set_object_global_data(bullet_object_index, bullet_properties.BulletResTexture, resources.TextureBullet);

        for iTemp = 1, kNUM_BLOCKS do
            g_block_object_indices[iTemp] = spawn_object(resources.ScriptBlock);
        end
    end

    if g_init_stage_index == 1 then
        g_init_stage_index = 2;
    end

    if g_init_stage_index == 0 then
        g_init_stage_index = 1;
        set_current_camera_mode(camera_mode.PerspectiveFar);
    end
end

function ResetBlocks()
    for iTemp = 1, kNUM_BLOCKS do
        GenerateBlock(iTemp);
    end
end

function GenerateBlock(iNum)
    local iPartNum = 1;
    local iNew = g_block_object_indices[iNum];

    for iX = 1, 9 do
        for iY = 1, 4 do
            local iCol = get_object_global_data(g_puzzle_object_index, puzzle_properties.BFormatColor + iX + iY * 11);

            if iCol == iNum then
                set_object_global_data(iNew, block_properties.BlockIX + iPartNum, iX - 1);
                set_object_global_data(iNew, block_properties.BlockIY + iPartNum, iY - 1);
                set_object_global_data(iNew, block_properties.BlockIStatus, 0);
                set_object_global_data(iNew, block_properties.BlockHung, 0)
                set_object_global_data(iNew, block_properties.BlockTexture, GetColor(iNum));
                iPartNum = iPartNum + 1;
            end
        end
    end
end

function CheckForWin()
    for iTest = 1, 9 do
        for iLoop = 1, 4 do
            local iY = get_object_global_data(g_block_object_indices[iTest], block_properties.BlockIY + iLoop);
            -- TODO: Debug print function? print(-2);
            -- TODO: Debug print function? print(iY);

            if iY > 3 then
                return false;
            end
        end
    end

    return true;
end

function on_collect_donut()
    if CheckForWin() then
        win();
        return;
    end

    local iDonut = get_script_event_data_1();

    if iDonut == 1 then
        select_donut(2);
        set_script_selected_level_object_visible(1);
    end

    if iDonut == 2 then
        select_donut(1);
        set_script_selected_level_object_visible(1);
    end

    set_object_global_data(g_puzzle_object_index, puzzle_properties.BFormatGenerated, 0);
    g_init_stage_index = 3;
end

function GetColor(iNum)
    return resources.TextureBoringBlue + iNum - 1;
end

function reset()
    set_player_current_position_x(8);
    set_player_current_position_y(5);
    set_player_current_position_z(3);
    set_player_current_state(player_state.JSNORMAL);
end
