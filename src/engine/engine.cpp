#include <fstream>
#define GLM_FORCE_LEFT_HANDED
#include <glm/gtc/matrix_transform.hpp>
#define GL3_PROTOTYPES
#include <OpenGL/gl3.h>
#include <SDL2/SDL.h>
#include "engine.hpp"
#include "leveldata.hpp"
#include "levelresource.hpp"
#include "logging.hpp"
#include "resourcecontext.hpp"
#include "scene.hpp"

struct EngineData {
  SDL_Window* main_window = NULL;
  SDL_GLContext gl_context = NULL;
  std::unique_ptr<ResourceContext> resource_context;
  std::unique_ptr<Scene> scene;
};

Engine::Engine() : data_(new EngineData) {
}

Engine::~Engine() {
  // TODO: Shutdown subsystems here, or rely on destruction of sub-objects?
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

  data_->resource_context.reset(new ResourceContext);

  return true;
}

// TODO: Get rid of this function. Put in a script context object?
bool Engine::LoadLevel(const std::string& filename) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Engine");

  std::ifstream levelfile(filename);

  if (!levelfile) {
    BOOST_LOG_SEV(log, LogSeverity::kError)
      << "Failed to open level file: " << filename;
    return false;
  }

  auto leveldata = LevelData::FromStream(levelfile);

  glm::mat4 projection_matrix = glm::perspective(
    glm::radians(45.0f),
    // TODO: Don't get window values from constants
    static_cast<float>(640) / static_cast<float>(480),
    0.1f, 300.0f);

  Camera camera { projection_matrix };
  camera.transform.SetTranslation(glm::vec3(80.0f, 103.0f, -115.0f));
  camera.transform.LookAt(glm::vec3(80.0f, 63.0f, 0.0f));

  data_->scene.reset(new Scene {
    camera,
  });

  LevelResource level(leveldata, *data_->resource_context, *data_->scene);

  return true;
}

int Engine::Run() {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Engine");

  // TODO: Running without a level should be fine, should run GUI
  // TODO: A level should be considered a resource anyhow,
  // not a core engine concept.
  // TODO: There should be a default script that runs the GUI,
  // and the GUI can trigger level loading, or choose not to

  const double max_accumulated_time = 2.0;
  const double ticks_per_second = SDL_GetPerformanceFrequency();
  const double seconds_per_update = 1.0 / 40.0;
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

      // TODO: Move somwehere, to other method or input class maybe
      SDL_Event event;

      while (SDL_PollEvent(&event)) {
        switch (event.type) {
          case SDL_QUIT:
            is_running = false;
            break;
          case SDL_KEYDOWN:
            switch (event.key.keysym.sym) {
              case SDLK_ESCAPE:
                is_running = false;
                break;
              // TODO: Remove this debug camera movement
              case SDLK_w: {
                float amount = event.key.keysym.mod & KMOD_SHIFT ? 10.0f : 1.0f;
                data_->scene->camera.transform.Translate(0.0f, 0.0f, amount);
                break;
              }
              case SDLK_s: {
                float amount = event.key.keysym.mod & KMOD_SHIFT ? 10.0f : 1.0f;
                data_->scene->camera.transform.Translate(0.0f, 0.0f, -amount);
                break;
              }
              case SDLK_UP: {
                float amount = event.key.keysym.mod & KMOD_SHIFT ? 10.0f : 1.0f;
                data_->scene->camera.transform.Translate(0.0f, amount, 0.0f);
                break;
              }
              case SDLK_DOWN: {
                float amount = event.key.keysym.mod & KMOD_SHIFT ? 10.0f : 1.0f;
                data_->scene->camera.transform.Translate(0.0f, -amount, 0.0f);
                break;
              }
              case SDLK_RIGHT: {
                float amount = event.key.keysym.mod & KMOD_SHIFT ? 10.0f : 1.0f;
                data_->scene->camera.transform.Translate(amount, 0.0f, 0.0f);
                break;
              }
              case SDLK_LEFT: {
                float amount = event.key.keysym.mod & KMOD_SHIFT ? 10.0f : 1.0f;
                data_->scene->camera.transform.Translate(-amount, 0.0f, 0.0f);
                break;
              }
            }
            break;
        }
      }
    }

    // TODO: Check OpenGL errors?
    glClearColor(0.15, 0.15, 0.15, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    data_->scene->Draw(time_since_last_frame);

    SDL_GL_SwapWindow(data_->main_window);
  }

  return 0;
}
