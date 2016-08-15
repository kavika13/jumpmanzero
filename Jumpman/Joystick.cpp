#include "stdafx.h"
#include <mmsystem.h>

int JoystickPresent() {
    MMRESULT mRes;
    JOYINFO ji;

    mRes = joyGetPos(0, &ji);

    if((!mRes) && ji.wXpos > 0) {
        return 1;
    }

    return 0;
}

void GetJoystickPosition(long* X, long* Y, long* B) {
    MMRESULT mRes;
    JOYINFO ji;

    mRes = joyGetPos(0, &ji);
    *X = ji.wXpos;
    *Y = ji.wYpos;
    *B = ji.wButtons;
}
