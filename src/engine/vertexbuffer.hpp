#ifndef ENGINE_VERTEXBUFFER_HPP_
#define ENGINE_VERTEXBUFFER_HPP_

#include <vector>
#define GL3_PROTOTYPES
#include <OpenGL/gl3.h>

class VertexBuffer {
 public:
  template <typename T, size_t N>
  explicit VertexBuffer(T buffer_data[N])
    : VertexBuffer(buffer_data, N * sizeof(T)) {
  }

  template <typename T>
  explicit VertexBuffer(std::vector<T> buffer_data)
    : VertexBuffer(&buffer_data[0], buffer_data.size() * sizeof(T)) {
  }

  VertexBuffer(const VertexBuffer&) = delete;
  VertexBuffer(VertexBuffer&&) noexcept;
  ~VertexBuffer();

  VertexBuffer& operator=(const VertexBuffer&) = delete;
  VertexBuffer& operator=(VertexBuffer&&) noexcept;

  // TODO: Function that returns a scoped Bind object?

  operator GLuint() const;  // TODO: Hide this, make other classes friends?

 private:
  VertexBuffer(const void* buffer_data, size_t buffer_size);
  void Deallocate();

  GLuint handle_;
};

struct VertexArray {
  explicit VertexArray(std::function<void()> configureVertexArray);
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

#endif  // ENGINE_VERTEXBUFFER_HPP_
