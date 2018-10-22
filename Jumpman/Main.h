#ifndef INCLUDED_JUMPMAN_ZERO_MAIN_H
#define INCLUDED_JUMPMAN_ZERO_MAIN_H

#include <stdbool.h>

#if defined(__cplusplus)
extern "C" {
#endif

// TODO: Should all this be bundled up and passed in, instead of set as global variables?
extern bool g_debug_is_enabled;

extern bool g_game_is_frozen;
extern long g_game_time_inactive;
extern long g_current_fps;

extern char g_game_base_path[300];

extern bool g_sound_effects_are_enabled;
extern bool g_music_is_enabled;
extern int g_save_settings_is_queued;

extern int GameKeys[10];
extern long iLastKey;
extern int iShowFPS;
extern int iKeyLeft, iTappedLeft, iTKeyLeft;
extern int iKeyRight, iTappedRight, iTKeyRight;
extern int iKeyDown, iTappedDown, iTKeyDown;
extern int iKeyUp, iTappedUp, iTKeyUp;
extern int iKeyJump, iTappedJump, iTKeyAttack;
extern int iKeyAttack, iTappedAttack, iTKeyJump;
extern int iKeySelect;

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_MAIN_H
