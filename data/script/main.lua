local context = jumpman.resource_context
local scene = jumpman.scene

-- TODO: Move to shared code?
function load_level(filename)
  local level = jumpman.Level.load(filename)

  function create_scene_object(object)
    local mesh_component = jumpman.MeshComponent.new()
    mesh_component.mesh = object.mesh
    mesh_component.material = object.material

    local scene_object = jumpman.SceneObject.new()
    scene_object.mesh_component = mesh_component
    scene_object.transform.translation = object.origin

    return scene_object
  end

  local load_scene_object = function(level_objects, scene_objects)
    for i, level_object in pairs(level_objects) do
      local scene_object = create_scene_object(level_object)
      scene:add_object(scene_object)
      table.insert(scene_objects, scene_object)
    end
  end

  local quad_objects = {}
  load_scene_object(level.quads, quad_objects)

  local donut_objects = {}
  load_scene_object(level.donuts, donut_objects)

  local platform_objects = {}
  load_scene_object(level.platforms, platform_objects)

  local wall_objects = {}
  load_scene_object(level.walls, wall_objects)

  local ladder_objects = {}
  load_scene_object(level.ladders, ladder_objects)

  local vine_objects = {}
  load_scene_object(level.vines, vine_objects)

  return {
    quads = quad_objects,
    donuts = donut_objects,
    platforms = platform_objects,
    walls = wall_objects,
    ladders = ladder_objects,
    vines = vine_objects,
  }
end

-- TODO: Put in main menu script
local scene_objects = load_level("data/level/MainMenu.json")

local camera = scene.camera
camera.transform:set_translation(80, 80, -100)
camera.transform:look_at(80, 80, 0)

local animation_time = 0
local animation_finish_time = 5.5

-- TODO: Put in zbits script
local zbit_objects = {}
local zbit_begin_positions = {}
local zbit_end_positions = {}

local zbit_mesh = context:find_mesh("0")
local zbit_texture = context:find_texture("6")

for i, zbit_object in ipairs(scene_objects.donuts) do
  local end_position = zbit_object.transform.translation
    + jumpman.Vector3.new(0, -2, 0)
  local begin_position = end_position
    + jumpman.Vector3.new(math.random(-100, 100), math.random(-100, 100), -500)

  table.insert(zbit_objects, zbit_object)
  table.insert(zbit_begin_positions, begin_position)
  table.insert(zbit_end_positions, end_position)

  local mesh_component = zbit_object.mesh_component
  mesh_component.mesh = zbit_mesh
  mesh_component.material.texture = zbit_texture

  local transform = zbit_object.transform
  transform:set_scale(4, 4, 4)
  transform.translation = begin_position
end

local y_axis = jumpman.Vector3.new(0, 1, 0)

function update(elapsed_seconds)
  -- TODO: Put in main menu script
  animation_time = animation_time + elapsed_seconds
  if animation_time > animation_finish_time then
    animation_time = animation_finish_time
  end
  local animation_scale = animation_time / animation_finish_time

  -- TODO: Put in zbits script
  for i, zbit_object in ipairs(zbit_objects) do
    local transform = zbit_object.transform
    transform.translation = jumpman.mix(
      zbit_begin_positions[i], zbit_end_positions[i], animation_scale)
    transform:set_angle_axis_rotation(
      (1 - animation_scale) * math.sin(i * math.pi / 180) * 10,
      y_axis)
  end
end
