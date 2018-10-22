#define WIN32_LEAN_AND_MEAN 1
#include <windows.h>  // NOLINT
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>

long StringToLong(unsigned char* sString) {
    float fTemp;

    fTemp = sString[1] * 256.0f + sString[2] + sString[3] / 256.0f;

    if (sString[0]) {
        return (long)(fTemp) * -1;
    } else {
        return (long)(fTemp);
    }
}

long StringToLong2(unsigned char* sString) {
    float fTemp;

    fTemp = (sString[0] & 127) * 256.0f * 256.0f * 256.0f + sString[1] * 256.0f * 256.0f + sString[2] * 256.0f + sString[3];

    if (sString[0] & 128) {
        return (long)(fTemp) * -1;
    } else {
        return (long)(fTemp);
    }
}

long StringToInt(unsigned char* sString) {
    float fTemp;
    fTemp = sString[0] * 256.0f + sString[1];
    return (long)(fTemp);
}

bool TextLine(char* sText, int iTextLen, char* sOut, int iOutLen, int iLine) {
    bool is_found = false;

    int iLoop;
    int iCR;
    int iChars;

    iChars = 0;
    iCR = 0;
    iLoop = -1;
    sOut[iChars] = 0;

    while (++iLoop < iTextLen) {
        if (iCR == iLine && sText[iLoop] != 13 && iChars < iOutLen - 1) {
            is_found = true;
            sOut[iChars] = sText[iLoop];
            ++iChars;
            sOut[iChars] = 0;
        }

        if (sText[iLoop] == 13) {
            ++iCR;
            ++iLoop;
        }

        if (iCR > iLine) {
            break;
        }
    }

    return is_found;
}

long FileToString(char* sFileName, unsigned char** sNewBuffer) {
    // TODO: Remove win32 dependency
    DWORD iNumRead;
    BY_HANDLE_FILE_INFORMATION info;
    HANDLE hFile;
    long iSize;

    hFile = CreateFile(sFileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    GetFileInformationByHandle(hFile, &info);
    iSize = info.nFileSizeLow;
    *sNewBuffer = (unsigned char*)(malloc(iSize));
    ReadFile(hFile, *sNewBuffer, iSize, &iNumRead, NULL);
    CloseHandle(hFile);

    char sError[300];
    sprintf_s(sError, sizeof(sError), "Can't find file - %s", sFileName);

    if (!iNumRead) {
        MessageBox(0, sError, "Jumpman Zero", 0);
    }

    return iNumRead;
}

bool GetFileLine(char* sOut, size_t sOutSize, char* sFile, int iLine) {
    bool is_found = false;
    int iLen;
    char sTemp[20] = { 0 };
    char* sData;

    iLen = FileToString(sFile, (unsigned char**)(&sData));

    if (TextLine(sData, iLen, sTemp, 20, iLine)) {
        is_found = true;
        sprintf_s(sOut, sOutSize, "%s", sTemp);
    }

    free(sData);

    return is_found;
}

long PointInQuad(long iX0, long iY0, long iX1, long iY1, long iX2, long iY2, long iX3, long iY3, long iX4, long iY4) {
    long iBX, iBY, iSX, iSY;
    long det, total;

    total = 0;

    iBX = iX2 - iX1;
    iBY = iY2 - iY1;
    iSX = iX0 - iX1;
    iSY = iY0 - iY1;
    det = iBX * iSY - iBY * iSX;

    if (det <= 0) {
        total = total + 1;
    }

    iBX = iX3 - iX2;
    iBY = iY3 - iY2;
    iSX = iX0 - iX2;
    iSY = iY0 - iY2;
    det = iBX * iSY - iBY * iSX;

    if (det <= 0) {
        total = total + 1;
    }

    iBX = iX4 - iX3;
    iBY = iY4 - iY3;
    iSX = iX0 - iX3;
    iSY = iY0 - iY3;
    det = iBX * iSY - iBY * iSX;

    if (det <= 0) {
        total = total + 1;
    }

    iBX = iX1 - iX4;
    iBY = iY1 - iY4;
    iSX = iX0 - iX4;
    iSY = iY0 - iY4;
    det = iBX * iSY - iBY * iSX;

    if (det <= 0) {
        total = total + 1;
    }

    if (total == 4) {
        return 1;
    }

    return 0;
}
