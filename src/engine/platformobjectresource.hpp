#ifndef ENGINE_PLATFORMOBJECTRESOURCE_HPP_
#define ENGINE_PLATFORMOBJECTRESOURCE_HPP_

#include "leveldata.hpp"
#include "meshgenerator.hpp"

class PlatformObjectResource {
 public:
  PlatformObjectResource(const PlatformObjectData&, MeshGenerator&);
};

#endif  // ENGINE_PLATFORMOBJECTRESOURCE_HPP_
