//===----------------------------- dyld_cache.c --------------------------===//
//
//                                  dyld_cache
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
//===-----------------------------------------------------------------------===//

//
//  I'm now working on dyld shared cache parsing for libhelper. This
//  file contains testing for that library.
//

#include <libhelper/file.h>
#include <libhelper-dyld/dyld.h>

int main (int argc, char *argv[])
{
    if (argc < 2)
        exit (0);

    const char *filename = argv[1];

    file_t *file = file_load (filename);

    uint32_t size = file->size;
    unsigned char *data = (unsigned char *) file_load_bytes (file, size, 0);

    if (!dyld_shared_cache_verify_header(data))
        printf ("Not a dyld_shared_cache\n");
    else
        printf ("Is a dyld_shared_cahce\n");

    dyld_cache_header_t *cache_header = dyld_cache_header_create ();
    cache_header = (dyld_cache_header_t *) data;

    //////////////////////////////////
    size_t uuid_size = sizeof(uint8_t) * 128;
    char *uuid_str = malloc (uuid_size);
    snprintf (uuid_str, uuid_size, "%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
                            (unsigned int)cache_header->uuid[0], (unsigned int)cache_header->uuid[1],
                            (unsigned int)cache_header->uuid[2],  (unsigned int)cache_header->uuid[3],
                            (unsigned int)cache_header->uuid[4],  (unsigned int)cache_header->uuid[5],
                            (unsigned int)cache_header->uuid[6],  (unsigned int)cache_header->uuid[7],
                            (unsigned int)cache_header->uuid[8],  (unsigned int)cache_header->uuid[9],
                            (unsigned int)cache_header->uuid[10], (unsigned int)cache_header->uuid[11],
                            (unsigned int)cache_header->uuid[12], (unsigned int)cache_header->uuid[13],
                            (unsigned int)cache_header->uuid[14], (unsigned int)cache_header->uuid[15]);
    ///////////////////////////////////////////////



    printf ("magic: %s\n", cache_header->magic);

    printf ("mappingOffset: 0x%llx\n", cache_header->mappingOffset);
    printf ("mappingCount: %d\n", cache_header->mappingCount);
    printf ("imagesOffset: 0x%llx\n", cache_header->imagesOffset);
    printf ("imagesCount: 0x%d\n", cache_header->imagesCount);

    printf ("dyldBaseAddress: 0x%llx\n", cache_header->dyldBaseAddress);
    printf ("codeSignatureOffset: 0x%llx\n", cache_header->codeSignatureOffset);
    printf ("codeSignatureSize: %d\n", cache_header->codeSignatureSize);
    printf ("slideInfoOffset: 0x%llx\n", cache_header->slideInfoOffset);
    printf ("slideInfoSize: %d\n", cache_header->slideInfoSize);
    printf ("localSymbolsOffset: 0x%llx\n", cache_header->localSymbolsOffset);
    printf ("localSymbolsSize: %d\n", cache_header->localSymbolsSize);

    printf ("uuid: %s\n", uuid_str);

    printf ("cacheType: 0x%llx\n", cache_header->cacheType);
    printf ("branchPoolsOffset: 0x%llx\n", cache_header->branchPoolsOffset);
    printf ("branchPoolsCount: %d\n", cache_header->branchPoolsCount);
    printf ("accelerateInfoAddr: 0x%llx\n", cache_header->accelerateInfoAddr);
    printf ("accelerateInfoSize: %d\n", cache_header->accelerateInfoSize);
    printf ("imagesTextOffset: 0x%llx\n", cache_header->imagesTextOffset);
    printf ("imagesTextCount: %d\n", cache_header->imagesTextCount);


}