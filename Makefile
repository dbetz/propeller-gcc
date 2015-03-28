#
# Normally this Makefile builds binaries for the same system as the host,
# i.e. when run on linux x86 it produces a linux x86 propgcc toolchain.
# However, you can also generate a toolchain for a different platform. To
# do this, first make for the host (just do a plain "make") and then do a
# "make CROSS=win32" to build a win32 toolchain.
#

# NOTE: for raspberry pi cross builds see README.cross for the tools; you may
# need to adjust the CURSES_PREFIX= variable setting below to get ncurses
# installed in the correct directory for your ARM cross-compiler (gdb needs
# ncurses, and that doesn't come with many cross compilers)

#dependencies:
# binutils and gcc have to be built first
#

# set to "gcc" for gcc5 and "gcc4" for gcc4 (from the original propgcc project)
GCCDIR?=gcc4

ROOT=$(shell pwd)
CURSES=
CURSES_PREFIX=$(HOME)
ifeq ($(CROSS),)
  CFGCROSS=
  CROSSCC=gcc
  BUILD?=$(realpath ..)/propeller-$(GCCDIR)-build
else
  BUILD?=$(realpath ..)/propeller-$(GCCDIR)-$(CROSS)-build
  ifeq ($(CROSS),win32)
    CROSS_TARGET=i586-mingw32msvc
    CFGCROSS=--host=$(CROSS_TARGET)
    CROSSCC=$(CROSS_TARGET)-gcc
    OS=msys
    EXT=.exe
  else
    ifeq ($(CROSS),rpi)
      CROSS_TARGET=arm-linux-gnueabihf
      CFGCROSS=--host=$(CROSS_TARGET)
      OS=linux
      EXT=
      CURSES=ncurses
      CURSES_PREFIX=$(HOME)/rpi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/arm-linux-gnueabihf/libc/usr
      CROSSCC=$(CROSS_TARGET)-gcc
    else
      echo "Unknown cross compilation selected"
    endif
  endif
endif

# BUILD is the directory where intermediate results from the build are written
$(warning BUILD directory is $(BUILD))

# PREFIX is the directory where "make" will write its generated files
PREFIX?=$(BUILD)/target
$(warning PREFIX is $(PREFIX))

# INSTALL is the directory where "make install" will copy the results of the build
INSTALL?=/opt/parallax
$(warning INSTALL directory is $(INSTALL))

ECHO=echo
RM=rm
CD=cd
MKDIR=mkdir -p
CHMOD=chmod
CP=cp
TOUCH=touch

UNAME=$(shell uname -s)

ifeq ($(UNAME),Linux)
  OS?=linux
  SRC_SPINCMP=openspin.linux
  EXT?=
endif

ifeq ($(UNAME),Darwin)
  OS?=macosx
  SRC_SPINCMP=openspin.osx
  EXT?=
endif

ifeq ($(UNAME),Msys)
  OS?=msys
  SRC_SPINCMP=openspin.exe
  EXT?=.exe
endif

ifeq ($(OS),)
  $(error Unknown system: $(UNAME))
endif

SPINCMP=openspin$(EXT)

$(warning OS $(OS) detected.)

export PREFIX
export BUILD
export OS
export SPINCMP
export PATH:=$(PREFIX)/bin:$(PATH)

#
# note that the propgcc version string does not deal well with
# spaces due to how it is used below
#
VERSION=$(shell cat release/VERSION.txt | grep -v '^\#')
# better revision command. thanks yeti.
#HGVERSION=$(shell hg tip --template '{rev}\n')
GITVERSION=$(shell git describe --tags --long 2>/dev/null)

PROPGCC_VERSION=$(VERSION)_$(GITVERSION)

$(warning PropGCC version is $(PROPGCC_VERSION).)
export PROPGCC_VERSION

BUGURL?=http://code.google.com/p/propgcc/issues
$(warning BugURL is $(BUGURL).)
export BUGURL

#
# configure options for propgcc
#
CONFIG_OPTIONS=--with-pkgversion=$(PROPGCC_VERSION) --with-bugurl=$(BUGURL) $(CFGCROSS)

.PHONY:	all

#all:	binutils gcc lib-cog libgcc lib lib-tiny openspin spin2cpp loader gdb gdbstub spinsim libstdc++
all:	binutils gcc lib-cog libgcc lib lib-tiny openspin spin2cpp loader spinsim
	@$(ECHO) Build complete.

.NOTPARALLEL:

########
# HELP #
########

.PHONY:	help
help:
	@$(ECHO)
	@$(ECHO) 'Targets:'
	@$(ECHO) '  all - build all targets (default)'
	@$(ECHO) '  binutils - build binutils'	
	@$(ECHO) '  gcc - build gcc'	
#	@$(ECHO) '  libstdc++ - build the C++ library'	
	@$(ECHO) '  libgcc - build libgcc'	
#	@$(ECHO) '  gdb - build gdb'	
#	@$(ECHO) '  gdbstub - build gdbstub'	
	@$(ECHO) '  lib - build the library'	
	@$(ECHO) '  lib-cog - build the cog library'	
	@$(ECHO) '  lib-tiny - build libtiny'	
	@$(ECHO) '  openspin - build openspin'
	@$(ECHO) '  spin2cpp - build spin2cpp'	
	@$(ECHO) '  spinsim - build spinsim'	
	@$(ECHO) '  loader - build the loader'
	@$(ECHO) '  install - install generated files to' $(INSTALL)	
	@$(ECHO)
	@$(ECHO) 'Cleaning targets:'
	@$(ECHO) '  clean - remove the' $(BUILD) 'directory'
	@$(ECHO) '  clean-all - remove the' $(BUILD) 'and' $(INSTALL) 'directories'
	@$(ECHO) '  clean-binutils - prepare for a fresh rebuild of binutils'	
	@$(ECHO) '  clean-gcc - prepare for a fresh rebuild of gcc, libgcc, libstdc++'	
#	@$(ECHO) '  clean-gdb - prepare for a fresh rebuild of gdb'
#	@$(ECHO) '  clean-gdbstub - prepare for a fresh rebuild of gdbstub'	
	@$(ECHO) '  clean-lib - prepare for a fresh rebuild of lib, lib-cog, lib-tiny'	
	@$(ECHO) '  clean-openspin - prepare for a fresh rebuild of openspin'
	@$(ECHO) '  clean-spin2cpp - prepare for a fresh rebuild of spin2cpp'	
	@$(ECHO) '  clean-spinsim prepare for a fresh rebuild of spinsim'	
	@$(ECHO)

############
# BINUTILS #
############

.PHONY:	binutils
binutils:	$(BUILD)/binutils/binutils-built

$(BUILD)/binutils/binutils-built:	$(BUILD)/binutils/binutils-configured
	@$(ECHO) Building binutils
	@$(MAKE) -C $(BUILD)/binutils all
	@$(ECHO) Installing binutils
	@$(MAKE) -C $(BUILD)/binutils install
	@$(TOUCH) $@

$(BUILD)/binutils/binutils-configured:	$(BUILD)/binutils/binutils-created
	@$(ECHO) Configuring binutils
	@$(CD) $(BUILD)/binutils; $(ROOT)/binutils/configure --target=propeller-elf --prefix=$(PREFIX) --disable-nls --disable-shared $(CONFIG_OPTIONS)
	@$(TOUCH) $@

#######
# GCC #
#######

.PHONY:	gcc
gcc:	binutils $(BUILD)/gcc/gcc-built

$(BUILD)/gcc/gcc-built:	$(BUILD)/gcc/gcc-configured
	@$(ECHO) Building gcc
	@$(MAKE) -C $(BUILD)/gcc all-gcc
	@$(ECHO) Installing gcc
	@$(MAKE) -C $(BUILD)/gcc install-gcc
	@$(TOUCH) $@

$(BUILD)/gcc/gcc-configured:	$(BUILD)/gcc/gcc-created
	@$(ECHO) Configuring gcc
	@$(CD) $(BUILD)/gcc; $(ROOT)/$(GCCDIR)/configure --target=propeller-elf --prefix=$(PREFIX) --disable-nls --disable-shared $(CONFIG_OPTIONS)
	@$(TOUCH) $@

#############
# LIBSTDC++ #
#############

.PHONY:	libstdc++
libstdc++:	lib $(BUILD)/gcc/libstdc++-built

$(BUILD)/gcc/libstdc++-built:	$(BUILD)/gcc/gcc-built
	@$(ECHO) Building libstdc++
	@$(MAKE) -C $(BUILD)/gcc all
	@$(ECHO) Installing libstdc++
	@$(MAKE) -C $(BUILD)/gcc install
	@$(TOUCH) $@

##########
# LIBGCC #
##########

.PHONY:	libgcc
libgcc:	binutils gcc $(BUILD)/gcc/libgcc-built

$(BUILD)/gcc/libgcc-built: $(BUILD)/gcc/gcc-built
	@$(ECHO) Building libgcc
	@$(MAKE) -C $(BUILD)/gcc all-target-libgcc
	@$(ECHO) Installing gcc
	@$(MAKE) -C $(BUILD)/gcc install-target-libgcc
	@$(TOUCH) $@

#######
# GDB #
#######

.PHONY:	gdb
gdb:	lib $(CURSES) $(BUILD)/gdb/gdb-built

$(BUILD)/gdb/gdb-built:	binutils gcc $(BUILD)/gdb/gdb-configured
	@$(ECHO) Building gdb
	@$(MAKE) -C $(BUILD)/gdb all
	@$(ECHO) Installing gdb
	@$(CP) -f $(BUILD)/gdb/gdb/gdb$(EXT) $(PREFIX)/bin/propeller-elf-gdb$(EXT)
	@$(TOUCH) $@

$(BUILD)/gdb/gdb-configured:	$(BUILD)/gdb/gdb-created
	@$(ECHO) Configuring gdb
	@$(CD) $(BUILD)/gdb; $(ROOT)/gdb/configure $(CFGCROSS) --target=propeller-elf --prefix=$(PREFIX) --with-system-gdbinit=$(PREFIX)/lib/gdb/gdbinit $(WITH_CURSES)
	@$(TOUCH) $@

###########
# NCURSES #
###########
# this is used for ncurses cross compilation only
.PHONY: ncurses
ncurses: $(BUILD)/ncurses/ncurses-built

$(BUILD)/ncurses/ncurses-built: $(BUILD)/ncurses/ncurses-configured
	@$(ECHO) Building ncurses
	@$(MAKE) -C $(BUILD)/ncurses all
	@$(MAKE) -C $(BUILD)/ncurses install
	@$(TOUCH) $@

$(BUILD)/ncurses/ncurses-configured: $(BUILD)/ncurses/ncurses-created
	@$(ECHO) Configuring ncurses
	@$(CD) $(BUILD)/ncurses; $(ROOT)/ncurses/configure --host=$(CROSS_TARGET) --prefix=$(CURSES_PREFIX)
	@$(TOUCH) $@

###########
# GDBSTUB #
###########

.PHONY:	gdbstub
gdbstub:	lib gdb $(BUILD)/gdbstub/gdbstub-built

$(BUILD)/gdbstub/gdbstub-built:	$(BUILD)/gdbstub/gdbstub-created
	@$(ECHO) Building gdbstub
	@$(MAKE) -C gdbstub BUILDROOT=$(BUILD)/gdbstub CC=$(CROSSCC)
	@$(ECHO) Installing gdbstub
	@$(CP) -f $(BUILD)/gdbstub/gdbstub$(EXT) $(PREFIX)/bin/
	@$(MKDIR) -p $(PREFIX)/lib/gdb
	@$(CP) -f gdbstub/gdbinit.propeller $(PREFIX)/lib/gdb/gdbinit
	@$(TOUCH) $@

#######
# LIB #
#######

.PHONY:	lib
lib:	libgcc $(BUILD)/lib/lib-built

$(BUILD)/lib/lib-built:	$(BUILD)/lib/lib-created
	@$(ECHO) Building library
	@$(MAKE) -C lib
	@$(ECHO) Installing library
	@$(MAKE) -C lib install
	@$(TOUCH) $@

###############
# COG LIBRARY #
###############

.PHONY:	lib-cog
lib-cog:	libgcc $(BUILD)/lib/lib-cog-built

$(BUILD)/lib/lib-cog-built:  $(BUILD)/lib/lib-created
	@$(ECHO) Building cog library
	@$(MAKE) -C lib cog
	@$(TOUCH) $@

###########
# LIBTINY #
###########

.PHONY:	lib-tiny
lib-tiny:	libgcc $(BUILD)/lib/lib-tiny-built

$(BUILD)/lib/lib-tiny-built:	$(BUILD)/lib/lib-created
	@$(ECHO) Building tiny library
	@$(MAKE) -C lib tiny
	@$(ECHO) Installing tiny library
	@$(MAKE) -C lib install-tiny
	@$(TOUCH) $@

############
# OPENSPIN #
############

.PHONY:	openspin
openspin:
	@$(ECHO) Building openspin
	@$(MAKE) -C openspin CC=$(CROSSCC)
	@$(ECHO) Installing openspin
	@$(CP) openspin/openspin$(EXT) $(PREFIX)/bin

.PHONY:	clean-openspin
clean-openspin:
	@$(RM) -rf $(BUILD)/openspin
	@$(MAKE) -C openspin clean

############
# SPIN2CPP #
############

.PHONY:	spin2cpp
spin2cpp:
	@$(ECHO) Building spin2cpp
	@$(MAKE) -C spin2cpp CC=$(CROSSCC) TARGET=$(PREFIX) BUILDROOT=$(BUILD)/spin2cpp
	@$(ECHO) Installing spin2cpp
	@$(CP) spin2cpp/spin2cpp$(EXT) $(PREFIX)/bin

.PHONY:	clean-spin2cpp
clean-spin2cpp:
	@$(RM) -rf $(BUILD)/spin2cpp
	@$(MAKE) -C spin2cpp clean

###########
# SPINSIM #
###########

.PHONY:	spinsim
spinsim:	$(BUILD)/spinsim/spinsim-built

$(BUILD)/spinsim/spinsim-built:	$(BUILD)/spinsim/spinsim-created
	@$(ECHO) Building spinsim
	@$(MAKE) -C spinsim CC=$(CROSSCC) OS=$(OS) BUILD=$(BUILD)/spinsim EXT=$(EXT)
	@$(CP) -f spinsim/spinsim$(EXT) $(PREFIX)/bin/
	@$(TOUCH) $@

.PHONY:	clean-spinsim
clean-spinsim:
	@$(RM) -rf $(BUILD)/spinsim
	@$(MAKE) -C spinsim clean

##########
# LOADER #
##########

.PHONY:	loader
loader:	lib $(BUILD)/loader/loader-built

$(BUILD)/loader/loader-built:	$(BUILD)/loader/loader-created
	@$(ECHO) Building propeller-load
	@$(MAKE) -C loader TARGET=$(PREFIX) BUILDROOT=$(BUILD)/loader TOOLCC=$(CROSSCC)
	@$(ECHO) Installing propeller-load
	@$(MAKE) -C loader TARGET=$(PREFIX) BUILDROOT=$(BUILD)/loader TOOLCC=$(CROSSCC) install
	@$(TOUCH) $@

###########
# INSTALL #
###########

.PHONY:	install
install:
	@$(ECHO) Installing to $(INSTALL)
	@$(RM) -rf $(INSTALL)
	@$(CP) -r $(PREFIX) $(INSTALL)

#########
# CLEAN #
#########

.PHONY:	clean
#clean:	clean-gdbstub clean-lib clean-loader clean-spin2cpp clean-spinsim
clean:	clean-lib clean-loader
	@$(ECHO) Removing $(BUILD)
	@$(RM) -rf $(BUILD)

#############
# CLEAN-ALL #
#############

.PHONY:	clean-all
clean-all:	clean
	@$(ECHO) Removing $(INSTALL)
	@$(RM) -rf $(INSTALL)

#####################
# INDIVIDUAL CLEANS #
#####################

.PHONY:	clean-binutils
clean-binutils:
	@$(RM) -rf $(BUILD)/binutils

.PHONY:	clean-gcc
clean-gcc:
	@$(RM) -rf $(BUILD)/gcc

.PHONY:	clean-gdb
clean-gdb:
	@$(RM) -rf $(BUILD)/gdb

.PHONY:	clean-gdbstub
clean-gdbstub:
	@$(RM) -rf $(BUILD)/gdbstub
	@$(MAKE) -C gdbstub clean

.PHONY:	clean-lib
clean-lib:
	@$(RM) -rf $(BUILD)/lib
	@$(MAKE) -C lib clean

.PHONY:	clean-loader
clean-loader:
	@$(RM) -rf $(BUILD)/loader
	@$(MAKE) -C loader clean

# create a directory

%-created:
	@$(MKDIR) -p $(@D)
	@$(TOUCH) $@

