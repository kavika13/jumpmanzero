#ifndef ENGINE_LEVELRESOURCE_HPP_
#define ENGINE_LEVELRESOURCE_HPP_

#include "leveldata.hpp"
#include "resourcecontext.hpp"
#include "scene.hpp"

class LevelResource {
 public:
  LevelResource(const LevelData&, ResourceContext&, Scene&);
};

#endif  // ENGINE_LEVELRESOURCE_HPP_
