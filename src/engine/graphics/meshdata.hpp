#ifndef ENGINE_GRAPHICS_MESHDATA_HPP_
#define ENGINE_GRAPHICS_MESHDATA_HPP_

#include <istream>
#include <vector>

namespace Jumpman {

namespace Graphics {

struct MeshVertexData {
  friend std::ostream& operator<<(std::ostream&, const MeshVertexData&);
  friend bool operator==(const MeshVertexData& lhs, const MeshVertexData& rhs);

  const float x, y, z;
  const float nx, ny, nz;
  const float tu, tv;
};

struct MeshData {
  static MeshData FromStream(std::istream& stream);

  friend std::ostream& operator<<(std::ostream& stream, const MeshData& data);
  friend bool operator==(const MeshData& lhs, const MeshData& rhs);

  const std::vector<MeshVertexData> vertices;
};

};  // namespace Graphics

};  // namespace Jumpman

#endif  // ENGINE_GRAPHICS_MESHDATA_HPP_
