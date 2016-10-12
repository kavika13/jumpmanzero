#version 330 core

layout(location = 0) in vec3 vertex;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec2 tex_coord;

uniform mat4 mvp_matrix;

out vec2 tex_coord_v;

void main() {
  tex_coord_v = tex_coord;
  gl_Position = mvp_matrix * vec4(vertex, 1.0);
}
