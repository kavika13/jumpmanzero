#ifndef ENGINE_SHADER_HPP_
#define ENGINE_SHADER_HPP_

#include <string>
#define GL3_PROTOTYPES
#include <OpenGL/gl3.h>

template <GLenum kShaderType>
class Shader {
 public:
  Shader(const std::string& source);
  Shader(const Shader&) = delete;
  Shader(Shader&&) noexcept;
  ~Shader();

  Shader& operator=(const Shader&) = delete;
  Shader& operator=(Shader&&) noexcept;

  operator GLuint() const;

 private:
  void Deallocate() noexcept;

  GLuint handle_;
  static const char* shader_type_name_;
};

class VertexShader : public Shader<GL_VERTEX_SHADER> {
  using Shader::Shader;
};

class FragmentShader : public Shader<GL_FRAGMENT_SHADER> {
  using Shader::Shader;
};

class GeometryShader : public Shader<GL_GEOMETRY_SHADER> {
  using Shader::Shader;
};

class ShaderProgram {
 public:
  ShaderProgram(
    const VertexShader& vertex_shader,
    const FragmentShader& fragment_shader);
  ShaderProgram(const ShaderProgram&) = delete;
  ShaderProgram(ShaderProgram&&) noexcept;
  ~ShaderProgram();

  ShaderProgram& operator=(const ShaderProgram&) = delete;
  ShaderProgram& operator=(ShaderProgram&&) noexcept;

  operator GLuint() const;

 private:
  void Deallocate() noexcept;

  GLuint handle_;
};

class ShaderUniformParameter {
 public:
  ShaderUniformParameter(
    const ShaderProgram& program, const std::string& uniform_name);

  operator GLint() const;

 private:
  const GLint handle_;
};

#endif  // ENGINE_SHADER_HPP_
