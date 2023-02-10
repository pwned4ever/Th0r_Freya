//===-------------------------- macho_toolset.c ----------------------------===//
//
//                               macho_toolset
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
//===-----------------------------------------------------------------------===//

#include <libhelper/libhelper.h>
#include <libhelper-macho/macho.h>
#include <libhelper-macho/macho-command.h>
#include <libhelper-macho/macho-segment.h> 

#ifdef __APPLE__
#   define BUILD_TARGET         "darwin"
#   define BUILD_TARGET_CAP     "Darwin"
#else
#   define BUILD_TARGET         "linux"
#   define BUILD_TARGET_CAP     "Linux"
#endif

#ifdef __x86_64__
#   define BUILD_ARCH           "x86_64"
#elif __arm64__
#	define BUILD_ARCH			"arm64"
#elif __arm__
#   define BUILD_ARCH           "arm"
#endif


/***********************************************************************
* Libhelper's MachO-Helper-Toolset.
*
*   I thought I'd be a bit creative with this and follow the model
*   of the iBoot source - build everything from a single file. So,
*   the code compiled depends on what value is set below.
*
*   Each tool has it's own version number, in the simple format of:
*   Major.Minor.Revision. The Toolset overall has it's own version
*   too. I did this because I can keep track of things based on the
*   version of the specific tool, and the toolset overall.
*
*   The Toolset's version number is like libhelper, xxx.xx.x. 
*
***********************************************************************/
#define TOOLSET_VERS            "101.52.6"

#define TOOL_SECT               0
#define TOOL_SPLIT              0
#define TOOL_DUMP               1

#if TOOL_SECT
#   define TOOL_VERS            "1.0.0"
#   define TOOL_NAME            "macho-section"
#elif TOOL_SPLIT
#   define TOOL_VERS            "1.0.0"
#   define TOOL_NAME            "macho-split"
#elif TOOL_DUMP
#   define TOOL_VERS            "1.0.1"
#   define TOOL_NAME            "macho-dump"
#endif

#define FAT(p) ((*(unsigned int *)(p) & ~1) == 0xbebafeca)

#if TOOL_SPLIT
struct archs {
	size_t 	  size;
	char	 *buf;
	char	 *name;
};
#endif

/**
 *  Prints the banner at the top of the output when the program is
 *  executed.
 * 
 */
void banner ()
{
    printf ("-----------------------------------------------------\n");
    printf (" %s %s (macho-helper-%s) - Built " __TIMESTAMP__ "\n", TOOL_NAME, TOOL_VERS, TOOLSET_VERS);
    printf ("-----------------------------------------------------\n");
}


/**
 *  Prints detailed version information about the tool, toolset and 
 *  libhelper.
 * 
 */
void version ()
{
    printf ("MachO-Helper %s Version %s (macho-helper-%s)\n", TOOL_NAME, TOOL_VERS, TOOLSET_VERS);
    
    printf ("  Build Time:\t\t" __TIMESTAMP__ "\n");
    printf ("  Default Target:\t%s-%s\n", BUILD_TARGET, BUILD_ARCH);
    printf ("  Libhelper:\t\t%s\n", LIBHELPER_VERSION_LONG);
    printf ("  Toolset:\t\tmacho-helper-%s\n", TOOLSET_VERS);

}


/**
 *  Help menu. Most of this is common across the different tools.
 * 
 */
void help ()
{
    banner ();

    printf ("Usage: %s", TOOL_NAME);
#if TOOL_SECT
    printf (" FILE [segment] [section]\n\n");
#elif TOOL_SPLIT
    printf (" FILE\n\n");
#elif TOOL_DUMP
    printf (" FILE [start_addr] [end_addr | -s size]\n\n");
#endif

    printf ("Other Options:\n");
    printf ("  -h\tHelp Menu\n  -v\tVersion Info\n\n");
}


#if TOOL_SECT
/**
 *  Main flow for the macho-sect tool.
 * 
 */
int section_main (int argc, char *argv[])
{
    // Filename, segment and section opts
    char *filename = argv[1];
    char *segment = argv[2];
    char *section = argv[3];

    // Check they are all set
    if ( !filename || !segment || !section )
        goto SECT_ERROR;

    // Load the file as a Mach-O
    macho_t *macho = macho_load (filename);

    // Log that we are looking for the section
    printf ("Attempting to seperate %s.%s from %s\n", segment, section, filename);

    // Find the section
    mach_section_info_t *section_inf = mach_section_info_from_name (macho, segment, section);

    // Check if the section was valid
    if ( !section_inf )
        goto SECT_ERROR;

    // Load bytes from the section
    unsigned char *section_data = macho_load_bytes (macho, section_inf->size, section_inf->addr);

    // Setup the filename to write to
    size_t sout = strlen (segment) + strlen (section) + 6;
    char *outfile = malloc (sout);
    snprintf (outfile, sout, "%s.%s.data", segment, section);

    // Try to write the file
    int fd = file_write_new (outfile, section_data, section_inf->size);
    if ( !fd )
        goto SECT_ERROR;

    // Print success
    printf ("Wrote file to %s\n", outfile);

    // Return
    return fd;


SECT_ERROR:
    printf ("Unable to split %s.%s from %s\n", segment, section, filename);
    return -1;
}
#endif


#if TOOL_SPLIT
/**
 *  Main flow for the macho-split tool.
 * 
 */
int split_main (int argc, char *argv[])
{
    // Get the filename
    char *filename = argv[1];

    // Create a file and load it's data and size
    file_t *file = file_load (filename);
    
    uint32_t size = file->size;
    unsigned char *data = (unsigned char *) file_load_bytes (file, size, 0);

    // Ensure that it is a Universal/FAT file
    if ( !FAT (data) ) {
        printf ("File is not a Universal / FAT file.\n");
        goto SPLIT_ERROR;
    }

    // Try to detect the architecture contained within the file
    fat_header_info_t *fat_info = mach_universal_load (file);

    // Create a list of archs to write to a file
    HSList *arch_list = NULL;

    // Go through each arch and print the details like $ file ...
    for (int i = 0; i < h_slist_length (fat_info->archs); i++) {

        // Check the current arch
        struct fat_arch *arch = (struct fat_arch *) h_slist_nth_data (fat_info->archs, i);
        char *arch_name = NULL;

        // Check for arm64e
        ///////////////////////////////////
        //  Implement this in libhelper  //
        ///////////////////////////////////
        if ( arch->cputype == CPU_TYPE_ARM64 ) {
            arch_name = "arm64";
            if ( arch->cpusubtype == CPU_SUBTYPE_ARM64E )
                arch_name = "arm64e";
        } else {
            arch_name = mach_header_read_cpu_type (arch->cputype);
        }

        // Print arch info
        mach_header_t *hdr = malloc (sizeof (mach_header_t));
        memset (hdr, '\0', sizeof (mach_header_t));
        memcpy (hdr, data + arch->offset, sizeof (mach_header_t));

        if ( hdr->magic == MACH_MAGIC_64 || hdr->magic == MACH_CIGAM_64 )
       		printf ("\t%s (for architecture %s):\tMach-O 64-bit %s %s\n", file->path, arch_name, mach_header_read_file_type_short (hdr->filetype), arch_name);
        else if (hdr->magic == MACH_MAGIC_32 || hdr->magic == MACH_CIGAM_32)
            printf ("\t%s (for architecture %s):\tMach-O 32-bit %s %s\n", file->path, arch_name, mach_header_read_file_type_short (hdr->filetype), arch_name);
        else
            printf ("\tunknown: 0x%x\n", hdr->magic);

        // Add to the archs list
        struct archs *tmp = malloc (sizeof(struct archs));
		tmp->size = arch->size;
		tmp->name = arch_name;

        tmp->buf = malloc (arch->size);
		memset (tmp->buf, '\0', arch->size);
		memcpy (tmp->buf, data + arch->offset, arch->size);

		arch_list = h_slist_append (arch_list, tmp);
		arch_name = NULL;
    }

    // Now write each extracted arch to a file
	for (int i = 0; i < (int) h_slist_length (arch_list); i++) {
		struct archs *tmp = (struct archs *) h_slist_nth_data (arch_list, i);

		// Create filename
        char outname[25];
        snprintf (outname, 25, "macho-split%02d.%s", i, tmp->name);
		printf ("[*] %s", outname);

		FILE *fptr = fopen (outname, "wb");
		fwrite (tmp->buf, tmp->size, 1, fptr);
		fclose (fptr);

		printf (" \t...done\n");
	}

    return 0;

SPLIT_ERROR:
    printf ("Unable to split architectures from file %s\n", filename);
    return -1;
}
#endif


#if TOOL_DUMP
/**
 *  Main flow for the macho-dump tool.
 * 
 */
int dump_main (int argc, char *argv[])
{
    // If we are here, no options were given.
    char *filename = argv[1];
    uint32_t start = (uint32_t) strtol (argv[2], NULL, 0);
    uint32_t a2 = (uint32_t) strtol (argv[3], NULL, 0);
    uint32_t size = 0;

    macho_t *macho = macho_create ();
    unsigned char *dump = NULL;

    macho = macho_load (filename);
    uint32_t offset = macho->offset;
    printf ("Filename: %s\nOffset: 0x%x\n", macho->path, offset);
    
//    if (!strcmp (argv[3], "-s")) {
//        // use a size
//        size = a2;
//    } else {
//        size = a2 - start;
//    }

	size = a2;
    printf ("Size: %d\n", size);
    
    dump = malloc (size);
    
    memset (dump, '\0', size);
    memcpy (dump, macho->data + offset, size);

    if (dump == NULL) {
        errorf ("Something went wrong\n");
        return -1;
    }

    // hexdump
    uint8_t hex_off = 0;
    int lines = size / 8;
    int pos = 0;

    for (int i = 0; i < lines; i++) {
	printf ("%08x  ", hex_off);

	uint8_t ln[16];

	int j;
	for (j = 0; j < 16; j++) {
	    uint8_t byte = (uint8_t) dump[pos];
	    printf ("%02x ", byte);

	    if (j == 7) printf (" ");

	    pos++;
	    ln[j] = byte;
	}

	printf ("  |");

	for (int k = 0; k < 16; k++) {
	    if (ln[k] < 0x20 || ln[k] > 0x7e)
		    printf ( "." );
	    else
		    printf ( "%c", (char) ln[k]);
	}

	printf ("|\n");
	    hex_off += 0x10;
    }

    printf ("\n");

    
    // write to file
    printf ("Writing %d bytes to outfile.data\n", size);
    FILE *fptr = fopen ("outfile.data", "wb");
    fwrite (dump, sizeof (char), size, fptr);
    fclose (fptr);

    return 0;
}
#endif


/**
 *  These tools aren't meant to be big, I'd like to keep them all to
 *  one file.
 * 
 */
/*
int main (int argc, char *argv[])
{
    // If there is less than two args, don't bother
    if (argc < 2) {
        help ();
        return -1;
    }

    // Check for the -v or -v options
    for (int i = 1; i < argc; i++) {
        if (!strcmp (argv[i], "-h")) {
            help ();
            return 0;
        } else if (!strcmp (argv[i], "-v")) {
            version ();
            return 0;
     	}
    }

#if TOOL_DUMP || TOOL_SECT
    // Make sure no less than 4 args are given
    if (argc < 4) {
        help ();
        return -1;
    }
#endif

    // Print the banner and begin
    banner ();

    // Return code
    int ret = 0;

#if TOOL_SECT
    ret = section_main (argc, argv);
#elif TOOL_SPLIT
    ret = split_main (argc, argv);
#elif TOOL_DUMP
    ret = dump_main (argc, argv);
#endif

    // Return and exit
    return ret;
}
*/

