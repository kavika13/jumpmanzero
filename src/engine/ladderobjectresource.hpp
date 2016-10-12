#ifndef ENGINE_LADDEROBJECTRESOURCE_HPP_
#define ENGINE_LADDEROBJECTRESOURCE_HPP_

#include "leveldata.hpp"
#include "meshgenerator.hpp"

class LadderObjectResource {
 public:
  LadderObjectResource(const LadderObjectData&, MeshGenerator&);
};

#endif  // ENGINE_LADDEROBJECTRESOURCE_HPP_
