/*
 * libdpkg - Debian packaging suite library routines
 * pkg-show.h - primitives for pkg information display
 *
 * Copyright © 2010-2012 Guillem Jover <guillem@debian.org>
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

#ifndef DPKG_PKG_SHOW_H
#define DPKG_PKG_SHOW_H

#include <dpkg/macros.h>
#include <dpkg/dpkg-db.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup pkg-show Package information display
 * @ingroup dpkg-public
 * @{
 */

int pkg_sorter_by_nonambig_name_arch(const void *a, const void *b);

const char *pkgbin_synopsis(const struct pkginfo *pkg,
                            const struct pkgbin *pkgbin, int *len_ret);
int pkg_abbrev_want(const struct pkginfo *pkg);
int pkg_abbrev_status(const struct pkginfo *pkg);
int pkg_abbrev_eflag(const struct pkginfo *pkg);

/** @} */

DPKG_END_DECLS

#endif /* DPKG_PKG_SHOW_H */
