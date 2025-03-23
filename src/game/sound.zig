const std = @import("std");
const assert = std.debug.assert;
const jumpman_sound_c = @cImport({
    // No AVX2 or greater for better backward compatibility
    @cDefine("MAL_NO_AVX2", {});
    @cInclude("miniaudio.h");
    @cInclude("SoundBuffer.h");
});

const kNUM_SOUND_DECODERS: usize = 5;
const kSOUND_CHANNEL_START_INDEX: usize = 2;

var g_sound_is_initialized: bool = false;
var g_sound_is_enabled: bool = false;
var g_sound_decoders = std.mem.zeroes([kNUM_SOUND_DECODERS]jumpman_sound_c.ma_decoder);

fn AddChannel0Samples(frameCount: u64, interleaved_stereo_samples: [*c]f32) callconv(.C) u64 {
    var frames_read: u64 = undefined;
    const result = jumpman_sound_c.ma_decoder_read_pcm_frames(&g_sound_decoders[0], interleaved_stereo_samples, frameCount, &frames_read);
    return if (result == jumpman_sound_c.MA_SUCCESS) frames_read else 0;
}

fn AddChannel1Samples(frameCount: u64, interleaved_stereo_samples: [*c]f32) callconv(.C) u64 {
    var frames_read: u64 = undefined;
    const result = jumpman_sound_c.ma_decoder_read_pcm_frames(&g_sound_decoders[1], interleaved_stereo_samples, frameCount, &frames_read);
    return if (result == jumpman_sound_c.MA_SUCCESS) frames_read else 0;
}

fn AddChannel2Samples(frameCount: u64, interleaved_stereo_samples: [*c]f32) callconv(.C) u64 {
    var frames_read: u64 = undefined;
    const result = jumpman_sound_c.ma_decoder_read_pcm_frames(&g_sound_decoders[2], interleaved_stereo_samples, frameCount, &frames_read);
    return if (result == jumpman_sound_c.MA_SUCCESS) frames_read else 0;
}

fn AddChannel3Samples(frameCount: u64, interleaved_stereo_samples: [*c]f32) callconv(.C) u64 {
    var frames_read: u64 = undefined;
    const result = jumpman_sound_c.ma_decoder_read_pcm_frames(&g_sound_decoders[3], interleaved_stereo_samples, frameCount, &frames_read);
    return if (result == jumpman_sound_c.MA_SUCCESS) frames_read else 0;
}

fn AddChannel4Samples(frameCount: u64, interleaved_stereo_samples: [*c]f32) callconv(.C) u64 {
    var frames_read: u64 = undefined;
    const result = jumpman_sound_c.ma_decoder_read_pcm_frames(&g_sound_decoders[4], interleaved_stereo_samples, frameCount, &frames_read);
    return if (result == jumpman_sound_c.MA_SUCCESS) frames_read else 0;
}

const g_sound_channel_callbacks: [kNUM_SOUND_DECODERS]jumpman_sound_c.SoundChannel = .{
    &AddChannel0Samples,
    &AddChannel1Samples,
    &AddChannel2Samples,
    &AddChannel3Samples,
    &AddChannel4Samples,
};

export fn InitSound() bool {
    g_sound_is_initialized = true;
    return true;
}

export fn GetIsSoundEnabled() bool {
    return g_sound_is_enabled;
}

export fn SetIsSoundEnabled(is_enabled: bool) void {
    g_sound_is_enabled = is_enabled;
}

export fn PlaySoundEffect(sound_index: usize) void {
    if (!g_sound_is_initialized or !g_sound_is_enabled) {
        return;
    }

    assert(sound_index < kNUM_SOUND_DECODERS);

    _ = jumpman_sound_c.ma_decoder_seek_to_pcm_frame(&g_sound_decoders[sound_index], 0); // TODO: Detect and handle error?
    jumpman_sound_c.SetSoundChannel(kSOUND_CHANNEL_START_INDEX + sound_index, g_sound_channel_callbacks[sound_index]);
}

export fn LoadSound(filename: [*:0]const u8, sound_index: usize) bool {
    // For now, enable loading sounds even if sounds are not enabled, so we can switch it enabled without having to load sounds again
    if (!g_sound_is_initialized) {
        return false;
    }

    assert(sound_index < kNUM_SOUND_DECODERS);

    jumpman_sound_c.SetSoundChannel(kSOUND_CHANNEL_START_INDEX + sound_index, null);
    _ = jumpman_sound_c.ma_decoder_uninit(&g_sound_decoders[sound_index]); // TODO: Detect and handle error

    const config: jumpman_sound_c.ma_decoder_config = jumpman_sound_c.ma_decoder_config_init(jumpman_sound_c.ma_format_f32, 2, 44100);
    const result: jumpman_sound_c.ma_result = jumpman_sound_c.ma_decoder_init_file(filename, &config, &g_sound_decoders[sound_index]);

    return result == jumpman_sound_c.MA_SUCCESS;
}

export fn CleanUpSounds() void {
    if (!g_sound_is_initialized) {
        return;
    }

    var sound_index: usize = 0;
    while (sound_index < kNUM_SOUND_DECODERS) : (sound_index += 1) {
        jumpman_sound_c.SetSoundChannel(kSOUND_CHANNEL_START_INDEX + sound_index, null);
        _ = jumpman_sound_c.ma_decoder_uninit(&g_sound_decoders[sound_index]); // TODO: Detect and handle error
    }

    g_sound_is_initialized = false;
}
