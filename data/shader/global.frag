#version 330 core

uniform sampler2D current_texture;
uniform mat4 texture_transform_matrix = mat4(1.0);

in vec2 tex_coord_v;

out vec4 color;

void main() {
  color = texture(
    current_texture,
    vec2(texture_transform_matrix * vec4(tex_coord_v, 1.0f, 1.0f)));
}
