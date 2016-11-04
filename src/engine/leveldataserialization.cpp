#include <unordered_map>
#include "leveldataserialization.hpp"
#include "resourcedataserialization.hpp"
#include "logging.hpp"

namespace Jumpman {

LevelData DeserializeLevelData(const Json::Value& root_node) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Reading level data from json";

  ResourceData resource_data = DeserializeResourceData(root_node);

  std::string death_track_tag = root_node["deathTrackTag"].asString();
  std::string end_level_track_tag = root_node["endLevelTrackTag"].asString();

  Json::Value objects_node = root_node["objects"];

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

  std::vector<DonutObjectData> donuts;
  for (const auto& donut_node: donuts_node) {
    donuts.push_back({
      donut_node.get("tag", "").asString(),
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
      platform_node.get("tag", "").asString(),
      platform_node["materialTag"].asString(),
      platform_node["drawTop"].asBool(),
      platform_node["drawBottom"].asBool(),
      platform_node["drawFront"].asBool(),
      platform_node["drawBack"].asBool(),
      platform_node["drawLeft"].asBool(),
      platform_node["drawRight"].asBool(),
      type_map.at(platform_node["type"].asString()),
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
      wall_node.get("tag", "").asString(),
      wall_node["materialTag"].asString(),
      wall_node["drawTop"].asBool(),
      wall_node["drawBottom"].asBool(),
      wall_node["drawFront"].asBool(),
      wall_node["drawBack"].asBool(),
      wall_node["drawLeft"].asBool(),
      wall_node["drawRight"].asBool(),
      wall_node["frontZ"].asFloat(),
      wall_node["backZ"].asFloat(),
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
      ladder_node.get("tag", "").asString(),
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
      vine_node.get("tag", "").asString(),
      vine_node["materialTag"].asString(),
      vine_node["originX"].asFloat(),
      vine_node["topY"].asFloat(),
      vine_node["bottomY"].asFloat(),
      vine_node["frontZ"].asFloat(),
    });
  }

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished reading level data from json";

  return LevelData {
    resource_data.main_script_tag,
    resource_data.main_script_filename,
    resource_data.background_track_tag,
    death_track_tag,
    end_level_track_tag,

    resource_data.scripts,
    resource_data.textures,
    resource_data.materials,
    resource_data.meshes,
    resource_data.music,
    resource_data.sounds,

    resource_data.quads,
    donuts,
    platforms,
    walls,
    ladders,
    vines,
  };
}

Json::Value SerializeLevelData(const LevelData& data) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resource");
  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Writing level data to json";

  Json::Value root_node = SerializeResourceData(ResourceData {
    data.main_script_tag,
    data.main_script_filename,
    data.background_track_tag,

    data.scripts,
    data.textures,
    data.materials,
    data.meshes,
    data.music,
    data.sounds,

    data.quads,
  });

  root_node["deathTrackTag"] = data.death_track_tag;
  root_node["endLevelTrackTag"] = data.end_level_track_tag;

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Set root node data:\n"
    << root_node;

  Json::Value objects_node = root_node["objects"];
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

  for (const auto& donut: data.donuts) {
    Json::Value donut_node(Json::objectValue);

    if (!donut.tag.empty()) {
      donut_node["tag"] = donut.tag;
    }

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

    if (!platform.tag.empty()) {
      platform_node["tag"] = platform.tag;
    }

    platform_node["materialTag"] = platform.material_tag;

    platform_node["drawTop"] = platform.drawtop;
    platform_node["drawBottom"] = platform.drawbottom;
    platform_node["drawFront"] = platform.drawfront;
    platform_node["drawBack"] = platform.drawback;
    platform_node["drawLeft"] = platform.drawleft;
    platform_node["drawRight"] = platform.drawright;

    platform_node["type"] = type_map.at(platform.platform_type);

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

    if (!wall.tag.empty()) {
      wall_node["tag"] = wall.tag;
    }

    wall_node["materialTag"] = wall.material_tag;

    wall_node["drawTop"] = wall.drawtop;
    wall_node["drawBottom"] = wall.drawbottom;
    wall_node["drawFront"] = wall.drawfront;
    wall_node["drawBack"] = wall.drawback;
    wall_node["drawLeft"] = wall.drawleft;
    wall_node["drawRight"] = wall.drawright;

    wall_node["frontZ"] = wall.front_z;
    wall_node["backZ"] = wall.back_z;

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

    if (!ladder.tag.empty()) {
      ladder_node["tag"] = ladder.tag;
    }

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

    if (!vine.tag.empty()) {
      vine_node["tag"] = vine.tag;
    }

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

  objects_node["donuts"] = donuts_node;
  objects_node["platforms"] = platforms_node;
  objects_node["walls"] = walls_node;
  objects_node["ladders"] = ladders_node;
  objects_node["vines"] = vines_node;
  root_node["objects"] = objects_node;

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Added objects node:\n"
    << objects_node;

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished writing level data to json";

  return root_node;
}

};  // namespace Jumpman
