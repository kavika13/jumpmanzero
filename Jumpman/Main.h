#ifndef INCLUDED_JUMPMAN_ZERO_MAIN_H
#define INCLUDED_JUMPMAN_ZERO_MAIN_H

#include <stdbool.h>

#if defined(__cplusplus)
extern "C" {
#endif

bool IsGameFrozen();
long GetCurrentFps();
long GetLastKeyPressed();
int GetKeyBinding(size_t binding_index);
void SetKeyBinding(size_t binding_index, int value);
void SaveSettings();

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_MAIN_H
