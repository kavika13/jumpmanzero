#ifndef ENGINE_LUASCRIPT_HPP_
#define ENGINE_LUASCRIPT_HPP_

#include <sol.hpp>

class LuaScript {
 public:
  LuaScript(const std::string& filename);

  void Update(double elapsed_seconds);

 private:
  sol::state script_;
  sol::function update_function_;
};

#endif  // ENGINE_LUASCRIPT_HPP_
