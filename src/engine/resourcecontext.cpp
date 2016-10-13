#include <fstream>
#define GL3_PROTOTYPES
#include <OpenGL/gl3.h>
#include "logging.hpp"
#include "meshdata.hpp"
#include "resourcecontext.hpp"
#include "shader.hpp"

std::shared_ptr<LuaScript> ResourceContext::LoadScript(
    const std::string& filename, const std::string& tag) {
  std::shared_ptr<LuaScript> script(new LuaScript(filename));

  scripts_.push_back(script);

  tag_to_script_map_[tag] = script;

  return script;
}

std::shared_ptr<LuaScript> ResourceContext::FindScript(const std::string& tag) {
  return tag_to_script_map_.at(tag).lock();
}

std::shared_ptr<Texture> ResourceContext::LoadTexture(
    const std::string& filename, const std::string& tag) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resources");
  // TODO: Check errors, do logging

  // TODO: Handle colorkey alpha in texture class
  std::shared_ptr<Texture> texture(new Texture);
  Image image(filename);

  glBindTexture(GL_TEXTURE_2D, *texture);
  SDL_Surface* image_data = image;

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

std::shared_ptr<Texture> ResourceContext::FindTexture(const std::string& tag) {
  return tag_to_texture_map_.at(tag).lock();
}

std::shared_ptr<Material> ResourceContext::LoadMaterial(
    const std::string& vertex_shader_filename,
    const std::string& fragment_shader_filename,
    const std::string& tag) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resources");

  std::ifstream vertexshaderfile(vertex_shader_filename);

  if (!vertexshaderfile) {
    std::string error_message =
      "Failed to open vertex shader file: " + vertex_shader_filename;
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  std::ifstream fragmentshaderfile(fragment_shader_filename);

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
  VertexShader vertex_shader(vertexshadersource);

  std::string fragmentshadersource;
  read_file_to_string(fragmentshaderfile, fragmentshadersource);
  FragmentShader fragment_shader(fragmentshadersource);

  std::shared_ptr<ShaderProgram> shader_program(
    new ShaderProgram(vertex_shader, fragment_shader));
  std::shared_ptr<Material> material(new Material(shader_program));

  tag_to_material_map_[tag] = material;

  materials_.push_back(material);

  return material;
}

std::shared_ptr<Material> ResourceContext::FindMaterial(
    const std::string& tag) {
  return tag_to_material_map_.at(tag).lock();
}

std::shared_ptr<TriangleMesh> ResourceContext::CreateMesh(
    const std::vector<Vertex>& vertices, const std::string& tag) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resources");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Generating mesh: " << tag;

  std::shared_ptr<TriangleMesh> mesh(new TriangleMesh(vertices));

  if (!tag.empty()) {
    tag_to_mesh_map_[tag] = mesh;
  }

  meshes_.push_back(mesh);

  return mesh;
}

std::shared_ptr<TriangleMesh> ResourceContext::LoadMesh(
    const std::string& filename, const std::string& tag) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resources");
  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Loading mesh: " << filename;

  std::ifstream mesh_file(filename);

  if (!mesh_file) {
    std::string error_message = "Failed to open mesh file: " + filename;
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  MeshData mesh_data(std::move(MeshData::FromStream(mesh_file)));
  std::vector<Vertex> vertices;
  vertices.reserve(mesh_data.vertices.size());

  for (const MeshVertexData& vertex: mesh_data.vertices) {
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

std::shared_ptr<TriangleMesh> ResourceContext::FindMesh(
    const std::string& tag) {
  return tag_to_mesh_map_.at(tag).lock();
}
