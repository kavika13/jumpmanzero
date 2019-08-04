#ifndef INCLUDED_JUMPMAN_ZERO_SCRIPT_H
#define INCLUDED_JUMPMAN_ZERO_SCRIPT_H

#include "Input.h"

#if defined(__cplusplus)
extern "C" {
#endif

typedef struct {
    int Subs;
    int SubStart[50];
    char SubName[50][20];
    long Code[8000];
} ScriptCode;

typedef struct {
    long Done;

    long SP;
    long BP;
    long IP;

    long CS[1000];
    long CallStack;

    long Stack[5000];
    long Globals[500];

    long ScriptNumber;
    long ScriptReference;

    long Active;

    ScriptCode* Script;
    char game_base_path[300];  // TODO: This doesn't have to be per-script
} ScriptContext;

void ResetContext(ScriptContext* script_context, const char* base_path);
void LoadScript(const char* base_path, const char* filename, ScriptCode* oScript);
void RunScript(ScriptContext* SC, long iSub, GameInput* game_input);
int FindScript(ScriptContext* SC, char* sFunc);

#if defined(__cplusplus)
}  // extern "C"
#endif


#endif  // INCLUDED_JUMPMAN_ZERO_SCRIPT_H
