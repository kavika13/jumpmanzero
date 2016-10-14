#include "level.hpp"

namespace Jumpman {

namespace Objects {

Level::Level(const LevelData& data, ResourceContext& resource_context)
    : main_script_tag(data.main_script_tag)
    , donut_script_tag(data.donut_script_tag)
    , background_track_tag(data.background_track_tag)
    , death_track_tag(data.death_track_tag)
    , end_level_track_tag(data.end_level_track_tag) {
  // TODO: Load scripts

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

  // TODO: Load sounds

  // TODO: Load music

  quads_.reserve(data.quads.size());

  for (const QuadObjectData& quad: data.quads) {
    quads_.push_back(
      std::shared_ptr<QuadObject>(new QuadObject(quad, resource_context)));
  }

  donuts_.reserve(data.donuts.size());

  for (const DonutObjectData& donut: data.donuts) {
    donuts_.push_back(
      std::shared_ptr<DonutObject>(new DonutObject(donut, resource_context)));
  }

  platforms_.reserve(data.platforms.size());

  for (const PlatformObjectData& platform: data.platforms) {
    platforms_.push_back(
      std::shared_ptr<PlatformObject>(
        new PlatformObject(platform, resource_context)));
  }

  walls_.reserve(data.walls.size());

  for (const WallObjectData& wall: data.walls) {
    walls_.push_back(
      std::shared_ptr<WallObject>(new WallObject(wall, resource_context)));
  }

  ladders_.reserve(data.ladders.size());

  for (const LadderObjectData& ladder: data.ladders) {
    ladders_.push_back(
      std::shared_ptr<LadderObject>(
        new LadderObject(ladder, resource_context)));
  }

  vines_.reserve(data.vines.size());

  for (const VineObjectData& vine: data.vines) {
    vines_.push_back(
      std::shared_ptr<VineObject>(new VineObject(vine, resource_context)));
  }
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

Level::ObjectIterator<QuadObject> Level::GetQuads() const {
  return quads_.begin();
}

Level::ObjectIterator<DonutObject> Level::GetDonuts() const {
  return donuts_.begin();
}

Level::ObjectIterator<PlatformObject> Level::GetPlatforms() const {
  return platforms_.begin();
}

Level::ObjectIterator<WallObject> Level::GetWalls() const {
  return walls_.begin();
}

Level::ObjectIterator<LadderObject> Level::GetLadders() const {
  return ladders_.begin();
}

Level::ObjectIterator<VineObject> Level::GetVines() const {
  return vines_.begin();
}

const Level::ObjectRef<QuadObject> Level::FindQuads(
    const std::string& tag) const {
  return tag_to_quad_map_.at(tag).lock();
}

const Level::ObjectRef<DonutObject> Level::FindDonuts(
    const std::string& tag) const {
  return tag_to_donut_map_.at(tag).lock();
}

const Level::ObjectRef<PlatformObject> Level::FindPlatforms(
    const std::string& tag) const {
  return tag_to_platform_map_.at(tag).lock();
}

const Level::ObjectRef<WallObject> Level::FindWalls(
    const std::string& tag) const {
  return tag_to_wall_map_.at(tag).lock();
}

const Level::ObjectRef<LadderObject> Level::FindLadders(
    const std::string& tag) const {
  return tag_to_ladder_map_.at(tag).lock();
}

const Level::ObjectRef<VineObject> Level::FindVines(
    const std::string& tag) const {
  return tag_to_vine_map_.at(tag).lock();
}

};  // namespace Objects

};  // namespace Jumpman
