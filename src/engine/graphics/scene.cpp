#include <stack>
#define GL3_PROTOTYPES
#include <OpenGL/gl3.h>
#include "scene.hpp"

namespace Jumpman {

namespace Graphics {

void MeshComponent::Draw(
    const glm::mat4& wvp_matrix,
    Transform& transform,
    const Material* previous_material,
    bool is_transparent_pass) {
  if (!material || !mesh) {
    return;
  }

  if (is_transparent_pass
      && !material->GetTexture()->GetIsAlphaBlendingEnabled()) {
    return;
  }

  material->Activate(previous_material, is_transparent_pass);

  glm::mat4 transpose_world_to_local_matrix = glm::transpose(
    transform.GetWorldToLocalMatrix());
  material->BindTransformMatrices(
    wvp_matrix,
    transform.GetLocalToWorldMatrix(),
    transpose_world_to_local_matrix);

  mesh->Draw();
}

void Scene::Draw(double time_since_last_frame) {
  std::stack<glm::mat4> matrix_stack({
    camera.GetProjectionMatrix() * camera.GetWorldToCameraMatrix()
  });
  Material* previous_material = nullptr;
  bool is_transparent_pass = false;

  std::function<void(const std::shared_ptr<SceneObject>&)> render_scene_object =
    [
      &render_scene_object,
      &matrix_stack,
      &previous_material,
      &is_transparent_pass](
        const std::shared_ptr<SceneObject>& scene_object) {

    glm::mat4 current_matrix = matrix_stack.top()
      * scene_object->transform.GetLocalToWorldMatrix();

    auto& mesh_component = scene_object->mesh_component;

    if (scene_object->is_enabled) {
      if (mesh_component) {
        mesh_component->Draw(
          current_matrix,
          scene_object->transform,
          previous_material,
          is_transparent_pass);
        previous_material = mesh_component->material.get();
      }

      matrix_stack.push(current_matrix);

      for (auto& child_scene_object: scene_object->children) {
        render_scene_object(child_scene_object);
      }

      matrix_stack.pop();
    }
  };

  glDepthMask(GL_TRUE);

  for (auto& scene_object: objects) {
    render_scene_object(scene_object);
  }

  glDepthMask(GL_FALSE);

  is_transparent_pass = true;

  for (auto& scene_object: objects) {
    render_scene_object(scene_object);
  }

  glDepthMask(GL_TRUE);
}

};  // namespace Graphics

};  // namespace Jumpman
