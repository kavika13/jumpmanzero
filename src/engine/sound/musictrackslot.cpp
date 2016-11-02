#include "musictrackslot.hpp"

namespace Jumpman {

namespace Sound {

MusicTrackSlot::MusicTrackSlot(std::shared_ptr<System> system)
    : system_(system) {
}

void MusicTrackSlot::PlayOnce(
    std::shared_ptr<MusicTrack> new_track, unsigned int start_at_milliseconds) {
  if (!current_track_
      || (new_track != current_track_ && !new_track->GetIsPlaying())) {
    if (current_track_ && current_track_->GetIsPlaying()) {
      current_track_->Pause(*system_);
    }

    new_track->PlayOnce(*system_, start_at_milliseconds);

    current_track_ = new_track;
  }
}

void MusicTrackSlot::PlayRepeating(
    std::shared_ptr<MusicTrack> new_track,
    unsigned int start_at_milliseconds,
    unsigned int repeat_at_milliseconds) {
  if (!current_track_
      || (new_track != current_track_ && !new_track->GetIsPlaying())) {
    if (current_track_ && current_track_->GetIsPlaying()) {
      current_track_->Pause(*system_);
    }

    new_track->PlayRepeating(
      *system_, start_at_milliseconds, repeat_at_milliseconds);

    current_track_ = new_track;
  }
}

void MusicTrackSlot::Stop() {
  if (current_track_ && current_track_->GetIsPlaying()) {
    current_track_->Pause(*system_);
  }

  current_track_ = nullptr;
}

bool MusicTrackSlot::GetIsPlaying() const {
  return current_track_ && current_track_->GetIsPlaying();
}

};  // namespace Sound

};  // namespace Jumpman
