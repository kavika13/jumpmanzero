#ifndef ENGINE_GRAPHICS_SCENE_HPP_
#define ENGINE_GRAPHICS_SCENE_HPP_

#include <memory>
#include <vector>
#define GLM_FORCE_LEFT_HANDED
#include <glm/mat4x4.hpp>
#include "material.hpp"
#include "projectioncamera.hpp"
#include "transform.hpp"
#include "trianglemesh.hpp"

namespace Jumpman {

namespace Graphics {

struct MeshComponent {
  void Draw(
    const glm::mat4& wvp_matrix,
    Transform& tranform,
    const Material* previous_material,
    bool is_transparent_pass);

  std::shared_ptr<TriangleMesh> mesh;
  std::shared_ptr<Material> material;
};

struct SceneObject {
  bool is_enabled = true;
  Transform transform;
  std::shared_ptr<MeshComponent> mesh_component;
  std::vector<std::shared_ptr<SceneObject>> children;
};

struct Scene {
  void Draw(double time_since_last_frame);

  // TODO: Support multiple cameras, one active
  ProjectionCamera camera;
  std::vector<std::shared_ptr<SceneObject>> objects;
};

};  // namespace Graphics

};  // namespace Jumpman

#endif  // ENGINE_GRAPHICS_SCENE_HPP_
