local context = jumpman.resource_context
local scene = jumpman.scene
local scene_root = jumpman.scene_root
local main_music_track_slot = jumpman.main_music_track_slot
local input = jumpman.input
local level = jumpman.level

local scene_objects = load_level_scene_objects(scene_root, level)
local char_models = load_char_models()
local jumpman_material_tag = "0"
local jumpman_character_models = load_jumpman_character_models(
  context:find_material(jumpman_material_tag))

local camera = scene.camera
camera.transform:set_translation(80, 80 + 40, -115)
camera.transform:look_at(80, 80, 0)

local jumpman_character_state = JumpmanState.new(input)

local jumpman_jump_sound_tag = "0"
local jumpman_death_bounce_sound_tag = "2"
local jumpman_character = JumpmanCharacter.new(
  jumpman_character_state,
  jumpman_character_models,
  scene_root,
  context:find_sound(jumpman_jump_sound_tag),
  context:find_sound(jumpman_death_bounce_sound_tag),
  { x = 80, y = 65, z = 9 })

local background_track = context:find_track(level.background_track_tag)

main_music_track_slot:play_repeating(background_track, 0, 4000)

function update(elapsed_seconds)
  input:activate_action_set("GameControls")

  -- TODO: Remove these temporary testing controls
  if input:get_digital_action_state("toggle_menu").was_just_pressed then
    background_track:pause()
    return false
  end

  local translation = input:get_digital_action_state("jump").is_pressed
    and 70
    or 20
  translation = translation * elapsed_seconds

  if input:get_digital_action_state("move_up").is_pressed then
    camera.transform:translate(0, translation, 0)
  end

  if input:get_digital_action_state("move_down").is_pressed then
    camera.transform:translate(0, -translation, 0)
  end

  if input:get_digital_action_state("move_left").is_pressed then
    camera.transform:translate(-translation, 0, 0)
  end

  if input:get_digital_action_state("move_right").is_pressed then
    camera.transform:translate(translation, 0, 0)
  end

  if input:get_digital_action_state("debug1").is_pressed then
    camera.transform:translate(0, 0, translation)
  end

  if input:get_digital_action_state("debug2").is_pressed then
    camera.transform:translate(0, 0, -translation)
  end

  if input:get_digital_action_state("debug3").was_just_pressed then
    jumpman_character:debug_show_next_model()
  end

  if input:get_digital_action_state("attack").was_just_pressed then
    return false
  end

  jumpman_character:update(elapsed_seconds)

  return true
end
