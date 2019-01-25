#ifndef INCLUDED_JUMPMAN_ZERO_INPUT_H
#define INCLUDED_JUMPMAN_ZERO_INPUT_H

#include <stdbool.h>

#if defined(__cplusplus)
extern "C" {
#endif

typedef struct {
    int key_bindings[10];
} GameInput;

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_INPUT_H
