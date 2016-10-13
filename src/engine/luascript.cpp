#include "luascript.hpp"
#include <unordered_set>

LuaScript::LuaScript(const std::string& filename) {
  script_.open_libraries(
    sol::lib::base,
    sol::lib::coroutine,
    sol::lib::string,
    sol::lib::os,
    sol::lib::math,
    sol::lib::table);
  sol::global_table glob = script_.globals();

  const std::unordered_set<std::string> base_whitelist {
    "coroutine",
    "string",
    "os",
    "math",
    "table",

    "_VERSION",
    "assert",
    "error",
    "ipairs",
    "next",
    "pairs",
    "pcall",
    "print",
    "select",
    "tonumber",
    "tostring",
    "type",
    "xpcall",
  };

  const std::unordered_set<std::string> coroutine_whitelist {
    "create",
    "isyieldable",
    "resume",
    "running",
    "status",
    "wrap",
    "yield",
  };

  const std::unordered_set<std::string> string_whitelist {
    "byte",
    "char",
    "find",
    "format",
    "gmatch",
    "gsub",
    "len",
    "lower",
    "match",
    "pack",
    "packsize",
    "rep",
    "reverse",
    "sub",
    "unpack",
    "upper",
  };

  const std::unordered_set<std::string> os_whitelist {
    "clock",
    "difftime",
    "time",
  };

  const std::unordered_set<std::string> math_whitelist {
    "abs",
    "acos",
    "asin",
    "atan",
    "atan2",
    "ceil",
    "cos",
    "cosh",
    "deg",
    "exp",
    "floor",
    "fmod",
    "frexp",
    "huge",
    "ldexp",
    "log",
    "log10",
    "max",
    "maxinteger",
    "min",
    "mininteger",
    "modf",
    "pi",
    "pow",
    "rad",
    "random",
    "randomseed",
    "sin",
    "sinh",
    "sqrt",
    "tan",
    "tanh",
    "tointeger",
    "type",
    "ult",
  };

  const std::unordered_set<std::string> table_whitelist {
    "concat",
    "insert",
    "move",
    "pack",
    "remove",
    "sort",
    "unpack",
  };

  glob.for_each([&](sol::object key, sol::object value) {
    if (base_whitelist.find(key.as<std::string>()) == base_whitelist.end()) {
      glob.set(key, sol::nil);
    }
  });

  auto coroutine_table = glob.get<sol::table>("coroutine");
  coroutine_table.for_each([&](sol::object key, sol::object value) {
    if (coroutine_whitelist.find(key.as<std::string>())
        == coroutine_whitelist.end()) {
      coroutine_table.set(key, sol::nil);
    }
  });

  auto string_table = glob.get<sol::table>("string");
  string_table.for_each([&](sol::object key, sol::object value) {
    if (string_whitelist.find(key.as<std::string>())
        == string_whitelist.end()) {
      string_table.set(key, sol::nil);
    }
  });

  auto os_table = glob.get<sol::table>("os");
  os_table.for_each([&](sol::object key, sol::object value) {
    if (os_whitelist.find(key.as<std::string>()) == os_whitelist.end()) {
      os_table.set(key, sol::nil);
    }
  });

  auto math_table = glob.get<sol::table>("math");
  math_table.for_each([&](sol::object key, sol::object value) {
    if (math_whitelist.find(key.as<std::string>()) == math_whitelist.end()) {
      math_table.set(key, sol::nil);
    }
  });

  auto table_table = glob.get<sol::table>("table");
  table_table.for_each([&](sol::object key, sol::object value) {
    if (table_whitelist.find(key.as<std::string>()) == table_whitelist.end()) {
      table_table.set(key, sol::nil);
    }
  });

  // TODO: Add bindings to engine

  script_.script_file(filename);
  update_function_ = script_["update"];
}

void LuaScript::Update(double elapsed_seconds) {
  update_function_(elapsed_seconds);
}
