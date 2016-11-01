#ifndef ENGINE_SOUND_SOUND_HPP_
#define ENGINE_SOUND_SOUND_HPP_

#include <istream>
#include <memory>
#include <fmod.hpp>
#include "system.hpp"

namespace Jumpman {

namespace Sound {

class Sound {
 public:
  Sound(const Sound&) = delete;
  Sound(Sound&&) noexcept;
  ~Sound() noexcept;

  static std::shared_ptr<Sound> FromStream(
    System& system, std::istream& stream);

  void Play(System& system);

  Sound& operator=(const Sound&) = delete;
  Sound& operator=(Sound&&) noexcept;

 private:
  Sound(FMOD::System& system, const char* sound_data, size_t sound_data_length);

  void Deallocate() noexcept;

  FMOD::Sound* handle_;
};

};  // namespace Sound

};  // namespace Jumpman

#endif  // ENGINE_SOUND_SOUND_HPP_
