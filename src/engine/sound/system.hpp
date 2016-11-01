#ifndef ENGINE_SOUND_SYSTEM_HPP_
#define ENGINE_SOUND_SYSTEM_HPP_

#include <fmod.hpp>

namespace Jumpman {

namespace Sound {

class System {
 public:
  System();
  System(const System&) = delete;
  System(System&&) noexcept;
  ~System() noexcept;

  System& operator=(const System&) = delete;
  System& operator=(System&&) noexcept;

  operator FMOD::System*();

 private:
  void Deallocate() noexcept;

  FMOD::System* handle_;
};

};  // namespace Sound

};  // namespace Jumpman

#endif  // ENGINE_SOUND_SYSTEM_HPP_
