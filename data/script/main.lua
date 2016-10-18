local level = jumpman.Level.load("data/level/Level1.json")
local context = jumpman.resource_context
local scene = jumpman.scene

function create_scene_object(object)
  local mesh_component = jumpman.MeshComponent.new()
  mesh_component.mesh = object.mesh
  mesh_component.material = object.material

  local scene_object = jumpman.SceneObject.new()
  scene_object.mesh_component = mesh_component
  scene_object.transform.translation = object.origin

  if (type(object) == "table" and object.rotation) then
    scene_object.transform:set_angle_axis_rotation(
      object.rotation.angle, object.rotation.axis)
  end

  return scene_object
end

local quad_objects = {}
for i, quad in pairs(level.quads) do
  local scene_object = create_scene_object(quad)
  scene:add_object(scene_object)
  table.insert(quad_objects, scene_object)
end

local donut_objects = {}
for i, donut in pairs(level.donuts) do
  local scene_object = create_scene_object(donut)
  scene:add_object(scene_object)
  table.insert(quad_objects, scene_object)
end

local platform_objects = {}
for i, platform in pairs(level.platforms) do
  local scene_object = create_scene_object(platform)
  scene:add_object(scene_object)
  table.insert(quad_objects, scene_object)
end

local wall_objects = {}
for i, wall in pairs(level.walls) do
  local scene_object = create_scene_object(wall)
  scene:add_object(scene_object)
  table.insert(quad_objects, scene_object)
end

local ladder_objects = {}
for i, ladder in pairs(level.ladders) do
  local scene_object = create_scene_object(ladder)
  scene:add_object(scene_object)
  table.insert(quad_objects, scene_object)
end

local vine_objects = {}
for i, vine in pairs(level.vines) do
  local scene_object = create_scene_object(vine)
  scene:add_object(scene_object)
  table.insert(quad_objects, scene_object)
end

local bullets = {}

local bullet_shell = create_scene_object({
  mesh = context:find_mesh("0"),
  material = context:find_material("4"),
  origin = jumpman.Vector3.new(),
  rotation = {
    angle = math.pi / 2,
    axis = jumpman.Vector3.new(0, 1, 0)
  }
})
local bullet_slug = create_scene_object({
  mesh = context:find_mesh("1"),
  material = context:find_material("4"),
  origin = jumpman.Vector3.new(),
})
local bullet_scene_object = jumpman.SceneObject.new()
bullet_scene_object:add_child(bullet_shell)
bullet_scene_object:add_child(bullet_slug)
bullet_scene_object.transform:set_translation(80, 80, 0)

scene:add_object(bullet_scene_object)

table.insert(bullets, bullet_scene_object)

local camera = scene.camera
camera.transform:set_translation(80, 103, -115)
camera.transform:look_at(80, 63, 0)

function update(elapsed_seconds)
  bullet_scene_object.transform:rotate_on_angle_axis(
    math.pi * 2 * elapsed_seconds, jumpman.Vector3.new(0, 1, 0))
end
