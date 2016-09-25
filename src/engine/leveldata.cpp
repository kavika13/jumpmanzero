#include <json/json.h>
#include "leveldata.hpp"
#include "logging.hpp"

bool operator==(const ScriptResourceData& lhs, const ScriptResourceData& rhs) {
  return lhs.filename == rhs.filename && lhs.tag == rhs.tag;
}

std::ostream& operator<<(std::ostream& stream, const ScriptResourceData& val) {
  stream << "filename: " << val.filename << " - tag: " << val.tag;
  return stream;
}

bool operator==(const MeshResourceData& lhs, const MeshResourceData& rhs) {
  return lhs.filename == rhs.filename && lhs.tag == rhs.tag;
}

std::ostream& operator<<(std::ostream& stream, const MeshResourceData& val) {
  stream << "filename: " << val.filename << " - tag: " << val.tag;
  return stream;
}

bool operator==(
    const TextureResourceData& lhs, const TextureResourceData& rhs) {
  return lhs.filename == rhs.filename
    && lhs.tag == rhs.tag
    && lhs.has_colorkey_alpha == rhs.has_colorkey_alpha
    && lhs.has_alpha_channel == rhs.has_alpha_channel;
}

std::ostream& operator<<(std::ostream& stream, const TextureResourceData& val) {
  stream << "filename: " << val.filename
    << " - tag: " << val.tag
    << " - has_colorkey_alpha: " << val.has_colorkey_alpha
    << " - has_alpha_channel: " << val.has_alpha_channel;
  return stream;
}

bool operator==(const MusicResourceData& lhs, const MusicResourceData& rhs) {
  return lhs.filename == rhs.filename
    && lhs.tag == rhs.tag
    && lhs.intro_end_offset_ms == rhs.intro_end_offset_ms;
}

std::ostream& operator<<(std::ostream& stream, const MusicResourceData& val) {
  stream
    << "filename: " << val.filename
    << " - tag: " << val.tag
    << " - intro_end_offset_ms: " << val.intro_end_offset_ms;
  return stream;
}

bool operator==(const SoundResourceData& lhs, const SoundResourceData& rhs) {
  return lhs.filename == rhs.filename && lhs.tag == rhs.tag;
}

std::ostream& operator<<(std::ostream& stream, const SoundResourceData& val) {
  stream << "filename: " << val.filename << " - tag: " << val.tag;
  return stream;
}

bool operator==(const VertexData& lhs, const VertexData& rhs) {
    return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
      && lhs.tu == rhs.tu && lhs.tv == rhs.tv;
}

std::ostream& operator<<(std::ostream& stream, const VertexData& val) {
  stream << "x: " << val.x << " - y: " << val.y << " - z: " << val.z
    << " - tu: " << val.tu << " - tv: " << val.tv;
  return stream;
}

bool operator==(const QuadObjectData& lhs, const QuadObjectData& rhs) {
  return lhs.tag == rhs.tag
    && lhs.texture_tag == rhs.texture_tag
    && lhs.origin_x == rhs.origin_x
    && lhs.origin_y == rhs.origin_y
    && lhs.vertices[0] == rhs.vertices[0]
    && lhs.vertices[1] == rhs.vertices[1]
    && lhs.vertices[2] == rhs.vertices[2]
    && lhs.vertices[3] == rhs.vertices[3];
}

std::ostream& operator<<(std::ostream& stream, const QuadObjectData& val) {
  stream << "tag: " << val.tag
    << " - texture_tag: " << val.texture_tag
    << " - origin_x: " << val.origin_x
    << " - origin_y: " << val.origin_y
    << " - vertices[0]: " << val.vertices[0]
    << " - vertices[1]: " << val.vertices[1]
    << " - vertices[2]: " << val.vertices[2]
    << " - vertices[3]: " << val.vertices[3];
  return stream;
}

LevelData LevelData::FromStream(std::istream& stream) {
  Json::Value root_node;
  stream >> root_node;

  std::string main_script_tag = root_node["mainScriptTag"].asString();
  std::string donut_script_tag = root_node["donutScriptTag"].asString();
  std::string background_track_tag = root_node["backgroundTrackTag"].asString();
  std::string death_track_tag = root_node["deathTrackTag"].asString();
  std::string end_level_track_tag = root_node["endLevelTrackTag"].asString();

  Json::Value resources_node = root_node["resources"];

  Json::Value scripts_node = resources_node["scripts"];
  Json::Value meshes_node = resources_node["meshes"];
  Json::Value textures_node = resources_node["textures"];
  Json::Value music_node = resources_node["music"];
  Json::Value sounds_node = resources_node["sounds"];

  std::vector<ScriptResourceData> scripts;
  for (const auto& script_node: scripts_node) {
    scripts.push_back({
      script_node["filename"].asString(),
      script_node["tag"].asString(),
    });
  }

  std::vector<MeshResourceData> meshes;
  for (const auto& mesh_node: meshes_node) {
    meshes.push_back({
      mesh_node["filename"].asString(),
      mesh_node["tag"].asString(),
    });
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
  // TODO: Other objects

  std::vector<QuadObjectData> quads;
  for (const auto& quad_node: quads_node) {
    Json::Value vertices_node = quad_node["vertices"];

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

    quads.push_back({
      quad_node["tag"].asString(),
      quad_node["textureTag"].asString(),
      quad_node["originX"].asFloat(),
      quad_node["originY"].asFloat(),
      {
        vertices_data[0],
        vertices_data[1],
        vertices_data[2],
        vertices_data[3],
      },
    });
  }
  // TODO: Other objects

  return LevelData {
    main_script_tag,
    donut_script_tag,
    background_track_tag,
    death_track_tag,
    end_level_track_tag,

    scripts,
    meshes,
    textures,
    music,
    sounds,

    quads,
    // TODO: Other objects
  };
}

std::ostream& operator<<(std::ostream& stream, const LevelData& data) {
  Json::Value root_node;

  root_node["mainScriptTag"] = data.main_script_tag;
  root_node["donutScriptTag"] = data.donut_script_tag;
  root_node["backgroundTrackTag"] = data.background_track_tag;
  root_node["deathTrackTag"] = data.death_track_tag;
  root_node["endLevelTrackTag"] = data.end_level_track_tag;

  Json::Value resources_node(Json::objectValue);
  root_node["resources"] = resources_node;

  Json::Value scripts_node(Json::arrayValue);
  resources_node["scripts"] = scripts_node;
  Json::Value meshes_node(Json::arrayValue);
  resources_node["meshes"] = meshes_node;
  Json::Value textures_node(Json::arrayValue);
  resources_node["textures"] = textures_node;
  Json::Value music_node(Json::arrayValue);
  resources_node["music"] = music_node;
  Json::Value sounds_node(Json::arrayValue);
  resources_node["sounds"] = sounds_node;

  for (const auto& script: data.scripts) {
    Json::Value script_node(Json::objectValue);
    script_node["filename"] = script.filename;
    script_node["tag"] = script.tag;
    scripts_node.append(script_node);
  }

  for (const auto& mesh: data.meshes) {
    Json::Value mesh_node(Json::objectValue);
    mesh_node["filename"] = mesh.filename;
    mesh_node["tag"] = mesh.tag;
    meshes_node.append(mesh_node);
  }

  for (const auto& texture: data.textures) {
    Json::Value texture_node(Json::objectValue);
    texture_node["filename"] = texture.filename;
    texture_node["tag"] = texture.tag;
    texture_node["hasColorkeyAlpha"] = texture.has_colorkey_alpha;
    texture_node["hasAlphaChannel"] = texture.has_alpha_channel;
    textures_node.append(texture_node);
  }

  for (const auto& track: data.music) {
    Json::Value track_node(Json::objectValue);
    track_node["filename"] = track.filename;
    track_node["tag"] = track.tag;
    if (track.intro_end_offset_ms) {
      track_node["introEndOffsetMS"] = track.intro_end_offset_ms;
    }
    music_node.append(track_node);
  }

  for (const auto& sound: data.sounds) {
    Json::Value sound_node(Json::objectValue);
    sound_node["filename"] = sound.filename;
    sound_node["tag"] = sound.tag;
    sounds_node.append(sound_node);
  }

  Json::Value objects_node(Json::objectValue);
  root_node["objects"] = objects_node;

  Json::Value quads_node(Json::arrayValue);
  resources_node["quads"] = quads_node;
  // TODO: Other objects

  for (const auto& quad: data.quads) {
    Json::Value quad_node(Json::objectValue);

    quad_node["tag"] = quad.tag;
    quad_node["textureTag"] = quad.texture_tag;

    quad_node["originX"] = quad.origin_x;
    quad_node["originY"] = quad.origin_y;

    Json::Value vertices_node(Json::arrayValue);
    resources_node["vertices"] = vertices_node;

    for (const auto& vertex: quad.vertices) {
      Json::Value vertex_node(Json::arrayValue);
      vertex_node["x"] = vertex.x;
      vertex_node["y"] = vertex.y;
      vertex_node["z"] = vertex.z;
      vertex_node["tu"] = vertex.tu;
      vertex_node["tv"] = vertex.tv;
      vertices_node.append(vertex_node);
    }

    quads_node.append(quad_node);
  }
  // TODO: Other objects

  stream << root_node;

  return stream;
}
