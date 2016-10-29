local context = jumpman.ScriptContext.load_level("data/level/MainMenu.json")

function update(elasped_seconds)
  return context:update(elasped_seconds)
end
