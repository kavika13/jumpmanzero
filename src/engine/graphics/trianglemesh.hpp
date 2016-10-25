#ifndef ENGINE_GRAPHICS_TRIANGLEMESH_HPP_
#define ENGINE_GRAPHICS_TRIANGLEMESH_HPP_

#include <vector>
#include "vertexarray.hpp"
#include "vertexbuffer.hpp"

namespace Jumpman {

namespace Graphics {

// TODO: Don't force this definition
struct Vertex {
  float x, y, z;
  float nx, ny, nz;
  float tu, tv;
};

class TriangleMesh {
 public:
  template <typename T, size_t N>
  explicit TriangleMesh(T buffer_data[N])
      : TriangleMesh(buffer_data, N * sizeof(T)) {
    static_assert(N % 3 == 0, "Vertex count is not divisible by three");
  }

  template <typename T>
  explicit TriangleMesh(std::vector<T> buffer_data)
      : TriangleMesh(&buffer_data[0], buffer_data.size() * sizeof(T)) {
    if (buffer_data.size() % 3 != 0) {
      throw std::runtime_error("Vertex count is not divisible by three");
    }
  }

  void Draw() noexcept;

 private:
  TriangleMesh(const void* buffer_data, size_t buffer_size);

  const size_t triangle_count_;
  VertexBuffer vertex_buffer_;
  VertexArray vertex_array_;
};

};  // namespace Graphics

};  // namespace Jumpman

#endif  // ENGINE_GRAPHICS_TRIANGLEMESH_HPP_
