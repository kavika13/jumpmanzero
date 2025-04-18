#include <math.h>
#define DR_WAV_IMPLEMENTATION
#include "extras/dr_wav.h"

#if defined(__GNUC__)
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wunused-parameter"
#endif
// No AVX2 or greater for better backward compatibility
#define MAL_NO_AVX2
#define MAL_NO_AVX512
#define MINI_AL_IMPLEMENTATION
#include "mini_al.h"
#if defined(__GNUC__)
    #pragma GCC diagnostic pop
#endif

#include "SoundBuffer.h"

static bool g_is_initialized = false;
static mal_device g_sound_device;
static SoundChannel g_sound_channels[kSOUND_CHANNEL_COUNT] = { 0 };
static float* g_temporary_sample_buffer = NULL;
static size_t g_temporary_sample_buffer_byte_count = 0;

static mal_uint32 on_send_frames_to_device(mal_device* pDevice, mal_uint32 frame_count, void* pSamples) {
    (void)pDevice;  // Unused, but passed due to passing this function as a function pointer
    float* output = (float*)pSamples;

    for(mal_uint32 i = 0; i < frame_count; ++i) {
        output[i * 2 + 0] = 0.0f;
        output[i * 2 + 1] = 0.0f;
    }

    size_t buffer_byte_count = frame_count * sizeof(float) * 2;

    if(g_temporary_sample_buffer_byte_count < buffer_byte_count) {
        free(g_temporary_sample_buffer);
        g_temporary_sample_buffer = malloc(buffer_byte_count);
        g_temporary_sample_buffer_byte_count = buffer_byte_count;
    }

    const float hard_coded_channel_gain = 0.8f;  // TODO: Expose gain interface?

    for(size_t i = 0; i < kSOUND_CHANNEL_COUNT; ++i) {
        memset(g_temporary_sample_buffer, 0, buffer_byte_count);

        if(g_sound_channels[i] != NULL) {
            g_sound_channels[i](frame_count, g_temporary_sample_buffer);

            for(size_t current_frame_index = 0; current_frame_index < frame_count; ++current_frame_index) {
                output[current_frame_index * 2 + 0] += g_temporary_sample_buffer[current_frame_index * 2 + 0] * hard_coded_channel_gain;
                output[current_frame_index * 2 + 1] += g_temporary_sample_buffer[current_frame_index * 2 + 1] * hard_coded_channel_gain;
            }
        }
    }

    for(size_t current_frame_index = 0; current_frame_index < frame_count; ++current_frame_index) {
        output[current_frame_index * 2 + 0] = (float)fmax(-1.0f, fmin(1.0f, output[current_frame_index * 2 + 0]));
        output[current_frame_index * 2 + 1] = (float)fmax(-1.0f, fmin(1.0f, output[current_frame_index * 2 + 1]));
    }

    return frame_count;
}

bool InitSoundBuffer(void) {
    if(!g_is_initialized) {
        mal_device_config config = mal_device_config_init_playback(
            mal_format_f32,
            2,
            44100,
            on_send_frames_to_device);

        if(mal_device_init(NULL, mal_device_type_playback, NULL, &config, NULL, &g_sound_device) != MAL_SUCCESS) {
            // TODO: printf("Failed to open playback device.\n");
            return false;
        }

        if(mal_device_start(&g_sound_device) != MAL_SUCCESS) {
            // TODO: printf("Failed to start playback device.\n");
            mal_device_uninit(&g_sound_device);
            return false;
        }

        for(size_t i = 0; i < kSOUND_CHANNEL_COUNT; ++i) {
            g_sound_channels[i] = NULL;
        }

        g_is_initialized = true;
    }

    return true;
}

void CleanupSoundBuffer(void) {
    mal_device_uninit(&g_sound_device);
    g_is_initialized = false;
}

void SetSoundChannel(size_t channel_index, SoundChannel new_channel_node) {
    assert(channel_index < kSOUND_CHANNEL_COUNT);
    g_sound_channels[channel_index] = new_channel_node;
}
