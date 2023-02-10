//===------------------------------ main.c ---------------------------------===//
//
//                                Img4Helper
//
// 	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
// 	but WITHOUT ANY WARRANTY; without even the implied warranty of
// 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// 	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
// 	along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//
//  Copyright (C) 2019, Is This On?, @h3adsh0tzz
//  me@h3adsh0tzz.com.
//
//
//===-----------------------------------------------------------------------===//

#include <libhelper/libhelper.h>
#include <libhelper-img4/sep.h>

#include "version.h"
#include "img4.h"


#define HELP_MENU_FLAG__UNDEF_OPT   0x1


/**
 * 	Img4helper version header.
 * 
 */
void version ()
{
#if IMG4HELPER_DEBUG
    debugf ("%s\n", libhelper_version_string());
#endif

    /* Print banner */
	printf ("-----------------------------------------------------\n");
	printf ("Img4Helper %s - Built " __TIMESTAMP__ "\n", IMG4HELPER_VERSION_NUMBER);
	printf ("-----------------------------------------------------\n\n");
}


/**
 * 	Img4helper detailed version output. This includes Build Target
 * 	and libhelper version.
 * 
 */
/*void print_version_detail ()
{
    printf ("h3adsh0tzz Img4Helper Version %s~%s (%s)\n", IMG4HELPER_VERSION_NUMBER, IMG4HELPER_VERSION_TAG, LIBHELPER_VERSION_LONG);
    printf ("\tBuild Time:\t\t" __TIMESTAMP__ "\n");

    printf ("\tDefault Target:\t\t%s-%s\n", BUILD_TARGET, BUILD_ARCH);
    printf ("\tBuild Type: \t\t%s\n", IMG4HELPER_VERSION_TAG);
    printf ("\tBuilt With: \t\t%s\n", LIBHELPER_VERSION_LONG);
}

*/
/**
 * 
 */
void help (int flag, char *undef_opt)
{
    version ();

    if (flag == HELP_MENU_FLAG__UNDEF_OPT)
        warningf ("Undefined Option: %s\n\n", undef_opt);

    printf ("Usage: img4helper [options] FILE\n\n");

	printf ("Application Options:\n");
	printf ("  -h, --help\t\t\tPrint everything from the Image4 file.\n");
	printf ("  -v, --version\t\t\tView Img4helper build info.\n\n");

	printf ("Image4:\n");
	printf ("  -a, --print-all\t\tPrint everything from the Image4 file.\n");
  	printf ("  -i, --print-im4p\t\tPrint everything from the im4p (Providing there is one).\n");
  	printf ("  -m, --print-im4m\t\tPrint everything from the im4m (Providing there is one).\n");
  	printf ("  -r, --print-im4r\t\tPrint everything from the im4r (Providing there is one).\n\n");

	printf ("Extract/Decrypt/Decompress:\n");
	printf ("  -e, --extract         Extract a payload from an IMG4 or IM4P (Use with --ivkey and --outfile) [Opt: -no-decomp].\n");
  	printf ("  -s, --extract-sep     Extract and split a Secure Enclave (SEPOS).\n");
  	printf ("  -k, --ivkey           Specify an IVKEY pair to decrypt an im4p (Use with --extract and --outfile).\n\n");
  	//printf ("  -o, --outfile         Specify a file to write output too (Default outfile.raw, use with --extract\n\n");

	printf ("HTool Preview:\n");
	printf ("  -x, --xnu             Analyse an XNU KernelCache.\n");
  	printf ("  -d, --devtree         Analyse a Device Tree.\n\n");

}


/**
 * 
 */
int check_cmd_args (char *arg1, char *arg2, char *in)
{
	if (!strcmp (arg1, in) || !strcmp (arg2, in)) return 1;
	else return 0;
}


/**
 * 
 * 
 */
int main (int argc, char *argv[])
{
    if (argc < 2) {
        help (0, NULL); 
        return 0;
    }

	// cmd opts
	char *filename = NULL;
	char *ivkey = NULL;
	int opt_filename = 0;
	int opt_img4_print_all = 0, opt_img4_print_im4p = 0, opt_img4_print_im4m = 0, opt_img4_print_im4r = 0;
	int opt_edd_extract = 0, opt_edd_extract_sep = 0, opt_edd_dec = 0, opt_no_decomp = 0;
	int opt_htool_kernel = 0, opt_htool_devtree = 0;

	// The file_t struct for the loaded file
	file_t *file = file_create ();

	// Check for cmd args
	int checked = argc - 1;
	for (int i = 1; i < argc; i++) {
		char *opt = argv[i];

		// Check for --help and --version
		if (check_cmd_args ("-h", "--help", opt)) { help (0, NULL); return 0; }
		//if (check_cmd_args ("-v", "--version", opt)) { print_version_detail (); return 0; }

		// Check for Image4 commands
		if (check_cmd_args ("-a", "--print-all", opt)) { opt_img4_print_all = 1; checked++; continue; }
		if (check_cmd_args ("-i", "--print-im4p", opt)) { opt_img4_print_im4p = 1; checked++; continue; }
		if (check_cmd_args ("-m", "--print-im4m", opt)) { opt_img4_print_im4m = 1; checked++; continue; }
		if (check_cmd_args ("-r", "--print-im4r", opt)) { opt_img4_print_im4r = 1; checked++; continue; }

		// Check for Extract/Decrypt/Decompress (EDD) commands
		if (check_cmd_args ("-s", "--extract-sep", opt )) { opt_edd_extract_sep = 1; checked++; continue; }
		if (check_cmd_args ("-e", "--extract", opt )) { opt_edd_extract = 1; checked++; continue; }
		if (check_cmd_args ("", "-no-decomp", opt )) { opt_no_decomp = 1; checked++; continue; }

		if (check_cmd_args ("-k", "--ivkey", opt )) { 

			// Check if they specified a key
			i++;
			char *tmp = argv[i];
			ivkey = (tmp[0] != '-') ? tmp : NULL;
#if IMG4HELPER_DEBUG
			debugf ("tmp: %s, ivkey: %s\n", tmp, ivkey);
#endif

			if (ivkey) {
				opt_edd_dec = 1;
				checked += 2;
				continue;
			} else {
				errorf ("No encryption key specified with %s\n", opt);
				exit (0);
			}
		}

		// HTool Preview commands
		if (check_cmd_args ("-x", "--xnu", opt )) { opt_htool_kernel = 1; continue; }
		if (check_cmd_args ("-d", "--devtree", opt )) { opt_htool_devtree = 1; continue; }

		// Try to load the file
		if (opt[0] != '-' && !opt_filename) {
			opt_filename = 1;
			filename = opt;
#if IMG4HELPER_DEBUG
			debugf ("Guessing %s is a file?\n", opt);
#endif
			continue;
		}

		// Show help because nothing seems to have matched
		help (1, argv[i]);
		return 0;
	}

	/**
	 * 	HTool Preview Options:
	 * 	
	 * 	HTool is my version of JTool. It is closed source and still in development,
	 * 	but I'm adding a couple functions here to demonstrate. I'll add these overtime.
	 * 
	 */
	if (opt_htool_devtree || opt_htool_kernel) {
		printf ("These options are part of the HTool preview, they will be added soon.\n");
		exit (0);
	}


	// Act on each command line option. Attempt to load the file,
	if (opt_filename && filename) {
		if (!opt_edd_extract_sep) {

			// load the file
			file = file_load (filename);
#if IMG4HELPER_DEBUG
			debugf ("File %s loaded\n", filename);
#endif
		}
	} else {
		// There is no file given, so we cannot continue
        errorf ("No filename specifed, cannot continue.\n");
        exit (0);
	}

	// Check for the -a, --print-all command
	if (opt_img4_print_all) {
		img4_print_with_type (IMG4_TYPE_ALL, filename);
	}

	// Check for the -i, --print-im4p command
	if (opt_img4_print_im4p) {
		img4_print_with_type (IMG4_TYPE_IM4P, filename);
	}

	// Check for the -m, --print-im4m command
	if (opt_img4_print_im4m) {
		img4_print_with_type (IMG4_TYPE_IM4M, filename);
	}

	// Check for the -r, --print-im4r command
	if (opt_img4_print_im4r) {
		img4_print_with_type (IMG4_TYPE_IM4R, filename);
	}

	// Check for the -e, --extract command
	if (opt_edd_extract) {

#if IMG4HELPER_DEBUG
		// Check for the -no-decomp flag
		printf ("-no-decomp: %d\n", opt_no_decomp);
#endif

		// Check for the -k, --ivkey command
		if (opt_edd_dec) {
#if IMG4HELPER_DEBUG
			debugf ("wow that actually worked\n");
#endif
			img4_extract_im4p (filename, "outfile.raw", ivkey, opt_no_decomp);
		} else {
			img4_extract_im4p (filename, "outfile.raw", NULL, opt_no_decomp);
		}
	}

	// Check for the -s, --extract-sep command
	if (opt_edd_extract_sep) {
		// Check for the -k, --ivkey command
		if (opt_edd_dec) {
#if IMG4HELPER_DEBUG
			debugf ("wow that actually worked (sep)\n");
#endif
			img4_extract_im4p (filename, ".sep-img4helper-decrytped", ivkey, 0);
			filename = ".sep-img4helper-decrytped";
		}
		sep_split_init (filename);
	}


	return 0;
}
