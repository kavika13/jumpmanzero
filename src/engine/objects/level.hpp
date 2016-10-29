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
  using ObjectContainer = std::vector<ObjectRef<T>>;

  static ObjectRef<Level> Load(
    const LevelData& data,
    std::function<void(sol::state&)> add_bindings_for_main_script,
    ResourceContext& resource_context);

  const std::string background_track_tag;
  const std::string death_track_tag;
  const std::string end_level_track_tag;

  ObjectRef<LuaScript> GetMainScript();

  size_t NumQuads() const;
  size_t NumDonuts() const;
  size_t NumPlatforms() const;
  size_t NumWalls() const;
  size_t NumLadders() const;
  size_t NumVines() const;

  const ObjectContainer<QuadObject>& GetQuads() const;
  const ObjectContainer<DonutObject>& GetDonuts() const;
  const ObjectContainer<PlatformObject>& GetPlatforms() const;
  const ObjectContainer<WallObject>& GetWalls() const;
  const ObjectContainer<LadderObject>& GetLadders() const;
  const ObjectContainer<VineObject>& GetVines() const;

  const ObjectRef<QuadObject> FindQuad(const std::string& tag) const;
  const ObjectRef<DonutObject> FindDonut(const std::string& tag) const;
  const ObjectRef<PlatformObject> FindPlatform(const std::string& tag) const;
  const ObjectRef<WallObject> FindWall(const std::string& tag) const;
  const ObjectRef<LadderObject> FindLadder(const std::string& tag) const;
  const ObjectRef<VineObject> FindVine(const std::string& tag) const;

 private:
  explicit Level(const LevelData& data);

  template <typename T>
  using TagObjectMap = std::unordered_map<std::string, std::weak_ptr<T>>;

  ObjectRef<LuaScript> main_script_;

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
