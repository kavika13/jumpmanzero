local Module = {};

-- TODO: Make this module stateless, and just pass variables around between functions instead of storing in shared vars?

local kPUZZLE_WIDTH = 11;
local kPUZZLE_HEIGHT = 5;  -- TODO: Is this correct? Seems like it should be 4?

local Color = {};  -- TODO: Rename
local Copy = {};  -- TODO: Rename
local Temp = {};  -- TODO: Rename

local iTWidth = 0;  -- TODO: Rename
local iTHeight = 0;  -- TODO: Rename

local iBlockNumber = 0;  -- TODO: Rename

local function SetTemp_(iA, iB, iC, iD)
    for iLoop = 0, 15 do
        Temp[iLoop] = 0;
    end

    Temp[iA] = 1;
    Temp[iB] = 1;
    Temp[iC] = 1;
    Temp[iD] = 1;

    if Temp[3] == 1 then
        iTWidth = 4;
        iTHeight = 1;
    elseif Temp[12] == 1 then
        iTWidth = 1;
        iTHeight = 4;
    elseif Temp[2] == 1 or Temp[6] == 1 then
        iTWidth = 3;
        iTHeight = 2;
    elseif Temp[8] == 1 or Temp[9] == 1 then
        iTWidth = 2;
        iTHeight = 3;
    else
        iTWidth = 2;
        iTHeight = 2;
    end
end

local function GenerateBlock_(iRnd)
    if iRnd < 4 then
        if iRnd == 0 then
            SetTemp_(0, 1, 2, 3);
        elseif iRnd == 1 then
            SetTemp_(0, 4, 8, 12);
        elseif iRnd == 2 then
            SetTemp_(0, 1, 4, 5);
        else
            SetTemp_(0, 1, 2, 6);
        end
    elseif iRnd < 8 then
        if iRnd == 4 then
            SetTemp_(1, 5, 9, 8);
        elseif iRnd == 5 then
            SetTemp_(0, 4, 5, 6);
        elseif iRnd == 6 then
            SetTemp_(0, 1, 4, 8);
        else
            SetTemp_(0, 1, 2, 4);
        end
    elseif iRnd < 12 then
        if iRnd == 8 then
            SetTemp_(0, 1, 5, 9);
        elseif iRnd == 9 then
            SetTemp_(2, 4, 5, 6);
        elseif iRnd == 10 then
            SetTemp_(0, 4, 8, 9);
        else
            SetTemp_(1, 2, 4, 5);
        end
    elseif iRnd < 16 then
        if iRnd == 12 then
            SetTemp_(0, 4, 5, 9);
        elseif iRnd == 13 then
            SetTemp_(0, 1, 5, 6);
        elseif iRnd == 14 then
            SetTemp_(1, 4, 5, 8);
        else
            SetTemp_(0, 1, 2, 5);
        end
    else
        if iRnd == 16 then
            SetTemp_(1, 4, 5, 9);
        elseif iRnd == 17 then
            SetTemp_(1, 4, 5, 6);
        else
            SetTemp_(0, 4, 5, 8);
        end
    end
end

local function CanAddTemp_(iSX, iSY)
    if iSX + iTWidth > 10 or iSY + iTHeight > 5 then
        return 0;
    end

    for iX = 0, iTWidth - 1 do
        for iY = 0, iTHeight - 1 do
            if Temp[iX + iY * 4] == 1 then
                if Color[iX + iSX + (iY + iSY) * kPUZZLE_WIDTH] ~= 0 then
                    return false;
                end
            end
        end
    end

    return true;
end

local function TestLayoutPos_(iTX, iTY, iTemp)
    if Copy[iTX + iTY * kPUZZLE_WIDTH] ~= 0 then
        return 0;
    end

    Copy[iTX + iTY * kPUZZLE_WIDTH] = iTemp;

    local iCount = 1;
    local iRep = 0;
    local iChange = true;

    while iRep < 14 and iChange do
        iChange = false;

        local iX = 1;  -- Note: Gets changed during loop, so can't use for loop

        while iX < 10 do
            local iY = 1;  -- Note: Gets changed during loop, so can't use for loop

            while iY < 5 do
                if Copy[iX + iY * kPUZZLE_WIDTH] == 0 then
                    local iGood = false;

                    if Copy[iX + iY * kPUZZLE_WIDTH + 1] == iTemp then
                        iGood = true;
                    elseif Copy[iX + iY * kPUZZLE_WIDTH - 1] == iTemp then
                        iGood = true;
                    elseif Copy[iX + iY * kPUZZLE_WIDTH + kPUZZLE_WIDTH] == iTemp then
                        iGood = true;
                    elseif Copy[iX + iY * kPUZZLE_WIDTH - kPUZZLE_WIDTH] == iTemp then
                        iGood = true;
                    end

                    if iGood then
                        Copy[iX + iY * kPUZZLE_WIDTH] = iTemp;
                        iCount = iCount + 1;
                        iChange = true;
                        iY = 1;

                        if iX > 1 then
                            iX = iX - 1;
                        end
                    end
                end

                iY = iY + 1;
            end

            iX = iX + 1;
        end

        iRep = iRep + 1;
    end

    return iCount;
end

local function SetRealFromCopy_(iCopy, iVal)
    for iLoop = 0, 55 do
        if Copy[iLoop] == iCopy then
            Color[iLoop] = iVal;
        end
    end
end

local function SetColor_(iX, iY, iCol)
    Color[iX + iY * kPUZZLE_WIDTH] = iCol;
end

local function AddTemp_(iSX, iSY)
    for iX = 0, 3 do
        for iY = 0, 3 do
            if Temp[iX + iY * 4] == 1 then
                SetColor_(iX + iSX, iY + iSY, iBlockNumber);
            end
        end
    end
end

local function ClearCopy_()
    for iLoop = 0, 55 do
        Copy[iLoop] = Color[iLoop];
    end
end

local function GoodLayout_()
    ClearCopy_();

    for iX = 1, 9 do
        for iY = 1, 4 do
            local iCount = TestLayoutPos_(iX, iY, 200);

            if (iCount & 3) ~= 0 then
                return false;
            end
        end
    end

    return true;
end

local function CheckForEasyOnes_()
    ClearCopy_();

    local iTemp = 200;

    for iX = 1, 9 do
        for iY = 1, 4 do
            iTemp = iTemp + 1;
            local iCount = TestLayoutPos_(iX, iY, iTemp);

            if iCount == 4 then
                SetRealFromCopy_(iTemp, iBlockNumber);
                iBlockNumber = iBlockNumber + 1;
            end
        end
    end
end

local function RemoveTempBlock_(iSX, iSY)
    for iX = 0, 3 do
        for iY = 0, 3 do
            if Temp[iX + iY * 4] == 1 then
                SetColor_(iX + iSX, iY + iSY, 0);
            end
        end
    end
end

local function DoAddBlock_()
    local iBlock = rnd(1, 18);
    local iSX = rnd(1, 9);
    local iSY = rnd(1, 4);
    GenerateBlock_(iBlock);

    if iSX + iTWidth > 10 then
        iSX = 1;
    end

    if iSY + iTHeight > 5 then
        iSY = 1;
    end

    local iOBlock = iBlock;
    local iOSX = iSX;
    local iOSY = iSY;

    while true do
        if CanAddTemp_(iSX, iSY) then
            AddTemp_(iSX, iSY, iBlockNumber);

            if GoodLayout_() then
                iBlockNumber = iBlockNumber + 1;
                CheckForEasyOnes_();
                return true;
            end

            RemoveTempBlock_(iSX, iSY);
        end

        iSX = iSX + 1;

        if iSX + iTWidth > 10 then
            iSX = 1;
            iSY = iSY + 1;

            if iSY + iTHeight > 5 then
                iSY = 1;
                iBlock = iBlock + 1;

                if iBlock > 18 then
                    iBlock = 1;
                end

                GenerateBlock_(iBlock);
            end
        end

        if iSX == iOSX then
            if iSY == iOSY then
                if iBlock == iOBlock then
                    return false;
                end
            end
        end
    end
end

local function Clear_()
    for iLoop = 0, 55 do
        Color[iLoop] = 0;
    end
end

local function FillWithBlocks_()
    iBlockNumber = 1;

    while iBlockNumber ~= 10 do
        iBlockNumber = 1;
        local iSuccess = true;
        Clear_();

        while iSuccess and iBlockNumber ~= 10 do
            iSuccess = DoAddBlock_();
        end
    end
end

function Module.find_new_layout()
    Clear_();
    FillWithBlocks_();
end

function Module.get_color_at_pos(pos_x, pos_y)
    return Color[pos_x + pos_y * kPUZZLE_WIDTH];
end

return Module;
