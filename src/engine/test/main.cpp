#include "logging.hpp"
#define CATCH_CONFIG_RUNNER
#include "./catch.hpp"

int main(int argc, char* argv[]) {
  InitializeLogging();
  int result = Catch::Session().run(argc, argv);
  return result;
}
