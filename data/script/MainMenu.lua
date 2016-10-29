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
    letter.is_enabled = false
  end
end

function FallingTitle:show()
  for i = 1, #self.string_.children do
    local letter = self.string_.children[i]
    letter.is_enabled = true
  end
end

-- Begin actual script
local scene_objects = load_level_scene_objects(scene_root, level)
local char_meshes = load_char_meshes(context)
local mod_list = jumpman.ModList.load()
local running_mod

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
    scene_root,
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
  scene_root,
  context:find_material("1"),
  context:find_material("2"),
  { x = 80, y = 100, z = 0 },
  { x = 1, y = 1, z = 1 },
  15,
  7,
  { x = 0, y = 0, z = -15 })

for mod_index = 1, #mod_list.builtin do
  local mod = mod_list.builtin[mod_index]
  mod_menu:add_item(mod.title, "RunningMod", "builtin", mod_index)
end

for mod_index = 1, #mod_list.discovered do
  local mod = mod_list.discovered[mod_index]
  mod_menu:add_item(mod.title, "RunningMod", "discovered", mod_index)
end

local enter_animate_title = function()
  camera.transform:set_translation(80, 80, -100)
  camera.transform:look_at(80, 80, 0)
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
  camera.transform:set_translation(80, 80, -100)
  camera.transform:look_at(80, 80, 0)
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

local enter_run_mod = function(list_name, mod_index)
  local mod_lists = {
    builtin = mod_list.builtin,
    discovered = mod_list.discovered,
  }
  local mod = mod_lists[list_name][mod_index]
  running_mod = jumpman.ScriptContext.load_mod(mod)
  scene_root.is_enabled = false
  mod_menu:hide()
  return true
end

local run_mod = function(elapsed_seconds)
  if input:get_digital_action_state("toggle_menu").was_just_pressed then
    running_mod.scene_root.is_enabled = false
    scene_root.is_enabled = true
    -- Call update to let mod hide sub-UI - TODO: Make it so it doesn't have to?
    running_mod:update(elapsed_seconds)
    menu_state:enter("SelectingTopMenu")  -- TODO: Different menu while in mod?
    return true
  end

  if not running_mod:update(elapsed_seconds) then
    scene:remove_child(running_mod.scene_root)
    running_mod = nil
    scene_root.is_enabled = true
    menu_state:enter("SelectingTopMenu")
  end

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
  :add_state("RunningMod", {
    enter = enter_run_mod,
    update = run_mod,
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

  if scene_root.is_enabled then
    sky_scroller:update(elapsed_seconds)
  end

  return menu_state:update(elapsed_seconds)
end
