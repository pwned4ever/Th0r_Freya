/*
 * libdpkg - Debian packaging suite library routines
 * pkg-files.h - primitives for pkg files handling
 *
 * Copyright © 2018 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_PKG_FILES_H
#define LIBDPKG_PKG_FILES_H

#include <dpkg/dpkg-db.h>
#include <dpkg/fsys.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup pkg-files Package files handling
 * @ingroup dpkg-public
 * @{
 */

void
pkg_files_blank(struct pkginfo *pkg);

struct fsys_namenode_list **
pkg_files_add_file(struct pkginfo *pkg, struct fsys_namenode *namenode,
                   struct fsys_namenode_list **file_tail);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_PKG_FILES_H */
