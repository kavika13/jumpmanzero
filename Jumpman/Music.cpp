#include "stdafx.h"

#include <windows.h>
#include <dmusicc.h>
#include <dmusici.h>
#include <dxerr8.h>
#include <tchar.h>
#include "DMUtil.h"
#include "DXUtil.h"
#include "jumpman.h"

HRESULT CheckForStop();
HRESULT LoadSegmentFile1(TCHAR* strFileName);
HRESULT LoadSegmentFile2(TCHAR* strFileName);

#define MUSIC_VOLUME_RANGE      ( 0-(DMUS_VOLUME_MIN/4) )

CMusicManager*     g_pMusicManager          = NULL;

CMusicSegment*     g_pMusicSegment1          = NULL;
CMusicSegment*     g_pMusicSegment2          = NULL;

HANDLE             g_hDMusicMessageEvent    = NULL;

int CheckMusicEvent()
{
    DWORD dwResult;

	dwResult = MsgWaitForMultipleObjects( 1, &g_hDMusicMessageEvent,FALSE, 0, QS_ALLEVENTS );

	if(dwResult==WAIT_OBJECT_0){
		if(CheckForStop()){	
			return 1;
			}
		}

	return 0;
}

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

void PauseMusic2()
{
  g_pMusicSegment2->Stop( DMUS_SEGF_BEAT ); 
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

long CheckForStop()
{
    HRESULT hr;
    IDirectMusicPerformance8* pPerf = NULL;
    DMUS_NOTIFICATION_PMSG* pPMsg;
	long bStopped;

	bStopped=0;
        
    pPerf = g_pMusicManager->GetPerformance();

	hr=pPerf->GetNotificationPMsg( &pPMsg );

	if(hr==S_OK)
    {
        switch( pPMsg->dwNotificationOption )
        {
        case DMUS_NOTIFICATION_SEGEND:
            if( pPMsg->punkUser )
            {
                IDirectMusicSegmentState8* pSegmentState   = NULL;
                IDirectMusicSegment*       pNotifySegment   = NULL;
                IDirectMusicSegment8*      pNotifySegment8  = NULL;
                IDirectMusicSegment8*      pPrimarySegment8 = NULL;

                // The pPMsg->punkUser contains a IDirectMusicSegmentState8, 
                // which we can query for the segment that the SegmentState refers to.
                if( FAILED( hr = pPMsg->punkUser->QueryInterface( IID_IDirectMusicSegmentState8,
                                                                  (VOID**) &pSegmentState ) ) )
                    return DXTRACE_ERR( TEXT("QueryInterface"), hr );

                if( FAILED( hr = pSegmentState->GetSegment( &pNotifySegment ) ) )
                {
                    // Sometimes the segend arrives after the segment is gone
                    // This can happen when you load another segment as 
                    // a motif or the segment is ending
                    if( hr == DMUS_E_NOT_FOUND )
                    {
                        SAFE_RELEASE( pSegmentState );
                        return S_OK;
                    }

                    return DXTRACE_ERR( TEXT("GetSegment"), hr );
                }

                if( FAILED( hr = pNotifySegment->QueryInterface( IID_IDirectMusicSegment8,
                                                                 (VOID**) &pNotifySegment8 ) ) )
                    return DXTRACE_ERR( TEXT("QueryInterface"), hr );

                // Get the IDirectMusicSegment for the primary segment
                pPrimarySegment8 = g_pMusicSegment1->GetSegment();

                // Figure out which segment this is
                if( pNotifySegment8 == pPrimarySegment8 )
                {
					bStopped=1;
                }

                // Cleanup
                SAFE_RELEASE( pSegmentState );
                SAFE_RELEASE( pNotifySegment );
                SAFE_RELEASE( pNotifySegment8 );
            }
            break;
        }

        pPerf->FreePMsg( (DMUS_PMSG*)pPMsg ); 
    }

    return bStopped;
}

