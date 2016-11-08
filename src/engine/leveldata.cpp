#include "leveldata.hpp"
#include "leveldataserialization.hpp"
#include "logging.hpp"

namespace Jumpman {

bool operator==(const DonutObjectData& lhs, const DonutObjectData& rhs) {
  return lhs.tag == rhs.tag
    && lhs.material_tag == rhs.material_tag
    && lhs.origin_x == rhs.origin_x
    && lhs.origin_y == rhs.origin_y
    && lhs.origin_z == rhs.origin_z;
}

std::ostream& operator<<(std::ostream& stream, const DonutObjectData& val) {
  stream << "tag: " << val.tag
    << " - material_tag: " << val.material_tag
    << " - origin_x: " << val.origin_x
    << " - origin_y: " << val.origin_y
    << " - origin_z: " << val.origin_z;
  return stream;
}

bool operator==(const PlatformObjectData& lhs, const PlatformObjectData& rhs) {
  return lhs.tag == rhs.tag
    && lhs.material_tag == rhs.material_tag
    && lhs.drawtop == rhs.drawtop
    && lhs.drawbottom == rhs.drawbottom
    && lhs.drawfront == rhs.drawfront
    && lhs.drawback == rhs.drawback
    && lhs.drawleft == rhs.drawleft
    && lhs.drawright == rhs.drawright
    && lhs.platform_type == rhs.platform_type
    && lhs.front_z == rhs.front_z
    && lhs.back_z == rhs.back_z
    && lhs.vertices[0] == rhs.vertices[0]
    && lhs.vertices[1] == rhs.vertices[1]
    && lhs.vertices[2] == rhs.vertices[2]
    && lhs.vertices[3] == rhs.vertices[3];
}

std::ostream& operator<<(std::ostream& stream, const PlatformObjectData& val) {
  stream << "tag: " << val.tag
    << " - material_tag: " << val.material_tag
    << " - drawtop: " << val.drawtop
    << " - drawbottom: " << val.drawbottom
    << " - drawfront: " << val.drawfront
    << " - drawback: " << val.drawback
    << " - drawleft: " << val.drawleft
    << " - drawright: " << val.drawright
    << " - platform_type: " << static_cast<int>(val.platform_type)
    << " - front_z: " << val.front_z
    << " - back_z: " << val.back_z
    << " - vertices[0]: " << val.vertices[0]
    << " - vertices[1]: " << val.vertices[1]
    << " - vertices[2]: " << val.vertices[2]
    << " - vertices[3]: " << val.vertices[3];
  return stream;
}

bool operator==(const WallObjectData& lhs, const WallObjectData& rhs) {
  return lhs.tag == rhs.tag
    && lhs.material_tag == rhs.material_tag
    && lhs.drawtop == rhs.drawtop
    && lhs.drawbottom == rhs.drawbottom
    && lhs.drawfront == rhs.drawfront
    && lhs.drawback == rhs.drawback
    && lhs.drawleft == rhs.drawleft
    && lhs.drawright == rhs.drawright
    && lhs.front_z == rhs.front_z
    && lhs.back_z == rhs.back_z
    && lhs.vertices[0] == rhs.vertices[0]
    && lhs.vertices[1] == rhs.vertices[1]
    && lhs.vertices[2] == rhs.vertices[2]
    && lhs.vertices[3] == rhs.vertices[3];
}

std::ostream& operator<<(std::ostream& stream, const WallObjectData& val) {
  stream << "tag: " << val.tag
    << " - material_tag: " << val.material_tag
    << " - drawtop: " << val.drawtop
    << " - drawbottom: " << val.drawbottom
    << " - drawfront: " << val.drawfront
    << " - drawback: " << val.drawback
    << " - drawleft: " << val.drawleft
    << " - drawright: " << val.drawright
    << " - front_z: " << val.front_z
    << " - back_z: " << val.back_z
    << " - vertices[0]: " << val.vertices[0]
    << " - vertices[1]: " << val.vertices[1]
    << " - vertices[2]: " << val.vertices[2]
    << " - vertices[3]: " << val.vertices[3];
  return stream;
}

bool operator==(const LadderObjectData& lhs, const LadderObjectData& rhs) {
  return lhs.tag == rhs.tag
    && lhs.material_tag == rhs.material_tag
    && lhs.origin_x == rhs.origin_x
    && lhs.top_y == rhs.top_y
    && lhs.bottom_y == rhs.bottom_y
    && lhs.front_z == rhs.front_z;
}

std::ostream& operator<<(std::ostream& stream, const LadderObjectData& val) {
  stream << "tag: " << val.tag
    << " - material_tag: " << val.material_tag
    << " - origin_x: " << val.origin_x
    << " - top_y: " << val.top_y
    << " - bottom_y: " << val.bottom_y
    << " - front_z: " << val.front_z;
  return stream;
}

bool operator==(const VineObjectData& lhs, const VineObjectData& rhs) {
  return lhs.tag == rhs.tag
    && lhs.material_tag == rhs.material_tag
    && lhs.origin_x == rhs.origin_x
    && lhs.top_y == rhs.top_y
    && lhs.bottom_y == rhs.bottom_y
    && lhs.front_z == rhs.front_z;
}

std::ostream& operator<<(std::ostream& stream, const VineObjectData& val) {
  stream << "tag: " << val.tag
    << " - material_tag: " << val.material_tag
    << " - origin_x: " << val.origin_x
    << " - top_y: " << val.top_y
    << " - bottom_y: " << val.bottom_y
    << " - front_z: " << val.front_z;
  return stream;
}

bool operator==(const LevelData& lhs, const LevelData& rhs) {
  return true
    && lhs.main_script_tag == rhs.main_script_tag
    && lhs.background_track_tag == rhs.background_track_tag
    && lhs.death_track_tag == rhs.death_track_tag
    && lhs.end_level_track_tag == rhs.end_level_track_tag
    && lhs.scripts == rhs.scripts
    && lhs.textures == rhs.textures
    && lhs.materials == rhs.materials
    && lhs.meshes == rhs.meshes
    && lhs.music == rhs.music
    && lhs.sounds == rhs.sounds
    && lhs.quads == rhs.quads
    && lhs.donuts == rhs.donuts
    && lhs.platforms == rhs.platforms
    && lhs.walls == rhs.walls
    && lhs.ladders == rhs.ladders
    && lhs.vines == rhs.vines
  ;
}

LevelData LevelData::FromStream(std::istream& stream) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Reading level data from stream";

  Json::Value root_node;
  stream >> root_node;

  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Read json data:\n" << root_node;

  return DeserializeLevelData(root_node);
}

std::ostream& operator<<(std::ostream& stream, const LevelData& data) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Writing level data to stream";

  Json::Value root_node = SerializeLevelData(data);
  stream << root_node;

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished writing level data to stream";

  return stream;
}

};  // namespace Jumpman
