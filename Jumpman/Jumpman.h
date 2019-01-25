#ifndef INCLUDED_JUMPMAN_ZERO_JUMPMAN_H
#define INCLUDED_JUMPMAN_ZERO_JUMPMAN_H

#include <stdint.h>
#include "Input.h"

#if defined(__cplusplus)
extern "C" {
#endif

long Init3D();
void InitGameDebugLevel(const char* level_name, GameRawInput* game_raw_input);
void InitGameNormal();
void UpdateGame(GameInput* game_input);
void ExitGame();

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_JUMPMAN_H
