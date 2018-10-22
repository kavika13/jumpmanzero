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
bool TextLine(char* sText, int iTextLen, char* sOut, int iOutLen, int iLine);
long FileToString(char* sFileName, unsigned char** sNewBuffer);
bool GetFileLine(char* sOut, size_t sOutSize, char* sFile, int iLine);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_UTILITIES_H
