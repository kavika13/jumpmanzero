local read_only = require "data/read_only";
local ending_data_module = assert(loadfile("data/ending_data.lua"));
local game_logic_module = assert(loadfile("data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("data/hud_overlay.lua"));
local end_alien_module = assert(loadfile("data/end_alien.lua"));
local credits_module = assert(loadfile("data/credits.lua"));

local Module = {};

Module.MenuLogic = nil;
Module.SkipToCredits = false;

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

-- TODO: Move this into a shared file, split into separate tables by type
local camera_mode = {
    PerspectiveNormal = 0,
    PerspectiveCloseUp = 1,
    PerspectiveFar = 2,
    PerspectiveWide = 3,
    PerspectiveFollow = 4,
    PerspectiveFixed = 5,
};
camera_mode = read_only.make_table_read_only(camera_mode);

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureJumpman = 0,
    TextureSpacePlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureSpaceBack = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    MeshDance1 = 0,
    MeshDance2 = 1,
    MeshDance3 = 2,
    MeshDance4 = 3,
    MeshDance5 = 4,
    MeshDiveLeft = 5,
    MeshRollLeft1 = 6,
    MeshRollLeft2 = 7,
    MeshRollLeft3 = 8,
    MeshRollLeft4 = 9,
    TextureFur = 5,
    MeshFyStand = 10,
    MeshFyFlopR = 11,
    MeshFyFR2 = 12,
    MeshFyLeft1 = 13,
    MeshFyLeft2 = 14,
    MeshFySR1 = 15,
    MeshFySR2 = 16,
    MeshSheepJR1 = 17,
    MeshSheepJR2 = 18,
    MeshSheepJR3 = 19,
    MeshSheepR1 = 20,
    MeshSheepR2 = 21,
    TextureSheep = 6,
    MeshTurtGR1 = 22,
    MeshTurtGR2 = 23,
    MeshTurtS1 = 24,
    TextureTurtleTexture = 7,
    MeshRunDonut1 = 25,
    MeshRunDonut2 = 26,
    MeshRunDonut3 = 27,
    MeshRunDonutHatch1 = 28,
    MeshRunDonutHatch2 = 29,
    MeshRunDonutHatch3 = 30,
    MeshRunDonutHatch4 = 31,
    MeshRunDonutHatch5 = 32,
    TextureRunDonut = 8,
    MeshTSaurWalkR1 = 33,
    MeshTSaurWalkR2 = 34,
    MeshTSaurWalkR3 = 35,
    MeshTSaurWalkR4 = 36,
    MeshTSaurYR1 = 37,
    MeshTSaurYR2 = 38,
    MeshTSaurYR3 = 39,
    MeshTSaurYR4 = 40,
    TextureDinosaur = 9,
    MeshAlien1 = 41,
    MeshAlien2 = 42,
    MeshCube = 43,
    MeshShipBase = 44,
    MeshShipTop = 45,
    TextureShipMetal = 10,
    TextureShipGlass = 11,
    TextureAlien = 12,
    ScriptEndAlien = 0,
    MeshJumpRight = 46,
    MeshKickRight = 47,
    MeshRight1 = 48,
    MeshRight2 = 49,
    TextureDABotO = 13,
    MeshRocket = 50,
    MeshSquare = 51,
    TextureBlast1 = 14,
    ScriptCredits = 1,
    TextureBlack = 15,
};
resources = read_only.make_table_read_only(resources);

local g_is_first_update_complete = false;
local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_end_alien;
local g_credits;

local g_object_mesh_indices = {};
local g_object_transform_indices = {};
local g_time_since_level_start = 0;

local g_current_pos_x = 0;
local g_current_pos_y = 0;

local function ClearAll_()
    g_game_logic.set_player_current_position_x(0);
    g_game_logic.set_player_is_visible(false);

    for iTemp = 0, 19 do
        set_mesh_is_visible(g_object_mesh_indices[iTemp], false);
    end
end

local function ShowPlayerStanding_(iAT)
    g_game_logic.set_player_is_visible(true);
    g_game_logic.set_player_current_position_x(80);
    g_game_logic.skip_player_next_mesh_interpolation();
end

local function Cycle_(iCCount, iSpeed, iMin, iMax)
    local iNeg = false;

    if iCCount < 0 then
        iNeg = true;
        iCCount = 0 - iCCount;
    end

    local iCycle = (iMax - iMin) + 1;
    local iCP = math.floor(iCCount * iSpeed) & 1023;
    local iPlace = ((iCP / 128) * iCycle) / 4;

    if iNeg then
        iPlace = iPlace + iCycle;

        if iPlace > iCycle * 2 then
            iPlace = iPlace - iCycle * 2;
        end
    end

    if iPlace > iCycle then
        iPlace = iCycle * 2 - iPlace;
    end

    iPlace = math.floor(iPlace + iMin) & 511;

    if iPlace < iMin then
        iPlace = iMin;
    elseif iPlace > iMax then
        iPlace = iMax;
    end

    return iPlace;
end

local g_first_show_player_grooving = true;

local function ShowPlayerGrooving_(iAT)
    local iFrame = Cycle_(iAT, 30, 0, 4);
    local iWiggle = Cycle_(iAT, 30, 0, 4) / 3;

    iFrame = resources.MeshDance1 + iFrame;
    set_mesh_to_mesh(g_object_mesh_indices[1], iFrame);
    transform_set_to_identity(g_object_transform_indices[1][1]);
    transform_set_translation(g_object_transform_indices[1][1], 80 + iWiggle, 85, 1.5);
    set_mesh_texture(g_object_mesh_indices[1], resources.TextureJumpman);
    set_mesh_is_visible(g_object_mesh_indices[1], true);

    if g_first_show_player_grooving then
        skip_next_mesh_interpolation(g_object_mesh_indices[1]);
    end

    g_first_show_player_grooving = false;
end

local g_first_show_player_leaving = true;

local function ShowPlayerLeaving_(iAT)
    local iFrame = 0;

    if iAT < 6 then
        iFrame = resources.MeshDiveLeft;
    else
        iFrame = Cycle_(iAT, 90, 0, 3);
        iFrame = resources.MeshRollLeft1 + iFrame;
    end

    set_mesh_to_mesh(g_object_mesh_indices[1], iFrame);
    transform_set_to_identity(g_object_transform_indices[1][1]);
    transform_set_translation(g_object_transform_indices[1][1], 80 - iAT, 85, 1.5);
    set_mesh_texture(g_object_mesh_indices[1], resources.TextureJumpman);
    set_mesh_is_visible(g_object_mesh_indices[1], true);

    if g_first_show_player_leaving then
        skip_next_mesh_interpolation(g_object_mesh_indices[1]);
    end

    g_first_show_player_leaving = false;
end

local g_first_show_bear = true;

local function ShowBear_(iAT)
    local iFrame = 0;

    if iAT == 0 then
        g_current_pos_x = 75;
        g_current_pos_y = 115;
    end

    if iAT < 30 then
        iFrame = resources.MeshFyFR2;
        g_current_pos_x = g_current_pos_x + 0.3;
        g_current_pos_y = g_current_pos_y - 1;
    elseif iAT < 84 then
        iFrame = resources.MeshFyFlopR;
    elseif iAT < 163 then
        iFrame = Cycle_(iAT, 90, 0, 2);

        if iFrame == 0 then
            iFrame = resources.MeshFySR1;
        elseif iFrame == 1 then
            iFrame = resources.MeshFyStand;
        elseif iFrame == 2 then
            iFrame = resources.MeshFySR2;
        end
    else
        if iAT > 168 then
            g_current_pos_x = g_current_pos_x - 0.5;
        end

        iFrame = Cycle_(iAT, 70, 0, 1);
        iFrame = resources.MeshFyLeft1 + iFrame;
    end

    set_mesh_to_mesh(g_object_mesh_indices[1], iFrame);
    transform_set_to_identity(g_object_transform_indices[1][1]);
    transform_set_scale(g_object_transform_indices[1][1], 1, 1, 1.3);
    transform_set_translation(g_object_transform_indices[1][1], g_current_pos_x, g_current_pos_y + 7, 1.5);
    set_mesh_texture(g_object_mesh_indices[1], resources.TextureFur);
    set_mesh_is_visible(g_object_mesh_indices[1], true);

    if g_first_show_bear then
        skip_next_mesh_interpolation(g_object_mesh_indices[1]);
    end

    g_first_show_bear = false;
end

local g_first_show_sheep = true;

local function ShowSheep_(iAT)
    if iAT == 0 then
        g_current_pos_x = 60;
    end

    g_current_pos_x = g_current_pos_x + 0.5;

    local iFrame = 0;

    for iSheep = 0, 3 do
        local iSheepX = g_current_pos_x - iSheep * 18;
        local iSheepY = 87;

        if iSheepX < 93 then
            iFrame = Cycle_(iAT, 90, 0, 1) + resources.MeshSheepR1;
        elseif iSheepX < 97 then
            iFrame = resources.MeshSheepJR1;
            iSheepY = iSheepY + (iSheepX - 93) / 2;
        elseif iSheepX < 101 then
            iFrame = resources.MeshSheepJR2;
            iSheepY = iSheepY + 2;
        elseif iSheepX < 115 then
            iFrame = resources.MeshSheepJR2;
            iSheepY = iSheepY + 2 - (iSheepX - 101);
        else
            iFrame = resources.MeshSheepJR2;
            iSheepY = iSheepY + 2 - (iSheepX - 101);
            iSheepY = iSheepY - (iSheepX - 115) / 2;
        end

        set_mesh_to_mesh(g_object_mesh_indices[iSheep], iFrame);
        transform_set_to_identity(g_object_transform_indices[iSheep][1]);
        transform_set_translation(g_object_transform_indices[iSheep][1], iSheepX, iSheepY, 2);
        set_mesh_texture(g_object_mesh_indices[iSheep], resources.TextureSheep);
        set_mesh_is_visible(g_object_mesh_indices[iSheep], true);

        if g_first_show_sheep then
            skip_next_mesh_interpolation(g_object_mesh_indices[iSheep]);
        end
    end

    g_first_show_sheep = false;
end

local g_first_show_turtles = true;

local function ShowTurtles_(iAT)
    if iAT == 0 then
        g_current_pos_x = 60;
    end

    g_current_pos_x = g_current_pos_x + 0.5;

    local iFrame = 0;

    for iTurt = 0, 3 do
        local iTurtX = g_current_pos_x - iTurt * 16;
        local iTurtY = 84;
        local mesh_index = g_object_mesh_indices[iTurt];
        local transform_indices = g_object_transform_indices[iTurt];

        transform_set_to_identity(transform_indices[1]);

        if iTurtX < 101 then
            iFrame = resources.MeshTurtGR1 + Cycle_(iAT, 90, 0, 1);
        else
            iFrame = resources.MeshTurtS1;
            local iRZ = (iTurtX - 101)* - 5;
            local iTemp = math.sin(iTurt * 63 * math.pi / 180.0) * 20 + 10;
            iRZ = iRZ * iTemp / 20;
            transform_set_rotation_z(transform_indices[1], iRZ);
            iTemp = (iTurtX - 101) * math.sin((iTurt * 111 + 20) * math.pi / 180.0);
            iTurtY = iTurtY - iTemp;
        end

        set_mesh_to_mesh(mesh_index, iFrame);
        transform_set_translation(transform_indices[1], iTurtX, iTurtY, 2);
        set_mesh_texture(mesh_index, resources.TextureTurtleTexture);
        set_mesh_is_visible(mesh_index, true);

        if g_first_show_turtles then
            skip_next_mesh_interpolation(mesh_index);
        end
    end

    g_first_show_turtles = false;
end

local g_first_show_run_donuts = true;

local function ShowDonuts_(iAT)
    for iDon = 0, 2 do
        local iZ = 2;
        iAT = iAT + 10 * iDon;

        if iAT < 90 then
            g_current_pos_y = 84 + ((90 - iAT) * 2 / 3);
        elseif iAT < 200 then
            g_current_pos_y = 84;
        elseif iAT < 230 then
            local iTemp = (iAT - 200) * 6;
            g_current_pos_y = 84 + math.sin(iTemp * math.pi / 180.0) * 10;
            iZ = iZ - (iAT - 200) / 5;
        else
            g_current_pos_y = 84 - (iAT - 230);
            iZ = iZ - 6;
        end

        local iDonX = 69 + iDon * 10;
        local iDonY = g_current_pos_y;

        transform_set_to_identity(g_object_transform_indices[iDon][1]);
        transform_set_scale(g_object_transform_indices[iDon][1], 0.5, 0.5, 1);

        local iFrame = 0;

        if iAT < 110 then
            iFrame = resources.MeshRunDonutHatch1;
        elseif iAT < 120 then
            iFrame = resources.MeshRunDonutHatch2;
        elseif iAT < 130 then
            iFrame = resources.MeshRunDonutHatch3;
        elseif iAT < 140 then
            iFrame = resources.MeshRunDonutHatch4;
        elseif iAT < 200 then
            iFrame = resources.MeshRunDonutHatch5;
        else
            iFrame = resources.MeshRunDonut1 + (iAT & 4) / 4;
        end

        set_mesh_to_mesh(g_object_mesh_indices[iDon], iFrame);
        transform_set_translation(g_object_transform_indices[iDon][1], iDonX, iDonY, iZ);
        set_mesh_texture(g_object_mesh_indices[iDon], resources.TextureRunDonut);
        set_mesh_is_visible(g_object_mesh_indices[iDon], true);

        if g_first_show_run_donuts then
            skip_next_mesh_interpolation(g_object_mesh_indices[iDon]);
        end
    end

    g_first_show_run_donuts = false;
end

local g_first_show_dino = true;

local function ShowDino_(iAT)
    local mesh_index = g_object_mesh_indices[0];
    local transform_indices = g_object_transform_indices[0];
    transform_set_to_identity(transform_indices[1]);
    transform_set_scale(transform_indices[1], 1.3, 1.3, 1.3);

    g_current_pos_x = 80;
    g_current_pos_y = 93;

    local iFrame = 0;

    if iAT < 60 then
        g_current_pos_x = 80 - (60 - iAT) / 2;
        iFrame = (iAT & 12) / 4;
        iFrame = iFrame + resources.MeshTSaurWalkR1;
    elseif iAT < 200 then
        iFrame = (iAT & 12) / 4;

        if iFrame == 2 then
            g_current_pos_x = 81.3;
        end

        iFrame = iFrame + resources.MeshTSaurYR1;
    elseif iAT < 220 then
        g_current_pos_y = g_current_pos_y + (iAT - 200) / 4;
        transform_set_rotation_z(transform_indices[1], (iAT - 200) * 3);
        iFrame = resources.MeshTSaurWalkR1 + Cycle_(iAT, 60, 0, 3);
    else
        g_current_pos_y = g_current_pos_y + 5+(iAT - 220) / 2;
        transform_set_rotation_z(transform_indices[1], (iAT - 200) * 3);
        iFrame = resources.MeshTSaurWalkR1 + Cycle_(iAT, 60, 0, 3);
    end

    set_mesh_to_mesh(mesh_index, iFrame);
    transform_set_translation(transform_indices[1], g_current_pos_x, g_current_pos_y, 0);
    set_mesh_texture(mesh_index, resources.TextureDinosaur);
    set_mesh_is_visible(mesh_index, true);

    if g_first_show_dino then
        skip_next_mesh_interpolation(mesh_index);
    end

    g_first_show_dino = false;
end

local g_first_show_jumpman_chase = true;

local function JumpmanChase_(iAT)
    if iAT == 0 then
        g_current_pos_y = 86;
    end

    local iFrame = 0;

    if iAT < 60 then
        iFrame = (iAT & 4) / 4;
        iFrame = resources.MeshRight1 + iFrame;
    elseif iAT < 200 then
        local iAir = iAT - 60;

        if iAir < 5 or iAir == 6 or iAir == 8 or iAir == 10 or iAir == 12 then
            g_current_pos_y = g_current_pos_y + 1;
        end

        if iAir > 26 or iAir == 25 or iAir == 23 or iAir == 20 or iAir == 17 then
            g_current_pos_y = g_current_pos_y - 1;
        end

        iFrame = resources.MeshJumpRight;
    end

    g_current_pos_x = (iAT * 4 / 5) + 40;

    transform_set_to_identity(g_object_transform_indices[0][1]);
    transform_set_scale(g_object_transform_indices[0][1], 1, 1, 1);
    set_mesh_to_mesh(g_object_mesh_indices[0], iFrame);
    transform_set_translation(g_object_transform_indices[0][1], g_current_pos_x, g_current_pos_y, 3);
    set_mesh_texture(g_object_mesh_indices[0], resources.TextureJumpman);
    set_mesh_is_visible(g_object_mesh_indices[0], true);

    if g_first_show_jumpman_chase then
        skip_next_mesh_interpolation(g_object_mesh_indices[0]);
    end

    g_first_show_jumpman_chase = false;
end

local g_first_show_jumpman_rocket = true;

local function ShowRocket_(iAT)
    g_current_pos_y = 20 + iAT / 2;
    local iRZ = math.sin(iAT * 3 * math.pi / 180.0) * 10;

    local mesh_index = g_object_mesh_indices[0];
    local transform_indices = g_object_transform_indices[0];
    set_mesh_to_mesh(mesh_index, resources.MeshRocket);
    transform_set_to_identity(transform_indices[1]);
    transform_set_scale(transform_indices[1], 2, 2, 2);
    transform_set_rotation_y(transform_indices[1], iAT / 3);
    transform_concat_rotation_z(transform_indices[1], iRZ);
    transform_set_translation(transform_indices[1], 130, g_current_pos_y, 10);
    set_mesh_texture(mesh_index, resources.TextureDABotO);
    set_mesh_is_visible(mesh_index, true);

    if g_first_show_jumpman_rocket then
        skip_next_mesh_interpolation(mesh_index);
    end

    for iBlip = 1, 14 do  -- TODO: Use constant
        local blip_mesh_index = g_object_mesh_indices[iBlip];
        local blip_transform_indices = g_object_transform_indices[iBlip];
        set_mesh_to_mesh(blip_mesh_index, resources.MeshSquare);
        transform_set_to_identity(blip_transform_indices[1]);
        local iSize = math.random(3, 6);
        transform_set_scale(blip_transform_indices[1], iSize, iSize, 1);

        local iBA = math.random(150, 210);
        local iBD = math.random(5, 20) * math.random(5, 20);
        iBD = iBD / 20;

        local iBX = math.sin(iBA * math.pi / 180.0) * iBD;
        local iBY = math.cos(iBA * math.pi / 180.0) * iBD;
        transform_set_translation(blip_transform_indices[1], iBX, iBY - 15, 0);
        transform_set_rotation_y(blip_transform_indices[2], 10);
        transform_concat_rotation_z(blip_transform_indices[2], iRZ);

        transform_set_translation(blip_transform_indices[2], 132.5, g_current_pos_y, 12);
        set_mesh_texture(blip_mesh_index, resources.TextureBlast1);
        set_mesh_is_visible(blip_mesh_index, true);

        skip_next_mesh_interpolation(blip_mesh_index);  -- They transport every frame, so don't interpolate
    end

    g_first_show_jumpman_rocket = false;
end

local function ShowSomething_()
    ClearAll_();

    if g_time_since_level_start < 210 then
        ShowPlayerStanding_(g_time_since_level_start - 0);
    elseif g_time_since_level_start < 440 then
        ShowPlayerGrooving_(g_time_since_level_start - 210);
    elseif g_time_since_level_start < 530 then
        ShowPlayerLeaving_(g_time_since_level_start - 440);
    elseif g_time_since_level_start < 825 then
        ShowBear_(g_time_since_level_start - 530);
    elseif g_time_since_level_start < 1160 then
        ShowSheep_(g_time_since_level_start - 825);
    elseif g_time_since_level_start < 1500 then
        ShowTurtles_(g_time_since_level_start - 1160);
    elseif g_time_since_level_start < 1800 then
        ShowDonuts_(g_time_since_level_start - 1500);
    elseif g_time_since_level_start < 2100 then
        ShowDino_(g_time_since_level_start - 1800);
    elseif g_time_since_level_start == 2100 then
        local new_end_alien = end_alien_module();
        new_end_alien.AlienMeshResourceIndices = { resources.MeshAlien1, resources.MeshAlien2 };
        new_end_alien.EyeMeshResourceIndex = resources.MeshCube;
        new_end_alien.ShipBaseMeshResourceIndex = resources.MeshShipBase;
        new_end_alien.ShipTopMeshResourceIndex = resources.MeshShipTop;
        new_end_alien.EyeTextureResourceIndex = resources.TextureRedMetal;
        new_end_alien.AlienTextureResourceIndex = resources.TextureAlien;
        new_end_alien.ShipTextureResourceIndex = resources.TextureShipMetal;
        new_end_alien.GlassTextureResourceIndex = resources.TextureShipGlass;
        new_end_alien.initialize();
        g_end_alien = new_end_alien;
    elseif g_time_since_level_start < 2400 then
        g_time_since_level_start = g_time_since_level_start;
    elseif g_time_since_level_start < 2750 then
        JumpmanChase_(g_time_since_level_start - 2400);
    elseif g_time_since_level_start < 3100 then
        g_end_alien = nil;
        ShowRocket_(g_time_since_level_start - 2750);
    end
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    g_game_logic.set_player_freeze_cooldown_frame_count(10);
    g_time_since_level_start = g_time_since_level_start + 1;

    local iFogBack = 0;
    local iFogStart = 0;

    if g_time_since_level_start < 35 then
        iFogStart = 20;
        iFogBack = 50;
    elseif g_time_since_level_start < 2900 then
        iFogStart = 20 + g_time_since_level_start / 3;

        if iFogStart > 60 then
            iFogStart = 60;
        end

        iFogBack = 50 + g_time_since_level_start / 5;

        if iFogBack > 200 then
            iFogBack = 200;
        end
    elseif g_time_since_level_start < 3100 then
        local iTemp = g_time_since_level_start - 2900;
        iFogStart = 60 - iTemp;

        if iFogStart < 20 then
            iFogStart = 20;
        end

        iFogBack = 200 - iTemp;

        if iFogBack < 50 then
            iFogBack = 50;
        end
    end

    set_fog(iFogStart, iFogBack, 0, 0, 0);

    if g_time_since_level_start < 3100 then
        ShowSomething_();
    elseif g_time_since_level_start == 3100 then
        local new_credits = credits_module();
        new_credits.GameLogic = g_game_logic;
        new_credits.TextureResourceIndex = resources.TextureRedMetal;
        new_credits.initialize();
        g_credits = new_credits;

        local platform_mesh_index = g_game_logic.find_platform_by_number(1).mesh_index;  -- TODO: Use constant for num
        set_mesh_is_visible(platform_mesh_index, false);

        local current_backdrop = g_game_logic.find_backdrop_by_number(100);  -- TODO: Use constant for num
        local backdrop_transform_index = transform_create();
        mesh_set_transform(current_backdrop.mesh_index, backdrop_transform_index);
        transform_set_translation(backdrop_transform_index, 40, 0, 20);
        set_mesh_texture(current_backdrop.mesh_index, resources.TextureBlack);
        set_mesh_is_visible(current_backdrop.mesh_index, true);
        skip_next_mesh_interpolation(current_backdrop.mesh_index);
    end

    if g_end_alien then
        g_end_alien.update();
    end

    if g_credits then
        if g_credits.update() and (game_input.jump_action.just_pressed or game_input.select_action.just_pressed) then
            Module.MenuLogic.load_next_level_from_set();  -- Triggers the main menu, or reload of the debug level
        end
    end

    g_game_logic.update_player_graphics();
end

function Module.initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.MenuLogic = Module.MenuLogic;
    g_game_logic.LevelData = ending_data_module();
    g_game_logic.ResetPlayerCallback = Module.reset;
    g_game_logic.OnCollectDonutCallback = on_collect_donut;
    g_game_logic.initialize();

    g_hud_overlay = hud_overlay_module();
    g_hud_overlay.MenuLogic = Module.MenuLogic;
    g_hud_overlay.GameLogic = g_game_logic;

    g_time_since_level_start = 0;
    Module.MenuLogic.set_remaining_life_count(0);
    g_game_logic.set_current_camera_mode(camera_mode.PerspectiveFixed);

    for iTemp = 0, 19 do  -- TODO: Use constant
        g_object_mesh_indices[iTemp] = new_mesh(0);
        g_object_transform_indices[iTemp] = { transform_create(), transform_create() };
        mesh_set_transform(g_object_mesh_indices[iTemp], g_object_transform_indices[iTemp][1]);
        transform_set_parent(g_object_transform_indices[iTemp][1], g_object_transform_indices[iTemp][2]);
    end

    if Module.SkipToCredits then
        ClearAll_();
        g_time_since_level_start = 3100 - 1;  -- TODO: Use constant
    end

    Module.reset();

    -- Make sure staged initialization has happened, and Jumpman has floated to the floor
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);

    skip_next_camera_interpolation();
end

function Module.update(game_input)
    if not g_title_is_done_scrolling then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return;
    end

    ProgressLevel_(game_input);

    if game_input.jump_action.is_pressed or game_input.select_action.is_pressed then
        for _ = 1, 50 do
            ProgressLevel_(game_input);
        end
    end
end

function Module.reset()
    g_game_logic.set_player_current_position_x(80);
    g_game_logic.set_player_current_position_y(79);
    g_game_logic.set_player_current_position_z(3);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end

return Module;
