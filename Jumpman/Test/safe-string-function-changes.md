/Jumpman/Basic3D.cpp LoadTexture (line 252)

- Run. Main menu mesh textures (colors and background) should show up at all.

/Jumpman/Jumpman.cpp ExtFunction (SERVICE_SAVEOPTIONS) (line 623, 625)

- Run. Select "Options". Toggle music setting (turn from off to on or whichever). Select "Back"

/Jumpman/Jumpman.cpp ExtFunction (SERVICE_OPTIONSTRING) (line 662)

- Run. Select "Options". Set any key binding to be a letter key.

/Jumpman/Jumpman.cpp ExtFunction (SERVICE_OPTIONSTRING) (line 665)

- Run. Select "Options". Set any key binding to be a number key.

/Jumpman/Jumpman.cpp ExtFunction (SERVICE_OPTIONSTRING) (line 667-674)

- Run. Select "Options". Set any key binding to be the up arrow key.
- Run. Select "Options". Set any key binding to be the down arrow key.
- Run. Select "Options". Set any key binding to be the left arrow key.
- Run. Select "Options". Set any key binding to be the right arrow key.
- Run. Select "Options". Set any key binding to be the space key.
- Hack Settings.DAT so the fifth option down says `58`. Run. Select "Options". Make sure the `:` (colon) displays properly next to the "jump" command.
- Hack Settings.DAT so the fifth option down says `46`. Run. Select "Options". Make sure the `.` (period) displays properly next to the "jump" command.
- Hack Settings.DAT so the fifth option down says `45`. Run. Select "Options". Make sure the `-` (dash) displays properly next to the "jump" command.

/Jumpman/Jumpman.cpp ExtFunction (SERVICE_OPTIONSTRING) (line 679-680)

- Run. Select "Options". Toggle music setting (turn from on to off).
- Run. Select "Options". Toggle music setting (turn from off to on).

/Jumpman/Jumpman.cpp ExtFunction (SERVICE_GAMESTART) (line 696, 703)

- Run. Select "Start Game". Select Beginner, Intermediate, or Advanced. Make sure it starts at the appropriate first level for that difficulty.

/Jumpman/Jumpman.cpp ExtFunction (SERVICE_CREDITLINE) (line 707)

- Run the game will a command line parameter of `ending`. Wait for the whole cinematic to finish and the credits to start rolling. If the credits text appear at all then the credits text loading function is working.

/Jumpman/Jumpman.cpp ExtFunction (SERVICE_GAMELIST) (line 717, 721)

- Run. Select "Start Game". Make sure it lists the correct set of difficulty levels.

/Jumpman/Jumpman.cpp ExtFunction (EFPRINT) (line 761, 763, 765)

- Run the game in the debugger with a command line parameter of `level14`. Check the debug output. It should have the solution to the tetris puzzle spelled out in four lines. (utilizing the '\n' debug output, with the `print(-1)` command)
- Run the game in the debugger with a command line parameter of `level14`. Check the debug output. It should have the solution to the tetris puzzle spelled out in formatted text. (utilizing the ' ' debug output, with the `print(-2)` command)
- Run the game in the debugger with a command line parameter of `level14`. Check the debug output. It should have the solution to the tetris puzzle spelled in numbers. (utilizing the numerical debug output, with the `print(<number>)` command)

/Jumpman/Jumpman.cpp LoadLevel (line 913)

- Run. Main menu will load midi for music.

/Jumpman/Jumpman.cpp LoadLevel (line 915)

- Run. Main menu will load midi for intro ("background") music and play it.

/Jumpman/Jumpman.cpp LoadLevel (line 918-919)

- Run. Main menu will load midi for background ("death") music and play it.
- Run. Select "Start Game". Select a difficulty. Complete map. Success ("win") music will play.

/Jumpman/Jumpman.cpp LoadLevel (line 922)

- Run. Select "Start Game". Select a difficulty. Level mesh will be loaded. (technically the main menu will load a mesh too, but I thought I'd be more picky)

/Jumpman/Jumpman.cpp LoadLevel (line 927)

- Run. Select "Options". Make sure sound is enabled. Return to main menu. Make sure menu movement and select effects are correct. Movement should sound vaguely like a jumpiung sound, and selection should sound like popcorn popping.

/Jumpman/Jumpman.cpp LoadLevel (line 933-936)

- Run. Main menu mesh color textures (BMPs) should show up correctly (Jumpman: orange. Zero: green. Menu items light cyan/blue when hilighted, dark cyan/blue when not).
- Run. Main menu background texture (JPG) should show up correctly (look like cloudy sky).
- Run the game will a command line parameter of `level12`. If the behive texture shows up in the background the PNG texture level resource loader code is working correctly.

/Jumpman/Jumpman.cpp LoadLevel (line 941)

- Run. Main menu script will load and run (MainMenu.bin). If you can navigate the menu and select menu options then it is working.

/Jumpman/Jumpman.cpp LoadLevel (line 1206)

- Run. Main menu level will load. If characters appear correctly then letter meshes were pre-loaded properly.

/Jumpman/Jumpman.cpp LoadLevel (line 1208-1213)

- Hack 1 A.jmg so instead of saying `Easy Does It`, it says `Easy Does it .` Run. Select "Start Game". Select "Beginner". Make sure the `.` (period) displays properly in the level title text.
- Hack 1 A.jmg so instead of saying `Easy Does It`, it says `Easy Does it '` Run. Select "Start Game". Select "Beginner". Make sure the `'` (apostrophe) displays properly in the level title text.
- Hack 1 A.jmg so instead of saying `Easy Does It`, it says `Easy Does it -` Run. Select "Start Game". Select "Beginner". Make sure the `-` (dash) displays properly in the level title text.
- Hack 1 A.jmg so instead of saying `Easy Does It`, it says `Easy Does it :` Run. Select "Start Game". Select "Beginner". Make sure the `:` (colon) displays properly in the level title text.
- Hack 1 A.jmg so instead of saying `Easy Does It`, it says `Easy Does it %` Run. Select "Start Game". Select "Beginner". Make sure the `%` (obelus) displays properly in the level title text.
- Hack 1 A.jmg so instead of saying `Easy Does It`, it says `Easy Does it ^` Run. Select "Start Game". Select "Beginner". Make sure the `^` (caret) displays properly in the level title text.

/Jumpman/Jumpman.cpp LoadLevel (line 1217)

- Run. Main menu level will load. If characters appear correctly then character meshes were pre-loaded properly (for the most part).

/Jumpman/Jumpman.cpp LoadLevel (line 1225, 1228)

- Run. Select "Start Game". Select a difficulty level. Show FPS. Should show with `data/panel.bmp` texture. Look at remaining lives. Should show with `data/panel.bmp` texture
- Run. Select "Start Game". Select a difficulty level. Level name should show with `data/titles.png` texture.

/Jumpman/Jumpman.cpp AnimateDying (line 1527-1528)

- Run. Select "Start Game". Select a difficulty level. Die until all lives depleted. No level title should be displayed on the Game Over screen.
- Run. Select "Start Game". Select a difficulty level. Die until all lives depleted. The game over level should be loaded and run (the cinematic).

/Jumpman/Jumpman.cpp GetLevelName (line 1680)

- Run. Select "Start Game". Select a difficulty level. The "next" level (the first one in the level playlist) should be loaded and run.

/Jumpman/Jumpman.cpp GetFileLine (line 1692)

- Run. Select "Start Game". The difficulty level list should show up with the correct names ("Beginner", "Intermediate", "Advanced"), loaded from the level playlist files.
  - You can also exercise this code by launching the game at all, because it is used when the options config is loaded. Make sure the loaded options are the same as the options you saved, including key bindings, music on/off, sound on/off.

/Jumpman/Jumpman.cpp PrepLevel (line 1716)

- Run. Select "Start Game". Select a difficulty level. Make sure the titles display when the level is started, which will make sure the title.bin script was loaded and run successfully.

/Jumpman/Jumpman.cpp LoadMenu (line 1755)

- Run. Main menu script will load. If the menu animates, you can move around the menu, sounds are played when moving around, and a sound is played when you select a menu option, the "Options" menu is displayed after selecting "Options" or the difficulty level menu is displayed after selecting "Start Game" then the main menu script is loaded and runs correctly.

/Jumpman/Jumpman.cpp PrepLevel (line 1766)

- Run. Select "Options". Options menu script will load. If the menu shows key bindings, and you can set new key bindings, then the options script is loaded and runs correctly.

/Jumpman/Jumpman.cpp PrepLevel (line 1774)

- Run. Select "Start Game". Select game menu script will load. If the list of difficulty levels (level playlists) is displayed and a level is launched when you select a difficulty level, then the select game script is loaded and runs correctly.

/Jumpman/Jumpman.cpp LoadSettings (line 1810)

- Run. Select "Options". Options menu script will load. Set alternate key bindings, save your changes by selecting "Back", and quit out. Run. Select "Options". Options menu will load. If the same settings you saved are displayed here then the settings file was loaded correctly.

/Jumpman/Jumpman.cpp _tWinMain (line 1864)

- Run the game will a command line parameter of `ending` or `level1`. If the appropriate level loads instead of the main menu then the level debug loader code is working correctly.

/Jumpman/Jumpman.cpp LoadMesh (line 1976)

- Run. Main menu level will load. If characters appear correctly then mesh-from-file load function is working properly.

/Jumpman/Utilities.cpp FileToString (line 48)

- Rename Data/Settings.DAT to Settings.DAT. Launch game. See error dialog and make sure it prints correctly
