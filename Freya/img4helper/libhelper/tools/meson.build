#
#	Tools built with libhelper. All of these can be compiled with no
#	other depndencies
#

#
#   Add a better way of building all three from ninja
#
macho_helper_toolset = executable ('macho_tool_NAME', sources: ['macho_toolset.c'], link_with : libhelper_static, include_directories : incdir)

#
#   Small program that prints the libhelper version
#
libhelper_vers = executable ('libhelper-version', sources: ['libhelper_version.c'], link_with : libhelper_static, include_directories: incdir)
