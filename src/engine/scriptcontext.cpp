#include <fstream>
#include <unordered_set>
#define GLM_FORCE_LEFT_HANDED
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtx/string_cast.hpp>
#include "engine/objects/level.hpp"
#include "engine/objects/modelobject.hpp"
#include "engine/objects/mod.hpp"
#include "input.hpp"
#include "logging.hpp"
#include "scriptcontext.hpp"

namespace Jumpman {

ScriptContext::ScriptContext(
  const std::string& resource_base_path,
  std::shared_ptr<Graphics::Scene> scene,
  std::shared_ptr<Sound::System> sound_system,
  std::shared_ptr<Input> input,
  const std::string& main_script_filename)
    : ScriptContext(
        resource_base_path,
        scene,
        sound_system,
        std::shared_ptr<Sound::MusicTrackSlot>(
          new Sound::MusicTrackSlot(sound_system)),
        input) {
  main_script_.script_file(resource_base_path_ + main_script_filename);
  update_function_ = main_script_["update"];
}

ScriptContext::ScriptContext(
  const std::string& resource_base_path,
  std::shared_ptr<Graphics::Scene> scene,
  std::shared_ptr<Sound::System> sound_system,
  std::shared_ptr<Sound::MusicTrackSlot> main_track_slot,
  std::shared_ptr<Input> input)
    : resource_base_path_(resource_base_path)
    , resource_context_(new ResourceContext(resource_base_path, sound_system))
    , scene_(scene)
    , scene_root_(new Graphics::SceneObject)
    , sound_system_(sound_system)
    , main_track_slot_(main_track_slot)
    , input_(input)
    , main_script_(StateFactory()) {
  scene_->objects.push_back(scene_root_);
}

bool ScriptContext::Update(double elapsed_seconds) {
  return update_function_(elapsed_seconds);
}

std::shared_ptr<ScriptContext> ScriptContext::LoadLevel(
    const std::string& filename) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Engine");

  std::ifstream levelfile(resource_base_path_ + filename);

  if (!levelfile) {
    const std::string error_message = "Failed to open level file: " + filename;
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  std::shared_ptr<ScriptContext> result(
    new ScriptContext(
      resource_base_path_, scene_, sound_system_, main_track_slot_, input_));
  sol::state& main_script = result->main_script_;

  const auto leveldata = LevelData::FromStream(levelfile);
  std::shared_ptr<Objects::Level> level = Objects::Level::Load(
    leveldata, *result->resource_context_);

  for (const ScriptResourceData& script: leveldata.scripts) {
    if (script.tag != leveldata.main_script_tag) {
      main_script.script_file(resource_base_path_ + script.filename);
    }
  }

  main_script["jumpman"]["level"] = level;

  main_script.script_file(resource_base_path_ + leveldata.main_script_filename);

  result->update_function_ = main_script["update"];

  return result;
}

std::shared_ptr<ScriptContext> ScriptContext::LoadMod(
    const std::string& filename) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Engine");

  std::ifstream modfile(resource_base_path_ + filename);

  if (!modfile) {
    const std::string error_message = "Failed to open mod file: " + filename;
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  std::shared_ptr<ScriptContext> result(
    new ScriptContext(
      resource_base_path_, scene_, sound_system_, main_track_slot_, input_));
  sol::state& main_script = result->main_script_;

  const auto moddata = ModData::FromStream(modfile, main_script);
  std::shared_ptr<Objects::Mod> mod = Objects::Mod::Load(
    moddata, *result->resource_context_);

  for (const ScriptResourceData& script: moddata.scripts) {
    if (script.tag != moddata.main_script_tag) {
      main_script.script_file(resource_base_path_ + script.filename);
    }
  }

  main_script["jumpman"]["mod"] = mod;
  main_script["jumpman"]["mod_data"] = moddata.custom_data;

  main_script.script_file(resource_base_path_ + moddata.main_script_filename);

  result->update_function_ = main_script["update"];

  return result;
}

Objects::ModList ScriptContext::LoadModList() {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Engine");

  // TODO: Don't hard code paths, at least not here
  const std::string filename("data/mod/knownmods.json");
  std::ifstream modlistfile(resource_base_path_ + filename);

  if (!modlistfile) {
    BOOST_LOG_SEV(log, LogSeverity::kError)
      << "Failed to mod list file: " << filename;
    throw std::runtime_error("Failed to mod list file: " + filename);
  }

  // TODO: Don't hard code paths, at least not here
  auto modlistdata = ModListData::FromStream(
    modlistfile, resource_base_path_, "data/mod");

  return Objects::ModList(modlistdata);
}

sol::state ScriptContext::StateFactory() {
  sol::state state;

  state.open_libraries(
    sol::lib::base,
    sol::lib::coroutine,
    sol::lib::string,
    sol::lib::os,
    sol::lib::math,
    sol::lib::table,
    sol::lib::io);
  sol::table glob = state.globals();

  const std::unordered_set<std::string> base_whitelist {
    "_G",
    "coroutine",
    "string",
    "os",
    "math",
    "table",
    "io",

    "setmetatable",  // Will be wiped out later, after being safely wrapped

    "_VERSION",
    "assert",
    "error",
    "ipairs",
    "next",
    "pairs",
    "pcall",
    "print",
    "select",
    "tonumber",
    "tostring",
    "type",
    "xpcall",
  };

  const std::unordered_set<std::string> coroutine_whitelist {
    "create",
    "isyieldable",
    "resume",
    "running",
    "status",
    "wrap",
    "yield",
  };

  const std::unordered_set<std::string> string_whitelist {
    "byte",
    "char",
    "find",
    "format",
    "gmatch",
    "gsub",
    "len",
    "lower",
    "match",
    "pack",
    "packsize",
    "rep",
    "reverse",
    "sub",
    "unpack",
    "upper",
  };

  const std::unordered_set<std::string> os_whitelist {
    "clock",
    "difftime",
    "time",
  };

  const std::unordered_set<std::string> math_whitelist {
    "abs",
    "acos",
    "asin",
    "atan",
    "atan2",
    "ceil",
    "cos",
    "cosh",
    "deg",
    "exp",
    "floor",
    "fmod",
    "frexp",
    "huge",
    "ldexp",
    "log",
    "log10",
    "max",
    "maxinteger",
    "min",
    "mininteger",
    "modf",
    "pi",
    "pow",
    "rad",
    "random",
    "randomseed",
    "sin",
    "sinh",
    "sqrt",
    "tan",
    "tanh",
    "tointeger",
    "type",
    "ult",
  };

  const std::unordered_set<std::string> table_whitelist {
    "concat",
    "insert",
    "move",
    "pack",
    "remove",
    "sort",
    "unpack",
  };

  const std::unordered_set<std::string> io_whitelist {
    "read",
    "write",
    "flush",
    "type",
  };

  auto sanitize_subtable = [&glob](
      const std::string& table_name,
      const std::unordered_set<std::string>& whitelist) {
    auto table = glob.get<sol::table>(table_name);
    table.for_each([&](sol::object key, sol::object value) {
      if (whitelist.find(key.as<std::string>()) == whitelist.end()) {
        table.set(key, sol::nil);
      }
    });
  };

  sanitize_subtable("coroutine", coroutine_whitelist);
  sanitize_subtable("string", string_whitelist);
  sanitize_subtable("os", os_whitelist);
  sanitize_subtable("math", math_whitelist);
  sanitize_subtable("table", table_whitelist);
  sanitize_subtable("io", io_whitelist);
  sanitize_subtable("_G", base_whitelist);

  state.script(
    R"RAWLITERAL(
      function wrap_setmetatable()
        local setmetatable_safe = setmetatable

        _G.create_class_instance = function(cls)
          return setmetatable_safe({}, cls)
        end

        table.as_readonly = function(target_table)
          return setmetatable_safe({}, {
            __index = target_table,
            __newindex =
              function(target_table, key, value)
                error("Attempted to modify read-only table")
              end,
            __metatable = false
          });
        end

      end
      wrap_setmetatable()
    )RAWLITERAL");
  auto global_table = glob.get<sol::table>("_G");
  global_table.set("setmetatable", sol::nil);
  global_table.set("wrap_setmetatable", sol::nil);

  sol::function as_readonly = global_table["table"]["as_readonly"];

  auto lock_subtable = [&global_table, &as_readonly](
      const std::string& table_name) {
    sol::table read_only_table = as_readonly(global_table[table_name]);
    global_table.set(table_name, read_only_table);
  };

  lock_subtable("coroutine");
  lock_subtable("string");
  lock_subtable("os");
  lock_subtable("math");
  lock_subtable("table");
  lock_subtable("io");

  sol::table jumpman = state.create_named_table("jumpman");

  jumpman.new_usertype<ScriptContext>("ScriptContext"
    , "new", sol::no_constructor

    , "load_mod", [this](const std::string& filename) {
      return this->LoadMod(filename);
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

    , "find_texture", &ResourceContext::FindTexture
    , "find_material", &ResourceContext::FindMaterial
    , "find_sound", &ResourceContext::FindSound
    , "find_track", &ResourceContext::FindTrack
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

  jumpman.new_usertype<AxisAlignedBox>("AxisAlignedBox"
    , "create_from_extents", &AxisAlignedBox::FromExtents
    , "create_from_origin", &AxisAlignedBox::FromOrigin
    , "create_from_boxes",
      sol::resolve<AxisAlignedBox (const std::vector<AxisAlignedBox>&)>(
        &AxisAlignedBox::FromBoxes)
    , "origin", sol::property(
        &AxisAlignedBox::GetOrigin, &AxisAlignedBox::SetOrigin)
    , "half_dimensions", sol::property(
        &AxisAlignedBox::GetHalfDimensions, &AxisAlignedBox::SetHalfDimensions)
    , "dimensions", sol::property(
        &AxisAlignedBox::GetDimensions, &AxisAlignedBox::SetDimensions)
    , "volume", sol::property(&AxisAlignedBox::GetVolume)
    , "merge", sol::overload(
      sol::resolve<AxisAlignedBox& (const glm::vec3&)>(&AxisAlignedBox::Merge),
      sol::resolve<AxisAlignedBox& (const AxisAlignedBox&)>(
        &AxisAlignedBox::Merge))
    , "is_intersecting", &AxisAlignedBox::IsIntersecting
    , "is_intersecting_xy", &AxisAlignedBox::IsIntersectingXY
    , "contains", sol::overload(
      sol::resolve<bool (const glm::vec3&) const>(&AxisAlignedBox::Contains),
      sol::resolve<bool (const AxisAlignedBox&) const>(
        &AxisAlignedBox::Contains))
    , "contains_xy", sol::overload(
      sol::resolve<bool (const glm::vec3&) const>(&AxisAlignedBox::ContainsXY),
      sol::resolve<bool (const AxisAlignedBox&) const>(
        &AxisAlignedBox::ContainsXY))
    , "get_closest_point_to", &AxisAlignedBox::GetClosestPointTo
    , "get_overlap", &AxisAlignedBox::GetOverlap

    , "min", &AxisAlignedBox::min
    , "max", &AxisAlignedBox::max

    , sol::meta_function::to_string, [](const AxisAlignedBox& value) {
      return "AxisAlignedBox("
        + glm::to_string(value.min)
        + ", " + glm::to_string(value.max)
        + ")";
    }
  );

  using ModelObject = Objects::ModelObject;

  jumpman.new_usertype<ModelObject>("Model"
    , "new", sol::no_constructor

    , "new", sol::factories(
      [this](const std::string& filename, const std::string& tag) {
        return std::shared_ptr<ModelObject>(
          new ModelObject(filename, tag, *resource_context_));
      })

    , "mesh", sol::property(
        &ModelObject::GetMesh, &ModelObject::SetMesh)
    , "bounding_box", sol::property(&ModelObject::GetBoundingBox)
    , "material", sol::property(
        &ModelObject::GetMaterial, &ModelObject::SetMaterial)
    , "origin", &ModelObject::origin
  );

  using QuadObject = Objects::QuadObject;

  jumpman.new_usertype<QuadObject>("Quad"
    , "new", sol::no_constructor

    , "mesh", sol::property(
        &QuadObject::GetMesh, &QuadObject::SetMesh)
    , "bounding_box", sol::property(&QuadObject::GetBoundingBox)
    , "material", sol::property(
        &QuadObject::GetMaterial, &QuadObject::SetMaterial)
    , "origin", &QuadObject::origin
  );

  using DonutObject = Objects::DonutObject;

  jumpman.new_usertype<DonutObject>("Donut"
    , "new", sol::no_constructor

    , "mesh", sol::property(&DonutObject::GetMesh, &DonutObject::SetMesh)
    , "bounding_box", sol::property(&DonutObject::GetBoundingBox)
    , "material", sol::property(
        &DonutObject::GetMaterial, &DonutObject::SetMaterial)
    , "origin", &DonutObject::origin
  );

  using PlatformObject = Objects::PlatformObject;

  jumpman.new_usertype<PlatformObject>("Platform"
    , "new", sol::no_constructor

    , "mesh", sol::property(&PlatformObject::GetMesh, &PlatformObject::SetMesh)
    , "bounding_box", sol::property(&PlatformObject::GetBoundingBox)
    , "material", sol::property(
        &PlatformObject::GetMaterial, &PlatformObject::SetMaterial)
    , "origin", &PlatformObject::origin
  );

  using WallObject = Objects::WallObject;

  jumpman.new_usertype<WallObject>("Wall"
    , "new", sol::no_constructor

    , "mesh", sol::property(&WallObject::GetMesh, &WallObject::SetMesh)
    , "bounding_box", sol::property(&WallObject::GetBoundingBox)
    , "material", sol::property(
        &WallObject::GetMaterial, &WallObject::SetMaterial)
    , "origin", &WallObject::origin
  );

  using LadderObject = Objects::LadderObject;

  jumpman.new_usertype<LadderObject>("Ladder"
    , "new", sol::no_constructor

    , "mesh", sol::property(&LadderObject::GetMesh, &LadderObject::SetMesh)
    , "bounding_box", sol::property(&LadderObject::GetBoundingBox)
    , "material", sol::property(
        &LadderObject::GetMaterial, &LadderObject::SetMaterial)
    , "origin", &LadderObject::origin
  );

  using VineObject = Objects::VineObject;

  jumpman.new_usertype<VineObject>("Vine"
    , "new", sol::no_constructor

    , "mesh", sol::property(&VineObject::GetMesh, &VineObject::SetMesh)
    , "bounding_box", sol::property(&VineObject::GetBoundingBox)
    , "material", sol::property(
        &VineObject::GetMaterial, &VineObject::SetMaterial)
    , "origin", &VineObject::origin
  );

  using Level = Objects::Level;

  jumpman.new_usertype<Level>("Level"
    , "new", sol::no_constructor

    , "background_track_tag", sol::readonly(
        &Level::background_track_tag)
    , "death_track_tag", sol::readonly(&Level::death_track_tag)
    , "end_level_track_tag", sol::readonly(
        &Level::end_level_track_tag)

    , "num_quads", sol::property(&Level::NumQuads)
    , "num_donuts", sol::property(&Level::NumDonuts)
    , "num_platforms", sol::property(&Level::NumPlatforms)
    , "num_walls", sol::property(&Level::NumWalls)
    , "num_ladders", sol::property(&Level::NumLadders)
    , "num_vines", sol::property(&Level::NumVines)

    , "quads", sol::property(&Level::GetQuads)
    , "donuts", sol::property(&Level::GetDonuts)
    , "platforms", sol::property(&Level::GetPlatforms)
    , "walls", sol::property(&Level::GetWalls)
    , "ladders", sol::property(&Level::GetLadders)
    , "vines", sol::property(&Level::GetVines)

    , "find_quad", &Level::FindQuad
    , "find_donut", &Level::FindDonut
    , "find_platform", &Level::FindPlatform
    , "find_wall", &Level::FindWall
    , "find_ladder", &Level::FindLadder
    , "find_vine", &Level::FindVine
  );

  using ModInfo = Objects::ModInfo;

  jumpman.new_usertype<ModInfo>("ModInfo"
    , "new", sol::no_constructor

    , "title", sol::property(&ModInfo::GetTitle)
    , "filename", sol::property(&ModInfo::GetFilename)
  );

  using ModList = Objects::ModList;

  jumpman.new_usertype<ModList>("ModList"
    , "new", sol::no_constructor

    , "load", sol::factories([this]() {
      return this->LoadModList();
    })

    , "builtin_mods", sol::property(&ModList::GetBuiltinMods)
    , "discovered_mods", sol::property(&ModList::GetDiscoveredMods)
  );

  using Mod = Objects::Mod;

  jumpman.new_usertype<Mod>("Mod"
    , "new", sol::no_constructor

    , "background_track_tag", sol::readonly(&Mod::background_track_tag)

    , "num_quads", sol::property(&Mod::NumQuads)
    , "quads", sol::property(&Mod::GetQuads)
    , "find_quad", &Mod::FindQuad
  );

  using MeshComponent = Graphics::MeshComponent;

  jumpman.new_usertype<MeshComponent>("MeshComponent"
    , "", sol::no_constructor

    , "new", sol::factories([]() {
      return std::shared_ptr<MeshComponent>(new MeshComponent);
    })

    , "mesh", &MeshComponent::mesh
    , "bounding_box", &MeshComponent::bounding_box
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

  return state;
}

};  // namespace Jumpman
