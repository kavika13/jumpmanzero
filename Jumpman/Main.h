#ifndef INCLUDED_JUMPMAN_ZERO_MAIN_H
#define INCLUDED_JUMPMAN_ZERO_MAIN_H

#include <stdbool.h>
#include <stddef.h>

#if defined(__cplusplus)
extern "C" {
#endif

bool IsGameFrozen(void);
int32_t GetCurrentFps(void);
double GetCurrentMaxUpdateFrameTime(void);
double GetCurrentMaxDrawAndSwapFrameTime(void);
int32_t GetLastKeyPressed(void);
int32_t GetKeyBinding(size_t binding_index);
void SetKeyBinding(size_t binding_index, int32_t value);
void SaveSettings(void);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_MAIN_H
