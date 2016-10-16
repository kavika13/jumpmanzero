#ifndef ENGINE_OBJECTS_QUADOBJECT_HPP_
#define ENGINE_OBJECTS_QUADOBJECT_HPP_

#include <memory>
#define GLM_FORCE_LEFT_HANDED
#include <glm/vec3.hpp>
#include "engine/leveldata.hpp"
#include "engine/resourcecontext.hpp"

namespace Jumpman {

namespace Objects {

class QuadObject {
 public:
  explicit QuadObject(const QuadObjectData& data, ResourceContext&);

  std::shared_ptr<TriangleMesh> GetMesh();
  void SetMesh(std::shared_ptr<TriangleMesh> mesh);

  std::shared_ptr<Material> GetMaterial();
  void SetMaterial(std::shared_ptr<Material> material);

  glm::vec3 origin;

 private:
  std::shared_ptr<TriangleMesh> mesh_;
  std::shared_ptr<Material> material_;
};

};  // namespace Objects

};  // namespace Jumpman

#endif  // ENGINE_OBJECTS_QUADOBJECT_HPP_
