/*
 * libdpkg - Debian packaging suite library routines
 * dpkg.h - general header for Debian package handling
 *
 * Copyright © 1994,1995 Ian Jackson <ijackson@chiark.greenend.org.uk>
 * Copyright © 2000,2001 Wichert Akkerman <wichert@debian.org>
 * Copyright © 2006-2015 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_DPKG_H
#define LIBDPKG_DPKG_H

#include <sys/types.h>

#include <stddef.h>
#include <stdio.h>

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @mainpage libdpkg C API
 *
 * This is the documentation for the libdpkg C API. It is divided in an
 * @ref dpkg-internal "internal API" and a @ref dpkg-public "public API".
 * Applications closely tied to dpkg can make use of the internal API, the
 * rest should only assume the availability of the public API.
 *
 * Applications need to define the LIBDPKG_VOLATILE_API macro to acknowledge
 * that the API is to be considered volatile, please read doc/README.api for
 * more information.
 *
 * @defgroup dpkg-internal Internal libdpkg C API
 *
 * @defgroup dpkg-public Public libdpkg C API
 */

#define MAXCONFFILENAME     1000
#define MAXDIVERTFILENAME   1024
#define MAXCONTROLFILENAME  100
#define DEBEXT             ".deb"
#define REMOVECONFFEXTS    "~", ".bak", "%", \
                           DPKGTEMPEXT, DPKGNEWEXT, DPKGOLDEXT, DPKGDISTEXT

#define NEWCONFFILEFLAG    "newconffile"
#define NONEXISTENTFLAG    "nonexistent"
#define EMPTYHASHFLAG      "-"

#define DPKGTEMPEXT        ".dpkg-tmp"
#define DPKGNEWEXT         ".dpkg-new"
#define DPKGOLDEXT         ".dpkg-old"
#define DPKGDISTEXT        ".dpkg-dist"

#define CONTROLFILE        "control"
#define CONFFILESFILE      "conffiles"
#define PREINSTFILE        "preinst"
#define EXTRAINSTFILE      "extrainst_"
#define POSTINSTFILE       "postinst"
#define PRERMFILE          "prerm"
#define POSTRMFILE         "postrm"
/* Debconf config maintainer script. */
#define MAINTSCRIPT_FILE_CONFIG		"config"
#define TRIGGERSCIFILE     "triggers"

#define STATUSFILE        "status"
#define AVAILFILE         "available"
#define LOCKFILE          "lock"
#define FRONTENDLOCKFILE  "lock-frontend"
#define DIVERSIONSFILE    "diversions"
#define STATOVERRIDEFILE  "statoverride"
#define UPDATESDIR        "updates/"
#define INFODIR           "info"
#define TRIGGERSDIR       "triggers"
#define TRIGGERSFILEFILE  "File"
#define TRIGGERSDEFERREDFILE "Unincorp"
#define TRIGGERSLOCKFILE  "Lock"
#define CONTROLDIRTMP     "tmp.ci"
#define IMPORTANTTMP      "tmp.i"
#define REASSEMBLETMP     "reassemble" DEBEXT
#define IMPORTANTMAXLEN    10
#define IMPORTANTFMT      "%04d"
#define MAXUPDATES         250

#define DEFAULTSHELL        "sh"
#define DEFAULTPAGER        "pager"

#define MD5HASHLEN           32
#define MAXTRIGDIRECTIVE     256

#define BACKEND		"dpkg-deb"
#define SPLITTER	"dpkg-split"
#define DPKGQUERY	"dpkg-query"
#define DPKGDIVERT	"dpkg-divert"
#define DPKGSTAT	"dpkg-statoverride"
#define DPKGTRIGGER	"dpkg-trigger"
#define DPKG		"dpkg"
#define DEBSIGVERIFY	"debsig-verify"

#define RM		"rm"
#define CAT		"cat"
#define DIFF		"diff"

#include <dpkg/progname.h>
#include <dpkg/ehandle.h>
#include <dpkg/report.h>
#include <dpkg/string.h>
#include <dpkg/program.h>

/*** log.c ***/

extern const char *log_file;
void log_message(const char *fmt, ...) DPKG_ATTR_PRINTF(1);

void statusfd_add(int fd);
void statusfd_send(const char *fmt, ...) DPKG_ATTR_PRINTF(1);

/*** cleanup.c ***/

void cu_closestream(int argc, void **argv);
void cu_closepipe(int argc, void **argv);
void cu_closedir(int argc, void **argv);
void cu_closefd(int argc, void **argv);
void cu_filename(int argc, void **argv);

/*** from mlib.c ***/

void setcloexec(int fd, const char *fn);
void *m_malloc(size_t);
void *m_calloc(size_t nmemb, size_t size);
void *m_realloc(void *, size_t);
char *m_strdup(const char *str);
char *m_strndup(const char *str, size_t n);
int m_asprintf(char **strp, const char *fmt, ...) DPKG_ATTR_PRINTF(2);
int m_vasprintf(char **strp, const char *fmt, va_list args)
	DPKG_ATTR_VPRINTF(2);
int m_dup(int oldfd);
void m_dup2(int oldfd, int newfd);
void m_pipe(int fds[2]);
void m_output(FILE *f, const char *name);

/*** from utils.c ***/

int fgets_checked(char *buf, size_t bufsz, FILE *f, const char *fn);
int fgets_must(char *buf, size_t bufsz, FILE *f, const char *fn);

DPKG_END_DECLS

#endif /* LIBDPKG_DPKG_H */
