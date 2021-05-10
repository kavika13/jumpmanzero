@ctype mat4 hmm_mat4
@ctype vec2 hmm_vec2
@ctype vec3 hmm_vec3
@ctype vec4 hmm_vec4

@vs main_shader_vs
in vec3 position;
in vec3 normal;
in vec2 texcoord0;

out vec3 vs_world_position;
out vec3 vs_view_position;
out vec3 vs_unscaled_normal;
out vec2 vs_uv;

uniform main_shader_vs_params {
    mat4 local_to_world_matrix;
    mat4 local_to_view_matrix;
    mat4 local_to_projection_matrix;
    mat4 transpose_world_to_local_matrix;
    vec2 uv_offset;
};

void main() {
    vec4 pos = vec4(position, 1.0);
    vs_world_position = vec3(local_to_world_matrix * pos);
    vs_view_position = vec3(local_to_view_matrix * pos);
    vs_unscaled_normal = normalize(vec3(transpose_world_to_local_matrix * vec4(normal, 0.0)));
    vs_uv = texcoord0 + uv_offset;
    gl_Position = local_to_projection_matrix * pos;
}
@end

@fs main_shader_fs
in vec3 vs_world_position;
in vec3 vs_view_position;
in vec3 vs_unscaled_normal;
in vec2 vs_uv;

out vec4 frag_color;

uniform sampler2D tex;

uniform main_shader_fs_params {
    vec3 scene_ambient_color;

    vec3 material_ambient_tint;
    vec3 material_diffuse_tint;

    vec3 light_ambient_color;
    vec3 light_diffuse_color;
    vec3 light_position;
    float light_range;

    float is_fog_enabled;  // TODO: Use bool when sokol shader compiler can handle it
    vec3 fog_color;
    float fog_start;
    float fog_end;
};

void main() {
    vec4 albedo = texture(tex, vs_uv);
    float out_alpha = albedo.a;

    vec3 ambient_color = material_ambient_tint * (scene_ambient_color + light_ambient_color);

    vec3 diffuse_color = vec3(0.0);

    if(length(light_position - vs_world_position) < light_range) {
        vec3 light_direction = normalize(light_position - vs_world_position);
        vec3 uninterpolated_normal = normalize(vs_unscaled_normal);
        diffuse_color = material_diffuse_tint *
            light_diffuse_color * max(dot(uninterpolated_normal, light_direction), 0.0);
    }

    vec3 out_color = (ambient_color + diffuse_color) * albedo.rgb;

    if(is_fog_enabled > 0.0) {
        out_color = mix(fog_color, out_color, clamp((fog_end - vs_view_position.z) / (fog_end - fog_start), 0.0, 1.0));
    }

    frag_color = vec4(out_color, out_alpha);
}
@end

@program main_shader main_shader_vs main_shader_fs
