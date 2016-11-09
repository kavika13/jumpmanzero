#include <fstream>
#define GL3_PROTOTYPES
#include <OpenGL/gl3.h>
#include "engine/graphics/meshdata.hpp"
#include "engine/graphics/shader.hpp"
#include "logging.hpp"
#include "resourcecontext.hpp"

namespace Jumpman {

ResourceContext::ResourceContext(
  const std::string& resource_base_path,
  std::shared_ptr<Sound::System> sound_system)
    : resource_base_path_(resource_base_path)
    , sound_system_(sound_system) {
}

std::shared_ptr<Graphics::Texture> ResourceContext::LoadTexture(
    const std::string& filename,
    const std::string& tag,
    bool enable_colorkey_alpha,
    bool enable_alpha_blending) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resources");
  // TODO: Check errors, do logging

  // TODO: Move implementation to Texture class
  std::shared_ptr<Graphics::Texture> texture(new Graphics::Texture);
  texture->SetIsAlphaBlendingEnabled(enable_alpha_blending);

  Graphics::Image image(resource_base_path_ + filename, enable_colorkey_alpha);

  glBindTexture(GL_TEXTURE_2D, *texture);
  SDL_Surface* image_data = image;

  // TODO: Different filter functions?
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

  // TODO: Correct target pixel format based on what OpenGL/SDL tells us,
  // or whichever SDL functions do the right conversion without extra work
  glTexImage2D(
    GL_TEXTURE_2D, 0, GL_RGBA, image_data->w, image_data->h, 0,
    GL_BGRA, GL_UNSIGNED_BYTE, image_data->pixels);
  glGenerateMipmap(GL_TEXTURE_2D);

  glBindTexture(GL_TEXTURE_2D, 0);

  if (!tag.empty()) {
    tag_to_texture_map_[tag] = texture;
  }

  textures_.push_back(texture);

  return texture;
}

std::shared_ptr<Graphics::Texture> ResourceContext::FindTexture(
    const std::string& tag) {
  auto iter = tag_to_texture_map_.find(tag);
  if (iter == tag_to_texture_map_.end()) {
    throw std::runtime_error("Failed to find texture with tag: " + tag);
  }
  return iter->second.lock();
}

std::shared_ptr<Graphics::Material> ResourceContext::LoadMaterial(
    const std::string& vertex_shader_filename,
    const std::string& fragment_shader_filename,
    const std::string& tag) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resources");

  std::ifstream vertexshaderfile(resource_base_path_ + vertex_shader_filename);

  if (!vertexshaderfile) {
    std::string error_message =
      "Failed to open vertex shader file: " + vertex_shader_filename;
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  std::ifstream fragmentshaderfile(
    resource_base_path_ + fragment_shader_filename);

  if (!fragmentshaderfile) {
    std::string error_message =
      "Failed to open fragment shader file: " + fragment_shader_filename;
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  auto read_file_to_string = [](std::ifstream& file, std::string& source) {
    file.seekg(0, std::ios::end);
    source.resize(file.tellg());
    file.seekg(0, std::ios::beg);
    file.read(&source[0], source.size());
    file.close();
  };

  std::string vertexshadersource;
  read_file_to_string(vertexshaderfile, vertexshadersource);
  Graphics::VertexShader vertex_shader(vertexshadersource);

  std::string fragmentshadersource;
  read_file_to_string(fragmentshaderfile, fragmentshadersource);
  Graphics::FragmentShader fragment_shader(fragmentshadersource);

  std::shared_ptr<Graphics::ShaderProgram> shader_program(
    new Graphics::ShaderProgram(vertex_shader, fragment_shader));
  std::shared_ptr<Graphics::Material> material(
    new Graphics::Material(shader_program));

  tag_to_material_map_[tag] = material;

  materials_.push_back(material);

  return material;
}

std::shared_ptr<Graphics::Material> ResourceContext::FindMaterial(
    const std::string& tag) {
  auto iter = tag_to_material_map_.find(tag);
  if (iter == tag_to_material_map_.end()) {
    throw std::runtime_error("Failed to find material with tag: " + tag);
  }
  return iter->second.lock();
}

std::shared_ptr<Graphics::TriangleMesh> ResourceContext::CreateMesh(
    const std::vector<Graphics::Vertex>& vertices, const std::string& tag) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resources");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Generating mesh: " << tag;

  std::shared_ptr<Graphics::TriangleMesh> mesh(
    new Graphics::TriangleMesh(vertices));

  if (!tag.empty()) {
    tag_to_mesh_map_[tag] = mesh;
  }

  meshes_.push_back(mesh);

  return mesh;
}

std::shared_ptr<Graphics::TriangleMesh> ResourceContext::LoadMesh(
    const std::string& filename, const std::string& tag) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resources");
  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Loading mesh: " << filename;

  std::ifstream mesh_file(resource_base_path_ + filename);

  if (!mesh_file) {
    std::string error_message = "Failed to open mesh file: " + filename;
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  Graphics::MeshData mesh_data(
    std::move(Graphics::MeshData::FromStream(mesh_file)));
  std::vector<Graphics::Vertex> vertices;
  vertices.reserve(mesh_data.vertices.size());

  for (const Graphics::MeshVertexData& vertex: mesh_data.vertices) {
    vertices.push_back({
      vertex.x,
      vertex.y,
      vertex.z,
      vertex.nx,
      vertex.ny,
      vertex.nz,
      vertex.tu,
      vertex.tv,
    });
  }

  return CreateMesh(vertices, tag);
}

std::shared_ptr<Graphics::TriangleMesh> ResourceContext::FindMesh(
    const std::string& tag) {
  auto iter = tag_to_mesh_map_.find(tag);
  if (iter == tag_to_mesh_map_.end()) {
    throw std::runtime_error("Failed to find mesh with tag: " + tag);
  }
  return iter->second.lock();
}

std::shared_ptr<Sound::Sound> ResourceContext::LoadSound(
    const std::string& filename, const std::string& tag) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resources");
  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Loading sound: " << filename;

  std::ifstream sound_file(resource_base_path_ + filename);

  if (!sound_file) {
    const std::string error_message = "Failed to open sound file: " + filename;
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  auto sound = Sound::Sound::FromStream(*sound_system_, sound_file);

  if (!tag.empty()) {
    tag_to_sound_map_[tag] = sound;
  }

  sounds_.push_back(sound);

  return sound;
}

std::shared_ptr<Sound::Sound> ResourceContext::FindSound(
    const std::string& tag) {
  auto iter = tag_to_sound_map_.find(tag);
  if (iter == tag_to_sound_map_.end()) {
    throw std::runtime_error("Failed to find sound with tag: " + tag);
  }
  return iter->second.lock();
}

std::shared_ptr<Sound::MusicTrack> ResourceContext::LoadTrack(
    const std::string& filename, const std::string& tag) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resources");
  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Loading music track: " << filename;

  std::ifstream track_file(resource_base_path_ + filename);

  if (!track_file) {
    const std::string error_message = "Failed to open music track file: "
      + filename;
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  auto track = Sound::MusicTrack::FromStream(*sound_system_, track_file);

  if (!tag.empty()) {
    tag_to_track_map_[tag] = track;
  }

  music_tracks_.push_back(track);

  return track;
}

std::shared_ptr<Sound::MusicTrack> ResourceContext::FindTrack(
    const std::string& tag) {
  auto iter = tag_to_track_map_.find(tag);
  if (iter == tag_to_track_map_.end()) {
    throw std::runtime_error("Failed to find music track with tag: " + tag);
  }
  return iter->second.lock();
}

};  // namespace Jumpman
