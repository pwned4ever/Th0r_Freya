#include <libhelper-macho/macho.h>
#include "libhelper-macho/macho-command-types.h"


void test1 (const char *path)
{
	macho_t *test = macho_load (path);

	mach_header_print_summary (test->header);


	// source version command
	mach_source_version_command_t *svc = mach_lc_find_source_version_cmd (test);
	printf ("svc: %s\n\n", mach_lc_source_version_string (svc));




	// build versionc command
	mach_command_info_t *cmdinfo = mach_lc_find_given_cmd (test, LC_BUILD_VERSION);
	mach_build_version_command_t *bvc_cmd = (mach_build_version_command_t *) macho_load_bytes (test, cmdinfo->lc->cmdsize,
																									cmdinfo->offset);

	mach_build_version_info_t *bvc_info = mach_lc_build_version_info (bvc_cmd, cmdinfo->offset, test);

    printf ("\t\tBuild Version:\t\tPlatform: %s,\tMinos: %s,\tSDK: %s\n", bvc_info->platform, bvc_info->minos, bvc_info->sdk);
    for (int a = 0; a < h_slist_length (bvc_info->tools); a++) {
    	struct build_tool_info_t *b = (struct build_tool_info_t *) h_slist_nth_data (bvc_info->tools, a);
        printf ("\t\t\t\t\t\t\tTool %d:\t %s (v%d.%d.%d)\n", a, b->tool, b->version >> 16, (b->version >> 8) & 0xf, b->version & 0xf);
    }


	// 


}

void test2 (const char *path)
{
	file_t *file = file_load (path);
	fat_header_t *fat = mach_universal_load (file);
}

int main (int argc, char *argv[])
{
	const char *path = argv[1];

	test1 (path);
	//test2 (path);


	return -1;
}
