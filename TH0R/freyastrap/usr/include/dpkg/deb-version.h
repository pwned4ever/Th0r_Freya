/*
 * libdpkg - Debian packaging suite library routines
 * deb-version.h - deb format version handling routines
 *
 * Copyright © 2012-2013 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_DEB_VERSION_H
#define LIBDPKG_DEB_VERSION_H

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup deb-version .deb format version handling
 * @ingroup dpkg-public
 * @{
 */

/**
 * Data structure representing a .deb format version.
 */
struct deb_version {
	int major;
	int minor;
};

/**
 * Constant initializer for a deb_version.
 */
#define DEB_VERSION(X, Y) \
	{ .major = (X), .minor = (Y) }

/**
 * Compound literal for a deb_version.
 */
#define DEB_VERSION_OBJECT(X, Y) \
	(struct deb_version)DEB_VERSION(X, Y)

const char *deb_version_parse(struct deb_version *version, const char *str);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_DEB_VERSION_H */
