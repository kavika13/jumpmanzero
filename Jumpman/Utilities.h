#ifndef INCLUDED_JUMPMAN_ZERO_UTILITIES_H
#define INCLUDED_JUMPMAN_ZERO_UTILITIES_H

#include <stddef.h>
#include <stdbool.h>

#if defined(__cplusplus)
extern "C" {
#endif

long PointInQuad(long iX0, long iY0, long iX1, long iY1, long iX2, long iY2, long iX3, long iY3, long iX4, long iY4);
long StringToInt(unsigned char* sString);
long StringToLong(unsigned char* sString);
long StringToLong2(unsigned char* sString);
bool TextLine(char* sText, size_t iTextLen, char* sOut, size_t iOutLen, int iLine);
bool GetWorkingDirectoryPath(char* output_path);
long FileToString(const char* filename, unsigned char** sNewBuffer);
bool StringToFile(const char* filename, const char* data);
bool GetFileLine(char* sOut, size_t sOutSize, char* sFile, int iLine);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_UTILITIES_H
