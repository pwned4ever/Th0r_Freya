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
#import <stdlib.h>
#import <mach/mach.h>
#import "OffsetHolder.h"//added tw

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

extern uint64_t our_procStruct_addr_exported;
extern uint64_t our_port_addr_exportedBYTW;
extern uint64_t our_task_addr_exportedBYTW;
extern uint64_t kernelbase_exportedBYTW;
extern mach_port_t tfp0_exportedBYTW;
extern int need_initialSSRenamed;
extern uint64_t our_kernel_procStruct_exportAstylez;
extern uint64_t our_kernel_taskStruct_exportAstylez;

uint64_t get_proc_struct_for_pid_TW(pid_t proc_pid);


//timewaste below
kern_return_t mach_vm_allocate(vm_map_t target, mach_vm_address_t *address, mach_vm_size_t size, int flags);
kern_return_t mach_vm_read_overwrite(vm_map_t target_task, mach_vm_address_t address, mach_vm_size_t size, mach_vm_address_t data, mach_vm_size_t *outsize);
kern_return_t mach_vm_write(vm_map_t target_task, mach_vm_address_t address, vm_offset_t data, mach_msg_type_number_t dataCnt);
kern_return_t mach_vm_deallocate(vm_map_t target, mach_vm_address_t address, mach_vm_size_t size);;
kern_return_t mach_vm_read(vm_map_t target_task, mach_vm_address_t address, mach_vm_size_t size, vm_offset_t *data, mach_msg_type_number_t *dataCnt);
kern_return_t mach_vm_map(vm_map_t target_task, mach_vm_address_t *address, mach_vm_size_t size, mach_vm_offset_t mask, int flags, mem_entry_name_port_t object, memory_object_offset_t offset, boolean_t copy, vm_prot_t cur_protection, vm_prot_t max_protection, vm_inherit_t inheritance);
kern_return_t mach_vm_region_recurse(vm_map_t target_task, mach_vm_address_t *address, mach_vm_size_t *size, natural_t *nesting_depth, vm_region_recurse_info_t info, mach_msg_type_number_t *infoCnt);
void init_kernel_memorytw(mach_port_t tfp0tw, uint64_t our_port_addrtw);

size_t kreadtw(uint64_t where, void *p, size_t size);
uint32_t rk32tw(uint64_t where);
uint64_t rk64tw(uint64_t where);
pid_t pidOfProcess(const char *name);
pid_t look_for_proc(const char *proc_name);


size_t kwritetw(uint64_t where, const void *p, size_t size);
void wk32tw(uint64_t where, uint32_t what);
void wk64tw(uint64_t where, uint64_t what);

void kfreetw(mach_vm_address_t address, vm_size_t size);
uint64_t kalloctw(vm_size_t size);

int kstrcmptw(uint64_t string1, uint64_t string2);
int kstrcmp_utw(uint64_t string1, char *string2);
unsigned long kstrlen(uint64_t string);

uint64_t find_porttw(mach_port_name_t port);
uint64_t find_portSP(mach_port_name_t port);

#endif /* KernelUtils_h */
