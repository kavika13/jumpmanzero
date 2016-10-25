#ifndef ENGINE_GRAPHICS_VERTEXBUFFER_HPP_
#define ENGINE_GRAPHICS_VERTEXBUFFER_HPP_

#define GL3_PROTOTYPES
#include <OpenGL/gl3.h>

namespace Jumpman {

namespace Graphics {

class VertexBuffer {
 public:
  VertexBuffer(const void* buffer_data, size_t buffer_size);
  VertexBuffer(const VertexBuffer&) = delete;
  VertexBuffer(VertexBuffer&&) noexcept;
  ~VertexBuffer();

  VertexBuffer& operator=(const VertexBuffer&) = delete;
  VertexBuffer& operator=(VertexBuffer&&) noexcept;

  // TODO: Function that returns a scoped Bind object?

  operator GLuint() const;  // TODO: Hide this, make other classes friends?

 private:
  void Deallocate();

  GLuint handle_;
};

};  // namespace Graphics

};  // namespace Jumpman

#endif  // ENGINE_GRAPHICS_VERTEXBUFFER_HPP_
