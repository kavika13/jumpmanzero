#include <glm/gtc/matrix_transform.hpp>
#include "projectioncamera.hpp"

namespace Jumpman {

namespace Graphics {

ProjectionCamera::ProjectionCamera() noexcept
    : field_of_view_in_radians_(static_cast<float>(M_PI) / 4.0f)
    , aspect_ratio_(4.0f / 3.0f)
    , near_clip_plane_distance_(0.1f)
    , far_clip_plane_distance_(300.0f)
    , projection_matrix_()
    , is_projection_matrix_dirty_(true) {
  RecalculateProjectionMatrix();
}

void ProjectionCamera::SetFieldOfView(float radians) noexcept {
  field_of_view_in_radians_ = radians;
  is_projection_matrix_dirty_ = true;
}

float ProjectionCamera::GetFieldOfView() const noexcept {
  return field_of_view_in_radians_;
}

void ProjectionCamera::SetAspectRatio(float value) noexcept {
  aspect_ratio_ = value;
  is_projection_matrix_dirty_ = true;
}

float ProjectionCamera::GetAspectRatio() const noexcept {
  return aspect_ratio_;
}

void ProjectionCamera::SetNearClipPlaneDistance(float value) noexcept {
  near_clip_plane_distance_ = value;
  is_projection_matrix_dirty_ = true;
}

float ProjectionCamera::GetNearClipPlaneDistance() const noexcept {
  return near_clip_plane_distance_;
}

void ProjectionCamera::SetFarClipPlaneDistance(float value) noexcept {
  far_clip_plane_distance_ = value;
  is_projection_matrix_dirty_ = true;
}

float ProjectionCamera::GetFarClipPlaneDistance() const noexcept {
  return far_clip_plane_distance_;
}

const glm::mat4& ProjectionCamera::GetProjectionMatrix() {
  if (is_projection_matrix_dirty_) {
    RecalculateProjectionMatrix();
  }

  return projection_matrix_;
}

const glm::mat4& ProjectionCamera::GetCameraToWorldMatrix() {
  return transform.GetLocalToWorldMatrix();
}

const glm::mat4& ProjectionCamera::GetWorldToCameraMatrix() {
  return transform.GetWorldToLocalMatrix();
}

void ProjectionCamera::RecalculateProjectionMatrix() {
  projection_matrix_ = glm::perspective(
    field_of_view_in_radians_,
    aspect_ratio_,
    near_clip_plane_distance_,
    far_clip_plane_distance_);
  is_projection_matrix_dirty_ = false;
}

};  // namespace Graphics

};  // namespace Jumpman
