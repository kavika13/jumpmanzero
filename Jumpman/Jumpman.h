#ifndef INCLUDED_JUMPMAN_ZERO_JUMPMAN_H
#define INCLUDED_JUMPMAN_ZERO_JUMPMAN_H

#include <stdint.h>
#include "Input.h"

#if defined(__cplusplus)
extern "C" {
#endif

long Init3D();
void InitGameDebugLevel(const char* level_name, GameInput* game_input, GameRawInput* input_bindings);
void InitGameNormal();
void UpdateGame(GameInput* game_input, GameRawInput* input_bindings);
void ExitGame();

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_JUMPMAN_H
