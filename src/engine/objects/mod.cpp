#include "mod.hpp"

namespace Jumpman {

namespace Objects {

Mod::Mod(const ModData& data)
    : background_track_tag(data.background_track_tag) {
}

std::shared_ptr<Mod> Mod::Load(
    const ModData& data, ResourceContext& resource_context) {
  std::shared_ptr<Mod> result(new Mod(data));

  for (const TextureResourceData& texture_resource: data.textures) {
    resource_context.LoadTexture(
      texture_resource.filename,
      texture_resource.tag,
      texture_resource.has_colorkey_alpha,
      texture_resource.has_alpha_channel);
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

  for (const MusicResourceData& track_resource: data.music) {
    resource_context.LoadTrack(track_resource.filename, track_resource.tag);
  }

  result->quads_.reserve(data.quads.size());

  for (const QuadObjectData& quad: data.quads) {
    auto object = std::shared_ptr<QuadObject>(
      new QuadObject(quad, resource_context));

    result->quads_.push_back(object);

    if (!quad.tag.empty()) {
      result->tag_to_quad_map_[quad.tag] = object;
    }
  }

  return result;
}

size_t Mod::NumQuads() const {
  return quads_.size();
}

const Mod::ObjectContainer<QuadObject>& Mod::GetQuads() const {
  return quads_;
}

const std::shared_ptr<QuadObject> Mod::FindQuad(const std::string& tag) const {
  return tag_to_quad_map_.at(tag).lock();
}

};  // namespace Objects

};  // namespace Jumpman
