#include <vector>
#include <fmod_errors.h>
#include "engine/logging.hpp"
#include "sound.hpp"

namespace Jumpman {

namespace Sound {

Sound::Sound(
    FMOD::System& system, const char* sound_data, size_t sound_data_length) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Sound");
  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Creating sound from data";

  FMOD_CREATESOUNDEXINFO options = {
    sizeof(FMOD_CREATESOUNDEXINFO),
  };
  options.length = sound_data_length;

  FMOD_RESULT result = system.createSound(
    sound_data,
    FMOD_OPENMEMORY | FMOD_CREATESAMPLE,
    &options,
    &handle_
  );

  if (result != FMOD_OK) {
    const std::string error_message =
      std::string("Error creating sound from data") + FMOD_ErrorString(result);
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Created sound from data: " << handle_;
}

std::shared_ptr<Sound> Sound::FromStream(System& system, std::istream& stream) {
  stream.seekg(0, std::ios::end);
  std::vector<char> sound_data(stream.tellg());
  stream.seekg(0, std::ios::beg);
  stream.read(&sound_data[0], sound_data.size());
  return std::shared_ptr<Sound>(
    new Sound(*system, &sound_data[0], sound_data.size()));
}

Sound::Sound(Sound&& other) noexcept
    : handle_(other.handle_) {
  other.handle_ = nullptr;
}

Sound::~Sound() noexcept {
  Deallocate();
}

void Sound::Play(System& system) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Sound");
  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Playing sound: " << handle_;

  FMOD_RESULT result = static_cast<FMOD::System*>(system)->playSound(
    handle_, nullptr, false, nullptr);

  if (result != FMOD_OK) {
    const std::string error_message = std::string("Failed to play sound: ")
      + FMOD_ErrorString(result);
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Played sound: " << handle_;
}

Sound& Sound::operator=(Sound&& other) noexcept {
  Deallocate();
  handle_ = other.handle_;
  other.handle_ = nullptr;
  return *this;
}

void Sound::Deallocate() noexcept {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Sound");

  if (handle_) {
    BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Freeing sound: " << handle_;
    FMOD_RESULT result = handle_->release();

    if (result != FMOD_OK) {
      BOOST_LOG_SEV(log, LogSeverity::kError)
        << "Failed to free sound: " << FMOD_ErrorString(result);
      // Don't throw in destructors
    }
  }
}

};  // namespace Sound

};  // namespace Jumpman
