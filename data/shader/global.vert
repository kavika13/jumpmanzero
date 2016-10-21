#version 330 core

layout(location = 0) in vec3 vertex;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec2 tex_coord;

uniform mat4 wvp_matrix;
uniform mat4 local_to_world_matrix;
uniform mat4 transpose_world_to_local_matrix;

out vec2 tex_coord_v;
out vec3 world_vertex_v;
out vec3 unscaled_normal_v;

void main() {
  vec4 local_vertex = vec4(vertex, 1.0);
  tex_coord_v = tex_coord;
  world_vertex_v = vec3(local_to_world_matrix * local_vertex);
  unscaled_normal_v = normalize(
    vec3(transpose_world_to_local_matrix * vec4(normal, 0.0)));
  gl_Position = wvp_matrix * local_vertex;
}
