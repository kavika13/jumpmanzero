#ifndef ENGINE_OBJECTS_WALLOBJECT_HPP_
#define ENGINE_OBJECTS_WALLOBJECT_HPP_

#include <memory>
#include "engine/leveldata.hpp"
#include "engine/resourcecontext.hpp"

namespace Jumpman {

namespace Objects {

class WallObject {
 public:
  explicit WallObject(const WallObjectData& data, ResourceContext&);

  std::shared_ptr<TriangleMesh> GetMesh();
  void SetMesh(std::shared_ptr<TriangleMesh> mesh);

  std::shared_ptr<Material> GetMaterial();
  void SetMaterial(std::shared_ptr<Material> material);

 private:
  std::shared_ptr<TriangleMesh> mesh_;
  std::shared_ptr<Material> material_;
};

};  // namespace Objects

};  // namespace Jumpman

#endif  // ENGINE_OBJECTS_WALLOBJECT_HPP_
