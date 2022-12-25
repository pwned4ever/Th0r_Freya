/*
 * libdpkg - Debian packaging suite library routines
 * debug.h - debugging support
 *
 * Copyright © 2011 Guillem Jover <guillem@debian.org>
 *
 * This is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#ifndef LIBDPKG_DEBUG_H
#define LIBDPKG_DEBUG_H

#include <dpkg/macros.h>

#include <stdbool.h>
#include <stdio.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup debug Debugging
 * @ingroup dpkg-internal
 * @{
 */

/*
 * XXX: We do not use DPKG_BIT() here, because the octal values are part
 * of the current output interface.
 */
enum debugflags {
	dbg_general = 01,
	dbg_scripts = 02,
	dbg_eachfile = 010,
	dbg_eachfiledetail = 0100,
	dbg_conff = 020,
	dbg_conffdetail = 0200,
	dbg_depcon = 040,
	dbg_depcondetail = 0400,
	dbg_veryverbose = 01000,
	dbg_stupidlyverbose = 02000,
	dbg_triggers = 010000,
	dbg_triggersdetail = 020000,
	dbg_triggersstupid = 040000,
};

void debug_set_output(FILE *output, const char *filename);
void debug_set_mask(int mask);
bool debug_has_flag(int flag);
void debug(int flag, const char *fmt, ...) DPKG_ATTR_PRINTF(2);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_DEBUG_H */
