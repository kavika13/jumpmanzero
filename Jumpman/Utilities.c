#define _CRT_SECURE_NO_WARNINGS
#ifdef _WIN32
    #include <direct.h>
    #define getcwd _getcwd
#else
    #include <unistd.h>
#endif
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <stb_sprintf.h>

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

bool TextLine(char* sText, size_t iTextLen, char* sOut, size_t iOutLen, int iLine) {
    bool is_found = false;

    int iCR;
    size_t iChars;

    iChars = 0;
    iCR = 0;
    sOut[iChars] = 0;

    for(size_t iLoop = 0; iLoop < iTextLen; ++iLoop) {
        if(iCR == iLine && sText[iLoop] != 10 && sText[iLoop] != 13 && iChars < iOutLen - 1) {
            is_found = true;
            sOut[iChars] = sText[iLoop];
            ++iChars;
            sOut[iChars] = 0;
        }

        if(sText[iLoop] == 10 || sText[iLoop] == 13) {
            ++iCR;

            if(sText[iLoop] == 13 && iLoop + 1 < iTextLen && sText[iLoop + 1] == 10) {
                // Handle Windows newline conventions, if present
                ++iLoop;
            }
        }

        if(iCR > iLine) {
            break;
        }
    }

    return is_found;
}

bool GetWorkingDirectoryPath(char* output_path) {
    if(getcwd(output_path, 200) == NULL) {
        // TODO: Proper error handling, handle longer paths, full cross-platform solution, check for unicode support
        return false;
    }

    return true;
}

size_t FileToString(const char* filename, unsigned char** sNewBuffer) {
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
    char sTemp[20] = { 0 };
    char* sData = NULL;

    size_t iLen = FileToString(sFile, (unsigned char**)(&sData));

    if(TextLine(sData, iLen, sTemp, 20, iLine)) {
        is_found = true;
        stbsp_snprintf(sOut, (int)sOutSize, "%s", sTemp);
    }

    free(sData);

    return is_found;
}
