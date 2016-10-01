#version 330 core

uniform sampler2D current_texture;

in vec2 tex_coord_v;

out vec4 color;

void main() {
  color = texture(current_texture, tex_coord_v);
}
