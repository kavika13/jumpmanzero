
const int kERROR_NO_ERROR = 0;
const int kERROR_INVALID_ARUGMENTS = 1;
const int kERROR_INPUT_FILE_MISSING = 2;
const int kERROR_ALLOCATION_FAILED = 3;
const int kERROR_TOO_MANY_INSTRUCTIONS = 4;

// TODO: Remove this temp code
#include <inttypes.h>
#include <stdbool.h>
#include <stdio.h>  // TODO: Warning! CRT dependency?
#include <stdlib.h>  // TODO: Warning! CRT dependency?
#include <string.h>  // TODO: Warning! CRT dependency?

#define kGLOBAL_VARIABLE_COUNT 500
#define kMAX_CODE_DATA_SIZE 8000

typedef struct {
    size_t subroutine_count;
    int32_t subroutine_start_instruction_index[50];
    char subroutine_name[50][20];

    size_t goto_label_count;
    int32_t goto_label_instruction_index[100];  // TODO: Increase?
    char goto_label_name[100][20];  // TODO: Increase count?

    size_t code_size;
    int32_t code[kMAX_CODE_DATA_SIZE];
}  script_code;

typedef struct {
    bool is_terminated;

    long stack_pointer;
    long base_pointer;
    int32_t current_instruction_index;

    long call_stack[1000];  // Holds instruction indices
    long current_call_stack_index;

    int32_t local_variable_stack[5000];
    int32_t global_variables[kGLOBAL_VARIABLE_COUNT];

    script_code* script;
} script_context;

#define kINSTRUCTION_BASECN 2
#define kINSTRUCTION_STACKCN 3

#define kINSTRUCTION_MOVBCCN 10
#define kINSTRUCTION_MOVSCCN 11
#define kINSTRUCTION_MOVBSSC 12
#define kINSTRUCTION_MOVSCBC 13
#define kINSTRUCTION_MOVSCSC 14

#define kINSTRUCTION_MOVGCCN 20
#define kINSTRUCTION_MOVGSSC 21
#define kINSTRUCTION_MOVSCGC 22
#define kINSTRUCTION_MOVGCSC 23

#define kINSTRUCTION_ADDSCCN 30

#define kINSTRUCTION_ADDSCSC 40
#define kINSTRUCTION_MULSCSC 41
#define kINSTRUCTION_SUBSCSC 42
#define kINSTRUCTION_DIVSCSC 43
#define kINSTRUCTION_MOVSCGS 44
#define kINSTRUCTION_MOVSCBS 45

#define kINSTRUCTION_BANDSCSC 46

#define kINSTRUCTION_JUMPZ 50
#define kINSTRUCTION_JUMPNZ 51
#define kINSTRUCTION_JUMP 52

#define kINSTRUCTION_EQUSCSC 60
#define kINSTRUCTION_NEQSCSC 61
#define kINSTRUCTION_GTSCSC 62
#define kINSTRUCTION_GTESCSC 63
#define kINSTRUCTION_ORSCSC 64
#define kINSTRUCTION_ANDSCSC 65
#define kINSTRUCTION_CALL 70
#define kINSTRUCTION_RET 71

#define kINSTRUCTION_CALL_ENGINE_FUNCTION 100



#define kENGINE_FUNCTION_DEBUG_PRINT 1
#define kENGINE_FUNCTION_SET 2
#define kENGINE_FUNCTION_SET_SELECTED_LEVEL_OBJECT_FIELD 3
#define kENGINE_FUNCTION_GET 8
#define kENGINE_FUNCTION_GET_SELECTED_LEVEL_OBJECT_FIELD 9
#define kENGINE_FUNCTION_GETNAVDIR 10
#define kENGINE_FUNCTION_STRCOPY 11
#define kENGINE_FUNCTION_STRCAT 12

#define kENGINE_FUNCTION_SELECT_PLATFORM_BY_ID 32
#define kENGINE_FUNCTION_SELECT_LADDER_BY_ID 33
#define kENGINE_FUNCTION_SELECT_DONUT_BY_ID 34
#define kENGINE_FUNCTION_SELECT_PLATFORM_BY_INDEX 35
#define kENGINE_FUNCTION_PLAYER_COLLIDE 36
#define kENGINE_FUNCTION_PLAYER_KILL 37
#define kENGINE_FUNCTION_SELECT_VINE_BY_ID 38
#define kENGINE_FUNCTION_SELECT_LADDER_BY_INDEX 39
#define kENGINE_FUNCTION_SPAWN 40
#define kENGINE_FUNCTION_NEWMESH 41
#define kENGINE_FUNCTION_SET_OBJECT_DATA 42
#define kENGINE_FUNCTION_PLAY_SOUND 43
#define kENGINE_FUNCTION_SETDATA 44
#define kENGINE_FUNCTION_GETDATA 45
#define kENGINE_FUNCTION_SELECT_DONUT_BY_INDEX 46
#define kENGINE_FUNCTION_COLLIDE_WALL 47
#define kENGINE_FUNCTION_SELECT_PICTURE_BY_ID 48
#define kENGINE_FUNCTION_MOVE_OBJECT_TO_FRONT 49
#define kENGINE_FUNCTION_SELECT_WALL_BY_ID 51
#define kENGINE_FUNCTION_SELECT_OBJECT_MESH_BY_INDEX 52
#define kENGINE_FUNCTION_DELETE_MESH 53
#define kENGINE_FUNCTION_DELETE_SCRIPT_CONTEXT 54
// TODO: Rename this next thing
#define kSCRIPT_CURRENT_CONTEXT 1000
#define kENGINE_FUNCTION_WIN_LEVEL 55
#define kENGINE_FUNCTION_SELECT_VINE_BY_INDEX 56
#define kENGINE_FUNCTION_SERVICE_FUNCTION 57
#define kENGINE_FUNCTION_NEW_TEXT_GLYPH_MESH 58
#define kENGINE_FUNCTION_RESET_PERSPECTIVE 59

#define kENGINE_FUNCTION_ROTATEX 64
#define kENGINE_FUNCTION_ROTATEY 65
#define kENGINE_FUNCTION_ROTATEZ 66
#define kENGINE_FUNCTION_TRANSLATE 67
#define kENGINE_FUNCTION_IDENTITY 70
#define kENGINE_FUNCTION_PERSPECTIVE 71
#define kENGINE_FUNCTION_SCALE 72
#define kENGINE_FUNCTION_SCROLLTEXTURE 73

#define kENGINE_FUNCTION_RAND_IN_RANGE 80
#define kENGINE_FUNCTION_FINDPLATFORM 81
#define kENGINE_FUNCTION_SINE 82
#define kENGINE_FUNCTION_COSINE 83
#define kENGINE_FUNCTION_FINDLADDER 84
#define kENGINE_FUNCTION_ARCTANGENT 85
#define kENGINE_FUNCTION_SQUAREROOT 86
#define kENGINE_FUNCTION_FINDVINE 87
#define kENGINE_FUNCTION_SETFOG 88
#define kENGINE_FUNCTION_CHANGEMESH 89

#define kENGINE_FIELD_PLAYER_X 1
#define kENGINE_FIELD_PLAYER_Y 2
#define kENGINE_FIELD_PLAYER_Z 3
#define kENGINE_FIELD_PLAYER_STATE 4
#define kENGINE_FIELD_PLAYER_STATE_COUNTER 5
#define kENGINE_FIELD_PLAYER_IS_VISIBLE 6
#define kENGINE_FIELD_PLAYER_DIRECTION 7
#define kENGINE_FIELD_PLAYER_CURRENT_SPECIAL_ACTION 8

#define kENGINE_FIELD_INPUT_LEFT_PRESSED 16
#define kENGINE_FIELD_INPUT_RIGHT_PRESSED 17
#define kENGINE_FIELD_INPUT_UP_PRESSED 18
#define kENGINE_FIELD_INPUT_DOWN_PRESSED 19
#define kENGINE_FIELD_INPUT_JUMP_PRESSED 20
#define kENGINE_FIELD_INPUT_ATTACK_PRESSED 21
#define kENGINE_FIELD_INPUT_SELECT_PRESSED 22
#define kENGINE_FIELD_INPUT_LAST_KEY_PRESSED 23

#define kENGINE_FIELD_ROLL_COOLDOWN_REMAINING 32
#define kENGINE_FIELD_FREEZE_COOLDOWN_REMAINING 33
#define kENGINE_FIELD_SOUND_IS_SFX_ENABLED 34
#define kENGINE_FIELD_SOUND_IS_MUSIC_ENABLED 35
#define kENGINE_FIELD_FPS_CURRENT_VALUE 36
#define kENGINE_FIELD_FPS_IS_DISPLAY_ENABLED 37
#define kENGINE_FIELD_LIVESREMAINING 38

#define kENGINE_FIELD_DONUT_COUNT 64
#define kENGINE_FIELD_PLATFORM_COUNT 65
#define kENGINE_FIELD_LADDER_COUNT 66
#define kENGINE_FIELD_VINE_COUNT 67
#define kENGINE_FIELD_WALL_COUNT 68
#define kENGINE_FIELD_TEXTURE_COUNT 69

#define kENGINE_FIELD_EVENT_VARIABLE_1 128
#define kENGINE_FIELD_EVENT_VARIABLE_2 129
#define kENGINE_FIELD_EVENT_VARIABLE_3 130
#define kENGINE_FIELD_EVENT_VARIABLE_4 131
#define kENGINE_CONSTANT_MAX_SCRIPT_OBJECTS 133
#define kENGINE_FIELD_DEBUG_IS_ENABLED 134
#define kENGINE_FIELD_CAMERA_PERSPECTIVE_TYPE 135
#define kENGINE_FIELD_LEVEL_WIDTH 136
#define kLEVEL_OBJECT_SCRIPT_CONTEXT_ID 137
// TODO: Rename this next thing
#define kSCRIPT_OBJECT_FIELD_ID 1000

#define kLEVEL_OBJECT_FIELD_SX1 1
#define kLEVEL_OBJECT_FIELD_SX2 2
#define kLEVEL_OBJECT_FIELD_SY1 3
#define kLEVEL_OBJECT_FIELD_SY2 4
#define kLEVEL_OBJECT_FIELD_SZ1 5
#define kLEVEL_OBJECT_FIELD_SZ2 6
#define kLEVEL_OBJECT_FIELD_VISIBLE 7
#define kLEVEL_OBJECT_FIELD_NUMBER 8
#define kLEVEL_OBJECT_FIELD_TEXTURE 9
#define kLEVEL_OBJECT_FIELD_EXTRA 10
#define kLEVEL_OBJECT_FIELD_THIS 137

#define kSERVICE_FUNCTION_GAMELIST 128
#define kSERVICE_FUNCTION_GAMESTART 129
#define kSERVICE_FUNCTION_LOADMENU 130
#define kSERVICE_FUNCTION_SETOPTIONSTRING 142
#define kSERVICE_FUNCTION_SETOPTION 143
#define kSERVICE_FUNCTION_SAVEOPTIONS 144
#define kSERVICE_FUNCTION_LEVELTITLE 154
#define kSERVICE_FUNCTION_CREDITLINE 155

long invoke_engine_function(long function_id) {
    long iLoop;
    // char sFileName[300];

    // long raw_argument_1 = context->local_variable_stack[context->base_pointer + 0];
    // long argument_1 = raw_argument_1 / 256;
    // long raw_argument_2 = context->local_variable_stack[context->base_pointer + 1];
    // long argument_2 = raw_argument_2 / 256;
    // long raw_argument_3 = context->local_variable_stack[context->base_pointer + 2];
    // long argument_3 = raw_argument_3 / 256;
    // long raw_argument_4 = context->local_variable_stack[context->base_pointer + 3];
    // long argument_4 = raw_argument_4 / 256;

    if(function_id == kENGINE_FUNCTION_CHANGEMESH) {
        // ChangeMesh(miSelectedMesh, iOtherMesh[argument_1]);
        printf("ChangeMesh(selected_mesh, int(base[0]))\n");
    }

    if(function_id == kENGINE_FUNCTION_IDENTITY) {
        // IdentityMatrix(miSelectedMesh);
        printf("Identity(selected_mesh)\n");
    }

    if(function_id == kENGINE_FUNCTION_PERSPECTIVE) {
        // PerspectiveMatrix(miSelectedMesh);
        printf("SetPerspectiveMatrix(selected_mesh)\n");
    }

    if(function_id == kENGINE_FUNCTION_TRANSLATE) {
        // TranslateMatrix(miSelectedMesh, raw_argument_1 / 256.0f, raw_argument_2 / 256.0f, raw_argument_3 / 256.0f);
        printf("Translate(selected_mesh, base[0], base[1], base[2])\n");
    }

    if(function_id == kENGINE_FUNCTION_SCALE) {
        // ScaleMatrix(miSelectedMesh, raw_argument_1 / 256.0f, raw_argument_2 / 256.0f, raw_argument_3 / 256.0f);
        printf("Scale(selected_mesh, base[0], base[1], base[2])\n");
    }

    if(function_id == kENGINE_FUNCTION_ROTATEX) {
        // RotateMatrixX(miSelectedMesh, raw_argument_1 / 256.0f);
        printf("RotateX(selected_mesh, base[0])\n");
    }

    if(function_id == kENGINE_FUNCTION_ROTATEY) {
        // RotateMatrixY(miSelectedMesh, raw_argument_1 / 256.0f);
        printf("RotateY(selected_mesh, base[0])\n");
    }

    if(function_id == kENGINE_FUNCTION_ROTATEZ) {
        // RotateMatrixZ(miSelectedMesh, raw_argument_1 / 256.0f);
        printf("RotateZ(selected_mesh, base[0])\n");
    }

    if(function_id == kENGINE_FUNCTION_SCROLLTEXTURE) {
        // ScrollTexture(miSelectedMesh, raw_argument_1 / 4096.0f, raw_argument_2 / 4096.0f);
        printf("ScrollTexture(selected_mesh, base[0], base[1])\n");
    }

    if(function_id == kENGINE_FUNCTION_SET_SELECTED_LEVEL_OBJECT_FIELD) {
        // if(argument_1 == kLEVEL_OBJECT_FIELD_SX1) {
        //     // loSelected->X1 = argument_2;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_SX2) {
        //     // loSelected->X2 = argument_2;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_SY1) {
        //     // loSelected->Y1 = argument_2;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_SY2) {
        //     // loSelected->Y2 = argument_2;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_SZ1) {
        //     // loSelected->Z1 = argument_2;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_SZ2) {
        //     // loSelected->Z2 = argument_2;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_VISIBLE) {
        //     // loSelected->Visible = argument_2;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_NUMBER) {
        //     // loSelected->Num = argument_2;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_TEXTURE) {
        //     // loSelected->Texture = argument_2;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_EXTRA) {
        //     // loSelected->Extra = argument_2;
        // }

        // SetObjectData(miSelectedMesh, loSelected->Texture, loSelected->Visible);
        // TODO: Get function name from source code, rename if necessary
        printf("SetSelectedLevelObjectField(field: base[0], value: base[1])\n");  // TODO: Any way to extract this? Seems like we might have to translate and store state to do it?
    }

    if(function_id == kENGINE_FUNCTION_GET_SELECTED_LEVEL_OBJECT_FIELD) {
        // if(argument_1 == kLEVEL_OBJECT_FIELD_SX1) {
        //     // return loSelected->X1;
        //     return -1;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_SX2) {
        //     // return loSelected->X2;
        //     return -1;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_SY1) {
        //     // return loSelected->Y1;
        //     return -1;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_SY2) {
        //     // return loSelected->Y2;
        //     return -1;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_SZ1) {
        //     // return loSelected->Z1;
        //     return -1;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_SZ2) {
        //     // return loSelected->Z2;
        //     return -1;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_VISIBLE) {
        //     // return loSelected->Visible;
        //     return -1;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_NUMBER) {
        //     // return loSelected->Num;
        //     return -1;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_TEXTURE) {
        //     // return loSelected->Texture;
        //     return -1;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_EXTRA) {
        //     // return loSelected->Extra;
        //     return -1;
        // } else if(argument_1 == kLEVEL_OBJECT_FIELD_THIS) {
        //     // return loSelected->ObjectNumber;
        //     return -1;
        // }
        printf("base[-1] = GetSelectedLevelObjectField(field: base[0])\n");  // TODO: Any way to extract this? Seems like we might have to translate and store state to do it?
    }

    if(function_id == kENGINE_FUNCTION_GETNAVDIR) {
        // return GetNavDir(argument_1, argument_2, argument_3, argument_4);
        printf("base[-1] = GetNavDir(base[0], base[1], base[2], base[3])\n");
        return -1;
    }

    if(function_id == kENGINE_FUNCTION_STRCOPY) {
        iLoop = -1;

        // while(++iLoop <= argument_2) {
        //     context->global_variables[argument_1 + iLoop] = context->local_variable_stack[context->stack_pointer + iLoop + 1];
        // }
        printf("strcpy(&global[base[0]], &stack[1])\n");
    }

    // int iLen1;
    // int iLen2;

    if(function_id == kENGINE_FUNCTION_STRCAT) {
        // iLen1 = context->global_variables[argument_1] / 256;
        // iLen2 = context->global_variables[argument_2] / 256;
        // context->global_variables[argument_1] = (iLen1 + iLen2) * 256;
        // iLoop = 0;

        // while(++iLoop <= iLen2) {
        //     context->global_variables[argument_1 + iLen1 + iLoop] = context->global_variables[argument_2 + iLoop];
        // }
        printf("strcat(&global[base[0]], &global[base[1]])\n");
    }

    if(function_id == kENGINE_FUNCTION_GET) {
        // if(argument_1 == kENGINE_FIELD_PLAYER_X) {
        //     // return (long)(iPlayerX * 256.0f);
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_PLAYER_Y) {
        //     // return (long)(iPlayerY * 256.0f);
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_PLAYER_Z) {
        //     // return (long)(iPlayerZ * 256.0f);
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_PLAYER_STATE) {
        //     // return iPlayerST * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_PLAYER_STATE_COUNTER) {
        //     // return iPlayerSC * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_PLAYER_DIRECTION) {
        //     // return iPlayerDIR * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_PLAYER_CURRENT_SPECIAL_ACTION) {
        //     // return iPlayerACT * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_FPS_IS_DISPLAY_ENABLED) {
        //     // return iShowFPS * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_LIVESREMAINING) {
        //     // return GameLivesRemaining * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_EVENT_VARIABLE_1) {
        //     // return iEvent1 * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_EVENT_VARIABLE_2) {
        //     // return iEvent2 * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_EVENT_VARIABLE_3) {
        //     // return iEvent3;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_EVENT_VARIABLE_4) {
        //     // return iEvent4;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_DEBUG_IS_ENABLED) {
        //     // return miDEBUG * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_CAMERA_PERSPECTIVE_TYPE) {
        //     // return miPerspective * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_CONSTANT_MAX_SCRIPT_OBJECTS) {
        //     // return MAX_SCRIPTOBJECTS * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_DONUT_COUNT) {
        //     // return iDS * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_TEXTURE_COUNT) {
        //     // return miTextures * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_PLATFORM_COUNT) {
        //     // return iPS * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_LADDER_COUNT) {
        //     // return iLS * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_VINE_COUNT) {
        //     // return iVS * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_WALL_COUNT) {
        //     // return iWS * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_LEVEL_WIDTH) {
        //     // return miLevelExtentX * 256;
        //     return -1;
        // } else if(argument_1 == kLEVEL_OBJECT_SCRIPT_CONTEXT_ID) {
        //     // return context->ScriptReference * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_INPUT_LEFT_PRESSED) {
        //     // return iKeyLeft * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_INPUT_RIGHT_PRESSED) {
        //     // return iKeyRight * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_INPUT_UP_PRESSED) {
        //     // return iKeyUp * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_INPUT_DOWN_PRESSED) {
        //     // return iKeyDown * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_INPUT_JUMP_PRESSED) {
        //     // return iKeyJump * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_INPUT_ATTACK_PRESSED) {
        //     // return iKeyAttack * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_INPUT_SELECT_PRESSED) {
        //     // return iKeySelect * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_FREEZE_COOLDOWN_REMAINING) {
        //     // return iPlayerFreeze * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_SOUND_IS_SFX_ENABLED) {
        //     // return GameSoundOn * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_SOUND_IS_MUSIC_ENABLED) {
        //     // return GameMusicOn * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_INPUT_LAST_KEY_PRESSED) {
        //     // return iLastKey * 256;
        //     return -1;
        // } else if(argument_1 == kENGINE_FIELD_FPS_CURRENT_VALUE) {
        //     // return GamePerformance * 256;
        //     return -1;
        // }
        printf("base[-1] = getext(field: base[0])\n");  // TODO: Any way to extract this? Seems like we might have to translate and store state to do it?
    }

    if(function_id == kENGINE_FUNCTION_SET) {
        // if(argument_1 == kENGINE_FIELD_PLAYER_X) {
        //     // iPlayerX = static_cast<float>(raw_argument_2) / 256;
        // } else if(argument_1 == kENGINE_FIELD_PLAYER_Y) {
        //     // iPlayerY = static_cast<float>(raw_argument_2) / 256;
        // } else if(argument_1 == kENGINE_FIELD_PLAYER_Z) {
        //     // iPlayerZ = static_cast<float>(argument_2);
        // } else if(argument_1 == kENGINE_FIELD_PLAYER_STATE) {
        //     // iPlayerST = argument_2;
        // } else if(argument_1 == kENGINE_FIELD_PLAYER_STATE_COUNTER) {
        //     // iPlayerSC = argument_2;
        // } else if(argument_1 == kENGINE_FIELD_PLAYER_DIRECTION) {
        //     // iPlayerDIR = argument_2;
        // } else if(argument_1 == kENGINE_FIELD_PLAYER_CURRENT_SPECIAL_ACTION) {
        //     // iPlayerACT = argument_2;
        // } else if(argument_1 == kENGINE_FIELD_EVENT_VARIABLE_1) {
        //     // iEvent1 = argument_2;
        // } else if(argument_1 == kENGINE_FIELD_EVENT_VARIABLE_2) {
        //     // iEvent2 = argument_2;
        // } else if(argument_1 == kENGINE_FIELD_EVENT_VARIABLE_3) {
        //     // iEvent3 = argument_2;
        // } else if(argument_1 == kENGINE_FIELD_EVENT_VARIABLE_4) {
        //     // iEvent4 = argument_2;
        // } else if(argument_1 == kENGINE_FIELD_CAMERA_PERSPECTIVE_TYPE) {
        //     // miPerspective = argument_2;
        // } else if(argument_1 == kENGINE_FIELD_DEBUG_IS_ENABLED) {
        //     // miDEBUG = argument_2;
        // } else if(argument_1 == kENGINE_FIELD_LEVEL_WIDTH) {
        //     // miLevelExtentX = argument_2;
        // } else if(argument_1 == kENGINE_FIELD_ROLL_COOLDOWN_REMAINING) {
        //     // iPlayerNoRoll = argument_2;
        // } else if(argument_1 == kENGINE_FIELD_FREEZE_COOLDOWN_REMAINING) {
        //     // iPlayerFreeze = argument_2;
        // } else if(argument_1 == kENGINE_FIELD_PLAYER_IS_VISIBLE) {
        //     // iPlayerVisible = argument_2;
        // } else if(argument_1 == kENGINE_FIELD_LIVESREMAINING) {
        //     // GameLivesRemaining = argument_2;
        // }
        printf("SetExt(field: base[0], value: base[1])\n");  // TODO: Any way to extract this? Seems like we might have to translate and store state to do it?

        return 0;
    }

    if(function_id == kENGINE_FUNCTION_SPAWN) {
        // long iNewObject = -1;
        // iLoop = -1;

        // while(++iLoop < MAX_SCRIPTOBJECTS) {
        //     if(!oObject[iLoop].Active) {
        //         iNewObject = iLoop;
        //         break;
        //     }
        // }

        // if(iNewObject < 0) {
        //     iNewObject = 0;
        // }

        // ResetContext(&oObject[iNewObject]);
        // oObject[iNewObject].Script = &oObjectScript[argument_1];
        // oObject[iNewObject].ScriptNumber = argument_1;
        // oObject[iNewObject].ScriptReference = iNewObject;
        // oObject[iNewObject].Active = 2;

        // return iNewObject;
        printf("base[-1] = Spawn(script: base[0])\n");

        return -1;
    }

    if(function_id == kENGINE_FUNCTION_NEWMESH) {
        // long iNew;
        // CopyObject(iOtherMesh[argument_1], &iNew);
        // miSelectedMesh = iNew;
        // return iNew;
        printf("base[-1] = NewMesh(base[0])\n");
        return -1;
    }

    if(function_id == kENGINE_FUNCTION_NEW_TEXT_GLYPH_MESH) {
        // long iNew;

        // if(argument_1 >= 97) {
        //     argument_1 += 65 - 97;
        // }

        // if(iCharMesh[argument_1] >= 0) {
        //     CopyObject(iCharMesh[argument_1], &iNew);
        //     miSelectedMesh = iNew;
        //     return iNew;
        // } else {
        //     return -1;
        // }
        printf("base[-1] = CopyCharMeshAndSelectNew(base[0])\n");
        return -1;
    }

    if(function_id == kENGINE_FUNCTION_SET_OBJECT_DATA) {
        // SetObjectData(miSelectedMesh, argument_1, argument_2);
        printf("SetProperties(selected_mesh, base[0], base[1])\n");
    }

    if(function_id == kENGINE_FUNCTION_MOVE_OBJECT_TO_FRONT) {
        // PrioritizeObject(miSelectedMesh);
        printf("PrioritizeObject(selected_mesh)\n");
    }

    if(function_id == kENGINE_FUNCTION_SETDATA) {
        // oObject[argument_1].global_variables[argument_2] = raw_argument_3;
        printf("context[base[0]].global[base[1]] = base[2]\n");
    }

    if(function_id == kENGINE_FUNCTION_GETDATA) {
        // if(argument_2 == kSCRIPT_OBJECT_FIELD_ID) {
        //     if(oObject[argument_1].Active) {
        //         return oObject[argument_1].ScriptNumber * 256;
        //     } else {
        //         return -256;
        //     }
        // }

        // return oObject[argument_1].global_variables[argument_2];
        printf("base[-1] = context[base[0]].global[base[1]]\n");  // TODO: Any way to extract this, and the arguments above? Seems like we might have to translate and store state to do it?
        return -256;
    }

    if(function_id == kENGINE_FUNCTION_RAND_IN_RANGE) {
        long iRand = -1;
        // iRand = (rand() & 16383) * (argument_2 - argument_1) / 16383 + argument_1;
        printf("base[-1] = RandInRange(base[0], base[1])\n");
        return iRand;
    }

    if(function_id == kENGINE_FUNCTION_FINDLADDER) {
        // long iLadA, iLadE;
        // FindLadder(argument_1, argument_2, &iLadA, &iLadE);
        // iEvent4 = iLadA * 256;
        // return iLadE;
        printf("base[-1] = FindLadder(base[0], base[1], &event_4)\n");
        return -1;
    }

    if(function_id == kENGINE_FUNCTION_FINDVINE) {
        // long iVinAp, iVinEx;
        // FindVine(argument_1, argument_2, &iVinAp, &iVinEx);
        // iEvent4 = iVinAp * 256;
        // return iVinEx;
        printf("base[-1] = FindVine(base[0], base[1], &event_4)\n");
        return -1;
    }

    if(function_id == kENGINE_FUNCTION_FINDPLATFORM) {
        // float iFind;
        long iPlat = -1;
        // GetNextPlatform(argument_1, argument_2, argument_3, argument_4, &iFind, &iPlat);
        // iEvent4 = static_cast<long>(iFind) * 256;
        printf("base[-1] = FindPlatform(base[0], base[1], base[2], base[3], &event_4)\n");
        return iPlat;
    }

    long iVal = -1;

    if(function_id == kENGINE_FUNCTION_SINE) {
        // iVal = static_cast<long>(sin(raw_argument_1 * 3.1415f / 180.0f / 256.0f) * argument_2);
        printf("base[-1] = Sin(base[0]) * base[1]\n");
        return iVal;
    }

    if(function_id == kENGINE_FUNCTION_COSINE) {
        // iVal = static_cast<long>(cos(raw_argument_1 * 3.1415f / 180.0f / 256.0f) * argument_2);
        printf("base[-1] = Cos(base[0]) * base[1]\n");
        return iVal;
    }

    if(function_id == kENGINE_FUNCTION_ARCTANGENT) {
        // if(raw_argument_2 == 0) {
        //     iVal = (raw_argument_1 > 0 ? 90 : 270);
        // } else {
        //     iVal = static_cast<long>(atan(static_cast<double>(raw_argument_1) / static_cast<double>(raw_argument_2)) * 180.0f / 3.1415f);
        // }
        printf("base[-1] = Atan(base[0] / base[1])\n");
        return iVal;
    }

    if(function_id == kENGINE_FUNCTION_SQUAREROOT) {
        // iVal = static_cast<long>(sqrt(raw_argument_1 / 256.0f));
        printf("base[-1] = sqrt(base[0])\n");
        return iVal;
    }

    if(function_id == kENGINE_FUNCTION_SELECT_PLATFORM_BY_INDEX) {
        // loSelected = &PS[argument_1];
        // miSelectedMesh = loSelected->MeshNumber;
        return 0;
    }

    if(function_id == kENGINE_FUNCTION_SELECT_LADDER_BY_INDEX) {
        // loSelected = &LS[argument_1];
        // miSelectedMesh = loSelected->MeshNumber;
        return 0;
    }

    if(function_id == kENGINE_FUNCTION_SELECT_DONUT_BY_INDEX) {
        // loSelected = &DS[argument_1];
        // miSelectedMesh = loSelected->MeshNumber;
        return 0;
    }

    if(function_id == kENGINE_FUNCTION_SELECT_VINE_BY_INDEX) {
        // loSelected = &VS[argument_1];
        // miSelectedMesh = loSelected->MeshNumber;
        return 0;
    }

    if(function_id == kENGINE_FUNCTION_COLLIDE_WALL) {
        // return CollideWall(argument_1, argument_2, argument_3, argument_4);
        return -1;
    }

    if(function_id == kENGINE_FUNCTION_SETFOG) {
        // SetFog(static_cast<float>(argument_1), static_cast<float>(argument_2), D3DCOLOR_XRGB(context->local_variable_stack[context->base_pointer + 2], context->local_variable_stack[context->base_pointer + 3], context->local_variable_stack[context->base_pointer + 4]));
    }

    // WIN32_FIND_DATA FindFileData;
    // HANDLE hFind;
    // int iTitle;
    // int iChar;
    // char sName[100];
    // char sFile[300];
    // int iKey;
    // int iKeyGood;
    // DWORD iWritten;
    // HANDLE hFile;

    if(function_id == kENGINE_FUNCTION_SERVICE_FUNCTION) {
        // if(argument_1 == kSERVICE_FUNCTION_LEVELTITLE) {
        //     // context->global_variables[argument_2] = static_cast<long>(strlen(GameTitle)) * 256;
        //     // iLoop = 0;

        //     // while(++iLoop <= static_cast<long>(strlen(GameTitle))) {
        //     //     context->global_variables[argument_2 + iLoop] = GameTitle[iLoop - 1] * 256;
        //     // }
        // }

        // if(argument_1 == kSERVICE_FUNCTION_SAVEOPTIONS) {
        //     // sprintf_s(sFile, "%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d", GameKeys[0], GameKeys[1], GameKeys[2], GameKeys[3], GameKeys[4], GameKeys[5], GameSoundOn, GameMusicOn);
        //     // char sFileName[300];
        //     // sprintf_s(sFileName, "%s\\Data\\Settings.dat", GamePath);
        //     // hFile = CreateFile(sFileName, GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
        //     // WriteFile(hFile, sFile, static_cast<long>(strlen(sFile)), &iWritten, NULL);
        //     // CloseHandle(hFile);
        // }

        // if(argument_1 == kSERVICE_FUNCTION_SETOPTION) {
        //     // if(argument_3 >= 0 && argument_3 <= 5) {
        //     //     iKeyGood = 0;
        //     //     iKey = argument_2;

        //     //     if(iKey == 38 && argument_3 == 0) {
        //     //         iKeyGood = 1;
        //     //     }

        //     //     if(iKey == 40 && argument_3 == 1) {
        //     //         iKeyGood = 1;
        //     //     }

        //     //     if(iKey == 37 && argument_3 == 2) {
        //     //         iKeyGood = 1;
        //     //     }

        //     //     if(iKey == 39 && argument_3 == 3) {
        //     //         iKeyGood = 1;
        //     //     }

        //     //     if(iKey == 32 && argument_3 == 4) {
        //     //         iKeyGood = 1;
        //     //     }

        //     //     if(iKey >= 'A' && iKey <= 'Z') {
        //     //         iKeyGood = 1;
        //     //     }

        //     //     if(iKey >= '0' && iKey <= '9') {
        //     //         iKeyGood = 1;
        //     //     }

        //     //     iLoop = -1;

        //     //     while(++iLoop < 6) {
        //     //         if(argument_2 != iLoop && GameKeys[iLoop] == iKey) {
        //     //             iKeyGood = 0;
        //     //         }
        //     //     }

        //     //     if(iKeyGood) {
        //     //         GameKeys[argument_3] = iKey;
        //     //     }
        //     // }

        //     // if(argument_3 == 32) {
        //     //     GameSoundOn = argument_2;
        //     // }

        //     // if(argument_3 == 33 && GameMusicOn != argument_2) {
        //     //     if(argument_2 == 0) {
        //     //         PauseMusic1();
        //     //     } else {
        //     //         NewTrack1(msBackMusic, 0, 0);
        //     //     }
        //     //     GameMusicOn = argument_2;
        //     // }
        // }

        // if(argument_1 == kSERVICE_FUNCTION_SETOPTIONSTRING) {
        //     // if(argument_3 >= 0 && argument_3 <= 5) {
        //     //     iKey = GameKeys[argument_3];

        //     //     if(iKey >= 'A' && iKey <= 'Z') {
        //     //         sprintf_s(sName, "%c   ", iKey);
        //     //     } else if(iKey >= '0' && iKey <= '9') {
        //     //         sprintf_s(sName, "%c   ", iKey);
        //     //     } else if(iKey == 38) {
        //     //         sprintf_s(sName, "UP  ");
        //     //     } else if(iKey == 40) {
        //     //         sprintf_s(sName, "DOWN");
        //     //     } else if(iKey == 37) {
        //     //         sprintf_s(sName, "LEFT");
        //     //     } else if(iKey == 39) {
        //     //         sprintf_s(sName, "RGHT");
        //     //     } else if(iKey == 32) {
        //     //         sprintf_s(sName, "SPC ");
        //     //     } else if(iKey == 58) {
        //     //         sprintf_s(sName, ":   ");
        //     //     } else if(iKey == 46) {
        //     //         sprintf_s(sName, ".   ");
        //     //     } else if(iKey == 45) {
        //     //         sprintf_s(sName, "-   ");
        //     //     }
        //     // } else if(argument_3 == 32 || argument_3 == 33) {
        //     //     if(argument_3 == 32) {
        //     //         // iKey = GameSoundOn;
        //     //     } else {
        //     //         // iKey = GameMusicOn;
        //     //     }

        //     //     if(iKey) {
        //     //         // sprintf_s(sName, "ON  ");
        //     //     } else {
        //     //         // sprintf_s(sName, "OFF ");
        //     //     }
        //     // }

        //     // context->global_variables[argument_2] = 1024;
        //     // context->global_variables[argument_2 + 1] = sName[0] * 256;
        //     // context->global_variables[argument_2 + 2] = sName[1] * 256;
        //     // context->global_variables[argument_2 + 3] = sName[2] * 256;
        //     // context->global_variables[argument_2 + 4] = sName[3] * 256;
        // }

        // if(argument_1 == kSERVICE_FUNCTION_LOADMENU) {
        //     // iEvent1 = iEvent1 - 1;
        //     // GameStatus = GS_MENU;
        //     // GameMenu = argument_2;
        // }

        // if(argument_1 == kSERVICE_FUNCTION_GAMESTART) {
        //     // iTitle = 0;
        //     // // GameLivesRemaining = 7;
        //     // sprintf_s(sFileName, "%s\\Data\\*.jmg", GamePath);
        //     // hFind = FindFirstFile(sFileName, &FindFileData);

        //     // while(iTitle < argument_2) {
        //     //     FindNextFile(hFind, &FindFileData);
        //     //     ++iTitle;
        //     // }

        //     // FindClose(hFind);
        //     // sprintf_s(GameFile, "%s\\Data\\%s", GamePath, FindFileData.cFileName);
        //     // GameStatus = GS_INLEVEL;
        // }

        // if(argument_1 == kSERVICE_FUNCTION_CREDITLINE) {
        //     // sprintf_s(sFileName, "%s\\Data\\credits.txt", GamePath);
        //     // GetFileLine(sName, sizeof(sName), sFileName, argument_2);
        //     // iChar = -1;

        //     // while(sName[++iChar] != 0 && iChar < 18) {
        //     //     context->global_variables[argument_3 + iChar + 1] = sName[iChar] * 256;
        //     // }

        //     // context->global_variables[argument_3] = iChar * 256;
        // }

        // if(argument_1 == kSERVICE_FUNCTION_GAMELIST) {
        //     iTitle = 0;
        //     // sprintf_s(sFileName, "%s\\Data\\*.jmg", GamePath);
        //     // hFind = FindFirstFile(sFileName, &FindFileData);

        //     // while(hFind != INVALID_HANDLE_VALUE) {
        //     //     iChar = -1;
        //     //     sprintf_s(sFile, "%s\\Data\\%s", GamePath, FindFileData.cFileName);
        //     //     GetFileLine(sName, sizeof(sName), sFile, 0);

        //     //     while(sName[++iChar] != 0 && iChar < 18) {
        //     //         context->global_variables[argument_2 + iTitle * 20 + iChar + 1] = sName[iChar] * 256;
        //     //     }
        //     //     context->global_variables[argument_2 + iTitle * 20] = iChar * 256;
        //     //     iTitle = iTitle + 1;

        //     //     if(!FindNextFile(hFind, &FindFileData)) {
        //     //         FindClose(hFind);
        //     //         hFind = INVALID_HANDLE_VALUE;
        //     //     }
        //     // }

        //     return iTitle;
        // }
    }

    if(function_id == kENGINE_FUNCTION_PLAY_SOUND) {
        // if(GameSoundOn) {
        //     DoPlaySound(argument_1);
        // }
    }

    if(function_id == kENGINE_FUNCTION_PLAYER_COLLIDE) {
        // return PlayerCollide(argument_1, argument_2, argument_3, argument_4) && !(iPlayerST == JS_DYING);
    }

    if(function_id == kENGINE_FUNCTION_PLAYER_KILL/* && !(iPlayerST & JS_DYING)*/) {
        // if(GameMusicOn) {
        //     PauseMusic1();
        // }

        // iPlayerST = JS_DYING;
        // iPlayerACT = 0;
        // iPlayerAS = 1;
        // iPlayerAX = 0;
        // iPlayerMX = 0;
        // iPlayerAF = iPlayerSC;
        // iPlayerSC = 1000;
    }

    if(function_id == kENGINE_FUNCTION_DEBUG_PRINT/* && miDEBUG */) {
        // char sNum[100];

        // if(argument_1 == -1) {
        //     sprintf_s(sNum, "\n");
        // } else if(argument_1 == -2) {
        //     sprintf_s(sNum, " ");
        // } else {
        //     sprintf_s(sNum, "%.0f", raw_argument_1 / 256.0f);
        // }

        // OutputDebugString(sNum);
    }

    if(function_id == kENGINE_FUNCTION_WIN_LEVEL) {
        // if(GameMusicOn) {
        //     PauseMusic1();
        // }

        // iPlayerSC = 0;
        // iPlayerST = JS_DONE;
    }

    if(function_id == kENGINE_FUNCTION_SELECT_OBJECT_MESH_BY_INDEX) {
        // miSelectedMesh = argument_1;
    }

    if(function_id == kENGINE_FUNCTION_DELETE_MESH) {
        // DeleteMesh(argument_1);
    }

    if(function_id == kENGINE_FUNCTION_DELETE_SCRIPT_CONTEXT) {
        // if(argument_1 == kSCRIPT_CURRENT_CONTEXT) {
        //     context->Active = 0;
        // } else {
        //     oObject[argument_1].Active = 0;
        // }
    }

    if(function_id == kENGINE_FUNCTION_RESET_PERSPECTIVE) {
        // SetGamePerspective();
    }

    if(function_id == kENGINE_FUNCTION_SELECT_PLATFORM_BY_ID || function_id == kENGINE_FUNCTION_SELECT_LADDER_BY_ID || function_id == kENGINE_FUNCTION_SELECT_DONUT_BY_ID || function_id == kENGINE_FUNCTION_SELECT_VINE_BY_ID || function_id == kENGINE_FUNCTION_SELECT_PICTURE_BY_ID || function_id == kENGINE_FUNCTION_SELECT_WALL_BY_ID) {
        int iObj = -1;

        if(function_id == kENGINE_FUNCTION_SELECT_WALL_BY_ID) {
            // iObj = FindObject(WS, iWS, argument_1);
            // loSelected = &WS[iObj];
        }

        if(function_id == kENGINE_FUNCTION_SELECT_PLATFORM_BY_ID) {
            // iObj = FindObject(PS, iPS, argument_1);
            // loSelected = &PS[iObj];
        }

        if(function_id == kENGINE_FUNCTION_SELECT_VINE_BY_ID) {
            // iObj = FindObject(VS, iVS, argument_1);
            // loSelected = &VS[iObj];
        }

        if(function_id == kENGINE_FUNCTION_SELECT_LADDER_BY_ID) {
            // iObj = FindObject(LS, iLS, argument_1);
            // loSelected = &LS[iObj];
        }

        if(function_id == kENGINE_FUNCTION_SELECT_DONUT_BY_ID) {
            // iObj = FindObject(DS, iDS, argument_1);
            // loSelected = &DS[iObj];
        }

        if(function_id == kENGINE_FUNCTION_SELECT_PICTURE_BY_ID) {
            // iObj = FindObject(AS, iAS, argument_1);
            // loSelected = &AS[iObj];
        }

        // miSelectedMesh = loSelected->MeshNumber;

        if(iObj < 0) {
            return -1;
        }

        // TODO: Return here?
    }

    return -1;
}

int32_t extract_int32(const unsigned char* data) {
    float result = (data[0] & 127) * 256.0f * 256.0f * 256.0f +
        data[1] * 256.0f * 256.0f +
        data[2] * 256.0f +
        data[3];

    if(data[0] & 128) {
        return (int32_t)(result) * -1;
    } else {
        return (int32_t)(result);
    }
}

int load_script(const unsigned char* file_data, size_t file_data_size, script_code* script) {
    size_t file_current_byte_index = 0;
    int32_t subroutine_count = extract_int32(&file_data[file_current_byte_index]);
    script->subroutine_count = subroutine_count;
    file_current_byte_index += 4;

    int current_subroutine_index =- 1;

    while(++current_subroutine_index < subroutine_count) {
        int current_char_index = -1;

        while(++current_char_index < 20) {
            script->subroutine_name[current_subroutine_index][current_char_index] = file_data[file_current_byte_index];
            ++file_current_byte_index;
        }

        script->subroutine_start_instruction_index[current_subroutine_index] = extract_int32(&file_data[file_current_byte_index]) / 3;
        file_current_byte_index += 4;
    }

    int current_code_index = 0;

    while(file_current_byte_index < file_data_size) {
        script->code[current_code_index] = extract_int32(&file_data[file_current_byte_index]);
        file_current_byte_index += 4;
        ++current_code_index;

        if(current_code_index > kMAX_CODE_DATA_SIZE) {
            return kERROR_TOO_MANY_INSTRUCTIONS;
        }
    }

    script->code_size = current_code_index - 1;
    script->goto_label_count = 0;

    for(int instruction_index = 0; instruction_index < script->code_size / 3; ++instruction_index) {
        int32_t instruction_id = script->code[instruction_index * 3 + 0];
        int32_t raw_argument_1 = script->code[instruction_index * 3 + 1];
        long argument_1 = raw_argument_1 / 256;

        switch(instruction_id) {
            case kINSTRUCTION_JUMPZ:
            case kINSTRUCTION_JUMPNZ:
            case kINSTRUCTION_JUMP:
            case kINSTRUCTION_CALL: {
                bool found_label = false;

                for(int sub_index = 0; sub_index < script->subroutine_count; ++sub_index) {
                    if(script->subroutine_start_instruction_index[sub_index] == (argument_1 + 1)) {
                        found_label = true;
                        break;
                    }
                }

                if(!found_label) {
                    for(int goto_label_index = 0; goto_label_index < script->goto_label_count; ++goto_label_index) {
                        if(script->goto_label_instruction_index[goto_label_index] == (argument_1 + 1)) {
                            found_label = true;
                            break;
                        }
                    }
                }

                if(!found_label) {
                    script->goto_label_instruction_index[script->goto_label_count] = argument_1 + 1;
                    sprintf(script->goto_label_name[script->goto_label_count], "label_%u", argument_1 + 1);
                    ++script->goto_label_count;
                }

                break;
            }
        }
    }

    return kERROR_NO_ERROR;
}

void print_loaded_script(const script_code* script) {
    for(size_t instruction_index = 0; instruction_index < script->code_size / 3; ++instruction_index) {
        for(int sub_index = 0; sub_index < script->subroutine_count; ++sub_index) {
            if(script->subroutine_start_instruction_index[sub_index] == instruction_index) {
                printf("%s:\n", script->subroutine_name[sub_index]);
            }
        }

        for(int label_index = 0; label_index < script->goto_label_count; ++label_index) {
            if(script->goto_label_instruction_index[label_index] == instruction_index) {
                printf("%s:\n", script->goto_label_name[label_index]);
            }
        }

        int32_t instruction_id = script->code[instruction_index * 3 + 0];
        int32_t raw_argument_1 = script->code[instruction_index * 3 + 1];
        int32_t raw_argument_2 = script->code[instruction_index * 3 + 2];

        long argument_1 = raw_argument_1 / 256;
        long argument_2 = raw_argument_2 / 256;

        printf("    ");  // Indent

        switch(instruction_id) {
            case kINSTRUCTION_BASECN:
                if(argument_1 >= 0) {
                    printf("base += %d\n", argument_1);
                } else {
                    printf("base -= %d\n", -argument_1);
                }
                break;
            case kINSTRUCTION_STACKCN:
                if(argument_1 >= 0) {
                    printf("stack += %d\n", argument_1);
                } else {
                    printf("stack -= %d\n", -argument_1);
                }
                break;
            case kINSTRUCTION_MOVBCCN:
                printf("base[%d] = %g\n", argument_1, raw_argument_2 / 256.0f);
                break;
            case kINSTRUCTION_MOVSCCN:
                printf("stack[%d] = %g\n", argument_1, raw_argument_2 / 256.0f);
                break;
            case kINSTRUCTION_MOVBSSC:
                printf("base[int(stack[%d])] = stack[%d]\n", argument_1, argument_2);
                break;
            case kINSTRUCTION_MOVSCBC:
                printf("stack[%d] = base[%d]\n", argument_1, argument_2);
                break;
            case kINSTRUCTION_MOVSCSC:
                printf("stack[%d] = stack[%d]\n", argument_1, argument_2);
                break;
            case kINSTRUCTION_MOVGCCN:
                printf("global[%d] = %g\n", argument_1, raw_argument_2 / 256.0f);
                break;
            case kINSTRUCTION_MOVGSSC:
                printf("global[int(stack[%d])] = stack[%d]\n", argument_1, argument_2);
                break;
            case kINSTRUCTION_MOVSCGC:
                printf("stack[%d] = global[%d]\n", argument_1, argument_2);
                break;
            case kINSTRUCTION_MOVGCSC:
                printf("global[%d] = stack[%d]\n", argument_1, argument_2);
                break;
            case kINSTRUCTION_ADDSCCN:
                printf("stack[%d] += %g\n", argument_1, raw_argument_2 / 256.0f);
                break;
            case kINSTRUCTION_ADDSCSC:
                printf("stack[%d] = stack[%d]\n", argument_1, argument_2);
                break;
            case kINSTRUCTION_MULSCSC:
                printf("stack[%d] *= stack[%d]\n", argument_1, argument_2);
                break;
            case kINSTRUCTION_SUBSCSC:
                printf("stack[%d] -= stack[%d]\n", argument_1, argument_2);
                break;
            case kINSTRUCTION_DIVSCSC:
                printf("stack[%d] = stack[%d]\n", argument_1, argument_2);
                break;
            case kINSTRUCTION_MOVSCGS:
                printf("stack[%d] = global[int(stack[%d])]]\n", argument_1, argument_2);
                break;
            case kINSTRUCTION_MOVSCBS:
                printf("stack[%d] = base[int(stack[%d])]\n", argument_1, argument_2);
                break;
            case kINSTRUCTION_BANDSCSC:
                printf("stack[%d] &= stack[%d]\n", argument_1, argument_2);
                break;
            case kINSTRUCTION_JUMPZ:
            case kINSTRUCTION_JUMPNZ:
            case kINSTRUCTION_JUMP:
            case kINSTRUCTION_CALL: {
                char* instruction_name = "";

                switch(instruction_id) {
                    case kINSTRUCTION_JUMPZ:
                        instruction_name = "if stack[0] == 0 -> goto";
                        break;
                    case kINSTRUCTION_JUMPNZ:
                        instruction_name = "if stack[0] != 0 -> goto";
                        break;
                    case kINSTRUCTION_JUMP:
                        instruction_name = "goto";
                        break;
                    case kINSTRUCTION_CALL:
                        instruction_name = "gosub";
                        break;
                }

                bool found_label = false;

                for(int sub_index = 0; sub_index < script->subroutine_count; ++sub_index) {
                    if(script->subroutine_start_instruction_index[sub_index] == (argument_1 + 1)) {
                        printf("%s %s\n", instruction_name, script->subroutine_name[sub_index]);
                        found_label = true;
                        break;
                    }
                }

                if(!found_label) {
                    for(int goto_label_index = 0; goto_label_index < script->goto_label_count; ++goto_label_index) {
                        if(script->goto_label_instruction_index[goto_label_index] == (argument_1 + 1)) {
                            printf("%s %s\n", instruction_name, script->goto_label_name[goto_label_index]);
                            found_label = true;
                            break;
                        }
                    }
                }

                if(!found_label) {
                    fprintf(stderr, "Couldn't find label for %s instruction. Likely a bug: %d\n", instruction_name, argument_1 + 1);
                    printf("%s %d\n", instruction_name, argument_1 + 1);
                }

                break;
            }
            case kINSTRUCTION_EQUSCSC:
                printf("stack[%d] = stack[%d] == stack[%d]\n", argument_1, argument_1, argument_2);
                break;
            case kINSTRUCTION_NEQSCSC:
                printf("stack[%d] = stack[%d] != stack[%d]\n", argument_1, argument_1, argument_2);
                break;
            case kINSTRUCTION_GTSCSC:
                printf("stack[%d] = stack[%d] > stack[%d]\n", argument_1, argument_1, argument_2);
                break;
            case kINSTRUCTION_GTESCSC:
                printf("stack[%d] = stack[%d] < stack[%d]\n", argument_1, argument_1, argument_2);
                break;
            case kINSTRUCTION_ORSCSC:
                printf("stack[%d] = stack[%d] || stack[%d]\n", argument_1, argument_1, argument_2);
                break;
            case kINSTRUCTION_ANDSCSC:
                printf("stack[%d] = stack[%d] && stack[%d]\n", argument_1, argument_1, argument_2);
                break;
            case kINSTRUCTION_RET:
                printf("return\n");
                break;
            case kINSTRUCTION_CALL_ENGINE_FUNCTION:
                // if(argument_1 == kENGINE_FUNCTION_GETDATA || argument_1 == kENGINE_FUNCTION_GET) {
                //     context->local_variable_stack[context->base_pointer - 1] = invoke_engine_function(argument_1, context);
                // } else {
                //     context->local_variable_stack[context->base_pointer - 1] = invoke_engine_function(argument_1, context) * 256;
                // }
                invoke_engine_function(argument_1);
                break;
            default:
                printf("exit\n");
                break;
        }
    }
}

int main(int argument_count, char* arguments[]) {
    if(argument_count < 2) {
        fprintf(stderr, "Must specify input file");
        return kERROR_INVALID_ARUGMENTS;
    } else if(argument_count > 2) {
        fprintf(stderr, "Too many arguments");
        return kERROR_INVALID_ARUGMENTS;
    }

    const char* input_filename = arguments[1];
    unsigned char* input_file_data = NULL;
    size_t input_file_size = 0;

    {
        FILE* input_file = fopen(input_filename, "rb");

        if(input_file) {
            fseek(input_file, 0, SEEK_END);
            input_file_size = ftell(input_file);
            fseek(input_file, 0, SEEK_SET);

            input_file_data = malloc(input_file_size);

            if(input_file_data) {
                fread(input_file_data, 1, input_file_size, input_file);
            } else {
                fprintf(stderr, "Failed to allocate %zu bytes\n", input_file_size);
                return kERROR_ALLOCATION_FAILED;
            }

            fclose(input_file);
        } else {
            fprintf(stderr, "Failed to open input file: %s\n", input_filename);
            return kERROR_INPUT_FILE_MISSING;
        }
    }

    // script_context context;
    script_code input_code;
    int load_script_result = load_script(input_file_data, input_file_size, &input_code);

    if(load_script_result != kERROR_NO_ERROR) {
        return load_script_result;
    }

    print_loaded_script(&input_code);

    // Don't worry about calling free. We're exiting
    return kERROR_NO_ERROR;
}
