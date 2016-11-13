Menu = {}
Menu.__index = Menu

function Menu.new(
    state_machine,
    char_models,
    scene_root,
    selected_material, deselected_material,
    selected_sound, lock_selection_sound,
    origin, scale, letter_height, letter_width, transform_selected,
    select_animation_time, explode_animation_time)
  local self = create_class_instance(Menu)

  self.menu_items_ = {}
  self.selected_item_index_ = 1

  self.state_machine_ = state_machine
  self.char_models_ = char_models
  self.scene_root_ = scene_root
  self.selected_material_ = selected_material
  self.deselected_material_ = deselected_material
  self.selected_sound_ = selected_sound
  self.lock_selection_sound_ = lock_selection_sound

  origin = origin or { x = 0, y = 0, z = 0 }
  self.deselected_origin_ = jumpman.Vector3.new(origin.x, origin.y, origin.z)

  local t_sel = transform_selected or { x = 0, y = 0, z = -5 }
  self.selected_origin_ = self.deselected_origin_
    + jumpman.Vector3.new(t_sel.x, t_sel.y, t_sel.z)

  scale = scale or { x = 1, y = 1, z = 1 }
  self.scale_ = jumpman.Vector3.new(scale.x, scale.y, scale.z)

  self.letter_height_ = letter_height or 8
  self.letter_width_ = letter_width or 5
  self.select_animation_time_ = select_animation_time or 0.25
  self.explode_animation_time_ = explode_animation_time or 1.275
  self.elapsed_explode_animation_time_ = 0

  self.is_selection_locked_in_ = false

  return self
end

function Menu:add_item(message, next_state_name, ...)
  table.insert(self.menu_items_, {
    string = create_string_object(
      self.char_models_, self.scene_root_, message, self.deselected_material_),
    select_tween_weight = 1,
    next_state_name = next_state_name,
    next_state_args = {...}
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

    self.selected_sound_:play()

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

    self.lock_selection_sound_:play()
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

function Menu:advance_state()
  self.is_selection_locked_in_ = true
  self.elapsed_explode_animation_time_ = self.explode_animation_time_

  local menu_item = self.menu_items_[self.selected_item_index_]

  if menu_item.next_state_name then
    return self.state_machine_:enter(
      menu_item.next_state_name,
      table.unpack(menu_item.next_state_args))
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
    menu_item.string.is_enabled = false
  end
end

function Menu:show()
  for item_index, menu_item in ipairs(self.menu_items_) do
    menu_item.string.is_enabled = true
  end
end
