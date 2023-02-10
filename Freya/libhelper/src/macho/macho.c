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

#include "libhelper-macho/macho-command-types.h"
#include "libhelper-macho/macho.h"


//===-----------------------------------------------------------------------===//
/*-- Mach-O                              									 --*/
//===-----------------------------------------------------------------------===//


/**
 *  Function:   macho_create
 *  ------------------------------------
 * 
 *  Creates a new Mach-O structure and assigns sufficient memory. Should
 *  be called to safely create a new raw Load Command structure.
 * 
 *  returns:    A macho_t structure with sufficient allocated memory.
 * 
 */
macho_t *macho_create ()
{
    macho_t *ret = malloc (sizeof (macho_t));
    memset (ret, '\0', sizeof (macho_t));
    return ret;
}


// Private Function
#define FAT(p) ((*(unsigned int *)(p) & ~1) == 0xbebafeca)

macho_t *macho_create_from_file (file_t *file)
{
    macho_t *macho = macho_create ();

    macho->path = file->path;

    macho->data = (uint8_t *) file_load_bytes (file, file->size, 0);
    macho->size = file->size;
    macho->offset = 0;

    // Try to detect if we are handling a fat file
    if (FAT(macho->data)) {
        warningf ("Cannot handle fat binary.\n");
        return NULL;
    }

    // Try to load the mach header, and handle a failure if it occurs
    macho->header = mach_header_load (macho);
    if (macho->header == NULL) {
        errorf ("Unable to load Mach-O\n");
        macho_free (macho);
        return NULL;
    }


    /**
     *  The first major chunk of data we will pull from mach->file is the
     *  Load Commands. They will be be split into two GSLists, cmdlist
     *  for the wide range of Load Commands, and seglist, which contains
     *  LC_SEGMENT_XX commands, of which there are many in a single file.
     * 
     *  My method is simply using a for loop to go through each base Load
     *  Command, which contains a command type and size field only, and
     *  check the lc->cmd property. 
     *  
     *  If the lc->cmd property equals LC_SEGMENT_64, we will load a segment
     *  command from the offset of that command, otherwise it is added to
     *  the cmdlist.
     * 
     *  You may notice I use mach_command_info_t instead of mach_load_command_t.
     *  I do this because the info struct contains the offset of where the
     *  Load Command is in the file.
     * 
     *  Mach-O's can contain dynamically linked libraries, which are referenced
     *  by the LC_LOAD_DYLIB, ..., Load Commands. As there are typically more
     *  than one, they are also stored within a list.
     * 
     */
    HSList *scmds = NULL;
    HSList *lcmds = NULL;
    HSList *dylibs = NULL;

    uint32_t offset = sizeof (mach_header_t);

    for (int i = 0; i < (int) macho->header->ncmds; i++) {

        // Create the Command Info struct
        mach_command_info_t *lc = mach_command_info_load (macho->data, offset);

        // Check for an LC_SEGMENT
        if (lc->type == LC_SEGMENT_64 || lc->type == LC_SEGMENT) {

            // Check and ignore any 32-bit segments
            if (lc->type == LC_SEGMENT) {
                warningf ("Skipping LC_SEGMENT (32-bit) at offset 0x%x\n", offset);
                continue;
            }

            // Create a Segment Info, then add to the hslist
            mach_segment_info_t *seginfo = mach_segment_info_load (macho->data, offset);
            if (seginfo == NULL) {
                warningf ("Failed to load LC_SEGMENT_64 at offset: 0x%x\n", offset);
                continue;
            }

            // Append to the segments list
            scmds = h_slist_append (scmds, seginfo);

        } else if (lc->type == LC_ID_DYLIB || lc->type == LC_LOAD_DYLIB ||
                   lc->type == LC_LOAD_WEAK_DYLIB || lc->type == LC_REEXPORT_DYLIB) {

            // Because a Mach-O can have multiple Dynamically linked libraries,
            // that means there are multiple LC_DYLIB-like commands, so it's
            // easier that we have a seperate list for them.

            // Create the info struct for the command
            mach_dylib_command_info_t *dylibinfo = malloc (sizeof (mach_dylib_command_info_t));
            uint32_t cmdsize = lc->lc->cmdsize;

            // Create and load the raw command
            mach_dylib_command_t *raw = malloc (sizeof (mach_dylib_command_t));
            memset (raw, '\0', sizeof (mach_dylib_command_t));
            memcpy (raw, macho->data + offset, sizeof (mach_dylib_command_t));

            // Load the name of the dylib. This is located after the Load Command
            //  and is included in the cmdsize property of the Load Command.
            uint32_t nsize = cmdsize - sizeof(mach_dylib_command_t);
            uint32_t noff = offset + raw->dylib.offset;

            char *name = malloc (nsize);
            memset (name, '\0', nsize);
            memcpy (name, macho->data + noff, nsize);

            // Set the name, raw cmd struct and type of the dylib
            dylibinfo->name = name;
            dylibinfo->dylib = raw;
            dylibinfo->type = lc->type;

            // Add the offset to lc
            lc->offset = offset;

            //  Add it to the list
            dylibs = h_slist_append (dylibs, dylibinfo);
            lcmds = h_slist_append (lcmds, lc);

        } else {

            // Set the offset of the command so we can find it again
            lc->offset = offset;

            // Append the Load Command to the 
            lcmds = h_slist_append (lcmds, lc);
        }

        
        // increment the offset
        offset += lc->lc->cmdsize;
    }

    macho->offset = offset;

    macho->lcmds = lcmds;
    macho->scmds = scmds;
    macho->dylibs = dylibs;

    return macho;
}


macho_t *macho_load (const char *filename)
{
    file_t          *file = NULL;
    macho_t         *macho = NULL;

	//	These are unused, but should be.
    //uint32_t         size = 0;
    //unsigned char   *data = NULL;

    if (filename) {

        debugf ("Reading Mach-O from filename: %s\n", filename);

        file = file_load (filename);
        if (file->size == 0) {
            errorf ("File not loaded properly\n");
            macho_free (macho);
            return NULL;
        }

        debugf ("Creating Mach-O struct\n");
        macho = macho_create_from_file (file);

        if (macho == NULL) {
            errorf ("Error creating Mach-O\n");
            return NULL;
        }

        debugf ("all seems well\n");
    } else {
        errorf ("No filename specified\n");
    }
    return macho;
}


void *macho_load_bytes (macho_t *macho, size_t size, uint32_t offset)
{
    void *ret = malloc (size);
    memcpy (ret, macho->data + offset, size);
    return ret;
}


void macho_free (macho_t *macho)
{
    macho = NULL;
    free (macho);
}


//===-----------------------------------------------------------------------===//
/*-- FAT & Mach-O Header functions         									 --*/
//===-----------------------------------------------------------------------===//

/**
 *  Function:   mach_header_verify
 *  ----------------------------------
 * 
 *  Verifies the given magic number, then returns a flag so the caller
 *  can proceed to either load a Mach-O or parse a FAT header.
 *  
 *  file:       The magic.
 * 
 *  Returns:    A header type flag.
 */
mach_header_type_t mach_header_verify (uint32_t magic)
{
    if (magic == MACH_CIGAM_64 || magic == MACH_MAGIC_64) {
        return MH_TYPE_MACHO64;
    } else if (magic == MACH_CIGAM_32 || magic == MACH_MAGIC_32) {
        return MH_TYPE_MACHO32;
    } else if (magic == MACH_CIGAM_UNIVERSAL || magic == MACH_MAGIC_UNIVERSAL) {
        return MH_TYPE_FAT;
    } else {
        return MH_TYPE_UNKNOWN;
    }
}


/**
 *  Function:   mach_header_create
 *  ------------------------------------
 * 
 *  Creates a new Mach-O Header structure and assigns sufficient memory. 
 *  Should be called to safely create a new Mach-O Header structure.
 * 
 *  Returns:    A mach_header_t structure with sufficient allocated memory.
 */
mach_header_t *mach_header_create ()
{
    mach_header_t *ret = malloc (sizeof (mach_header_t));
    memset (ret, '\0', sizeof (mach_header_t));
    return ret;
}


/**
 *  Function:   mach_header_load
 *  ----------------------------------
 * 
 *  Loads a raw Mach-O Header from the buffer contained in a given Mach-O struct. 
 *  Verifies the result is either a 32-bit or 64-bit Mach-O, and returns a populated
 *  mach_header_t struct. 
 *  
 *  file:       A Mach-O struct.
 * 
 *  Returns:    A verified Mach Header structure.
 */
mach_header_t *mach_header_load (macho_t *macho)
{
    // Creates the return header type/
    mach_header_t *header = NULL;

    // Check the macho given was at least initlaised and is not NULL
    if (macho) {
        unsigned char *data = macho->data;
        //uint32_t size = macho->size;
        header = mach_header_create ();

        // cpy bytes into the header struct.
        memcpy (header, &data[0], sizeof (mach_header_t));

        // verify that a magic value was loaded, and that we didn't just
        //  copy null bytes into the struct.
        if (!header->magic) {
            errorf ("No magic value, something went wrong.\n");
            return NULL;
        }

        //  Check the magic.
        mach_header_type_t type = mach_header_verify (header->magic);

        //  There are a few magic values that we can deal with. 0xfeedfacf,
        //  0xfeedface, and 0xcafebabe. 
        //
        //  0xcafebabe is awkward, because it's not known how the client
        //  wants to handle Universal Binary  formats. So, just print an
        //  error and return.
        //
        //  mach_header_check_magic () can be used to check if we are
        //  handling a FAT file, then the client can use functions for
        //  fat files. 
        //
        if (type == MH_TYPE_MACHO64) {
            // building libhelper with DEBUG == 0 will disable these msgs
            debugf ("Detected Mach-O 64-bit\n");
        } else if (type == MH_TYPE_MACHO32) {
            debugf ("Detected Mach-O 32-bit\n");
        } else if (type == MH_TYPE_FAT) {
            errorf ("Detected Universal Binary, but cannot load it.\n");
            header = NULL;
        } else {
            errorf ("Unknown file magic: 0x%08x\n", header->magic);
            header = NULL;
        }
    }
    return header;
}


/**
 *  Function:   swap_header_bytes
 *  ------------------------------------
 * 
 *  Swaps the bytes of a fat_header_t. 
 * 
 *  returns:    A swapped fat_header_t struct.
 * 
 */
fat_header_t *swap_header_bytes (fat_header_t *header)
{
    header->magic = OSSwapInt32(header->magic);
    header->nfat_arch = OSSwapInt32(header->nfat_arch);
    return header;
}


/**
 *  Function:   swap_fat_arch_bytes
 *  ------------------------------------
 * 
 *  Swaps the bytes of a fat_arch. 
 * 
 *  returns:    A swapped fat_arch struct.
 * 
 */
struct fat_arch *swap_fat_arch_bytes (struct fat_arch *a)
{
    a->cputype = OSSwapInt32(a->cputype);
    a->cpusubtype = OSSwapInt32(a->cpusubtype);
    a->offset = OSSwapInt32(a->offset);
    a->size = OSSwapInt32(a->size);
    a->align = OSSwapInt32(a->align);
    return a;
}


/**
 *  Function:   mach_universal_load
 *  ----------------------------------
 * 
 *  Loads a raw Universal Mach-O Header from a given offset in a verified file, and
 *  returns the resulting structure.
 *  
 *  file:       The verified file.
 * 
 *  Returns:    A verified Universal/FAT Mach Header structure.
 */
fat_header_info_t *mach_universal_load (file_t *file)
{
	uint32_t size = file->size;
    unsigned char *data = (unsigned char *) file_load_bytes (file, size, 0);

    // Create the FAT header so we can read some data from
    // the file. The header starts at 0x0 in the file. It
    // is also in Little-Endian form, so we have to swap
    // the byte order.
    fat_header_t *fat_header = malloc (sizeof (fat_header_t));
    memset (fat_header, '\0', sizeof (fat_header_t));
    memcpy (fat_header, &data[0], sizeof (fat_header_t));

    fat_header = swap_header_bytes (fat_header);

    // Check the number of architectures
    if (!fat_header->nfat_arch) {
        errorf ("Empty Mach-O Universal Binary");
        exit (0);
    }

    if (fat_header->nfat_arch > 1) 
        printf ("[*] %s: Mach-O Universal Binary. Found %d architectures.\n", file->path, fat_header->nfat_arch);

    // Arch list
    HSList *archs = NULL;

    // Create an offset to move through the archs.
    uint32_t offset = sizeof(fat_header_t);
    for (uint32_t i = 0; i < fat_header->nfat_arch; i++) {

        // Current arch. Also needs to swap the bytes.
        struct fat_arch *arch = (struct fat_arch *) malloc (sizeof (struct fat_arch));
        memset (arch, '\0', sizeof (struct fat_arch));
        memcpy (arch, data + offset, sizeof (struct fat_arch));
        ///file_load_bytes (file, sizeof(struct fat_arch), offset);

        arch = swap_fat_arch_bytes (arch);

        // Add to the list
        archs = h_slist_append (archs, arch);

        // Increment the offset
        offset += sizeof(struct fat_arch);
    }

    fat_header_info_t *ret = malloc (sizeof(fat_header_info_t));
    ret->header = fat_header;
    ret->archs = archs;

    return ret;
}


/**
 *  Function:   mach_header_read_cpu_type
 *  -------------------------------------
 * 
 *  Returns a decoded string of header->cputype.
 * 
 *  type:       The cpu_type_t from the Mach-O Header.
 * 
 *  Returns:    Decoded CPU type String.
 */
char *mach_header_read_cpu_type (cpu_type_t type)
{
    char *cpu_type = "";
    switch (type) {
        case CPU_TYPE_X86:
            cpu_type = "x86";
            break;
        case CPU_TYPE_X86_64:
            cpu_type = "x86_64";
            break;
        case CPU_TYPE_ARM:
            cpu_type = "arm";
            break;
        case CPU_TYPE_ARM64:
            cpu_type = "arm64";
            break;
        case CPU_TYPE_ARM64_32:
            cpu_type = "arm64_32";
            break;
        default:
            cpu_type = "unknown";
            break;
    }
    return cpu_type;
}


/**
 *  Function:   mach_header_read_cpu_sub_type
 *  -------------------------------------
 * 
 *  Returns a decoded string of header->cpusubtype.
 * 
 *  type:       The cpu_subtype_t from the Mach-O Header.
 * 
 *  Returns:    Decoded CPU sub type String.
 */
char *mach_header_read_cpu_sub_type (cpu_subtype_t type)
{
    char *cpu_subtype = "";
    switch (type) {
        case CPU_SUBTYPE_ARM64_ALL:
            cpu_subtype = "arm64";
            break;
        case CPU_SUBTYPE_ARM64_V8:
            cpu_subtype = "arm64_v8";
            break;
        case CPU_SUBTYPE_ARM64E:
            cpu_subtype = "arm64e";
            break;
        default:
            cpu_subtype = "unknown";
            break;
    }
    return cpu_subtype;
}


/**
 *  Function:   mach_header_read_file_type
 *  -------------------------------------
 * 
 *  Returns a decoded string of header->filetype.
 * 
 *  type:       The header->filetype uint32_t from the Mach-O Header.
 * 
 *  Returns:    Decoded header->filetype.
 */
char *mach_header_read_file_type (uint32_t type)
{
    char *ret = "";
    switch (type) {
        case MACH_TYPE_OBJECT:
            ret = "Mach Object (MH_OBJECT)";
            break;
        case MACH_TYPE_EXECUTE:
            ret = "Mach Executable (MH_EXECUTE)";
            break;
        case MACH_TYPE_DYLIB:
            ret = "Mach Dynamic Library (MH_DYLIB)";
            break;
        case MACH_TYPE_KEXT_BUNDLE:
            ret = "Mach Kernel Extension Bundle (MH_KEXT_BUNDLE)";
            break;
        default:
            ret = "Unknown";
            break;
    }
    return ret;
}


/**
 *  Function:   mach_header_read_file_type_short
 *  -------------------------------------
 * 
 *  Returns a decoded string of header->filetype.
 * 
 *  type:       The header->filetype uint32_t from the Mach-O Header.
 * 
 *  Returns:    Decoded header->filetype.
 */
char *mach_header_read_file_type_short (uint32_t type)
{
    char *ret = "";
    switch (type) {
        case MACH_TYPE_OBJECT:
            ret = "Object";
            break;
        case MACH_TYPE_EXECUTE:
            ret = "Executable";
            break;
        case MACH_TYPE_DYLIB:
            ret = "Dynamic Library";
            break;
        default:
            ret = "Unknown";
            break;
    }
    return ret;
}


/**
 *  Function:   mach_header_print_summary
 *  -------------------------------------
 * 
 *  Outputs a summary of a given mach_header_t.
 * 
 *  header:     The Mach-O Header.
 * 
 */
void mach_header_print_summary (mach_header_t *header)
{
    debugf ("==================\nMach-O Header Dump\n==================\n\n");

    debugf ("Magic: \t\t0x%x\n", header->magic);
    debugf ("CPU Type: \t%s\n", mach_header_read_cpu_type(header->cputype));
    debugf ("CPU Sub-Type: \t0x%x\n", header->cpusubtype);
    debugf ("File Type: \t%s\n", mach_header_read_file_type (header->filetype));
    debugf ("Load Commands: \t%d\n", header->ncmds);
    debugf ("LC Size: \t%d\n", header->sizeofcmds);

    debugf ("------------------\n\n");
}
