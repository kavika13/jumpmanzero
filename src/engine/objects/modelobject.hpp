#ifndef ENGINE_OBJECTS_MODELOBJECT_HPP_
#define ENGINE_OBJECTS_MODELOBJECT_HPP_

#include <memory>
#define GLM_FORCE_LEFT_HANDED
#include <glm/vec3.hpp>
#include "engine/axisalignedbox.hpp"
#include "engine/leveldata.hpp"
#include "engine/resourcecontext.hpp"

namespace Jumpman {

namespace Objects {

class ModelObject {
 public:
  explicit ModelObject(
    const std::string& filename, const std::string& tag, ResourceContext&);

  std::shared_ptr<Graphics::TriangleMesh> GetMesh();
  void SetMesh(std::shared_ptr<Graphics::TriangleMesh> mesh);

  const AxisAlignedBox& GetBoundingBox() const;

  std::shared_ptr<Graphics::Material> GetMaterial();
  void SetMaterial(std::shared_ptr<Graphics::Material> material);

  glm::vec3 origin;

 private:
  std::shared_ptr<Graphics::TriangleMesh> mesh_;
  AxisAlignedBox bounding_box_;
  std::shared_ptr<Graphics::Material> material_;
};

};  // namespace Objects

};  // namespace Jumpman

#endif  // ENGINE_OBJECTS_MODELOBJECT_HPP_
