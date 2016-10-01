#ifndef ENGINE_ENGINE_HPP_
#define ENGINE_ENGINE_HPP_

#include <memory>
#include <string>

struct EngineData;

class Engine {
 public:
  Engine();
  ~Engine();

  bool Initialize();
  bool LoadLevel(const std::string& filename);
  int Run();

 private:
  std::unique_ptr<EngineData> data_;
};

#endif  // ENGINE_ENGINE_HPP_
