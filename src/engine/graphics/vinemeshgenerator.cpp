#include "vinemeshgenerator.hpp"

namespace Jumpman {

namespace Graphics {

VineMeshGenerator::VineMeshGenerator(
    const VineObjectData& data,
    MeshGenerator& mesh_generator) {
  // TODO: Bounding box, proper scene origin
  bool is_right_side = false;
  for (
      float lobe_position = data.bottom_y + 3.0f;
      lobe_position <= data.top_y;
      lobe_position += 3, is_right_side ^= is_right_side) {
    if (is_right_side) {
      mesh_generator.AddCube(
        data.origin_x - 0.25f, lobe_position, data.front_z,
        data.origin_x + 0.75f, lobe_position - 3.0f, data.front_z + 1);
    } else {
      mesh_generator.AddCube(
        data.origin_x - 0.75f, lobe_position, data.front_z,
        data.origin_x + 0.25f, lobe_position - 3.0f, data.front_z + 1);
    }
  }
}

};  // namespace Graphics

};  // namespace Jumpman
