#ifndef ENGINE_GRAPHICS_MATERIAL_HPP_
#define ENGINE_GRAPHICS_MATERIAL_HPP_

#include <memory>
#include <unordered_map>
#define GLM_FORCE_LEFT_HANDED
#include <glm/mat4x4.hpp>
#define GL3_PROTOTYPES
#include <OpenGL/gl3.h>
#include "transform.hpp"
#include "shader.hpp"
#include "texture.hpp"

namespace Jumpman {

namespace Graphics {

class Material {
 public:
  Material(std::shared_ptr<ShaderProgram>) noexcept;

  void Activate(const Material* previous_material);

  void SetTexture(std::shared_ptr<Texture>) noexcept;
  std::shared_ptr<Texture> GetTexture() noexcept;

  void BindTransformMatrices(
    const glm::mat4& wvp_matrix,
    const glm::mat4& local_to_world_matrix,
    const glm::mat4& transpose_world_to_local_matrix);

  void SetShaderUniform(const std::string& name, const glm::mat4& value);
  void SetShaderUniform(const std::string& name, const glm::vec3& value);
  void SetShaderUniform(const std::string& name, float value);

  Transform texture_transform;

 private:
  std::shared_ptr<ShaderProgram> shader_program_;
  std::shared_ptr<Texture> texture_;
  ShaderUniformParameter current_texture_param_;
  ShaderUniformParameter texture_transform_matrix_param_;
  ShaderUniformParameter wvp_matrix_param_;
  ShaderUniformParameter local_to_world_matrix_param_;
  ShaderUniformParameter transpose_world_to_local_matrix_param_;

  std::unordered_map<std::string, ShaderUniformParameter> matrix_parameters_;
  std::unordered_map<std::string, ShaderUniformParameter> vector_parameters_;
  std::unordered_map<std::string, ShaderUniformParameter> float_parameters_;

  std::unordered_map<std::string, glm::mat4> matrix_values_;
  std::unordered_map<std::string, glm::vec3> vector_values_;
  std::unordered_map<std::string, float> float_values_;
};

};  // namespace Graphics

};  // namespace Jumpman

#endif  // ENGINE_GRAPHICS_MATERIAL_HPP_
