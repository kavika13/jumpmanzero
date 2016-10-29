#ifndef ENGINE_MODDATA_HPP_
#define ENGINE_MODDATA_HPP_

#include <fstream>
#include <vector>
#include <json/json.h>

namespace Jumpman {

struct ModData {
  static ModData FromStream(std::istream& stream, const std::string& mod_path);

  friend std::ostream& operator<<(std::ostream& stream, const ModData& data);

  // TODO: Make const once we wrap this with a safer resource loader
  std::string title;
  std::string filename;
  Json::Value data;  // TODO: Don't expose as json
};

bool operator==(const ModData& lhs, const ModData& rhs);

class ModList {
 public:
  static ModList FromStream(  // TODO: Take dir search as object instead of path
    std::istream& stream, const std::string& mod_dir_path);

  friend std::ostream& operator<<(std::ostream& stream, const ModList& data);

  // TODO: Make const once we wrap this with a safer resource loader
  std::vector<ModData> builtin;
  std::vector<ModData> discovered;
};

bool operator==(const ModList& lhs, const ModList& rhs);

};  // namespace Jumpman

#endif  // ENGINE_MODDATA_HPP_
