#version 330 core

struct PointLight {
  vec3 translation;
  vec3 ambient_intensity;
  vec3 diffuse_intensity;
  vec3 specular_intensity;
};

struct Material {
  vec3 ambient_reflection;
  vec3 diffuse_reflection;
  vec3 specular_reflection;
  vec3 shininess;
};

uniform sampler2D current_texture;
uniform bool is_alpha_test_enabled = false;
uniform float alpha_test_threshold = 1.0;
uniform mat4 texture_transform_matrix = mat4(1.0);

uniform PointLight pointlight0 = PointLight(  // TODO: Bind from scene
  vec3(80.0f, 80.0f + 10.0f, -200.0f),
  vec3(1.0f, 1.0f, 1.0f),
  vec3(1.0f, 1.0f, 1.0f),
  vec3(0.0f, 0.0f, 0.0f));
uniform Material material = Material(  // TODO: Bind from scene
  vec3(0.5f, 0.5f, 0.5f),
  vec3(0.5f, 0.5f, 0.5f),
  vec3(0.0f, 0.0f, 0.0f),
  vec3(0.0f, 0.0f, 0.0f));

in vec2 tex_coord_v;
in vec3 world_vertex_v;
in vec3 unscaled_normal_v;  // Model transform's scale undone

out vec4 color;

void main() {
  vec4 texture_color = texture(
    current_texture,
    vec2(texture_transform_matrix * vec4(tex_coord_v, 1.0, 1.0)));

  if (is_alpha_test_enabled && texture_color.a < alpha_test_threshold) {
    discard;
  }

  vec3 ambient_color = pointlight0.ambient_intensity
    * material.ambient_reflection;

  vec3 light_direction = normalize(pointlight0.translation - world_vertex_v);
  vec3 uninterpolated_normal = normalize(unscaled_normal_v);
  vec3 diffuse_color = max(dot(uninterpolated_normal, light_direction), 0.0)
    * pointlight0.diffuse_intensity * material.diffuse_reflection;

  // TODO: specular_color

  color = vec4(ambient_color + diffuse_color, 1.0) * texture_color;
}
