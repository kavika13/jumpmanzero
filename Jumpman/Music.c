#include <assert.h>
#define TSF_IMPLEMENTATION
#include "tsf.h"
#define TML_IMPLEMENTATION
#include "tml.h"
#include "SoundBuffer.h"

#define kMIDI_CHANNEL_COUNT 16

typedef struct {
    tsf* sound_font;
    double current_playback_timestamp_msec;
    unsigned int loop_start_point_msec;
    unsigned int track_end_point_msec;
    unsigned int current_tempo_usec_per_quarter_note;
    bool is_looped;
    tml_message* first_midi_message;
    tml_message* current_midi_message;
    bool is_midi_channel_note_on[kMIDI_CHANNEL_COUNT];
    bool is_stopping;
} MusicTrack;

static MusicTrack g_track_1;
static MusicTrack g_track_2;

static unsigned int MusicTimeToMilliseconds(tml_message* first_midi_message, unsigned int music_time_value) {
    const double kMUSIC_TIME_PER_QUARTER_NOTE = 768.0;

    tml_message* current_midi_message = first_midi_message;
    double current_time_ms = 0.0;
    double remaining_quarter_notes = music_time_value / kMUSIC_TIME_PER_QUARTER_NOTE;
    double current_tempo_ms_per_quarter_note = 500.0;
    double target_time_ms = current_time_ms + remaining_quarter_notes * current_tempo_ms_per_quarter_note;

    while(current_midi_message != NULL && current_midi_message->time < target_time_ms) {
        remaining_quarter_notes -= (current_midi_message->time - current_time_ms) / current_tempo_ms_per_quarter_note;
        current_time_ms = current_midi_message->time;
        double new_tempo_ms_per_quarter_note = tml_get_tempo_value(current_midi_message) / 1000.0;
        current_midi_message = current_midi_message->next;

        if(new_tempo_ms_per_quarter_note != 0) {  // tml_get_tempo_value returns 0 if not a tempo change
            current_tempo_ms_per_quarter_note = new_tempo_ms_per_quarter_note;
            target_time_ms = current_time_ms + remaining_quarter_notes * current_tempo_ms_per_quarter_note;
        }
    }

    return (unsigned int)target_time_ms;
}

static void StopAllNotesWithSustainAndRelease(MusicTrack* track) {
    for(int i = 0; i < track->sound_font->channels->channelNum; ++i) {
        tsf_channel_note_off_all(track->sound_font, i);
    }

    for(int i = 0; i < kMIDI_CHANNEL_COUNT; ++i) {
        track->is_midi_channel_note_on[i] = false;
    }
}

static void SeekTrack(MusicTrack* track, unsigned int target_timestamp_msec) {
    assert(track);

    track->current_midi_message = track->first_midi_message;

    while(track->current_midi_message && (track->current_midi_message->time < target_timestamp_msec)) {
        switch (track->current_midi_message->type) {
            case TML_PROGRAM_CHANGE:
                tsf_channel_set_presetnumber(track->sound_font, track->current_midi_message->channel, track->current_midi_message->program, (track->current_midi_message->channel == 9));
                break;
            case TML_SET_TEMPO: {
                int new_tempo_usec_per_quarter_note = tml_get_tempo_value(track->current_midi_message);

                if(new_tempo_usec_per_quarter_note > 0) {
                    track->current_tempo_usec_per_quarter_note = new_tempo_usec_per_quarter_note;
                }

                break;
            }
            case TML_NOTE_ON:
                track->is_midi_channel_note_on[track->current_midi_message->channel] = true;
                break;
            case TML_NOTE_OFF:
                track->is_midi_channel_note_on[track->current_midi_message->channel] = false;
                break;
            case TML_PITCH_BEND:
                tsf_channel_set_pitchwheel(track->sound_font, track->current_midi_message->channel, track->current_midi_message->pitch_bend);
                break;
            case TML_CONTROL_CHANGE:
                tsf_channel_midi_control(track->sound_font, track->current_midi_message->channel, track->current_midi_message->control, track->current_midi_message->control_value);
                break;
        }

        track->current_midi_message = track->current_midi_message->next;
    }

    if(track->current_midi_message) {
        track->current_playback_timestamp_msec = track->current_midi_message->time;
    }
}

static uint32_t AddMidiSamples(size_t sound_channel, MusicTrack* track, uint32_t frameCount, float* interleaved_stereo_samples) {
    assert(track);

    int SampleBlock, SampleCount = frameCount;

    for(SampleBlock = TSF_RENDER_EFFECTSAMPLEBLOCK; SampleCount; SampleCount -= SampleBlock, interleaved_stereo_samples += (SampleBlock * 2)) {
        if(SampleBlock > SampleCount) SampleBlock = SampleCount;

        if(!track->is_stopping) {
            for(track->current_playback_timestamp_msec += SampleBlock * (1000.0 / 44100.0); track->current_midi_message && track->current_playback_timestamp_msec >= track->current_midi_message->time; track->current_midi_message = track->current_midi_message->next) {
                switch (track->current_midi_message->type) {
                    case TML_PROGRAM_CHANGE:
                        tsf_channel_set_presetnumber(track->sound_font, track->current_midi_message->channel, track->current_midi_message->program, (track->current_midi_message->channel == 9));
                        break;
                    case TML_SET_TEMPO: {
                        int new_tempo_usec_per_quarter_note = tml_get_tempo_value(track->current_midi_message);

                        if(new_tempo_usec_per_quarter_note > 0) {
                            track->current_tempo_usec_per_quarter_note = new_tempo_usec_per_quarter_note;
                        }

                        break;
                    }
                    case TML_NOTE_ON:
                        track->is_midi_channel_note_on[track->current_midi_message->channel] = true;
                        tsf_channel_note_on(track->sound_font, track->current_midi_message->channel, track->current_midi_message->key, track->current_midi_message->velocity / 127.0f);
                        break;
                    case TML_NOTE_OFF:
                        track->is_midi_channel_note_on[track->current_midi_message->channel] = false;
                        tsf_channel_note_off(track->sound_font, track->current_midi_message->channel, track->current_midi_message->key);
                        break;
                    case TML_PITCH_BEND:
                        tsf_channel_set_pitchwheel(track->sound_font, track->current_midi_message->channel, track->current_midi_message->pitch_bend);
                        break;
                    case TML_CONTROL_CHANGE:
                        tsf_channel_midi_control(track->sound_font, track->current_midi_message->channel, track->current_midi_message->control, track->current_midi_message->control_value);
                        break;
                }
            }
        }

        tsf_render_float(track->sound_font, interleaved_stereo_samples, SampleBlock, 1);
    }

    if(!track->current_midi_message && track->current_playback_timestamp_msec > track->track_end_point_msec) {
        if(track->is_looped) {
            bool are_any_notes_on = false;

            for(size_t i = 0; i < kMIDI_CHANNEL_COUNT; ++i) {
                are_any_notes_on = track->is_midi_channel_note_on[i];
            }

            // If notes are still on at end, then wait one quarter note before looping
            // TODO: Do we need to wait? If not, we can just force all notes immediately to off/to ring out, and immediately loop.
            //       Not sure there's currently any music files that would exercise this waiting period, so might have to hack one to test
            if(!are_any_notes_on || track->current_playback_timestamp_msec >= track->track_end_point_msec + track->current_tempo_usec_per_quarter_note / 1000.0) {
                StopAllNotesWithSustainAndRelease(track);
                SeekTrack(track, track->loop_start_point_msec);
            }
        } else {
            track->is_stopping = true;
        }
    }

    if(track->is_stopping && tsf_active_voice_count(track->sound_font) == 0) {
        // Unhook callback - TODO: Better name for these callback functions/callback setup functions. "SetSoundChannel" is a little abstract
        SetSoundChannel(sound_channel, NULL);
    }

    return frameCount;
}

static uint32_t AddTrack1Samples(uint32_t frameCount, float* interleaved_stereo_samples) {
    return AddMidiSamples(0, &g_track_1, frameCount, interleaved_stereo_samples);
}

static uint32_t AddTrack2Samples(uint32_t frameCount, float* interleaved_stereo_samples) {
    return AddMidiSamples(1, &g_track_2, frameCount, interleaved_stereo_samples);
}

static void LoadAndPlayTrack(const char* filename, MusicTrack* track, int start_time_msec, int sound_channel_index, SoundChannel sound_channel) {
    tml_message* tiny_midi_loader = NULL;
    tiny_midi_loader = tml_load_filename(filename);

    if(!tiny_midi_loader) {
        // TODO: fprintf(stderr, "Could not load MIDI file\n");
        return;
    }

    unsigned int time_length;
    tml_get_info(tiny_midi_loader, NULL, NULL, NULL, NULL, &time_length);
    track->track_end_point_msec = time_length;
    track->current_midi_message = track->first_midi_message = tiny_midi_loader;
    track->current_playback_timestamp_msec = 0.0;

    if(start_time_msec > 0) {
        SeekTrack(track, start_time_msec);
    }

    SetSoundChannel(sound_channel_index, sound_channel);
    track->is_stopping = false;
}

static void StopTrack(MusicTrack* track) {
    assert(track);
    StopAllNotesWithSustainAndRelease(track);
    track->is_stopping = true;
}

bool InitMusic() {
    g_track_1 = (const MusicTrack){ 0 };
    g_track_1.sound_font = tsf_load_filename("Sound/Reality_GMGS_falcomod.sf2");

    if(!g_track_1.sound_font) {
        // TODO: fprintf(stderr, "Could not load SoundFont\n");
        return false;
    }

    tsf_channel_set_bank_preset(g_track_1.sound_font, 9, 128, 0);
    tsf_set_output(g_track_1.sound_font, TSF_STEREO_INTERLEAVED, 44100, 0.0f);

    g_track_2 = (const MusicTrack){ 0 };
    g_track_2.sound_font = tsf_load_filename("Sound/Reality_GMGS_falcomod.sf2");

    if(!g_track_2.sound_font) {
        // TODO: fprintf(stderr, "Could not load SoundFont\n");
        return false;
    }

    tsf_channel_set_bank_preset(g_track_2.sound_font, 9, 128, 0);
    tsf_set_output(g_track_2.sound_font, TSF_STEREO_INTERLEAVED, 44100, 0.0f);

    return true;
}

void NewTrack1(const char* filename, unsigned int song_start_music_time, unsigned int loop_start_music_time) {
    StopTrack(&g_track_1);
    tml_free(g_track_1.first_midi_message);

    if(loop_start_music_time >= 0 && loop_start_music_time != 55000) {
        g_track_1.loop_start_point_msec = MusicTimeToMilliseconds(g_track_1.first_midi_message, loop_start_music_time);
        g_track_1.is_looped = true;
    } else {
        g_track_1.loop_start_point_msec = 0;
        g_track_1.is_looped = false;
    }

    LoadAndPlayTrack(filename, &g_track_1, MusicTimeToMilliseconds(g_track_1.first_midi_message, song_start_music_time), 0, AddTrack1Samples);
}

void NewTrack2(const char* filename) {
    StopTrack(&g_track_2);
    tml_free(g_track_2.first_midi_message);

    g_track_2.loop_start_point_msec = 0;
    g_track_2.is_looped = false;

    LoadAndPlayTrack(filename, &g_track_2, 0, 1, AddTrack2Samples);
}

void StopMusic1() {
    StopTrack(&g_track_1);
}

void CleanUpMusic() {
    SetSoundChannel(0, NULL);
    SetSoundChannel(1, NULL);
    tsf_reset(g_track_1.sound_font);
    tsf_reset(g_track_2.sound_font);
    tsf_close(g_track_1.sound_font);
    tsf_close(g_track_2.sound_font);
    tml_free(g_track_1.first_midi_message);
    tml_free(g_track_2.first_midi_message);
    g_track_1 = (const MusicTrack){ 0 };
    g_track_2 = (const MusicTrack){ 0 };
}
