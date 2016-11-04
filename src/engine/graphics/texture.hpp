#ifndef ENGINE_GRAPHICS_TEXTURE_HPP_
#define ENGINE_GRAPHICS_TEXTURE_HPP_

#include <string>
#define GL3_PROTOTYPES
#include <OpenGL/gl3.h>
#include <SDL2_image/SDL_image.h>

namespace Jumpman {

namespace Graphics {

class Texture {
 public:
  Texture();
  Texture(const Texture&) = delete;
  Texture(Texture&&) noexcept;
  ~Texture();

  Texture& operator=(const Texture&) = delete;
  Texture& operator=(Texture&&) noexcept;

  bool GetIsAlphaBlendingEnabled() const;
  void SetIsAlphaBlendingEnabled(bool value);

  operator GLuint() const;

 private:
  void Deallocate();

  GLuint handle_;
  bool is_alpha_blending_enabled_;
};

class Image {
 public:
  Image(const std::string& filename, bool enable_colorkey_alpha);
  Image(const Image&) = delete;
  Image(Image&&) noexcept;
  ~Image();

  Image& operator=(const Image&) = delete;
  Image& operator=(Image&&) noexcept;

  operator SDL_Surface*() const;

 private:
  void Deallocate();

  SDL_Surface* handle_;
};

};  // namespace Graphics

};  // namespace Jumpman

#endif  // ENGINE_GRAPHICS_TEXTURE_HPP_
