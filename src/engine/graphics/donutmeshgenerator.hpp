#ifndef ENGINE_GRAPHICS_DONUTMESHGENERATOR_HPP_
#define ENGINE_GRAPHICS_DONUTMESHGENERATOR_HPP_

#include "engine/leveldata.hpp"
#include "meshgenerator.hpp"

namespace Jumpman {

namespace Graphics {

class DonutMeshGenerator {
 public:
  DonutMeshGenerator(const DonutObjectData&, MeshGenerator&);
};

};  // namespace Graphics

};  // namespace Jumpman

#endif  // ENGINE_GRAPHICS_DONUTMESHGENERATOR_HPP_
