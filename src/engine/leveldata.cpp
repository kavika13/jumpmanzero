#include <unordered_map>
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

bool operator==(
    const MaterialResourceData& lhs,
    const MaterialResourceData& rhs) {
  return lhs.vertex_shader_filename == rhs.vertex_shader_filename
    && lhs.fragment_shader_filename == rhs.fragment_shader_filename
    && lhs.tag == rhs.tag
    && lhs.texture_tag == rhs.texture_tag;
}

std::ostream& operator<<(
    std::ostream& stream,
    const MaterialResourceData& val) {
  stream << "vertex_shader_filename: " << val.vertex_shader_filename
    << " - fragment_shader_filename: " << val.fragment_shader_filename
    << " - tag: " << val.tag
    << " - texture_tag: " << val.texture_tag;
  return stream;
}

bool operator==(const MeshResourceData& lhs, const MeshResourceData& rhs) {
  return lhs.filename == rhs.filename
    && lhs.tag == rhs.tag;
}

std::ostream& operator<<(std::ostream& stream, const MeshResourceData& val) {
  stream << "filename: " << val.filename
    << " - tag: " << val.tag;
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
    && lhs.material_tag == rhs.material_tag
    && lhs.origin_x == rhs.origin_x
    && lhs.origin_y == rhs.origin_y
    && lhs.vertices[0] == rhs.vertices[0]
    && lhs.vertices[1] == rhs.vertices[1]
    && lhs.vertices[2] == rhs.vertices[2]
    && lhs.vertices[3] == rhs.vertices[3];
}

std::ostream& operator<<(std::ostream& stream, const QuadObjectData& val) {
  stream << "tag: " << val.tag
    << " - material_tag: " << val.material_tag
    << " - origin_x: " << val.origin_x
    << " - origin_y: " << val.origin_y
    << " - vertices[0]: " << val.vertices[0]
    << " - vertices[1]: " << val.vertices[1]
    << " - vertices[2]: " << val.vertices[2]
    << " - vertices[3]: " << val.vertices[3];
  return stream;
}

bool operator==(const DonutObjectData& lhs, const DonutObjectData& rhs) {
  return lhs.tag == rhs.tag
    && lhs.material_tag == rhs.material_tag
    && lhs.origin_x == rhs.origin_x
    && lhs.origin_y == rhs.origin_y
    && lhs.origin_z == rhs.origin_z;
}

std::ostream& operator<<(std::ostream& stream, const DonutObjectData& val) {
  stream << "tag: " << val.tag
    << " - material_tag: " << val.material_tag
    << " - origin_x: " << val.origin_x
    << " - origin_y: " << val.origin_y
    << " - origin_z: " << val.origin_z;
  return stream;
}

bool operator==(const PlatformObjectData& lhs, const PlatformObjectData& rhs) {
  return lhs.tag == rhs.tag
    && lhs.material_tag == rhs.material_tag
    && lhs.drawtop == rhs.drawtop
    && lhs.drawbottom == rhs.drawbottom
    && lhs.drawfront == rhs.drawfront
    && lhs.drawback == rhs.drawback
    && lhs.drawleft == rhs.drawleft
    && lhs.drawright == rhs.drawright
    && lhs.platform_type == rhs.platform_type
    && lhs.start_x == rhs.start_x
    && lhs.start_y == rhs.start_y
    && lhs.end_x == rhs.end_x
    && lhs.end_y == rhs.end_y
    && lhs.front_z == rhs.front_z
    && lhs.back_z == rhs.back_z
    && lhs.vertices[0] == rhs.vertices[0]
    && lhs.vertices[1] == rhs.vertices[1]
    && lhs.vertices[2] == rhs.vertices[2]
    && lhs.vertices[3] == rhs.vertices[3];
}

std::ostream& operator<<(std::ostream& stream, const PlatformObjectData& val) {
  stream << "tag: " << val.tag
    << " - material_tag: " << val.material_tag
    << " - drawtop: " << val.drawtop
    << " - drawbottom: " << val.drawbottom
    << " - drawfront: " << val.drawfront
    << " - drawback: " << val.drawback
    << " - drawleft: " << val.drawleft
    << " - drawright: " << val.drawright
    << " - platform_type: " << static_cast<int>(val.platform_type)
    << " - start_x: " << val.start_x
    << " - start_y: " << val.start_y
    << " - end_x: " << val.end_x
    << " - end_y: " << val.end_y
    << " - front_z: " << val.front_z
    << " - back_z: " << val.back_z
    << " - vertices[0]: " << val.vertices[0]
    << " - vertices[1]: " << val.vertices[1]
    << " - vertices[2]: " << val.vertices[2]
    << " - vertices[3]: " << val.vertices[3];
  return stream;
}

bool operator==(const WallObjectData& lhs, const WallObjectData& rhs) {
  return lhs.tag == rhs.tag
    && lhs.material_tag == rhs.material_tag
    && lhs.drawtop == rhs.drawtop
    && lhs.drawbottom == rhs.drawbottom
    && lhs.drawfront == rhs.drawfront
    && lhs.drawback == rhs.drawback
    && lhs.drawleft == rhs.drawleft
    && lhs.drawright == rhs.drawright
    && lhs.vertices[0] == rhs.vertices[0]
    && lhs.vertices[1] == rhs.vertices[1]
    && lhs.vertices[2] == rhs.vertices[2]
    && lhs.vertices[3] == rhs.vertices[3];
}

std::ostream& operator<<(std::ostream& stream, const WallObjectData& val) {
  stream << "tag: " << val.tag
    << " - material_tag: " << val.material_tag
    << " - drawtop: " << val.drawtop
    << " - drawbottom: " << val.drawbottom
    << " - drawfront: " << val.drawfront
    << " - drawback: " << val.drawback
    << " - drawleft: " << val.drawleft
    << " - drawright: " << val.drawright
    << " - vertices[0]: " << val.vertices[0]
    << " - vertices[1]: " << val.vertices[1]
    << " - vertices[2]: " << val.vertices[2]
    << " - vertices[3]: " << val.vertices[3];
  return stream;
}

bool operator==(const LadderObjectData& lhs, const LadderObjectData& rhs) {
  return lhs.tag == rhs.tag
    && lhs.material_tag == rhs.material_tag
    && lhs.origin_x == rhs.origin_x
    && lhs.top_y == rhs.top_y
    && lhs.bottom_y == rhs.bottom_y
    && lhs.front_z == rhs.front_z;
}

std::ostream& operator<<(std::ostream& stream, const LadderObjectData& val) {
  stream << "tag: " << val.tag
    << " - material_tag: " << val.material_tag
    << " - origin_x: " << val.origin_x
    << " - top_y: " << val.top_y
    << " - bottom_y: " << val.bottom_y
    << " - front_z: " << val.front_z;
  return stream;
}

bool operator==(const VineObjectData& lhs, const VineObjectData& rhs) {
  return lhs.tag == rhs.tag
    && lhs.material_tag == rhs.material_tag
    && lhs.origin_x == rhs.origin_x
    && lhs.top_y == rhs.top_y
    && lhs.bottom_y == rhs.bottom_y
    && lhs.front_z == rhs.front_z;
}

std::ostream& operator<<(std::ostream& stream, const VineObjectData& val) {
  stream << "tag: " << val.tag
    << " - material_tag: " << val.material_tag
    << " - origin_x: " << val.origin_x
    << " - top_y: " << val.top_y
    << " - bottom_y: " << val.bottom_y
    << " - front_z: " << val.front_z;
  return stream;
}

bool operator==(const LevelData& lhs, const LevelData& rhs) {
  return true
    && lhs.main_script_tag == rhs.main_script_tag
    && lhs.donut_script_tag == rhs.donut_script_tag
    && lhs.background_track_tag == rhs.background_track_tag
    && lhs.death_track_tag == rhs.death_track_tag
    && lhs.end_level_track_tag == rhs.end_level_track_tag
    && lhs.scripts == rhs.scripts
    && lhs.textures == rhs.textures
    && lhs.materials == rhs.materials
    && lhs.meshes == rhs.meshes
    && lhs.music == rhs.music
    && lhs.sounds == rhs.sounds
    && lhs.quads == rhs.quads
    && lhs.donuts == rhs.donuts
    && lhs.platforms == rhs.platforms
    && lhs.walls == rhs.walls
    && lhs.ladders == rhs.ladders
    && lhs.vines == rhs.vines
  ;
}

LevelData LevelData::FromStream(std::istream& stream) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Reading level data from stream";

  Json::Value root_node;
  stream >> root_node;

  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Read json data:\n" << root_node;

  std::string main_script_tag = root_node["mainScriptTag"].asString();
  std::string donut_script_tag = root_node["donutScriptTag"].asString();
  std::string background_track_tag = root_node["backgroundTrackTag"].asString();
  std::string death_track_tag = root_node["deathTrackTag"].asString();
  std::string end_level_track_tag = root_node["endLevelTrackTag"].asString();

  Json::Value resources_node = root_node["resources"];

  Json::Value scripts_node = resources_node["scripts"];
  Json::Value textures_node = resources_node["textures"];
  Json::Value materials_node = resources_node["materials"];
  Json::Value meshes_node = resources_node["meshes"];
  Json::Value music_node = resources_node["music"];
  Json::Value sounds_node = resources_node["sounds"];

  std::vector<ScriptResourceData> scripts;
  for (const auto& script_node: scripts_node) {
    scripts.push_back({
      script_node["filename"].asString(),
      script_node["tag"].asString(),
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
  Json::Value donuts_node = objects_node["donuts"];
  Json::Value platforms_node = objects_node["platforms"];
  Json::Value walls_node = objects_node["walls"];
  Json::Value ladders_node = objects_node["ladders"];
  Json::Value vines_node = objects_node["vines"];

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
      quad_node["tag"].asString(),
      quad_node["materialTag"].asString(),
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

  std::vector<DonutObjectData> donuts;
  for (const auto& donut_node: donuts_node) {
    donuts.push_back({
      donut_node["tag"].asString(),
      donut_node["materialTag"].asString(),
      donut_node["originX"].asFloat(),
      donut_node["originY"].asFloat(),
      donut_node["originZ"].asFloat(),
    });
  }

  static const std::unordered_map<std::string, PlatformType> type_map = {
    { "plain", PlatformType::kPlain },
    { "slideLeft", PlatformType::kSlideLeft },
    { "slideRight", PlatformType::kSlideRight },
    { "hang", PlatformType::kHang },
  };

  std::vector<PlatformObjectData> platforms;
  for (const auto& platform_node: platforms_node) {
    std::vector<VertexData> vertices_data =
      extract_vertices_node(platform_node);

    platforms.push_back({
      platform_node["tag"].asString(),
      platform_node["materialTag"].asString(),
      platform_node["drawTop"].asBool(),
      platform_node["drawBottom"].asBool(),
      platform_node["drawFront"].asBool(),
      platform_node["drawBack"].asBool(),
      platform_node["drawLeft"].asBool(),
      platform_node["drawRight"].asBool(),
      type_map.at(platform_node["type"].asString()),
      platform_node["startX"].asFloat(),
      platform_node["startY"].asFloat(),
      platform_node["endX"].asFloat(),
      platform_node["endY"].asFloat(),
      platform_node["frontZ"].asFloat(),
      platform_node["backZ"].asFloat(),
      {
        vertices_data[0],
        vertices_data[1],
        vertices_data[2],
        vertices_data[3],
      },
    });
  }

  std::vector<WallObjectData> walls;
  for (const auto& wall_node: walls_node) {
    std::vector<VertexData> vertices_data =
      extract_vertices_node(wall_node);

    walls.push_back({
      wall_node["tag"].asString(),
      wall_node["materialTag"].asString(),
      wall_node["drawTop"].asBool(),
      wall_node["drawBottom"].asBool(),
      wall_node["drawFront"].asBool(),
      wall_node["drawBack"].asBool(),
      wall_node["drawLeft"].asBool(),
      wall_node["drawRight"].asBool(),
      {
        vertices_data[0],
        vertices_data[1],
        vertices_data[2],
        vertices_data[3],
      },
    });
  }

  std::vector<LadderObjectData> ladders;
  for (const auto& ladder_node: ladders_node) {
    ladders.push_back({
      ladder_node["tag"].asString(),
      ladder_node["materialTag"].asString(),
      ladder_node["originX"].asFloat(),
      ladder_node["topY"].asFloat(),
      ladder_node["bottomY"].asFloat(),
      ladder_node["frontZ"].asFloat(),
    });
  }

  std::vector<VineObjectData> vines;
  for (const auto& vine_node: vines_node) {
    vines.push_back({
      vine_node["tag"].asString(),
      vine_node["materialTag"].asString(),
      vine_node["originX"].asFloat(),
      vine_node["topY"].asFloat(),
      vine_node["bottomY"].asFloat(),
      vine_node["frontZ"].asFloat(),
    });
  }

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished reading level data from stream";

  return LevelData {
    main_script_tag,
    donut_script_tag,
    background_track_tag,
    death_track_tag,
    end_level_track_tag,

    scripts,
    textures,
    materials,
    meshes,
    music,
    sounds,

    quads,
    donuts,
    platforms,
    walls,
    ladders,
    vines,
  };
}

std::ostream& operator<<(std::ostream& stream, const LevelData& data) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Writing level data to stream";

  Json::Value root_node;

  root_node["mainScriptTag"] = data.main_script_tag;
  root_node["donutScriptTag"] = data.donut_script_tag;
  root_node["backgroundTrackTag"] = data.background_track_tag;
  root_node["deathTrackTag"] = data.death_track_tag;
  root_node["endLevelTrackTag"] = data.end_level_track_tag;

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
  Json::Value donuts_node(Json::arrayValue);
  Json::Value platforms_node(Json::arrayValue);
  Json::Value walls_node(Json::arrayValue);
  Json::Value ladders_node(Json::arrayValue);
  Json::Value vines_node(Json::arrayValue);

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

    quad_node["tag"] = quad.tag;
    quad_node["materialTag"] = quad.material_tag;

    quad_node["originX"] = quad.origin_x;
    quad_node["originY"] = quad.origin_y;

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

  for (const auto& donut: data.donuts) {
    Json::Value donut_node(Json::objectValue);

    donut_node["tag"] = donut.tag;
    donut_node["materialTag"] = donut.material_tag;

    donut_node["originX"] = donut.origin_x;
    donut_node["originY"] = donut.origin_y;
    donut_node["originZ"] = donut.origin_z;

    donuts_node.append(donut_node);

    BOOST_LOG_SEV(log, LogSeverity::kTrace)
      << "Added donut node:\n"
      << donut_node;
  }

  static const std::unordered_map<PlatformType, std::string> type_map = {
    { PlatformType::kPlain, "plain" },
    { PlatformType::kSlideLeft, "slideLeft" },
    { PlatformType::kSlideRight, "slideRight" },
    { PlatformType::kHang, "hang" },
  };

  for (const auto& platform: data.platforms) {
    Json::Value platform_node(Json::objectValue);

    platform_node["tag"] = platform.tag;
    platform_node["materialTag"] = platform.material_tag;

    platform_node["drawTop"] = platform.drawtop;
    platform_node["drawBottom"] = platform.drawbottom;
    platform_node["drawFront"] = platform.drawfront;
    platform_node["drawBack"] = platform.drawback;
    platform_node["drawLeft"] = platform.drawleft;
    platform_node["drawRight"] = platform.drawright;

    platform_node["type"] = type_map.at(platform.platform_type);

    platform_node["startX"] = platform.start_x;
    platform_node["startY"] = platform.start_y;
    platform_node["endX"] = platform.end_x;
    platform_node["endY"] = platform.end_y;
    platform_node["frontZ"] = platform.front_z;
    platform_node["backZ"] = platform.back_z;

    Json::Value vertices_node(Json::arrayValue);

    for (const auto& vertex: platform.vertices) {
      vertices_node.append(create_vertex_node(vertex));
    }
    platform_node["vertices"] = vertices_node;

    platforms_node.append(platform_node);

    BOOST_LOG_SEV(log, LogSeverity::kTrace)
      << "Added platform node:\n"
      << platform_node;
  }

  for (const auto& wall: data.walls) {
    Json::Value wall_node(Json::objectValue);

    wall_node["tag"] = wall.tag;
    wall_node["materialTag"] = wall.material_tag;

    wall_node["drawTop"] = wall.drawtop;
    wall_node["drawBottom"] = wall.drawbottom;
    wall_node["drawFront"] = wall.drawfront;
    wall_node["drawBack"] = wall.drawback;
    wall_node["drawLeft"] = wall.drawleft;
    wall_node["drawRight"] = wall.drawright;

    Json::Value vertices_node(Json::arrayValue);

    for (const auto& vertex: wall.vertices) {
      vertices_node.append(create_vertex_node(vertex));
    }
    wall_node["vertices"] = vertices_node;

    walls_node.append(wall_node);

    BOOST_LOG_SEV(log, LogSeverity::kTrace)
      << "Added wall node:\n"
      << wall_node;
  }

  for (const auto& ladder: data.ladders) {
    Json::Value ladder_node(Json::objectValue);

    ladder_node["tag"] = ladder.tag;
    ladder_node["materialTag"] = ladder.material_tag;

    ladder_node["originX"] = ladder.origin_x;
    ladder_node["topY"] = ladder.top_y;
    ladder_node["bottomY"] = ladder.bottom_y;
    ladder_node["frontZ"] = ladder.front_z;

    ladders_node.append(ladder_node);

    BOOST_LOG_SEV(log, LogSeverity::kTrace)
      << "Added ladder node:\n"
      << ladder_node;
  }

  for (const auto& vine: data.vines) {
    Json::Value vine_node(Json::objectValue);

    vine_node["tag"] = vine.tag;
    vine_node["materialTag"] = vine.material_tag;

    vine_node["originX"] = vine.origin_x;
    vine_node["topY"] = vine.top_y;
    vine_node["bottomY"] = vine.bottom_y;
    vine_node["frontZ"] = vine.front_z;

    vines_node.append(vine_node);

    BOOST_LOG_SEV(log, LogSeverity::kTrace)
      << "Added vine node:\n"
      << vine_node;
  }

  objects_node["quads"] = quads_node;
  objects_node["donuts"] = donuts_node;
  objects_node["platforms"] = platforms_node;
  objects_node["walls"] = walls_node;
  objects_node["ladders"] = ladders_node;
  objects_node["vines"] = vines_node;
  root_node["objects"] = objects_node;

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Added objects node:\n"
    << objects_node;

  stream << root_node;

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished writing level data to stream";

  return stream;
}
