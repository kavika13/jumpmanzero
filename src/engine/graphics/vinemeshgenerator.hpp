#ifndef ENGINE_GRAPHICS_VINEMESHGENERATOR_HPP_
#define ENGINE_GRAPHICS_VINEMESHGENERATOR_HPP_

#include "engine/leveldata.hpp"
#include "meshgenerator.hpp"

namespace Jumpman {

namespace Graphics {

class VineMeshGenerator {
 public:
  VineMeshGenerator(const VineObjectData&, MeshGenerator&);
};

};  // namespace Graphics

};  // namespace Jumpman

#endif  // ENGINE_GRAPHICS_VINEMESHGENERATOR_HPP_
