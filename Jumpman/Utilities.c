#include <direct.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>

long StringToLong(unsigned char* sString) {
    float fTemp;

    fTemp = sString[1] * 256.0f + sString[2] + sString[3] / 256.0f;

    if(sString[0]) {
        return (long)(fTemp) * -1;
    } else {
        return (long)(fTemp);
    }
}

long StringToLong2(unsigned char* sString) {
    float fTemp;

    fTemp = (sString[0] & 127) * 256.0f * 256.0f * 256.0f + sString[1] * 256.0f * 256.0f + sString[2] * 256.0f + sString[3];

    if(sString[0] & 128) {
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

    while(++iLoop < iTextLen) {
        if(iCR == iLine && sText[iLoop] != 13 && iChars < iOutLen - 1) {
            is_found = true;
            sOut[iChars] = sText[iLoop];
            ++iChars;
            sOut[iChars] = 0;
        }

        if(sText[iLoop] == 13) {
            ++iCR;
            ++iLoop;
        }

        if(iCR > iLine) {
            break;
        }
    }

    return is_found;
}

bool GetWorkingDirectoryPath(char* output_path) {
    if(_getcwd(output_path, 200) == NULL) {
        // TODO: Proper error handling, handle longer paths, full cross-platform solution, check for unicode support
        return false;
    }

    return true;
}

long FileToString(const char* filename, unsigned char** sNewBuffer) {
    long length = 0;
    FILE* input_file = fopen(filename, "rb");

    if(input_file) {
        fseek(input_file, 0, SEEK_END);
        length = ftell(input_file);
        fseek(input_file, 0, SEEK_SET);

        *sNewBuffer = (unsigned char*)malloc(length);

        if(*sNewBuffer) {
            fread(*sNewBuffer, 1, length, input_file);
        }

        fclose(input_file);
    }

    return length;
}

bool StringToFile(const char* filename, const char* data) {
    int success = false;

    FILE* output_file = fopen(filename, "wb+");

    if(output_file != NULL) {
        if(fputs(data, output_file) != EOF) {
            success = true;
        }

        if(fclose(output_file) == EOF) {
            success = false;
        }
    }

    return success;
}

bool GetFileLine(char* sOut, size_t sOutSize, char* sFile, int iLine) {
    bool is_found = false;
    int iLen;
    char sTemp[20] = { 0 };
    char* sData;

    iLen = FileToString(sFile, (unsigned char**)(&sData));

    if(TextLine(sData, iLen, sTemp, 20, iLine)) {
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

    if(det <= 0) {
        total = total + 1;
    }

    iBX = iX3 - iX2;
    iBY = iY3 - iY2;
    iSX = iX0 - iX2;
    iSY = iY0 - iY2;
    det = iBX * iSY - iBY * iSX;

    if(det <= 0) {
        total = total + 1;
    }

    iBX = iX4 - iX3;
    iBY = iY4 - iY3;
    iSX = iX0 - iX3;
    iSY = iY0 - iY3;
    det = iBX * iSY - iBY * iSX;

    if(det <= 0) {
        total = total + 1;
    }

    iBX = iX1 - iX4;
    iBY = iY1 - iY4;
    iSX = iX0 - iX4;
    iSY = iY0 - iY4;
    det = iBX * iSY - iBY * iSX;

    if(det <= 0) {
        total = total + 1;
    }

    if(total == 4) {
        return 1;
    }

    return 0;
}
