#include <math.h>
#include "glad/glad.h"
#define SOKOL_IMPL
#define SOKOL_GLCORE33
#include "sokol_gfx.h"

#if defined(__APPLE__)
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wcomma"
#elif defined(__GNUC__)
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wunused-parameter"
#endif
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#if defined(__APPLE__)
    #pragma clang diagnostic pop
#elif defined(__GNUC__)
    #pragma GCC diagnostic pop
#endif

#include <stb_sprintf.h>

#if defined(__APPLE__)
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wconditional-uninitialized"
#endif
#define HANDMADE_MATH_IMPLEMENTATION
#define HANDMADE_MATH_NO_SSE
#include "HandmadeMath.h"
#if defined(__APPLE__)
    #pragma clang diagnostic pop
#endif

#include "boxer/boxer.h"
#include "Basic3d.h"
#include "logging.h"

#define kMAX_TEXTURES ((size_t)30)
#define kMAX_OBJECTS ((size_t)600)
#define kMAX_VERTICES ((size_t)110000)

typedef struct {
    hmm_vec3 ambient_color;
    hmm_vec3 diffuse_color;
    hmm_vec3 position;
    float range;
} Light;

typedef struct {
    hmm_vec3 ambient_tint;
    hmm_vec3 diffuse_tint;
} Material;

typedef struct {
    hmm_mat4 local_to_world_matrix;
    hmm_mat4 local_to_view_matrix;
    hmm_mat4 local_to_projection_matrix;
    hmm_mat4 transpose_world_to_local_matrix;
    hmm_vec2 uv_offset;
} VertexShaderParams;

typedef struct {
    hmm_vec3 scene_ambient_color;
    Material material;
    Light light;
    float is_fog_enabled;
    hmm_vec3 fog_color;
    float fog_start;
    float fog_end;
} FragmentShaderParams;

static void FatalError(const char* error_msg);
static long init_3d(void);
static void kill_3d(void);
static void init_scene(void);
static void kill_scene(void);
static void SwapObjects(long o1, long o2);

static int g_backbuffer_width;
static int g_backbuffer_height;
static sg_draw_state g_draw_state = { 0 };
static sg_pipeline g_opaque_pipline = { 0 };
static sg_pipeline g_transparent_pipline = { 0 };
static sg_pass_action g_pass_action = { 0 };
static Light g_camera_light;
static Material g_global_material;
static hmm_vec3 g_scene_ambient_color;
static bool g_is_fog_enabled;
static hmm_vec3 g_fog_color;
static float g_fog_start;
static float g_fog_end;

static sg_image g_textures[kMAX_TEXTURES];
static char g_texture_filename[kMAX_TEXTURES][300];
static long g_texture_is_alpha_blend_enabled[kMAX_TEXTURES];
static long g_texture_is_color_key_alpha_enabled[kMAX_TEXTURES];

#define kERROR_IMAGE_WIDTH ((size_t)32)
#define kERROR_IMAGE_HEIGHT ((size_t)32)
static unsigned char g_error_image_data[kERROR_IMAGE_HEIGHT][kERROR_IMAGE_WIDTH][4];

static hmm_mat4 g_world_to_view_matrix;
static hmm_mat4 g_view_to_projection_matrix;

static long g_vertices_to_load_count;
static MeshVertex* g_vertices_to_load = NULL;

static long g_object_count;

static long g_object_redirects[kMAX_OBJECTS];
static long g_object_vertex_start_index[kMAX_OBJECTS];
static long g_object_vertex_count[kMAX_OBJECTS];
static long g_object_texture_index[kMAX_OBJECTS];
static long g_object_is_visible[kMAX_OBJECTS];
static hmm_vec2 g_object_uv_offset[kMAX_OBJECTS];
static hmm_mat4 g_object_local_to_world_matrix[kMAX_OBJECTS];

// Begin: helpers that weren't included in HandmadeMath (yet). Replace if they are added

static hmm_mat4 HMM_Mat4FromVec4(hmm_vec4 column_0, hmm_vec4 column_1, hmm_vec4 column_2, hmm_vec4 column_3) {
    hmm_mat4 result = { {
        { column_0.Elements[0], column_0.Elements[1], column_0.Elements[2], column_0.Elements[3] },
        { column_1.Elements[0], column_1.Elements[1], column_1.Elements[2], column_1.Elements[3] },
        { column_2.Elements[0], column_2.Elements[1], column_2.Elements[2], column_2.Elements[3] },
        { column_3.Elements[0], column_3.Elements[1], column_3.Elements[2], column_3.Elements[3] },
    } };
    return result;
}

static hmm_mat4 JM_HMM_Inverse(hmm_mat4 input) {
    float coef_00 = input.Elements[2][2] * input.Elements[3][3] - input.Elements[3][2] * input.Elements[2][3];
    float coef_02 = input.Elements[1][2] * input.Elements[3][3] - input.Elements[3][2] * input.Elements[1][3];
    float coef_03 = input.Elements[1][2] * input.Elements[2][3] - input.Elements[2][2] * input.Elements[1][3];

    float coef_04 = input.Elements[2][1] * input.Elements[3][3] - input.Elements[3][1] * input.Elements[2][3];
    float coef_06 = input.Elements[1][1] * input.Elements[3][3] - input.Elements[3][1] * input.Elements[1][3];
    float coef_07 = input.Elements[1][1] * input.Elements[2][3] - input.Elements[2][1] * input.Elements[1][3];

    float coef_08 = input.Elements[2][1] * input.Elements[3][2] - input.Elements[3][1] * input.Elements[2][2];
    float coef_10 = input.Elements[1][1] * input.Elements[3][2] - input.Elements[3][1] * input.Elements[1][2];
    float coef_11 = input.Elements[1][1] * input.Elements[2][2] - input.Elements[2][1] * input.Elements[1][2];

    float coef_12 = input.Elements[2][0] * input.Elements[3][3] - input.Elements[3][0] * input.Elements[2][3];
    float coef_14 = input.Elements[1][0] * input.Elements[3][3] - input.Elements[3][0] * input.Elements[1][3];
    float coef_15 = input.Elements[1][0] * input.Elements[2][3] - input.Elements[2][0] * input.Elements[1][3];

    float coef_16 = input.Elements[2][0] * input.Elements[3][2] - input.Elements[3][0] * input.Elements[2][2];
    float coef_18 = input.Elements[1][0] * input.Elements[3][2] - input.Elements[3][0] * input.Elements[1][2];
    float coef_19 = input.Elements[1][0] * input.Elements[2][2] - input.Elements[2][0] * input.Elements[1][2];

    float coef_20 = input.Elements[2][0] * input.Elements[3][1] - input.Elements[3][0] * input.Elements[2][1];
    float coef_22 = input.Elements[1][0] * input.Elements[3][1] - input.Elements[3][0] * input.Elements[1][1];
    float coef_23 = input.Elements[1][0] * input.Elements[2][1] - input.Elements[2][0] * input.Elements[1][1];

    hmm_vec4 fac_0 = HMM_Vec4(coef_00, coef_00, coef_02, coef_03);
    hmm_vec4 fac_1 = HMM_Vec4(coef_04, coef_04, coef_06, coef_07);
    hmm_vec4 fac_2 = HMM_Vec4(coef_08, coef_08, coef_10, coef_11);
    hmm_vec4 fac_3 = HMM_Vec4(coef_12, coef_12, coef_14, coef_15);
    hmm_vec4 fac_4 = HMM_Vec4(coef_16, coef_16, coef_18, coef_19);
    hmm_vec4 fac_5 = HMM_Vec4(coef_20, coef_20, coef_22, coef_23);

    hmm_vec4 vec_0 = HMM_Vec4(input.Elements[1][0], input.Elements[0][0], input.Elements[0][0], input.Elements[0][0]);
    hmm_vec4 vec_1 = HMM_Vec4(input.Elements[1][1], input.Elements[0][1], input.Elements[0][1], input.Elements[0][1]);
    hmm_vec4 vec_2 = HMM_Vec4(input.Elements[1][2], input.Elements[0][2], input.Elements[0][2], input.Elements[0][2]);
    hmm_vec4 vec_3 = HMM_Vec4(input.Elements[1][3], input.Elements[0][3], input.Elements[0][3], input.Elements[0][3]);

    hmm_vec4 inv_0 = HMM_AddVec4(
        HMM_SubtractVec4(
            HMM_MultiplyVec4(vec_1, fac_0),
            HMM_MultiplyVec4(vec_2, fac_1)),
        HMM_MultiplyVec4(vec_3, fac_2));
    hmm_vec4 inv_1 = HMM_AddVec4(
        HMM_SubtractVec4(
            HMM_MultiplyVec4(vec_0, fac_0),
            HMM_MultiplyVec4(vec_2, fac_3)),
        HMM_MultiplyVec4(vec_3, fac_4));
    hmm_vec4 inv_2 = HMM_AddVec4(
        HMM_SubtractVec4(
            HMM_MultiplyVec4(vec_0, fac_1),
            HMM_MultiplyVec4(vec_1, fac_3)),
        HMM_MultiplyVec4(vec_3, fac_5));
    hmm_vec4 inv_3 = HMM_AddVec4(
        HMM_SubtractVec4(
            HMM_MultiplyVec4(vec_0, fac_2),
            HMM_MultiplyVec4(vec_1, fac_4)),
        HMM_MultiplyVec4(vec_2, fac_5));

    hmm_vec4 sign_a = HMM_Vec4(+1, -1, +1, -1);
    hmm_vec4 sign_b = HMM_Vec4(-1, +1, -1, +1);
    hmm_mat4 inverse_matrix = HMM_Mat4FromVec4(
        HMM_MultiplyVec4(inv_0, sign_a),
        HMM_MultiplyVec4(inv_1, sign_b),
        HMM_MultiplyVec4(inv_2, sign_a),
        HMM_MultiplyVec4(inv_3, sign_b));

    hmm_vec4 row_0 = HMM_Vec4(inverse_matrix.Elements[0][0], inverse_matrix.Elements[1][0], inverse_matrix.Elements[2][0], inverse_matrix.Elements[3][0]);
    hmm_vec4 input_column_0 = HMM_Vec4(input.Elements[0][0], input.Elements[0][1], input.Elements[0][2], input.Elements[0][3]);

    hmm_vec4 dot_0 = HMM_MultiplyVec4(input_column_0, row_0);
    float dot_1 = (dot_0.X + dot_0.Y) + (dot_0.Z + dot_0.W);

    float one_over_determinant = 1.0f / dot_1;

    return HMM_MultiplyMat4f(inverse_matrix, one_over_determinant);
}

static hmm_mat4 HMM_LookAtLH(hmm_vec3 Eye, hmm_vec3 Center, hmm_vec3 Up) {
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

HMM_INLINE hmm_mat4 HMM_PerspectiveLH_NO(float FOV, float AspectRatio, float Near, float Far) {
    hmm_mat4 Result = HMM_Mat4();

    float TanThetaOver2 = HMM_TanF(FOV * (HMM_PI32 / 360.0f));

    Result.Elements[0][0] = 1.0f / (AspectRatio * TanThetaOver2);
    Result.Elements[1][1] = 1.0f / TanThetaOver2;
    Result.Elements[2][2] = (Far + Near) / (Far - Near);
    Result.Elements[2][3] = 1.0f;
    Result.Elements[3][2] = -(2.0f * Far * Near) / (Far - Near);
    Result.Elements[3][3] = 0.0f;

    return (Result);
}

// End: helpers that weren't included in HandmadeMath (yet). Replace if they are added

static long SurfaceObject(long o1) {
    for(int iLoop = 0; iLoop < kMAX_OBJECTS; ++iLoop) {
        if(g_object_redirects[iLoop] == o1) {
            return iLoop;
        }
    }

    boxerShow("Can't find object to surface!", "Jumpman Zero", BoxerStyleWarning, BoxerButtonsOK);

    return 0;
}

void DeleteMesh(long iMesh) {
    long iReal = g_object_redirects[iMesh];
    SwapObjects(iReal, g_object_count - 1);

    g_object_redirects[iMesh] = -1;
    --g_object_count;
}

void IdentityMatrix(long iObj) {
    long iReal = g_object_redirects[iObj];
    hmm_mat4 result = { {
        { 1, 0, 0, 0 },
        { 0, 1, 0, 0 },
        { 0, 0, 1, 0 },
        { 0, 0, 0, 1 },
    } };
    g_object_local_to_world_matrix[iReal] = result;
}

void PerspectiveMatrix(long iObj) {
    long iReal = g_object_redirects[iObj];
    g_object_local_to_world_matrix[iReal] = HMM_MultiplyMat4(
        JM_HMM_Inverse(g_world_to_view_matrix),
        g_object_local_to_world_matrix[iReal]);
}

void TranslateMatrix(long iObj, float fX, float fY, float fZ) {
    long iReal = g_object_redirects[iObj];
    g_object_local_to_world_matrix[iReal] = HMM_MultiplyMat4(
        HMM_Translate(HMM_Vec3(fX, fY, fZ)),
        g_object_local_to_world_matrix[iReal]);
}

void ScaleMatrix(long iObj, float fX, float fY, float fZ) {
    long iReal = g_object_redirects[iObj];
    g_object_local_to_world_matrix[iReal] = HMM_MultiplyMat4(
        HMM_Scale(HMM_Vec3(fX, fY, fZ)),
        g_object_local_to_world_matrix[iReal]);
}

void ScrollTexture(long iObj, float fX, float fY) {
    long iReal = g_object_redirects[iObj];
    g_object_uv_offset[iReal] = HMM_AddVec2(
        HMM_Vec2(fX, fY),
        g_object_uv_offset[iReal]);
}

void RotateMatrixX(long iObj, float fDegrees) {
    long iReal = g_object_redirects[iObj];
    g_object_local_to_world_matrix[iReal] = HMM_MultiplyMat4(
        HMM_Rotate(fDegrees, HMM_Vec3(1.0f, 0.0f, 0.0f)),
        g_object_local_to_world_matrix[iReal]);
}

void RotateMatrixY(long iObj, float fDegrees) {
    long iReal = g_object_redirects[iObj];
    g_object_local_to_world_matrix[iReal] = HMM_MultiplyMat4(
        HMM_Rotate(fDegrees, HMM_Vec3(0.0f, 1.0f, 0.0f)),
        g_object_local_to_world_matrix[iReal]);
}

void RotateMatrixZ(long iObj, float fDegrees) {
    long iReal = g_object_redirects[iObj];
    g_object_local_to_world_matrix[iReal] = HMM_MultiplyMat4(
        HMM_Rotate(fDegrees, HMM_Vec3(0.0f, 0.0f, 1.0f)),
        g_object_local_to_world_matrix[iReal]);
}

void MoveMeshToFront(long o1) {
    for(long iSwap = g_object_redirects[o1] - 1; iSwap >= 0; --iSwap) {
        SwapObjects(iSwap, iSwap + 1);
    }
}

void MoveMeshToBack(long o1) {
    for(long iSwap = g_object_redirects[o1] + 1; iSwap < g_object_count; ++iSwap) {
        SwapObjects(iSwap, iSwap - 1);
    }
}

static void SwapLong(long* l1, long* l2) {
    long iSwap = *l1;
    *l1 = *l2;
    *l2 = iSwap;
}

static void SwapObjects(long o1, long o2) {
    long iRealO1 = o1;
    long iRealO2 = o2;

    hmm_mat4 mSwap = g_object_local_to_world_matrix[iRealO1];
    g_object_local_to_world_matrix[iRealO1] = g_object_local_to_world_matrix[iRealO2];
    g_object_local_to_world_matrix[iRealO2] = mSwap;

    hmm_vec2 temp_uv_offset = g_object_uv_offset[iRealO1];
    g_object_uv_offset[iRealO1] = g_object_uv_offset[iRealO2];
    g_object_uv_offset[iRealO2] = temp_uv_offset;

    SwapLong(&g_object_vertex_start_index[iRealO1], &g_object_vertex_start_index[iRealO2]);
    SwapLong(&g_object_vertex_count[iRealO1], &g_object_vertex_count[iRealO2]);
    SwapLong(&g_object_texture_index[iRealO1], &g_object_texture_index[iRealO2]);
    SwapLong(&g_object_is_visible[iRealO1], &g_object_is_visible[iRealO2]);

    SwapLong(&g_object_redirects[SurfaceObject(o1)], &g_object_redirects[SurfaceObject(o2)]);
}

void Clear3dData(void) {
    for(uint32_t iLoop = 0; iLoop < kERROR_IMAGE_WIDTH * kERROR_IMAGE_HEIGHT; ++iLoop) {
        ((uint32_t*)&g_error_image_data[0][0][0])[iLoop] = 0x7FFF00FF;  // AABBGGRR
    }

    for(int iLoop = 0; iLoop < kMAX_TEXTURES; ++iLoop) {
        if(g_textures[iLoop].id != SG_INVALID_ID) {
            sg_destroy_image(g_textures[iLoop]);
        }

        g_textures[iLoop].id = SG_INVALID_ID;
    }

    g_object_count = 0;

    for(int iLoop = 0; iLoop < kMAX_OBJECTS; ++iLoop) {
        g_object_redirects[iLoop] = -1;
        g_object_uv_offset[iLoop] = (const hmm_vec2){ 0 };
    }

    g_vertices_to_load_count = 0;
}

void LoadTexture(int iTex, char* sFile, long image_type, int is_alpha_blend_enabled) {
    g_texture_is_alpha_blend_enabled[iTex] = is_alpha_blend_enabled;
    stbsp_snprintf(g_texture_filename[iTex], sizeof(g_texture_filename[iTex]), "%s", sFile);
    g_texture_is_color_key_alpha_enabled[iTex] = image_type == 1 ? 1 : 0;

    int width = 0, height = 0, channels_in_file;
    unsigned char* image_data = stbi_load(sFile, &width, &height, &channels_in_file, 4);
    bool load_was_successful = image_data != NULL;

    if(load_was_successful) {
        if(image_type == 1) {
            // Color key alpha, on 0xFFFFFFFF
            for(int y = 0; y < height; ++y) {
                for(int x = 0; x < width; ++x) {
                    if(*((uint32_t*)&image_data[y * width * 4 + x * 4 + 0]) == 0xFFFFFFFF) {
                        image_data[y * width * 4 + x * 4 + 3] = 0x0;
                    }
                }
            }
        }
    } else {
        width = kERROR_IMAGE_WIDTH;
        height = kERROR_IMAGE_HEIGHT;
        image_data = &g_error_image_data[0][0][0];

        // TODO: Error handling
        const char* error_message = stbi_failure_reason();
        debug_log("Failed to load image file \"%s\": %s\ndefault texture loaded instead", sFile, error_message);
    }

    sg_image_desc image_desc = { 0 };
    image_desc.width = width;
    image_desc.height = height;
    image_desc.pixel_format = SG_PIXELFORMAT_RGBA8;
    // TODO: Diff mipmap level based on iType. 0: full set, 1: only one. Probably have to manually do the resize for each mip level. Use stb_image_resize.h?
    image_desc.min_filter = SG_FILTER_LINEAR;
    image_desc.mag_filter = SG_FILTER_LINEAR;
    image_desc.content.subimage[0][0].ptr = image_data;
    image_desc.content.subimage[0][0].size = width * height * 4;

    g_textures[iTex] = sg_make_image(&image_desc);

    if(g_textures[iTex].id == SG_INVALID_ID) {
        FatalError("Error unlocking texture data");  // TODO: Read back error info
    }

    if(load_was_successful) {
        stbi_image_free(image_data);
    }
}

void ChangeMesh(long iMesh, long iNewMesh) {
    long iObjectToCopy = g_object_redirects[iNewMesh];
    long iRealMesh = g_object_redirects[iMesh];
    g_object_vertex_start_index[iRealMesh] = g_object_vertex_start_index[iObjectToCopy];
    g_object_vertex_count[iRealMesh] = g_object_vertex_count[iObjectToCopy];
}

void CopyObject(long iObject, long* iNum) {
    long iObjectToCopy = g_object_redirects[iObject];
    long iPlace = -1;

    for(int iLoop = 0; iLoop < kMAX_OBJECTS && iPlace == -1; ++iLoop) {
        if(g_object_redirects[iLoop] == -1) {
            iPlace = iLoop;
        }
    }

    if(iPlace == -1) {
        iPlace = 0;
        boxerShow("Too many objects!", "Jumpman Zero", BoxerStyleError, BoxerButtonsOK);
    }

    *iNum = iPlace;
    g_object_redirects[iPlace] = g_object_count;

    g_object_vertex_start_index[g_object_count] = g_object_vertex_start_index[iObjectToCopy];
    g_object_vertex_count[g_object_count] = g_object_vertex_count[iObjectToCopy];

    SetObjectData(*iNum, 0, 0);
    IdentityMatrix(*iNum);

    ++g_object_count;
}

void CreateObject(long* iParams, long iCount, long* iNum) {
    *iNum = g_object_count;
    g_object_redirects[g_object_count] = g_object_count;
    g_object_vertex_start_index[g_object_count] = g_vertices_to_load_count;
    g_object_vertex_count[g_object_count] = iCount;

    SetObjectData(g_object_count, 0, 0);
    IdentityMatrix(g_object_count);

    for(int iPlace = 0; iPlace < iCount; ++iPlace) {
        g_vertices_to_load[g_vertices_to_load_count].x = iParams[iPlace * 9 + 0] / 256.0f;
        g_vertices_to_load[g_vertices_to_load_count].y = iParams[iPlace * 9 + 1] / 256.0f;
        g_vertices_to_load[g_vertices_to_load_count].z = iParams[iPlace * 9 + 2] / 256.0f;
        g_vertices_to_load[g_vertices_to_load_count].nx = iParams[iPlace * 9 + 3] / 256.0f;
        g_vertices_to_load[g_vertices_to_load_count].ny = iParams[iPlace * 9 + 4] / 256.0f;
        g_vertices_to_load[g_vertices_to_load_count].nz = iParams[iPlace * 9 + 5] / 256.0f;
        g_vertices_to_load[g_vertices_to_load_count].tu = iParams[iPlace * 9 + 7] / 256.0f;
        g_vertices_to_load[g_vertices_to_load_count].tv = iParams[iPlace * 9 + 8] / 256.0f;

        ++g_vertices_to_load_count;
    }

    ++g_object_count;
}

size_t CreateMesh(MeshVertex* vertices, size_t vertex_count, long texture_index, bool is_visible) {
    size_t result = g_object_count;

    g_object_redirects[g_object_count] = g_object_count;
    g_object_vertex_start_index[g_object_count] = g_vertices_to_load_count;
    g_object_vertex_count[g_object_count] = (long)vertex_count;

    SetObjectData(g_object_count, texture_index, is_visible ? 1 : 0);
    IdentityMatrix(g_object_count);

    for(size_t index = 0; index < vertex_count; ++index) {
        g_vertices_to_load[g_vertices_to_load_count] = vertices[index];
        ++g_vertices_to_load_count;
    }

    ++g_object_count;

    return result;
}

void SetObjectData(long iNum, long iTexture, int iVisible) {
    long iRNum = g_object_redirects[iNum];
    g_object_texture_index[iRNum] = iTexture;
    g_object_is_visible[iRNum] = iVisible;
    g_object_uv_offset[iRNum] = (const hmm_vec2){ 0 };  // TODO: Expose this separately?
}

void SetObjectTextureIndex(long iNum, long texture_index) {
    long iRNum = g_object_redirects[iNum];
    g_object_texture_index[iRNum] = texture_index;
}

void SetObjectIsVisible(long iNum, bool is_visible) {
    long iRNum = g_object_redirects[iNum];
    g_object_is_visible[iRNum] = is_visible ? 1 : 0;
}

void ResizeViewport(int width, int height) {
    g_backbuffer_width = width;
    g_backbuffer_height = height;
}

void Reset3d(void) {
    // TODO: Is there any case where we need to reset the context? I think this is a relic from D3D9. Do we might need to handle suspend/resume, ala UWP though?
}

bool InitializeAll(void) {
    if(!init_3d()) {
        return false;
    }

    init_scene();

    return true;
}

void Begin3dLoad(void) {
    if(g_vertices_to_load) {
        free(g_vertices_to_load);
        g_vertices_to_load = NULL;
    }

    g_vertices_to_load = (MeshVertex*)malloc(kMAX_VERTICES * sizeof(MeshVertex));

    if(!g_vertices_to_load) {
        FatalError("Failed to allocate enough memory in order to load model's vertex data");
    }
}

void EndAndCommit3dLoad(void) {
    sg_update_buffer(g_draw_state.vertex_buffers[0], g_vertices_to_load, kMAX_VERTICES * sizeof(MeshVertex));

    if(g_vertices_to_load) {
        free(g_vertices_to_load);
        g_vertices_to_load = NULL;
    }
}

void DoCleanUp(void) {
    kill_scene();
    kill_3d();
}

static long init_3d(void) {
    for(int iLoop = 0; iLoop < kMAX_TEXTURES; ++iLoop) {
        g_textures[iLoop].id = SG_INVALID_ID;
    }

    for(int iLoop = 0; iLoop < kMAX_OBJECTS; ++iLoop) {
        g_object_redirects[iLoop] = -1;
        g_object_uv_offset[iLoop] = (const hmm_vec2){ 0 };
    }

    sg_desc desc = {0};
    sg_setup(&desc);

    if(!sg_isvalid()) {
        return 0;
    }

    return 1;
}

static void kill_3d(void) {
    sg_shutdown();
}

void SetFog(float iFogStart, float iFogEnd, uint8_t red, uint8_t green, uint8_t blue) {
    if(iFogStart == 0 && iFogEnd == 0) {
        g_is_fog_enabled = false;
    } else {
        g_is_fog_enabled = true;
        g_fog_color = (const hmm_vec3){ { red / 255.0f, green / 255.0f, blue / 255.0f } };
        g_fog_start = iFogStart;
        g_fog_end = iFogEnd;
    }
}

void SetPerspective(float iCamX, float iCamY, float iCamZ, float iPoiX, float iPoiY, float iPoiZ) {
    g_world_to_view_matrix = HMM_LookAtLH(HMM_Vec3(iCamX, iCamY, iCamZ), HMM_Vec3(iPoiX, iPoiY, iPoiZ), HMM_Vec3(0.0f, 1.0f, 0.0f));
    g_camera_light.position = (const hmm_vec3){ { iCamX, iCamY + 10.0f, -200.0f } };
    g_camera_light.diffuse_color = (const hmm_vec3){ { 1.0f, 1.0f, 1.0f } };
    g_camera_light.ambient_color = (const hmm_vec3){ { 1.0f, 1.0f, 1.0f } };
}

static void init_scene(void) {
    g_camera_light = (const Light){ 0 };
    g_camera_light.diffuse_color = (const hmm_vec3){ { 1.0f, 1.0f, 1.0f } };
    g_camera_light.ambient_color = (const hmm_vec3){ { 1.0f, 1.0f, 1.0f } };
    g_camera_light.position = (const hmm_vec3){ { 80.0f, 100.0f, -200.0f } };
    g_camera_light.range = 1000.0f;

    g_scene_ambient_color = (const hmm_vec3){ { 1.0f / 255.0f, 1.0f / 255.0f, 1.0f / 255.0f } };

    SetPerspective(80.0f, 90.0f, -145.0f, 80.0f, 59.0f, 0.0f);

    g_view_to_projection_matrix = HMM_PerspectiveLH_NO(45.0f, 640.0f / 480.0f, 1.0f, 300.0f);  // Fixed aspect ratio. Will be letterboxed elsewhere

    g_global_material = (const Material){ 0 };
    g_global_material.ambient_tint = (const hmm_vec3){ { 0.5f, 0.5f, 0.5f } };
    g_global_material.diffuse_tint = (const hmm_vec3){ { 0.5f, 0.5f, 0.5f } };

    sg_buffer_desc vbuf_desc = { 0 };
    vbuf_desc.usage = SG_USAGE_STREAM;
    vbuf_desc.size = kMAX_VERTICES * sizeof(MeshVertex);

    g_draw_state = (const sg_draw_state){ 0 };
    g_draw_state.vertex_buffers[0] = sg_make_buffer(&vbuf_desc);

    sg_shader_desc shd_desc = { 0 };

    sg_shader_uniform_block_desc* ub0 = &shd_desc.vs.uniform_blocks[0];
    ub0->size = sizeof(VertexShaderParams);
    ub0->uniforms[0].name = "local_to_world_matrix";
    ub0->uniforms[0].type = SG_UNIFORMTYPE_MAT4;
    ub0->uniforms[1].name = "local_to_view_matrix";
    ub0->uniforms[1].type = SG_UNIFORMTYPE_MAT4;
    ub0->uniforms[2].name = "local_to_projection_matrix";
    ub0->uniforms[2].type = SG_UNIFORMTYPE_MAT4;
    ub0->uniforms[3].name = "transpose_world_to_local_matrix";
    ub0->uniforms[3].type = SG_UNIFORMTYPE_MAT4;
    ub0->uniforms[4].name = "uv_offset";
    ub0->uniforms[4].type = SG_UNIFORMTYPE_FLOAT2;

    shd_desc.vs.source =
        "#version 330\n"
        "\n"
        "in vec3 position;\n"
        "in vec3 normal;\n"
        "in vec2 texcoord0;\n"
        "\n"
        "out vec3 vs_world_position;\n"
        "out vec3 vs_view_position;\n"
        "out vec3 vs_unscaled_normal;\n"
        "out vec2 vs_uv;\n"
        "\n"
        "uniform mat4 local_to_world_matrix;\n"
        "uniform mat4 local_to_view_matrix;\n"
        "uniform mat4 local_to_projection_matrix;\n"
        "uniform mat4 transpose_world_to_local_matrix;\n"
        "uniform vec2 uv_offset;\n"
        "\n"
        "void main() {\n"
        "    vec4 pos = vec4(position, 1.0);\n"
        "    vs_world_position = vec3(local_to_world_matrix * pos);\n"
        "    vs_view_position = vec3(local_to_view_matrix * pos);\n"
        "    vs_unscaled_normal = normalize(vec3(transpose_world_to_local_matrix * vec4(normal, 0.0)));\n"
        "    vs_uv = texcoord0 + uv_offset;\n"
        "    gl_Position = local_to_projection_matrix * pos;\n"
        "}\n";

    shd_desc.fs.images[0].name = "tex";
    shd_desc.fs.images[0].type = SG_IMAGETYPE_2D;

    sg_shader_uniform_block_desc* fs_ub0 = &shd_desc.fs.uniform_blocks[0];
    fs_ub0->size = sizeof(FragmentShaderParams);
    fs_ub0->uniforms[0].name = "scene_ambient_color";
    fs_ub0->uniforms[0].type = SG_UNIFORMTYPE_FLOAT3;
    fs_ub0->uniforms[1].name = "material_ambient_tint";
    fs_ub0->uniforms[1].type = SG_UNIFORMTYPE_FLOAT3;
    fs_ub0->uniforms[2].name = "material_diffuse_tint";
    fs_ub0->uniforms[2].type = SG_UNIFORMTYPE_FLOAT3;
    fs_ub0->uniforms[3].name = "light_ambient_color";
    fs_ub0->uniforms[3].type = SG_UNIFORMTYPE_FLOAT3;
    fs_ub0->uniforms[4].name = "light_diffuse_color";
    fs_ub0->uniforms[4].type = SG_UNIFORMTYPE_FLOAT3;
    fs_ub0->uniforms[5].name = "light_position";
    fs_ub0->uniforms[5].type = SG_UNIFORMTYPE_FLOAT3;
    fs_ub0->uniforms[6].name = "light_range";
    fs_ub0->uniforms[6].type = SG_UNIFORMTYPE_FLOAT;
    fs_ub0->uniforms[7].name = "is_fog_enabled";
    fs_ub0->uniforms[7].type = SG_UNIFORMTYPE_FLOAT;
    fs_ub0->uniforms[8].name = "fog_color";
    fs_ub0->uniforms[8].type = SG_UNIFORMTYPE_FLOAT3;
    fs_ub0->uniforms[9].name = "fog_start";
    fs_ub0->uniforms[9].type = SG_UNIFORMTYPE_FLOAT;
    fs_ub0->uniforms[10].name = "fog_end";
    fs_ub0->uniforms[10].type = SG_UNIFORMTYPE_FLOAT;

    shd_desc.fs.source =
        "#version 330\n"
        "\n"
        "in vec3 vs_world_position;\n"
        "in vec3 vs_view_position;\n"
        "in vec3 vs_unscaled_normal;\n"
        "in vec2 vs_uv;\n"
        "\n"
        "out vec4 frag_color;\n"
        "\n"
        "uniform sampler2D tex;\n"
        "\n"
        "uniform vec3 scene_ambient_color;\n"
        "\n"
        "uniform vec3 material_ambient_tint;\n"
        "uniform vec3 material_diffuse_tint;\n"
        "\n"
        "uniform vec3 light_ambient_color;\n"
        "uniform vec3 light_diffuse_color;\n"
        "uniform vec3 light_position;\n"
        "uniform float light_range;\n"
        "\n"
        "uniform bool is_fog_enabled;\n"
        "uniform vec3 fog_color;\n"
        "uniform float fog_start;\n"
        "uniform float fog_end;\n"
        "\n"
        "void main() {\n"
        "    vec4 albedo = texture(tex, vs_uv);\n"
        "    float out_alpha = albedo.a;\n"
        "\n"
        "    vec3 ambient_color = material_ambient_tint * (scene_ambient_color + light_ambient_color);\n"
        "\n"
        "    vec3 diffuse_color = vec3(0.0);\n"
        "\n"
        "    if(length(light_position - vs_world_position) < light_range) {\n"
        "        vec3 light_direction = normalize(light_position - vs_world_position);\n"
        "        vec3 uninterpolated_normal = normalize(vs_unscaled_normal);\n"
        "        diffuse_color = material_diffuse_tint *\n"
        "            light_diffuse_color * max(dot(uninterpolated_normal, light_direction), 0.0);\n"
        "    }\n"
        "\n"
        "    vec3 out_color = (ambient_color + diffuse_color) * albedo.rgb;\n"
        "\n"
        "    if(is_fog_enabled) {\n"
        "        out_color = mix(fog_color, out_color, clamp((fog_end - vs_view_position.z) / (fog_end - fog_start), 0.0, 1.0));\n"
        "    }\n"
        "\n"
        "    frag_color = vec4(out_color, out_alpha);\n"
        "}\n";

    sg_shader shd = sg_make_shader(&shd_desc);

    sg_pipeline_desc pip_desc = { 0 };

    pip_desc.layout.buffers[0].stride = sizeof(MeshVertex);
    sg_vertex_attr_desc* attrs = pip_desc.layout.attrs;
    attrs[0].name = "position";
    attrs[0].format = SG_VERTEXFORMAT_FLOAT3;
    attrs[1].name = "normal";
    attrs[1].format = SG_VERTEXFORMAT_FLOAT3;
    attrs[2].name = "texcoord0";
    attrs[2].format = SG_VERTEXFORMAT_FLOAT2;

    pip_desc.shader = shd;

    pip_desc.depth_stencil.depth_compare_func = SG_COMPAREFUNC_LESS;
    pip_desc.depth_stencil.depth_write_enabled = true;
    pip_desc.rasterizer.face_winding = SG_FACEWINDING_CW;
    pip_desc.rasterizer.cull_mode = SG_CULLMODE_BACK;

    pip_desc.blend.enabled = true;
    pip_desc.blend.src_factor_rgb = SG_BLENDFACTOR_SRC_ALPHA;
    pip_desc.blend.dst_factor_rgb = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
    pip_desc.blend.color_write_mask = SG_COLORMASK_RGBA;

    g_draw_state.pipeline = g_transparent_pipline = sg_make_pipeline(&pip_desc);

    pip_desc.blend.enabled = false;
    g_opaque_pipline = sg_make_pipeline(&pip_desc);

    g_pass_action = (const sg_pass_action){ 0 };
    g_pass_action.colors[0].action = SG_ACTION_CLEAR;
    g_pass_action.colors[0].val[0] = 0.0f;
    g_pass_action.colors[0].val[1] = 0.0f;
    g_pass_action.colors[0].val[2] = 0.0f;
    g_pass_action.colors[0].val[3] = 1.0f;
}

static void kill_scene(void) {
    for(int iLoop = 0; iLoop < kMAX_TEXTURES; ++iLoop) {
        if(g_textures[iLoop].id != SG_INVALID_ID) {
            sg_destroy_image(g_textures[iLoop]);
            g_textures[iLoop].id = SG_INVALID_ID;
        }
    }
}

static void RenderObject(int object_index, long* previous_texture_index, VertexShaderParams* vs_params, bool* are_fs_params_applied, FragmentShaderParams* fs_params) {
    long current_texture_index = g_object_texture_index[object_index];

    if(*previous_texture_index != current_texture_index) {
        *previous_texture_index = current_texture_index;
        g_draw_state.fs_images[0] = g_textures[current_texture_index];
        sg_apply_draw_state(&g_draw_state);
    }

    vs_params->local_to_world_matrix = g_object_local_to_world_matrix[object_index];
    vs_params->local_to_view_matrix = HMM_MultiplyMat4(g_world_to_view_matrix, g_object_local_to_world_matrix[object_index]);
    vs_params->local_to_projection_matrix = HMM_MultiplyMat4(
        HMM_MultiplyMat4(g_view_to_projection_matrix, g_world_to_view_matrix),
        g_object_local_to_world_matrix[object_index]);
    vs_params->transpose_world_to_local_matrix = HMM_Transpose(JM_HMM_Inverse(g_object_local_to_world_matrix[object_index]));
    vs_params->uv_offset = g_object_uv_offset[object_index];
    sg_apply_uniform_block(SG_SHADERSTAGE_VS, 0, vs_params, sizeof(*vs_params));

    if(!*are_fs_params_applied) {
        sg_apply_uniform_block(SG_SHADERSTAGE_FS, 0, fs_params, sizeof(*fs_params));
        *are_fs_params_applied = true;
    }

    sg_draw((int)g_object_vertex_start_index[object_index], (int)g_object_vertex_count[object_index], 1);
}

void Render(void) {
    sg_begin_default_pass(&g_pass_action, g_backbuffer_width, g_backbuffer_height);

    float backbuffer_aspect_ratio = (float)g_backbuffer_width / g_backbuffer_height;
    const float target_aspect_ratio = 640.0f / 480.0f;

    if(backbuffer_aspect_ratio > target_aspect_ratio) {
        float width_scale = target_aspect_ratio / backbuffer_aspect_ratio;
        float border_half_width = (g_backbuffer_width - width_scale * g_backbuffer_width) / 2.0f;
        sg_apply_viewport((int)border_half_width, 0, (int)(g_backbuffer_width - (border_half_width * 2.0f)), g_backbuffer_height, true);
    } else {
        float height_scale = backbuffer_aspect_ratio / target_aspect_ratio;
        float border_half_height = (g_backbuffer_height - height_scale * g_backbuffer_height) / 2.0f;
        sg_apply_viewport(0, (int)border_half_height, g_backbuffer_width, (int)(g_backbuffer_height - (border_half_height * 2.0f)), true);
    }

    VertexShaderParams vs_params;
    FragmentShaderParams fs_params;
    fs_params.scene_ambient_color = g_scene_ambient_color;
    fs_params.material = g_global_material;
    fs_params.light = g_camera_light;
    fs_params.is_fog_enabled = g_is_fog_enabled ? 1.0f : 0.0f;
    fs_params.fog_color = g_fog_color;
    fs_params.fog_start = g_fog_start;
    fs_params.fog_end = g_fog_end;

    // Draw opaque
    g_draw_state.pipeline = g_opaque_pipline;

    long previous_texture_index = -1;
    bool are_fs_params_applied = false;  // These are currently set globally, so don't need to be set for every object

    for(long object_index = 0; object_index < g_object_count; ++object_index) {
        if(g_object_is_visible[object_index] && !g_texture_is_alpha_blend_enabled[g_object_texture_index[object_index]]) {
            RenderObject(object_index, &previous_texture_index, &vs_params, &are_fs_params_applied, &fs_params);
        }
    }

    // Draw transparent
    g_draw_state.pipeline = g_transparent_pipline;

    previous_texture_index = -1;
    are_fs_params_applied = false;

    for(long object_index = 0; object_index < g_object_count; ++object_index) {
        if(g_object_is_visible[object_index] && g_texture_is_alpha_blend_enabled[g_object_texture_index[object_index]]) {
            RenderObject(object_index, &previous_texture_index, &vs_params, &are_fs_params_applied, &fs_params);
        }
    }

    sg_end_pass();
    sg_commit();
}

static void FatalError(const char* error_msg) {
    kill_scene();
    kill_3d();
    boxerShow(error_msg, "Jumpman Zero", BoxerStyleError, BoxerButtonsOK);
}
