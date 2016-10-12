#include "donutobjectresource.hpp"

DonutObjectResource::DonutObjectResource(
    const DonutObjectData& data, MeshGenerator& generator) {
  // TODO: Bounding box, proper scene origin
  generator.AddCube(
    data.origin_x - 1, data.origin_y + 3, data.origin_z,
    data.origin_x + 1, data.origin_y + 1, data.origin_z + 1);
  generator.AddCube(
    data.origin_x - 3, data.origin_y + 1, data.origin_z,
    data.origin_x - 1, data.origin_y - 1, data.origin_z + 1);
  generator.AddCube(
    data.origin_x + 1, data.origin_y + 1, data.origin_z,
    data.origin_x + 3, data.origin_y - 1, data.origin_z + 1);
  generator.AddCube(
    data.origin_x - 1, data.origin_y - 1, data.origin_z,
    data.origin_x + 1, data.origin_y - 3, data.origin_z + 1);
}
