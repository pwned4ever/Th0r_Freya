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

#ifndef LIBHELPER_MACHO_COMMAND_LL_H
#define LIBHELPER_MACHO_COMMAND_LL_H

#include "libhelper-macho/macho-command-const.h"
#include "libhelper-macho/macho.h"
#include "libhelper/strutils.h"


/**
 * 	Mach-O Load Command structure definition.
 * 
 * 	Load commands directly follow the Mach Header. The total size of the command area
 * 	is given by the `sizeofcmds` property in the header, and the number of commands as
 * 	`mcmds`. 
 * 
 * 	The first two properties of a Load Command are always the cmd, which represents a LC
 * 	type, and a Size. Based on the LC type the command can be parsed correctly. For example,
 * 	given the cmd is LC_SEGMENT_64, we know to copy sizeof(mach_segment_command_t) bytes
 * 	from the start offset of the LC into a mach_segment_command_t. 
 * 
 * 	The structure is not architecture-specific. It will work with both 32bit and 64bit
 * 	parsing.
 * 
 */
struct load_command {
    uint32_t    cmd;        // type of load command
    uint32_t    cmdsize;    // size of load command
};
typedef struct load_command     mach_load_command_t;



/**
 *  Mach-O Load Command Info Structure
 * 
 *  Used to carry the offset of the load command relative from the base address
 *  of the mach-o.
 * 
 */
typedef struct mach_command_info_t {
    uint32_t                 offset;     // offset of the cmd
    uint32_t                 index;      // index of the cmd
    uint32_t                 type;       // load command type
    mach_load_command_t     *lc;         // load command structure
} mach_command_info_t;


/**
 *  Flags for the Load Command print functions.
 * 
 *  LC_RAW      Prints a raw Load Command Struct.
 *  LC_INFO     Prints a Load Command Info Struct.
 */
#define     LC_RAW      0x0
#define     LC_INFO     0x1


mach_load_command_t     *mach_load_command_create ();
mach_command_info_t     *mach_command_info_create ();

mach_command_info_t     *mach_command_info_load (unsigned char *data, uint32_t offset);

void 					 mach_load_command_info_print (mach_command_info_t *cmd);
void 					 mach_load_command_print (void *cmd, int flag);
char 					*mach_load_command_get_string (mach_load_command_t *lc);


#endif /* libhelper_macho_command_ll_h */