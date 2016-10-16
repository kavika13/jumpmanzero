#ifndef ENGINE_MATERIAL_HPP_
#define ENGINE_MATERIAL_HPP_

#include <memory>
#define GLM_FORCE_LEFT_HANDED
#include <glm/mat4x4.hpp>
#define GL3_PROTOTYPES
#include <OpenGL/gl3.h>
#include "shader.hpp"
#include "texture.hpp"

class Material {
 public:
  Material(std::shared_ptr<ShaderProgram>) noexcept;

  void SetActive() noexcept;

  void SetTexture(std::shared_ptr<Texture>) noexcept;
  std::shared_ptr<Texture> GetTexture() noexcept;
  void BindTexture(GLuint texture_index);

  void BindMvpMatrix(const glm::mat4& mvp_matrix);

 private:
  std::shared_ptr<ShaderProgram> shader_program_;
  std::shared_ptr<Texture> texture_;
  ShaderUniformParameter current_texture_param_;
  ShaderUniformParameter mvp_matrix_param_;
};

#endif  // ENGINE_MATERIAL_HPP_
