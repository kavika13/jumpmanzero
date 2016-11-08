#include "resourcedataserialization.hpp"
#include "logging.hpp"

namespace Jumpman {

ResourceData DeserializeResourceData(const Json::Value& root_node) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Reading resource data from json";

  std::string main_script_tag = root_node["mainScriptTag"].asString();
  std::string background_track_tag = root_node["backgroundTrackTag"].asString();

  Json::Value resources_node = root_node["resources"];

  Json::Value scripts_node = resources_node["scripts"];
  Json::Value textures_node = resources_node["textures"];
  Json::Value materials_node = resources_node["materials"];
  Json::Value meshes_node = resources_node["meshes"];
  Json::Value music_node = resources_node["music"];
  Json::Value sounds_node = resources_node["sounds"];

  std::vector<ScriptResourceData> scripts;
  std::string main_script_filename;
  bool was_main_script_found = false;

  for (const auto& script_node: scripts_node) {
    const std::string script_filename(script_node["filename"].asString());
    const std::string script_tag(script_node["tag"].asString());

    if (script_tag == main_script_tag) {
      main_script_filename = script_filename;
      was_main_script_found = true;
    }

    scripts.push_back({
      script_filename,
      script_tag,
    });
  }

  if (!was_main_script_found) {
    const std::string error_message(
      "Failed to find script that has main script tag");
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  std::vector<TextureResourceData> textures;
  for (const auto& texture_node: textures_node) {
    textures.push_back({
      texture_node["filename"].asString(),
      texture_node["tag"].asString(),
      texture_node.get("hasColorkeyAlpha", false).asBool(),
      texture_node.get("hasAlphaChannel", false).asBool(),
    });
  }

  std::vector<MaterialResourceData> materials;
  for (const auto& material_node: materials_node) {
    materials.push_back({
      material_node["vertexShaderFilename"].asString(),
      material_node["fragmentShaderFilename"].asString(),
      material_node["tag"].asString(),
      material_node["textureTag"].asString(),
    });
  }

  std::vector<MeshResourceData> meshes;
  for (const auto& mesh_node: meshes_node) {
    meshes.push_back({
      mesh_node["filename"].asString(),
      mesh_node["tag"].asString(),
    });
  }

  std::vector<MusicResourceData> music;
  for (const auto& track_node: music_node) {
    music.push_back({
      track_node["filename"].asString(),
      track_node["tag"].asString(),
      track_node.get("introEndOffsetMS", 0).asUInt(),
    });
  }

  std::vector<SoundResourceData> sounds;
  for (const auto& sound_node: sounds_node) {
    sounds.push_back({
      sound_node["filename"].asString(),
      sound_node["tag"].asString(),
    });
  }

  Json::Value objects_node = root_node["objects"];

  Json::Value quads_node = objects_node["quads"];

  auto extract_vertices_node = [](const Json::Value& object_node) {
    Json::Value vertices_node = object_node["vertices"];

    std::vector<VertexData> vertices_data;
    for (const auto& vertex_node: vertices_node) {
      vertices_data.push_back({
        vertex_node["x"].asFloat(),
        vertex_node["y"].asFloat(),
        vertex_node["z"].asFloat(),
        vertex_node["tu"].asFloat(),
        vertex_node["tv"].asFloat(),
      });
    }

    return vertices_data;
  };

  std::vector<QuadObjectData> quads;
  for (const auto& quad_node: quads_node) {
    std::vector<VertexData> vertices_data = extract_vertices_node(quad_node);

    quads.push_back({
      quad_node.get("tag", "").asString(),
      quad_node["materialTag"].asString(),
      quad_node["originX"].asFloat(),
      quad_node["originY"].asFloat(),
      quad_node["originZ"].asFloat(),
      {
        vertices_data[0],
        vertices_data[1],
        vertices_data[2],
        vertices_data[3],
      },
    });
  }

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished reading resource data from json";

  return ResourceData {
    main_script_tag,
    main_script_filename,
    background_track_tag,

    scripts,
    textures,
    materials,
    meshes,
    music,
    sounds,

    quads,
  };
}

Json::Value SerializeResourceData(const ResourceData& data) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Writing resource data to json";

  Json::Value root_node;

  root_node["mainScriptTag"] = data.main_script_tag;
  root_node["backgroundTrackTag"] = data.background_track_tag;

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Set root node data:\n"
    << root_node;

  Json::Value resources_node(Json::objectValue);
  Json::Value scripts_node(Json::arrayValue);
  Json::Value textures_node(Json::arrayValue);
  Json::Value materials_node(Json::arrayValue);
  Json::Value meshes_node(Json::arrayValue);
  Json::Value music_node(Json::arrayValue);
  Json::Value sounds_node(Json::arrayValue);

  for (const auto& script: data.scripts) {
    Json::Value script_node(Json::objectValue);
    script_node["filename"] = script.filename;
    script_node["tag"] = script.tag;
    scripts_node.append(script_node);
    BOOST_LOG_SEV(log, LogSeverity::kTrace)
      << "Added script node:\n"
      << script_node;
  }

  for (const auto& texture: data.textures) {
    Json::Value texture_node(Json::objectValue);
    texture_node["filename"] = texture.filename;
    texture_node["tag"] = texture.tag;
    texture_node["hasColorkeyAlpha"] = texture.has_colorkey_alpha;
    texture_node["hasAlphaChannel"] = texture.has_alpha_channel;
    textures_node.append(texture_node);
    BOOST_LOG_SEV(log, LogSeverity::kTrace)
      << "Added texture node:\n"
      << texture_node;
  }

  for (const auto& material: data.materials) {
    Json::Value material_node(Json::objectValue);
    material_node["vertexShaderFilename"] = material.vertex_shader_filename;
    material_node["fragmentShaderFilename"] = material.fragment_shader_filename;
    material_node["tag"] = material.tag;
    material_node["textureTag"] = material.texture_tag;
    materials_node.append(material_node);
    BOOST_LOG_SEV(log, LogSeverity::kTrace)
      << "Added material node:\n"
      << material_node;
  }

  for (const auto& mesh: data.meshes) {
    Json::Value mesh_node(Json::objectValue);
    mesh_node["filename"] = mesh.filename;
    mesh_node["tag"] = mesh.tag;
    meshes_node.append(mesh_node);
    BOOST_LOG_SEV(log, LogSeverity::kTrace)
      << "Added mesh node:\n"
      << mesh_node;
  }

  for (const auto& track: data.music) {
    Json::Value track_node(Json::objectValue);
    track_node["filename"] = track.filename;
    track_node["tag"] = track.tag;
    if (track.intro_end_offset_ms) {
      track_node["introEndOffsetMS"] = track.intro_end_offset_ms;
    }
    music_node.append(track_node);
    BOOST_LOG_SEV(log, LogSeverity::kTrace)
      << "Added music node:\n"
      << track_node;
  }

  for (const auto& sound: data.sounds) {
    Json::Value sound_node(Json::objectValue);
    sound_node["filename"] = sound.filename;
    sound_node["tag"] = sound.tag;
    sounds_node.append(sound_node);
    BOOST_LOG_SEV(log, LogSeverity::kTrace)
      << "Added sound node:\n"
      << sound_node;
  }

  resources_node["scripts"] = scripts_node;
  resources_node["textures"] = textures_node;
  resources_node["materials"] = materials_node;
  resources_node["meshes"] = meshes_node;
  resources_node["music"] = music_node;
  resources_node["sounds"] = sounds_node;
  root_node["resources"] = resources_node;

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Added resources node:\n"
    << resources_node;

  Json::Value objects_node(Json::objectValue);
  Json::Value quads_node(Json::arrayValue);

  auto create_vertex_node = [](const VertexData& vertex) {
    Json::Value vertex_node(Json::objectValue);
    vertex_node["x"] = vertex.x;
    vertex_node["y"] = vertex.y;
    vertex_node["z"] = vertex.z;
    vertex_node["tu"] = vertex.tu;
    vertex_node["tv"] = vertex.tv;
    return vertex_node;
  };

  for (const auto& quad: data.quads) {
    Json::Value quad_node(Json::objectValue);

    if (!quad.tag.empty()) {
      quad_node["tag"] = quad.tag;
    }

    quad_node["materialTag"] = quad.material_tag;

    quad_node["originX"] = quad.origin_x;
    quad_node["originY"] = quad.origin_y;
    quad_node["originZ"] = quad.origin_z;

    Json::Value vertices_node(Json::arrayValue);
    for (const auto& vertex: quad.vertices) {
      vertices_node.append(create_vertex_node(vertex));
    }
    quad_node["vertices"] = vertices_node;

    quads_node.append(quad_node);

    BOOST_LOG_SEV(log, LogSeverity::kTrace)
      << "Added quad node:\n"
      << quad_node;
  }

  objects_node["quads"] = quads_node;
  root_node["objects"] = objects_node;

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Added objects node:\n"
    << objects_node;

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished writing resource data to json";

  return root_node;
}

};  // namespace Jumpman
