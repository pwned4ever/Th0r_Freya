#include <libhelper/libhelper.h>
#include <libhelper/strutils.h>

#include <libhelper-macho/macho.h>
#include <libhelper-macho/macho-header.h>
#include <libhelper-macho/macho-command.h>
#include <libhelper-macho/macho-segment.h>

int main (int argc, char *argv[])
{
    file_t *f = file_load (argv[1]);
    macho_t *macho = macho_load (f);

    /*char *__rdsk = NULL;
    char *__overlay = NULL;

    mach_segment_info_t *info = mach_segment_command_search (macho, "__TEXT");
    mach_segment_command_dump (info);

    mach_section_64_t *__rdsk_sect = mach_search_section (info, "__rdsk");
    mach_section_print (__rdsk_sect);
    __rdsk = file_load_bytes (f, __rdsk_sect->size, __rdsk_sect->offset);

    mach_section_64_t *__overlay_sect = mach_search_section (info, "__overlay");
    mach_section_print (__overlay_sect);
    __overlay = file_load_bytes (f, __overlay_sect->size, __overlay_sect->offset);*/

    mach_section_info_t *__rdsk = mach_load_section_data (macho, "__TEXT", "__rdsk");

    if (__rdsk) {
        printf ("[*] Loaded %d bytes from __TEXT.__rdsk\n", __rdsk->size);
        printf ("[*] Writing to file: out.raw...");

        FILE *fptr = fopen ("out.raw", "wb");
        fwrite (__rdsk->data, __rdsk->size, 1, fptr);
        fclose (fptr);

        printf ("done!\n");
    } else {
        printf ("[*] Error: Could not load __TEXT.__rdsk\n");
    }

    return 0;
}