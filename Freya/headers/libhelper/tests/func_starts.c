#include <libhelper/libhelper.h>
#include <libhelper-macho/macho.h>
#include <libhelper-macho/macho-command-types.h>

int main (int argc, char *argv[])
{

	//	This is a test so I'm not worrying about verifying the input, I trust
	//	myself to not fuck it up.
	//

	// Load the macho
	macho_t *macho = macho_load (argv[1]);

	// == testing ==

	mach_linkedit_data_command_t *func_starts_cmd = malloc (sizeof (mach_linkedit_data_command_t));
	mach_command_info_t *lc = malloc (sizeof (mach_command_info_t));

	for (int i = 0; i < macho->header->ncmds; i++) {
		mach_command_info_t *lc = (mach_command_info_t *) h_slist_nth_data (macho->lcmds, i);
		if (lc->lc->cmd == LC_FUNCTION_STARTS) {
			func_starts_cmd = (mach_linkedit_data_command_t *) macho_load_bytes (macho, lc->lc->cmdsize, lc->offset);
			break;
		}
	}

	if (!func_starts_cmd)
		return 0;

	printf ("func_starts: 0x%x (%d bytes)\n", func_starts_cmd->dataoff, func_starts_cmd->datasize);

	//uint32_t func_size = func_starts_cmd->datasize;
	//unsigned char *func_data = (unsigned char *) macho_load_bytes (macho, func_starts_cmd->dataoff, func_size);

	//if (!func_data)
	//	return;

	// This code is taken from dyldinfo.cpp:printFunctionStartsInfo()
	const uint8_t *infoStart = (uint8_t *) macho->data + func_starts_cmd->dataoff;
	const uint8_t *infoEnd = &infoStart[func_starts_cmd->datasize];

	uint64_t address = 0xfffffff007004000; //0x0;
	for (const uint8_t *p = infoStart; (*p != 0) && (p < infoEnd); ) {
		uint64_t delta = 0;
		uint64_t shift = 0;
		int more = 1;

		do {
			uint8_t byte = *p++;
			delta |= ((byte & 0x7f) << shift);
			shift += 7;
			if (byte < 0x80) {
				address += delta;

				//print_func_start_name (address);
				printf ("func: 0x%llx\n", address);

				more = 0;
			}
		} while (more);
	}

	return 1;
}