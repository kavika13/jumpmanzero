#include "moddataserialization.hpp"
#include "resourcedataserialization.hpp"
#include "logging.hpp"

namespace Jumpman {

ModData DeserializeModData(const Json::Value& root_node, sol::state& state) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Reading mod data from json";

  ResourceData resource_data = DeserializeResourceData(root_node);

  std::function<sol::object(const Json::Value&)> convert_node =
    [&state, &convert_node](const Json::Value& node) -> sol::object {
      if (node.isNull()) {
        return sol::make_object(state, sol::nil);
      } else if (node.isArray()) {
        sol::table result = state.create_table();
        for (auto& sub_node: node) {
          result.add(convert_node(sub_node));
        }
        return result;
      } else if (node.isObject()) {
        sol::table result = state.create_table();
        for (auto& key: node.getMemberNames()) {
          result.set(key, convert_node(node[key]));
        }
        return result;
      } else if (node.isBool()) {
        return sol::make_object(state, node.asBool());
      } else if (node.isNumeric()) {
        return sol::make_object(state, node.asDouble());
      } else if (node.isString()) {
        return sol::make_object(state, node.asString());
      } else {
        throw std::runtime_error("Unrecognized json type");
      }
    };

  sol::object custom_data = convert_node(root_node["data"]);

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
