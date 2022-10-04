/*
 * libdpkg - Debian packaging suite library routines
 * pkg-list.h - primitives for pkg linked list handling
 *
 * Copyright © 2009 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_PKG_LIST_H
#define LIBDPKG_PKG_LIST_H

#include <dpkg/dpkg-db.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup pkg-list Package linked lists
 * @ingroup dpkg-public
 * @{
 */

struct pkg_list {
	struct pkg_list *next;
	struct pkginfo *pkg;
};

struct pkg_list *pkg_list_new(struct pkginfo *pkg, struct pkg_list *next);
void pkg_list_free(struct pkg_list *head);
void pkg_list_prepend(struct pkg_list **head, struct pkginfo *pkg);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_PKG_LIST_H */
