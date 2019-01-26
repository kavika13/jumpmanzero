#ifndef INCLUDED_JUMPMAN_ZERO_JUMPMAN_H
#define INCLUDED_JUMPMAN_ZERO_JUMPMAN_H

#include <stdint.h>
#include "Input.h"

#if defined(__cplusplus)
extern "C" {
#endif

typedef struct {
    bool debug_is_enabled;
    bool game_is_frozen;
    long current_fps;

    char game_base_path[300];

    bool sound_effects_are_enabled;
    bool music_is_enabled;
    bool show_fps_is_enabled;
} GameSettings;

long Init3D();
void InitGameDebugLevel(const char* level_name, GameSettings* game_settings, GameInput* game_input, GameRawInput* input_bindings);
void InitGameNormal();
void UpdateGame(GameSettings* game_settings, GameInput* game_input, GameRawInput* input_bindings);
void ExitGame();

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_JUMPMAN_H
