#ifndef ENGINE_RESOURCECONTEXT_HPP_
#define ENGINE_RESOURCECONTEXT_HPP_

#include <memory>
#include <unordered_map>
#include <vector>
#include "engine/graphics/material.hpp"
#include "engine/graphics/texture.hpp"
#include "engine/graphics/trianglemesh.hpp"
#include "engine/sound/musictrack.hpp"
#include "engine/sound/sound.hpp"
#include "engine/sound/system.hpp"
#include "luascript.hpp"

namespace Jumpman {

class ResourceContext {
 public:
  using ScriptFactory = std::function<std::shared_ptr<LuaScript>()>;

  ResourceContext(
    std::shared_ptr<Sound::System> sound_system, ScriptFactory script_factory);

  std::shared_ptr<LuaScript> LoadScript(
    const std::string& filename, const std::string& tag);
  std::shared_ptr<LuaScript> LoadScript(
    std::function<void(sol::state&)> add_bindings_for_main_script,
    const std::string& filename,
    const std::string& tag);
  std::shared_ptr<LuaScript> LoadScripts(
    const std::vector<std::string>& script_dependency_filenames,
    std::function<void(sol::state&)> add_bindings_for_main_script,
    const std::string& main_script_filename,
    const std::string& tag);
  std::shared_ptr<LuaScript> FindScript(const std::string& tag);

  std::shared_ptr<Graphics::Texture> LoadTexture(
    const std::string& filename,
    const std::string& tag,
    bool enable_colorkey_alpha = false);
  std::shared_ptr<Graphics::Texture> FindTexture(const std::string& tag);

  std::shared_ptr<Graphics::Material> LoadMaterial(
    const std::string& vertex_shader_filename,
    const std::string& fragment_shader_filename,
    const std::string& tag);
  std::shared_ptr<Graphics::Material> FindMaterial(const std::string& tag);

  std::shared_ptr<Graphics::TriangleMesh> CreateMesh(
    const std::vector<Graphics::Vertex>& vertices, const std::string& tag = "");

  std::shared_ptr<Graphics::TriangleMesh> LoadMesh(
    const std::string& filename, const std::string& tag);
  std::shared_ptr<Graphics::TriangleMesh> FindMesh(const std::string& tag);

  std::shared_ptr<Sound::Sound> LoadSound(
    const std::string& filename, const std::string& tag);
  std::shared_ptr<Sound::Sound> FindSound(const std::string& tag);

  std::shared_ptr<Sound::MusicTrack> LoadTrack(
    const std::string& filename, const std::string& tag);
  std::shared_ptr<Sound::MusicTrack> FindTrack(const std::string& tag);

 private:
  std::shared_ptr<Sound::System> sound_system_;
  const ScriptFactory script_factory_;

  std::vector<std::shared_ptr<LuaScript>> scripts_;
  std::vector<std::shared_ptr<Graphics::Texture>> textures_;
  std::vector<std::shared_ptr<Graphics::Material>> materials_;
  std::vector<std::shared_ptr<Graphics::TriangleMesh>> meshes_;
  std::vector<std::shared_ptr<Sound::Sound>> sounds_;
  std::vector<std::shared_ptr<Sound::MusicTrack>> music_tracks_;

  std::unordered_map<std::string, std::weak_ptr<LuaScript>> tag_to_script_map_;
  std::unordered_map<std::string, std::weak_ptr<Graphics::Texture>>
    tag_to_texture_map_;
  std::unordered_map<std::string, std::weak_ptr<Graphics::Material>>
    tag_to_material_map_;
  std::unordered_map<std::string, std::weak_ptr<Graphics::TriangleMesh>>
    tag_to_mesh_map_;
  std::unordered_map<std::string, std::weak_ptr<Sound::Sound>>
    tag_to_sound_map_;
  std::unordered_map<std::string, std::weak_ptr<Sound::MusicTrack>>
    tag_to_track_map_;
};

};  // namespace Jumpman

#endif  // ENGINE_RESOURCECONTEXT_HPP_
