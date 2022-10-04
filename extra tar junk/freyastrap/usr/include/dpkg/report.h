/*
 * libdpkg - Debian packaging suite library routines
 * report.h - message reporting
 *
 * Copyright © 2004 Scott James Remnant <scott@netsplit.com>
 * Copyright © 2008-2012 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_REPORT_H
#define LIBDPKG_REPORT_H

#include <stdarg.h>
#include <stdio.h>

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup report Message reporting
 * @ingroup dpkg-internal
 * @{
 */

void dpkg_set_report_piped_mode(int mode);
void dpkg_set_report_buffer(FILE *fp);

typedef void dpkg_warning_printer_func(const char *msg, void *data);

void dpkg_warning_printer(const char *msg, void *data);
void dpkg_set_warning_printer(dpkg_warning_printer_func *printer, void *data);

int warning_get_count(void);
void warningv(const char *fmt, va_list args) DPKG_ATTR_VPRINTF(1);
void warning(const char *fmt, ...) DPKG_ATTR_PRINTF(1);

void notice(const char *fmt, ...) DPKG_ATTR_PRINTF(1);

void info(const char *fmt, ...) DPKG_ATTR_PRINTF(1);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_REPORT_H */
