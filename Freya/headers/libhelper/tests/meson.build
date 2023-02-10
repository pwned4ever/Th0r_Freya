sources = ['main.c']
deps = []

#libhelper_tests = executable('libhelper-tests', sources, dependencies: deps, link_with: libhelper, include_directories : incdir)
#checkra1n_example = executable('checkra1n-tests', sources: ['checkra1n_extract_demo.c'], dependencies: deps, link_with: libhelper, include_directories : incdir)

#hslist_tests = executable ('hlibc_test', sources: ['hlibc_tests.c'], dependencies: deps, link_with: libhelper, include_directories : incdir)

#header_test = executable ('machotest-header', sources: ['machotest-header.c'], dependencies: deps, link_with: libhelper, include_directories : incdir)

#macho_test = executable ('machotest', sources: ['macho.c'])

#macholl_test = executable ('macho-ll', sources: ['macho-ll.c'], link_with : libhelper_static, include_directories : incdir)
macholl_lib_test = executable ('macholl-lib', sources: ['macho-ll-lib.c'], link_with : libhelper_static, include_directories : incdir)

dyld_cache_test = executable ('dyld_cache', sources: ['dyld_cache.c'], link_with : libhelper_static, include_directories : incdir)
function_starts_test = executable ('func_starts', sources: ['func_starts.c'], link_with : libhelper_static, include_directories : incdir)