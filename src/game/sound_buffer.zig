const std = @import("std");
const assert = std.debug.assert;
const sound = @import("sound.zig");
const jumpman_sound_buffer_c = @cImport({
    // No AVX2 or greater for better backward compatibility
    @cDefine("MAL_NO_AVX2", {});
    @cInclude("miniaudio.h");
});

pub const kSOUND_CHANNEL_COUNT: usize = 64;
pub const SoundChannel = fn (frameCount: u64, interleaved_stereo_samples: [*]f32) callconv(.C) u64; // TODO: Make not export

var g_is_initialized: bool = false;
var g_sound_device = std.mem.zeroes(jumpman_sound_buffer_c.ma_device);
var g_sound_channels = std.mem.zeroes([kSOUND_CHANNEL_COUNT]?*const SoundChannel);
var g_temporary_sample_buffer: ?[*]f32 = null;
var g_temporary_sample_buffer_byte_count: usize = 0;

// TODO: Take allocator somehow?
fn on_send_frames_to_device(_: ?*anyopaque, pOutput: ?*anyopaque, _: ?*const anyopaque, frame_count: u32) callconv(.C) void {
    const output: [*]f32 = @alignCast(@ptrCast(pOutput));

    var i: u32 = 0;
    while (i < frame_count) : (i += 1) {
        output[i * 2 + 0] = 0.0;
        output[i * 2 + 1] = 0.0;
    }

    // TODO: Don't need to use byte counts, since allocated buffers can be strongly typed in zig.
    //       Still will need to use frame_count * 2 though.
    const buffer_byte_count: usize = frame_count * @sizeOf(f32) * 2;

    if (g_temporary_sample_buffer_byte_count < buffer_byte_count) {
        if (g_temporary_sample_buffer != null) {
            std.heap.raw_c_allocator.free(g_temporary_sample_buffer.?[0..g_temporary_sample_buffer_byte_count]);
        }
        g_temporary_sample_buffer = @alignCast(@ptrCast(std.heap.raw_c_allocator.alloc(u8, buffer_byte_count) catch @panic("oom"))); // TODO: Don't panic?
        g_temporary_sample_buffer_byte_count = buffer_byte_count;
    }

    const hard_coded_channel_gain: f32 = 0.8; // TODO: Expose gain interface?

    i = 0;
    while (i < kSOUND_CHANNEL_COUNT) : (i += 1) {
        @memset(g_temporary_sample_buffer.?[0 .. buffer_byte_count / @sizeOf(f32)], 0);

        if (g_sound_channels[i]) |sound_channel| {
            _ = sound_channel(frame_count, g_temporary_sample_buffer.?);

            var current_frame_index: usize = 0;
            while (current_frame_index < frame_count) : (current_frame_index += 1) {
                output[current_frame_index * 2 + 0] += g_temporary_sample_buffer.?[current_frame_index * 2 + 0] * hard_coded_channel_gain;
                output[current_frame_index * 2 + 1] += g_temporary_sample_buffer.?[current_frame_index * 2 + 1] * hard_coded_channel_gain;
            }
        }
    }

    var current_frame_index: usize = 0;
    while (current_frame_index < frame_count) : (current_frame_index += 1) {
        output[current_frame_index * 2 + 0] = @max(-1.0, @min(1.0, output[current_frame_index * 2 + 0]));
        output[current_frame_index * 2 + 1] = @max(-1.0, @min(1.0, output[current_frame_index * 2 + 1]));
    }
}

pub fn InitSoundBuffer() bool {
    if (!g_is_initialized) {
        var config: jumpman_sound_buffer_c.ma_device_config = jumpman_sound_buffer_c.ma_device_config_init(jumpman_sound_buffer_c.ma_device_type_playback); // TODO: This is the problem line. Causing circular dependencies in the C code?
        config.playback.format = jumpman_sound_buffer_c.ma_format_f32;
        config.playback.channels = 2;
        config.sampleRate = 44100;
        config.dataCallback = on_send_frames_to_device;

        if (jumpman_sound_buffer_c.ma_device_init(null, &config, &g_sound_device) != jumpman_sound_buffer_c.MA_SUCCESS) {
            // TODO: printf("Failed to open playback device.\n");
            return false;
        }

        if (jumpman_sound_buffer_c.ma_device_start(&g_sound_device) != jumpman_sound_buffer_c.MA_SUCCESS) {
            // TODO: printf("Failed to start playback device.\n");
            jumpman_sound_buffer_c.ma_device_uninit(&g_sound_device);
            return false;
        }

        var i: usize = 0;
        while (i < kSOUND_CHANNEL_COUNT) : (i += 1) {
            g_sound_channels[i] = null;
        }

        g_is_initialized = true;
    }

    return true;
}

pub fn CleanupSoundBuffer() void {
    jumpman_sound_buffer_c.ma_device_uninit(&g_sound_device);
    g_is_initialized = false;
}

pub export fn SetSoundChannel(channel_index: usize, new_channel_node: ?*const SoundChannel) void { // TODO: Make not export
    assert(channel_index < kSOUND_CHANNEL_COUNT);
    g_sound_channels[channel_index] = new_channel_node;
}
