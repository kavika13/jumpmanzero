#include "stdafx.h"  // NOLINT
#include <stdio.h>  // NOLINT
#define WIN32_LEAN_AND_MEAN
#include <windows.h>  // NOLINT
#include <D3DX8.h>
#include "./jumpman.h"

#define MAX_TEXTURES 30
#define MAX_OBJECTS 600
#define MAX_VERTICES 110000

#pragma comment(lib, "d3d8.lib")
#pragma comment(lib, "d3dx8.lib")

void FatalError(const char* error_msg);
long init_d3d(HWND hWindow);
void kill_d3d(void);
void init_scene(void);
void kill_scene(void);

HWND g_main_window = NULL;

LPDIRECT3D8 g_D3D = NULL;
IDirect3DDevice8* g_d3d_device = NULL;

LPDIRECT3DTEXTURE8 texData[MAX_TEXTURES];
char RetainTextureFile[MAX_TEXTURES][300];
long texRequiresAlpha[MAX_TEXTURES];
long texType[MAX_TEXTURES];

D3DLIGHT8 light;
D3DXMATRIX view_matrix;

// #define D3D8T_CUSTOMVERTEX (D3DFVF_XYZ|D3DFVF_TEX1|D3DFVF_NORMAL|D3DFVF_DIFFUSE)
#define D3D8T_CUSTOMVERTEX (D3DFVF_XYZ|D3DFVF_TEX1|D3DFVF_NORMAL)

D3DPRESENT_PARAMETERS d3dpp;

long CapsFog;

long miVertices;
IDirect3DVertexBuffer8* g_vb = NULL;

long DrawnObjects;

long miObjects;

long iRedirects[MAX_OBJECTS];
long iStart[MAX_OBJECTS];
long iLength[MAX_OBJECTS];
long iTEX[MAX_OBJECTS];
long iVis[MAX_OBJECTS];
D3DXMATRIX matObject[MAX_OBJECTS];

long GetDrawnObjects() {
    return DrawnObjects;
}

long SurfaceObject(long o1) {
    int iLoop = -1;

    while (++iLoop < MAX_OBJECTS) {
        if (iRedirects[iLoop] == o1) {
            return iLoop;
        }
    }

    MessageBox(0, "Can't find object to surface!", "Jumpman Zero", 0);

    return 0;
}

void DeleteMesh(long iMesh) {
//  long iReal;
//  iReal = iRedirects[iMesh];
//  iVis[iReal] = 0;

    long iReal;
    iReal = iRedirects[iMesh];
    SwapObjects(iReal, miObjects - 1);

    iRedirects[iMesh] = -1;
    --miObjects;
}

void IdentityMatrix(long iObj) {
    long iReal;

    iReal = iRedirects[iObj];
    D3DXMatrixIdentity(&matObject[iReal]);
}

void PerspectiveMatrix(long iObj) {
    long iReal;
    float det;
    D3DXMATRIX tempMatrix1;

    iReal = iRedirects[iObj];
    D3DXMatrixInverse(&tempMatrix1, &det, &view_matrix);
    D3DXMatrixMultiply(&matObject[iReal], &matObject[iReal], &tempMatrix1);
}

void TranslateMatrix(long iObj, float fX, float fY, float fZ) {
    long iReal;
    D3DXMATRIX tempMatrix1;

    iReal = iRedirects[iObj];
    D3DXMatrixTranslation(&tempMatrix1, fX, fY, fZ);
    D3DXMatrixMultiply(&matObject[iReal], &matObject[iReal], &tempMatrix1);
}

void ScaleMatrix(long iObj, float fX, float fY, float fZ) {
    long iReal;
    D3DXMATRIX tempMatrix1;

    iReal = iRedirects[iObj];
    D3DXMatrixScaling(&tempMatrix1, fX, fY, fZ);
    D3DXMatrixMultiply(&matObject[iReal], &matObject[iReal], &tempMatrix1);
}

void ScrollTexture(long iObj, float fX, float fY) {
    long iPlace;
    long iVertice;
    long iRNum;

    iRNum = iRedirects[iObj];

    my_vertex* vb_vertices;
    HRESULT hr;

    hr = g_vb->Lock(0, 0, reinterpret_cast<BYTE**>(&vb_vertices), 0);

    if (FAILED(hr)) {
        FatalError("Error Locking triangle buffer");
    }

    iVertice = iStart[iRNum];

    iPlace = -1;
    while (++iPlace < iLength[iRNum]) {
        vb_vertices[iVertice].tu += fX;
        vb_vertices[iVertice].tv += fY;
        ++iVertice;
    }

    g_vb->Unlock();
}

void RotateMatrixX(long iObj, float fDegrees) {
    long iReal;
    D3DXMATRIX tempMatrix1;

    iReal = iRedirects[iObj];
    D3DXMatrixRotationX(&tempMatrix1, fDegrees * 3.1415f / 180.0f);
    D3DXMatrixMultiply(&matObject[iReal], &matObject[iReal], &tempMatrix1);
}

void RotateMatrixY(long iObj, float fDegrees) {
    long iReal;
    D3DXMATRIX tempMatrix1;

    iReal = iRedirects[iObj];
    D3DXMatrixRotationY(&tempMatrix1, fDegrees * 3.1415f / 180.0f);
    D3DXMatrixMultiply(&matObject[iReal], &matObject[iReal], &tempMatrix1);
}

void RotateMatrixZ(long iObj, float fDegrees) {
    long iReal;
    D3DXMATRIX tempMatrix1;

    iReal = iRedirects[iObj];
    D3DXMatrixRotationZ(&tempMatrix1, fDegrees * 3.1415f / 180.0f);
    D3DXMatrixMultiply(&matObject[iReal], &matObject[iReal], &tempMatrix1);
}

void PrioritizeObject(long o1) {
    long iSwap;

    iSwap = iRedirects[o1];

//  SwapObjects(0, iSwap);
//  return;

    while (--iSwap >= 0) {
        SwapObjects(iSwap, iSwap + 1);
    }
}

void SwapLong(long* l1, long* l2) {
    long iSwap;
    iSwap = *l1;
    *l1 = *l2;
    *l2 = iSwap;
}

void SwapObjects(long o1, long o2) {
    D3DXMATRIX mSwap;
    long iRealO1, iRealO2;

    iRealO1 = o1;
    iRealO2 = o2;

    mSwap = matObject[iRealO1];
    matObject[iRealO1] = matObject[iRealO2];
    matObject[iRealO2] = mSwap;

    SwapLong(&iStart[iRealO1], &iStart[iRealO2]);
    SwapLong(&iLength[iRealO1], &iLength[iRealO2]);
    SwapLong(&iTEX[iRealO1], &iTEX[iRealO2]);
    SwapLong(&iVis[iRealO1], &iVis[iRealO2]);

    SwapLong(&iRedirects[SurfaceObject(o1)], &iRedirects[SurfaceObject(o2)]);
}

void Clear3dData() {
    int iLoop;

    for (iLoop = 0; iLoop < MAX_TEXTURES; ++iLoop) {
        if (texData[iLoop]) {
            texData[iLoop]->Release();
        }
        texData[iLoop] = NULL;
    }

    miObjects = 0;

    for (iLoop = 0; iLoop < MAX_OBJECTS; ++iLoop) {
        iRedirects[iLoop] = -1;
    }

    miVertices = 0;
}

void LoadTexture(int iTex, char* sFile, int iType, int iAlpha) {
    HRESULT hr;
    texRequiresAlpha[iTex] = iAlpha;
    strcpy_s(RetainTextureFile[iTex], sFile);
    texType[iTex] = iType;

    if (iType == 0) {
        hr = D3DXCreateTextureFromFile(g_d3d_device, sFile, &texData[iTex]);
    } else if (iType == 1) {
        hr = D3DXCreateTextureFromFileEx(g_d3d_device,  // Our D3D Device
                                         sFile,         // Filename of our texture
                                         D3DX_DEFAULT,  // Width:D3DX_DEFAULT = Take from file
                                         D3DX_DEFAULT,  // Height:D3DX_DEFAULT = Take from file
                                         1,             // MipLevels
                                         0,             // Usage, Is this to be used as a Render Target? 0 == No
                                         D3DFMT_A8R8G8B8,  // 32-bit with Alpha, everything should support this
                                         D3DPOOL_MANAGED,  // Pool, let D3D Manage our memory
                                         D3DX_DEFAULT,  // Filter:Default filtering
                                         D3DX_DEFAULT,  // MipFilter, used for filtering mipmaps
                                         0xFFFFFFFF,    // ColourKey
                                         NULL,          // SourceInfo, returns extra info if we want it (we don't)
                                         NULL,          // Palette:We're not using one
                                         &texData[iTex]);  // Our texture goes here.
    }

    if (FAILED(hr)) {
        FatalError("Error loading texture");
    }
}

void SetObjectMesh(long* iParams, long iCount, long iNum) {
    long iPlace;
    long iVertice;
    long iRNum;

    iRNum = iRedirects[iNum];

    my_vertex* vb_vertices;
    HRESULT hr;

    hr = g_vb->Lock(0, 0, reinterpret_cast<BYTE**>(&vb_vertices), 0);
    if (FAILED(hr)) {
        FatalError("Error Locking triangle buffer");
    }

    iVertice = iStart[iRNum];
    iLength[iRNum] = iCount;

    iPlace = -1;
    while (++iPlace < iCount) {
        vb_vertices[iVertice].x = iParams[iPlace * 9 + 0] / 256.0f;
        vb_vertices[iVertice].y = iParams[iPlace * 9 + 1] / 256.0f;
        vb_vertices[iVertice].z = iParams[iPlace * 9 + 2] / 256.0f;
        vb_vertices[iVertice].nx = iParams[iPlace * 9 + 3] / 256.0f;
        vb_vertices[iVertice].ny = iParams[iPlace * 9 + 4] / 256.0f;
        vb_vertices[iVertice].nz = iParams[iPlace * 9 + 5] / 256.0f;
        vb_vertices[iVertice].tu = iParams[iPlace * 9 + 7] / 256.0f;
        vb_vertices[iVertice].tv = iParams[iPlace * 9 + 8] / 256.0f;

        ++iVertice;
    }

    g_vb->Unlock();
}

void ChangeMesh(long iMesh, long iNewMesh) {
    long iObjectToCopy;
    long iRealMesh;

    iRealMesh = iRedirects[iMesh];
    iObjectToCopy = iRedirects[iNewMesh];

    iStart[iRealMesh] = iStart[iObjectToCopy];
    iLength[iRealMesh] = iLength[iObjectToCopy];
}

void CopyObject(int iObject, long* iNum) {
    long iObjectToCopy;
    long iLoop;
    long iPlace;

    iObjectToCopy = iRedirects[iObject];

    iLoop = -1;
    iPlace = -1;

    while (++iLoop < MAX_OBJECTS && iPlace == -1) {
        if (iRedirects[iLoop] == -1) {
            iPlace = iLoop;
        }
    }

    if (iPlace == -1) {
        iPlace = 0;
        MessageBox(0, "Too many objects!", "Jumpman Zero", 0);
    }

    *iNum = iPlace;
    iRedirects[iPlace] = miObjects;

    iStart[miObjects] = iStart[iObjectToCopy];
    iLength[miObjects] = iLength[iObjectToCopy];

    SetObjectData(*iNum, 0, 0);
    IdentityMatrix(*iNum);

    ++miObjects;
}

void CreateObject(long* iParams, long iCount, long* iNum) {
    long iPlace;

    *iNum = miObjects;
    iRedirects[miObjects] = miObjects;
    iStart[miObjects] = miVertices;
    iLength[miObjects] = iCount;

    SetObjectData(miObjects, 0, 0);
    IdentityMatrix(miObjects);

    my_vertex* vb_vertices;
    HRESULT hr;

    hr = g_vb->Lock(0, 0, reinterpret_cast<BYTE**>(&vb_vertices), 0);
    if (FAILED(hr)) {
        FatalError("Error Locking triangle buffer");
    }

    iPlace = -1;
    while (++iPlace < iCount) {
        vb_vertices[miVertices].x = iParams[iPlace * 9 + 0] / 256.0f;
        vb_vertices[miVertices].y = iParams[iPlace * 9 + 1] / 256.0f;
        vb_vertices[miVertices].z = iParams[iPlace * 9 + 2] / 256.0f;
        vb_vertices[miVertices].nx = iParams[iPlace * 9 + 3] / 256.0f;
        vb_vertices[miVertices].ny = iParams[iPlace * 9 + 4] / 256.0f;
        vb_vertices[miVertices].nz = iParams[iPlace * 9 + 5] / 256.0f;
        vb_vertices[miVertices].tu = iParams[iPlace * 9 + 7] / 256.0f;
        vb_vertices[miVertices].tv = iParams[iPlace * 9 + 8] / 256.0f;

        ++miVertices;
    }

    miObjects = miObjects + 1;

    g_vb->Unlock();
}

void SetObjectData(long iNum, long iTexture, int iVisible) {
    long iRNum;
    iRNum = iRedirects[iNum];
    iTEX[iRNum] = iTexture;
    iVis[iRNum] = iVisible;
}

void Reset3d(HWND hWindow) {
    my_vertex* vb_vertices;
    my_vertex* CopyVertice;
    HRESULT hr;
    long i;

    if (g_D3D == NULL) {
        return;
    }
    if (g_vb == NULL) {
        return;
    }
    if (g_d3d_device == NULL) {
        return;
    }

    CopyVertice = static_cast<my_vertex*>(malloc(MAX_VERTICES * sizeof(my_vertex)));
    hr = g_vb->Lock(0, 0, reinterpret_cast<BYTE**>(&vb_vertices), 0);

    if (FAILED(hr)) {
        return;
    }

    i = -1;

    while (++i < MAX_VERTICES) {
        CopyVertice[i] = vb_vertices[i];
    }

    g_vb->Unlock();

    if (g_vb) {
        g_vb->Release();
        g_vb = NULL;
    }
    if (g_d3d_device) {
        g_d3d_device->Release();
        g_d3d_device = NULL;
    }
    if (g_D3D) {
        g_D3D->Release();
        g_D3D = NULL;
    }

    D3DDISPLAYMODE display_mode;

    int iLoop = -1;
    int iLoadTexture[MAX_TEXTURES];

    while (++iLoop < MAX_TEXTURES) {
        iLoadTexture[iLoop] = (texData[iLoop] != NULL);
        texData[iLoop] = NULL;
    }

    g_D3D = Direct3DCreate8(D3D_SDK_VERSION);
    hr = g_D3D->GetAdapterDisplayMode(D3DADAPTER_DEFAULT, &display_mode);

    if (FAILED(hr)) {
        return;
    }

    hr = g_D3D->CreateDevice(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, hWindow, D3DCREATE_SOFTWARE_VERTEXPROCESSING, &d3dpp, &g_d3d_device);

    if (FAILED(hr)) {
        return;
    }

    init_scene();

    iLoop = -1;

    while (++iLoop < MAX_TEXTURES) {
        if (iLoadTexture[iLoop]) {
            LoadTexture(iLoop, RetainTextureFile[iLoop], texType[iLoop], texRequiresAlpha[iLoop]);
        }
    }

    hr = g_vb->Lock(0, 0, reinterpret_cast<BYTE**>(&vb_vertices), 0);

    if (FAILED(hr)) {
        return;
    }

    i = -1;

    while (++i < MAX_VERTICES) {
        vb_vertices[i] = CopyVertice[i];
    }

    g_vb->Unlock();
}

long InitializeAll(HWND hWindow) {
    if (!init_d3d(hWindow)) {
        return 0;
    }

    init_scene();

    return 1;
}

void DoCleanUp() {
    kill_scene();
    kill_d3d();
}

long init_d3d(HWND hWindow) {
    HRESULT hr;
    D3DDISPLAYMODE display_mode;

    int iLoop;
    iLoop = -1;
    while (++iLoop < MAX_TEXTURES) {
        texData[iLoop] = NULL;
    }

    for (iLoop = 0; iLoop < MAX_OBJECTS; ++iLoop) {
        iRedirects[iLoop] = -1;
    }

    g_D3D = Direct3DCreate8(D3D_SDK_VERSION);

    if (!g_D3D) {
        FatalError("Error getting Direct3D - ensure you have DirectX 8.1 installed.");
        return 0;
    }

    hr = g_D3D->GetAdapterDisplayMode(D3DADAPTER_DEFAULT, &display_mode);

    if (FAILED(hr)) {
        FatalError("Error getting display mode\n");
        return 0;
    }

    ZeroMemory(&d3dpp, sizeof(d3dpp));

    d3dpp.SwapEffect = D3DSWAPEFFECT_DISCARD;
    d3dpp.hDeviceWindow = hWindow;
    d3dpp.BackBufferCount = 1;

    d3dpp.EnableAutoDepthStencil = TRUE;
    d3dpp.AutoDepthStencilFormat = D3DFMT_D16;

    if (FULL_SCREEN) {
        d3dpp.Windowed = FALSE;
//      d3dpp.BackBufferWidth = 640;
//      d3dpp.BackBufferHeight = 480;
        d3dpp.BackBufferWidth = FULLSCREEN_RESX;
        d3dpp.BackBufferHeight = FULLSCREEN_RESY;
        d3dpp.BackBufferFormat = D3DFMT_A8R8G8B8;
    } else {
        d3dpp.Windowed = TRUE;
        d3dpp.BackBufferFormat = display_mode.Format;
    }

//  hr = g_D3D->CreateDevice(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, hWindow, D3DCREATE_HARDWARE_VERTEXPROCESSING, &d3dpp, &g_d3d_device);
//  hr = g_D3D->CreateDevice(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, hWindow, D3DCREATE_SOFTWARE_VERTEXPROCESSING, &d3dpp, &g_d3d_device);
    hr = g_D3D->CreateDevice(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, hWindow, D3DCREATE_HARDWARE_VERTEXPROCESSING, &d3dpp, &g_d3d_device);

    if (FAILED(hr)) {
        FatalError("Error creating device - ensure that your video card supports 3d acceleration.\n");
        return 0;
    }

    D3DCAPS8 dCaps;
    g_d3d_device->GetDeviceCaps(&dCaps);

    CapsFog = 1;
    if (!(dCaps.RasterCaps & D3DPRASTERCAPS_ZFOG)) {
        CapsFog = 0;
    }

    return 1;
}

void kill_d3d(void) {
    if (g_d3d_device) {
        g_d3d_device->Release();
        g_d3d_device = NULL;
    }

    if (g_D3D) {
        g_D3D->Release();
        g_D3D = NULL;
    }
}

void SetFog(float iFogStart, float iFogEnd, DWORD Color) {
    if (!CapsFog) {
        return;
    }

    if (iFogStart == 0 && iFogEnd == 0) {
        g_d3d_device->SetRenderState(D3DRS_FOGENABLE, FALSE);
    } else {
        g_d3d_device->SetRenderState(D3DRS_FOGENABLE, TRUE);
        g_d3d_device->SetRenderState(D3DRS_FOGCOLOR, Color);
        g_d3d_device->SetRenderState(D3DRS_FOGTABLEMODE, D3DFOG_LINEAR);
        g_d3d_device->SetRenderState(D3DRS_FOGSTART, *reinterpret_cast<DWORD*>(&iFogStart));
        g_d3d_device->SetRenderState(D3DRS_FOGEND, *reinterpret_cast<DWORD*>(&iFogEnd));
    }
}

void SetPerspective(float iCamX, float iCamY, float iCamZ, float iPoiX, float iPoiY, float iPoiZ) {
    D3DXMatrixLookAtLH(&view_matrix, &D3DXVECTOR3(iCamX, iCamY, iCamZ), &D3DXVECTOR3(iPoiX, iPoiY, iPoiZ), &D3DXVECTOR3(0.0f, 1.0f, 0.0f));
    g_d3d_device->SetTransform(D3DTS_VIEW, &view_matrix);

    light.Position = D3DXVECTOR3(iCamX, iCamY + 10.0f, -200.0f);

    light.Diffuse.r = 1.0f;
    light.Diffuse.g = 1.0f;
    light.Diffuse.b = 1.0f;

    light.Ambient.r = 1.0f;
    light.Ambient.g = 1.0f;
    light.Ambient.b = 1.0f;

    g_d3d_device->SetLight(0, &light);
    g_d3d_device->LightEnable(0, TRUE);
}

void init_scene(void) {
    HRESULT hr;
    D3DXMATRIX matProj;

    ZeroMemory(&light, sizeof(D3DLIGHT8));
    light.Type = D3DLIGHT_POINT;

    light.Diffuse.r = 1.0f;
    light.Diffuse.g = 1.0f;
    light.Diffuse.b = 1.0f;

    light.Ambient.r = 1.0f;
    light.Ambient.g = 1.0f;
    light.Ambient.b = 1.0f;

    light.Range = 1000.0f;
    light.Position = D3DXVECTOR3(80.0f, 100.0f, -200.0f);
    light.Attenuation0 = 1.0f;

    g_d3d_device->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
//   g_d3d_device->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG2);

    g_d3d_device->SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
    g_d3d_device->SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_CURRENT);

/*
    g_d3d_device->SetTextureStageState(0, D3DTSS_MAGFILTER, D3DTEXF_NONE);
    g_d3d_device->SetTextureStageState(0, D3DTSS_MINFILTER, D3DTEXF_NONE);
*/

    g_d3d_device->SetRenderState(D3DRS_LIGHTING, TRUE);
    g_d3d_device->SetRenderState(D3DRS_AMBIENT, 0x01010101);
    g_d3d_device->SetRenderState(D3DRS_ZENABLE, TRUE);

    // SET ALPHA DISABLED
/*
    g_d3d_device->SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_DISABLE);
    g_d3d_device->SetRenderState(D3DRS_ALPHABLENDENABLE, FALSE);
*/

    // SET ALPHA ENABLED
    g_d3d_device->SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
    g_d3d_device->SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
    g_d3d_device->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
    g_d3d_device->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
    g_d3d_device->SetRenderState(D3DRS_ALPHABLENDENABLE, TRUE);

    SetPerspective(80.0f, 90.0f, -145.0f, 80.0f, 59.0f, 0.0f);

    D3DXMatrixPerspectiveFovLH(&matProj, D3DX_PI / 4, 640.0f / 480.0f, 1.0f, 300.0f);
    g_d3d_device->SetTransform(D3DTS_PROJECTION, &matProj);

    hr = g_d3d_device->CreateVertexBuffer(MAX_VERTICES * sizeof(my_vertex), D3DUSAGE_WRITEONLY, D3D8T_CUSTOMVERTEX, D3DPOOL_MANAGED, &g_vb);
    if (FAILED(hr)) {
        FatalError("Error creating vertex buffer");
    }

    D3DMATERIAL8 mtrl;
    ZeroMemory(&mtrl, sizeof(D3DMATERIAL8));
    mtrl.Diffuse.r = 0.5f;
    mtrl.Diffuse.g = 0.5f;
    mtrl.Diffuse.b = 0.5f;
    mtrl.Ambient.r = 0.5f;
    mtrl.Ambient.g = 0.5f;
    mtrl.Ambient.b = 0.5f;
    g_d3d_device->SetMaterial(&mtrl);

    g_d3d_device->SetVertexShader(D3D8T_CUSTOMVERTEX);
    g_d3d_device->SetStreamSource(0, g_vb, sizeof(my_vertex));
}

void kill_scene(void) {
    int iLoop;

    iLoop = -1;
    while (++iLoop < MAX_TEXTURES) {
        if (texData[iLoop]) {
            texData[iLoop]->Release();
            texData[iLoop] = NULL;
        }
    }

    if (g_vb) {
        g_vb->Release();
        g_vb = NULL;
    }
}

long Render(void) {
    long iObject;
    long iLastTexture;
    long iAlphaEnabled;
    long iReq;
    HRESULT hr;

    hr = g_d3d_device->Clear(0, NULL, D3DCLEAR_ZBUFFER, D3DCOLOR_XRGB(0, 0, 0), 1.0f, 0);
    if (FAILED(hr)) {
        return 0;
    }

    hr = g_d3d_device->BeginScene();
    if (FAILED(hr)) {
        return 0;
    }

    DrawnObjects = 0;
    iObject = -1;
    iLastTexture = -1;
    iAlphaEnabled = -1;

    while (++iObject < miObjects) {
        if (iVis[iObject]) {
            ++DrawnObjects;
            if (iLastTexture != iTEX[iObject]) {
                hr = g_d3d_device->SetTexture(0, texData[iTEX[iObject]]);
                if (FAILED(hr)) {
                    MessageBox(0, "Error setting texture!", "Jumpman Zero", 0);
                }
                iLastTexture = iTEX[iObject];
                iReq = texRequiresAlpha[iLastTexture];
                if (iAlphaEnabled != iReq) {
                    hr = g_d3d_device->SetRenderState(D3DRS_ALPHABLENDENABLE, iReq);
                    if (FAILED(hr)) {
                        MessageBox(0, "Error setting alpha!", "Jumpman Zero", 0);
                    }
                    iAlphaEnabled = iReq;
                }
            }

            g_d3d_device->SetTransform(D3DTS_WORLD, &matObject[iObject]);
            g_d3d_device->DrawPrimitive(D3DPT_TRIANGLELIST, iStart[iObject], iLength[iObject] / 3);
        }
    }

    hr = g_d3d_device->EndScene();
    if (FAILED(hr)) {
        return 0;
    }

    hr = g_d3d_device->SetTexture(0, NULL);
    if (FAILED(hr)) {
        return 0;
    }

    hr = g_d3d_device->Present(NULL, NULL, NULL, NULL);
    if (FAILED(hr)) {
        return 0;
    }

    return 1;
}

void FatalError(const char* error_msg) {
    kill_scene();
    kill_d3d();
    MessageBox(NULL, error_msg, "Jumpman Zero", MB_OK);
}
