#ifndef ENGINE_LEVELCONVERTER_HPP_
#define ENGINE_LEVELCONVERTER_HPP_

#include <array>
#include <cstdint>
#include <string>
#include <vector>

enum LevelResourceType {
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

enum LevelObjectType {
  kArbitrary,
  kDonut,
  kPlatform,
  kWall,
  kLadder,
  kVine,
};

struct LevelObjectVertex {
  float tx, ty;
  float x, y, z;
};

struct LevelObjectEntry {
  bool drawbottom, drawfront, drawleft, drawright, drawtop, drawback;

  float platform_type;

  float frontback_scale_x, frontback_scale_y;
  float frontback_start_x, frontback_start_y;

  float leftright_scale_x, leftright_scale_y;
  float leftright_start_x, leftright_start_y;

  int64_t tag_handle;

  float topbottom_scale_x, topbottom_scale_y;
  float topbottom_start_x, topbottom_start_y;

  LevelObjectType object_type;

  std::array<LevelObjectVertex, 8> vertices;

  float z1, z2;  // TODO: Better name? near_offset, far_offset?
  int64_t texture_index;
};

class LevelConverter {
 public:
  explicit LevelConverter(const std::string& source_filename);
  void Convert(const std::string& target_filename);

  size_t num_resources() const {
    return level_resources_.size();
  }

  size_t num_objects() const {
    return level_objects_.size();
  }

  LevelResourceEntry& at_resource(size_t index) {
    return level_resources_[index];
  }

  const LevelResourceEntry& at_resource(size_t index) const {
    return level_resources_[index];
  }

  LevelObjectEntry& at_object(size_t index) {
    return level_objects_[index];
  }

  const LevelObjectEntry& at_object(size_t index) const {
    return level_objects_[index];
  }

 private:
  std::vector<LevelResourceEntry> level_resources_;
  std::vector<LevelObjectEntry> level_objects_;
};

#endif  // ENGINE_LEVELCONVERTER_HPP_
