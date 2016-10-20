#include <glm/gtc/type_ptr.hpp>
#include <glm/gtx/transform.hpp>
#include "material.hpp"

Material::Material(std::shared_ptr<ShaderProgram> shader_program) noexcept
    : shader_program_(shader_program)
    , current_texture_param_(*shader_program, "current_texture")
    , texture_transform_matrix_param_(
        *shader_program, "texture_transform_matrix")
    , mvp_matrix_param_(*shader_program, "mvp_matrix") {
}

void Material::Activate(const Material* previous_material) {
  if (!previous_material
      || previous_material->shader_program_ != shader_program_) {
    glUseProgram(*shader_program_);

    // Accomodate that textures have down == y coordinate space
    glm::mat4 texture_transform_matrix =
      glm::scale(glm::vec3(1.0f, -1.0f, 1.0f))
      * texture_transform.GetWorldToLocalMatrix();
    glUniformMatrix4fv(
      texture_transform_matrix_param_, 1,
      GL_FALSE, glm::value_ptr(texture_transform_matrix));

    for (auto& pair: matrix_parameters_) {
      glUniformMatrix4fv(
        pair.second, 1, GL_FALSE, glm::value_ptr(matrix_values_[pair.first]));
    }

    for (auto& pair: vector_parameters_) {
      glUniform3fv(pair.second, 1, glm::value_ptr(vector_values_[pair.first]));
    }

    for (auto& pair: float_parameters_) {
      glUniform1f(pair.second, float_values_[pair.first]);
    }
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

void Material::SetShaderUniform(
    const std::string& name, const glm::mat4& value) {
  auto uniform_iter = matrix_parameters_.find(name);
  if (uniform_iter == matrix_parameters_.end()) {
    uniform_iter = matrix_parameters_.emplace(
      name,
      ShaderUniformParameter(*shader_program_, name)).first;
  }

  matrix_values_[name] = value;
}

void Material::SetShaderUniform(
    const std::string& name, const glm::vec3& value) {
  auto uniform_iter = vector_parameters_.find(name);
  if (uniform_iter == vector_parameters_.end()) {
    uniform_iter = vector_parameters_.emplace(
      name,
      ShaderUniformParameter(*shader_program_, name)).first;
  }

  vector_values_[name] = value;
}

void Material::SetShaderUniform(const std::string& name, float value) {
  auto uniform_iter = float_parameters_.find(name);
  if (uniform_iter == float_parameters_.end()) {
    uniform_iter = float_parameters_.emplace(
      name,
      ShaderUniformParameter(*shader_program_, name)).first;
  }

  float_values_[name] = value;
}
