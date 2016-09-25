TODO: More info about total rebuild

#[Jumpman Zero](http://www.jumpmanzero.com)

A platformer video game with a very old-school theme. Based on the [Jumpman](http://en.wikipedia.org/wiki/Jumpman) series by Randy Glover, released by Epyx in 1983.

Not to be confused with the original name of Nintendo's mascot, though Donkey Kong was an inspiration to Randy's vision of the game.

Jumpman Zero is a completely original game with a similar theme to Randy Glover's Jumpman. It is written by Dave Campbell (along with other contributors).

Currently Windows is the only supported platform.

([archive for Jumpman Zero home page](http://web.archive.org/web/20120527012046/http://www.jumpmanzero.com/), since above link is broken)

##About this repository

[The original home page for the Jumpman Zero project](http://www.jumpmanzero.com) is currently inaccessible. I haven't managed to get in contact with the author yet about this, but [an archive of the Jumpman Zero site](http://web.archive.org/web/20120527012046/http://www.jumpmanzero.com/) is still visible, as is the source code/tools and latest released version of the game.

This repository exists in order to continue Dave's work, and to add Merlyn Morgan-Graham's work on porting the game to Linux and Apple OS X. Contributions from others are perfectly welcome as well.

It seems from [Dave Campbell's Jumpman Zero developer diary](http://web.archive.org/web/20110713125316/http://www.jumpmanzero.com/pc/diary.htm) that some of his work never got publically released. Maybe some of those features or bug fixes will make it into this development branch at some point.

##Building

###Clone this repository

Install Git and follow [the instructions off GitHub](https://help.github.com/articles/working-with-repositories) to clone [the Jumpman Zero repository](https://github.com/kavika13/jumpmanzero). No need to fork it first (unless you want to) - just clone.

###Makefile based build instructions

TODO: Full instructions for each OS and each dependency.

Just build with:

    make

Dependencies:

- FMOD 1.08.11 (put in `extlibs` and rename the top level directory so it becomes `extlibs/FMOD-1.08.11`)
- glm 0.9.8.0 (put in `extlibs`, forget if you have to rename)
- jsoncpp 1.7.5 (see instruction below)
- lua 5.3.3 (put in `extlibs` and build it + lib, forget if you have to rename)
- SDL2_Image 2.0.1 (put framework in `extlibs/SDL2_image-2.0.1/Frameworks`)
- SDL2 2.0.4 (put framework in `extlibs/SDL2-2.0.4/Frameworks`)

- Unzip jsoncpp (1.7.5) to `extlibs` so it creates a `jsoncpp-1.7.5` subdirectory
- Build jsoncpp with:

    mkdir -p extlibs/jsoncpp-1.7.5/build
    cd extlibs/jsoncpp-1.7.5/build
    cmake -DJSONCPP_WITH_PKGCONFIG_SUPPORT=OFF -DBUILD_STATIC_LIBS=ON -DBUILD_SHARED_LIBS=ON -DLIBRARY_INSTALL_DIR=../lib -DARCHIVE_INSTALL_DIR=../lib -DINCLUDE_INSTALL_DIR=../include -G "Unix Makefiles" ..
    make install
