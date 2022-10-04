/*
 * libdpkg - Debian packaging suite library routines
 * trigdeferred.h - parsing of triggers/Unincorp (was …/Deferred)
 *
 * Copyright © 2007 Canonical, Ltd.
 *   written by Ian Jackson <ijackson@chiark.greenend.org.uk>
 * Copyright © 2008-2014 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_TRIGDEFERRED_H
#define LIBDPKG_TRIGDEFERRED_H

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup trigdeferred Trigger deferred file handling
 * @ingroup dpkg-internal
 * @{
 */

enum trigdef_update_flags {
	TDUF_NO_LOCK_OK		= DPKG_BIT(0),
	TDUF_WRITE		= DPKG_BIT(1),
	TDUF_NO_LOCK		= TDUF_NO_LOCK_OK | TDUF_WRITE,
	/** Should not be set unless TDUF_WRITE is. */
	TDUF_WRITE_IF_EMPTY	= DPKG_BIT(3),
	TDUF_WRITE_IF_ENOENT	= DPKG_BIT(4),
};

enum trigdef_update_status {
	TDUS_ERROR_NO_DIR = -1,
	TDUS_ERROR_EMPTY_DEFERRED = -2,
	TDUS_ERROR_NO_DEFERRED = -3,
	TDUS_NO_DEFERRED = 1,
	TDUS_OK = 2,
};

struct trigdefmeths {
	void (*trig_begin)(const char *trig);
	void (*package)(const char *awname);
	void (*trig_end)(void);
};

void trigdef_set_methods(const struct trigdefmeths *methods);

enum trigdef_update_status trigdef_update_start(enum trigdef_update_flags uf);
void trigdef_update_printf(const char *format, ...) DPKG_ATTR_PRINTF(1);
int trigdef_parse(void);
void trigdef_process_done(void);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_TRIGDEFERRED_H */
