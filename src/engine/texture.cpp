#include "logging.hpp"
#include "openglerror.hpp"
#include "texture.hpp"

Texture::Texture() {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Graphics");
  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Creating texture";

  glGenTextures(1, &handle_);

  if (AreOpenGLErrorFlagsSet()) {
    BOOST_LOG_SEV(log, LogSeverity::kError) << "Error creating texture";
    throw std::runtime_error("Error creating texture");
  }

  BOOST_LOG_SEV(log, LogSeverity::kDebug) << "Created texture: " << handle_;
}

Texture::Texture(Texture&& other) noexcept : handle_(other.handle_) {
  other.handle_ = 0;
}

Texture::~Texture() {
  Deallocate();
}

Texture& Texture::operator=(Texture&& other) noexcept {
  Deallocate();
  handle_ = other.handle_;
  other.handle_ = 0;
  return *this;
}

Texture::operator GLuint() const {
  return handle_;
}

void Texture::Deallocate() {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Graphics");

  if (handle_) {
    BOOST_LOG_SEV(log, LogSeverity::kDebug)
      << "Destorying texture: " << handle_;
    glDeleteTextures(1, &handle_);
  }
}

Image::Image(const std::string& filename) {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Graphics");
  BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Loading image: " << filename;

  SDL_Surface* loaded_surface = IMG_Load(filename.c_str());

  if (!loaded_surface) {
    std::string error_message(
      "Error loading image: " + filename + " - " + IMG_GetError());
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  // Ensure we're using RGBA
  handle_ = SDL_ConvertSurfaceFormat(
    loaded_surface, SDL_PIXELFORMAT_ARGB8888, 0);

  SDL_FreeSurface(loaded_surface);

  if (!handle_) {
    std::string error_message(
      "Error converting image to RGBA: " + filename + " - " + IMG_GetError());
    BOOST_LOG_SEV(log, LogSeverity::kError) << error_message;
    throw std::runtime_error(error_message);
  }

  BOOST_LOG_SEV(log, LogSeverity::kDebug)
    << "Finished loading image: " << filename;
}

Image::Image(Image&& other) noexcept : handle_(other.handle_) {
  other.handle_ = NULL;
}

Image::~Image() {
  Deallocate();
}

Image& Image::operator=(Image&& other) noexcept {
  Deallocate();
  handle_ = other.handle_;
  other.handle_ = 0;
  return *this;
}

Image::operator SDL_Surface*() const {
  return handle_;
}

void Image::Deallocate() {
  GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(log, "Graphics");

  if (handle_) {
    BOOST_LOG_SEV(log, LogSeverity::kTrace) << "Destorying image: " << handle_;
    SDL_FreeSurface(handle_);
  }
}
