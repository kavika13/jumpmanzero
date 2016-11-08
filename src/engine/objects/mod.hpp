#ifndef ENGINE_OBJECTS_MOD_HPP_
#define ENGINE_OBJECTS_MOD_HPP_

#include <memory>
#include <unordered_map>
#include <vector>
#include "engine/moddata.hpp"
#include "engine/resourcecontext.hpp"
#include "quadobject.hpp"

namespace Jumpman {

namespace Objects {

class Mod {
 public:
  template <typename T>
  using ObjectContainer = std::vector<std::shared_ptr<T>>;

  static std::shared_ptr<Mod> Load(const ModData&, ResourceContext&);

  const std::string background_track_tag;

  size_t NumQuads() const;
  const ObjectContainer<QuadObject>& GetQuads() const;
  const std::shared_ptr<QuadObject> FindQuad(const std::string& tag) const;

 private:
  explicit Mod(const ModData& data);

  ObjectContainer<QuadObject> quads_;
  std::unordered_map<std::string, std::weak_ptr<QuadObject>> tag_to_quad_map_;
};

};  // namespace Objects

};  // namespace Jumpman

#endif  // ENGINE_OBJECTS_MOD_HPP_
