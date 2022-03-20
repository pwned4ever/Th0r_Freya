//
//  cpBootHash.c
//  Ziyou
//
//  Created by Tanay Findley on 8/18/19.
//  Copyright © 2019 Ziyou Team. All rights reserved.
//

#include "cpBootHash.h"

#include "IOKit.h"

char *copyBootHash(void) {
    unsigned char buf[1024];
    uint32_t length = 1024;
    io_registry_entry_t chosen = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/chosen");
    
    if (!MACH_PORT_VALID(chosen)) {
        printf("Unable to get IODeviceTree:/chosen port\n");
        return NULL;
    }
    
    kern_return_t ret = IORegistryEntryGetProperty(chosen, "boot-manifest-hash", (void*)buf, &length);
    
    IOObjectRelease(chosen);
    
    if (ret != ERR_SUCCESS) {
        printf("Unable to read boot-manifest-hash\n");
        return NULL;
    }
    
    // Make a hex string out of the hash
    char manifestHash[length*2+1];
    bzero(manifestHash, sizeof(manifestHash));
    
    int i;
    for (i=0; i<length; i++) {
        sprintf(manifestHash+i*2, "%02X", buf[i]);
    }
    
    printf("Hash: %s\n", manifestHash);
    return strdup(manifestHash);
}
