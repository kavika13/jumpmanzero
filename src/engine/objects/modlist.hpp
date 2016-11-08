#ifndef ENGINE_OBJECTS_MODLIST_HPP_
#define ENGINE_OBJECTS_MODLIST_HPP_

#include <vector>
#include "engine/modlistdata.hpp"

namespace Jumpman {

namespace Objects {

class ModInfo {
 public:
  explicit ModInfo(const ModListItemData& data) noexcept;

  const std::string& GetTitle() const noexcept;
  const std::string& GetFilename() const noexcept;

 private:
  std::string title_;
  std::string filename_;
};

class ModList {
 public:
  explicit ModList(const ModListData& data);

  const std::vector<ModInfo>& GetBuiltinMods() const noexcept;
  const std::vector<ModInfo>& GetDiscoveredMods() const noexcept;

 private:
  std::vector<ModInfo> builtin_mods_;
  std::vector<ModInfo> discovered_mods_;
};

};  // namespace Objects

};  // namespace Jumpman

#endif  // ENGINE_OBJECTS_MODLIST_HPP_
