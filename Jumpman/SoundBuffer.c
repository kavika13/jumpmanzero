#define MINI_AL_IMPLEMENTATION
#define MAL_NO_AVX512
#include "mini_al.h"
#include "SoundBuffer.h"

bool g_is_initialized = false;
mal_device g_sound_device;
static SoundChannel g_sound_channels[kSoundChannelCount] = { 0 };

static mal_uint32 on_send_frames_to_device(mal_device* pDevice, mal_uint32 frameCount, void* pSamples) {
    float* output = (float*)pSamples;

    for (mal_uint32 i = 0; i < frameCount; ++i) {
        output[i * 2 + 0] = 0.0f;
        output[i * 2 + 1] = 0.0f;
    }

    for (size_t i = 0; i < kSoundChannelCount; ++i) {
        if (g_sound_channels[i] != NULL) {
            g_sound_channels[i](frameCount, pSamples);
        }
    }

    return frameCount;
}

bool InitSoundBuffer() {
    if(!g_is_initialized) {
        mal_device_config config = mal_device_config_init_playback(
            mal_format_f32,
            2,
            44100,
            on_send_frames_to_device);

        if (mal_device_init(NULL, mal_device_type_playback, NULL, &config, NULL, &g_sound_device) != MAL_SUCCESS) {
            // TODO: printf("Failed to open playback device.\n");
            return false;
        }

        if (mal_device_start(&g_sound_device) != MAL_SUCCESS) {
            // TODO: printf("Failed to start playback device.\n");
            mal_device_uninit(&g_sound_device);
            return false;
        }

        for(size_t i = 0; i < kSoundChannelCount; ++i) {
            g_sound_channels[i] = NULL;
        }

        g_is_initialized = true;
    }

    return true;
}

void CleanupSoundBuffer() {
    mal_device_uninit(&g_sound_device);
    g_is_initialized = false;
}

void SetSoundChannel(size_t channel_index, SoundChannel new_channel_node) {
    assert(channel_index < kSoundChannelCount);
    g_sound_channels[channel_index] = new_channel_node;
}
