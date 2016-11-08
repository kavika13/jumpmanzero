#include "moddataserialization.hpp"
#include "resourcedataserialization.hpp"
#include "logging.hpp"

namespace Jumpman {

ModData DeserializeModData(const Json::Value& root_node, sol::state& state) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Reading mod data from json";

  ResourceData resource_data = DeserializeResourceData(root_node);

  // TODO: Convert dynamically
  sol::table custom_data = state.create_table();
  Json::Value data_node = root_node["data"];

  for (const auto& leveset_node: data_node) {
    sol::table levelset_table = state.create_table();
    levelset_table["title"] = leveset_node["title"].asString();

    sol::table levels_table = state.create_table();
    for (const auto& level_node: leveset_node["levels"]) {
      sol::table level_table = state.create_table();
      level_table["filename"] = level_node["filename"].asString();
      level_table["title"] = level_node["title"].asString();
      levels_table.add(level_table);
    }
    levelset_table["levels"] = levels_table;

    custom_data.add(levelset_table);
  }

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished reading level data from json";

  return ModData {
    resource_data.main_script_tag,
    resource_data.main_script_filename,
    resource_data.background_track_tag,

    resource_data.scripts,
    resource_data.textures,
    resource_data.materials,
    resource_data.meshes,
    resource_data.music,
    resource_data.sounds,

    resource_data.quads,

    custom_data
  };
}

Json::Value SerializeModData(const ModData& data) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Writing mod data to json";

  Json::Value root_node = SerializeResourceData(ResourceData {
    data.main_script_tag,
    data.main_script_filename,
    data.background_track_tag,

    data.scripts,
    data.textures,
    data.materials,
    data.meshes,
    data.music,
    data.sounds,

    data.quads,
  });

  // TODO: Convert and add custom data

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished writing mod data to json";

  return root_node;
}

};  // namespace Jumpman
