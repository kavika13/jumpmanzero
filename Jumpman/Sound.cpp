#include "stdafx.h"

#include <windows.h>
#include <basetsd.h>
#include <commdlg.h>
#include <mmreg.h>
#include <dxerr8.h>
#include <dsound.h>
#include "resource.h"
#include "DSUtil.h"
#include "DXUtil.h"
#include "jumpman.h"

#pragma comment(lib,"dsound.lib")

CSoundManager* g_pSoundManager = NULL;
CSound*        g_pSound[5]={NULL,NULL,NULL,NULL,NULL};

void DoPlaySound(int iSound)
{
    DWORD dwFlags = 0L;
    if(g_pSound[iSound]->IsSoundPlaying()){
        g_pSound[iSound]->Stop();
        g_pSound[iSound]->Reset();
        }
    g_pSound[iSound]->Play( 0, dwFlags );
}

void CleanUpSounds()
{
    int iLoop;
    iLoop=-1;while(++iLoop<5){
        SAFE_DELETE( g_pSound[iLoop] );
        }
    SAFE_DELETE( g_pSoundManager );
}

long InitSound(HWND hWnd)
{
    HRESULT hr;
    g_pSoundManager = new CSoundManager();
    hr=g_pSoundManager->Initialize(hWnd, DSSCL_PRIORITY, 2, 22050, 16 );
    if(FAILED(hr))return 0;
    return 1;
}

void LoadSound(char *sFile,int iSound)
{
    SAFE_DELETE( g_pSound[iSound] );
    g_pSoundManager->Create(&g_pSound[iSound], sFile, 0, GUID_NULL);
}
