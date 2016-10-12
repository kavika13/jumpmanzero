#ifndef ENGINE_RESOURCECONTEXT_HPP_
#define ENGINE_RESOURCECONTEXT_HPP_

#include <memory>
#include <unordered_map>
#include <vector>
#include "material.hpp"
#include "texture.hpp"
#include "trianglemesh.hpp"

class ResourceContext {
 public:
  // TODO:
  // std::weak_ptr<Script> LoadScript(const std::string& filename) {
  //   // TODO Implement
  // }

  // std::weak_ptr<Script> FindScript(const std::string& tag) {
  //   return tag_to_script_map_.at(tag);
  // }

  std::weak_ptr<Texture> LoadTexture(
      const std::string& filename, const std::string& tag = "");

  std::weak_ptr<Texture> FindTexture(const std::string& tag);

  std::weak_ptr<Material> LoadMaterial(
      const std::string& vertex_shader_filename,
      const std::string& fragment_shader_filename,
      const std::string& tag);
  std::weak_ptr<Material> FindMaterial(const std::string& tag);

  std::weak_ptr<TriangleMesh> CreateMesh(
      const std::vector<Vertex>& vertices, const std::string& tag = "");

  std::weak_ptr<TriangleMesh> LoadMesh(
      const std::string& filename, const std::string& tag = "");
  std::weak_ptr<TriangleMesh> FindMesh(const std::string& tag);

  // TODO:
  // std::weak_ptr<Sound> LoadSound(const std::string& filename) {
  //   // TODO Implement
  // }

  // std::weak_ptr<Sound> FindSound(const std::string& tag) {
  //   return tag_to_sound_map_.at(tag);
  // }

  // TODO:
  // std::weak_ptr<Music> LoadMusic(const std::string& filename) {
  //   // TODO Implement
  // }

  // std::weak_ptr<Music> FindMusic(const std::string& tag) {
  //   return tag_to_music_map_.at(tag);
  // }

 private:
  // TODO: std::vector<std::shared_ptr<Script>> scripts_;
  std::vector<std::shared_ptr<Texture>> textures_;
  std::vector<std::shared_ptr<Material>> materials_;
  std::vector<std::shared_ptr<TriangleMesh>> meshes_;
  // TODO: std::vector<std::shared_ptr<Sound>> sounds_;
  // TODO: std::vector<std::shared_ptr<Music>> music_tracks_;

  // TODO: std::unordered_map<std::string, std::weak_ptr<Script>> tag_to_script_map_;
  std::unordered_map<std::string, std::weak_ptr<Texture>> tag_to_texture_map_;
  std::unordered_map<std::string, std::weak_ptr<Material>> tag_to_material_map_;
  std::unordered_map<std::string, std::weak_ptr<TriangleMesh>> tag_to_mesh_map_;
  // TODO: std::unordered_map<std::string, std::weak_ptr<Sound>> tag_to_sound_map_;
  // TODO:  std::unordered_map<std::string, std::weak_ptr<Music>> tag_to_music_map_;
};

#endif  // ENGINE_RESOURCECONTEXT_HPP_
