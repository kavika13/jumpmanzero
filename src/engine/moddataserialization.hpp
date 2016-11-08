#ifndef ENGINE_MODDATASERIALIZATION_HPP_
#define ENGINE_MODDATASERIALIZATION_HPP_

#include <json/json.h>
#include "moddata.hpp"

namespace Jumpman {

ModData DeserializeModData(const Json::Value& root_node, sol::state& state);
Json::Value SerializeModData(const ModData& data);

};  // namespace Jumpman

#endif  // ENGINE_MODDATASERIALIZATION_HPP_
