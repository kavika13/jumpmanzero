#ifndef ENGINE_SCENE_HPP_
#define ENGINE_SCENE_HPP_

#include <memory>
#include <vector>
#define GLM_FORCE_LEFT_HANDED
#include <glm/mat4x4.hpp>
#include "material.hpp"
#include "transform.hpp"
#include "trianglemesh.hpp"

struct MeshComponent {
  // TODO: shared_ptr?
  std::shared_ptr<TriangleMesh> mesh;
  std::shared_ptr<Material> material;
  // TODO: Make into a good class
};

struct SceneObject {
  Transform transform;
  std::shared_ptr<MeshComponent> mesh_component;
};

struct Camera {  // TODO: Make into a good class
  glm::mat4 projection_matrix;
  Transform transform;
};

struct Scene {
  void Draw(double time_since_last_frame);

  Camera camera;  // TODO: Support multiple cameras, one active
  std::vector<std::shared_ptr<SceneObject>> objects;
};

#endif  // ENGINE_SCENE_HPP_
