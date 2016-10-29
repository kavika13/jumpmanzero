#ifndef ENGINE_LUASCRIPT_HPP_
#define ENGINE_LUASCRIPT_HPP_

#include <sol.hpp>

namespace Jumpman {

class LuaScript {
 public:
  LuaScript();

  LuaScript& LoadScript(const std::string filename);
  LuaScript& AddState(std::function<void(sol::state&)> add_state);

  bool Update(double elapsed_seconds);

 private:
  sol::state script_;
  sol::function update_function_;
};

};  // namespace Jumpman

#endif  // ENGINE_LUASCRIPT_HPP_
