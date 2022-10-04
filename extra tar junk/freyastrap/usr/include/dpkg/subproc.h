/*
 * libdpkg - Debian packaging suite library routines
 * subproc.h - sub-process handling routines
 *
 * Copyright © 2008-2014 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_SUBPROC_H
#define LIBDPKG_SUBPROC_H

#include <sys/types.h>

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup subproc Sub-process handling
 * @ingroup dpkg-internal
 * @{
 */

enum subproc_flags {
	/** Default subprocess flags. */
	SUBPROC_NORMAL		= 0,
	/** Emit a warning instead of an error. */
	SUBPROC_WARN		= DPKG_BIT(0),
	/** Ignore SIGPIPE, and make it return 0. */
	SUBPROC_NOPIPE		= DPKG_BIT(1),
	/** Do not check the subprocess status. */
	SUBPROC_NOCHECK		= DPKG_BIT(2),
	/** Do not emit errors, just return the exit status. */
	SUBPROC_RETERROR	= DPKG_BIT(3),
	/** Do not emit errors, just return the signal number. */
	SUBPROC_RETSIGNO	= DPKG_BIT(3),
};

void subproc_signals_ignore(const char *name);
void subproc_signals_cleanup(int argc, void **argv);
void subproc_signals_restore(void);

pid_t subproc_fork(void);
int subproc_reap(pid_t pid, const char *desc, enum subproc_flags flags);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_SUBPROC_H */
