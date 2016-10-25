#ifndef ENGINE_MODDATA_HPP_
#define ENGINE_MODDATA_HPP_

#include <fstream>
#include <vector>
#include <json/json.h>

namespace Jumpman {

struct ModData {
  static ModData FromStream(std::istream& stream);

  friend std::ostream& operator<<(std::ostream& stream, const ModData& data);

  const std::string title;
  const std::string entrypoint_script_filename;
  const Json::Value data;  // TODO: Don't expose as json
};

bool operator==(const ModData& lhs, const ModData& rhs);

class ModList {
 public:
  static ModList FromStream(  // TODO: Take dir search as object instead of path
    std::istream& stream, const std::string& mod_dir_path);

  friend std::ostream& operator<<(std::ostream& stream, const ModList& data);

  const std::vector<ModData> builtin;
  const std::vector<ModData> discovered;
};

bool operator==(const ModList& lhs, const ModList& rhs);

};  // namespace Jumpman

#endif  // ENGINE_MODDATA_HPP_
