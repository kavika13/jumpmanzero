#ifndef ENGINE_RESOURCEDATA_HPP_
#define ENGINE_RESOURCEDATA_HPP_

#include <array>
#include <cstdint>
#include <ostream>
#include <string>
#include <vector>

namespace Jumpman {

struct ScriptResourceData {
  const std::string filename;
  const std::string tag;
};

bool operator==(const ScriptResourceData& lhs, const ScriptResourceData& rhs);
std::ostream& operator<<(std::ostream& stream, const ScriptResourceData& val);

struct TextureResourceData {
  const std::string filename;
  const std::string tag;
  const bool has_colorkey_alpha;
  const bool has_alpha_channel;
};

bool operator==(const TextureResourceData& lhs, const TextureResourceData& rhs);
std::ostream& operator<<(std::ostream& stream, const TextureResourceData& val);

struct MaterialResourceData {
  const std::string vertex_shader_filename;
  const std::string fragment_shader_filename;
  const std::string tag;
  const std::string texture_tag;
};

bool operator==(const MaterialResourceData&, const MaterialResourceData&);
std::ostream& operator<<(std::ostream& stream, const MaterialResourceData& val);

struct MeshResourceData {
  const std::string filename;
  const std::string tag;
};

bool operator==(const MeshResourceData& lhs, const MeshResourceData& rhs);
std::ostream& operator<<(std::ostream& stream, const MeshResourceData& val);

struct MusicResourceData {
  const std::string filename;
  const std::string tag;
  const uint32_t intro_end_offset_ms;
};

bool operator==(const MusicResourceData& lhs, const MusicResourceData& rhs);
std::ostream& operator<<(std::ostream& stream, const MusicResourceData& val);

struct SoundResourceData {
  const std::string filename;
  const std::string tag;
};

bool operator==(const SoundResourceData& lhs, const SoundResourceData& rhs);
std::ostream& operator<<(std::ostream& stream, const SoundResourceData& val);

struct VertexData {
  const float x, y, z;
  const float tu, tv;
};

bool operator==(const VertexData& lhs, const VertexData& rhs);
std::ostream& operator<<(std::ostream& stream, const VertexData& val);

struct QuadObjectData {
  const std::string tag;
  const std::string material_tag;
  const float origin_x, origin_y, origin_z;
  const std::array<VertexData, 4> vertices;
};

bool operator==(const QuadObjectData& lhs, const QuadObjectData& rhs);
std::ostream& operator<<(std::ostream& stream, const QuadObjectData& val);

struct ResourceData {
  const std::string main_script_tag;
  const std::string main_script_filename;
  const std::string background_track_tag;

  const std::vector<ScriptResourceData> scripts;
  const std::vector<TextureResourceData> textures;
  const std::vector<MaterialResourceData> materials;
  const std::vector<MeshResourceData> meshes;
  const std::vector<MusicResourceData> music;
  const std::vector<SoundResourceData> sounds;

  const std::vector<QuadObjectData> quads;
};

};  // namespace Jumpman

#endif  // ENGINE_RESOURCEDATA_HPP_
