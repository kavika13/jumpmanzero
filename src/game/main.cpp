#include "engine/engine.hpp"

int main(int argc, char* argv[]) {
  Engine engine;

  if (engine.Initialize()) {
    if (engine.LoadLevel("data/level/Level1.json")) {
      return engine.Run();
    }
  }

  return -1;
}
