#include "./deleteme.hpp"
#include "./logging.hpp"

// TODO: Remove this once we have real files in here to build
void DoStuff() {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "DeleteMe");
  BOOST_LOG_SEV(log, LogSeverity::kInfo) << "Do something";
}
