local context = jumpman.resource_context
local scene = jumpman.scene

-- TODO: Move to shared code?
function create_scene_object(object)
  local mesh_component = jumpman.MeshComponent.new()
  mesh_component.mesh = object.mesh
  mesh_component.material = object.material

  local scene_object = jumpman.SceneObject.new()
  scene_object.mesh_component = mesh_component
  scene_object.transform.translation = object.origin

  return scene_object
end

function load_level(filename)
  local level = jumpman.Level.load(filename)

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

local char_mesh_cache = {}
local char_meshes_loaded = false

function load_char_meshes()
  if char_meshes_loaded then
    return char_mesh_cache
  end

  function load_char_mesh(char)
    char_mesh_cache[char] = context:load_mesh(
      "data/model/Char" .. char .. ".obj")
  end

  local char_mesh_names = {
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "A",
    "Apos",
    "B",
    "C",
    "Colon",
    "D",
    "Dash",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "Jump",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Period",
    "Q",
    "R",
    "S",
    "Square",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
  }

  for i, char in ipairs(char_mesh_names) do
    load_char_mesh(char)
  end

  return char_mesh_cache
end

function animate(animation, current_time)
  local result = animation.start_value

  if current_time >= animation.start_time + animation.length then
    result = animation.end_value
  elseif current_time >= animation.start_time then
    result = animation.start_value
      + (animation.end_value - animation.start_value)
      * (current_time - animation.start_time)
      / (animation.length)
  end

  return result
end

-- TODO: Put in main menu script
local scene_objects = load_level("data/level/MainMenu.json")
local char_meshes = load_char_meshes()

local camera = scene.camera
camera.transform:set_translation(80, 80, -100)
camera.transform:look_at(80, 80, 0)

local animation_time = 0
local animation_finish_time = 5.5

function create_string_objects(input_string, material)
  local result = {}

  for i = 1, string.len(input_string) do
    local char = string.sub(input_string, i, i)
    local scene_object = create_scene_object({
      mesh = char_meshes[char],
      material = material,
      origin = jumpman.Vector3.new(),
    })
    scene:add_object(scene_object)
    table.insert(result, scene_object)
  end

  return result
end

local jumpman_string_objects = create_string_objects(
  "JUMPMAN", context:find_material("7"))
local jumpman_string_starting_heights = {
  [1] = 22,
  [5] = 54,
  [2] = 76,
  [3] = 80,
  [4] = 84,
  [6] = 82,
  [7] = 78,
}

function animate_jumpman_string(letter_index, animation_scale)
  local height = math.max(
    0,
    (jumpman_string_starting_heights[letter_index] * 4 / 3)
      - (animation_scale * 200))
  local transform = jumpman_string_objects[letter_index].transform
  transform:set_translation(transform.translation.x, 100 + height, height)

  if height >= 3 then
    transform:set_angle_axis_rotation(
      10 * (height - 3) * math.pi / 180,
      jumpman.Vector3.unit_x())
  end
end

for i, letter in ipairs(jumpman_string_objects) do
  local x = i * 15 + 20

  if i > 1 then
    x = x - 1
  end

  if i > 4 then
    x = x - 2
  end

  if i > 6 then
    x = x + 1
  end

  local transform = letter.transform
  transform.translation.x = x
  animate_jumpman_string(i, 0)
  transform:set_scale(2, 0.8, 0.2)
end

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

function update(elapsed_seconds)
  -- TODO: Put in main menu script
  animation_time = animation_time + elapsed_seconds
  if animation_time > animation_finish_time then
    animation_time = animation_finish_time
  end
  local animation_scale = animation_time / animation_finish_time

  local jumpman_inflate_thickness =
    animate({
      start_value = 0.2,
      end_value = 2.5,
      start_time = 3.35,
      length = 0.55
    }, animation_time)

  for i, jumpman_string_object in ipairs(jumpman_string_objects) do
    animate_jumpman_string(i, animation_scale)
    jumpman_string_object.transform.scale.z = jumpman_inflate_thickness
  end

  -- TODO: Put in zbits script
  for i, zbit_object in ipairs(zbit_objects) do
    local transform = zbit_object.transform
    transform.translation = jumpman.mix(
      zbit_begin_positions[i], zbit_end_positions[i], animation_scale)
    transform:set_angle_axis_rotation(
      (1 - animation_scale) * math.sin(i * math.pi / 180) * 10,
      jumpman.Vector3.unit_y())
  end
end
