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

  for (const QuadObjectData& quad: leveldata.quads) {
    MeshGenerator generator;
    QuadObjectResource quad_object(quad, generator);
    generator.CreateMesh(resource_context, quad.tag);
    scene_objects.push_back(std::make_shared<SceneObject>(SceneObject {
      {},
      std::make_shared<MeshComponent>(MeshComponent {
        resource_context.FindMesh(quad.tag),
        resource_context.FindMaterial(quad.material_tag)
      }),
    }));
  }

  for (const DonutObjectData& donut: leveldata.donuts) {
    MeshGenerator generator;
    DonutObjectResource donut_object(donut, generator);
    generator.CreateMesh(resource_context, donut.tag);
    scene_objects.push_back(std::make_shared<SceneObject>(SceneObject {
      {},
      std::make_shared<MeshComponent>(MeshComponent {
        resource_context.FindMesh(donut.tag),
        resource_context.FindMaterial(donut.material_tag)
      }),
    }));
  }

  for (const PlatformObjectData& platform: leveldata.platforms) {
    MeshGenerator generator;
    PlatformObjectResource platform_object(platform, generator);
    generator.CreateMesh(resource_context, platform.tag);
    scene_objects.push_back(std::make_shared<SceneObject>(SceneObject {
      {},
      std::make_shared<MeshComponent>(MeshComponent {
        resource_context.FindMesh(platform.tag),
        resource_context.FindMaterial(platform.material_tag)
      }),
    }));
  }

  // TODO: Wall objects

  for (const LadderObjectData& ladder: leveldata.ladders) {
    MeshGenerator generator;
    LadderObjectResource ladder_object(ladder, generator);
    generator.CreateMesh(resource_context, ladder.tag);
    scene_objects.push_back(std::make_shared<SceneObject>(SceneObject {
      {},
      std::make_shared<MeshComponent>(MeshComponent {
        resource_context.FindMesh(ladder.tag),
        resource_context.FindMaterial(ladder.material_tag)
      }),
    }));
  }

  // TODO: Vine objects

  scene.objects = std::move(scene_objects);
}
