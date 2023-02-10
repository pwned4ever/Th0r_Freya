project ('img4helper', 'c',
		 version: '1.0.0',
		 default_options: [
			'werror=true',
			'warning_level=2',
			'c_std=c11'
		])

#
#	Allow unused variables but still show a warning
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


#
#	Dependencies
#
#lzfse_dep = dependency('lzfse')
#openssl_dep = dependency('openssl')
cc_dep = dependency('cryptokit')


#
#	Sub directories
#
subdir('libhelper/src')
subdir('src')
