//===--------------------------- strutils ----------------------------===//
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

/**
 *  Original license: The Ni Programming Language
 */

#ifndef LIBHELPER_STRUTILS_H
#define LIBHELPER_STRUTILS_H

#include "libhelper/libhelper.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/***********************************************************************
* Wrappers for printf ()
*
*   Part of Libhelper String Utilities are some print functions. There
*   are three to be exact. errorf() prints an error message in red with
*   "Error: " prepended to the given string, warningf() the same but in
*   yellow. debugf() is slightly different because calls to it are only
*   acted upon if the LIBHELPER_DEBUG is set in libhelper.h
*
***********************************************************************/

/**
 *  Types to tell __printf() what colour and message to prepend to
 *  the start of the given message
 * 
 */
typedef enum {
    LOG_ERROR,
    LOG_WARNING,
    LOG_DEBUG,
    LOG_PRINT
} log_type;

/**
 *  Defined colours for print functions
 */
#define ANSI_COLOR_RED     "\x1b[31m"
#define ANSI_COLOR_GREEN   "\x1b[32m"
#define ANSI_COLOR_YELLOW  "\x1b[33m"
#define ANSI_COLOR_BLUE    "\x1b[34m"
#define ANSI_COLOR_MAGENTA "\x1b[35m"
#define ANSI_COLOR_CYAN    "\x1b[36m"
#define ANSI_COLOR_RESET   "\x1b[0m"

/**
 *  Re-implementation of printf() just for these macros
 */
int __printf(log_type msgType, char *fmt, ...);

/**
 *  Macro's for each print type.
 */
#define errorf(fmt, ...)  __printf(LOG_ERROR, fmt, ##__VA_ARGS__)
#define debugf(fmt, ...)  __printf(LOG_DEBUG, fmt, ##__VA_ARGS__)
#define warningf(fmt, ...)  __printf(LOG_WARNING, fmt, ##__VA_ARGS__)


/***********************************************************************
* String Appending
*
*   Part of Libhelper String Utilities are some regular string appending
*   functions. strappend() can take to strings, a and b, and append b to
*   a. While mstrappend() can take a list of strings and append them all
*   to fmt.
*
***********************************************************************/

/**
 *  Functions
 */
char *strappend (char *a, char *b);
char *mstrappend (char *fmt, ...);


/***********************************************************************
* String Lists
*
*   Part of Libhelper String Utilities is a string split function. This 
*   takes a string, and a delim to split it by, and returns a StringList
*   accordingly.
*
***********************************************************************/

/**
 *  StringList structure. Has a list of strings and a count of how
 *  many strings are in that list.
 * 
 */
typedef struct StringList {
    char    **ptrs;
    int     count;
} StringList;

/**
 *  Functions
 */
StringList *strsplit (const char *s, const char *delim);


#endif /* libhelper_strutils_h */