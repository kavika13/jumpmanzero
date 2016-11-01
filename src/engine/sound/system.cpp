#include <fmod_errors.h>
#include "engine/logging.hpp"
#include "system.hpp"

namespace Jumpman {

namespace Sound {

System::System() {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Sound");
  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Initializing sound system";

  FMOD_RESULT result = System_Create(&handle_);

  if (result != FMOD_OK) {
    const std::string error_message =
      std::string("Failed to create sound system") + FMOD_ErrorString(result);
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  // TODO: Get magic constants from somewhere else
  result = handle_->init(32, FMOD_INIT_NORMAL, nullptr);

  if (result != FMOD_OK) {
    const std::string error_message =
      std::string("Failed to initialize sound system")
        + FMOD_ErrorString(result);
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Initialized sound system: " << handle_;
}

System::System(System&& other) noexcept
    : handle_(other.handle_) {
  other.handle_ = nullptr;
}

System::~System() noexcept {
  Deallocate();
}

System& System::operator=(System&& other) noexcept {
  Deallocate();
  handle_ = other.handle_;
  other.handle_ = nullptr;
  return *this;
}

System::operator FMOD::System*() {
  return handle_;
}

void System::Deallocate() noexcept {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Sound");

  if (handle_) {
    BOOST_LOG_SEV(log, LogSeverity::kTrace)
      << "Shutting down sound system: " << handle_;
    FMOD_RESULT result = handle_->release();

    if (result != FMOD_OK) {
      BOOST_LOG_SEV(log, LogSeverity::kError)
        << "Failed to shut down sound system: " << FMOD_ErrorString(result);
      // Don't throw in destructors
    }
  }
}

};  // namespace Sound

};  // namespace Jumpman
