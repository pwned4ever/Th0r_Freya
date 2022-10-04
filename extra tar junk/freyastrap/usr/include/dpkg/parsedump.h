/*
 * libdpkg - Debian packaging suite library routines
 * parsedump.h - declarations for in-core database reading/writing
 *
 * Copyright © 1995 Ian Jackson <ijackson@chiark.greenend.org.uk>
 * Copyright © 2001 Wichert Akkerman
 * Copyright © 2008-2011 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_PARSEDUMP_H
#define LIBDPKG_PARSEDUMP_H

#include <stdint.h>

#include <dpkg/error.h>

/**
 * @defgroup parsedump In-core package database parsing and reading
 * @ingroup dpkg-public
 * @{
 */

struct fieldinfo;

/**
 * Parse action.
 */
enum parsedbtype {
	pdb_file_update,
	pdb_file_status,
	pdb_file_control,
	pdb_file_available,
};

struct parsedb_state {
	enum parsedbtype type;
	enum parsedbflags flags;
	struct dpkg_error err;
	struct pkginfo *pkg;
	struct pkgbin *pkgbin;
	char *data;
	char *dataptr;
	char *endptr;
	const char *filename;
	int fd;
	int lno;
};

#define parse_at_eof(ps)	((ps)->dataptr >= (ps)->endptr)
#define parse_getc(ps)		*(ps)->dataptr++
#define parse_ungetc(c, ps)	(ps)->dataptr--

struct field_state {
	const char *fieldstart;
	const char *valuestart;
	struct varbuf value;
	int fieldlen;
	int valuelen;
	int *fieldencountered;
};

struct parsedb_state *
parsedb_new(const char *filename, int fd, enum parsedbflags flags);
struct parsedb_state *
parsedb_open(const char *filename, enum parsedbflags flags);
void
parsedb_load(struct parsedb_state *ps);
int
parsedb_parse(struct parsedb_state *ps, struct pkginfo **pkgp);
void
parsedb_close(struct parsedb_state *ps);

typedef void parse_field_func(struct parsedb_state *ps, struct field_state *fs,
                              void *parse_obj);

bool parse_stanza(struct parsedb_state *ps, struct field_state *fs,
                  parse_field_func *parse_field, void *parse_obj);

#define STRUCTFIELD(klass, off, type) (*(type *)((uintptr_t)(klass) + (off)))

#define PKGIFPOFF(f) (offsetof(struct pkgbin, f))
#define ARCHIVEFOFF(f) (offsetof(struct archivedetails, f))

typedef void freadfunction(struct pkginfo *pkg, struct pkgbin *pkgbin,
                           struct parsedb_state *ps,
                           const char *value, const struct fieldinfo *fip);
freadfunction f_name;
freadfunction f_charfield;
freadfunction f_priority;
freadfunction f_section;
freadfunction f_status;
freadfunction f_boolean, f_dependency, f_conffiles, f_version, f_revision;
freadfunction f_configversion;
freadfunction f_multiarch;
freadfunction f_architecture;
freadfunction f_trigpend, f_trigaw;
freadfunction f_archives;

enum fwriteflags {
	/** Print field header and trailing newline. */
	fw_printheader		= DPKG_BIT(0),
};

typedef void fwritefunction(struct varbuf*,
                            const struct pkginfo *, const struct pkgbin *,
			    enum fwriteflags flags, const struct fieldinfo*);
fwritefunction w_name, w_charfield, w_priority, w_section, w_status, w_configversion;
fwritefunction w_version, w_null, w_booleandefno, w_dependency, w_conffiles;
fwritefunction w_multiarch;
fwritefunction w_architecture;
fwritefunction w_trigpend, w_trigaw;
fwritefunction w_archives;

void
varbuf_add_arbfield(struct varbuf *vb, const struct arbitraryfield *arbfield,
                    enum fwriteflags flags);

#define FIELD(name) name, sizeof(name) - 1

struct fieldinfo {
  const char *name;
  size_t namelen;
  freadfunction *rcall;
  fwritefunction *wcall;
  size_t integer;
};

int
parse_db_version(struct parsedb_state *ps,
                 struct dpkg_version *version, const char *value)
	DPKG_ATTR_REQRET;

void parse_error(struct parsedb_state *ps, const char *fmt, ...)
	DPKG_ATTR_NORET DPKG_ATTR_PRINTF(2);
void parse_warn(struct parsedb_state *ps, const char *fmt, ...)
	DPKG_ATTR_PRINTF(2);
void
parse_problem(struct parsedb_state *ps, const char *fmt, ...)
	DPKG_ATTR_PRINTF(2);

void parse_must_have_field(struct parsedb_state *ps,
                           const char *value, const char *what);
void parse_ensure_have_field(struct parsedb_state *ps,
                             const char **value, const char *what);

#define MSDOS_EOF_CHAR '\032' /* ^Z */

extern const struct fieldinfo fieldinfos[];

/** @} */

#endif /* LIBDPKG_PARSEDUMP_H */
