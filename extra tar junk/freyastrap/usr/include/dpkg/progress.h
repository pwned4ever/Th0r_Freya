/*
 * libdpkg - Debian packaging suite library routines
 * progress.h - generic progress reporting
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

#ifndef LIBDPKG_PROGRESS_H
#define LIBDPKG_PROGRESS_H

#include <stdbool.h>

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup progress Progress reporting
 * @ingroup dpkg-internal
 * @{
 */

struct progress {
	const char *text;

	int max;
	int cur;
	int last_percent;

	bool on_tty;
};

void progress_init(struct progress *progress, const char *text, int max);
void progress_step(struct progress *progress);
void progress_done(struct progress *progress);

/** @} */

DPKG_END_DECLS

#endif
