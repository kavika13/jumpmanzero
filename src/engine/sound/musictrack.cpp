#include <unordered_map>
#include <vector>
#include <fmod_errors.h>
#include "engine/logging.hpp"
#include "musictrack.hpp"

namespace Jumpman {

namespace Sound {

static std::unordered_map<FMOD::Channel*, MusicTrack*> g_callback_map;

MusicTrack::MusicTrack(
  FMOD::System& system, const char* track_data, size_t track_data_length)
    : is_playing_(false)
    , channel_(nullptr) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Sound");
  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Creating music track from data";

  FMOD_CREATESOUNDEXINFO options = {
    sizeof(FMOD_CREATESOUNDEXINFO),
  };
  options.length = track_data_length;

  FMOD_RESULT result = system.createSound(
    track_data,
    FMOD_OPENMEMORY | FMOD_CREATESAMPLE | FMOD_LOOP_NORMAL,
    &options,
    &handle_
  );

  if (result != FMOD_OK) {
    const std::string error_message =
      std::string("Error creating music track from data")
        + FMOD_ErrorString(result);
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Created music track from data: " << handle_;
}

std::shared_ptr<MusicTrack> MusicTrack::FromStream(
    System& system, std::istream& stream) {
  stream.seekg(0, std::ios::end);
  std::vector<char> track_data(stream.tellg());
  stream.seekg(0, std::ios::beg);
  stream.read(&track_data[0], track_data.size());
  return std::shared_ptr<MusicTrack>(
    new MusicTrack(*system, &track_data[0], track_data.size()));
}

MusicTrack::MusicTrack(MusicTrack&& other) noexcept
    : is_playing_(other.is_playing_)
    , handle_(other.handle_)
    , channel_(other.channel_) {
  if (channel_) {
    g_callback_map[channel_] = this;
  }

  other.is_playing_ = false;
  other.handle_ = nullptr;
  other.channel_ = nullptr;
}

MusicTrack::~MusicTrack() noexcept {
  Deallocate();
}

void MusicTrack::PlayOnce(System& system, unsigned int start_at_milliseconds) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Sound");
  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Playing music track: " << handle_
    << " at start offset: " << start_at_milliseconds;

  FMOD_RESULT result = static_cast<FMOD::System*>(system)->playSound(
    handle_, nullptr, true, &channel_);

  if (result != FMOD_OK) {
    const std::string error_message =
      std::string("Failed to play music track: ")
        + FMOD_ErrorString(result);
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Setting starting point: " << start_at_milliseconds;
  result = channel_->setPosition(start_at_milliseconds, FMOD_TIMEUNIT_MS);

  if (result != FMOD_OK) {
    const std::string error_message =
      std::string("Failed to set music track start position: ")
        + FMOD_ErrorString(result);
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Disabling music track looping: " << handle_;
  result = channel_->setMode(FMOD_LOOP_OFF);

  if (result != FMOD_OK) {
    const std::string error_message =
      std::string("Failed to disable music track looping: ")
        + FMOD_ErrorString(result);
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Resgistering track end callback: " << handle_;

  auto callback = [](
    FMOD_CHANNELCONTROL* chanControl,
    FMOD_CHANNELCONTROL_TYPE controlType,
    FMOD_CHANNELCONTROL_CALLBACK_TYPE callbackType,
    void* commandData1,
    void* commandData2) {
      if (controlType == FMOD_CHANNELCONTROL_CHANNEL) {
        auto iter = g_callback_map.find(
          reinterpret_cast<FMOD::Channel*>(chanControl));

        if (iter != g_callback_map.end()) {
          iter->second->Callback(
            chanControl,
            controlType,
            callbackType,
            commandData1,
            commandData2);
        }
      }

      return FMOD_OK;
    };
  g_callback_map[channel_] = this;
  result = channel_->setCallback(callback);

  if (result != FMOD_OK) {
    const std::string error_message =
      std::string("Failed to set track end callback: ")
        + FMOD_ErrorString(result);
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Unpausing track: " << handle_;

  result = channel_->setPaused(false);

  if (result != FMOD_OK) {
    const std::string error_message =
      std::string("Failed to unpause track after setting start position: ")
        + FMOD_ErrorString(result);
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  is_playing_ = true;

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Played music track: " << handle_
    << " at start offset: " << start_at_milliseconds;
}

void MusicTrack::PlayRepeating(
    System& system,
    unsigned int start_at_milliseconds,
    unsigned int repeat_at_milliseconds) {
  // TODO: Deduplicate implementation
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Sound");
  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Playing music track with repeat: " << handle_
    << " at start offset: " << start_at_milliseconds
    << " at repeat offset: " << repeat_at_milliseconds;

  bool has_start_offset = start_at_milliseconds;

  FMOD_RESULT result = static_cast<FMOD::System*>(system)->playSound(
    handle_, nullptr, true, &channel_);

  if (result != FMOD_OK) {
    const std::string error_message =
      std::string("Failed to play music track: ")
        + FMOD_ErrorString(result);
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  BOOST_LOG_SEV(log, LogSeverity::kTrace)
    << "Setting starting point: " << start_at_milliseconds;
  result = channel_->setPosition(start_at_milliseconds, FMOD_TIMEUNIT_MS);

  if (result != FMOD_OK) {
    const std::string error_message =
      std::string("Failed to set music track start position: ")
        + FMOD_ErrorString(result);
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  bool track_repeats = repeat_at_milliseconds;

  if (track_repeats) {
    BOOST_LOG_SEV(log, LogSeverity::kTrace)
      << "Getting track length to set loop points: " << handle_;
    unsigned int track_length;
    result = handle_->getLength(&track_length, FMOD_TIMEUNIT_PCM);

    if (result != FMOD_OK) {
      const std::string error_message =
        std::string("Failed to get length of track when setting loop points: ")
          + FMOD_ErrorString(result);
      BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
      throw std::runtime_error(error_message);
    }

    BOOST_LOG_SEV(log, LogSeverity::kTrace)
      << "Setting loop points: " << handle_;
    result = channel_->setLoopPoints(
      repeat_at_milliseconds, FMOD_TIMEUNIT_MS,
      track_length - 1, FMOD_TIMEUNIT_PCM);

    if (result != FMOD_OK) {
      const std::string error_message =
        std::string("Failed to set music track loop points: ")
          + FMOD_ErrorString(result);
      BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
      throw std::runtime_error(error_message);
    }
  }

  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Unpausing track: " << handle_;
  result = channel_->setPaused(false);

  if (result != FMOD_OK) {
    const std::string error_message =
      std::string("Failed to unpause track after setting start position: ")
        + FMOD_ErrorString(result);
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  is_playing_ = true;

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Played music track with repeat: " << handle_
    << " at start offset: " << start_at_milliseconds
    << " at repeat offset: " << repeat_at_milliseconds;
}

void MusicTrack::Pause(System& system) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Sound");

  if (!is_playing_) {
    BOOST_LOG_SEV(log, LogSeverity::kError)
      << "Tried to pause track that wasn't playing: " << handle_;
  } else {
    if (!channel_) {
      throw std::runtime_error("Channel was null when pausing track");
    }

    FMOD_RESULT result = channel_->setPaused(true);

    if (result != FMOD_OK) {
      const std::string error_message = std::string("Failed to pause track: ")
        + FMOD_ErrorString(result);
      BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
      throw std::runtime_error(error_message);
    }

    is_playing_ = false;
    channel_ = nullptr;
  }
}

bool MusicTrack::GetIsPlaying() const {
  return is_playing_;
}

MusicTrack& MusicTrack::operator=(MusicTrack&& other) noexcept {
  Deallocate();

  handle_ = other.handle_;
  channel_ = other.channel_;
  is_playing_ = other.is_playing_;

  if (channel_) {
    g_callback_map[channel_] = this;
  }

  other.is_playing_ = false;
  other.handle_ = nullptr;
  other.channel_ = nullptr;

  return *this;
}

FMOD_RESULT F_CALLBACK MusicTrack::Callback(
    FMOD_CHANNELCONTROL* chanControl,
    FMOD_CHANNELCONTROL_TYPE controlType,
    FMOD_CHANNELCONTROL_CALLBACK_TYPE callbackType,
    void* commandData1,
    void* commandData2) {
  if (callbackType == FMOD_CHANNELCONTROL_CALLBACK_END) {
    g_callback_map[channel_] = nullptr;
    is_playing_ = false;
    channel_ = nullptr;
  }

  return FMOD_OK;
}

void MusicTrack::Deallocate() noexcept {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Sound");

  if (handle_) {
    BOOST_LOG_SEV(log, LogSeverity::kTrace)
      << "Freeing music track: " << handle_;
    FMOD_RESULT result = handle_->release();

    if (result != FMOD_OK) {
      BOOST_LOG_SEV(log, LogSeverity::kError)
        << "Failed to free music track: " << FMOD_ErrorString(result);
      // Don't throw in destructors
    }
  }

  if (channel_) {
    g_callback_map[channel_] = nullptr;
  }
}

};  // namespace Sound

};  // namespace Jumpman
