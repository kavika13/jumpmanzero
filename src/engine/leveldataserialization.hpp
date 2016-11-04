#ifndef ENGINE_LEVELDATASERIALIZATION_HPP_
#define ENGINE_LEVELDATASERIALIZATION_HPP_

#include <json/json.h>
#include "leveldata.hpp"

namespace Jumpman {

LevelData DeserializeLevelData(const Json::Value& root_node);
Json::Value SerializeLevelData(const LevelData& data);

};  // namespace Jumpman

#endif  // ENGINE_LEVELDATASERIALIZATION_HPP_
