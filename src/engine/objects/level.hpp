#ifndef ENGINE_OBJECTS_LEVEL_HPP_
#define ENGINE_OBJECTS_LEVEL_HPP_

#include <memory>
#include <unordered_map>
#include <vector>
#include "engine/leveldata.hpp"
#include "engine/resourcecontext.hpp"
#include "donutobject.hpp"
#include "ladderobject.hpp"
#include "platformobject.hpp"
#include "quadobject.hpp"
#include "vineobject.hpp"
#include "wallobject.hpp"

namespace Jumpman {

namespace Objects {

class Level {
 public:
  template <typename T>
  using ObjectRef = std::shared_ptr<T>;

  template <typename T>
  using ObjectIterator = typename std::vector<ObjectRef<T>>::const_iterator;

  explicit Level(const LevelData& data, ResourceContext& resource_context);

  const std::string main_script_tag;
  const std::string donut_script_tag;
  const std::string background_track_tag;
  const std::string death_track_tag;
  const std::string end_level_track_tag;

  size_t NumQuads() const;
  size_t NumDonuts() const;
  size_t NumPlatforms() const;
  size_t NumWalls() const;
  size_t NumLadders() const;
  size_t NumVines() const;

  ObjectIterator<QuadObject> GetQuads() const;
  ObjectIterator<DonutObject> GetDonuts() const;
  ObjectIterator<PlatformObject> GetPlatforms() const;
  ObjectIterator<WallObject> GetWalls() const;
  ObjectIterator<LadderObject> GetLadders() const;
  ObjectIterator<VineObject> GetVines() const;

  const ObjectRef<QuadObject> FindQuads(const std::string& tag) const;
  const ObjectRef<DonutObject> FindDonuts(const std::string& tag) const;
  const ObjectRef<PlatformObject> FindPlatforms(const std::string& tag) const;
  const ObjectRef<WallObject> FindWalls(const std::string& tag) const;
  const ObjectRef<LadderObject> FindLadders(const std::string& tag) const;
  const ObjectRef<VineObject> FindVines(const std::string& tag) const;

 private:
  template <typename T>
  using ObjectContainer = std::vector<ObjectRef<T>>;

  template <typename T>
  using TagObjectMap = std::unordered_map<std::string, std::weak_ptr<T>>;

  ObjectContainer<QuadObject> quads_;
  ObjectContainer<DonutObject> donuts_;
  ObjectContainer<PlatformObject> platforms_;
  ObjectContainer<WallObject> walls_;
  ObjectContainer<LadderObject> ladders_;
  ObjectContainer<VineObject> vines_;

  TagObjectMap<QuadObject> tag_to_quad_map_;
  TagObjectMap<DonutObject> tag_to_donut_map_;
  TagObjectMap<PlatformObject> tag_to_platform_map_;
  TagObjectMap<WallObject> tag_to_wall_map_;
  TagObjectMap<LadderObject> tag_to_ladder_map_;
  TagObjectMap<VineObject> tag_to_vine_map_;
};

};  // namespace Objects

};  // namespace Jumpman

#endif  // ENGINE_OBJECTS_LEVEL_HPP_
