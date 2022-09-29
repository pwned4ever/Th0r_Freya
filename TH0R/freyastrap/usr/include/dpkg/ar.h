/*
 * libdpkg - Debian packaging suite library routines
 * ar.h - primitives for ar handling
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

#ifndef LIBDPKG_AR_H
#define LIBDPKG_AR_H

#include <sys/types.h>

#include <stdbool.h>
#include <ar.h>

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup ar Ar archive handling
 * @ingroup dpkg-public
 * @{
 */

#define DPKG_AR_MAGIC "!<arch>\n"
#define DPKG_AR_FMAG  "`\n"

/**
 * An on-disk archive header.
 */
struct dpkg_ar_hdr {
	char ar_name[16];	   /* Member file name, sometimes / terminated. */
	char ar_date[12];	   /* File date, decimal seconds since Epoch.  */
	char ar_uid[6], ar_gid[6]; /* User and group IDs, in ASCII decimal.  */
	char ar_mode[8];	   /* File mode, in ASCII octal.  */
	char ar_size[10];	   /* File size, in ASCII decimal.  */
	char ar_fmag[2];
};

/**
 * An archive (Unix ar) file.
 */
struct dpkg_ar {
	const char *name;
	mode_t mode;
	time_t time;
	off_t size;
	int fd;
};

/**
 * In-memory archive member information.
 */
struct dpkg_ar_member {
	struct dpkg_ar_member *next;
	const char *name;
	off_t offset;
	off_t size;
	time_t time;
	mode_t mode;
	uid_t uid;
	gid_t gid;
};

struct dpkg_ar *
dpkg_ar_fdopen(const char *filename, int fd);
struct dpkg_ar *dpkg_ar_open(const char *filename);
struct dpkg_ar *dpkg_ar_create(const char *filename, mode_t mode);
void dpkg_ar_set_mtime(struct dpkg_ar *ar, time_t mtime);
void dpkg_ar_close(struct dpkg_ar *ar);

void dpkg_ar_normalize_name(struct dpkg_ar_hdr *arh);
bool dpkg_ar_member_is_illegal(struct dpkg_ar_hdr *arh);

void dpkg_ar_put_magic(struct dpkg_ar *ar);
void dpkg_ar_member_put_header(struct dpkg_ar *ar,
                               struct dpkg_ar_member *member);
void dpkg_ar_member_put_file(struct dpkg_ar *ar, const char *name,
                             int fd, off_t size);
void dpkg_ar_member_put_mem(struct dpkg_ar *ar, const char *name,
                            const void *data, size_t size);
off_t dpkg_ar_member_get_size(struct dpkg_ar *ar, struct dpkg_ar_hdr *arh);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_AR_H */
