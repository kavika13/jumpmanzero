#include "luascript.hpp"
#include <unordered_set>

LuaScript::LuaScript(const std::string& filename) {
  script_.open_libraries(
    sol::lib::base,
    sol::lib::coroutine,
    sol::lib::string,
    sol::lib::os,
    sol::lib::math,
    sol::lib::table,
    sol::lib::io);
  sol::table glob = script_.globals();

  const std::unordered_set<std::string> base_whitelist {
    "_G",
    "coroutine",
    "string",
    "os",
    "math",
    "table",
    "io",

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

  const std::unordered_set<std::string> io_whitelist {
    "read",
    "write",
    "flush",
    "type",
  };

  auto sanitize_subtable = [&glob, this](
      const std::string& table_name,
      const std::unordered_set<std::string>& whitelist) {
    auto table = glob.get<sol::table>(table_name);
    table.for_each([&](sol::object key, sol::object value) {
      if (whitelist.find(key.as<std::string>()) == whitelist.end()) {
        table.set(key, sol::nil);
      }
    });
  };

  sanitize_subtable("coroutine", coroutine_whitelist);
  sanitize_subtable("string", string_whitelist);
  sanitize_subtable("os", os_whitelist);
  sanitize_subtable("math", math_whitelist);
  sanitize_subtable("table", table_whitelist);
  sanitize_subtable("io", io_whitelist);
  sanitize_subtable("_G", base_whitelist);

  // TODO: Make environment read-only for white-listed functions/tables

  // TODO: Add bindings to engine

  script_.script_file(filename);
  update_function_ = script_["update"];
}

void LuaScript::Update(double elapsed_seconds) {
  update_function_(elapsed_seconds);
}
