#ifndef INCLUDED_JUMPMAN_ZERO_SOUND_BUFFER_H
#define INCLUDED_JUMPMAN_ZERO_SOUND_BUFFER_H

#include <inttypes.h>
#include <stdbool.h>

#if defined(__cplusplus)
extern "C" {
#endif

#define kSoundChannelCount 64

typedef uint32_t (*SoundChannel)(uint32_t frameCount, float* interleaved_stereo_samples);

bool InitSoundBuffer();
void CleanupSoundBuffer();
void SetSoundChannel(size_t channel_index, SoundChannel new_channel_node);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_SOUND_BUFFER_H
