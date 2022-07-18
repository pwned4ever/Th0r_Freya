/*
 * libdpkg - Debian packaging suite library routines
 * pkg-spec.h - primitives for pkg specifier handling
 *
 * Copyright © 2011 Linaro Limited
 * Copyright © 2011 Raphaël Hertzog <hertzog@debian.org>
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

#ifndef LIBDPKG_PKG_SPEC_H
#define LIBDPKG_PKG_SPEC_H

#include <stdbool.h>

#include <dpkg/macros.h>
#include <dpkg/dpkg-db.h>
#include <dpkg/error.h>
#include <dpkg/arch.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup pkg-spec Package specifiers
 * @ingroup dpkg-public
 * @{
 */

enum pkg_spec_flags {
	/** Recognize glob patterns. */
	PKG_SPEC_PATTERNS	= DPKG_BIT(0),

	/* How to consider the lack of an arch qualifier. */
	PKG_SPEC_ARCH_SINGLE	= DPKG_BIT(8),
	PKG_SPEC_ARCH_WILDCARD	= DPKG_BIT(9),
	PKG_SPEC_ARCH_MASK	= 0xff00,
};

struct pkg_spec {
	char *name;
	const struct dpkg_arch *arch;

	enum pkg_spec_flags flags;

	/* Members below are private state. */

	bool name_is_pattern;
	bool arch_is_pattern;

	/** Used for the pkg_db iterator. */
	struct pkg_hash_iter *pkg_iter;
	/** Used for the pkgset iterator. */
	struct pkginfo *pkg_next;
};

void pkg_spec_init(struct pkg_spec *ps, enum pkg_spec_flags flags);
void pkg_spec_destroy(struct pkg_spec *ps);

const char *pkg_spec_is_illegal(struct pkg_spec *ps);

const char *pkg_spec_set(struct pkg_spec *ps,
                         const char *pkgname, const char *archname);
const char *pkg_spec_parse(struct pkg_spec *ps, const char *str);
bool pkg_spec_match_pkg(struct pkg_spec *ps,
                        struct pkginfo *pkg, struct pkgbin *pkgbin);

struct pkginfo *pkg_spec_parse_pkg(const char *str, struct dpkg_error *err);
struct pkginfo *pkg_spec_find_pkg(const char *pkgname, const char *archname,
                                  struct dpkg_error *err);

void pkg_spec_iter_init(struct pkg_spec *ps);
struct pkginfo *pkg_spec_iter_next_pkg(struct pkg_spec *ps);
void pkg_spec_iter_destroy(struct pkg_spec *ps);

/** @} */

DPKG_END_DECLS

#endif
