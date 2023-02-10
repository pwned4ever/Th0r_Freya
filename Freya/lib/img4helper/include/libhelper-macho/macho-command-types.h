//===--------------------------- macho_command ------------------------===//
//
//                          Libhelper Mach-O Parser
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//
//  Copyright (C) 2019, Is This On?, @h3adsh0tzz
//  me@h3adsh0tzz.com.
//
//
//===------------------------------------------------------------------===//

#ifndef LIBHELPER_MACHO_COMMAND_TYPES_LL_H
#define LIBHELPER_MACHO_COMMAND_TYPES_LL_H

#include "libhelper-macho/macho-command.h"
#include "libhelper-macho/macho-segment.h"
#include "libhelper-macho/macho-symbol.h"
#include "libhelper-macho/macho.h"
#include "libhelper/strutils.h"


mach_command_info_t *mach_lc_find_given_cmd (macho_t *macho, int cmd);

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////


/*
 * 	The source_version_command is an optional load command containing
 * 	the version of the sources used to build the binary.
 */
typedef struct mach_source_version_command_t {
    uint32_t  	cmd;			/* LC_SOURCE_VERSION */
    uint32_t  	cmdsize;		/* 16 */
    uint64_t  	version;		/* A.B.C.D.E packed as a24.b10.c10.d10.e10 */
} mach_source_version_command_t;


mach_source_version_command_t 	*mach_lc_find_source_version_cmd (macho_t *macho);
char 							*mach_lc_source_version_string (mach_source_version_command_t *svc);


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////


/**
 * 	The build_version_command contains the min OS version on which this
 * 	binary was built to run for its platform.
 */
typedef struct mach_build_version_command_t {
    uint32_t	cmd;		/* LC_BUILD_VERSION */
    uint32_t	cmdsize;	/* sizeof(struct build_version_command) plus */
                                /* ntools * sizeof(struct build_tool_version) */
    uint32_t	platform;	/* platform */
    uint32_t	minos;		/* X.Y.Z is encoded in nibbles xxxx.yy.zz */
    uint32_t	sdk;		/* X.Y.Z is encoded in nibbles xxxx.yy.zz */
    uint32_t	ntools;		/* number of tool entries following this */
} mach_build_version_command_t;


/**
 * 	The build_tool_version are found after the mach_build_version_command_t
 * 	in the Mach-O file. The `ntools` prop defines how many build_tool_version
 * 	structs are present. 
 * 
 * 	It defines a build tool, and it's version. For example:
 * 		LD 520.0.0
 */
struct build_tool_version
{
	uint32_t	tool;		/* enum for the tool */
    uint32_t	version;	/* version number of the tool */
};


/**
 * 	This is a neater version of build_tool_version that has an actual char *
 * 	for the tool name, and then the build version as is found in build_tool_version.
 * 
 */
typedef struct build_tool_info_t {
	char		*tool;
	uint32_t	version;
} build_tool_info_t;


/**
 * 	This struct brings all the Build version types together. It contains the 
 * 	original build version Load Command, but also string reps of the platform
 * 	minos, sdk, the number of build tools, and a HSList of tools.
 * 
 */
typedef struct mach_build_version_info_t {
	mach_build_version_command_t *cmd;
	
	char 		*platform;
	char		*minos;
	char		*sdk;

	uint32_t	 ntools;
	HSList 		*tools;
} mach_build_version_info_t;

/* Known values for the platform field above. */
#define PLATFORM_MACOS 1
#define PLATFORM_IOS 2
#define PLATFORM_TVOS 3
#define PLATFORM_WATCHOS 4
#define PLATFORM_BRIDGEOS 5
#define PLATFORM_MACCATALYST 6
#define PLATFORM_IOSSIMULATOR 7
#define PLATFORM_TVOSSIMULATOR 8
#define PLATFORM_WATCHOSSIMULATOR 9
#define PLATFORM_DRIVERKIT 10

/* Known values for the tool field above. */
#define TOOL_CLANG 1
#define TOOL_SWIFT 2
#define TOOL_LD	3


mach_build_version_info_t 		*mach_lc_build_version_info (mach_build_version_command_t *bvc, off_t offset, macho_t *macho);


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

/**
 * 	The mach_uuid_command_t is an optional load command containing
 * 	the UUID of the binary.
 */
typedef struct mach_uuid_command_t {
	uint32_t	cmd;			/* LC_UUID */
	uint32_t	cmdsize;		/* sizeof(mach_uuid_command_t) */
	uint8_t		uuid[16];		/* 128-bit UUID */
} mach_uuid_command_t;


mach_uuid_command_t 		*mach_lc_find_uuid_cmd (macho_t *macho);
char 						*mach_lc_uuid_string (mach_uuid_command_t *cmd);


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

/**
 * 	The mach_dyld_info_command_t contains file offsets and size of the new
 * 	compressed form of the information the dyld needs to load the image.
 * 	On macOS the Dynamic Linker uses the information in this command.
 * 
 * 	[Note]
 * 		These are the docs from loader.h, I'll write them in my own words
 * 		as I learn what they do.
 * 
 */
typedef struct mach_dyld_info_command_t {

	/**
	 * 	Base Mach-O Load Command data.
	 */
	uint32_t	cmd;			/* LC_DYLD_INFO or LC_DYLD_INFO_ONLY */
	uint32_t	cmdsize;		/* sizeof (mach_dyld_info_command_t) */

	/**
	 * 	Dynamic Linker rebases an image whenever dyld loads it at an address
	 * 	different from its preffered address. The rebase information is a
	 * 	stream of byte sized opcodes whose symbolic names start with REBASE_OPCODE_..
	 * 	
	 * 	Conceptually, the rebase information is a table of tuples:
	 * 		<seg-index, seg-offset, type>
	 * 
	 * 	The opcodes are a compressed way to encode teh table by only encoding
	 * 	when a column changes. In addition, simple patterns like "every n'th
	 * 	offset for m times" can be encoded in a few bytes.
	 * 
	 */
	uint32_t	rebase_off;		/* file offset to rebase info */
	uint32_t	rebase_size;	/* size of rebase info */

	/**
	 * 	Dynamic Linker binds an image during the loading process, if the image
	 * 	requires any pointers to be initialised to symbols in other images. The
	 * 	bind information is a stream of byte sized opcodes whose symbolic
	 * 	names start with BIND_OPCODE_...
	 * 
	 * 	Conceptually, the bind information is a table of tuples:
	 * 		<seg-index, seg-offset, type, symbol-library-ordinal, symbol-name, addend>
	 * 
	 * 	The opcodes are a compressed way to encode teh table by only encoding
	 * 	when a column changes. In addition simple patterns like for runs of
	 * 	pointers initialised to the same value can be encoded in a few bytes.
	 * 
	 */
	uint32_t	bind_off;		/* file offset to binding info */
	uint32_t	bind_size;		/* size of binding info */

	/**
	 * 	Some C++ programs require dyld to unique symbols so that all images
	 * 	in the process use the same copy of some code/data. This step is done
	 * 	after binding. The content of the weak_bind info is an opcode stream
	 * 	like the bind_info. But it is sorted alphabetically by symbol name. This
	 * 	enables dyld to walk all images with weak binding information in order
	 * 	and look for collisions. If there are no collisions, dyld does no updating.
	 * 	That means that some fixups are also encoded in the bind_info. For instnace,
	 * 	all calls the "operator new" are first bound to libstdc++.dylib using
	 * 	the information in bind_info. Then if some image overrides operator new
	 * 	that is detected when the weak_bind information is processed and teh call
	 * 	to operator new is then rebound.
	 * 
	 */
	uint32_t	weak_bind_off;		/* file offset to weak binding info */
	uint32_t	weak_bind_size;		/* size of weak binding info */

	/*
     * 	Some uses of external symbols do not need to be bound immediately.
     * 	Instead they can be lazily bound on first use.  The lazy_bind
     * 	are contains a stream of BIND opcodes to bind all lazy symbols.
     * 	Normal use is that dyld ignores the lazy_bind section when
     * 	loading an image.  Instead the static linker arranged for the
     * 	lazy pointer to initially point to a helper function which 
     * 	pushes the offset into the lazy_bind area for the symbol
     * 	needing to be bound, then jumps to dyld which simply adds
     * 	the offset to lazy_bind_off to get the information on what 
     * 	to bind.  
     */
    uint32_t   lazy_bind_off;	/* file offset to lazy binding info */
    uint32_t   lazy_bind_size;  /* size of lazy binding infs */

	/*
     * 	The symbols exported by a dylib are encoded in a trie.  This
     * 	is a compact representation that factors out common prefixes.
     * 	It also reduces LINKEDIT pages in RAM because it encodes all  
     * 	information (name, address, flags) in one small, contiguous range.
     * 	The export area is a stream of nodes.  The first node sequentially
     * 	is the start node for the trie.  
     *
     * 	Nodes for a symbol start with a uleb128 that is the length of
     * 	the exported symbol information for the string so far.
     * 	If there is no exported symbol, the node starts with a zero byte. 
     * 	If there is exported info, it follows the length.  
	 *
	 * 	First is a uleb128 containing flags. Normally, it is followed by
     * 	a uleb128 encoded offset which is location of the content named
     * 	by the symbol from the mach_header for the image.  If the flags
     * 	is EXPORT_SYMBOL_FLAGS_REEXPORT, then following the flags is
     * 	a uleb128 encoded library ordinal, then a zero terminated
     * 	UTF8 string.  If the string is zero length, then the symbol
     * 	is re-export from the specified dylib with the same name.
	 * 	If the flags is EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER, then following
	 * 	the flags is two uleb128s: the stub offset and the resolver offset.
	 * 	The stub is used by non-lazy pointers.  The resolver is used
	 * 	by lazy pointers and must be called to get the actual address to use.
     *
     * 	After the optional exported symbol information is a byte of
     * 	how many edges (0-255) that this node has leaving it, 
     * 	followed by each edge.
     * 	Each edge is a zero terminated UTF8 of the addition chars
     * 	in the symbol, followed by a uleb128 offset for the node that
     * 	edge points to.
     *  
     */
    uint32_t   export_off;	/* file offset to lazy binding info */
    uint32_t   export_size;	/* size of lazy binding infs */
} mach_dyld_info_command_t;


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////


/*
 * 	A program that uses a dynamic linker contains a dylinker_command to identify
 * 	the name of the dynamic linker (LC_LOAD_DYLINKER).  And a dynamic linker
 * 	contains a dylinker_command to identify the dynamic linker (LC_ID_DYLINKER).
 * 	A file can have at most one of these.
 * 	This struct is also used for the LC_DYLD_ENVIRONMENT load command and
 * 	contains string for dyld to treat like environment variable.
 * 
 */
typedef struct mach_dylinker_command_t {
	uint32_t		cmd;
	uint32_t		cmdsize;

	uint32_t		offset;
#ifndef __LP64__
	char			*ptr;
#endif
} mach_dylinker_command_t; 


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////


/**
 * 	Dynamicly linked Shared Library command.
 * 
 * 	This identifies any dynamically shared linked libraries that an
 * 	executable requires.
 * 
 * 	The 'dylib' struct contains the lib properties.
 * 
 * 	The 'dylib_command' is the load command structure.
 * 
 * 	The dylib name string is stored just after the load command structure.
 * 	The offset prop is from the start of the load command structure, so
 * 	the size of the string is:
 * 		s = cmdsize - (sizeof(uint32_t) * 4);
 * 
 */
typedef struct dylib_vers_t {
	uint32_t			a;			/* XXXX.00.00 */
	uint32_t			b;			/* 0000.XX.00 */
	uint32_t			c;			/* 0000.00.XX */
} dylib_vers_t;


/**
 * 	dylib struct defines a dynamic library. The name of the library is
 * 	placed after the structure, but is included in the cmdsize of the
 * 	mach_dylib_command_t.
 * 
 */		
struct dylib {
	uint32_t		offset;					/* Offset of the library name in the string table */
#ifndef __LP64__
	char			*ptr;					/* pointer to the string */
#endif
	
	uint32_t		timestamp;				/* lib build time stamp */
	uint32_t		current_version;		/* lib current version numbre */
	uint32_t		compatibility_version;	/* lib compatibility vers numb */
};


/**
 * 	Base mach_dylib_command_t Load Command that matches that in loader.h
 * 
 */	
typedef struct mach_dylib_command_t {
	uint32_t		cmd;		/* LC_ID_DYLIB, LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB, LC_REEXPORT_DYLIB */
	uint32_t		cmdsize;	/* Includes pathname string */
	struct dylib	dylib;
} mach_dylib_command_t;


/**
 * 	Struct holding the original load command struct, which type of dylib
 * 	it is, and the pre-calculated name for the library. 
 * 
 */
typedef struct mach_dylib_command_info_t {
	mach_dylib_command_t	*dylib;
	uint32_t				 type;
	char					*name;
} mach_dylib_command_info_t;


char 		*mach_lc_load_dylib_format_version (uint32_t vers);
char 		*mach_lc_dylib_get_type_string (mach_dylib_command_t *dylib);


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////


/**
 * 	LC_LOAD_DYLINKER
 */
typedef struct mach_load_dylinker_command_t {
	uint32_t		cmd;
	uint32_t		cmdsize;		/* includes str size at offset */

	uint32_t		offset;
#ifndef __LP64__
	char			*ptr;
#endif
} mach_load_dylinker_command_t;


char 		*mach_lc_load_dylinker_string_cmd (macho_t *macho, mach_load_dylinker_command_t *dylinker, off_t offset);


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////


/**
 * 	LC_MAIN stuff
 */
typedef struct mach_entry_point_command_t {
	uint32_t		cmd;
	uint32_t		cmdsize;
	uint64_t		entryoff;
	uint64_t		stacksize;
} mach_entry_point_command_t;


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////


/**
 * 	LC_CODE_SIGNATURE, LC_SEGMENT_SPLIT_INFO, LC_FUNCTION_STARTS, 
 * 	LC_DATA_IN_CODE, LC_DYLIB_CODE_SIGN_DRS, LC_LINKER_OPTIMIZATION_HINT
 * 	LC_DYLD_EXPORTS_TIRE, LC_DYLD_CHAINED_FIXUPS
 */
typedef struct mach_linkedit_data_command_t {
	uint32_t		cmd;
	uint32_t		cmdsize;

	uint32_t		dataoff;
	uint32_t		datasize;
} mach_linkedit_data_command_t;


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////


/**
 * 	LC_RPATH
 */
typedef struct mach_rpath_command_t {
	uint32_t		cmd;
	uint32_t		cmdsize;

	uint32_t		offset;
#ifndef __LP64__
	char			*ptr;
#endif
} mach_rpath_command_t;


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////


/**
 * 	LC_ENCRYPTION_INFO
 */	
typedef struct mach_crypto_command_64_t {
	uint32_t	cmd;		/* LC_ENCRYPTION_INFO_64 */
   	uint32_t	cmdsize;	/* sizeof(struct encryption_info_command_64) */
   	uint32_t	cryptoff;	/* file offset of encrypted range */
   	uint32_t	cryptsize;	/* file size of encrypted range */
   	uint32_t	cryptid;	/* which enryption system,
				   0 means not-encrypted yet */
   	uint32_t	pad;		/* padding to make this struct's size a multiple
				   of 8 bytes */
} mach_crypto_command_64_t;

//////////////////////////////////////////////////////////////////////////
//                 Other Function Definitions                           //
//////////////////////////////////////////////////////////////////////////


mach_command_info_t 	*mach_lc_find_given_cmd (macho_t *macho, int cmd);
mach_symtab_command_t 	*mach_lc_find_symtab_cmd (macho_t *macho);

mach_dysymtab_command_t *mach_lc_find_dysymtab_cmd (macho_t *macho);

char 					*mach_lc_load_str (macho_t *macho, uint32_t cmdsize, uint32_t struct_size, off_t cmd_offset, off_t str_offset);


#endif /* libhelper_macho_command_type_ll_h_ */