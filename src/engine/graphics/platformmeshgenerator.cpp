#include "platformmeshgenerator.hpp"

namespace Jumpman {

namespace Graphics {

PlatformMeshGenerator::PlatformMeshGenerator(
    const PlatformObjectData& data,
    MeshGenerator& generator) {
  // TODO: Bounding box, proper scene origin
  generator.AddSkewedCube(
    data.drawtop,
    data.drawbottom,
    data.drawleft,
    data.drawright,
    data.drawfront,
    data.drawback,
    generator.ConvertVertex(data.vertices[0]),
    generator.ConvertVertex(data.vertices[1]),
    generator.ConvertVertex(data.vertices[2]),
    generator.ConvertVertex(data.vertices[3]),
    data.front_z, data.back_z);
}

};  // namespace Graphics

};  // namespace Jumpman
