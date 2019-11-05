inc = [
    'boxer-c/include',
    'cute_files-6760a7d',
    'glad/include',
    'handmademath-1.7.0',
    'lua-5.3.5/src',
    'mini_al-0.8.9',
    'sokol-gfx-master-f1efc6d',
    'stb-image-2.19.0',
    'stb-sprintf-1.06.0',
    'tiny_sound_font-master-5506592',
]

incdir = include_directories(inc)

src = [
    'Basic3D.c',
    'Jumpman.c',
    'Main.c',
    'Music.c',
    'Sound.c',
    'SoundBuffer.c',
    'Utilities.c',
    # Glad source files
    'glad/src/glad.c',
    # Boxer source files
    'boxer-c/src/boxer_linux.c',
    # Lua source files
    'lua-5.3.5/src/lapi.c',
    'lua-5.3.5/src/lauxlib.c',
    'lua-5.3.5/src/lbaselib.c',
    'lua-5.3.5/src/lbitlib.c',
    'lua-5.3.5/src/lcode.c',
    'lua-5.3.5/src/lcorolib.c',
    'lua-5.3.5/src/lctype.c',
    'lua-5.3.5/src/ldblib.c',
    'lua-5.3.5/src/ldebug.c',
    'lua-5.3.5/src/ldo.c',
    'lua-5.3.5/src/ldump.c',
    'lua-5.3.5/src/lfunc.c',
    'lua-5.3.5/src/lgc.c',
    'lua-5.3.5/src/linit.c',
    'lua-5.3.5/src/liolib.c',
    'lua-5.3.5/src/llex.c',
    'lua-5.3.5/src/lmathlib.c',
    'lua-5.3.5/src/lmem.c',
    'lua-5.3.5/src/loadlib.c',
    'lua-5.3.5/src/lobject.c',
    'lua-5.3.5/src/lopcodes.c',
    'lua-5.3.5/src/loslib.c',
    'lua-5.3.5/src/lparser.c',
    'lua-5.3.5/src/lstate.c',
    'lua-5.3.5/src/lstring.c',
    'lua-5.3.5/src/lstrlib.c',
    'lua-5.3.5/src/ltable.c',
    'lua-5.3.5/src/ltablib.c',
    'lua-5.3.5/src/ltm.c',
    'lua-5.3.5/src/lundump.c',
    'lua-5.3.5/src/lutf8lib.c',
    'lua-5.3.5/src/lvm.c',
    'lua-5.3.5/src/lzio.c',
]

c_compiler = meson.get_compiler('c')

glfw3_dep = dependency('glfw3', version : '>=3.3.0')
gtk3_dep = dependency('gtk+-3.0', version : '>=3.24.0')
dl_dep = c_compiler.find_library('dl')
m_dep = c_compiler.find_library('m')
pthread_dep = c_compiler.find_library('pthread')

exe = executable('jumpmanzero', src,
    include_directories : incdir,
    dependencies : [glfw3_dep, gtk3_dep, dl_dep, m_dep, pthread_dep],
    c_args : '-Wno-pedantic',
    install : true)
