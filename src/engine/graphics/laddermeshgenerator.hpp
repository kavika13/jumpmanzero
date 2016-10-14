#ifndef ENGINE_GRAPHICS_LADDERMESHGENERATOR_HPP_
#define ENGINE_GRAPHICS_LADDERMESHGENERATOR_HPP_

#include "engine/leveldata.hpp"
#include "meshgenerator.hpp"

namespace Jumpman {

namespace Graphics {

class LadderMeshGenerator {
 public:
  LadderMeshGenerator(const LadderObjectData&, MeshGenerator&);
};

};  // namespace Graphics

};  // namespace Jumpman

#endif  // ENGINE_GRAPHICS_LADDERMESHGENERATOR_HPP_
