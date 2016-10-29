#include "logging.hpp"
#include "moddata.hpp"

namespace Jumpman {

std::ostream& operator<<(std::ostream& stream, const ModData& data) {
  stream
    << "ModData(title: " << data.title
    << ", filename: " << data.filename
    << ", data: " << data.data
    << ")";
  return stream;
}

bool operator==(const ModData& lhs, const ModData& rhs) {
  return lhs.title == rhs.title
    && lhs.filename == rhs.filename
    && lhs.data == rhs.data;
}

ModData ModData::FromStream(std::istream& stream, const std::string& filename) {
  Json::Value root_node;
  stream >> root_node;

  std::string title = root_node["title"].asString();
  Json::Value data_node = root_node["data"];

  return {
    title,
    filename,
    data_node,
  };
}

std::ostream& operator<<(std::ostream& stream, const ModList& data) {
  stream << "ModList(builtin: ";

  for (const auto& builtin_mod: data.builtin) {
    stream << builtin_mod << ",";  // TODO: Remove extra comma
  }

  stream << ", discovered: ";

  for (const auto& discovered_mod: data.discovered) {
    stream << discovered_mod << ",";  // TODO: Remove extra comma
  }

  stream << ")";

  return stream;
}

bool operator==(const ModList& lhs, const ModList& rhs) {
  return lhs.builtin == rhs.builtin
    && lhs.discovered == rhs.discovered;
}

ModList ModList::FromStream(
    std::istream& stream, const std::string& mod_dir_path) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Reading mod list from stream";

  Json::Value root_node;
  stream >> root_node;

  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Read json data:\n" << root_node;

  Json::Value builtin_node = root_node["builtin"];

  std::vector<ModData> builtin;

  for (const auto& mod_path_value: builtin_node) {
    std::string mod_path = mod_path_value.asString();
    std::ifstream mod_file(mod_path);

    if (!mod_file) {
      BOOST_LOG_SEV(log, LogSeverity::kError)
        << "Failed to open builtin mod at path: " << mod_path;
      throw std::runtime_error(
        "Failed to open builtin mod at path: " + mod_path);
    }

    builtin.push_back(ModData::FromStream(mod_file, mod_path));
  }

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Finished reading builtin mod list";

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Discovering user mods in mod directory";

  // TODO: Implement
  std::vector<ModData> discovered;

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Finished discovering user mods in mod directory";

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished reading mod list from stream";

  return {
    builtin,
    discovered,
  };
}

};  // namespace Jumpman
