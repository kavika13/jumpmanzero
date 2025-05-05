#ifndef INCLUDED_JUMPMAN_ZERO_UTILITIES_H
#define INCLUDED_JUMPMAN_ZERO_UTILITIES_H

#include <stddef.h>
#include <stdbool.h>

#if defined(__cplusplus)
extern "C" {
#endif

long StringToLong(unsigned char* sString);
long StringToLong2(unsigned char* sString);
long FileToString(const char* filename, unsigned char** sNewBuffer);
bool StringToFile(const char* filename, const char* data);
bool GetFileLine(char* sOut, size_t sOutSize, char* sFile, int iLine);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_UTILITIES_H
