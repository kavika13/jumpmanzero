#ifndef INCLUDED_JUMPMAN_ZERO_SOUND_H
#define INCLUDED_JUMPMAN_ZERO_SOUND_H

#include <stddef.h>
#include <stdbool.h>

#if defined(__cplusplus)
extern "C" {
#endif

bool InitSound(void);
bool GetIsSoundEnabled(void);
void SetIsSoundEnabled(bool is_enabled);
void CleanUpSounds(void);
bool LoadSound(const char* filename, size_t sound_index);
void PlaySoundEffect(size_t sound_index);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_SOUND_H
