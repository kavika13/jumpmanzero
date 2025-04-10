#ifndef INCLUDED_JUMPMAN_ZERO_JUMPMAN_H
#define INCLUDED_JUMPMAN_ZERO_JUMPMAN_H

#include "Input.h"

#if defined(__cplusplus)
extern "C" {
#endif

bool Init3D(void);

void InitGameDebugScript(const char* base_path, const char* script_name);
void InitGameDebugLevel(const char* base_path, const char* level_name);
void InitGameNormal(const char* base_path);
void UpdateGame(const GameInput* game_input, double seconds_per_update_timestep);
void DrawGame(double seconds_per_update_timestep, double seconds_since_previous_update, double time_scale);
void ExitGame(void);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_JUMPMAN_H
