/*
 * libdpkg - Debian packaging suite library routines
 * triglib.h - declarations for trigger handling
 *
 * Copyright © 2007 Canonical, Ltd.
 *   written by Ian Jackson <ijackson@chiark.greenend.org.uk>
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

#ifndef LIBDPKG_TRIGLIB_H
#define LIBDPKG_TRIGLIB_H

#include <dpkg/macros.h>
#include <dpkg/dpkg-db.h>
#include <dpkg/fsys.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup triglib Trigger handling
 * @ingroup dpkg-internal
 * @{
 */

/*
 * Hooks for more sophisticated processing in dpkg proper.
 *
 * We do things like this so we can get most of the trigger tracking
 * in dpkg-query, dselect, and so on, but avoid the transitional
 * processing and deferred trigproc queue management other than when
 * we're actually doing real package management work.
 */

const char *trig_name_is_illegal(const char *p);

enum trig_options {
	TRIG_AWAIT,
	TRIG_NOAWAIT,
};

struct trigfileint {
	struct pkginfo *pkg;
	struct pkgbin *pkgbin;
	struct fsys_namenode *fnn;
	enum trig_options options;
	struct trigfileint *samefile_next;
	struct {
		struct trigfileint *next, *prev;
	} inoverall;
};

/**
 * The first two hooks are normally NULL.
 * If non-NULL, we're dpkg proper and we might need to invent trigger
 * activations as the first run of a triggers-supporting dpkg.
 */
struct trig_hooks {
	void (*enqueue_deferred)(struct pkginfo *pend);
	void (*transitional_activate)(enum modstatdb_rw cstatus);

	struct fsys_namenode *(*namenode_find)(const char *filename, bool nonew);
	struct trigfileint **(*namenode_interested)(struct fsys_namenode *fnn);

	/** Returns a pointer from nfmalloc. */
	const char *(*namenode_name)(struct fsys_namenode *fnn);
};

#define TRIGHOOKS_DEFINE_NAMENODE_ACCESSORS				 \
  static struct fsys_namenode *th_nn_find(const char *name, bool nonew)	 \
    { return fsys_hash_find_node(name, nonew ? FHFF_NONE : 0); }		 \
  static struct trigfileint **th_nn_interested(struct fsys_namenode *fnn) \
    { return &fnn->trig_interested; }					 \
  static const char *th_nn_name(struct fsys_namenode *fnn)		 \
    { return fnn->name; }

void trig_override_hooks(const struct trig_hooks *hooks);

void trig_file_activate_byname(const char *trig, struct pkginfo *aw);
void trig_file_activate(struct fsys_namenode *trig, struct pkginfo *aw);
void trig_path_activate(struct fsys_namenode *trig, struct pkginfo *aw);

bool trig_note_pend_core(struct pkginfo *pend, const char *trig /*not copied!*/);
bool trig_note_pend(struct pkginfo *pend, const char *trig /*not copied!*/);
bool trig_note_aw(struct pkginfo *pend, struct pkginfo *aw);
void trig_clear_awaiters(struct pkginfo *notpend);

typedef void trig_awaited_pend_foreach_func(struct pkginfo *pkg);

void trig_awaited_pend_enqueue(struct pkginfo *pend);
void trig_awaited_pend_foreach(trig_awaited_pend_foreach_func *func);
void trig_awaited_pend_free(void);

void trig_fixup_awaiters(enum modstatdb_rw cstatus);

void trig_file_interests_ensure(void);
void trig_file_interests_save(void);

typedef void trig_parse_cicb(const char *trig, struct pkginfo *pkg,
                             struct pkgbin *pkgbin, enum trig_options to);
void trig_cicb_interest_delete(const char *trig, struct pkginfo *pkg,
                             struct pkgbin *pkgbin, enum trig_options to);
void trig_cicb_interest_add(const char *trig, struct pkginfo *pkg,
                             struct pkgbin *pkgbin, enum trig_options to);
void trig_cicb_statuschange_activate(const char *trig, struct pkginfo *pkg,
                             struct pkgbin *pkgbin, enum trig_options to);
void trig_parse_ci(const char *file, trig_parse_cicb *interest,
                   trig_parse_cicb *activate, struct pkginfo *pkg,
                   struct pkgbin *pkgbin);

void trig_incorporate(enum modstatdb_rw cstatus);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_TRIGLIB_H */
