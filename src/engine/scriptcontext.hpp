#ifndef ENGINE_SCRIPTCONTEXT_HPP_
#define ENGINE_SCRIPTCONTEXT_HPP_

#include <memory>
#include <string>
#include "engine/graphics/scene.hpp"
#include "engine/objects/level.hpp"
#include "input.hpp"
#include "luascript.hpp"
#include "resourcecontext.hpp"

namespace Jumpman {

class ScriptContext {
 public:
  ScriptContext(
    std::shared_ptr<Graphics::Scene> scene,
    std::shared_ptr<Input> input,
    const std::string& main_script_filename);

  bool Update(double elapsed_seconds);

  std::shared_ptr<Objects::Level> LoadLevel(const std::string& filename);

 private:
  std::shared_ptr<LuaScript> ScriptFactory(const std::string& filename);

  std::shared_ptr<ResourceContext> resource_context_;
  std::shared_ptr<Graphics::Scene> scene_;
  std::shared_ptr<Input> input_;
  std::shared_ptr<LuaScript> main_script_;
};

};  // namespace Jumpman

#endif  // ENGINE_SCRIPTCONTEXT_HPP_
