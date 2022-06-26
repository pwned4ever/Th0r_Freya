/*
 * libdpkg - Debian packaging suite library routines
 * atomic-file.h - atomic file helper functions
 *
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

#ifndef LIBDPKG_ATOMIC_FILE_H
#define LIBDPKG_ATOMIC_FILE_H

#include <stdio.h>

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup atomic-file Atomic file operations
 * @ingroup dpkg-internal
 * @{
 */

enum atomic_file_flags {
	ATOMIC_FILE_BACKUP	= DPKG_BIT(0),
};

struct atomic_file {
	enum atomic_file_flags flags;
	char *name;
	char *name_new;
	FILE *fp;
};

struct atomic_file *
atomic_file_new(const char *filename, enum atomic_file_flags flags);
void atomic_file_open(struct atomic_file *file);
void atomic_file_sync(struct atomic_file *file);
void atomic_file_close(struct atomic_file *file);
void atomic_file_commit(struct atomic_file *file);
void atomic_file_remove(struct atomic_file *file);
void atomic_file_free(struct atomic_file *file);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_ATOMIC_FILE_H */
