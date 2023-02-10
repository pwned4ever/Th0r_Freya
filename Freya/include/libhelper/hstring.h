//===----------------------------- hstring ----------------------------===//
//
//                         The Libhelper Project
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//
//  Copyright (C) 2019, Is This On?, @h3adsh0tzz
//  me@h3adsh0tzz.com.
//
//
//===------------------------------------------------------------------===//

#ifndef _LIBHELPER_H_STRING_H_
#define _LIBHELPER_H_STRING_H_

#include <ctype.h>
#include "strutils.h"
#include "hslist.h"

/***********************************************************************
* HString - Implementation of Strings
*
*   Implementation of Strings in C based on that of GLib's GString's.
*   This is part of my effort to keep Libhelper dependency-free.
*
***********************************************************************/

/**
 *  HString structure. Contains the regular C "string" of characters,
 *  a count of how long that string is, and the amount of memory that
 *  has currently been allocated for it.
 * 
 */
typedef struct _HString HString;
struct _HString {
    char        *str;
    size_t       len;
    size_t       allocated;
};

/**
 *  Macro's defined by GLib for HString.
 * 
 */
#define H_UNLIKELY(expr) (expr)
#define MY_MAXSIZE  ((size_t) -1)
#define MAX(a, b)  (((a) > (b)) ? (a) : (b))
#define MIN(a, b)  (((a) < (b)) ? (a) : (b))

/**
 *  Returns the given value if the expression is false.
 * 
 */
//
//	@TODO: This generates a warning:
//		warning: incompatible poiunter types returning 'char *' from a
//			function with result type 'HString *' (aka 'struct _HString *')
//
#define h_return_val_if_fail(expr, val)  \
    if(!(#expr)) {                       \
        debugf ("bugger\n");             \
        return #val;                     \
    }


/**
 *  Functions for creating and manipulating HString's
 * 
 */
HString *h_string_new (const char *init);
HString *h_string_insert_len (HString *string, size_t pos, const char *val, size_t len);
HString *h_string_append_len (HString *string, const char *val, size_t len);
HString *h_string_sized_new (size_t size);

HString *h_string_insert_c (HString *string, size_t pos, char c);
HString *h_string_append_c (HString *string, char c);

#endif /* _libhelper_h_string_h_ */