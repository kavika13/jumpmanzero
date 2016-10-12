#include "scene.hpp"

void Scene::Draw(double time_since_last_frame) {
  glm::mat4 vp_matrix = camera.projection_matrix
    * camera.transform.GetWorldToLocalMatrix();

  std::shared_ptr<Material> previous_material;

  for (auto& scene_object: objects) {
    // TODO: Push this logic into mesh component
    // TODO: Handle matrix stack
    auto& mesh_component = scene_object->mesh_component;

    if (mesh_component) {
      // TODO: Handle enable/diable alpha blend depending on texture data
      auto current_material = mesh_component->material.lock();

      // TODO: Move to mesh component/material
      if (current_material != previous_material) {
        previous_material = current_material;
        current_material->SetActive();
        current_material->BindTexture(0);
      }

      // TODO: Move to mesh component/material
      glm::mat4 mvp_matrix = vp_matrix
        * scene_object->transform.GetLocalToWorldMatrix();
      current_material->BindMvpMatrix(mvp_matrix);

      // TODO: Move to mesh component
      auto mesh = mesh_component->mesh.lock();
      mesh->Draw();
    }
  }
}
