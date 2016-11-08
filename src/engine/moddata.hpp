#ifndef ENGINE_MODDATA_HPP_
#define ENGINE_MODDATA_HPP_

#include <istream>
#include <sol.hpp>
#include "resourcedata.hpp"

namespace Jumpman {

struct ModData {
  static ModData FromStream(std::istream& stream, sol::state& state);

  friend std::ostream& operator<<(std::ostream& stream, const ModData& data);

  const std::string main_script_tag;
  const std::string main_script_filename;
  const std::string background_track_tag;

  const std::vector<ScriptResourceData> scripts;
  const std::vector<TextureResourceData> textures;
  const std::vector<MaterialResourceData> materials;
  const std::vector<MeshResourceData> meshes;
  const std::vector<MusicResourceData> music;
  const std::vector<SoundResourceData> sounds;

  const std::vector<QuadObjectData> quads;

  sol::object custom_data;
};

bool operator==(const ModData& lhs, const ModData& rhs);

};  // namespace Jumpman

#endif  // ENGINE_MODDATA_HPP_
