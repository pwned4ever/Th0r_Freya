#
#   Build file for libhelper.
#
#   Copyright (C) 2019, @h3adsh0tzz
#   See LICENSE
#

#
#   Sources
#
mach_parser_sources =  ['macho/macho.c',
                        'macho/macho-command.c',
                        'macho/macho-segment.c',
                        'macho/macho-symbol.c']

dyld_parser_sources = ['dyld/dyld.c']

img4_sources = ['img4/sep.c']

lzss_sources = ['lzss/lzss.c']

lzfse_sources = ['lzfse/lzfse_encode_base.c',
                 'lzfse/lzfse_decode_base.c',
                 'lzfse/lzfse_decode.c',
                 'lzfse/lzfse_encode.c',
                 'lzfse/lzfse_fse.c',
                 'lzfse/lzvn_encode_base.c',
                 'lzfse/lzvn_decode_base.c',]

lib_sources = ['libhelper.c',
                'file.c',
                'strutils.c', 
                'hslist.c', 
                'hstring.c', 
                mach_parser_sources,
                dyld_parser_sources,
                img4_sources,
                lzss_sources,
                lzfse_sources]

#
#   Include Directories
#
incdir = include_directories('../include')


#
#   dont quite know what im doing here. ignore for now.
#
libhelper_static    =  static_library('helper', lib_sources, version : '1.0', include_directories : incdir)
libhelper           =  shared_library('helper', lib_sources, version : '1.0', include_directories : incdir)