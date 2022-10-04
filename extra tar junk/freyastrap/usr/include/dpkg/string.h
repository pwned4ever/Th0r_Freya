/*
 * libdpkg - Debian packaging suite library routines
 * string.h - string handling routines
 *
 * Copyright © 2008-2015 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_STRING_H
#define LIBDPKG_STRING_H

#include <stddef.h>
#include <stdbool.h>

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

/**
 * @defgroup string String handling
 * @ingroup dpkg-internal
 * @{
 */

/**
 * Check if a string is either NULL or empty.
 */
static inline bool
str_is_unset(const char *str)
{
	return str == NULL || str[0] == '\0';
}

/**
 * Check if a string has content.
 */
static inline bool
str_is_set(const char *str)
{
	return str != NULL && str[0] != '\0';
}

bool str_match_end(const char *str, const char *end);

unsigned int str_fnv_hash(const char *str);

char *str_concat(char *dst, ...) DPKG_ATTR_SENTINEL;
char *str_fmt(const char *fmt, ...) DPKG_ATTR_PRINTF(1);
char *str_escape_fmt(char *dest, const char *src, size_t n);
char *str_quote_meta(const char *src);
char *str_strip_quotes(char *str);

struct str_crop_info {
	int str_bytes;
	int max_bytes;
};

int str_width(const char *str);
void str_gen_crop(const char *str, int max_width, struct str_crop_info *crop);

/** @} */

DPKG_END_DECLS

#endif /* LIBDPKG_STRING_H */
