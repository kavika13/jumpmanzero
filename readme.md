# Getting the game

Binaries are available here: https://github.com/kavika13/jumpmanzero/releases

The game builds and runs on OSX and Linux now, but I haven't put up binaries yet
I will add the alternate OS binaries that when people ask me to! :)

# [Jumpman Zero](http://www.jumpmanzero.com)

A platformer video game with a very old-school theme. Based on the [Jumpman](http://en.wikipedia.org/wiki/Jumpman) series by Randy Glover, released by Epyx in 1983.

Not to be confused with the original name of Nintendo's mascot, though Donkey Kong was an inspiration to Randy's vision of the game.

Jumpman Zero is a completely original game with a similar theme to Randy Glover's Jumpman. It is written by Dave Campbell (along with other contributors).

Currently Windows is the only supported platform.

([archive for Jumpman Zero home page](http://web.archive.org/web/20120527012046/http://www.jumpmanzero.com/), since above link is broken)

## About this repository

[The original home page for the Jumpman Zero project](http://www.jumpmanzero.com) is currently inaccessible. I haven't managed to get in contact with the author yet about this, but [an archive of the Jumpman Zero site](http://web.archive.org/web/20120527012046/http://www.jumpmanzero.com/) is still visible, as is the source code/tools and latest released version of the game.

This repository exists in order to continue Dave's work, and to add Merlyn Morgan-Graham's work on porting the game to Linux and Apple OS X. Contributions from others are perfectly welcome as well.

It seems from [Dave Campbell's Jumpman Zero developer diary](http://web.archive.org/web/20110713125316/http://www.jumpmanzero.com/pc/diary.htm) that some of his work never got publically released. Maybe some of those features or bug fixes will make it into this development branch at some point.

## Building

Most of these instructions are very out of date, and very excessive. For the most part I think you can just install VS community 2015 or above, making sure you installed C++ and the Windows SDK. Then just open the solution (see [the section below](https://github.com/kavika13/jumpmanzero#open-the-solution-in-visual-studio)), and build and run it.

It's possible you might need a recent DirectX SDK, but you definitely don't need a fancy weird one like the old instructions say you do.

I'll try this all out on a clean Windows install some time soon and update these instructions for real.

### Clone this repository

Install Git and follow [the instructions off GitHub](https://help.github.com/articles/working-with-repositories) to clone [the Jumpman Zero repository](https://github.com/kavika13/jumpmanzero). No need to fork it first (unless you want to) - just clone.

~~### Install Visual Studio~~

~~2012 is the version I am using~~

~~### Install a DirectX SDK~~

~~The simplest way to get a good SDK version is to clone and use [the Jumpman Zero third-party packages repository](https://github.com/kavika13/jumpmanzero-thirdparty). The rest of this section is how I got hold of those packages and a warning about them - use at your own risk!~~

~~You need a version that supports [DirectMusic](http://en.wikipedia.org/wiki/DirectMusic) and includes the extended DirectX 8 SDK~~

~~The last one that supported these is [the October 2004 release, which is no longer available](www.microsoft.com/download/en/details.aspx?id=19320)~~

~~- See [The web archive of the MS download](http://web.archive.org/web/20111220021902/http://www.microsoft.com/download/en/details.aspx?id=19320)~~

~~I got [a copy of the SDK download from google off "FindThatFile.com"](http://www.findthatfile.com/search-608303-fEXE/software-tools-download-dxsdk_oct2004.exe.htm) (totally legit :P - lots of sarcasm)~~

~~- I scanned the file with a virus scanner (Windows Defender)~~
~~- I checked that the checksum matched [the only MD5 I could find on the web](http://www.isthisfilesafe.com/md5/7400ADDC1EF83CC8A813040E192168CA_details.aspx) (couldn't find a checksum on MS's site, and I don't have an MSDN subscription).  This might just mean it is the same tampered file.  **Try at your own risk**~~

~~Apparently when installing you can [ignore the error message: "This Pre-release version of Xaudio2 has expired"](http://forum.thegamecreators.com/?m=forum_view&t=185890&b=22) - this might only apply to the August 2007 SDK though.  I tried that one first.~~

### Open the Solution in Visual Studio

The solution is `Jumpman/Jumpman.sln`

~~### Setup your SDK sources~~

~~Point at the DirectX SDK you installed (Include and Libraries folders)~~

~~- TODO: Set up these values via user Property Sheets for `DXInstallDir` macro now used by build (see value below).~~
~~- See the "To specify a per-user directory list" section of [the archived Directories Property Page instructions](https://web.archive.org/web/20130106025556/http://msdn.microsoft.com/en-us/library/vstudio/ee855621.aspx)~~
~~- Make sure you add the DirectX SDK Include/Lib paths, and add them **before all other paths** - otherwise the Windows SDK versions of the headers might be used instead, and you'll have build problems~~
~~- Make sure you set up the directories for both the Debug and Release builds (if it doesn't automatically do both.  It did both at the same time for me)~~
~~- The library I am using is installed at `C:\Program Files (x86)\Microsoft DirectX 9.0 SDK (October 2004)\`. Create a `DXInstallDir` macro with this value.~~

### Additional credits/software used

- https://github.com/floooh/sokol (sokol_gfx - minimal cross-platform standalone C header for 3D graphics)
- https://github.com/nothings/stb (stb_image - image loading/decoding from file/memory: JPG, PNG, TGA, BMP, PSD, GIF, HDR, PIC)
- https://github.com/glfw/glfw (A multi-platform library for OpenGL, OpenGL ES, Vulkan, window and input http://www.glfw.org/)
- https://github.com/Dav1dde/glad (Multi-Language Vulkan/GL/GLES/EGL/GLX/WGL Loader-Generator based on the official specs. https://glad.dav1d.de/)
- https://github.com/HandmadeMath/Handmade-Math (A simple math library for games and computer graphics)
- http://falcosoft.hu/softwares.html (for Reality_GMGS_falcomod.sf2 sound font)
- https://github.com/dr-soft/mini_al (Single file audio playback and capture library)
- https://github.com/schellingb/TinySoundFont (SoundFont2 synthesizer library in a single C/C++ file)
