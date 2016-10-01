#include <fstream>
#include <unordered_map>
#define GLM_FORCE_LEFT_HANDED
#include <glm/mat4x4.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <glm/gtx/projection.hpp>
#include <glm/gtx/string_cast.hpp>
#define GL3_PROTOTYPES
#include <OpenGL/gl3.h>
#include <SDL2/SDL.h>
#include "engine.hpp"
#include "leveldata.hpp"
#include "logging.hpp"
#include "shader.hpp"
#include "texture.hpp"
#include "vertexbuffer.hpp"

struct Vertex {
  static Vertex FromData(const VertexData& data) {
    return Vertex {
      data.x,
      data.y,
      data.z,
      // TODO: Normals
      data.tu,
      data.tv,
    };
  }

  Vertex AddTexCoord(float tu, float tv) const {
    return Vertex {
      this->x,
      this->y,
      this->z,
      // TODO: Normals
      tu,
      tv,
    };
  }

  Vertex AddZ(float z) const {
    return Vertex {
      this->x,
      this->y,
      z,
      // TODO: Normals
      this->tu,
      this->tv,
    };
  }

  float x, y, z;
  // float nx, ny, nz;
  float tu, tv;
};

struct SceneObject {
  glm::mat4 model_matrix;
  GLuint texture_handle;
  size_t starting_vertex_index;
  size_t vertex_count;
};

struct Scene {
  glm::mat4 projection_matrix;
  glm::mat4 view_matrix;
  std::vector<SceneObject> objects;
};

struct EngineData {
  SDL_Window* main_window = NULL;
  SDL_GLContext gl_context = NULL;
  std::vector<Vertex> vertices;
  std::vector<std::unique_ptr<Texture>> textures;
  std::unordered_map<std::string, GLuint> tag_to_texture_map;
  std::unique_ptr<VertexBuffer> vertex_buffer;
  std::unique_ptr<VertexArray> vertex_array;
  std::unique_ptr<ShaderProgram> shader_program;
  std::unique_ptr<ShaderUniformParameter> mvp_matrix_parameter;
  std::unique_ptr<ShaderUniformParameter> current_texture_parameter;
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

  // TODO: Check for OpenGL errors:
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  glEnable(GL_DEPTH_TEST);
  glEnable(GL_CULL_FACE);

  return true;
}

bool Engine::LoadLevel(const std::string& filename) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Engine");

  std::ifstream levelfile(filename);

  if (!levelfile) {
    BOOST_LOG_SEV(log, LogSeverity::kError)
      << "Failed to open level file: " << filename;
    return false;
  }

  // TODO: Level object that takes the data and creates/populates a scene

  auto leveldata = LevelData::FromStream(levelfile);

  for (const TextureResourceData& texture_resource: leveldata.textures) {
    // TODO: Handle colorkey alpha in texture class
    std::unique_ptr<Texture> texture(new Texture);
    Image image(texture_resource.filename);

    glBindTexture(GL_TEXTURE_2D, *texture);
    SDL_Surface* image_data = image;

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    // TODO: Correct target pixel format based on what OpenGL/SDL tells us,
    // or whichever SDL functions do the right conversion without extra work
    glTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, image_data->w, image_data->h, 0,
      GL_BGRA, GL_UNSIGNED_BYTE, image_data->pixels);
    glGenerateMipmap(GL_TEXTURE_2D);

    glBindTexture(GL_TEXTURE_2D, 0);

    data_->tag_to_texture_map[texture_resource.tag] = *texture;
    data_->textures.push_back(std::move(texture));
  }

  std::vector<SceneObject> scene_objects;
  data_->vertices.reserve(leveldata.quads.size() * 6);

  auto add_triangle = [&](
      const Vertex& v0, const Vertex& v1, const Vertex& v2) {
    data_->vertices.push_back(v0);
    data_->vertices.push_back(v1);
    data_->vertices.push_back(v2);
  };

  auto add_pretextured_quad = [&](
      const Vertex& upper_left, const Vertex& upper_right,
      const Vertex& lower_left, const Vertex& lower_right) {
    add_triangle(upper_left, lower_left, upper_right);
    add_triangle(upper_right, lower_left, lower_right);
  };

  auto add_quad = [&](
      const Vertex& v0, const Vertex& v1, const Vertex& v2, const Vertex& v3) {
    const Vertex upper_left = v0.AddTexCoord(0.0f, 1.0f);
    const Vertex upper_right = v1.AddTexCoord(1.0f, 1.0f);
    const Vertex lower_left = v2.AddTexCoord(0.0f, 0.0f);
    const Vertex lower_right = v3.AddTexCoord(1.0f, 0.0f);

    add_pretextured_quad(upper_left, upper_right, lower_left, lower_right);
  };

  auto add_cube = [&](
      float x_left, float y_top, float z_front,
      float x_right, float y_bottom, float z_back) {
    const Vertex left_top_front { x_left, y_top, z_front };
    const Vertex left_top_back { x_left, y_top, z_back };
    const Vertex left_bottom_front { x_left, y_bottom, z_front };
    const Vertex left_bottom_back { x_left, y_bottom, z_back };
    const Vertex right_top_front { x_right, y_top, z_front };
    const Vertex right_top_back { x_right, y_top, z_back };
    const Vertex right_bottom_front { x_right, y_bottom, z_front };
    const Vertex right_bottom_back { x_right, y_bottom, z_back };

    add_quad(
      left_top_front, right_top_front,
      left_bottom_front, right_bottom_front);
    add_quad(
      right_top_back, left_top_back,
      right_bottom_back, left_bottom_back);
    add_quad(
      left_top_back, right_top_back,
      left_top_front, right_top_front);
    add_quad(
      left_bottom_front, right_bottom_front,
      left_bottom_back, right_bottom_back);
    add_quad(
      left_top_back, left_top_front,
      left_bottom_back, left_bottom_front);
    add_quad(
      right_top_front, right_top_back,
      right_bottom_front, right_bottom_back);
  };

  for (const QuadObjectData& quad: leveldata.quads) {
    size_t starting_vertex_index = data_->vertices.size();

    const Vertex v0 = Vertex::FromData(quad.vertices[0]);
    const Vertex v1 = Vertex::FromData(quad.vertices[1]);
    const Vertex v2 = Vertex::FromData(quad.vertices[2]);
    const Vertex v3 = Vertex::FromData(quad.vertices[3]);

    add_quad(v0, v1, v2, v3);

    scene_objects.push_back({
      glm::mat4(),
      data_->tag_to_texture_map.at(quad.texture_tag),
      starting_vertex_index,
      data_->vertices.size() - starting_vertex_index,
    });
  }

  for (const DonutObjectData& donut: leveldata.donuts) {
    size_t starting_vertex_index = data_->vertices.size();

    add_cube(
      donut.origin_x - 1, donut.origin_y + 3, donut.origin_z,
      donut.origin_x + 1, donut.origin_y + 1, donut.origin_z + 1);
    add_cube(
      donut.origin_x - 3, donut.origin_y + 1, donut.origin_z,
      donut.origin_x - 1, donut.origin_y - 1, donut.origin_z + 1);
    add_cube(
      donut.origin_x + 1, donut.origin_y + 1, donut.origin_z,
      donut.origin_x + 3, donut.origin_y - 1, donut.origin_z + 1);
    add_cube(
      donut.origin_x - 1, donut.origin_y - 1, donut.origin_z,
      donut.origin_x + 1, donut.origin_y - 3, donut.origin_z + 1);

    scene_objects.push_back({
      glm::mat4(),
      data_->tag_to_texture_map.at(donut.texture_tag),
      starting_vertex_index,
      data_->vertices.size() - starting_vertex_index,
    });
  }

  auto add_platform_cube = [&](
      const PlatformObjectData& platform,
      const Vertex& v0, const Vertex& v1, const Vertex& v2, const Vertex& v3,
      float front_z, float back_z) {
    // TODO: Reduce the math/temp variables here
    const Vertex left_top_front = v0.AddZ(front_z);
    const Vertex left_top_back = v0.AddZ(back_z);
    const Vertex left_bottom_front = v2.AddZ(front_z);
    const Vertex left_bottom_back = v2.AddZ(back_z);
    const Vertex right_top_front = v1.AddZ(front_z);
    const Vertex right_top_back = v1.AddZ(back_z);
    const Vertex right_bottom_front = v3.AddZ(front_z);
    const Vertex right_bottom_back = v3.AddZ(back_z);

    const glm::vec2 top_left_vec = glm::vec2(
      left_top_front.x, left_top_front.y);
    const glm::vec2 top_right_vec = glm::vec2(
      right_top_front.x, right_top_front.y);
    const glm::vec2 bottom_left_vec = glm::vec2(
      left_bottom_front.x, left_bottom_front.y);
    const glm::vec2 bottom_right_vec = glm::vec2(
      right_bottom_front.x, right_bottom_front.y);

    const glm::vec2 texture_direction_x = top_right_vec - top_left_vec;
    const glm::vec2 texture_normal_x = glm::normalize(texture_direction_x);
    const float length_x = glm::length(texture_direction_x);

    const float scale_tu_base = length_x / 15.0f;
    const float scale_tu_temp = round(scale_tu_base * 4.0f) / 4.0f;
    const float scale_tu = (scale_tu_temp / scale_tu_base) / 15.0f;

    const float top_right_tu = length_x * scale_tu;

    const float length_bottom_left_x = glm::dot(
      bottom_left_vec - top_left_vec, texture_normal_x);
    const float bottom_left_tu = length_bottom_left_x * scale_tu;

    const float length_bottom_right_x = glm::dot(
      bottom_right_vec - top_left_vec, texture_normal_x);
    const float bottom_right_tu = length_bottom_right_x * scale_tu;

    if (platform.drawtop) {
      add_pretextured_quad(
        left_top_back.AddTexCoord(0.0f, 0.5f),
        right_top_back.AddTexCoord(top_right_tu, 0.5f),
        left_top_front.AddTexCoord(0.0f, 0.0f),
        right_top_front.AddTexCoord(top_right_tu, 0.0f));
    }

    if (platform.drawbottom) {
      add_pretextured_quad(
        left_bottom_front.AddTexCoord(0.0f, 0.5f),
        right_bottom_front.AddTexCoord(top_right_tu, 0.5f),
        left_bottom_back.AddTexCoord(0.0f, 0.0f),
        right_bottom_back.AddTexCoord(top_right_tu, 0.0f));
    }

    if (platform.drawleft) {
      add_pretextured_quad(
        // TODO: Project texture with vertical scale?
        left_top_back.AddTexCoord(0.0f, 0.5f),
        left_top_front.AddTexCoord(bottom_left_tu, 0.5f),
        left_bottom_back.AddTexCoord(0.0f, 0.0f),
        left_bottom_front.AddTexCoord(bottom_left_tu, 0.0f));
    }

    if (platform.drawright) {
      add_pretextured_quad(
        // TODO: Project texture with vertical scale?
        right_top_front.AddTexCoord(0.0f, 0.5f),
        right_top_back.AddTexCoord(bottom_right_tu, 0.5f),
        right_bottom_front.AddTexCoord(0.0f, 0.0f),
        right_bottom_back.AddTexCoord(bottom_right_tu, 0.0f));
    }

    if (platform.drawfront) {
      add_pretextured_quad(
        left_top_front.AddTexCoord(0.0f, 1.0f),
        right_top_front.AddTexCoord(top_right_tu, 1.0f),
        left_bottom_front.AddTexCoord(bottom_left_tu, 0.5f),
        right_bottom_front.AddTexCoord(bottom_right_tu, 0.5f));
    }

    if (platform.drawback) {
      add_pretextured_quad(
        right_top_back.AddTexCoord(top_right_tu, 1.0f),
        left_top_back.AddTexCoord(0.0f, 1.0f),
        right_bottom_back.AddTexCoord(bottom_right_tu, 0.5f),
        left_bottom_back.AddTexCoord(bottom_left_tu, 0.5f));
    }
  };

  for (const PlatformObjectData& platform: leveldata.platforms) {
    size_t starting_vertex_index = data_->vertices.size();

    add_platform_cube(
      platform,
      Vertex::FromData(platform.vertices[0]),
      Vertex::FromData(platform.vertices[1]),
      Vertex::FromData(platform.vertices[2]),
      Vertex::FromData(platform.vertices[3]),
      platform.front_z, platform.back_z);

    scene_objects.push_back({
      glm::mat4(),
      data_->tag_to_texture_map.at(platform.texture_tag),
      starting_vertex_index,
      data_->vertices.size() - starting_vertex_index,
    });
  }

  data_->vertex_buffer.reset(new VertexBuffer(data_->vertices));
  data_->vertex_array.reset(new VertexArray([&]() {
    // TODO: Defer this to an Initialize function
    GLuint index = 0;

    // TODO: Check OpenGL errors?
    glBindBuffer(GL_ARRAY_BUFFER, *data_->vertex_buffer);
      glVertexAttribPointer(
        index, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex),
        reinterpret_cast<GLvoid*>(offsetof(Vertex, x)));
      glEnableVertexAttribArray(index++);

      glVertexAttribPointer(
        index, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex),
        reinterpret_cast<GLvoid*>(offsetof(Vertex, tu)));
      glEnableVertexAttribArray(index++);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
  }));

  auto read_file_to_string = [](std::ifstream& file, std::string& source) {
    file.seekg(0, std::ios::end);
    source.resize(file.tellg());
    file.seekg(0, std::ios::beg);
    file.read(&source[0], source.size());
    file.close();
  };

  {
    const std::string vertexshaderfilename = "data/shader/global.vert";
    std::ifstream vertexshaderfile(vertexshaderfilename);

    if (!vertexshaderfile) {
      BOOST_LOG_SEV(log, LogSeverity::kError)
        << "Failed to open level file: " << vertexshaderfilename;
      return false;
    }

    const std::string fragmentshaderfilename = "data/shader/global.frag";
    std::ifstream fragmentshaderfile(fragmentshaderfilename);

    if (!fragmentshaderfile) {
      BOOST_LOG_SEV(log, LogSeverity::kError)
        << "Failed to open level file: " << fragmentshaderfilename;
      return false;
    }

    std::string vertexshadersource;
    read_file_to_string(vertexshaderfile, vertexshadersource);
    VertexShader vertex_shader(vertexshadersource);

    std::string fragmentshadersource;
    read_file_to_string(fragmentshaderfile, fragmentshadersource);
    FragmentShader fragment_shader(fragmentshadersource);

    data_->shader_program.reset(
      new ShaderProgram(vertex_shader, fragment_shader));
  }

  data_->current_texture_parameter.reset(
    new ShaderUniformParameter(*data_->shader_program, "current_texture"));
  data_->mvp_matrix_parameter.reset(
    new ShaderUniformParameter(*data_->shader_program, "mvp_matrix"));

  glm::mat4 projection_matrix = glm::perspective(
    glm::radians(45.0f),
    // TODO: Don't get window values from constants
    static_cast<float>(640) / static_cast<float>(480),
    0.1f, 300.0f);
  glm::mat4 view_matrix = glm::lookAt(
    glm::vec3(80.0f, 103.0f, -115.0f),
    glm::vec3(80.0f, 63.0f, 0.0f),
    glm::vec3(0.0f, 1.0f, 0.0f));

  data_->scene.reset(new Scene {
    std::move(projection_matrix),
    std::move(view_matrix),
    std::move(scene_objects),
  });

  return true;
}

int Engine::Run() {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Engine");

  // TODO: Running without a "level"" should be fine, should run GUI

  const double max_accumulated_time = 2.0;
  const double ticks_per_second = SDL_GetPerformanceFrequency();
  const double seconds_per_update = 1.0 / 40.0;
  double previous_tick_count = SDL_GetPerformanceCounter();
  double accumulated_time = 0.0;
  bool is_running = true;

  while (is_running) {
    double current_tick_count = SDL_GetPerformanceCounter();
    double delta_tick_count = current_tick_count - previous_tick_count;
    accumulated_time += delta_tick_count / ticks_per_second;
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
            }
            break;
        }
      }
    }

    // TODO: Move somwehere, to other method or level/scene class maybe
    // TODO: Check OpenGL errors?
    glm::mat4 vp_matrix = data_->scene->projection_matrix
      * data_->scene->view_matrix;

    glClearColor(0.15, 0.15, 0.15, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glUseProgram(*data_->shader_program);
      glBindVertexArray(*data_->vertex_array);

      for (const SceneObject& scene_object: data_->scene->objects) {
        // TODO: Handle enable/diable alpha blend depending on texture data
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, scene_object.texture_handle);
        glUniform1i(*data_->current_texture_parameter, 0);

        glm::mat4 mvp_matrix = scene_object.model_matrix * vp_matrix;
        glUniformMatrix4fv(
          *data_->mvp_matrix_parameter, 1, GL_FALSE,
          glm::value_ptr(mvp_matrix));

        glDrawArrays(
          GL_TRIANGLES,
          scene_object.starting_vertex_index,
          scene_object.vertex_count);
      }

      glBindVertexArray(0);
    glUseProgram(0);

    SDL_GL_SwapWindow(data_->main_window);
  }

  return 0;
}
