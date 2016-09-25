#ifndef ENGINE_LEVELDATA_HPP_
#define ENGINE_LEVELDATA_HPP_

#include <array>
#include <cstdint>
#include <istream>
#include <string>
#include <vector>

struct ScriptResourceData {
  const std::string filename;
  const std::string tag;
};

bool operator==(const ScriptResourceData& lhs, const ScriptResourceData& rhs);
std::ostream& operator<<(std::ostream& stream, const ScriptResourceData& val);

struct MeshResourceData {
  const std::string filename;
  const std::string tag;
};

bool operator==(const MeshResourceData& lhs, const MeshResourceData& rhs);
std::ostream& operator<<(std::ostream& stream, const MeshResourceData& val);

struct TextureResourceData {
  const std::string filename;
  const std::string tag;
  const bool has_colorkey_alpha;
  const bool has_alpha_channel;
};

bool operator==(const TextureResourceData& lhs, const TextureResourceData& rhs);
std::ostream& operator<<(std::ostream& stream, const TextureResourceData& val);

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
  const std::string texture_tag;
  const float origin_x, origin_y;
  const std::array<VertexData, 4> vertices;
};

bool operator==(const QuadObjectData& lhs, const QuadObjectData& rhs);
std::ostream& operator<<(std::ostream& stream, const QuadObjectData& val);

struct DonutObjectData {
  const std::string tag;
  const std::string texture_tag;
  const float origin_x, origin_y, origin_z;
};

bool operator==(const DonutObjectData& lhs, const DonutObjectData& rhs);
std::ostream& operator<<(std::ostream& stream, const DonutObjectData& val);

enum class PlatformType {
  // TODO: Are these values right for left/right?
  kPlain = 0,
  kSlideLeft = 1,
  kSlideRight = 2,
  kHang = 3,
};

struct PlatformObjectData {
  const std::string tag;
  const std::string texture_tag;
  bool drawtop, drawbottom, drawfront, drawback, drawleft, drawright;
  const PlatformType platform_type;
  // TODO: Do we need end_x, end_y?
  const float start_x, start_y, end_x, end_y, front_z;  // TODO: Better names?
  const std::array<VertexData, 4> vertices;
};

bool operator==(const PlatformObjectData& lhs, const PlatformObjectData& rhs);
std::ostream& operator<<(std::ostream& stream, const PlatformObjectData& val);

// struct WallObjectData {
//   const std::string tag;
//   const std::string texture_tag;
//   const std::array<VertexData, 4> vertices;
//   const float x1, y1, x2, y2, x3, y3, x4, y4;  // TODO: Better type? Don't need?
//   // TODO: Add fields, but only base data, not triangles/squares
// };

struct LadderObjectData {
  const std::string tag;
  const std::string texture_tag;
  const float origin_x, top_y, bottom_y, front_z;
};

bool operator==(const LadderObjectData& lhs, const LadderObjectData& rhs);
std::ostream& operator<<(std::ostream& stream, const LadderObjectData& val);

// struct VineObjectData {
//   const std::string tag;
//   const std::string texture_tag;
//   const float x1, y1, y2, z1, z2;  // TODO: Better type? Don't need?
//   // TODO: Add fields, but only base data, not triangles/squares
// };

struct LevelData {
  static LevelData FromStream(std::istream& stream);

  friend std::ostream& operator<<(std::ostream& stream, const LevelData& data);

  const std::string main_script_tag;
  const std::string donut_script_tag;
  const std::string background_track_tag;
  const std::string death_track_tag;
  const std::string end_level_track_tag;

  const std::vector<ScriptResourceData> scripts;
  const std::vector<MeshResourceData> meshes;
  const std::vector<TextureResourceData> textures;
  const std::vector<MusicResourceData> music;
  const std::vector<SoundResourceData> sounds;

  const std::vector<QuadObjectData> quads;
  const std::vector<DonutObjectData> donuts;
  const std::vector<PlatformObjectData> platforms;
  // const std::vector<WallObjectData> walls;
  const std::vector<LadderObjectData> ladders;
  // const std::vector<VineObjectData> vines;
};

#endif  // ENGINE_LEVELDATA_HPP_
