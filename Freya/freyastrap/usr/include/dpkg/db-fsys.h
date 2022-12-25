/*
 * libdpkg - Debian packaging suite library routines
 * db-fsys.h - management of database of files installed on system
 *
 * Copyright © 1995 Ian Jackson <ijackson@chiark.greenend.org.uk>
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

#ifndef LIBDPKG_DB_FSYS_H
#define LIBDPKG_DB_FSYS_H

#include <dpkg/file.h>
#include <dpkg/fsys.h>

/*
 * Data structure here is as follows:
 *
 * For each package we have a ‘struct fsys_namenode_list *’, the head of a list of
 * files in that package. They are in ‘forwards’ order. Each entry has a
 * pointer to the ‘struct fsys_namenode’.
 *
 * The struct fsys_namenodes are in a hash table, indexed by name.
 * (This hash table is not visible to callers.)
 *
 * Each fsys_namenode has a (possibly empty) list of ‘struct filepackage’,
 * giving a list of the packages listing that filename.
 *
 * When we read files contained info about a particular package we set the
 * ‘files’ member of the clientdata struct to the appropriate thing. When
 * not yet set the files pointer is made to point to ‘fileslist_uninited’
 * (this is available only internally, within filesdb.c - the published
 * interface is ensure_*_available).
 */

struct pkginfo;

void ensure_diversions(void);

enum statdb_parse_flags {
	STATDB_PARSE_NORMAL = 0,
	STATDB_PARSE_LAX = 1,
};

uid_t statdb_parse_uid(const char *str);
gid_t statdb_parse_gid(const char *str);
mode_t statdb_parse_mode(const char *str);
void ensure_statoverrides(enum statdb_parse_flags flags);

#define LISTFILE           "list"
#define HASHFILE           "md5sums"

void ensure_packagefiles_available(struct pkginfo *pkg);
void ensure_allinstfiles_available(void);
void ensure_allinstfiles_available_quiet(void);
void note_must_reread_files_inpackage(struct pkginfo *pkg);
void parse_filehash(struct pkginfo *pkg, struct pkgbin *pkgbin);
void write_filelist_except(struct pkginfo *pkg, struct pkgbin *pkgbin,
                           struct fsys_namenode_list *list, enum fsys_namenode_flags mask);
void write_filehash_except(struct pkginfo *pkg, struct pkgbin *pkgbin,
                           struct fsys_namenode_list *list, enum fsys_namenode_flags mask);

#endif /* LIBDPKG_DB_FSYS_H */
