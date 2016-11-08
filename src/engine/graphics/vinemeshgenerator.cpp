#include "vinemeshgenerator.hpp"

namespace Jumpman {

namespace Graphics {

VineMeshGenerator::VineMeshGenerator(
    const VineObjectData& data,
    MeshGenerator& mesh_generator) {
  // TODO: Bounding box
  const float height = data.top_y - data.bottom_y;
  bool is_right_side = false;
  for (
      float lobe_position = 3.0f;
      lobe_position <= height;
      lobe_position += 3, is_right_side = !is_right_side) {
    if (is_right_side) {
      mesh_generator.AddCube(
        -0.25f, lobe_position, 0.0f,
        0.75f, lobe_position - 3.0f, 1.0f);
    } else {
      mesh_generator.AddCube(
        -0.75f, lobe_position, 0.0f,
        0.25f, lobe_position - 3.0f, 1.0f);
    }
  }
}

};  // namespace Graphics

};  // namespace Jumpman
