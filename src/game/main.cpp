#include "engine/engine.hpp"

int main(int argc, char* argv[]) {
  Engine engine;

  if (engine.Initialize()) {
    return engine.Run();
  }

  return -1;
}
