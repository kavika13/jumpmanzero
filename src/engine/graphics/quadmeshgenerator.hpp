#ifndef ENGINE_GRAPHICS_QUADMESHGENERATOR_HPP_
#define ENGINE_GRAPHICS_QUADMESHGENERATOR_HPP_

#include "engine/leveldata.hpp"
#include "meshgenerator.hpp"

namespace Jumpman {

namespace Graphics {

class QuadMeshGenerator {
 public:
  QuadMeshGenerator(const QuadObjectData&, MeshGenerator&);
};

};  // namespace Graphics

};  // namespace Jumpman

#endif  // ENGINE_GRAPHICS_QUADMESHGENERATOR_HPP_
