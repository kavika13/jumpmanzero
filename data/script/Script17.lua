local context = jumpman.resource_context
local scene = jumpman.scene
local scene_root = jumpman.scene_root
local input = jumpman.input
local level = jumpman.level

local scene_objects = load_level_scene_objects(scene_root, level)

local camera = scene.camera
camera.transform:set_translation(80, 80 + 40, -115)
camera.transform:look_at(80, 80, 0)

function update(elapsed_seconds)
  input:activate_action_set("GameControls")

  -- TODO: Remove these temporary testing controls
  if input:get_digital_action_state("toggle_menu").was_just_pressed then
    return false
  end

  local translation = input:get_digital_action_state("jump").is_pressed
    and 70
    or 20
  translation = translation * elapsed_seconds

  if input:get_digital_action_state("move_up").is_pressed then
    camera.transform:translate(0, translation, 0)
  elseif input:get_digital_action_state("move_down").is_pressed then
    camera.transform:translate(0, -translation, 0)
  elseif input:get_digital_action_state("move_left").is_pressed then
    camera.transform:translate(-translation, 0, 0)
  elseif input:get_digital_action_state("move_right").is_pressed then
    camera.transform:translate(translation, 0, 0)
  elseif input:get_digital_action_state("attack").was_just_pressed then
    return false
  end

  return true
end
