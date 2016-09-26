#include <fstream>
#include <iostream>
#include "engine/levelconverter.hpp"
#include "engine/logging.hpp"

int main(int argc, char* argv[]) {
  InitializeLogging();  // Engine logging - TODO: Should be in its own namespace

  if (argc != 3) {
    std::cerr << "Usage: levelconverter path/level.lvl path/outputlevel.json"
      << std::endl;
    return -1;
  }

  std::ifstream old_level_file(argv[1]);

  if (!old_level_file) {
    std::cerr << "Failed to open input file: " << argv[1];
    return -1;
  }

  std::ofstream new_level_file(argv[2]);

  if (!new_level_file) {
    std::cerr << "Failed to open output file: " << argv[2];
    return -1;
  }

  auto converter = LevelConverter::FromStream(old_level_file);
  LevelData converted_data = converter.Convert();
  new_level_file << converted_data;

  return 0;
}
