#include "level.hpp"

namespace Jumpman {

namespace Objects {

Level::Level(const LevelData& data)
    : background_track_tag(data.background_track_tag)
    , death_track_tag(data.death_track_tag)
    , end_level_track_tag(data.end_level_track_tag) {
}

Level::ObjectRef<Level> Level::Load(
    const LevelData& data,
    std::function<void(sol::state&)> add_bindings_for_main_script,
    ResourceContext& resource_context) {
  Level::ObjectRef<Level> result(new Level(data));

  for (const TextureResourceData& texture_resource: data.textures) {
    resource_context.LoadTexture(
      texture_resource.filename, texture_resource.tag);
  }

  for (const MaterialResourceData& material_resource: data.materials) {
    auto material = resource_context.LoadMaterial(
      material_resource.vertex_shader_filename,
      material_resource.fragment_shader_filename,
      material_resource.tag);
    material->SetTexture(
      resource_context.FindTexture(material_resource.texture_tag));
  }

  for (const MeshResourceData& mesh_resource: data.meshes) {
    resource_context.LoadMesh(mesh_resource.filename, mesh_resource.tag);
  }

  for (const SoundResourceData& sound_resource: data.sounds) {
    resource_context.LoadSound(sound_resource.filename, sound_resource.tag);
  }

  // TODO: Load music

  result->quads_.reserve(data.quads.size());

  for (const QuadObjectData& quad: data.quads) {
    auto object = std::shared_ptr<QuadObject>(
      new QuadObject(quad, resource_context));

    result->quads_.push_back(object);

    if (!quad.tag.empty()) {
      result->tag_to_quad_map_[quad.tag] = object;
    }
  }

  result->donuts_.reserve(data.donuts.size());

  for (const DonutObjectData& donut: data.donuts) {
    auto object = std::shared_ptr<DonutObject>(
      new DonutObject(donut, resource_context));

    result->donuts_.push_back(object);

    if (!donut.tag.empty()) {
      result->tag_to_donut_map_[donut.tag] = object;
    }
  }

  result->platforms_.reserve(data.platforms.size());

  for (const PlatformObjectData& platform: data.platforms) {
    auto object = std::shared_ptr<PlatformObject>(
      new PlatformObject(platform, resource_context));

    result->platforms_.push_back(object);

    if (!platform.tag.empty()) {
      result->tag_to_platform_map_[platform.tag] = object;
    }
  }

  result->walls_.reserve(data.walls.size());

  for (const WallObjectData& wall: data.walls) {
    auto object = std::shared_ptr<WallObject>(
      new WallObject(wall, resource_context));

    result->walls_.push_back(object);

    if (!wall.tag.empty()) {
      result->tag_to_wall_map_[wall.tag] = object;
    }
  }

  result->ladders_.reserve(data.ladders.size());

  for (const LadderObjectData& ladder: data.ladders) {
    auto object = std::shared_ptr<LadderObject>(
      new LadderObject(ladder, resource_context));

    result->ladders_.push_back(object);

    if (!ladder.tag.empty()) {
      result->tag_to_ladder_map_[ladder.tag] = object;
    }
  }

  result->vines_.reserve(data.vines.size());

  for (const VineObjectData& vine: data.vines) {
    auto object = std::shared_ptr<VineObject>(
      new VineObject(vine, resource_context));

    result->vines_.push_back(object);

    if (!vine.tag.empty()) {
      result->tag_to_vine_map_[vine.tag] = object;
    }
  }

  // Loading scripts last so it can reference resources on initialization
  std::vector<std::string> script_dependency_filenames;
  script_dependency_filenames.reserve(data.scripts.size());

  for (const ScriptResourceData& script: data.scripts) {
    if (script.tag != data.main_script_tag) {
      script_dependency_filenames.push_back(script.filename);
    }
  }

  result->main_script_ = resource_context.LoadScripts(
    script_dependency_filenames,
    [&result, &add_bindings_for_main_script](sol::state& state) {
      state["jumpman"]["level"] = result;
      add_bindings_for_main_script(state);
    },
    data.main_script_filename,
    data.main_script_tag);

  return result;
}

Level::ObjectRef<LuaScript> Level::GetMainScript() {
  return main_script_;
}

size_t Level::NumQuads() const {
  return quads_.size();
}

size_t Level::NumDonuts() const {
  return donuts_.size();
}

size_t Level::NumPlatforms() const {
  return platforms_.size();
}

size_t Level::NumWalls() const {
  return walls_.size();
}

size_t Level::NumLadders() const {
  return ladders_.size();
}

size_t Level::NumVines() const {
  return vines_.size();
}

const Level::ObjectContainer<QuadObject>& Level::GetQuads() const {
  return quads_;
}

const Level::ObjectContainer<DonutObject>& Level::GetDonuts() const {
  return donuts_;
}

const Level::ObjectContainer<PlatformObject>& Level::GetPlatforms() const {
  return platforms_;
}

const Level::ObjectContainer<WallObject>& Level::GetWalls() const {
  return walls_;
}

const Level::ObjectContainer<LadderObject>& Level::GetLadders() const {
  return ladders_;
}

const Level::ObjectContainer<VineObject>& Level::GetVines() const {
  return vines_;
}

const Level::ObjectRef<QuadObject> Level::FindQuad(
    const std::string& tag) const {
  return tag_to_quad_map_.at(tag).lock();
}

const Level::ObjectRef<DonutObject> Level::FindDonut(
    const std::string& tag) const {
  return tag_to_donut_map_.at(tag).lock();
}

const Level::ObjectRef<PlatformObject> Level::FindPlatform(
    const std::string& tag) const {
  return tag_to_platform_map_.at(tag).lock();
}

const Level::ObjectRef<WallObject> Level::FindWall(
    const std::string& tag) const {
  return tag_to_wall_map_.at(tag).lock();
}

const Level::ObjectRef<LadderObject> Level::FindLadder(
    const std::string& tag) const {
  return tag_to_ladder_map_.at(tag).lock();
}

const Level::ObjectRef<VineObject> Level::FindVine(
    const std::string& tag) const {
  return tag_to_vine_map_.at(tag).lock();
}

};  // namespace Objects

};  // namespace Jumpman
