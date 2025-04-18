#include <math.h>
#include "glad/glad.h"
#define SOKOL_IMPL
#define SOKOL_GLCORE33
#define SOKOL_EXTERNAL_GL_LOADER
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

#include "shader.h"

#include "boxer/boxer.h"
#include "Basic3d.h"
#include "logging.h"

#define kMAX_TEXTURES ((size_t)30)
#define kMAX_TRANSFORMS ((size_t)1200)
#define kMAX_MESHES ((size_t)600)
#define kMAX_VERTICES ((size_t)110000)

typedef struct Light {
    hmm_vec3 ambient_color;
    hmm_vec3 diffuse_color;
    hmm_vec3 position;
    float range;
} Light;

typedef struct Material {
    hmm_vec3 ambient_tint;
    hmm_vec3 diffuse_tint;
} Material;

static void FatalError_(const char* error_msg);

static int g_backbuffer_width;
static int g_backbuffer_height;
static sg_bindings g_bindings = { 0 };
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
static bool g_texture_is_alpha_blend_enabled[kMAX_TEXTURES];
static bool g_texture_is_color_key_alpha_enabled[kMAX_TEXTURES];  // TODO: This is just for debugging. ifdef it out for release builds

#define kERROR_IMAGE_WIDTH ((size_t)32)
#define kERROR_IMAGE_HEIGHT ((size_t)32)
static unsigned char g_error_image_data[kERROR_IMAGE_HEIGHT][kERROR_IMAGE_WIDTH][4];

static hmm_mat4 g_world_to_view_matrix;
static hmm_mat4 g_world_to_view_matrix_previous;
static hmm_mat4 g_view_to_projection_matrix;
// These aren't necessarily interpolated, but if not then will fall back to the correct non-interpolated matrix for this frame
static hmm_mat4 g_interpolated_world_to_view_matrix;
static hmm_mat4 g_interpolated_world_to_projection_matrix;
static bool g_camera_animation_is_continuous = false;

static int g_vertices_to_load_count;
static MeshVertex* g_vertices_to_load = NULL;

static int g_transform_count = 0;

static hmm_vec3 g_transform_translations[kMAX_TRANSFORMS];
static hmm_quaternion g_transform_rotations[kMAX_TRANSFORMS];
static hmm_vec3 g_transform_scales[kMAX_TRANSFORMS];
static hmm_vec3 g_transform_translations_previous[kMAX_TRANSFORMS];
static hmm_quaternion g_transform_rotations_previous[kMAX_TRANSFORMS];
static hmm_vec3 g_transform_scales_previous[kMAX_TRANSFORMS];
static int g_transform_parent_indices[kMAX_TRANSFORMS];
static int g_transform_parent_handles[kMAX_TRANSFORMS];
static bool g_transform_parent_is_camera[kMAX_TRANSFORMS];
// TODO: Figure out how to get children to be next to parents, for better cache performance

static int g_transform_handles[kMAX_TRANSFORMS];
static int g_transform_handle_next_free_indices[kMAX_TRANSFORMS];
static int g_transform_handle_first_free_index;

static int g_mesh_count = 0;

static int g_mesh_vertex_start_indices[kMAX_MESHES];
static int g_mesh_vertex_counts[kMAX_MESHES];
static int g_mesh_texture_indices[kMAX_MESHES];
static bool g_mesh_is_visible[kMAX_MESHES];
static hmm_vec2 g_mesh_uv_offsets[kMAX_MESHES];
static bool g_mesh_is_visible_previous[kMAX_MESHES];
static hmm_vec2 g_mesh_uv_offsets_previous[kMAX_MESHES];
static bool g_mesh_animation_is_continuous[kMAX_MESHES];
static int g_mesh_transform_indices[kMAX_MESHES];

static int g_mesh_handles[kMAX_MESHES];
static int g_mesh_handle_next_free_indices[kMAX_MESHES];
static int g_mesh_handle_first_free_index;

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

static hmm_vec3 HMM_LerpVec3(hmm_vec3 lhs, hmm_vec3 rhs, float time) {
    return HMM_AddVec3(
        lhs,
        HMM_MultiplyVec3f(
            HMM_SubtractVec3(rhs, lhs),
            time));
}

static hmm_vec2 HMM_LerpVec2(hmm_vec2 lhs, hmm_vec2 rhs, float time) {
    return HMM_AddVec2(
        lhs,
        HMM_MultiplyVec2f(
            HMM_SubtractVec2(rhs, lhs),
            time));
}

// End: helpers that weren't included in HandmadeMath (yet). Replace if they are added


void Clear3dData(void) {
    for(uint32_t pixel_index = 0; pixel_index < kERROR_IMAGE_WIDTH * kERROR_IMAGE_HEIGHT; ++pixel_index) {
        ((uint32_t*)&g_error_image_data[0][0][0])[pixel_index] = 0x7FFF00FF;  // AABBGGRR
    }

    for(int texture_index = 0; texture_index < kMAX_TEXTURES; ++texture_index) {
        if(g_textures[texture_index].id != SG_INVALID_ID) {
            sg_destroy_image(g_textures[texture_index]);
        }

        g_textures[texture_index].id = SG_INVALID_ID;
    }

    g_transform_count = 0;

    for(int transform_index = 0; transform_index < kMAX_TRANSFORMS; ++transform_index) {
        g_transform_translations[transform_index] = (hmm_vec3){ 0 };
        g_transform_rotations[transform_index] = (hmm_quaternion){ .X = 0.0f, .Y = 0.0f, .Z = 0.0f, .W = 1.0f };
        g_transform_scales[transform_index] = (hmm_vec3){ .X = 1.0f, .Y = 1.0f, .Z = 1.0f };
        g_transform_translations_previous[transform_index] = (hmm_vec3){ 0 };
        g_transform_rotations_previous[transform_index] = (hmm_quaternion){ .X = 0.0f, .Y = 0.0f, .Z = 0.0f, .W = 1.0f };
        g_transform_scales_previous[transform_index] = (hmm_vec3){ .X = 1.0f, .Y = 1.0f, .Z = 1.0f };
        g_transform_parent_indices[transform_index] = -1;
        g_transform_parent_handles[transform_index] = -1;
        g_transform_parent_is_camera[transform_index] = false;
        g_transform_handles[transform_index] = -1;
        g_transform_handle_next_free_indices[transform_index] = transform_index + 1;
    }

    g_transform_handle_next_free_indices[kMAX_TRANSFORMS - 1] = -1;
    g_transform_handle_first_free_index = 0;

    g_mesh_count = 0;

    for(int mesh_index = 0; mesh_index < kMAX_MESHES; ++mesh_index) {
        g_mesh_uv_offsets[mesh_index] = (const hmm_vec2){ 0 };
        g_mesh_animation_is_continuous[mesh_index] = false;
        g_mesh_transform_indices[mesh_index] = -1;
        // TODO: Set visibility?
        g_mesh_handles[mesh_index] = -1;
        g_mesh_handle_next_free_indices[mesh_index] = mesh_index + 1;
    }

    g_mesh_handle_next_free_indices[kMAX_MESHES - 1] = -1;
    g_mesh_handle_first_free_index = 0;

    g_vertices_to_load_count = 0;
}

void LoadTexture(int texture_index, char* sFile, int image_type, bool is_alpha_blend_enabled) {
    g_texture_is_alpha_blend_enabled[texture_index] = is_alpha_blend_enabled;
    stbsp_snprintf(g_texture_filename[texture_index], sizeof(g_texture_filename[texture_index]), "%s", sFile);
    g_texture_is_color_key_alpha_enabled[texture_index] = image_type == 1;

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
    // TODO: Diff mipmap level based on image_type. 0: full set, 1: only one. Probably have to manually do the resize for each mip level. Use stb_image_resize.h?
    image_desc.min_filter = SG_FILTER_LINEAR;
    image_desc.mag_filter = SG_FILTER_LINEAR;
    image_desc.data.subimage[0][0].ptr = image_data;
    image_desc.data.subimage[0][0].size = width * height * 4;

    g_textures[texture_index] = sg_make_image(&image_desc);

    if(g_textures[texture_index].id == SG_INVALID_ID) {
        FatalError_("Error unlocking texture data");  // TODO: Read back error info
    }

    if(load_was_successful) {
        stbi_image_free(image_data);
    }
}

static bool init_3d_(void) {
    for(int texture_index = 0; texture_index < kMAX_TEXTURES; ++texture_index) {
        g_textures[texture_index].id = SG_INVALID_ID;
    }

    for(int mesh_index = 0; mesh_index < kMAX_MESHES; ++mesh_index) {
        g_mesh_handles[mesh_index] = -1;
        g_mesh_uv_offsets[mesh_index] = (const hmm_vec2){ 0 };
        g_mesh_animation_is_continuous[mesh_index] = false;
        // TODO: Set visibility?
    }

    sg_desc desc = {0};
    sg_setup(&desc);

    if(!sg_isvalid()) {
        return false;
    }

    return true;
}

static void init_scene_(void) {
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

    g_bindings = (const sg_bindings){ 0 };
    g_bindings.vertex_buffers[0] = sg_make_buffer(&vbuf_desc);

    sg_shader shd = sg_make_shader(main_shader_shader_desc(SG_BACKEND_GLCORE33));

    sg_pipeline_desc pip_desc = { 0 };

    pip_desc.layout.buffers[0].stride = sizeof(MeshVertex);
    sg_vertex_attr_desc* attrs = pip_desc.layout.attrs;
    attrs[0].format = SG_VERTEXFORMAT_FLOAT3;
    attrs[1].format = SG_VERTEXFORMAT_FLOAT3;
    attrs[2].format = SG_VERTEXFORMAT_FLOAT2;

    pip_desc.shader = shd;

    pip_desc.depth.compare = SG_COMPAREFUNC_LESS;
    pip_desc.depth.write_enabled = false;
    pip_desc.face_winding = SG_FACEWINDING_CW;
    pip_desc.cull_mode = SG_CULLMODE_BACK;

    pip_desc.colors[0].blend.enabled = true;
    pip_desc.colors[0].blend.src_factor_rgb = SG_BLENDFACTOR_SRC_ALPHA;
    pip_desc.colors[0].blend.dst_factor_rgb = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
    pip_desc.colors[0].write_mask = SG_COLORMASK_RGBA;

    g_transparent_pipline = sg_make_pipeline(&pip_desc);

    pip_desc.depth.write_enabled = true;
    pip_desc.colors[0].blend.enabled = false;
    g_opaque_pipline = sg_make_pipeline(&pip_desc);

    g_pass_action = (const sg_pass_action){ 0 };
    g_pass_action.colors[0].action = SG_ACTION_CLEAR;
    g_pass_action.colors[0].value.r = 0.0f;
    g_pass_action.colors[0].value.g = 0.0f;
    g_pass_action.colors[0].value.b = 0.0f;
    g_pass_action.colors[0].value.a = 1.0f;
}

bool InitializeAll(void) {
    if(!init_3d_()) {
        return false;
    }

    init_scene_();

    return true;
}

void Begin3dLoad(void) {
    if(g_vertices_to_load) {
        free(g_vertices_to_load);
        g_vertices_to_load = NULL;
    }

    g_vertices_to_load = (MeshVertex*)malloc(kMAX_VERTICES * sizeof(MeshVertex));

    if(!g_vertices_to_load) {
        FatalError_("Failed to allocate enough memory in order to load model's vertex data");
    }
}

void EndAndCommit3dLoad(void) {
    sg_update_buffer(g_bindings.vertex_buffers[0], &(sg_range){ g_vertices_to_load, kMAX_VERTICES * sizeof(MeshVertex) });

    if(g_vertices_to_load) {
        free(g_vertices_to_load);
        g_vertices_to_load = NULL;
    }
}

void Reset3d(void) {
    // TODO: Is there any case where we need to reset the context? I think this is a relic from D3D9. Do we might need to handle suspend/resume, ala UWP though?
}

static void kill_scene_(void) {
    for(int texture_index = 0; texture_index < kMAX_TEXTURES; ++texture_index) {
        if(g_textures[texture_index].id != SG_INVALID_ID) {
            sg_destroy_image(g_textures[texture_index]);
            g_textures[texture_index].id = SG_INVALID_ID;
        }
    }
}

static void kill_3d_(void) {
    sg_shutdown();
}

void DoCleanUp(void) {
    kill_scene_();
    kill_3d_();
}


// Returns -1 if handle not valid
static int GetMeshIndexFromHandle_(int mesh_handle_index) {
    assert(mesh_handle_index >= 0);
    assert(mesh_handle_index < kMAX_MESHES);

    int mesh_index = -1;
    if(mesh_handle_index >= 0 && mesh_handle_index < kMAX_MESHES) {
        int temp_mesh_index = g_mesh_handles[mesh_handle_index];
        assert(temp_mesh_index >= 0);
        assert(temp_mesh_index < g_mesh_count);

        if(temp_mesh_index >= 0 && temp_mesh_index < g_mesh_count) {
            mesh_index = temp_mesh_index;
        }
    }

    return mesh_index;
}

// Returns -1 if handle not valid
static int GetTransformIndexFromHandle_(int transform_handle_index) {
    assert(transform_handle_index >= 0);
    assert(transform_handle_index < kMAX_TRANSFORMS);

    int transform_index = -1;
    if(transform_handle_index >= 0 && transform_handle_index < kMAX_MESHES) {
        int temp_transform_index = g_transform_handles[transform_handle_index];
        assert(temp_transform_index >= 0);
        assert(temp_transform_index < g_transform_count);

        if(temp_transform_index >= 0 && temp_transform_index < g_transform_count) {
            transform_index = temp_transform_index;
        }
    }

    return transform_index;
}

int TransformCreate(void) {
    assert(g_transform_count < kMAX_TRANSFORMS);
    assert(g_transform_handle_first_free_index != -1);
    int new_transform_handle_index = -1;

    if(g_transform_count < kMAX_TRANSFORMS && g_transform_handle_first_free_index != -1) {
        int new_transform_index = g_transform_count;
        g_transform_translations[new_transform_index] = (hmm_vec3){ 0 };
        g_transform_rotations[new_transform_index] = (hmm_quaternion){ .X = 0.0f, .Y = 0.0f, .Z = 0.0f, .W = 1.0f };
        g_transform_scales[new_transform_index] = (hmm_vec3){ .X = 1.0f, .Y = 1.0f, .Z = 1.0f };
        g_transform_translations_previous[new_transform_index] = (hmm_vec3){ 0 };
        g_transform_rotations_previous[new_transform_index] = (hmm_quaternion){ .X = 0.0f, .Y = 0.0f, .Z = 0.0f, .W = 1.0f };
        g_transform_scales_previous[new_transform_index] = (hmm_vec3){ .X = 1.0f, .Y = 1.0f, .Z = 1.0f };
        g_transform_parent_indices[new_transform_index] = -1;
        g_transform_parent_handles[new_transform_index] = -1;
        g_transform_parent_is_camera[new_transform_index] = false;
        ++g_transform_count;

        new_transform_handle_index = g_transform_handle_first_free_index;
        g_transform_handles[new_transform_handle_index] = new_transform_index;
        g_transform_handle_first_free_index = g_transform_handle_next_free_indices[g_transform_handle_first_free_index];
    } // TODO: Else log?

    return new_transform_handle_index;
}

void TransformDelete(int deleting_transform_handle_index) {
    assert(g_transform_count > 0);

    if(g_transform_count > 0) {
        int deleting_transform_index = GetTransformIndexFromHandle_(deleting_transform_handle_index);
        int last_transform_index = g_transform_count - 1;

        if(deleting_transform_index != -1) {
            if(g_transform_count > 1 && deleting_transform_index < last_transform_index) {
                // Overwrite the transform being deleted with the last transform
                g_transform_translations[deleting_transform_index] = g_transform_translations[last_transform_index];
                g_transform_rotations[deleting_transform_index] = g_transform_rotations[last_transform_index];
                g_transform_scales[deleting_transform_index] = g_transform_scales[last_transform_index];
                g_transform_translations_previous[deleting_transform_index] = g_transform_translations_previous[last_transform_index];
                g_transform_rotations_previous[deleting_transform_index] = g_transform_rotations_previous[last_transform_index];
                g_transform_scales_previous[deleting_transform_index] = g_transform_scales_previous[last_transform_index];
                g_transform_parent_indices[deleting_transform_index] = g_transform_parent_indices[last_transform_index];
                g_transform_parent_handles[deleting_transform_index] = g_transform_parent_handles[last_transform_index];
                g_transform_parent_is_camera[deleting_transform_index] = g_transform_parent_is_camera[last_transform_index];

                // Redirect all meshes that pointed at last transform to its new location
                for(int mesh_index = 0; mesh_index < g_mesh_count; ++mesh_index) {
                    if(g_mesh_transform_indices[mesh_index] == last_transform_index) {
                        g_mesh_transform_indices[mesh_index] = deleting_transform_index;
                    }
                }

                // Redirect all transforms that had the last transform as their parent to its new location
                for(int child_transform_index = 0; child_transform_index < g_transform_count; ++child_transform_index) {
                    if(g_transform_parent_indices[child_transform_index] == last_transform_index) {
                        g_transform_parent_indices[child_transform_index] = deleting_transform_index;
                    }
                }

                // Redirect all handles that pointed at the last transform to its new location
                for(int handle_index = 0; handle_index < kMAX_TRANSFORMS; ++handle_index) {
                    if(g_transform_handles[handle_index] == last_transform_index) {
                        g_transform_handles[handle_index] = deleting_transform_index;
                    }
                }
            }

            g_transform_handle_next_free_indices[deleting_transform_handle_index] = g_transform_handle_first_free_index;
            g_transform_handle_first_free_index = deleting_transform_handle_index;

            --g_transform_count;
        } // TODO: Else log?
    } // TODO: Else log?
}

int TransformGetParent(int transform_handle_index) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);
    int result = -1;

    if(transform_index != -1) {
        result = g_transform_parent_handles[transform_index];
    } // TODO: Else log?

    return result;
}

void TransformSetParent(int transform_handle_index, int new_parent_transform_handle_index) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);
    int new_parent_transform_index = GetTransformIndexFromHandle_(new_parent_transform_handle_index);

    if(transform_index != -1 && new_parent_transform_index != -1) {
        // TODO: Detect cycle, assert, and break the cycle in non-debug build
        g_transform_parent_indices[transform_index] = new_parent_transform_index;
        g_transform_parent_handles[transform_index] = new_parent_transform_handle_index;
        g_transform_parent_is_camera[transform_index] = false;
    } // TODO: Else log?
}

void TransformClearParent(int transform_handle_index) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);

    if(transform_index != -1) {
        g_transform_parent_indices[transform_index] = -1;
        g_transform_parent_handles[transform_index] = -1;
        g_transform_parent_is_camera[transform_index] = false;
    } // TODO: Else log?
}

bool TransformGetParentIsCamera(int transform_handle_index) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);
    bool result = false;

    if(transform_index != -1) {
        result = g_transform_parent_is_camera[transform_index];
    } // TODO: Else log?

    return result;
}

void TransformSetParentIsCamera(int transform_handle_index, bool is_parent_camera) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);

    if(transform_index != -1) {
        if(is_parent_camera) {
            g_transform_parent_indices[transform_index] = -1;
            g_transform_parent_handles[transform_index] = -1;
        }

        g_transform_parent_is_camera[transform_index] = is_parent_camera;
    } // TODO: Else log?
}

int MeshGetTransform(int mesh_handle_index) {
    int mesh_index = GetMeshIndexFromHandle_(mesh_handle_index);
    int result = -1;

    if(mesh_index != -1) {
        result = g_mesh_transform_indices[mesh_index];
    } // TODO: Else log?

    return result;
}

void MeshSetTransform(int mesh_handle_index, int transform_handle_index) {
    int mesh_index = GetMeshIndexFromHandle_(mesh_handle_index);
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);

    if(mesh_index != -1 && transform_index != -1) {
        g_mesh_transform_indices[mesh_index] = transform_index;
    } // TODO: Else log?
}

void MeshClearTransform(int mesh_handle_index) {
    int mesh_index = GetMeshIndexFromHandle_(mesh_handle_index);

    if(mesh_index != -1) {
        g_mesh_transform_indices[mesh_index] = -1;
    } // TODO: Else log?
}

void TransformSetToIdentity(int transform_handle_index) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);

    if(transform_index != -1) {
        g_transform_translations[transform_index] = (hmm_vec3){ 0 };
        g_transform_rotations[transform_index] = (hmm_quaternion){ .X = 0.0f, .Y = 0.0f, .Z = 0.0f, .W = 1.0f };
        g_transform_scales[transform_index] = (hmm_vec3){ .X = 1.0f, .Y = 1.0f, .Z = 1.0f };
    } // TODO: Else log?
}

void TransformSetTranslation(int transform_handle_index, float x, float y, float z) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);

    if(transform_index != -1) {
        g_transform_translations[transform_index] = (hmm_vec3){ .X = x, .Y = y, .Z = z };
    } // TODO: Else log?
}

void TransformClearTranslation(int transform_handle_index) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);

    if(transform_index != -1) {
        g_transform_translations[transform_index] = (hmm_vec3){ 0 };
    } // TODO: Else log?
}

void TransformSetRotationX(int transform_handle_index, float angle_in_degrees) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);

    if(transform_index != -1) {
        g_transform_rotations[transform_index] = HMM_QuaternionFromAxisAngle((hmm_vec3){ .X = 1.0f, .Y = 0.0f, .Z = 0.0f }, HMM_ToRadians(angle_in_degrees));
    } // TODO: Else log?
}

void TransformSetRotationY(int transform_handle_index, float angle_in_degrees) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);

    if(transform_index != -1) {
        g_transform_rotations[transform_index] = HMM_QuaternionFromAxisAngle((hmm_vec3){ .X = 0.0f, .Y = 1.0f, .Z = 0.0f }, HMM_ToRadians(angle_in_degrees));
    } // TODO: Else log?
}

void TransformSetRotationZ(int transform_handle_index, float angle_in_degrees) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);

    if(transform_index != -1) {
        g_transform_rotations[transform_index] = HMM_QuaternionFromAxisAngle((hmm_vec3){ .X = 0.0f, .Y = 0.0f, .Z = 1.0f }, HMM_ToRadians(angle_in_degrees));
    } // TODO: Else log?
}

void TransformConcatRotationX(int transform_handle_index, float angle_in_degrees) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);

    if(transform_index != -1) {
        g_transform_rotations[transform_index] = HMM_MultiplyQuaternion(
            HMM_QuaternionFromAxisAngle((hmm_vec3){ .X = 1.0f, .Y = 0.0f, .Z = 0.0f }, HMM_ToRadians(angle_in_degrees)),
            g_transform_rotations[transform_index]);
    } // TODO: Else log?
}

void TransformConcatRotationY(int transform_handle_index, float angle_in_degrees) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);

    if(transform_index != -1) {
        g_transform_rotations[transform_index] = HMM_MultiplyQuaternion(
            HMM_QuaternionFromAxisAngle((hmm_vec3){ .X = 0.0f, .Y = 1.0f, .Z = 0.0f }, HMM_ToRadians(angle_in_degrees)),
            g_transform_rotations[transform_index]);
    } // TODO: Else log?
}

void TransformConcatRotationZ(int transform_handle_index, float angle_in_degrees) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);

    if(transform_index != -1) {
        g_transform_rotations[transform_index] = HMM_MultiplyQuaternion(
            HMM_QuaternionFromAxisAngle((hmm_vec3){ .X = 0.0f, .Y = 0.0f, .Z = 1.0f }, HMM_ToRadians(angle_in_degrees)),
            g_transform_rotations[transform_index]);
    } // TODO: Else log?
}

void TransformClearRotation(int transform_handle_index) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);

    if(transform_index != -1) {
        g_transform_rotations[transform_index] = (hmm_quaternion){ .X = 0.0f, .Y = 0.0f, .Z = 0.0f, .W = 1.0f };
    } // TODO: Else log?
}

void TransformSetScale(int transform_handle_index, float x, float y, float z) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);

    if(transform_index != -1) {
        g_transform_scales[transform_index] = (hmm_vec3){ .X = x, .Y = y, .Z = z };
    } // TODO: Else log?
}

void TransformClearScale(int transform_handle_index) {
    int transform_index = GetTransformIndexFromHandle_(transform_handle_index);

    if(transform_index != -1) {
        g_transform_scales[transform_index] = (hmm_vec3){ .X = 1.0f, .Y = 1.0f, .Z = 1.0f };
    } // TODO: Else log?
}


static void SwapBool_(bool* lhs, bool* rhs) {
    bool temp = *lhs;
    *lhs = *rhs;
    *rhs = temp;
}

static void SwapInt_(int* lhs, int* rhs) {
    int temp = *lhs;
    *lhs = *rhs;
    *rhs = temp;
}

static int GetMeshHandleFromIndex_(int mesh_index) {
    assert(mesh_index >= 0);
    assert(mesh_index < kMAX_MESHES);

    int result_mesh_handle_index = -1;
    for(int mesh_handle_index = 0; mesh_handle_index < kMAX_MESHES; ++mesh_handle_index) {
        if(g_mesh_handles[mesh_handle_index] == mesh_index) {
            result_mesh_handle_index = mesh_handle_index;
            break;
        }
    }

    if(result_mesh_handle_index == -1) {
        boxerShow("Can't find mesh handle with given mesh index!", "Jumpman Zero", BoxerStyleWarning, BoxerButtonsOK);  // TODO: Better error handling?
    }

    return result_mesh_handle_index;
}

static void MeshSwap_(int mesh_index_1, int mesh_index_2) {
    hmm_vec2 temp_uv_offset = g_mesh_uv_offsets[mesh_index_1];
    g_mesh_uv_offsets[mesh_index_1] = g_mesh_uv_offsets[mesh_index_2];
    g_mesh_uv_offsets[mesh_index_2] = temp_uv_offset;

    temp_uv_offset = g_mesh_uv_offsets_previous[mesh_index_1];
    g_mesh_uv_offsets_previous[mesh_index_1] = g_mesh_uv_offsets_previous[mesh_index_2];
    g_mesh_uv_offsets_previous[mesh_index_2] = temp_uv_offset;

    bool temp_animation_is_continuous = g_mesh_animation_is_continuous[mesh_index_1];
    g_mesh_animation_is_continuous[mesh_index_1] = g_mesh_animation_is_continuous[mesh_index_2];
    g_mesh_animation_is_continuous[mesh_index_2] = temp_animation_is_continuous;

    SwapInt_(&g_mesh_vertex_start_indices[mesh_index_1], &g_mesh_vertex_start_indices[mesh_index_2]);
    SwapInt_(&g_mesh_vertex_counts[mesh_index_1], &g_mesh_vertex_counts[mesh_index_2]);
    SwapInt_(&g_mesh_texture_indices[mesh_index_1], &g_mesh_texture_indices[mesh_index_2]);
    SwapBool_(&g_mesh_is_visible[mesh_index_1], &g_mesh_is_visible[mesh_index_2]);
    SwapBool_(&g_mesh_is_visible_previous[mesh_index_1], &g_mesh_is_visible_previous[mesh_index_2]);

    SwapInt_(&g_mesh_transform_indices[mesh_index_1], &g_mesh_transform_indices[mesh_index_2]);

    int mesh_handle_index_1 = GetMeshHandleFromIndex_(mesh_index_1);
    int mesh_handle_index_2 = GetMeshHandleFromIndex_(mesh_index_2);
    SwapInt_(&g_mesh_handles[mesh_handle_index_1], &g_mesh_handles[mesh_handle_index_2]);
}

int MeshCreateFromVertexComponents(long* vertex_components, int vertex_count) {
    assert(g_mesh_count < kMAX_MESHES);
    assert(g_mesh_handle_first_free_index != -1);
    int new_mesh_handle_index = -1;

    if(g_mesh_count < kMAX_TRANSFORMS && g_mesh_handle_first_free_index != -1) {
        int new_mesh_index = g_mesh_count;

        g_mesh_vertex_start_indices[new_mesh_index] = g_vertices_to_load_count;
        g_mesh_vertex_counts[new_mesh_index] = vertex_count;

        g_mesh_texture_indices[new_mesh_index] = -1;
        g_mesh_is_visible[new_mesh_index] = false;
        g_mesh_uv_offsets[new_mesh_index] = (const hmm_vec2){ 0 };
        g_mesh_animation_is_continuous[new_mesh_index] = false;
        // TODO: Set visibility?

        for(int vertex_index = 0; vertex_index < vertex_count; ++vertex_index) {
            g_vertices_to_load[g_vertices_to_load_count].x = vertex_components[vertex_index * 9 + 0] / 256.0f;
            g_vertices_to_load[g_vertices_to_load_count].y = vertex_components[vertex_index * 9 + 1] / 256.0f;
            g_vertices_to_load[g_vertices_to_load_count].z = vertex_components[vertex_index * 9 + 2] / 256.0f;
            g_vertices_to_load[g_vertices_to_load_count].nx = vertex_components[vertex_index * 9 + 3] / 256.0f;
            g_vertices_to_load[g_vertices_to_load_count].ny = vertex_components[vertex_index * 9 + 4] / 256.0f;
            g_vertices_to_load[g_vertices_to_load_count].nz = vertex_components[vertex_index * 9 + 5] / 256.0f;
            g_vertices_to_load[g_vertices_to_load_count].tu = vertex_components[vertex_index * 9 + 7] / 256.0f;
            g_vertices_to_load[g_vertices_to_load_count].tv = vertex_components[vertex_index * 9 + 8] / 256.0f;

            ++g_vertices_to_load_count;
        }

        ++g_mesh_count;

        new_mesh_handle_index = g_mesh_handle_first_free_index;
        g_mesh_handles[new_mesh_handle_index] = new_mesh_index;
        g_mesh_handle_first_free_index = g_mesh_handle_next_free_indices[g_mesh_handle_first_free_index];
    } // TODO: Else log?

    return new_mesh_handle_index;
}

int MeshCreateFromVertices(MeshVertex* vertices, int vertex_count, int texture_index, bool is_visible) {
    assert(g_mesh_count < kMAX_MESHES);
    assert(g_mesh_handle_first_free_index != -1);
    int new_mesh_handle_index = -1;

    if(g_mesh_count < kMAX_TRANSFORMS && g_mesh_handle_first_free_index != -1) {
        int new_mesh_index = g_mesh_count;

        g_mesh_vertex_start_indices[new_mesh_index] = g_vertices_to_load_count;
        g_mesh_vertex_counts[new_mesh_index] = vertex_count;

        g_mesh_texture_indices[new_mesh_index] = texture_index;
        g_mesh_is_visible[new_mesh_index] = is_visible;
        g_mesh_uv_offsets[new_mesh_index] = (const hmm_vec2){ 0 };
        g_mesh_animation_is_continuous[new_mesh_index] = false;
        // TODO: Set visibility?

        for(size_t vertex_index = 0; vertex_index < vertex_count; ++vertex_index) {
            g_vertices_to_load[g_vertices_to_load_count] = vertices[vertex_index];
            ++g_vertices_to_load_count;
        }

        ++g_mesh_count;

        new_mesh_handle_index = g_mesh_handle_first_free_index;
        g_mesh_handles[new_mesh_handle_index] = new_mesh_index;
        g_mesh_handle_first_free_index = g_mesh_handle_next_free_indices[g_mesh_handle_first_free_index];
    }

    return new_mesh_handle_index;
}

int MeshCreateFromCopy(int source_mesh_handle_index) {
    assert(g_mesh_count < kMAX_MESHES);
    assert(g_mesh_handle_first_free_index != -1);
    int source_mesh_index = GetMeshIndexFromHandle_(source_mesh_handle_index);
    int new_mesh_handle_index = -1;

    if(g_mesh_count < kMAX_TRANSFORMS && g_mesh_handle_first_free_index != -1 && source_mesh_index != -1) {
        int new_mesh_index = g_mesh_count;

        g_mesh_vertex_start_indices[new_mesh_index] = g_mesh_vertex_start_indices[source_mesh_index];
        g_mesh_vertex_counts[new_mesh_index] = g_mesh_vertex_counts[source_mesh_index];

        g_mesh_texture_indices[new_mesh_index] = -1;  // TODO: Copy texture over?
        g_mesh_is_visible[new_mesh_index] = false;
        g_mesh_uv_offsets[new_mesh_index] = (const hmm_vec2){ 0 };
        g_mesh_animation_is_continuous[new_mesh_index] = false;
        // TODO: Set visibility?

        ++g_mesh_count;

        new_mesh_handle_index = g_mesh_handle_first_free_index;
        g_mesh_handles[new_mesh_handle_index] = new_mesh_index;
        g_mesh_handle_first_free_index = g_mesh_handle_next_free_indices[g_mesh_handle_first_free_index];
    }

    return new_mesh_handle_index;
}

void MeshReplaceWithCopy(int target_mesh_handle_index, int source_mesh_handle_index) {
    int target_mesh_index = GetMeshIndexFromHandle_(target_mesh_handle_index);
    int source_mesh_index = GetMeshIndexFromHandle_(source_mesh_handle_index);

    if(target_mesh_index != -1 && source_mesh_index != -1) {
        g_mesh_vertex_start_indices[target_mesh_index] = g_mesh_vertex_start_indices[source_mesh_index];
        g_mesh_vertex_counts[target_mesh_index] = g_mesh_vertex_counts[source_mesh_index];
    }
}

void MeshDelete(int deleting_mesh_handle_index) {
    assert(g_mesh_count > 0);
    int deleting_mesh_index = GetMeshIndexFromHandle_(deleting_mesh_handle_index);

    if(g_mesh_count > 0 && deleting_mesh_index != -1) {
        int last_mesh_index = g_mesh_count - 1;

        if(g_mesh_count > 1 && deleting_mesh_index < last_mesh_index) {
            // Overwrite the mesh being deleted with the last mesh
            g_mesh_uv_offsets[deleting_mesh_index] = g_mesh_uv_offsets[last_mesh_index];
            g_mesh_uv_offsets_previous[deleting_mesh_index] = g_mesh_uv_offsets_previous[last_mesh_index];
            g_mesh_animation_is_continuous[deleting_mesh_index] = g_mesh_animation_is_continuous[last_mesh_index];

            g_mesh_vertex_start_indices[deleting_mesh_index] = g_mesh_vertex_start_indices[last_mesh_index];
            g_mesh_vertex_counts[deleting_mesh_index] = g_mesh_vertex_counts[last_mesh_index];
            g_mesh_texture_indices[deleting_mesh_index] = g_mesh_texture_indices[last_mesh_index];
            g_mesh_is_visible[deleting_mesh_index] = g_mesh_is_visible[last_mesh_index];
            g_mesh_is_visible_previous[deleting_mesh_index] = g_mesh_is_visible_previous[last_mesh_index];

            g_mesh_transform_indices[deleting_mesh_index] = g_mesh_transform_indices[last_mesh_index];

            // Redirect all handles that pointed at the last mesh to its new location
            for(int handle_index = 0; handle_index < kMAX_MESHES; ++handle_index) {
                if(g_mesh_handles[handle_index] == last_mesh_index) {
                    g_mesh_handles[handle_index] = deleting_mesh_index;
                }
            }
        }

        g_mesh_handle_next_free_indices[deleting_mesh_handle_index] = g_mesh_handle_first_free_index;
        g_mesh_handle_first_free_index = deleting_mesh_handle_index;

        --g_mesh_count;
    } // TODO: Else log?
}

void MeshSetIsVisible(int mesh_handle_index, bool is_visible) {
    int mesh_index = GetMeshIndexFromHandle_(mesh_handle_index);
    if(mesh_index != -1) {
        g_mesh_is_visible[mesh_index] = is_visible;
    }
}

void MeshSetTextureIndex(int mesh_handle_index, int texture_index) {
    int mesh_index = GetMeshIndexFromHandle_(mesh_handle_index);
    if(mesh_index != -1) {
        g_mesh_texture_indices[mesh_index] = texture_index;
    }
}

void MeshMoveToFrontForTransparentDrawing(int mesh_handle_index) {
    int mesh_index = GetMeshIndexFromHandle_(mesh_handle_index);

    for(int current_mesh_index = mesh_index + 1; current_mesh_index < g_mesh_count; ++current_mesh_index) {
        MeshSwap_(current_mesh_index, current_mesh_index - 1);
    }
}

void MeshMoveToBackForTransparentDrawing(int mesh_handle_index) {
    int mesh_index = GetMeshIndexFromHandle_(mesh_handle_index);

    for(int current_mesh_index = mesh_index - 1; current_mesh_index >= 0; --current_mesh_index) {
        MeshSwap_(current_mesh_index, current_mesh_index + 1);
    }
}

void MeshScrollTexture(int mesh_handle_index, float translate_x, float translate_y) {
    int mesh_index = GetMeshIndexFromHandle_(mesh_handle_index);

    if(mesh_index != -1) {
        g_mesh_uv_offsets[mesh_index] = HMM_AddVec2(
            HMM_Vec2(translate_x, translate_y),
            g_mesh_uv_offsets[mesh_index]);
    }
}

void MeshSetIsAnimationContinuous(int mesh_handle_index, bool is_continuous) {
    int mesh_index = GetMeshIndexFromHandle_(mesh_handle_index);
    if(mesh_index != -1) {
        g_mesh_animation_is_continuous[mesh_index] = is_continuous;
    }
}


void SetCameraIsAnimationContinuous(bool is_continuous) {
    g_camera_animation_is_continuous = is_continuous;
}

void SetFog(float fog_start, float fog_end, uint8_t red, uint8_t green, uint8_t blue) {
    if(fog_start == 0 && fog_end == 0) {
        g_is_fog_enabled = false;
    } else {
        g_is_fog_enabled = true;
        g_fog_color = (const hmm_vec3){ { red / 255.0f, green / 255.0f, blue / 255.0f } };
        g_fog_start = fog_start;
        g_fog_end = fog_end;
    }
}

void SetPerspective(float cam_x, float cam_y, float cam_z, float look_at_x, float look_at_y, float look_at_z) {
    g_world_to_view_matrix = HMM_LookAtLH(HMM_Vec3(cam_x, cam_y, cam_z), HMM_Vec3(look_at_x, look_at_y, look_at_z), HMM_Vec3(0.0f, 1.0f, 0.0f));
    g_camera_light.position = (const hmm_vec3){ { cam_x, cam_y + 10.0f, -200.0f } };
    g_camera_light.diffuse_color = (const hmm_vec3){ { 1.0f, 1.0f, 1.0f } };
    g_camera_light.ambient_color = (const hmm_vec3){ { 1.0f, 1.0f, 1.0f } };
}


void RendererPreUpdate(double seconds_per_update_timestep) {
    g_world_to_view_matrix_previous = g_world_to_view_matrix;
    g_camera_animation_is_continuous = true;

    for(int mesh_index = 0; mesh_index < g_mesh_count; ++mesh_index) {
        if(!g_mesh_animation_is_continuous[mesh_index]) {
            // Has to have existed since previous update call for this to be triggered
            g_mesh_animation_is_continuous[mesh_index] = true;
        }

        g_mesh_is_visible_previous[mesh_index] = g_mesh_is_visible[mesh_index];
        g_mesh_uv_offsets_previous[mesh_index] = g_mesh_uv_offsets[mesh_index];
    }

    for(int transform_index = 0; transform_index < g_transform_count; ++transform_index) {
        g_transform_translations_previous[transform_index] = g_transform_translations[transform_index];
        g_transform_rotations_previous[transform_index] = g_transform_rotations[transform_index];
        g_transform_scales_previous[transform_index] = g_transform_scales[transform_index];
    }
}

void RendererPostUpdate(void) {
    for(int mesh_index = 0; mesh_index < g_mesh_count; ++mesh_index) {
        if(!g_mesh_is_visible_previous[mesh_index] && g_mesh_is_visible[mesh_index]) {
            g_mesh_animation_is_continuous[mesh_index] = false;
        }
    }
}

static void RenderMesh_(int mesh_index, int* previous_texture_index, main_shader_vs_params_t* vs_params, bool* are_fs_params_applied, main_shader_fs_params_t* fs_params, bool do_interpolation, float interpolation_scale) {
    int current_texture_index = g_mesh_texture_indices[mesh_index];
    assert(current_texture_index != -1);
    // TODO: If current_texture_index == -1 then set to a default texture

    if(*previous_texture_index != current_texture_index) {
        *previous_texture_index = current_texture_index;
        g_bindings.fs_images[0] = g_textures[current_texture_index];
        sg_apply_bindings(&g_bindings);
    }

    int current_transform_index = g_mesh_transform_indices[mesh_index];
    bool transform_skip_world_to_view = false;

    // TODO: Calculate matrices in more cache-friendly/packed manner
    // TODO: Are parent/child being multiplied in the correct order here? Seems they're reversed right now. Should do parent[SRT]child[SRT]?
    hmm_mat4 current_local_to_world_matrix = { {
        { 1, 0, 0, 0 },
        { 0, 1, 0, 0 },
        { 0, 0, 1, 0 },
        { 0, 0, 0, 1 },
    } };

    if(do_interpolation && g_mesh_animation_is_continuous[mesh_index]) {
        while(current_transform_index != -1) {
            hmm_vec3 current_translation = HMM_LerpVec3(g_transform_translations_previous[current_transform_index], g_transform_translations[current_transform_index], interpolation_scale);
            hmm_quaternion current_rotation = HMM_Slerp(g_transform_rotations_previous[current_transform_index], interpolation_scale, g_transform_rotations[current_transform_index]);
            hmm_vec3 current_scale = HMM_LerpVec3(g_transform_scales_previous[current_transform_index], g_transform_scales[current_transform_index], interpolation_scale);
            current_local_to_world_matrix =
                HMM_MultiplyMat4(
                    HMM_Translate(current_translation),
                    HMM_MultiplyMat4(
                        HMM_QuaternionToMat4(current_rotation),
                        HMM_MultiplyMat4(
                            HMM_Scale(current_scale),
                            current_local_to_world_matrix)));

            if(g_transform_parent_is_camera[current_transform_index]) {
                transform_skip_world_to_view = true;
            }

            current_transform_index = g_transform_parent_indices[current_transform_index];
        }
    } else {
        while(current_transform_index != -1) {
            hmm_vec3 current_translation = g_transform_translations[current_transform_index];
            hmm_quaternion current_rotation = g_transform_rotations[current_transform_index];
            hmm_vec3 current_scale = g_transform_scales[current_transform_index];
            current_local_to_world_matrix =
                HMM_MultiplyMat4(
                    HMM_Translate(current_translation),
                    HMM_MultiplyMat4(
                        HMM_QuaternionToMat4(current_rotation),
                        HMM_MultiplyMat4(
                            HMM_Scale(current_scale),
                            current_local_to_world_matrix)));

            if(g_transform_parent_is_camera[current_transform_index]) {
                transform_skip_world_to_view = true;
            }

            current_transform_index = g_transform_parent_indices[current_transform_index];
        }
    }

    vs_params->local_to_world_matrix = current_local_to_world_matrix;
    vs_params->local_to_view_matrix = transform_skip_world_to_view
        ? current_local_to_world_matrix
        : HMM_MultiplyMat4(g_interpolated_world_to_view_matrix, current_local_to_world_matrix);
    vs_params->local_to_projection_matrix = transform_skip_world_to_view
        ? HMM_MultiplyMat4(g_view_to_projection_matrix, current_local_to_world_matrix)
        : HMM_MultiplyMat4(g_interpolated_world_to_projection_matrix, current_local_to_world_matrix);
    vs_params->transpose_world_to_local_matrix = HMM_Transpose(JM_HMM_Inverse(current_local_to_world_matrix));

    if(do_interpolation && g_mesh_animation_is_continuous[mesh_index]) {
        vs_params->uv_offset = HMM_LerpVec2(g_mesh_uv_offsets_previous[mesh_index], g_mesh_uv_offsets[mesh_index], interpolation_scale);
    } else {
        vs_params->uv_offset = g_mesh_uv_offsets[mesh_index];
    }

    sg_apply_uniforms(SG_SHADERSTAGE_VS, 0, &(sg_range){ vs_params, sizeof(*vs_params) });

    if(!*are_fs_params_applied) {
        sg_apply_uniforms(SG_SHADERSTAGE_FS, 0, &(sg_range){ fs_params, sizeof(*fs_params) });
        *are_fs_params_applied = true;
    }

    sg_draw(g_mesh_vertex_start_indices[mesh_index], g_mesh_vertex_counts[mesh_index], 1);
}

void RendererDraw(bool do_interpolation, float interpolation_scale) {
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

    main_shader_vs_params_t vs_params;
    main_shader_fs_params_t fs_params;
    fs_params.scene_ambient_color = g_scene_ambient_color;
    fs_params.material_ambient_tint = g_global_material.ambient_tint;  // TODO: Use struct in shader?
    fs_params.material_diffuse_tint = g_global_material.diffuse_tint;
    fs_params.light_ambient_color = g_camera_light.ambient_color;  // TODO: Use struct in shader?
    fs_params.light_diffuse_color = g_camera_light.diffuse_color;
    fs_params.light_position = g_camera_light.position;
    fs_params.light_range = g_camera_light.range;
    fs_params.is_fog_enabled = g_is_fog_enabled ? 1.0f : 0.0f;
    fs_params.fog_color = g_fog_color;
    fs_params.fog_start = g_fog_start;
    fs_params.fog_end = g_fog_end;

    g_interpolated_world_to_view_matrix = g_world_to_view_matrix;

    if(do_interpolation && g_camera_animation_is_continuous) {
        hmm_vec3 camera_pos_current = *(hmm_vec3*)&g_world_to_view_matrix.Elements[3];
        hmm_vec3 camera_pos_previous = *(hmm_vec3*)&g_world_to_view_matrix_previous.Elements[3];
        *(hmm_vec3*)&g_interpolated_world_to_view_matrix.Elements[3] = HMM_AddVec3(
            camera_pos_previous,
            HMM_MultiplyVec3f(
                HMM_SubtractVec3(camera_pos_current, camera_pos_previous),
                g_camera_animation_is_continuous ? interpolation_scale : 0.0f));
    }

    g_interpolated_world_to_projection_matrix = HMM_MultiplyMat4(g_view_to_projection_matrix, g_interpolated_world_to_view_matrix);

    // Draw opaque
    sg_apply_pipeline(g_opaque_pipline);

    int previous_texture_index = -1;
    bool are_fs_params_applied = false;  // These are currently set globally, so don't need to be set for every mesh

    for(int mesh_index = 0; mesh_index < g_mesh_count; ++mesh_index) {
        if(g_mesh_is_visible[mesh_index] && !g_texture_is_alpha_blend_enabled[g_mesh_texture_indices[mesh_index]]) {
            RenderMesh_(mesh_index, &previous_texture_index, &vs_params, &are_fs_params_applied, &fs_params, do_interpolation, interpolation_scale);
        }
    }

    // Draw transparent
    sg_apply_pipeline(g_transparent_pipline);

    previous_texture_index = -1;
    are_fs_params_applied = false;

    for(int mesh_index = 0; mesh_index < g_mesh_count; ++mesh_index) {
        if(g_mesh_is_visible[mesh_index] && g_texture_is_alpha_blend_enabled[g_mesh_texture_indices[mesh_index]]) {
            RenderMesh_(mesh_index, &previous_texture_index, &vs_params, &are_fs_params_applied, &fs_params, do_interpolation, interpolation_scale);
        }
    }

    sg_end_pass();
    sg_commit();
}

void ResizeViewport(int width, int height) {
    g_backbuffer_width = width;
    g_backbuffer_height = height;
}

void GetViewportMousePos(float* pos_x, float* pos_y) {
    float backbuffer_aspect_ratio = (float)g_backbuffer_width / g_backbuffer_height;
    const float target_aspect_ratio = 640.0f / 480.0f;

    float temp_x;
    float temp_y;

    if(backbuffer_aspect_ratio > target_aspect_ratio) {
        float width_scale = target_aspect_ratio / backbuffer_aspect_ratio;
        float border_half_width = (g_backbuffer_width - width_scale * g_backbuffer_width) / 2.0f;

        temp_x = (*pos_x - border_half_width) / (g_backbuffer_width - (border_half_width * 2.0f));
        temp_y = *pos_y / g_backbuffer_height;

    } else {
        float height_scale = backbuffer_aspect_ratio / target_aspect_ratio;
        float border_half_height = (g_backbuffer_height - height_scale * g_backbuffer_height) / 2.0f;

        temp_x = *pos_x / g_backbuffer_width;
        temp_y = (*pos_y - border_half_height) / (g_backbuffer_height - (border_half_height * 2.0f));
    }

    if(temp_x < 0.0f) {
        temp_x = 0.0f;
    }
    if(temp_x > 1.0f) {
        temp_x = 1.0f;
    }
    if(temp_y < 0.0f) {
        temp_y = 0.0f;
    }
    if(temp_y > 1.0f) {
        temp_y = 1.0f;
    }

    *pos_x = temp_x;
    *pos_y = temp_y;
}


static void FatalError_(const char* error_msg) {
    kill_scene_();
    kill_3d_();
    boxerShow(error_msg, "Jumpman Zero", BoxerStyleError, BoxerButtonsOK);
}
