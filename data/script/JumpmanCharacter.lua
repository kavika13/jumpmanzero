local jumpman_character_model_cache = {}
local jumpman_character_models_loaded = false

function load_jumpman_character_models(character_material)
  if jumpman_character_models_loaded then
    return jumpman_character_model_cache
  end

  function load_jumpman_character_model(model_name)
    local model = jumpman.Model.new(
      "data/model/" .. model_name .. ".obj", "Jumpman" .. model_name)
    model.material = character_material
    jumpman_character_model_cache[model_name:upper()] = model
  end

  local jumpman_character_model_names = {
    "Stand",
    "Left1",
    "Left2",
    "Right1",
    "Right2",

    "JumpUp",
    "JumpLeft",
    "JumpRight",

    "RopeClimb1",
    "RopeClimb2",

    "LadderClimb1",
    "LadderClimb2",

    "KickLeft",
    "KickRight",

    "DiveRight",
    "RollRight1",
    "RollRight2",
    "RollRight3",
    "RollRight4",

    "DiveLeft",
    "RollLEFT1",
    "RollLEFT2",
    "RollLEFT3",
    "RollLEFT4",

    "PunchLeft",
    "PunchRight",
    "PunchLeft2",
    "PunchRight2",

    "Dying",
    "Dead",
    "Stars",

    "SlideR",
    "SlideRB",
    "SlideL",
    "SlideLB",

    "BORED1",
    "BORED2",
    "BORED3",
    "BORED4",
    "BORED5",
  }

  for i, model_name in ipairs(jumpman_character_model_names) do
    load_jumpman_character_model(model_name)
  end

  jumpman_character_models_loaded = true

  return jumpman_character_model_cache
end

JumpmanCharacter = {}
JumpmanCharacter.__index = JumpmanCharacter

function JumpmanCharacter.new(
    state_machine,
    jumpman_character_models,
    scene_root,
    jump_sound,
    death_bounce_sound)
  local self = create_class_instance(JumpmanCharacter)

  local scene_object = create_scene_object({}, true)
  scene_object.mesh_component = jumpman.MeshComponent.new()
  scene_root:add_child(scene_object)

  self.state_machine_ = state_machine
  self.character_models_ = jumpman_character_models
  self.scene_object_ = scene_object
  self.debug_model_index_ = 1
  self.jump_sound_ = jump_sound
  self.death_bounce_sound_ = death_bounce_sound

  state_machine:enter("Stand", self)

  return self
end

-- TODO: Remove this
function JumpmanCharacter:debug_show_next_model()
  local jumpman_character_model_names = {
    "Stand",
    "Left1",
    "Left2",
    "Right1",
    "Right2",

    "JumpUp",
    "JumpLeft",
    "JumpRight",

    "RopeClimb1",
    "RopeClimb2",

    "LadderClimb1",
    "LadderClimb2",

    "KickLeft",
    "KickRight",

    "DiveRight",
    "RollRight1",
    "RollRight2",
    "RollRight3",
    "RollRight4",

    "DiveLeft",
    "RollLEFT1",
    "RollLEFT2",
    "RollLEFT3",
    "RollLEFT4",

    "PunchLeft",
    "PunchRight",
    "PunchLeft2",
    "PunchRight2",

    "Dying",
    "Dead",
    "Stars",

    "SlideR",
    "SlideRB",
    "SlideL",
    "SlideLB",

    "BORED1",
    "BORED2",
    "BORED3",
    "BORED4",
    "BORED5",
  }

  local new_index = self.debug_model_index_ + 1
  if new_index > #jumpman_character_model_names then
    new_index = 1
  end
  self.debug_model_index_ = new_index

  local model = self.character_models_[
    jumpman_character_model_names[new_index]:upper()]

  local mesh_component = self.scene_object_.mesh_component
  mesh_component.mesh = model.mesh
  mesh_component.material = model.material
end

function JumpmanCharacter:set_model(model_name)
  model_name = model_name:upper()

  local model = self.character_models_[model_name]

  if not model then
    error("Failed to find character model with name: " .. model_name)
  end

  local mesh_component = self.scene_object_.mesh_component
  mesh_component.mesh = model.mesh
  mesh_component.material = model.material
end

function JumpmanCharacter:update(elapsed_seconds)
  self.state_machine_:update(self, elapsed_seconds)
end

function JumpmanCharacter:hide()
  self.scene_object_.is_enabled = false
end

function JumpmanCharacter:show()
  self.scene_object_.is_enabled = true
end
