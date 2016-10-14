#include "laddermeshgenerator.hpp"

namespace Jumpman {

namespace Graphics {

LadderMeshGenerator::LadderMeshGenerator(
    const LadderObjectData& data,
    MeshGenerator& mesh_generator) {
  mesh_generator.AddCube(
    data.origin_x - 6.5f, data.top_y, data.front_z,
    data.origin_x - 5.2f, data.bottom_y, data.front_z + 1);
  mesh_generator.AddCube(
    data.origin_x + 5.2f, data.top_y, data.front_z,
    data.origin_x + 6.5f, data.bottom_y, data.front_z + 1);

  for (
      float rung_position = data.bottom_y + 5.0f;
      rung_position <= data.top_y - 3.0f;
      rung_position += 6) {
    mesh_generator.AddCube(
      data.origin_x - 5.3f, rung_position, data.front_z,
      data.origin_x + 5.3f, rung_position - 1.5f, data.front_z + 1);
  }
}

};  // namespace Graphics

};  // namespace Jumpman
