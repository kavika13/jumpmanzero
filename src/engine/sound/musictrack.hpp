#ifndef ENGINE_SOUND_MUSICTRACK_HPP_
#define ENGINE_SOUND_MUSICTRACK_HPP_

#include <istream>
#include <memory>
#include <fmod.hpp>
#include "system.hpp"

namespace Jumpman {

namespace Sound {

class MusicTrack {
 public:
  MusicTrack(const MusicTrack&) = delete;
  MusicTrack(MusicTrack&&) noexcept;
  ~MusicTrack() noexcept;

  static std::shared_ptr<MusicTrack> FromStream(
    System& system, std::istream& stream);

  void PlayOnce(System& system, unsigned int start_at_milliseconds = 0);
  void PlayRepeating(
    System& system,
    unsigned int start_at_milliseconds = 0,
    unsigned int repeat_at_milliseconds = 0);
  void Pause(System& system);
  bool GetIsPlaying() const;

  MusicTrack& operator=(const MusicTrack&) = delete;
  MusicTrack& operator=(MusicTrack&&) noexcept;

 private:
  MusicTrack(
    FMOD::System& system, const char* track_data, size_t track_data_length);

  FMOD_RESULT F_CALLBACK Callback(
    FMOD_CHANNELCONTROL* chanControl,
    FMOD_CHANNELCONTROL_TYPE controlType,
    FMOD_CHANNELCONTROL_CALLBACK_TYPE callbackType,
    void* commandData1,
    void* commandData2);

  void Deallocate() noexcept;

  bool is_playing_;
  FMOD::Sound* handle_;
  FMOD::Channel* channel_;
};

};  // namespace Sound

};  // namespace Jumpman

#endif  // ENGINE_SOUND_MUSICTRACK_HPP_
