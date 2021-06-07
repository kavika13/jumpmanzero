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

void Clear3dData(void);
void LoadTexture(int texture_index, char* sFile, int image_type, bool is_alpha_blend_enabled);
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

int MeshCreateFromVertexComponents(long* vertex_components, int vertex_count);
int MeshCreateFromVertices(MeshVertex* vertices, int vertex_count, int texture_index, bool is_visible);
int MeshCreateFromCopy(int source_mesh_handle_index);
void MeshReplaceWithCopy(int target_mesh_handle_index, int source_mesh_handle_index);
void MeshDelete(int mesh_handle_index);
void MeshSetIsVisible(int mesh_handle_index, bool is_visible);
void MeshSetTextureIndex(int mesh_handle_index, int texture_index);
void MeshMoveToFrontForTransparentDrawing(int mesh_handle_index);
void MeshMoveToBackForTransparentDrawing(int mesh_handle_index);
void MeshScrollTexture(int mesh_handle_index, float translate_x, float translate_y);
void MeshSetIsAnimationContinuous(int mesh_handle_index, bool is_continuous);

void SetPerspective(float cam_x, float cam_y, float cam_z, float look_at_x, float look_at_y, float look_at_z);
void SetCameraIsAnimationContinuous(bool is_continuous);

void SetFog(float fog_start, float fog_end, uint8_t red, uint8_t green, uint8_t blue);

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
