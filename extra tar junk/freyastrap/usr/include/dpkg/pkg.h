/*
 * libdpkg - Debian packaging suite library routines
 * pkg.h - primitives for pkg handling
 *
 * Copyright © 2009,2011-2012 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_PKG_H
#define LIBDPKG_PKG_H

#include <dpkg/macros.h>
#include <dpkg/dpkg-db.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup pkg Package handling primitives
 * @ingroup dpkg-public
 * @{
 */

typedef int pkg_sorter_func(const void *a, const void *b);

void pkgset_link_pkg(struct pkgset *set, struct pkginfo *pkg);

void pkg_set_status(struct pkginfo *pkg, enum pkgstatus status);
void pkg_set_eflags(struct pkginfo *pkg, enum pkgeflag eflag);
void pkg_clear_eflags(struct pkginfo *pkg, enum pkgeflag eflag);
void pkg_reset_eflags(struct pkginfo *pkg);
void pkg_copy_eflags(struct pkginfo *pkg_dst, struct pkginfo *pkg_src);
void pkg_set_want(struct pkginfo *pkg, enum pkgwant want);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_PKG_H */
