#ifndef INCLUDED_JUMPMAN_ZERO_JUMPMAN_H
#define INCLUDED_JUMPMAN_ZERO_JUMPMAN_H

#include <stdint.h>
#include "Input.h"

#if defined(__cplusplus)
extern "C" {
#endif

long Init3D(void);
void InitGameDebugLevel(const char* base_path, const char* level_name);
void InitGameNormal(void);
void UpdateGame(const char* base_path, GameInput* game_input);
void DrawGame(void);
void ExitGame(void);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_JUMPMAN_H
