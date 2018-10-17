#include <assert.h>
#define TSF_IMPLEMENTATION
#include "tsf.h"
#define TML_IMPLEMENTATION
#include "tml.h"
#include "jumpman.h"
#include "SoundBuffer.h"

struct MusicTrack {
    tsf* sound_font;
    double current_playback_timestamp_msec;
    unsigned int loop_start_point_msec;
    unsigned int track_end_point_msec;
    bool is_looped;
    tml_message* first_midi_message;
    tml_message* current_midi_message;
    bool is_stopping;
};

static MusicTrack g_track_1;
static MusicTrack g_track_2;

static void SeekTrack(MusicTrack* track, unsigned int target_timestamp_msec) {
    assert(track);

    track->current_midi_message = track->first_midi_message;

    while(track->current_midi_message && (track->current_midi_message->time < target_timestamp_msec)) {
        switch (track->current_midi_message->type) {
            case TML_PROGRAM_CHANGE:
                tsf_channel_set_presetnumber(track->sound_font, track->current_midi_message->channel, track->current_midi_message->program, (track->current_midi_message->channel == 9));
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

    for (SampleBlock = TSF_RENDER_EFFECTSAMPLEBLOCK; SampleCount; SampleCount -= SampleBlock, interleaved_stereo_samples += (SampleBlock * 2)) {
        if (SampleBlock > SampleCount) SampleBlock = SampleCount;

        if (!track->is_stopping) {
            for (track->current_playback_timestamp_msec += SampleBlock * (1000.0 / 44100.0); track->current_midi_message && track->current_playback_timestamp_msec >= track->current_midi_message->time; track->current_midi_message = track->current_midi_message->next)
            {
                switch (track->current_midi_message->type)
                {
                case TML_PROGRAM_CHANGE:
                    tsf_channel_set_presetnumber(track->sound_font, track->current_midi_message->channel, track->current_midi_message->program, (track->current_midi_message->channel == 9));
                    break;
                case TML_NOTE_ON:
                    tsf_channel_note_on(track->sound_font, track->current_midi_message->channel, track->current_midi_message->key, track->current_midi_message->velocity / 127.0f);
                    break;
                case TML_NOTE_OFF:
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

    // TODO: Wait for final note to finish before looping? Might require us to know tempo, and/or MUSIC_TIME -> msec to get it right
    if(!track->current_midi_message && track->current_playback_timestamp_msec > track->track_end_point_msec) {
        if(track->is_looped) {
            SeekTrack(track, track->loop_start_point_msec);
        } else {
            track->is_stopping = true;
        }
    }

    if (track->is_stopping) {
        bool all_voices_are_done = true;

        for (int i = 0; i < track->sound_font->voiceNum; ++i) {
            if (track->sound_font->voices[i].playingPreset != -1 && track->sound_font->voices[i].ampenv.segment != TSF_SEGMENT_DONE) {
                all_voices_are_done = false;
                break;
            }
        }

        if (all_voices_are_done) {
            SetSoundChannel(sound_channel, NULL);
        }
    }

    return frameCount;
}

static uint32_t add_track_1_samples(uint32_t frameCount, float* interleaved_stereo_samples) {
    return AddMidiSamples(0, &g_track_1, frameCount, interleaved_stereo_samples);
}

static uint32_t add_track_2_samples(uint32_t frameCount, float* interleaved_stereo_samples) {
    return AddMidiSamples(1, &g_track_2, frameCount, interleaved_stereo_samples);
}

static void LoadAndPlayTrack(const char* filename, MusicTrack* track, int start_time_msec, int sound_channel_index, SoundChannel sound_channel) {
    tml_message* tiny_midi_loader = NULL;
    tiny_midi_loader = tml_load_filename(filename);

    if (!tiny_midi_loader) {
        // TODO: fprintf(stderr, "Could not load MIDI file\n");
        return;
    }

    unsigned int time_length;
    tml_get_info(tiny_midi_loader, NULL, NULL, NULL, NULL, &time_length);
    track->track_end_point_msec = time_length;
    track->current_midi_message = track->first_midi_message = tiny_midi_loader;
    track->current_playback_timestamp_msec = 0.0;

    if (start_time_msec > 0) {
        SeekTrack(track, start_time_msec);
    }

    SetSoundChannel(sound_channel_index, sound_channel);
    track->is_stopping = false;
}

static void StopTrack(MusicTrack* track) {
    assert(track);

    for (int i = 0; i < track->sound_font->channels->channelNum; ++i) {
        tsf_channel_note_off_all(track->sound_font, i);
    }

    track->is_stopping = true;
}

bool InitMusic() {
    bool result = InitSoundBuffer();

    if (!result) {
        return false;
    }

    g_track_1 = { 0 };
    g_track_1.sound_font = tsf_load_filename("Sound/Reality_GMGS_falcomod.sf2");

    if(!g_track_1.sound_font) {
        // TODO: fprintf(stderr, "Could not load SoundFont\n");
        return false;
    }

    tsf_channel_set_bank_preset(g_track_1.sound_font, 9, 128, 0);
    tsf_set_output(g_track_1.sound_font, TSF_STEREO_INTERLEAVED, 44100);

    g_track_2 = { 0 };
    g_track_2.sound_font = tsf_load_filename("Sound/Reality_GMGS_falcomod.sf2");

    if (!g_track_2.sound_font) {
        // TODO: fprintf(stderr, "Could not load SoundFont\n");
        return false;
    }

    tsf_channel_set_bank_preset(g_track_2.sound_font, 9, 128, 0);
    tsf_set_output(g_track_2.sound_font, TSF_STEREO_INTERLEAVED, 44100);

    return true;
}

void NewTrack1(char* filename, long song_start_music_time, long loop_start_music_time) {
    StopTrack(&g_track_1);
    tml_free(g_track_1.first_midi_message);

    if(loop_start_music_time >= 0 && loop_start_music_time != 55000) {
        // TODO: Fix. MUSIC_TIME -> msec. Right now is hard-coded to 120 BPM, with no tempo changes (time * 500 / 768)
        g_track_1.loop_start_point_msec = (unsigned int)(loop_start_music_time * 500.0 / 768.0);
        g_track_1.is_looped = true;
    } else {
        g_track_1.loop_start_point_msec = 0;
        g_track_1.is_looped = false;
    }

    // TODO: Fix. MUSIC_TIME -> msec. Right now is hard-coded to 120 BPM, with no tempo changes (time * 500 / 768)
    LoadAndPlayTrack(filename, &g_track_1, (unsigned int)(song_start_music_time * 500.0 / 768.0), 0, add_track_1_samples);
}

void NewTrack2(char* filename) {
    StopTrack(&g_track_2);
    tml_free(g_track_2.first_midi_message);

    g_track_2.loop_start_point_msec = 0;
    g_track_2.is_looped = false;

    LoadAndPlayTrack(filename, &g_track_2, 0, 1, add_track_2_samples);
}

void StopMusic1() {
    StopTrack(&g_track_1);
}

void CleanUpMusic() {
    tsf_close(g_track_1.sound_font);
    tsf_close(g_track_2.sound_font);
    tml_free(g_track_1.first_midi_message);
    tml_free(g_track_2.first_midi_message);
    g_track_1 = { 0 };
    g_track_2 = { 0 };
}
