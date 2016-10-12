#ifndef ENGINE_QUADOBJECTRESOURCE_HPP_
#define ENGINE_QUADOBJECTRESOURCE_HPP_

#include "leveldata.hpp"
#include "meshgenerator.hpp"

class QuadObjectResource {
 public:
  QuadObjectResource(const QuadObjectData&, MeshGenerator&);
};

#endif  // ENGINE_QUADOBJECTRESOURCE_HPP_
