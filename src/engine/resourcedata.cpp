#include "resourcedata.hpp"

namespace Jumpman {

bool operator==(const ScriptResourceData& lhs, const ScriptResourceData& rhs) {
  return lhs.filename == rhs.filename && lhs.tag == rhs.tag;
}

std::ostream& operator<<(std::ostream& stream, const ScriptResourceData& val) {
  stream << "filename: " << val.filename << " - tag: " << val.tag;
  return stream;
}

bool operator==(
    const TextureResourceData& lhs, const TextureResourceData& rhs) {
  return lhs.filename == rhs.filename
    && lhs.tag == rhs.tag
    && lhs.has_colorkey_alpha == rhs.has_colorkey_alpha
    && lhs.has_alpha_channel == rhs.has_alpha_channel;
}

std::ostream& operator<<(std::ostream& stream, const TextureResourceData& val) {
  stream << "filename: " << val.filename
    << " - tag: " << val.tag
    << " - has_colorkey_alpha: " << val.has_colorkey_alpha
    << " - has_alpha_channel: " << val.has_alpha_channel;
  return stream;
}

bool operator==(
    const MaterialResourceData& lhs,
    const MaterialResourceData& rhs) {
  return lhs.vertex_shader_filename == rhs.vertex_shader_filename
    && lhs.fragment_shader_filename == rhs.fragment_shader_filename
    && lhs.tag == rhs.tag
    && lhs.texture_tag == rhs.texture_tag;
}

std::ostream& operator<<(
    std::ostream& stream,
    const MaterialResourceData& val) {
  stream << "vertex_shader_filename: " << val.vertex_shader_filename
    << " - fragment_shader_filename: " << val.fragment_shader_filename
    << " - tag: " << val.tag
    << " - texture_tag: " << val.texture_tag;
  return stream;
}

bool operator==(const MeshResourceData& lhs, const MeshResourceData& rhs) {
  return lhs.filename == rhs.filename
    && lhs.tag == rhs.tag;
}

std::ostream& operator<<(std::ostream& stream, const MeshResourceData& val) {
  stream << "filename: " << val.filename
    << " - tag: " << val.tag;
  return stream;
}

bool operator==(const MusicResourceData& lhs, const MusicResourceData& rhs) {
  return lhs.filename == rhs.filename
    && lhs.tag == rhs.tag
    && lhs.intro_end_offset_ms == rhs.intro_end_offset_ms;
}

std::ostream& operator<<(std::ostream& stream, const MusicResourceData& val) {
  stream
    << "filename: " << val.filename
    << " - tag: " << val.tag
    << " - intro_end_offset_ms: " << val.intro_end_offset_ms;
  return stream;
}

bool operator==(const SoundResourceData& lhs, const SoundResourceData& rhs) {
  return lhs.filename == rhs.filename && lhs.tag == rhs.tag;
}

std::ostream& operator<<(std::ostream& stream, const SoundResourceData& val) {
  stream << "filename: " << val.filename << " - tag: " << val.tag;
  return stream;
}

bool operator==(const VertexData& lhs, const VertexData& rhs) {
    return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
      && lhs.tu == rhs.tu && lhs.tv == rhs.tv;
}

std::ostream& operator<<(std::ostream& stream, const VertexData& val) {
  stream << "x: " << val.x << " - y: " << val.y << " - z: " << val.z
    << " - tu: " << val.tu << " - tv: " << val.tv;
  return stream;
}

bool operator==(const QuadObjectData& lhs, const QuadObjectData& rhs) {
  return lhs.tag == rhs.tag
    && lhs.material_tag == rhs.material_tag
    && lhs.origin_x == rhs.origin_x
    && lhs.origin_y == rhs.origin_y
    && lhs.origin_z == rhs.origin_z
    && lhs.vertices[0] == rhs.vertices[0]
    && lhs.vertices[1] == rhs.vertices[1]
    && lhs.vertices[2] == rhs.vertices[2]
    && lhs.vertices[3] == rhs.vertices[3];
}

std::ostream& operator<<(std::ostream& stream, const QuadObjectData& val) {
  stream << "tag: " << val.tag
    << " - material_tag: " << val.material_tag
    << " - origin_x: " << val.origin_x
    << " - origin_y: " << val.origin_y
    << " - origin_z: " << val.origin_z
    << " - vertices[0]: " << val.vertices[0]
    << " - vertices[1]: " << val.vertices[1]
    << " - vertices[2]: " << val.vertices[2]
    << " - vertices[3]: " << val.vertices[3];
  return stream;
}

};  // namespace Jumpman
