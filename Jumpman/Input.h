#ifndef INCLUDED_JUMPMAN_ZERO_INPUT_H
#define INCLUDED_JUMPMAN_ZERO_INPUT_H

#include <stdbool.h>

#if defined(__cplusplus)
extern "C" {
#endif

typedef struct {
    bool is_pressed;
    bool just_pressed;
} GameAction;

typedef struct {
    float x;
    float y;
} GameCursorPosition;

typedef struct {
    GameAction move_left_action;
    GameAction move_right_action;
    GameAction move_down_action;
    GameAction move_up_action;
    GameAction jump_action;
    GameAction attack_action;
    GameAction select_action;
    GameAction slowmo_action;
    GameAction debug_action;
    GameAction cheat_action;
    GameAction cursor_select_action;
    GameCursorPosition cursor_position;
    bool cursor_is_on_screen;
} GameInput;

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_INPUT_H
