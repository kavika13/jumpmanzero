#include <fstream>
#include <iostream>
#include <boost/filesystem.hpp>
#include "engine/levelconverter.hpp"
#include "engine/logging.hpp"

int main(int argc, char* argv[]) {
  Jumpman::InitializeLogging();

  if (argc < 2 || argc > 3) {
    std::cerr << "Usage: levelconverter path/level.lvl[ path/outputlevel.json]"
      << std::endl;
    return -1;
  }

  boost::filesystem::path source_filename(argv[1]);
  boost::filesystem::path target_filename(
    argc == 3
      ? argv[2]
      : boost::filesystem::path(source_filename)
        .replace_extension("json"));

  std::ifstream old_level_file(source_filename.string());

  if (!old_level_file) {
    std::cerr << "Failed to open input file: " << source_filename;
    return -1;
  }

  std::ofstream new_level_file(target_filename.string());

  if (!new_level_file) {
    std::cerr << "Failed to open output file: " << target_filename;
    return -1;
  }

  auto converter = Jumpman::LevelConverter::FromStream(old_level_file);
  Jumpman::LevelData converted_data = converter.Convert();
  new_level_file << converted_data;

  return 0;
}
