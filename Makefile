# This project is designed to be built for Nintendo 3DS. In order to compile it,
# devkitPro and several dependencies need to be installed and available on the $PATH.
# See the 3DBrew wiki for instructions: <https://3dbrew.org/wiki/Setting_up_Development_Environment>
# The devkitPro website: <https://devkitpro.org/>
#
# Metadata such as title and description is loaded from 'project.cfg'.
#
# © 2019, MIT license

ifndef DEVKITPRO
  $(error This project requires devkitPro to build, but no $$DEVKITPRO environment variable was found. See <https://devkitpro.org/> for installation instructions)
endif
ifndef DEVKITARM
  $(error Please set the $$DEVKITARM environment variable)
endif

include $(DEVKITARM)/3ds_rules

# Retrieves values from the project.cfg file and trims whitespace.
define proj_metadata
$(shell grep \^$(1)\\s\= < project.cfg | cut -d'=' -f2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$\//')
endef

# Information about the application, to be included in the SMDH/CIA files.
APP_TITLE  := $(call proj_metadata,title)
APP_DESC   := $(call proj_metadata,description)
APP_CODE   := $(shell echo $(call proj_metadata,code) | tr [:lower:] [:upper:])
APP_COPY   := $(call proj_metadata,copyright)
APP_RELEASE:= $(call proj_metadata,release)
APP_HOME   := $(call proj_metadata,homepage)
APP_REPO   := $(call proj_metadata,repository)
APP_LICENSE:= $(call proj_metadata,license)
APP_AUTHOR := $(call proj_metadata,author)
APP_VERSION:= $(call proj_metadata,version)
CIA_ID     := $(shell echo $(call proj_metadata,cia_id) | tr [:lower:] [:upper:])
CIA_AUDIO  := $(call proj_metadata,cia_audio)
CIA_BANNER := $(call proj_metadata,cia_banner)
CIA_ICON   := $(call proj_metadata,cia_icon)

# Some information from Git that we'll use for the build info indicator file.
HASH        = $(shell git rev-parse --short HEAD)
BRANCH      = $(shell git describe --all | sed s@heads/@@)
COUNT       = $(shell git rev-list HEAD --count)
DATE        = $(shell date +"%Y-%m-%d")
DATETIME    = $(shell date +"%Y-%m-%d %T")
UNIXTIME    = $(shell date +"%s")
BUILDTIME   = $(shell date +"%Y-%m-%dT%T%z")
OSINFO      = $(shell uname -v)
REPO_VERSION= $(COUNT)-$(BRANCH)
REPO_LONG_VERSION= $(COUNT)-$(BRANCH) [$(HASH); $(DATE)]

# The current, main project directory
TOPDIR     ?= $(CURDIR)
# Name of the output files (.3dsx, etc.)
FILENAME   := $(notdir $(CURDIR))
# Object files and intermediate files
TMP        := tmp
# Directory to which the final build files will be saved
TARGET     := target
# List of directories containing source code
SOURCES    := source
# List of directories containing data files
DATA       := data
# List of directories including header files
INCLUDES   := include
# List of directories containing graphics files
GRAPHICS   := gfx
# Directory containing deps
DEPS       := $(TMP)
# Converted graphics files output directory;
# If set to $(TMP), the converted files will be statically linked as if they were data files.
# Consider setting this to $(ROMFS)/gfx when using a RomFS.
GFXTMP     := $(TMP)
# Directory containing the RomFS (optional)
ROMFS      := romfs
# Command to use to run Citra for testing purposes
CITRA_BIN  := citra
# Spec file to use when creating a CIA
SPEC_RSF   := assets/spec.rsf
# Name of the files that will contain the build time version information (.c, .h)
VERSION_FN := buildinfo

# Code generation options
ARCH       := -march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft
CFLAGS     := -g -Wall -O2 -mword-relocations -fomit-frame-pointer -ffunction-sections $(ARCH)
CFLAGS     += -DARM11 -D_3DS
CXXFLAGS   := $(CFLAGS) -fno-rtti -fno-exceptions -std=gnu++11
ASFLAGS    := -g $(ARCH)
LDFLAGS     = -specs=3dsx.specs -g $(ARCH) -Wl,-Map,$(TMP)/$(notdir $*).map
LIBS       := -lctru -lm

# Define names and descriptions used in generating 'buildinfo.c'. See readme for an overview.
VVARS      := HASH BRANCH COUNT DATE DATETIME UNIXTIME BUILDTIME OSINFO VERSION REPO_VERSION REPO_LONG_VERSION CFLAGS
VEXPL      := Returns_the_build_commit_hash. Returns_the_build_commit_branch. Returns_the_number_of_commits_preceding_this_build_commit. Returns_the_build_date. Returns_the_build_date_and_time. Returns_a_Unix_time_number_of_the_build_date_(as_a_string). Returns_an_ISO_8601_timestamp_with_timezone_of_the_build_date. Returns_OS\/kernel_info_string_during_build_time. Returns_the_version_number_set_in_project.cfg. Returns_a_formatted_short_version_string. Returns_a_formatted_full_version_string. Returns_the_CFLAGS_variables_used_to_compile_the_code.
VDEF        = -DHASH="\"$(subst ",\\",$(HASH))\"" -DBRANCH="\"$(subst ",\\",$(BRANCH))\"" -DCOUNT="\"$(subst ",\\",$(COUNT))\"" -DDATE="\"$(subst ",\\",$(DATE))\"" -DDATETIME="\"$(subst ",\\",$(DATETIME))\"" -DUNIXTIME="\"$(subst ",\\",$(UNIXTIME))\"" -DBUILDTIME="\"$(subst ",\\",$(BUILDTIME))\"" -DOSINFO="\"$(subst ",\\",$(OSINFO))\"" -DVERSION="\"$(subst ",\\",$(VERSION))\"" -DREPO_VERSION="\"$(subst ",\\",$(REPO_VERSION))\"" -DREPO_LONG_VERSION="\"$(subst ",\\",$(REPO_LONG_VERSION))\"" -DCFLAGS="\"$(subst ",\\",$(CFLAGS))\""
VVARS_L     = $(shell seq 0 1 $$(($(words $(VVARS)) - 1)))

# List of directories containing libraries (must be top level, containing 'include' and 'lib')
LIBDIRS    := $(CTRULIB)

#---------------------------------------------------------------------------------

# Several final checks to ensure we can begin:

ifeq ($(CIA_ID),)
  $(error No CIA ID has been set in project.cfg)
endif

ifeq ($(CIA_ID),000000)
  $(error CIA ID must not be '000000')
endif

ifeq ($(shell echo $(CIA_ID) | grep "[0-9A-Fa-f]\{6\}"),)
  $(error CIA ID must be 6 hexadecimal characters in either lowercase or uppercase (given: '$(CIA_ID)'))
endif

ifeq ($(APP_CODE),)
  $(error No app code has been set in project.cfg)
endif

ifeq ($(CIA_AUDIO),)
  $(error No audio file has been set in project.cfg)
endif

ifeq ($(CIA_BANNER),)
  $(error No banner image file has been set in project.cfg)
endif

ifeq ($(CIA_ICON),)
  $(error No icon file has been set in project.cfg)
endif

ifeq ($(shell which tex3ds),)
  $(error No tex3ds binary found on the $$PATH - cannot convert 3DS textures)
endif

ifeq ($(TMP),)
  $(error A $$TMP directory must be set)
endif

ifeq ($(if $(filter "","$(wildcard $(CURDIR)/$(CIA_ICON))"),0,1),0)
  $(error Could not find the icon file ($(CIA_ICON)))
endif

ifeq ($(if $(filter "","$(wildcard $(CURDIR)/$(CIA_AUDIO))"),0,1),0)
  $(error Could not find the audio file ($(CIA_AUDIO)))
endif

ifeq ($(if $(filter "","$(wildcard $(CURDIR)/$(CIA_BANNER))"),0,1),0)
  $(error Could not find the banner image file ($(CIA_BANNER)))
endif

OUTPUT     := $(CURDIR)/$(TARGET)/$(FILENAME)
DEPSDIR    := $(CURDIR)/$(DEPS)
VPATH      := $(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
              $(foreach dir,$(GRAPHICS),$(CURDIR)/$(dir)) \
              $(foreach dir,$(DATA),$(CURDIR)/$(dir))
CFILES     := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES   := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES     := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
PICAFILES  := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.v.pica)))
SHLISTFILES:= $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.shlist)))
GFXFILES   := $(foreach dir,$(GRAPHICS),$(notdir $(wildcard $(dir)/*.t3s)))
BINFILES   := $(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

# Set the linker to either CC or CXX, depending on whether there are C++ files.
IS_CPP     := $(if $(strip $(CPPFILES)),1,)
LD         := $(if $(filter 1,$(IS_CPP)),$(CXX),$(CC))

# If GFXTMP is the same as TMP, converted graphics files will be statically linked.
ifeq ($(GFXTMP),$(TMP))
  T3XFILES := $(GFXFILES:.t3s=.t3x)
else
  ROMFS_T3XFILES := $(patsubst %.t3s, $(GFXTMP)/%.t3x, $(GFXFILES))
  T3XHFILES := $(patsubst %.t3s, $(TMP)/%.h, $(GFXFILES))
endif

# All object and header files.
OBJS_SRC   := $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)
OBJS_BIN   := $(addsuffix .o,$(BINFILES)) \
              $(PICAFILES:.v.pica=.shbin.o) $(SHLISTFILES:.shlist=.shbin.o) \
              $(addsuffix .o,$(T3XFILES))
OBJS       := $(addprefix $(TMP)/,$(OBJS_BIN)) $(addprefix $(TMP)/,$(OBJS_SRC))
HFILES     := $(PICAFILES:.v.pica=_shbin.h) $(SHLISTFILES:.shlist=_shbin.h) \
              $(addsuffix .h,$(subst .,_,$(BINFILES))) \
              $(GFXFILES:.t3s=.h)

# Project includes and external includes.
INCLUDE    := $(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
              $(foreach dir,$(LIBDIRS),-I$(dir)/include) \
              -I$(CURDIR)/$(TMP)
LIBPATHS   := $(foreach dir,$(LIBDIRS),-L$(dir)/lib)
CFLAGS     += $(INCLUDE)
CXXFLAGS   += $(INCLUDE)
VFILE_TPL_C:= $(CURDIR)/assets/version_tpl.c
VFILE_TPL_H:= $(CURDIR)/assets/version_tpl.h
FN_TPL_C   := $(CURDIR)/$(TMP)/fn_tpl.c
FN_TPL_H   := $(CURDIR)/$(TMP)/fn_tpl.h

# Targets
_3DSXDEPS  := $(if $(NO_SMDH),,$(OUTPUT).smdh)
CIA_ICON   := $(CURDIR)/$(CIA_ICON)
VFILE_C    := $(CURDIR)/$(SOURCES)/$(VERSION_FN).c
VFILE_H    := $(VFILE_C:.c=.h)
VFILE_O    := $(VFILE_C:.c=.o)
ROMFS_ARG  :=
ROMFS_BIN  :=

# If the user wants to generate an SMDH.
ifeq ($(strip $(NO_SMDH)),)
  _3DSXFLAGS += --smdh=$(TARGET)/$(FILENAME).smdh
endif

# If a RomFS directory is specified.
ifneq ($(ROMFS),)
  _3DSXFLAGS += --romfs=$(CURDIR)/$(ROMFS)
	ROMFS_ARG += -romfs $(TMP)/romfs.bin
endif

.SUFFIXES:
.PHONY: all clean test
.PRECIOUS: %.t3x

default: all

TMPDIRS := $(TMP)

$(TMP):
	mkdir -p $@

$(TARGET):
	mkdir -p $@

ifneq ($(GFXTMP),$(TMP))
TMPDIRS += $(GFXTMP)
$(GFXTMP):
	mkdir -p $@
endif

ifneq ($(DEPS),$(TMP))
TMPDIRS += $(DEPS)
$(DEPSDIR):
	mkdir -p $@
endif

all: $(TMP) $(TARGET) $(GFXTMP) $(DEPSDIR) $(ROMFS_T3XFILES) $(T3XHFILES) $(VFILE_O) $(OUTPUT).3dsx $(OUTPUT).cia

test: all
	$(CITRA_BIN) $(TARGET)/$(FILENAME).3dsx

clean:
	rm -rf $(TMPDIRS)
	rm -rf $(TARGET)
	rm -f $(VFILE_C) $(VFILE_H) $(VFILE_O)

$(GFXTMP)/%.t3x	$(TMP)/%.h: $(TMP) %.t3s
	tex3ds -i $< -H $(TMP)/$*.h -d $(DEPSDIR)/$*.d -o $(GFXTMP)/$*.t3x

$(OUTPUT).3dsx: $(OBJS) $(OUTPUT).elf $(_3DSXDEPS)

ifneq ($(ROMFS),)
ROMFS_BIN := $(TMP)/romfs.bin
$(TMP)/romfs.bin:
	3dstool -cvtf romfs $(TMP)/romfs.bin --romfs-dir $(ROMFS)
endif

$(FN_TPL_C): $(TMP)
	awk 'BEGIN { p = 0; }; /^\{\{\/--\}\}/ { exit(0) }; p != 0 { print; }; /^\{\{--\}\}/ { p = 1; };' $(VFILE_TPL_C) > $@

$(FN_TPL_H): $(TMP)
	awk 'BEGIN { p = 0; }; /^\{\{\/--\}\}/ { exit(0) }; p != 0 { print; }; /^\{\{--\}\}/ { p = 1; };' $(VFILE_TPL_H) > $@

$(VFILE_C): $(FN_TPL_C)
	touch $@
	cat $(VFILE_TPL_C) | awk '/^\{\{--\}\}/ { exit(0) }; 1;' > $@
	cvars=($(VVARS)); cexpl=($(subst _, ,$(addprefix ",$(addsuffix ",$(VEXPL))))); for n in $(VVARS_L); do lc=$$(echo $${cvars[$$n]} | tr '[:upper:]' '[:lower:]'); cat $(FN_TPL_C) | sed "s/{{1}}/$${cexpl[$$n]}/" | sed "s/{{2}}/$$lc/" | sed "s/{{3}}/$${cvars[$$n]}/" >> $@; echo >> $@; done

$(VFILE_H): $(FN_TPL_H)
	touch $@
	cat $(VFILE_TPL_H) | awk '/^\{\{--\}\}/ { exit(0) }; 1;' > $@
	cvars=($(VVARS)); cexpl=($(subst _, ,$(addprefix ",$(addsuffix ",$(VEXPL))))); for n in $(VVARS_L); do lc=$$(echo $${cvars[$$n]} | tr '[:upper:]' '[:lower:]'); cat $(FN_TPL_H) | sed "s/{{1}}/$${cexpl[$$n]}/" | sed "s/{{2}}/$$lc/" | sed "s/{{3}}/$${cvars[$$n]}/" >> $@; done
	awk 'BEGIN { p = 0; }; p != 0 { print; }; /^\{\{\/--\}\}/ { p = 1 };' $(VFILE_TPL_H) >> $@

$(VFILE_O): $(VFILE_C) $(VFILE_H)
	$(COMPILE.c) $(OUTPUT_OPTION) $(VDEF) $<

$(OUTPUT).cia: $(TMP)/banner.bin $(TMP)/icon.bin $(TMP)/spec.rsf $(ROMFS_BIN)
	makerom -f cia -o "$(OUTPUT).cia" -elf "$(OUTPUT).elf" -rsf "$(TMP)/spec.rsf" -icon "$(TMP)/icon.bin" -banner $(TMP)/banner.bin -exefslogo -target t $(ROMFS_ARG)

$(TMP)/spec.rsf:
	cat $(SPEC_RSF) | sed -e "s/{{CIA_ID}}/$(CIA_ID)/; s/{{APP_CODE}}/$(APP_CODE)/; s/{{APP_TITLE}}/$(APP_TITLE)/" > $@

$(TMP)/banner.bin:
	bannertool makebanner -i $(TOPDIR)/$(CIA_BANNER) -a $(TOPDIR)/$(CIA_AUDIO) -o $@

$(TMP)/icon.bin:
	bannertool makesmdh -s "$(APP_TITLE)" -l "$(APP_TITLE)" -p "$(APP_AUTHOR)" -i "$(CIA_ICON)" -o $@

$(OBJS): $(VFILE_C) $(VFILE_H) $(HFILES)

$(OUTPUT).elf: $(OBJS)

$(TMP)/%.o: %.c
	$(COMPILE.c) $(OUTPUT_OPTION) $<

%.smdh: $(APP_ICON) $(MAKEFILE_LIST)
	smdhtool --create "$(APP_TITLE)" "$(APP_DESC)" "$(APP_AUTHOR)" "$(APP_ICON)" $@

%.3dsx: %.elf
	3dsxtool $< $@ $(_3DSXFLAGS)

%.elf:
	$(LD) $(LDFLAGS) $(OBJS) $(LIBPATHS) $(LIBS) -o $@
	$(NM) -CSn $@ > $(TMP)/$(notdir $*).lst

%.bin.o	%_bin.h: %.bin
	echo $(notdir $<)
	$(bin2o)

%.t3x.o	%_t3x.h: %.t3x
	echo $(notdir $<)
	$(bin2o)

# Rules for assembling GPU shaders.
define shader-as
	$(eval CURBIN := $*.shbin)
	$(eval DEPSFILE := $(DEPSDIR)/$*.shbin.d)
	echo "$(CURBIN).o: $< $1" > $(DEPSFILE)
	echo "extern const u8" `(echo $(CURBIN) | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`"_end[];" > `(echo $(CURBIN) | tr . _)`.h
	echo "extern const u8" `(echo $(CURBIN) | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`"[];" >> `(echo $(CURBIN) | tr . _)`.h
	echo "extern const u32" `(echo $(CURBIN) | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`_size";" >> `(echo $(CURBIN) | tr . _)`.h
	picasso -o $(CURBIN) $1
	bin2s $(CURBIN) | $(AS) -o $*.shbin.o
endef

%.shbin.o %_shbin.h: %.v.pica %.g.pica
	echo $(notdir $^)
	$(call shader-as,$^)

%.shbin.o %_shbin.h: %.v.pica
	echo $(notdir $<)
	$(call shader-as,$<)

%.shbin.o %_shbin.h: %.shlist
	echo $(notdir $<)
	$(call shader-as,$(foreach file,$(shell cat $<),$(dir $<)$(file)))

%.t3x	%.h: %.t3s
	echo $(notdir $<)
	tex3ds -i $< -H $*.h -d $*.d -o $*.t3x

-include $(DEPSDIR)/*.d
