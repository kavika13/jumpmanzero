#include "meshgenerator.hpp"
#define GLM_FORCE_LEFT_HANDED
#include <glm/vec3.hpp>

namespace Jumpman {

namespace Graphics {

static Vertex AppendNormalCoord(const Vertex& vertex, const glm::vec3& normal) {
  return Vertex {
    vertex.x,
    vertex.y,
    vertex.z,
    normal.x,
    normal.y,
    normal.z,
    vertex.tu,
    vertex.tv,
  };
}

static Vertex AppendTexCoord(const Vertex& vertex, float tu, float tv) {
  return Vertex {
    vertex.x,
    vertex.y,
    vertex.z,
    vertex.nx,
    vertex.ny,
    vertex.nz,
    tu,
    tv,
  };
}

static Vertex TranslateVertexZ(const Vertex& vertex, float z) {
  return Vertex {
    vertex.x,
    vertex.y,
    vertex.z + z,
    vertex.nx,
    vertex.ny,
    vertex.nz,
    vertex.tu,
    vertex.tv,
  };
}

Vertex MeshGenerator::ConvertVertex(const VertexData& vertex) {
  return Vertex {
    vertex.x,
    vertex.y,
    vertex.z,
    0.0f,
    0.0f,
    0.0f,
    vertex.tu,
    vertex.tv,
  };
}

Vertex MeshGenerator::TranslateVertex(
    const VertexData& vertex,
    float translate_x,
    float translate_y,
    float translate_z) {
  return Vertex {
    vertex.x + translate_x,
    vertex.y + translate_y,
    vertex.z + translate_z,
    vertex.x,
    vertex.y,
    vertex.z,
    vertex.tu,
    vertex.tv,
  };
}

void MeshGenerator::AddTriangle(
    const Vertex& v0, const Vertex& v1, const Vertex& v2) {
  glm::vec3 v0pos(v0.x, v0.y, v0.z);
  glm::vec3 v1pos(v1.x, v1.y, v1.z);
  glm::vec3 v2pos(v2.x, v2.y, v2.z);
  glm::vec3 normal = glm::cross(v0pos - v1pos, v2pos - v1pos);

  vertices_.push_back(AppendNormalCoord(v0, normal));
  vertices_.push_back(AppendNormalCoord(v1, normal));
  vertices_.push_back(AppendNormalCoord(v2, normal));
}

void MeshGenerator::AddPretexturedQuad(
    const Vertex& upper_left, const Vertex& upper_right,
    const Vertex& lower_left, const Vertex& lower_right) {
  AddTriangle(upper_left, lower_left, upper_right);
  AddTriangle(upper_right, lower_left, lower_right);
}

void MeshGenerator::AddQuad(
    const Vertex& v0, const Vertex& v1, const Vertex& v2, const Vertex& v3) {
  // TODO: Normals
  const Vertex upper_left = AppendTexCoord(v0, 0.0f, 1.0f);
  const Vertex upper_right = AppendTexCoord(v1, 1.0f, 1.0f);
  const Vertex lower_left = AppendTexCoord(v2, 0.0f, 0.0f);
  const Vertex lower_right = AppendTexCoord(v3, 1.0f, 0.0f);

  AddPretexturedQuad(upper_left, upper_right, lower_left, lower_right);
}

void MeshGenerator::AddCube(
    float x_left, float y_top, float z_front,
    float x_right, float y_bottom, float z_back) {
  const Vertex left_top_front { x_left, y_top, z_front };
  const Vertex left_top_back { x_left, y_top, z_back };
  const Vertex left_bottom_front { x_left, y_bottom, z_front };
  const Vertex left_bottom_back { x_left, y_bottom, z_back };
  const Vertex right_top_front { x_right, y_top, z_front };
  const Vertex right_top_back { x_right, y_top, z_back };
  const Vertex right_bottom_front { x_right, y_bottom, z_front };
  const Vertex right_bottom_back { x_right, y_bottom, z_back };

  AddQuad(
    left_top_front, right_top_front,
    left_bottom_front, right_bottom_front);
  AddQuad(
    right_top_back, left_top_back,
    right_bottom_back, left_bottom_back);
  AddQuad(
    left_top_back, right_top_back,
    left_top_front, right_top_front);
  AddQuad(
    left_bottom_front, right_bottom_front,
    left_bottom_back, right_bottom_back);
  AddQuad(
    left_top_back, left_top_front,
    left_bottom_back, left_bottom_front);
  AddQuad(
    right_top_front, right_top_back,
    right_bottom_front, right_bottom_back);
}

void MeshGenerator::AddSkewedCube(
    bool drawtop, bool drawbottom,
    bool drawleft, bool drawright,
    bool drawfront, bool drawback,
    const Vertex& v0, const Vertex& v1, const Vertex& v2, const Vertex& v3,
    float front_z, float back_z) {
  // TODO: Reduce the math/temp variables here
  const Vertex left_top_front = TranslateVertexZ(v0, front_z);
  const Vertex left_top_back = TranslateVertexZ(v0, back_z);
  const Vertex left_bottom_front = TranslateVertexZ(v2, front_z);
  const Vertex left_bottom_back = TranslateVertexZ(v2, back_z);
  const Vertex right_top_front = TranslateVertexZ(v1, front_z);
  const Vertex right_top_back = TranslateVertexZ(v1, back_z);
  const Vertex right_bottom_front = TranslateVertexZ(v3, front_z);
  const Vertex right_bottom_back = TranslateVertexZ(v3, back_z);

  const glm::vec2 top_left_vec = glm::vec2(
    left_top_front.x, left_top_front.y);
  const glm::vec2 top_right_vec = glm::vec2(
    right_top_front.x, right_top_front.y);
  const glm::vec2 bottom_left_vec = glm::vec2(
    left_bottom_front.x, left_bottom_front.y);
  const glm::vec2 bottom_right_vec = glm::vec2(
    right_bottom_front.x, right_bottom_front.y);

  const glm::vec2 texture_direction_x = top_right_vec - top_left_vec;
  const glm::vec2 texture_normal_x = glm::normalize(texture_direction_x);
  const float length_x = glm::length(texture_direction_x);

  const float scale_tu_base = length_x / 15.0f;
  const float scale_tu_temp = round(scale_tu_base * 4.0f) / 4.0f;
  const float scale_tu = (scale_tu_temp / scale_tu_base) / 15.0f;

  const float top_right_tu = length_x * scale_tu;

  const float length_bottom_left_x = glm::dot(
    bottom_left_vec - top_left_vec, texture_normal_x);
  const float bottom_left_tu = length_bottom_left_x * scale_tu;

  const float length_bottom_right_x = glm::dot(
    bottom_right_vec - top_left_vec, texture_normal_x);
  const float bottom_right_tu = length_bottom_right_x * scale_tu;

  if (drawtop) {
    AddPretexturedQuad(
      AppendTexCoord(left_top_back, 0.0f, 0.5f),
      AppendTexCoord(right_top_back, top_right_tu, 0.5f),
      AppendTexCoord(left_top_front, 0.0f, 0.0f),
      AppendTexCoord(right_top_front, top_right_tu, 0.0f));
  }

  if (drawbottom) {
    AddPretexturedQuad(
      AppendTexCoord(left_bottom_front, 0.0f, 0.5f),
      AppendTexCoord(right_bottom_front, top_right_tu, 0.5f),
      AppendTexCoord(left_bottom_back, 0.0f, 0.0f),
      AppendTexCoord(right_bottom_back, top_right_tu, 0.0f));
  }

  if (drawleft) {
    AddPretexturedQuad(
      // TODO: Project texture with vertical scale?
      AppendTexCoord(left_top_back, 0.0f, 0.5f),
      AppendTexCoord(left_top_front, bottom_left_tu, 0.5f),
      AppendTexCoord(left_bottom_back, 0.0f, 0.0f),
      AppendTexCoord(left_bottom_front, bottom_left_tu, 0.0f));
  }

  if (drawright) {
    AddPretexturedQuad(
      // TODO: Project texture with vertical scale?
      AppendTexCoord(right_top_front, 0.0f, 0.5f),
      AppendTexCoord(right_top_back, bottom_right_tu, 0.5f),
      AppendTexCoord(right_bottom_front, 0.0f, 0.0f),
      AppendTexCoord(right_bottom_back, bottom_right_tu, 0.0f));
  }

  if (drawfront) {
    AddPretexturedQuad(
      AppendTexCoord(left_top_front, 0.0f, 1.0f),
      AppendTexCoord(right_top_front, top_right_tu, 1.0f),
      AppendTexCoord(left_bottom_front, bottom_left_tu, 0.5f),
      AppendTexCoord(right_bottom_front, bottom_right_tu, 0.5f));
  }

  if (drawback) {
    AddPretexturedQuad(
      AppendTexCoord(right_top_back, top_right_tu, 1.0f),
      AppendTexCoord(left_top_back, 0.0f, 1.0f),
      AppendTexCoord(right_bottom_back, bottom_right_tu, 0.5f),
      AppendTexCoord(left_bottom_back, bottom_left_tu, 0.5f));
  }
}

std::shared_ptr<TriangleMesh> MeshGenerator::CreateMesh(
    ResourceContext& resource_context, const std::string& tag) const {
  return resource_context.CreateMesh(vertices_, tag);
}

};  // namespace Jumpman

};  // namespace Graphics
