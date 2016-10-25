#define GL3_PROTOTYPES
#include <OpenGL/gl3.h>
#include "trianglemesh.hpp"

namespace Jumpman {

namespace Graphics {

TriangleMesh::TriangleMesh(const void* buffer_data, size_t buffer_size)
    : triangle_count_(buffer_size)
    , vertex_buffer_(buffer_data, buffer_size)
    , vertex_array_([&]() {
      GLuint index = 0;

      // TODO: Check OpenGL errors?
      glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer_);

      // TODO: Don't assume vertex shape?
      glVertexAttribPointer(
        index, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex),
        reinterpret_cast<GLvoid*>(offsetof(Vertex, x)));
      glEnableVertexAttribArray(index++);

      glVertexAttribPointer(
        index, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex),
        reinterpret_cast<GLvoid*>(offsetof(Vertex, nx)));
      glEnableVertexAttribArray(index++);

      glVertexAttribPointer(
        index, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex),
        reinterpret_cast<GLvoid*>(offsetof(Vertex, tu)));
      glEnableVertexAttribArray(index++);

      glBindBuffer(GL_ARRAY_BUFFER, 0);
    }) {
}

void TriangleMesh::Draw() noexcept {
  glBindVertexArray(vertex_array_);
  glDrawArrays(GL_TRIANGLES, 0, triangle_count_);
}

};  // namespace Graphics

};  // namespace Jumpman
