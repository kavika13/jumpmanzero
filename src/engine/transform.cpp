#define GLM_FORCE_LEFT_HANDED
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtx/matrix_decompose.hpp>
#include <glm/gtx/quaternion.hpp>
#include <glm/gtx/transform.hpp>
#include "transform.hpp"

Transform::Transform()
  : scale_(1.0f),
    orientation_(),
    translation_(),
    local_to_world_matrix_(),
    world_to_local_matrix_(),
    are_matrices_dirty_(false) {
}

void Transform::Reset() {
  scale_ = glm::vec3(1.0f);
  orientation_ = glm::quat();
  translation_ = glm::vec3();

  local_to_world_matrix_ = glm::mat4();
  world_to_local_matrix_ = glm::mat4();
  are_matrices_dirty_ = false;
}

void Transform::SetScale(const glm::vec3& value) {
  scale_ = value;
  are_matrices_dirty_ = true;
}

void Transform::SetScale(float x, float y, float z) {
  scale_ = glm::vec3(x, y, z);
  are_matrices_dirty_ = true;
}

const glm::vec3& Transform::GetScale() const {
  return scale_;
}

void Transform::SetOrientation(const glm::quat& value) {
  orientation_ = value;
  are_matrices_dirty_ = true;
}

void Transform::SetAngleAxisRotation(float radians, const glm::vec3& axis) {
  orientation_ = glm::angleAxis(radians, axis);
  are_matrices_dirty_ = true;
}

void Transform::RotateOnAngleAxis(float radians, const glm::vec3& axis) {
  orientation_ *= glm::angleAxis(radians, axis);
  are_matrices_dirty_ = true;
}

const glm::quat& Transform::GetOrientation() const {
  return orientation_;
}

void Transform::SetTranslation(const glm::vec3& value) {
  translation_ = value;
  are_matrices_dirty_ = true;
}

void Transform::SetTranslation(float x, float y, float z) {
  translation_ = glm::vec3(x, y, z);
  are_matrices_dirty_ = true;
}

void Transform::Translate(const glm::vec3& value) {
  translation_ += value;
  are_matrices_dirty_ = true;
}

void Transform::Translate(float x, float y, float z) {
  translation_ += glm::vec3(x, y, z);
  are_matrices_dirty_ = true;
}

const glm::vec3& Transform::GetTranslation() const {
  return translation_;
}

void Transform::LookAt(const glm::vec3& point_of_interest) {
  orientation_ = glm::rotation(
    glm::vec3(0.0f, 0.0f, 1.0f),
    glm::normalize(point_of_interest - translation_));
  are_matrices_dirty_ = true;
}

void Transform::LookAt(float poi_x, float poi_y, float poi_z) {
  LookAt(glm::vec3(poi_x, poi_y, poi_z));
}

const glm::mat4& Transform::GetLocalToWorldMatrix() {
  if (are_matrices_dirty_) {
    RecalculateMatrices();
  }

  return local_to_world_matrix_;
}

const glm::mat4& Transform::GetWorldToLocalMatrix() {
  if (are_matrices_dirty_) {
    RecalculateMatrices();
  }

  return world_to_local_matrix_;
}

void Transform::RecalculateMatrices() {
  local_to_world_matrix_ = glm::translate(translation_)
    * glm::mat4_cast(orientation_)
    * glm::scale(scale_);
  world_to_local_matrix_ = glm::inverse(local_to_world_matrix_);
  are_matrices_dirty_ = false;
}
