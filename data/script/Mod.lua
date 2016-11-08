function load_mod_scene_objects(scene_root, mod)
  local load_scene_object = function(mod_objects, scene_objects)
    for i, mod_object in pairs(mod_objects) do
      local scene_object = create_scene_object(mod_object)
      scene_root:add_child(scene_object)
      table.insert(scene_objects, scene_object)
    end
  end

  local quad_objects = {}
  load_scene_object(mod.quads, quad_objects)

  return {
    quads = quad_objects,
  }
end
