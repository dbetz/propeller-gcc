# Put this Makefile in "propsideworkspace/Learn/Simple Libraries" and type:
#
# "make" to build the CMM, LMM, and XMMC libraries.
# "make lmm" to build the LMM libraries.
# "make cmm" to build the CMM libraries.
# "make xmmc" to build the XMMC libraries.
#
# "make clean" to clean the CMM, LMM, and XMM libraries.
# "make clean-lmm" to clean the LMM library.
# "make clean-cmm" to clean the CMM library.
# "make clean-xmmc" to clean the XMMC library.
#
# Libraries are written to the 'lib' directory and all header files are copied to
# the 'include' directory.

CC=propeller-elf-gcc
SPINC=openspin -q
AR=propeller-elf-ar
OBJCOPY=propeller-elf-objcopy
ECHO=echo
MKDIR=mkdir -p
CD=cd
CP=cp
RM=rm -f
RMDIR=rm -rf

MMODEL=cmm

HDRDIR=include
OBJDIR=obj-$(MMODEL)
LIBDIR=lib

SIDE_FILES=$(wildcard */*/*.side) $(wildcard */*/*/*.side)

INC=$(foreach side,$(SIDE_FILES),-I $(dir $(side)))

HDRS=$(foreach side,$(SIDE_FILES),$(wildcard $(dir $(side))*.h))

CFILES=$(foreach side,$(SIDE_FILES),$(foreach file,$(filter-out lib%,$(filter %.c,$(shell cat $(side)))),$(dir $(side))$(file)))

COGCFILES=$(foreach side,$(SIDE_FILES),$(foreach file,$(filter %.cogc,$(shell cat $(side))),$(dir $(side))$(file)))

SPINFILES=$(foreach side,$(SIDE_FILES),$(foreach file,$(filter %.spin,$(shell cat $(side))),$(dir $(side))$(file)))

CFLAGS=-m$(MMODEL) -Os $(INC) -m32bit-doubles -fno-exceptions -std=c99

COGCFLAGS=-mcog -xc -Os $(INC) -m32bit-doubles

all:	includes lmm cmm xmmc

clean:	clean-includes clean-lmm clean-cmm clean-xmmc
	@$(RMDIR) $(LIBDIR)

includes:	$(HDRDIR)
	@$(CP) $(HDRS) $(HDRDIR)

clean-includes:
	@$(RMDIR) $(HDRDIR)

lmm:
	$(MAKE) MMODEL=lmm model
	
clean-lmm:
	$(MAKE) MMODEL=lmm clean-model
	
cmm:
	$(MAKE) MMODEL=cmm model
	
clean-cmm:
	$(MAKE) MMODEL=cmm clean-model
	
xmmc:
	$(MAKE) MMODEL=xmmc model

clean-xmmc:
	$(MAKE) MMODEL=xmmc clean-model

model:	$(HDRDIR) $(OBJDIR) $(LIBDIR) includes $(LIBDIR)/libsimple-$(MMODEL).a

clean-model:
	@$(RMDIR) $(OBJDIR) $(LIBDIR)/*.a

OBJS=$(foreach file,$(CFILES),$(OBJDIR)/$(notdir $(patsubst %.c,%.o,$(file))))
OBJS+=$(foreach file,$(COGCFILES),$(OBJDIR)/$(notdir $(patsubst %.cogc,%.cogc.o,$(file))))
OBJS+=$(foreach file,$(SPINFILES),$(OBJDIR)/$(notdir $(patsubst %.spin,%.o,$(file))))

$(LIBDIR)/libsimple-$(MMODEL).a:	$(OBJS)
	@$(ECHO) AR $@
	@$(AR) rs $@ $(OBJS)

define compile-objects

$(OBJDIR)/%.o:	$1%.c
	@$(ECHO) C $$<
	@$(CC) $(CFLAGS) -c -o $$@ $$<

# this rule is a hack to handle one case where a SimpleIDE project puts its files in a subdirectory
$(OBJDIR)/%.o:	$1source/%.c
	@$(ECHO) C $$<
	@$(CC) $(CFLAGS) -c -o $$@ $$<

$(OBJDIR)/%.cogc.o:	$1%.cogc
	@$(ECHO) COGC $$<
	@$(CC) $(COGCFLAGS) -c -o $$@ $$<

$(OBJDIR)/%.dat:	$1%.spin
	@$(ECHO) SPIN $$<
	@$(SPINC) -c -o $$@ $$<

endef

$(foreach side,$(SIDE_FILES),$(eval $(call compile-objects,$(dir $(side)))))

$(OBJDIR)/%.o:	$(OBJDIR)/%.dat
	@$(CD) $(dir $<); $(OBJCOPY) -I binary -B propeller -O propeller-elf-gcc --redefine-sym _binary_$(MMODEL)_$(basename $<)_dat_start=_binary_$(basename $<)_dat_start --redefine-sym _binary_$(MMODEL)_$(basename $<)_dat_end=_binary_$(basename $<)_dat_end $(notdir $<) $(notdir $@)

$(HDRDIR) $(OBJDIR) $(LIBDIR):
	$(MKDIR) $@
