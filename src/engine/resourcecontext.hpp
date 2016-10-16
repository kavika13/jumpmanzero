#ifndef ENGINE_RESOURCECONTEXT_HPP_
#define ENGINE_RESOURCECONTEXT_HPP_

#include <memory>
#include <unordered_map>
#include <vector>
#include "luascript.hpp"
#include "material.hpp"
#include "texture.hpp"
#include "trianglemesh.hpp"

class ResourceContext {
 public:
  using ScriptFactory =
    std::function<std::shared_ptr<LuaScript>(const std::string&)>;

  ResourceContext(ScriptFactory script_factory);

  std::shared_ptr<LuaScript> LoadScript(
    const std::string& filename, const std::string& tag);
  std::shared_ptr<LuaScript> FindScript(const std::string& tag);

  std::shared_ptr<Texture> LoadTexture(
      const std::string& filename, const std::string& tag);
  std::shared_ptr<Texture> FindTexture(const std::string& tag);

  std::shared_ptr<Material> LoadMaterial(
      const std::string& vertex_shader_filename,
      const std::string& fragment_shader_filename,
      const std::string& tag);
  std::shared_ptr<Material> FindMaterial(const std::string& tag);

  std::shared_ptr<TriangleMesh> CreateMesh(
      const std::vector<Vertex>& vertices, const std::string& tag = "");

  std::shared_ptr<TriangleMesh> LoadMesh(
      const std::string& filename, const std::string& tag);
  std::shared_ptr<TriangleMesh> FindMesh(const std::string& tag);

  // TODO:
  // std::shared_ptr<Sound> LoadSound(const std::string& filename) {
  //   // TODO Implement
  // }

  // std::shared_ptr<Sound> FindSound(const std::string& tag) {
  //   return tag_to_sound_map_.at(tag);
  // }

  // TODO:
  // std::shared_ptr<Music> LoadMusic(const std::string& filename) {
  //   // TODO Implement
  // }

  // std::shared_ptr<Music> FindMusic(const std::string& tag) {
  //   return tag_to_music_map_.at(tag);
  // }

 private:
  const ScriptFactory script_factory_;

  std::vector<std::shared_ptr<LuaScript>> scripts_;
  std::vector<std::shared_ptr<Texture>> textures_;
  std::vector<std::shared_ptr<Material>> materials_;
  std::vector<std::shared_ptr<TriangleMesh>> meshes_;
  // TODO: std::vector<std::shared_ptr<Sound>> sounds_;
  // TODO: std::vector<std::shared_ptr<Music>> music_tracks_;

  std::unordered_map<std::string, std::weak_ptr<LuaScript>> tag_to_script_map_;
  std::unordered_map<std::string, std::weak_ptr<Texture>> tag_to_texture_map_;
  std::unordered_map<std::string, std::weak_ptr<Material>> tag_to_material_map_;
  std::unordered_map<std::string, std::weak_ptr<TriangleMesh>> tag_to_mesh_map_;
  // TODO: std::unordered_map<std::string, std::weak_ptr<Sound>> tag_to_sound_map_;
  // TODO:  std::unordered_map<std::string, std::weak_ptr<Music>> tag_to_music_map_;
};

#endif  // ENGINE_RESOURCECONTEXT_HPP_
