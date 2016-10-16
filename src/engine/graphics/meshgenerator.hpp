#ifndef ENGINE_GRAPHICS_MESHGENERATOR_HPP_
#define ENGINE_GRAPHICS_MESHGENERATOR_HPP_

#include <vector>
#include "engine/leveldata.hpp"
#include "engine/resourcecontext.hpp"
#include "engine/trianglemesh.hpp"

namespace Jumpman {

namespace Graphics {

class MeshGenerator {
 public:
  Vertex ConvertVertex(const VertexData& vertex);
  Vertex TranslateVertex(const VertexData& vertex, float x, float y, float z);

  void AddTriangle(const Vertex& v0, const Vertex& v1, const Vertex& v2);
  void AddPretexturedQuad(
    const Vertex& upper_left, const Vertex& upper_right,
    const Vertex& lower_left, const Vertex& lower_right);
  void AddQuad(
    const Vertex& v0, const Vertex& v1, const Vertex& v2, const Vertex& v3);
  void AddCube(
    float x_left, float y_top, float z_front,
    float x_right, float y_bottom, float z_back);
  void AddSkewedCube(
    bool drawtop, bool drawbottom,
    bool drawleft, bool drawright,
    bool drawfront, bool drawback,
    const Vertex& v0, const Vertex& v1, const Vertex& v2, const Vertex& v3,
    float front_z, float back_z);

  std::shared_ptr<TriangleMesh> CreateMesh(
    ResourceContext&, const std::string& tag) const;

 private:
  std::vector<Vertex> vertices_;
};

};  // namespace Jumpman

};  // namespace Graphics

#endif  // ENGINE_GRAPHICS_MESHGENERATOR_HPP_
