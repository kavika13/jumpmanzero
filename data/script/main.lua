local context = jumpman.resource_context
local scene = jumpman.scene

-- TODO: Move to shared code?
function create_scene_object(object, allow_nil)
  local mesh_component = jumpman.MeshComponent.new()

  if not allow_nil or object.mesh then
    mesh_component.mesh = object.mesh
  end

  if not allow_nil or object.material then
    mesh_component.material = object.material
  end

  local scene_object = jumpman.SceneObject.new()
  scene_object.mesh_component = mesh_component

  local origin = object.origin or jumpman.Vector3.new()
  scene_object.transform.translation = origin

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

function create_string_objects(char_meshes, text, material)
  local result = {}
  local char_map = {
    ["'"] = "Apos",
    [":"] = "Colon",
    ["-"] = "Dash",
    ["^"] = "Jump",
    ["."] = "Period",
    ["%"] = "Square",
  }

  for i = 1, string.len(text) do
    local char = string.sub(text, i, i)
    local scene_object = create_scene_object({
      mesh = char_meshes[char_map[char] or char],
      material = material,
      origin = jumpman.Vector3.new(),
      char = char,
    }, true)
    scene:add_object(scene_object)
    table.insert(result, scene_object)
  end

  return result
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

local Menu = {}
Menu.__index = Menu

function Menu.new(
    char_meshes,
    selected_material_tag, deselected_material_tag,
    origin, scale, transform_selected, letter_width, letter_height,
    select_animation_time, explode_animation_time)
  local self = create_class_instance(Menu)

  self.menu_items_ = {}
  self.selected_item_index_ = 1

  self.char_meshes_ = char_meshes
  self.selected_material_ = context:find_material(selected_material_tag)
  self.deselected_material_ = context:find_material(deselected_material_tag)

  origin = origin or { x = 0, y = 0, z = 0 }
  self.deselected_origin_ = jumpman.Vector3.new(origin.x, origin.y, origin.z)

  local t_sel = transform_selected or { x = 0, y = 0, z = -5 }
  self.selected_origin_ = self.deselected_origin_
    + jumpman.Vector3.new(t_sel.x, t_sel.y, t_sel.z)

  scale = scale or { x = 1, y = 1, z = 1 }
  self.scale_ = jumpman.Vector3.new(scale.x, scale.y, scale.z)

  self.letter_width_ = letter_width or 5
  self.letter_height_ = letter_height or 8
  self.select_animation_time_ = select_animation_time or 0.125
  self.explode_animation_time_ = explode_animation_time or 0.125

  self.is_selection_locked_in_ = false

  return self
end

function Menu:add_item(message)
  table.insert(self.menu_items_, {
    letters = create_string_objects(
      self.char_meshes_, message, self.deselected_material_),
    tween_weight = 1,
  })

  return self
end

function Menu:select(new_index)
  if not self.is_selection_locked_in_
      and self.selected_item_index_ ~= index then
    local old_menu_item = self.menu_items_[self.selected_item_index_]
    old_menu_item.tween_weight = 1 - old_menu_item.tween_weight

    local new_menu_item = self.menu_items_[new_index]
    new_menu_item.tween_weight = 1 - new_menu_item.tween_weight

    self.selected_item_index_ = new_index
  end
end

function Menu:lock_selection()
  if not self.is_selection_locked_in_ then
    self.is_selection_locked_in_ = true
    self.menu_items_[self.selected_item_index_].tween_weight = 1

    for item_index, other_menu_item in ipairs(self.menu_items_) do
      if item_index ~= self.selected_item_index_ then
        other_menu_item.tween_weight = 0
      end
    end
  end
end

function Menu:update(elapsed_seconds)
  for item_index, menu_item in ipairs(self.menu_items_) do
    local num_letters = #menu_item.letters
    local fudge_factor = 3
    local item_width = num_letters * self.letter_width_ - fudge_factor
    local is_selected = self.selected_item_index_ == item_index
    local current_material = is_selected
      and self.selected_material_
      or self.deselected_material_
    local first_keyframe_position = is_selected
      and self.deselected_origin_
      or self.selected_origin_
    local second_keyframe_position = is_selected
      and self.selected_origin_
      or self.deselected_origin_
    menu_item.tween_weight = menu_item.tween_weight
      + elapsed_seconds / self.select_animation_time_

    if menu_item.tween_weight > 1 then
      menu_item.tween_weight = 1
    end

    for letter_index, letter in ipairs(menu_item.letters) do
      -- TODO: implement on select: explode of non-selected, rotate of selected
      -- TODO: implement on select animation finished: callbacks?
      local transform = letter.transform
      transform.translation = jumpman.mix(
        first_keyframe_position,
        second_keyframe_position,
        menu_item.tween_weight)
      transform:translate(
        -item_width / 2 + (letter_index - 1) * self.letter_width_,
        -(item_index - 1) * self.letter_height_,
        0)
      transform.scale = self.scale_
      letter.mesh_component.material = current_material
    end
  end
end

function Menu:hide()
  for item_index, menu_item in ipairs(self.menu_items_) do
    for letter_index, letter in ipairs(menu_item.letters) do
      letter.mesh_component.is_visible = false
    end
  end
end

function Menu:show()
  for item_index, menu_item in ipairs(self.menu_items_) do
    for letter_index, letter in ipairs(menu_item.letters) do
      letter.mesh_component.is_visible = true
    end
  end
end

-- TODO: Put in main menu script
local scene_objects = load_level("data/level/MainMenu.json")
local char_meshes = load_char_meshes()

local camera = scene.camera
camera.transform:set_translation(80, 80, -100)
camera.transform:look_at(80, 80, 0)

local jumpman_string_objects = create_string_objects(
  char_meshes, "JUMPMAN", context:find_material("7"))
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

local top_menu = Menu.new(
    char_meshes,
    "1",
    "2",
    { x = 80, y = 64, z = 0 },
    { x = 0.7, y = 0.7, z = 1 })
  :add_item("START GAME")
  :add_item("OPTIONS")
top_menu:hide()

local sky_material = context:find_material("0")
local sky_material_transform = sky_material.texture_transform

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

local total_elapsed_time = 0
local animation_time = 0
local animation_finish_time = 5.5

function update(elapsed_seconds)
  -- TODO: Put in main menu script
  total_elapsed_time = total_elapsed_time + elapsed_seconds
  animation_time = animation_time + elapsed_seconds
  if animation_time > animation_finish_time then
    animation_time = animation_finish_time
    top_menu:show()
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

  top_menu:update(elapsed_seconds)

  local shift_sky = 0.025 * total_elapsed_time
  sky_material_transform:set_translation(-shift_sky, shift_sky, 0.0)

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
