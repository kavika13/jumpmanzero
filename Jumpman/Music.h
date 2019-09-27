#ifndef INCLUDED_JUMPMAN_ZERO_MUSIC_H
#define INCLUDED_JUMPMAN_ZERO_MUSIC_H

#include <stdbool.h>

#if defined(__cplusplus)
extern "C" {
#endif

bool InitMusic(void);
bool GetIsMusicEnabled(void);
void SetIsMusicEnabled(bool is_enabled);
void CleanUpMusic(void);
void NewTrack1(const char* filename, unsigned int song_start_music_time, int loop_start_music_time);
void NewTrack2(const char* filename);
void StopMusic1(void);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_MUSIC_H
