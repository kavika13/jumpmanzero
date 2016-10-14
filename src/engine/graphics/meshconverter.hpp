#ifndef ENGINE_GRAPHICS_MESHCONVERTER_HPP_
#define ENGINE_GRAPHICS_MESHCONVERTER_HPP_

#include "meshdata.hpp"

namespace Jumpman {

namespace Graphics {

struct OldMeshVertexData {
  const float x, y, z;
  const float nx, ny, nz;
  const float unused_;
  const float tu, tv;
};

struct MeshConverter {
  static MeshConverter FromStream(std::istream& stream);
  MeshData Convert();

  const std::vector<OldMeshVertexData> vertices;
};

};  // namespace Graphics

};  // namespace Jumpman

#endif  // ENGINE_GRAPHICS_MESHCONVERTER_HPP_
