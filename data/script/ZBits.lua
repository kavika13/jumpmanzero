ZBits = {}
ZBits.__index = ZBits

function ZBits.new(base_objects, mesh, texture, animation_time)
  local self = create_class_instance(ZBits)

  self.objects_ = {}
  self.begin_positions_ = {}
  self.end_positions_ = {}
  self.animation_time_ = animation_time or 5.5
  self.total_elapsed_seconds_ = 0

  for i, object in ipairs(base_objects) do
    local end_position = object.transform.translation
      + jumpman.Vector3.new(0, -2, 0)
    local begin_position = end_position
      + jumpman.Vector3.new(
          math.random(-100, 100),
          math.random(-100, 100),
          -500)

    table.insert(self.objects_, object)
    table.insert(self.begin_positions_, begin_position)
    table.insert(self.end_positions_, end_position)

    local mesh_component = object.mesh_component
    mesh_component.mesh = mesh
    mesh_component.material.texture = texture

    local transform = object.transform
    transform:set_scale(4, 4, 4)
    transform.translation = begin_position
  end

  return self
end

function ZBits:update(elapsed_seconds)
  self.total_elapsed_seconds_ = self.total_elapsed_seconds_ + elapsed_seconds
  local animation_scale = self.total_elapsed_seconds_ / self.animation_time_

  if animation_scale > 1 then
    animation_scale = 1
  end

  for i, object in ipairs(self.objects_) do
    local transform = object.transform
    transform.translation = jumpman.mix(
      self.begin_positions_[i], self.end_positions_[i], animation_scale)
    transform:set_angle_axis_rotation(
      (1 - animation_scale) * math.sin(i * math.pi / 180) * 10,
      jumpman.Vector3.unit_y())
  end
end

function ZBits:finish()
  self.total_elapsed_seconds_ = self.animation_time_
  self:update(0)
end

function ZBits:is_finished()
  return self.total_elapsed_seconds_ >= self.animation_time_
end

function ZBits:hide()
  for item_index, zbit in ipairs(self.objects_) do
    zbit.is_enabled = false
  end
end

function ZBits:show()
  for item_index, zbit in ipairs(self.objects_) do
    zbit.is_enabled = true
  end
end
