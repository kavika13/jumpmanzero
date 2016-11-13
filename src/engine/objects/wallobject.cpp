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
  bounding_box_ = generator.CreateBoundingBox();
  material_ = resource_context.FindMaterial(data.material_tag);
}

std::shared_ptr<Graphics::TriangleMesh> WallObject::GetMesh() {
  return mesh_;
}

void WallObject::SetMesh(std::shared_ptr<Graphics::TriangleMesh> mesh) {
  mesh_ = mesh;
}

const AxisAlignedBox& WallObject::GetBoundingBox() const {
  return bounding_box_;
}

std::shared_ptr<Graphics::Material> WallObject::GetMaterial() {
  return material_;
}

void WallObject::SetMaterial(std::shared_ptr<Graphics::Material> material) {
  material_ = material;
}

};  // namespace Objects

};  // namespace Jumpman
