local context = jumpman.resource_context
local scene = jumpman.scene
local scene_root = jumpman.scene_root
local input = jumpman.input
local level = jumpman.level
local mod_data = jumpman.mod_data

local scene_objects = load_level_scene_objects(scene_root, level)
local char_meshes = load_char_meshes(context)
local mod_list = jumpman.ModList.load()
local running_level_set
local running_level
local running_level_index = 0

local camera = scene.camera
camera.transform:set_translation(80, 80, -100)
camera.transform:look_at(80, 80, 0)

local menu_state = StateMachine.new()

local sky_scroller = MaterialScroller.new(
  context:find_material("0"),
  jumpman.Vector3.new(-0.025, 0.025, 0))

local level_set_menu = Menu.new(
    menu_state,
    char_meshes,
    scene_root,
    context:find_material("1"),
    context:find_material("3"),
    context:find_sound("0"),
    context:find_sound("1"),
    { x = 80, y = 100, z = 0 },
    { x = 1, y = 1, z = 1 },
    15,
    6.1,
    { x = 0, y = 0, z = -15 })

for i, level_set in pairs(mod_data) do
  level_set_menu:add_item(level_set.title, "RunningLevelSet", level_set)
end

local enter_select_level_set = function()
  level_set_menu:reset()
  level_set_menu:show()
  return true
end

local select_level_set = function(elapsed_seconds)
  if input:get_digital_action_state("menu_down").was_just_pressed then
    level_set_menu:select_next()
  elseif input:get_digital_action_state("menu_up").was_just_pressed then
    level_set_menu:select_previous()
  elseif input:get_digital_action_state("menu_select").was_just_pressed then
    menu_state:enter("AnimatingLevelSetSelected")
    return true
  end

  level_set_menu:update(elapsed_seconds)

  return true
end

local enter_animate_level_set_selected = function()
  level_set_menu:lock_selection()
  return true
end

local animate_level_set_selected = function(elapsed_seconds)
  if level_set_menu:is_finished() then
    level_set_menu:advance_state()
    return true
  end

  level_set_menu:update(elapsed_seconds)

  return true
end

local enter_run_level_set = function(level_set)
  scene:remove_child(scene_root)

  if running_level then
    scene:remove_child(running_level.scene_root)
  end

  -- TODO: Create states for levels?
  running_level_set = level_set

  if running_level_index < #running_level_set.levels then
    running_level_index = running_level_index + 1
    running_level = jumpman.ScriptContext.load_level(
      level_set.levels[running_level_index].filename)
    return true
  end

  return false
end

local run_level_set = function(elapsed_seconds)
  if input:get_digital_action_state("toggle_menu").was_just_pressed then
    running_level.scene_root.is_enabled = false
    return true
  end

  if not running_level:update(elapsed_seconds) then
    return menu_state:enter("RunningLevelSet", running_level_set)
  end

  return true
end

menu_state
  :add_state("SelectingLevelSet", {
    enter = enter_select_level_set,
    update = select_level_set,
  })
  :add_state("AnimatingLevelSetSelected", {
    enter = enter_animate_level_set_selected,
    update = animate_level_set_selected,
  })
  :add_state("RunningLevelSet", {
    enter = enter_run_level_set,
    update = run_level_set,
  })

menu_state:enter("SelectingLevelSet")

function update(elapsed_seconds)
  input:activate_action_set("MenuControls")

  if scene_root.is_enabled then
    sky_scroller:update(elapsed_seconds)
  end

  return menu_state:update(elapsed_seconds)
end
