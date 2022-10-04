/*
 * libdpkg - Debian packaging suite library routines
 * macros.h - C language support macros
 *
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

#ifndef LIBDPKG_MACROS_H
#define LIBDPKG_MACROS_H

/**
 * @defgroup macros C language support macros
 * @ingroup dpkg-public
 * @{
 */

#ifndef LIBDPKG_VOLATILE_API
#error "The libdpkg API is to be considered volatile, please read 'README.api'."
#endif

/* Language definitions. */

#ifdef __GNUC__
#define DPKG_GCC_VERSION (__GNUC__ << 8 | __GNUC_MINOR__)
#else
#define DPKG_GCC_VERSION 0
#endif

#if DPKG_GCC_VERSION >= 0x0300
#define DPKG_ATTR_UNUSED	__attribute__((unused))
#define DPKG_ATTR_CONST		__attribute__((const))
#define DPKG_ATTR_PURE		__attribute__((pure))
#define DPKG_ATTR_MALLOC	__attribute__((malloc))
#define DPKG_ATTR_NORET		__attribute__((noreturn))
#define DPKG_ATTR_PRINTF(n)	__attribute__((format(printf, n, n + 1)))
#define DPKG_ATTR_VPRINTF(n)	__attribute__((format(printf, n, 0)))
#else
#define DPKG_ATTR_UNUSED
#define DPKG_ATTR_CONST
#define DPKG_ATTR_PURE
#define DPKG_ATTR_MALLOC
#define DPKG_ATTR_NORET
#define DPKG_ATTR_PRINTF(n)
#define DPKG_ATTR_VPRINTF(n)
#endif

#if DPKG_GCC_VERSION > 0x0302
#define DPKG_ATTR_NONNULL(...)	__attribute__((nonnull(__VA_ARGS__)))
#define DPKG_ATTR_REQRET	__attribute__((warn_unused_result))
#else
#define DPKG_ATTR_NONNULL(...)
#define DPKG_ATTR_REQRET
#endif

#if DPKG_GCC_VERSION >= 0x0400
#define DPKG_ATTR_SENTINEL	__attribute__((sentinel))
#else
#define DPKG_ATTR_SENTINEL
#endif

#if defined(__cplusplus) && __cplusplus >= 201103L
#define DPKG_ATTR_THROW(exception)
#define DPKG_ATTR_NOEXCEPT		noexcept
#elif defined(__cplusplus)
#define DPKG_ATTR_THROW(exception)	throw(exception)
#define DPKG_ATTR_NOEXCEPT		throw()
#endif

#ifdef __cplusplus
#define DPKG_BEGIN_DECLS	extern "C" {
#define DPKG_END_DECLS		}
#else
#define DPKG_BEGIN_DECLS
#define DPKG_END_DECLS
#endif

/**
 * @def DPKG_BIT
 *
 * Return the integer value of bit n.
 */
#define DPKG_BIT(n)	(1UL << (n))

/**
 * @def array_count
 *
 * Returns the amount of items in an array.
 */
#ifndef array_count
#define array_count(a) (sizeof(a) / sizeof((a)[0]))
#endif

/* For C++ use native implementations from STL or similar. */
#ifndef __cplusplus
#ifndef min
#define min(a, b) ((a) < (b) ? (a) : (b))
#endif

#ifndef max
#define max(a, b) ((a) > (b) ? (a) : (b))
#endif
#endif

/**
 * @def clamp
 *
 * Returns a normalized value within the low and high limits.
 *
 * @param v The value to clamp.
 * @param l The low limit.
 * @param h The high limit.
 */
#ifndef clamp
#define clamp(v, l, h) ((v) > (h) ? (h) : ((v) < (l) ? (l) : (v)))
#endif

/** @} */

#endif /* LIBDPKG_MACROS_H */
