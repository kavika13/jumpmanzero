#include "./jumpman.h"

#define FCBASECN 2
#define FCSTACKCN 3

#define FCMOVBCCN 10
#define FCMOVSCCN 11
#define FCMOVBSSC 12
#define FCMOVSCBC 13
#define FCMOVSCSC 14

#define FCMOVGCCN 20
#define FCMOVGSSC 21
#define FCMOVSCGC 22
#define FCMOVGCSC 23

#define FCADDSCCN 30

#define FCADDSCSC 40
#define FCMULSCSC 41
#define FCSUBSCSC 42
#define FCDIVSCSC 43
#define FCMOVSCGS 44
#define FCMOVSCBS 45

#define FCBANDSCSC 46

#define FCJUMPZ 50
#define FCJUMPNZ 51
#define FCJUMP 52

#define FCEQUSCSC 60
#define FCNEQSCSC 61
#define FCGTSCSC 62
#define FCGTESCSC 63
#define FCORSCSC 64
#define FCANDSCSC 65
#define FCCALL 70
#define FCRET 71

#define FCEXT 100

void RunLine(ScriptContext* SC, long iFunc, long rArg1, long rArg2);

void ResetContext(ScriptContext *SC) {
    int iLoop;

    for (iLoop = 0; iLoop < 500; ++iLoop) {
        SC->Globals[iLoop] = 0;
    }
}

int FindScript(ScriptContext* SC, char* sFunc) {
    int iFind;
    iFind = -1;

    while (++iFind < SC->Script->Subs) {
        if (strcmp(sFunc, SC->Script->SubName[iFind]) == 0) {
            return iFind;
        }
    }

    return -1;
}

void RunScript(ScriptContext* SC, long iSub) {
    if (iSub == -1) {
        return;
    }

    SC->Done = 0;
    SC->BP = 1;
    SC->SP = 1;
    SC->CallStack = 0;
    SC->IP = (SC->Script->SubStart[iSub]) / 3;

    long iFunc, iArg1, iArg2;

    while (!SC->Done) {
        iFunc = SC->Script->Code[SC->IP * 3 + 0];
        iArg1 = SC->Script->Code[SC->IP * 3 + 1];
        iArg2 = SC->Script->Code[SC->IP * 3 + 2];

        RunLine(SC, iFunc, iArg1, iArg2);

        ++SC->IP;
    }
}

void RunLine(ScriptContext* SC, long iFunc, long rArg1, long rArg2) {
    long iArg1, iArg2;
    iArg1 = rArg1 / 256;
    iArg2 = rArg2 / 256;

    if (iFunc == FCBASECN) {
        SC->BP += iArg1;
    } else if (iFunc == FCSTACKCN) {
        SC->SP += iArg1;
    } else if (iFunc == FCMOVBCCN) {
        SC->Stack[SC->BP + iArg1] = rArg2;
    } else if (iFunc == FCMOVSCCN) {
        SC->Stack[SC->SP + iArg1] = rArg2;
    } else if (iFunc == FCMOVBSSC) {
        SC->Stack[SC->BP + (SC->Stack[SC->SP + iArg1]) / 256] = SC->Stack[SC->SP + iArg2];
    } else if (iFunc == FCMOVSCBC) {
        SC->Stack[SC->SP + iArg1] = SC->Stack[SC->BP + iArg2];
    } else if (iFunc == FCMOVSCSC) {
        SC->Stack[SC->SP + iArg1] = SC->Stack[SC->SP + iArg2];
    } else if (iFunc == FCADDSCCN) {
        SC->Stack[SC->SP + iArg1] += rArg2;
    } else if (iFunc == FCADDSCSC) {
        SC->Stack[SC->SP + iArg1] += SC->Stack[SC->SP + iArg2];
    } else if (iFunc == FCSUBSCSC) {
        SC->Stack[SC->SP + iArg1] -= SC->Stack[SC->SP + iArg2];
    } else if (iFunc == FCMULSCSC) {
        SC->Stack[SC->SP + iArg1] = SC->Stack[SC->SP + iArg1] * SC->Stack[SC->SP + iArg2] / 256;
    } else if (iFunc == FCDIVSCSC) {
        SC->Stack[SC->SP + iArg1] = SC->Stack[SC->SP + iArg1] * 256 / SC->Stack[SC->SP + iArg2];
    } else if (iFunc == FCBANDSCSC) {
        SC->Stack[SC->SP + iArg1] &= SC->Stack[SC->SP + iArg2];
    } else if (iFunc == FCMOVSCGS) {
        SC->Stack[SC->SP + iArg1] = SC->Globals[SC->Stack[SC->SP + iArg2] / 256];
    } else if (iFunc == FCMOVSCBS) {
        SC->Stack[SC->SP + iArg1] = SC->Stack[SC->BP + SC->Stack[SC->SP + iArg2] / 256];
    } else if (iFunc == FCMOVGCCN) {
        SC->Globals[iArg1] = rArg2;
    } else if (iFunc == FCMOVGSSC) {
        SC->Globals[(SC->Stack[SC->SP + iArg1]) / 256] = SC->Stack[SC->SP + iArg2];
    } else if (iFunc == FCMOVSCGC) {
        SC->Stack[SC->SP + iArg1] = SC->Globals[iArg2];
    } else if (iFunc == FCMOVGCSC) {
        SC->Globals[iArg1] = SC->Stack[SC->SP + iArg2];
    } else if (iFunc == FCEQUSCSC) {
        SC->Stack[SC->SP + iArg1] = (SC->Stack[SC->SP + iArg1] == SC->Stack[SC->SP + iArg2]) ? 256 : 0;
    } else if (iFunc == FCNEQSCSC) {
        SC->Stack[SC->SP + iArg1] = (SC->Stack[SC->SP + iArg1] != SC->Stack[SC->SP + iArg2]) ? 256 : 0;
    } else if (iFunc == FCGTSCSC) {
        SC->Stack[SC->SP + iArg1] = (SC->Stack[SC->SP + iArg1] > SC->Stack[SC->SP + iArg2]) ? 256 : 0;
    } else if (iFunc == FCGTESCSC) {
        SC->Stack[SC->SP + iArg1] = (SC->Stack[SC->SP + iArg1] >= SC->Stack[SC->SP + iArg2]) ? 256 : 0;
    } else if (iFunc == FCORSCSC) {
        SC->Stack[SC->SP + iArg1] = (SC->Stack[SC->SP + iArg1] || SC->Stack[SC->SP + iArg2]) ? 256 : 0;
    } else if (iFunc == FCANDSCSC) {
        SC->Stack[SC->SP + iArg1] = (SC->Stack[SC->SP + iArg1] && SC->Stack[SC->SP + iArg2]) ? 256 : 0;
    } else if (iFunc == FCCALL) {
        SC->CS[SC->CallStack] = SC->IP;
        ++SC->CallStack;
        SC->IP = iArg1;
    } else if (iFunc == FCRET) {
        --SC->CallStack;
        if (SC->CallStack < 0) {
            SC->Done = 1;
        } else {
            SC->IP = SC->CS[SC->CallStack];
        }
    } else if (iFunc == FCJUMP) {
        SC->IP = iArg1;
    } else if (iFunc == FCJUMPZ) {
        if (SC->Stack[SC->SP] == 0) {
            SC->IP = iArg1;
        }
    } else if (iFunc == FCJUMPNZ) {
        if (!SC->Stack[SC->SP]) {
            SC->IP = iArg1;
        }
    } else if (iFunc == FCEXT) {
        if (iArg1 == EFGETDATA || iArg1 == EFGET) {
            SC->Stack[SC->BP - 1] = ExtFunction(iArg1, SC);
        } else {
            SC->Stack[SC->BP - 1] = ExtFunction(iArg1, SC) * 256;
        }
    } else {
        SC->Done = 1;
    }
}

void LoadScript(char* sFileName, ScriptCode* oScript) {
    unsigned char* cData;
    int iLen;

    cData = NULL;
    iLen = FileToString(sFileName, &cData);

    int iPlace;
    int iSubs;
    int iSub;
    int iCopy;

    iPlace = 0;

    iSubs = StringToLong2(&cData[iPlace]);
    oScript->Subs = iSubs;
    iPlace += 4;

    iSub =- 1;
    while (++iSub < iSubs) {
        iCopy = -1;

        while (++iCopy < 20) {
            oScript->SubName[iSub][iCopy] = cData[iPlace];
            ++iPlace;
        }

        oScript->SubStart[iSub] = StringToLong2(&cData[iPlace]);
        iPlace += 4;
    }

    int iCodeLine;

    iCodeLine = 0;
    while (iPlace < iLen) {
        oScript->Code[iCodeLine] = StringToLong2(&cData[iPlace]);
        iPlace += 4;
        ++iCodeLine;

        if (iCodeLine > 6990) {
            MessageBox(0, "Script is too long!", "ERROR", 0);
            break;
        }
    }

    free(cData);
}
