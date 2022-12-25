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
#include "patchfinder64.h"
#include "PFOffs.h"
#include "proc_info.h"
int need_initialSSRenamed = 0;
uint64_t cached_task_self_addr = 0;
uint64_t our_port_addr_exportedBYTW = 0;
uint64_t our_task_addr_exportedBYTW = 0;
uint64_t our_procStruct_addr_exported = 0;
uint64_t kernelbase_exportedBYTW = 0;
uint64_t our_kernel_procStruct_exportAstylez = 0;
uint64_t our_kernel_taskStruct_exportAstylez = 0;
mach_port_t tfp0_exportedBYTW = MACH_PORT_NULL;

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



//twaste below

static mach_port_t tfpzerotw;
static uint64_t task_selftw;

void init_kernel_memorytw(mach_port_t tfp0tw, uint64_t our_port_addrtw) {
    tfp0 = tfpzerotw = tfp0tw;
    task_selftw = our_port_addrtw;
}

uint64_t kalloctw(vm_size_t size) {
    mach_vm_address_t address = 0;
    mach_vm_allocate(tfpzerotw, (mach_vm_address_t *)&address, size, VM_FLAGS_ANYWHERE);
    return address;
}

void kfreetw(mach_vm_address_t address, vm_size_t size) {
    mach_vm_deallocate(tfpzerotw, address, size);
}

size_t kreadtw(uint64_t where, void *p, size_t size) {
    int rv;
    size_t offset = 0;
    while (offset < size) {
        mach_vm_size_t sz, chunk = 2048;
        if (chunk > size - offset) {
            chunk = size - offset;
        }
        rv = mach_vm_read_overwrite(tfpzerotw, where + offset, chunk, (mach_vm_address_t)p + offset, &sz);
        if (rv || sz == 0) {
            printf("[-] error on kread(0x%016llx)\n", where);
            break;
        }
        offset += sz;
    }
    return offset;
}

uint32_t rk32tw(uint64_t where) {
    uint32_t out;
    kreadtw(where, &out, sizeof(uint32_t));
    return out;
}

uint64_t rk64tw(uint64_t where) {
    uint64_t out;
    kreadtw(where, &out, sizeof(uint64_t));
    return out;
}

size_t kwritetw(uint64_t where, const void *p, size_t size) {
    int rv;
    size_t offset = 0;
    while (offset < size) {
        size_t chunk = 2048;
        if (chunk > size - offset) {
            chunk = size - offset;
        }
        rv = mach_vm_write(tfpzerotw, where + offset, (mach_vm_offset_t)p + offset, (int)chunk);
        if (rv) {
            printf("[-] error on kwrite(0x%016llx)\n", where);
            break;
        }
        offset += chunk;
    }
    return offset;
}

void wk32tw(uint64_t where, uint32_t what) {
    uint32_t _what = what;
    kwritetw(where, &_what, sizeof(uint32_t));
}


void wk64tw(uint64_t where, uint64_t what) {
    uint64_t _what = what;
    kwritetw(where, &_what, sizeof(uint64_t));
}

unsigned long kstrlentw(uint64_t string) {
    if (!string) return 0;
    
    unsigned long len = 0;
    char ch = 0;
    int i = 0;
    while (true) {
        kreadtw(string + i, &ch, 1);
        if (!ch) break;
        len++;
        i++;
    }
    return len;
}

int kstrcmptw(uint64_t string1, uint64_t string2) {
    unsigned long len1 = kstrlentw(string1);
    unsigned long len2 = kstrlentw(string2);
    
    char *s1 = malloc(len1);
    char *s2 = malloc(len2);
    kreadtw(string1, s1, len1);
    kreadtw(string2, s2, len2);
    
    int ret = strcmp(s1, s2);
    free(s1);
    free(s2);
    
    return ret;
}

int kstrcmp_utw(uint64_t string1, char *string2) {
    unsigned long len1 = kstrlentw(string1);
    
    char *s1 = malloc(len1);
    kreadtw(string1, s1, len1);
 
    int ret = strcmp(s1, string2);
    free(s1);
    
    return ret;
}

uint64_t find_porttw(mach_port_name_t port) {
    uint64_t task_addr = rk64tw(task_selftw + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT));
    uint64_t itk_space = rk64tw(task_addr + koffset(KSTRUCT_OFFSET_TASK_ITK_SPACE));
    uint64_t is_table = rk64tw(itk_space + koffset(KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE));
    
    uint32_t port_index = port >> 8;
    const int sizeof_ipc_entry_t = 0x18;
    
    uint64_t port_addr = rk64tw(is_table + (port_index * sizeof_ipc_entry_t));
    
    return port_addr;
}

uint64_t find_portSP(mach_port_name_t port) {
    uint64_t task_addr = our_task_addr_exportedBYTW;//ReadKernel64(our_port_addr_exportedBYTW + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT));
    uint64_t itk_space = ReadKernel64(task_addr + koffset(KSTRUCT_OFFSET_TASK_ITK_SPACE));
    uint64_t is_table = ReadKernel64(itk_space + koffset(KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE));
    
    uint32_t port_index = port >> 8;
    const int sizeof_ipc_entry_t = 0x18;
    
    uint64_t port_addr = ReadKernel64(is_table + (port_index * sizeof_ipc_entry_t));
    
    return port_addr;
}

uint64_t get_proc_struct_for_pid_TW(pid_t proc_pid) {
    
        kptr_t ret = KPTR_NULL;
        kptr_t const symbol = GETOFFSET(allproc);
        kptr_t const task = ReadKernel64(symbol);
        kptr_t const bsd_info = ReadKernel64(task + koffset(KSTRUCT_OFFSET_TASK_BSD_INFO));
        ret = bsd_info;
        printf("proc struct: 0x%llx\n", ret);

    out:;
        return ret;
    
    /*uint64_t proc = ReadKernel64(find_allproc());
    while (proc) {
        uint32_t pid = (uint32_t)ReadKernel32(proc + koffset(KSTRUCT_OFFSET_PROC_PID));
        if (pid == proc_pid){
            printf("our pid: %d proc struct: 0x%llx\n", pid, proc);
            return proc;
        }
        proc = ReadKernel64(proc);
    }*/
    
   // return 0;

}

char *Build_resource_path(char *filename);
void patch_amfid(pid_t amfid_pid);

#define PROC_ALL_PIDS        1
extern int proc_listpids(uint32_t type, uint32_t typeinfo, void *buffer, int buffersize);
extern int proc_pidpath(int pid, void * buffer, uint32_t  buffersize);

pid_t look_for_proc_internal(const char *name, bool (^match)(const char *path, const char *want))
{
    pid_t *pids = calloc(1, 3000 * sizeof(pid_t));
    int procs_cnt = proc_listpids(PROC_ALL_PIDS, 0, pids, 3000);
    if(procs_cnt > 3000) {
        pids = realloc(pids, procs_cnt * sizeof(pid_t));
        procs_cnt = proc_listpids(PROC_ALL_PIDS, 0, pids, procs_cnt);
    }
    int len;
    char pathBuffer[4096];
    for (int i=(procs_cnt-1); i>=0; i--) {
        if (pids[i] == 0) {
            continue;
        }
        memset(pathBuffer, 0, sizeof(pathBuffer));
        len = proc_pidpath(pids[i], pathBuffer, sizeof(pathBuffer));
        if (len == 0) {
            continue;
        }
        if (match(pathBuffer, name)) {
            free(pids);
            return pids[i];
        }
    }
    free(pids);
    return 0;
}

pid_t look_for_proc(const char *proc_name)
{
    return look_for_proc_internal(proc_name, ^bool (const char *path, const char *want) {
        if (!strcmp(path, want)) {
            return true;
        }
        return false;
    });
}

pid_t look_for_proc_basename(const char *base_name)
{
    return look_for_proc_internal(base_name, ^bool (const char *path, const char *want) {
        const char *base = path;
        const char *last = strrchr(path, '/');
        if (last) {
            base = last + 1;
        }
        if (!strcmp(base, want)) {
            return true;
        }
        return false;
    });
}

pid_t pidOfProcess(const char *name) {
    int numberOfProcesses = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    pid_t pids[numberOfProcesses];
    bzero(pids, sizeof(pids));
    proc_listpids(PROC_ALL_PIDS, 0, pids, (int)sizeof(pids));
    for (int i = 0; i < numberOfProcesses; ++i) {
        if (pids[i] == 0) {
            continue;
        }
        char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];
        bzero(pathBuffer, PROC_PIDPATHINFO_MAXSIZE);
        proc_pidpath(pids[i], pathBuffer, sizeof(pathBuffer));
        if (strlen(pathBuffer) > 0 && strcmp(pathBuffer, name) == 0) {
            return pids[i];
        }
    }
    return 0;
}
