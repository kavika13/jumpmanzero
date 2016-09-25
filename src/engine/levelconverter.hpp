#ifndef ENGINE_LEVELCONVERTER_HPP_
#define ENGINE_LEVELCONVERTER_HPP_

#include "leveldata.hpp"

enum class LevelResourceType {
  kMusic = 1,
  kMesh = 2,
  kBitmap = 3,
  kJpeg = 4,
  kScript = 5,
  kPng = 6,
  kWave = 7,
};

struct LevelResourceEntry {
  std::string filename;
  LevelResourceType type;
  float data1, data2;
  bool is_data2_present;
};

enum class LevelObjectType {
  kQuad,
  kDonut,
  kPlatform,
  kWall,
  kLadder,
  kVine,
};

struct LevelObjectVertex {
  float x, y, z;
  float tu, tv;
};

struct LevelObjectEntry {
  bool drawbottom, drawfront, drawleft, drawright, drawtop, drawback;

  float platform_type;

  float frontback_scale_x, frontback_scale_y;
  float frontback_start_x, frontback_start_y;

  float leftright_scale_x, leftright_scale_y;
  float leftright_start_x, leftright_start_y;

  uint32_t tag_handle;

  float topbottom_scale_x, topbottom_scale_y;
  float topbottom_start_x, topbottom_start_y;

  LevelObjectType type;

  std::array<LevelObjectVertex, 8> vertices;

  float near_z, far_z;
  int64_t texture_index;
};

struct LevelConverter {
  static LevelConverter FromStream(std::istream& stream);
  LevelData Convert();

  const std::vector<LevelResourceEntry> resources;
  const std::vector<LevelObjectEntry> objects;
};

#endif  // ENGINE_LEVELCONVERTER_HPP_
