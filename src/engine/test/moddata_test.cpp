#include <fstream>
#include <string>
#include "engine/moddata.hpp"
#include "catch.hpp"

using ModData = Jumpman::ModData;
using ModList = Jumpman::ModList;

SCENARIO ("load mod file and verify there are no errors",
          "[resourceloading]") {
  std::string mod_directory = "data/mod";

  GIVEN ("maincampaign.json") {
    const std::string mod_filename = mod_directory + "/maincampaign.json";
    std::ifstream mod_file(mod_filename);

    WHEN ("the load is done") {
      auto data = ModData::FromStream(mod_file);

      THEN ("correct data to have been parsed") {
        REQUIRE ("Campaign" == data.title);
        REQUIRE (
          "data/script/maincampaign.lua" == data.entrypoint_script_filename);
        REQUIRE (3 == data.data.size());
      }
    }
  }
}

SCENARIO ("load mod list and verify there are no errors",
          "[resourceloading]") {
  std::string mod_directory = "data/mod";

  GIVEN ("knownmods.json") {
    const std::string mod_filename = mod_directory + "/knownmods.json";
    std::ifstream mod_file(mod_filename);

    WHEN ("the load is done") {
      auto data = ModList::FromStream(mod_file, mod_directory);

      THEN ("correct data to have been parsed") {
        REQUIRE (1 == data.builtin.size());
        REQUIRE (0 == data.discovered.size());
        REQUIRE ("Campaign" == data.builtin[0].title);
        REQUIRE (
          "data/script/maincampaign.lua"
            == data.builtin[0].entrypoint_script_filename);
        REQUIRE (3 == data.builtin[0].data.size());
      }
    }
  }
}
