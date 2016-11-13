#include "modelobject.hpp"

namespace Jumpman {

namespace Objects {

ModelObject::ModelObject(
    const std::string& filename,
    const std::string& tag,
    ResourceContext& resource_context) {
  mesh_ = resource_context.LoadMesh(
    filename,
    tag,
    [this](std::vector<Graphics::Vertex>& vertices) {
      bounding_box_ = AxisAlignedBox::FromPoints(vertices);
    });
}

std::shared_ptr<Graphics::TriangleMesh> ModelObject::GetMesh() {
  return mesh_;
}

void ModelObject::SetMesh(std::shared_ptr<Graphics::TriangleMesh> mesh) {
  mesh_ = mesh;
}

const AxisAlignedBox& ModelObject::GetBoundingBox() const {
  return bounding_box_;
}

std::shared_ptr<Graphics::Material> ModelObject::GetMaterial() {
  return material_;
}

void ModelObject::SetMaterial(std::shared_ptr<Graphics::Material> material) {
  material_ = material;
}

};  // namespace Objects

};  // namespace Jumpman
