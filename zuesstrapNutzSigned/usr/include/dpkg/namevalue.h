/*
 * libdpkg - Debian packaging suite library routines
 * namevalue.h - name value structure handling
 *
 * Copyright © 1994,1995 Ian Jackson <ijackson@chiark.greenend.org.uk>
 * Copyright © 2009-2012, 2015 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_NAMEVALUE_H
#define LIBDPKG_NAMEVALUE_H

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup namevalue Name/Value data
 * @ingroup dpkg-public
 * @{
 */

struct namevalue {
	const char *name;
	int value;
	int length;
};

#define NAMEVALUE_DEF(n, v) \
	[v] = { .name = n, .value = v, .length = sizeof(n) - 1 }

const struct namevalue *namevalue_find_by_name(const struct namevalue *head,
                                               const char *str);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_NAMEVALUE_H */
