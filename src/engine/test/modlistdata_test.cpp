#include <fstream>
#include <string>
#include "engine/modlistdata.hpp"
#include "catch.hpp"

using ModListItemData = Jumpman::ModListItemData;
using ModListData = Jumpman::ModListData;

SCENARIO ("load mod file and verify there are no errors",
          "[resourceloading]") {
  std::string mod_directory = "data/mod";

  GIVEN ("maincampaign.json") {
    const std::string mod_filename = mod_directory + "/maincampaign.json";
    std::ifstream mod_file(mod_filename);

    WHEN ("the load is done") {
      auto data = ModListItemData::FromStream(mod_file, mod_filename);

      THEN ("correct data to have been parsed") {
        REQUIRE ("Campaign" == data.title);
        REQUIRE ("data/mod/maincampaign.json" == data.filename);
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
      auto data = ModListData::FromStream(mod_file, "", mod_directory);

      THEN ("correct data to have been parsed") {
        REQUIRE (1 == data.builtin_mods.size());
        REQUIRE (0 == data.discovered_mods.size());
        REQUIRE ("Campaign" == data.builtin_mods[0].title);
        REQUIRE ("data/mod/maincampaign.json" == data.builtin_mods[0].filename);
      }
    }
  }
}
