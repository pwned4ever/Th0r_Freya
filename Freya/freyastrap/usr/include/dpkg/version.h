/*
 * libdpkg - Debian packaging suite library routines
 * version.h - version handling routines
 *
 * Copyright © 1994,1995 Ian Jackson <ijackson@chiark.greenend.org.uk>
 * Copyright © 2011-2014 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_VERSION_H
#define LIBDPKG_VERSION_H

#include <stdbool.h>

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup version Version handling
 * @ingroup dpkg-public
 * @{
 */

/**
 * Data structure representing a Debian version.
 *
 * @see deb-version(5)
 */
struct dpkg_version {
	/** The epoch. It will be zero if no epoch is present. */
	unsigned int epoch;
	/** The upstream part of the version. */
	const char *version;
	/** The Debian revision part of the version. */
	const char *revision;
};

/**
 * Compound literal for a dpkg_version.
 */
#define DPKG_VERSION_OBJECT(e, v, r) \
	(struct dpkg_version){ .epoch = (e), .version = (v), .revision = (r) }

/**
 * Enum constants for the supported relation operations that can be done
 * on Debian versions.
 */
enum dpkg_relation {
	/** The “none” relation, sentinel value. */
	DPKG_RELATION_NONE	= 0,
	/** Equality relation (‘=’). */
	DPKG_RELATION_EQ	= DPKG_BIT(0),
	/** Less than relation (‘<<’). */
	DPKG_RELATION_LT	= DPKG_BIT(1),
	/** Less than or equal to relation (‘<=’). */
	DPKG_RELATION_LE	= DPKG_RELATION_LT | DPKG_RELATION_EQ,
	/** Greater than relation (‘>>’). */
	DPKG_RELATION_GT	= DPKG_BIT(2),
	/** Greater than or equal to relation (‘>=’). */
	DPKG_RELATION_GE	= DPKG_RELATION_GT | DPKG_RELATION_EQ,
};

void dpkg_version_blank(struct dpkg_version *version);
bool dpkg_version_is_informative(const struct dpkg_version *version);
int dpkg_version_compare(const struct dpkg_version *a,
                         const struct dpkg_version *b);
bool dpkg_version_relate(const struct dpkg_version *a,
                         enum dpkg_relation rel,
                         const struct dpkg_version *b);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_VERSION_H */
