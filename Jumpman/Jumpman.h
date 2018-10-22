#ifndef INCLUDED_JUMPMAN_ZERO_JUMPMAN_H
#define INCLUDED_JUMPMAN_ZERO_JUMPMAN_H

#include <stdint.h>

#if defined(__cplusplus)
extern "C" {
#endif

long Init3D();
void InitGameDebugLevel(const char* level_name);
void InitGameNormal();
void UpdateGame();
void ExitGame();

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_JUMPMAN_H
