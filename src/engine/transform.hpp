#ifndef ENGINE_TRANSFORM_HPP_
#define ENGINE_TRANSFORM_HPP_

#include <glm/mat4x4.hpp>
#include <glm/gtc/quaternion.hpp>

class Transform {
 public:
  Transform();

  void Reset();

  void SetScale(const glm::vec3& value);
  void SetScale(float x, float y, float z);
  const glm::vec3& GetScale() const;

  void SetOrientation(const glm::quat& value);
  void SetAngleAxisRotation(float radians, const glm::vec3& axis);
  const glm::quat& GetOrientation() const;

  void SetTranslation(const glm::vec3& value);
  void SetTranslation(float x, float y, float z);
  void Translate(const glm::vec3& value);
  void Translate(float x, float y, float z);
  const glm::vec3& GetTranslation() const;

  void LookAt(const glm::vec3& point_of_interest);

  const glm::mat4& GetLocalToWorldMatrix();
  const glm::mat4& GetWorldToLocalMatrix();

 private:
  void RecalculateMatrices();

  glm::vec3 translation_;
  glm::quat orientation_;
  glm::vec3 scale_;

  glm::mat4 local_to_world_matrix_;
  glm::mat4 world_to_local_matrix_;
  bool are_matrices_dirty_;
};

#endif  // ENGINE_TRANSFORM_HPP_
