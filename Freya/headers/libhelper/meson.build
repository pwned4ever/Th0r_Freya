#
#   Build file for libhelper.
#
#   Copyright (C) 2019, @h3adsh0tzz
#   See LICENSE
#

#
#   Project declaration
#
project ('libhelper', 'c', version: '1.0', default_options: [
                                                'werror=true',
                                                'warning_level=2',
                                                'c_std=c11'
                                            ])


#
#   Suppress some build errors
#
add_project_arguments('-Wno-error=unused-variable', language : 'c')
add_project_arguments('-Wno-error=unused-function', language : 'c')
add_project_arguments('-Wno-error=unused-parameter', language : 'c')
add_project_arguments('-Wno-error=int-conversion', language : 'c')
add_project_arguments('-Wno-error=missing-field-initializers', language : 'c')
add_project_arguments('-Wno-error=sign-compare', language : 'c')
add_project_arguments('-Wno-error=int-conversion', language : 'c')
add_project_arguments('-Wno-error=incompatible-pointer-types', language : 'c')
add_project_arguments('-Wno-error=format', language : 'c')
add_project_arguments('-Wno-error=type-limits', language : 'c')


#
#   Sub directories
#
subdir('src')
subdir('tools')
subdir('tests')
