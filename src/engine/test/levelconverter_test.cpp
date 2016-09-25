#include <fstream>
#include <string>
#include "levelconverter.hpp"
#include "./catch.hpp"

SCENARIO ("load old level files and verify there are no errors",
          "[dataconversion]") {
  std::string level_directory = "data/level";

  GIVEN ("Blank.lvl") {
    const std::string level_filename = level_directory + "/Blank.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (16 == converter.resources.size());
        REQUIRE (2 == converter.objects.size());
      }
    }
  }

  GIVEN ("Ending.lvl") {
    const std::string level_filename = level_directory + "/Ending.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (78 == converter.resources.size());
        REQUIRE (2 == converter.objects.size());
      }
    }
  }

  GIVEN ("GameOver.lvl") {
    const std::string level_filename = level_directory + "/GameOver.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (17 == converter.resources.size());
        REQUIRE (2 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level1.lvl") {
    const std::string level_filename = level_directory + "/Level1.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (17 == converter.resources.size());
        REQUIRE (51 == converter.objects.size());
      }
    }

    WHEN ("the conversion is done") {
      auto converter = LevelConverter::FromStream(level);
      LevelData data = converter.Convert();

      THEN ("correct level objects and resources to have been converted") {
        REQUIRE ("1" == data.main_script_tag);
        REQUIRE ("2" == data.donut_script_tag);
        REQUIRE ("1" == data.background_track_tag);
        REQUIRE ("2" == data.death_track_tag);
        REQUIRE ("3" == data.end_level_track_tag);

        REQUIRE (2 == data.scripts.size());
        REQUIRE (ScriptResourceData({ "Script1.lua", "1" }) == data.scripts[0]);
        REQUIRE (ScriptResourceData({ "Bullet.lua", "2" }) == data.scripts[1]);

        REQUIRE (2 == data.meshes.size());
        REQUIRE (MeshResourceData({ "Bullet1.msh", "0" }) == data.meshes[0]);
        REQUIRE (MeshResourceData({ "Bullet2.msh", "1" }) == data.meshes[1]);

        REQUIRE (6 == data.textures.size());
        REQUIRE (
          TextureResourceData({ "Jumpman.bmp", "0" }) == data.textures[0]);
        REQUIRE (
          TextureResourceData({ "ClassicPlatform.bmp", "1" })
          == data.textures[1]);
        REQUIRE (
          TextureResourceData({ "BlueMarble.bmp", "2" }) == data.textures[2]);
        REQUIRE (
          TextureResourceData({ "RedMetal.bmp", "3" }) == data.textures[3]);
        REQUIRE (
          TextureResourceData({ "Bullet.bmp", "4" }) == data.textures[4]);
        REQUIRE (TextureResourceData({ "sky.jpg", "5" }) == data.textures[5]);

        REQUIRE (3 == data.music.size());
        REQUIRE (MusicResourceData({ "L1.mid", "1", 1200 }) == data.music[0]);
        REQUIRE (MusicResourceData({ "death.mid", "2" }) == data.music[1]);
        REQUIRE (MusicResourceData({ "ENDLEVEL.mid", "3" }) == data.music[2]);

        REQUIRE (4 == data.sounds.size());
        REQUIRE (SoundResourceData({ "Jump.wav", "0" }) == data.sounds[0]);
        REQUIRE (SoundResourceData({ "chomp.wav", "1" }) == data.sounds[1]);
        REQUIRE (SoundResourceData({ "bonk.wav", "2" }) == data.sounds[2]);
        REQUIRE (SoundResourceData({ "Fire.wav", "3" }) == data.sounds[3]);

        REQUIRE (1 == data.quads.size());
        REQUIRE (
          QuadObjectData({
            "0", "5", 77.5f, 30.0f,
            {
              VertexData({ -100.0f, 200.0f, 80.0f, 0.0f, 0.0f }),
              VertexData({ 255.0f, 200.0f, 80.0f, 1.0f, 0.0f }),
              VertexData({ -100.0f, -140.0f, 80.0f, 0.0f, 1.0f }),
              VertexData({ 255.0f, -140.0f, 80.0f, 1.0f, 1.0f }),
            }
          })
          == data.quads[0]);
      }
    }
  }

  GIVEN ("Level10.lvl") {
    const std::string level_filename = level_directory + "/Level10.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (27 == converter.resources.size());
        REQUIRE (42 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level11.lvl") {
    const std::string level_filename = level_directory + "/Level11.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (51 == converter.resources.size());
        REQUIRE (68 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level12.lvl") {
    const std::string level_filename = level_directory + "/Level12.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (21 == converter.resources.size());
        REQUIRE (77 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level13.lvl") {
    const std::string level_filename = level_directory + "/Level13.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (20 == converter.resources.size());
        REQUIRE (58 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level14.lvl") {
    const std::string level_filename = level_directory + "/Level14.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (30 == converter.resources.size());
        REQUIRE (35 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level15.lvl") {
    const std::string level_filename = level_directory + "/Level15.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (21 == converter.resources.size());
        REQUIRE (66 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level16.lvl") {
    const std::string level_filename = level_directory + "/Level16.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (26 == converter.resources.size());
        REQUIRE (69 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level17.lvl") {
    const std::string level_filename = level_directory + "/Level17.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (18 == converter.resources.size());
        REQUIRE (61 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level18.lvl") {
    const std::string level_filename = level_directory + "/Level18.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (34 == converter.resources.size());
        REQUIRE (30 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level19.lvl") {
    const std::string level_filename = level_directory + "/Level19.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (23 == converter.resources.size());
        REQUIRE (47 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level2.lvl") {
    const std::string level_filename = level_directory + "/Level2.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (24 == converter.resources.size());
        REQUIRE (63 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level20.lvl") {
    const std::string level_filename = level_directory + "/Level20.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (35 == converter.resources.size());
        REQUIRE (58 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level21.lvl") {
    const std::string level_filename = level_directory + "/Level21.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (26 == converter.resources.size());
        REQUIRE (28 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level22.lvl") {
    const std::string level_filename = level_directory + "/Level22.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (22 == converter.resources.size());
        REQUIRE (51 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level23.lvl") {
    const std::string level_filename = level_directory + "/Level23.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (29 == converter.resources.size());
        REQUIRE (63 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level24.lvl") {
    const std::string level_filename = level_directory + "/Level24.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (31 == converter.resources.size());
        REQUIRE (83 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level25.lvl") {
    const std::string level_filename = level_directory + "/Level25.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (46 == converter.resources.size());
        REQUIRE (28 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level27.lvl") {
    const std::string level_filename = level_directory + "/Level27.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (40 == converter.resources.size());
        REQUIRE (59 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level3.lvl") {
    const std::string level_filename = level_directory + "/Level3.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (33 == converter.resources.size());
        REQUIRE (73 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level4.lvl") {
    const std::string level_filename = level_directory + "/Level4.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (38 == converter.resources.size());
        REQUIRE (62 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level5.lvl") {
    const std::string level_filename = level_directory + "/Level5.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (22 == converter.resources.size());
        REQUIRE (76 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level6.lvl") {
    const std::string level_filename = level_directory + "/Level6.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (26 == converter.resources.size());
        REQUIRE (70 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level7.lvl") {
    const std::string level_filename = level_directory + "/Level7.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (22 == converter.resources.size());
        REQUIRE (79 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level8.lvl") {
    const std::string level_filename = level_directory + "/Level8.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (19 == converter.resources.size());
        REQUIRE (82 == converter.objects.size());
      }
    }
  }

  GIVEN ("Level9.lvl") {
    const std::string level_filename = level_directory + "/Level9.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (21 == converter.resources.size());
        REQUIRE (49 == converter.objects.size());
      }
    }
  }

  GIVEN ("MainMenu.lvl") {
    const std::string level_filename = level_directory + "/MainMenu.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (16 == converter.resources.size());
        REQUIRE (40 == converter.objects.size());
      }
    }
  }

  GIVEN ("Options.lvl") {
    const std::string level_filename = level_directory + "/Options.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (9 == converter.resources.size());
        REQUIRE (1 == converter.objects.size());
      }
    }
  }

  GIVEN ("SelectGame.lvl") {
    const std::string level_filename = level_directory + "/SelectGame.lvl";
    std::ifstream level(level_filename);

    WHEN ("the load is done") {
      auto converter = LevelConverter::FromStream(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (10 == converter.resources.size());
        REQUIRE (1 == converter.objects.size());
      }
    }
  }
}
