#include <stack>
#include "scene.hpp"

void MeshComponent::Draw(
    const glm::mat4& current_matrix, const Material* previous_material) {
  material->Activate(previous_material);
  material->BindMvpMatrix(current_matrix);
  mesh->Draw();
}

void Scene::Draw(double time_since_last_frame) {
  std::stack<glm::mat4> matrix_stack({
    camera.projection_matrix * camera.transform.GetWorldToLocalMatrix()
  });
  Material* previous_material = nullptr;

  std::function<void(const std::shared_ptr<SceneObject>&)> render_scene_object =
    [&render_scene_object, &matrix_stack, &previous_material](
      const std::shared_ptr<SceneObject>& scene_object) {

    glm::mat4 current_matrix = matrix_stack.top()
      * scene_object->transform.GetLocalToWorldMatrix();

    auto& mesh_component = scene_object->mesh_component;

    if (mesh_component) {
      mesh_component->Draw(current_matrix, previous_material);
      previous_material = mesh_component->material.get();
    }

    matrix_stack.push(current_matrix);

    for (auto& child_scene_object: scene_object->children) {
      render_scene_object(child_scene_object);
    }

    matrix_stack.pop();
  };

  for (auto& scene_object: objects) {
    render_scene_object(scene_object);
  }
}
