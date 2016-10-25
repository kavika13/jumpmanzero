#include "engine/logging.hpp"
#include "openglerror.hpp"
#include "vertexbuffer.hpp"

namespace Jumpman {

namespace Graphics {

VertexBuffer::VertexBuffer(const void* buffer_data, size_t buffer_size) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Graphics");
  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Creating vertex buffer";

  glGenBuffers(1, &handle_);

  if (AreOpenGLErrorFlagsSet()) {
    BOOST_LOG_SEV(log, LogSeverity::kError) << "Error creating vertex buffer";
    throw std::runtime_error("Error creating vertex buffer");
  }

  glBindBuffer(GL_ARRAY_BUFFER, handle_);

  if (AreOpenGLErrorFlagsSet()) {
    BOOST_LOG_SEV(log, LogSeverity::kError) << "Error binding vertex buffer";
    throw std::runtime_error("Error binding vertex buffer");
  }

  glBufferData(GL_ARRAY_BUFFER, buffer_size, buffer_data, GL_STATIC_DRAW);

  if (AreOpenGLErrorFlagsSet()) {
    BOOST_LOG_SEV(log, LogSeverity::kError) << "Error setting buffer data";
    throw std::runtime_error("Error setting buffer data");
  }

  glBindBuffer(GL_ARRAY_BUFFER, 0);  // TODO: Should never error?

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Created vertex buffer: " << handle_;
}

VertexBuffer::VertexBuffer(VertexBuffer&& other) noexcept
    : handle_(other.handle_) {
  other.handle_ = 0;
}

VertexBuffer::~VertexBuffer() {
  Deallocate();
}

VertexBuffer& VertexBuffer::operator=(VertexBuffer&& other) noexcept {
  Deallocate();
  handle_ = other.handle_;
  other.handle_ = 0;
  return *this;
}

VertexBuffer::operator GLuint() const {
  return handle_;
}

void VertexBuffer::Deallocate() {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Graphics");

  if (handle_) {
    BOOST_LOG_SEV(log, LogSeverity::kInfo)
      << "Deleting vertex buffer: " << handle_;
    glDeleteBuffers(1, &handle_);
  }
}

};  // namespace Graphics

};  // namespace Jumpman
