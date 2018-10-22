#include <assert.h>
#include "mini_al.h"
#include "SoundBuffer.h"
#include "Sound.h"

#define kNUM_SOUND_DECODERS 5
#define kSOUND_CHANNEL_START_INDEX 2

static mal_decoder g_sound_decoders[kNUM_SOUND_DECODERS] = { 0 };

static uint32_t AddChannel0Samples(uint32_t frameCount, float* interleaved_stereo_samples) {
    return (uint32_t)mal_decoder_read(&g_sound_decoders[0], frameCount, interleaved_stereo_samples);
}

static uint32_t AddChannel1Samples(uint32_t frameCount, float* interleaved_stereo_samples) {
    return (uint32_t)mal_decoder_read(&g_sound_decoders[1], frameCount, interleaved_stereo_samples);
}

static uint32_t AddChannel2Samples(uint32_t frameCount, float* interleaved_stereo_samples) {
    return (uint32_t)mal_decoder_read(&g_sound_decoders[2], frameCount, interleaved_stereo_samples);
}

static uint32_t AddChannel3Samples(uint32_t frameCount, float* interleaved_stereo_samples) {
    return (uint32_t)mal_decoder_read(&g_sound_decoders[3], frameCount, interleaved_stereo_samples);
}

static uint32_t AddChannel4Samples(uint32_t frameCount, float* interleaved_stereo_samples) {
    return (uint32_t)mal_decoder_read(&g_sound_decoders[4], frameCount, interleaved_stereo_samples);
}

static const SoundChannel g_sound_channel_callbacks[kNUM_SOUND_DECODERS] = {
    AddChannel0Samples,
    AddChannel1Samples,
    AddChannel2Samples,
    AddChannel3Samples,
    AddChannel4Samples,
};

bool InitSound() {
    return true;
}

void PlaySoundEffect(size_t sound_index) {
    assert(sound_index < kNUM_SOUND_DECODERS);

    mal_decoder_seek_to_frame(&g_sound_decoders[sound_index], 0);
    SetSoundChannel(kSOUND_CHANNEL_START_INDEX + sound_index, g_sound_channel_callbacks[sound_index]);
}

bool LoadSound(const char* filename, size_t sound_index) {
    assert(sound_index < kNUM_SOUND_DECODERS);

    SetSoundChannel(kSOUND_CHANNEL_START_INDEX + sound_index, NULL);
    mal_decoder_uninit(&g_sound_decoders[sound_index]);

    mal_decoder_config config = mal_decoder_config_init(mal_format_f32, 2, 44100);
    mal_result result = mal_decoder_init_file(filename, &config, &g_sound_decoders[sound_index]);

    return result == MAL_SUCCESS;
}

void CleanUpSounds() {
    for(size_t sound_index = 0; sound_index < kNUM_SOUND_DECODERS; ++sound_index) {
        SetSoundChannel(kSOUND_CHANNEL_START_INDEX + sound_index, NULL);
        mal_decoder_uninit(&g_sound_decoders[sound_index]);
    }
}
