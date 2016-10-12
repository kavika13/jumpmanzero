#include "quadobjectresource.hpp"

QuadObjectResource::QuadObjectResource(
    const QuadObjectData& data,
    MeshGenerator& generator) {
  // TODO: Bounding box, proper scene origin
  const Vertex v0 = generator.ConvertVertex(data.vertices[0]);
  const Vertex v1 = generator.ConvertVertex(data.vertices[1]);
  const Vertex v2 = generator.ConvertVertex(data.vertices[2]);
  const Vertex v3 = generator.ConvertVertex(data.vertices[3]);

  generator.AddQuad(v0, v1, v2, v3);
}
