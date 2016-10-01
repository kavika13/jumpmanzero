#include <fstream>
#include <string>
#include "engine/levelconverter.hpp"
#include "catch.hpp"

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

        const std::vector<ScriptResourceData> expected_scripts = {
          { "data/script/Script1.lua", "1" },
          { "data/script/Bullet.lua", "2" },
        };
        REQUIRE (expected_scripts == data.scripts);

        const std::vector<MeshResourceData> expected_meshes = {
          { "data/model/Bullet1.msh", "0" },
          { "data/model/Bullet2.msh", "1" },
        };
        REQUIRE (expected_meshes == data.meshes);

        const std::vector<TextureResourceData> expected_textures = {
          { "data/texture/Jumpman.bmp", "0" },
          { "data/texture/ClassicPlatform.bmp", "1" },
          { "data/texture/BlueMarble.bmp", "2" },
          { "data/texture/RedMetal.bmp", "3" },
          { "data/texture/Bullet.bmp", "4" },
          { "data/texture/sky.jpg", "5" },
        };
        REQUIRE (expected_textures == data.textures);

        const std::vector<MusicResourceData> expected_music = {
          { "data/music/L1.mid", "1", 1200 },
          { "data/music/death.mid", "2" },
          { "data/music/ENDLEVEL.mid", "3" },
        };
        REQUIRE (expected_music == data.music);

        const std::vector<SoundResourceData> expected_sounds = {
          { "data/sound/Jump.wav", "0" },
          { "data/sound/chomp.wav", "1" },
          { "data/sound/bonk.wav", "2" },
          { "data/sound/Fire.wav", "3" },
        };
        REQUIRE (expected_sounds == data.sounds);

        const std::vector<QuadObjectData> expected_quads = {
          {
            "0", "5", 77.5f, 30.0f,
            {
              VertexData({ -100.0f, 200.0f, 80.0f, 0.0f, 0.0f }),
              VertexData({ 255.0f, 200.0f, 80.0f, 1.0f, 0.0f }),
              VertexData({ -100.0f, -140.0f, 80.0f, 0.0f, 1.0f }),
              VertexData({ 255.0f, -140.0f, 80.0f, 1.0f, 1.0f }),
            }
          }
        };
        REQUIRE (expected_quads == data.quads);

        const std::vector<DonutObjectData> expected_donuts = {
          { "2", "3", 138.0f, 137.0f, 15.0f },
          { "1", "3", 22.0f, 137.0f, 15.0f },
          { "0", "3", 50.0f, 110.0f, 15.0f },
          { "0", "3", 110.0f, 110.0f, 15.0f },
          { "3", "3", 35.0f, 70.0f, 12.0f },
          { "4", "3", 125.0f, 70.0f, 12.0f },
          { "0", "3", 80.0f, 50.0f, 6.0f },
          { "0", "3", 130.0f, 13.0f, 2.0f },
          { "0", "3", 30.0f, 13.0f, 2.0f },
        };
        REQUIRE (expected_donuts == data.donuts);

        const std::vector<PlatformObjectData> expected_platforms = {
          {
            "1", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 25.0f, 125.0f, 33.0f, 120.0f, 14.0f, 18.0f,
            {
              VertexData({ 25.0f, 125.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 33.0f, 120.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 25.0f, 122.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 33.0f, 117.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "2", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 33.0f, 120.0f, 41.0f, 125.0f, 14.0f, 18.0f,
            {
              VertexData({ 33.0f, 120.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 41.0f, 125.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 33.0f, 117.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 41.0f, 122.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "3", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 119.0f, 125.0f, 127.0f, 120.0f, 14.0f, 18.0f,
            {
              VertexData({ 119.0f, 125.0f, 80.0f, 0.0f, 0.0f }),
              VertexData({ 127.0f, 120.0f, 80.0f, 1.0f, 0.0f }),
              VertexData({ 119.0f, 122.0f, 80.0f, 0.0f, 1.0f }),
              VertexData({ 127.0f, 117.0f, 80.0f, 1.0f, 1.0f }),
            }
          },
          {
            "4", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 127.0f, 120.0f, 135.0f, 125.0f, 14.0f, 18.0f,
            {
              VertexData({ 127.0f, 120.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 135.0f, 125.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 127.0f, 117.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 135.0f, 122.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 41.0f, 125.0f, 58.0f, 125.0f, 14.0f, 18.0f,
            {
              VertexData({ 41.0f, 125.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 58.0f, 125.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 41.0f, 122.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 58.0f, 122.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, true, true, false, true, true,
            PlatformType::kPlain, 58.0f, 125.0f, 67.0f, 130.0f, 14.0f, 18.0f,
            {
              VertexData({ 58.0f, 125.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 67.0f, 130.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 58.0f, 122.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 67.0f, 127.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, true, true, false, true, true,
            PlatformType::kPlain, 93.0f, 130.0f, 102.0f, 125.0f, 14.0f, 18.0f,
            {
              VertexData({ 93.0f, 130.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 102.0f, 125.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 93.0f, 127.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 102.0f, 122.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 102.0f, 125.0f, 119.0f, 125.0f, 14.0f, 19.0f,
            {
              VertexData({ 102.0f, 125.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 119.0f, 125.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 102.0f, 122.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 119.0f, 122.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 135.0f, 125.0f, 157.0f, 125.0f, 14.0f, 18.0f,
            {
              VertexData({ 135.0f, 125.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 157.0f, 125.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 135.0f, 122.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 157.0f, 122.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 3.0f, 125.0f, 25.0f, 125.0f, 14.0f, 18.0f,
            {
              VertexData({ 3.0f, 125.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 25.0f, 125.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 3.0f, 122.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 25.0f, 122.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 3.0f, 90.0f, 25.0f, 90.0f, 14.0f, 18.0f,
            {
              VertexData({ 3.0f, 90.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 25.0f, 90.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 3.0f, 87.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 25.0f, 87.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 42.0f, 95.0f, 59.0f, 95.0f, 14.0f, 18.0f,
            {
              VertexData({ 42.0f, 95.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 59.0f, 95.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 42.0f, 92.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 59.0f, 92.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 59.0f, 95.0f, 69.0f, 90.0f, 14.0f, 18.0f,
            {
              VertexData({ 59.0f, 95.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 69.0f, 90.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 59.0f, 92.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 69.0f, 87.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 69.0f, 90.0f, 91.0f, 90.0f, 14.0f, 18.0f,
            {
              VertexData({ 69.0f, 90.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 91.0f, 90.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 69.0f, 87.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 91.0f, 87.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 91.0f, 90.0f, 101.0f, 95.0f, 14.0f, 18.0f,
            {
              VertexData({ 91.0f, 90.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 101.0f, 95.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 91.0f, 87.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 101.0f, 92.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 135.0f, 90.0f, 157.0f, 90.0f, 14.0f, 18.0f,
            {
              VertexData({ 135.0f, 90.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 157.0f, 90.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 135.0f, 87.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 157.0f, 87.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 101.0f, 95.0f, 118.0f, 95.0f, 14.0f, 18.0f,
            {
              VertexData({ 101.0f, 95.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 118.0f, 95.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 101.0f, 92.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 118.0f, 92.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 125.0f, 55.0f, 157.0f, 55.0f, 9.0f, 14.0f,
            {
              VertexData({ 125.0f, 55.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 157.0f, 55.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 125.0f, 52.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 157.0f, 52.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 50.0f, 63.0f, 110.0f, 63.0f, 9.0f, 14.0f,
            {
              VertexData({ 50.0f, 63.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 110.0f, 63.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 50.0f, 60.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 110.0f, 60.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 3.0f, 55.0f, 35.0f, 55.0f, 9.0f, 14.0f,
            {
              VertexData({ 3.0f, 55.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 35.0f, 55.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 3.0f, 52.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 35.0f, 52.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 35.0f, 25.0f, 50.0f, 35.0f, 5.0f, 9.0f,
            {
              VertexData({ 35.0f, 25.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 50.0f, 35.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 35.0f, 22.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 50.0f, 32.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 50.0f, 35.0f, 110.0f, 35.0f, 5.0f, 9.0f,
            {
              VertexData({ 50.0f, 35.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 110.0f, 35.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 50.0f, 32.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 110.0f, 32.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 3.0f, 25.0f, 35.0f, 25.0f, 5.0f, 9.0f,
            {
              VertexData({ 3.0f, 25.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 35.0f, 25.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 3.0f, 22.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 35.0f, 22.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 110.0f, 35.0f, 125.0f, 25.0f, 5.0f, 9.0f,
            {
              VertexData({ 110.0f, 35.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 125.0f, 25.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 110.0f, 32.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 125.0f, 22.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 125.0f, 25.0f, 157.0f, 25.0f, 5.0f, 9.0f,
            {
              VertexData({ 125.0f, 25.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 157.0f, 25.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 125.0f, 22.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 157.0f, 22.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 3.0f, 2.0f, 65.0f, 2.0f, 1.0f, 5.0f,
            {
              VertexData({ 3.0f, 2.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 65.0f, 2.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 3.0f, -1.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 65.0f, -1.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 65.0f, 2.0f, 70.0f, 5.0f, 1.0f, 5.0f,
            {
              VertexData({ 65.0f, 2.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 70.0f, 5.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 65.0f, -1.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 70.0f, 2.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 70.0f, 5.0f, 90.0f, 5.0f, 1.0f, 5.0f,
            {
              VertexData({ 70.0f, 5.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 90.0f, 5.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 70.0f, 2.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 90.0f, 2.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 95.0f, 2.0f, 157.0f, 2.0f, 1.0f, 5.0f,
            {
              VertexData({ 95.0f, 2.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 157.0f, 2.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 95.0f, -1.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 157.0f, -1.0f, 0.0f, 0.0f, 0.0f }),
            }
          },
          {
            "0", "1", true, false, true, false, true, true,
            PlatformType::kPlain, 90.0f, 5.0f, 95.0f, 2.0f, 1.0f, 5.0f,
            {
              VertexData({ 90.0f, 5.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 95.0f, 2.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 90.0f, 2.0f, 0.0f, 0.0f, 0.0f }),
              VertexData({ 95.0f, -1.0f, 0.0f, 0.0f, 0.0f }),
            }
          },

        };
        REQUIRE (expected_platforms == data.platforms);

        // TODO: REQUIRE (0 == data.walls.size());

        const std::vector<LadderObjectData> expected_ladders = {
          { "0", "2", 10.0f, 130.0f, 79.0f, 13.0f },
          { "0", "2", 10.0f, 67.0f, 55.0f, 13.0f },
          { "1", "2", 10.0f, 79.0f, 67.0f, 13.0f },
          { "0", "2", 150.0f, 130.0f, 79.0f, 13.0f },
          { "0", "2", 150.0f, 67.0f, 55.0f, 13.0f },
          { "2", "2", 150.0f, 79.0f, 67.0f, 13.0f },
          { "0", "2", 80.0f, 95.0f, 63.0f, 13.0f },
          { "0", "2", 60.0f, 68.0f, 35.0f, 8.0f },
          { "0", "2", 100.0f, 68.0f, 35.0f, 8.0f },
          { "0", "2", 12.0f, 30.0f, 2.0f, 4.0f },
          { "0", "2", 148.0f, 30.0f, 2.0f, 4.0f },
        };
        REQUIRE (expected_ladders == data.ladders);

        REQUIRE (0 == data.vines.size());
      }
    }

    WHEN ("a round-trip save and load is done") {
      auto converter = LevelConverter::FromStream(level);
      const LevelData expected_data = converter.Convert();

      std::stringstream buffer;
      buffer << expected_data;
      LevelData actual_data = LevelData::FromStream(buffer);

      THEN ("correct level objects and resources to have been loaded") {
        REQUIRE (expected_data == actual_data);
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
