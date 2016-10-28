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
