#include <algorithm>
#define GLM_FORCE_LEFT_HANDED
#include <glm/common.hpp>
#include <glm/gtc/constants.hpp>
#include "axisalignedbox.hpp"

namespace Jumpman {

AxisAlignedBox AxisAlignedBox::FromExtents(
    const glm::vec3& min, const glm::vec3& max) noexcept {
  return { min, max };
}

AxisAlignedBox AxisAlignedBox::FromOrigin(
    const glm::vec3& origin, const glm::vec3& half_dimensions) noexcept {
  return {
    origin - half_dimensions,
    origin + half_dimensions,
  };
}

AxisAlignedBox AxisAlignedBox::FromPoints(
    std::initializer_list<glm::vec3> points) noexcept {
  glm::vec3 min, max;

  // TODO: Fancier way to do this?
  if (points.size() > 0) {
    auto& first_point = *points.begin();
    min.x = max.x = first_point.x;
    min.y = max.y = first_point.y;
    min.z = max.z = first_point.z;
  }

  for (const glm::vec3& point: points) {
    min.x = std::min(min.x, point.x);
    min.y = std::min(min.y, point.y);
    min.z = std::min(min.z, point.z);
    max.x = std::max(max.x, point.x);
    max.y = std::max(max.y, point.y);
    max.z = std::max(max.z, point.z);
  }

  return { min, max };
}

template<typename TContainer>
static AxisAlignedBox CreateFromBoxes(TContainer boxes) noexcept {
  glm::vec3 min, max;

  // TODO: Fancier way to do this?
  if (boxes.size() > 0) {
    auto& first_box = *boxes.begin();
    min.x = max.x = first_box.min.x;
    min.y = max.y = first_box.min.y;
    min.z = max.z = first_box.min.z;
  }

  for (const AxisAlignedBox& box: boxes) {
    min.x = std::min(min.x, box.min.x);
    min.y = std::min(min.y, box.min.y);
    min.z = std::min(min.z, box.min.z);
    max.x = std::max(max.x, box.min.x);
    max.y = std::max(max.y, box.min.y);
    max.z = std::max(max.z, box.min.z);
    min.x = std::min(min.x, box.max.x);
    min.y = std::min(min.y, box.max.y);
    min.z = std::min(min.z, box.max.z);
    max.x = std::max(max.x, box.max.x);
    max.y = std::max(max.y, box.max.y);
    max.z = std::max(max.z, box.max.z);
  }

  return { min, max };
}

AxisAlignedBox AxisAlignedBox::FromBoxes(
    std::initializer_list<AxisAlignedBox> boxes) noexcept {
  return CreateFromBoxes(boxes);
}

AxisAlignedBox AxisAlignedBox::FromBoxes(
    const std::vector<AxisAlignedBox>& boxes) noexcept {
  return CreateFromBoxes(boxes);
}

glm::vec3 AxisAlignedBox::GetOrigin() const noexcept {
  return min + (max - min) / 2.0f;
}

void AxisAlignedBox::SetOrigin(const glm::vec3& origin) noexcept {
  glm::vec3 half_dimensions = (max - min) / 2.0f;
  min = origin - half_dimensions;
  max = origin + half_dimensions;
}

glm::vec3 AxisAlignedBox::GetHalfDimensions() const noexcept {
  return (max - min) / 2.0f;
}

void AxisAlignedBox::SetHalfDimensions(
    const glm::vec3& half_dimensions) noexcept {
  glm::vec3 origin = min + (max - min) / 2.0f;
  min = origin - half_dimensions;
  max = origin + half_dimensions;
}

glm::vec3 AxisAlignedBox::GetDimensions() const noexcept {
  return max - min;
}

void AxisAlignedBox::SetDimensions(const glm::vec3& dimensions) noexcept {
  glm::vec3 origin = min + (max - min) / 2.0f;
  glm::vec3 half_dimensions = dimensions / 2.0f;
  min = origin - half_dimensions;
  max = origin + half_dimensions;
}

const float AxisAlignedBox::GetVolume() const noexcept {
  glm::vec3 dimensions = max - min;
  return dimensions.x * dimensions.y * dimensions.z;
}

AxisAlignedBox& AxisAlignedBox::Merge(const glm::vec3& point) {
  return *this = AxisAlignedBox::FromPoints({ min, max, point });
}

AxisAlignedBox& AxisAlignedBox::Merge(const AxisAlignedBox& other) {
  return *this = AxisAlignedBox::FromPoints({ min, max, other.min, other.max });
}

bool AxisAlignedBox::IsIntersecting(
    const AxisAlignedBox& other) const noexcept {
  return glm::all(
    glm::lessThan(
      glm::abs(min - other.min) * 2.0f,
      max - min + other.max - other.min));
}

bool AxisAlignedBox::IsIntersectingXY(
    const AxisAlignedBox& other) const noexcept {
  return glm::all(
    glm::lessThan(
      glm::abs(glm::vec2(min) - glm::vec2(other.min)) * 2.0f,
      glm::vec2(max) - glm::vec2(min)
        + glm::vec2(other.max) - glm::vec2(other.min)));
}

bool AxisAlignedBox::Contains(const glm::vec3& point) const noexcept {
  const glm::vec3& zero = glm::zero<glm::vec3>();
  return glm::all(glm::lessThan(min - point, zero))
    && glm::all(glm::greaterThan(max - point, zero));
}

bool AxisAlignedBox::Contains(const AxisAlignedBox& other) const noexcept {
  return glm::all(glm::lessThanEqual(min, other.min))
    && glm::all(glm::greaterThanEqual(max, other.max));
}

bool AxisAlignedBox::ContainsXY(const glm::vec3& point) const noexcept {
  const glm::vec2& zero = glm::zero<glm::vec2>();
  return glm::all(glm::lessThan(glm::vec2(min) - glm::vec2(point), zero))
    && glm::all(glm::greaterThan(glm::vec2(max) - glm::vec2(point), zero));
}

bool AxisAlignedBox::ContainsXY(const AxisAlignedBox& other) const noexcept {
  return glm::all(glm::lessThanEqual(glm::vec2(min), glm::vec2(other.min)))
    && glm::all(glm::greaterThanEqual(glm::vec2(max), glm::vec2(other.max)));
}

glm::vec3 AxisAlignedBox::GetClosestPointTo(
    const glm::vec3& point) const noexcept {
  glm::vec3 result;
  result.x = std::min(min.x, point.x);
  result.x = std::max(max.x, point.x);
  result.y = std::min(min.y, point.y);
  result.y = std::max(max.y, point.y);
  result.z = std::min(min.z, point.z);
  result.z = std::max(max.z, point.z);
  return result;
}

AxisAlignedBox AxisAlignedBox::GetOverlap(
    const AxisAlignedBox& other) const noexcept {
  return {
    glm::max(min, other.min),
    glm::min(max, other.max),
  };
}

};  // namespace Jumpman
