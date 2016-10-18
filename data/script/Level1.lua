-- local bullets = {}

-- local bullet_shell = create_scene_object({
--   mesh = context:find_mesh("0"),
--   material = context:find_material("4"),
--   origin = jumpman.Vector3.new(),
--   rotation = {
--     angle = math.pi / 2,
--     axis = jumpman.Vector3.new(0, 1, 0)
--   }
-- })
-- bullet_shell.transform:set_angle_axis_rotation(
--   math.pi / 2, jumpman.Vector3.new(0, 1, 0))

-- local bullet_slug = create_scene_object({
--   mesh = context:find_mesh("1"),
--   material = context:find_material("4"),
--   origin = jumpman.Vector3.new(),
-- })
-- local bullet_scene_object = jumpman.SceneObject.new()
-- bullet_scene_object:add_child(bullet_shell)
-- bullet_scene_object:add_child(bullet_slug)
-- bullet_scene_object.transform:set_translation(80, 80, 0)

-- scene:add_object(bullet_scene_object)

-- table.insert(bullets, bullet_scene_object)

function update(elapsed_seconds)
  -- bullet_scene_object.transform:rotate_on_angle_axis(
  --   math.pi * 2 * elapsed_seconds, jumpman.Vector3.new(0, 1, 0))
end
