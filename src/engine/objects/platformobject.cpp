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
  material_ = resource_context.FindMaterial(data.material_tag);
}

std::shared_ptr<TriangleMesh> PlatformObject::GetMesh() {
  return mesh_;
}

void PlatformObject::SetMesh(std::shared_ptr<TriangleMesh> mesh) {
  mesh_ = mesh;
}

std::shared_ptr<Material> PlatformObject::GetMaterial() {
  return material_;
}

void PlatformObject::SetMaterial(std::shared_ptr<Material> material) {
  material_ = material;
}

};  // namespace Objects

};  // namespace Jumpman