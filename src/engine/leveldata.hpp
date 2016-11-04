#ifndef ENGINE_LEVELDATA_HPP_
#define ENGINE_LEVELDATA_HPP_

#include <istream>
#include "resourcedata.hpp"

namespace Jumpman {

struct DonutObjectData {
  const std::string tag;
  const std::string material_tag;
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
  const std::string material_tag;
  bool drawtop, drawbottom, drawfront, drawback, drawleft, drawright;
  const PlatformType platform_type;
  const float front_z, back_z;
  const std::array<VertexData, 4> vertices;
};

bool operator==(const PlatformObjectData& lhs, const PlatformObjectData& rhs);
std::ostream& operator<<(std::ostream& stream, const PlatformObjectData& val);

struct WallObjectData {
  const std::string tag;
  const std::string material_tag;
  bool drawtop, drawbottom, drawfront, drawback, drawleft, drawright;
  const float front_z, back_z;
  const std::array<VertexData, 4> vertices;
};

bool operator==(const WallObjectData& lhs, const WallObjectData& rhs);
std::ostream& operator<<(std::ostream& stream, const WallObjectData& val);

struct LadderObjectData {
  const std::string tag;
  const std::string material_tag;
  const float origin_x, top_y, bottom_y, front_z;
};

bool operator==(const LadderObjectData& lhs, const LadderObjectData& rhs);
std::ostream& operator<<(std::ostream& stream, const LadderObjectData& val);

struct VineObjectData {
  const std::string tag;
  const std::string material_tag;
  const float origin_x, top_y, bottom_y, front_z;
};

bool operator==(const VineObjectData& lhs, const VineObjectData& rhs);
std::ostream& operator<<(std::ostream& stream, const VineObjectData& val);

struct LevelData {
  static LevelData FromStream(std::istream& stream);

  friend std::ostream& operator<<(std::ostream& stream, const LevelData& data);

  const std::string main_script_tag;
  const std::string main_script_filename;
  const std::string background_track_tag;
  const std::string death_track_tag;
  const std::string end_level_track_tag;

  const std::vector<ScriptResourceData> scripts;
  const std::vector<TextureResourceData> textures;
  const std::vector<MaterialResourceData> materials;
  const std::vector<MeshResourceData> meshes;
  const std::vector<MusicResourceData> music;
  const std::vector<SoundResourceData> sounds;

  const std::vector<QuadObjectData> quads;
  const std::vector<DonutObjectData> donuts;
  const std::vector<PlatformObjectData> platforms;
  const std::vector<WallObjectData> walls;
  const std::vector<LadderObjectData> ladders;
  const std::vector<VineObjectData> vines;
};

bool operator==(const LevelData& lhs, const LevelData& rhs);

};  // namespace Jumpman

#endif  // ENGINE_LEVELDATA_HPP_
