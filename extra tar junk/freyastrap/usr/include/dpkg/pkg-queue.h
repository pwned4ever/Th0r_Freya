/*
 * libdpkg - Debian packaging suite library routines
 * pkg-queue.h - primitives for pkg queue handling
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

#ifndef DPKG_PKG_QUEUE_H
#define DPKG_PKG_QUEUE_H

#include <dpkg/macros.h>
#include <dpkg/pkg-list.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup pkg-queue Package queues
 * @ingroup dpkg-public
 * @{
 */

struct pkg_queue {
	struct pkg_list *head, *tail;
	int length;
};

/**
 * Constant initializer for a package queue.
 */
#define PKG_QUEUE_INIT \
	{ .head = NULL, .tail = NULL, .length = 0 }

/**
 * Compound literal for a package queue.
 */
#define PKG_QUEUE_OBJECT \
	(struct pkg_queue)PKG_QUEUE_INIT

void pkg_queue_init(struct pkg_queue *queue);
void pkg_queue_destroy(struct pkg_queue *queue);

int pkg_queue_is_empty(struct pkg_queue *queue);

struct pkg_list *pkg_queue_push(struct pkg_queue *queue, struct pkginfo *pkg);
struct pkginfo *pkg_queue_pop(struct pkg_queue *queue);

/** @} */

DPKG_END_DECLS

#endif /* DPKG_PKG_QUEUE_H */
