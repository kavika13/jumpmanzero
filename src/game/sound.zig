const std = @import("std");
const assert = std.debug.assert;
const sound = @import("sound.zig");
const sound_buffer = @import("sound_buffer.zig");
const miniaudio_c = @import("miniaudio_c");

const kNUM_SOUND_DECODERS: usize = 5;
const kSOUND_CHANNEL_START_INDEX: usize = 2;

var g_sound_is_initialized: bool = false;
var g_sound_is_enabled: bool = false;
var g_sound_decoders = std.mem.zeroes([kNUM_SOUND_DECODERS]miniaudio_c.ma_decoder);

fn addChannel0Samples(frameCount: u64, interleaved_stereo_samples: [*]f32) callconv(.c) u64 {
    var frames_read: u64 = undefined;
    const result = miniaudio_c.ma_decoder_read_pcm_frames(&g_sound_decoders[0], interleaved_stereo_samples, frameCount, &frames_read);
    return if (result == miniaudio_c.MA_SUCCESS) frames_read else 0;
}

fn addChannel1Samples(frameCount: u64, interleaved_stereo_samples: [*]f32) callconv(.c) u64 {
    var frames_read: u64 = undefined;
    const result = miniaudio_c.ma_decoder_read_pcm_frames(&g_sound_decoders[1], interleaved_stereo_samples, frameCount, &frames_read);
    return if (result == miniaudio_c.MA_SUCCESS) frames_read else 0;
}

fn addChannel2Samples(frameCount: u64, interleaved_stereo_samples: [*]f32) callconv(.c) u64 {
    var frames_read: u64 = undefined;
    const result = miniaudio_c.ma_decoder_read_pcm_frames(&g_sound_decoders[2], interleaved_stereo_samples, frameCount, &frames_read);
    return if (result == miniaudio_c.MA_SUCCESS) frames_read else 0;
}

fn addChannel3Samples(frameCount: u64, interleaved_stereo_samples: [*]f32) callconv(.c) u64 {
    var frames_read: u64 = undefined;
    const result = miniaudio_c.ma_decoder_read_pcm_frames(&g_sound_decoders[3], interleaved_stereo_samples, frameCount, &frames_read);
    return if (result == miniaudio_c.MA_SUCCESS) frames_read else 0;
}

fn addChannel4Samples(frameCount: u64, interleaved_stereo_samples: [*]f32) callconv(.c) u64 {
    var frames_read: u64 = undefined;
    const result = miniaudio_c.ma_decoder_read_pcm_frames(&g_sound_decoders[4], interleaved_stereo_samples, frameCount, &frames_read);
    return if (result == miniaudio_c.MA_SUCCESS) frames_read else 0;
}

const g_sound_channel_callbacks: [kNUM_SOUND_DECODERS]*const sound_buffer.SoundChannel = .{
    &addChannel0Samples,
    &addChannel1Samples,
    &addChannel2Samples,
    &addChannel3Samples,
    &addChannel4Samples,
};

pub fn init() bool {
    g_sound_is_initialized = true;
    return true;
}

pub fn getIsSoundEnabled() bool {
    return g_sound_is_enabled;
}

pub fn setIsSoundEnabled(is_enabled: bool) void {
    g_sound_is_enabled = is_enabled;
}

pub fn playSoundEffect(sound_index: usize) void {
    if (!g_sound_is_initialized or !g_sound_is_enabled) {
        return;
    }

    assert(sound_index < kNUM_SOUND_DECODERS);

    _ = miniaudio_c.ma_decoder_seek_to_pcm_frame(&g_sound_decoders[sound_index], 0); // TODO: Detect and handle error?
    sound_buffer.setSoundChannel(kSOUND_CHANNEL_START_INDEX + sound_index, g_sound_channel_callbacks[sound_index]);
}

pub fn loadSound(filename: [:0]const u8, sound_index: usize) bool {
    // For now, enable loading sounds even if sounds are not enabled, so we can switch it enabled without having to load sounds again
    if (!g_sound_is_initialized) {
        return false;
    }

    assert(sound_index < kNUM_SOUND_DECODERS);

    sound_buffer.setSoundChannel(kSOUND_CHANNEL_START_INDEX + sound_index, null);
    _ = miniaudio_c.ma_decoder_uninit(&g_sound_decoders[sound_index]); // TODO: Detect and handle error

    const config: miniaudio_c.ma_decoder_config = miniaudio_c.ma_decoder_config_init(miniaudio_c.ma_format_f32, 2, 44100);
    const result: miniaudio_c.ma_result = miniaudio_c.ma_decoder_init_file(filename, &config, &g_sound_decoders[sound_index]);

    return result == miniaudio_c.MA_SUCCESS;
}

pub fn cleanup() void {
    if (!g_sound_is_initialized) {
        return;
    }

    var sound_index: usize = 0;
    while (sound_index < kNUM_SOUND_DECODERS) : (sound_index += 1) {
        miniaudio_c.SetSoundChannel(kSOUND_CHANNEL_START_INDEX + sound_index, null);
        _ = miniaudio_c.ma_decoder_uninit(&g_sound_decoders[sound_index]); // TODO: Detect and handle error
    }

    g_sound_is_initialized = false;
}
