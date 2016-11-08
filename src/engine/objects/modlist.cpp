#include "modlist.hpp"

namespace Jumpman {

namespace Objects {

ModInfo::ModInfo(const ModListItemData& data) noexcept
  : title_(data.title)
  , filename_(data.filename) {
}

const std::string& ModInfo::GetTitle() const noexcept {
  return title_;
}

const std::string& ModInfo::GetFilename() const noexcept {
  return filename_;
}

ModList::ModList(const ModListData& data) {
  for (auto& item: data.builtin_mods) {
    builtin_mods_.push_back(ModInfo(item));
  }

  for (auto& item: data.discovered_mods) {
    discovered_mods_.push_back(ModInfo(item));
  }
}

const std::vector<ModInfo>& ModList::GetBuiltinMods() const noexcept {
  return builtin_mods_;
}

const std::vector<ModInfo>& ModList::GetDiscoveredMods() const noexcept {
  return discovered_mods_;
}

};  // namespace Objects

};  // namespace Jumpman
