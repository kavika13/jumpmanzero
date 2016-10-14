#include "engine/logging.hpp"
#include "meshconverter.hpp"

namespace Jumpman {

namespace Graphics {

MeshConverter MeshConverter::FromStream(std::istream& stream) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resources");
  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Loading old mesh";

  stream.seekg(0, stream.end);
  const size_t data_size = stream.tellg();
  stream.seekg(0, stream.beg);

  const size_t vertex_count = data_size / sizeof(OldMeshVertexData);

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Mesh contains " << vertex_count << " vertices";

  std::vector<OldMeshVertexData> vertices;
  vertices.reserve(vertex_count);

  auto extract_fixed_point = [](char* vertex_data, size_t index) -> float {
    auto data = reinterpret_cast<unsigned char*>(&vertex_data[index * 4]);
    return (data[1] * 65536L + data[2] * 256L + data[3])
      * (data[0] ? -1 : 1)
      / 65536.0f;
  };

  for (size_t index = 0; index < vertex_count; ++index) {
    char vertex_data[sizeof(OldMeshVertexData)];
    stream.read(vertex_data, sizeof(vertex_data));

    vertices.push_back({
      extract_fixed_point(vertex_data, 0),  // x
      extract_fixed_point(vertex_data, 1),  // y
      extract_fixed_point(vertex_data, 2),  // z
      extract_fixed_point(vertex_data, 3),  // nx
      extract_fixed_point(vertex_data, 4),  // ny
      extract_fixed_point(vertex_data, 5),  // nz
      extract_fixed_point(vertex_data, 6),  // unused_
      extract_fixed_point(vertex_data, 7),  // tu
      extract_fixed_point(vertex_data, 8),  // tv
    });
  }

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished extracting vertices - vertex count: " << vertices.size();

  return MeshConverter {
    std::move(vertices),
  };
}

MeshData MeshConverter::Convert() {
  std::vector<MeshVertexData> vertices;

  for (const auto& vertex: this->vertices) {
    vertices.push_back({
      vertex.x,
      vertex.y,
      vertex.z,
      vertex.nx,
      vertex.ny,
      vertex.nz,
      vertex.tu,
      vertex.tv,
    });
  }

  return {
    std::move(vertices),
  };
}

};  // namespace Graphics

};  // namespace Jumpman
