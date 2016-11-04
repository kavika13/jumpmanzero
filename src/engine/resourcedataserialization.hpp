#ifndef ENGINE_RESOURCEDATASERIALIZATION_HPP_
#define ENGINE_RESOURCEDATASERIALIZATION_HPP_

#include <json/json.h>
#include "resourcedata.hpp"

namespace Jumpman {

ResourceData DeserializeResourceData(const Json::Value& root_node);
Json::Value SerializeResourceData(const ResourceData& data);

};  // namespace Jumpman


#endif  // ENGINE_RESOURCEDATASERIALIZATION_HPP_
