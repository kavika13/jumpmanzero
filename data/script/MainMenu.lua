local context = jumpman.resource_context
local scene = jumpman.scene
local scene_root = jumpman.scene_root
local input = jumpman.input
local level = jumpman.level

-- TODO: Move to shared code?
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

-- TODO: Move to its own script?
local FallingTitle = {}
FallingTitle.__index = FallingTitle

function FallingTitle.new(
    char_meshes,
    message, material,
    starting_heights,
    animation_time,
    inflate_animation_start_time,
    inflate_animation_duration)
  local self = create_class_instance(FallingTitle)

  self.string_ = create_string_object(
    char_meshes, scene_root, message, material)
  self.starting_heights_ = starting_heights
  self.animation_time_ = animation_time or 5.5  -- TODO: Separate fall velocity?
  self.inflate_animation_start_time_ = inflate_animation_start_time or 3.35
  self.inflate_animation_duration_ = inflate_animation_duration or 0.55
  self.total_elapsed_seconds_ = 0

  for i = 1, #self.string_.children do
    local letter = self.string_.children[i]
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
    transform:set_scale(2, 0.8, 0.2)
  end

  return self
end

function FallingTitle:update(elapsed_seconds)
  self.total_elapsed_seconds_ = self.total_elapsed_seconds_ + elapsed_seconds
  local fall_tween_weight = self.total_elapsed_seconds_ / self.animation_time_
  local letters = self.string_.children
  local inflate_thickness =
    animate({
      start_value = 0.2,
      end_value = 2.5,
      start_time = self.inflate_animation_start_time_,
      length = self.inflate_animation_duration_
    }, self.total_elapsed_seconds_)

  for letter_index = 1, #letters do
    local letter = letters[letter_index]
    local starting_height = self.starting_heights_[letter_index]
    local height = math.max(
      0,
      (starting_height * 4 / 3) - (fall_tween_weight * 200))

    local transform = letter.transform
    transform:set_translation(transform.translation.x, 100 + height, height)
    transform.scale.z = inflate_thickness

    if height >= 3 then
      transform:set_angle_axis_rotation(
        10 * (height - 3) * math.pi / 180,
        jumpman.Vector3.unit_x())
    else
      transform:set_angle_axis_rotation(0, jumpman.Vector3.unit_x())
    end
  end
end

function FallingTitle:finish()
  self.total_elapsed_seconds_ = self.animation_time_
  self:update(0)
end

function FallingTitle:is_finished()
  return self.total_elapsed_seconds_ >= self.animation_time_
end

function FallingTitle:hide()
  for i = 1, #self.string_.children do
    local letter = self.string_.children[i]
    letter.mesh_component.is_visible = false
  end
end

function FallingTitle:show()
  for i = 1, #self.string_.children do
    local letter = self.string_.children[i]
    letter.mesh_component.is_visible = true
  end
end

-- TODO: Move to its own script?
local Menu = {}
Menu.__index = Menu

function Menu.new(
    state_machine,
    char_meshes,
    selected_material, deselected_material,
    origin, scale, letter_height, transform_selected, letter_width,
    select_animation_time, explode_animation_time)
  local self = create_class_instance(Menu)

  self.menu_items_ = {}
  self.selected_item_index_ = 1

  self.state_machine_ = state_machine
  self.char_meshes_ = char_meshes
  self.selected_material_ = selected_material
  self.deselected_material_ = deselected_material

  origin = origin or { x = 0, y = 0, z = 0 }
  self.deselected_origin_ = jumpman.Vector3.new(origin.x, origin.y, origin.z)

  local t_sel = transform_selected or { x = 0, y = 0, z = -5 }
  self.selected_origin_ = self.deselected_origin_
    + jumpman.Vector3.new(t_sel.x, t_sel.y, t_sel.z)

  scale = scale or { x = 1, y = 1, z = 1 }
  self.scale_ = jumpman.Vector3.new(scale.x, scale.y, scale.z)

  self.letter_height_ = letter_height or 8
  self.letter_width_ = letter_width or 5
  self.select_animation_time_ = select_animation_time or 0.125
  self.explode_animation_time_ = explode_animation_time or 1.275
  self.elapsed_explode_animation_time_ = 0

  self.is_selection_locked_in_ = false

  return self
end

function Menu:add_item(message, next_state_name, ...)
  table.insert(self.menu_items_, {
    string = create_string_object(
      self.char_meshes_, scene_root, message, self.deselected_material_),
    select_tween_weight = 1,
    next_state_name = next_state_name,
    next_state_args = arg
  })

  return self
end

function Menu:select(new_index)
  if not self.is_selection_locked_in_
      and self.selected_item_index_ ~= index then

    if new_index < 1 then
      new_index = #self.menu_items_ + new_index
    elseif new_index > #self.menu_items_ then
      new_index = new_index - #self.menu_items_
    end

    local old_menu_item = self.menu_items_[self.selected_item_index_]
    old_menu_item.select_tween_weight = 1 - old_menu_item.select_tween_weight

    local new_menu_item = self.menu_items_[new_index]
    new_menu_item.select_tween_weight = 1 - new_menu_item.select_tween_weight

    self.selected_item_index_ = new_index
  end
end

function Menu:select_next()
  self:select(self.selected_item_index_ + 1)
end

function Menu:select_previous()
  self:select(self.selected_item_index_ - 1)
end

function Menu:lock_selection()
  if not self.is_selection_locked_in_ then
    self.is_selection_locked_in_ = true
    self.elapsed_explode_animation_time_ = 0

    for item_index, menu_item in ipairs(self.menu_items_) do
      menu_item.select_tween_weight = 1
    end
  end
end

function Menu:update(elapsed_seconds)
  if self.is_selection_locked_in_ then
    local animation_time = self.elapsed_explode_animation_time_
      + elapsed_seconds

    if animation_time > self.explode_animation_time_ then
      animation_time = self.explode_animation_time_
    end

    self.elapsed_explode_animation_time_ = animation_time
  end

  for item_index, menu_item in ipairs(self.menu_items_) do
    local num_letters = #menu_item.string.children
    local fudge_factor = 3
    local item_width = num_letters * self.letter_width_ - fudge_factor
    local is_selected = self.selected_item_index_ == item_index

    -- Menu item texture based on if it is selected
    local current_material = is_selected
      and self.selected_material_
      or self.deselected_material_

    -- Menu item base position based on if it is selected
    local select_tween_weight = menu_item.select_tween_weight
      + elapsed_seconds / self.select_animation_time_

    if select_tween_weight > 1 then
      select_tween_weight = 1
    end

    menu_item.select_tween_weight = select_tween_weight

    if not is_selected then
      select_tween_weight = 1 - select_tween_weight
    end

    local menu_item_origin = jumpman.mix(
      self.deselected_origin_, self.selected_origin_, select_tween_weight)

    for letter_index = 1, #menu_item.string.children do
      local letter_position = jumpman.Vector3.new(
        -item_width / 2 + (letter_index - 1) * self.letter_width_,
        -(item_index - 1) * self.letter_height_,
        0)
      local letter = menu_item.string.children[letter_index]
      local transform = letter.transform
      transform.translation = menu_item_origin + letter_position
      transform.scale = self.scale_

      if self.is_selection_locked_in_ then
        if is_selected then
          local letter_rotation = math.pi * (
            200 * self.elapsed_explode_animation_time_ * 4
              - letter_position.x * 4 + 10) / 180

          if letter_rotation > math.pi * 2 then
            letter_rotation = 0
          end

          transform:set_angle_axis_rotation(
            letter_rotation, jumpman.Vector3.unit_x())
        else
          local absolute_letter_x = transform.translation.x
          transform:translate(
            self.elapsed_explode_animation_time_
              * 100 * math.sin(absolute_letter_x * 27 * math.pi / 180),
            self.elapsed_explode_animation_time_
              * 100 * math.sin(absolute_letter_x * 59 * math.pi / 180),
            self.elapsed_explode_animation_time_ * 40 / 3)
          transform:set_angle_axis_rotation(
            (200 * self.elapsed_explode_animation_time_ + absolute_letter_x)
              * math.pi / 180,
            jumpman.Vector3.unit_z())
        end
      end

      letter.mesh_component.material = current_material
    end
  end
end

function Menu:is_finished()
  return self.elapsed_explode_animation_time_ >= self.explode_animation_time_
end

function Menu:finish()
  self.is_selection_locked_in_ = true
  self.elapsed_explode_animation_time_ = self.explode_animation_time_

  local menu_item = self.menu_items_[self.selected_item_index_]

  if menu_item.next_state_name then
    return self.state_machine_:enter(
      menu_item.next_state_name,
      menu_item.next_state_args)
  end
end

function Menu:reset()
  self.is_selection_locked_in_ = false
  self.elapsed_explode_animation_time_ = 0

  for item_index, menu_item in ipairs(self.menu_items_) do
    menu_item.select_tween_weight = 1

    for letter_index = 1, #menu_item.string.children do
      local transform = menu_item.string.children[letter_index].transform
      transform.orientation = jumpman.Quaternion.new()
    end
  end
end

function Menu:hide()
  for item_index, menu_item in ipairs(self.menu_items_) do
    menu_item.string.mesh_component.is_visible = false
  end
end

function Menu:show()
  for item_index, menu_item in ipairs(self.menu_items_) do
    menu_item.string.mesh_component.is_visible = true
  end
end

local scene_objects = load_level_scene_objects(scene_root, level)
local mod_list = jumpman.ModList.load()
local char_meshes = load_char_meshes(context)

local camera = scene.camera
camera.transform:set_translation(80, 80, -100)
camera.transform:look_at(80, 80, 0)

local menu_state = StateMachine.new()

local sky_scroller = MaterialScroller.new(
  context:find_material("0"),
  jumpman.Vector3.new(-0.025, 0.025, 0))

local jumpman_title = FallingTitle.new(
  char_meshes,
  "JUMPMAN",
  context:find_material("7"),
  {
    [1] = 22,
    [5] = 54,
    [2] = 76,
    [3] = 80,
    [4] = 84,
    [6] = 82,
    [7] = 78,
  })

local zbits = ZBits.new(
  scene_objects.donuts, context:find_mesh("0"), context:find_texture("6"))

local top_menu = Menu.new(
    menu_state,
    char_meshes,
    context:find_material("1"),
    context:find_material("2"),
    { x = 80, y = 64, z = 0 },
    { x = 0.7, y = 0.7, z = 1 },
    8)
  :add_item("START GAME", "SelectingModMenu")
  :add_item("OPTIONS", "SelectingOptionMenu")

local mod_menu = Menu.new(
  menu_state,
  char_meshes,
  context:find_material("1"),
  context:find_material("2"),
  { x = 80, y = 100, z = 0 },
  { x = 0.7, y = 0.7, z = 1 },
  15)

for mod_index = 1, #mod_list.builtin do
  local mod = mod_list.builtin[mod_index]
  -- TODO: Correct state name, param
  mod_menu:add_item(mod.title)
end

for mod_index = 1, #mod_list.discovered do
  local mod = mod_list.discovered[mod_index]
  -- TODO: Correct state name, param
  mod_menu:add_item(mod.title)
end

local enter_animate_title = function()
  top_menu:hide()
  mod_menu:hide()
  jumpman_title:show()
  zbits:show()
  return true
end

local animate_title = function(elapsed_seconds)
  if input:get_digital_action_state("menu_cancel").was_just_pressed then
    return false
  end

  local is_animation_finished = jumpman_title:is_finished()
    and zbits:is_finished()

  if is_animation_finished
      or input:get_digital_action_state("menu_select").was_just_pressed then
    menu_state:enter("SelectingTopMenu")
    return true
  end

  jumpman_title:update(elapsed_seconds)
  zbits:update(elapsed_seconds)

  return true
end

local enter_select_top_menu = function()
  mod_menu:hide()

  jumpman_title:finish()
  zbits:finish()
  jumpman_title:show()
  zbits:show()

  top_menu:reset()
  top_menu:show()
  return true
end

local select_top_menu = function(elapsed_seconds)
  if input:get_digital_action_state("menu_cancel").was_just_pressed then
    return false
  end

  if input:get_digital_action_state("menu_down").was_just_pressed then
    top_menu:select_next()
  elseif input:get_digital_action_state("menu_up").was_just_pressed then
    top_menu:select_previous()
  elseif input:get_digital_action_state("menu_select").was_just_pressed then
    menu_state:enter("AnimatingTopMenuSelected")
    return true
  end

  top_menu:update(elapsed_seconds)

  return true
end

local enter_animate_top_menu_selected = function()
  top_menu:lock_selection()
  return true
end

local animate_top_menu_selected = function(elapsed_seconds)
  if input:get_digital_action_state("menu_cancel").was_just_pressed then
    return false
  end

  if top_menu:is_finished() then
    top_menu:finish()
    return true
  end

  top_menu:update(elapsed_seconds)

  return true
end

local enter_select_mod_menu = function()
  -- TODO: If only one mod, switch straight to next state, and return false.
  --       Or should that be part of the menu class functionality?
  jumpman_title:hide()
  zbits:hide()
  top_menu:hide()

  mod_menu:reset()
  mod_menu:show()
  return true
end

local select_mod_menu = function(elapsed_seconds)
  if input:get_digital_action_state("menu_cancel").was_just_pressed then
    menu_state:enter("SelectingTopMenu")
    return true
  end

  if input:get_digital_action_state("menu_down").was_just_pressed then
    mod_menu:select_next()
  elseif input:get_digital_action_state("menu_up").was_just_pressed then
    mod_menu:select_previous()
  elseif input:get_digital_action_state("menu_select").was_just_pressed then
    menu_state:enter("AnimatingModMenuSelected")
    return true
  end

  mod_menu:update(elapsed_seconds)

  return true
end

local enter_animate_mod_menu_selected = function()
  mod_menu:lock_selection()
  return true
end

local animate_mod_menu_selected = function(elapsed_seconds)
  if input:get_digital_action_state("menu_cancel").was_just_pressed then
    menu_state:enter("SelectingTopMenu")
    return true
  end

  if mod_menu:is_finished() then
    mod_menu:finish()
    return true
  end

  mod_menu:update(elapsed_seconds)

  return true
end

local enter_select_option_menu = function()
  jumpman_title:hide()
  zbits:hide()
  top_menu:hide()

  -- TODO: Show options menu
  return true
end

local select_option_menu = function(elapsed_seconds)
  if input:get_digital_action_state("menu_cancel").was_just_pressed then
    menu_state:enter("SelectingTopMenu")
    return true
  end

  -- TODO: Implement

  return true
end

local enter_animate_option_menu_exited = function()
  -- TODO: Implement
  return true
end

local animate_option_menu_exited = function(elapsed_seconds)
  if input:get_digital_action_state("menu_cancel").was_just_pressed then
    menu_state:enter("SelectingTopMenu")
    return true
  end

  -- TODO: Implement

  return true
end

menu_state
  :add_state("AnimatingTitle", {
    enter = enter_animate_title,
    update = animate_title,
  })
  :add_state("SelectingTopMenu", {
    enter = enter_select_top_menu,
    update = select_top_menu,
  })
  :add_state("AnimatingTopMenuSelected", {
    enter = enter_animate_top_menu_selected,
    update = animate_top_menu_selected,
  })
  :add_state("SelectingModMenu", {
    enter = enter_select_mod_menu,
    update = select_mod_menu,
  })
  :add_state("AnimatingModMenuSelected", {
    enter = enter_animate_mod_menu_selected,
    update = animate_mod_menu_selected,
  })
  :add_state("SelectingOptionMenu", {
    enter = enter_select_option_menu,
    update = select_option_menu,
  })
  :add_state("AnimatingOptionMenuExited", {
    enter = enter_animate_option_menu_exited,
    update = animate_option_menu_exited,
  })

menu_state:enter("AnimatingTitle")

function update(elapsed_seconds)
  input:activate_action_set("MenuControls")

  sky_scroller:update(elapsed_seconds)

  return menu_state:update(elapsed_seconds)
end
