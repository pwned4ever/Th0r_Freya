/*
 * libdpkg - Debian packaging suite library routines
 * dir.h - directory handling routines
 *
 * Copyright © 2010 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_DIR_H
#define LIBDPKG_DIR_H

#include <dpkg/macros.h>

#include <dirent.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup dir Directory handling
 * @ingroup dpkg-internal
 * @{
 */

void dir_sync_path(const char *path);
void dir_sync_path_parent(const char *path);
void dir_sync_contents(const char *path);
bool dir_sign_file(const char *file);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_DIR_H */
