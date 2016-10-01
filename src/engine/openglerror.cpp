#define GL3_PROTOTYPES
#include <OpenGL/gl3.h>
#include "logging.hpp"
#include "openglerror.hpp"

bool AreOpenGLErrorFlagsSet() {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Graphics");

  bool result = false;
  GLenum current_error;

  while ((current_error = glGetError())) {
    result = true;
    const char* current_error_message;

    switch (current_error) {
      case GL_INVALID_ENUM:
        current_error_message = "GL_INVALID_ENUM";
        break;
      case GL_INVALID_VALUE:
        current_error_message = "GL_INVALID_VALUE";
        break;
      case GL_INVALID_OPERATION:
        current_error_message = "GL_INVALID_OPERATION";
        break;
      case GL_INVALID_FRAMEBUFFER_OPERATION:
        current_error_message = "GL_INVALID_FRAMEBUFFER_OPERATION";
        break;
      case GL_OUT_OF_MEMORY:
        current_error_message = "GL_OUT_OF_MEMORY";
        break;
      default:
        assert(false);
    }

    BOOST_LOG_SEV(log, LogSeverity::kError)
      << "Error from OpenGL: " << current_error_message;
  }

  return result;
}
