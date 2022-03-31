//
//  amfi.c
//  LiRa-Rootfs
//
//  Created by hoahuynh on 2021/05/29.
//

#ifndef amfi_h
#define amfi_h

#include <stdio.h>
#include <stdbool.h>
#include <mach/machine/kern_return.h>
#include <mach-o/loader.h>


void platformize_amfi(pid_t pid);
bool grabEntitlementsForRootFS(uint64_t selfProc);
void resetEntitlementsForRootFS(uint64_t selfProc);
bool grabEntitlements(uint64_t selfProc);
void takeoverAmfid(int amfidPid);
uint64_t loadAddr(mach_port_t port);
void* AMFIDExceptionHandler(void* arg);
uint8_t* map_file_to_mem(const char* path);
uint64_t find_amfid_OFFSET_MISValidate_symbol(uint8_t* amfid_macho);

kern_return_t
mach_vm_read_overwrite(vm_map_t, mach_vm_address_t, mach_vm_size_t, mach_vm_address_t, mach_vm_size_t *);

kern_return_t
mach_vm_read(vm_map_t target_task, mach_vm_address_t address, mach_vm_size_t size, vm_offset_t *data, mach_msg_type_number_t *dataCnt);

kern_return_t
mach_vm_write(vm_map_t, mach_vm_address_t, vm_offset_t, mach_msg_type_number_t);

kern_return_t
mach_vm_region(vm_map_t, mach_vm_address_t *, mach_vm_size_t *, vm_region_flavor_t, vm_region_info_t, mach_msg_type_number_t *, mach_port_t *);

kern_return_t
mach_vm_deallocate(vm_map_t target, mach_vm_address_t address, mach_vm_size_t size);

#endif /* amfi_h */
