#include "engine/graphics/meshgenerator.hpp"
#include "engine/graphics/laddermeshgenerator.hpp"
#include "ladderobject.hpp"

namespace Jumpman {

namespace Objects {

LadderObject::LadderObject(
  const LadderObjectData& data, ResourceContext& resource_context)
    : origin(data.origin_x, data.bottom_y, data.front_z) {
  Graphics::MeshGenerator generator;
  Graphics::LadderMeshGenerator generate_ladder_mesh(data, generator);
  mesh_ = generator.CreateMesh(resource_context, data.tag);
  material_ = resource_context.FindMaterial(data.material_tag);
}

std::shared_ptr<Graphics::TriangleMesh> LadderObject::GetMesh() {
  return mesh_;
}

void LadderObject::SetMesh(std::shared_ptr<Graphics::TriangleMesh> mesh) {
  mesh_ = mesh;
}

std::shared_ptr<Graphics::Material> LadderObject::GetMaterial() {
  return material_;
}

void LadderObject::SetMaterial(std::shared_ptr<Graphics::Material> material) {
  material_ = material;
}

};  // namespace Objects

};  // namespace Jumpman
