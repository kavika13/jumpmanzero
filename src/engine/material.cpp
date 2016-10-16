#include <glm/gtc/type_ptr.hpp>
#include "material.hpp"

Material::Material(std::shared_ptr<ShaderProgram> shader_program) noexcept
    : shader_program_(shader_program)
    , current_texture_param_(*shader_program, "current_texture")
    , mvp_matrix_param_(*shader_program, "mvp_matrix") {
}

void Material::Activate(const Material* previous_material) {
  if (!previous_material
      || previous_material->shader_program_ != shader_program_) {
    glUseProgram(*shader_program_);
  }

  if (!previous_material
      || previous_material->texture_ != texture_) {
    // TODO: Handle enable/diable alpha blend depending on texture data
    // TODO: Pass in texture index? Store it as a material property?
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, *texture_);
    glUniform1i(current_texture_param_, 0);
  }
}

void Material::SetTexture(std::shared_ptr<Texture> texture) noexcept {
  // TODO: Handle null texture
  texture_ = texture;
}

std::shared_ptr<Texture> Material::GetTexture() noexcept {
  return texture_;
}

void Material::BindMvpMatrix(const glm::mat4& mvp_matrix) {
  glUniformMatrix4fv(
    mvp_matrix_param_, 1, GL_FALSE, glm::value_ptr(mvp_matrix));
}
