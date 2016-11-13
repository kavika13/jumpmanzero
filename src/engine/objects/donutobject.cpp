#include "engine/graphics/meshgenerator.hpp"
#include "engine/graphics/donutmeshgenerator.hpp"
#include "donutobject.hpp"

namespace Jumpman {

namespace Objects {

DonutObject::DonutObject(
      const DonutObjectData& data, ResourceContext& resource_context)
    : origin(data.origin_x, data.origin_y, data.origin_z) {
  Graphics::MeshGenerator generator;
  Graphics::DonutMeshGenerator generate_donut_mesh(data, generator);
  mesh_ = generator.CreateMesh(resource_context, data.tag);
  bounding_box_ = generator.CreateBoundingBox();
  material_ = resource_context.FindMaterial(data.material_tag);
}

std::shared_ptr<Graphics::TriangleMesh> DonutObject::GetMesh() {
  return mesh_;
}

void DonutObject::SetMesh(std::shared_ptr<Graphics::TriangleMesh> mesh) {
  mesh_ = mesh;
}

const AxisAlignedBox& DonutObject::GetBoundingBox() const {
  return bounding_box_;
}

std::shared_ptr<Graphics::Material> DonutObject::GetMaterial() {
  return material_;
}

void DonutObject::SetMaterial(std::shared_ptr<Graphics::Material> material) {
  material_ = material;
}

};  // namespace Objects

};  // namespace Jumpman
