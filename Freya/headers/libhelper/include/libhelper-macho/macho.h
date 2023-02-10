//===------------------------------ macho -----------------------------===//
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

#ifndef LIBHELPER_MACHO_LL_H
#define LIBHELPER_MACHO_LL_H

/**
 *                  === The Libhelper Project ===
 *                          Mach-O Parser
 *
 *  Mach-O-ll, eventually just Libhelper-Mach-O, is a more lower-level
 *  implementation of a Mach-O parser than I currently have. Instead of
 *  interacting with the Mach-O with calls to fread, it will load the file
 *  into memory and operate from there. There are two benefits of this.
 * 
 *      1)  Less file operations
 *      2)  Modify the data more easily
 * 
 *  Tests will take place in /tests, otherwise for now projects built with
 *  Libhelper-Mach-O should not have any issues with compiling or runtime.
 * 
 *  DEVNOTES:
 *      -   Change the header guard once done!
 *      -   Test the absolute shit out of it, make sure it's as reliable
 *          as current implementation.
 *
 *  ----------------
 *  Original Author:
 *      Harry Moulton, @h3adsh0tzz  -   me@h3adsh0tzz.com.
 *
 */

#include "libhelper-macho/macho-header-const.h"
#include "libhelper-macho/macho-segment.h"
#include "libhelper/hslist.h"
#include "libhelper/strutils.h"

//  Linux does not have OSSwapInt32(), instead it has bswap_32, so
//  if the build platform is Linux, redefine bswap_32 as OSSwapInt32
//  and include byteswap.h
//
#ifndef __APPLE__
#    include <byteswap.h>
#endif

/***********************************************************************
* Mach-O Header.
*
*   Here are some definitions for CPU types, Mach-O types and the Mach
*   O File Header.
*
***********************************************************************/


/**
 *  Capability bits used in the definition of cpu_type. These are used to
 *  calculate the value of the 64bit CPU Type's by performing a logical OR
 *  between the 32bit variant, and the architecture mask.
 *
 *      E.g. CPU_TYPE_ARM64 = (CPU_TYPE_ARM | CPU_ARCH_ABI64)
 *
 */
#define CPU_ARCH_MASK           0xff000000      /* mask for architecture bits */
#define CPU_ARCH_ABI64          0x01000000      /* 64 bit ABI */
#define CPU_ARCH_ABI64_32       0x02000000      /* ABI for 64-bit hardware with 32-bit types; LP32 */


/**
 *  Mach-O file type specifiers. Mach-O's can be executables, objects, dynamic
 *  libraries, etc.
 *
 *  The layout of the file is dependent on the type of Mach-O. For all types
 *  excluding the MACH_TYPE_OBJECT, or MH_OBJECT as defined in loader.h, the
 *  Segments are padded out and aligned on a segment alignment boundary.
 *
 *  The MACH_TYPE_EXECUTE, MACH_TYPE_FVMLIB, MACH_TYPE_DYLIB, MACH_TYPE_DYLINKER,
 *  and MACH_TYPE_BUNDLE all have the headers included as part of their first
 *  segment.
 *
 *  MACH_TYPE_OBJECT is intended as output of the assembler and input, or output,
 *  of the linker. An example of this is when one compiles each source file induvidually
 *  to get a number of .o files, then linking them all together.
 *
 *  Over time I will add more of these MACH_TYPE definitions as I add support for
 *  them.
 *
 */
#define MACH_TYPE_UNKNOWN       0x0

#define MACH_TYPE_OBJECT        0x1
#define MACH_TYPE_EXECUTE       0x2

#define MACH_TYPE_DYLIB         0x6

#define MACH_TYPE_KEXT_BUNDLE   0xb


/**
 *  Mach-O Magic's.
 *
 *  There are three Magic Numbers we need to be concerned with. That is
 *  the 32bit, 64bit and Universal Binary Magic Numbers.
 *
 *  32-bit:     0xfeedface
 *  64-bit:     0xfeedfacf
 *  Uni Bin:    0xcafebabe
 *
 */
#define MACH_MAGIC_64           0xfeedfacf      /* 64bit magic number */
#define MACH_CIGAM_64           0xcffaedfe      /* NXSwapInt */

#define MACH_MAGIC_32           0xfeedface      /* 32bit magic number */
#define MACH_CIGAM_32           0xcefaedfe      /* NXSwapInt */

#define MACH_MAGIC_UNIVERSAL    0xcafebabe      /* Universal Binary magic number */
#define MACH_CIGAM_UNIVERSAL    0xbebafeca      /* NXSwapInt */


/**
 *  Redefinition of `cpu_type_t` and `cpu_subtype_t` for mach_header_t.
 *
 *  These are originally defined in macho/machine.h, but I'd like to write
 *  this library in a way that's cross-compatible with systems that do not
 *  have these headers natively.
 *
 */
typedef enum cpu_type_t {
    CPU_TYPE_ANY = 100,

    CPU_TYPE_X86 = 6,
    CPU_TYPE_X86_64 = 0x01000007,

    CPU_TYPE_ARM = 12,
    CPU_TYPE_ARM64 = (CPU_TYPE_ARM | CPU_ARCH_ABI64),
    CPU_TYPE_ARM64_32 = (CPU_TYPE_ARM | CPU_ARCH_ABI64_32)
} cpu_type_t;

// TODO
typedef enum cpu_subtype_t {
    CPU_SUBTYPE_ANY = 100,

    CPU_SUBTYPE_ARM64_ALL = 0,
    CPU_SUBTYPE_ARM64_V8 = 1,
    CPU_SUBTYPE_ARM64E = 2
} cpu_subtype_t;


/**
 * 	Mach-O Header type flag.
 * 
 * 	Two flags that determine whether a file is a Mach-O or a FAT file containg
 * 	multiple Mach-O's for different arhcitectures.
 * 
 */
typedef enum mach_header_type_t {
	MH_TYPE_UNKNOWN = -1,
	MH_TYPE_MACHO64 = 1,
	MH_TYPE_MACHO32,
	MH_TYPE_FAT
} mach_header_type_t;


/**
 *  Mach-O header
 * 
 *  Mach-O header is 64-bit. This appears at the very top of Mach-O files
 *  and sets out the format of the file, and how to parse stuff. 
 * 
 *  To avoid any overflows or crashes, one should check that magic before
 *  doing any operations involving the `reserved` property, as this is not
 *  present in 32-bit Mach-O's.
 * 
 */
struct mach_header {
    uint32_t            magic;          // mach magic number
    cpu_type_t          cputype;        // cpu specifier
    cpu_subtype_t       cpusubtype;     // cpu subtype specifier
    uint32_t            filetype;       // type of mach-o e.g. exec, dylib ...
    uint32_t            ncmds;          // number of load commands
    uint32_t            sizeofcmds;     // size of load command region
    uint32_t            flags;          // flags
    uint32_t            reserved;       // *64-bit only* reserved
};
typedef struct mach_header      mach_header_t;


/**
 *  Mach-O Header (32-bit)
 * 
 */
struct mach_header_32 {
    uint32_t            magic;          // mach magic number
    cpu_type_t          cputype;        // cpu specifier
    cpu_subtype_t       cpusubtype;     // cpu subtype specifier
    uint32_t            filetype;       // type of mach-o e.g. exec, dylib ...
    uint32_t            ncmds;          // number of load commands
    uint32_t            sizeofcmds;     // size of load command region
    uint32_t            flags;          // flags
};
typedef struct mach_header_32   mach_header_32_t;


/***********************************************************************
* FAT (Universal Binary) Header.
***********************************************************************/

/**
 *  FAT Header (Universal Binary)
 *
 *  FAT file header for Universal Binaries. This appears at the top of a universal
 *  file, with a summary of all the architectures contained within it.
 *
 */
typedef struct fat_header_t {
    uint32_t        magic;          /* 0xcafebabe */
    uint32_t        nfat_arch;      /* number of fat_arch that follow */
} fat_header_t;


/**
 *  fat_arch defines an architecture that is part of the universal binary.
 *
 */
struct fat_arch {
    cpu_type_t      cputype;        /* cpu type for this arch */
    cpu_subtype_t   cpusubtype;     /* cpu sub type for this arch */
    uint32_t        offset;         /* offset for where this arch begins */
    uint32_t        size;           /* size of this archs macho */
    uint32_t        align;          /* byte align */
};


/**
 *  Universal Binary header with parsed and verified data about containing
 *  architectures.
 */
typedef struct fat_header_info_t {
    fat_header_t    *header;
    HSList          *archs;
} fat_header_info_t;

#ifdef __APPLE__
#	define OSSwapInt32(x) 	 _OSSwapInt32(x)
#else
#	define OSSwapInt32(x)	bswap_32(x)
#endif

/***********************************************************************
* Mach-O File Parsing.
***********************************************************************/

/**
 *  Mach-O file representation. Contains all the parsed properties of a Mach-O
 *  file, and some raw properties. 
 * 
 * 
 *  == Notes on 32-bit Mach-O's
 *  
 *      Despite the Mach-O header on 32-bit binaries being shorter, we can use
 *  `offset` property to define where to start reading the rest of the file. We 
 *  will use a 64-bit header by default, then check the magic to see if we need 
 *  to read the `reserved` property at the end of the header. 
 * 
 */
typedef struct macho_t {

    /* file data */
    char            *path;          // file path

    /* raw file properties */
    uint8_t         *data;          // ptr to mach-o in memory
    uint32_t         size;          // size of mach-o
    uint32_t         offset;        // base_addr + sizeof(mach_header_t)

    /* Parsed Mach-O properties */
    mach_header_t   *header;        // mach-o header
    HSList          *lcmds;         // list of all load commands (including LC_SEGMENT)
    HSList          *scmds;         // list of segment commands
    HSList          *dylibs;        // list of dynamic libraries
    HSList          *symbols;       // list of symbols;
    HSList          *strings;       // list of strings;
    /* add the rest */
} macho_t;


// Functions
macho_t *macho_create ();

macho_t *macho_load (const char *filename);
void *macho_load_bytes (macho_t *macho, size_t size, uint32_t offset);
void macho_free (macho_t *macho);

// has to be here because segment.h includes this header
HSList *mach_segment_get_list (macho_t *mach);

mach_section_info_t *mach_section_info_from_name (macho_t *macho, char *segment, char *section);

/***********************************************************************
* FAT & Mach-O Header functions.
***********************************************************************/

//  These are defined here because the Mach-O header functions require
//  macho_t, but macho_t requires mach_header_t, so these are defined
//  below macho_t, and the header is defined above.
//

// Mach-O header functions
mach_header_t *mach_header_create ();
mach_header_t *mach_header_load (macho_t *macho);

mach_header_type_t mach_header_verify (uint32_t magic);

char *mach_header_read_cpu_type (cpu_type_t type);
char *mach_header_read_cpu_sub_type (cpu_subtype_t type);
char *mach_header_read_file_type (uint32_t type);
char *mach_header_read_file_type_short (uint32_t type);

void mach_header_print_summary (mach_header_t *header);


// FAT header functions
fat_header_t        *swap_header_bytes (fat_header_t *header);
struct fat_arch     *swap_fat_arch_bytes (struct fat_arch *a);
fat_header_info_t   *mach_universal_load (file_t *file);


#endif /* libhelper_macho_ll_h */
