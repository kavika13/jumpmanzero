StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new()
  local self = create_class_instance(StateMachine)

  self.states_ = {}
  self.current_state_ = nil
  self.current_state_name_ = nil
  self.state_stack_ = {}

  return self
end

function StateMachine:add_state(state_name, state)
  local enter_function = state.enter
  local update_function = state.update
  local enter_type = type(enter_funtion)
  local update_type = type(update_function)

  if not enter_type == 'function' then
    enter("State: '" .. state_name .. "'"
      .. " has invalid enter function type: '" .. enter_type .. "'")
  end

  if not update_type == 'function' then
    enter("State: '" .. state_name .. "'"
      .. " has invalid update function type: '" .. update_type .. "'")
  end

  self.states_[state_name] = {
    enter = enter_function,
    update = update_function,
    -- TODO: Would leave() function allow states to be more modular?
  }

  return self
end

function StateMachine:enter(state_name, ...)
  local next_state = self.states_[state_name]

  if not next_state then
    error("Invalid state name: " .. state_name)
  end

  result = next_state.enter(...)

  if result then
    self.current_state_ = next_state
    table.remove(self.state_stack_)
    table.insert(self.state_stack_, next_state)
  end

  return result
end

function StateMachine:push(state_name, ...)
  local next_state = self.states_[state_name]

  if not next_state then
    error("Invalid state name: " .. state_name)
  end

  result = next_state.enter(...)

  if result then
    self.current_state_ = next_state
    table.insert(self.state_stack_, next_state)
  end

  return result
end

function StateMachine:pop(...)
  local next_state = self.state_stack_[#self.state_stack_ - 1]

  if not next_state then
    error("Must have parent state to pop from state stack")
  end

  result = next_state.enter(...)

  if result then
    self.current_state_ = next_state
    table.remove(self.state_stack_)
  end

  return result
end

function StateMachine:update(...)
  return self.current_state_.update(...)
end

function StateMachine:current_state()
  return self.current_state_
end

function StateMachine:current_state_name()
  return self.current_state_name_
end
