#include <fstream>
#define GL3_PROTOTYPES
#include <OpenGL/gl3.h>
#include <SDL2/SDL.h>
#include "engine/graphics/scene.hpp"
#include "engine/sound/system.hpp"
#include "engine.hpp"
#include "input.hpp"
#include "logging.hpp"
#include "scriptcontext.hpp"

namespace Jumpman {

struct Engine::EngineData {
  SDL_Window* main_window = NULL;
  SDL_GLContext gl_context = NULL;
  std::shared_ptr<Graphics::Scene> scene;
  std::shared_ptr<Sound::System> sound_system;
  std::shared_ptr<Input> input;
  std::shared_ptr<ScriptContext> script_context;
};

Engine::Engine() : data_(new EngineData) {
}

Engine::~Engine() {
  data_->script_context.reset();
  data_->input.reset();
  data_->sound_system.reset();
  data_->scene.reset();
  SDL_GL_DeleteContext(data_->gl_context);
  SDL_DestroyWindow(data_->main_window);
  SDL_Quit();
}

bool Engine::Initialize() {
  InitializeLogging();
  AddLogFile("log.txt");  // TODO: Put in writable directory path
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Engine");

  // TODO: Load config, initialize all subsystems, etc

  if (SDL_Init(SDL_INIT_EVERYTHING) != 0) {
    BOOST_LOG_SEV(log, LogSeverity::kError)
      << "Failed to initialize SDL: " << SDL_GetError();
    return false;
  }

  SDL_GL_SetAttribute(  // Required by OSX
    SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);

  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
  SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

  SDL_Window* main_window = SDL_CreateWindow(
    "Jumpan Zero",
    SDL_WINDOWPOS_CENTERED,
    SDL_WINDOWPOS_CENTERED,
    640,
    480,
    SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);

  if (!main_window) {
    BOOST_LOG_SEV(log, LogSeverity::kError)
      << "Failed to create main window: " << SDL_GetError();
    return false;
  }

  data_->main_window = main_window;

  SDL_GLContext gl_context = SDL_GL_CreateContext(main_window);

  if (!gl_context) {
    BOOST_LOG_SEV(log, LogSeverity::kError)
      << "Failed to create OpenGL context: " << SDL_GetError();
    return false;
  }

  data_->gl_context = gl_context;

  if (SDL_GL_SetSwapInterval(1) != 0) {
    BOOST_LOG_SEV(log, LogSeverity::kWarning)
      << "Failed to set GL swap interval: " << SDL_GetError();
  }

  glEnable(GL_BLEND);  // TODO: Should never error?
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);  // TODO: Shouldn't error?

  glEnable(GL_DEPTH_TEST);  // TODO: Should never error?
  glEnable(GL_CULL_FACE);  // TODO: Should never error?

  data_->scene.reset(new Graphics::Scene);
  data_->sound_system.reset(new Sound::System);
  data_->input.reset(new Input);
  data_->script_context.reset(
    new ScriptContext(
      data_->scene, data_->sound_system, data_->input, "data/script/main.lua"));

  return true;
}

int Engine::Run() {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Engine");

  const double max_accumulated_time = 2.0;
  const double ticks_per_second = SDL_GetPerformanceFrequency();
  const double seconds_per_update = 1.0 / 60.0;
  double previous_tick_count = SDL_GetPerformanceCounter();
  double accumulated_time = 0.0;
  bool is_running = true;

  while (is_running) {
    double current_tick_count = SDL_GetPerformanceCounter();
    double delta_tick_count = current_tick_count - previous_tick_count;
    double time_since_last_frame = delta_tick_count / ticks_per_second;
    accumulated_time += time_since_last_frame;
    previous_tick_count = current_tick_count;

    if (accumulated_time > max_accumulated_time) {
      accumulated_time = max_accumulated_time;
    }

    if (accumulated_time > seconds_per_update) {
      accumulated_time -= seconds_per_update;

      SDL_PumpEvents();
      is_running = !SDL_HasEvent(SDL_QUIT);
      data_->input->Update();

      is_running &= data_->script_context->Update(seconds_per_update);
    }

    // TODO: Check OpenGL errors?
    glClearColor(0.15, 0.15, 0.15, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    data_->scene->Draw(time_since_last_frame);

    SDL_GL_SwapWindow(data_->main_window);
  }

  return 0;
}

};  // namespace Jumpman
