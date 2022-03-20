//
//  KernelUtils.h
//  Ziyou
//
//  Created by Tanay Findley on 5/8/19.
//  Copyright © 2019 Ziyou Team. All rights reserved.
//

#ifndef KernelUtils_h
#define KernelUtils_h

#include <stdio.h>
#include <stdbool.h>


//Check to see if we init patchfinder64 (got offsets) This should never be false by the time we use it.
extern bool found_offs;
bool wkbuffer(uint64_t kaddr, void* buffer, size_t length);
size_t kreadOwO(uint64_t where, void* p, size_t size);
size_t kwriteOwO(uint64_t where, const void* p, size_t size);
bool rkbuffer(uint64_t kaddr, void* buffer, size_t length);
uint64_t ReadKernel64(uint64_t kaddr);
void WriteKernel64(uint64_t kaddr, uint64_t val);
uint64_t kmem_alloc(uint64_t size);
uint64_t task_self_addr(void);
uint32_t ReadKernel32(uint64_t kaddr);
void kmemcpy(uint64_t dest, uint64_t src, uint32_t length);
void WriteKernel32(uint64_t kaddr, uint32_t val);
bool have_kmem_read(void);
bool kmem_free(uint64_t kaddr, uint64_t size);

#endif /* KernelUtils_h */
