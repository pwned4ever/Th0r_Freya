# This Makefile snippet defines the following variables for host tools:
#
# AS: assembler
# CPP: C preprocessor
# CC: C compiler
# CXX: C++ compiler
# OBJC: Objective C compiler
# OBJCXX: Objective C++ compiler
# GCJ: GNU Java compiler
# F77: Fortran 77 compiler
# FC: Fortran 9x compiler
# LD: linker
# STRIP: strip objects
# OBJCOPY: copy objects
# OBJDUMP: dump objects
# NM: names lister
# AR: archiver
# RANLIB: archive index generator
# PKG_CONFIG: pkg-config tool
#
# All the above variables have a counterpart variable for the build tool,
# as in CC → CC_FOR_BUILD.
#
# The variables are not exported by default. This can be changed by
# defining DPKG_EXPORT_BUILDTOOLS.

dpkg_datadir = /usr/share/dpkg
include $(dpkg_datadir)/architecture.mk

# We set the TOOL_FOR_BUILD variables to the specified value, and the TOOL
# variables (for the host) to the their triplet-prefixed form iff they are
# not defined or contain the make built-in defaults. On native builds if
# TOOL is defined and TOOL_FOR_BUILD is not, we fallback to use TOOL.
define dpkg_buildtool_setvar
ifeq ($(origin $(1)),default)
$(1) = $(DEB_HOST_GNU_TYPE)-$(2)
endif
$(1) ?= $(DEB_HOST_GNU_TYPE)-$(2)

# On native build fallback to use TOOL if that's defined.
ifeq ($(DEB_BUILD_GNU_TYPE),$(DEB_HOST_GNU_TYPE))
ifdef $(1)
$(1)_FOR_BUILD ?= $$($(1))
endif
endif
$(1)_FOR_BUILD ?= $(DEB_BUILD_GNU_TYPE)-$(2)

ifdef DPKG_EXPORT_BUILDTOOLS
export $(1)
export $(1)_FOR_BUILD
endif
endef

$(eval $(call dpkg_buildtool_setvar,AS,as))
$(eval $(call dpkg_buildtool_setvar,CPP,gcc -E))
$(eval $(call dpkg_buildtool_setvar,CC,gcc))
$(eval $(call dpkg_buildtool_setvar,CXX,g++))
$(eval $(call dpkg_buildtool_setvar,OBJC,gcc))
$(eval $(call dpkg_buildtool_setvar,OBJCXX,g++))
$(eval $(call dpkg_buildtool_setvar,GCJ,gcj))
$(eval $(call dpkg_buildtool_setvar,F77,f77))
$(eval $(call dpkg_buildtool_setvar,FC,f77))
$(eval $(call dpkg_buildtool_setvar,LD,ld))
$(eval $(call dpkg_buildtool_setvar,STRIP,strip))
$(eval $(call dpkg_buildtool_setvar,OBJCOPY,objcopy))
$(eval $(call dpkg_buildtool_setvar,OBJDUMP,objdump))
$(eval $(call dpkg_buildtool_setvar,NM,nm))
$(eval $(call dpkg_buildtool_setvar,AR,ar))
$(eval $(call dpkg_buildtool_setvar,RANLIB,ranlib))
$(eval $(call dpkg_buildtool_setvar,PKG_CONFIG,pkg-config))
