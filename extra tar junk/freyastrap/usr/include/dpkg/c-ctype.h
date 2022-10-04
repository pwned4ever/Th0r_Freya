/*
 * libdpkg - Debian packaging suite library routines
 * c-ctype.h - ASCII C locale-only functions
 *
 * Copyright © 2009-2014 Guillem Jover <guillem@debian.org>
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

#ifndef LIBDPKG_C_CTYPE_H
#define LIBDPKG_C_CTYPE_H

#include <stdbool.h>

#include <dpkg/macros.h>

DPKG_BEGIN_DECLS

#define C_CTYPE_BIT(bit)	(1 << (bit))

enum c_ctype_bit {
	C_CTYPE_BLANK = C_CTYPE_BIT(0),
	C_CTYPE_WHITE = C_CTYPE_BIT(1),
	C_CTYPE_SPACE = C_CTYPE_BIT(2),
	C_CTYPE_UPPER = C_CTYPE_BIT(3),
	C_CTYPE_LOWER = C_CTYPE_BIT(4),
	C_CTYPE_DIGIT = C_CTYPE_BIT(5),

	C_CTYPE_ALPHA = C_CTYPE_UPPER | C_CTYPE_LOWER,
	C_CTYPE_ALNUM = C_CTYPE_ALPHA | C_CTYPE_DIGIT,
};

bool
c_isbits(int c, enum c_ctype_bit bits);

/**
 * Check if the character is [ \t].
 */
static inline bool
c_isblank(int c)
{
	return c_isbits(c, C_CTYPE_BLANK);
}

/**
 * Check if the character is [ \t\n].
 */
static inline bool
c_iswhite(int c)
{
	return c_isbits(c, C_CTYPE_WHITE);
}

/**
 * Check if the character is [ \v\t\f\r\n].
 */
static inline bool
c_isspace(int c)
{
	return c_isbits(c, C_CTYPE_SPACE);
}

/**
 * Check if the character is [0-9].
 */
static inline bool
c_isdigit(int c)
{
	return c_isbits(c, C_CTYPE_DIGIT);
}

/**
 * Check if the character is [A-Z].
 */
static inline bool
c_isupper(int c)
{
	return c_isbits(c, C_CTYPE_UPPER);
}

/**
 * Check if the character is [a-z].
 */
static inline bool
c_islower(int c)
{
	return c_isbits(c, C_CTYPE_LOWER);
}

/**
 * Check if the character is [a-zA-Z].
 */
static inline bool
c_isalpha(int c)
{
	return c_isbits(c, C_CTYPE_ALPHA);
}

/**
 * Check if the character is [a-zA-Z0-9].
 */
static inline bool
c_isalnum(int c)
{
	return c_isbits(c, C_CTYPE_ALNUM);
}

/**
 * Maps the character to its lower-case form.
 */
static inline int
c_tolower(int c)
{
	return (c_isupper(c) ? ((unsigned char)c & ~0x20) | 0x20 : c);
}

DPKG_END_DECLS

#endif
