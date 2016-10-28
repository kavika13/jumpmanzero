local main_menu_level = jumpman.Level.load("data/level/MainMenu.json")

function update(elasped_seconds)
  return main_menu_level.main_script:update(elasped_seconds)
end
