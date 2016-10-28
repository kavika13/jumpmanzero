MaterialScroller = {}
MaterialScroller.__index = MaterialScroller

function MaterialScroller.new(material, translation_per_second)
  local self = create_class_instance(MaterialScroller)

  self.material_ = material
  self.translation_per_second_ = translation_per_second
  self.total_elapsed_seconds_ = 0

  return self
end

function MaterialScroller:update(elapsed_seconds)
  self.total_elapsed_seconds_ = self.total_elapsed_seconds_ + elapsed_seconds
  self.material_.texture_transform:set_translation(
    self.translation_per_second_ * self.total_elapsed_seconds_)
end
