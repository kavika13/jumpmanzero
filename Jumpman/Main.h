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
extern bool g_save_settings_is_queued;
extern bool g_show_fps_is_enabled;

extern int iTKeyLeft;
extern int iTKeyRight;
extern int iTKeyDown;
extern int iTKeyUp;
extern int iTKeyAttack;
extern int iTKeyJump;
extern int iKeySelect;

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_MAIN_H
