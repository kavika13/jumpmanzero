#ifndef ENGINE_GRAPHICS_PROJECTIONCAMERA_HPP_
#define ENGINE_GRAPHICS_PROJECTIONCAMERA_HPP_

#include <ostream>
#define GLM_FORCE_LEFT_HANDED
#include <glm/mat4x4.hpp>
#include "transform.hpp"

namespace Jumpman {

namespace Graphics {

class ProjectionCamera {
 public:
  ProjectionCamera() noexcept;

  void SetFieldOfView(float radians) noexcept;
  float GetFieldOfView() const noexcept;

  void SetAspectRatio(float aspect_ratio) noexcept;
  float GetAspectRatio() const noexcept;

  void SetNearClipPlaneDistance(float distance) noexcept;
  float GetNearClipPlaneDistance() const noexcept;

  void SetFarClipPlaneDistance(float distance) noexcept;
  float GetFarClipPlaneDistance() const noexcept;

  const glm::mat4& GetProjectionMatrix();
  const glm::mat4& GetCameraToWorldMatrix();
  const glm::mat4& GetWorldToCameraMatrix();

  Transform transform;

  friend std::ostream& operator<<(std::ostream&, const ProjectionCamera&);

 private:
  void RecalculateProjectionMatrix();

  float field_of_view_in_radians_;
  float aspect_ratio_;
  float near_clip_plane_distance_;
  float far_clip_plane_distance_;

  glm::mat4 projection_matrix_;
  bool is_projection_matrix_dirty_;
};

};  // namespace Graphics

};  // namespace Jumpman

#endif  // ENGINE_GRAPHICS_PROJECTIONCAMERA_HPP_
