#ifndef ENGINE_MESHGENERATOR_HPP_
#define ENGINE_MESHGENERATOR_HPP_

#include <vector>
#include "leveldata.hpp"
#include "resourcecontext.hpp"
#include "trianglemesh.hpp"

class MeshGenerator {
 public:
  Vertex ConvertVertex(const VertexData& vertex);

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
  Vertex AppendTexCoord(const Vertex& vertex, float tu, float tv);
  Vertex AppendZCoord(const Vertex& vertex, float z);

  std::vector<Vertex> vertices_;
};

#endif  // ENGINE_MESHGENERATOR_HPP_