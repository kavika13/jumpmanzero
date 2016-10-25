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
  material_ = resource_context.FindMaterial(data.material_tag);
}

std::shared_ptr<Graphics::TriangleMesh> VineObject::GetMesh() {
  return mesh_;
}

void VineObject::SetMesh(std::shared_ptr<Graphics::TriangleMesh> mesh) {
  mesh_ = mesh;
}

std::shared_ptr<Graphics::Material> VineObject::GetMaterial() {
  return material_;
}

void VineObject::SetMaterial(std::shared_ptr<Graphics::Material> material) {
  material_ = material;
}

};  // namespace Objects

};  // namespace Jumpman
