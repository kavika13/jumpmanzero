#ifndef ENGINE_SCRIPTCONTEXT_HPP_
#define ENGINE_SCRIPTCONTEXT_HPP_

#include <memory>
#include <string>
#include <sol.hpp>
#include "engine/graphics/scene.hpp"
#include "engine/objects/modlist.hpp"
#include "engine/sound/system.hpp"
#include "engine/sound/musictrackslot.hpp"
#include "input.hpp"
#include "modlistdata.hpp"
#include "resourcecontext.hpp"

namespace Jumpman {

class ScriptContext {
 public:
  ScriptContext(
    std::shared_ptr<Graphics::Scene> scene,
    std::shared_ptr<Sound::System> sound_system,
    std::shared_ptr<Input> input,
    const std::string& main_script_filename);

  bool Update(double elapsed_seconds);

  Objects::ModList LoadModList();
  std::shared_ptr<ScriptContext> LoadMod(const std::string& filename);
  std::shared_ptr<ScriptContext> LoadLevel(const std::string& filename);

 private:
  ScriptContext(
    std::shared_ptr<Graphics::Scene> scene,
    std::shared_ptr<Sound::System> sound_system,
    std::shared_ptr<Sound::MusicTrackSlot> main_track_slot,
    std::shared_ptr<Input> input);

  sol::state StateFactory();

  std::shared_ptr<ResourceContext> resource_context_;
  std::shared_ptr<Graphics::Scene> scene_;
  std::shared_ptr<Sound::System> sound_system_;
  std::shared_ptr<Sound::MusicTrackSlot> main_track_slot_;
  std::shared_ptr<Graphics::SceneObject> scene_root_;
  std::shared_ptr<Input> input_;
  sol::state main_script_;
  sol::function update_function_;
};

};  // namespace Jumpman

#endif  // ENGINE_SCRIPTCONTEXT_HPP_
