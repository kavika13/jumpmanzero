const std = @import("std");
const sound_buffer = @import("sound_buffer.zig");
const tml_c = @import("tml_c");
const tsf_c = @import("tsf_c");

const kMIDI_CHANNEL_COUNT: usize = 16;

const MusicTrack = struct {
    sound_font: ?*tsf_c.tsf,
    current_playback_timestamp_msec: f64,
    loop_start_point_msec: u32,
    track_end_point_msec: u32,
    current_tempo_usec_per_quarter_note: i32,
    is_looped: bool,
    first_midi_message: ?*tml_c.tml_message,
    current_midi_message: ?*tml_c.tml_message,
    is_midi_channel_note_on: [kMIDI_CHANNEL_COUNT]bool,
    is_stopping: bool,

    const default: MusicTrack = .{
        .sound_font = null,
        .current_playback_timestamp_msec = 0.0,
        .loop_start_point_msec = 0,
        .track_end_point_msec = 0,
        .current_tempo_usec_per_quarter_note = 0,
        .is_looped = false,
        .first_midi_message = null,
        .current_midi_message = null,
        .is_midi_channel_note_on = @splat(false),
        .is_stopping = false,
    };
};

var g_music_is_initialized: bool = false;
var g_music_is_enabled: bool = false;
var g_track_1: MusicTrack = .default;
var g_track_2: MusicTrack = .default;
var g_current_track_filename: []const u8 = &.{};
var g_current_track_song_start_music_time: i32 = 0;
var g_current_track_loop_start_music_time: i32 = 0;

fn MusicTimeToMilliseconds(first_midi_message: *tml_c.tml_message, music_time_value: i32) u32 {
    const kMUSIC_TIME_PER_QUARTER_NOTE: f64 = 768.0;

    var current_midi_message: *tml_c.tml_message = first_midi_message;
    var current_time_ms: f64 = 0.0;
    var remaining_quarter_notes: f64 = music_time_value / kMUSIC_TIME_PER_QUARTER_NOTE;
    var current_tempo_ms_per_quarter_note: f64 = 500.0;
    var target_time_ms: f64 = current_time_ms + remaining_quarter_notes * current_tempo_ms_per_quarter_note;

    while (current_midi_message.time < target_time_ms) {
        remaining_quarter_notes -= (current_midi_message.time - current_time_ms) / current_tempo_ms_per_quarter_note;
        current_time_ms = current_midi_message.time;
        const new_tempo_ms_per_quarter_note: f64 = @as(f64, @floatFromInt(tml_c.tml_get_tempo_value(current_midi_message))) / 1000.0;
        current_midi_message = current_midi_message.next;

        if (new_tempo_ms_per_quarter_note != 0) { // tml_get_tempo_value returns 0 if not a tempo change
            current_tempo_ms_per_quarter_note = new_tempo_ms_per_quarter_note;
            target_time_ms = current_time_ms + remaining_quarter_notes * current_tempo_ms_per_quarter_note;
        }
    }

    return @intFromFloat(target_time_ms);
}

fn StopAllNotesWithSustainAndRelease(track: *MusicTrack) void {
    if (track.sound_font) |sound_font| {
        tsf_c.tsf_note_off_all(sound_font);
    }

    for (0..kMIDI_CHANNEL_COUNT) |i| {
        track.is_midi_channel_note_on[i] = false;
    }
}

fn SeekTrack(track: *MusicTrack, target_timestamp_msec: u32) void {
    track.current_midi_message = track.first_midi_message;

    while (track.current_midi_message != null and (track.current_midi_message.?.time < target_timestamp_msec)) {
        switch (track.current_midi_message.?.type) {
            tml_c.TML_PROGRAM_CHANGE => {
                _ = tsf_c.tsf_channel_set_presetnumber(track.sound_font, track.current_midi_message.?.channel, track.current_midi_message.?.unnamed_0.unnamed_0.unnamed_0.program, if (track.current_midi_message.?.channel == 9) 1 else 0);
            },
            tml_c.TML_SET_TEMPO => {
                const new_tempo_usec_per_quarter_note: i32 = tml_c.tml_get_tempo_value(track.current_midi_message.?);

                if (new_tempo_usec_per_quarter_note > 0) {
                    track.current_tempo_usec_per_quarter_note = new_tempo_usec_per_quarter_note;
                }
            },
            tml_c.TML_NOTE_ON => {
                track.is_midi_channel_note_on[track.current_midi_message.?.channel] = true;
            },
            tml_c.TML_NOTE_OFF => {
                track.is_midi_channel_note_on[track.current_midi_message.?.channel] = false;
            },
            tml_c.TML_PITCH_BEND => {
                _ = tsf_c.tsf_channel_set_pitchwheel(track.sound_font, track.current_midi_message.?.channel, track.current_midi_message.?.unnamed_0.unnamed_1.pitch_bend);
            },
            tml_c.TML_CONTROL_CHANGE => {
                // TODO: control and control_value are from different unions structs??
                _ = tsf_c.tsf_channel_midi_control(track.sound_font, track.current_midi_message.?.channel, track.current_midi_message.?.unnamed_0.unnamed_0.unnamed_0.control, track.current_midi_message.?.unnamed_0.unnamed_0.unnamed_1.control_value);
            },
            else => {}, // TODO: Anything else that should be handled? Should this assert?
        }

        track.current_midi_message = track.current_midi_message.?.next;
    }

    if (track.current_midi_message != null) {
        track.current_playback_timestamp_msec = track.current_midi_message.?.time;
    }
}

fn AddMidiSamples(sound_channel: usize, track: *MusicTrack, frame_count: usize, interleaved_stereo_samples: [*]f32) usize {
    const TSF_RENDER_EFFECTSAMPLEBLOCK = 64; // TODO: Why isn't this exposed unless implementation is exposed? Isn't it necessary for us to use it?
    var SampleBlock: c_int = TSF_RENDER_EFFECTSAMPLEBLOCK;
    var SampleCount: usize = frame_count;
    var samples_pointer = interleaved_stereo_samples;

    while (SampleCount != 0) : ({
        SampleCount -= @intCast(SampleBlock);
        samples_pointer += @intCast(SampleBlock * 2);
    }) {
        if (SampleBlock > SampleCount) SampleBlock = @intCast(SampleCount);

        if (!track.is_stopping) {
            track.current_playback_timestamp_msec += @as(f64, @floatFromInt(SampleBlock)) * (1000.0 / 44100.0);
            while (track.current_midi_message != null and track.current_playback_timestamp_msec >= track.current_midi_message.?.time) : (track.current_midi_message = track.current_midi_message.?.next) {
                switch (track.current_midi_message.?.type) {
                    tml_c.TML_PROGRAM_CHANGE => {
                        _ = tsf_c.tsf_channel_set_presetnumber(track.sound_font, track.current_midi_message.?.channel, track.current_midi_message.?.unnamed_0.unnamed_0.unnamed_0.program, if (track.current_midi_message.?.channel == 9) 1 else 0);
                    },
                    tml_c.TML_SET_TEMPO => {
                        const new_tempo_usec_per_quarter_note: i32 = tml_c.tml_get_tempo_value(track.current_midi_message.?);

                        if (new_tempo_usec_per_quarter_note > 0) {
                            track.current_tempo_usec_per_quarter_note = new_tempo_usec_per_quarter_note;
                        }
                    },
                    tml_c.TML_NOTE_ON => {
                        track.is_midi_channel_note_on[track.current_midi_message.?.channel] = true;
                        // TODO: key and velocity are from different unions structs??
                        _ = tsf_c.tsf_channel_note_on(track.sound_font, track.current_midi_message.?.channel, track.current_midi_message.?.unnamed_0.unnamed_0.unnamed_0.key, @as(f32, @floatFromInt(track.current_midi_message.?.unnamed_0.unnamed_0.unnamed_1.velocity)) / 127.0);
                    },
                    tml_c.TML_NOTE_OFF => {
                        track.is_midi_channel_note_on[track.current_midi_message.?.channel] = false;
                        _ = tsf_c.tsf_channel_note_off(track.sound_font, track.current_midi_message.?.channel, track.current_midi_message.?.unnamed_0.unnamed_0.unnamed_0.key);
                    },
                    tml_c.TML_PITCH_BEND => {
                        _ = tsf_c.tsf_channel_set_pitchwheel(track.sound_font, track.current_midi_message.?.channel, track.current_midi_message.?.unnamed_0.unnamed_1.pitch_bend);
                    },
                    tml_c.TML_CONTROL_CHANGE => {
                        // TODO: control and control_value are from different unions structs??
                        _ = tsf_c.tsf_channel_midi_control(track.sound_font, track.current_midi_message.?.channel, track.current_midi_message.?.unnamed_0.unnamed_0.unnamed_0.control, track.current_midi_message.?.unnamed_0.unnamed_0.unnamed_1.control_value);
                    },
                    else => {}, // TODO: Anything else that should be handled? Should this assert?
                }
            }
        }

        tsf_c.tsf_render_float(track.sound_font, samples_pointer, SampleBlock, 1);
    }

    if (track.current_midi_message != null and track.current_playback_timestamp_msec > track.track_end_point_msec) {
        if (track.is_looped) {
            var are_any_notes_on: bool = false;

            for (0..kMIDI_CHANNEL_COUNT) |i| {
                are_any_notes_on = track.is_midi_channel_note_on[i];
            }

            // If notes are still on at end, then wait one quarter note before looping
            // TODO: Do we need to wait? If not, we can just force all notes immediately to off/to ring out, and immediately loop.
            //       Not sure there's currently any music files that would exercise this waiting period, so might have to hack one to test
            if (!are_any_notes_on or track.current_playback_timestamp_msec >= track.track_end_point_msec + @as(f64, @floatFromInt(track.current_tempo_usec_per_quarter_note)) / 1000.0) {
                StopAllNotesWithSustainAndRelease(track);
                SeekTrack(track, track.loop_start_point_msec);
            }
        } else {
            track.is_stopping = true;
        }
    }

    if (track.is_stopping and tsf_c.tsf_active_voice_count(track.sound_font) == 0) {
        // Unhook callback - TODO: Better name for these callback functions/callback setup functions. "SetSoundChannel" is a little abstract
        sound_buffer.SetSoundChannel(sound_channel, null);
    }

    return frame_count;
}

fn AddTrack1Samples(frame_count: u64, interleaved_stereo_samples: [*]f32) callconv(.c) usize {
    return AddMidiSamples(0, &g_track_1, frame_count, interleaved_stereo_samples);
}

fn AddTrack2Samples(frame_count: u64, interleaved_stereo_samples: [*]f32) callconv(.c) usize {
    return AddMidiSamples(1, &g_track_2, frame_count, interleaved_stereo_samples);
}

fn LoadAndPlayTrack(filename: []const u8, track: *MusicTrack, start_time_music_time: i32, loop_start_music_time: i32, sound_channel_index: usize, sound_channel: sound_buffer.SoundChannel) void {
    var tiny_midi_loader: ?*tml_c.tml_message = null;
    tiny_midi_loader = tml_c.tml_load_filename(filename.ptr);

    if (tiny_midi_loader == null) {
        std.log.err("Could not load MIDI file\n", .{});
        return;
    }

    var time_length: u32 = undefined;
    _ = tml_c.tml_get_info(tiny_midi_loader.?, null, null, null, null, &time_length);
    track.track_end_point_msec = time_length;
    track.first_midi_message = tiny_midi_loader;
    track.current_midi_message = tiny_midi_loader;
    track.current_playback_timestamp_msec = 0.0;

    if (track.first_midi_message != null and loop_start_music_time >= 0 and loop_start_music_time != 55000) {
        track.loop_start_point_msec = MusicTimeToMilliseconds(track.first_midi_message.?, loop_start_music_time);
        track.is_looped = true;
    } else {
        track.loop_start_point_msec = 0;
        track.is_looped = false;
    }

    if (track.first_midi_message != null and start_time_music_time > 0) {
        const start_time_msec: u32 = MusicTimeToMilliseconds(track.first_midi_message.?, start_time_music_time);
        SeekTrack(track, start_time_msec);
    }

    sound_buffer.SetSoundChannel(sound_channel_index, sound_channel);
    track.is_stopping = false;
}

fn StopTrack(track: *MusicTrack) void {
    StopAllNotesWithSustainAndRelease(track);
    track.is_stopping = true;
}

pub fn InitMusic() bool {
    if (g_music_is_initialized) {
        return true;
    }

    g_track_1 = .default;
    g_track_1.sound_font = tsf_c.tsf_load_filename("sound/reality_gmgs_falcomod.sf2");

    if (g_track_1.sound_font == null) {
        std.log.err("Could not load SoundFont", .{});
        return false;
    }

    _ = tsf_c.tsf_channel_set_bank_preset(g_track_1.sound_font.?, 9, 128, 0);
    tsf_c.tsf_set_output(g_track_1.sound_font, tsf_c.TSF_STEREO_INTERLEAVED, 44100, -10.0);

    g_track_2 = .default;
    g_track_2.sound_font = tsf_c.tsf_load_filename("sound/reality_gmgs_falcomod.sf2");

    if (g_track_2.sound_font == null) {
        std.log.err("Could not load SoundFont", .{});
        return false;
    }

    _ = tsf_c.tsf_channel_set_bank_preset(g_track_2.sound_font.?, 9, 128, 0);
    tsf_c.tsf_set_output(g_track_2.sound_font, tsf_c.TSF_STEREO_INTERLEAVED, 44100, -10.0);

    g_music_is_initialized = true;

    return true;
}

pub fn GetIsMusicEnabled() bool {
    return g_music_is_enabled;
}

pub fn SetIsMusicEnabled(is_enabled: bool) void {
    if (g_music_is_enabled != is_enabled) {
        g_music_is_enabled = is_enabled;

        if (g_music_is_initialized and g_current_track_filename.len != 0) {
            // TODO: Handle track 2?
            if (is_enabled) {
                NewTrack1(g_current_track_filename, g_current_track_song_start_music_time, g_current_track_loop_start_music_time);
            } else {
                StopMusic1();
            }
        }
    }
}

pub fn NewTrack1(filename: []const u8, song_start_music_time: i32, loop_start_music_time: i32) void {
    if (!g_music_is_initialized) {
        return;
    }

    // Enable setting track even if music is not enabled, so we can start the track if we set it enabled again
    g_current_track_filename = filename;
    g_current_track_song_start_music_time = song_start_music_time;
    g_current_track_loop_start_music_time = loop_start_music_time;

    if (!g_music_is_enabled) {
        return;
    }

    StopTrack(&g_track_1);
    tml_c.tml_free(g_track_1.first_midi_message);

    LoadAndPlayTrack(filename, &g_track_1, song_start_music_time, loop_start_music_time, 0, AddTrack1Samples);
}

pub fn NewTrack2(filename: []const u8) void {
    if (!g_music_is_initialized) {
        return;
    }

    // Enable setting track even if music is not enabled, so we can start the track if we set it enabled again
    g_current_track_filename = filename;
    g_current_track_song_start_music_time = 0;
    g_current_track_loop_start_music_time = 0;

    if (!g_music_is_enabled) {
        return;
    }

    StopTrack(&g_track_2);
    tml_c.tml_free(g_track_2.first_midi_message);

    LoadAndPlayTrack(filename, &g_track_2, 0, -1, 1, AddTrack2Samples);
}

pub fn StopMusic1() void {
    if (!g_music_is_initialized) {
        return;
    }

    // Enable stopping track even if music is not enabled
    g_current_track_filename = &.{};
    g_current_track_song_start_music_time = 0;
    g_current_track_loop_start_music_time = 0;

    if (!g_music_is_enabled) {
        return;
    }

    StopTrack(&g_track_1);
}

pub fn CleanUpMusic() void {
    if (!g_music_is_initialized) {
        return;
    }

    sound_buffer.SetSoundChannel(0, null);
    sound_buffer.SetSoundChannel(1, null);
    tsf_c.tsf_reset(g_track_1.sound_font);
    tsf_c.tsf_reset(g_track_2.sound_font);
    tsf_c.tsf_close(g_track_1.sound_font);
    tsf_c.tsf_close(g_track_2.sound_font);
    tml_c.tml_free(g_track_1.first_midi_message);
    tml_c.tml_free(g_track_2.first_midi_message);
    g_track_1 = .default;
    g_track_2 = .default;

    g_music_is_initialized = false;
}

pub fn CleanupMusic() void {
    if (!g_music_is_initialized) {
        return;
    }

    sound_buffer.SetSoundChannel(0, null);
    sound_buffer.SetSoundChannel(1, null);
    tsf_c.tsf_reset(g_track_1.sound_font);
    tsf_c.tsf_reset(g_track_2.sound_font);
    tsf_c.tsf_close(g_track_1.sound_font);
    tsf_c.tsf_close(g_track_2.sound_font);
    tml_c.tml_free(g_track_1.first_midi_message);
    tml_c.tml_free(g_track_2.first_midi_message);
    g_track_1 = .default;
    g_track_2 = .default;

    g_music_is_initialized = false;
}
