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
void RendererPreUpdate(double seconds_per_update_timestep);
void RendererPostUpdate(void);
void RendererDraw(bool do_interpolation, float interpolation_scale);
void ResizeViewport(int width, int height);
void GetViewportMousePos(float* pos_x, float* pos_y);  // In/out parameters. Tested against latest viewport size and corrected
void Reset3d(void);  // TODO: Is this function necessary anymore? Used for resetting context after focus switch

void DoCleanUp(void);
void CreateObject(long* iParams, long iCount, long* iNum);
size_t CreateMesh(MeshVertex* vertices, size_t vertex_count, long texture_index, bool is_visible);
void SetObjectData(long iNum, long iTexture, int iVisible);
void SetObjectTextureIndex(long iNum, long texture_index);
void SetObjectIsVisible(long iNum, bool is_visible);
void SetObjectIsAnimationContinuous(long iNum, bool is_continuous);
void SetPerspective(float iCamX, float iCamY, float iCamZ, float iPoiX, float iPoiY, float iPoiZ);
void SetCameraIsAnimationContinuous(bool is_continuous);
void CopyObject(long iObject, long* iNum);
void MoveTransparentMeshToFront(long o1);
void MoveTransparentMeshToBack(long o1);

int TransformCreate(void);
void TransformDelete(int deleting_transform_index);
int TransformGetParent(int transform_index);
void TransformSetParent(int transform_index, int new_parent_index);
void TransformClearParent(int transform_index);
bool TransformGetParentIsCamera(int transform_index);
void TransformSetParentIsCamera(int transform_index, bool is_parent_camera);
int MeshGetTransform(int mesh_handle_index);
void MeshSetTransform(int mesh_handle_index, int transform_index);
void MeshClearTransform(int mesh_handle_index);
void TransformSetToIdentity(int transform_index);
void TransformSetTranslation(int transform_index, float x, float y, float z);
void TransformClearTranslation(int transform_index);
void TransformSetRotationX(int transform_index, float angle_in_degrees);
void TransformSetRotationY(int transform_index, float angle_in_degrees);
void TransformSetRotationZ(int transform_index, float angle_in_degrees);
void TransformConcatRotationX(int transform_index, float angle_in_degrees);
void TransformConcatRotationY(int transform_index, float angle_in_degrees);
void TransformConcatRotationZ(int transform_index, float angle_in_degrees);
void TransformClearRotation(int transform_index);
void TransformSetScale(int transform_index, float x, float y, float z);
void TransformClearScale(int transform_index);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // INCLUDED_JUMPMAN_ZERO_BASIC3D_H
