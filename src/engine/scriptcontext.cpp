#include <fstream>
#define GLM_FORCE_LEFT_HANDED
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtx/string_cast.hpp>
#include "input.hpp"
#include "logging.hpp"
#include "scriptcontext.hpp"

namespace Jumpman {

ScriptContext::ScriptContext(
  std::shared_ptr<Graphics::Scene> scene,
  std::shared_ptr<Sound::System> sound_system,
  std::shared_ptr<Input> input,
  const std::string& main_script_filename)
    : ScriptContext(
        scene,
        sound_system,
        std::shared_ptr<Sound::MusicTrackSlot>(
          new Sound::MusicTrackSlot(sound_system)),
        input) {
  main_script_ = resource_context_->LoadScript(main_script_filename, "main");
}

ScriptContext::ScriptContext(
  std::shared_ptr<Graphics::Scene> scene,
  std::shared_ptr<Sound::System> sound_system,
  std::shared_ptr<Sound::MusicTrackSlot> main_track_slot,
  std::shared_ptr<Input> input)
    : scene_(scene)
    , scene_root_(new Graphics::SceneObject)
    , sound_system_(sound_system)
    , main_track_slot_(main_track_slot)
    , input_(input) {
  resource_context_ = std::shared_ptr<ResourceContext>(
    new ResourceContext(
      sound_system, std::bind(&ScriptContext::ScriptFactory, this)));
  scene_->objects.push_back(scene_root_);
}

bool ScriptContext::Update(double elapsed_seconds) {
  return main_script_->Update(elapsed_seconds);
}

std::shared_ptr<ScriptContext> ScriptContext::LoadLevel(
    const std::string& filename) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Engine");

  std::ifstream levelfile(filename);

  if (!levelfile) {
    const std::string error_message = "Failed to open level file: " + filename;
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  std::shared_ptr<ScriptContext> result(
    new ScriptContext(scene_, sound_system_, main_track_slot_, input_));

  const auto leveldata = LevelData::FromStream(levelfile);
  std::shared_ptr<Objects::Level> level = Objects::Level::Load(
    leveldata, [](sol::state&) { }, *result->resource_context_);

  result->main_script_ = level->GetMainScript();

  return result;
}

std::shared_ptr<ScriptContext> ScriptContext::LoadMod(const ModData& moddata) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Engine");

  std::ifstream modfile(moddata.filename);

  if (!modfile) {
    const std::string error_message = "Failed to open level file: "
      + moddata.filename;
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  std::shared_ptr<ScriptContext> result(
    new ScriptContext(scene_, sound_system_, main_track_slot_, input_));

  const auto leveldata = LevelData::FromStream(modfile);
  std::shared_ptr<Objects::Level> level = Objects::Level::Load(
    leveldata,
    [moddata](sol::state& state) {
      // TODO: Delegate to a class that knows json and converts dynamically
      sol::table data_table = sol::table::create(state);
      Json::Value data_node = moddata.data;
      for (const auto& leveset_node: data_node) {
        sol::table levelset_table = sol::table::create(state);
        levelset_table["title"] = leveset_node["title"].asString();

        sol::table levels_table = sol::table::create(state);
        for (const auto& level_node: leveset_node["levels"]) {
          sol::table level_table = sol::table::create(state);
          level_table["filename"] = level_node["filename"].asString();
          level_table["title"] = level_node["title"].asString();
          levels_table.add(level_table);
        }
        levelset_table["levels"] = levels_table;

        data_table.add(levelset_table);
      }

      state["jumpman"]["mod_data"] = data_table;
    },
    *result->resource_context_);

  result->main_script_ = level->GetMainScript();

  return result;
}

// TODO: Not a good interface for this
ModList ScriptContext::LoadModList() {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Engine");

  // TODO: Don't hard code paths, at least not here
  const std::string filename("data/mod/knownmods.json");
  std::ifstream modlistfile(filename);

  if (!modlistfile) {
    BOOST_LOG_SEV(log, LogSeverity::kError)
      << "Failed to mod list file: " << filename;
    throw std::runtime_error("Failed to mod list file: " + filename);
  }

  // TODO: Don't hard code paths, at least not here
  return ModList::FromStream(modlistfile, "data/mod");
}

std::shared_ptr<LuaScript> ScriptContext::ScriptFactory() {
  std::shared_ptr<LuaScript> result(new LuaScript());

  result->AddState([this](sol::state& state) {
    sol::table jumpman = state.create_named_table("jumpman");

    jumpman.new_usertype<ScriptContext>("ScriptContext"
      , "new", sol::no_constructor

      , "load_mod", [this](const ModData& moddata) {
        return this->LoadMod(moddata);
      }
      , "load_level", [this](const std::string& filename) {
        return this->LoadLevel(filename);
      }

      , "update", sol::readonly(&ScriptContext::Update)
      , "scene_root", sol::readonly(&ScriptContext::scene_root_)
    );

    using Sound = Sound::Sound;

    jumpman.new_usertype<Sound>("Sound"
      , "new", sol::no_constructor

      , "play", [this](Sound& sound) {
        sound.Play(*this->sound_system_);
      }
    );

    using MusicTrack = Jumpman::Sound::MusicTrack;

    jumpman.new_usertype<MusicTrack>("MusicTrack"
      , "new", sol::no_constructor

      , "pause", [this](std::shared_ptr<MusicTrack> track) {
        track->Pause(*sound_system_);
      }
      , "unpause", [this](std::shared_ptr<MusicTrack> track) {
        track->Unpause(*sound_system_);
      }
      , "is_playing", sol::property(&MusicTrack::GetIsPlaying)
    );

    using MusicTrackSlot = Jumpman::Sound::MusicTrackSlot;

    jumpman.new_usertype<MusicTrackSlot>("MusicTrackSlot"
      , "new", sol::no_constructor

      , "play_once", sol::overload(
        [](MusicTrackSlot& slot, std::shared_ptr<MusicTrack> track) {
          slot.PlayOnce(track);
        },
        static_cast<void(MusicTrackSlot::*)(
          std::shared_ptr<MusicTrack>, unsigned int)>(
            &MusicTrackSlot::PlayOnce))
      , "play_repeating", sol::overload(
        [](MusicTrackSlot& slot, std::shared_ptr<MusicTrack> track) {
          slot.PlayRepeating(track);
        },
        [](
            MusicTrackSlot& slot,
            std::shared_ptr<MusicTrack> track,
            unsigned int start_at_milliseconds) {
          slot.PlayRepeating(track, start_at_milliseconds);
        },
        static_cast<void(MusicTrackSlot::*)(
          std::shared_ptr<MusicTrack>, unsigned int, unsigned int)>(
            &MusicTrackSlot::PlayRepeating))
      , "stop", &MusicTrackSlot::Stop
    );

    jumpman.new_usertype<ResourceContext>("ResourceContext"
      , "new", sol::no_constructor

      , "find_script", &ResourceContext::FindScript
      , "find_texture", &ResourceContext::FindTexture
      , "find_material", &ResourceContext::FindMaterial
      , "find_sound", &ResourceContext::FindSound
      , "find_track", &ResourceContext::FindTrack

      , "load_mesh", &ResourceContext::LoadMesh
      , "find_mesh", &ResourceContext::FindMesh
    );

    using Material = Graphics::Material;

    jumpman.new_usertype<Material>("Material"
      , "new", sol::no_constructor

      , "texture", sol::property(&Material::GetTexture, &Material::SetTexture)
      , "texture_transform", &Material::texture_transform
      , "set_uniform", sol::overload(
        static_cast<void(Material::*)(const std::string&, const glm::mat4&)>(
          &Material::SetShaderUniform),
        static_cast<void(Material::*)(const std::string&, const glm::vec3&)>(
          &Material::SetShaderUniform),
        static_cast<void(Material::*)(const std::string&, float)>(
          &Material::SetShaderUniform))
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

    // TODO: Wrap these types with a safe resource loader - makes new context?
    jumpman.new_usertype<ModData>("ModData"
      , "new", sol::no_constructor

      , "title", sol::readonly(&ModData::title)
    );

    jumpman.new_usertype<ModList>("ModList"
      , "new", sol::no_constructor

      , "load", sol::factories([this]() {
        return this->LoadModList();
      })

      , "builtin", sol::readonly(&ModList::builtin)
      , "discovered", sol::readonly(&ModList::discovered)
    );

    using MeshComponent = Graphics::MeshComponent;

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

      , "unit_x", sol::factories([]() -> const glm::vec3& {
        static glm::vec3 unit_x(1.0f, 0.0f, 0.0f);
        return unit_x;
      })
      , "unit_y", sol::factories([]() -> const glm::vec3& {
        static glm::vec3 unit_y(0.0f, 1.0f, 0.0f);
        return unit_y;
      })
      , "unit_z", sol::factories([]() -> const glm::vec3& {
        static glm::vec3 unit_z(0.0f, 0.0f, 1.0f);
        return unit_z;
      })

      , sol::meta_function::index, static_cast<float&(glm::vec3::*)(int)>(
        &glm::vec3::operator[])
      , sol::meta_function::to_string,
        static_cast<std::string(*)(const glm::vec3&)>(&glm::to_string)

      , sol::meta_function::unary_minus,
        static_cast<glm::vec3(*)(const glm::vec3&)>(&glm::operator-)
      , sol::meta_function::addition,
        sol::overload(
          static_cast<glm::vec3(*)(const glm::vec3&, const glm::vec3&)>(
            &glm::operator+),
          static_cast<glm::vec3(*)(const glm::vec3&, float)>(
            &glm::operator+),
          static_cast<glm::vec3(*)(float, const glm::vec3&)>(
            &glm::operator+))
      , sol::meta_function::subtraction,
        sol::overload(
          static_cast<glm::vec3(*)(const glm::vec3&, const glm::vec3&)>(
            &glm::operator-),
          static_cast<glm::vec3(*)(const glm::vec3&, float)>(
            &glm::operator-),
          static_cast<glm::vec3(*)(float, const glm::vec3&)>(
            &glm::operator-))
      , sol::meta_function::multiplication,
        sol::overload(
          static_cast<glm::vec3(*)(const glm::vec3&, const glm::vec3&)>(
            &glm::operator*),
          static_cast<glm::vec3(*)(const glm::vec3&, float)>(
            &glm::operator*),
          static_cast<glm::vec3(*)(float, const glm::vec3&)>(
            &glm::operator*))
      , sol::meta_function::division,
        sol::overload(
          static_cast<glm::vec3(*)(const glm::vec3&, const glm::vec3&)>(
            &glm::operator/),
          static_cast<glm::vec3(*)(const glm::vec3&, float)>(
            &glm::operator/),
          static_cast<glm::vec3(*)(float, const glm::vec3&)>(
            &glm::operator/))

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

    jumpman.new_usertype<glm::quat>("Quaternion"
      , sol::constructors<
          sol::types<>,
          sol::types<const glm::quat&>,
          sol::types<float, const glm::vec3&>,
          sol::types<float, float, float, float>>()

      , "x", &glm::quat::x
      , "y", &glm::quat::y
      , "z", &glm::quat::z
      , "w", &glm::quat::w
    );

    using Transform = Graphics::Transform;

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
      , "set_translation", sol::overload(
        static_cast<void (Transform::*)(const glm::vec3&)>(
          &Transform::SetTranslation),
        static_cast<void (Transform::*)(float, float, float)>(
          &Transform::SetTranslation))

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

    using SceneObject = Graphics::SceneObject;

    jumpman.new_usertype<SceneObject>("SceneObject"
      , "", sol::no_constructor

      , "new", sol::factories([]() {
        return std::shared_ptr<SceneObject>(
          new SceneObject);
      })

      , "is_enabled", &SceneObject::is_enabled
      , "transform", &SceneObject::transform
      , "mesh_component", &SceneObject::mesh_component
      , "children", &SceneObject::children
      , "add_child", [](
          SceneObject& scene_object, std::shared_ptr<SceneObject> child) {
        scene_object.children.push_back(child);
      }
      , "remove_child", [](
          SceneObject& scene_object, std::shared_ptr<SceneObject> child) {
        auto it = std::find(
          scene_object.children.begin(), scene_object.children.end(), child);

        if (it != scene_object.children.end()) {
          scene_object.children.erase(it);
        }
      }
    );

    jumpman.new_usertype<glm::mat4>("Matrix"
      , "new_perspective", sol::factories(
        [](float fovy, float aspect, float z_near, float z_far) {
          return glm::perspective(glm::radians(fovy), aspect, z_near, z_far);
        })
    );

    using ProjectionCamera = Graphics::ProjectionCamera;

    jumpman.new_usertype<ProjectionCamera>("ProjectionCamera"
      , "field_of_view", sol::property(
        &ProjectionCamera::GetFieldOfView, &ProjectionCamera::SetFieldOfView)
      , "aspect_ratio", sol::property(
        &ProjectionCamera::GetAspectRatio, &ProjectionCamera::SetAspectRatio)
      , "near_clip_plane_distance", sol::property(
        &ProjectionCamera::GetNearClipPlaneDistance,
        &ProjectionCamera::GetNearClipPlaneDistance)
      , "far_clip_plane_distance", sol::property(
        &ProjectionCamera::GetFarClipPlaneDistance,
        &ProjectionCamera::GetFarClipPlaneDistance)
      , "transform", &ProjectionCamera::transform
    );

    using Scene = Graphics::Scene;

    jumpman.new_usertype<Scene>("Scene"
      , "new", sol::no_constructor

      , "camera", &Scene::camera
      , "remove_child", [](
          Scene& scene, std::shared_ptr<SceneObject> child) {
        auto it = std::find(scene.objects.begin(), scene.objects.end(), child);

        if (it != scene.objects.end()) {
          scene.objects.erase(it);
        }
      }
    );

    jumpman.new_usertype<DigitalControllerActionState>(
      "DigitalControllerActionState"
      , "new", sol::no_constructor

      , "is_pressed", &DigitalControllerActionState::is_pressed
      , "was_just_pressed", &DigitalControllerActionState::was_just_pressed
      , "is_released", &DigitalControllerActionState::is_released
      , "was_just_released", &DigitalControllerActionState::was_just_released
    );

    jumpman.new_usertype<Input>("Input"
      , "new", sol::no_constructor

      , "activate_action_set", &Input::ActivateActionSet
      , "get_digital_action_state", &Input::GetDigitalActionState
      , "get_analog_action_state", &Input::GetAnalogActionState
    );

    jumpman.set_function(
      "abs", static_cast<glm::vec3(*)(const glm::vec3&)>(&glm::abs));
    jumpman.set_function(
      "sign", static_cast<glm::vec3(*)(const glm::vec3&)>(&glm::sign));
    jumpman.set_function(
      "ceil", static_cast<glm::vec3(*)(const glm::vec3&)>(&glm::ceil));
    jumpman.set_function(
      "floor", static_cast<glm::vec3(*)(const glm::vec3&)>(&glm::floor));
    jumpman.set_function(
      "trunc", static_cast<glm::vec3(*)(const glm::vec3&)>(&glm::trunc));
    jumpman.set_function(
      "round", static_cast<glm::vec3(*)(const glm::vec3&)>(&glm::round));
    jumpman.set_function(
      "max", static_cast<glm::vec3(*)(const glm::vec3&, const glm::vec3&)>(
        &glm::max));
    jumpman.set_function(
      "min", static_cast<glm::vec3(*)(const glm::vec3&, const glm::vec3&)>(
        &glm::min));
    jumpman.set_function(
      "clamp",
      sol::overload(
        static_cast<
          glm::vec3(*)(const glm::vec3&, const glm::vec3&, const glm::vec3&)>(
            &glm::clamp),
        static_cast<glm::vec3(*)(const glm::vec3&, float, float)>(
          &glm::clamp)));
    jumpman.set_function(
      "mix",
      sol::overload(
        static_cast<
          glm::vec3(*)(const glm::vec3&, const glm::vec3&, const glm::vec3&)>(
            &glm::mix),
        static_cast<glm::vec3(*)(const glm::vec3&, const glm::vec3&, float)>(
          &glm::mix)));

    jumpman.set("resource_context", resource_context_);
    jumpman.set("scene", scene_);
    jumpman.set("scene_root", scene_root_);
    jumpman.set("main_music_track_slot", main_track_slot_);
    jumpman.set("input", input_);
  });

  return result;
}

};  // namespace Jumpman
