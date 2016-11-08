#include <json/json.h>
#include "logging.hpp"
#include "modlistdata.hpp"

namespace Jumpman {

std::ostream& operator<<(std::ostream& stream, const ModListItemData& item) {
  stream
    << "ModListItemData("
    << "title: " << item.title
    << ", filename: " << item.filename
    << ")";
  return stream;
}

bool operator==(const ModListItemData& lhs, const ModListItemData& rhs) {
  return lhs.title == rhs.title
    && lhs.filename == rhs.filename
  ;
}

ModListItemData ModListItemData::FromStream(
    std::istream& stream, const std::string& filename) {
  Json::Value root_node;
  stream >> root_node;

  std::string title = root_node["title"].asString();

  return {
    title,
    filename,
  };
}

std::ostream& operator<<(std::ostream& stream, const ModListData& data) {
  stream << "ModListData(builtin: ";

  for (const auto& builtin_mod: data.builtin_mods) {
    stream << builtin_mod << ",";  // TODO: Remove extra comma
  }

  stream << ", discovered: ";

  for (const auto& discovered_mod: data.discovered_mods) {
    stream << discovered_mod << ",";  // TODO: Remove extra comma
  }

  stream << ")";

  return stream;
}

bool operator==(const ModListData& lhs, const ModListData& rhs) {
  return lhs.builtin_mods == rhs.builtin_mods
    && lhs.discovered_mods == rhs.discovered_mods;
}

ModListData ModListData::FromStream(
    std::istream& stream, const std::string& mod_dir_path) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Reading mod list from stream";

  Json::Value root_node;
  stream >> root_node;

  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Read json data:\n" << root_node;

  Json::Value builtin_node = root_node["builtin"];

  std::vector<ModListItemData> builtin_mods;

  for (const auto& mod_path_value: builtin_node) {
    std::string mod_path = mod_path_value.asString();
    std::ifstream mod_file(mod_path);

    if (!mod_file) {
      BOOST_LOG_SEV(log, LogSeverity::kError)
        << "Failed to open builtin mod at path: " << mod_path;
      throw std::runtime_error(
        "Failed to open builtin mod at path: " + mod_path);
    }

    builtin_mods.push_back(ModListItemData::FromStream(mod_file, mod_path));
  }

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Finished reading builtin mod list";

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Discovering user mods in mod directory";

  // TODO: Implement
  std::vector<ModListItemData> discovered_mods;

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Finished discovering user mods in mod directory";

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished reading mod list from stream";

  return {
    builtin_mods,
    discovered_mods,
  };
}

};  // namespace Jumpman
