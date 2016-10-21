#include <stack>
#include "scene.hpp"

void MeshComponent::Draw(
    const glm::mat4& wvp_matrix,
    Jumpman::Graphics::Transform& transform,
    const Material* previous_material) {
  if (!material || !mesh) {
    return;
  }

  material->Activate(previous_material);

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

  std::function<void(const std::shared_ptr<SceneObject>&)> render_scene_object =
    [&render_scene_object, &matrix_stack, &previous_material](
      const std::shared_ptr<SceneObject>& scene_object) {

    glm::mat4 current_matrix = matrix_stack.top()
      * scene_object->transform.GetLocalToWorldMatrix();

    auto& mesh_component = scene_object->mesh_component;

    if (mesh_component && mesh_component->is_visible) {
      mesh_component->Draw(
        current_matrix, scene_object->transform, previous_material);
      previous_material = mesh_component->material.get();
    }

    // TODO: Should is_visible be on a scene object instead?
    if (!mesh_component || (mesh_component && mesh_component->is_visible)) {
      matrix_stack.push(current_matrix);

      for (auto& child_scene_object: scene_object->children) {
        render_scene_object(child_scene_object);
      }

      matrix_stack.pop();
    }
  };

  for (auto& scene_object: objects) {
    render_scene_object(scene_object);
  }
}
