local level = jumpman.Level.load("data/level/Level1.json")
local context = jumpman.resource_context
local scene = jumpman.scene

function bind_to_scene(object)
  local mesh_component = jumpman.MeshComponent.new()
  mesh_component.mesh = object.mesh
  mesh_component.material = object.material

  local scene_object = jumpman.SceneObject.new()
  scene_object.mesh_component = mesh_component
  scene_object.transform.translation = object.origin

  scene:add_object(scene_object)

  return scene_object
end

local quad_objects = {}
for i, quad in pairs(level.quads) do
  table.insert(quad_objects, bind_to_scene(quad))
end

local donut_objects = {}
for i, donut in pairs(level.donuts) do
  table.insert(donut_objects, bind_to_scene(donut))
end

local platform_objects = {}
for i, platform in pairs(level.platforms) do
  table.insert(platform_objects, bind_to_scene(platform))
end

local wall_objects = {}
for i, wall in pairs(level.walls) do
  table.insert(wall_objects, bind_to_scene(wall))
end

local ladder_objects = {}
for i, ladder in pairs(level.ladders) do
  table.insert(ladder_objects, bind_to_scene(ladder))
end

local vine_objects = {}
for i, vine in pairs(level.vines) do
  table.insert(vine_objects, bind_to_scene(vine))
end

local bullets = {}

table.insert(bullets, bind_to_scene({
  mesh=context:find_mesh("0"),
  material=context:find_material("4"),
  origin=jumpman.Vector3.new(),
}))

table.insert(bullets, bind_to_scene({
  mesh=context:find_mesh("1"),
  material=context:find_material("4"),
  origin=jumpman.Vector3.new(),
}))

local camera = scene.camera
camera.projection_matrix = jumpman.Matrix.new_perspective(
  45,
  640 / 480,  -- TODO: Get actual window values
  0.1, 300.0)
camera.transform:set_translation(80, 103, -115)
camera.transform:look_at(80, 63, 0)

function update(elapsed_seconds)
  -- print("got here:", elapsed_seconds)
end
