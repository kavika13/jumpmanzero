#include "engine/graphics/meshgenerator.hpp"
#include "engine/graphics/vinemeshgenerator.hpp"
#include "vineobject.hpp"

namespace Jumpman {

namespace Objects {

VineObject::VineObject(
  const VineObjectData& data, ResourceContext& resource_context)
    : origin(data.origin_x, data.bottom_y, data.front_z) {
  Graphics::MeshGenerator generator;
  Graphics::VineMeshGenerator generate_vine_mesh(data, generator);
  mesh_ = generator.CreateMesh(resource_context, data.tag);
  bounding_box_ = generator.CreateBoundingBox();
  material_ = resource_context.FindMaterial(data.material_tag);
}

std::shared_ptr<Graphics::TriangleMesh> VineObject::GetMesh() {
  return mesh_;
}

void VineObject::SetMesh(std::shared_ptr<Graphics::TriangleMesh> mesh) {
  mesh_ = mesh;
}

const AxisAlignedBox& VineObject::GetBoundingBox() const {
  return bounding_box_;
}

std::shared_ptr<Graphics::Material> VineObject::GetMaterial() {
  return material_;
}

void VineObject::SetMaterial(std::shared_ptr<Graphics::Material> material) {
  material_ = material;
}

};  // namespace Objects

};  // namespace Jumpman
