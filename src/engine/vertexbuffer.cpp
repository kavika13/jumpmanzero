#include "logging.hpp"
#include "vertexbuffer.hpp"
#include "openglerror.hpp"

VertexBuffer::VertexBuffer(const void* buffer_data, size_t buffer_size) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Graphics");
  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Creating vertex buffer";

  glGenBuffers(1, &handle_);

  if (AreOpenGLErrorFlagsSet()) {
    BOOST_LOG_SEV(log, LogSeverity::kError) << "Error creating vertex buffer";
    throw std::runtime_error("Error creating vertex buffer");
  }

  glBindBuffer(GL_ARRAY_BUFFER, handle_);
    glBufferData(GL_ARRAY_BUFFER, buffer_size, buffer_data, GL_STATIC_DRAW);
  glBindBuffer(GL_ARRAY_BUFFER, 0);

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

VertexArray::VertexArray(std::function<void()> configureVertexArray) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Graphics");
  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Creating vertex array";

  glGenVertexArrays(1, &handle_);

  if (AreOpenGLErrorFlagsSet()) {
    BOOST_LOG_SEV(log, LogSeverity::kError) << "Error creating vertex array";
    throw std::runtime_error("Error creating vertex array");
  }

  glBindVertexArray(handle_);
    configureVertexArray();
  glBindVertexArray(0);

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
