#include <glm/gtc/type_ptr.hpp>
#include "material.hpp"

Material::Material(std::shared_ptr<ShaderProgram> shader_program) noexcept
    : shader_program_(shader_program)
    , current_texture_param_(*shader_program, "current_texture")
    , mvp_matrix_param_(*shader_program, "mvp_matrix") {
}

void Material::SetActive() noexcept {
  glUseProgram(*shader_program_);
}

void Material::SetTexture(std::weak_ptr<Texture> texture) noexcept {
  // TODO: Handle null texture
  texture_ = texture;
}

std::weak_ptr<Texture> Material::GetTexture() noexcept {
  return texture_;
}

void Material::BindTexture(GLuint texture_index) {
  if (!texture_.expired()) {
    glActiveTexture(GL_TEXTURE0);  // TODO: base off texture_index
    glBindTexture(GL_TEXTURE_2D, *texture_.lock());
    glUniform1i(current_texture_param_, texture_index);
  } else {
    // TODO: Draw null texture
  }
}

void Material::BindMvpMatrix(const glm::mat4& mvp_matrix) {
  glUniformMatrix4fv(
    mvp_matrix_param_, 1, GL_FALSE, glm::value_ptr(mvp_matrix));
}
