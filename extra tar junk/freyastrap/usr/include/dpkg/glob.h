/*
 * libdpkg - Debian packaging suite library routines
 * glob.h - file globing functions
 *
 * Copyright © 2009, 2010 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_GLOB_H
#define LIBDPKG_GLOB_H

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup glob File globbing
 * @ingroup dpkg-internal
 * @{
 */

struct glob_node {
	struct glob_node *next;
	char *pattern;
};

void glob_list_prepend(struct glob_node **list, char *pattern);
void glob_list_free(struct glob_node *head);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_GLOB_H */
