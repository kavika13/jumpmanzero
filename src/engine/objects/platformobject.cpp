#include "engine/graphics/meshgenerator.hpp"
#include "engine/graphics/platformmeshgenerator.hpp"
#include "platformobject.hpp"

namespace Jumpman {

namespace Objects {

PlatformObject::PlatformObject(
  const PlatformObjectData& data, ResourceContext& resource_context)
    : origin(data.vertices[2].x, data.vertices[2].y, data.front_z) {
  Graphics::MeshGenerator generator;
  Graphics::PlatformMeshGenerator generate_platform_mesh(data, generator);
  mesh_ = generator.CreateMesh(resource_context, data.tag);
  bounding_box_ = generator.CreateBoundingBox();
  material_ = resource_context.FindMaterial(data.material_tag);
}

std::shared_ptr<Graphics::TriangleMesh> PlatformObject::GetMesh() {
  return mesh_;
}

void PlatformObject::SetMesh(std::shared_ptr<Graphics::TriangleMesh> mesh) {
  mesh_ = mesh;
}

const AxisAlignedBox& PlatformObject::GetBoundingBox() const {
  return bounding_box_;
}

std::shared_ptr<Graphics::Material> PlatformObject::GetMaterial() {
  return material_;
}

void PlatformObject::SetMaterial(std::shared_ptr<Graphics::Material> material) {
  material_ = material;
}

};  // namespace Objects

};  // namespace Jumpman
