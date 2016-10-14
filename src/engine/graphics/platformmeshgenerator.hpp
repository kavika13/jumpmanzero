#ifndef ENGINE_GRAPHICS_PLATFORMMESHGENERATOR_HPP_
#define ENGINE_GRAPHICS_PLATFORMMESHGENERATOR_HPP_

#include "engine/leveldata.hpp"
#include "meshgenerator.hpp"

namespace Jumpman {

namespace Graphics {

class PlatformMeshGenerator {
 public:
  PlatformMeshGenerator(const PlatformObjectData&, MeshGenerator&);
};

};  // namespace Graphics

};  // namespace Jumpman

#endif  // ENGINE_GRAPHICS_PLATFORMMESHGENERATOR_HPP_
