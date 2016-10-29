local mod_data = jumpman.mod_data

for i, levelset in ipairs(mod_data) do
  print("title:", levelset["title"])

  for i, level in ipairs(levelset["levels"]) do
    print("  title:", level["title"])
    print("  entrypoint:", level["entrypoint"])
  end
end

function update(elapsed_seconds)
  return true
end
