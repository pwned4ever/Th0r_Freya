/*
 * libdpkg - Debian packaging suite library routines
 * treewalk.h - directory tree walk support
 *
 * Copyright © 2013-2015 Guillem Jover <guillem@debian.org>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef LIBDPKG_TREEWALK_H
#define LIBDPKG_TREEWALK_H

#include <dpkg/macros.h>

#include <sys/stat.h>
#include <sys/types.h>

#include <stdbool.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup treewalk Directory tree walking
 * @ingroup dpkg-internal
 * @{
 */

enum treewalk_options {
	TREEWALK_NONE = 0,
	TREEWALK_FORCE_STAT = DPKG_BIT(0),
	TREEWALK_FOLLOW_LINKS = DPKG_BIT(1),
};

struct treenode;

typedef int treenode_visit_func(struct treenode *node);
typedef bool treenode_skip_func(struct treenode *node);
typedef int treenode_sort_func(struct treenode *node);

struct treewalk_funcs {
	treenode_visit_func *visit;
	treenode_sort_func *sort;
	treenode_skip_func *skip;
};

struct treeroot *
treewalk_open(const char *rootdir, enum treewalk_options options,
              struct treewalk_funcs *funcs);
struct treenode *
treewalk_node(struct treeroot *tree);
struct treenode *
treewalk_next(struct treeroot *tree);
void
treewalk_close(struct treeroot *tree);

int
treewalk(const char *rootdir, enum treewalk_options options,
         struct treewalk_funcs *funcs);

struct treenode *
treenode_get_parent(struct treenode *node);
const char *
treenode_get_name(struct treenode *node);
const char *
treenode_get_pathname(struct treenode *node);
const char *
treenode_get_virtname(struct treenode *node);
mode_t
treenode_get_mode(struct treenode *node);
struct stat *
treenode_get_stat(struct treenode *node);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_TREEWALK_H */
