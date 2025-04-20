#include <math.h>
#include "glad/glad.h"
#define SOKOL_IMPL
#define SOKOL_GLCORE33
#define SOKOL_EXTERNAL_GL_LOADER
#include "sokol_gfx.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define MA_NO_AVX2
#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

#define STB_SPRINTF_IMPLEMENTATION
#define STB_SPRINTF_NOUNALIGNED
#include "stb_sprintf.h"
