#ifndef ENGINE_ENGINE_HPP_
#define ENGINE_ENGINE_HPP_

#include <memory>

namespace Jumpman {

class Engine {
 public:
  Engine();
  ~Engine();

  bool Initialize();
  int Run();

 private:
  struct EngineData;
  std::unique_ptr<EngineData> data_;
};

};  // namespace Jumpman

#endif  // ENGINE_ENGINE_HPP_
