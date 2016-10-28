function create_scene_object(object, allow_nil)
  local mesh_component = jumpman.MeshComponent.new()

  if not allow_nil or object.mesh then
    mesh_component.mesh = object.mesh
  end

  if not allow_nil or object.material then
    mesh_component.material = object.material
  end

  local scene_object = jumpman.SceneObject.new()
  scene_object.mesh_component = mesh_component

  local origin = object.origin or jumpman.Vector3.new()
  scene_object.transform.translation = origin

  return scene_object
end

function load_level_scene_objects(scene_root, level)
  local load_scene_object = function(level_objects, scene_objects)
    for i, level_object in pairs(level_objects) do
      local scene_object = create_scene_object(level_object)
      scene_root:add_child(scene_object)
      table.insert(scene_objects, scene_object)
    end
  end

  local quad_objects = {}
  load_scene_object(level.quads, quad_objects)

  local donut_objects = {}
  load_scene_object(level.donuts, donut_objects)

  local platform_objects = {}
  load_scene_object(level.platforms, platform_objects)

  local wall_objects = {}
  load_scene_object(level.walls, wall_objects)

  local ladder_objects = {}
  load_scene_object(level.ladders, ladder_objects)

  local vine_objects = {}
  load_scene_object(level.vines, vine_objects)

  return {
    quads = quad_objects,
    donuts = donut_objects,
    platforms = platform_objects,
    walls = wall_objects,
    ladders = ladder_objects,
    vines = vine_objects,
  }
end
