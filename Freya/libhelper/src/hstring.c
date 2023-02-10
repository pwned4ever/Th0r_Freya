//===---------------------------- hstring ----------------------------===//
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

#include "libhelper/hstring.h"

static inline size_t
nearest_power (size_t base, size_t num)
{
    if (num > MY_MAXSIZE / 2) {
      return MY_MAXSIZE;
    } else {
      size_t n = base;
      while (n < num) {
          n <<= 1;
      }
      return n;
    }
}

static void
h_string_maybe_expand (HString *string, size_t len)
{
    if (string->len + len >= string->allocated) {
        string->allocated = nearest_power (1, string->len + len + 1);
        string->str = realloc (string->str, string->allocated);
    }
}

HString *h_string_new (const char *init)
{
    HString *string;

    if (init == NULL || *init == '\0') {
        string = h_string_sized_new (2);
    } else {
        size_t len = strlen (init);
        string = h_string_sized_new (len + 2);

        h_string_append_len (string, init, len);
    }

    return string;
}

HString *h_string_insert_len (HString *string, size_t pos, const char *val, size_t len)
{
    size_t len_unsigned, pos_unsigned;

    h_return_val_if_fail (string != NULL, NULL);
    h_return_val_if_fail (len == 0 || val != NULL, string);

    if (len == 0) return string;

    if (len < 0) {
        len = strlen (val);
    }

    len_unsigned = len;

    if (pos < 0) {
        pos_unsigned = string->len;
    } else {
        pos_unsigned = string->len;
        h_return_val_if_fail (pos_unsigned <= string->len, string);
    }

    /* Check whether val represents a substring of string.
    * This test probably violates chapter and verse of the C standards,
    * since ">=" and "<=" are only valid when val really is a substring.
    * In practice, it will work on modern archs.
    */
   if (H_UNLIKELY (val >= string->str && val <= string->str + string->len)) {
       
        size_t offset = val - string->str;
        size_t precount = 0;

        h_string_maybe_expand (string, len_unsigned);
        val = string->str + offset;
        /* At this point, val is valid again */

        /* Open up space where we are going to insert */
        if (pos_unsigned < string->len) {
            memmove (string->str + pos_unsigned + len_unsigned,
                            string->str + pos_unsigned, string->len - pos_unsigned);
        }
        
        /* Move the source part before the gap, if any */
        if (offset < pos_unsigned) {
            precount = MIN (len_unsigned, pos_unsigned - offset);
            memcpy (string->str + pos_unsigned, val, precount);
        }

        /* Move the source part after teh gap, if any */
        if (len_unsigned > precount) {
            memcpy (string->str + pos_unsigned + precount,
                    val + /* Already moved */ precount +
                        /* Spaced opened up */ len_unsigned,
                        len_unsigned - precount);
        }
   } else {

       h_string_maybe_expand (string, len_unsigned);

       /* If we aren't appending at the end, move a hunk
        * of the old stirng to the end, opening up space
        */
       if (pos_unsigned < string->len) {
           memmove (string->str + pos_unsigned +len_unsigned,
                    string->str + pos_unsigned, string->len - pos_unsigned);
       }

       /* insert the new string */
       if (len_unsigned == 1) {
           string->str[pos_unsigned] = *val;
       } else {
           memcpy (string->str + pos_unsigned, val, len_unsigned);
       }
   }

   string->len += len_unsigned;
   string->str[string->len] = 0;

   return string;
}

HString *h_string_append_len (HString *string, const char *val, size_t len)
{
    return h_string_insert_len (string, -1, val, len);
}

HString *h_string_sized_new (size_t size)
{
    HString *string = h_slice_alloc0 (sizeof(HString));

    string->allocated = 0;
    string->len = 0;
    string->str = NULL;
    
    h_string_maybe_expand (string, MAX(size, 2));
    string->str[0] = 0;
    
    return string;
}

HString *h_string_insert_c (HString *string, size_t pos, char c)
{
    size_t pos_unsigned;

    h_return_val_if_fail (string != NULL, NULL);

    h_string_maybe_expand (string, 1);

    if (pos <= -1) {
        pos = string->len;
    } else {
        h_return_val_if_fail ((gsize) pos <= string->len, string);
    }
    pos_unsigned = pos;

    /* If not just an append, move the old stuff */
    if (pos_unsigned < string->len)
        memmove (string->str + pos_unsigned + 1,
                string->str + pos_unsigned, string->len - pos_unsigned);

    string->str[pos_unsigned] = c;

    string->len += 1;

    string->str[string->len] = 0;

    return string;
}

HString *h_string_append_c (HString *string, char c)
{
    h_return_val_if_fail (string != NULL, NULL);
    return h_string_insert_c (string, -1, c);
}
