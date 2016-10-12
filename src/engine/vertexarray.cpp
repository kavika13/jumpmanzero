#include "logging.hpp"
#include "vertexarray.hpp"
#include "openglerror.hpp"

VertexArray::VertexArray(std::function<void()> configure_vertex_array) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Graphics");
  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Creating vertex array";

  glGenVertexArrays(1, &handle_);

  if (AreOpenGLErrorFlagsSet()) {
    BOOST_LOG_SEV(log, LogSeverity::kError) << "Error creating vertex array";
    throw std::runtime_error("Error creating vertex array");
  }

  glBindVertexArray(handle_);

  if (AreOpenGLErrorFlagsSet()) {
    BOOST_LOG_SEV(log, LogSeverity::kError) << "Error binding vertex array";
    throw std::runtime_error("Error binding vertex array");
  }

  configure_vertex_array();

  glBindVertexArray(0);  // TODO: Should never error?

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Created vertex array: " << handle_;
}

VertexArray::VertexArray(VertexArray&& other) noexcept
    : handle_(other.handle_) {
  other.handle_ = 0;
}

VertexArray::~VertexArray() {
  Deallocate();
}

VertexArray& VertexArray::operator=(VertexArray&& other) noexcept {
  Deallocate();
  handle_ = other.handle_;
  other.handle_ = 0;
  return *this;
}

VertexArray::operator GLuint() const {
  return handle_;
}

void VertexArray::Deallocate() {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Graphics");

  if (handle_) {
    BOOST_LOG_SEV(log, LogSeverity::kDebug)
      << "Deleting vertex array: " << handle_;
    glDeleteVertexArrays(1, &handle_);
  }
}
