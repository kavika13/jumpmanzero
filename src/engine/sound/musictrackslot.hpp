#ifndef ENGINE_SOUND_MUSICTRACKSLOT_HPP_
#define ENGINE_SOUND_MUSICTRACKSLOT_HPP_

#include "musictrack.hpp"
#include "system.hpp"

namespace Jumpman {

namespace Sound {

class MusicTrackSlot {
 public:
  MusicTrackSlot(std::shared_ptr<System> system);

  void PlayOnce(
    std::shared_ptr<MusicTrack> new_track,
    unsigned int start_at_milliseconds = 0);
  void PlayRepeating(
    std::shared_ptr<MusicTrack> new_track,
    unsigned int start_at_milliseconds = 0,
    unsigned int repeat_at_milliseconds = 0);
  void Stop();
  bool GetIsPlaying() const;

 private:
  std::shared_ptr<System> system_;
  std::shared_ptr<MusicTrack> current_track_;
};

};  // namespace Sound

};  // namespace Jumpman

#endif  // ENGINE_SOUND_MUSICTRACKSLOT_HPP_
