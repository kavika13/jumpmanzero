#include <string>
#include "levelconverter.hpp"
#include "./catch.hpp"

SCENARIO ("load old level files and verify there are no errors",
          "[dataconversion]") {
  std::string level_directory = "data/level";

  GIVEN ("Blank.lvl") {
    const std::string level = level_directory + "/Blank.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (16 == converter.num_resources());
        REQUIRE (2 == converter.num_objects());
      }
    }
  }

  GIVEN ("Ending.lvl") {
    const std::string level = level_directory + "/Ending.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (78 == converter.num_resources());
        REQUIRE (2 == converter.num_objects());
      }
    }
  }

  GIVEN ("GameOver.lvl") {
    const std::string level = level_directory + "/GameOver.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (17 == converter.num_resources());
        REQUIRE (2 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level1.lvl") {
    const std::string level = level_directory + "/Level1.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (17 == converter.num_resources());
        REQUIRE (51 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level10.lvl") {
    const std::string level = level_directory + "/Level10.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (27 == converter.num_resources());
        REQUIRE (42 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level11.lvl") {
    const std::string level = level_directory + "/Level11.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (51 == converter.num_resources());
        REQUIRE (68 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level12.lvl") {
    const std::string level = level_directory + "/Level12.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (21 == converter.num_resources());
        REQUIRE (77 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level13.lvl") {
    const std::string level = level_directory + "/Level13.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (20 == converter.num_resources());
        REQUIRE (58 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level14.lvl") {
    const std::string level = level_directory + "/Level14.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (30 == converter.num_resources());
        REQUIRE (35 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level15.lvl") {
    const std::string level = level_directory + "/Level15.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (21 == converter.num_resources());
        REQUIRE (66 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level16.lvl") {
    const std::string level = level_directory + "/Level16.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (26 == converter.num_resources());
        REQUIRE (69 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level17.lvl") {
    const std::string level = level_directory + "/Level17.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (18 == converter.num_resources());
        REQUIRE (61 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level18.lvl") {
    const std::string level = level_directory + "/Level18.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (34 == converter.num_resources());
        REQUIRE (30 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level19.lvl") {
    const std::string level = level_directory + "/Level19.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (23 == converter.num_resources());
        REQUIRE (47 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level2.lvl") {
    const std::string level = level_directory + "/Level2.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (24 == converter.num_resources());
        REQUIRE (63 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level20.lvl") {
    const std::string level = level_directory + "/Level20.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (35 == converter.num_resources());
        REQUIRE (58 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level21.lvl") {
    const std::string level = level_directory + "/Level21.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (26 == converter.num_resources());
        REQUIRE (28 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level22.lvl") {
    const std::string level = level_directory + "/Level22.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (22 == converter.num_resources());
        REQUIRE (51 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level23.lvl") {
    const std::string level = level_directory + "/Level23.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (29 == converter.num_resources());
        REQUIRE (63 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level24.lvl") {
    const std::string level = level_directory + "/Level24.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (31 == converter.num_resources());
        REQUIRE (83 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level25.lvl") {
    const std::string level = level_directory + "/Level25.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (46 == converter.num_resources());
        REQUIRE (28 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level27.lvl") {
    const std::string level = level_directory + "/Level27.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (40 == converter.num_resources());
        REQUIRE (59 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level3.lvl") {
    const std::string level = level_directory + "/Level3.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (33 == converter.num_resources());
        REQUIRE (73 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level4.lvl") {
    const std::string level = level_directory + "/Level4.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (38 == converter.num_resources());
        REQUIRE (62 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level5.lvl") {
    const std::string level = level_directory + "/Level5.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (22 == converter.num_resources());
        REQUIRE (76 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level6.lvl") {
    const std::string level = level_directory + "/Level6.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (26 == converter.num_resources());
        REQUIRE (70 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level7.lvl") {
    const std::string level = level_directory + "/Level7.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (22 == converter.num_resources());
        REQUIRE (79 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level8.lvl") {
    const std::string level = level_directory + "/Level8.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (19 == converter.num_resources());
        REQUIRE (82 == converter.num_objects());
      }
    }
  }

  GIVEN ("Level9.lvl") {
    const std::string level = level_directory + "/Level9.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (21 == converter.num_resources());
        REQUIRE (49 == converter.num_objects());
      }
    }
  }

  GIVEN ("MainMenu.lvl") {
    const std::string level = level_directory + "/MainMenu.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (16 == converter.num_resources());
        REQUIRE (40 == converter.num_objects());
      }
    }
  }

  GIVEN ("Options.lvl") {
    const std::string level = level_directory + "/Options.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (9 == converter.num_resources());
        REQUIRE (1 == converter.num_objects());
      }
    }
  }

  GIVEN ("SelectGame.lvl") {
    const std::string level = level_directory + "/SelectGame.lvl";

    WHEN ("the load is done") {
      auto converter = LevelConverter(level);

      THEN ("correct level objects and resources to have been parsed") {
        REQUIRE (10 == converter.num_resources());
        REQUIRE (1 == converter.num_objects());
      }
    }
  }
}
