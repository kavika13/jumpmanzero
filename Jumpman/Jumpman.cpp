#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "glad/glad.h"
#include "GLFW/glfw3.h"
#include "./Jumpman.h"
#include "SoundBuffer.h"
#include "Sound.h"

char GameFile[100];
char GameTitle[50];
long GameStatus;
long GameMenuDrawn;
long GameMenu;
long GameDebugMode;
char GameDebugLevel[300];
long GameTimeInactive;

long GamePerformance;
char GamePath[300];

int GameKeys[10];
int GameSoundOn;
int GameMusicOn;
int GameLivesRemaining;

int GameFrozen;

int iShowFPS;

long iKeySpecial;
long iLastKey;

long iSitVinAp;
long iSitVinEx;
long iSitLadA;
long iSitLadE;
long iSitPlatform;
float iSitSupport;

int miIntroLength;

char msBackMusic[200];
char msDeathMusic[200];
char msWinMusic[200];
int miPerspective;
long miSelectedMesh;

int iLevel;
int iLoadedLevel;

int miDEBUG;

int miTextures;
int miMeshes;
int miScripts;

unsigned long iFrameTime;

struct StoreVert {
    long X, Y, Z, NX, NY, NZ, COLOR, TX, TY;
};

long iFindMesh[100];
long iOtherMesh[300];
long iCharMesh[100];

int iKeyLeft, iTappedLeft, iTKeyLeft;
int iKeyRight, iTappedRight, iTKeyRight;
int iKeyDown, iTappedDown, iTKeyUp;
int iKeyUp, iTappedUp, iTKeyDown;
int iKeyJump, iTappedJump, iTKeyAttack;
int iKeyAttack, iTappedAttack, iTKeyJump;
int iKeySelect;

float iPlayerX;
float iPlayerY;
float iPlayerOldX;
float iPlayerOldY;

float iPlayerZ;
float iPlayerRX;
int iPlayerAX;
int iPlayerMX;
int iPlayerM;
int iPlayerVisible;

long iPlayerST;
long iPlayerDIR;
long iPlayerACT;

int iPlayerAF;
long iPlayerSC;
int iPlayerAS;

int iPlayerNoRoll;
int iPlayerFreeze;
int iScrollTitle;

#define MAX_SCRIPTOBJECTS 60

int iDS;
LevelObject DS[100];
int iLS;
LevelObject LS[50];
int iPS;
LevelObject PS[100];
int iVS;
LevelObject VS[50];
int iWS;
LevelObject WS[50];
int iAS;
LevelObject AS[30];

// SCRIPT
int iMainScript, iDonutScript;

long iEvent1, iEvent2, iEvent3, iEvent4;
LevelObject* loSelected;

long miLevelExtentX;
long miLevelExtentY;

ScriptCode LevelScript;
ScriptContext SCLevel;
ScriptCode TitleScript;
ScriptContext SCTitle;

ScriptCode oObjectScript[5];
ScriptContext oObject[MAX_SCRIPTOBJECTS];

LARGE_INTEGER iTime;

// ------------------------------- BASIC GAME STUFF ----------------------------

long CollideWall(long iX1, long iY1, long iX2, long iY2) {
    long iW;
    int iLeft, iRight, iTop, iBottom;

    iW = -1;
    iLeft = 0;
    iRight = 0;
    iTop = 0;
    iBottom = 0;

    while (++iW < iWS) {
        if (PointInQuad(iX1, iY1, WS[iW].X1, WS[iW].Y1, WS[iW].X2, WS[iW].Y2, WS[iW].X3, WS[iW].Y3, WS[iW].X4, WS[iW].Y4)) {
            ++iLeft;
            ++iTop;
        }

        if (PointInQuad(iX2, iY1, WS[iW].X1, WS[iW].Y1, WS[iW].X2, WS[iW].Y2, WS[iW].X3, WS[iW].Y3, WS[iW].X4, WS[iW].Y4)) {
            ++iRight;
            ++iTop;
        }

        if (PointInQuad(iX1, iY2, WS[iW].X1, WS[iW].Y1, WS[iW].X2, WS[iW].Y2, WS[iW].X3, WS[iW].Y3, WS[iW].X4, WS[iW].Y4)) {
            ++iLeft;
            ++iBottom;
        }

        if (PointInQuad(iX2, iY2, WS[iW].X1, WS[iW].Y1, WS[iW].X2, WS[iW].Y2, WS[iW].X3, WS[iW].Y3, WS[iW].X4, WS[iW].Y4)) {
            ++iRight;
            ++iBottom;
        }
    }

    if (iTop > 1) {
        return 1;
    }

    if (iLeft) {
        return 3;
    }

    if (iRight) {
        return 4;
    }

    return 0;
}

void BuildNavigation() {
    int iLoop;
    int iTest;
    int iType;
    float iHeight;
    long iPlatform;
    long iEX;
    long iLen;
    long iH;

    iLoop = -1;

    while (++iLoop < iLS) {
        LS[iLoop].Navs = 0;
    }

    iLoop = -1;

    while (++iLoop < iPS) {
        PS[iLoop].Navs = 0;

        GetNextPlatform(PS[iLoop].X1 - 4, PS[iLoop].Y1, 4, 2, &iHeight, &iPlatform);

        if (iPlatform >= 0) {
            iType = NT_Platform;

            if (iHeight < PS[iLoop].Y1 - 4) {
                iType = NT_PlatformFallLeft;
            }

            PS[iLoop].NavTo[PS[iLoop].Navs] = iPlatform;
            PS[iLoop].NavToType[PS[iLoop].Navs] = iType;
            ++PS[iLoop].Navs;
        }

        GetNextPlatform(PS[iLoop].X2 + 4, PS[iLoop].Y2, 4, 2, &iHeight, &iPlatform);

        if (iPlatform >= 0) {
            iType = NT_Platform;

            if (iHeight < PS[iLoop].Y2 - 4) {
                iType = NT_PlatformFallRight;
            }

            PS[iLoop].NavTo[PS[iLoop].Navs] = iPlatform;
            PS[iLoop].NavToType[PS[iLoop].Navs] = iType;
            ++PS[iLoop].Navs;
        }

        iTest = -1;

        while (++iTest < iLS) {
            if (PS[iLoop].X1 < LS[iTest].X1 && PS[iLoop].X2 > LS[iTest].X1) {
                iEX = LS[iTest].X1;
                iLen = PS[iLoop].X2 - PS[iLoop].X1;
                iH = PS[iLoop].Y1 * abs(PS[iLoop].X2 - iEX) + PS[iLoop].Y2 * abs(PS[iLoop].X1 - iEX);
                iH /= iLen;

                if (iH < LS[iTest].Y1 + 2 && iH > LS[iTest].Y2 - 2) {
                    PS[iLoop].NavTo[PS[iLoop].Navs] = iTest;
                    PS[iLoop].NavToType[PS[iLoop].Navs] = NT_Ladder;
                    ++PS[iLoop].Navs;

                    LS[iTest].NavTo[LS[iTest].Navs] = iLoop;
                    LS[iTest].NavToType[LS[iTest].Navs] = NT_Platform;
                    ++LS[iTest].Navs;
                }
            }
        }
    }

    return;
}

long PlayerCollide(int iArg1, int iArg2, int iArg3, int iArg4) {
    if (iPlayerST & JS_JUMPING) {
        if (iPlayerX + 4 > iArg1 && iPlayerY + 9 > iArg2 && iPlayerX - 4 < iArg3 && iPlayerY + 4 < iArg4) {
            return 1;
        }
    } else if ((iPlayerST & JS_ROLL) && iPlayerAF < 12) {
        if (iPlayerX + 4 > iArg1 && iPlayerY + 7 > iArg2 && iPlayerX - 4 < iArg3 && iPlayerY + 3 < iArg4) {
            return 1;
        }
    } else if (iPlayerST & JS_ROLL) {
        if (iPlayerX + 3 > iArg1 && iPlayerY + 7 > iArg2 && iPlayerX - 3 < iArg3 && iPlayerY < iArg4) {
            return 1;
        }
    } else {
        if (iPlayerX + 2 > iArg1 && iPlayerY + 9 > iArg2 && iPlayerX - 2 < iArg3 && iPlayerY + 2 < iArg4) {
            return 1;
        }
    }

    return 0;
}

long GetNavDir(long iFrom, long iTo, long iFromType, long iToType) {
    int iLoop;

    iLoop = -1;

    while (++iLoop < iPS) {
        PS[iLoop].NavDist = 5000;
    }

    iLoop = -1;

    while (++iLoop < iLS) {
        LS[iLoop].NavDist = 5000;
    }

    if (iFrom < 0 || iTo < 0) {
        return -1;
    }

    if (iFromType == NT_Ladder) {
        LS[iFrom].NavDist = 0;
    }

    if (iFromType == NT_Platform) {
        PS[iFrom].NavDist = 0;
    }

    int iRep;
    int iNav;
    int iDone;
    int iNavTo;
    int iChoice;

    iDone = 0;
    iRep = -1;

    while (++iRep < 50 && !iDone) {
        iLoop = -1;

        while (++iLoop < iLS) {
            if (LS[iLoop].NavDist < 5000) {
                iNav = -1;

                while (++iNav < LS[iLoop].Navs) {
                    if (LS[iLoop].NavToType[iNav] == NT_Platform) {
                        iNavTo = LS[iLoop].NavTo[iNav];

                        if (PS[iNavTo].NavDist > LS[iLoop].NavDist + 1) {
                            PS[iNavTo].NavDist = LS[iLoop].NavDist + 1;
                            PS[iNavTo].NavChoice = LS[iLoop].NavChoice;

                            if (LS[iLoop].NavDist == 0) {
                                PS[iNavTo].NavChoice = iNavTo;
                            }
                        }
                    }
                }
            }
        }

        iLoop = -1;

        while (++iLoop < iPS) {
            if (PS[iLoop].NavDist < 5000) {
                int iNavType;
                iNav = -1;

                while (++iNav < PS[iLoop].Navs) {
                    iNavType = PS[iLoop].NavToType[iNav];

                    if (iNavType != NT_Ladder) {
                        iNavTo = PS[iLoop].NavTo[iNav];

                        if (PS[iNavTo].NavDist > PS[iLoop].NavDist + 1) {
                            PS[iNavTo].NavDist = PS[iLoop].NavDist + 1;
                            PS[iNavTo].NavChoice = PS[iLoop].NavChoice;

                            if (PS[iLoop].NavDist == 0) {
                                if (iNavType == NT_Platform) {
                                    PS[iNavTo].NavChoice = iNavTo;
                                }

                                if (iNavType == NT_PlatformFallLeft) {
                                    PS[iNavTo].NavChoice = iNavTo + 2000;
                                }

                                if (iNavType == NT_PlatformFallRight) {
                                    PS[iNavTo].NavChoice = iNavTo + 3000;
                                }
                            }
                        }
                    }

                    if (iNavType == NT_Ladder) {
                        iNavTo = PS[iLoop].NavTo[iNav];

                        if (LS[iNavTo].NavDist > PS[iLoop].NavDist + 1) {
                            LS[iNavTo].NavDist = PS[iLoop].NavDist + 1;
                            LS[iNavTo].NavChoice = PS[iLoop].NavChoice;

                            if (PS[iLoop].NavDist == 0) {
                                LS[iNavTo].NavChoice = iNavTo + 1000;
                            }
                        }
                    }
                }
            }
        }

        if (iToType == NT_Ladder && LS[iTo].NavDist < 5000) {
            iDone = 1;
        }

        if (iToType != NT_Ladder && PS[iTo].NavDist < 5000) {
            iDone = 1;
        }
    }

    if (iDone == 0) {
        return -1;
    }

    if (iToType == NT_Ladder) {
        iChoice = LS[iTo].NavChoice;
    }

    if (iToType != NT_Ladder) {
        iChoice = PS[iTo].NavChoice;
    }

    return iChoice;
}

long ExtFunction(long iFunc, ScriptContext* SC) {
    long iArg1, iArg2, iArg3, iArg4;
    long rArg1, rArg2, rArg3, rArg4;
    long iLoop;
    char sFileName[300];

    rArg1 = SC->Stack[SC->BP + 0];
    iArg1 = rArg1 / 256;
    rArg2 = SC->Stack[SC->BP + 1];
    iArg2 = rArg2 / 256;
    rArg3 = SC->Stack[SC->BP + 2];
    iArg3 = rArg3 / 256;
    rArg4 = SC->Stack[SC->BP + 3];
    iArg4 = rArg4 / 256;

    if (iFunc == EFCHANGEMESH) {
        ChangeMesh(miSelectedMesh, iOtherMesh[iArg1]);
    }

    if (iFunc == EFIDENTITY) {
        IdentityMatrix(miSelectedMesh);
    }

    if (iFunc == EFPERSPECTIVE) {
        PerspectiveMatrix(miSelectedMesh);
    }

    if (iFunc == EFTRANSLATE) {
        TranslateMatrix(miSelectedMesh, rArg1 / 256.0f, rArg2 / 256.0f, rArg3 / 256.0f);
    }

    if (iFunc == EFSCALE) {
        ScaleMatrix(miSelectedMesh, rArg1 / 256.0f, rArg2 / 256.0f, rArg3 / 256.0f);
    }

    if (iFunc == EFROTATEX) {
        RotateMatrixX(miSelectedMesh, rArg1 / 256.0f);
    }

    if (iFunc == EFROTATEY) {
        RotateMatrixY(miSelectedMesh, rArg1 / 256.0f);
    }

    if (iFunc == EFROTATEZ) {
        RotateMatrixZ(miSelectedMesh, rArg1 / 256.0f);
    }

    if (iFunc == EFSCROLLTEXTURE) {
        ScrollTexture(miSelectedMesh, rArg1 / 4096.0f, rArg2 / 4096.0f);
    }

    if (iFunc == EFSETSEL) {
        if (iArg1 == EFS_SX1) {
            loSelected->X1 = iArg2;
        } else if (iArg1 == EFS_SX2) {
            loSelected->X2 = iArg2;
        } else if (iArg1 == EFS_SY1) {
            loSelected->Y1 = iArg2;
        } else if (iArg1 == EFS_SY2) {
            loSelected->Y2 = iArg2;
        } else if (iArg1 == EFS_SZ1) {
            loSelected->Z1 = iArg2;
        } else if (iArg1 == EFS_SZ2) {
            loSelected->Z2 = iArg2;
        } else if (iArg1 == EFS_VISIBLE) {
            loSelected->Visible = iArg2;
        } else if (iArg1 == EFS_NUMBER) {
            loSelected->Num = iArg2;
        } else if (iArg1 == EFS_TEXTURE) {
            loSelected->Texture = iArg2;
        } else if (iArg1 == EFS_EXTRA) {
            loSelected->Extra = iArg2;
        }

        SetObjectData(miSelectedMesh, loSelected->Texture, loSelected->Visible);
    }

    if (iFunc == EFGETSEL) {
        if (iArg1 == EFS_SX1) {
            return loSelected->X1;
        } else if (iArg1 == EFS_SX2) {
            return loSelected->X2;
        } else if (iArg1 == EFS_SY1) {
            return loSelected->Y1;
        } else if (iArg1 == EFS_SY2) {
            return loSelected->Y2;
        } else if (iArg1 == EFS_SZ1) {
            return loSelected->Z1;
        } else if (iArg1 == EFS_SZ2) {
            return loSelected->Z2;
        } else if (iArg1 == EFS_VISIBLE) {
            return loSelected->Visible;
        } else if (iArg1 == EFS_NUMBER) {
            return loSelected->Num;
        } else if (iArg1 == EFS_TEXTURE) {
            return loSelected->Texture;
        } else if (iArg1 == EFS_EXTRA) {
            return loSelected->Extra;
        } else if (iArg1 == EFS_THIS) {
            return loSelected->ObjectNumber;
        }
    }

    if (iFunc == EFGETNAVDIR) {
        return GetNavDir(iArg1, iArg2, iArg3, iArg4);
    }

    if (iFunc == EFSTRCOPY) {
        iLoop = -1;

        while (++iLoop <= iArg2) {
            SC->Globals[iArg1 + iLoop] = SC->Stack[SC->SP + iLoop + 1];
        }
    }

    int iLen1;
    int iLen2;

    if (iFunc == EFSTRCAT) {
        iLen1 = SC->Globals[iArg1] / 256;
        iLen2 = SC->Globals[iArg2] / 256;
        SC->Globals[iArg1] = (iLen1 + iLen2) * 256;
        iLoop = 0;

        while (++iLoop <= iLen2) {
            SC->Globals[iArg1 + iLen1 + iLoop] = SC->Globals[iArg2 + iLoop];
        }
    }

    if (iFunc == EFGET) {
        if (iArg1 == EFV_PX) {
            return (long)(iPlayerX * 256.0f);
        } else if (iArg1 == EFV_PY) {
            return (long)(iPlayerY * 256.0f);
        } else if (iArg1 == EFV_PZ) {
            return (long)(iPlayerZ * 256.0f);
        } else if (iArg1 == EFV_PSTAT) {
            return iPlayerST * 256;
        } else if (iArg1 == EFV_PSC) {
            return iPlayerSC * 256;
        } else if (iArg1 == EFV_PDIR) {
            return iPlayerDIR * 256;
        } else if (iArg1 == EFV_PACT) {
            return iPlayerACT * 256;
        } else if (iArg1 == EFV_SHOWFPS) {
            return iShowFPS * 256;
        } else if (iArg1 == EFV_LIVESREMAINING) {
            return GameLivesRemaining * 256;
        } else if (iArg1 == EFV_EVENT1) {
            return iEvent1 * 256;
        } else if (iArg1 == EFV_EVENT2) {
            return iEvent2 * 256;
        } else if (iArg1 == EFV_EVENT3) {
            return iEvent3;
        } else if (iArg1 == EFV_EVENT4) {
            return iEvent4;
        } else if (iArg1 == EFV_DEBUG) {
            return miDEBUG * 256;
        } else if (iArg1 == EFV_PERSPECTIVE) {
            return miPerspective * 256;
        } else if (iArg1 == EFV_OBJECTS) {
            return MAX_SCRIPTOBJECTS * 256;
        } else if (iArg1 == EFV_DONUTS) {
            return iDS * 256;
        } else if (iArg1 == EFV_TEXTURES) {
            return miTextures * 256;
        } else if (iArg1 == EFV_PLATFORMS) {
            return iPS * 256;
        } else if (iArg1 == EFV_LADDERS) {
            return iLS * 256;
        } else if (iArg1 == EFV_VINES) {
            return iVS * 256;
        } else if (iArg1 == EFV_WALLS) {
            return iWS * 256;
        } else if (iArg1 == EFV_LEVELEXTENTX) {
            return miLevelExtentX * 256;
        } else if (iArg1 == EFV_THIS) {
            return SC->ScriptReference * 256;
        } else if (iArg1 == EFV_INPUTLEFT) {
            return (iKeyLeft || iTKeyLeft ? 1 : 0) * 256;
        } else if (iArg1 == EFV_INPUTRIGHT) {
            return (iKeyRight || iTKeyRight ? 1 : 0) * 256;
        } else if (iArg1 == EFV_INPUTUP) {
            return (iKeyUp || iTKeyUp ? 1 : 0) * 256;
        } else if (iArg1 == EFV_INPUTDOWN) {
            return (iKeyDown || iTKeyDown ? 1 : 0) * 256;
        } else if (iArg1 == EFV_INPUTJUMP) {
            return (iKeyJump || iTKeyJump ? 1 : 0) * 256;
        } else if (iArg1 == EFV_INPUTATTACK) {
            return (iKeyAttack || iTKeyAttack ? 1 : 0) * 256;
        } else if (iArg1 == EFV_INPUTSELECT) {
            return iKeySelect * 256;
        } else if (iArg1 == EFV_FREEZE) {
            return iPlayerFreeze * 256;
        } else if (iArg1 == EFV_SOUNDON) {
            return GameSoundOn * 256;
        } else if (iArg1 == EFV_MUSICON) {
            return GameMusicOn * 256;
        } else if (iArg1 == EFV_LASTKEY) {
            return iLastKey * 256;
        } else if (iArg1 == EFV_PERFORMANCE) {
            return GamePerformance * 256;
        }
    }

    if (iFunc == EFSET) {
        if (iArg1 == EFV_PX) {
            iPlayerX = static_cast<float>(rArg2) / 256;
        } else if (iArg1 == EFV_PY) {
            iPlayerY = static_cast<float>(rArg2) / 256;
        } else if (iArg1 == EFV_PZ) {
            iPlayerZ = static_cast<float>(iArg2);
        } else if (iArg1 == EFV_PSTAT) {
            iPlayerST = iArg2;
        } else if (iArg1 == EFV_PSC) {
            iPlayerSC = iArg2;
        } else if (iArg1 == EFV_PDIR) {
            iPlayerDIR = iArg2;
        } else if (iArg1 == EFV_PACT) {
            iPlayerACT = iArg2;
        } else if (iArg1 == EFV_EVENT1) {
            iEvent1 = iArg2;
        } else if (iArg1 == EFV_EVENT2) {
            iEvent2 = iArg2;
        } else if (iArg1 == EFV_EVENT3) {
            iEvent3 = iArg2;
        } else if (iArg1 == EFV_EVENT4) {
            iEvent4 = iArg2;
        } else if (iArg1 == EFV_PERSPECTIVE) {
            miPerspective = iArg2;
        } else if (iArg1 == EFV_DEBUG) {
            miDEBUG = iArg2;
        } else if (iArg1 == EFV_LEVELEXTENTX) {
            miLevelExtentX = iArg2;
        } else if (iArg1 == EFV_NOROLL) {
            iPlayerNoRoll = iArg2;
        } else if (iArg1 == EFV_FREEZE) {
            iPlayerFreeze = iArg2;
        } else if (iArg1 == EFV_PVISIBLE) {
            iPlayerVisible = iArg2;
        } else if (iArg1 == EFV_LIVESREMAINING) {
            GameLivesRemaining = iArg2;
        }

        return 0;
    }

    if (iFunc == EFSPAWN) {
        long iNewObject = -1;
        iLoop = -1;

        while (++iLoop < MAX_SCRIPTOBJECTS) {
            if (!oObject[iLoop].Active && iNewObject == -1) {
                iNewObject = iLoop;
            }
        }

        if (iNewObject < 0) {
            iNewObject = 0;
        }

        ResetContext(&oObject[iNewObject]);
        oObject[iNewObject].Script = &oObjectScript[iArg1];
        oObject[iNewObject].ScriptNumber = iArg1;
        oObject[iNewObject].ScriptReference = iNewObject;
        oObject[iNewObject].Active = 2;

        return iNewObject;
    }

    if (iFunc == EFNEWMESH) {
        long iNew;
        CopyObject(iOtherMesh[iArg1], &iNew);
        miSelectedMesh = iNew;
        return iNew;
    }

    if (iFunc == EFNEWCHARMESH) {
        long iNew;

        if (iArg1 >= 97) {
            iArg1 += 65 - 97;
        }

        if (iCharMesh[iArg1] >= 0) {
            CopyObject(iCharMesh[iArg1], &iNew);
            miSelectedMesh = iNew;
            return iNew;
        } else {
            return -1;
        }
    }

    if (iFunc == EFSETOBJECT) {
        SetObjectData(miSelectedMesh, iArg1, iArg2);
    }

    if (iFunc == EFPRIORITIZE_OBJECT) {
        PrioritizeObject(miSelectedMesh);
    }

    if (iFunc == EFSETDATA) {
        oObject[iArg1].Globals[iArg2] = rArg3;
    }

    if (iFunc == EFGETDATA) {
        if (iArg2 == 1000) {
            if (oObject[iArg1].Active) {
                return oObject[iArg1].ScriptNumber * 256;
            } else {
                return -256;
            }
        }

        return oObject[iArg1].Globals[iArg2];
    }

    if (iFunc == EFRND) {
        long iRand;
        iRand = (rand() & 16383) * (iArg2 - iArg1) / 16383 + iArg1;
        return iRand;
    }

    if (iFunc == EFFINDLADDER) {
        long iLadA, iLadE;
        FindLadder(iArg1, iArg2, &iLadA, &iLadE);
        iEvent4 = iLadA * 256;
        return iLadE;
    }

    if (iFunc == EFFINDVINE) {
        long iVinAp, iVinEx;
        FindVine(iArg1, iArg2, &iVinAp, &iVinEx);
        iEvent4 = iVinAp * 256;

        return iVinEx;
    }

    if (iFunc == EFFINDPLATFORM) {
        float iFind;
        long iPlat;
        GetNextPlatform(iArg1, iArg2, iArg3, iArg4, &iFind, &iPlat);
        iEvent4 = static_cast<long>(iFind) * 256;
        return iPlat;
    }

    long iVal;

    if (iFunc == EFSIN) {
        iVal = static_cast<long>(sin(rArg1 * 3.1415f / 180.0f / 256.0f) * iArg2);
        return iVal;
    }

    if (iFunc == EFCOS) {
        iVal = static_cast<long>(cos(rArg1 * 3.1415f / 180.0f / 256.0f) * iArg2);
        return iVal;
    }

    if (iFunc == EFATAN) {
        if (rArg2 == 0) {
            iVal = (rArg1 > 0 ? 90 : 270);
        } else {
            iVal = static_cast<long>(atan(static_cast<double>(rArg1) / static_cast<double>(rArg2)) * 180.0f / 3.1415f);
        }
        return iVal;
    }

    if (iFunc == EFSQR) {
        iVal = static_cast<long>(sqrt(rArg1 / 256.0f));
        return iVal;
    }

    if (iFunc == EFABS_PLATFORM) {
        loSelected = &PS[iArg1];
        miSelectedMesh = loSelected->MeshNumber;
        return 0;
    }

    if (iFunc == EFABS_LADDER) {
        loSelected = &LS[iArg1];
        miSelectedMesh = loSelected->MeshNumber;
        return 0;
    }

    if (iFunc == EFABS_DONUT) {
        loSelected = &DS[iArg1];
        miSelectedMesh = loSelected->MeshNumber;
        return 0;
    }

    if (iFunc == EFABS_VINE) {
        loSelected = &VS[iArg1];
        miSelectedMesh = loSelected->MeshNumber;
        return 0;
    }

    if (iFunc == EFCOLLIDE_WALL) {
        return CollideWall(iArg1, iArg2, iArg3, iArg4);
    }

    if (iFunc == EFSETFOG) {
        SetFog((float)iArg1, (float)iArg2, SC->Stack[SC->BP + 2] & 0xFF, SC->Stack[SC->BP + 3] & 0xFF, SC->Stack[SC->BP + 4] & 0xFF);
    }

    WIN32_FIND_DATA FindFileData;
    HANDLE hFind;
    int iTitle;
    int iChar;
    char sName[100];
    char sFile[300];
    int iKey;
    int iKeyGood;
    DWORD iWritten;
    HANDLE hFile;

    if (iFunc == EFSERVICE) {
        if (iArg1 == SERVICE_LEVELTITLE) {
            SC->Globals[iArg2] = static_cast<long>(strlen(GameTitle)) * 256;
            iLoop = 0;

            while (++iLoop <= static_cast<long>(strlen(GameTitle))) {
                SC->Globals[iArg2 + iLoop] = GameTitle[iLoop - 1] * 256;
            }
        }

        if (iArg1 == SERVICE_SAVEOPTIONS) {
            sprintf_s(sFile, "%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d\x0D\x0A%d", GameKeys[0], GameKeys[1], GameKeys[2], GameKeys[3], GameKeys[4], GameKeys[5], GameSoundOn, GameMusicOn);
            char sFileName[300];
            sprintf_s(sFileName, "%s\\Data\\Settings.dat", GamePath);
            hFile = CreateFile(sFileName, GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
            WriteFile(hFile, sFile, static_cast<long>(strlen(sFile)), &iWritten, NULL);
            CloseHandle(hFile);
        }

        if (iArg1 == SERVICE_SETOPTION) {
            if (iArg3 >= 0 && iArg3 <= 5) {
                iKeyGood = 0;
                iKey = iArg2;

                if (iKey == 38 && iArg3 == 0) {
                    iKeyGood = 1;
                }

                if (iKey == 40 && iArg3 == 1) {
                    iKeyGood = 1;
                }

                if (iKey == 37 && iArg3 == 2) {
                    iKeyGood = 1;
                }

                if (iKey == 39 && iArg3 == 3) {
                    iKeyGood = 1;
                }

                if (iKey == 32 && iArg3 == 4) {
                    iKeyGood = 1;
                }

                if (iKey >= 'A' && iKey <= 'Z') {
                    iKeyGood = 1;
                }

                if (iKey >= '0' && iKey <= '9') {
                    iKeyGood = 1;
                }

                iLoop = -1;

                while (++iLoop < 6) {
                    if (iArg2 != iLoop && GameKeys[iLoop] == iKey) {
                        iKeyGood = 0;
                    }
                }

                if (iKeyGood) {
                    GameKeys[iArg3] = iKey;
                }
            }

            if (iArg3 == 32) {
                GameSoundOn = iArg2;
            }

            if (iArg3 == 33 && GameMusicOn != iArg2) {
                if (iArg2 == 0) {
                    StopMusic1();
                } else {
                    NewTrack1(msBackMusic, 0, 0);
                }
                GameMusicOn = iArg2;
            }
        }

        if (iArg1 == SERVICE_OPTIONSTRING) {
            if (iArg3 >= 0 && iArg3 <= 5) {
                iKey = GameKeys[iArg3];

                if (iKey >= 'A' && iKey <= 'Z') {
                    sprintf_s(sName, "%c   ", iKey);
                } else if (iKey >= '0' && iKey <= '9') {
                    sprintf_s(sName, "%c   ", iKey);
                } else if (iKey == 38) {
                    sprintf_s(sName, "UP  ");
                } else if (iKey == 40) {
                    sprintf_s(sName, "DOWN");
                } else if (iKey == 37) {
                    sprintf_s(sName, "LEFT");
                } else if (iKey == 39) {
                    sprintf_s(sName, "RGHT");
                } else if (iKey == 32) {
                    sprintf_s(sName, "SPC ");
                } else if (iKey == 58) {
                    sprintf_s(sName, ":   ");
                } else if (iKey == 46) {
                    sprintf_s(sName, ".   ");
                } else if (iKey == 45) {
                    sprintf_s(sName, "-   ");
                }
            } else if (iArg3 == 32 || iArg3 == 33) {
                if (iArg3 == 32) {
                    iKey = GameSoundOn;
                } else {
                    iKey = GameMusicOn;
                }

                if (iKey) {
                    sprintf_s(sName, "ON  ");
                } else {
                    sprintf_s(sName, "OFF ");
                }
            }

            SC->Globals[iArg2] = 1024;
            SC->Globals[iArg2 + 1] = sName[0] * 256;
            SC->Globals[iArg2 + 2] = sName[1] * 256;
            SC->Globals[iArg2 + 3] = sName[2] * 256;
            SC->Globals[iArg2 + 4] = sName[3] * 256;
        }

        if (iArg1 == SERVICE_LOADMENU) {
            iEvent1 = iEvent1 - 1;
            GameStatus = GS_MENU;
            GameMenu = iArg2;
        }

        if (iArg1 == SERVICE_GAMESTART) {
            iTitle = 0;
            GameLivesRemaining = 7;
            sprintf_s(sFileName, "%s\\Data\\*.jmg", GamePath);
            hFind = FindFirstFile(sFileName, &FindFileData);

            while (iTitle < iArg2) {
                FindNextFile(hFind, &FindFileData);
                ++iTitle;
            }

            FindClose(hFind);
            sprintf_s(GameFile, "%s\\Data\\%s", GamePath, FindFileData.cFileName);
            GameStatus = GS_INLEVEL;
        }

        if (iArg1 == SERVICE_CREDITLINE) {
            sprintf_s(sFileName, "%s\\Data\\credits.txt", GamePath);
            GetFileLine(sName, sizeof(sName), sFileName, iArg2);
            iChar = -1;

            while (sName[++iChar] != 0 && iChar < 18) {
                SC->Globals[iArg3 + iChar + 1] = sName[iChar] * 256;
            }

            SC->Globals[iArg3] = iChar * 256;
        }

        if (iArg1 == SERVICE_GAMELIST) {
            iTitle = 0;
            sprintf_s(sFileName, "%s\\Data\\*.jmg", GamePath);
            hFind = FindFirstFile(sFileName, &FindFileData);

            while (hFind != INVALID_HANDLE_VALUE) {
                iChar = -1;
                sprintf_s(sFile, "%s\\Data\\%s", GamePath, FindFileData.cFileName);
                GetFileLine(sName, sizeof(sName), sFile, 0);

                while (sName[++iChar] != 0 && iChar < 18) {
                    SC->Globals[iArg2 + iTitle * 20 + iChar + 1] = sName[iChar] * 256;
                }
                SC->Globals[iArg2 + iTitle * 20] = iChar * 256;
                iTitle = iTitle + 1;

                if (!FindNextFile(hFind, &FindFileData)) {
                    FindClose(hFind);
                    hFind = INVALID_HANDLE_VALUE;
                }
            }

            return iTitle;
        }
    }

    if (iFunc == EFSOUND) {
        if (GameSoundOn) {
            PlaySound(iArg1);
        }
    }

    if (iFunc == EFCOLLIDE) {
        return PlayerCollide(iArg1, iArg2, iArg3, iArg4) && !(iPlayerST == JS_DYING);
    }

    if (iFunc == EFKILL && !(iPlayerST & JS_DYING)) {
        if (GameMusicOn) {
            StopMusic1();
        }

        iPlayerST = JS_DYING;
        iPlayerACT = 0;
        iPlayerAS = 1;
        iPlayerAX = 0;
        iPlayerMX = 0;
        iPlayerAF = iPlayerSC;
        iPlayerSC = 1000;
    }

    if (iFunc == EFPRINT && miDEBUG) {
        char sNum[100];

        if (iArg1 == -1) {
            sprintf_s(sNum, "\n");
        } else if (iArg1 == -2) {
            sprintf_s(sNum, " ");
        } else {
            sprintf_s(sNum, "%.0f", rArg1 / 256.0f);
        }

        OutputDebugString(sNum);
    }

    if (iFunc == EFWIN) {
        if (GameMusicOn) {
            StopMusic1();
        }

        iPlayerSC = 0;
        iPlayerST = JS_DONE;
    }

    if (iFunc == EFSELECT_OBJECT_MESH) {
        miSelectedMesh = iArg1;
    }

    if (iFunc == EFDELETE_MESH) {
        DeleteMesh(iArg1);
    }

    if (iFunc == EFDELETE_OBJECT) {
        if (iArg1 == 1000) {
            SC->Active = 0;
        } else {
            oObject[iArg1].Active = 0;
        }
    }

    if (iFunc == EFRESETPERSPECTIVE) {
        SetGamePerspective();
    }

    if (iFunc == EFSELECT_PLATFORM || iFunc == EFSELECT_LADDER || iFunc == EFSELECT_DONUT || iFunc == EFSELECT_VINE || iFunc == EFSELECT_PICTURE || iFunc == EFSELECT_WALL) {
        int iObj;

        if (iFunc == EFSELECT_WALL) {
            iObj = FindObject(WS, iWS, iArg1);
            loSelected = &WS[iObj];
        }

        if (iFunc == EFSELECT_PLATFORM) {
            iObj = FindObject(PS, iPS, iArg1);
            loSelected = &PS[iObj];
        }

        if (iFunc == EFSELECT_VINE) {
            iObj = FindObject(VS, iVS, iArg1);
            loSelected = &VS[iObj];
        }

        if (iFunc == EFSELECT_LADDER) {
            iObj = FindObject(LS, iLS, iArg1);
            loSelected = &LS[iObj];
        }

        if (iFunc == EFSELECT_DONUT) {
            iObj = FindObject(DS, iDS, iArg1);
            loSelected = &DS[iObj];
        }

        if (iFunc == EFSELECT_PICTURE) {
            iObj = FindObject(AS, iAS, iArg1);
            loSelected = &AS[iObj];
        }

        miSelectedMesh = loSelected->MeshNumber;

        if (iObj < 0) {
            return -1;
        }
    }

    return -1;
}

int FindObject(LevelObject* lObj, int iCount, int iFind) {
    int iLoop;
    iLoop = -1;

    while (++iLoop < iCount) {
        if (lObj[iLoop].Num == iFind) {
            return iLoop;
        }
    }

    return -1;
}

void CleanResources() {
    int iLoop;

    iLoop = -1;

    while (++iLoop < iPS) {
        free(PS[iLoop].Mesh);
    }

    iLoop = -1;

    while (++iLoop < iLS) {
        free(LS[iLoop].Mesh);
    }

    iLoop = -1;

    while (++iLoop < iDS) {
        free(DS[iLoop].Mesh);
    }

    iLoop = -1;

    while (++iLoop < iVS) {
        free(VS[iLoop].Mesh);
    }

    iLoop = -1;

    while (++iLoop < iWS) {
        free(WS[iLoop].Mesh);
    }

    iLoop = -1;

    while (++iLoop < iAS) {
        free(AS[iLoop].Mesh);
    }
}

void ComposeObject(LevelObject* lObj, long* oData, long* iPlace) {
    int iCopy;

    iCopy = -1;

    while (++iCopy < lObj->MeshSize) {
        oData[*iPlace] = lObj->Mesh[iCopy];
        ++*iPlace;
    }
}

void LoadLevel(char* sFileName) {
    unsigned char* cData;

    char sTemp[300];

    int iLen;
    int iPlace;
    int iLoop;
    int iData;
    char sBuild[200];
    long iTemp;
    long iArg1;
    long iArg2;
    long iNum;

    long* oData;
    long iMPlace;
    int iSounds;

    iPlayerFreeze = 0;
    iPlayerNoRoll = 0;
    iPlayerVisible = 1;

    miLevelExtentX = 160;
    miLevelExtentY = 160;

    miPerspective = 0;
    miTextures = 0;
    miMeshes = 0;
    miScripts = 0;
    iSounds = 0;

    iLoop = -1;

    while (++iLoop < MAX_SCRIPTOBJECTS) {
        oObject[iLoop].Active = 0;
    }

    iPS = 0;
    iLS = 0;
    iDS = 0;
    iVS = 0;
    iWS = 0;
    iAS = 0;

    cData = NULL;
    iLen = FileToString(sFileName, &cData);

    iPlace = 0;

    while (iPlace < iLen) {
        sTemp[8] = 0;

        if (cData[iPlace] == 'R' && cData[iPlace + 1] == 0) {
            iPlace += 2;
            iLoop = -1;

            while (++iLoop < 30) {
                sTemp[iLoop] = cData[iPlace + iLoop];
            }
            iPlace += 30;

            iTemp = StringToInt(&cData[iPlace + 0]);
            iArg1 = StringToInt(&cData[iPlace + 2]);
            iArg2 = StringToInt(&cData[iPlace + 4]);

            if (iTemp == 1) {
                sprintf_s(sBuild, "%s\\Sound\\%s.MID", GamePath, sTemp);

                if (iArg1 == 1) {
                    strcpy_s(msBackMusic, sBuild);
                    miIntroLength = iArg2 * 10;
                }

                if (iArg1 == 2) {
                    strcpy_s(msDeathMusic, sBuild);
                }

                if (iArg1 == 3) {
                    strcpy_s(msWinMusic, sBuild);
                }
            }

            if (iTemp == 2) {
                sprintf_s(sBuild, "%s.MSH", sTemp);
                iOtherMesh[miMeshes] = LoadMesh(sBuild);
                ++miMeshes;
            }

            if (iTemp == 7) {
                sprintf_s(sBuild, "%s\\Sound\\%s.WAV", GamePath, sTemp);
                LoadSound(sBuild, iSounds);
                ++iSounds;
            }

            if (iTemp == 3 || iTemp == 4 || iTemp == 6) {
                sprintf_s(sBuild, "%s\\Data\\%s", GamePath, sTemp);

                if (iTemp == 3) {
                    strcat_s(sBuild, ".BMP");
                }

                if (iTemp == 4) {
                    strcat_s(sBuild, ".JPG");
                }

                if (iTemp == 6) {
                    strcat_s(sBuild, ".PNG");
                }

                LoadTexture(miTextures, sBuild, iArg1, (iTemp == 6) || (iTemp == 3 && iArg1 == 1));
                ++miTextures;
            }

            if (iTemp == 5) {
                sprintf_s(sBuild, "%s\\Data\\%s.BIN", GamePath, sTemp);

                if (iArg1 == 1) {
                    LoadScript(sBuild, &LevelScript);
                    ResetContext(&SCLevel);
                    SCLevel.Script = &LevelScript;
                    iMainScript = FindScript(&SCLevel, "main");
                    iDonutScript = FindScript(&SCLevel, "donut");
                } else {
                    LoadScript(sBuild, &oObjectScript[miScripts]);
                    ++miScripts;
                }
            }

            iPlace += 8;
        } else if (cData[iPlace] == 'A' && cData[iPlace + 1] == 0) {
            iPlace += 10;

            AS[iAS].Texture = StringToInt(&cData[iPlace + 0]);
            AS[iAS].X1 = StringToInt(&cData[iPlace + 2]);
            AS[iAS].Y1 = StringToInt(&cData[iPlace + 4]);
            AS[iAS].Num = StringToInt(&cData[iPlace + 6]);
            AS[iAS].Visible = 1;
            iPlace += 20;

            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            AS[iAS].Mesh = static_cast<long*>(malloc(iData * sizeof(long)));
            AS[iAS].MeshSize = iData;
            AS[iAS].ObjectNumber = iAS;

            iNum = -1;

            while (++iNum < iData) {
                AS[iAS].Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }
            iPlace += iNum << 2;

            oData = static_cast<long*>(malloc(AS[iAS].MeshSize * sizeof(long)));
            iMPlace = 0;
            ComposeObject(&AS[iAS], oData, &iMPlace);
            CreateObject(oData, iMPlace / 9, &iNum);
            SetObjectData(iNum, AS[iAS].Texture, AS[iAS].Visible);

            AS[iAS].MeshNumber = iNum;
            free(oData);

            ++iAS;
        } else if (cData[iPlace] == 'L' && cData[iPlace + 1] == 0) {
            iLoop = -1;

            while (++iLoop < 8) {
                LS[iLS].Func[iLoop] = cData[iPlace + 2 + iLoop];
            }
            iPlace += 10;

            LS[iLS].Visible = 1;
            LS[iLS].X1 = StringToInt(&cData[iPlace + 0]);
            LS[iLS].Y1 = StringToInt(&cData[iPlace + 2]);
            LS[iLS].Y2 = StringToInt(&cData[iPlace + 4]);
            LS[iLS].Z1 = StringToInt(&cData[iPlace + 6]);
            LS[iLS].Z2 = StringToInt(&cData[iPlace + 8]);
            LS[iLS].Num = StringToInt(&cData[iPlace + 10]);
            LS[iLS].Texture = StringToInt(&cData[iPlace + 12]);
            iPlace += 20;

            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            LS[iLS].Mesh = static_cast<long*>(malloc(iData * sizeof(long)));
            LS[iLS].MeshSize = iData;
            LS[iLS].ObjectNumber = iLS;

            iNum = -1;

            while (++iNum < iData) {
                LS[iLS].Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            oData = static_cast<long*>(malloc(LS[iLS].MeshSize * sizeof(long)));
            iMPlace = 0;
            ComposeObject(&LS[iLS], oData, &iMPlace);
            CreateObject(oData, iMPlace / 9, &iNum);
            SetObjectData(iNum, LS[iLS].Texture, LS[iLS].Visible);
            LS[iLS].MeshNumber = iNum;
            free(oData);

            ++iLS;
        } else if (cData[iPlace] == 'W' && cData[iPlace + 1] == 0) {
            iLoop = -1;

            while (++iLoop < 8) {
                WS[iWS].Func[iLoop] = cData[iPlace + 2 + iLoop];
            }

            iPlace += 10;

            WS[iWS].Visible = 1;
            WS[iWS].X1 = StringToInt(&cData[iPlace + 0]);
            WS[iWS].Y1 = StringToInt(&cData[iPlace + 2]);
            WS[iWS].X2 = StringToInt(&cData[iPlace + 4]);
            WS[iWS].Y2 = StringToInt(&cData[iPlace + 6]);
            WS[iWS].X3 = StringToInt(&cData[iPlace + 8]);
            WS[iWS].Y3 = StringToInt(&cData[iPlace + 10]);
            WS[iWS].X4 = StringToInt(&cData[iPlace + 12]);
            WS[iWS].Y4 = StringToInt(&cData[iPlace + 14]);

            WS[iWS].Num = StringToInt(&cData[iPlace + 16]);
            WS[iWS].Texture = StringToInt(&cData[iPlace + 18]);

            iPlace += 20;

            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            WS[iWS].Mesh = static_cast<long*>(malloc(iData * sizeof(long)));
            WS[iWS].MeshSize = iData;
            WS[iWS].ObjectNumber = iWS;

            long iNum;

            iNum = -1;

            while (++iNum < iData) {
                WS[iWS].Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            oData = static_cast<long*>(malloc(WS[iWS].MeshSize * sizeof(long)));
            iMPlace = 0;
            ComposeObject(&WS[iWS], oData, &iMPlace);
            CreateObject(oData, iMPlace / 9, &iNum);
            SetObjectData(iNum, WS[iWS].Texture, WS[iWS].Visible);
            WS[iWS].MeshNumber = iNum;
            free(oData);

            ++iWS;
        } else if (cData[iPlace] == 'V' && cData[iPlace + 1] == 0) {
            iLoop = -1;

            while (++iLoop < 8) {
                VS[iVS].Func[iLoop] = cData[iPlace + 2 + iLoop];
            }

            iPlace += 10;

            VS[iVS].Visible = 1;
            VS[iVS].X1 = StringToInt(&cData[iPlace + 0]);
            VS[iVS].Y1 = StringToInt(&cData[iPlace + 2]);
            VS[iVS].Y2 = StringToInt(&cData[iPlace + 4]);
            VS[iVS].Z1 = StringToInt(&cData[iPlace + 6]);
            VS[iVS].Z2 = StringToInt(&cData[iPlace + 8]);
            VS[iVS].Num = StringToInt(&cData[iPlace + 10]);
            VS[iVS].Texture = StringToInt(&cData[iPlace + 12]);
            iPlace += 20;

            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            VS[iVS].Mesh = static_cast<long*>(malloc(iData * sizeof(long)));
            VS[iVS].MeshSize = iData;
            VS[iVS].ObjectNumber = iVS;

            long iNum;

            iNum = -1;

            while (++iNum < iData) {
                VS[iVS].Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            oData = static_cast<long*>(malloc(VS[iVS].MeshSize * sizeof(long)));
            iMPlace = 0;
            ComposeObject(&VS[iVS], oData, &iMPlace);
            CreateObject(oData, iMPlace / 9, &iNum);
            SetObjectData(iNum, VS[iVS].Texture, VS[iVS].Visible);
            VS[iVS].MeshNumber = iNum;
            free(oData);

            ++iVS;
        } else if (cData[iPlace] == 'D' && cData[iPlace + 1] == 0) {
            iLoop = -1;

            while (++iLoop < 8) {
                DS[iDS].Func[iLoop] = cData[iPlace + 2 + iLoop];
            }

            iPlace += 10;

            DS[iDS].Visible = 1;
            DS[iDS].X1 = StringToInt(&cData[iPlace + 0]);
            DS[iDS].Y1 = StringToInt(&cData[iPlace + 2]);
            DS[iDS].Z1 = StringToInt(&cData[iPlace + 4]);
            DS[iDS].Num = StringToInt(&cData[iPlace + 6]);
            DS[iDS].Texture = StringToInt(&cData[iPlace + 8]);
            iPlace += 20;

            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            DS[iDS].Mesh = static_cast<long*>(malloc(iData * sizeof(long)));
            DS[iDS].MeshSize = iData;
            DS[iDS].ObjectNumber = iDS;

            long iNum;

            iNum = -1;

            while (++iNum < iData) {
                DS[iDS].Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            oData = static_cast<long*>(malloc(DS[iDS].MeshSize * sizeof(long)));
            iMPlace = 0;
            ComposeObject(&DS[iDS], oData, &iMPlace);
            CreateObject(oData, iMPlace / 9, &iNum);
            SetObjectData(iNum, DS[iDS].Texture, DS[iDS].Visible);
            DS[iDS].MeshNumber = iNum;
            free(oData);

            ++iDS;
        } else if (cData[iPlace] == 'P' && cData[iPlace + 1] == 0) {
            iLoop = -1;

            while (++iLoop < 8) {
                PS[iPS].Func[iLoop] = cData[iPlace + 2 + iLoop];
            }

            iPlace += 10;

            PS[iPS].Visible = 1;
            PS[iPS].X1 = StringToInt(&cData[iPlace + 0]);
            PS[iPS].Y1 = StringToInt(&cData[iPlace + 2]);
            PS[iPS].X2 = StringToInt(&cData[iPlace + 4]);
            PS[iPS].Y2 = StringToInt(&cData[iPlace + 6]);
            PS[iPS].Z1 = StringToInt(&cData[iPlace + 8]);
            PS[iPS].Extra = StringToInt(&cData[iPlace + 10]);
            PS[iPS].Num = StringToInt(&cData[iPlace + 12]);
            PS[iPS].Texture = StringToInt(&cData[iPlace + 14]);
            iPlace += 20;

            iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            PS[iPS].Mesh = static_cast<long*>(malloc(iData * sizeof(long)));
            PS[iPS].MeshSize = iData;
            PS[iPS].ObjectNumber = iPS;

            long iNum;

            iNum = -1;

            while (++iNum < iData) {
                PS[iPS].Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            oData = static_cast<long*>(malloc(PS[iPS].MeshSize * sizeof(long)));
            iMPlace = 0;
            ComposeObject(&PS[iPS], oData, &iMPlace);
            CreateObject(oData, iMPlace / 9, &iNum);
            SetObjectData(iNum, PS[iPS].Texture, PS[iPS].Visible);
            PS[iPS].MeshNumber = iNum;
            free(oData);

            ++iPS;
        } else {
            return;
        }
    }

    free(cData);

    int iChar;
    char sFile[100];
    char sChar[10];
    int bGood;

    iChar = -1;

    while (++iChar < 100) {
        bGood = 1;

        if ((iChar >= 'A' && iChar <= 'Z') || (iChar >= '0' && iChar <= '9')) {
            sprintf_s(sChar, "%c", iChar);
        } else if (iChar == '.') {
            sprintf_s(sChar, "Period");
        } else if (iChar == '\'') {
            sprintf_s(sChar, "Apos");
        } else if (iChar == '-') {
            sprintf_s(sChar, "Dash");
        } else if (iChar == ':') {
            sprintf_s(sChar, "Colon");
        } else if (iChar == '%') {
            sprintf_s(sChar, "Square");
        } else if (iChar == '^') {
            sprintf_s(sChar, "Jump");
        } else {
            bGood = 0;
        }

        if (bGood) {
            sprintf_s(sFile, "Char%s.MSH", sChar);
            iCharMesh[iChar] = LoadMesh(sFile);
        } else {
            iCharMesh[iChar] = -1;
        }
    }

    sprintf_s(sTemp, "%s\\Data\\panel.bmp", GamePath);
    LoadTexture(miTextures, sTemp, 0, 0);
    ++miTextures;

    sprintf_s(sTemp, "%s\\Data\\Titles.png", GamePath);
    LoadTexture(miTextures, sTemp, 0, 0);
    ++miTextures;
}

void FindVine(long iX, long iY, long* iAbout, long* iExact) {
    long iV;

    *iAbout = -1;
    *iExact = -1;

    iV = -1;

    while (++iV < iVS) {
        if (*iAbout == -1 || VS[*iAbout].Y1 < VS[iV].Y1) {
            if (VS[iV].Y1 - 3 > iY && VS[iV].Y2 - 9 < iY) {
                if (VS[iV].X1 - 3 < iX && VS[iV].X1 + 3 > iX) {
                    *iAbout = iV;

                    if (VS[iV].X1 == iX) {
                        *iExact = iV;
                    }
                }
            }
        }
    }
}

void FindLadder(long iX, long iY, long* iAbout, long* iExact) {
    long iL;
    long iDiff;
    long iBestDif;

    *iAbout = -1;
    *iExact = -1;

    iBestDif = 1000;
    iL = -1;

    while (++iL < iLS) {
        if (*iAbout == -1 || LS[*iAbout].Y1 < LS[iL].Y1) {
            if (LS[iL].Y1 - 3 > iY && LS[iL].Y2 - 9 < iY) {
                iDiff = LS[iL].X1 - iX;

                if (iDiff < 0) {
                    iDiff *= -1;
                }

                if (iDiff < 8 && iDiff <= iBestDif) {
                    iBestDif = iDiff;
                    *iAbout = iL;

                    if (iDiff == 0) {
                        *iExact = iL;
                    }
                }
            }
        }
    }
}

long PlayerFloor() {
    long iFloor;
    iFloor = 0;

    if ((iPlayerST & JS_JUMPING) && (iPlayerSC < 12)) {
        iFloor = 4;
    }

    return iFloor;
}

long PlayerHeight() {
    long iHeight;
    iHeight = 14;

    if ((iPlayerST & JS_ROLL)) {
        iHeight = 7;
    }

    if ((iPlayerST & JS_PUNCH)) {
        iHeight = 9;
    }

    if ((iPlayerST & JS_DYING)) {
        iHeight = 7;
    }

    return iHeight;
}

void GetNextPlatform(long iX, long iY, long iHeight, long iWide, float* iSupport, long* iPlatform) {
    long iP;
    float iH;
    long iLen;
    long iEX;
    long iExtra;
    int bGood;

    *iPlatform = -1;
    *iSupport = -1;
    iEvent3 = 0;

    iP = -1;
    iExtra = 0;

    while (++iP < iPS) {
        if (PS[iP].X1 <= iX + iWide && PS[iP].X2 >= iX - iWide) {
            iEX = iX;

            if (iEX < PS[iP].X1) {
                iEX = PS[iP].X1;
            }

            if (iEX > PS[iP].X2) {
                iEX = PS[iP].X2;
            }

            iLen = PS[iP].X2 - PS[iP].X1;
            iH = static_cast<float>(PS[iP].Y1) * abs(PS[iP].X2 - iEX) + static_cast<float>(PS[iP].Y2) * abs(PS[iP].X1 - iEX);
            iH /= iLen;

            bGood = 0;

            if (PS[iP].Extra == 3) {
                if (iH < iY + 1.5 && iH >= iY) {
                    bGood = 1;
                }

                if (iPlayerST == JS_ROLL && iPlayerSC < 6) {
                    bGood = 0;
                }
            } else {
                if (iH < iY + iHeight) {
                    bGood = 1;
                }
            }

            if (bGood && (iH > *iSupport || (iH == *iSupport && (iExtra == 1 || iExtra == 2)))) {
                *iSupport = iH;
                *iPlatform = iP;
                iExtra = PS[iP].Extra;
            }
        }
    }
}

void GrabDonuts() {
    int iLoop;
    int iCheck;
    int iWon;
    int iGot;

    iLoop = -1;
    iGot = 0;

    while (++iLoop < iDS) {
        if (DS[iLoop].Visible && PlayerCollide(DS[iLoop].X1 - 3, DS[iLoop].Y1 - 4, DS[iLoop].X1 + 3, DS[iLoop].Y1 + 2)) {
            DS[iLoop].Visible = 0;
            SetObjectData(DS[iLoop].MeshNumber, DS[iLoop].Texture, 0);
            iGot = 1;

            iEvent1 = DS[iLoop].Num;
            RunScript(&SCLevel, iDonutScript);
        }
    }

    if (iGot) {
        iCheck = -1;
        iWon = 1;

        while (++iCheck < iDS) {
            if (DS[iCheck].Visible) {
                iWon = 0;
            }
        }

        if (iWon) {
            if (GameMusicOn) {
                StopMusic1();
            }

            iPlayerSC = 0;
            iPlayerST = JS_DONE;
        } else if (GameSoundOn) {
            PlaySound(1);
        }
    }
}

void GetInput() {
    iTKeyLeft = iKeyLeft || iTappedLeft; iTappedLeft = 0;
    iTKeyRight = iKeyRight || iTappedRight;
    iTappedRight = 0;
    iTKeyUp = iKeyUp || iTappedUp;
    iTappedUp = 0;
    iTKeyDown = iKeyDown || iTappedDown;
    iTappedDown = 0;
    iTKeyJump = iKeyJump || iTappedJump;
    iTappedJump = 0;
    iTKeyAttack = iKeyAttack || iTappedAttack;
    iTappedAttack = 0;

    for(int i = GLFW_JOYSTICK_1; i <= GLFW_JOYSTICK_LAST; ++i) {
        if(glfwJoystickPresent(i) == GLFW_TRUE) {
            int axis_count;
            const float* axis_values = glfwGetJoystickAxes(i, &axis_count);

            if(axis_count > 0) {
                if(axis_values[0] <= -0.5f) {
                    iTKeyLeft = 1;
                }

                if(axis_values[0] >= 0.5f) {
                    iTKeyRight = 1;
                }
            }

            if(axis_count > 1) {
                if(axis_values[1] <= -0.5f) {
                    iTKeyUp = 1;
                }

                if(axis_values[1] >= 0.5f) {
                    iTKeyDown = 1;
                }
            }

            int button_count;
            const unsigned char* button_values = glfwGetJoystickButtons(GLFW_JOYSTICK_1, &button_count);

            // Face buttons - PS4 values
            if(button_count > 1 && button_values[1] == GLFW_PRESS) {
                iTKeyJump = 1;
            }

            if(button_count > 0 && button_values[0] == GLFW_PRESS) {
                iTKeyAttack = 1;
            }

            // D-Pad buttons - PS4 values
            // TODO: Need to map per controller type?
            if(button_count > 14 && button_values[14] == GLFW_PRESS) {
                iTKeyUp = 1;
            }

            if(button_count > 15 && button_values[15] == GLFW_PRESS) {
                iTKeyRight = 1;
            }

            if(button_count > 16 && button_values[16] == GLFW_PRESS) {
                iTKeyDown = 1;
            }

            if(button_count > 17 && button_values[17] == GLFW_PRESS) {
                iTKeyLeft = 1;
            }
        }
    }

    ++GameTimeInactive;

    if(iTKeyLeft + iTKeyRight + iTKeyUp + iTKeyDown + iTKeyJump) {
        GameTimeInactive = 0;
    }

    iTKeyAttack = 0;
}

void AdjustPlayerZ(int iTargetZ, int iTime) {
    if (iTime < abs(iTargetZ - static_cast<int>(iPlayerZ))) {
        if (iTargetZ < iPlayerZ) {
            --iPlayerZ;
        }

        if (iTargetZ > iPlayerZ) {
            ++iPlayerZ;
        }
    }
}

void ResetPlayer(int iNewLevel) {
    long iResetScript;

    iResetScript = FindScript(&SCLevel, "reset");
    RunScript(&SCLevel, iResetScript);

    int iObj;
    iObj = -1;

    while (++iObj < MAX_SCRIPTOBJECTS) {
        if (oObject[iObj].Active) {
            iResetScript = FindScript(&oObject[iObj], "resetpos");
            RunScript(&oObject[iObj], iResetScript);
        }
    }
}

void AnimateDying() {
    float iSupport;
    long iPlatform;
    int bGrounded;
    char sTemp[300];

    iEvent2 = -1;

    if (iPlayerAS == 0) {
        iPlayerM = JM_JUMPUP;

        ++iPlayerAX;

        if (iPlayerAX < 5 || iPlayerAX == 6) {
            ++iPlayerY;
        }

        if (iPlayerAX > 10 || iPlayerAX == 8) {
            --iPlayerY;
        }

        if (iPlayerAX > 15) {
            iPlayerAS = 1;
        }

        ++iPlayerAF;

        if (iPlayerSC < 10) {
            ++iPlayerAF;
        }

        if (iPlayerSC < 5) {
            ++iPlayerAF;
        }

        if (iPlayerSC < 0) {
            ++iPlayerAF;
            iPlayerM = JM_DEAD;
        }

        iPlayerRX = iPlayerAF / -10.0f;

        if (iPlayerAF & 1) {
            iPlayerX += iPlayerMX;
        }
    }

    if (iPlayerAS == 1) {
        iPlayerM = JM_JUMPUP;
        ++iPlayerAF;
        iPlayerY -= 2;
        iPlayerRX = iPlayerAF / -10.0f;

        GetNextPlatform(static_cast<long>(iPlayerX), static_cast<long>(iPlayerY), 8, 2, &iSupport, &iPlatform);
        iSupport -= PlayerFloor();
        bGrounded = (iPlayerY + 4 <= iSupport);
        AdjustPlayerZ(PS[iPlatform].Z1 - 2, static_cast<int>(iPlayerY - iSupport));

        if (bGrounded && iPlayerY > -5 && iSupport < iPlayerSC) {
            iPlayerMX = 0;
            int iRand;
            iRand = rand();

            if ((iRand & 3) == 1 && iPlayerY > 30 && iPlayerX > 30) {
                iPlayerMX = -1;
            }

            if ((iRand & 3) == 2 && iPlayerY > 30 && iPlayerX < 130) {
                iPlayerMX = 1;
            }

            iPlayerSC = static_cast<long>(iSupport) - 3;
            iPlayerAS = 0;
            iPlayerAX = 0;

            if (GameSoundOn) {
                PlaySound(2);
            }

            GetNextPlatform(static_cast<long>(iPlayerX), static_cast<long>(iPlayerY) - 8, 8, 2, &iSupport, &iPlatform);

            if (iPlatform == -1) {
                iPlayerAS = 2;
                iPlayerAX = 0;
                iPlayerAF = 0;
            }
        }

        if (iPlayerY < -2 && iPlayerAS == 1) {
            iPlayerAS = 2;
            iPlayerAF = 0;
        }
    }

    if (iPlayerAS == 2) {
        iPlayerM = JM_DEAD;

        ++iPlayerAX;

        if (iPlayerAX < 10 || iPlayerAX == 12 || iPlayerAX == 14) {
            ++iPlayerY;
        }

        if (iPlayerAX > 20 || iPlayerAX == 18 || iPlayerAX == 16) {
            --iPlayerY;
        }

        if (iPlayerAX == 10 || iPlayerAX == 12 || iPlayerAX == 17 || iPlayerAX == 20) {
            --iPlayerZ;
        }

        if (iPlayerAX == 25) {
            if (GameMusicOn) {
                NewTrack2(msDeathMusic);
            }
        }

        iPlayerAF += 4;
        iPlayerRX = iPlayerAF / -10.0f;

        if (iPlayerAX > 30) {
            iPlayerAS = 10;
            iPlayerAF = 0;
            iPlayerRX = 0;
            iPlayerAS = 10;
        }
    }

    if (iPlayerAS == 10) {
        IdentityMatrix(iFindMesh[JM_STARS]);
        RotateMatrixY(iFindMesh[JM_STARS], iPlayerAF * 180.0f / 50.0f);
        TranslateMatrix(iFindMesh[JM_STARS], iPlayerX, iPlayerY + 12, iPlayerZ + 1);
        SetObjectData(iFindMesh[JM_STARS], 0, 1);

        ++iPlayerAF;
        iPlayerRX = 0.1f;
        iPlayerM = JM_DEAD;

        if (iPlayerAF == 85) {
            SetObjectData(iFindMesh[JM_STARS], 0, 0);
            GameLivesRemaining = GameLivesRemaining - 1;

            if (GameLivesRemaining == 0) {
                iPlayerST = JS_NORMAL;
                strcpy_s(GameTitle, "");
                sprintf_s(sTemp, "%s\\Data\\GameOver.DAT", GamePath);
                PrepLevel(sTemp);
            } else {
                ResetPlayer(0);

                if (GameMusicOn && miIntroLength != 5550) {
                    NewTrack1(msBackMusic, miIntroLength, miIntroLength);
                }
            }
        }
    }
}

void ProgressGame() {
    int iObject;
    int iTemp;

    if (!(iPlayerST & JS_DONE)) {
        if (iPlayerFreeze) {
            --iPlayerFreeze;
        }

        if (iPlayerNoRoll) {
            --iPlayerNoRoll;
        }

        if (!(iPlayerST & JS_DYING) && !iPlayerFreeze) {
            ++iPlayerAF;
            iPlayerRX = 0;
            iPlayerM = JM_STAND;
            MoveJumpman();

            if (iPlayerM == JM_STAND && iPlayerVisible && GameTimeInactive > 400) {
                iTemp = (GameTimeInactive % 400) / 6;
                iTemp = iTemp > 10 ? 2 : iTemp & 1;
                iPlayerM = JM_BORED1 + iTemp;
            }
            GrabDonuts();
        }

        if ((iPlayerST & JS_DYING) && !iPlayerFreeze) {
            AnimateDying();
            GrabDonuts();
        }

        SetGamePerspective();

        RunScript(&SCLevel, iMainScript);

        for (iObject = 0; iObject < MAX_SCRIPTOBJECTS; ++iObject) {
            if (oObject[iObject].Active == 1) {
                RunScript(&oObject[iObject], 1);
            }
        }

        for (iObject = 0; iObject < MAX_SCRIPTOBJECTS; ++iObject) {
            if (oObject[iObject].Active == 2) {
                RunScript(&oObject[iObject], 1);
                oObject[iObject].Active = 1;
            }
        }
    } else {
        ++iPlayerSC;

        if (iPlayerSC == 30) {
            if (GameMusicOn) {
                NewTrack2(msWinMusic);
            }
        }

        if (iPlayerSC == 300) {
            LoadNextLevel();
        }
    }
}

void SetGamePerspective() {
    static float iCamX, iCamY;
    static float iPX, iPY;
    float iTX, iTY;

    if (iPlayerX > -50) {
        iPX = iPlayerX;
    }
    iPY = iPlayerY;

    iTX = iPX / 2 + miLevelExtentX / 4;
    iTY = iPY;

    if (iTX < 35) {
        iTX = 35;
    }

    if (iTX > miLevelExtentX - 45) {
        iTX = static_cast<float>(miLevelExtentX - 45);
    }

    iCamX = (iCamX + iTX) / 2;
    iCamY = (iCamY + iTY) / 2;

    if (iCamX < iTX - 10 || iCamX > iTX + 10) {
        iCamX = iTX;
    }

    if (iCamY < iTY - 10 || iCamY > iTY + 10) {
        iCamY = iTY;
    }

// PerspectiveNormal
    if (miPerspective == 0) {
        SetPerspective(iCamX, iCamY + 40.0f, -115.0f, iCamX, iCamY, 0.0f);
    }

// PerspectiveCloseUp
    if (miPerspective == 1) {
        SetPerspective(iPlayerX, iCamY + 35.0f, -95.0f, iPlayerX, iCamY + 7, 0.0f);
    }

// Far
    if (miPerspective == 2) {
        SetPerspective(80, iCamY + 50, -195.0f, 80, iCamY, 0);
    }

//  SetPerspective(0, 0.0f, -185.0f, 0, 0, 0.0f);
    if (miPerspective == 3) {
        SetPerspective(iPlayerX, iCamY / 2 + 60.0f, -110, iPlayerX, iCamY / 2 + 32.0f, 0);
    }

// SpaceLevel
    if (miPerspective == 4) {
        SetPerspective(iPlayerX, iCamY / 2 + 60.0f, -110, iPlayerX, iCamY / 2 + 32.0f, 0);
    }

// Fixed (for ending)
    if (miPerspective == 5) {
        SetPerspective(70, 110, -60, 100, 90, 0);
    }

// Above
//  SetPerspective(80, 150, 0.0f, 80, 80, 30);
// STRAIGHT
//  SetPerspective(iPlayerX, iPlayerY, -75.0f, iPlayerX, iPlayerY, 0.0f);
// QUITE ABOVE
//  SetPerspective(iPlayerX, iPlayerY + 60, -95.0f, iPlayerX, iPlayerY, 0.0f);
}

void DrawGame() {
    IdentityMatrix(iFindMesh[iPlayerM]);
    RotateMatrixX(iFindMesh[iPlayerM], iPlayerRX * 180.0f / 3.14f);
    TranslateMatrix(iFindMesh[iPlayerM], iPlayerX, iPlayerY + 6, iPlayerZ + 1);

    if (iPlayerVisible) {
        SetObjectData(iFindMesh[iPlayerM], 0, 1);
    }

    Render();

    SetObjectData(iFindMesh[iPlayerM], 0, 0);
}

// ------------------- OTHER STUFF -------------------------------

void TextLine(char* sText, int iTextLen, char* sOut, int iOutLen, int iLine) {
    int iLoop;
    int iCR;
    int iChars;

    iChars = 0;
    iCR = 0;
    iLoop = -1;
    sOut[iChars] = 0;

    while (++iLoop < iTextLen) {
        if (iCR == iLine && sText[iLoop] != 13 && iChars < iOutLen - 1) {
            sOut[iChars] = sText[iLoop];
            ++iChars;
            sOut[iChars] = 0;
        }

        if (sText[iLoop] == 13) {
            ++iCR;
            ++iLoop;
        }

        if (iCR > iLine) {
            return;
        }
    }
}

void GetLevelName(char* sLevel, size_t sLevelSize, int iLevel) {
    int iLen;
    char sTemp[20];
    char* sData;

    iLen = FileToString(GameFile, reinterpret_cast<unsigned char**>(&sData));
    TextLine(sData, iLen, sTemp, 20, iLevel * 2 - 1);
    TextLine(sData, iLen, GameTitle, 49, iLevel * 2);
    sprintf_s(sLevel, sLevelSize, "%s\\Data\\%s.DAT", GamePath, sTemp);
    free(sData);
}

void GetFileLine(char* sOut, size_t sOutSize, char* sFile, int iLine) {
    int iLen;
    char sTemp[20];
    char* sData;

    iLen = FileToString(sFile, reinterpret_cast<unsigned char**>(&sData));
    TextLine(sData, iLen, sTemp, 20, iLine);
    sprintf_s(sOut, sOutSize, "%s", sTemp);
    free(sData);
}

void PrepLevel(char* sLevel) {
    Clear3dData();
    Begin3dLoad();

    SetFog(0, 0, 0, 0, 0);

    iEvent1 = 0;

    LoadMeshes();
    LoadLevel(sLevel);

    EndAndCommit3dLoad();

    BuildNavigation();
    ResetPlayer(1);
    GameTimeInactive = 0;

    ProgressGame();
    ProgressGame();
    ProgressGame();
    ProgressGame();
    ProgressGame();

    char sFileName[300];
    sprintf_s(sFileName, "%s\\Data\\Title.BIN", GamePath);

    LoadScript(sFileName, &TitleScript);
    ResetContext(&SCTitle);
    SCTitle.Script = &TitleScript;

    iScrollTitle = 1;
    iLoadedLevel = iLevel;

    Render();

    if (GameMusicOn && miIntroLength != 5550) {
        NewTrack1(msBackMusic, 0, miIntroLength);
    }
}

void LoadNextLevel() {
    char sLevel[200];

    if (GameDebugMode) {
        GameLivesRemaining = 5;
        PrepLevel(GameDebugLevel);
    } else {
        ++iLevel;
        GetLevelName(sLevel, sizeof(sLevel), iLevel);
        PrepLevel(sLevel);
    }
}

void LoadMenu() {
    if (GameMenuDrawn == GameMenu) {
        return;
    }
    char sFileName[300];

    Clear3dData();
    Begin3dLoad();

    SetFog(0, 0, 0, 0, 0);

    if (GameMenu == GM_MAIN) {
        sprintf_s(sFileName, "%s\\Data\\MainMenu.DAT", GamePath);
        LoadLevel(sFileName);

        if (iEvent1 == 10) {
            if (GameMusicOn) {
                NewTrack1(msBackMusic, 3000, -1);
            }
        }

        if (iEvent1 == 100) {
            if (GameMusicOn) {
                NewTrack1(msDeathMusic, 0, -1);
            }
        }
    }

    if (GameMenu == GM_OPTIONS) {
        sprintf_s(sFileName, "%s\\Data\\Options.DAT", GamePath);
        LoadLevel(sFileName);

        if (iEvent1 == 9) {
            if (GameMusicOn) {
                NewTrack1(msBackMusic, 0, miIntroLength);
            }
        }
    }

    if (GameMenu == GM_SELECTGAME) {
        sprintf_s(sFileName, "%s\\Data\\SelectGame.DAT", GamePath);
        LoadLevel(sFileName);

        if (iEvent1 == 9) {
            if (GameMusicOn) {
                NewTrack1(msBackMusic, 0, miIntroLength);
            }
        }
    }

    GameMenuDrawn = GameMenu;

    EndAndCommit3dLoad();
}

void InteractMenu() {
    long iObject;
    RunScript(&SCLevel, iMainScript);

    for (iObject = 0; iObject < MAX_SCRIPTOBJECTS; ++iObject) {
        if (oObject[iObject].Active == 1) {
            RunScript(&oObject[iObject], 1);
        }
    }

    for (iObject = 0; iObject < MAX_SCRIPTOBJECTS; ++iObject) {
        if (oObject[iObject].Active == 2) {
            RunScript(&oObject[iObject], 1);
            oObject[iObject].Active = 1;
        }
    }

    SetPerspective(80.0f, 80.0f, -100.0f, 80.0f, 80.0f, 0.0f);
    Render();
}

long LoadSettings() {
    char sTemp[30];
    int iKey;
    char sFileName[300];

    sprintf_s(sFileName, "%s\\Data\\Settings.DAT", GamePath);

    char* sData;
    long iLen;
    iLen = FileToString(sFileName, reinterpret_cast<unsigned char**>(&sData));

    if (!iLen) {
        return 0;
    }

    iKey = -1;

    while (++iKey < 6) {
        GetFileLine(sTemp, sizeof(sTemp), sFileName, iKey);
        GameKeys[iKey] = atoi(sTemp);
    }

    GetFileLine(sTemp, sizeof(sTemp), sFileName, 6);
    GameSoundOn = atoi(sTemp);

    GetFileLine(sTemp, sizeof(sTemp), sFileName, 7);
    GameMusicOn = atoi(sTemp);

    return 1;
}

static void error_callback(int error, const char* description) {
    fprintf(stderr, "Error: %s\n", description);
}

static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    switch (action) {
        case GLFW_PRESS: {
            switch (key) {
                case GLFW_KEY_GRAVE_ACCENT: {
                    iShowFPS = 1;
                    break;
                }
                case GLFW_KEY_UP: {
                    iTappedUp = iKeyUp = 1;
                    break;
                }
                case GLFW_KEY_DOWN: {
                    iTappedDown = iKeyDown = 1;
                    break;
                }
                case GLFW_KEY_LEFT: {
                    iTappedLeft = iKeyLeft = 1;
                    break;
                }
                case GLFW_KEY_RIGHT: {
                    iTappedRight = iKeyRight = 1;
                    break;
                }
                case GLFW_KEY_SPACE: {
                    iTappedJump = iKeyJump = 1;
                    iKeySelect = 1;
                    break;
                }
                case GLFW_KEY_ENTER: {
                    iKeySelect = 1;
                    break;
                }
                case GLFW_KEY_Q: {
                    iKeySpecial = 1;
                    break;
                }
                case GLFW_KEY_ESCAPE: {
                    GameStatus = GS_EXITING;
                    glfwSetWindowShouldClose(window, GLFW_TRUE);
                    break;
                }
            }

            // Modifier keys
            if (mods & GLFW_MOD_CONTROL) {
                iTappedJump = iKeyJump = 1;
                iKeySelect = 1;
            }

            if (mods & GLFW_MOD_ALT) {
                iTappedAttack = iKeyAttack = 1;
            }

            // Bound keys
            if (key == GameKeys[0]) {
                iTappedUp = iKeyUp = 1;
            }

            if (key == GameKeys[1]) {
                iTappedDown = iKeyDown = 1;
            }

            if (key == GameKeys[2]) {
                iTappedLeft = iKeyLeft = 1;
            }

            if (key == GameKeys[3]) {
                iTappedRight = iKeyRight = 1;
            }

            if (key == GameKeys[4]) {
                iTappedJump = iKeyJump = 1;
                iKeySelect = 1;
            }

            if (key == GameKeys[5]) {
                iTappedAttack = iKeyAttack = 1;
            }

            iLastKey = key;
            break;
        }
        case GLFW_RELEASE: {
            switch (key) {
                case GLFW_KEY_GRAVE_ACCENT: {
                    iShowFPS = 0;
                    break;
                }
                case GLFW_KEY_UP: {
                    iKeyUp = 0;
                    break;
                }
                case GLFW_KEY_DOWN: {
                    iKeyDown = 0;
                    break;
                }
                case GLFW_KEY_LEFT: {
                    iKeyLeft = 0;
                    break;
                }
                case GLFW_KEY_RIGHT: {
                    iKeyRight = 0;
                    break;
                }
                case GLFW_KEY_SPACE: {
                    iKeyJump = 0;
                    iKeySelect = 0;
                    break;
                }
                case GLFW_KEY_ENTER: {
                    iKeySelect = 0;
                    break;
                }
                case GLFW_KEY_Q: {
                    iKeySpecial = 0;
                    break;
                }
            }

            // Modifier keys
            if (!(mods & GLFW_MOD_CONTROL)) {
                iKeyJump = 0;
                iKeySelect = 0;
            }

            if (!(mods & GLFW_MOD_ALT)) {
                iKeyAttack = 0;
            }

            // Bound keys
            if (key == GameKeys[0]) {
                iKeyUp = 0;
            }

            if (key == GameKeys[1]) {
                iKeyDown = 0;
            }

            if (key == GameKeys[2]) {
                iKeyLeft = 0;
            }

            if (key == GameKeys[3]) {
                iKeyRight = 0;
            }

            if (key == GameKeys[4]) {
                iKeyJump = 0;
                iKeySelect = 0;
            }

            if (key == GameKeys[5]) {
                iKeyAttack = 0;
            }

            iLastKey = key;
            break;
        }
    }
}

void window_focus_callback(GLFWwindow* window, int is_focused) {
    if(is_focused) {
        GameFrozen = 0;
        Reset3d();
    } else {
        GameFrozen = 1;
    }
}

void window_size_callback(GLFWwindow* window, int width, int height) {
    ResizeViewport(width, height);
}

int main(int arguments_count, char* arguments[]) {
    miDEBUG = 1;

    glfwSetErrorCallback(error_callback);

    if (!glfwInit()) {
        exit(EXIT_FAILURE);
    }

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    GLFWmonitor* monitor = NULL;
    int target_width = FULLSCREEN_RESX;
    int target_height = FULLSCREEN_RESY;

    if (FULL_SCREEN) {
        monitor = glfwGetPrimaryMonitor();

        const GLFWvidmode* mode = glfwGetVideoMode(monitor);
        glfwWindowHint(GLFW_RED_BITS, mode->redBits);
        glfwWindowHint(GLFW_GREEN_BITS, mode->greenBits);
        glfwWindowHint(GLFW_BLUE_BITS, mode->blueBits);
        glfwWindowHint(GLFW_REFRESH_RATE, mode->refreshRate);

        target_width = mode->width;
        target_height = mode->height;
    }

    GLFWwindow* main_window = glfwCreateWindow(target_width, target_height, "Jumpman Zero", monitor, NULL);

    if (!main_window) {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }

    glfwSetWindowFocusCallback(main_window, window_focus_callback);
    glfwSetWindowSizeCallback(main_window, window_size_callback);
    glfwSetKeyCallback(main_window, key_callback);
    glfwMakeContextCurrent(main_window);
    glfwSwapInterval(1);

    gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);

    if (FULL_SCREEN) {
        glfwSetInputMode(main_window, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);
    } else {
        glfwSetWindowSizeLimits(main_window, 320, 240, GLFW_DONT_CARE, GLFW_DONT_CARE);
    }

    ResizeViewport(target_width, target_height);

    GetCurrentDirectory(200, GamePath);

    GameFrozen = 0;

    if (!LoadSettings()) {
        exit(EXIT_FAILURE);
    }

    if (!Init3D()) {
        exit(EXIT_FAILURE);
    }

    if(InitSoundBuffer()) {
        if(!InitMusic()) {
            GameMusicOn = 0;
        }

        if(!InitSound()) {
            GameSoundOn = 0;
        }
    } else {
        GameMusicOn = 0;
        GameSoundOn = 0;
    }

    int bDone = 0;

    HANDLE g_hDMusicMessageEvent = NULL;

    if (arguments_count > 1 && strlen(arguments[1])) {
        sprintf_s(GameDebugLevel, "%s\\Data\\%s.DAT", GamePath, arguments[1]);
        GameDebugMode = 1;
        LoadNextLevel();
        iLevel = 0;
        GameStatus = GS_INLEVEL;
    } else {
        iEvent1 = 10;
        GameStatus = GS_MENU;
        GameMenuDrawn = GM_NONE;
        GameMenu = GM_MAIN;
        GameDebugMode = 0;
    }

    long iPerfCount;
    unsigned long iPerfTime;

    iPerfTime = 0;
    iPerfCount = 0;

    while (!glfwWindowShouldClose(main_window)) {
        LARGE_INTEGER tTime;
        QueryPerformanceCounter(&tTime);

        if (tTime.LowPart - iTime.LowPart > iFrameTime || tTime.LowPart < iTime.LowPart) {
            ++iPerfCount;

            if ((static_cast<unsigned long>(tTime.LowPart) - iPerfTime) > (iFrameTime * 40) || static_cast<unsigned long>(tTime.LowPart) < iPerfTime) {
                iPerfTime = static_cast<long>(tTime.LowPart);
                GamePerformance = iPerfCount;

                if (GamePerformance > 99) {
                    GamePerformance = 99;
                }

                iPerfCount = 0;
            }


            iTime = tTime;

            GetInput();

            if (GameStatus == GS_MENU) {
                LoadMenu();
                InteractMenu();

                if (GameStatus == GS_INLEVEL) {
                    iLevel = 0;
                    LoadNextLevel();
                }
            }

            if (GameStatus == GS_INLEVEL) {
                if (iScrollTitle > 0) {
                    if (iEvent1 == -100) {
                        iScrollTitle = 1000;
                    }
                    ++iScrollTitle;
                    iEvent1 = iScrollTitle;
                    RunScript(&SCTitle, 1);

                    if (iScrollTitle > 600) {
                        iScrollTitle = 0;
                    }
                } else {
                    if (!GameFrozen) {
                        ProgressGame();
                    }

                    RunScript(&SCTitle, 1);
                }

                if (!GameFrozen) {
                    DrawGame();
                }
            }

            glfwSwapBuffers(main_window);
        }

        glfwPollEvents();
    }

    // TODO: Can we just let these drop?
    CleanResources();
    CleanUpMusic();
    CleanUpSounds();
    CleanupSoundBuffer();
    DoCleanUp();

    glfwDestroyWindow(main_window);
    glfwTerminate();
    exit(EXIT_SUCCESS);
}

long Init3D() {
    int iLoop;

    iPlayerST = 0;
    iPlayerSC = 0;

    iPlayerRX = 0;

    iLoop = -1;

    while (++iLoop < 100) {
        iFindMesh[iLoop] = 0;
    }

    iLoop = -1;

    while (++iLoop < 300) {
        iOtherMesh[iLoop] = 0;
    }

    iKeyUp = 0;
    iKeyDown = 0;
    iKeyRight = 0;
    iKeyLeft = 0;
    iKeyJump = 0;
    iKeyAttack = 0;
    iTappedLeft = 0;
    iTappedDown = 0;
    iTappedRight = 0;
    iTappedUp = 0;
    iTappedJump = 0;
    iTappedAttack = 0;

    LARGE_INTEGER LI;
    QueryPerformanceFrequency(&LI);
    iFrameTime = LI.LowPart / 40;

    QueryPerformanceCounter(&iTime);
    srand(static_cast<unsigned>(iTime.LowPart));

    if (!InitializeAll()) {
        return 0;
    }

    return 1;
}

long LoadMesh(char* sFileName) {
    unsigned char* cData;
    long* oData;
    char sFullFile[300];
    long iObjectNum;
    int iNums;

    sprintf_s(sFullFile, "%s\\Data\\%s", GamePath, sFileName);

    cData = NULL;
    iNums = FileToString(sFullFile, &cData);
    iNums = iNums / 4;

    oData = static_cast<long*>(malloc(iNums * sizeof(long)));

    long iNum;

    iNum = -1;

    while (++iNum < iNums) {
        oData[iNum] = StringToLong(&cData[iNum << 2]);
    }

    CreateObject(oData, iNum / 9, &iObjectNum);

    free(cData);
    free(oData);

    return iObjectNum;
}

void LoadMeshes() {
    iFindMesh[JM_STAND] = LoadMesh("Stand.MSH");
    iFindMesh[JM_LEFT1] = LoadMesh("Left1.MSH");
    iFindMesh[JM_LEFT2] = LoadMesh("Left2.MSH");
    iFindMesh[JM_RIGHT1] = LoadMesh("Right1.MSH");
    iFindMesh[JM_RIGHT2] = LoadMesh("Right2.MSH");

    iFindMesh[JM_JUMPUP] = LoadMesh("JumpUp.MSH");
    iFindMesh[JM_JUMPLEFT] = LoadMesh("JumpLeft.MSH");
    iFindMesh[JM_JUMPRIGHT] = LoadMesh("JumpRight.MSH");

    iFindMesh[JM_VINECLIMB1] = LoadMesh("RopeClimb1.MSH");
    iFindMesh[JM_VINECLIMB2] = LoadMesh("RopeClimb2.MSH");

    iFindMesh[JM_LADDERCLIMB1] = LoadMesh("LadderClimb1.MSH");
    iFindMesh[JM_LADDERCLIMB2] = LoadMesh("LadderClimb2.MSH");

    iFindMesh[JM_KICKLEFT] = LoadMesh("KickLeft.MSH");
    iFindMesh[JM_KICKRIGHT] = LoadMesh("KickRight.MSH");

    iFindMesh[JM_DIVERIGHT] = LoadMesh("DiveRight.MSH");
    iFindMesh[JM_ROLLRIGHT1] = LoadMesh("RollRight1.MSH");
    iFindMesh[JM_ROLLRIGHT2] = LoadMesh("RollRight2.MSH");
    iFindMesh[JM_ROLLRIGHT3] = LoadMesh("RollRight3.MSH");
    iFindMesh[JM_ROLLRIGHT4] = LoadMesh("RollRight4.MSH");

    iFindMesh[JM_DIVELEFT] = LoadMesh("DiveLeft.MSH");
    iFindMesh[JM_ROLLLEFT1] = LoadMesh("RollLEFT1.MSH");
    iFindMesh[JM_ROLLLEFT2] = LoadMesh("RollLEFT2.MSH");
    iFindMesh[JM_ROLLLEFT3] = LoadMesh("RollLEFT3.MSH");
    iFindMesh[JM_ROLLLEFT4] = LoadMesh("RollLEFT4.MSH");

    iFindMesh[JM_PUNCHLEFT] = LoadMesh("PunchLeft.MSH");
    iFindMesh[JM_PUNCHRIGHT] = LoadMesh("PunchRight.MSH");
    iFindMesh[JM_PUNCHLEFT2] = LoadMesh("PunchLeft2.MSH");
    iFindMesh[JM_PUNCHRIGHT2] = LoadMesh("PunchRight2.MSH");

    iFindMesh[JM_DYING] = LoadMesh("Dying.MSH");
    iFindMesh[JM_DEAD] = LoadMesh("Dead.MSH");
    iFindMesh[JM_STARS] = LoadMesh("Stars.MSH");

    iFindMesh[JM_SLIDER] = LoadMesh("SlideR.MSH");
    iFindMesh[JM_SLIDERB] = LoadMesh("SlideRB.MSH");
    iFindMesh[JM_SLIDEL] = LoadMesh("SlideL.MSH");
    iFindMesh[JM_SLIDELB] = LoadMesh("SlideLB.MSH");

    iFindMesh[JM_BORED1] = LoadMesh("BORED1.MSH");
    iFindMesh[JM_BORED2] = LoadMesh("BORED2.MSH");
    iFindMesh[JM_BORED3] = LoadMesh("BORED3.MSH");
    iFindMesh[JM_BORED4] = LoadMesh("BORED4.MSH");
    iFindMesh[JM_BORED5] = LoadMesh("BORED5.MSH");
}


























void MoveJumpmanPunch();
void MoveJumpmanSlide();
void MoveJumpmanFalling();
void MoveJumpmanRoll();
void MoveJumpmanJumping();
void MoveJumpmanNormal();

int iIgnoreLadders;

void DoDeathBounce() {
    if (GameMusicOn) {
        StopMusic1();
    }

    iPlayerST = JS_DYING;
    iPlayerAS = 1;
    iPlayerAX = 0;
    iPlayerMX = 0;
    iPlayerAF = iPlayerSC;
    iPlayerSC = 1000;

    int iRand;
    iRand = rand();

    if ((iRand & 7) == 1 && iPlayerX > 30) {
        iPlayerMX = -1;
    }

    if ((iRand & 7) == 2 && iPlayerX < 130) {
        iPlayerMX = 1;
    }
}

int CheckWalkOff(int iCenter) {
    if (iPlayerX < iCenter && iTKeyRight) {
        return 0;
    }

    if (iPlayerX > iCenter && iTKeyLeft) {
        return 0;
    }

    if (iTKeyDown && iPlayerY < iSitSupport - 2) {
        return 0;
    }

    if (iPlayerY <= iSitSupport && (iTKeyLeft != iTKeyRight)) {
        MoveJumpmanNormal();
        return 1;
    }

    return 0;
}

int CheckJumpStart(int iLeft, int iUp, int iRight) {
    if (!iTKeyJump) {
        return 0;
    }

    if (iLeft && iTKeyLeft && !iTKeyRight) {
        iPlayerDIR = JD_LEFT;
    } else if (iRight && iTKeyRight && !iTKeyLeft) {
        iPlayerDIR = JD_RIGHT;
    } else if (iUp) {
        iPlayerDIR = JD_UP;
    } else {
        return 0;
    }

    iPlayerACT = 0;
    iPlayerSC = 0;

    if (GameSoundOn) {
        PlaySound(0);
    }

    MoveJumpmanJumping();

    return 1;
}

void UpdateSituation() {
    FindVine(static_cast<long>(iPlayerX), static_cast<long>(iPlayerY), &iSitVinAp, &iSitVinEx);
    FindLadder(static_cast<long>(iPlayerX), static_cast<long>(iPlayerY), &iSitLadA, &iSitLadE);
    GetNextPlatform(static_cast<long>(iPlayerX), static_cast<long>(iPlayerY), PlayerHeight(), 2, &iSitSupport, &iSitPlatform);
    iSitSupport -= PlayerFloor();

    iEvent2 = -1;

    if (iSitSupport >= iPlayerY) {
        iEvent2 = iSitPlatform;
    }
}

void MoveJumpmanVine() {
    iPlayerST = JS_VINE;
    iPlayerACT = 0;

    if (iSitVinAp == -1) {
        iPlayerST = JS_NORMAL;
        return;
    }

    if (CheckJumpStart(1, 0, 1)) {
        return;
    }

    if (CheckWalkOff(VS[iSitVinAp].X1)) {
        return;
    }

    iPlayerM = (iPlayerAF & 2) ? JM_VINECLIMB1 : JM_VINECLIMB2;
    AdjustPlayerZ(VS[iSitVinAp].Z1 - 3, 0);

    if (VS[iSitVinAp].Y2 < iSitSupport - 2 || iPlayerY > iSitSupport - 1) {
        --iPlayerY;
    } else {
        MoveJumpmanNormal();
        return;
    }

    long iVinX;

    iVinX = VS[iSitVinAp].X1;

    if (iPlayerAF & 1) {
        if (iPlayerX + 1 > iVinX && iPlayerX - 1 < iVinX) {
            iPlayerX = static_cast<float>(iVinX);
        } else if (iPlayerX < iVinX) {
            ++iPlayerX;
        } else if (iPlayerX > iVinX) {
            --iPlayerX;
        }
    }
}

void MoveJumpmanLadder() {
    iPlayerST = JS_LADDER;
    iPlayerACT = 0;
    iIgnoreLadders = 1;

    if (iSitLadA == -1) {
        iPlayerST = JS_NORMAL;
        return;
    }

    if (iSitSupport >= iPlayerY || (LS[iSitLadA].X1 < iPlayerX + 2 && LS[iSitLadA].X1 > iPlayerX - 2)) {
        if (CheckJumpStart(1, 0, 1)) {
            return;
        }
    }

    if (CheckWalkOff(LS[iSitLadA].X1)) {
        return;
    }

    iPlayerM = JM_JUMPUP;
    AdjustPlayerZ(LS[iSitLadA].Z1 - 3, 0);

    if (iTKeyUp && LS[iSitLadA].Y1 - 5 > iPlayerY) {
        ++iPlayerY;
        iPlayerM = (iPlayerAF & 2) ? JM_LADDERCLIMB2 : JM_LADDERCLIMB1;
    } else if (iTKeyUp && !iTKeyDown) {
        iPlayerM = (iPlayerAF & 2) ? JM_LADDERCLIMB2 : JM_LADDERCLIMB1;
    }

    if (iTKeyDown && (LS[iSitLadA].Y2 < iSitSupport - 3 || iPlayerY > iSitSupport)) {
        --iPlayerY;
        iPlayerM = (iPlayerAF & 2) ? JM_LADDERCLIMB2 : JM_LADDERCLIMB1;

        if (LS[iSitLadA].Y2 >= iSitSupport - 3 && iPlayerY < iSitSupport) {
            iPlayerY = iSitSupport;
        }
    }

    long iLadderX;

    iLadderX = LS[iSitLadA].X1;

    if (iPlayerX < iLadderX + 1 && iPlayerX > iLadderX - 1) {
        iPlayerX = static_cast<float>(iLadderX);
    } else if (iPlayerX < iLadderX) {
        iPlayerX += 1;
    } else if (iPlayerX > iLadderX) {
        iPlayerX -= 1;
    }
}

void MoveJumpmanNormal() {
    iPlayerST = JS_NORMAL;
    iPlayerACT = 0;

    AdjustPlayerZ(PS[iSitPlatform].Z1 - 2, static_cast<int>(iPlayerY - iSitSupport));

    if (iSitVinAp != -1 && !iTKeyLeft && !iTKeyRight && (VS[iSitVinAp].Y2 < iSitSupport - 2 || iPlayerY > iSitSupport)) {
        MoveJumpmanVine();
        return;
    }

    if (iSitSupport > iPlayerY - 2 && (PS[iSitPlatform].Extra == 1 || PS[iSitPlatform].Extra == 2)) {
        MoveJumpmanSlide();
        return;
    }

    if (iSitLadA != -1 && !iIgnoreLadders && (iTKeyUp != iTKeyDown)) {
        if ((!iTKeyRight || iPlayerX < LS[iSitLadA].X1 + 1) && (!iTKeyLeft || iPlayerX > LS[iSitLadA].X1 - 1)) {
            if (iTKeyUp && LS[iSitLadA].Y1 - 5 > iPlayerY) {
                MoveJumpmanLadder();
                return;
            }

            if (iTKeyDown && (LS[iSitLadA].Y2 < iSitSupport - 3 || iSitSupport < iPlayerY - 1)) {
                MoveJumpmanLadder();
                return;
            }
        }
    }

    if (iPlayerY <= iSitSupport + 1) {
        if (CheckJumpStart(1, 1, 1)) {
            return;
        }
    }

    if (iTKeyLeft && !iTKeyRight) {
        iPlayerM = (iPlayerAF & 2) ? JM_LEFT1 : JM_LEFT2;
        --iPlayerX;
    }

    if (iTKeyRight && !iTKeyLeft) {
        iPlayerM = (iPlayerAF & 2) ? JM_RIGHT1 : JM_RIGHT2;
        ++iPlayerX;
    }

    int iClimbing;

    iClimbing = 0;

    if (iSitSupport < iPlayerY + 1 && iSitSupport > iPlayerY - 1) {
        iPlayerY = iSitSupport;
    } else if (iSitSupport < iPlayerY - 4) {
        iPlayerSC = 0;
        MoveJumpmanFalling();
        return;
    } else if (iSitSupport < iPlayerY - 1) {
        --iPlayerY;
    } else if (iSitSupport > iPlayerY + 3) {
        iPlayerM = (iPlayerAF & 2) ? JM_VINECLIMB1 : JM_VINECLIMB2;
        ++iPlayerY;
        iClimbing = 1;
    } else if (iSitSupport > iPlayerY + 1) {
        ++iPlayerY;
        iClimbing = 1;
    } else {
        iPlayerY = iSitSupport;
    }

    UpdateSituation();

    if (iSitSupport < iPlayerY - 5 && iClimbing) {
        iPlayerX = iPlayerOldX;
    }

    if (PS[iSitPlatform].Extra == 2) {
        if (iPlayerX > iPlayerOldX) {
            iPlayerX = iPlayerOldX;
        }

        if (iPlayerY > iPlayerOldY) {
            iPlayerY = iPlayerOldY;
        }
    }

    if (PS[iSitPlatform].Extra == 1) {
        if (iPlayerX < iPlayerOldX) {
            iPlayerX = iPlayerOldX;
        }

        if (iPlayerY > iPlayerOldY) {
            iPlayerY = iPlayerOldY;
        }
    }
}

void MoveJumpmanFalling() {
    iPlayerST = JS_FALLING;
    iPlayerACT = 0;

    --iPlayerY;
    ++iPlayerSC;
    iPlayerRX = iPlayerSC / -10.0f;
    iPlayerM = JM_JUMPUP;

    if (iPlayerSC > 10) {
        iPlayerY -= .5;
    }

    if (iPlayerSC > 20) {
        iPlayerY -= .5;
    }

    if (iPlayerY <= iSitSupport && PS[iSitPlatform].Extra != 3) {
        if (iPlayerSC < 10) {
            MoveJumpmanNormal();
            return;
        } else {
            iPlayerACT = 0;
            DoDeathBounce();
            return;
        }
    }
}

void MoveJumpmanJumping() {
    iPlayerST = JS_JUMPING;

    if (iPlayerACT != JA_KICK && iTKeyAttack && ((iPlayerDIR == JD_RIGHT) || (iPlayerDIR == JD_LEFT))) {
        iPlayerACT = JA_KICK;
    }

    if (iSitLadE != -1 && !iTKeyAttack && (iPlayerSC > 15 || !iTKeyJump || ((iPlayerDIR == JD_RIGHT) && iTKeyLeft) || ((iPlayerDIR == JD_LEFT) && iTKeyRight) )) {
        MoveJumpmanLadder();
        return;
    }

    if (iSitVinEx != -1 && !iTKeyAttack && (iPlayerSC > 10 || !iTKeyJump || ((iPlayerDIR == JD_RIGHT) && iTKeyLeft) || ((iPlayerDIR == JD_LEFT) && iTKeyRight) )) {
        MoveJumpmanVine();
        return;
    }

    if (iPlayerSC > 50) {
        if (iSitLadA != -1) {
            MoveJumpmanLadder();
            return;
        }

        if (iSitVinAp != -1) {
            MoveJumpmanVine();
            return;
        }

        MoveJumpmanNormal();
        return;
    }

    if (iPlayerY < iSitSupport && iPlayerSC > 6 && (!iTKeyJump || iPlayerSC > 12)) {
        MoveJumpmanNormal();
        return;
    }

    ++iPlayerSC;

    if (iPlayerSC == 1) {
        iPlayerY += 1;
    }

    if (iPlayerSC < 5 || iPlayerSC == 6 || iPlayerSC == 8 || iPlayerSC == 10 || iPlayerSC == 12) {
        iPlayerY += 1;
    }

    if (iPlayerSC > 26 || iPlayerSC == 25 || iPlayerSC == 23 || iPlayerSC == 20 || iPlayerSC == 17) {
        iPlayerY -= 1;
    }

    iPlayerM = JM_JUMPUP;

    if (iPlayerDIR == JD_LEFT) {
        --iPlayerX;
        iPlayerM = (iPlayerACT == JA_KICK) ? JM_KICKLEFT : JM_JUMPLEFT;
    }

    if (iPlayerDIR == JD_RIGHT) {
        ++iPlayerX;
        iPlayerM = (iPlayerACT == JA_KICK) ? JM_KICKRIGHT : JM_JUMPRIGHT;
    }

    if (iTKeyDown && !iPlayerNoRoll && (iPlayerDIR == JD_RIGHT || iPlayerDIR == JD_LEFT)) {
        iPlayerSC = 0;
        MoveJumpmanRoll();
    }
}

void MoveJumpmanSlide() {
    iPlayerST = JS_SLIDE;
    iPlayerACT = 0;

    long iExtra;
    long iOldPlayerM;

    iOldPlayerM = iPlayerM;

    iExtra = PS[iSitPlatform].Extra;

    if (!iExtra && iPlayerY <= iSitSupport) {
        MoveJumpmanNormal();
        return;
    }

    if (iPlayerY > iSitSupport + 3) {
        ++iPlayerSC;

        if (iPlayerSC > 30) {
            MoveJumpmanNormal();
            return;
        }
    } else {
        iPlayerSC = 0;
    }

    if (iPlayerY < iSitSupport + 1) {
        if (iExtra == 1) {
            if (CheckJumpStart(0, 0, 1)) {
                return;
            }
            ++iPlayerX;
            iPlayerDIR = JD_RIGHT;
        }

        if (iExtra == 2) {
            if (CheckJumpStart(1, 0, 0)) {
                return;
            }
            --iPlayerX;
            iPlayerDIR = JD_LEFT;
        }
    } else {
        if (iPlayerDIR == JD_RIGHT) {
            if (iPlayerSC < 6) {
                if (CheckJumpStart(0, 0, 1)) {
                    return;
                }
            }

            iPlayerX += static_cast<float>(30 - iPlayerSC) / 60.0f+.5f;
        }

        if (iPlayerDIR == JD_LEFT) {
            if (iPlayerSC < 6) {
                if (CheckJumpStart(1, 0, 0)) {
                    return;
                }
            }

            iPlayerX -= static_cast<float>(30 - iPlayerSC) / 60.0f+.5f;
        }
    }

    if (iPlayerDIR == JD_RIGHT) {
        iPlayerM = JM_SLIDER;

        if (((iPlayerAF & 7) == 1) || ((iPlayerAF & 7) == 2) || ((iPlayerAF & 7) == 4) || ((iPlayerAF & 7) == 5)) {
            iPlayerM = JM_SLIDERB;
        }
    } else {
        iPlayerM = JM_SLIDEL;

        if (((iPlayerAF & 7) == 1) || ((iPlayerAF & 7) == 2) || ((iPlayerAF & 7) == 4) || ((iPlayerAF & 7) == 5)) {
            iPlayerM = JM_SLIDELB;
        }
    }

    if (iPlayerY < iSitSupport + 2 && iPlayerY > iSitSupport - 2) {
        iPlayerY = iSitSupport;
    }

    if (iPlayerY < iSitSupport) {
        ++iPlayerY;
    }

    if (iPlayerY < iSitSupport) {
        ++iPlayerY;
    }

    if (iPlayerY > iSitSupport) {
        --iPlayerY;
    }

    if (iPlayerY > iSitSupport) {
        --iPlayerY;
    }
}

void MoveJumpmanRoll() {
    iPlayerST = JS_ROLL;
    iPlayerACT = 0;

    if (iPlayerSC < 7 || iPlayerY > iSitSupport + 1) {
        ++iPlayerSC;

        if (iPlayerSC > 50) {
            MoveJumpmanNormal();
            return;
        }
    } else {
        iPlayerSC = 7;
    }

    if (iPlayerY <= iSitSupport && (PS[iSitPlatform].Extra == 1 || PS[iSitPlatform].Extra == 2)) {
        MoveJumpmanSlide();
        return;
    }

    if (iPlayerY <= iSitSupport) {
        if (iPlayerDIR == JD_RIGHT && !iTKeyRight) {
            MoveJumpmanNormal();
            return;
        }

        if (iPlayerDIR == JD_LEFT && !iTKeyLeft) {
            MoveJumpmanNormal();
            return;
        }

        if (!iTKeyDown) {
            if (CheckJumpStart(1, 1, 1)) {
                return;
            }
        }
    }

    if ((!iTKeyJump) && (iPlayerY <= iSitSupport+.1) && iTKeyAttack) {
        iPlayerSC = 0;
        MoveJumpmanPunch();
        return;
    }

    if (iSitLadE != -1 && iSitSupport < iPlayerY && (iPlayerSC > 10)) {
        MoveJumpmanLadder();
        return;
    }

    if (iSitVinEx != -1 && iSitSupport < iPlayerY && (iPlayerSC > 10)) {
        MoveJumpmanVine();
        return;
    }

    AdjustPlayerZ(PS[iSitPlatform].Z1 - 2, static_cast<int>(iPlayerY - iSitSupport));

    float iVel;
    iVel = 1.3f;

    if (iPlayerSC > 8) {
        iVel = 1;
    }

    if (iPlayerSC > 25) {
        iVel = .7f;
    }

    if (iPlayerSC > 38) {
        iVel = .3f;
    }

    if (iPlayerDIR == JD_LEFT) {
        iPlayerX -= iVel;
        iPlayerM = JM_ROLLLEFT1 + ((iPlayerAF & 6) >> 1);

        if (iPlayerSC < 6) {
            iPlayerM = JM_DIVELEFT;
        }
    }

    if (iPlayerDIR == JD_RIGHT) {
        iPlayerX += iVel;
        iPlayerM = JM_ROLLRIGHT1 + ((iPlayerAF & 6) >> 1);

        if (iPlayerSC < 6) {
            iPlayerM = JM_DIVERIGHT;
        }
    }

    UpdateSituation();

    if (iSitSupport < iPlayerY + 1 && iSitSupport > iPlayerY - 1) {
        iPlayerY = iSitSupport;
    } else if (iSitSupport < iPlayerY) {
        --iPlayerY;
    } else if (iSitSupport > iPlayerY) {
        ++iPlayerY;
    }
}

void MoveJumpmanPunch() {
    iPlayerST = JS_PUNCH;
    iPlayerACT = JA_PUNCH;

    if (iPlayerSC > 20 || (iPlayerSC < 12 && iPlayerY < iSitSupport - 2) || (iPlayerSC > 11 && iPlayerY <= iSitSupport)) {
        MoveJumpmanNormal();
        return;
    }

    ++iPlayerSC;

    if (iPlayerSC < 3) {
        iPlayerM = (iPlayerDIR == JD_RIGHT) ? JM_PUNCHRIGHT : JM_PUNCHLEFT;
    } else {
        iPlayerM = (iPlayerDIR == JD_RIGHT) ? JM_PUNCHRIGHT2 : JM_PUNCHLEFT2;
    }

    if (iPlayerSC < 11 && iPlayerSC != 9) {
        ++iPlayerY;
    }

    if (iPlayerSC > 12 && iPlayerSC != 14) {
        --iPlayerY;
    }

    if (iPlayerSC < 4 || iPlayerSC == 5 || iPlayerSC == 7) {
        iPlayerX += (iPlayerDIR == JD_RIGHT) ? 1 : -1;
    }
}

void MoveJumpman() {
    iPlayerOldX = iPlayerX;
    iPlayerOldY = iPlayerY;

    iIgnoreLadders = 0;

    UpdateSituation();

    if (iPlayerST == JS_VINE) {
        MoveJumpmanVine();
    } else if (iPlayerST == JS_LADDER) {
        MoveJumpmanLadder();
    } else if (iPlayerST == JS_NORMAL) {
        MoveJumpmanNormal();
    } else if (iPlayerST == JS_FALLING) {
        MoveJumpmanFalling();
    } else if (iPlayerST == JS_JUMPING) {
        MoveJumpmanJumping();
    } else if (iPlayerST == JS_SLIDE) {
        MoveJumpmanSlide();
    } else if (iPlayerST == JS_ROLL) {
        MoveJumpmanRoll();
    } else if (iPlayerST == JS_PUNCH) {
        MoveJumpmanPunch();
    }

    if (iPlayerY < 0) {
        iPlayerACT = 0;
        DoDeathBounce();
        return;
    }

    long iCollide;
    long iRep;

    iRep = -1;

    while (++iRep < 2) {
        iCollide = CollideWall(static_cast<long>(iPlayerX) - 2, static_cast<long>(iPlayerY) + 11, static_cast<long>(iPlayerX) + 2, static_cast<long>(iPlayerY) + 9);

        if (iCollide == 1) {
            iPlayerY -= 1;

            if ((iPlayerST == JS_JUMPING) && iPlayerSC < 15) {
                iPlayerSC = 15;
            }
        }

        iCollide = CollideWall(static_cast<long>(iPlayerX) - 3, static_cast<long>(iPlayerY) + 9, static_cast<long>(iPlayerX) + 3, static_cast<long>(iPlayerY) + 3);

        if (iCollide == 3) {
            ++iPlayerX;

            if (iPlayerST == JS_JUMPING && iPlayerSC < 15) {
                iPlayerSC = 16;
            }

            if (iPlayerST != JS_JUMPING && iPlayerY > iSitSupport - 1 && iPlayerY >= iPlayerOldY) {
                --iPlayerY;
            }
        }

        if (iCollide == 4) {
            --iPlayerX;

            if (iPlayerST == JS_JUMPING && iPlayerSC < 15) {
                iPlayerSC = 16;
            }

            if (iPlayerST != JS_JUMPING && iPlayerY > iSitSupport - 1 && iPlayerY >= iPlayerOldY) {
                --iPlayerY;
            }
        }
    }

    UpdateSituation();
}
