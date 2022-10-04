/*
 * libdpkg - Debian packaging suite library routines
 * fsys.h - filesystem nodes hash table
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

#ifndef LIBDPKG_FSYS_H
#define LIBDPKG_FSYS_H

#include <stdio.h>

#include <dpkg/file.h>

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

/**
 * Flags to fsys_hash_find_node().
 */
enum fsys_hash_find_flags {
	/** Do not need to copy filename. */
	FHFF_NOCOPY			= DPKG_BIT(0),
	/** The find function might return NULL. */
	FHFF_NONE			= DPKG_BIT(1),
};

enum fsys_namenode_flags {
	/** In the newconffiles list. */
	FNNF_NEW_CONFF			= DPKG_BIT(0),
	/** In the new filesystem archive. */
	FNNF_NEW_INARCHIVE		= DPKG_BIT(1),
	/** In the old package's conffiles list. */
	FNNF_OLD_CONFF			= DPKG_BIT(2),
	/** Obsolete conffile. */
	FNNF_OBS_CONFF			= DPKG_BIT(3),
	/** Must remove from other packages' lists. */
	FNNF_ELIDE_OTHER_LISTS		= DPKG_BIT(4),
	/** >= 1 instance is a dir, cannot rename over. */
	FNNF_NO_ATOMIC_OVERWRITE	= DPKG_BIT(5),
	/** New file has been placed on the disk. */
	FNNF_PLACED_ON_DISK		= DPKG_BIT(6),
	FNNF_DEFERRED_FSYNC		= DPKG_BIT(7),
	FNNF_DEFERRED_RENAME		= DPKG_BIT(8),
	/** Path being filtered. */
	FNNF_FILTERED			= DPKG_BIT(9),
};

/**
 * Stores information to uniquely identify an on-disk file.
 */
struct file_ondisk_id {
	dev_t id_dev;
	ino_t id_ino;
};

struct fsys_namenode {
	struct fsys_namenode *next;
	const char *name;
	struct pkg_list *packages;
	struct fsys_diversion *divert;

	/** We allow the administrator to override the owner, group and mode
	 * of a file. If such an override is present we use that instead of
	 * the stat information stored in the archive.
	 *
	 * This functionality used to be in the suidmanager package. */
	struct file_stat *statoverride;

	struct trigfileint *trig_interested;

	/*
	 * Fields from here on are used by archives.c &c, and cleared by
	 * fsys_hash_init().
	 */

	/** Set to zero when a new node is created. */
	enum fsys_namenode_flags flags;

	/** Valid iff this namenode is in the newconffiles list. */
	const char *oldhash;

	/** Valid iff the file was unpacked and hashed on this run. */
	const char *newhash;

	struct file_ondisk_id *file_ondisk_id;
};

struct fsys_namenode_list {
	struct fsys_namenode_list *next;
	struct fsys_namenode *namenode;
};

/**
 * Queue of fsys_namenode entries.
 */
struct fsys_namenode_queue {
	struct fsys_namenode_list *head, **tail;
};

/**
 * When we deal with an ‘overridden’ file, every package except the
 * overriding one is considered to contain the other file instead. Both
 * files have entries in the filesdb database, and they refer to each other
 * via these diversion structures.
 *
 * The contested filename's fsys_namenode has an diversion entry with
 * useinstead set to point to the redirected filename's fsys_namenode; the
 * redirected fsys_namenode has camefrom set to the contested fsys_namenode.
 * Both sides' diversion entries will have pkg set to the package (if any)
 * which is allowed to use the contended filename.
 *
 * Packages that contain either version of the file will all refer to the
 * contested fsys_namenode in their per-file package lists (both in core and
 * on disk). References are redirected to the other fsys_namenode's filename
 * where appropriate.
 */
struct fsys_diversion {
	struct fsys_namenode *useinstead;
	struct fsys_namenode *camefrom;
	struct pkgset *pkgset;

	/** The ‘contested’ halves are in this list for easy cleanup. */
	struct fsys_diversion *next;
};

struct fsys_node_pkgs_iter;
struct fsys_node_pkgs_iter *
fsys_node_pkgs_iter_new(struct fsys_namenode *fnn);
struct pkginfo *
fsys_node_pkgs_iter_next(struct fsys_node_pkgs_iter *iter);
void
fsys_node_pkgs_iter_free(struct fsys_node_pkgs_iter *iter);

void
fsys_hash_init(void);
void
fsys_hash_reset(void);
void
fsys_hash_report(FILE *file);
int
fsys_hash_entries(void);

struct fsys_hash_iter;
struct fsys_hash_iter *
fsys_hash_iter_new(void);
struct fsys_namenode *
fsys_hash_iter_next(struct fsys_hash_iter *iter);
void
fsys_hash_iter_free(struct fsys_hash_iter *iter);

struct fsys_namenode *
fsys_hash_find_node(const char *filename, enum fsys_hash_find_flags flags);

struct fsys_hash_rev_iter {
	struct fsys_namenode_list *todo;
};

void
fsys_hash_rev_iter_init(struct fsys_hash_rev_iter *iter,
                        struct fsys_namenode_list *files);
struct fsys_namenode *
fsys_hash_rev_iter_next(struct fsys_hash_rev_iter *iter);
void
fsys_hash_rev_iter_abort(struct fsys_hash_rev_iter *iter);

const char *dpkg_fsys_set_dir(const char *dir);
const char *dpkg_fsys_get_dir(void);
char *dpkg_fsys_get_path(const char *pathpart);

#endif /* LIBDPKG_FSYS_H */
