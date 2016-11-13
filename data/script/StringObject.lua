local char_model_cache = {}
local char_models_loaded = false

function load_char_models()
  if char_models_loaded then
    return char_model_cache
  end

  function load_char_model(char)
    char_model_cache[char] = jumpman.Model.new(
      "data/model/Char" .. char .. ".obj", "Char" .. char)
  end

  local char_model_names = {
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

  for i, char in ipairs(char_model_names) do
    load_char_model(char)
  end

  return char_model_cache
end

function create_string_object(char_models, scene_root, text, material)
  local result = jumpman.SceneObject.new()
  result.mesh_component = jumpman.MeshComponent.new()

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
    local char_model = char_models[char_map[char] or char]
    local char_mesh = char_model and char_model.mesh or nil
    local char_bounding_box = char_model and char_model.bounding_box or nil

    local scene_object = create_scene_object({
      mesh = char_mesh,
      bounding_box = char_bounding_box,
      material = material,
    }, true)
    result:add_child(scene_object)
  end

  scene_root:add_child(result)

  return result
end
