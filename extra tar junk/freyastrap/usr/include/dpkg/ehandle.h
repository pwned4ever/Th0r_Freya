/*
 * libdpkg - Debian packaging suite library routines
 * ehandle.h - error handling
 *
 * Copyright © 1994,1995 Ian Jackson <ijackson@chiark.greenend.org.uk>
 * Copyright © 2000,2001 Wichert Akkerman <wichert@debian.org>
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

#ifndef LIBDPKG_EHANDLE_H
#define LIBDPKG_EHANDLE_H

#include <setjmp.h>
#include <stddef.h>
#include <stdarg.h>

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup ehandle Error context handling
 * @ingroup dpkg-public
 * @{
 */

extern volatile int onerr_abort;

enum {
	ehflag_normaltidy	= DPKG_BIT(0),
	ehflag_bombout		= DPKG_BIT(1),
	ehflag_recursiveerror	= DPKG_BIT(2),
};

typedef void error_handler_func(void);
typedef void error_printer_func(const char *emsg, const void *data);

void print_fatal_error(const char *emsg, const void *data);
void catch_fatal_error(void);

void push_error_context_jump(jmp_buf *jumper,
                             error_printer_func *printer,
                             const void *printer_data);
void push_error_context_func(error_handler_func *handler,
                             error_printer_func *printer,
                             const void *printer_data);
void push_error_context(void);
void pop_error_context(int flagset);

void push_cleanup_fallback(void (*f1)(int argc, void **argv), int flagmask1,
                           void (*f2)(int argc, void **argv), int flagmask2,
                           unsigned int nargs, ...);
void push_cleanup(void (*call)(int argc, void **argv), int flagmask,
                  unsigned int nargs, ...);
void push_checkpoint(int mask, int value);
void pop_cleanup(int flagset);

void ohshitv(const char *fmt, va_list args)
	DPKG_ATTR_NORET DPKG_ATTR_VPRINTF(1);
void ohshit(const char *fmt, ...) DPKG_ATTR_NORET DPKG_ATTR_PRINTF(1);
void ohshite(const char *fmt, ...) DPKG_ATTR_NORET DPKG_ATTR_PRINTF(1);

void do_internerr(const char *file, int line, const char *func,
                  const char *fmt, ...)
	DPKG_ATTR_NORET DPKG_ATTR_PRINTF(4);
#define internerr(...) do_internerr(__FILE__, __LINE__, __func__, __VA_ARGS__)

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_EHANDLE_H */
