#include <fstream>
#include <iostream>
#include <boost/filesystem.hpp>
#include "engine/meshconverter.hpp"
#include "engine/logging.hpp"

int main(int argc, char* argv[]) {
  InitializeLogging();  // Engine logging - TODO: Should be in its own namespace

  if (argc < 2 || argc > 3) {
    std::cerr << "Usage: meshconverter path/mesh.msh[ path/outputmesh.obj]"
      << std::endl;
    return -1;
  }

  boost::filesystem::path source_filename(argv[1]);
  boost::filesystem::path target_filename(
    argc == 3
      ? argv[2]
      : boost::filesystem::path(source_filename)
        .replace_extension("obj"));

  std::ifstream old_mesh_file(source_filename.string());

  if (!old_mesh_file) {
    std::cerr << "Failed to open input file: " << source_filename;
    return -1;
  }

  std::ofstream new_mesh_file(target_filename.string());

  if (!new_mesh_file) {
    std::cerr << "Failed to open output file: " << target_filename;
    return -1;
  }

  auto converter = MeshConverter::FromStream(old_mesh_file);
  MeshData converted_data = std::move(converter.Convert());
  new_mesh_file << converted_data;

  return 0;
}
