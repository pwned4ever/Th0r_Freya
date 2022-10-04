/*
 * libdpkg - Debian packaging suite library routines
 * progname.h - program name handling functions
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

#ifndef LIBDPKG_PROGNAME_H
#define LIBDPKG_PROGNAME_H

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup progname Program name handling
 * @ingroup dpkg-public
 * @{
 */

void dpkg_set_progname(const char *name);
const char *dpkg_get_progname(void);

/** @} */

DPKG_END_DECLS

#endif
