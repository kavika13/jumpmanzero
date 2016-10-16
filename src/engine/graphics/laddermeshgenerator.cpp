#include "laddermeshgenerator.hpp"

namespace Jumpman {

namespace Graphics {

LadderMeshGenerator::LadderMeshGenerator(
    const LadderObjectData& data,
    MeshGenerator& mesh_generator) {
  // TODO: Bounding box
  const float height = data.top_y - data.bottom_y;
  mesh_generator.AddCube(
    -6.5f, height, 0.0f,
    -5.2f, 0.0f, 1.0f);
  mesh_generator.AddCube(
    5.2f, height, 0.0f,
    6.5f, 0.0f, 1.0f);

  for (
      float rung_position = 5.0f;
      rung_position <= height - 3.0f;
      rung_position += 6) {
    mesh_generator.AddCube(
      -5.3f, rung_position, 0.0f,
      5.3f, rung_position - 1.5f, 1.0f);
  }
}

};  // namespace Graphics

};  // namespace Jumpman
