==============================================================
# propeller-gcc
A port of GCC to the Parallax Propeller
==============================================================

This project uses submodules so it requires a slightly different setup procedure:

    git clone https://github.com/dbetz/propeller-gcc.git
    cd propeller-gcc
    git submodule init
    git submodule update

After cloning the propeller-gcc repository and updating the submodules you need to
fetch some additional libraries needed to build GCC. Doing this requires that you
have wget available on your machine.

    cd propeller-gcc/gcc
    ./contrib/download_prerequisites

MacOS does not seem to come with wget so you will probably have to add an alias
at the start of the download_prerequisits file:

    alias wget="curl -O"

Also, the Xcode compiler seems to be more picky than the compilers on other platforms
so you will probably need to disable some warnings:

    source fix-xcode-warnings.sh
    
To build propeller-gcc (currently builds gcc4):

    make
    
To build with gcc4:

    make GCCDIR=gcc4

To build with gcc5:

    make GCCDIR=gcc

To install propeller-gcc into /opt/parallax:

    sudo make install
    
To install propeller-gcc to another location:

    INSTALL=/my/install/directory make install
    
To update all submodules to the latest commit in their home repositories:

    git submodule foreach git pull origin master
    
==============================================================
Cross Compilation Instructions
==============================================================

This is a guide for how to produce propeller-elf-gcc tools for 
Windows (32 bit) or Raspberry Pi on your Linux machine. Both could
be produced natively, but take a long time to build, so cross compilation
is attractive.

The instructions assume a Ubuntu 14.04 LTS machine is being used to do
the builds. Other Linux versions should work as well (in particular newer
Ubuntu releases). They also assume you can already build the native
Linux tools.

NOTE: all cross-compilations require that the native Propeller tools be
built first, and that they are available on the PATH. Typically this is
done by adding /opt/parallax/bin to your PATH environment variable.

==============================================================
WINDOWS
==============================================================

(1) Install the mingw-w64 toolchain for Ubuntu:
    sudo apt-get install mingw-w64

(2) Make the native propeller-gcc toolchain (if you haven't already) by doing:
    make
    sudo make install
in the propeller-gcc directory. The output is in /opt/parallax.

(3) Build the Win32 toolchain by doing:
    make CROSS=win32
in the propeller-gcc directory. The output is in ../propeller-gcc-win32-build.

==============================================================
RASPBERRY PI
==============================================================

(1) Install a Raspberry Pi cross compiler. I followed the directions from
http://hertaville.com/2012/09/28/development-environment-raspberry-pi-cross-compiler/,
but I skipped all the Eclipse stuff (the command line tools are all 
we need). This boils down to:

    mkdir ~/rpi
    cd ~/rpi
    git clone git://github.com/raspberrypi/tools.git
    export PATH=$PATH:~/rpi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/

You'll probably want to add the "export PATH=..." stuff to one of your
startup scripts, e.g. .bashrc, so as to avoid typing it every time.

NOTE: if you install the Raspberry Pi cross compiler in a different place,
or use a different cross compiler, then you'll have to adjust the
definitions in the Makefile. In particular the CURSES_PREFIX variable will
have to be set so that the ncurses library can be installed in the proper
place (where the ARM libraries are), and obviously the CROSS_TARGET setting
will have to reflect the proper name for the toolchain -- gcc, for example,
will be invoked as $(CROSS_TARGET)-gcc.

(2) Make the native propeller-gcc toolchain (if you haven't already).

(3) Build the Raspberry Pi toolchain by doing:
    make CROSS=rpi
in the propeller-gcc directory. The output is in ../propeller-gcc-rip-build.
