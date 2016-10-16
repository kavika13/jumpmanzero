#include "engine/graphics/meshgenerator.hpp"
#include "engine/graphics/wallmeshgenerator.hpp"
#include "wallobject.hpp"

namespace Jumpman {

namespace Objects {

WallObject::WallObject(
  const WallObjectData& data, ResourceContext& resource_context)
    : origin(data.vertices[2].x, data.vertices[2].y, data.front_z) {
  Graphics::MeshGenerator generator;
  Graphics::WallMeshGenerator generate_wall_mesh(data, generator);
  mesh_ = generator.CreateMesh(resource_context, data.tag);
  material_ = resource_context.FindMaterial(data.material_tag);
}

std::shared_ptr<TriangleMesh> WallObject::GetMesh() {
  return mesh_;
}

void WallObject::SetMesh(std::shared_ptr<TriangleMesh> mesh) {
  mesh_ = mesh;
}

std::shared_ptr<Material> WallObject::GetMaterial() {
  return material_;
}

void WallObject::SetMaterial(std::shared_ptr<Material> material) {
  material_ = material;
}

};  // namespace Objects

};  // namespace Jumpman
