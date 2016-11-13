function create_scene_object(object, allow_nil)
  local scene_object = jumpman.SceneObject.new()

  if not allow_nil or object.mesh or object.material or object.bounding_box then
    local mesh_component = jumpman.MeshComponent.new()

    if not allow_nil or object.mesh then
      mesh_component.mesh = object.mesh
    end

    if object.bounding_box then
      mesh_component.bounding_box = object.bounding_box
    end

    if not allow_nil or object.material then
      mesh_component.material = object.material
    end

    scene_object.mesh_component = mesh_component
  end

  local origin = object.origin or jumpman.Vector3.new()
  scene_object.transform.translation = origin

  return scene_object
end
