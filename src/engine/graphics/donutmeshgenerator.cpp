#include "donutmeshgenerator.hpp"

namespace Jumpman {

namespace Graphics {

DonutMeshGenerator::DonutMeshGenerator(
    const DonutObjectData& data, MeshGenerator& generator) {
  // TODO: Bounding box
  generator.AddCube(-1.0f, 3.0f, 0.0f, 1.0f, 1.0f, 1.0f);
  generator.AddCube(-3.0f, 1.0f, 0.0f, -1.0f, -1.0f, 1.0f);
  generator.AddCube(1.0f, 1.0f, 0.0f, 3.0f, -1.0f, 1.0f);
  generator.AddCube(-1.0f, -1.0f, 0.0f, 1.0f, -3.0f, 1.0f);
}

}; // namespace Graphics

}; // namespace Jumpman
