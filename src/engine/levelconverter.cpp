#include <fstream>
#include <unordered_map>
#include <sstream>
#include "./levelconverter.hpp"
#include "./logging.hpp"

std::istream& operator>>(std::istream& stream, LevelResourceType& type) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Level");

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
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Level");
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
    "msh",
    "bmp",
    "jpg",
    "lua",
    "png",
    "wav",
  };

  constexpr size_t extension_count =
    sizeof(file_extensions) / sizeof(*file_extensions);

  if (static_cast<size_t>(type) < extension_count) {
    filename += std::string(".") + file_extensions[type];
  } else {
    BOOST_LOG_SEV(log, LogSeverity::kWarning)
      << "Invalid resource type: " << type;
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
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Level");
  float tx, ty, x, y, z;

  if (!(stream >> tx >> ty >> x >> y >> z)) {
    BOOST_LOG_SEV(log, LogSeverity::kWarning)
      << "Failed to parse level object vertex";
    return stream;
  }

  vertex.tx = tx;
  vertex.ty = ty;
  vertex.x = x;
  vertex.y = y;
  vertex.z = z;

  return stream;
}

std::istream& operator>>(std::istream& stream, LevelObjectEntry& entry) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Level");

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

  float platform_type;

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

  int64_t tag_handle;

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
    {"ARBITRARY", kArbitrary},
    {"DONUT", kDonut},
    {"PLATFORM", kPlatform},
    {"WALL", kWall},
    {"LADDER", kLadder},
    {"VINE", kVine},
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

  float z1, z2;

  if (!(stream >> z1 >> z2)) {
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

  entry.object_type = object_type;

  for (size_t vertex_index = 0; vertex_index < 8; ++vertex_index) {
    const auto& vertex = vertices[vertex_index];
    entry.vertices[vertex_index] = {
      vertex.tx,
      vertex.ty,
      vertex.x,
      vertex.y,
      vertex.z,
    };
  }

  entry.z1 = z1;
  entry.z2 = z2;

  entry.texture_index = texture_index;

  return stream;
}

LevelConverter::LevelConverter(const std::string& source_filename) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Level");
  std::ifstream source_file(source_filename);

  if (!source_file) {
    std::string error_message = "failed to open file: " + source_filename;
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::ifstream::failure(error_message);
  }

  int line_count = 0;
  std::string line;

  while (std::getline(source_file, line)) {
    ++line_count;
    std::istringstream iss(line);

    char entry_type;

    if (!(iss >> entry_type)) {
      BOOST_LOG_SEV(log, LogSeverity::kWarning)
        << "failed to parse entry type from line of level file"
        << ": " << source_filename
        << " - line: " << line_count;
      continue;
    }

    switch (entry_type) {
      case 'R': {
        LevelResourceEntry resource_entry;

        if (!(iss >> resource_entry)) {
          BOOST_LOG_SEV(log, LogSeverity::kWarning)
            << "failed to parse resource entry from line of level file"
            << ": " << source_filename
            << " - line: " << line_count;
          continue;
        }

        level_resources_.push_back(resource_entry);
        break;
      }
      case 'O': {
        LevelObjectEntry object_entry;

        if (!(iss >> object_entry)) {
          BOOST_LOG_SEV(log, LogSeverity::kWarning)
            << "failed to parse object entry from line of level file"
            << ": " << source_filename
            << " - line: " << line_count;
          continue;
        }

        level_objects_.push_back(object_entry);
        break;
      }
      default:
        assert(false);
    }
  }
}

void LevelConverter::Convert(const std::string& target_filename) {
}
