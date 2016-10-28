#ifndef ENGINE_LUASCRIPT_HPP_
#define ENGINE_LUASCRIPT_HPP_

#include <sol.hpp>

namespace Jumpman {

class LuaScript {
 public:
  LuaScript(
    const std::string& filename, std::function<void(sol::state&)> add_bindings);

  void LoadScript(const std::string filename);
  bool Update(double elapsed_seconds);

 private:
  sol::state script_;
  sol::function update_function_;
};

};  // namespace Jumpman

#endif  // ENGINE_LUASCRIPT_HPP_
