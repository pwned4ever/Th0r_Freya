//===---------------------------- file -----------------------------===//
//
//                        The Libhelper Project
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

#ifndef FILE_H_
#define FILE_H_

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

#include "libhelper/strutils.h"
#include "libhelper/hstring.h"

/***********************************************************************
* File loading and handling.
***********************************************************************/

/**
 *  A small structure for handling and streamlining files in C. It's
 *  used to pass around some extra information about a file like it's
 *  original path, along with the size and data pointer.
 *  
 */
typedef struct file_t {
    FILE    *desc;      /* Loaded file */
    size_t   size;      /* Size of the file */
//  unsigned char *data;    /* WIP */
    char    *path;      /* Original path */
} file_t;

/**
 *  Use `file_create()` for creating a new file_t structure by allocating
 *  and initialising it. Should be used for safely creating a new struct.
 * 
 *  Use `file_load()` for loading a given file (including the file path)
 *  into a file_t structure.
 * 
 *  Use `file_close()` to safely close a file, similar to `fclose()`.
 * 
 *  Use `file_free()` to free and NULL out the file_t structure.
 */ 
file_t  *file_create ();
file_t  *file_load (const char *path);
void     file_close (file_t *file);
void     file_free (file_t *file);

/**
 *  Flags for results of `file_read()` and `file_write_new()`.
 */
#define     LH_FILE_FAILURE     0x0
#define     LH_FILE_SUCCESS     0x1

/**
 *  Use `file_write_new()` to create and write a new file at the given
 *  path with the given data and size.
 * 
 *  Use `file_load_bytes()` to load `size` bytes from a given file
 *  struct starting at a given offset.
 */
int      file_write_new (char *filename, unsigned char *buf, size_t size);
char    *file_load_bytes (file_t *f, size_t size, uint32_t offset);


#endif /* FILE_H_ */
