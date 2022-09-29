/*
 * libdpkg - Debian packaging suite library routines
 * color.h - color support
 *
 * Copyright © 2015-2016 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_COLOR_H
#define LIBDPKG_COLOR_H

#include <stdbool.h>

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup color Color support
 * @ingroup dpkg-internal
 * @{
 */

/* Standard ANSI colors and attributes. */
#define COLOR_NORMAL		""
#define COLOR_RESET		"\e[0m"
#define COLOR_BOLD		"\e[1m"
#define COLOR_BLACK		"\e[30m"
#define COLOR_RED		"\e[31m"
#define COLOR_GREEN		"\e[32m"
#define COLOR_YELLOW		"\e[33m"
#define COLOR_BLUE		"\e[34m"
#define COLOR_MAGENTA		"\e[35m"
#define COLOR_CYAN		"\e[36m"
#define COLOR_WHITE		"\e[37m"
#define COLOR_BOLD_BLACK	"\e[1;30m"
#define COLOR_BOLD_RED		"\e[1;31m"
#define COLOR_BOLD_GREEN	"\e[1;32m"
#define COLOR_BOLD_YELLOW	"\e[1;33m"
#define COLOR_BOLD_BLUE		"\e[1;34m"
#define COLOR_BOLD_MAGENTA	"\e[1;35m"
#define COLOR_BOLD_CYAN		"\e[1;36m"
#define COLOR_BOLD_WHITE	"\e[1;37m"

/* Current defaults. These might become configurable in the future. */
#define COLOR_PROG		COLOR_BOLD
#define COLOR_INFO		COLOR_GREEN
#define COLOR_NOTICE		COLOR_YELLOW
#define COLOR_WARN		COLOR_BOLD_YELLOW
#define COLOR_ERROR		COLOR_BOLD_RED

enum color_mode {
	COLOR_MODE_UNKNOWN = -1,
	COLOR_MODE_NEVER,
	COLOR_MODE_ALWAYS,
	COLOR_MODE_AUTO,
};

bool
color_set_mode(const char *mode);

const char *
color_get(const char *color);

static inline const char *
color_reset(void)
{
	return color_get(COLOR_RESET);
}

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_COLOR_H */
