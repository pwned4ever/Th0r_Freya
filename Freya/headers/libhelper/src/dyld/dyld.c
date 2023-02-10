//===------------------------------ macho -----------------------------===//
//
//                          Libhelper Mach-O Parser
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

#include "libhelper-dyld/dyld.h"

/***********************************************************************
* DYLD Shared Cache Parser.
***********************************************************************/

dyld_cache_t *dyld_cache_create ()
{
    dyld_cache_t *ret = malloc (sizeof (dyld_cache_t));
    memset (ret, '\0', sizeof (dyld_cache_t));
    return ret;
}

dyld_cache_t *dyld_cache_create_from_file (file_t *file)
{
    dyld_cache_t *dyld = dyld_cache_create ();

    dyld->path = file->path;

    dyld->size = file->size;
    dyld->data = (uint8_t *) file_load_bytes (file, dyld->size, 0);
    
    // Check we are 100% using a dyld_shared_cache

    // load the header
    dyld_cache_header_t *dyld_hdr = dyld_cache_header_create ();
    dyld_hdr = (dyld_cache_header_t *) dyld_load_bytes (dyld, sizeof (dyld_cache_header_t), 0);
    dyld->header = dyld_hdr;

    return dyld;
}

dyld_cache_t *dyld_cache_load (const char *filename)
{
    file_t          *file = NULL;
    dyld_cache_t    *dyld = NULL; 
    uint32_t         size = 0;
    unsigned char   *data = NULL;

    if (filename) {

        debugf ("Reading dyld_cache from filename: %s\n", filename);

        file = file_load (filename);
        if (file->size == 0) {
            errorf ("File not loaded properly\n");
            dyld_cache_free (dyld);
            return NULL;
        }

        debugf ("Creating dyld shared cache struct\n");
        dyld = dyld_cache_create_from_file (file);

        if (dyld == NULL)
            return NULL;

        debugf ("all seems well (dyld)\n");
    } else {
        debugf ("No filename specified\n");
    }

    return dyld;
}

void *dyld_load_bytes (dyld_cache_t *dyld, size_t size, uint32_t offset)
{
    void *ret = malloc (size);
    memcpy (ret, dyld->data + offset, size);
    return ret;
}

void dyld_cache_free (dyld_cache_t *dyld)
{
    dyld = NULL;
    free (dyld);
}

/***********************************************************************
* DYLD Shared Cache Header functions.
***********************************************************************/

dyld_cache_header_t *dyld_cache_header_create ()
{
    dyld_cache_header_t *ret = malloc (sizeof (dyld_cache_header_t));
    memset (ret, '\0', sizeof (dyld_cache_header_t));
    return ret;
}

int dyld_shared_cache_verify_header (unsigned char *dyld_ptr)
{
    if (!strncmp ((const char *) dyld_ptr, "dyld_", 5))
        return 1;
    
    return 0;
}

/*dyld_cache_header_t *dyld_cache_header_load (dyld_cache_t *dyld)
{

}*/