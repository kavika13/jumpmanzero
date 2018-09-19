#include <stdio.h>  // NOLINT
#define WIN32_LEAN_AND_MEAN
#include <windows.h>  // NOLINT
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#define HANDMADE_MATH_IMPLEMENTATION
#define HANDMADE_MATH_NO_SSE
#include "HandmadeMath.h"
#include "./jumpman.h"

#define MAX_TEXTURES 30
#define MAX_OBJECTS 600
#define MAX_VERTICES 110000

#pragma comment(lib, "d3d8.lib")

extern int g_backbuffer_width;
extern int g_backbuffer_height;

void FatalError(const char* error_msg);
long init_d3d(HWND hWindow);
void kill_d3d(void);
void init_scene(void);
void kill_scene(void);

LPDIRECT3D8 g_D3D = NULL;
IDirect3DDevice8* g_d3d_device = NULL;

LPDIRECT3DTEXTURE8 texData[MAX_TEXTURES];
char RetainTextureFile[MAX_TEXTURES][300];
long texRequiresAlpha[MAX_TEXTURES];
long texType[MAX_TEXTURES];

D3DLIGHT8 g_light;
hmm_mat4 g_view_matrix;

hmm_mat4 HMM_Mat4(hmm_vec4 column_0, hmm_vec4 column_1, hmm_vec4 column_2, hmm_vec4 column_3) {
    hmm_mat4 result {
        column_0[0], column_0[1], column_0[2], column_0[3],
        column_1[0], column_1[1], column_1[2], column_1[3],
        column_2[0], column_2[1], column_2[2], column_2[3],
        column_3[0], column_3[1], column_3[2], column_3[3],
    };
    return result;
}

hmm_mat4 jm_hmm_inverse(hmm_mat4 input) {
    float coef_00 = input[2][2] * input[3][3] - input[3][2] * input[2][3];
    float coef_02 = input[1][2] * input[3][3] - input[3][2] * input[1][3];
    float coef_03 = input[1][2] * input[2][3] - input[2][2] * input[1][3];

    float coef_04 = input[2][1] * input[3][3] - input[3][1] * input[2][3];
    float coef_06 = input[1][1] * input[3][3] - input[3][1] * input[1][3];
    float coef_07 = input[1][1] * input[2][3] - input[2][1] * input[1][3];

    float coef_08 = input[2][1] * input[3][2] - input[3][1] * input[2][2];
    float coef_10 = input[1][1] * input[3][2] - input[3][1] * input[1][2];
    float coef_11 = input[1][1] * input[2][2] - input[2][1] * input[1][2];

    float coef_12 = input[2][0] * input[3][3] - input[3][0] * input[2][3];
    float coef_14 = input[1][0] * input[3][3] - input[3][0] * input[1][3];
    float coef_15 = input[1][0] * input[2][3] - input[2][0] * input[1][3];

    float coef_16 = input[2][0] * input[3][2] - input[3][0] * input[2][2];
    float coef_18 = input[1][0] * input[3][2] - input[3][0] * input[1][2];
    float coef_19 = input[1][0] * input[2][2] - input[2][0] * input[1][2];

    float coef_20 = input[2][0] * input[3][1] - input[3][0] * input[2][1];
    float coef_22 = input[1][0] * input[3][1] - input[3][0] * input[1][1];
    float coef_23 = input[1][0] * input[2][1] - input[2][0] * input[1][1];

    hmm_vec4 Fac0 = HMM_Vec4(coef_00, coef_00, coef_02, coef_03);
    hmm_vec4 Fac1 = HMM_Vec4(coef_04, coef_04, coef_06, coef_07);
    hmm_vec4 Fac2 = HMM_Vec4(coef_08, coef_08, coef_10, coef_11);
    hmm_vec4 Fac3 = HMM_Vec4(coef_12, coef_12, coef_14, coef_15);
    hmm_vec4 Fac4 = HMM_Vec4(coef_16, coef_16, coef_18, coef_19);
    hmm_vec4 Fac5 = HMM_Vec4(coef_20, coef_20, coef_22, coef_23);

    hmm_vec4 Vec0 = HMM_Vec4(input[1][0], input[0][0], input[0][0], input[0][0]);
    hmm_vec4 Vec1 = HMM_Vec4(input[1][1], input[0][1], input[0][1], input[0][1]);
    hmm_vec4 Vec2 = HMM_Vec4(input[1][2], input[0][2], input[0][2], input[0][2]);
    hmm_vec4 Vec3 = HMM_Vec4(input[1][3], input[0][3], input[0][3], input[0][3]);

    hmm_vec4 Inv0(Vec1 * Fac0 - Vec2 * Fac1 + Vec3 * Fac2);
    hmm_vec4 Inv1(Vec0 * Fac0 - Vec2 * Fac3 + Vec3 * Fac4);
    hmm_vec4 Inv2(Vec0 * Fac1 - Vec1 * Fac3 + Vec3 * Fac5);
    hmm_vec4 Inv3(Vec0 * Fac2 - Vec1 * Fac4 + Vec2 * Fac5);

    hmm_vec4 SignA = HMM_Vec4(+1, -1, +1, -1);
    hmm_vec4 SignB = HMM_Vec4(-1, +1, -1, +1);
    hmm_mat4 Inverse = HMM_Mat4(Inv0 * SignA, Inv1 * SignB, Inv2 * SignA, Inv3 * SignB);

    hmm_vec4 Row0 = HMM_Vec4(Inverse[0][0], Inverse[1][0], Inverse[2][0], Inverse[3][0]);

    hmm_vec4 Dot0(input[0] * Row0);
    float Dot1 = (Dot0.X + Dot0.Y) + (Dot0.Z + Dot0.W);

    float OneOverDeterminant = 1.0f / Dot1;

    return Inverse * OneOverDeterminant;
}

hmm_mat4 HMM_LookAtLH(hmm_vec3 Eye, hmm_vec3 Center, hmm_vec3 Up) {
    hmm_mat4 Result;

    hmm_vec3 F = HMM_NormalizeVec3(HMM_SubtractVec3(Center, Eye));
    hmm_vec3 S = HMM_NormalizeVec3(HMM_Cross(Up, F));
    hmm_vec3 U = HMM_Cross(F, S);

    Result.Elements[0][0] = S.X;
    Result.Elements[0][1] = U.X;
    Result.Elements[0][2] = F.X;
    Result.Elements[0][3] = 0.0f;

    Result.Elements[1][0] = S.Y;
    Result.Elements[1][1] = U.Y;
    Result.Elements[1][2] = F.Y;
    Result.Elements[1][3] = 0.0f;

    Result.Elements[2][0] = S.Z;
    Result.Elements[2][1] = U.Z;
    Result.Elements[2][2] = F.Z;
    Result.Elements[2][3] = 0.0f;

    Result.Elements[3][0] = -HMM_DotVec3(S, Eye);
    Result.Elements[3][1] = -HMM_DotVec3(U, Eye);
    Result.Elements[3][2] = -HMM_DotVec3(F, Eye);
    Result.Elements[3][3] = 1.0f;

    return (Result);
}

HMM_INLINE hmm_mat4 HMM_PerspectiveFovLH_ZO(float FOV, float AspectRatio, float Near, float Far) {
    hmm_mat4 Result = HMM_Mat4();

    float TanThetaOver2 = HMM_TanF(FOV * (HMM_PI32 / 360.0f));

    Result.Elements[0][0] = 1.0f / (TanThetaOver2 * AspectRatio);
    Result.Elements[1][1] = 1.0f / TanThetaOver2;
    Result.Elements[2][2] = Far / (Far - Near);
    Result.Elements[2][3] = 1.0f;
    Result.Elements[3][2] = -(Far * Near) / (Far - Near);
    Result.Elements[3][3] = 0.0f;

    return (Result);
}

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
hmm_mat4 matObject[MAX_OBJECTS];

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
    long iReal = iRedirects[iObj];
    hmm_mat4 result {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    };
    matObject[iReal] = result;
}

void PerspectiveMatrix(long iObj) {
    long iReal = iRedirects[iObj];
    matObject[iReal] = jm_hmm_inverse(g_view_matrix) * matObject[iReal];
}

void TranslateMatrix(long iObj, float fX, float fY, float fZ) {
    long iReal = iRedirects[iObj];
    matObject[iReal] = HMM_Translate(HMM_Vec3(fX, fY, fZ)) * matObject[iReal];
}

void ScaleMatrix(long iObj, float fX, float fY, float fZ) {
    long iReal = iRedirects[iObj];
    matObject[iReal] = HMM_Scale(HMM_Vec3(fX, fY, fZ)) * matObject[iReal];
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
    long iReal = iRedirects[iObj];
    matObject[iReal] = HMM_Rotate(fDegrees, HMM_Vec3(1.0f, 0.0f, 0.0f)) * matObject[iReal];
}

void RotateMatrixY(long iObj, float fDegrees) {
    long iReal = iRedirects[iObj];
    matObject[iReal] = HMM_Rotate(fDegrees, HMM_Vec3(0.0f, 1.0f, 0.0f)) * matObject[iReal];
}

void RotateMatrixZ(long iObj, float fDegrees) {
    long iReal = iRedirects[iObj];
    matObject[iReal] = HMM_Rotate(fDegrees, HMM_Vec3(0.0f, 0.0f, 1.0f)) * matObject[iReal];
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
    hmm_mat4 mSwap;
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

    int width, height, channels_in_file;
    unsigned char* image_data = stbi_load(sFile, &width, &height, &channels_in_file, 4);

    hr = g_d3d_device->CreateTexture(width, height, 0, 0, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED, &texData[iTex]);

    if (FAILED(hr)) {
        FatalError("Error creating texture resource");  // TODO: Read back error info
    }

    D3DLOCKED_RECT rect;
    hr = texData[iTex]->LockRect(0, &rect, NULL, 0);

    if (FAILED(hr)) {
        FatalError("Error locking texture data");  // TODO: Read back error info
    }

    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            // BGRA
            ((unsigned char*)rect.pBits)[y * rect.Pitch + x * 4 + 0] = image_data[y * rect.Pitch + x * 4 + 2];
            ((unsigned char*)rect.pBits)[y * rect.Pitch + x * 4 + 1] = image_data[y * rect.Pitch + x * 4 + 1];
            ((unsigned char*)rect.pBits)[y * rect.Pitch + x * 4 + 2] = image_data[y * rect.Pitch + x * 4 + 0];

            if (iType == 1 && *((uint32_t*)&image_data[y * rect.Pitch + x * 4 + 0]) == 0xFFFFFFFF) {
                // Color key alpha, on 0xFFFFFFFF
                ((unsigned char*)rect.pBits)[y * rect.Pitch + x * 4 + 3] = 0x0;
            } else {
                ((unsigned char*)rect.pBits)[y * rect.Pitch + x * 4 + 3] = image_data[y * rect.Pitch + x * 4 + 3];
            }
        }
    }

    stbi_image_free(image_data);

    hr = texData[iTex]->UnlockRect(0);

    if (FAILED(hr)) {
        FatalError("Error unlocking texture data");  // TODO: Read back error info
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
        d3dpp.BackBufferWidth = g_backbuffer_width;
        d3dpp.BackBufferHeight = g_backbuffer_height;
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
    g_view_matrix = HMM_LookAtLH(HMM_Vec3(iCamX, iCamY, iCamZ), HMM_Vec3(iPoiX, iPoiY, iPoiZ), HMM_Vec3(0.0f, 1.0f, 0.0f));
    g_d3d_device->SetTransform(D3DTS_VIEW, (D3DMATRIX*)&g_view_matrix);

    g_light.Position = { iCamX, iCamY + 10.0f, -200.0f };

    g_light.Diffuse.r = 1.0f;
    g_light.Diffuse.g = 1.0f;
    g_light.Diffuse.b = 1.0f;

    g_light.Ambient.r = 1.0f;
    g_light.Ambient.g = 1.0f;
    g_light.Ambient.b = 1.0f;

    g_d3d_device->SetLight(0, &g_light);
    g_d3d_device->LightEnable(0, TRUE);
}

void init_scene(void) {
    HRESULT hr;

    ZeroMemory(&g_light, sizeof(D3DLIGHT8));
    g_light.Type = D3DLIGHT_POINT;

    g_light.Diffuse.r = 1.0f;
    g_light.Diffuse.g = 1.0f;
    g_light.Diffuse.b = 1.0f;

    g_light.Ambient.r = 1.0f;
    g_light.Ambient.g = 1.0f;
    g_light.Ambient.b = 1.0f;

    g_light.Range = 1000.0f;
    g_light.Position = { 80.0f, 100.0f, -200.0f };
    g_light.Attenuation0 = 1.0f;

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

    hmm_mat4 matProj = HMM_PerspectiveFovLH_ZO(45.0f, 640.0f / 480.0f, 1.0f, 300.0f);
    g_d3d_device->SetTransform(D3DTS_PROJECTION, (D3DMATRIX*)&matProj);

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

            g_d3d_device->SetTransform(D3DTS_WORLD, (D3DMATRIX*)&matObject[iObject]);
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
