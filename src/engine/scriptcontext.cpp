#include <fstream>
#define GLM_FORCE_LEFT_HANDED
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtx/string_cast.hpp>
#include "logging.hpp"
#include "scriptcontext.hpp"

namespace Jumpman {

ScriptContext::ScriptContext(
  std::shared_ptr<Scene> scene, const std::string& main_script_filename)
    : scene_(scene) {
  // TODO: Why isn't std::bind working?
  auto script_factory = [this](const std::string& filename) {
    return this->ScriptFactory(filename);
  };

  resource_context_ = std::shared_ptr<ResourceContext>(
    new ResourceContext(script_factory));

  main_script_ = resource_context_->LoadScript(main_script_filename, "main");
}

void ScriptContext::Update(double elapsed_seconds) {
  main_script_->Update(elapsed_seconds);
}

std::shared_ptr<Objects::Level> ScriptContext::LoadLevel(
    const std::string& filename) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Engine");

  std::ifstream levelfile(filename);

  if (!levelfile) {
    BOOST_LOG_SEV(log, LogSeverity::kError)
      << "Failed to open level file: " << filename;
    return std::shared_ptr<Objects::Level>();
  }

  auto data = LevelData::FromStream(levelfile);

  return std::shared_ptr<Objects::Level>(
    new Objects::Level(data, *resource_context_));
}

std::shared_ptr<LuaScript> ScriptContext::ScriptFactory(
    const std::string& filename) {
  return std::shared_ptr<LuaScript>(
    new LuaScript(filename, [this](sol::state& script) {
      sol::table jumpman = script.create_named_table("jumpman");

      jumpman.new_usertype<ResourceContext>("ResourceContext"
        , "new", sol::no_constructor

        , "find_script", &ResourceContext::FindScript
        , "find_texture", &ResourceContext::FindTexture
        , "find_material", &ResourceContext::FindMaterial
        , "find_mesh", &ResourceContext::FindMesh
      );

      jumpman.new_usertype<Material>("Material"
        , "new", sol::no_constructor

        , "texture", sol::property(&Material::GetTexture, &Material::SetTexture)
      );

      jumpman.new_usertype<Objects::QuadObject>("Quad"
        , "new", sol::no_constructor

        , "mesh", sol::property(
            &Objects::QuadObject::GetMesh, &Objects::QuadObject::SetMesh)
        , "material", sol::property(
            &Objects::QuadObject::GetMaterial,
            &Objects::QuadObject::SetMaterial)
        , "origin", &Objects::QuadObject::origin
      );

      jumpman.new_usertype<Objects::DonutObject>("Donut"
        , "new", sol::no_constructor

        , "mesh", sol::property(
            &Objects::DonutObject::GetMesh, &Objects::DonutObject::SetMesh)
        , "material", sol::property(
            &Objects::DonutObject::GetMaterial,
            &Objects::DonutObject::SetMaterial)
        , "origin", &Objects::DonutObject::origin
      );

      jumpman.new_usertype<Objects::PlatformObject>("Platform"
        , "new", sol::no_constructor

        , "mesh", sol::property(
            &Objects::PlatformObject::GetMesh,
            &Objects::PlatformObject::SetMesh)
        , "material", sol::property(
            &Objects::PlatformObject::GetMaterial,
            &Objects::PlatformObject::SetMaterial)
        , "origin", &Objects::PlatformObject::origin
      );

      jumpman.new_usertype<Objects::WallObject>("Wall"
        , "new", sol::no_constructor

        , "mesh", sol::property(
            &Objects::WallObject::GetMesh, &Objects::WallObject::SetMesh)
        , "material", sol::property(
            &Objects::WallObject::GetMaterial,
            &Objects::WallObject::SetMaterial)
        , "origin", &Objects::WallObject::origin
      );

      jumpman.new_usertype<Objects::LadderObject>("Ladder"
        , "new", sol::no_constructor

        , "mesh", sol::property(
            &Objects::LadderObject::GetMesh, &Objects::LadderObject::SetMesh)
        , "material", sol::property(
            &Objects::LadderObject::GetMaterial,
            &Objects::LadderObject::SetMaterial)
        , "origin", &Objects::LadderObject::origin
      );

      jumpman.new_usertype<Objects::VineObject>("Vine"
        , "new", sol::no_constructor

        , "mesh", sol::property(
            &Objects::VineObject::GetMesh, &Objects::VineObject::SetMesh)
        , "material", sol::property(
            &Objects::VineObject::GetMaterial,
            &Objects::VineObject::SetMaterial)
        , "origin", &Objects::VineObject::origin
      );

      jumpman.new_usertype<Objects::Level>("Level"
        , "new", sol::no_constructor

        , "load", sol::factories([this](const std::string& filename) {
          return this->LoadLevel(filename);
        })

        , "main_script_tag", sol::readonly(&Objects::Level::main_script_tag)
        , "donut_script_tag", sol::readonly(&Objects::Level::donut_script_tag)
        , "background_track_tag", sol::readonly(
            &Objects::Level::background_track_tag)
        , "death_track_tag", sol::readonly(&Objects::Level::death_track_tag)
        , "end_level_track_tag", sol::readonly(
            &Objects::Level::end_level_track_tag)

        , "num_quads", sol::property(&Objects::Level::NumQuads)
        , "num_donuts", sol::property(&Objects::Level::NumDonuts)
        , "num_platforms", sol::property(&Objects::Level::NumPlatforms)
        , "num_walls", sol::property(&Objects::Level::NumWalls)
        , "num_ladders", sol::property(&Objects::Level::NumLadders)
        , "num_vines", sol::property(&Objects::Level::NumVines)

        , "quads", sol::property(&Objects::Level::GetQuads)
        , "donuts", sol::property(&Objects::Level::GetDonuts)
        , "platforms", sol::property(&Objects::Level::GetPlatforms)
        , "walls", sol::property(&Objects::Level::GetWalls)
        , "ladders", sol::property(&Objects::Level::GetLadders)
        , "vines", sol::property(&Objects::Level::GetVines)

        , "find_quad", &Objects::Level::FindQuad
        , "find_donut", &Objects::Level::FindDonut
        , "find_platform", &Objects::Level::FindPlatform
        , "find_wall", &Objects::Level::FindWall
        , "find_ladder", &Objects::Level::FindLadder
        , "find_vine", &Objects::Level::FindVine
      );

      jumpman.new_usertype<MeshComponent>("MeshComponent"
        , "", sol::no_constructor

        , "new", sol::factories([]() {
          return std::shared_ptr<MeshComponent>(new MeshComponent);
        })

        , "mesh", &MeshComponent::mesh
        , "material", &MeshComponent::material
      );

      jumpman.new_usertype<glm::vec3>("Vector3"
        , sol::constructors<
            sol::types<>,
            sol::types<const glm::vec3&>,
            sol::types<float>,
            sol::types<float, float, float>>()

        , sol::meta_function::index, static_cast<float&(glm::vec3::*)(int)>(
          &glm::vec3::operator[])
        , sol::meta_function::to_string,
          static_cast<std::string(*)(const glm::vec3&)>(&glm::to_string)

        , "x", &glm::vec3::x
        , "y", &glm::vec3::y
        , "z", &glm::vec3::z

        , "r", &glm::vec3::r
        , "g", &glm::vec3::g
        , "b", &glm::vec3::b

        , "s", &glm::vec3::s
        , "t", &glm::vec3::t
        , "p", &glm::vec3::p
      );

      jumpman.new_usertype<Transform>("Transform"
        , "scale", sol::property(
          &Transform::GetScale,
          static_cast<void (Transform::*)(const glm::vec3&)>(
            &Transform::SetScale))
        , "set_scale", static_cast<void (Transform::*)(float, float, float)>(
          &Transform::SetScale)

        , "orientation", sol::property(
          &Transform::GetOrientation, &Transform::SetOrientation)
        , "set_angle_axis_rotation", &Transform::SetAngleAxisRotation

        , "rotate_on_angle_axis", &Transform::RotateOnAngleAxis

        , "translation", sol::property(
          &Transform::GetTranslation,
          static_cast<void (Transform::*)(const glm::vec3&)>(
            &Transform::SetTranslation))
        , "set_translation",
          static_cast<void (Transform::*)(float, float, float)>(
            &Transform::SetTranslation)

        , "translate", sol::overload(
          static_cast<void (Transform::*)(const glm::vec3&)>(
            &Transform::Translate),
          static_cast<void (Transform::*)(float, float, float)>(
            &Transform::Translate))

        , "look_at", sol::overload(
          static_cast<void (Transform::*)(const glm::vec3&)>(
            &Transform::LookAt),
          static_cast<void (Transform::*)(float, float, float)>(
            &Transform::LookAt))
      );

      jumpman.new_usertype<SceneObject>("SceneObject"
        , "", sol::no_constructor

        , "new", sol::factories([]() {
          return std::shared_ptr<SceneObject>(new SceneObject);
        })

        , "transform", &SceneObject::transform
        , "mesh_component", &SceneObject::mesh_component
        , "children", &SceneObject::children
        , "add_child", [](
            SceneObject& scene_object, std::shared_ptr<SceneObject> child) {
          scene_object.children.push_back(child);
        }
      );

      jumpman.new_usertype<glm::mat4>("Matrix"
        , "new_perspective", sol::factories(
          [](float fovy, float aspect, float z_near, float z_far) {
            return glm::perspective(glm::radians(fovy), aspect, z_near, z_far);
          })
      );

      jumpman.new_usertype<Camera>("Camera"
        , "projection_matrix", &Camera::projection_matrix
        , "transform", &Camera::transform
      );

      jumpman.new_usertype<Scene>("Scene"
        , "new", sol::no_constructor

        , "camera", &Scene::camera
        , "objects", &Scene::objects
        , "add_object", [](Scene& scene, std::shared_ptr<SceneObject> object) {
          scene.objects.push_back(object);
        }
      );

      jumpman.set("resource_context", resource_context_);
      jumpman.set("scene", scene_);
    })
  );
}

};  // namespace Jumpman