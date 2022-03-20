//
//  KernelUtils.c
//  Ziyou
//
//  Created by Tanay Findley on 5/8/19.
//  Copyright © 2019 Ziyou Team. All rights reserved.
//

#include "KernelUtils.h"
#include "ImportantHolders.h"
#include "common.h"
#include "KernelUtils.h"
#include "remap_tfp_set_hsp.h"
#include "find_port.h"
#include "mach_vm.h"

uint64_t cached_task_self_addr = 0;
bool found_offs = false;
uint64_t task_self_addr()
{
    if (cached_task_self_addr == 0) {
        cached_task_self_addr = have_kmem_read() && found_offs ? get_address_of_port(getpid(), mach_task_self()) : find_port_address(mach_task_self(), MACH_MSG_TYPE_COPY_SEND);
        LOG("task self: 0x%llx", cached_task_self_addr);
    }
    return cached_task_self_addr;
}



size_t kreadOwO(uint64_t where, void* p, size_t size)
{
    int rv;
    size_t offset = 0;
    while (offset < size) {
        mach_vm_size_t sz, chunk = 2048;
        if (chunk > size - offset) {
            chunk = size - offset;
        }
        rv = mach_vm_read_overwrite(tfp0,
                                    where + offset,
                                    chunk,
                                    (mach_vm_address_t)p + offset,
                                    &sz);
        if (rv || sz == 0) {
            LOG("error reading kernel @%p", (void*)(offset + where));
            break;
        }
        offset += sz;
    }
    return offset;
}

size_t kwriteOwO(uint64_t where, const void* p, size_t size)
{
    int rv;
    size_t offset = 0;
    while (offset < size) {
        size_t chunk = 2048;
        if (chunk > size - offset) {
            chunk = size - offset;
        }
        rv = mach_vm_write(tfp0,
                           where + offset,
                           (mach_vm_offset_t)p + offset,
                           (mach_msg_type_number_t)chunk);
        if (rv) {
            LOG("error writing kernel @%p", (void*)(offset + where));
            break;
        }
        offset += chunk;
    }
    return offset;
}

bool wkbuffer(uint64_t kaddr, void* buffer, size_t length)
{
    if (tfp0 == MACH_PORT_NULL) {
        LOG("attempt to write to kernel memory before any kernel memory write primitives available");
        return false;
    }
    
    return (kwriteOwO(kaddr, buffer, length) == length);
}


bool rkbuffer(uint64_t kaddr, void* buffer, size_t length)
{
    return (kreadOwO(kaddr, buffer, length) == length);
}



uint64_t rk64_via_tfp0(uint64_t kaddr)
{
    uint64_t val = 0;
    rkbuffer(kaddr, &val, sizeof(val));
    return val;
}

uint32_t rk32_via_tfp0(uint64_t kaddr)
{
    uint32_t val = 0;
    rkbuffer(kaddr, &val, sizeof(val));
    return val;
}


uint64_t ReadKernel64(uint64_t kaddr)
{
    if (tfp0 != MACH_PORT_NULL) {
        return rk64_via_tfp0(kaddr);
    }
    
    LOG("attempt to read kernel memory but no kernel memory read primitives available");
    
    return 0;
}

uint32_t ReadKernel32(uint64_t kaddr)
{
    if (tfp0 != MACH_PORT_NULL) {
        return rk32_via_tfp0(kaddr);
    }
    
    LOG("attempt to read kernel memory but no kernel memory read primitives available");
    
    return 0;
}

void WriteKernel64(uint64_t kaddr, uint64_t val)
{
    if (tfp0 == MACH_PORT_NULL) {
        LOG("attempt to write to kernel memory before any kernel memory write primitives available");
        return;
    }
    wkbuffer(kaddr, &val, sizeof(val));
}

void WriteKernel32(uint64_t kaddr, uint32_t val)
{
    if (tfp0 == MACH_PORT_NULL) {
        LOG("attempt to write to kernel memory before any kernel memory write primitives available");
        return;
    }
    wkbuffer(kaddr, &val, sizeof(val));
}




uint64_t kmem_alloc(uint64_t size)
{
    if (tfp0 == MACH_PORT_NULL) {
        LOG("attempt to allocate kernel memory before any kernel memory write primitives available");
        return 0;
    }
    
    kern_return_t err;
    mach_vm_address_t addr = 0;
    mach_vm_size_t ksize = round_page_kernel(size);
    err = mach_vm_allocate(tfp0, &addr, ksize, VM_FLAGS_ANYWHERE);
    if (err != KERN_SUCCESS) {
        LOG("unable to allocate kernel memory via tfp0: %s %x", mach_error_string(err), err);
        return 0;
    }
    return addr;
}

const uint64_t kernel_address_space_base = 0xffff000000000000;
void kmemcpy(uint64_t dest, uint64_t src, uint32_t length)
{
    if (dest >= kernel_address_space_base) {
        // copy to kernel:
        wkbuffer(dest, (void*)src, length);
    } else {
        // copy from kernel
        rkbuffer(src, (void*)dest, length);
    }
}

bool have_kmem_read()
{
    return (tfp0 != MACH_PORT_NULL);
}

bool kmem_free(uint64_t kaddr, uint64_t size)
{
    if (tfp0 == MACH_PORT_NULL) {
        LOG("attempt to deallocate kernel memory before any kernel memory write primitives available");
        return false;
    }
    
    kern_return_t err;
    mach_vm_size_t ksize = round_page_kernel(size);
    err = mach_vm_deallocate(tfp0, kaddr, ksize);
    if (err != KERN_SUCCESS) {
        LOG("unable to deallocate kernel memory via tfp0: %s %x", mach_error_string(err), err);
        return false;
    }
    return true;
}


