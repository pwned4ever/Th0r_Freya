/*
 * libdpkg - Debian packaging suite library routines
 * program.h - dpkg-based program support
 *
 * Copyright © 2013 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_PROGRAM_H
#define LIBDPKG_PROGRAM_H

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup program Program support
 * @ingroup dpkg-public
 * @{
 */

void dpkg_program_init(const char *progname);
void dpkg_program_done(void);

/** @} */

DPKG_END_DECLS

#endif
