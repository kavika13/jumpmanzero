#ifndef ENGINE_AXISALIGNEDBOX_HPP_
#define ENGINE_AXISALIGNEDBOX_HPP_

#include <vector>
#define GLM_FORCE_LEFT_HANDED
#include <glm/vec3.hpp>
#include "engine/graphics/transform.hpp"

namespace Jumpman {

class AxisAlignedBox {
 public:
  static AxisAlignedBox FromExtents(
    const glm::vec3& min, const glm::vec3& max) noexcept;
  static AxisAlignedBox FromOrigin(
    const glm::vec3& origin, const glm::vec3& half_dimensions) noexcept;
  static AxisAlignedBox FromPoints(
    std::initializer_list<glm::vec3> points) noexcept;
  static AxisAlignedBox FromBoxes(
    std::initializer_list<AxisAlignedBox> boxes) noexcept;
  static AxisAlignedBox FromBoxes(
    const std::vector<AxisAlignedBox>& boxes) noexcept;

  template<typename TVertex>
  static AxisAlignedBox FromPoints(
      const std::vector<TVertex>& points) noexcept {
    glm::vec3 min, max;

    // TODO: Fancier way to do this?
    if (!points.empty()) {
      min.x = max.x = points[0].x;
      min.y = max.y = points[0].y;
      min.z = max.z = points[0].z;
    }

    for (const TVertex& point: points) {
      min.x = std::min(min.x, point.x);
      min.y = std::min(min.y, point.y);
      min.z = std::min(min.z, point.z);
      max.x = std::max(max.x, point.x);
      max.y = std::max(max.y, point.y);
      max.z = std::max(max.z, point.z);
    }

    return { min, max };
  }

  bool IsValid() const noexcept;

  glm::vec3 GetOrigin() const noexcept;
  void SetOrigin(const glm::vec3& origin) noexcept;

  glm::vec3 GetHalfDimensions() const noexcept;
  void SetHalfDimensions(const glm::vec3& half_dimensions) noexcept;

  glm::vec3 GetDimensions() const noexcept;
  void SetDimensions(const glm::vec3& dimensions) noexcept;

  const float GetVolume() const noexcept;

  AxisAlignedBox& Merge(const glm::vec3& point);
  AxisAlignedBox& Merge(const AxisAlignedBox& other);

  bool IsIntersecting(const AxisAlignedBox& other) const noexcept;
  bool IsIntersectingXY(const AxisAlignedBox& other) const noexcept;

  bool Contains(const glm::vec3& point) const noexcept;
  bool Contains(const AxisAlignedBox& other) const noexcept;
  bool ContainsXY(const glm::vec3& point) const noexcept;
  bool ContainsXY(const AxisAlignedBox& other) const noexcept;

  glm::vec3 GetClosestPointTo(const glm::vec3& point) const noexcept;

  AxisAlignedBox GetOverlap(const AxisAlignedBox& other) const noexcept;

  AxisAlignedBox Transform(Graphics::Transform& transform) const noexcept;

  glm::vec3 min;
  glm::vec3 max;
};

};  // namespace Jumpman

#endif  // ENGINE_AXISALIGNEDBOX_HPP_
