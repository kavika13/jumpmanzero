#include "levelresource.hpp"
#include "donutobjectresource.hpp"
#include "ladderobjectresource.hpp"
#include "platformobjectresource.hpp"
#include "quadobjectresource.hpp"

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
    material->SetTexture(
      resource_context.FindTexture(material_resource.texture_tag));
  }

  for (const MeshResourceData& mesh_resource: leveldata.meshes) {
    resource_context.LoadMesh(mesh_resource.filename, mesh_resource.tag);
  }

  // TODO: Load sounds

  // TODO: Load music

  std::vector<std::shared_ptr<SceneObject>> scene_objects;

  auto create_scene_object = [&](
      const MeshGenerator& generator,
      const std::string& tag,
      const std::string& material_tag) {
    scene_objects.push_back(std::make_shared<SceneObject>(SceneObject {
      {},
      std::make_shared<MeshComponent>(MeshComponent {
        generator.CreateMesh(resource_context, tag),
        resource_context.FindMaterial(material_tag)
      }),
    }));
  };

  for (const QuadObjectData& quad: leveldata.quads) {
    MeshGenerator generator;
    QuadObjectResource quad_object(quad, generator);
    // TODO: Add transform
    create_scene_object(generator, quad.tag, quad.material_tag);
  }

  for (const DonutObjectData& donut: leveldata.donuts) {
    MeshGenerator generator;
    DonutObjectResource donut_object(donut, generator);
    // TODO: Add transform
    create_scene_object(generator, donut.tag, donut.material_tag);
  }

  for (const PlatformObjectData& platform: leveldata.platforms) {
    MeshGenerator generator;
    PlatformObjectResource platform_object(platform, generator);
    // TODO: Add transform
    create_scene_object(generator, platform.tag, platform.material_tag);
  }

  // TODO: Wall objects

  for (const LadderObjectData& ladder: leveldata.ladders) {
    MeshGenerator generator;
    LadderObjectResource ladder_object(ladder, generator);
    // TODO: Add transform
    create_scene_object(generator, ladder.tag, ladder.material_tag);
  }

  // TODO: Vine objects

  scene.objects = std::move(scene_objects);
}
