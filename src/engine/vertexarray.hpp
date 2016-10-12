#ifndef ENGINE_VERTEXARRAY_HPP_
#define ENGINE_VERTEXARRAY_HPP_

#include <functional>
#define GL3_PROTOTYPES
#include <OpenGL/gl3.h>

struct VertexArray {
  explicit VertexArray(std::function<void()> configure_vertex_array);
  VertexArray(const VertexArray&) = delete;
  VertexArray(VertexArray&&) noexcept;
  ~VertexArray();

  VertexArray& operator=(const VertexArray&) = delete;
  VertexArray& operator=(VertexArray&&) noexcept;

  operator GLuint() const;

 private:
  void Deallocate();

  GLuint handle_;
};

#endif  // ENGINE_VERTEXARRAY_HPP_
