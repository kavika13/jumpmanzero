#include "logging.hpp"
#include "shader.hpp"
#include "openglerror.hpp"

static constexpr const char* GetShaderNameByType(GLenum type) {
  switch (type) {
    case GL_VERTEX_SHADER:
      return "vertex";
      break;
    case GL_FRAGMENT_SHADER:
      return "fragment";
      break;
    case GL_GEOMETRY_SHADER:
      return "geometry";
      break;
    default:
      assert(false);
  }
}

template <GLenum kShaderType>
const char* Shader<kShaderType>::shader_type_name_ =
  GetShaderNameByType(kShaderType);

template <GLenum kShaderType>
Shader<kShaderType>::Shader(const std::string& source) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Graphics");

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Creating " << shader_type_name_ << " shader";

  handle_ = glCreateShader(kShaderType);

  if (AreOpenGLErrorFlagsSet()) {
    BOOST_LOG_SEV(log, LogSeverity::kError) << "Error creating shader";
    throw std::runtime_error("Error creating shader");
  }

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Compiling " << shader_type_name_ << " shader: " << handle_;

  // TODO: Log OpenGL errors and throw at each of these steps
  const char* source_chars = &source[0];
  glShaderSource(handle_, 1, &source_chars, NULL);
  glCompileShader(handle_);

  GLint param;
  glGetShaderiv(handle_, GL_COMPILE_STATUS, &param);

  if (!param) {
    glGetShaderiv(handle_, GL_INFO_LOG_LENGTH, &param);
    std::string error_message;
    error_message.resize(param);
    glGetShaderInfoLog(handle_, param, NULL, &error_message[0]);
    BOOST_LOG_SEV(log, LogSeverity::kError)
      << "Error compiling shader: " << error_message;
    throw std::runtime_error("Error compiling shader: " + error_message);
  }

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished compiling " << shader_type_name_ << " shader: " << handle_;
}

template <GLenum kShaderType>
Shader<kShaderType>::Shader(Shader&& other) noexcept : handle_(other.handle_) {
  other.handle_ = 0;
}

template <GLenum kShaderType>
Shader<kShaderType>::~Shader() {
  Deallocate();
}

template <GLenum kShaderType>
Shader<kShaderType>& Shader<kShaderType>::operator=(Shader&& other) noexcept {
  Deallocate();
  handle_ = other.handle_;
  other.handle_ = 0;
  return *this;
}

template <GLenum kShaderType>
Shader<kShaderType>::operator GLuint() const {
  return handle_;
}

template <GLenum kShaderType>
void Shader<kShaderType>::Deallocate() noexcept {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Graphics");

  if (handle_) {
    BOOST_LOG_SEV(log, LogSeverity::kDebug)
      << "Deleting " << shader_type_name_ << " shader: " << handle_;
    glDeleteShader(handle_);
  }
}

template class Shader<GL_VERTEX_SHADER>;
template class Shader<GL_FRAGMENT_SHADER>;
template class Shader<GL_GEOMETRY_SHADER>;

ShaderProgram::ShaderProgram(
    const VertexShader& vertex_shader,
    const FragmentShader& fragment_shader) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Graphics");

  handle_ = glCreateProgram();

  if(AreOpenGLErrorFlagsSet()) {
    BOOST_LOG_SEV(log, LogSeverity::kError) << "Error creating shader program";
    throw std::runtime_error("Error creating shader program");
  }

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Linking shader program: " << handle_
    << " from vertex shader: " << vertex_shader
    << " and fragment shader: " << fragment_shader;

  // TODO: Check OpenGL errors/throw on error at each of these steps
  glAttachShader(handle_, vertex_shader);
  glAttachShader(handle_, fragment_shader);
  glLinkProgram(handle_);

  GLint param;
  glGetProgramiv(handle_, GL_LINK_STATUS, &param);

  if (!param) {
    glGetProgramiv(handle_, GL_INFO_LOG_LENGTH, &param);
    std::string error_message;
    error_message.resize(param);
    glGetProgramInfoLog(handle_, param, NULL, &error_message[0]);
    BOOST_LOG_SEV(log, LogSeverity::kError)
      << "Error linking shader program: " << error_message;
    throw std::runtime_error("Error linking shader program: " + error_message);
  }

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished linking shader program: " << handle_;
}

ShaderProgram::ShaderProgram(ShaderProgram&& other) noexcept
    : handle_(other.handle_) {
  other.handle_ = 0;
}

ShaderProgram::~ShaderProgram() {
  Deallocate();
}

ShaderProgram& ShaderProgram::operator=(ShaderProgram&& other) noexcept {
  Deallocate();
  handle_ = other.handle_;
  other.handle_ = 0;
  return *this;
}

ShaderProgram::operator GLuint() const {
  return handle_;
}

void ShaderProgram::Deallocate() noexcept {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Graphics");

  if (handle_) {
    BOOST_LOG_SEV(log, LogSeverity::kDebug)
      << "Deleting shader program: " << handle_;
    glDeleteProgram(handle_);
  }
}

ShaderUniformParameter::ShaderUniformParameter(
  const ShaderProgram& program, const std::string& uniform_name)
    : handle_(glGetUniformLocation(program, uniform_name.c_str())) {
  // TODO: Check OpenGL errors? Throw exception?
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Graphics");
  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Got uniform parameter: " << uniform_name
    << " from shader program: " << program;
}

ShaderUniformParameter::operator GLint() const {
  return handle_;
}
