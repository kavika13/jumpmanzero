#ifndef INCLUDED_JUMPMAN_ZERO_SOUND_BUFFER_H
#define INCLUDED_JUMPMAN_ZERO_SOUND_BUFFER_H

#include <inttypes.h>
#include <stdbool.h>
#include <stddef.h>

#if defined(__cplusplus)
extern "C" {
#endif

#define kSOUND_CHANNEL_COUNT ((size_t)64)

typedef uint32_t (*SoundChannel)(uint32_t frameCount, float* interleaved_stereo_samples);

bool InitSoundBuffer(void);
void CleanupSoundBuffer(void);
void SetSoundChannel(size_t channel_index, SoundChannel new_channel_node);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_SOUND_BUFFER_H
