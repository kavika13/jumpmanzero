#define WIN32_LEAN_AND_MEAN
#include <windows.h>  // NOLINT
#pragma warning( disable:4005 )
#include <dmusicc.h>
#pragma warning( default:4005 )
#include <dmusici.h>
#include <dxerr8.h>
#include <tchar.h>
#include "DMUtil.h"
#include "DXUtil.h"
#include "jumpman.h"

HRESULT LoadSegmentFile1(TCHAR* strFileName);
HRESULT LoadSegmentFile2(TCHAR* strFileName);

#define MUSIC_VOLUME_RANGE      ( 0-(DMUS_VOLUME_MIN/4) )

CMusicManager*     g_pMusicManager          = NULL;

CMusicSegment*     g_pMusicSegment1          = NULL;
CMusicSegment*     g_pMusicSegment2          = NULL;

HANDLE             g_hDMusicMessageEvent    = NULL;

long InitMusic(HWND hWnd)
{
    HRESULT hr;

    g_hDMusicMessageEvent = CreateEvent( NULL, FALSE, FALSE, NULL );
    g_pMusicManager = new CMusicManager();

    if( FAILED( hr = g_pMusicManager->Initialize( hWnd ) ) )return 0;
    return 1;

//    IDirectMusicPerformance* pPerf = g_pMusicManager->GetPerformance();
//    GUID guid = GUID_NOTIFICATION_SEGMENT;
//
//    hr = pPerf->AddNotificationType(guid);
//    hr = pPerf->SetNotificationHandle(g_hDMusicMessageEvent, 0);
}

void NewTrack1(char *sFile,long iStart,long iIntro)
{
    if(g_pMusicSegment1!=NULL)g_pMusicSegment1->Stop(DMUS_SEGF_BEAT);

    LoadSegmentFile1(sFile);

    HRESULT hr;
    if(iIntro>=0 && iIntro!=55000){
        hr=g_pMusicSegment1->SetRepeats(100);
        hr=g_pMusicSegment1->Play(DMUS_SEGF_BEAT,NULL,iStart,iIntro,0);
        }
    else{
        hr=g_pMusicSegment1->SetRepeats(0);
        hr=g_pMusicSegment1->Play(DMUS_SEGF_BEAT,NULL,iStart,0,0);
        }
}

void NewTrack2(char *sFile)
{
    if(g_pMusicSegment2!=NULL)g_pMusicSegment2->Stop(DMUS_SEGF_BEAT);

    LoadSegmentFile2(sFile);

    HRESULT hr;
    hr=g_pMusicSegment2->SetRepeats(0);
    hr=g_pMusicSegment2->Play(DMUS_SEGF_BEAT);
}

void PauseMusic1()
{
    if(g_pMusicSegment1!=NULL)g_pMusicSegment1->Stop(DMUS_SEGF_BEAT);
}

void CleanUpMusic()
{
    SAFE_DELETE( g_pMusicSegment1 );
    SAFE_DELETE( g_pMusicSegment2 );
    SAFE_DELETE( g_pMusicManager );
    CloseHandle( g_hDMusicMessageEvent );
}

HRESULT LoadSegmentFile1(TCHAR* strFileName)
{
    SAFE_DELETE( g_pMusicSegment1 );
    g_pMusicManager->CollectGarbage();

    if( FAILED( g_pMusicManager->CreateSegmentFromFile( &g_pMusicSegment1, strFileName, TRUE,TRUE ) ) )
    {
        return S_FALSE;
    }

    return S_OK;
}

HRESULT LoadSegmentFile2(TCHAR* strFileName)
{
    SAFE_DELETE( g_pMusicSegment2 );
    g_pMusicManager->CollectGarbage();

    if( FAILED( g_pMusicManager->CreateSegmentFromFile( &g_pMusicSegment2, strFileName, TRUE,TRUE ) ) )
    {
        return S_FALSE;
    }

    return S_OK;
}
