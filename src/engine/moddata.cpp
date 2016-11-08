#include "moddata.hpp"
#include "moddataserialization.hpp"
#include "logging.hpp"

namespace Jumpman {

bool operator==(const ModData& lhs, const ModData& rhs) {
  return true
    && lhs.main_script_tag == rhs.main_script_tag
    && lhs.background_track_tag == rhs.background_track_tag
    && lhs.scripts == rhs.scripts
    && lhs.textures == rhs.textures
    && lhs.materials == rhs.materials
    && lhs.meshes == rhs.meshes
    && lhs.music == rhs.music
    && lhs.sounds == rhs.sounds
    && lhs.quads == rhs.quads
    && lhs.custom_data == rhs.custom_data
  ;
}

ModData ModData::FromStream(std::istream& stream, sol::state& state) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Reading mod data from stream";

  Json::Value root_node;
  stream >> root_node;

  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Read json data:\n" << root_node;

  return DeserializeModData(root_node, state);
}

std::ostream& operator<<(std::ostream& stream, const ModData& data) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Writing mod data to stream";

  Json::Value root_node = SerializeModData(data);
  stream << root_node;

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished writing mod data to stream";

  return stream;
}

};  // namespace Jumpman
