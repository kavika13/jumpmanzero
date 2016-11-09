#ifndef ENGINE_MODLISTDATA_HPP_
#define ENGINE_MODLISTDATA_HPP_

#include <fstream>
#include <vector>

namespace Jumpman {

struct ModListItemData {
  static ModListItemData FromStream(std::istream&, const std::string&);

  friend std::ostream& operator<<(std::ostream&, const ModListItemData&);

  const std::string title;
  const std::string filename;
};

bool operator==(const ModListItemData& lhs, const ModListItemData& rhs);

class ModListData {
 public:
  static ModListData FromStream(  // TODO: Take dir search as object instead of path
    std::istream& stream,
    const std::string& resource_base_path,
    const std::string& mod_dir_path);

  friend std::ostream& operator<<(std::ostream& stream, const ModListData& list);

  const std::vector<ModListItemData> builtin_mods;
  const std::vector<ModListItemData> discovered_mods;
};

bool operator==(const ModListData& lhs, const ModListData& rhs);

};  // namespace Jumpman

#endif  // ENGINE_MODLISTDATA_HPP_
