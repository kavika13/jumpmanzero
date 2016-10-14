#include "engine/graphics/meshgenerator.hpp"
#include "engine/graphics/quadmeshgenerator.hpp"
#include "quadobject.hpp"

namespace Jumpman {

namespace Objects {

QuadObject::QuadObject(
    const QuadObjectData& data, ResourceContext& resource_context) {
  Graphics::MeshGenerator generator;
  Graphics::QuadMeshGenerator generate_quad_mesh(data, generator);
  mesh_ = generator.CreateMesh(resource_context, data.tag);
  material_ = resource_context.FindMaterial(data.material_tag);
}

std::shared_ptr<TriangleMesh> QuadObject::GetMesh() {
  return mesh_;
}

void QuadObject::SetMesh(std::shared_ptr<TriangleMesh> mesh) {
  mesh_ = mesh;
}

std::shared_ptr<Material> QuadObject::GetMaterial() {
  return material_;
}

void QuadObject::SetMaterial(std::shared_ptr<Material> material) {
  material_ = material;
}

};  // namespace Objects

};  // namespace Jumpman
