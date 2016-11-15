JumpmanState = {}
JumpmanState.__index = JumpmanState

function JumpmanState.new(input)
  local self = create_class_instance(JumpmanState)

  local function bind(func, instance)
    return function(...) return func(instance, ...) end
  end

  local state_machine = StateMachine.new()
    :add_state("Stand", {
      enter = bind(self.enter_stand, self),
      update = bind(self.stand, self),
    })
    :add_state("Idle", {
      enter = bind(self.enter_idle, self),
      update = bind(self.idle, self),
    })

  self.input_ = input
  self.state_machine_ = state_machine
  self.current_animation_elapsed_seconds_ = 0

  return self
end

function JumpmanState:enter(state_name, ...)
  return self.state_machine_:enter(state_name, ...)
end

function JumpmanState:update(...)
  return self.state_machine_:update(...)
end

function JumpmanState:enter_stand(jumpman_character)
  self.current_animation_elapsed_seconds_ = 0
  jumpman_character:set_model("STAND")
  return true
end

function JumpmanState:stand(jumpman_character, elapsed_seconds)
  local animation_seconds = self.current_animation_elapsed_seconds_
    + elapsed_seconds

  if animation_seconds > 10 then
    self.state_machine_:push("Idle", jumpman_character)
    return true
  end

  self.current_animation_elapsed_seconds_ = animation_seconds

  local input = self.input_
  local is_idle_broken = false

  -- TODO: Transition to movement instead of just breaking idle
  if input:get_digital_action_state("move_up").is_pressed then
    is_idle_broken = true
  elseif input:get_digital_action_state("move_down").is_pressed then
    is_idle_broken = true
  elseif input:get_digital_action_state("move_left").is_pressed then
    is_idle_broken = true
  elseif input:get_digital_action_state("move_right").is_pressed then
    is_idle_broken = true
  end

  if is_idle_broken then
    self.current_animation_elapsed_seconds_ = 0
  end

  return true
end

function JumpmanState:enter_idle(jumpman_character)
  self.current_animation_elapsed_seconds_ = 0
  jumpman_character:set_model("BORED1")
  return true
end

function JumpmanState:idle(jumpman_character, elapsed_seconds)
  local animation_seconds = self.current_animation_elapsed_seconds_
    + elapsed_seconds

  if animation_seconds > 10 then
    self.state_machine_:enter("Idle", jumpman_character)
    return true
  end

  self.current_animation_elapsed_seconds_ = animation_seconds

  local input = self.input_
  local is_idle_broken = false

  if input:get_digital_action_state("move_up").is_pressed then
    is_idle_broken = true
  elseif input:get_digital_action_state("move_down").is_pressed then
    is_idle_broken = true
  elseif input:get_digital_action_state("move_left").is_pressed then
    is_idle_broken = true
  elseif input:get_digital_action_state("move_right").is_pressed then
    is_idle_broken = true
  end

  if is_idle_broken then
    self.state_machine_:pop(jumpman_character)
    return self:update(jumpman_character, elapsed_seconds)
  end

  -- TODO: Implement animation

  return true
end
