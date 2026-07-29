const std = @import("std");
const boxer_c = @import("boxer_c");
const sokol_gfx_c = @import("sokol_gfx_c");
const stb_image_c = @import("stb_image_c");

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

const Color3 = extern struct {
    r: f32,
    g: f32,
    b: f32,

    fn init(r: f32, g: f32, b: f32) Color3 {
        const result = Color3{ .r = r, .g = g, .b = b };
        return result;
    }

    fn initFromU8(r: u8, g: u8, b: u8) Color3 {
        const max_value: f32 = 255.0;
        const result = init(
            @as(f32, @floatFromInt(r)) / max_value,
            @as(f32, @floatFromInt(g)) / max_value,
            @as(f32, @floatFromInt(b)) / max_value,
        );
        return result;
    }

    const black = init(0, 0, 0);
    const white = init(1, 1, 1);
    const red = init(1, 0, 0);
    const green = init(0, 1, 0);
    const blue = init(0, 0, 1);
    const magenta = init(1, 0, 1);
    const yellow = init(1, 1, 0);
    const cyan = init(0, 1, 1);

    const almost_black = init(1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0);
};

const Vec2 = extern struct {
    x: f32,
    y: f32,

    fn init(x: f32, y: f32) Vec2 {
        const result = Vec2{ .x = x, .y = y };
        return result;
    }

    fn add(lhs: Vec2, rhs: Vec2) Vec2 {
        const result = init(lhs.x + rhs.x, lhs.y + rhs.y);
        return result;
    }

    fn sub(lhs: Vec2, rhs: Vec2) Vec2 {
        const result = init(lhs.x - rhs.x, lhs.y - rhs.y);
        return result;
    }

    fn mul(lhs: Vec2, rhs: f32) Vec2 {
        const result = init(lhs.x * rhs, lhs.y * rhs);
        return result;
    }

    fn lerp(lhs: Vec2, rhs: Vec2, time: f32) Vec2 {
        return add(lhs, mul(sub(rhs, lhs), time));
    }

    const zero = init(0, 0);
};

const Vec3 = extern struct {
    x: f32,
    y: f32,
    z: f32,

    fn init(x: f32, y: f32, z: f32) Vec3 {
        const result = Vec3{ .x = x, .y = y, .z = z };
        return result;
    }

    fn add(lhs: Vec3, rhs: Vec3) Vec3 {
        const result = init(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z);
        return result;
    }

    fn sub(lhs: Vec3, rhs: Vec3) Vec3 {
        const result = init(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z);
        return result;
    }

    fn mul(lhs: Vec3, rhs: f32) Vec3 {
        const result = init(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs);
        return result;
    }

    fn div(vec: Vec3, scalar: f32) Vec3 {
        const result = init(vec.x / scalar, vec.y / scalar, vec.z / scalar);
        return result;
    }

    fn dot(lhs: Vec3, rhs: Vec3) f32 {
        const result = lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z;
        return result;
    }

    fn cross(lhs: Vec3, rhs: Vec3) Vec3 {
        const result = init(lhs.y * rhs.z - lhs.z * rhs.y, lhs.z * rhs.x - lhs.x * rhs.z, lhs.x * rhs.y - lhs.y * rhs.x);
        return result;
    }

    fn lerp(lhs: Vec3, rhs: Vec3, time: f32) Vec3 {
        return add(lhs, mul(sub(rhs, lhs), time));
    }

    fn getNormalized(self: Vec3) Vec3 {
        var result: Vec3 = .zero;
        const vector_length = std.math.sqrt(dot(self, self));
        if (vector_length != 0.0) {
            result = init(
                self.x * (1.0 / vector_length),
                self.y * (1.0 / vector_length),
                self.z * (1.0 / vector_length),
            );
        }
        return result;
    }

    const zero = init(0, 0, 0);
    const one = init(1, 1, 1);
    const x_axis = init(1, 0, 0);
    const y_axis = init(0, 1, 0);
    const z_axis = init(0, 0, 1);
};

const Vec4 = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    fn init(x: f32, y: f32, z: f32, w: f32) Vec4 {
        const result = Vec4{ .x = x, .y = y, .z = z, .w = w };
        return result;
    }

    fn add(lhs: Vec4, rhs: Vec4) Vec4 {
        const result = init(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w);
        return result;
    }

    fn sub(lhs: Vec4, rhs: Vec4) Vec4 {
        const result = init(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w);
        return result;
    }

    fn mul(lhs: Vec4, rhs: Vec4) Vec4 {
        const result = init(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z, lhs.w * rhs.w);
        return result;
    }

    const zero = init(0, 0, 0, 0);
    const one = init(1, 1, 1, 1);
    const x_axis = init(1, 0, 0, 0);
    const y_axis = init(0, 1, 0, 0);
    const z_axis = init(0, 0, 1, 0);
    const w_axis = init(0, 0, 0, 1);
};

const Mat4 = extern struct {
    elements: [4][4]f32,

    fn fromVec4(column_0: Vec4, column_1: Vec4, column_2: Vec4, column_3: Vec4) Mat4 {
        const result: Mat4 = .{ .elements = .{
            .{ column_0.x, column_0.y, column_0.z, column_0.w },
            .{ column_1.x, column_1.y, column_1.z, column_1.w },
            .{ column_2.x, column_2.y, column_2.z, column_2.w },
            .{ column_3.x, column_3.y, column_3.z, column_3.w },
        } };
        return result;
    }

    fn fromScale(value: Vec3) Mat4 {
        const result: Mat4 = .{ .elements = .{
            .{ value.x, 0.0, 0.0, 0.0 },
            .{ 0.0, value.y, 0.0, 0.0 },
            .{ 0.0, 0.0, value.z, 0.0 },
            .{ 0.0, 0.0, 0.0, 1.0 },
        } };
        return result;
    }

    fn fromTranslation(translation: Vec3) Mat4 {
        const result: Mat4 = .{ .elements = .{
            .{ 1.0, 0.0, 0.0, 0.0 },
            .{ 0.0, 1.0, 0.0, 0.0 },
            .{ 0.0, 0.0, 1.0, 0.0 },
            .{ translation.x, translation.y, translation.z, 1.0 },
        } };
        return result;
    }

    fn fromLookAtLeftHanded(eye: Vec3, center: Vec3, up: Vec3) Mat4 {
        var result: Mat4 = undefined;

        const f = Vec3.getNormalized(Vec3.sub(center, eye));
        const s = Vec3.getNormalized(Vec3.cross(up, f));
        const u = Vec3.cross(f, s);

        result.elements[0][0] = s.x;
        result.elements[0][1] = u.x;
        result.elements[0][2] = f.x;
        result.elements[0][3] = 0.0;

        result.elements[1][0] = s.y;
        result.elements[1][1] = u.y;
        result.elements[1][2] = f.y;
        result.elements[1][3] = 0.0;

        result.elements[2][0] = s.z;
        result.elements[2][1] = u.z;
        result.elements[2][2] = f.z;
        result.elements[2][3] = 0.0;

        result.elements[3][0] = -Vec3.dot(s, eye);
        result.elements[3][1] = -Vec3.dot(u, eye);
        result.elements[3][2] = -Vec3.dot(f, eye);
        result.elements[3][3] = 1.0;

        return result;
    }

    fn fromPerspectiveLeftHandedNegativeOne(fov: f32, aspect_ratio: f32, near_distance: f32, far_distance: f32) Mat4 {
        var result = std.mem.zeroes(Mat4);

        const TanThetaOver2: f32 = std.math.tan(std.math.degreesToRadians(fov / 2));

        result.elements[0][0] = 1.0 / (aspect_ratio * TanThetaOver2);
        result.elements[1][1] = 1.0 / TanThetaOver2;
        result.elements[2][2] = (far_distance + near_distance) / (far_distance - near_distance);
        result.elements[2][3] = 1.0;
        result.elements[3][2] = -(2.0 * far_distance * near_distance) / (far_distance - near_distance);
        result.elements[3][3] = 0.0;

        return result;
    }

    fn mul(lhs: Mat4, rhs: Mat4) Mat4 {
        var result: Mat4 = undefined;
        for (0..4) |column| {
            for (0..4) |row| {
                var sum: f32 = 0;
                for (0..4) |current_index| {
                    sum += lhs.elements[current_index][row] * rhs.elements[column][current_index];
                }
                result.elements[column][row] = sum;
            }
        }
        return result;
    }

    fn mulByScalar(mat: Mat4, scalar: f32) Mat4 {
        var result: Mat4 = undefined;
        for (0..4) |column| {
            for (0..4) |row| {
                result.elements[column][row] = mat.elements[column][row] * scalar;
            }
        }
        return result;
    }

    fn getTranspose(self: Mat4) Mat4 {
        var result: Mat4 = undefined;
        for (0..4) |column| {
            for (0..4) |row| {
                result.elements[row][column] = self.elements[column][row];
            }
        }
        return result;
    }

    fn getInverse(self: Mat4) Mat4 {
        const coef_00 = self.elements[2][2] * self.elements[3][3] - self.elements[3][2] * self.elements[2][3];
        const coef_02 = self.elements[1][2] * self.elements[3][3] - self.elements[3][2] * self.elements[1][3];
        const coef_03 = self.elements[1][2] * self.elements[2][3] - self.elements[2][2] * self.elements[1][3];

        const coef_04 = self.elements[2][1] * self.elements[3][3] - self.elements[3][1] * self.elements[2][3];
        const coef_06 = self.elements[1][1] * self.elements[3][3] - self.elements[3][1] * self.elements[1][3];
        const coef_07 = self.elements[1][1] * self.elements[2][3] - self.elements[2][1] * self.elements[1][3];

        const coef_08 = self.elements[2][1] * self.elements[3][2] - self.elements[3][1] * self.elements[2][2];
        const coef_10 = self.elements[1][1] * self.elements[3][2] - self.elements[3][1] * self.elements[1][2];
        const coef_11 = self.elements[1][1] * self.elements[2][2] - self.elements[2][1] * self.elements[1][2];

        const coef_12 = self.elements[2][0] * self.elements[3][3] - self.elements[3][0] * self.elements[2][3];
        const coef_14 = self.elements[1][0] * self.elements[3][3] - self.elements[3][0] * self.elements[1][3];
        const coef_15 = self.elements[1][0] * self.elements[2][3] - self.elements[2][0] * self.elements[1][3];

        const coef_16 = self.elements[2][0] * self.elements[3][2] - self.elements[3][0] * self.elements[2][2];
        const coef_18 = self.elements[1][0] * self.elements[3][2] - self.elements[3][0] * self.elements[1][2];
        const coef_19 = self.elements[1][0] * self.elements[2][2] - self.elements[2][0] * self.elements[1][2];

        const coef_20 = self.elements[2][0] * self.elements[3][1] - self.elements[3][0] * self.elements[2][1];
        const coef_22 = self.elements[1][0] * self.elements[3][1] - self.elements[3][0] * self.elements[1][1];
        const coef_23 = self.elements[1][0] * self.elements[2][1] - self.elements[2][0] * self.elements[1][1];

        const fac_0: Vec4 = .init(coef_00, coef_00, coef_02, coef_03);
        const fac_1: Vec4 = .init(coef_04, coef_04, coef_06, coef_07);
        const fac_2: Vec4 = .init(coef_08, coef_08, coef_10, coef_11);
        const fac_3: Vec4 = .init(coef_12, coef_12, coef_14, coef_15);
        const fac_4: Vec4 = .init(coef_16, coef_16, coef_18, coef_19);
        const fac_5: Vec4 = .init(coef_20, coef_20, coef_22, coef_23);

        const vec_0: Vec4 = .init(self.elements[1][0], self.elements[0][0], self.elements[0][0], self.elements[0][0]);
        const vec_1: Vec4 = .init(self.elements[1][1], self.elements[0][1], self.elements[0][1], self.elements[0][1]);
        const vec_2: Vec4 = .init(self.elements[1][2], self.elements[0][2], self.elements[0][2], self.elements[0][2]);
        const vec_3: Vec4 = .init(self.elements[1][3], self.elements[0][3], self.elements[0][3], self.elements[0][3]);

        const inv_0: Vec4 = .add(.sub(.mul(vec_1, fac_0), .mul(vec_2, fac_1)), .mul(vec_3, fac_2));
        const inv_1: Vec4 = .add(.sub(.mul(vec_0, fac_0), .mul(vec_2, fac_3)), .mul(vec_3, fac_4));
        const inv_2: Vec4 = .add(.sub(.mul(vec_0, fac_1), .mul(vec_1, fac_3)), .mul(vec_3, fac_5));
        const inv_3: Vec4 = .add(.sub(.mul(vec_0, fac_2), .mul(vec_1, fac_4)), .mul(vec_2, fac_5));

        const sign_a: Vec4 = .init(1, -1, 1, -1);
        const sign_b: Vec4 = .init(-1, 1, -1, 1);
        const inverse_matrix = fromVec4(
            .mul(inv_0, sign_a),
            .mul(inv_1, sign_b),
            .mul(inv_2, sign_a),
            .mul(inv_3, sign_b),
        );

        const row_0: Vec4 = .init(inverse_matrix.elements[0][0], inverse_matrix.elements[1][0], inverse_matrix.elements[2][0], inverse_matrix.elements[3][0]);
        const self_column_0: Vec4 = .init(self.elements[0][0], self.elements[0][1], self.elements[0][2], self.elements[0][3]);

        const dot_0 = Vec4.mul(self_column_0, row_0);
        const dot_1 = (dot_0.x + dot_0.y) + (dot_0.z + dot_0.w);

        const one_over_determinant = 1.0 / dot_1;

        return mulByScalar(inverse_matrix, one_over_determinant);
    }

    const zero = fromVec4(.zero, .zero, .zero, .zero);
    const identity = fromVec4(.x_axis, .y_axis, .z_axis, .w_axis);
};

const Quaternion = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    fn init(x: f32, y: f32, z: f32, w: f32) Quaternion {
        const result = Quaternion{ .x = x, .y = y, .z = z, .w = w };
        return result;
    }

    fn fromAxisAngle(axis: Vec3, angle: f32) Quaternion {
        const axis_norm: f32 = std.math.sqrt(Vec3.dot(axis, axis));
        const sine_angle_over_two = std.math.sin(angle / 2.0);
        const rotated_vector = Vec3.mul(axis, sine_angle_over_two);
        const w_part: f32 = std.math.cos(angle / 2.0);
        const xyz_part = Vec3.div(rotated_vector, axis_norm);
        const result = init(xyz_part.x, xyz_part.y, xyz_part.z, w_part);
        return result;
    }

    fn add(lhs: Quaternion, rhs: Quaternion) Quaternion {
        const result = init(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w);
        return result;
    }

    fn mul(lhs: Quaternion, rhs: Quaternion) Quaternion {
        const result = init(
            (lhs.x * rhs.w) + (lhs.y * rhs.z) - (lhs.z * rhs.y) + (lhs.w * rhs.x),
            (-lhs.x * rhs.z) + (lhs.y * rhs.w) + (lhs.z * rhs.x) + (lhs.w * rhs.y),
            (lhs.x * rhs.y) - (lhs.y * rhs.x) + (lhs.z * rhs.w) + (lhs.w * rhs.z),
            (-lhs.x * rhs.x) - (lhs.y * rhs.y) - (lhs.z * rhs.z) + (lhs.w * rhs.w),
        );
        return result;
    }

    fn mulByScalar(quat: Quaternion, scalar: f32) Quaternion {
        const result = init(quat.x * scalar, quat.y * scalar, quat.z * scalar, quat.w * scalar);
        return result;
    }

    fn dot(lhs: Quaternion, rhs: Quaternion) f32 {
        const result = lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z + lhs.w * rhs.w;
        return result;
    }

    fn slerp(lhs: Quaternion, rhs: Quaternion, time: f32) Quaternion {
        var cos_theta = dot(lhs, rhs);

        // If cosTheta < 0, the interpolation will take the long way around the sphere.
        // To fix this, one quat must be negated.
        const corrected_rhs: Quaternion = blk: {
            if (cos_theta < 0.0) {
                cos_theta = -cos_theta;
                break :blk init(-rhs.x, -rhs.y, -rhs.z, -rhs.w);
            }
            break :blk rhs;
        };

        // Perform a linear interpolation when cosTheta is close to 1 to avoid side effect of sin(angle) becoming a zero denominator
        if (cos_theta > 1.0 - 0.001) {
            const result = init(
                std.math.lerp(lhs.x, corrected_rhs.x, time),
                std.math.lerp(lhs.y, corrected_rhs.y, time),
                std.math.lerp(lhs.z, corrected_rhs.z, time),
                std.math.lerp(lhs.w, corrected_rhs.w, time),
            );
            return result;
        }

        const angle: f32 = std.math.cos(cos_theta);

        const s1: f32 = std.math.sin((1.0 - time) * angle);
        const s2: f32 = std.math.sin(time * angle);
        const inverse_sine_angle: f32 = 1.0 / std.math.sin(angle);

        const quat_left = mulByScalar(lhs, s1);
        const quat_right = mulByScalar(corrected_rhs, s2);

        const result = mulByScalar(.add(quat_left, quat_right), inverse_sine_angle);

        return result;
    }

    fn getNormalized(self: Quaternion) Quaternion {
        const length: f32 = std.math.sqrt(dot(self, self));
        const result = init(self.x / length, self.y / length, self.z / length, self.w / length);
        return result;
    }

    fn toMat4(self: Quaternion) Mat4 {
        const norm_quat = getNormalized(self);
        const xx = norm_quat.x * norm_quat.x;
        const yy = norm_quat.y * norm_quat.y;
        const zz = norm_quat.z * norm_quat.z;
        const xy = norm_quat.x * norm_quat.y;
        const xz = norm_quat.x * norm_quat.z;
        const yz = norm_quat.y * norm_quat.z;
        const wx = norm_quat.w * norm_quat.x;
        const wy = norm_quat.w * norm_quat.y;
        const wz = norm_quat.w * norm_quat.z;

        var result: Mat4 = .zero;
        result.elements[0][0] = 1.0 - 2.0 * (yy + zz);
        result.elements[0][1] = 2.0 * (xy + wz);
        result.elements[0][2] = 2.0 * (xz - wy);
        result.elements[1][0] = 2.0 * (xy - wz);
        result.elements[1][1] = 1.0 - 2.0 * (xx + zz);
        result.elements[1][2] = 2.0 * (yz + wx);
        result.elements[2][0] = 2.0 * (xz + wy);
        result.elements[2][1] = 2.0 * (yz - wx);
        result.elements[2][2] = 1.0 - 2.0 * (xx + yy);
        result.elements[3][3] = 1.0;

        return result;
    }

    const identity = init(0, 0, 0, 1);
};

const kMAX_TEXTURES: usize = 30;
const kMAX_TRANSFORMS: usize = 1200;
const kMAX_MESHES: usize = 600;
const kMAX_VERTICES: usize = 110000;

const Light = struct {
    ambient_color: Color3,
    diffuse_color: Color3,
    position: Vec3,
    range: f32,
};

const Material = struct {
    ambient_tint: Color3,
    diffuse_tint: Color3,
};

var g_backbuffer_width: i32 = 0;
var g_backbuffer_height: i32 = 0;
var g_bindings: sokol_gfx_c.sg_bindings = .{};
var g_opaque_pipline: sokol_gfx_c.sg_pipeline = .{};
var g_transparent_pipline: sokol_gfx_c.sg_pipeline = .{};
var g_pass_action: sokol_gfx_c.sg_pass_action = .{};
var g_camera_light = std.mem.zeroes(Light);
var g_global_material = std.mem.zeroes(Material);
var g_scene_ambient_color: Color3 = .black;
var g_is_fog_enabled: bool = false;
var g_fog_color: Color3 = .black;
var g_fog_start: f32 = 0;
var g_fog_end: f32 = 0;

var g_textures = std.mem.zeroes([kMAX_TEXTURES]sokol_gfx_c.sg_image);
var g_texture_filename = std.mem.zeroes([kMAX_TEXTURES][std.fs.max_path_bytes:0]u8);
var g_texture_is_alpha_blend_enabled = std.mem.zeroes([kMAX_TEXTURES]bool);
var g_texture_is_color_key_alpha_enabled = std.mem.zeroes([kMAX_TEXTURES]bool); // TODO: This is just for debugging. ifdef it out for release builds - TODO: Don't raindrops and lava generators use it?

const kERROR_IMAGE_WIDTH: usize = 32;
const kERROR_IMAGE_HEIGHT: usize = 32;
var g_error_image_data = std.mem.zeroes([kERROR_IMAGE_HEIGHT][kERROR_IMAGE_WIDTH][4]u8);

var g_world_to_view_matrix = std.mem.zeroes(Mat4);
var g_world_to_view_matrix_previous = std.mem.zeroes(Mat4);
var g_view_to_projection_matrix = std.mem.zeroes(Mat4);
// These aren't necessarily interpolated, but if not then will fall back to the correct non-interpolated matrix for this frame
var g_interpolated_world_to_view_matrix = std.mem.zeroes(Mat4);
var g_interpolated_world_to_projection_matrix = std.mem.zeroes(Mat4);
var g_camera_animation_is_continuous = false;

var g_vertices_to_load_count: i32 = 0;
var g_vertices_to_load: ?[]MeshVertex = null;

var g_transform_count: i32 = 0;

var g_transform_translations = std.mem.zeroes([kMAX_TRANSFORMS]Vec3);
var g_transform_rotations = std.mem.zeroes([kMAX_TRANSFORMS]Quaternion);
var g_transform_scales = std.mem.zeroes([kMAX_TRANSFORMS]Vec3);
var g_transform_translations_previous = std.mem.zeroes([kMAX_TRANSFORMS]Vec3);
var g_transform_rotations_previous = std.mem.zeroes([kMAX_TRANSFORMS]Quaternion);
var g_transform_scales_previous = std.mem.zeroes([kMAX_TRANSFORMS]Vec3);
var g_transform_parent_indices = std.mem.zeroes([kMAX_TRANSFORMS]i32);
var g_transform_parent_handles = std.mem.zeroes([kMAX_TRANSFORMS]i32);
var g_transform_parent_is_camera = std.mem.zeroes([kMAX_TRANSFORMS]bool);
// TODO: Figure out how to get children to be next to parents, for better cache performance

var g_transform_handles = std.mem.zeroes([kMAX_TRANSFORMS]i32);
var g_transform_handle_next_free_indices = std.mem.zeroes([kMAX_TRANSFORMS]i32);
var g_transform_handle_first_free_index: i32 = 0;

var g_mesh_count: i32 = 0;

var g_mesh_vertex_start_indices = std.mem.zeroes([kMAX_MESHES]i32);
var g_mesh_vertex_counts = std.mem.zeroes([kMAX_MESHES]usize);
var g_mesh_texture_indices = std.mem.zeroes([kMAX_MESHES]i32);
var g_mesh_is_visible = std.mem.zeroes([kMAX_MESHES]bool);
var g_mesh_uv_offsets = std.mem.zeroes([kMAX_MESHES]Vec2);
var g_mesh_is_visible_previous = std.mem.zeroes([kMAX_MESHES]bool);
var g_mesh_uv_offsets_previous = std.mem.zeroes([kMAX_MESHES]Vec2);
var g_mesh_animation_is_continuous = std.mem.zeroes([kMAX_MESHES]bool);
var g_mesh_transform_indices = std.mem.zeroes([kMAX_MESHES]i32);

var g_mesh_handles = std.mem.zeroes([kMAX_MESHES]i32);
var g_mesh_handle_next_free_indices = std.mem.zeroes([kMAX_MESHES]i32);
var g_mesh_handle_first_free_index: i32 = 0;

pub fn clear3dData() void {
    for (0..kERROR_IMAGE_WIDTH * kERROR_IMAGE_HEIGHT) |pixel_index| {
        @as([*]u32, @ptrCast(@alignCast(&g_error_image_data[0][0][0])))[pixel_index] = 0x7FFF00FF; // AABBGGRR
    }

    for (0..kMAX_TEXTURES) |texture_index| {
        if (g_textures[texture_index].id != sokol_gfx_c.SG_INVALID_ID) {
            sokol_gfx_c.sg_destroy_image(g_textures[texture_index]);
        }

        g_textures[texture_index].id = sokol_gfx_c.SG_INVALID_ID;
    }

    g_transform_count = 0;

    for (0..kMAX_TRANSFORMS) |transform_index| {
        g_transform_translations[transform_index] = .zero;
        g_transform_rotations[transform_index] = .identity;
        g_transform_scales[transform_index] = .one;
        g_transform_translations_previous[transform_index] = .zero;
        g_transform_rotations_previous[transform_index] = .identity;
        g_transform_scales_previous[transform_index] = .one;
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

pub fn loadTexture(texture_index: usize, sFile: [:0]const u8, image_type: i32, is_alpha_blend_enabled: bool) void {
    g_texture_is_alpha_blend_enabled[texture_index] = is_alpha_blend_enabled;
    @memcpy(g_texture_filename[texture_index][0..sFile.len], sFile);
    g_texture_is_color_key_alpha_enabled[texture_index] = image_type == 1;

    var width_cint: c_int = 0;
    var height_cint: c_int = 0;
    var channels_in_file: i32 = undefined;
    var image_data: ?[*]u8 = stb_image_c.stbi_load(&sFile[0], &width_cint, &height_cint, &channels_in_file, 4);
    defer if (image_data != null) {
        stb_image_c.stbi_image_free(image_data);
    };
    var width: usize = @intCast(width_cint);
    var height: usize = @intCast(height_cint);

    if (image_data != null) {
        if (image_type == 1) {
            // Color key alpha, on 0xFFFFFFFF
            for (0..height) |y| {
                for (0..width) |x| {
                    if (@as(*u32, @ptrCast(@alignCast(&image_data.?[y * width * 4 + x * 4 + 0]))).* == 0xFFFFFFFF) {
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
        const error_message: ?[*c]const u8 = stb_image_c.stbi_failure_reason();
        std.log.err("Failed to load image file \"{s}\": {s}\ndefault texture loaded instead", .{ sFile, error_message.? });
    }

    var image_desc: sokol_gfx_c.sg_image_desc = .{};
    image_desc.width = @intCast(width);
    image_desc.height = @intCast(height);
    image_desc.pixel_format = sokol_gfx_c.SG_PIXELFORMAT_RGBA8;
    // TODO: Diff mipmap level based on image_type. 0: full set, 1: only one. Probably have to manually do the resize for each mip level. Use stb_image_resize.h?
    image_desc.min_filter = sokol_gfx_c.SG_FILTER_LINEAR;
    image_desc.mag_filter = sokol_gfx_c.SG_FILTER_LINEAR;
    image_desc.data.subimage[0][0].ptr = image_data;
    image_desc.data.subimage[0][0].size = width * height * 4;

    g_textures[texture_index] = sokol_gfx_c.sg_make_image(&image_desc);

    if (g_textures[texture_index].id == sokol_gfx_c.SG_INVALID_ID) {
        fatalError("Error unlocking texture data"); // TODO: Read back error info
    }
}

fn init3d() bool {
    for (0..kMAX_TEXTURES) |texture_index| {
        g_textures[texture_index].id = sokol_gfx_c.SG_INVALID_ID;
    }

    for (0..kMAX_MESHES) |mesh_index| {
        g_mesh_handles[mesh_index] = -1;
        g_mesh_uv_offsets[mesh_index] = .zero;
        g_mesh_animation_is_continuous[mesh_index] = false;
        // TODO: Set visibility?
    }

    var desc: sokol_gfx_c.sg_desc = .{};
    sokol_gfx_c.sg_setup(&desc);

    if (!sokol_gfx_c.sg_isvalid()) {
        return false;
    }

    return true;
}

fn initScene() void {
    g_camera_light = .{
        .diffuse_color = .white,
        .ambient_color = .white,
        .position = .init(80.0, 100.0, -200.0),
        .range = 1000.0,
    };

    g_scene_ambient_color = .almost_black;

    setPerspective(80.0, 90.0, -145.0, 80.0, 59.0, 0.0);

    g_view_to_projection_matrix = Mat4.fromPerspectiveLeftHandedNegativeOne(45.0, 640.0 / 480.0, 1.0, 300.0); // Fixed aspect ratio. Will be letterboxed elsewhere

    g_global_material = .{
        .ambient_tint = .init(0.5, 0.5, 0.5),
        .diffuse_tint = .init(0.5, 0.5, 0.5),
    };

    var vbuf_desc: sokol_gfx_c.sg_buffer_desc = .{};
    vbuf_desc.usage = sokol_gfx_c.SG_USAGE_STREAM;
    vbuf_desc.size = kMAX_VERTICES * @sizeOf(MeshVertex);

    g_bindings = .{};
    g_bindings.vertex_buffers[0] = sokol_gfx_c.sg_make_buffer(&vbuf_desc);

    const shd: sokol_gfx_c.sg_shader = sokol_gfx_c.sg_make_shader(sokol_gfx_c.main_shader_shader_desc(sokol_gfx_c.SG_BACKEND_GLCORE33));

    var pip_desc: sokol_gfx_c.sg_pipeline_desc = .{};

    pip_desc.layout.buffers[0].stride = @sizeOf(MeshVertex);
    var attrs: [*]sokol_gfx_c.sg_vertex_attr_desc = @ptrCast(&pip_desc.layout.attrs[0]);
    attrs[0].format = sokol_gfx_c.SG_VERTEXFORMAT_FLOAT3;
    attrs[1].format = sokol_gfx_c.SG_VERTEXFORMAT_FLOAT3;
    attrs[2].format = sokol_gfx_c.SG_VERTEXFORMAT_FLOAT2;

    pip_desc.shader = shd;

    pip_desc.depth.compare = sokol_gfx_c.SG_COMPAREFUNC_LESS;
    pip_desc.depth.write_enabled = false;
    pip_desc.face_winding = sokol_gfx_c.SG_FACEWINDING_CW;
    pip_desc.cull_mode = sokol_gfx_c.SG_CULLMODE_BACK;

    pip_desc.colors[0].blend.enabled = true;
    pip_desc.colors[0].blend.src_factor_rgb = sokol_gfx_c.SG_BLENDFACTOR_SRC_ALPHA;
    pip_desc.colors[0].blend.dst_factor_rgb = sokol_gfx_c.SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
    pip_desc.colors[0].write_mask = sokol_gfx_c.SG_COLORMASK_RGBA;

    g_transparent_pipline = sokol_gfx_c.sg_make_pipeline(&pip_desc);

    pip_desc.depth.write_enabled = true;
    pip_desc.colors[0].blend.enabled = false;
    g_opaque_pipline = sokol_gfx_c.sg_make_pipeline(&pip_desc);

    g_pass_action = .{};
    g_pass_action.colors[0].action = sokol_gfx_c.SG_ACTION_CLEAR;
    g_pass_action.colors[0].value.r = 0.0;
    g_pass_action.colors[0].value.g = 0.0;
    g_pass_action.colors[0].value.b = 0.0;
    g_pass_action.colors[0].value.a = 1.0;
}

pub fn initializeAll() bool {
    if (!init3d()) {
        return false;
    }

    initScene();

    return true;
}

pub fn begin3dLoad(gpa: std.mem.Allocator) void {
    if (g_vertices_to_load != null) {
        gpa.free(g_vertices_to_load.?);
        g_vertices_to_load = null;
    }

    g_vertices_to_load = gpa.alloc(MeshVertex, kMAX_VERTICES) catch @panic("failed to allocate"); // TODO: Better error handling

    if (g_vertices_to_load == null) {
        fatalError("Failed to allocate enough memory in order to load model's vertex data");
    }
}

pub fn endAndCommit3dLoad(gpa: std.mem.Allocator) void {
    sokol_gfx_c.sg_update_buffer(g_bindings.vertex_buffers[0], &.{ .ptr = &g_vertices_to_load.?[0], .size = kMAX_VERTICES * @sizeOf(MeshVertex) });

    if (g_vertices_to_load != null) {
        gpa.free(g_vertices_to_load.?);
        g_vertices_to_load = null;
    }
}

pub fn reset3d() void {
    // TODO: Is there any case where we need to reset the context? I think this is a relic from D3D9. Do we might need to handle suspend/resume, ala UWP though?
}

fn killScene() void {
    for (0..kMAX_TEXTURES) |texture_index| {
        if (g_textures[texture_index].id != sokol_gfx_c.SG_INVALID_ID) {
            sokol_gfx_c.sg_destroy_image(g_textures[texture_index]);
            g_textures[texture_index].id = sokol_gfx_c.SG_INVALID_ID;
        }
    }
}

fn kill3d() void {
    sokol_gfx_c.sg_shutdown();
}

pub fn doCleanUp() void {
    killScene();
    kill3d();
}

// Returns null if handle not valid
fn getMeshIndexFromHandle(mesh_handle_index_i32: i32) ?usize {
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
fn getTransformIndexFromHandle(transform_handle_index_i32: i32) ?usize {
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

pub fn transformCreate() i32 {
    std.debug.assert(g_transform_count < kMAX_TRANSFORMS);
    std.debug.assert(g_transform_handle_first_free_index != -1);
    var new_transform_handle_index: i32 = -1;

    if (g_transform_count < kMAX_TRANSFORMS and g_transform_handle_first_free_index != -1) {
        const new_transform_index: usize = @intCast(g_transform_count);
        g_transform_translations[new_transform_index] = .zero;
        g_transform_rotations[new_transform_index] = .identity;
        g_transform_scales[new_transform_index] = .one;
        g_transform_translations_previous[new_transform_index] = .zero;
        g_transform_rotations_previous[new_transform_index] = .identity;
        g_transform_scales_previous[new_transform_index] = .one;
        g_transform_parent_indices[new_transform_index] = -1;
        g_transform_parent_handles[new_transform_index] = -1;
        g_transform_parent_is_camera[new_transform_index] = false;
        g_transform_count += 1;

        new_transform_handle_index = g_transform_handle_first_free_index;
        g_transform_handles[@intCast(new_transform_handle_index)] = @intCast(new_transform_index);
        g_transform_handle_first_free_index = g_transform_handle_next_free_indices[@intCast(g_transform_handle_first_free_index)];
    } else {
        std.log.err("unable to create transform - g_transform_count: {} g_transform_handle_first_free_index: {}", .{ g_transform_count, g_transform_handle_first_free_index });
    }

    return new_transform_handle_index;
}

pub fn transformDelete(deleting_transform_handle_index: i32) void {
    std.debug.assert(g_transform_count > 0);

    if (g_transform_count > 0) {
        const deleting_transform_index_from_handle: ?usize = getTransformIndexFromHandle(deleting_transform_handle_index);
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
        } else {
            std.log.warn("could not find transform with handle {}", .{deleting_transform_handle_index});
        }
    } else {
        std.log.err("called transformDelete when no transforms were active", .{});
    }
}

pub fn transformGetParent(transform_handle_index: i32) i32 {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);
    var result: i32 = -1;

    if (transform_index_from_handle) |transform_index| {
        result = g_transform_parent_handles[transform_index];
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }

    return result;
}

pub fn transformSetParent(transform_handle_index: i32, new_parent_transform_handle_index: i32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        const new_parent_transform_index_from_handle: ?usize = getTransformIndexFromHandle(new_parent_transform_handle_index);

        if (new_parent_transform_index_from_handle) |new_parent_transform_index| {
            // TODO: Detect cycle, assert, and break the cycle in non-debug build
            g_transform_parent_indices[transform_index] = @intCast(new_parent_transform_index);
            g_transform_parent_handles[transform_index] = @intCast(new_parent_transform_handle_index);
            g_transform_parent_is_camera[transform_index] = false;
        } else {
            std.log.warn("could not find transform with handle {}", .{new_parent_transform_handle_index});
        }
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }
}

pub fn transformClearParent(transform_handle_index: i32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_parent_indices[transform_index] = -1;
        g_transform_parent_handles[transform_index] = -1;
        g_transform_parent_is_camera[transform_index] = false;
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }
}

pub fn transformGetParentIsCamera(transform_handle_index: i32) bool {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);
    var result = false;

    if (transform_index_from_handle) |transform_index| {
        result = g_transform_parent_is_camera[transform_index];
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }

    return result;
}

pub fn transformSetParentIsCamera(transform_handle_index: i32, is_parent_camera: bool) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        if (is_parent_camera) {
            g_transform_parent_indices[transform_index] = -1;
            g_transform_parent_handles[transform_index] = -1;
        }

        g_transform_parent_is_camera[transform_index] = is_parent_camera;
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }
}

pub fn meshGetTransform(mesh_handle_index: i32) i32 {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle(mesh_handle_index);
    var result: i32 = -1;

    if (mesh_index_from_handle) |mesh_index| {
        result = g_mesh_transform_indices[mesh_index];
    } else {
        std.log.warn("could not find mesh with handle {}", .{mesh_handle_index});
    }

    return result;
}

pub fn meshSetTransform(mesh_handle_index: i32, transform_handle_index: i32) void {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle(mesh_handle_index);

    if (mesh_index_from_handle) |mesh_index| {
        const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);

        if (transform_index_from_handle) |transform_index| {
            g_mesh_transform_indices[mesh_index] = @intCast(transform_index);
        } else {
            std.log.warn("could not find transform with handle {}", .{transform_handle_index});
        }
    } else {
        std.log.warn("could not find mesh with handle {}", .{mesh_handle_index});
    }
}

pub fn meshClearTransform(mesh_handle_index: i32) void {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle(mesh_handle_index);

    if (mesh_index_from_handle) |mesh_index| {
        g_mesh_transform_indices[mesh_index] = -1;
    } else {
        std.log.warn("could not find mesh with handle {}", .{mesh_handle_index});
    }
}

pub fn transformSetToIdentity(transform_handle_index: i32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_translations[transform_index] = .zero;
        g_transform_rotations[transform_index] = .identity;
        g_transform_scales[transform_index] = .one;
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }
}

pub fn transformSetTranslation(transform_handle_index: i32, x: f32, y: f32, z: f32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_translations[transform_index] = .init(x, y, z);
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }
}

pub fn transformClearTranslation(transform_handle_index: i32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_translations[transform_index] = .zero;
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }
}

pub fn transformSetRotationX(transform_handle_index: i32, angle_in_degrees: f32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_rotations[transform_index] = Quaternion.fromAxisAngle(.x_axis, std.math.degreesToRadians(angle_in_degrees));
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }
}

pub fn transformSetRotationY(transform_handle_index: i32, angle_in_degrees: f32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_rotations[transform_index] = Quaternion.fromAxisAngle(.y_axis, std.math.degreesToRadians(angle_in_degrees));
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }
}

pub fn transformSetRotationZ(transform_handle_index: i32, angle_in_degrees: f32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_rotations[transform_index] = Quaternion.fromAxisAngle(.z_axis, std.math.degreesToRadians(angle_in_degrees));
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }
}

pub fn transformConcatRotationX(transform_handle_index: i32, angle_in_degrees: f32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_rotations[transform_index] = Quaternion.mul(Quaternion.fromAxisAngle(.x_axis, std.math.degreesToRadians(angle_in_degrees)), g_transform_rotations[transform_index]);
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }
}

pub fn transformConcatRotationY(transform_handle_index: i32, angle_in_degrees: f32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_rotations[transform_index] = Quaternion.mul(Quaternion.fromAxisAngle(.y_axis, std.math.degreesToRadians(angle_in_degrees)), g_transform_rotations[transform_index]);
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }
}

pub fn transformConcatRotationZ(transform_handle_index: i32, angle_in_degrees: f32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_rotations[transform_index] = Quaternion.mul(Quaternion.fromAxisAngle(.z_axis, std.math.degreesToRadians(angle_in_degrees)), g_transform_rotations[transform_index]);
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }
}

pub fn transformClearRotation(transform_handle_index: i32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_rotations[transform_index] = .identity;
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }
}

pub fn transformSetScale(transform_handle_index: i32, x: f32, y: f32, z: f32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_scales[transform_index] = .init(x, y, z);
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }
}

pub fn transformClearScale(transform_handle_index: i32) void {
    const transform_index_from_handle: ?usize = getTransformIndexFromHandle(transform_handle_index);

    if (transform_index_from_handle) |transform_index| {
        g_transform_scales[transform_index] = .one;
    } else {
        std.log.warn("could not find transform with handle {}", .{transform_handle_index});
    }
}

fn getMeshHandleFromIndex(mesh_index: i32) ?usize {
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
        _ = boxer_c.boxerShow("Can't find mesh handle with given mesh index!", "Jumpman Zero", boxer_c.BoxerStyleWarning, boxer_c.BoxerButtonsOK); // TODO: Better error handling? Don't ignore result?
    }

    return result_mesh_handle_index;
}

fn meshSwap(mesh_index_1: usize, mesh_index_2: usize) void {
    var temp_uv_offset: Vec2 = g_mesh_uv_offsets[mesh_index_1];
    g_mesh_uv_offsets[mesh_index_1] = g_mesh_uv_offsets[mesh_index_2];
    g_mesh_uv_offsets[mesh_index_2] = temp_uv_offset;

    temp_uv_offset = g_mesh_uv_offsets_previous[mesh_index_1];
    g_mesh_uv_offsets_previous[mesh_index_1] = g_mesh_uv_offsets_previous[mesh_index_2];
    g_mesh_uv_offsets_previous[mesh_index_2] = temp_uv_offset;

    const temp_animation_is_continuous: bool = g_mesh_animation_is_continuous[mesh_index_1];
    g_mesh_animation_is_continuous[mesh_index_1] = g_mesh_animation_is_continuous[mesh_index_2];
    g_mesh_animation_is_continuous[mesh_index_2] = temp_animation_is_continuous;

    std.mem.swap(i32, &g_mesh_vertex_start_indices[mesh_index_1], &g_mesh_vertex_start_indices[mesh_index_2]);
    std.mem.swap(usize, &g_mesh_vertex_counts[mesh_index_1], &g_mesh_vertex_counts[mesh_index_2]);
    std.mem.swap(i32, &g_mesh_texture_indices[mesh_index_1], &g_mesh_texture_indices[mesh_index_2]);
    std.mem.swap(bool, &g_mesh_is_visible[mesh_index_1], &g_mesh_is_visible[mesh_index_2]);
    std.mem.swap(bool, &g_mesh_is_visible_previous[mesh_index_1], &g_mesh_is_visible_previous[mesh_index_2]);

    std.mem.swap(i32, &g_mesh_transform_indices[mesh_index_1], &g_mesh_transform_indices[mesh_index_2]);

    const mesh_handle_index_1_from_index: ?usize = getMeshHandleFromIndex(@intCast(mesh_index_1));

    if (mesh_handle_index_1_from_index) |mesh_handle_index_1| {
        const mesh_handle_index_2_from_index: ?usize = getMeshHandleFromIndex(@intCast(mesh_index_2));

        if (mesh_handle_index_2_from_index) |mesh_handle_index_2| {
            std.mem.swap(i32, &g_mesh_handles[mesh_handle_index_1], &g_mesh_handles[mesh_handle_index_2]);
        } else {
            std.log.warn("could not find mesh with handle {}", .{mesh_index_2});
        }
    } else {
        std.log.warn("could not find mesh with handle {}", .{mesh_index_1});
    }
}

pub fn meshCreateFromVertexComponents(vertex_components: []const i32, vertex_count: usize) i32 {
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
    } else {
        std.log.err("unable to create mesh - g_mesh_count: {} g_mesh_handle_first_free_index: {}", .{ g_mesh_count, g_mesh_handle_first_free_index });
    }

    return new_mesh_handle_index;
}

pub fn meshCreateFromVertices(vertices: [*]MeshVertex, vertex_count: usize, texture_index: i32, is_visible: bool) i32 {
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

        for (0..vertex_count) |vertex_index| {
            g_vertices_to_load.?[@intCast(g_vertices_to_load_count)] = vertices[vertex_index];
            g_vertices_to_load_count += 1;
        }

        g_mesh_count += 1;

        new_mesh_handle_index = g_mesh_handle_first_free_index;
        g_mesh_handles[@intCast(new_mesh_handle_index)] = @intCast(new_mesh_index);
        g_mesh_handle_first_free_index = g_mesh_handle_next_free_indices[@intCast(g_mesh_handle_first_free_index)];
    } else {
        std.log.err("unable to create mesh - g_mesh_count: {} g_mesh_handle_first_free_index: {}", .{ g_mesh_count, g_mesh_handle_first_free_index });
    }

    return new_mesh_handle_index;
}

pub fn meshCreateFromCopy(source_mesh_handle_index: i32) i32 {
    std.debug.assert(g_mesh_count < kMAX_MESHES);
    std.debug.assert(g_mesh_handle_first_free_index != -1);
    const source_mesh_index_from_handle: ?usize = getMeshIndexFromHandle(source_mesh_handle_index);
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
        } else {
            std.log.warn("could not find mesh with handle {}", .{source_mesh_handle_index});
        }
    } else {
        std.log.err("unable to create mesh - g_mesh_count: {} g_mesh_handle_first_free_index: {}", .{ g_mesh_count, g_mesh_handle_first_free_index });
    }

    return new_mesh_handle_index;
}

pub fn meshReplaceWithCopy(target_mesh_handle_index: i32, source_mesh_handle_index: i32) void {
    const target_mesh_index_from_handle: ?usize = getMeshIndexFromHandle(target_mesh_handle_index);

    if (target_mesh_index_from_handle) |target_mesh_index| {
        const source_mesh_index_from_handle: ?usize = getMeshIndexFromHandle(source_mesh_handle_index);

        if (source_mesh_index_from_handle) |source_mesh_index| {
            g_mesh_vertex_start_indices[target_mesh_index] = g_mesh_vertex_start_indices[source_mesh_index];
            g_mesh_vertex_counts[target_mesh_index] = g_mesh_vertex_counts[source_mesh_index];
        } else {
            std.log.warn("could not find mesh with handle {}", .{source_mesh_handle_index});
        }
    } else {
        std.log.warn("could not find mesh with handle {}", .{target_mesh_handle_index});
    }
}

pub fn meshDelete(deleting_mesh_handle_index: i32) void {
    std.debug.assert(g_mesh_count > 0);
    const deleting_mesh_index_from_handle: ?usize = getMeshIndexFromHandle(deleting_mesh_handle_index);

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
        } else {
            std.log.warn("could not find mesh with handle {}", .{deleting_mesh_handle_index});
        }

        g_mesh_handle_next_free_indices[@intCast(deleting_mesh_handle_index)] = g_mesh_handle_first_free_index;
        g_mesh_handle_first_free_index = deleting_mesh_handle_index;

        g_mesh_count -= 1;
    } else {
        std.log.err("called meshDelete when no meshes were active", .{});
    }
}

pub fn meshSetIsVisible(mesh_handle_index: i32, is_visible: bool) void {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle(mesh_handle_index);

    if (mesh_index_from_handle) |mesh_index| {
        g_mesh_is_visible[mesh_index] = is_visible;
    } else {
        std.log.warn("could not find mesh with handle {}", .{mesh_handle_index});
    }
}

pub fn meshSetTextureIndex(mesh_handle_index: i32, texture_index: i32) void {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle(mesh_handle_index);

    if (mesh_index_from_handle) |mesh_index| {
        g_mesh_texture_indices[mesh_index] = texture_index;
    } else {
        std.log.warn("could not find mesh with handle {}", .{mesh_handle_index});
    }
}

pub fn meshMoveToFrontForTransparentDrawing(mesh_handle_index: i32) void {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle(mesh_handle_index);

    if (mesh_index_from_handle) |mesh_index| {
        for (mesh_index + 1..@intCast(g_mesh_count)) |current_mesh_index| {
            meshSwap(current_mesh_index, current_mesh_index - 1);
        }
    } else {
        std.log.warn("could not find mesh with handle {}", .{mesh_handle_index});
    }
}

pub fn meshMoveToBackForTransparentDrawing(mesh_handle_index: i32) void {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle(mesh_handle_index);

    if (mesh_index_from_handle) |mesh_index| {
        var current_mesh_index: usize = mesh_index;
        while (current_mesh_index > 0) {
            current_mesh_index -= 1;
            meshSwap(current_mesh_index, current_mesh_index + 1);
        }
    } else {
        std.log.warn("could not find mesh with handle {}", .{mesh_handle_index});
    }
}

pub fn meshScrollTexture(mesh_handle_index: i32, translate_x: f32, translate_y: f32) void {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle(mesh_handle_index);

    if (mesh_index_from_handle) |mesh_index| {
        g_mesh_uv_offsets[mesh_index] = Vec2.add(.init(translate_x, translate_y), g_mesh_uv_offsets[mesh_index]);
    } else {
        std.log.warn("could not find mesh with handle {}", .{mesh_handle_index});
    }
}

pub fn meshSetIsAnimationContinuous(mesh_handle_index: i32, is_continuous: bool) void {
    const mesh_index_from_handle: ?usize = getMeshIndexFromHandle(mesh_handle_index);

    if (mesh_index_from_handle) |mesh_index| {
        g_mesh_animation_is_continuous[mesh_index] = is_continuous;
    } else {
        std.log.warn("could not find mesh with handle {}", .{mesh_handle_index});
    }
}

pub fn setCameraIsAnimationContinuous(is_continuous: bool) void {
    g_camera_animation_is_continuous = is_continuous;
}

pub fn setFog(fog_start: f32, fog_end: f32, red: u8, green: u8, blue: u8) void {
    if (fog_start == 0 and fog_end == 0) {
        g_is_fog_enabled = false;
    } else {
        g_is_fog_enabled = true;
        g_fog_color = .initFromU8(red, green, blue);
        g_fog_start = fog_start;
        g_fog_end = fog_end;
    }
}

pub fn setPerspective(cam_x: f32, cam_y: f32, cam_z: f32, look_at_x: f32, look_at_y: f32, look_at_z: f32) void {
    g_world_to_view_matrix = Mat4.fromLookAtLeftHanded(.init(cam_x, cam_y, cam_z), .init(look_at_x, look_at_y, look_at_z), .init(0.0, 1.0, 0.0));
    g_camera_light.position = .init(cam_x, cam_y + 10.0, -200.0);
    g_camera_light.diffuse_color = .white;
    g_camera_light.ambient_color = .white;
}

pub fn rendererPreUpdate(_: f64) void {
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

pub fn rendererPostUpdate() void {
    for (0..@intCast(g_mesh_count)) |mesh_index| {
        if (!g_mesh_is_visible_previous[mesh_index] and g_mesh_is_visible[mesh_index]) {
            g_mesh_animation_is_continuous[mesh_index] = false;
        }
    }
}

fn renderMesh(mesh_index: usize, previous_texture_index: *i32, vs_params: *MainShaderVertexParams, are_fs_params_applied: *bool, fs_params: *MainShaderFragmentParams, do_interpolation: bool, interpolation_scale: f32) void {
    const current_texture_index_i32: i32 = g_mesh_texture_indices[mesh_index];
    std.debug.assert(current_texture_index_i32 != -1);
    const current_texture_index: usize = @intCast(current_texture_index_i32);
    // TODO: If current_texture_index == -1 then set to a default texture

    if (previous_texture_index.* != current_texture_index) {
        previous_texture_index.* = current_texture_index_i32;
        g_bindings.fs_images[0] = g_textures[current_texture_index];
        sokol_gfx_c.sg_apply_bindings(&g_bindings);
    }

    var current_transform_index_i32: i32 = g_mesh_transform_indices[mesh_index];
    var transform_skip_world_to_view: bool = false;

    // TODO: Calculate matrices in more cache-friendly/packed manner
    // TODO: Are parent/child being multiplied in the correct order here? Seems they're reversed right now. Should do parent[SRT]child[SRT]?
    var current_local_to_world_matrix = Mat4.identity;

    if (do_interpolation and g_mesh_animation_is_continuous[mesh_index]) {
        while (current_transform_index_i32 != -1) {
            const current_transform_index: usize = @intCast(current_transform_index_i32);
            const current_translation = Vec3.lerp(g_transform_translations_previous[current_transform_index], g_transform_translations[current_transform_index], interpolation_scale);
            const current_rotation = Quaternion.slerp(g_transform_rotations_previous[current_transform_index], g_transform_rotations[current_transform_index], interpolation_scale);
            const current_scale = Vec3.lerp(g_transform_scales_previous[current_transform_index], g_transform_scales[current_transform_index], interpolation_scale);
            current_local_to_world_matrix =
                Mat4.mul(
                    Mat4.fromTranslation(current_translation),
                    Mat4.mul(
                        current_rotation.toMat4(),
                        Mat4.mul(Mat4.fromScale(current_scale), current_local_to_world_matrix),
                    ),
                );

            if (g_transform_parent_is_camera[current_transform_index]) {
                transform_skip_world_to_view = true;
            }

            current_transform_index_i32 = g_transform_parent_indices[current_transform_index];
        }
    } else {
        while (current_transform_index_i32 != -1) {
            const current_transform_index: usize = @intCast(current_transform_index_i32);
            const current_translation: Vec3 = g_transform_translations[current_transform_index];
            const current_rotation: Quaternion = g_transform_rotations[current_transform_index];
            const current_scale: Vec3 = g_transform_scales[current_transform_index];
            current_local_to_world_matrix =
                Mat4.mul(
                    Mat4.fromTranslation(current_translation),
                    Mat4.mul(
                        current_rotation.toMat4(),
                        Mat4.mul(Mat4.fromScale(current_scale), current_local_to_world_matrix),
                    ),
                );

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
        Mat4.mul(g_interpolated_world_to_view_matrix, current_local_to_world_matrix);
    vs_params.local_to_projection_matrix = if (transform_skip_world_to_view)
        Mat4.mul(g_view_to_projection_matrix, current_local_to_world_matrix)
    else
        Mat4.mul(g_interpolated_world_to_projection_matrix, current_local_to_world_matrix);
    vs_params.transpose_world_to_local_matrix = current_local_to_world_matrix.getInverse().getTranspose();

    if (do_interpolation and g_mesh_animation_is_continuous[mesh_index]) {
        vs_params.uv_offset = Vec2.lerp(g_mesh_uv_offsets_previous[mesh_index], g_mesh_uv_offsets[mesh_index], interpolation_scale);
    } else {
        vs_params.uv_offset = g_mesh_uv_offsets[mesh_index];
    }

    sokol_gfx_c.sg_apply_uniforms(sokol_gfx_c.SG_SHADERSTAGE_VS, 0, &.{ .ptr = vs_params, .size = @sizeOf(MainShaderVertexParams) });

    if (!are_fs_params_applied.*) {
        sokol_gfx_c.sg_apply_uniforms(sokol_gfx_c.SG_SHADERSTAGE_FS, 0, &.{ .ptr = fs_params, .size = @sizeOf(MainShaderFragmentParams) });
        are_fs_params_applied.* = true;
    }

    sokol_gfx_c.sg_draw(g_mesh_vertex_start_indices[mesh_index], @intCast(g_mesh_vertex_counts[mesh_index]), 1);
}

const MainShaderVertexParams = extern struct {
    local_to_world_matrix: Mat4,
    local_to_view_matrix: Mat4,
    local_to_projection_matrix: Mat4,
    transpose_world_to_local_matrix: Mat4,
    uv_offset: Vec2,
    _pad_264: [8]u8,
};

const MainShaderFragmentParams = extern struct {
    scene_ambient_color: Color3,
    _pad_12: [4]u8,
    material_ambient_tint: Color3,
    _pad_28: [4]u8,
    material_diffuse_tint: Color3,
    _pad_44: [4]u8,
    light_ambient_color: Color3,
    _pad_60: [4]u8,
    light_diffuse_color: Color3,
    _pad_76: [4]u8,
    light_position: Vec3,
    light_range: f32,
    is_fog_enabled: f32,
    _pad_100: [12]u8,
    fog_color: Color3,
    fog_start: f32,
    fog_end: f32,
    _pad_132: [12]u8,
};

pub fn rendererDraw(do_interpolation: bool, interpolation_scale: f32) void {
    if (g_backbuffer_width < 1 or g_backbuffer_height < 1) {
        return;
    }

    sokol_gfx_c.sg_begin_default_pass(&g_pass_action, g_backbuffer_width, g_backbuffer_height);

    const backbuffer_aspect_ratio: f32 = @as(f32, @floatFromInt(g_backbuffer_width)) / @as(f32, @floatFromInt(g_backbuffer_height));
    const target_aspect_ratio: f32 = 640.0 / 480.0;

    if (backbuffer_aspect_ratio > target_aspect_ratio) {
        const width_scale: f32 = target_aspect_ratio / backbuffer_aspect_ratio;
        const border_half_width: f32 = (@as(f32, @floatFromInt(g_backbuffer_width)) - width_scale * @as(f32, @floatFromInt(g_backbuffer_width))) / 2.0;
        sokol_gfx_c.sg_apply_viewport(@intFromFloat(border_half_width), 0, g_backbuffer_width - @as(i32, @intFromFloat(border_half_width * 2.0)), g_backbuffer_height, true);
    } else {
        const height_scale: f32 = backbuffer_aspect_ratio / target_aspect_ratio;
        const border_half_height: f32 = (@as(f32, @floatFromInt(g_backbuffer_height)) - height_scale * @as(f32, @floatFromInt(g_backbuffer_height))) / 2.0;
        sokol_gfx_c.sg_apply_viewport(0, @intFromFloat(border_half_height), g_backbuffer_width, g_backbuffer_height - @as(i32, @intFromFloat(border_half_height * 2.0)), true);
    }

    var vs_params: MainShaderVertexParams = undefined;
    var fs_params: MainShaderFragmentParams = undefined;
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
        const camera_pos_current: Vec3 = @as(*const Vec3, @ptrCast(&g_world_to_view_matrix.elements[3])).*;
        const camera_pos_previous: Vec3 = @as(*const Vec3, @ptrCast(&g_world_to_view_matrix_previous.elements[3])).*;
        @as(*Vec3, @ptrCast(&g_interpolated_world_to_view_matrix.elements[3][0])).* = Vec3.add(camera_pos_previous, Vec3.mul(Vec3.sub(camera_pos_current, camera_pos_previous), if (g_camera_animation_is_continuous) interpolation_scale else 0.0));
    }

    g_interpolated_world_to_projection_matrix = Mat4.mul(g_view_to_projection_matrix, g_interpolated_world_to_view_matrix);

    // Draw opaque
    sokol_gfx_c.sg_apply_pipeline(g_opaque_pipline);

    var previous_texture_index: i32 = -1;
    var are_fs_params_applied: bool = false; // These are currently set globally, so don't need to be set for every mesh

    for (0..@intCast(g_mesh_count)) |mesh_index| {
        if (g_mesh_is_visible[mesh_index] and !g_texture_is_alpha_blend_enabled[@intCast(g_mesh_texture_indices[mesh_index])]) {
            renderMesh(mesh_index, &previous_texture_index, &vs_params, &are_fs_params_applied, &fs_params, do_interpolation, interpolation_scale);
        }
    }

    // Draw transparent
    sokol_gfx_c.sg_apply_pipeline(g_transparent_pipline);

    previous_texture_index = -1;
    are_fs_params_applied = false;

    for (0..@intCast(g_mesh_count)) |mesh_index| {
        if (g_mesh_is_visible[mesh_index] and g_texture_is_alpha_blend_enabled[@intCast(g_mesh_texture_indices[mesh_index])]) {
            renderMesh(mesh_index, &previous_texture_index, &vs_params, &are_fs_params_applied, &fs_params, do_interpolation, interpolation_scale);
        }
    }

    sokol_gfx_c.sg_end_pass();
    sokol_gfx_c.sg_commit();
}

pub fn resizeViewport(width: i32, height: i32) void {
    g_backbuffer_width = width;
    g_backbuffer_height = height;
}

pub fn getViewportMousePos(pos_x: *f32, pos_y: *f32) void {
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

fn fatalError(error_msg: []const u8) void {
    killScene();
    kill3d();
    _ = boxer_c.boxerShow(&error_msg[0], "Jumpman Zero", boxer_c.BoxerStyleError, boxer_c.BoxerButtonsOK); // TODO: Don't discard result?
}
