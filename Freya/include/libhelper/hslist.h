//===----------------------------- hslist ----------------------------===//
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
 *                  === The Libhelper Project ===
 *                          HLibc? Maybe...
 *
 *  Implementation of Singly Linked Lists. Currently, I've used GLib 
 *  GSList's, however I want to move away from using GLib to both reduce 
 *  binary size, and remove the need for an arm64, iOS compatible GLib to 
 *  be installed on an iOS device that uses libhelper.
 * 
 *  Now, the aim isn't to write my own libc implementation. Instead there
 *  are a few things for GLib that I'd like to use, but I'd rather not be
 *  linking GLib. 
 * 
 * 
 *  == My Implementation: HSList.
 * 
 *      Each element in the list contains a pointer to it's data, along
 *  with a pointer to the next peice of data in the list.
 *                                                                      |
 *                                                                      |
 * 
 *  ----------------
 *  Original Author:
 *      Harry Moulton, @h3adsh0tzz  -   me@h3adsh0tzz.com.
 * 
 */

#ifndef _LIBHELPER_H_SLIST_H_
#define _LIBHELPER_H_SLIST_H_

#include <ctype.h>
#include <stdlib.h>
#include <string.h>

/**
 * 
 */
typedef struct __hslist HSList;
struct __hslist
{
    void    *data;
    HSList  *next;
};


/**
 *  Allocates a block of memory and initialises to 0.
 * 
 *  (I'm trying my best to not end up writing a libc
 *      implementation, but I can feel it coming).
 */
void *h_slice_alloc0 (size_t size);


HSList *h_slist_last (HSList *list);
HSList *h_slist_append (HSList *list, void *data);
HSList *h_slist_remove (HSList *list, void *data);
int h_slist_length (HSList *list);
void *h_slist_nth_data (HSList *list, int n);

#endif /* _libhelper_h_slist_h_ */