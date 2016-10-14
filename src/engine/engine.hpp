#ifndef ENGINE_ENGINE_HPP_
#define ENGINE_ENGINE_HPP_

#include <memory>

struct EngineData;

class Engine {
 public:
  Engine();
  ~Engine();

  bool Initialize();
  int Run();

 private:
  std::unique_ptr<EngineData> data_;
};

#endif  // ENGINE_ENGINE_HPP_
