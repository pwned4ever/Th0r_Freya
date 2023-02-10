//===--------------------------- macho_segment ------------------------===//
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

#ifndef LIBHELPER_MACHO_SEGMENT_LL_H
#define LIBHELPER_MACHO_SEGMENT_LL_H

#include "libhelper/hslist.h"
#include "libhelper/strutils.h"

//===-----------------------------------------------------------------------===//
/*-- Mach-O Segments                     									 --*/
//===-----------------------------------------------------------------------===//


/**
 *  Segment Load Commands, LC_SEGMENT and LC_SEGMENT_64, indicate a part of the
 *  Mach-O to be mapped into a tasks address space.
 * 
 */
typedef int vm_prot_t;
struct segment_command_64 {
    uint32_t	cmd;			/* LC_SEGMENT_64 */
    uint32_t	cmdsize;		/* includes sizeof section_64 structs */
    char		segname[16];	/* segment name */
    uint64_t	vmaddr;			/* memory address of this segment */
    uint64_t	vmsize;			/* memory size of this segment */
    uint64_t	fileoff;		/* file offset of this segment */
    uint64_t	filesize;		/* amount to map from the file */
    vm_prot_t	maxprot;		/* maximum VM protection */
    vm_prot_t	initprot;		/* initial VM protection */
    uint32_t	nsects;			/* number of sections in segment */
    uint32_t	flags;			/* flags */   
};
typedef struct segment_command_64 mach_segment_command_64_t;

struct segment_command {
	uint32_t	cmd;		/* LC_SEGMENT */
	uint32_t	cmdsize;	/* includes sizeof section structs */
	char		segname[16];	/* segment name */
	uint32_t	vmaddr;		/* memory address of this segment */
	uint32_t	vmsize;		/* memory size of this segment */
	uint32_t	fileoff;	/* file offset of this segment */
	uint32_t	filesize;	/* amount to map from the file */
	vm_prot_t	maxprot;	/* maximum VM protection */
	vm_prot_t	initprot;	/* initial VM protection */
	uint32_t	nsects;		/* number of sections in segment */
	uint32_t	flags;		/* flags */
};
typedef struct segment_command mach_segment_command_32_t;

typedef struct mach_segment_info_t {
    mach_segment_command_64_t   *segcmd;    /* Segment command */
    uint64_t                    padding;
    HSList                      *sections;  /* List of sections */
} mach_segment_info_t;

// VM Protection types
#define VM_PROT_READ			0x00000001
#define VM_PROT_WRITE			0x00000002
#define VM_PROT_EXEC			0x00000004


// Functions
mach_segment_command_64_t *mach_segment_command_create ();
mach_segment_command_64_t *mach_segment_command_load (unsigned char *data, uint32_t offset);
mach_segment_command_64_t *mach_segment_command_from_info (mach_segment_info_t *info);

mach_segment_info_t *mach_segment_info_create ();
mach_segment_info_t *mach_segment_info_load (unsigned char *data, uint32_t offset);
mach_segment_info_t *mach_segment_info_search (HSList *segments, char *segname);

char *mach_segment_vm_protection (vm_prot_t prot);

//===-----------------------------------------------------------------------===//
/*-- Mach-O Sections                     									 --*/
//===-----------------------------------------------------------------------===//


/**
 * 	A segment is made up of zero or more sections. CONT
 * 
 */
struct section_64 {
	char		sectname[16];	/* name of this section */
	char		segname[16];	/* segment this section goes in */
	uint64_t	addr;			/* memory address of this section */
	uint64_t	size;			/* size in bytes of this section */
	uint32_t	offset;			/* file offset of this section */
	uint32_t	align;			/* section alignment (power of 2) */
	uint32_t	reloff;			/* file offset of relocation entries */
	uint32_t	nreloc;			/* number of relocation entries */
	uint32_t	flags;			/* flags (section type and attributes)*/
	uint32_t	reserved1;		/* reserved (for offset or index) */
	uint32_t	reserved2;		/* reserved (for count or sizeof) */
	uint32_t	reserved3;		/* reserved */
};
typedef struct section_64 mach_section_64_t;


/**
 * 
 */
typedef struct mach_section_info_t {
	mach_section_64_t	*_struct;
    char                *segment;
    char                *section;
    char                *data;
    size_t               size;
    uint32_t             addr;
} mach_section_info_t;


/**
 * 
 */
mach_section_64_t *mach_section_create ();
mach_section_64_t *mach_section_load (unsigned char *data, uint32_t offset);
mach_section_64_t *mach_section_from_segment_info (mach_segment_info_t *info, char *sectname);
mach_section_64_t *mach_find_section_command_at_index (HSList *segments, int index);

// NOT IMPLEMENTED
//mach_section_64_t *mach_find_section (HSList *segments, int sect);
//HSList *mach_sections_load_from_segment (unsigned char *data, mach_segment_command_64_t *seg);
//void mach_section_print (mach_section_64_t *section);



#endif /* libhelper_macho_segment_ll_h */