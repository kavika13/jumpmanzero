#ifndef INCLUDED_JUMPMAN_ZERO_SOUND_H
#define INCLUDED_JUMPMAN_ZERO_SOUND_H

#include <inttypes.h>
#include <stdbool.h>

#if defined(__cplusplus)
extern "C" {
#endif

bool InitSound();
void CleanUpSounds();
bool LoadSound(const char* filename, size_t sound_index);
void PlaySound(size_t sound_index);

#if defined(__cplusplus)
}
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_SOUND_H
