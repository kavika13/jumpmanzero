#include <iomanip>
#define TINYOBJLOADER_IMPLEMENTATION
#include <tiny_obj_loader.h>
#include "logging.hpp"
#include "meshdata.hpp"

std::ostream& operator<<(std::ostream& stream, const MeshVertexData& vertex) {
  stream << "(MeshVertex"
    << " - x: " << vertex.x
    << " - y: " << vertex.y
    << " - z: " << vertex.z
    << " - nx: " << vertex.nx
    << " - ny: " << vertex.ny
    << " - nz: " << vertex.nz
    << " - tu: " << vertex.tu
    << " - tv: " << vertex.tv;
  return stream;
}

bool operator==(const MeshVertexData& lhs, const MeshVertexData& rhs) {
  return lhs.x == rhs.x
    && lhs.y == rhs.y
    && lhs.z == rhs.z
    && lhs.nx == rhs.nx
    && lhs.ny == rhs.ny
    && lhs.nz == rhs.nz
    && lhs.tu == rhs.tu
    && lhs.tv == rhs.tv;
}

MeshData MeshData::FromStream(std::istream& stream) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resources");
  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Loading mesh";

  tinyobj::attrib_t attrib;
  std::vector<tinyobj::shape_t> shapes;
  std::vector<tinyobj::material_t> materials;

  std::string err;
  bool ret = tinyobj::LoadObj(&attrib, &shapes, &materials, &err, &stream);

  if (!ret || !err.empty()) {
    std::string error_message = "Failed to load mesh: " + err;
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  std::vector<MeshVertexData> vertices;

  for (const auto& shape: shapes) {
    size_t index_offset = 0;

    for (const auto& face_vertex_count: shape.mesh.num_face_vertices) {
      for (size_t vertex_index = 0;
           vertex_index < face_vertex_count;
           ++vertex_index) {
        tinyobj::index_t idx = shape.mesh.indices[index_offset + vertex_index];

        vertices.push_back({
          attrib.vertices[3 * idx.vertex_index + 0],
          attrib.vertices[3 * idx.vertex_index + 1],
          attrib.vertices[3 * idx.vertex_index + 2],
          attrib.normals[3 * idx.normal_index + 0],
          attrib.normals[3 * idx.normal_index + 1],
          attrib.normals[3 * idx.normal_index + 2],
          attrib.texcoords[2 * idx.texcoord_index + 0],
          attrib.texcoords[2 * idx.texcoord_index + 1],
        });
      }

      index_offset += face_vertex_count;
    }
  }

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished loading mesh - vertex count: " << vertices.size();

  return {
    std::move(vertices),
  };
}

std::ostream& operator<<(std::ostream& stream, const MeshData& data) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Resources");
  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Writing mesh to stream";

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Writing object grouping data to stream";

  stream << std::fixed << std::setprecision(8) << "o 1\n";

  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Writing vertex data to stream";

  for (const MeshVertexData& vertex: data.vertices) {
    stream << "v"
      << " " << vertex.x
      << " " << vertex.y
      << " " << vertex.z
      << "\n";
  }

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Writing texture coordinate data to stream";

  for (const MeshVertexData& vertex: data.vertices) {
    stream << "vt"
      << " " << vertex.tu
      << " " << vertex.tv
      << "\n";
  }

  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Writing normal data to stream";

  for (const MeshVertexData& vertex: data.vertices) {
    stream << "vn"
      << " " << vertex.nx
      << " " << vertex.ny
      << " " << vertex.nz
      << "\n";
  }

  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Writing material data to stream";

  stream << "usemtl (null)\n";

  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Writing face data to stream";

  for (size_t index = 1; index <= data.vertices.size(); index += 3) {
    stream << "f"
      << " " << index + 0 << "/" << index + 0 << "/" << index + 0
      << " " << index + 1 << "/" << index + 1 << "/" << index + 1
      << " " << index + 2 << "/" << index + 2 << "/" << index + 2
      << "\n";
  }

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished writing data to stream"
    << " - vertex count: " << data.vertices.size();

  return stream;
}

bool operator==(const MeshData& lhs, const MeshData& rhs) {
  return lhs.vertices == rhs.vertices;
}
