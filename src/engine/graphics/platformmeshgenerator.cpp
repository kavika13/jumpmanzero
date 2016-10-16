#include "platformmeshgenerator.hpp"

namespace Jumpman {

namespace Graphics {

PlatformMeshGenerator::PlatformMeshGenerator(
    const PlatformObjectData& data,
    MeshGenerator& generator) {
  // TODO: Bounding box
  auto& origin = data.vertices[2];
  generator.AddSkewedCube(
    data.drawtop,
    data.drawbottom,
    data.drawleft,
    data.drawright,
    data.drawfront,
    data.drawback,
    generator.TranslateVertex(
      data.vertices[0], -origin.x, -origin.y, 0.0f),
    generator.TranslateVertex(
      data.vertices[1], -origin.x, -origin.y, 0.0f),
    generator.TranslateVertex(
      data.vertices[2], -origin.x, -origin.y, 0.0f),
    generator.TranslateVertex(
      data.vertices[3], -origin.x, -origin.y, 0.0f),
    0.0f, data.back_z - data.front_z);
}

};  // namespace Graphics

};  // namespace Jumpman
