#include "engine/graphics/meshgenerator.hpp"
#include "engine/graphics/quadmeshgenerator.hpp"
#include "quadobject.hpp"

namespace Jumpman {

namespace Objects {

QuadObject::QuadObject(
  const QuadObjectData& data, ResourceContext& resource_context)
    : origin(data.origin_x, data.origin_y, data.origin_z) {
  Graphics::MeshGenerator generator;
  Graphics::QuadMeshGenerator generate_quad_mesh(data, generator);
  mesh_ = generator.CreateMesh(resource_context, data.tag);
  bounding_box_ = generator.CreateBoundingBox();
  material_ = resource_context.FindMaterial(data.material_tag);
}

std::shared_ptr<Graphics::TriangleMesh> QuadObject::GetMesh() {
  return mesh_;
}

void QuadObject::SetMesh(std::shared_ptr<Graphics::TriangleMesh> mesh) {
  mesh_ = mesh;
}

const AxisAlignedBox& QuadObject::GetBoundingBox() const {
  return bounding_box_;
}

std::shared_ptr<Graphics::Material> QuadObject::GetMaterial() {
  return material_;
}

void QuadObject::SetMaterial(std::shared_ptr<Graphics::Material> material) {
  material_ = material;
}

};  // namespace Objects

};  // namespace Jumpman
