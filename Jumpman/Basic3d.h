#ifndef INCLUDED_JUMPMAN_ZERO_BASIC3D_H
#define INCLUDED_JUMPMAN_ZERO_BASIC3D_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#if defined(__cplusplus)
extern "C" {
#endif

typedef struct {
    float x, y, z;
    float nx, ny, nz;
    float tu, tv;
} MeshVertex;

void ChangeMesh(long iMesh, long iNewMesh);
void SetFog(float iFogStart, float iFogEnd, uint8_t red, uint8_t green, uint8_t blue);
void ScrollTexture(long iObj, float fX, float fY);
void DeleteMesh(long iMesh);
void Clear3dData(void);
void LoadTexture(int iTex, char* sFile, long iType, int iAlpha);
bool InitializeAll(void);
void Begin3dLoad(void);
void EndAndCommit3dLoad(void);
void RendererPreUpdate(double seconds_since_previous_update);
void RendererPostUpdate(void);
void RendererDraw(double seconds_since_previous_draw, double time_scale);
void ResizeViewport(int width, int height);
void Reset3d(void);  // TODO: Is this function necessary anymore? Used for resetting context after focus switch

void DoCleanUp(void);
void CreateObject(long* iParams, long iCount, long* iNum);
size_t CreateMesh(MeshVertex* vertices, size_t vertex_count, long texture_index, bool is_visible);
void SetObjectData(long iNum, long iTexture, int iVisible);
void SetObjectTextureIndex(long iNum, long texture_index);
void SetObjectIsVisible(long iNum, bool is_visible);
void SetObjectIsAnimationContinuous(long iNum, bool is_continuous);
void SetPerspective(float iCamX, float iCamY, float iCamZ, float iPoiX, float iPoiY, float iPoiZ);
void CopyObject(long iObject, long* iNum);
void MoveMeshToFront(long o1);
void MoveMeshToBack(long o1);

void ScaleMatrix(long iObj, float fX, float fY, float fZ);
void PerspectiveMatrix(long iObj);
void IdentityMatrix(long iObj);
void TranslateMatrix(long iObj, float fX, float fY, float fZ);
void RotateMatrixX(long iObj, float fDegrees);
void RotateMatrixY(long iObj, float fDegrees);
void RotateMatrixZ(long iObj, float fDegrees);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_BASIC3D_H
