#ifndef ENGINE_GRAPHICS_WALLMESHGENERATOR_HPP_
#define ENGINE_GRAPHICS_WALLMESHGENERATOR_HPP_

#include "engine/leveldata.hpp"
#include "meshgenerator.hpp"

namespace Jumpman {

namespace Graphics {

class WallMeshGenerator {
 public:
  WallMeshGenerator(const WallObjectData&, MeshGenerator&);
};

};  // namespace Graphics

};  // namespace Jumpman

#endif  // ENGINE_GRAPHICS_WALLMESHGENERATOR_HPP_
