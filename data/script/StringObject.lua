local char_mesh_cache = {}
local char_meshes_loaded = false

function load_char_meshes(resource_context)
  if char_meshes_loaded then
    return char_mesh_cache
  end

  function load_char_mesh(char)
    char_mesh_cache[char] = resource_context:load_mesh(
      "data/model/Char" .. char .. ".obj")
  end

  local char_mesh_names = {
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "A",
    "Apos",
    "B",
    "C",
    "Colon",
    "D",
    "Dash",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "Jump",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Period",
    "Q",
    "R",
    "S",
    "Square",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
  }

  for i, char in ipairs(char_mesh_names) do
    load_char_mesh(char)
  end

  return char_mesh_cache
end

function create_string_object(char_meshes, scene_root, text, material)
  local result = create_scene_object({}, true)
  local char_map = {
    ["'"] = "Apos",
    [":"] = "Colon",
    ["-"] = "Dash",
    ["^"] = "Jump",
    ["."] = "Period",
    ["%"] = "Square",
  }

  for i = 1, string.len(text) do
    local char = string.sub(text, i, i):upper()
    local scene_object = create_scene_object({
      mesh = char_meshes[char_map[char] or char],
      material = material,
    }, true)
    result:add_child(scene_object)
  end

  scene_root:add_child(result)

  return result
end
