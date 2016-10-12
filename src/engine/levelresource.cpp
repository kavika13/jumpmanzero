#include "levelresource.hpp"

LevelResource::LevelResource(
    const LevelData& leveldata,
    ResourceContext& resource_context,
    Scene& scene) {
  // TODO: Load scripts

  for (const TextureResourceData& texture_resource: leveldata.textures) {
    resource_context.LoadTexture(
      texture_resource.filename, texture_resource.tag);
  }

  for (const MaterialResourceData& material_resource: leveldata.materials) {
    auto material = resource_context.LoadMaterial(
      material_resource.vertex_shader_filename,
      material_resource.fragment_shader_filename,
      material_resource.tag);
    material.lock()->SetTexture(
      resource_context.FindTexture(material_resource.texture_tag));
  }

  for (const MeshResourceData& mesh_resource: leveldata.meshes) {
    resource_context.LoadMesh(
      mesh_resource.filename, mesh_resource.tag);
  }

  // TODO: Load sounds

  // TODO: Load music

  std::vector<std::shared_ptr<SceneObject>> scene_objects;

  auto convert_vertex = [](const VertexData& vertex) {
    return Vertex {
      vertex.x,
      vertex.y,
      vertex.z,
      0.0f,
      0.0f,
      0.0f,
      vertex.tu,
      vertex.tv,
    };
  };

  auto add_tex_coord = [](const Vertex& vertex, float tu, float tv) {
    return Vertex {
      vertex.x,
      vertex.y,
      vertex.z,
      vertex.nx,
      vertex.ny,
      vertex.nz,
      tu,
      tv,
    };
  };

  auto add_z = [](const Vertex& vertex, float z) {
    return Vertex {
      vertex.x,
      vertex.y,
      z,
      vertex.nx,
      vertex.ny,
      vertex.nz,
      vertex.tu,
      vertex.tv,
    };
  };

  auto add_triangle = [](
      std::vector<Vertex>& vertices,
      const Vertex& v0, const Vertex& v1, const Vertex& v2) {
    vertices.push_back(v0);
    vertices.push_back(v1);
    vertices.push_back(v2);
  };

  auto add_pretextured_quad = [&add_triangle](
      std::vector<Vertex>& vertices,
      const Vertex& upper_left, const Vertex& upper_right,
      const Vertex& lower_left, const Vertex& lower_right) {
    add_triangle(vertices, upper_left, lower_left, upper_right);
    add_triangle(vertices, upper_right, lower_left, lower_right);
  };

  auto add_quad = [&add_tex_coord, &add_pretextured_quad](
      std::vector<Vertex>& vertices,
      const Vertex& v0, const Vertex& v1, const Vertex& v2, const Vertex& v3) {
    // TODO: Normals
    const Vertex upper_left = add_tex_coord(v0, 0.0f, 1.0f);
    const Vertex upper_right = add_tex_coord(v1, 1.0f, 1.0f);
    const Vertex lower_left = add_tex_coord(v2, 0.0f, 0.0f);
    const Vertex lower_right = add_tex_coord(v3, 1.0f, 0.0f);

    add_pretextured_quad(
      vertices, upper_left, upper_right, lower_left, lower_right);
  };

  auto add_cube = [&add_quad](
      std::vector<Vertex>& vertices,
      float x_left, float y_top, float z_front,
      float x_right, float y_bottom, float z_back) {
    const Vertex left_top_front { x_left, y_top, z_front };
    const Vertex left_top_back { x_left, y_top, z_back };
    const Vertex left_bottom_front { x_left, y_bottom, z_front };
    const Vertex left_bottom_back { x_left, y_bottom, z_back };
    const Vertex right_top_front { x_right, y_top, z_front };
    const Vertex right_top_back { x_right, y_top, z_back };
    const Vertex right_bottom_front { x_right, y_bottom, z_front };
    const Vertex right_bottom_back { x_right, y_bottom, z_back };

    add_quad(
      vertices,
      left_top_front, right_top_front,
      left_bottom_front, right_bottom_front);
    add_quad(
      vertices,
      right_top_back, left_top_back,
      right_bottom_back, left_bottom_back);
    add_quad(
      vertices,
      left_top_back, right_top_back,
      left_top_front, right_top_front);
    add_quad(
      vertices,
      left_bottom_front, right_bottom_front,
      left_bottom_back, right_bottom_back);
    add_quad(
      vertices,
      left_top_back, left_top_front,
      left_bottom_back, left_bottom_front);
    add_quad(
      vertices,
      right_top_front, right_top_back,
      right_bottom_front, right_bottom_back);
  };

  for (const QuadObjectData& quad: leveldata.quads) {
    // TODO: Bounding box, proper scene origin
    const Vertex v0 = convert_vertex(quad.vertices[0]);
    const Vertex v1 = convert_vertex(quad.vertices[1]);
    const Vertex v2 = convert_vertex(quad.vertices[2]);
    const Vertex v3 = convert_vertex(quad.vertices[3]);

    std::vector<Vertex> vertices;
    vertices.reserve(4);

    add_quad(vertices, v0, v1, v2, v3);

    scene_objects.push_back(std::make_shared<SceneObject>(SceneObject {
      {},
      std::make_shared<MeshComponent>(MeshComponent {
        resource_context.CreateMesh(vertices, quad.tag),
        resource_context.FindMaterial(quad.material_tag)
      }),
    }));
  }

  for (const DonutObjectData& donut: leveldata.donuts) {
    // TODO: Bounding box, proper scene origin
    std::vector<Vertex> vertices;
    vertices.reserve(4 * 6 * 2 * 3);

    add_cube(
      vertices,
      donut.origin_x - 1, donut.origin_y + 3, donut.origin_z,
      donut.origin_x + 1, donut.origin_y + 1, donut.origin_z + 1);
    add_cube(
      vertices,
      donut.origin_x - 3, donut.origin_y + 1, donut.origin_z,
      donut.origin_x - 1, donut.origin_y - 1, donut.origin_z + 1);
    add_cube(
      vertices,
      donut.origin_x + 1, donut.origin_y + 1, donut.origin_z,
      donut.origin_x + 3, donut.origin_y - 1, donut.origin_z + 1);
    add_cube(
      vertices,
      donut.origin_x - 1, donut.origin_y - 1, donut.origin_z,
      donut.origin_x + 1, donut.origin_y - 3, donut.origin_z + 1);

    scene_objects.push_back(std::make_shared<SceneObject>(SceneObject {
      {},
      std::make_shared<MeshComponent>(MeshComponent {
        resource_context.CreateMesh(vertices, donut.tag),
        resource_context.FindMaterial(donut.material_tag)
      }),
    }));
  }

  auto add_platform_cube = [&add_z, &add_tex_coord, &add_pretextured_quad](
      std::vector<Vertex>& vertices,
      const PlatformObjectData& platform,
      const Vertex& v0, const Vertex& v1, const Vertex& v2, const Vertex& v3,
      float front_z, float back_z) {
    // TODO: Reduce the math/temp variables here
    const Vertex left_top_front = add_z(v0, front_z);
    const Vertex left_top_back = add_z(v0, back_z);
    const Vertex left_bottom_front = add_z(v2, front_z);
    const Vertex left_bottom_back = add_z(v2, back_z);
    const Vertex right_top_front = add_z(v1, front_z);
    const Vertex right_top_back = add_z(v1, back_z);
    const Vertex right_bottom_front = add_z(v3, front_z);
    const Vertex right_bottom_back = add_z(v3, back_z);

    const glm::vec2 top_left_vec = glm::vec2(
      left_top_front.x, left_top_front.y);
    const glm::vec2 top_right_vec = glm::vec2(
      right_top_front.x, right_top_front.y);
    const glm::vec2 bottom_left_vec = glm::vec2(
      left_bottom_front.x, left_bottom_front.y);
    const glm::vec2 bottom_right_vec = glm::vec2(
      right_bottom_front.x, right_bottom_front.y);

    const glm::vec2 texture_direction_x = top_right_vec - top_left_vec;
    const glm::vec2 texture_normal_x = glm::normalize(texture_direction_x);
    const float length_x = glm::length(texture_direction_x);

    const float scale_tu_base = length_x / 15.0f;
    const float scale_tu_temp = round(scale_tu_base * 4.0f) / 4.0f;
    const float scale_tu = (scale_tu_temp / scale_tu_base) / 15.0f;

    const float top_right_tu = length_x * scale_tu;

    const float length_bottom_left_x = glm::dot(
      bottom_left_vec - top_left_vec, texture_normal_x);
    const float bottom_left_tu = length_bottom_left_x * scale_tu;

    const float length_bottom_right_x = glm::dot(
      bottom_right_vec - top_left_vec, texture_normal_x);
    const float bottom_right_tu = length_bottom_right_x * scale_tu;

    if (platform.drawtop) {
      add_pretextured_quad(
        vertices,
        add_tex_coord(left_top_back, 0.0f, 0.5f),
        add_tex_coord(right_top_back, top_right_tu, 0.5f),
        add_tex_coord(left_top_front, 0.0f, 0.0f),
        add_tex_coord(right_top_front, top_right_tu, 0.0f));
    }

    if (platform.drawbottom) {
      add_pretextured_quad(
        vertices,
        add_tex_coord(left_bottom_front, 0.0f, 0.5f),
        add_tex_coord(right_bottom_front, top_right_tu, 0.5f),
        add_tex_coord(left_bottom_back, 0.0f, 0.0f),
        add_tex_coord(right_bottom_back, top_right_tu, 0.0f));
    }

    if (platform.drawleft) {
      add_pretextured_quad(
        // TODO: Project texture with vertical scale?
        vertices,
        add_tex_coord(left_top_back, 0.0f, 0.5f),
        add_tex_coord(left_top_front, bottom_left_tu, 0.5f),
        add_tex_coord(left_bottom_back, 0.0f, 0.0f),
        add_tex_coord(left_bottom_front, bottom_left_tu, 0.0f));
    }

    if (platform.drawright) {
      add_pretextured_quad(
        // TODO: Project texture with vertical scale?
        vertices,
        add_tex_coord(right_top_front, 0.0f, 0.5f),
        add_tex_coord(right_top_back, bottom_right_tu, 0.5f),
        add_tex_coord(right_bottom_front, 0.0f, 0.0f),
        add_tex_coord(right_bottom_back, bottom_right_tu, 0.0f));
    }

    if (platform.drawfront) {
      add_pretextured_quad(
        vertices,
        add_tex_coord(left_top_front, 0.0f, 1.0f),
        add_tex_coord(right_top_front, top_right_tu, 1.0f),
        add_tex_coord(left_bottom_front, bottom_left_tu, 0.5f),
        add_tex_coord(right_bottom_front, bottom_right_tu, 0.5f));
    }

    if (platform.drawback) {
      add_pretextured_quad(
        vertices,
        add_tex_coord(right_top_back, top_right_tu, 1.0f),
        add_tex_coord(left_top_back, 0.0f, 1.0f),
        add_tex_coord(right_bottom_back, bottom_right_tu, 0.5f),
        add_tex_coord(left_bottom_back, bottom_left_tu, 0.5f));
    }
  };

  for (const PlatformObjectData& platform: leveldata.platforms) {
    // TODO: Bounding box, proper scene origin
    std::vector<Vertex> vertices;
    vertices.reserve(6 * 2 * 3);

    add_platform_cube(
      vertices,
      platform,
      convert_vertex(platform.vertices[0]),
      convert_vertex(platform.vertices[1]),
      convert_vertex(platform.vertices[2]),
      convert_vertex(platform.vertices[3]),
      platform.front_z, platform.back_z);

    scene_objects.push_back(std::make_shared<SceneObject>(SceneObject {
      {},
      std::make_shared<MeshComponent>(MeshComponent {
        resource_context.CreateMesh(vertices, platform.tag),
        resource_context.FindMaterial(platform.material_tag)
      }),
    }));
  }

  // TODO: Wall objects

  for (const LadderObjectData& ladder: leveldata.ladders) {
    // TODO: Bounding box, proper scene origin
    std::vector<Vertex> vertices;
    vertices.reserve(2 * 6 * 2 * 3);  // TODO: Reserve for rungs

    add_cube(
      vertices,
      ladder.origin_x - 6.5f, ladder.top_y, ladder.front_z,
      ladder.origin_x - 5.2f, ladder.bottom_y, ladder.front_z + 1);
    add_cube(
      vertices,
      ladder.origin_x + 5.2f, ladder.top_y, ladder.front_z,
      ladder.origin_x + 6.5f, ladder.bottom_y, ladder.front_z + 1);

    for (
        float rung_position = ladder.bottom_y + 5.0f;
        rung_position <= ladder.top_y - 3.0f;
        rung_position += 6) {
      add_cube(
        vertices,
        ladder.origin_x - 5.3f, rung_position, ladder.front_z,
        ladder.origin_x + 5.3f, rung_position - 1.5f, ladder.front_z + 1);
    }

    scene_objects.push_back(std::make_shared<SceneObject>(SceneObject {
      {},
      std::make_shared<MeshComponent>(MeshComponent {
        resource_context.CreateMesh(vertices, ladder.tag),
        resource_context.FindMaterial(ladder.material_tag)
      }),
    }));
  }

  // TODO: Vine objects

  scene.objects = std::move(scene_objects);
}
