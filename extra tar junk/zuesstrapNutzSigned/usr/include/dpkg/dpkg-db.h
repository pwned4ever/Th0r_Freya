/*
 * libdpkg - Debian packaging suite library routines
 * dpkg-db.h - declarations for in-core package database management
 *
 * Copyright © 1994,1995 Ian Jackson <ijackson@chiark.greenend.org.uk>
 * Copyright © 2000,2001 Wichert Akkerman
 * Copyright © 2006-2014 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_DPKG_DB_H
#define LIBDPKG_DPKG_DB_H

#include <sys/types.h>

#include <stdbool.h>
#include <stdio.h>

#include <dpkg/macros.h>
#include <dpkg/varbuf.h>
#include <dpkg/version.h>
#include <dpkg/arch.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup dpkg-db In-core package database management
 * @ingroup dpkg-public
 * @{
 */

enum deptype {
  dep_suggests,
  dep_recommends,
  dep_depends,
  dep_predepends,
  dep_breaks,
  dep_conflicts,
  dep_provides,
  dep_replaces,
  dep_enhances
};

struct dependency {
  struct pkginfo *up;
  struct dependency *next;
  struct deppossi *list;
  enum deptype type;
};

struct deppossi {
  struct dependency *up;
  struct pkgset *ed;
  struct deppossi *next, *rev_next, *rev_prev;
  const struct dpkg_arch *arch;
  struct dpkg_version version;
  enum dpkg_relation verrel;
  bool arch_is_implicit;
  bool cyclebreak;
};

struct arbitraryfield {
  struct arbitraryfield *next;
  const char *name;
  const char *value;
};

struct conffile {
  struct conffile *next;
  const char *name;
  const char *hash;
  bool obsolete;
};

struct archivedetails {
  struct archivedetails *next;
  const char *name;
  const char *msdosname;
  const char *size;
  const char *md5sum;
};

enum pkgmultiarch {
	PKG_MULTIARCH_NO,
	PKG_MULTIARCH_SAME,
	PKG_MULTIARCH_ALLOWED,
	PKG_MULTIARCH_FOREIGN,
};

/**
 * Node describing a binary package file.
 *
 * This structure holds information contained on each binary package.
 */
struct pkgbin {
  struct dependency *depends;
  /** The ‘essential’ flag, true = yes, false = no (absent). */
  bool essential;
  enum pkgmultiarch multiarch;
  const struct dpkg_arch *arch;
  /** The following is the "pkgname:archqual" cached string, if this was a
   * C++ class this member would be mutable. */
  const char *pkgname_archqual;
  const char *description;
  const char *maintainer;
  const char *source;
  const char *installedsize;
  const char *origin;
  const char *bugs;
  struct dpkg_version version;
  struct conffile *conffiles;
  struct arbitraryfield *arbs;
};

/**
 * Node indicates that parent's Triggers-Pending mentions name.
 *
 * Note: These nodes do double duty: after they're removed from a package's
 * trigpend list, references may be preserved by the trigger cycle checker
 * (see trigproc.c).
 */
struct trigpend {
  struct trigpend *next;
  const char *name;
};

/**
 * Node indicates that aw's Triggers-Awaited mentions pend.
 */
struct trigaw {
  struct pkginfo *aw, *pend;
  struct trigaw *samepend_next;
  struct {
    struct trigaw *next, *prev;
  } sameaw;
};

/* Note: dselect and dpkg have different versions of this. */
struct perpackagestate;

enum pkgwant {
	PKG_WANT_UNKNOWN,
	PKG_WANT_INSTALL,
	PKG_WANT_HOLD,
	PKG_WANT_DEINSTALL,
	PKG_WANT_PURGE,
	/** Not allowed except as special sentinel value in some places. */
	PKG_WANT_SENTINEL,
};

enum pkgeflag {
	PKG_EFLAG_OK		= 0,
	PKG_EFLAG_REINSTREQ	= 1,
};

enum pkgstatus {
	PKG_STAT_NOTINSTALLED,
	PKG_STAT_CONFIGFILES,
	PKG_STAT_HALFINSTALLED,
	PKG_STAT_UNPACKED,
	PKG_STAT_HALFCONFIGURED,
	PKG_STAT_TRIGGERSAWAITED,
	PKG_STAT_TRIGGERSPENDING,
	PKG_STAT_INSTALLED,
};

enum pkgpriority {
	PKG_PRIO_REQUIRED,
	PKG_PRIO_IMPORTANT,
	PKG_PRIO_STANDARD,
	PKG_PRIO_OPTIONAL,
	PKG_PRIO_EXTRA,
	PKG_PRIO_OTHER,
	PKG_PRIO_UNKNOWN,
	PKG_PRIO_UNSET = -1,
};

/**
 * Node describing an architecture package instance.
 *
 * This structure holds state information.
 */
struct pkginfo {
  struct pkgset *set;
  struct pkginfo *arch_next;

  enum pkgwant want;
  /** The error flag bitmask. */
  enum pkgeflag eflag;
  enum pkgstatus status;
  enum pkgpriority priority;
  const char *otherpriority;
  const char *section;
  struct dpkg_version configversion;
  struct pkgbin installed;
  struct pkgbin available;
  struct perpackagestate *clientdata;

  struct archivedetails *archives;

  struct {
    /* ->aw == this */
    struct trigaw *head, *tail;
  } trigaw;

  /* ->pend == this, non-NULL for us when Triggers-Pending. */
  struct trigaw *othertrigaw_head;
  struct trigpend *trigpend_head;

  /**
   * files_list_valid  files  Meaning
   * ----------------  -----  -------
   * false             NULL   Not read yet, must do so if want them.
   * false             !NULL  Read, but rewritten and now out of date. If want
   *                          info must throw away old and reread file.
   * true              !NULL  Read, all is OK.
   * true              NULL   Read OK, but, there were no files.
   */
  struct fsys_namenode_list *files;
  off_t files_list_phys_offs;
  bool files_list_valid;

  /* The status has changed, it needs to be logged. */
  bool status_dirty;
};

/**
 * Node describing a package set sharing the same package name.
 */
struct pkgset {
  struct pkgset *next;
  const char *name;
  struct pkginfo pkg;
  struct {
    struct deppossi *available;
    struct deppossi *installed;
  } depended;
  int installed_instances;
};

/*** from dbdir.c ***/

const char *dpkg_db_set_dir(const char *dir);
const char *dpkg_db_get_dir(void);
char *dpkg_db_get_path(const char *pathpart);

#include <dpkg/atomic-file.h>

/*** from dbmodify.c ***/

enum modstatdb_rw {
  /* Those marked with \*s*\ are possible returns from modstatdb_init. */
  msdbrw_readonly/*s*/, msdbrw_needsuperuserlockonly/*s*/,
  msdbrw_writeifposs,
  msdbrw_write/*s*/, msdbrw_needsuperuser,

  /* Now some optional flags (starting at bit 8): */
  msdbrw_available_readonly	= DPKG_BIT(8),
  msdbrw_available_write	= DPKG_BIT(9),
  msdbrw_available_mask		= 0xff00,
};

void modstatdb_init(void);
void modstatdb_done(void);
bool modstatdb_is_locked(void);
bool modstatdb_can_lock(void);
void modstatdb_lock(void);
void modstatdb_unlock(void);
enum modstatdb_rw modstatdb_open(enum modstatdb_rw reqrwflags);
enum modstatdb_rw modstatdb_get_status(void);
void modstatdb_note(struct pkginfo *pkg);
void modstatdb_note_ifwrite(struct pkginfo *pkg);
void modstatdb_checkpoint(void);
void modstatdb_shutdown(void);

/*** from database.c ***/

void pkgset_blank(struct pkgset *set);
int pkgset_installed_instances(struct pkgset *set);

void pkg_blank(struct pkginfo *pp);
void pkgbin_blank(struct pkgbin *pkgbin);
bool pkg_is_informative(struct pkginfo *pkg, struct pkgbin *info);

struct pkgset *
pkg_hash_find_set(const char *name);
struct pkginfo *
pkg_hash_get_singleton(struct pkgset *set);
struct pkginfo *
pkg_hash_find_singleton(const char *name);
struct pkginfo *
pkg_hash_get_pkg(struct pkgset *set, const struct dpkg_arch *arch);
struct pkginfo *
pkg_hash_find_pkg(const char *name, const struct dpkg_arch *arch);
int
pkg_hash_count_set(void);
int
pkg_hash_count_pkg(void);
void
pkg_hash_reset(void);

struct pkg_hash_iter *
pkg_hash_iter_new(void);
struct pkgset *
pkg_hash_iter_next_set(struct pkg_hash_iter *iter);
struct pkginfo *
pkg_hash_iter_next_pkg(struct pkg_hash_iter *iter);
void
pkg_hash_iter_free(struct pkg_hash_iter *iter);

void
pkg_hash_report(FILE *);

/*** from parse.c ***/

enum parsedbflags {
  /** Parse a single control stanza. */
  pdb_single_stanza		= DPKG_BIT(0),
  /** Store in ‘available’ in-core structures, not ‘status’. */
  pdb_recordavailable		= DPKG_BIT(1),
  /** Throw up an error if ‘Status’ encountered. */
  pdb_rejectstatus		= DPKG_BIT(2),
  /** Ignore priority/section info if we already have any. */
  pdb_weakclassification	= DPKG_BIT(3),
  /** Ignore archives info if we already have them. */
  pdb_ignore_archives		= DPKG_BIT(4),
  /** Ignore packages with older versions already read. */
  pdb_ignoreolder		= DPKG_BIT(5),
  /** Perform laxer version parsing. */
  pdb_lax_version_parser	= DPKG_BIT(6),
  /** Perform laxer control stanza parsing. */
  pdb_lax_stanza_parser		= DPKG_BIT(9),
  /** Perform laxer parsing, used to transition to stricter parsing. */
  pdb_lax_parser		= pdb_lax_stanza_parser | pdb_lax_version_parser,
  /** Close file descriptor on context destruction. */
  pdb_close_fd			= DPKG_BIT(7),
  /** Interpret filename ‘-’ as stdin. */
  pdb_dash_is_stdin		= DPKG_BIT(8),

  /* Standard operations. */

  pdb_parse_status		= pdb_lax_parser | pdb_weakclassification,
  pdb_parse_update		= pdb_parse_status | pdb_single_stanza,
  pdb_parse_available		= pdb_recordavailable | pdb_rejectstatus |
				  pdb_lax_parser,
  pdb_parse_binary		= pdb_recordavailable | pdb_rejectstatus |
				  pdb_single_stanza,
};

const char *pkg_name_is_illegal(const char *p);

const struct fieldinfo *
find_field_info(const struct fieldinfo *fields, const char *fieldname);
const struct arbitraryfield *
find_arbfield_info(const struct arbitraryfield *arbs, const char *fieldname);

int parsedb(const char *filename, enum parsedbflags, struct pkginfo **donep);
void copy_dependency_links(struct pkginfo *pkg,
                           struct dependency **updateme,
                           struct dependency *newdepends,
                           bool available);

/*** from parsehelp.c ***/

#include <dpkg/namevalue.h>

extern const struct namevalue booleaninfos[];
extern const struct namevalue multiarchinfos[];
extern const struct namevalue priorityinfos[];
extern const struct namevalue statusinfos[];
extern const struct namevalue eflaginfos[];
extern const struct namevalue wantinfos[];

#include <dpkg/error.h>

enum versiondisplayepochwhen { vdew_never, vdew_nonambig, vdew_always };
void varbufversion(struct varbuf *, const struct dpkg_version *,
                   enum versiondisplayepochwhen);
int parseversion(struct dpkg_version *version, const char *,
                 struct dpkg_error *err);
const char *versiondescribe(const struct dpkg_version *,
                            enum versiondisplayepochwhen);

enum pkg_name_arch_when {
  /** Never display arch. */
  pnaw_never,
  /** Display arch only when it's non-ambiguous. */
  pnaw_nonambig,
  /** Display arch only when it's a foreign one. */
  pnaw_foreign,
  /** Always display arch. */
  pnaw_always,
};

void varbuf_add_pkgbin_name(struct varbuf *vb, const struct pkginfo *pkg,
                            const struct pkgbin *pkgbin,
                            enum pkg_name_arch_when pnaw);

const char *
pkgbin_name_archqual(const struct pkginfo *pkg, const struct pkgbin *pkgbin);

const char *
pkgbin_name(struct pkginfo *pkg, struct pkgbin *pkgbin,
            enum pkg_name_arch_when pnaw);
const char *
pkg_name(struct pkginfo *pkg, enum pkg_name_arch_when pnaw);

const char *
pkgbin_name_const(const struct pkginfo *pkg, const struct pkgbin *pkgbin,
                  enum pkg_name_arch_when pnaw);
const char *
pkg_name_const(const struct pkginfo *pkg, enum pkg_name_arch_when pnaw);

void
pkg_source_version(struct dpkg_version *version,
                   const struct pkginfo *pkg, const struct pkgbin *pkgbin);

void
varbuf_add_source_version(struct varbuf *vb,
                          const struct pkginfo *pkg, const struct pkgbin *pkgbin);

const char *pkg_want_name(const struct pkginfo *pkg);
const char *pkg_status_name(const struct pkginfo *pkg);
const char *pkg_eflag_name(const struct pkginfo *pkg);

const char *pkg_priority_name(const struct pkginfo *pkg);

/*** from dump.c ***/

void writerecord(FILE*, const char*,
                 const struct pkginfo *, const struct pkgbin *);

enum writedb_flags {
  /** Dump ‘available’ in-core structures, not ‘status’. */
  wdb_dump_available		= DPKG_BIT(0),
  /** Must sync the written file. */
  wdb_must_sync			= DPKG_BIT(1),
};

void writedb_records(FILE *fp, const char *filename, enum writedb_flags flags);
void writedb(const char *filename, enum writedb_flags flags);

/* Note: The varbufs must have been initialized and will not be
 * NUL-terminated. */
void varbufrecord(struct varbuf *, const struct pkginfo *,
                  const struct pkgbin *);
void varbufdependency(struct varbuf *vb, struct dependency *dep);

/*** from depcon.c ***/

bool versionsatisfied(struct pkgbin *it, struct deppossi *against);
bool deparchsatisfied(struct pkgbin *it, const struct dpkg_arch *arch,
                      struct deppossi *against);
bool archsatisfied(struct pkgbin *it, struct deppossi *against);

bool
pkg_virtual_deppossi_satisfied(struct deppossi *dependee,
                               struct deppossi *provider);

/*** from nfmalloc.c ***/
void *nfmalloc(size_t);
char *nfstrsave(const char*);
char *nfstrnsave(const char*, size_t);
void nffreeall(void);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_DPKG_DB_H */
