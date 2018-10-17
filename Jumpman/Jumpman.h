#pragma once

#include <stdint.h>

#define FULL_SCREEN 1
#define FULLSCREEN_RESX 640
#define FULLSCREEN_RESY 480

#define GS_EXITING 0
#define GS_MENU 1
#define GS_INLEVEL 2

#define GM_NONE 0
#define GM_MAIN 1
#define GM_OPTIONS 2
#define GM_SELECTGAME 3
#define GM_SELECTLEVEL 4

#define JM_STAND 1
#define JM_LEFT1 2
#define JM_LEFT2 3
#define JM_RIGHT1 4
#define JM_RIGHT2 5
#define JM_JUMPLEFT 6
#define JM_JUMPRIGHT 7
#define JM_JUMPUP 8
#define JM_VINECLIMB1 9
#define JM_VINECLIMB2 10
#define JM_LADDERCLIMB1 11
#define JM_LADDERCLIMB2 12
#define JM_KICKLEFT 13
#define JM_KICKRIGHT 14

#define JM_DIVERIGHT 15
#define JM_ROLLRIGHT1 16
#define JM_ROLLRIGHT2 17
#define JM_ROLLRIGHT3 18
#define JM_ROLLRIGHT4 19

#define JM_DIVELEFT 20
#define JM_ROLLLEFT1 21
#define JM_ROLLLEFT2 22
#define JM_ROLLLEFT3 23
#define JM_ROLLLEFT4 24

#define JM_PUNCHLEFT 25
#define JM_PUNCHRIGHT 26
#define JM_PUNCHLEFT2 27
#define JM_PUNCHRIGHT2 28
#define JM_DYING 29
#define JM_DEAD 30
#define JM_STARS 31
#define JM_SLIDER 32
#define JM_SLIDERB 33
#define JM_SLIDEL 34
#define JM_SLIDELB 35
#define JM_BORED1 36
#define JM_BORED2 37
#define JM_BORED3 38
#define JM_BORED4 39
#define JM_BORED5 40

#define JS_NORMAL 0
#define JS_JUMPING 1
#define JS_FALLING 8
#define JS_LADDER 16
#define JS_ROLL 64
#define JS_PUNCH 128
#define JS_DYING 256
#define JS_DONE 512
#define JS_VINE 1024
#define JS_SLIDE 2048

#define JD_UP 1
#define JD_DOWN 2
#define JD_LEFT 3
#define JD_RIGHT 4

#define JA_KICK 1
#define JA_PUNCH 2

#define NT_Ladder 1
#define NT_Platform 2
#define NT_PlatformFallLeft 3
#define NT_PlatformFallRight 4

struct LevelObject{
    int X1, X2, X3, X4;
    int Y1, Y2, Y3, Y4;
    int Z1, Z2;
    int Num;
    int Visible;
    char Func[10];
    int Extra;

    int Navs;
    int NavTo[10];
    int NavToType[10];
    int NavDist;
    int NavChoice;

    int MeshSize;
    long* Mesh;
    long MeshNumber;
    int Texture;
    int ObjectNumber;
};

struct ScriptCode{
    int Subs;
    int SubStart[50];
    char SubName[50][20];
    long Code[8000];
};

struct ScriptContext{
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
};

// IN JUMPMAN
void GetFileLine(char* sOut, size_t sOutSize, char* sFile, int iLine);
void LoadNextLevel();
void ProgressGame();
void DrawGame();
long Init3D();
void LoadMeshes();
long LoadMesh(char* sFileName);
void PrepLevel(char* sLevel);
int FindObject(LevelObject* lObj, int iCount, int iFind);
void GetNextPlatform(long iX, long iY, long iHeight, long iWide, float* iSupport, long* iPlatform);
void FindLadder(long iX, long iY, long* iAbout, long* iExact);
void FindVine(long iX, long iY, long* iAbout, long* iExact);
void SetGamePerspective();
void MoveJumpman();

// EXT FUNCTION
long ExtFunction(long iFunc, ScriptContext* SC);

#define EFPRINT 1
#define EFSET 2
#define EFSETSEL 3
#define EFGET 8
#define EFGETSEL 9
#define EFGETNAVDIR 10
#define EFSTRCOPY 11
#define EFSTRCAT 12

#define EFSELECT_PLATFORM 32
#define EFSELECT_LADDER 33
#define EFSELECT_DONUT 34
#define EFABS_PLATFORM 35
#define EFCOLLIDE 36
#define EFKILL 37
#define EFSELECT_VINE 38
#define EFABS_LADDER 39
#define EFSPAWN 40
#define EFNEWMESH 41
#define EFSETOBJECT 42
#define EFSOUND 43
#define EFSETDATA 44
#define EFGETDATA 45
#define EFABS_DONUT 46
#define EFCOLLIDE_WALL 47
#define EFSELECT_PICTURE 48
#define EFPRIORITIZE_OBJECT 49
#define EFSELECT_WALL 51
#define EFSELECT_OBJECT_MESH 52
#define EFDELETE_MESH 53
#define EFDELETE_OBJECT 54
#define EFWIN 55
#define EFABS_VINE 56
#define EFSERVICE 57
#define EFNEWCHARMESH 58
#define EFRESETPERSPECTIVE 59

#define EFROTATEX 64
#define EFROTATEY 65
#define EFROTATEZ 66
#define EFTRANSLATE 67
#define EFIDENTITY 70
#define EFPERSPECTIVE 71
#define EFSCALE 72
#define EFSCROLLTEXTURE 73

#define EFRND 80
#define EFFINDPLATFORM 81
#define EFSIN 82
#define EFCOS 83
#define EFFINDLADDER 84
#define EFATAN 85
#define EFSQR 86
#define EFFINDVINE 87
#define EFSETFOG 88
#define EFCHANGEMESH 89

#define EFV_PX 1
#define EFV_PY 2
#define EFV_PZ 3
#define EFV_PSTAT 4
#define EFV_PSC 5
#define EFV_PVISIBLE 6
#define EFV_PDIR 7
#define EFV_PACT 8

#define EFV_INPUTLEFT 16
#define EFV_INPUTRIGHT 17
#define EFV_INPUTUP 18
#define EFV_INPUTDOWN 19
#define EFV_INPUTJUMP 20
#define EFV_INPUTATTACK 21
#define EFV_INPUTSELECT 22
#define EFV_LASTKEY 23

#define EFV_NOROLL 32
#define EFV_FREEZE 33
#define EFV_SOUNDON 34
#define EFV_MUSICON 35
#define EFV_PERFORMANCE 36
#define EFV_SHOWFPS 37
#define EFV_LIVESREMAINING 38

#define EFV_DONUTS 64
#define EFV_PLATFORMS 65
#define EFV_LADDERS 66
#define EFV_VINES 67
#define EFV_WALLS 68
#define EFV_TEXTURES 69

#define EFV_EVENT1 128
#define EFV_EVENT2 129
#define EFV_EVENT3 130
#define EFV_EVENT4 131
#define EFV_COMPOSE 132
#define EFV_OBJECTS 133
#define EFV_DEBUG 134
#define EFV_PERSPECTIVE 135
#define EFV_LEVELEXTENTX 136
#define EFV_THIS 137

#define EFS_SX1 1
#define EFS_SX2 2
#define EFS_SY1 3
#define EFS_SY2 4
#define EFS_SZ1 5
#define EFS_SZ2 6
#define EFS_VISIBLE 7
#define EFS_NUMBER 8
#define EFS_TEXTURE 9
#define EFS_EXTRA 10
#define EFS_THIS 137

#define SERVICE_GAMELIST 128
#define SERVICE_GAMESTART 129
#define SERVICE_LOADMENU 130
#define SERVICE_OPTIONSTRING 142
#define SERVICE_SETOPTION 143
#define SERVICE_SAVEOPTIONS 144
#define SERVICE_LEVELTITLE 154
#define SERVICE_CREDITLINE 155

// IN MUSIC
bool InitMusic();
void CleanUpMusic();
void NewTrack1(char* sFile, long iStart, long iIntro);
void NewTrack2(char* sFile);
void StopMusic1();

// IN UTILITIES
long PointInQuad(long iX0, long iY0, long iX1, long iY1, long iX2, long iY2, long iX3, long iY3, long iX4, long iY4);
long StringToInt(unsigned char* sString);
long StringToLong(unsigned char* sString);
long StringToLong2(unsigned char* sString);
long FileToString(char* sFileName, unsigned char** sNewBuffer);

// IN JOYSTICK
void GetJoystickPosition(long* X, long* Y, long* B);
int JoystickPresent();

// IN BASIC3D
void ChangeMesh(long iMesh, long iNewMesh);
void SetFog(float iFogStart, float iFogEnd, uint8_t red, uint8_t green, uint8_t blue);
long GetObjectsDrawnSinceLastFrameCount();
void ScrollTexture(long iObj, float fX, float fY);
void DeleteMesh(long iMesh);
void Clear3dData();
void LoadTexture(int iTex, char* sFile, int iType, int iAlpha);
long InitializeAll();
void Begin3dLoad();
void EndAndCommit3dLoad();
void Render();
void ResizeViewport(int width, int height);
void Reset3d();
void DoCleanUp();
void CreateObject(long* iParams, long iCount, long* iNum);
void SetObjectData(long iNum, long iTexture, int iVisible);
void SetPerspective(float iCamX, float iCamY, float iCamZ, float iPoiX, float iPoiY, float iPoiZ);
void CopyObject(int iObject, long* iNum);
void SwapObjects(long o1, long o2);
void PrioritizeObject(long o1);

void ScaleMatrix(long iObj, float fX, float fY, float fZ);
void PerspectiveMatrix(long iObj);
void IdentityMatrix(long iObj);
void TranslateMatrix(long iObj, float fX, float fY, float fZ);
void RotateMatrixX(long iObj, float fDegrees);
void RotateMatrixY(long iObj, float fDegrees);
void RotateMatrixZ(long iObj, float fDegrees);

// IN SCRIPT
void ResetContext(ScriptContext* SC);
void LoadScript(char* sFileName, ScriptCode* oScript);
void RunScript(ScriptContext* SC, long iSub);
int FindScript(ScriptContext* SC, char* sFunc);

// IN SOUND
void DoPlaySound(int iSound);
void CleanUpSounds();
// long InitSound(HWND hWnd);  // TODO: Remove HWND parameter
void LoadSound(char* sFile, int iSound);
