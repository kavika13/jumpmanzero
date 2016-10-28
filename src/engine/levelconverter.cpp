#include <numeric>
#include <sstream>
#include <unordered_map>
#include "levelconverter.hpp"
#include "logging.hpp"

namespace Jumpman {

std::istream& operator>>(std::istream& stream, LevelResourceType& type) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");

  int i;
  if (!(stream >> i)) {
    BOOST_LOG_SEV(log, LogSeverity::kWarning)
      << "Failed to parse level resource type";
    return stream;
  }
  type = LevelResourceType(i);

  return stream;
}

std::istream& operator>>(std::istream& stream, LevelResourceEntry& entry) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  std::string filename;
  LevelResourceType type;
  float data1;

  if (!(stream >> filename >> type >> data1)) {
    BOOST_LOG_SEV(log, LogSeverity::kWarning)
      << "Failed to parse level resource entry";
    return stream;
  }

  float data2;
  bool is_data2_present = bool(stream >> data2);

  if (!is_data2_present) {
    stream.clear();
  }

  static const char* file_extensions[] = {
    "",
    "mid",
    "obj",
    "bmp",
    "jpg",
    "lua",
    "png",
    "wav",
  };

  static const char* data_directory[] = {
    "",
    "music",
    "model",
    "texture",
    "texture",
    "script",
    "texture",
    "sound",
  };

  constexpr size_t extension_count =
    sizeof(file_extensions) / sizeof(*file_extensions);
  auto type_index = static_cast<size_t>(type);

  if (type_index < extension_count) {
    filename = std::string("data/")
      + data_directory[type_index]
      + "/" + filename + std::string(".") + file_extensions[type_index];
  } else {
    BOOST_LOG_SEV(log, LogSeverity::kWarning)
      << "Invalid resource type: " << type_index;
    return stream;
  }

  // Only set output data now that all extraction has succeeded
  entry.filename = filename;
  entry.type = type;
  entry.data1 = data1;
  entry.is_data2_present = is_data2_present;

  if (is_data2_present) {
    entry.data2 = data2;
  }

  return stream;
}

std::istream& operator>>(std::istream& stream, LevelObjectVertex& vertex) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  float tu, tv, x, y, z;

  if (!(stream >> tu >> tv >> x >> y >> z)) {
    BOOST_LOG_SEV(log, LogSeverity::kWarning)
      << "Failed to parse level object vertex";
    return stream;
  }

  vertex.tu = tu;
  vertex.tv = tv;
  vertex.x = x;
  vertex.y = y;
  vertex.z = z;

  return stream;
}

std::istream& operator>>(std::istream& stream, LevelObjectEntry& entry) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");

  std::string drawbottomdata, drawfrontdata;
  std::string drawleftdata, drawrightdata;
  std::string drawtopdata, drawbackdata;

  if (!(stream
      >> drawbottomdata >> drawfrontdata >> drawleftdata >> drawrightdata
      >> drawtopdata >> drawbackdata)) {
    BOOST_LOG_SEV(log, LogSeverity::kWarning)
      << "failed to parse draw fields from level object entry";
    return stream;
  }

  static const std::unordered_map<std::string, bool> boolean_name_map = {
    {"TRUE", true},
    {"FALSE", false},
    {"True", true},
    {"False", false},
    {"true", true},
    {"false", false},
  };

  bool drawbottom = boolean_name_map.at(drawbottomdata);
  bool drawfront = boolean_name_map.at(drawfrontdata);
  bool drawleft = boolean_name_map.at(drawleftdata);
  bool drawright = boolean_name_map.at(drawrightdata);
  bool drawtop = boolean_name_map.at(drawtopdata);
  bool drawback = boolean_name_map.at(drawbackdata);

  uint16_t platform_type;

  if (!(stream >> platform_type)) {
    BOOST_LOG_SEV(log, LogSeverity::kWarning)
      << "failed to parse platform type field from level object entry";
    return stream;
  }

  float frontback_scale_x, frontback_scale_y;
  float frontback_start_x, frontback_start_y;

  if (!(stream
      >> frontback_scale_x >> frontback_scale_y
      >> frontback_start_x >> frontback_start_y)) {
    BOOST_LOG_SEV(log, LogSeverity::kWarning)
      << "failed to parse front/back dimension fields from level object entry";
    return stream;
  }

  float leftright_scale_x, leftright_scale_y;
  float leftright_start_x, leftright_start_y;

  if (!(stream
      >> leftright_scale_x >> leftright_scale_y
      >> leftright_start_x >> leftright_start_y)) {
    BOOST_LOG_SEV(log, LogSeverity::kWarning)
      << "failed to parse left/right dimension fields from level object entry";
    return stream;
  }

  uint32_t tag_handle;

  if (!(stream >> tag_handle)) {
    BOOST_LOG_SEV(log, LogSeverity::kWarning)
      << "failed to parse tag handle field from level object entry";
    return stream;
  }

  float topbottom_scale_x, topbottom_scale_y;
  float topbottom_start_x, topbottom_start_y;

  if (!(stream
      >> topbottom_scale_x >> topbottom_scale_y
      >> topbottom_start_x >> topbottom_start_y)) {
    BOOST_LOG_SEV(log, LogSeverity::kWarning)
      << "failed to parse top/bottom dimension fields from level object entry";
    return stream;
  }

  std::string object_type_data;

  if (!(stream >> object_type_data)) {
    BOOST_LOG_SEV(log, LogSeverity::kWarning)
      << "failed to parse object type field from level object entry";
    return stream;
  }

  static const std::unordered_map<std::string, LevelObjectType>
  object_type_name_map = {
    {"ARBITRARY", LevelObjectType::kQuad},
    {"DONUT", LevelObjectType::kDonut},
    {"PLATFORM", LevelObjectType::kPlatform},
    {"WALL", LevelObjectType::kWall},
    {"LADDER", LevelObjectType::kLadder},
    {"VINE", LevelObjectType::kVine},
  };

  LevelObjectType object_type = object_type_name_map.at(object_type_data);

  std::array<LevelObjectVertex, 8> vertices;

  for (size_t vertex_index = 0; vertex_index < 8; ++vertex_index) {
    if (!(stream >> vertices[vertex_index])) {
      BOOST_LOG_SEV(log, LogSeverity::kWarning)
        << "failed to parse vertex field from level object entry"
        << ": " << vertex_index;
      return stream;
    }
  }

  float near_z, far_z;  // TODO: Right order?

  if (!(stream >> near_z >> far_z)) {
    BOOST_LOG_SEV(log, LogSeverity::kWarning)
      << "failed to parse depth fields from level object entry";
    return stream;
  }

  int64_t texture_index;

  if (!(stream >> texture_index)) {
    BOOST_LOG_SEV(log, LogSeverity::kWarning)
      << "failed to parse texture index field from level object entry";
    return stream;
  }

  // Only set output data now that all extraction has succeeded
  entry.drawbottom = drawbottom;
  entry.drawfront = drawfront;
  entry.drawleft = drawleft;
  entry.drawright = drawright;
  entry.drawtop = drawtop;
  entry.drawback = drawback;

  entry.platform_type = platform_type;

  entry.frontback_scale_x = frontback_scale_x;
  entry.frontback_scale_y = frontback_scale_y;
  entry.frontback_start_x = frontback_start_x;
  entry.frontback_start_y = frontback_start_y;

  entry.leftright_scale_x = leftright_scale_x;
  entry.leftright_scale_y = leftright_scale_y;
  entry.leftright_start_x = leftright_start_x;
  entry.leftright_start_y = leftright_start_y;

  entry.tag_handle = tag_handle;

  entry.topbottom_scale_x = topbottom_scale_x;
  entry.topbottom_scale_y = topbottom_scale_y;
  entry.topbottom_start_x = topbottom_start_x;
  entry.topbottom_start_y = topbottom_start_y;

  entry.type = object_type;

  for (size_t vertex_index = 0; vertex_index < 8; ++vertex_index) {
    const auto& vertex = vertices[vertex_index];
    entry.vertices[vertex_index] = {
      vertex.x,
      vertex.y,
      vertex.z,
      vertex.tu,
      vertex.tv,
    };
  }

  entry.near_z = near_z;
  entry.far_z = far_z;

  entry.texture_index = texture_index;

  return stream;
}

LevelConverter LevelConverter::FromStream(std::istream& stream) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");

  std::vector<LevelResourceEntry> level_resources;
  std::vector<LevelObjectEntry> level_objects;
  int line_count = 0;
  std::string line;

  while (std::getline(stream, line)) {
    ++line_count;
    std::istringstream iss(line);

    char entry_type;

    if (!(iss >> entry_type)) {
      BOOST_LOG_SEV(log, LogSeverity::kWarning)
        << "failed to parse entry type from line of level stream"
        << " - line: " << line_count;
      continue;
    }

    switch (entry_type) {
      case 'R': {
        LevelResourceEntry resource_entry;

        if (!(iss >> resource_entry)) {
          BOOST_LOG_SEV(log, LogSeverity::kWarning)
            << "failed to parse resource entry from line of level stream"
            << " - line: " << line_count;
          continue;
        }

        level_resources.push_back(resource_entry);
        break;
      }
      case 'O': {
        LevelObjectEntry object_entry;

        if (!(iss >> object_entry)) {
          BOOST_LOG_SEV(log, LogSeverity::kWarning)
            << "failed to parse object entry from line of level stream"
            << " - line: " << line_count;
          continue;
        }

        level_objects.push_back(object_entry);
        break;
      }
      default:
        assert(false);
    }
  }

  return {
    level_resources,
    level_objects,
  };
}

enum class MusicResourceType {
  kBackgroundTrack = 1,
  kDeathTrack = 2,
  kWinTrack = 3,
};

LevelData LevelConverter::Convert() {
  std::string main_script_tag;
  std::string main_script_filename;
  std::string background_track_tag;
  std::string death_track_tag;
  std::string end_level_track_tag;

  std::vector<ScriptResourceData> scripts;
  std::vector<TextureResourceData> textures;
  std::vector<MaterialResourceData> materials;
  std::vector<MeshResourceData> meshes;
  std::vector<MusicResourceData> music_tracks;
  std::vector<SoundResourceData> sounds;

  for (const auto& resource: resources) {
    switch (resource.type) {
      case LevelResourceType::kScript: {
        int tag_number = static_cast<int>(resource.data1);
        std::string tag = std::to_string(tag_number);

        switch (tag_number) {
          case 1:
            main_script_tag = tag;
            main_script_filename = resource.filename;
            break;
        }

        scripts.push_back({
          resource.filename,
          tag,
        });

        break;
      }
      case LevelResourceType::kMusic: {
        auto music_type = static_cast<MusicResourceType>(resource.data1);
        std::string tag = std::to_string(static_cast<int>(music_type));

        switch (music_type) {
          case MusicResourceType::kBackgroundTrack:
            background_track_tag = tag;
            break;
          case MusicResourceType::kDeathTrack:
            death_track_tag = tag;
            break;
          case MusicResourceType::kWinTrack:
            end_level_track_tag = tag;
            break;
        }

        music_tracks.push_back({
          resource.filename,
          tag,
          static_cast<uint32_t>(resource.data2),
        });

        break;
      }
      case LevelResourceType::kWave:
        sounds.push_back({
          resource.filename,
          std::to_string(sounds.size()),
        });
        break;
      case LevelResourceType::kMesh:
        meshes.push_back({
          resource.filename,
          std::to_string(meshes.size()),
        });
        break;
      case LevelResourceType::kBitmap:
      case LevelResourceType::kJpeg:
      case LevelResourceType::kPng: {
        // TODO: Correct logic on these?
        bool has_alpha_channel = resource.data1;
        bool has_colorkey_alpha =
          resource.type == LevelResourceType::kPng
          || (resource.type == LevelResourceType::kBitmap && has_alpha_channel);

        textures.push_back({
          resource.filename,
          std::to_string(textures.size()),
          has_colorkey_alpha,
          has_alpha_channel,
        });

        break;
      }
      default:
        assert(false);
    }
  }

  for (size_t i = 0; i < textures.size(); ++i) {
    materials.push_back({
      "data/shader/global.vert",
      "data/shader/global.frag",
      std::to_string(i),
      std::to_string(i),
    });
  }

  std::vector<QuadObjectData> quads;
  std::vector<DonutObjectData> donuts;
  std::vector<PlatformObjectData> platforms;
  std::vector<WallObjectData> walls;
  std::vector<LadderObjectData> ladders;
  std::vector<VineObjectData> vines;

  auto convert_vertex = [](const LevelObjectVertex& source)
      -> const VertexData {
    return {
      source.x,
      source.y,
      source.z,
      source.tu,
      source.tv,
    };
  };

  auto translate = [](const VertexData& source, float x, float y, float z)
      -> const VertexData {
    return {
      source.x + x,
      source.y + y,
      source.z + z,
      source.tu,
      source.tv,
    };
  };

  auto make_tag = [](const std::string& type, const LevelObjectEntry& object) {
    return object.tag_handle != 0
      ? (type + std::to_string(object.tag_handle))
      : "";
  };

  for (const auto& object: objects) {
    switch (object.type) {
      case LevelObjectType::kQuad: {
        const auto vertices = object.vertices;
        const auto sum = std::accumulate(
          vertices.begin(),
          vertices.end(),
          LevelObjectVertex({ 0, 0 }),
          [](const auto& source, const auto& target) {
            return LevelObjectVertex({
              source.x + target.x,
              source.y + target.y,
            });
          });
        LevelObjectVertex origin = { sum.x / 4, sum.y / 4 };
        origin.x = origin.x < 0.0f ? 0.0f : origin.x;
        origin.y = origin.y < 0.0f ? 0.0f : origin.y;

        quads.push_back({
          make_tag("quad", object),
          std::to_string(object.texture_index),
          origin.x,
          origin.y,
          object.near_z,
          {
            translate(
              convert_vertex(vertices[0]),
              -origin.x, -origin.y, -object.near_z),
            translate(
              convert_vertex(vertices[1]),
              -origin.x, -origin.y, -object.near_z),
            translate(
              convert_vertex(vertices[2]),
              -origin.x, -origin.y, -object.near_z),
            translate(
              convert_vertex(vertices[3]),
              -origin.x, -origin.y, -object.near_z),
          },
        });
        break;
      }
      case LevelObjectType::kDonut: {
        donuts.push_back({
          make_tag("donut", object),
          std::to_string(object.texture_index),
          object.vertices[0].x,
          object.vertices[0].y,
          object.near_z,
        });
        break;
      }
      case LevelObjectType::kPlatform: {
        const auto vertices = object.vertices;
        platforms.push_back({
          make_tag("platform", object),
          std::to_string(object.texture_index),
          object.drawtop,
          object.drawbottom,
          object.drawfront,
          object.drawback,
          object.drawleft,
          object.drawright,
          static_cast<PlatformType>(object.platform_type),
          object.near_z,
          object.far_z,
          {
            convert_vertex(vertices[0]),
            convert_vertex(vertices[1]),
            convert_vertex(vertices[2]),
            convert_vertex(vertices[3]),
          },
        });
        break;
      }
      case LevelObjectType::kWall: {
        const auto vertices = object.vertices;
        walls.push_back({
          make_tag("wall", object),
          std::to_string(object.texture_index),
          object.drawtop,
          object.drawbottom,
          object.drawfront,
          object.drawback,
          object.drawleft,
          object.drawright,
          object.near_z,
          object.far_z,
          {
            convert_vertex(vertices[0]),
            convert_vertex(vertices[1]),
            convert_vertex(vertices[2]),
            convert_vertex(vertices[3]),
          },
        });
        break;
      }
      case LevelObjectType::kLadder: {
        ladders.push_back({
          make_tag("ladder", object),
          std::to_string(object.texture_index),
          object.vertices[0].x,
          object.vertices[0].y,
          object.vertices[1].y,
          object.near_z,
        });
        break;
      }
      case LevelObjectType::kVine: {
        vines.push_back({
          make_tag("vine", object),
          std::to_string(object.texture_index),
          object.vertices[0].x,
          object.vertices[0].y,
          object.vertices[1].y,
          object.near_z,
        });
        break;
      }
    }
  }

  return LevelData {
    main_script_tag,
    main_script_filename,
    background_track_tag,
    death_track_tag,
    end_level_track_tag,

    scripts,
    textures,
    materials,
    meshes,
    music_tracks,
    sounds,

    quads,
    donuts,
    platforms,
    walls,
    ladders,
    vines,
  };
}

};  // namespace Jumpman
