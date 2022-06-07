/*
 * platform.h
 * Brandon Azad
 */
#ifndef OOB_TIMESTAMP__PLATFORM__H_
#define OOB_TIMESTAMP__PLATFORM__H_

#include <stdbool.h>
#include <stddef.h>
#include <mach/machine.h>

#ifdef PLATFORM_EXTERN
#define extern PLATFORM_EXTERN
#endif

/*
 * platform
 *
 * Description:
 * 	Basic information about the platform.
 */
struct platform {
	// The name of the platform, e.g. iPhone11,8.
	const char machine[32];
	// The version of the OS build, e.g. 16C50.
	const char osversion[32];
	// The platform CPU type.
	cpu_type_t cpu_type;
	// The platform CPU subtype.
	cpu_subtype_t cpu_subtype;
	// The number of physical CPU cores.
	unsigned physical_cpu;
	// The number of logical CPU cores.
	unsigned logical_cpu;
	// The kernel page size.
	size_t page_size;
	// The size of physical memory on the device.
	size_t memory_size;
};
extern struct platform platform;

/*
 * page_size
 *
 * Description:
 * 	The kernel page size on this platform, made available globally for convenience.
 */
extern size_t page_size;

#undef extern

#endif
