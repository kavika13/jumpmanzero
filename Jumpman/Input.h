#ifndef INCLUDED_JUMPMAN_ZERO_INPUT_H
#define INCLUDED_JUMPMAN_ZERO_INPUT_H

#include <stdbool.h>

#if defined(__cplusplus)
extern "C" {
#endif

typedef struct {
    int key_bindings[10];
    long last_key_pressed;
} GameRawInput;

typedef struct {
    bool is_pressed;
    bool just_pressed;
} GameAction;

typedef struct {
    GameRawInput raw_input;
    GameAction move_left_action;
    GameAction move_right_action;
    GameAction move_down_action;
    GameAction move_up_action;
    GameAction jump_action;
    GameAction attack_action;
    GameAction select_action;
} GameInput;

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_INPUT_H
