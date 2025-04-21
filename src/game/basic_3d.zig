const std = @import("std");
const jumpman_basic_3d_c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("sokol_gfx.h");
    @cInclude("stb_sprintf.h");
    @cInclude("stb_image.h");
    @cInclude("boxer/boxer.h");
    @cDefine("ZIG_SKIP_SHADER_DEF", "");
    @cInclude("shader.h");
});

pub const MeshVertex = extern struct {
    x: f32,
    y: f32,
    z: f32,
    nx: f32,
    ny: f32,
    nz: f32,
    tu: f32,
    tv: f32,
};

// Begin: helpers from HandmadeMath. Rename after HMM is removed from build

const hmm_vec2 = extern struct {
    // TODO: lowercase
    X: f32,
    Y: f32,

    fn init(x: f32, y: f32) hmm_vec2 {
        const result = hmm_vec2{ .X = x, .Y = y };
        return result;
    }

    const zero = init(0, 0);
};

const hmm_vec3 = extern struct {
    // TODO: lowercase
    X: f32,
    Y: f32,
    Z: f32,

    fn init(x: f32, y: f32, z: f32) hmm_vec3 {
        const result = hmm_vec3{ .X = x, .Y = y, .Z = z };
        return result;
    }

    const zero = init(0, 0, 0);
};

const hmm_vec4 = struct {
    // TODO: lowercase
    X: f32,
    Y: f32,
    Z: f32,
    W: f32,

    fn init(x: f32, y: f32, z: f32, w: f32) hmm_vec4 {
        const result = hmm_vec4{ .X = x, .Y = y, .Z = z, .W = w };
        return result;
    }

    const zero = init(0, 0, 0, 0);
};

const hmm_mat4 = extern struct {
    Elements: [4][4]f32,

    const zero: hmm_mat4 = .fromVec4(.zero, .zero, .zero, .zero);

    fn fromVec4(column_0: hmm_vec4, column_1: hmm_vec4, column_2: hmm_vec4, column_3: hmm_vec4) hmm_mat4 {
        const result: hmm_mat4 = .{ .Elements = .{
            .{ column_0.X, column_0.Y, column_0.Z, column_0.W },
            .{ column_1.X, column_1.Y, column_1.Z, column_1.W },
            .{ column_2.X, column_2.Y, column_2.Z, column_2.W },
            .{ column_3.X, column_3.Y, column_3.Z, column_3.W },
        } };
        return result;
    }

    fn scale(value: hmm_vec3) hmm_mat4 {
        const result: hmm_mat4 = .{ .Elements = .{
            .{ value.X, 0.0, 0.0, 0.0 },
            .{ 0.0, value.Y, 0.0, 0.0 },
            .{ 0.0, 0.0, value.Z, 0.0 },
            .{ 0.0, 0.0, 0.0, 1.0 },
        } };
        return result;
    }

    fn getTranspose(self: @This()) hmm_mat4 {
        var result: hmm_mat4 = undefined;
        for (0..4) |column| {
            for (0..4) |row| {
                result.Elements[row][column] = self.Elements[column][row];
            }
        }
        return result;
    }

    fn getInverse(self: @This()) hmm_mat4 {
        const coef_00: f32 = self.Elements[2][2] * self.Elements[3][3] - self.Elements[3][2] * self.Elements[2][3];
        const coef_02: f32 = self.Elements[1][2] * self.Elements[3][3] - self.Elements[3][2] * self.Elements[1][3];
        const coef_03: f32 = self.Elements[1][2] * self.Elements[2][3] - self.Elements[2][2] * self.Elements[1][3];

        const coef_04: f32 = self.Elements[2][1] * self.Elements[3][3] - self.Elements[3][1] * self.Elements[2][3];
        const coef_06: f32 = self.Elements[1][1] * self.Elements[3][3] - self.Elements[3][1] * self.Elements[1][3];
        const coef_07: f32 = self.Elements[1][1] * self.Elements[2][3] - self.Elements[2][1] * self.Elements[1][3];

        const coef_08: f32 = self.Elements[2][1] * self.Elements[3][2] - self.Elements[3][1] * self.Elements[2][2];
        const coef_10: f32 = self.Elements[1][1] * self.Elements[3][2] - self.Elements[3][1] * self.Elements[1][2];
        const coef_11: f32 = self.Elements[1][1] * self.Elements[2][2] - self.Elements[2][1] * self.Elements[1][2];

        const coef_12: f32 = self.Elements[2][0] * self.Elements[3][3] - self.Elements[3][0] * self.Elements[2][3];
        const coef_14: f32 = self.Elements[1][0] * self.Elements[3][3] - self.Elements[3][0] * self.Elements[1][3];
        const coef_15: f32 = self.Elements[1][0] * self.Elements[2][3] - self.Elements[2][0] * self.Elements[1][3];

        const coef_16: f32 = self.Elements[2][0] * self.Elements[3][2] - self.Elements[3][0] * self.Elements[2][2];
        const coef_18: f32 = self.Elements[1][0] * self.Elements[3][2] - self.Elements[3][0] * self.Elements[1][2];
        const coef_19: f32 = self.Elements[1][0] * self.Elements[2][2] - self.Elements[2][0] * self.Elements[1][2];

        const coef_20: f32 = self.Elements[2][0] * self.Elements[3][1] - self.Elements[3][0] * self.Elements[2][1];
        const coef_22: f32 = self.Elements[1][0] * self.Elements[3][1] - self.Elements[3][0] * self.Elements[1][1];
        const coef_23: f32 = self.Elements[1][0] * self.Elements[2][1] - self.Elements[2][0] * self.Elements[1][1];

        const fac_0: hmm_vec4 = .init(coef_00, coef_00, coef_02, coef_03);
        const fac_1: hmm_vec4 = .init(coef_04, coef_04, coef_06, coef_07);
        const fac_2: hmm_vec4 = .init(coef_08, coef_08, coef_10, coef_11);
        const fac_3: hmm_vec4 = .init(coef_12, coef_12, coef_14, coef_15);
        const fac_4: hmm_vec4 = .init(coef_16, coef_16, coef_18, coef_19);
        const fac_5: hmm_vec4 = .init(coef_20, coef_20, coef_22, coef_23);

        const vec_0: hmm_vec4 = .init(self.Elements[1][0], self.Elements[0][0], self.Elements[0][0], self.Elements[0][0]);
        const vec_1: hmm_vec4 = .init(self.Elements[1][1], self.Elements[0][1], self.Elements[0][1], self.Elements[0][1]);
        const vec_2: hmm_vec4 = .init(self.Elements[1][2], self.Elements[0][2], self.Elements[0][2], self.Elements[0][2]);
        const vec_3: hmm_vec4 = .init(self.Elements[1][3], self.Elements[0][3], self.Elements[0][3], self.Elements[0][3]);

        const inv_0: hmm_vec4 = HMM_AddVec4_(HMM_SubtractVec4_(HMM_MultiplyVec4_(vec_1, fac_0), HMM_MultiplyVec4_(vec_2, fac_1)), HMM_MultiplyVec4_(vec_3, fac_2));
        const inv_1: hmm_vec4 = HMM_AddVec4_(HMM_SubtractVec4_(HMM_MultiplyVec4_(vec_0, fac_0), HMM_MultiplyVec4_(vec_2, fac_3)), HMM_MultiplyVec4_(vec_3, fac_4));
        const inv_2: hmm_vec4 = HMM_AddVec4_(HMM_SubtractVec4_(HMM_MultiplyVec4_(vec_0, fac_1), HMM_MultiplyVec4_(vec_1, fac_3)), HMM_MultiplyVec4_(vec_3, fac_5));
        const inv_3: hmm_vec4 = HMM_AddVec4_(HMM_SubtractVec4_(HMM_MultiplyVec4_(vec_0, fac_2), HMM_MultiplyVec4_(vec_1, fac_4)), HMM_MultiplyVec4_(vec_2, fac_5));

        const sign_a: hmm_vec4 = .init(1, -1, 1, -1);
        const sign_b: hmm_vec4 = .init(-1, 1, -1, 1);
        const inverse_matrix: hmm_mat4 = .fromVec4(HMM_MultiplyVec4_(inv_0, sign_a), HMM_MultiplyVec4_(inv_1, sign_b), HMM_MultiplyVec4_(inv_2, sign_a), HMM_MultiplyVec4_(inv_3, sign_b));

        const row_0: hmm_vec4 = .init(inverse_matrix.Elements[0][0], inverse_matrix.Elements[1][0], inverse_matrix.Elements[2][0], inverse_matrix.Elements[3][0]);
        const self_column_0: hmm_vec4 = .init(self.Elements[0][0], self.Elements[0][1], self.Elements[0][2], self.Elements[0][3]);

        const dot_0: hmm_vec4 = HMM_MultiplyVec4_(self_column_0, row_0);
        const dot_1: f32 = (dot_0.X + dot_0.Y) + (dot_0.Z + dot_0.W);

        const one_over_determinant: f32 = 1.0 / dot_1;

        return HMM_MultiplyMat4f_(inverse_matrix, one_over_determinant);
    }
};

const hmm_quaternion = struct {
    X: f32,
    Y: f32,
    Z: f32,
    W: f32,

    fn init(x: f32, y: f32, z: f32, w: f32) hmm_quaternion {
        const result = hmm_quaternion{ .X = x, .Y = y, .Z = z, .W = w };
        return result;
    }
};

// End: helpers from HandmadeMath. Rename after HMM is removed from build

const kMAX_TEXTURES: usize = 30;
const kMAX_TRANSFORMS: usize = 1200;
const kMAX_MESHES: usize = 600;
const kMAX_VERTICES: usize = 110000;

// Begin: helpers from HandmadeMath. Rename after HMM is removed from build

const HMM_PI32: f32 = 3.14159265359;

fn HMM_ToRadians_(degrees: f32) f32 {
    const result: f32 = degrees * (HMM_PI32 / 180.0);
    return result;
}

fn HMM_Lerp_(lhs: f32, time: f32, rhs: f32) f32 {
    const result: f32 = (1.0 - time) * lhs + time * rhs;
    return result;
}

fn HMM_AddVec2_(lhs: hmm_vec2, rhs: hmm_vec2) hmm_vec2 {
    const result: hmm_vec2 = .init(lhs.X + rhs.X, lhs.Y + rhs.Y);
    return result;
}

fn HMM_SubtractVec2_(lhs: hmm_vec2, rhs: hmm_vec2) hmm_vec2 {
    const result: hmm_vec2 = .init(lhs.X - rhs.X, lhs.Y - rhs.Y);
    return result;
}

fn HMM_MultiplyVec2f_(lhs: hmm_vec2, rhs: f32) hmm_vec2 {
    const result: hmm_vec2 = .init(lhs.X * rhs, lhs.Y * rhs);
    return result;
}

fn HMM_AddVec3_(lhs: hmm_vec3, rhs: hmm_vec3) hmm_vec3 {
    const result: hmm_vec3 = .init(lhs.X + rhs.X, lhs.Y + rhs.Y, lhs.Z + rhs.Z);
    return result;
}

fn HMM_SubtractVec3_(lhs: hmm_vec3, rhs: hmm_vec3) hmm_vec3 {
    const result: hmm_vec3 = .init(lhs.X - rhs.X, lhs.Y - rhs.Y, lhs.Z - rhs.Z);
    return result;
}

fn HMM_MultiplyVec3f_(lhs: hmm_vec3, rhs: f32) hmm_vec3 {
    const result: hmm_vec3 = .init(lhs.X * rhs, lhs.Y * rhs, lhs.Z * rhs);
    return result;
}

fn HMM_DivideVec3f_(vec: hmm_vec3, scalar: f32) hmm_vec3 {
    const result: hmm_vec3 = .init(vec.X / scalar, vec.Y / scalar, vec.Z / scalar);
    return result;
}

fn HMM_DotVec3_(lhs: hmm_vec3, rhs: hmm_vec3) f32 {
    const result: f32 = lhs.X * rhs.X + lhs.Y * rhs.Y + lhs.Z * rhs.Z;
    return result;
}

fn HMM_Cross_(lhs: hmm_vec3, rhs: hmm_vec3) hmm_vec3 {
    const result: hmm_vec3 = .init(lhs.Y * rhs.Z - lhs.Z * rhs.Y, lhs.Z * rhs.X - lhs.X * rhs.Z, lhs.X * rhs.Y - lhs.Y * rhs.X);
    return result;
}

fn HMM_NormalizeVec3_(vec: hmm_vec3) hmm_vec3 {
    var result: hmm_vec3 = .zero;
    const vector_length: f32 = std.math.sqrt(HMM_DotVec3_(vec, vec));
    if (vector_length != 0.0) {
        result = .init(
            vec.X * (1.0 / vector_length),
            vec.Y * (1.0 / vector_length),
            vec.Z * (1.0 / vector_length),
        );
    }
    return result;
}

fn HMM_AddVec4_(lhs: hmm_vec4, rhs: hmm_vec4) hmm_vec4 {
    const result: hmm_vec4 = .init(lhs.X + rhs.X, lhs.Y + rhs.Y, lhs.Z + rhs.Z, lhs.W + rhs.W);
    return result;
}

fn HMM_SubtractVec4_(lhs: hmm_vec4, rhs: hmm_vec4) hmm_vec4 {
    const result: hmm_vec4 = .init(lhs.X - rhs.X, lhs.Y - rhs.Y, lhs.Z - rhs.Z, lhs.W - rhs.W);
    return result;
}

fn HMM_MultiplyVec4_(lhs: hmm_vec4, rhs: hmm_vec4) hmm_vec4 {
    const result: hmm_vec4 = .init(lhs.X * rhs.X, lhs.Y * rhs.Y, lhs.Z * rhs.Z, lhs.W * rhs.W);
    return result;
}

fn HMM_Translate_(translation: hmm_vec3) hmm_mat4 {
    const result: hmm_mat4 = .{ .Elements = .{
        .{ 1.0, 0.0, 0.0, 0.0 },
        .{ 0.0, 1.0, 0.0, 0.0 },
        .{ 0.0, 0.0, 1.0, 0.0 },
        .{ translation.X, translation.Y, translation.Z, 1.0 },
    } };
    return result;
}

fn HMM_MultiplyMat4_(lhs: hmm_mat4, rhs: hmm_mat4) hmm_mat4 {
    var result: hmm_mat4 = undefined;
    for (0..4) |column| {
        for (0..4) |row| {
            var sum: f32 = 0;
            for (0..4) |current_index| {
                sum += lhs.Elements[current_index][row] * rhs.Elements[column][current_index];
            }
            result.Elements[column][row] = sum;
        }
    }
    return result;
}

fn HMM_MultiplyMat4f_(mat: hmm_mat4, scalar: f32) hmm_mat4 {
    var result: hmm_mat4 = undefined;
    for (0..4) |column| {
        for (0..4) |row| {
            result.Elements[column][row] = mat.Elements[column][row] * scalar;
        }
    }
    return result;
}

fn HMM_QuaternionFromAxisAngle_(axis: hmm_vec3, angle: f32) hmm_quaternion {
    const axis_norm: f32 = std.math.sqrt(HMM_DotVec3_(axis, axis));
    const sine_angle_over_two: f32 = std.math.sin(angle / 2.0);
    const rotated_vector: hmm_vec3 = HMM_MultiplyVec3f_(axis, sine_angle_over_two);
    const w_part: f32 = std.math.cos(angle / 2.0);
    const xyz_part: hmm_vec3 = HMM_DivideVec3f_(rotated_vector, axis_norm);
    const result: hmm_quaternion = .init(xyz_part.X, xyz_part.Y, xyz_part.Z, w_part);
    return result;
}

fn HMM_AddQuaternion_(lhs: hmm_quaternion, rhs: hmm_quaternion) hmm_quaternion {
    const result: hmm_quaternion = .init(lhs.X + rhs.X, lhs.Y + rhs.Y, lhs.Z + rhs.Z, lhs.W + rhs.W);
    return result;
}

fn HMM_MultiplyQuaternion_(lhs: hmm_quaternion, rhs: hmm_quaternion) hmm_quaternion {
    const result: hmm_quaternion = .init(
        (lhs.X * rhs.W) + (lhs.Y * rhs.Z) - (lhs.Z * rhs.Y) + (lhs.W * rhs.X),
        (-lhs.X * rhs.Z) + (lhs.Y * rhs.W) + (lhs.Z * rhs.X) + (lhs.W * rhs.Y),
        (lhs.X * rhs.Y) - (lhs.Y * rhs.X) + (lhs.Z * rhs.W) + (lhs.W * rhs.Z),
        (-lhs.X * rhs.X) - (lhs.Y * rhs.Y) - (lhs.Z * rhs.Z) + (lhs.W * rhs.W),
    );
    return result;
}

fn HMM_MultiplyQuaternionF_(quat: hmm_quaternion, scalar: f32) hmm_quaternion {
    const result: hmm_quaternion = .init(quat.X * scalar, quat.Y * scalar, quat.Z * scalar, quat.W * scalar);
    return result;
}

fn HMM_DotQuaternion_(lhs: hmm_quaternion, rhs: hmm_quaternion) f32 {
    const result: f32 = lhs.X * rhs.X + lhs.Y * rhs.Y + lhs.Z * rhs.Z + lhs.W * rhs.W;
    return result;
}

fn HMM_NormalizeQuaternion_(quat: hmm_quaternion) hmm_quaternion {
    const length: f32 = std.math.sqrt(HMM_DotQuaternion_(quat, quat));
    const result: hmm_quaternion = .init(quat.X / length, quat.Y / length, quat.Z / length, quat.W / length);
    return result;
}

fn HMM_QuaternionToMat4_(quat: hmm_quaternion) hmm_mat4 {
    const norm_quat: hmm_quaternion = HMM_NormalizeQuaternion_(quat);
    const xx: f32 = norm_quat.X * norm_quat.X;
    const yy: f32 = norm_quat.Y * norm_quat.Y;
    const zz: f32 = norm_quat.Z * norm_quat.Z;
    const xy: f32 = norm_quat.X * norm_quat.Y;
    const xz: f32 = norm_quat.X * norm_quat.Z;
    const yz: f32 = norm_quat.Y * norm_quat.Z;
    const wx: f32 = norm_quat.W * norm_quat.X;
    const wy: f32 = norm_quat.W * norm_quat.Y;
    const wz: f32 = norm_quat.W * norm_quat.Z;

    var result: hmm_mat4 = .zero;
    result.Elements[0][0] = 1.0 - 2.0 * (yy + zz);
    result.Elements[0][1] = 2.0 * (xy + wz);
    result.Elements[0][2] = 2.0 * (xz - wy);
    result.Elements[1][0] = 2.0 * (xy - wz);
    result.Elements[1][1] = 1.0 - 2.0 * (xx + zz);
    result.Elements[1][2] = 2.0 * (yz + wx);
    result.Elements[2][0] = 2.0 * (xz + wy);
    result.Elements[2][1] = 2.0 * (yz - wx);
    result.Elements[2][2] = 1.0 - 2.0 * (xx + yy);
    result.Elements[3][3] = 1.0;

    return result;
}

fn HMM_Slerp_(lhs: hmm_quaternion, time: f32, rhs: hmm_quaternion) hmm_quaternion {
    var cos_theta: f32 = HMM_DotQuaternion_(lhs, rhs);

    // If cosTheta < 0, the interpolation will take the long way around the sphere.
    // To fix this, one quat must be negated.
    const corrected_rhs: hmm_quaternion = blk: {
        if (cos_theta < 0.0) {
            cos_theta = -cos_theta;
            break :blk .init(-rhs.X, -rhs.Y, -rhs.Z, -rhs.W);
        }
        break :blk rhs;
    };

    // Perform a linear interpolation when cosTheta is close to 1 to avoid side effect of sin(angle) becoming a zero denominator
    if (cos_theta > 1.0 - 0.001) {
        const result: hmm_quaternion = .init(HMM_Lerp_(lhs.X, time, corrected_rhs.X), HMM_Lerp_(lhs.Y, time, corrected_rhs.Y), HMM_Lerp_(lhs.Z, time, corrected_rhs.Z), HMM_Lerp_(lhs.W, time, corrected_rhs.W));
        return result;
    }

    const angle: f32 = std.math.cos(cos_theta);

    const s1: f32 = std.math.sin((1.0 - time) * angle);
    const s2: f32 = std.math.sin(time * angle);
    const inverse_sine_angle: f32 = 1.0 / std.math.sin(angle);

    const quat_left: hmm_quaternion = HMM_MultiplyQuaternionF_(lhs, s1);
    const quat_right: hmm_quaternion = HMM_MultiplyQuaternionF_(corrected_rhs, s2);

    const result: hmm_quaternion = HMM_MultiplyQuaternionF_(HMM_AddQuaternion_(quat_left, quat_right), inverse_sine_angle);

    return result;
}

// End: helpers from HandmadeMath. Rename after HMM is removed from build

const Light = struct {
    ambient_color: hmm_vec3,
    diffuse_color: hmm_vec3,
    position: hmm_vec3,
    range: f32,
};

const Material = struct {
    ambient_tint: hmm_vec3,
    diffuse_tint: hmm_vec3,
};

var g_backbuffer_width: i32 = 0;
var g_backbuffer_height: i32 = 0;
var g_bindings: jumpman_basic_3d_c.sg_bindings = .{};
var g_opaque_pipline: jumpman_basic_3d_c.sg_pipeline = .{};
var g_transparent_pipline: jumpman_basic_3d_c.sg_pipeline = .{};
var g_pass_action: jumpman_basic_3d_c.sg_pass_action = .{};
var g_camera_light = std.mem.zeroes(Light);
var g_global_material = std.mem.zeroes(Material);
var g_scene_ambient_color: hmm_vec3 = .zero;
var g_is_fog_enabled: bool = false;
var g_fog_color: hmm_vec3 = .zero;
var g_fog_start: f32 = 0;
var g_fog_end: f32 = 0;

var g_textures = std.mem.zeroes([kMAX_TEXTURES]jumpman_basic_3d_c.sg_image);
const kTEXTURE_FILENAME_LENGTH: usize = 300;
var g_texture_filename = std.mem.zeroes([kMAX_TEXTURES][kTEXTURE_FILENAME_LENGTH:0]u8);
var g_texture_is_alpha_blend_enabled = std.mem.zeroes([kMAX_TEXTURES]bool);
var g_texture_is_color_key_alpha_enabled = std.mem.zeroes([kMAX_TEXTURES]bool); // TODO: This is just for debugging. ifdef it out for release builds

const kERROR_IMAGE_WIDTH: usize = 32;
const kERROR_IMAGE_HEIGHT: usize = 32;
var g_error_image_data = std.mem.zeroes([kERROR_IMAGE_HEIGHT][kERROR_IMAGE_WIDTH][4]u8);

var g_world_to_view_matrix = std.mem.zeroes(hmm_mat4);
var g_world_to_view_matrix_previous = std.mem.zeroes(hmm_mat4);
var g_view_to_projection_matrix = std.mem.zeroes(hmm_mat4);
// These aren't necessarily interpolated, but if not then will fall back to the correct non-interpolated matrix for this frame
var g_interpolated_world_to_view_matrix = std.mem.zeroes(hmm_mat4);
var g_interpolated_world_to_projection_matrix = std.mem.zeroes(hmm_mat4);
var g_camera_animation_is_continuous = false;

var g_vertices_to_load_count: i32 = 0;
var g_vertices_to_load: ?[]MeshVertex = null;

var g_transform_count: i32 = 0;

var g_transform_translations = std.mem.zeroes([kMAX_TRANSFORMS]hmm_vec3);
var g_transform_rotations = std.mem.zeroes([kMAX_TRANSFORMS]hmm_quaternion);
var g_transform_scales = std.mem.zeroes([kMAX_TRANSFORMS]hmm_vec3);
var g_transform_translations_previous = std.mem.zeroes([kMAX_TRANSFORMS]hmm_vec3);
var g_transform_rotations_previous = std.mem.zeroes([kMAX_TRANSFORMS]hmm_quaternion);
var g_transform_scales_previous = std.mem.zeroes([kMAX_TRANSFORMS]hmm_vec3);
var g_transform_parent_indices = std.mem.zeroes([kMAX_TRANSFORMS]i32);
var g_transform_parent_handles = std.mem.zeroes([kMAX_TRANSFORMS]i32);
var g_transform_parent_is_camera = std.mem.zeroes([kMAX_TRANSFORMS]bool);
// TODO: Figure out how to get children to be next to parents, for better cache performance

var g_transform_handles = std.mem.zeroes([kMAX_TRANSFORMS]i32);
var g_transform_handle_next_free_indices = std.mem.zeroes([kMAX_TRANSFORMS]i32);
var g_transform_handle_first_free_index: i32 = 0;

var g_mesh_count: i32 = 0;

var g_mesh_vertex_start_indices = std.mem.zeroes([kMAX_MESHES]i32);
var g_mesh_vertex_counts = std.mem.zeroes([kMAX_MESHES]i32);
var g_mesh_texture_indices = std.mem.zeroes([kMAX_MESHES]i32);
var g_mesh_is_visible = std.mem.zeroes([kMAX_MESHES]bool);
var g_mesh_uv_offsets = std.mem.zeroes([kMAX_MESHES]hmm_vec2);
var g_mesh_is_visible_previous = std.mem.zeroes([kMAX_MESHES]bool);
var g_mesh_uv_offsets_previous = std.mem.zeroes([kMAX_MESHES]hmm_vec2);
var g_mesh_animation_is_continuous = std.mem.zeroes([kMAX_MESHES]bool);
var g_mesh_transform_indices = std.mem.zeroes([kMAX_MESHES]i32);

var g_mesh_handles = std.mem.zeroes([kMAX_MESHES]i32);
var g_mesh_handle_next_free_indices = std.mem.zeroes([kMAX_MESHES]i32);
var g_mesh_handle_first_free_index: i32 = 0;

// Begin: helpers that weren't included in HandmadeMath (yet). Replace if they are added

fn HMM_LookAtLH_(Eye: hmm_vec3, Center: hmm_vec3, Up: hmm_vec3) hmm_mat4 {
    var Result: hmm_mat4 = undefined;

    const F: hmm_vec3 = HMM_NormalizeVec3_(HMM_SubtractVec3_(Center, Eye));
    const S: hmm_vec3 = HMM_NormalizeVec3_(HMM_Cross_(Up, F));
    const U: hmm_vec3 = HMM_Cross_(F, S);

    Result.Elements[0][0] = S.X;
    Result.Elements[0][1] = U.X;
    Result.Elements[0][2] = F.X;
    Result.Elements[0][3] = 0.0;

    Result.Elements[1][0] = S.Y;
    Result.Elements[1][1] = U.Y;
    Result.Elements[1][2] = F.Y;
    Result.Elements[1][3] = 0.0;

    Result.Elements[2][0] = S.Z;
    Result.Elements[2][1] = U.Z;
    Result.Elements[2][2] = F.Z;
    Result.Elements[2][3] = 0.0;

    Result.Elements[3][0] = -HMM_DotVec3_(S, Eye);
    Result.Elements[3][1] = -HMM_DotVec3_(U, Eye);
    Result.Elements[3][2] = -HMM_DotVec3_(F, Eye);
    Result.Elements[3][3] = 1.0;

    return Result;
}

fn HMM_PerspectiveLH_NO_(FOV: f32, AspectRatio: f32, Near: f32, Far: f32) hmm_mat4 {
    var Result = std.mem.zeroes(hmm_mat4);

    const TanThetaOver2: f32 = std.math.tan(FOV * (HMM_PI32 / 360.0));

    Result.Elements[0][0] = 1.0 / (AspectRatio * TanThetaOver2);
    Result.Elements[1][1] = 1.0 / TanThetaOver2;
    Result.Elements[2][2] = (Far + Near) / (Far - Near);
    Result.Elements[2][3] = 1.0;
    Result.Elements[3][2] = -(2.0 * Far * Near) / (Far - Near);
    Result.Elements[3][3] = 0.0;

    return Result;
}

fn HMM_LerpVec3_(lhs: hmm_vec3, rhs: hmm_vec3, time: f32) hmm_vec3 {
    return HMM_AddVec3_(lhs, HMM_MultiplyVec3f_(HMM_SubtractVec3_(rhs, lhs), time));
}

fn HMM_LerpVec2_(lhs: hmm_vec2, rhs: hmm_vec2, time: f32) hmm_vec2 {
    return HMM_AddVec2_(lhs, HMM_MultiplyVec2f_(HMM_SubtractVec2_(rhs, lhs), time));
}

// End: helpers that weren't included in HandmadeMath (yet). Replace if they are added

pub fn Clear3dData() void {
    for (0..kERROR_IMAGE_WIDTH * kERROR_IMAGE_HEIGHT) |pixel_index| {
        @as([*]u32, @alignCast(@ptrCast(&g_error_image_data[0][0][0])))[pixel_index] = 0x7FFF00FF; // AABBGGRR
    }

    for (0..kMAX_TEXTURES) |texture_index| {
        if (g_textures[texture_index].id != jumpman_basic_3d_c.SG_INVALID_ID) {
            jumpman_basic_3d_c.sg_destroy_image(g_textures[texture_index]);
        }

        g_textures[texture_index].id = jumpman_basic_3d_c.SG_INVALID_ID;
    }

    g_transform_count = 0;

    for (0..kMAX_TRANSFORMS) |transform_index| {
        g_transform_translations[transform_index] = .zero;
        g_transform_rotations[transform_index] = .{ .X = 0.0, .Y = 0.0, .Z = 0.0, .W = 1.0 };
        g_transform_scales[transform_index] = .{ .X = 1.0, .Y = 1.0, .Z = 1.0 };
        g_transform_translations_previous[transform_index] = .zero;
        g_transform_rotations_previous[transform_index] = .{ .X = 0.0, .Y = 0.0, .Z = 0.0, .W = 1.0 };
        g_transform_scales_previous[transform_index] = .{ .X = 1.0, .Y = 1.0, .Z = 1.0 };
        g_transform_parent_indices[transform_index] = -1;
        g_transform_parent_handles[transform_index] = -1;
        g_transform_parent_is_camera[transform_index] = false;
        g_transform_handles[transform_index] = -1;
        g_transform_handle_next_free_indices[transform_index] = @intCast(transform_index + 1);
    }

    g_transform_handle_next_free_indices[kMAX_TRANSFORMS - 1] = -1;
    g_transform_handle_first_free_index = 0;

    g_mesh_count = 0;

    for (0..kMAX_MESHES) |mesh_index| {
        g_mesh_uv_offsets[mesh_index] = .zero;
        g_mesh_animation_is_continuous[mesh_index] = false;
        g_mesh_transform_indices[mesh_index] = -1;
        // TODO: Set visibility?
        g_mesh_handles[mesh_index] = -1;
        g_mesh_handle_next_free_indices[mesh_index] = @intCast(mesh_index + 1);
    }

    g_mesh_handle_next_free_indices[kMAX_MESHES - 1] = -1;
    g_mesh_handle_first_free_index = 0;

    g_vertices_to_load_count = 0;
}

// TODO: texture_index should be usize
pub fn LoadTexture(texture_index_i32: i32, sFile: [:0]const u8, image_type: i32, is_alpha_blend_enabled: bool) void {
    const texture_index: usize = @intCast(texture_index_i32);
    g_texture_is_alpha_blend_enabled[texture_index] = is_alpha_blend_enabled;
    std.mem.copyForwards(u8, &g_texture_filename[texture_index], sFile);
    g_texture_is_color_key_alpha_enabled[texture_index] = image_type == 1;

    // TODO: Convert to usize asap instead of casting a bunch below
    var width_cint: c_int = 0;
    var height_cint: c_int = 0;
    var channels_in_file: i32 = undefined;
    var image_data: ?[*]u8 = jumpman_basic_3d_c.stbi_load(&sFile[0], &width_cint, &height_cint, &channels_in_file, 4);
    defer if (image_data != null) {
        jumpman_basic_3d_c.stbi_image_free(image_data);
    };
    var width: usize = @intCast(width_cint);
    var height: usize = @intCast(height_cint);

    if (image_data != null) {
        if (image_type == 1) {
            // Color key alpha, on 0xFFFFFFFF
            for (0..height) |y| {
                for (0..width) |x| {
                    if (@as(*u32, @alignCast(@ptrCast(&image_data.?[y * width * 4 + x * 4 + 0]))).* == 0xFFFFFFFF) {
                        image_data.?[y * width * 4 + x * 4 + 3] = 0x0;
                    }
                }
            }
        }
    } else {
        width = kERROR_IMAGE_WIDTH;
        height = kERROR_IMAGE_HEIGHT;
        image_data = @ptrCast(&g_error_image_data[0][0][0]);

        // TODO: Error handling
        const error_message: ?[*c]const u8 = jumpman_basic_3d_c.stbi_failure_reason();
        std.log.err("Failed to load image file \"{s}\": {s}\ndefault texture loaded instead", .{ sFile, error_message.? });
    }

    var image_desc: jumpman_basic_3d_c.sg_image_desc = .{};
    image_desc.width = @intCast(width);
    image_desc.height = @intCast(height);
    image_desc.pixel_format = jumpman_basic_3d_c.SG_PIXELFORMAT_RGBA8;
    // TODO: Diff mipmap level based on image_type. 0: full set, 1: only one. Probably have to manually do the resize for each mip level. Use stb_image_resize.h?
    image_desc.min_filter = jumpman_basic_3d_c.SG_FILTER_LINEAR;
    image_desc.mag_filter = jumpman_basic_3d_c.SG_FILTER_LINEAR;
    image_desc.data.subimage[0][0].ptr = image_data;
    image_desc.data.subimage[0][0].size = width * height * 4;

    g_textures[texture_index] = jumpman_basic_3d_c.sg_make_image(&image_desc);

    if (g_textures[texture_index].id == jumpman_basic_3d_c.SG_INVALID_ID) {
        fatalError_("Error unlocking texture data"); // TODO: Read back error info
    }
}

fn init3d_() bool {
    for (0..kMAX_TEXTURES) |texture_index| {
        g_textures[texture_index].id = jumpman_basic_3d_c.SG_INVALID_ID;
    }

    for (0..kMAX_MESHES) |mesh_index| {
        g_mesh_handles[mesh_index] = -1;
        g_mesh_uv_offsets[mesh_index] = .zero;
        g_mesh_animation_is_continuous[mesh_index] = false;
        // TODO: Set visibility?
    }

    var desc: jumpman_basic_3d_c.sg_desc = .{};
    jumpman_basic_3d_c.sg_setup(&desc);

    if (!jumpman_basic_3d_c.sg_isvalid()) {
        return false;
    }

    return true;
}

fn initScene_() void {
    g_camera_light = .{
        .diffuse_color = .init(1.0, 1.0, 1.0),
        .ambient_color = .init(1.0, 1.0, 1.0),
        .position = .init(80.0, 100.0, -200.0),
        .range = 1000.0,
    };

    g_scene_ambient_color = .init(1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0);

    SetPerspective(80.0, 90.0, -145.0, 80.0, 59.0, 0.0);

    g_view_to_projection_matrix = HMM_PerspectiveLH_NO_(45.0, 640.0 / 480.0, 1.0, 300.0); // Fixed aspect ratio. Will be letterboxed elsewhere

    g_global_material = .{
        .ambient_tint = .init(0.5, 0.5, 0.5),
        .diffuse_tint = .init(0.5, 0.5, 0.5),
    };

    var vbuf_desc: jumpman_basic_3d_c.sg_buffer_desc = .{};
    vbuf_desc.usage = jumpman_basic_3d_c.SG_USAGE_STREAM;
    vbuf_desc.size = kMAX_VERTICES * @sizeOf(MeshVertex);

    g_bindings = .{};
    g_bindings.vertex_buffers[0] = jumpman_basic_3d_c.sg_make_buffer(&vbuf_desc);

    const shd: jumpman_basic_3d_c.sg_shader = jumpman_basic_3d_c.sg_make_shader(jumpman_basic_3d_c.main_shader_shader_desc(jumpman_basic_3d_c.SG_BACKEND_GLCORE33));

    var pip_desc: jumpman_basic_3d_c.sg_pipeline_desc = .{};

    pip_desc.layout.buffers[0].stride = @sizeOf(MeshVertex);
    var attrs: [*]jumpman_basic_3d_c.sg_vertex_attr_desc = @ptrCast(&pip_desc.layout.attrs[0]);
    attrs[0].format = jumpman_basic_3d_c.SG_VERTEXFORMAT_FLOAT3;
    attrs[1].format = jumpman_basic_3d_c.SG_VERTEXFORMAT_FLOAT3;
    attrs[2].format = jumpman_basic_3d_c.SG_VERTEXFORMAT_FLOAT2;

    pip_desc.shader = shd;

    pip_desc.depth.compare = jumpman_basic_3d_c.SG_COMPAREFUNC_LESS;
    pip_desc.depth.write_enabled = false;
    pip_desc.face_winding = jumpman_basic_3d_c.SG_FACEWINDING_CW;
    pip_desc.cull_mode = jumpman_basic_3d_c.SG_CULLMODE_BACK;

    pip_desc.colors[0].blend.enabled = true;
    pip_desc.colors[0].blend.src_factor_rgb = jumpman_basic_3d_c.SG_BLENDFACTOR_SRC_ALPHA;
    pip_desc.colors[0].blend.dst_factor_rgb = jumpman_basic_3d_c.SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
    pip_desc.colors[0].write_mask = jumpman_basic_3d_c.SG_COLORMASK_RGBA;

    g_transparent_pipline = jumpman_basic_3d_c.sg_make_pipeline(&pip_desc);

    pip_desc.depth.write_enabled = true;
    pip_desc.colors[0].blend.enabled = false;
    g_opaque_pipline = jumpman_basic_3d_c.sg_make_pipeline(&pip_desc);

    g_pass_action = .{};
    g_pass_action.colors[0].action = jumpman_basic_3d_c.SG_ACTION_CLEAR;
    g_pass_action.colors[0].value.r = 0.0;
    g_pass_action.colors[0].value.g = 0.0;
    g_pass_action.colors[0].value.b = 0.0;
    g_pass_action.colors[0].value.a = 1.0;
}

pub fn InitializeAll() bool {
    if (!init3d_()) {
        return false;
    }

    initScene_();

    return true;
}

// TODO: Take allocator as param
pub fn Begin3dLoad() void {
    if (g_vertices_to_load != null) {
        std.heap.c_allocator.free(g_vertices_to_load.?);
        g_vertices_to_load = null;
    }

    g_vertices_to_load = std.heap.c_allocator.alloc(MeshVertex, kMAX_VERTICES) catch @panic("failed to allocate"); // TODO: Better error handling

    if (g_vertices_to_load == null) {
        fatalError_("Failed to allocate enough memory in order to load model's vertex data");
    }
}

// TODO: Take allocator as param
pub fn EndAndCommit3dLoad() void {
    jumpman_basic_3d_c.sg_update_buffer(g_bindings.vertex_buffers[0], &.{ .ptr = &g_vertices_to_load.?[0], .size = kMAX_VERTICES * @sizeOf(MeshVertex) });

    if (g_vertices_to_load != null) {
        std.heap.c_allocator.free(g_vertices_to_load.?);
        g_vertices_to_load = null;
    }
}

pub fn Reset3d() void {
    // TODO: Is there any case where we need to reset the context? I think this is a relic from D3D9. Do we might need to handle suspend/resume, ala UWP though?
}

fn killScene_() void {
    for (0..kMAX_TEXTURES) |texture_index| {
        if (g_textures[texture_index].id != jumpman_basic_3d_c.SG_INVALID_ID) {
            jumpman_basic_3d_c.sg_destroy_image(g_textures[texture_index]);
            g_textures[texture_index].id = jumpman_basic_3d_c.SG_INVALID_ID;
        }
    }
}

fn kill3d_() void {
    jumpman_basic_3d_c.sg_shutdown();
}

pub fn DoCleanUp() void {
    killScene_();
    kill3d_();
}

// Returns null if handle not valid
fn getMeshIndexFromHandle_(mesh_handle_index_i32: i32) ?usize {
    const mesh_handle_index: usize = @intCast(mesh_handle_index_i32);
    std.debug.assert(mesh_handle_index < kMAX_MESHES);

    var mesh_index: ?usize = null;
    if (mesh_handle_index >= 0 and mesh_handle_index < kMAX_MESHES) {
        const temp_mesh_index: i32 = g_mesh_handles[mesh_handle_index];
        std.debug.assert(temp_mesh_index >= 0);
        std.debug.assert(temp_mesh_index < g_mesh_count);

        if (temp_mesh_index >= 0 and temp_mesh_index < g_mesh_count) {
            mesh_index = @intCast(temp_mesh_index);
        }
    }

    return mesh_index;
}

// Returns null if handle not valid
fn getTransformIndexFromHandle_(transform_handle_index_i32: i32) ?usize {
    const transform_handle_index: usize = @intCast(transform_handle_index_i32);
    std.debug.assert(transform_handle_index < kMAX_TRANSFORMS);

    var transform_index: ?usize = null;
    if (transform_handle_index < kMAX_MESHES) {
        const temp_transform_index: i32 = g_transform_handles[transform_handle_index];
        std.debug.assert(temp_transform_index >= 0);
        std.debug.assert(temp_transform_index < g_transform_count);

        if (temp_transform_index >= 0 and temp_transform_index < g_transform_count) {
            transform_index = @intCast(temp_transform_index);
        }
    }

    return transform_index;
}

pub fn TransformCreate() i32 {
    std.debug.assert(g_transform_count < kMAX_TRANSFORMS);
    std.debug.assert(g_transform_handle_first_free_index != -1);
    var new_transform_handle_index: i32 = -1;

    if (g_transform_count < kMAX_TRANSFORMS and g_transform_handle_first_free_index != -1) {
        const new_transform_index: usize = @intCast(g_transform_count);
        g_transform_translations[new_transform_index] = .zero;
        g_transform_rotations[new_transform_index] = .{ .X = 0.0, .Y = 0.0, .Z = 0.0, .W = 1.0 };
        g_transform_scales[new_transform_index] = .{ .X = 1.0, .Y = 1.0, .Z = 1.0 };
        g_transform_translations_previous[new_transform_index] = .zero;
        g_transform_rotations_previous[new_transform_index] = .{ .X = 0.0, .Y = 0.0, .Z = 0.0, .W = 1.0 };
        g_transform_scales_previous[new_transform_index] = .{ .X = 1.0, .Y = 1.0, .Z = 1.0 };
        g_transform_parent_indices[new_transform_index] = -1;
        g_transform_parent_handles[new_transform_index] = -1;
        g_transform_parent_is_camera[new_transform_index] = false;
        g_transform_count += 1;

        // TODO: Untangle the int casts
        new_transform_handle_index = @intCast(g_transform_handle_first_free_index);
        g_transform_handles[@intCast(new_transform_handle_index)] = @intCast(new_transform_index);
        g_transform_handle_first_free_index = g_transform_handle_next_free_indices[@intCast(g_transform_handle_first_free_index)];
    } // TODO: Else log?

    return new_transform_handle_index;
}

pub fn TransformDelete(deleting_transform_handle_index: i32) void {
    std.debug.assert(g_transform_count > 0);

    if (g_transform_count > 0) {
        const deleting_transform_index_from_handle: ?usize = getTransformIndexFromHandle_(deleting_transform_handle_index);
        const last_transform_index_i32: i32 = g_transform_count - 1;

        if (deleting_transform_index_from_handle) |deleting_transform_index| {
            if (g_transform_count > 1 and deleting_transform_index < last_transform_index_i32) {
                const last_transform_index: usize = @intCast(last_transform_index_i32);

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
                for (0..@intCast(g_mesh_count)) |mesh_index| {
                    if (g_mesh_transform_indices[mesh_index] == last_transform_index) {
                        g_mesh_transform_indices[mesh_index] = @intCast(deleting_transform_index);
                    }
                }

                // Redirect all transforms that had the last transform as their parent to its new location
                for (0..@intCast(g_transform_count)) |child_transform_index| {
                    if (g_transform_parent_indices[child_transform_index] == last_transform_index) {
                        g_transform_parent_indices[child_transform_index] = @intCast(deleting_transform_index);
                    }
                }

                // Redirect all handles that pointed at the last transform to its new location
                for (0..@intCast(kMAX_TRANSFORMS)) |handle_index| {
                    if (g_transform_handles[handle_index] == last_transform_index) {
                        g_transform_handles[handle_index] = @intCast(deleting_transform_index);
                    }
                }
            }

            g_transform_handle_next_free_indices[@intCast(deleting_transform_handle_index)] = g_transform_handle_first_free_index;
            g_transform_handle_first_free_index = deleting_transform_handle_index;

            g_transform_count -= 1;
        } // TODO: Else log?
    } // TODO: Else log?
}

pub fn TransformGetParent(transform_handle_index: i32) i32 {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);
    var result: i32 = -1;

    if (transform_index_from_handle) |transform_index| {
        result = g_transform_parent_handles[transform_index];
    } // TODO: Else log?

    return result;
}

pub fn TransformSetParent(transform_handle_index: i32, new_parent_transform_handle_index: i32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);
    const new_parent_transform_index_from_handle: ?usize = getTransformIndexFromHandle_(new_parent_transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        if (new_parent_transform_index_from_handle) |new_parent_transform_index| {
            // TODO: Detect cycle, assert, and break the cycle in non-debug build
            g_transform_parent_indices[transform_index] = @intCast(new_parent_transform_index);
            g_transform_parent_handles[transform_index] = @intCast(new_parent_transform_handle_index);
            g_transform_parent_is_camera[transform_index] = false;
        }
    } // TODO: Else log?
}

pub fn TransformClearParent(transform_handle_index: i32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_parent_indices[transform_index] = -1;
        g_transform_parent_handles[transform_index] = -1;
        g_transform_parent_is_camera[transform_index] = false;
    } // TODO: Else log?
}

pub fn TransformGetParentIsCamera(transform_handle_index: i32) bool {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);
    var result = false;

    if (transform_index_from_handle) |transform_index| {
        result = g_transform_parent_is_camera[transform_index];
    } // TODO: Else log?

    return result;
}

pub fn TransformSetParentIsCamera(transform_handle_index: i32, is_parent_camera: bool) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        if (is_parent_camera) {
            g_transform_parent_indices[transform_index] = -1;
            g_transform_parent_handles[transform_index] = -1;
        }

        g_transform_parent_is_camera[transform_index] = is_parent_camera;
    } // TODO: Else log?
}

pub fn MeshGetTransform(mesh_handle_index: i32) i32 {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle_(mesh_handle_index);
    var result: i32 = -1;

    if (mesh_index_from_handle) |mesh_index| {
        result = g_mesh_transform_indices[mesh_index];
    } // TODO: Else log?

    return result;
}

pub fn MeshSetTransform(mesh_handle_index: i32, transform_handle_index: i32) void {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle_(mesh_handle_index);
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);

    if (mesh_index_from_handle) |mesh_index| {
        if (transform_index_from_handle) |transform_index| {
            g_mesh_transform_indices[mesh_index] = @intCast(transform_index);
        }
    } // TODO: Else log?
}

pub fn MeshClearTransform(mesh_handle_index: i32) void {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle_(mesh_handle_index);

    if (mesh_index_from_handle) |mesh_index| {
        g_mesh_transform_indices[mesh_index] = -1;
    } // TODO: Else log?
}

pub fn TransformSetToIdentity(transform_handle_index: i32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_translations[transform_index] = .zero;
        g_transform_rotations[transform_index] = .init(0.0, 0.0, 0.0, 1.0);
        g_transform_scales[transform_index] = .init(1.0, 1.0, 1.0);
    } // TODO: Else log?
}

pub fn TransformSetTranslation(transform_handle_index: i32, x: f32, y: f32, z: f32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_translations[transform_index] = .init(x, y, z);
    } // TODO: Else log?
}

pub fn TransformClearTranslation(transform_handle_index: i32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_translations[transform_index] = .zero;
    } // TODO: Else log?
}

pub fn TransformSetRotationX(transform_handle_index: i32, angle_in_degrees: f32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_rotations[transform_index] = HMM_QuaternionFromAxisAngle_(.init(1.0, 0.0, 0.0), HMM_ToRadians_(angle_in_degrees));
    } // TODO: Else log?
}

pub fn TransformSetRotationY(transform_handle_index: i32, angle_in_degrees: f32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_rotations[transform_index] = HMM_QuaternionFromAxisAngle_(.init(0.0, 1.0, 0.0), HMM_ToRadians_(angle_in_degrees));
    } // TODO: Else log?
}

pub fn TransformSetRotationZ(transform_handle_index: i32, angle_in_degrees: f32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_rotations[transform_index] = HMM_QuaternionFromAxisAngle_(.init(0.0, 0.0, 1.0), HMM_ToRadians_(angle_in_degrees));
    } // TODO: Else log?
}

pub fn TransformConcatRotationX(transform_handle_index: i32, angle_in_degrees: f32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_rotations[transform_index] = HMM_MultiplyQuaternion_(HMM_QuaternionFromAxisAngle_((hmm_vec3){ .X = 1.0, .Y = 0.0, .Z = 0.0 }, HMM_ToRadians_(angle_in_degrees)), g_transform_rotations[transform_index]);
    } // TODO: Else log?
}

pub fn TransformConcatRotationY(transform_handle_index: i32, angle_in_degrees: f32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_rotations[transform_index] = HMM_MultiplyQuaternion_(HMM_QuaternionFromAxisAngle_((hmm_vec3){ .X = 0.0, .Y = 1.0, .Z = 0.0 }, HMM_ToRadians_(angle_in_degrees)), g_transform_rotations[transform_index]);
    } // TODO: Else log?
}

pub fn TransformConcatRotationZ(transform_handle_index: i32, angle_in_degrees: f32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_rotations[transform_index] = HMM_MultiplyQuaternion_(HMM_QuaternionFromAxisAngle_((hmm_vec3){ .X = 0.0, .Y = 0.0, .Z = 1.0 }, HMM_ToRadians_(angle_in_degrees)), g_transform_rotations[transform_index]);
    } // TODO: Else log?
}

pub fn TransformClearRotation(transform_handle_index: i32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_rotations[transform_index] = .init(0.0, 0.0, 0.0, 1.0);
    } // TODO: Else log?
}

pub fn TransformSetScale(transform_handle_index: i32, x: f32, y: f32, z: f32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_scales[transform_index] = .init(x, y, z);
    } // TODO: Else log?
}

pub fn TransformClearScale(transform_handle_index: i32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle_(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_scales[transform_index] = .init(1.0, 1.0, 1.0);
    } // TODO: Else log?
}

fn swapBool_(lhs: *bool, rhs: *bool) void {
    const temp: bool = lhs.*;
    lhs.* = rhs.*;
    rhs.* = temp;
}

fn swapInt_(lhs: *i32, rhs: *i32) void {
    const temp: i32 = lhs.*;
    lhs.* = rhs.*;
    rhs.* = temp;
}

fn getMeshHandleFromIndex_(mesh_index: i32) ?usize {
    std.debug.assert(mesh_index >= 0);
    std.debug.assert(mesh_index < kMAX_MESHES);

    var result_mesh_handle_index: ?usize = null;
    for (0..kMAX_MESHES) |mesh_handle_index| {
        if (g_mesh_handles[mesh_handle_index] == mesh_index) {
            result_mesh_handle_index = mesh_handle_index;
            break;
        }
    }

    if (result_mesh_handle_index == null) {
        _ = jumpman_basic_3d_c.boxerShow("Can't find mesh handle with given mesh index!", "Jumpman Zero", jumpman_basic_3d_c.BoxerStyleWarning, jumpman_basic_3d_c.BoxerButtonsOK); // TODO: Better error handling? Don't ignore result?
    }

    return result_mesh_handle_index;
}

fn meshSwap_(mesh_index_1: usize, mesh_index_2: usize) void {
    var temp_uv_offset: hmm_vec2 = g_mesh_uv_offsets[mesh_index_1];
    g_mesh_uv_offsets[mesh_index_1] = g_mesh_uv_offsets[mesh_index_2];
    g_mesh_uv_offsets[mesh_index_2] = temp_uv_offset;

    temp_uv_offset = g_mesh_uv_offsets_previous[mesh_index_1];
    g_mesh_uv_offsets_previous[mesh_index_1] = g_mesh_uv_offsets_previous[mesh_index_2];
    g_mesh_uv_offsets_previous[mesh_index_2] = temp_uv_offset;

    const temp_animation_is_continuous: bool = g_mesh_animation_is_continuous[mesh_index_1];
    g_mesh_animation_is_continuous[mesh_index_1] = g_mesh_animation_is_continuous[mesh_index_2];
    g_mesh_animation_is_continuous[mesh_index_2] = temp_animation_is_continuous;

    swapInt_(&g_mesh_vertex_start_indices[mesh_index_1], &g_mesh_vertex_start_indices[mesh_index_2]);
    swapInt_(&g_mesh_vertex_counts[mesh_index_1], &g_mesh_vertex_counts[mesh_index_2]);
    swapInt_(&g_mesh_texture_indices[mesh_index_1], &g_mesh_texture_indices[mesh_index_2]);
    swapBool_(&g_mesh_is_visible[mesh_index_1], &g_mesh_is_visible[mesh_index_2]);
    swapBool_(&g_mesh_is_visible_previous[mesh_index_1], &g_mesh_is_visible_previous[mesh_index_2]);

    swapInt_(&g_mesh_transform_indices[mesh_index_1], &g_mesh_transform_indices[mesh_index_2]);

    const mesh_handle_index_1_from_index: ?usize = getMeshHandleFromIndex_(@intCast(mesh_index_1));
    const mesh_handle_index_2_from_index: ?usize = getMeshHandleFromIndex_(@intCast(mesh_index_2));
    if (mesh_handle_index_1_from_index) |mesh_handle_index_1| {
        if (mesh_handle_index_2_from_index) |mesh_handle_index_2| {
            swapInt_(&g_mesh_handles[mesh_handle_index_1], &g_mesh_handles[mesh_handle_index_2]);
        } // TODO: Else log?
    } // TODO: Else log?
}

// TODO: vertex_count count should be usize
pub fn MeshCreateFromVertexComponents(vertex_components: [*]i32, vertex_count: i32) i32 {
    std.debug.assert(vertex_count >= 0);
    std.debug.assert(g_mesh_count < kMAX_MESHES);
    std.debug.assert(g_mesh_handle_first_free_index != -1);
    var new_mesh_handle_index: i32 = -1;

    if (g_mesh_count >= 0 and g_mesh_count < kMAX_TRANSFORMS and g_mesh_handle_first_free_index != -1) {
        const new_mesh_index: usize = @intCast(g_mesh_count);

        g_mesh_vertex_start_indices[new_mesh_index] = g_vertices_to_load_count;
        g_mesh_vertex_counts[new_mesh_index] = @intCast(vertex_count);

        g_mesh_texture_indices[new_mesh_index] = -1;
        g_mesh_is_visible[new_mesh_index] = false;
        g_mesh_uv_offsets[new_mesh_index] = .zero;
        g_mesh_animation_is_continuous[new_mesh_index] = false;
        // TODO: Set visibility?

        for (0..@intCast(vertex_count)) |vertex_index| {
            const new_vertex_index: usize = @intCast(g_vertices_to_load_count);
            g_vertices_to_load.?[new_vertex_index].x = @as(f32, @floatFromInt(vertex_components[vertex_index * 9 + 0])) / 256.0;
            g_vertices_to_load.?[new_vertex_index].y = @as(f32, @floatFromInt(vertex_components[vertex_index * 9 + 1])) / 256.0;
            g_vertices_to_load.?[new_vertex_index].z = @as(f32, @floatFromInt(vertex_components[vertex_index * 9 + 2])) / 256.0;
            g_vertices_to_load.?[new_vertex_index].nx = @as(f32, @floatFromInt(vertex_components[vertex_index * 9 + 3])) / 256.0;
            g_vertices_to_load.?[new_vertex_index].ny = @as(f32, @floatFromInt(vertex_components[vertex_index * 9 + 4])) / 256.0;
            g_vertices_to_load.?[new_vertex_index].nz = @as(f32, @floatFromInt(vertex_components[vertex_index * 9 + 5])) / 256.0;
            g_vertices_to_load.?[new_vertex_index].tu = @as(f32, @floatFromInt(vertex_components[vertex_index * 9 + 7])) / 256.0;
            g_vertices_to_load.?[new_vertex_index].tv = @as(f32, @floatFromInt(vertex_components[vertex_index * 9 + 8])) / 256.0;

            g_vertices_to_load_count += 1;
        }

        g_mesh_count += 1;

        new_mesh_handle_index = g_mesh_handle_first_free_index;
        g_mesh_handles[@intCast(new_mesh_handle_index)] = @intCast(new_mesh_index);
        g_mesh_handle_first_free_index = g_mesh_handle_next_free_indices[@intCast(g_mesh_handle_first_free_index)];
    } // TODO: Else log?

    return new_mesh_handle_index;
}

// TODO: vertex_count count should be usize
pub fn MeshCreateFromVertices(vertices: [*]MeshVertex, vertex_count: i32, texture_index: i32, is_visible: bool) i32 {
    std.debug.assert(g_mesh_count < kMAX_MESHES);
    std.debug.assert(g_mesh_handle_first_free_index != -1);
    var new_mesh_handle_index: i32 = -1;

    if (g_mesh_count < kMAX_TRANSFORMS and g_mesh_handle_first_free_index != -1) {
        const new_mesh_index: usize = @intCast(g_mesh_count);

        g_mesh_vertex_start_indices[new_mesh_index] = g_vertices_to_load_count;
        g_mesh_vertex_counts[new_mesh_index] = vertex_count;

        g_mesh_texture_indices[new_mesh_index] = texture_index;
        g_mesh_is_visible[new_mesh_index] = is_visible;
        g_mesh_uv_offsets[new_mesh_index] = .zero;
        g_mesh_animation_is_continuous[new_mesh_index] = false;
        // TODO: Set visibility?

        for (0..@intCast(vertex_count)) |vertex_index| {
            g_vertices_to_load.?[@intCast(g_vertices_to_load_count)] = vertices[vertex_index];
            g_vertices_to_load_count += 1;
        }

        g_mesh_count += 1;

        new_mesh_handle_index = g_mesh_handle_first_free_index;
        g_mesh_handles[@intCast(new_mesh_handle_index)] = @intCast(new_mesh_index);
        g_mesh_handle_first_free_index = g_mesh_handle_next_free_indices[@intCast(g_mesh_handle_first_free_index)];
    }

    return new_mesh_handle_index;
}

pub fn MeshCreateFromCopy(source_mesh_handle_index: i32) i32 {
    std.debug.assert(g_mesh_count < kMAX_MESHES);
    std.debug.assert(g_mesh_handle_first_free_index != -1);
    const source_mesh_index_from_handle: ?usize = getMeshIndexFromHandle_(source_mesh_handle_index);
    var new_mesh_handle_index: i32 = -1;

    if (g_mesh_count < kMAX_TRANSFORMS and g_mesh_handle_first_free_index != -1) {
        if (source_mesh_index_from_handle) |source_mesh_index| {
            const new_mesh_index: usize = @intCast(g_mesh_count);

            g_mesh_vertex_start_indices[new_mesh_index] = g_mesh_vertex_start_indices[source_mesh_index];
            g_mesh_vertex_counts[new_mesh_index] = g_mesh_vertex_counts[source_mesh_index];

            g_mesh_texture_indices[new_mesh_index] = -1; // TODO: Copy texture over?
            g_mesh_is_visible[new_mesh_index] = false;
            g_mesh_uv_offsets[new_mesh_index] = .zero;
            g_mesh_animation_is_continuous[new_mesh_index] = false;
            // TODO: Set visibility?

            g_mesh_count += 1;

            new_mesh_handle_index = g_mesh_handle_first_free_index;
            g_mesh_handles[@intCast(new_mesh_handle_index)] = @intCast(new_mesh_index);
            g_mesh_handle_first_free_index = g_mesh_handle_next_free_indices[@intCast(g_mesh_handle_first_free_index)];
        }
    }

    return new_mesh_handle_index;
}

pub fn MeshReplaceWithCopy(target_mesh_handle_index: i32, source_mesh_handle_index: i32) void {
    const target_mesh_index_from_handle: ?usize = getMeshIndexFromHandle_(target_mesh_handle_index);
    const source_mesh_index_from_handle: ?usize = getMeshIndexFromHandle_(source_mesh_handle_index);

    if (target_mesh_index_from_handle) |target_mesh_index| {
        if (source_mesh_index_from_handle) |source_mesh_index| {
            g_mesh_vertex_start_indices[target_mesh_index] = g_mesh_vertex_start_indices[source_mesh_index];
            g_mesh_vertex_counts[target_mesh_index] = g_mesh_vertex_counts[source_mesh_index];
        }
    }
}

pub fn MeshDelete(deleting_mesh_handle_index: i32) void {
    std.debug.assert(g_mesh_count > 0);
    const deleting_mesh_index_from_handle: ?usize = getMeshIndexFromHandle_(deleting_mesh_handle_index);

    if (g_mesh_count > 0) {
        if (deleting_mesh_index_from_handle) |deleting_mesh_index| {
            const last_mesh_index: usize = @intCast(g_mesh_count - 1);

            if (g_mesh_count > 1 and deleting_mesh_index < last_mesh_index) {
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
                for (0..kMAX_MESHES) |handle_index| {
                    if (g_mesh_handles[handle_index] == last_mesh_index) {
                        g_mesh_handles[handle_index] = @intCast(deleting_mesh_index);
                    }
                }
            }
        }

        g_mesh_handle_next_free_indices[@intCast(deleting_mesh_handle_index)] = g_mesh_handle_first_free_index;
        g_mesh_handle_first_free_index = deleting_mesh_handle_index;

        g_mesh_count -= 1;
    } // TODO: Else log?
}

pub fn MeshSetIsVisible(mesh_handle_index: i32, is_visible: bool) void {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle_(mesh_handle_index);
    if (mesh_index_from_handle) |mesh_index| {
        g_mesh_is_visible[mesh_index] = is_visible;
    }
}

pub fn MeshSetTextureIndex(mesh_handle_index: i32, texture_index: i32) void {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle_(mesh_handle_index);
    if (mesh_index_from_handle) |mesh_index| {
        g_mesh_texture_indices[mesh_index] = texture_index;
    }
}

pub fn MeshMoveToFrontForTransparentDrawing(mesh_handle_index: i32) void {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle_(mesh_handle_index);

    if (mesh_index_from_handle) |mesh_index| {
        for (mesh_index + 1..@intCast(g_mesh_count)) |current_mesh_index| {
            meshSwap_(current_mesh_index, current_mesh_index - 1);
        }
    } // TODO: Else log?
}

pub fn MeshMoveToBackForTransparentDrawing(mesh_handle_index: i32) void {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle_(mesh_handle_index);

    if (mesh_index_from_handle) |mesh_index| {
        var current_mesh_index: usize = mesh_index - 1;
        while (current_mesh_index >= 0) : (current_mesh_index -= 1) {
            meshSwap_(current_mesh_index, current_mesh_index + 1);
        }
    }
}

pub fn MeshScrollTexture(mesh_handle_index: i32, translate_x: f32, translate_y: f32) void {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle_(mesh_handle_index);

    if (mesh_index_from_handle) |mesh_index| {
        g_mesh_uv_offsets[mesh_index] = HMM_AddVec2_(.init(translate_x, translate_y), g_mesh_uv_offsets[mesh_index]);
    }
}

pub fn MeshSetIsAnimationContinuous(mesh_handle_index: i32, is_continuous: bool) void {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle_(mesh_handle_index);
    if (mesh_index_from_handle) |mesh_index| {
        g_mesh_animation_is_continuous[mesh_index] = is_continuous;
    }
}

pub fn SetCameraIsAnimationContinuous(is_continuous: bool) void {
    g_camera_animation_is_continuous = is_continuous;
}

pub fn SetFog(fog_start: f32, fog_end: f32, red: u8, green: u8, blue: u8) void {
    if (fog_start == 0 and fog_end == 0) {
        g_is_fog_enabled = false;
    } else {
        g_is_fog_enabled = true;
        g_fog_color = .init(@as(f32, @floatFromInt(red)) / 255.0, @as(f32, @floatFromInt(green)) / 255.0, @as(f32, @floatFromInt(blue)) / 255.0);
        g_fog_start = fog_start;
        g_fog_end = fog_end;
    }
}

pub fn SetPerspective(cam_x: f32, cam_y: f32, cam_z: f32, look_at_x: f32, look_at_y: f32, look_at_z: f32) void {
    g_world_to_view_matrix = HMM_LookAtLH_(.init(cam_x, cam_y, cam_z), .init(look_at_x, look_at_y, look_at_z), .init(0.0, 1.0, 0.0));
    g_camera_light.position = .init(cam_x, cam_y + 10.0, -200.0);
    g_camera_light.diffuse_color = .init(1.0, 1.0, 1.0);
    g_camera_light.ambient_color = .init(1.0, 1.0, 1.0);
}

pub fn RendererPreUpdate(_: f64) void {
    g_world_to_view_matrix_previous = g_world_to_view_matrix;
    g_camera_animation_is_continuous = true;

    for (0..@intCast(g_mesh_count)) |mesh_index| {
        if (!g_mesh_animation_is_continuous[mesh_index]) {
            // Has to have existed since previous update call for this to be triggered
            g_mesh_animation_is_continuous[mesh_index] = true;
        }

        g_mesh_is_visible_previous[mesh_index] = g_mesh_is_visible[mesh_index];
        g_mesh_uv_offsets_previous[mesh_index] = g_mesh_uv_offsets[mesh_index];
    }

    for (0..@intCast(g_transform_count)) |transform_index| {
        g_transform_translations_previous[transform_index] = g_transform_translations[transform_index];
        g_transform_rotations_previous[transform_index] = g_transform_rotations[transform_index];
        g_transform_scales_previous[transform_index] = g_transform_scales[transform_index];
    }
}

pub fn RendererPostUpdate() void {
    for (0..@intCast(g_mesh_count)) |mesh_index| {
        if (!g_mesh_is_visible_previous[mesh_index] and g_mesh_is_visible[mesh_index]) {
            g_mesh_animation_is_continuous[mesh_index] = false;
        }
    }
}

fn renderMesh_(mesh_index: usize, previous_texture_index: *i32, vs_params: *main_shader_vs_params_t, are_fs_params_applied: *bool, fs_params: *main_shader_fs_params_t, do_interpolation: bool, interpolation_scale: f32) void {
    const current_texture_index_i32: i32 = g_mesh_texture_indices[mesh_index];
    std.debug.assert(current_texture_index_i32 != -1);
    const current_texture_index: usize = @intCast(current_texture_index_i32);
    // TODO: If current_texture_index == -1 then set to a default texture

    if (previous_texture_index.* != current_texture_index) {
        previous_texture_index.* = current_texture_index_i32;
        g_bindings.fs_images[0] = g_textures[current_texture_index];
        jumpman_basic_3d_c.sg_apply_bindings(&g_bindings);
    }

    var current_transform_index_i32: i32 = g_mesh_transform_indices[mesh_index];
    var transform_skip_world_to_view: bool = false;

    // TODO: Calculate matrices in more cache-friendly/packed manner
    // TODO: Are parent/child being multiplied in the correct order here? Seems they're reversed right now. Should do parent[SRT]child[SRT]?
    var current_local_to_world_matrix: hmm_mat4 = .{ .Elements = .{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    } };

    if (do_interpolation and g_mesh_animation_is_continuous[mesh_index]) {
        while (current_transform_index_i32 != -1) {
            const current_transform_index: usize = @intCast(current_transform_index_i32);
            const current_translation: hmm_vec3 = HMM_LerpVec3_(g_transform_translations_previous[current_transform_index], g_transform_translations[current_transform_index], interpolation_scale);
            const current_rotation: hmm_quaternion = HMM_Slerp_(g_transform_rotations_previous[current_transform_index], interpolation_scale, g_transform_rotations[current_transform_index]);
            const current_scale: hmm_vec3 = HMM_LerpVec3_(g_transform_scales_previous[current_transform_index], g_transform_scales[current_transform_index], interpolation_scale);
            current_local_to_world_matrix =
                HMM_MultiplyMat4_(HMM_Translate_(current_translation), HMM_MultiplyMat4_(HMM_QuaternionToMat4_(current_rotation), HMM_MultiplyMat4_(.scale(current_scale), current_local_to_world_matrix)));

            if (g_transform_parent_is_camera[current_transform_index]) {
                transform_skip_world_to_view = true;
            }

            current_transform_index_i32 = g_transform_parent_indices[current_transform_index];
        }
    } else {
        while (current_transform_index_i32 != -1) {
            const current_transform_index: usize = @intCast(current_transform_index_i32);
            const current_translation: hmm_vec3 = g_transform_translations[current_transform_index];
            const current_rotation: hmm_quaternion = g_transform_rotations[current_transform_index];
            const current_scale: hmm_vec3 = g_transform_scales[current_transform_index];
            current_local_to_world_matrix =
                HMM_MultiplyMat4_(HMM_Translate_(current_translation), HMM_MultiplyMat4_(HMM_QuaternionToMat4_(current_rotation), HMM_MultiplyMat4_(.scale(current_scale), current_local_to_world_matrix)));

            if (g_transform_parent_is_camera[current_transform_index]) {
                transform_skip_world_to_view = true;
            }

            current_transform_index_i32 = g_transform_parent_indices[current_transform_index];
        }
    }

    vs_params.local_to_world_matrix = current_local_to_world_matrix;
    vs_params.local_to_view_matrix = if (transform_skip_world_to_view)
        current_local_to_world_matrix
    else
        HMM_MultiplyMat4_(g_interpolated_world_to_view_matrix, current_local_to_world_matrix);
    vs_params.local_to_projection_matrix = if (transform_skip_world_to_view)
        HMM_MultiplyMat4_(g_view_to_projection_matrix, current_local_to_world_matrix)
    else
        HMM_MultiplyMat4_(g_interpolated_world_to_projection_matrix, current_local_to_world_matrix);
    vs_params.transpose_world_to_local_matrix = current_local_to_world_matrix.getInverse().getTranspose();

    if (do_interpolation and g_mesh_animation_is_continuous[mesh_index]) {
        vs_params.uv_offset = HMM_LerpVec2_(g_mesh_uv_offsets_previous[mesh_index], g_mesh_uv_offsets[mesh_index], interpolation_scale);
    } else {
        vs_params.uv_offset = g_mesh_uv_offsets[mesh_index];
    }

    jumpman_basic_3d_c.sg_apply_uniforms(jumpman_basic_3d_c.SG_SHADERSTAGE_VS, 0, &.{ .ptr = vs_params, .size = @sizeOf(main_shader_vs_params_t) });

    if (!are_fs_params_applied.*) {
        jumpman_basic_3d_c.sg_apply_uniforms(jumpman_basic_3d_c.SG_SHADERSTAGE_FS, 0, &.{ .ptr = fs_params, .size = @sizeOf(main_shader_fs_params_t) });
        are_fs_params_applied.* = true;
    }

    jumpman_basic_3d_c.sg_draw(g_mesh_vertex_start_indices[mesh_index], g_mesh_vertex_counts[mesh_index], 1);
}

// TODO: Rename to match zig naming standards
const main_shader_vs_params_t = extern struct {
    local_to_world_matrix: hmm_mat4,
    local_to_view_matrix: hmm_mat4,
    local_to_projection_matrix: hmm_mat4,
    transpose_world_to_local_matrix: hmm_mat4,
    uv_offset: hmm_vec2,
    _pad_264: [8]u8,
};

// TODO: Rename to match zig naming standards
const main_shader_fs_params_t = extern struct {
    scene_ambient_color: hmm_vec3,
    _pad_12: [4]u8,
    material_ambient_tint: hmm_vec3,
    _pad_28: [4]u8,
    material_diffuse_tint: hmm_vec3,
    _pad_44: [4]u8,
    light_ambient_color: hmm_vec3,
    _pad_60: [4]u8,
    light_diffuse_color: hmm_vec3,
    _pad_76: [4]u8,
    light_position: hmm_vec3,
    light_range: f32,
    is_fog_enabled: f32,
    _pad_100: [12]u8,
    fog_color: hmm_vec3,
    fog_start: f32,
    fog_end: f32,
    _pad_132: [12]u8,
};

pub fn RendererDraw(do_interpolation: bool, interpolation_scale: f32) void {
    jumpman_basic_3d_c.sg_begin_default_pass(&g_pass_action, g_backbuffer_width, g_backbuffer_height);

    const backbuffer_aspect_ratio: f32 = @as(f32, @floatFromInt(g_backbuffer_width)) / @as(f32, @floatFromInt(g_backbuffer_height));
    const target_aspect_ratio: f32 = 640.0 / 480.0;

    if (backbuffer_aspect_ratio > target_aspect_ratio) {
        const width_scale: f32 = target_aspect_ratio / backbuffer_aspect_ratio;
        const border_half_width: f32 = (@as(f32, @floatFromInt(g_backbuffer_width)) - width_scale * @as(f32, @floatFromInt(g_backbuffer_width))) / 2.0;
        jumpman_basic_3d_c.sg_apply_viewport(@intFromFloat(border_half_width), 0, g_backbuffer_width - @as(i32, @intFromFloat(border_half_width * 2.0)), g_backbuffer_height, true);
    } else {
        const height_scale: f32 = backbuffer_aspect_ratio / target_aspect_ratio;
        const border_half_height: f32 = (@as(f32, @floatFromInt(g_backbuffer_height)) - height_scale * @as(f32, @floatFromInt(g_backbuffer_height))) / 2.0;
        jumpman_basic_3d_c.sg_apply_viewport(0, @intFromFloat(border_half_height), g_backbuffer_width, g_backbuffer_height - @as(i32, @intFromFloat(border_half_height * 2.0)), true);
    }

    var vs_params: main_shader_vs_params_t = undefined;
    var fs_params: main_shader_fs_params_t = undefined;
    fs_params.scene_ambient_color = g_scene_ambient_color;
    fs_params.material_ambient_tint = g_global_material.ambient_tint; // TODO: Use struct in shader?
    fs_params.material_diffuse_tint = g_global_material.diffuse_tint;
    fs_params.light_ambient_color = g_camera_light.ambient_color; // TODO: Use struct in shader?
    fs_params.light_diffuse_color = g_camera_light.diffuse_color;
    fs_params.light_position = g_camera_light.position;
    fs_params.light_range = g_camera_light.range;
    fs_params.is_fog_enabled = if (g_is_fog_enabled) 1.0 else 0.0;
    fs_params.fog_color = g_fog_color;
    fs_params.fog_start = g_fog_start;
    fs_params.fog_end = g_fog_end;

    g_interpolated_world_to_view_matrix = g_world_to_view_matrix;

    if (do_interpolation and g_camera_animation_is_continuous) {
        const camera_pos_current: hmm_vec3 = @as(*const hmm_vec3, @ptrCast(&g_world_to_view_matrix.Elements[3])).*;
        const camera_pos_previous: hmm_vec3 = @as(*const hmm_vec3, @ptrCast(&g_world_to_view_matrix_previous.Elements[3])).*;
        @as(*hmm_vec3, @ptrCast(&g_interpolated_world_to_view_matrix.Elements[3][0])).* = HMM_AddVec3_(camera_pos_previous, HMM_MultiplyVec3f_(HMM_SubtractVec3_(camera_pos_current, camera_pos_previous), if (g_camera_animation_is_continuous) interpolation_scale else 0.0));
    }

    g_interpolated_world_to_projection_matrix = HMM_MultiplyMat4_(g_view_to_projection_matrix, g_interpolated_world_to_view_matrix);

    // Draw opaque
    jumpman_basic_3d_c.sg_apply_pipeline(g_opaque_pipline);

    var previous_texture_index: i32 = -1;
    var are_fs_params_applied: bool = false; // These are currently set globally, so don't need to be set for every mesh

    for (0..@intCast(g_mesh_count)) |mesh_index| {
        if (g_mesh_is_visible[mesh_index] and !g_texture_is_alpha_blend_enabled[@intCast(g_mesh_texture_indices[mesh_index])]) {
            renderMesh_(mesh_index, &previous_texture_index, &vs_params, &are_fs_params_applied, &fs_params, do_interpolation, interpolation_scale);
        }
    }

    // Draw transparent
    jumpman_basic_3d_c.sg_apply_pipeline(g_transparent_pipline);

    previous_texture_index = -1;
    are_fs_params_applied = false;

    for (0..@intCast(g_mesh_count)) |mesh_index| {
        if (g_mesh_is_visible[mesh_index] and g_texture_is_alpha_blend_enabled[@intCast(g_mesh_texture_indices[mesh_index])]) {
            renderMesh_(mesh_index, &previous_texture_index, &vs_params, &are_fs_params_applied, &fs_params, do_interpolation, interpolation_scale);
        }
    }

    jumpman_basic_3d_c.sg_end_pass();
    jumpman_basic_3d_c.sg_commit();
}

pub fn ResizeViewport(width: i32, height: i32) void {
    g_backbuffer_width = width;
    g_backbuffer_height = height;
}

pub fn GetViewportMousePos(pos_x: *f32, pos_y: *f32) void {
    const backbuffer_width: f32 = @as(f32, @floatFromInt(g_backbuffer_width));
    const backbuffer_height: f32 = @as(f32, @floatFromInt(g_backbuffer_height));
    const backbuffer_aspect_ratio: f32 = backbuffer_width / backbuffer_height;
    const target_aspect_ratio: f32 = 640.0 / 480.0;

    var temp_x: f32 = undefined;
    var temp_y: f32 = undefined;

    if (backbuffer_aspect_ratio > target_aspect_ratio) {
        const width_scale: f32 = target_aspect_ratio / backbuffer_aspect_ratio;
        const border_half_width: f32 = (backbuffer_width - width_scale * backbuffer_width) / 2.0;

        temp_x = (pos_x.* - border_half_width) / (backbuffer_width - (border_half_width * 2.0));
        temp_y = pos_y.* / backbuffer_height;
    } else {
        const height_scale: f32 = backbuffer_aspect_ratio / target_aspect_ratio;
        const border_half_height: f32 = (backbuffer_height - height_scale * backbuffer_height) / 2.0;

        temp_x = pos_x.* / backbuffer_width;
        temp_y = (pos_y.* - border_half_height) / (backbuffer_height - (border_half_height * 2.0));
    }

    if (temp_x < 0.0) {
        temp_x = 0.0;
    }
    if (temp_x > 1.0) {
        temp_x = 1.0;
    }
    if (temp_y < 0.0) {
        temp_y = 0.0;
    }
    if (temp_y > 1.0) {
        temp_y = 1.0;
    }

    pos_x.* = temp_x;
    pos_y.* = temp_y;
}

fn fatalError_(error_msg: []const u8) void {
    killScene_();
    kill3d_();
    _ = jumpman_basic_3d_c.boxerShow(&error_msg[0], "Jumpman Zero", jumpman_basic_3d_c.BoxerStyleError, jumpman_basic_3d_c.BoxerButtonsOK); // TODO: Don't discard result?
}
