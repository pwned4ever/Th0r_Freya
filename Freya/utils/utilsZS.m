//
//  utils.m
//  freya
//
//  Created by Brandon Plank on 5/8/19.
//  Copyright © 2019 freya Team. All rights reserved.
//

#define KADD_SEARCH 0xfffffff007004000

#import <Foundation/Foundation.h>
#include <sys/utsname.h>
#include <mach-o/nlist.h>
#include <mach-o/getsect.h>
#include "kernel_memory.h"
#include "lzssdec.h"
#import <UIKit/UIView.h>
#include "find_port.h"
#include "kernel_slide.h"
#include "kernel_structs.h"
#include "utilsZS.h"
#include "shenanigans.h"
#include "common.h"
#include "ms_offs.h"
#include "bypass.h"
#include "unlocknvram.h"
#include "machswap.h"
#include "KernelUtils.h"
#include "remap_tfp_set_hsp.h"
#include "patchfinder64.h"
#include "parameters.h"
#include "PFOffs.h"
#include "ImportantHolders.h"
#include "kernel_memory.h"
#include "KernelUtils.h"
#include "OffsetHolder.h"
#include "offsets.h"
#include <sys/mount.h>
#include "sockPort.h"
#include <spawn.h>
#include <pwd.h>
#include "kernel_exec.h"
#include <copyfile.h>
#include "insert_dylib.h"
#include "vnode_utils.h"
#include "cpBootHash.h"
#include "libsnappy.h"
#include <sys/stat.h>
#include <sys/snapshot.h>
#include "ViewController.h"
#include "reboot.h"
#include "amfi_utils.h"
#include "ArchiveUtils.h"
#include "libproc.h"
#import "voucher_swap.h"
#import "kernel_call.h"
#import "machswap2.h"
#include <sys/sysctl.h>
#include "wasteoftime.h"
#include "remount.h"
#include "amfi.h"
#include "file_utils.h"
#include "cicuta_virosa.h"
#include "mycommon.h"
#include "undecimusRemove.h"
#include "electraRemove.h"
#include "chimeraRemove.h"
#include "FreyaRemove.h"
#include "SockPuppet3.h"


//#include "jelbrekLib.h"
/*
 
 kCFCoreFoundationVersionNumber =
 2.0      478.23
 * 2.1      478.26
 * 2.2      478.29
 * 3.0      478.47
 * 3.1      478.52
 * 3.2      478.61
 * 4.0      550.32
 * 4.1      550.38
 * 4.2      550.52
 * 4.3      550.58
 * 5.0      675.00
 * 5.1      690.10
 * 6.x      793.00
 * 7.0      847.20
 * 7.0.3    847.21
 * 7.1      847.26
 * 8.0      1140.10
 * 8.1      1141.14
 * 8.2      1142.16
 * 8.3      1144.17
 * 8.4      1145.15
 * 9.0      1240.1
 * 9.1      1241.11
 * 9.2      1242.13
 * 9.3      1280.30
 * 10.0     1348.00
 * 10.1     1348.00
 * 10.2     1348.22
 * 10.3     1349.56
 * 11.0     1443.00
 * 11.1     1445.32    ///1535.12
 * 11.2     1450.14
 * 11.3     1452.23
 * 11.4     1452.23
 * 12.0     1556.00
 * 12.1     1560.10
 * 12.2     1570.15
 * 12.3     1575.13
 * 12.4     1575.17
 * 12.5     1575.23
 * 13.0     1665.15
 * 13.1     1671.101
 * 13.2     1673.126
 * 13.3     1674.102
 * 13.4     1675.129
 * 13.5     1676.104
 * 14.0     1751.108
 * 14.1     1751.108
 * 14.2     1770.106
 * 14.3     1770.300
 * 14.4     1774.101
 * 14.5     1775.118
 * 14.6     1776.103
 * 14.7     1777.103
 * 14.8     1778.101
 * 15.0     1854
 * 15.1     1855.105
 * 15.2     1856.105
 * 15.3     1856.105
 * 15.4     1858.112
 */

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

bool isArm64e(void){
#if __arm64e__
    return true;
#else
    return false;
#endif
}


pid_t amfid_pid;
int always_AMFIPID;
int weneedaUICACHE = 0;
bool runShenPatchOWO = false;
int thejbdawaits = 0;
int ourtoolsextracted = 0;
int kickcheck = 0;
int doweneedamfidPatch = 0;


char *myenviron[] = {
    "PATH=/freya/usr/local/sbin:/freya/usr/local/bin:/freya/usr/sbin:/freya/usr/bin:/freya/sbin:/freya/bin:/freya/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games",
    "PS1=\\h:\\w \\u\\$ ",
    NULL
};

char *sysctlWithName(const char *name) {
    kern_return_t kr = KERN_FAILURE;
    char *ret = NULL;
    size_t *size = NULL;
    size = (size_t *)malloc(sizeof(size_t));
    if (size == NULL) goto out;
    bzero(size, sizeof(size_t));
    if (sysctlbyname(name, NULL, size, NULL, 0) != ERR_SUCCESS) goto out;
    ret = (char *)malloc(*size);
    if (ret == NULL) goto out;
    bzero(ret, *size);
    if (sysctlbyname(name, ret, size, NULL, 0) != ERR_SUCCESS) goto out;
    kr = KERN_SUCCESS;
    out:
    if (kr == KERN_FAILURE)
    {
        free(ret);
        ret = NULL;
    }
    free(size);
    size = NULL;
    return ret;
}

bool machineNameContains(const char *string) {
    char *machineName = sysctlWithName("hw.machine");
    if (machineName == NULL) return false;
    bool ret = strstr(machineName, string) != NULL;
    free(machineName);
    machineName = NULL;
    return ret;
}

NSString *getKernelBuildVersion() {
    NSString *kernelBuild = nil;
    NSString *cleanString = nil;
    char *kernelVersion = NULL;
    kernelVersion = sysctlWithName("kern.version");
    if (kernelVersion == NULL) return nil;
    cleanString = [NSString stringWithUTF8String:kernelVersion];
    free(kernelVersion);
    kernelVersion = NULL;
    cleanString = [[cleanString componentsSeparatedByString:@"; "] objectAtIndex:1];
    cleanString = [[cleanString componentsSeparatedByString:@"-"] objectAtIndex:1];
    cleanString = [[cleanString componentsSeparatedByString:@"/"] objectAtIndex:0];
    kernelBuild = [cleanString copy];
    return kernelBuild;
}

bool supportsExploit(int exploit) {

    
    //0 = MachSwap
    //1 = MachSwap2
    //2 = Voucher_Swap
    //3 = SockPort
    //6 = SockPuppet
    //4 = Timewaste
    //5 = cicuta?

    /** 12.0     1556.00
    * 12.1     1560.10
    * 12.2     1570.15
    * 12.3     1575.13
    * 12.4     1575.17
    * 12.5     1575.23*/
    
    vm_size_t kernel_page_size = 0;
    vm_size_t *out_page_size = NULL;
    host_t host = mach_host_self();
    if (!MACH_PORT_VALID(host)) goto out;
    out_page_size = (vm_size_t *)malloc(sizeof(vm_size_t));
    if (out_page_size == NULL) goto out;
    bzero(out_page_size, sizeof(vm_size_t));
    if (_host_page_size(host, out_page_size) != KERN_SUCCESS) goto out;
    kernel_page_size = *out_page_size;
    out:
    if (MACH_PORT_VALID(host)) mach_port_deallocate(mach_task_self(), host); host = HOST_NULL;
    free(out_page_size);
    out_page_size = NULL;
    
    NSString *minKernelBuildVersion = nil;
    NSString *maxKernelBuildVersion = nil;
    // * 13.0     1665.15
    //* 13.1     1671.101
    //* 13.2     1673.126
    //* 13.3     1674.102
   // * 13.4     1675.129
    //* 13.5     1676.104
    //* 14.0     1751.108
    //                if (machineNameContains("iPhone10,")) {//&&

    
    if ((kCFCoreFoundationVersionNumber >= 1575.17) && machineNameContains("iPhone10,")) { // > 12.4
        
    }
    switch (exploit) {
            
       /* case 6: {
            minKernelBuildVersion = @"4397.0.0.2.4~1";
            maxKernelBuildVersion = @"4903.270.47~7";// <- 12.4 @"4903.262.2~2";//ios 12.3
            break;
        }*/
        case 5: {
            if ((kCFCoreFoundationVersionNumber >= 1675.17) && (kCFCoreFoundationVersionNumber < 1751.108)) { // > 12.4
                minKernelBuildVersion = @"5397.0.0.2.4~1";
                maxKernelBuildVersion = @"9903.270.47~7";
                break;
            }
            // @"4903.270.47~7"

           
        }
           
        case 4: {
            minKernelBuildVersion = @"4397.0.0.2.4~1";
            maxKernelBuildVersion = @"5903.272.4~1";
            if ((kCFCoreFoundationVersionNumber >= 1575.17) && machineNameContains("iPhone10,")) { // > 12.4
                printf("hello iphone x\n");
            }
            // @"4903.270.47~7"

            break;
        }
        case 3: {
            minKernelBuildVersion = @"4397.0.0.2.4~1";

            if (kCFCoreFoundationVersionNumber == 1575.17) { // == 12.4
                if ((kCFCoreFoundationVersionNumber >= 1575.17) && machineNameContains("iPhone10,")) { // > 12.4
                    return false;
                }
                maxKernelBuildVersion = @"4903.270.47~7";// <- 12.4 @"4903.262.2~2";//ios 12.3

            } else {
                if ((kCFCoreFoundationVersionNumber >= 1575.17) && machineNameContains("iPhone10,")) { // > 12.4
                    return false;
                }
                maxKernelBuildVersion = @"4903.252.2~1";// <- 12.2 @"4903.262.2~2";//ios 12.3
            }

            break;
        }
        case 2: {
            if (kernel_page_size != 0x4000) {
                return false;
            }
            if (machineNameContains("iPad5,") &&
                kCFCoreFoundationVersionNumber >= 1535.12) {
                return false;
            }
            minKernelBuildVersion = @"4397.0.0.2.4~1";
            maxKernelBuildVersion = @"4903.240.8~8";//4903.242.2~1
            break;
        }
        case 0: {
            if (kernel_page_size != 0x1000 &&
                !machineNameContains("iPad5,") &&
                !machineNameContains("iPhone8,") &&
                !machineNameContains("iPad6,")) {
                return false;
            }
            minKernelBuildVersion = @"4397.0.0.2.4~1";
            maxKernelBuildVersion = @"4903.240.8~8";
            //            maxKernelBuildVersion = @"4903.232.2~1";// <- ios 12.1.1/2?  -- -- @"4903.240.8~8";

            break;
        }
        case 1: {
            minKernelBuildVersion = @"4397.0.0.2.4~1";
            maxKernelBuildVersion = @"4903.240.8~8"; //4903.242.2~1
            break;
        }
        default:
            return false;
            break;
    }
    //kernelBuildVersion    __NSCFString *    @"7195.62.1~4" iphone 8 14.3

    if (minKernelBuildVersion != nil && maxKernelBuildVersion != nil) {
        NSString *kernelBuildVersion = getKernelBuildVersion();
        if (kernelBuildVersion != nil) {
            if ([kernelBuildVersion compare:minKernelBuildVersion options:NSNumericSearch] != NSOrderedAscending && [kernelBuildVersion compare:maxKernelBuildVersion options:NSNumericSearch] != NSOrderedDescending) {
                return true;
            }
        }
    } else {
        return true;
    }
    
    return false;
}


int autoSelectExploit()
{
    
    
    
    //0 = MachSwap
    //1 = MachSwap2
    //2 = Voucher_Swap
    //3 = SockPort
    //6 = SockPuppet
    //4 = timewaste
    //5 = cicuta
    
    if (supportsExploit(0))
    {
        return 0;
        
    } else if (supportsExploit(1))
    {
        printf("supports machswap\n");
        return 1;
    } else if (supportsExploit(2))
    {
        return 2;
    } else if (supportsExploit(3))
    {
        return 3;
    } else if (supportsExploit(4))
    {
        return 4;
    }else if (supportsExploit(5))
    {
        return 5;
    }else if (supportsExploit(6)){
        return 6;
    }else {
        return 7;
    }
    
}

void set_csflags(uint64_t proc) {
    
    uint32_t csflags = ReadKernel32(proc + off_p_csflags);
    csflags |= CS_PLATFORM_BINARY;
    WriteKernel32(proc + off_p_csflags, csflags);
}

NSString *getNameFromInt(int exp_int) {
    if (exp_int == 0) {
        return @"Machswap";
    } else if (exp_int == 1) {
        return @"Machswap 2";
    } else if (exp_int == 2) {
        return @"Voucher_Swap";
    } else if (exp_int == 3) {
        return @"SockPort";
    } else if (exp_int == 4) {
        return @"Timewaste";
    } else if (exp_int == 5) {
        return @"Cicuta";
    } /*else if (exp_int == 6) {
        return @"SockPuppet";
    }*/ else {
        return @"ERROR";
    }
}

void initSettingsIfNotExist()
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:@"ExploitType"] == nil)
    {
        [defaults setInteger:0 forKey:@"ExploitType"];
        [defaults setInteger:0 forKey:@"PackagerType"];
        [defaults setInteger:0 forKey:@"LoadTweaks"];
        [defaults setInteger:1 forKey:@"RestoreFS"];
        [defaults setInteger:0 forKey:@"RootSetting"];
        [defaults setInteger:0 forKey:@"fixFS"];
        [defaults setInteger:0 forKey:@"forceuicache"];
        [defaults setValue:@"0x1111111111111111" forKey:@"Nonce"];
        [defaults setInteger:1 forKey:@"SetNonce"];
        [defaults synchronize];
        
        if ([getNameFromInt(autoSelectExploit())  isEqual: @"ERROR"])
        {
            showMSG(@"There was an error automatically selecting your exploit. The default has been set to machswap. Please change this under settings if you would like to use a different one.", false, false);
        } else {
            NSString *msgString = [NSString stringWithFormat:@"Since this is your first run, we have automatically selected what we think is the best exploit for your device. The exploit chosen is %@. If this is not your desired exploit, please change it under the settings menu.", getNameFromInt(autoSelectExploit())];
            
            showMSG(msgString, false, false);
            
            [defaults setInteger:autoSelectExploit() forKey:@"ExploitType"];
        }
        
        
    }
}

bool shouldSetNonce()
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults integerForKey:@"SetNonce"] == 0)
    {
        return true;
    } else {
        return false;
    }
}

NSString* getBootNonce()
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults valueForKey:@"Nonce"];
}

const char *userGenerator(void) {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@K_GENERATOR] == nil)
        return NULL;
    
    const char *generator = [[userDefaults objectForKey:@K_GENERATOR] UTF8String];
    char compareString[22];
    uint64_t rawGeneratorValue;
    sscanf(generator, "0x%16llx", &rawGeneratorValue);
    sprintf(compareString, "0x%016llx", rawGeneratorValue);
    if(strcmp(compareString, generator) != 0)
        return NULL;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:0 forKey:@"SetNonce"];
    //shouldSetNonce();
    return generator;
}

const char *genToSet(void) {
    const char *generator = userGenerator();
    if (generator == NULL)
        generator = strdup(K_freya_GENERATOR);
    
    return generator;
}

void saveCustomSetting(NSString *setting, int settingResult)
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:settingResult forKey:setting];
}

BOOL shouldLoadTweaks()
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults integerForKey:@"LoadTweaks"] == 0)
    {
        return true;
    } else {
        return false;
    }
}

BOOL shoulduicache()
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults integerForKey:@"forceuicache"] == 0)
    {
        return true;
    } else {
        return false;
    }
}
int getExploitType()
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return (int)[defaults integerForKey:@"ExploitType"];
}

int getPackagerType()
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return (int)[defaults integerForKey:@"PackagerType"];
}

BOOL isRootless()
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults integerForKey:@"RootSetting"] == 1)
    {
        return true;
    } else {
        return false;
    }
}

BOOL shouldfixFS()
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults integerForKey:@"fixFS"] == 0)
    {
        return true;
    } else {
        return false;
    }
}


BOOL shouldRestoreFS()
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults integerForKey:@"RestoreFS"] == 0)
    {
        return true;
    } else {
        return false;
    }
}


uint64_t selfproc() {
    // TODO use kcall(proc_find) + ZM_FIX_ADDR
    uint64_t proc = 0;
    if (proc == 0) {
        proc = ReadKernel64(current_task + OFFSET(task, bsd_info));
        NSLog(@"Found proc 0x%llx for PID %i", proc, getpid());    }
    return proc;
}

uint64_t fport(mach_port_name_t port)
{
    uint64_t task_port_addr = task_self_addr();
    uint64_t task_addr = ReadKernel64(task_port_addr + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT));
    uint64_t itk_space = ReadKernel64(task_addr + koffset(KSTRUCT_OFFSET_TASK_ITK_SPACE));
    uint64_t is_table = ReadKernel64(itk_space + koffset(KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE));
    uint32_t port_index = port >> 8;
    const int sizeof_ipc_entry_t = 0x18;
    uint64_t port_addr = ReadKernel64(is_table + (port_index * sizeof_ipc_entry_t));
    return port_addr;
}


void platformize(uint64_t proc) {
    uint64_t task = ReadKernel64(proc + off_task);
    uint32_t t_flags = ReadKernel32(task + off_t_flags);
    t_flags |= 0x400;
    WriteKernel32(task+off_t_flags, t_flags);
    uint32_t csflags = ReadKernel32(proc + off_p_csflags);
    WriteKernel32(proc + off_p_csflags, csflags | 0x24004001u);
}

void setcsflags(uint64_t proc) {
    uint32_t csflags = ReadKernel32(proc + off_p_csflags);
    uint32_t newflags = (csflags | CS_PLATFORM_BINARY | CS_INSTALLER | CS_GET_TASK_ALLOW | CS_DEBUGGED) & ~(CS_RESTRICT | CS_HARD | CS_KILL);
    WriteKernel32(proc + off_p_csflags, newflags);
}


void exploit_startxs(void);
void exploit_start(void);

/*
void runzec0ps() {
    if (isArm64e()) {
        bool isArm64e = true;

    }
    bool isArm64e = true;
    dothesploit();

    exploit_start();
    //exploit_start();
    
}

void runzec0psXS() {
    if (isArm64e()) {
        bool isArm64e = true;

    }
    bool isArm64e = true;

    exploit_startxs();
    //exploit_start();
    
}*/


void runMachswap() {
    
    dothesploit();

    offsets_t *ms_offs = get_machswap_offsets();
    machswap_exploit(ms_offs, &tfp0, &kbase);
    
    if (MACH_PORT_VALID(tfp0))
    {
        kernel_slide = (kbase - KADD_SEARCH);
        
    } else {
        util_info("ERROR!");
        exit(1);
    }
    if (tfp0 == 0) {
        util_info("ERROR!");
        NSString *str = [NSString stringWithFormat:@"ERROR TFP0: 0x%x", tfp0];
        showMSG(str, true, false);
        exit(7);
    } else {
        util_info("TFP0: 0x%x\nKERNEL BASE: 0x%llx\nKERNEL SLIDE: 0x%llx\nUID: %u, GID: %u ", tfp0, kbase, kernel_slide, getuid(), getgid());
    }
    
}

void runMachswap2() {
    printf("supports machswap2\n");
   // offsets_t *ms_offs = get_machswap_offsets();
   // machswap2_exploit(ms_offs, &tfp0, &kbase);
    dothesploit();

    if (MACH_PORT_VALID(tfp0))
    {
        kernel_slide = (kbase - KADD_SEARCH);
        
    } else {
        util_info("ERROR!");
        exit(1);
    }
    
    if (tfp0 == 0) {
        util_info("ERROR!");
        NSString *str = [NSString stringWithFormat:@"ERROR TFP0: 0x%x", tfp0];
        showMSG(str, true, false);
        exit(7);
    } else {
        util_info("TFP0: 0x%x\nKERNEL BASE: 0x%llx\nKERNEL SLIDE: 0x%llx\nUID: %u, GID: %u ", tfp0, kbase, kernel_slide, getuid(), getgid());
    }
    
}



//V_SWAP

uint64_t find_kernel_base_sockpuppet() {
    uint64_t hostport_addr = find_port_address_sockpuppet(mach_host_self(), MACH_MSG_TYPE_COPY_SEND);
    uint64_t realhost = ReadKernel64(hostport_addr + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT));
    
    uint64_t base = realhost & ~0xfffULL;
    // walk down to find the magic:
    for (int i = 0; i < 0x10000; i++) {
        if (ReadKernel32(base) == 0xfeedfacf) {
            return base;
        }
        base -= 0x1000;
    }
    return 0;
}

uint64_t find_kernel_base_timewaste() {
    
    if (kernelbase_exportedBYTW !=0) {
        return kernelbase_exportedBYTW;
    }
    uint64_t hostport_addr = find_port_address_timewaste(mach_host_self(), MACH_MSG_TYPE_COPY_SEND);
    uint64_t realhost = ReadKernel64(hostport_addr + koffset_TW(KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT_TW));
    
    uint64_t base = realhost & ~0xfffULL;
    // walk down to find the magic:
    for (int i = 0; i < 0x10000; i++) {
        if (ReadKernel32(base) == 0xfeedfacf) {
            return base;
        }
        base -= 0x1000;
    }
    return 0;
}


void runVoucherSwap() {
    dothesploit();

    voucher_swap();
    
    if (MACH_PORT_VALID(tfp0)) {
        
        kernel_slide_init();
        kbase = (kernel_slide + KADD_SEARCH);
        set_selfproc(selfproc());
        runShenPatchOWO = true;
        
    } else {
        util_info("ERROR!");
        exit(1);
    }
    if (tfp0 == 0) {
        util_info("ERROR!");
        NSString *str = [NSString stringWithFormat:@"ERROR TFP0: 0x%x", tfp0];
        showMSG(str, true, false);
        exit(7);
    } else {
        util_info("TFP0: 0x%x\nKERNEL BASE: 0x%llx\nKERNEL SLIDE: 0x%llx\nUID: %u, GID: %u ", tfp0, kbase, kernel_slide, getuid(), getgid());
    }
}

void runCicuta() {
    if (cicuta_virosa() == 0) {
        if (MACH_PORT_VALID(tfp0)) {
            if (kernelbase_exportedBYTW != 0) {
                kbase = kernelbase_exportedBYTW; }
            else {
                kbase = find_kernel_base_sockpuppet(); }
            kernel_slide = (kbase - KADD_SEARCH); // runShenPatchOWO = true;
        }
        if (tfp0 == 0) { util_info("ERROR!");
            NSString *str = [NSString stringWithFormat:@"Exploit failed, however with sockpuppet. You can open the app up again and just keep trying again until it either, kernel panics or succeeds. tfp: 0x%x", tfp0];
            showMSG(str, true, false);
            dispatch_sync( dispatch_get_main_queue(), ^{
                UIApplication *app = [UIApplication sharedApplication];
                [app performSelector:@selector(suspend)]; //wait 2 seconds while app is going background
                [NSThread sleepForTimeInterval:1.0]; //exit app when app is in background
                exit(0); });
        } else {
            util_info("TFP0: 0x%x\nKERNEL BASE: 0x%llx\nKERNEL SLIDE: 0x%llx\nUID: %u, GID: %u ", tfp0, kbase, kernel_slide, getuid(), getgid());            ourprogressMeter();
        }
    }
    
}
void runSockPort() {
    ourprogressMeter();
    dothesploit();

    get_tfp0();
    
    if (MACH_PORT_VALID(tfp0))
    {
        if (kernelbase_exportedBYTW != 0) {
            kbase = kernelbase_exportedBYTW;
        } else {
            kbase = find_kernel_base_sockpuppet();
        }
        kernel_slide = (kbase - KADD_SEARCH);
       // runShenPatchOWO = true;
        
    }
    if (tfp0 == 0) {
        util_info("ERROR!");
        NSString *str = [NSString stringWithFormat:@"Exploit failed, however with sockpuppet. You can open the app up again and just keep trying again until it either, kernel panics or succeeds. tfp: 0x%x", tfp0];
        showMSG(str, true, false);
        
        dispatch_sync( dispatch_get_main_queue(), ^{
            UIApplication *app = [UIApplication sharedApplication];
            [app performSelector:@selector(suspend)];

            //wait 2 seconds while app is going background
            [NSThread sleepForTimeInterval:1.0];

            //exit app when app is in background
            exit(0);

        });
        

        
    } else {
        util_info("TFP0: 0x%x\nKERNEL BASE: 0x%llx\nKERNEL SLIDE: 0x%llx\nUID: %u, GID: %u ", tfp0, kbase, kernel_slide, getuid(), getgid());
        ourprogressMeter();
    }
    
}

/*void runSockPuppet() {
    ourprogressMeter();
    dothesploit();
    SockPuppet3.run;
    
    if (SYSTEM_VERSION_EQUAL_TO(@"12.4") || SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"12.2")){ }
            if (!([SockPuppet3 run])){
     return false;
     }
     tfp0 = [SockPuppet3 fakeKernelTaskPort];
     init_kernel_memory(tfp0);
     task_addr_cache = [SockPuppet3 currentTaskAddress];
     
     uint64_t itk_space = rk64(task_addr_cache + koffset(KSTRUCT_OFFSET_TASK_ITK_SPACE));
     uint64_t task_xd = rk64(itk_space + 0x28);
     uint64_t selfproc = rk64(task_xd + koffset(KSTRUCT_OFFSET_TASK_BSD_INFO));
     selfproc_cached = selfproc;
     
     kbase = get_kbase(&kslide, tfp0);
     
     if (escapeSandboxSock() == false){
     return false;
     }
     } else {
     time_waste();
     kbase = get_kbase(&kslide, tfp0);
     if (escapeSandboxTime() == false){
     return false;
     }
     }
     
     if (tfp0 != 0x0){
     return true;
     }
     return false;
     
     
    if (MACH_PORT_VALID(tfp0)) {
        if (kernelbase_exportedBYTW != 0) {
            kbase = kernelbase_exportedBYTW; }
        else {
            kbase = find_kernel_base_sockpuppet(); }
        kernel_slide = (kbase - KADD_SEARCH);// runShenPatchOWO = true;
    }
    if (tfp0 == 0) {
        util_info("ERROR!");
        NSString *str = [NSString stringWithFormat:@"Exploit failed, however with sockpuppet. You can open the app up again and just keep trying again until it either, kernel panics or succeeds. tfp: 0x%x", tfp0];
        showMSG(str, true, false);
        dispatch_sync( dispatch_get_main_queue(), ^{
            UIApplication *app = [UIApplication sharedApplication];
            [app performSelector:@selector(suspend)]; //wait 2 seconds while app is going background
            [NSThread sleepForTimeInterval:1.0]; //exit app when app is in background
            exit(0); }); }
    else {
        util_info("TFP0: 0x%x\nKERNEL BASE: 0x%llx\nKERNEL SLIDE: 0x%llx\nUID: %u, GID: %u", tfp0, kbase, kernel_slide, getuid(), getgid());
        ourprogressMeter(); }
}
*/
void runTIMEWaste()
{
    ourprogressMeter();
    struct utsname u = { 0 };
    uname(&u);
    if ((SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"12.3")) || (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"12.4.1"))) {
        if (!strcmp(u.machine, "iPhone8,1") || (!strcmp(u.machine, "iPhone8,2"))) {
            printf("i6s & 6s+ -----------\n"); }
        else if (!strcmp(u.machine, "iPhone8,4")) {
            printf("iSE-----------\n"); }
        else if (!strcmp(u.machine, "iPhone6,1") || (!strcmp(u.machine, "iPhone6,2") || (!strcmp(u.machine, "iPhone7,1") || (!strcmp(u.machine, "iPhone7,2"))))) {
            printf("i5s & i6  & 6+ -----------\n");
            printf("Hello %s ---------------\n", u.machine);
            juswaitn();
        }
        else if (!strcmp(u.machine, "iPad5,3") || (!strcmp(u.machine, "iPad5,4") || (!strcmp(u.machine, "iPad4,2") || (!strcmp(u.machine, "iPad4,3"))))) {
            printf("iPad air 1 & 2 -----------\n"); }
        else if (!strcmp(u.machine, "iPad4,4") || (!strcmp(u.machine, "iPad4,5"))) {
            printf("iPad mini 2 -----------\n");
            juswaitn4pad();

        }
        else if (!strcmp(u.machine, "iPod7,1")) {
            printf("iPod 6 -----------\n"); }
    }
    dothesploit();

    get_tfp0_waste();
    
    if (MACH_PORT_VALID(tfp0))
    {
        kbase = find_kernel_base_timewaste();
        kernel_slide = (kbase - KADD_SEARCH);
        runShenPatchOWO = true;
        
    }
    if (tfp0 == 0) { util_info("ERROR!");
        NSString *str = [NSString stringWithFormat:@"Exploit failed, Please reboot your device and try again. Timewaste exploit will not succeed on this bootup unfortunately."];
        showMSG(str, true, false);
        dispatch_sync( dispatch_get_main_queue(), ^{
            UIApplication *app = [UIApplication sharedApplication];
            [app performSelector:@selector(suspend)];//wait 2 seconds while app is going background
            [NSThread sleepForTimeInterval:1.0];//exit app when app is in background
            exit(0); });
    } else {
        util_info("TFP0: 0x%x\nKERNEL BASE: 0x%llx\nKERNEL SLIDE: 0x%llx\nUID: %u, GID: %u ", tfp0, kbase, kernel_slide, getuid(), getgid());
        runShenPatchOWO = true;

        ourprogressMeter();
    }
    
}

void runExploit(int expType)
{
    //0 = MachSwap //1 = MachSwap2 //2 = Voucher_Swap //3 = Sockport //6 = SockPuppet //4 = timewaste //5 = cicuta
    if (expType == 0) { util_info("Running MachSwap..."); runMachswap(); }
    else if (expType == 1) { util_info("Running MachSwap2"); runMachswap2(); }
    else if (expType == 2) { util_info("Running Voucher_Swap..."); runVoucherSwap(); }
    else if (expType == 3) { util_info("Running SockPort..."); runSockPort();
        if (MACH_PORT_VALID(kernel_task_port)) {
            set_tfp0(kernel_task_port);
            kernel_slide_init();
            kbase = (kernel_slide + KADD_SEARCH);
            NSString *str = [NSString stringWithFormat:@"TFP0: 0x%x", tfp0];
            showMSG(str, true, false); } }
    else if (expType == 4) { util_info("Running Timewaste..."); runTIMEWaste(); printf("TFP0: 0x%x\nTFP0 from tw: 0x%x\n", tfp0, tfp0_exportedBYTW);
        if (MACH_PORT_VALID(kernel_task_port)) {
            set_tfp0(kernel_task_port);
            kernel_slide_init();
            kbase = (kernel_slide + KADD_SEARCH);
            NSString *str = [NSString stringWithFormat:@"TFP0: 0x%x", tfp0];
            showMSG(str, true, false); } }
    else if (expType == 5){ util_info("Running Cicuta Virosa..."); runCicuta();printf("TFP0: 0x%x\nTFP0 from Cicuta: 0x%x\n", tfp0, tfp0_exportedBYTW);
        if (MACH_PORT_VALID(kernel_task_port)) {
            set_tfp0(kernel_task_port);
            kernel_slide_init();
            kbase = (kernel_slide + KADD_SEARCH);
            NSString *str = [NSString stringWithFormat:@"TFP0: 0x%x", tfp0];
            showMSG(str, true, false); } }
    /*else if (expType == 6){ util_info("Running Sock Puppet..."); runSockPuppet(); printf("TFP0: 0x%x\nTFP0 from Cicuta: 0x%x\n", tfp0, tfp0_exportedBYTW);
        if (MACH_PORT_VALID(kernel_task_port)) {
            set_tfp0(kernel_task_port);
            kernel_slide_init();
            kbase = (kernel_slide + KADD_SEARCH);
            NSString *str = [NSString stringWithFormat:@"TFP0: 0x%x", tfp0];
            showMSG(str, true, false); } }*/
    else { util_info("No Exploit? Tf..."); exit(1); }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

NSString *get_path_res(NSString *resource) {
    static NSString *sourcePath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sourcePath = [[NSBundle mainBundle] bundlePath];
    });
    
    NSString *path = [[sourcePath stringByAppendingPathComponent:resource] stringByStandardizingPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    return path;
}

NSString *get_bootstrap_file(NSString *file)
{
    return get_path_res([@"bootstrap/" stringByAppendingString:file]);
}
NSString *get_bootstrap_fileDEBS(NSString *file)
{
    return get_path_res([@"bootstrap/DEBS/" stringByAppendingString:file]);
}

NSString *get_debian_file(NSString *file)
{
    //return [@"/freya/DEBS/" stringByAppendingString:file];
    return [@"/freya/DEBS/" stringByAppendingString:file];
}

NSString *get_TweakInject_file(NSString *file)
{
    return [@"/usr/lib/TweakInject/" stringByAppendingString:file];
    //return get_path_res([@"bootstrap/DEBS/" stringByAppendingString:file]);
}
NSString *get_prefbundle_file(NSString *file)
{
    return [@"/Library/PreferenceBundles/" stringByAppendingString:file];
    //return get_path_res([@"bootstrap/DEBS/" stringByAppendingString:file]);
}
NSString *get_prefloader_file(NSString *file)
{
    return [@"/Library/PreferenceLoader/" stringByAppendingString:file];
    //return get_path_res([@"bootstrap/DEBS/" stringByAppendingString:file]);
}
NSString *get_prefbundleall_file(NSString *file)
{
    return [@"/Library/PreferenceBundles/*/" stringByAppendingString:file];
    //return get_path_res([@"bootstrap/DEBS/" stringByAppendingString:file]);
}
NSString *get_prefloaderall_file(NSString *file)
{
    return [@"/Library/PreferenceLoader/*/" stringByAppendingString:file];
    //return get_path_res([@"bootstrap/DEBS/" stringByAppendingString:file]);
}
NSString *get_debian12_file(NSString *file)
{
    return [@"/freya/DEBS_4_ios12_updates/" stringByAppendingString:file];
    //return get_path_res([@"bootstrap/DEBS/" stringByAppendingString:file]);
}


void ls (const char *path) {
    NSError *error;
    NSString *pathToSearch = [NSString stringWithUTF8String:path];
    NSArray *filesInDir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pathToSearch error:&error];
    
    if (error) {
        LOG("ERROR LS: %@", error);
    } else {
        NSLog(@"Contents Of %@:", pathToSearch);
        for (NSString *file in filesInDir) {
            NSLog(@"%@", file);
        }
    }
}

bool canRead(const char *file) {
    NSString *path = @(file);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return ([fileManager attributesOfItemAtPath:path error:nil]);
}

static void *load_bytes2(FILE *obj_file, off_t offset, uint32_t size) {
    void *buf = calloc(1, size);
    fseek(obj_file, offset, SEEK_SET);
    fread(buf, size, 1, obj_file);
    return buf;
}

static inline bool clean_file(const char *file) {
    NSString *path = @(file);
    if ([[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil]) {
        return [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    return YES;
}

uint32_t find_macho_header(FILE *file) {
    uint32_t off = 0;
    uint32_t *magic = load_bytes2(file, off, sizeof(uint32_t));
    while ((*magic & ~1) != 0xFEEDFACE) {
        off++;
        magic = load_bytes2(file, off, sizeof(uint32_t));
    }
    return off - 1;
}

static inline bool createFile(const char *file, int owner, mode_t mode) {
    NSString *path = @(file);
    return ([[NSFileManager defaultManager] fileExistsAtPath:path] &&
            [[NSFileManager defaultManager] setAttributes:@{NSFileOwnerAccountID: @(owner), NSFileGroupOwnerAccountID: @(owner), NSFilePosixPermissions: @(mode)} ofItemAtPath:path error:nil]);
}

bool ensure_directory(const char *directory, int owner, mode_t mode) {
    NSString *path = @(directory);
    NSFileManager *fm = [NSFileManager defaultManager];
    id attributes = [fm attributesOfItemAtPath:path error:nil];
    if (attributes &&
        [attributes[NSFileType] isEqual:NSFileTypeDirectory] &&
        [attributes[NSFileOwnerAccountID] isEqual:@(owner)] &&
        [attributes[NSFileGroupOwnerAccountID] isEqual:@(owner)] &&
        [attributes[NSFilePosixPermissions] isEqual:@(mode)]
        ) {
        // Directory exists and matches arguments
        return true;
    }
    if (attributes) {
        if ([attributes[NSFileType] isEqual:NSFileTypeDirectory]) {
            // Item exists and is a directory
            return [fm setAttributes:@{
                                       NSFileOwnerAccountID: @(owner),
                                       NSFileGroupOwnerAccountID: @(owner),
                                       NSFilePosixPermissions: @(mode)
                                       } ofItemAtPath:path error:nil];
        } else if (![fm removeItemAtPath:path error:nil]) {
            // Item exists and is not a directory but could not be removed
            return false;
        }
    }
    // Item does not exist at this point
    return [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:@{
                                                                                       NSFileOwnerAccountID: @(owner),
                                                                                       NSFileGroupOwnerAccountID: @(owner),
                                                                                       NSFilePosixPermissions: @(mode)
                                                                                       } error:nil];
}



bool is_mountpoint(const char *filename) {
    struct stat buf;
    if (lstat(filename, &buf) != ERR_SUCCESS) {
        return false;
    }
    
    if (!S_ISDIR(buf.st_mode))
        return false;
    
    char *cwd = getcwd(NULL, 0);
    int rv = chdir(filename);
    assert(rv == ERR_SUCCESS);
    struct stat p_buf;
    rv = lstat("..", &p_buf);
    assert(rv == ERR_SUCCESS);
    if (cwd) {
        chdir(cwd);
        free(cwd);
    }
    return buf.st_dev != p_buf.st_dev || buf.st_ino == p_buf.st_ino;
}




void set_tfplatform(uint64_t proc) {
    // task.t_flags & TF_PLATFORM
    uint64_t task = ReadKernel64(proc + off_task);
    uint32_t t_flags = ReadKernel32(task + off_t_flags);
    t_flags |= 0x400;
    WriteKernel32(task+off_t_flags, t_flags);
}





void saveOffs() {
    remove("/private/var/tmp/jb");
    unlink("/private/var/tmp/jb");
    mkdir("/private/var/tmp/jb", 0777);
    _assert(chdir("/private/var/tmp/jb") == ERR_SUCCESS, @"Failed to create jailbreak directory.", true);
    //_assert(chdir("/freya") == ERR_SUCCESS, @"Failed to create jailbreak directory.", true);

   // NSString *offsetsFile = @"/freya/offsets.plist";
    NSString *offsetsFile = @"/private/var/tmp/jb/offsets.plist";
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
#define ADDRSTRING(val)        [NSString stringWithFormat:@ADDR, val]
#define CACHEADDR(value, name) do { \
dictionary[@(name)] = ADDRSTRING(value); \
} while (false)
#define CACHEOFFSET(offset, name) CACHEADDR(GETOFFSET(offset), name)
    
    CACHEADDR(kbase, "KernelBase");
    CACHEADDR(ReadKernel64(ReadKernel64(GETOFFSET(kernel_task)) + koffset(KSTRUCT_OFFSET_TASK_BSD_INFO)), "KernProcAddr");
    CACHEADDR(GETOFFSET(zone_map_ref) - kernel_slide, "ZoneMapOffset");
    CACHEADDR(ReadKernel64(GETOFFSET(OSBoolean_True)) + sizeof(void *), "OSBoolean_False");
    CACHEADDR(ReadKernel64(GETOFFSET(OSBoolean_True)), "OSBoolean_True");
    CACHEOFFSET(kernel_task, "KernelTask");
    CACHEOFFSET(trustcache, "trust_cache");
    CACHEOFFSET(pmap_load_trust_cache, "pmap_load_trust_cache");
    CACHEOFFSET(smalloc, "smalloc");
    CACHEOFFSET(add_x0_x0_0x40_ret, "add_x0_x0_0x40_ret");
    CACHEOFFSET(zone_map_ref, "zone_map_ref");
    CACHEOFFSET(osunserializexml, "osunserializexml");
    CACHEOFFSET(vfs_context_current, "vfs_context_current");
    CACHEOFFSET(vnode_lookup, "vnode_lookup");
    CACHEOFFSET(vnode_put, "vnode_put");
    CACHEOFFSET(kalloc_canblock, "kalloc_canblock");
    CACHEOFFSET(ubc_cs_blob_allocate_site, "ubc_cs_blob_allocate_site");
    CACHEOFFSET(cs_validate_csblob, "cs_validate_csblob");
    CACHEOFFSET(cs_find_md, "cs_find_md");
    CACHEOFFSET(cs_blob_generation_count, "cs_blob_generation_count");
    CACHEOFFSET(kfree, "kfree");
    CACHEOFFSET(smalloc, "Smalloc");
    CACHEOFFSET(allproc, "AllProc");
    CACHEOFFSET(paciza_pointer__l2tp_domain_module_stop, "P2Stop");
    CACHEOFFSET(paciza_pointer__l2tp_domain_module_start, "P2Start");
    CACHEOFFSET(l2tp_domain_inited, "L2DI");
    CACHEOFFSET(sysctl__net_ppp_l2tp, "CTL2");
    CACHEOFFSET(sysctl_unregister_oid, "CTLUO");
    CACHEOFFSET(mov_x0_x4__br_x5, "Mx0");
    CACHEOFFSET(mov_x9_x0__br_x1, "Mx9");
    CACHEOFFSET(mov_x10_x3__br_x6, "Mx10");
    CACHEOFFSET(kernel_forge_pacia_gadget, "KFPG");
    CACHEOFFSET(IOUserClient__vtable, "IOUserClient__vtable");
    CACHEOFFSET(IORegistryEntry__getRegistryEntryID, "IORegistryEntry__getRegistryEntryID");
    CACHEOFFSET(proc_rele, "proc_rele");
    
#undef CACHEOFFSET
#undef CACHEADDR
    if (![[NSMutableDictionary dictionaryWithContentsOfFile:offsetsFile] isEqual:dictionary]) {
        util_info("Saving Offsets For JelbrekD...");
        savedoffs();

        _assert(([dictionary writeToFile:offsetsFile atomically:YES]), @"Failed to save offsets.", true);
        _assert(createFile(offsetsFile.UTF8String, 0, 0644), @"Failed to save offsets.", true);
        util_info("Successfully saved offsets!");
    }
}

void saveOffs_rootless() {
    
    _assert(chdir("/var/containers/Bundle/freya") == ERR_SUCCESS, @"Failed to create jailbreak directory.", true);
    
    
    NSString *offsetsFile = @"/var/containers/Bundle/freya/offsets.plist";
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
#define ADDRSTRING(val)        [NSString stringWithFormat:@ADDR, val]
#define CACHEADDR(value, name) do { \
dictionary[@(name)] = ADDRSTRING(value); \
} while (false)
#define CACHEOFFSET(offset, name) CACHEADDR(GETOFFSET(offset), name)
    
    CACHEADDR(kbase, "KernelBase");
    CACHEADDR(ReadKernel64(ReadKernel64(GETOFFSET(kernel_task)) + koffset(KSTRUCT_OFFSET_TASK_BSD_INFO)), "KernProcAddr");
    CACHEADDR(GETOFFSET(zone_map_ref) - kernel_slide, "ZoneMapOffset");
    CACHEADDR(ReadKernel64(GETOFFSET(OSBoolean_True)) + sizeof(void *), "OSBoolean_False");
    CACHEADDR(ReadKernel64(GETOFFSET(OSBoolean_True)), "OSBoolean_True");
    CACHEOFFSET(kernel_task, "KernelTask");
    CACHEOFFSET(trustcache, "trust_cache");
    CACHEOFFSET(pmap_load_trust_cache, "pmap_load_trust_cache");
    CACHEOFFSET(smalloc, "smalloc");
    CACHEOFFSET(add_x0_x0_0x40_ret, "add_x0_x0_0x40_ret");
    CACHEOFFSET(zone_map_ref, "zone_map_ref");
    CACHEOFFSET(osunserializexml, "osunserializexml");
    CACHEOFFSET(vfs_context_current, "vfs_context_current");
    CACHEOFFSET(vnode_lookup, "vnode_lookup");
    CACHEOFFSET(vnode_put, "vnode_put");
    CACHEOFFSET(kalloc_canblock, "kalloc_canblock");
    CACHEOFFSET(ubc_cs_blob_allocate_site, "ubc_cs_blob_allocate_site");
    CACHEOFFSET(cs_validate_csblob, "cs_validate_csblob");
    CACHEOFFSET(cs_find_md, "cs_find_md");
    CACHEOFFSET(cs_blob_generation_count, "cs_blob_generation_count");
    CACHEOFFSET(kfree, "kfree");
    CACHEOFFSET(smalloc, "Smalloc");
    CACHEOFFSET(allproc, "AllProc");
    CACHEOFFSET(paciza_pointer__l2tp_domain_module_stop, "P2Stop");
    CACHEOFFSET(paciza_pointer__l2tp_domain_module_start, "P2Start");
    CACHEOFFSET(l2tp_domain_inited, "L2DI");
    CACHEOFFSET(sysctl__net_ppp_l2tp, "CTL2");
    CACHEOFFSET(sysctl_unregister_oid, "CTLUO");
    CACHEOFFSET(mov_x0_x4__br_x5, "Mx0");
    CACHEOFFSET(mov_x9_x0__br_x1, "Mx9");
    CACHEOFFSET(mov_x10_x3__br_x6, "Mx10");
    CACHEOFFSET(kernel_forge_pacia_gadget, "KFPG");
    CACHEOFFSET(IOUserClient__vtable, "IOUserClient__vtable");
    CACHEOFFSET(IORegistryEntry__getRegistryEntryID, "IORegistryEntry__getRegistryEntryID");
    CACHEOFFSET(proc_rele, "proc_rele");
    
#undef CACHEOFFSET
#undef CACHEADDR
    if (![[NSMutableDictionary dictionaryWithContentsOfFile:offsetsFile] isEqual:dictionary]) {
        util_info("Saving Offsets For JelbrekD...");
        _assert(([dictionary writeToFile:offsetsFile atomically:YES]), @"Failed to save offsets.", true);
        _assert(createFile(offsetsFile.UTF8String, 0, 0644), @"Failed to save offsets.", true);
        util_info("Successfully saved offsets!");
    }
}


kptr_t swap_sandbox(kptr_t proc, kptr_t sandbox) {
    kptr_t ret = KPTR_NULL;
    kptr_t const ucred = ReadKernel64(proc + koffset(KSTRUCT_OFFSET_PROC_UCRED));
    kptr_t const cr_label = ReadKernel64(ucred + koffset(KSTRUCT_OFFSET_UCRED_CR_LABEL));
    kptr_t const sandbox_addr = cr_label + 0x8 + 0x8;
    kptr_t const current_sandbox = ReadKernel64(sandbox_addr);
    WriteKernel64(sandbox_addr, sandbox);
    ret = current_sandbox;
    out:;
    return ret;
}











void getOffsets() {
    
    findoffs();
    util_info("Initializing patchfinder64...");
    const char *original_kernel_cache_path = "/System/Library/Caches/com.apple.kernelcaches/kernelcache";
    
    if (!canRead(original_kernel_cache_path))
    {
        swap_sandbox(get_selfproc(), KPTR_NULL);
    }
    
    NSString *homeDirectory = NSHomeDirectory();
    
    const char *decompressed_kernel_cache_path = [homeDirectory stringByAppendingPathComponent:@"Documents/kernelcache.dec"].UTF8String;
    util_info("DECOMPRESSED KERNEL CACHE AT: %s", decompressed_kernel_cache_path);
    if (!canRead(decompressed_kernel_cache_path)) {
        FILE *original_kernel_cache = fopen(original_kernel_cache_path, "rb");
        _assert(original_kernel_cache != NULL, @"Failed to initialize patchfinder64.", true);
        uint32_t macho_header_offset = find_macho_header(original_kernel_cache);
        _assert(macho_header_offset != 0, @"Failed to initialize patchfinder64.", true);
        char *args[5] = { "lzssdec", "-o", (char *)[NSString stringWithFormat:@"0x%x", macho_header_offset].UTF8String, (char *)original_kernel_cache_path, (char *)decompressed_kernel_cache_path};
        _assert(lzssdec(5, args) == ERR_SUCCESS, @"Failed to initialize patchfinder64.", true);
        fclose(original_kernel_cache);
        
    }
    struct utsname u = { 0 };
    _assert(uname(&u) == ERR_SUCCESS, @"Failed to initialize patchfinder64.", true);
    if (init_kernel(NULL, 0, decompressed_kernel_cache_path) != ERR_SUCCESS || find_strref(u.version, 1, string_base_const, true, false) == 0) {
        _assert(clean_file(decompressed_kernel_cache_path), @"Failed to initialize patchfinder64.", true);
        _assert(false, @"Failed to initialize patchfinder64.", true);
    }
    if (auth_ptrs) {
        printf("Detected A12 Device.\n");
        pmap_load_trust_cache = _pmap_load_trust_cache;
        setA12(1);
    }
    if (monolithic_kernel) {
        printf("Detected monolithic kernel.\n");
    }
    printf("Successfully initialized patchfinder64.\n");
    
    //This has to be a define rather than its own void. damn.
    #define findPFOffset(x) do { \
    SETOFFSET(x, find_symbol("_" #x)); \
    if (!ISADDR(GETOFFSET(x))) SETOFFSET(x, find_ ##x()); \
    /*LOG("Offset: "#x " = " ADDR, GETOFFSET(x)); \*/\
    _assert(ISADDR(GETOFFSET(x)), @"Failed to find " #x " offset.", true); \
    SETOFFSET(x, GETOFFSET(x) + kernel_slide); \
    } while (false)
    
    //Get Strlen for jbd
    findPFOffset(strlen);
    //Get AllProc for jbd
    findPFOffset(allproc);
    //find kenrel task
    findPFOffset(kernel_task);
    //our_kernel_taskStruct_exportAstylez = GETOFFSET(kernel_task);;// ReadKernel64(GETOFFSET(kernel_task));//
    //our_kernel_taskStruct_exportAstylez = ReadKernel64(our_kernel_taskStruct_exportAstylez);//

    //Get KFree for jbd
    findPFOffset(kfree);
    //Get cs_gen_count for jbd
    findPFOffset(cs_blob_generation_count);
    //Get cs_blob_allocate_site for jbd
    findPFOffset(ubc_cs_blob_allocate_site);
    //Get cs_validate_csblob for jbd
    findPFOffset(cs_validate_csblob);
    //Get kalloc_canblock for jbd
    findPFOffset(kalloc_canblock);
    //Get cs_find_md for jbd
    findPFOffset(cs_find_md);
    //Get AllProc for jbd
    findPFOffset(allproc);
    //Get Release Proc for jbd
    findPFOffset(proc_rele);
    
    //Voucher Swap
    findPFOffset(shenanigans);
    
    //NVRam
    findPFOffset(IOMalloc);
    findPFOffset(IOFree);
    
    
    findPFOffset(trustcache);
    findPFOffset(OSBoolean_True);
    findPFOffset(osunserializexml);
    findPFOffset(smalloc);
    if (!auth_ptrs) {
        findPFOffset(add_x0_x0_0x40_ret);
    }
    findPFOffset(zone_map_ref);
    findPFOffset(vfs_context_current);
    findPFOffset(vnode_lookup);
    findPFOffset(vnode_put);
    findPFOffset(lck_mtx_lock);
    findPFOffset(lck_mtx_unlock);
    if (kCFCoreFoundationVersionNumber >= 1535.12) {
        findPFOffset(vnode_get_snapshot);
        findPFOffset(fs_lookup_snapshot_metadata_by_name_and_return_name);
        findPFOffset(apfs_jhash_getvnode);
    }
    if (auth_ptrs) {
        findPFOffset(pmap_load_trust_cache);
        findPFOffset(paciza_pointer__l2tp_domain_module_start);
        findPFOffset(paciza_pointer__l2tp_domain_module_stop);
        findPFOffset(l2tp_domain_inited);
        findPFOffset(sysctl__net_ppp_l2tp);
        findPFOffset(sysctl_unregister_oid);
        findPFOffset(mov_x0_x4__br_x5);
        findPFOffset(mov_x9_x0__br_x1);
        findPFOffset(mov_x10_x3__br_x6);
        findPFOffset(kernel_forge_pacia_gadget);
        findPFOffset(kernel_forge_pacda_gadget);
        findPFOffset(IOUserClient__vtable);
        findPFOffset(IORegistryEntry__getRegistryEntryID);
    }
    #undef findPFOffset
    
    //We got offsets.
    found_offs = true;

    term_kernel();
    
    clean_file(decompressed_kernel_cache_path);
    
    if (runShenPatchOWO == false)
    {
        printf("We are going to use the shenanigans patch.\n");
        runShenPatch();
    }

}



void setGID(gid_t gid, uint64_t proc) {
    if (getgid() == gid) return;
    uint64_t ucred = ReadKernel64(proc + off_p_ucred);
    WriteKernel32(proc + off_p_gid, gid);
    WriteKernel32(proc + off_p_rgid, gid);
    WriteKernel32(ucred + off_ucred_cr_rgid, gid);
    WriteKernel32(ucred + off_ucred_cr_svgid, gid);
    util_info("Overwritten GID to %i for proc 0x%llx", gid, proc);
}

void setUID (uid_t uid, uint64_t proc) {
    if (getuid() == uid) return;
    uint64_t ucred = ReadKernel64(proc + off_p_ucred);
    WriteKernel32(proc + off_p_uid, uid);
    WriteKernel32(proc + off_p_ruid, uid);
    WriteKernel32(ucred + off_ucred_cr_uid, uid);
    WriteKernel32(ucred + off_ucred_cr_ruid, uid);
    WriteKernel32(ucred + off_ucred_cr_svuid, uid);
    util_info("Overwritten UID to %i for proc 0x%llx", uid, proc);
}

void removeFileIfExists(const char *fileToRemove)
{
    NSString *fileToRM = [NSString stringWithUTF8String:fileToRemove];
    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileToRM])
    {
        [[NSFileManager defaultManager] removeItemAtPath:fileToRM error:&error];
        if (error)
        {
            LOG("ERROR REMOVING FILE! ERROR REPORTED: %@", error);
        } else {
            LOG("REMOVED FILE: %@", fileToRM);
        }
    } else {
        LOG("File Doesn't exist. Not removing.");
    }
}

extern char **environ;
NSData *lastSystemOutput=nil;
int execCmdV(const char *cmd, int argc, const char * const* argv, void (^unrestrict)(pid_t)) {
    pid_t pid;
    posix_spawn_file_actions_t *actions = NULL;
    posix_spawn_file_actions_t actionsStruct;
    int out_pipe[2];
    bool valid_pipe = false;
    posix_spawnattr_t *attr = NULL;
    posix_spawnattr_t attrStruct;
    
    NSMutableString *cmdstr = [NSMutableString stringWithCString:cmd encoding:NSUTF8StringEncoding];
    for (int i=1; i<argc; i++) {
        [cmdstr appendFormat:@" \"%s\"", argv[i]];
    }
    
    valid_pipe = pipe(out_pipe) == ERR_SUCCESS;
    if (valid_pipe && posix_spawn_file_actions_init(&actionsStruct) == ERR_SUCCESS) {
        actions = &actionsStruct;
        posix_spawn_file_actions_adddup2(actions, out_pipe[1], 1);
        posix_spawn_file_actions_adddup2(actions, out_pipe[1], 2);
        posix_spawn_file_actions_addclose(actions, out_pipe[0]);
        posix_spawn_file_actions_addclose(actions, out_pipe[1]);
    }
    
    if (unrestrict && posix_spawnattr_init(&attrStruct) == ERR_SUCCESS) {
        attr = &attrStruct;
        posix_spawnattr_setflags(attr, POSIX_SPAWN_START_SUSPENDED);
    }
    
    int rv = posix_spawn(&pid, cmd, actions, attr, (char *const *)argv, myenviron);
//    int rv = posix_spawn(&pid, cmd, actions, attr, (char *const *)argv, environ);
    util_info("%s(%d) command: %s", __FUNCTION__, pid, [cmdstr UTF8String]);
    
    if (unrestrict) {
        unrestrict(pid);
        kill(pid, SIGCONT);
    }
    
    if (valid_pipe) {
        close(out_pipe[1]);
    }
    
    if (rv == ERR_SUCCESS) {
        if (valid_pipe) {
            NSMutableData *outData = [NSMutableData new];
            char c;
            char s[2] = {0, 0};
            NSMutableString *line = [NSMutableString new];
            while (read(out_pipe[0], &c, 1) == 1) {
                [outData appendBytes:&c length:1];
                if (c == '\n') {
                    util_info("%s(%d): %s", __FUNCTION__, pid, [line UTF8String]);
                    [line setString:@""];
                } else {
                    s[0] = c;
                    [line appendString:@(s)];
                }
            }
            if ([line length] > 0) {
                util_info("%s(%d): %s", __FUNCTION__, pid, [line UTF8String]);
            }
            lastSystemOutput = [outData copy];
        }
        if (waitpid(pid, &rv, 0) == -1) {
            util_info("ERROR: Waitpid failed");
        } else {
            util_info("%s(%d) completed with exit status %d", __FUNCTION__, pid, WEXITSTATUS(rv));
        }
        
    } else {
        util_info("%s(%d): ERROR posix_spawn failed (%d): %s", __FUNCTION__, pid, rv, strerror(rv));
        rv <<= 8; // Put error into WEXITSTATUS
    }
    if (valid_pipe) {
        close(out_pipe[0]);
    }
    return rv;
}

int execCmd(const char *cmd, ...) {
    va_list ap, ap2;
    int argc = 1;
    
    va_start(ap, cmd);
    va_copy(ap2, ap);
    
    while (va_arg(ap, const char *) != NULL) {
        argc++;
    }
    va_end(ap);
    
    const char *argv[argc+1];
    argv[0] = cmd;
    for (int i=1; i<argc; i++) {
        argv[i] = va_arg(ap2, const char *);
    }
    va_end(ap2);
    argv[argc] = NULL;
    
    int rv = execCmdV(cmd, argc, argv, NULL);
    return WEXITSTATUS(rv);
}

int systemCmd(const char *cmd) {
    const char *argv[] = {"sh", "-c", (char *)cmd, NULL};
    return execCmdV("/bin/sh", 3, argv, NULL);
}

uint64_t getKernproc()
{
    uint64_t kernproc = 0x0;
    while (kernproc != 0x0)
    {
        uint32_t found_pid = ReadKernel32(kernproc + off_p_pid);
        if (found_pid == 0)
        {
            break;
        }
        
        /*
         kernproc will always be at the start of the linked list,
         so we loop backwards in order to find it
         */
        kernproc = ReadKernel64(kernproc + 0x0);
    }
    
    util_info("GOT KERNPROC AT: %llx", kernproc);
    return kernproc;
}

void rootMe(uint64_t proc) {
    uint64_t ucred = ReadKernel64(proc + off_p_ucred);
    WriteKernel32(proc + off_p_uid, 0);
    WriteKernel32(proc + off_p_ruid, 0);
    WriteKernel32(proc + off_p_gid, 0);
    WriteKernel32(proc + off_p_rgid, 0);
    WriteKernel32(ucred + off_ucred_cr_uid, 0);
    WriteKernel32(ucred + off_ucred_cr_ruid, 0);
    WriteKernel32(ucred + off_ucred_cr_svuid, 0);
    WriteKernel32(ucred + off_ucred_cr_ngroups, 1);
    WriteKernel32(ucred + off_ucred_cr_groups, 0);
    WriteKernel32(ucred + off_ucred_cr_rgid, 0);
    WriteKernel32(ucred + off_ucred_cr_svgid, 0);
}

void unsandbox(uint64_t proc) {
    util_info("Unsandboxed proc 0x%llx", proc);
    uint64_t ucred = ReadKernel64(proc + off_p_ucred);
    uint64_t cr_label = ReadKernel64(ucred + off_ucred_cr_label);
    WriteKernel64(cr_label + off_sandbox_slot, 0);
}

void list_all_snapshots(const char **snapshots, const char *origfs, bool has_origfs)
{
    for (const char **snapshot = snapshots; *snapshot; snapshot++) {
        if (strcmp(origfs, *snapshot) == 0) {
            has_origfs = true;
        }
        util_info("%s", *snapshot);
    }
}
char *itoa(long n) {
    int len = n==0 ? 1 : floor(log10l(labs(n)))+1;
    if (n<0) len++; // room for negative sign '-'
    char    *buf = calloc(sizeof(char), len+1); // +1 for null
    snprintf(buf, len+1, "%ld", n);
    return   buf;
}

bool patchtheSIGNSofCOde(){
    util_info("amfid_patch in progress...");
    posix_spawnattr_t attrp;
    posix_spawnattr_init(&attrp);
    posix_spawnattr_setflags(&attrp, POSIX_SPAWN_START_SUSPENDED);
    pid_t pid;
    const char *argv[] = {"amfid", NULL};
    if(!(amfid_pid = pidOfProcess("/usr/libexec/amfid"))){
        util_info("amfid_pid %u", amfid_pid);
        
        int retVal = posix_spawn(&pid, "/usr/libexec/amfid", NULL, &attrp, (char* const*)argv, myenviron);
//        int retVal = posix_spawn(&pid, "/usr/libexec/amfid", NULL, &attrp, (char* const*)argv, environ);

        if(retVal < 0)
        printf("failed to spawn spindump\n");
        util_info("amfid_pid %u", amfid_pid);
    }
    always_AMFIPID = amfid_pid;
    takeoverAmfid(amfid_pid);
    //trust_file(@"/freya/inject_criticald");
    if (file_exists("/freya/inject_criticald")) {
        int amfidpatchtest = execCmd("/freya/inject_criticald", itoa(amfid_pid), "/usr/lib/amfid_payload.dylib", NULL);
        if (amfidpatchtest == 0) {
            util_info("amfid has been infected by our dynamic library, it is now dismantled");//dismantled
        doweneedamfidPatch = 1;
            return true;

        } else {
            showMSG(NSLocalizedString(@"Error patching amfid, rebooting device", nil), 1, 1);
            dispatch_sync( dispatch_get_main_queue(), ^{
                UIApplication *app = [UIApplication sharedApplication];
                [app performSelector:@selector(suspend)];//wait 2 seconds while app is going background
                [NSThread sleepForTimeInterval:1.0];//exit app when app is in background
                reboot(RB_QUICK); });

            return false;

        }

    }
    return false;

}

int waitFF(const char *filename) {
    int rv = 0;
    printf(".");
    rv = access(filename, F_OK);
    for (int i = 0; !(i >= 1000 || rv == ERR_SUCCESS); i++) {
        usleep(10000);
        printf(".");
        rv = access(filename, F_OK);
    }
    return rv;
}

bool mod_plist_file(NSString *filename, void (^function)(id)) {
    NSData *data = [NSData dataWithContentsOfFile:filename];
    if (data == nil) {
        return false;
    }
    NSPropertyListFormat format = 0;
    NSError *error = nil;
    id plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
    if (plist == nil) {
        return false;
    }
    if (function) {
        function(plist);
    }
    NSData *newData = [NSPropertyListSerialization dataWithPropertyList:plist format:format options:0 error:&error];
    if (newData == nil) {
        return false;
    }
    if (![data isEqual:newData]) {
        if (![newData writeToFile:filename atomically:YES]) {
            return false;
        }
    }
    util_info("%s: Success", __FUNCTION__);
    return true;
}

void justrenamesnap() {
    
    int checkuncovermarker = (file_exists("/.installed_unc0ver"));
    int checkbash = (file_exists("/bin/bash"));
    int checkuicache = (file_exists("/usr/bin/uicache"));
    int checkelectra = (file_exists("/.bootstrapped_electra"));
    int checkth0rmarkerFinal = (file_exists("/.freya_installed"));
    int checkchimeramarker = (file_exists("/.procursus_strapped"));
    int checkJBRemoverMarker = (file_exists("/var/mobile/Media/.bootstrapped_Th0r_remover"));
    int checkjbdRun = (file_exists("/var/tmp/suckmyd.pid"));
    int checkpspawnhook = (file_exists("/var/run/pspawn_hook.ts"));
    printf("JUSTremovecheck exists?: %d\n",JUSTremovecheck);
    printf("checkuicache marker exists?: %d\n", checkuicache);
    printf("Uncover marker exists?: %d\n", checkuncovermarker);
    printf("pspawnhook marker exists?: %d\n", checkpspawnhook);
    printf("checkbash marker exists?: %d\n", checkbash);
    printf("electra exist = %d\n", checkelectra);
    printf("JBRemover marker exists?: %d\n", checkJBRemoverMarker);
    printf("Th0r Final marker exists?: %d\n", checkth0rmarkerFinal);
    printf("chimera marker exists?: %d\n", checkchimeramarker);
    printf("suckmyd Run marker exists?: %d\n", checkjbdRun);
    ourprogressMeter();

    struct passwd *const root_pw = getpwnam("root");
    removethejb();
    mkdir("/var/mobile/freya/", 0777);
    extractFile(get_bootstrap_file(@"aJBDofSorts.tar.gz"), @"/var/mobile/freya");
    extractFile(get_bootstrap_file(@"rmDevice.tar"), @"/var/mobile/freya/freya");
    extractFile(get_bootstrap_file(@"uicacheDevice.tar"), @"/var/mobile/freya/freya");
    extractFile(get_bootstrap_file(@"snappy.tar"), @"/var/mobile/freya/freya");
    NSString *snapdddd = get_bootstrap_file(@"snappy.tar"); pid_t pd;
    posix_spawn(&pd, "/var/mobile/freya/freya/tar", NULL, NULL, (char **)&(const char*[]){ "/var/mobile/freya/freya/tar", "--preserve-permissions", "-xvpf", [snapdddd UTF8String], "-C", "/var/mobile/freya/freya/", NULL}, NULL);

    chmod("/var/mobile/freya/freya/snappy", 04755);
    int rvchecsnap1 = posix_spawn(&pd, "/var/mobile/freya/freya/snappy", NULL, NULL, (char **)&(const char*[]){ "/var/mobile/freya/freya/snappy", "-f", "/", "-r",  "orig-fs", "-x", NULL}, NULL);
    waitpid(pd, NULL, 0);
    printf("[*] Trying snappy result = %d \n" , rvchecsnap1);
    
    disableRootFS();
    spotless();
    util_info("Rebooting...");
    showMSG(NSLocalizedString(@"RootFS Restored! We are going to reboot your device.", nil), 1, 1);
    dispatch_sync( dispatch_get_main_queue(), ^{
        UIApplication *app = [UIApplication sharedApplication];
        [app performSelector:@selector(suspend)]; //wait 2 seconds while app is going background
        [NSThread sleepForTimeInterval:1.0];//exit app when app is in background
        reboot(RB_QUICK); });
}


void restoreFSOLDStyle() {
    int checkbash = (file_exists("/bin/bash"));
    int checkuicache = (file_exists("/usr/bin/uicache"));
    int checkelectra = (file_exists("/.bootstrapped_electra"));
    printf("checkuicache marker exists?: %d\n", checkuicache);
    printf("checkbash marker exists?: %d\n", checkbash);
    printf("electra exist = %d\n", checkelectra);
    ourprogressMeter();
    removethejb();
    pid_t pd;
    if (checkbash ==1 ) {
        extractFile(get_bootstrap_file(@"aJBDofSorts.tar.gz"), @"/");
        if (doweneedamfidPatch == 1) { util_info("Amfid done fucked up already!"); } else {
            if (patchtheSIGNSofCOde()){ util_info("Amfid bombed for restore process!"); } else {
                util_info("Failure to bomb Amfid");} }
        mkdir("/freya", 0777);
        extractFile(get_bootstrap_file(@"restoreUtils.tar"), @"/");
        extractFile(get_bootstrap_file(@"rmDevice.tar"), @"/freya");
        extractFile(get_bootstrap_file(@"uicacheDevice.tar"), @"/freya");
        extractFile(get_bootstrap_file(@"snappy.tar"), @"/freya");
        NSString *snapdddd = get_bootstrap_file(@"snappy.tar");
        posix_spawn(&pd, "/freya/tar", NULL, NULL, (char **)&(const char*[]){ "/freya/tar", "--preserve-permissions", "-xvpf", [snapdddd UTF8String], "-C", "/freya/", NULL}, NULL);
        waitpid(pd, NULL, 0);
        removingElectraiOS();
        if (checkuicache == 1) { uicaching("uicache");trust_file(@"/freya/uicache");trust_file(@"/usr/bin/uicache");
            _assert(clean_file("/usr/lib/libjailbreak.dylib"), localize(@"Unable to clean old libjailbreak dylib."), true);
            _assert(execCmd("/freya/uicache", NULL) >= 0, localize(@"Unable to refresh icon cache."), true);
            _assert(clean_file("/freya/uicache"), localize(@"Unable to clean uicache usr/bin/ binary."), true);
            _assert(clean_file("/usr/bin/uicache"), localize(@"Unable to clean uicache usr/bin/ binary."), true); }

        ourprogressMeter();
    }
        
    [[NSFileManager defaultManager] removeItemAtPath:@"/etc/apt/sources.list.d" error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:@"/etc/profile" error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:@"/usr/bin/rsync" error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:@"/bin/rm" error:nil];
    _assert(mod_plist_file(@"/var/mobile/Library/Preferences/com.apple.springboard.plist", ^(id plist) {
        plist[@"SBShowNonDefaultSystemApps"] = @NO;
    }), localize(@"Unable to update SpringBoard preferences."), true);// Disallow SpringBoard to show non-default system apps.
    util_info("Successfully disallowed SpringBoard to show non-default system apps.");
    disableRootFS();
    char *targettype = sysctlWithName("hw.targettype");
    _assert(targettype != NULL, localize(@"Unable to get hardware targettype."), true);
    NSString *const jetsamFile = [NSString stringWithFormat:@"/System/Library/LaunchDaemons/com.apple.jetsamproperties.%s.plist", targettype];
    free(targettype);
    targettype = NULL;
    _assert(mod_plist_file(jetsamFile, ^(id plist) {
        plist[@"Version4"][@"System"][@"Override"][@"Global"][@"UserHighWaterMark"] = nil;
    }), localize(@"Unable to update Jetsam plist to restore memory limit."), true);
    spotless();
    ourprogressMeter();
    util_info("Rebooting...");
    if (kCFCoreFoundationVersionNumber < 1452.23 ) {//ios 11.3 = 1452.23 if ((kCFCoreFoundationVersionNumber < 1556.00 ) && (checkelectra ==1 )) {
        showMSG(NSLocalizedString(@"Jailbreak Files manually removed. We are going to reboot your device.", nil), 1, 1);
        dispatch_sync( dispatch_get_main_queue(), ^{ UIApplication *app = [UIApplication sharedApplication];
            [app performSelector:@selector(suspend)]; [NSThread sleepForTimeInterval:1.0]; reboot(RB_QUICK); });}
    chmod("/freya/snappy", 04755);
    int rvchecsnap1 = posix_spawn(&pd, "/freya/snappy", NULL, NULL, (char **)&(const char*[]){ "/freya/snappy", "-f", "/", "-r",  "orig-fs", "-x", NULL}, NULL);
    waitpid(pd, NULL, 0);
    printf("[*] Trying snappy result = %d \n" , rvchecsnap1);
    
    showMSG(NSLocalizedString(@"RootFS Restored! We are going to reboot your device.", nil), 1, 1);
    dispatch_sync( dispatch_get_main_queue(), ^{
        UIApplication *app = [UIApplication sharedApplication];
        [app performSelector:@selector(suspend)]; //wait 2 seconds while app is going background
        [NSThread sleepForTimeInterval:1.0];//exit app when app is in background
        reboot(RB_QUICK); });

}

void restoreRootFS()
{
    int checkuncovermarker = (file_exists("/.installed_unc0ver"));int checkbash = (file_exists("/bin/bash"));
    int checkuicache = (file_exists("/usr/bin/uicache"));int checkelectra = (file_exists("/.bootstrapped_electra"));
    int checkth0rmarkerFinal = (file_exists("/.freya_installed"));int checkchimeramarker = (file_exists("/.procursus_strapped"));
    ourprogressMeter();struct passwd *const root_pw = getpwnam("root");removethejb();
    if (kCFCoreFoundationVersionNumber < 1443.00) {//if ((kCFCoreFoundationVersionNumber < 1556.00) && (kCFCoreFoundationVersionNumber >= 1443.00)) { //lower than ios 12 and 11.3 == to or greater
        restoreFSOLDStyle();}if (checkelectra == 1) { restoreFSOLDStyle();}
    int const rootfd = open("/", O_RDONLY);_assert(rootfd > 0, localize(@"Unable to open RootFS."), true);const char **snapshots = snapshot_list(rootfd);
    _assert(snapshots != NULL, localize(@"Unable to get snapshots for RootFS."), true);
    _assert(*snapshots != NULL, localize(@"Found no snapshot for RootFS."), true);
    char *snapshot = strdup(*snapshots);util_info("%s", snapshot);_assert(snapshot != NULL, localize(@"Unable to find original snapshot for RootFS."), true);
    char *systemSnapshot = copySystemSnapshot();_assert(systemSnapshot != NULL, localize(@"Unable to copy system snapshot."), true);
    _assert(fs_snapshot_rename(rootfd, snapshot, systemSnapshot, 0) == ERR_SUCCESS, localize(@"Unable to rename original snapshot."), true);
    free(snapshot);snapshot = NULL;snapshot = strdup(systemSnapshot);_assert(snapshot != NULL, localize(@"Unable to duplicate string."), true);
    free(systemSnapshot);systemSnapshot = NULL;
    if (checkchimeramarker == 1) {
        char *const systemSnapshotMountPoint = "/var/rootfsmnt";
        if (is_mountpoint(systemSnapshotMountPoint)) {_assert(unmount(systemSnapshotMountPoint, MNT_FORCE) == ERR_SUCCESS, localize(@"Unable to unmount old snapshot mount point."), true);}
        _assert(clean_file(systemSnapshotMountPoint), localize(@"Unable to clean old snapshot mount point."), true);
        _assert(ensure_directory(systemSnapshotMountPoint, root_pw->pw_uid, 0755), localize(@"Unable to create snapshot mount point."), true);
        _assert(fs_snapshot_mount(rootfd, systemSnapshotMountPoint, snapshot, 0) == ERR_SUCCESS, localize(@"Unable to mount original snapshot."), true);
        const char *systemSnapshotLaunchdPath = [@(systemSnapshotMountPoint) stringByAppendingPathComponent:@"sbin/launchd"].UTF8String;
        _assert(waitFF(systemSnapshotLaunchdPath) == ERR_SUCCESS, localize(@"Unable to verify mounted snapshot."), true);
        ourprogressMeter();
       if (checkbash == 1) {
            _assert(clean_file("/usr/bin/uicache"), localize(@"Unable to clean old uicache binary."), true);
            unlink("/usr/bin/uicache");removeFileIfExists("/usr/bin/uicache");extractFile(get_bootstrap_file(@"rsync.tar"), @"/");mkdir("/freya", 0777);
            extractFile(get_bootstrap_file(@"rmDevice.tar"), @"/freya");extractFile(get_bootstrap_file(@"uicacheDevice.tar"), @"/freya"); }
        //removingChimeraiOS();
        _assert(execCmd("/usr/bin/rsync", "-vaxcH", "--progress", "--delete", [@(systemSnapshotMountPoint) stringByAppendingPathComponent:@"Applications/."].UTF8String, "/Applications", NULL) == 0, localize(@"Unable to sync /Applications."), true);
        _assert(unmount(systemSnapshotMountPoint, MNT_FORCE) == ERR_SUCCESS, localize(@"Unable to unmount original snapshot mount point."), true);
        close(rootfd);}
    else if (checkuncovermarker == 1) {
        char *const systemSnapshotMountPoint = "/private/var/mnt";
        if (is_mountpoint(systemSnapshotMountPoint)) {_assert(unmount(systemSnapshotMountPoint, MNT_FORCE) == ERR_SUCCESS, localize(@"Unable to unmount old snapshot mount point."), true);}
        _assert(clean_file(systemSnapshotMountPoint), localize(@"Unable to clean old snapshot mount point."), true);
        _assert(ensure_directory(systemSnapshotMountPoint, root_pw->pw_uid, 0755), localize(@"Unable to create snapshot mount point."), true);
        _assert(fs_snapshot_mount(rootfd, systemSnapshotMountPoint, snapshot, 0) == ERR_SUCCESS, localize(@"Unable to mount original snapshot."), true);
        const char *systemSnapshotLaunchdPath = [@(systemSnapshotMountPoint) stringByAppendingPathComponent:@"sbin/launchd"].UTF8String;
        _assert(waitFF(systemSnapshotLaunchdPath) == ERR_SUCCESS, localize(@"Unable to verify mounted snapshot."), true);
        if (checkbash == 1) {
            extractFile(get_bootstrap_file(@"aJBDofSorts.tar.gz"), @"/");
            if (doweneedamfidPatch == 1) { util_info("Amfid done fucked up already!"); } else { if (patchtheSIGNSofCOde()){ util_info("Amfid bombed for restore process!"); } else { util_info("Failure to bomb Amfid");
                    showMSG(NSLocalizedString(@"Failure to bomb Amfid! We are going to reboot your device.", nil), 1, 1);
                    dispatch_sync( dispatch_get_main_queue(), ^{UIApplication *app = [UIApplication sharedApplication];
                        [app performSelector:@selector(suspend)];[NSThread sleepForTimeInterval:1.0];reboot(RB_QUICK); }); } }
            _assert(clean_file("/usr/bin/uicache"), localize(@"Unable to clean old uicache binary."), true);
            unlink("/usr/bin/uicache");removeFileIfExists("/usr/bin/uicache");
            extractFile(get_bootstrap_file(@"rsync.tar"), @"/");mkdir("/freya", 0777);
            extractFile(get_bootstrap_file(@"rmDevice.tar"), @"/freya");extractFile(get_bootstrap_file(@"uicacheDevice.tar"), @"/freya");
        }removingu0iOS();
        
        _assert(execCmd("/usr/bin/rsync", "-vaxcH", "--progress", "--delete", [@(systemSnapshotMountPoint) stringByAppendingPathComponent:@"Applications/."].UTF8String, "/Applications", NULL) == 0, localize(@"Unable to sync /Applications."), true);
        _assert(unmount(systemSnapshotMountPoint, MNT_FORCE) == ERR_SUCCESS, localize(@"Unable to unmount original snapshot mount point."), true);
        close(rootfd); }
    else { if (checkth0rmarkerFinal == 1) {
            char *const systemSnapshotMountPoint = "/var/rootfsmnt"; //freya removing
            if (is_mountpoint(systemSnapshotMountPoint)) {
                _assert(unmount(systemSnapshotMountPoint, MNT_FORCE) == ERR_SUCCESS, localize(@"Unable to unmount old RootFS mount point."), true);}
            _assert(clean_file(systemSnapshotMountPoint), localize(@"Unable to clean old snapshot mount point."), true);
            _assert(ensure_directory(systemSnapshotMountPoint, root_pw->pw_uid, 0755), localize(@"Unable to create snapshot mount point."), true);
            _assert(fs_snapshot_mount(rootfd, systemSnapshotMountPoint, snapshot, 0) == ERR_SUCCESS, localize(@"Unable to mount original snapshot."), true);
            const char *systemSnapshotLaunchdPath = [@(systemSnapshotMountPoint) stringByAppendingPathComponent:@"sbin/launchd"].UTF8String;
            _assert(waitFF(systemSnapshotLaunchdPath) == ERR_SUCCESS, localize(@"Unable to verify mounted snapshot."), true);
            if (checkbash == 1) { //freya removing
                extractFile(get_bootstrap_file(@"aJBDofSorts.tar.gz"), @"/");
                if (doweneedamfidPatch == 1) {util_info("Amfid done fucked up already!"); } else {
                    if (patchtheSIGNSofCOde()){util_info("Amfid bombed for restore process!");} else {
                        util_info("Failure to bomb Amfid");
                        showMSG(NSLocalizedString(@"Failure to bomb Amfid! We are going to reboot your device.", nil), 1, 1);
                        dispatch_sync( dispatch_get_main_queue(), ^{UIApplication *app = [UIApplication sharedApplication];
                            [app performSelector:@selector(suspend)];[NSThread sleepForTimeInterval:1.0];reboot(RB_QUICK); }); } }
                              unlink("/usr/bin/uicache");
                removeFileIfExists("/usr/bin/uicache");extractFile(get_bootstrap_file(@"rsync.tar"), @"/");mkdir("/freya", 0777);
                extractFile(get_bootstrap_file(@"rmDevice.tar"), @"/freya");extractFile(get_bootstrap_file(@"uicacheDevice.tar"), @"/freya");
                removingFreyaiOS();
            }
            _assert(execCmd("/freya/rm", "-rvdf", "/usr/lib/suckmyd", NULL) >= 0, localize(@"Unable to remove suckmyd."), true);
        _assert(execCmd("/freya/rm", "-rvdf", "/usr/lib/suckmyd_client", NULL) >= 0, localize(@"Unable to remove suckmyd_client."), true);
        _assert(execCmd("/freya/rm", "-rvdf", "/usr/lib/TweakInject", NULL) >= 0, localize(@"Unable to remove tweakinject."), true);
        _assert(execCmd("/freya/rm", "-rvdf", "/usr/lib/TweakInject.dylib", NULL) >= 0, localize(@"Unable to remove tweakinject."), true);
            _assert(execCmd("/freya/rm", "-rvdf", "/usr/lib/libjailbreak.dylib", NULL) >= 0, localize(@"Unable to remove libjailbreak."), true);
            _assert(execCmd("/usr/bin/rsync", "-vaxcH", "--progress", "--delete", [@(systemSnapshotMountPoint) stringByAppendingPathComponent:@"Applications/."].UTF8String, "/Applications", NULL) == 0, localize(@"Unable to sync /Applications."), true);
            _assert(unmount(systemSnapshotMountPoint, MNT_FORCE) == ERR_SUCCESS, localize(@"Unable to unmount original snapshot mount point."), true);
            close(rootfd);} }
    ourprogressMeter();free(snapshot);snapshot = NULL;free(snapshots);snapshots = NULL;
    if (checkuicache == 1) {uicaching("uicache");trust_file(@"/usr/bin/uicache");
        _assert(clean_file("/usr/lib/libjailbreak.dylib"), localize(@"Unable to clean old libjailbreak dylib."), true);
        _assert(execCmd("/freya/uicache", NULL) >= 0, localize(@"Unable to refresh icon cache."), true);
        _assert(clean_file("/freya/uicache"), localize(@"Unable to clean uicache usr/bin/ binary."), true);
        _assert(clean_file("/usr/bin/uicache"), localize(@"Unable to clean uicache usr/bin/ binary."), true);}
    ourprogressMeter();ourprogressMeter();ourprogressMeter();ourprogressMeter();

    _assert(clean_file("/usr/bin/find"), localize(@"Unable to clean find binary."), true);
    util_info("Successfully reverted back RootFS remount. Cleaning up...");
    NSArray *const cleanUpFileList = @[@"/var/cache",
                                       @"/var/freya",
                                       @"/var/lib",
                                       @"/var/stash",
                                       @"/var/db/stash",
                                       @"/var/mobile/Library/Cydia",
                                       @"/var/mobile/Library/Caches/com.saurik.Cydia",
                                       @"/etc/apt/sources.list.d",
                                       @"/etc/apt/sources.list",
                                       @"/private/etc/apt",
                                       @"/private/etc/alternatives",
                                       @"/private/etc/default",
                                       @"/private/etc/dpkg",
                                       @"/private/etc/dropbear",
                                       @"/private/etc/localtime",
                                       @"/private/etc/motd",
                                       @"/private/etc/pam.d",
                                       @"/private/etc/profile",
                                       @"/private/etc/pkcs11",
                                       @"/private/etc/profile.d",
                                       @"/private/etc/profile.ro",
                                       @"/private/etc/rc.d",
                                       @"/private/etc/resolv.conf",
                                       @"/private/etc/ssh",
                                       @"/private/etc/ssl",
                                       @"/private/etc/sudo_logsrvd.conf",
                                       @"/private/etc/sudo.conf",
                                       @"/private/etc/sudo_logsrvd.conf",
                                       @"/private/etc/sudoers",
                                       @"/private/etc/sudoers.d",
                                       @"/private/etc/sudoers.dist",
                                       @"/private/etc/wgetrc",
                                       @"/private/etc/symlibs.dylib",
                                       @"/private/etc/zshrc",
                                       @"/private/etc/zprofile",
                                       @"/private/private",
                                       @"/private/var/containers/Bundle/dylibs",
                                       @"/private/var/containers/Bundle/iosbinpack64",
                                       @"/private/var/containers/Bundle/tweaksupport",
                                       @"/private/var/log/suckmyd-stderr.log",
                                       @"/private/var/log/suckmyd-stdout.log",
                                       @"/private/var/log/jailbreakd-stderr.log",
                                       @"/private/var/log/jailbreakd-stdout.log",
                                       @"/private/var/backups",
                                       @"/private/var/empty",
                                       @"/private/var/bin",
                                       @"/private/var/cache",
                                       @"/private/var/cercube_stashed",
                                       @"/private/var/db/stash",
                                       @"/private/var/db/sudo",
                                       @"/private/var/dropbear",
                                       @"/private/var/Ext3nder-Installer",
                                       @"/private/var/lib",
                                       @"/var/lib",
                                       @"/private/var/LIB",
                                       @"/private/var/local",
                                       @"/private/var/log/apt",
                                       @"/private/var/log/dpkg",
                                       @"/private/var/log/testbin.log",
                                       @"/private/var/lock",
                                       @"/private/var/mobile/Library/Activator",
                                       @"/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist",
                                       @"/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia",
                                       @"/private/var/mobile/Library/Application\ Support/Activator",
                                       @"/private/var/mobile/Library/Application\ Support/Flex3",
                                       @"/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState",
                                       @"/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState",
                                       @"/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState",
                                       @"/private/var/mobile/Library/com.saurik.Cydia",
                                       @"/private/var/mobile/Library/Cr4shed",
                                       @"/private/var/mobile/Library/CT4",
                                       @"/private/var/mobile/Library/CT3",
                                       @"/private/var/mobile/Library/Cydia",
                                       @"/private/var/mobile/Library/Flex3",
                                       @"/private/var/mobile/Library/Filza",
                                       @"/private/var/mobile/Library/Fingal",
                                       @"/private/var/mobile/Library/iWidgets",
                                       @"/private/var/mobile/Library/LockHTML",
                                       @"/private/var/mobile/Library/Logs/Cydia",
                                       @"/private/var/mobile/Library/Notchification",
                                       @"/private/var/mobile/Library/unlimapps_tweaks_resources",
                                       @"/private/var/mobile/Library/Sileo",
                                       @"/private/var/mobile/Library/SBHTML",
                                       @"/private/var/mobile/Library/Toonsy",
                                       @"/private/var/mobile/Library/Widgets",
                                       @"/private/var/mobile/Library/Caches/libactivator.plist",
                                       @"/private/var/mobile/Library/Caches/com.johncoates.Flex",
                                       @"/private/var/mobile/Library/Caches/com.saurik.Cydia",
                                       @"/private/var/mobile/Library/Caches/AmyCache",
                                       @"/private/var/mobile/Library/Caches/org.coolstar.SileoStore",
                                       @"/private/var/mobile/Library/Caches/com.saurik.Cydia",
                                       @"/private/var/mobile/Library/Caches/com.saurik.Cydia",
                                       @"/private/var/mobile/Library/Caches/com.tigisoftware.Filza",
                                       @"/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia",
                                       @"/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza",
                                       @"/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex",
                                       @"/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode",
                                       @"/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal",
                                       @"/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo",
                                       @"/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist",
                                       @"/private/var/mobile/Library/libactivator.plist",
                                       @"/private/var/motd",
                                       @"/private/var/profile",
                                       @"/private/var/run/pspawn_hook.ts",
                                       @"/private/var/run/utmp",
                                       @"/private/var/run/sudo",
                                       @"/private/var/sbin",
                                       @"/private/var/spool",
                                       @"/private/var/tmp/cydia.log",
                                       @"/private/var/tweak",
                                       @"/private/var/unlimapps_tweak_resources",
                                       @"/.freya_installed",
                                       @"/.freya_bootstrap"];
    for (id file in cleanUpFileList) { clean_file([file UTF8String]); }
    ourprogressMeter();
    [[NSFileManager defaultManager] removeItemAtPath:@"/etc/apt/sources.list.d" error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:@"/etc/profile" error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:@"/usr/bin/rsync" error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:@"/bin/rm" error:nil];
    _assert(clean_file("/freya/uicache"), localize(@"Unable to clean uicache usr/bin/ binary."), true);
    _assert(clean_file("/usr/bin/uicache"), localize(@"Unable to clean uicache usr/bin/ binary."), true);
    _assert(mod_plist_file(@"/var/mobile/Library/Preferences/com.apple.springboard.plist", ^(id plist) {
        plist[@"SBShowNonDefaultSystemApps"] = @NO;
    }), localize(@"Unable to update SpringBoard preferences."), true);// Disallow SpringBoard to show non-default system apps.
    util_info("Successfully disallowed SpringBoard to show non-default system apps.");
    disableRootFS();
    char *targettype = sysctlWithName("hw.targettype");
    _assert(targettype != NULL, localize(@"Unable to get hardware targettype."), true);
    NSString *const jetsamFile = [NSString stringWithFormat:@"/System/Library/LaunchDaemons/com.apple.jetsamproperties.%s.plist", targettype];
    free(targettype);targettype = NULL;
    _assert(mod_plist_file(jetsamFile, ^(id plist) {
        plist[@"Version4"][@"System"][@"Override"][@"Global"][@"UserHighWaterMark"] = nil;
    }), localize(@"Unable to update Jetsam plist to restore memory limit."), true);
    spotless();ourprogressMeter();util_info("Rebooting...");
    showMSG(NSLocalizedString(@"RootFS Restored! We are going to reboot your device.", nil), 1, 1);
    dispatch_sync( dispatch_get_main_queue(), ^{
        UIApplication *app = [UIApplication sharedApplication];
        [app performSelector:@selector(suspend)]; //wait 2 seconds while app is going background
        [NSThread sleepForTimeInterval:1.0];//exit app when app is in background
        reboot(RB_QUICK); });
enddid:
    printf("restored oldie\n");
}





int trust_file(NSString *path) {
    NSMutableArray *paths = [NSMutableArray new];
    [paths addObject:path];
    injectTrustCache(paths, GETOFFSET(trustcache), pmap_load_trust_cache);
    return 0;
}

void renameSnapshot(int rootfd, const char* rootFsMountPoint, const char **snapshots, const char *origfs)
{
    util_info("Renaming snapshot...");
    rootfd = open(rootFsMountPoint, O_RDONLY);
    _assert(rootfd > 0, @"Error renaming snapshot", true);
    snapshots = snapshot_list(rootfd);
    _assert(snapshots != NULL, @"Error renaming snapshot", true);
    util_info("Snapshots on newly mounted RootFS:");
    for (const char **snapshot = snapshots; *snapshot; snapshot++) {
        util_info("\t%s", *snapshot);
    }
    free(snapshots);
    snapshots = NULL;
    NSString *systemVersionPlist = @"/System/Library/CoreServices/SystemVersion.plist";
    NSString *rootSystemVersionPlist = [@(rootFsMountPoint) stringByAppendingPathComponent:systemVersionPlist];
    _assert(rootSystemVersionPlist != nil, @"Error renaming snapshot", true);
    NSDictionary *snapshotSystemVersion = [NSDictionary dictionaryWithContentsOfFile:systemVersionPlist];
    _assert(snapshotSystemVersion != nil, @"Error renaming snapshot", true);
    NSDictionary *rootfsSystemVersion = [NSDictionary dictionaryWithContentsOfFile:rootSystemVersionPlist];
    _assert(rootfsSystemVersion != nil, @"Error renaming snapshot", true);
    if (![rootfsSystemVersion[@"ProductBuildVersion"] isEqualToString:snapshotSystemVersion[@"ProductBuildVersion"]]) {
        LOG("snapshot VersionPlist: %@", snapshotSystemVersion);
        LOG("rootfs VersionPlist: %@", rootfsSystemVersion);
        _assert("BuildVersions match"==NULL, @"Error renaming snapshot/root_msg", true);
    }
    const char *test_snapshot = "test-snapshot";
    _assert(fs_snapshot_create(rootfd, test_snapshot, 0) == ERR_SUCCESS, @"Error renaming snapshot", true);
    _assert(fs_snapshot_delete(rootfd, test_snapshot, 0) == ERR_SUCCESS, @"Error renaming snapshot", true);
    char *systemSnapshot = copySystemSnapshot();
    _assert(systemSnapshot != NULL, @"Error renaming snapshot", true);
    uint64_t system_snapshot_vnode = 0;
    uint64_t system_snapshot_vnode_v_data = 0;
    uint32_t system_snapshot_vnode_v_data_flag = 0;
    if (kCFCoreFoundationVersionNumber >= 1452.23) {//1535.12) {
        system_snapshot_vnode = vnodeForSnapshot(rootfd, systemSnapshot);
        LOG("system_snapshot_vnode = " ADDR, system_snapshot_vnode);
        _assert(ISADDR(system_snapshot_vnode),  @"Error renaming snapshot", true);
        system_snapshot_vnode_v_data = ReadKernel64(system_snapshot_vnode + koffset(KSTRUCT_OFFSET_VNODE_V_DATA));
        LOG("system_snapshot_vnode_v_data = " ADDR, system_snapshot_vnode_v_data);
        _assert(ISADDR(system_snapshot_vnode_v_data),  @"Error renaming snapshot", true);
        system_snapshot_vnode_v_data_flag = ReadKernel32(system_snapshot_vnode_v_data + 49);
        LOG("system_snapshot_vnode_v_data_flag = 0x%x", system_snapshot_vnode_v_data_flag);
        WriteKernel32(system_snapshot_vnode_v_data + 49, system_snapshot_vnode_v_data_flag & ~0x40);
    }
    _assert(fs_snapshot_rename(rootfd, systemSnapshot, origfs, 0) == ERR_SUCCESS,  @"Error renaming snapshot", true);
    if (kCFCoreFoundationVersionNumber >= 1452.23) {//1535.12) {
        WriteKernel32(system_snapshot_vnode_v_data + 49, system_snapshot_vnode_v_data_flag);
        _assert(_vnode_put(system_snapshot_vnode) == ERR_SUCCESS,  @"Error renaming snapshot", true); }
    free(systemSnapshot);
    systemSnapshot = NULL;
    util_info("Successfully renamed system snapshot.");
    close(rootfd);
    showMSG(NSLocalizedString(@"RootFS Renamed! We are going to reboot your device.", nil), 1, 1);
    dispatch_sync( dispatch_get_main_queue(), ^{// Reboot.
        UIApplication *app = [UIApplication sharedApplication];
        [app performSelector:@selector(suspend)];
        [NSThread sleepForTimeInterval:1.0];//wait 2 seconds while app is going background
        reboot(RB_QUICK);//exit app when app is in background
        exit(0); });
}


void preMountFS(const char *thedisk, int root_fs, const char **snapshots, const char *origfs)
{
    util_info("Pre-Mounting RootFS...");

    _assert(!is_mountpoint("/var/mnt"), invalidRootMessage, true);
    char *const rootFsMountPoint = "/var/rootfsmnt";
    if (is_mountpoint(rootFsMountPoint)) {
        _assert(unmount(rootFsMountPoint, MNT_FORCE) == ERR_SUCCESS, localize(@"Unable to unmount old RootFS mount point."), true);
    }
    _assert(clean_file(rootFsMountPoint), localize(@"Unable to clean old RootFS mount point."), true);
    char *const hardwareMountPoint = "/private/var/hardware";
    if (is_mountpoint(hardwareMountPoint)) {
        _assert(unmount(hardwareMountPoint, MNT_FORCE) == ERR_SUCCESS, localize(@"Unable to unmount hardware mount point."), true);
    }
    _assert(ensure_directory(rootFsMountPoint, 0, 0755), localize(@"Unable to create RootFS mount point."), true);
    const char *argv[] = {"/sbin/mount_apfs", thedisk, rootFsMountPoint, NULL};
    _assert(execCmdV(argv[0], 3, argv, ^(pid_t pid) {
        kptr_t const procStructAddr = get_proc_struct_for_pid(pid);
        LOG("procStructAddr = " ADDR, procStructAddr);
        _assert(KERN_POINTER_VALID(procStructAddr), localize(@"Unable to find mount_apfs's process in kernel memory."), true);
        give_creds_to_process_at_addr(procStructAddr, get_kernel_cred_addr());
    }) == ERR_SUCCESS, localize(@"Unable to mount RootFS."), true);
    _assert(execCmd("/sbin/mount", NULL) == ERR_SUCCESS, localize(@"Unable to print new mount list."), true);
    const char *systemSnapshotLaunchdPath = [@(rootFsMountPoint) stringByAppendingPathComponent:@"sbin/launchd"].UTF8String;
    _assert(waitFF(systemSnapshotLaunchdPath) == ERR_SUCCESS, localize(@"Unable to verify newly mounted RootFS."), true);
    //util_info("Successfully mounted RootFS.");

    renameSnapshot(root_fs, rootFsMountPoint, snapshots, origfs);
}

void update_springboard_plist(){
    NSDictionary *springBoardPlist = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist"];
    [springBoardPlist setValue:@YES forKey:@"SBShowNonDefaultSystemApps"];
    [springBoardPlist writeToFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist" atomically:YES];
    
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithShort:0755], NSFilePosixPermissions,@"mobile",NSFileOwnerAccountName,NULL];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] setAttributes:attr ofItemAtPath:@"/var/mobile/Library/Preferences/com.apple.springboard.plist" error:&error];
}

bool ensure_symlink(const char *to, const char *from) {
    ssize_t wantedLength = strlen(to);
    ssize_t maxLen = wantedLength + 1;
    char link[maxLen];
    ssize_t linkLength = readlink(from, link, sizeof(link));
    if (linkLength != wantedLength ||
        strncmp(link, to, maxLen) != ERR_SUCCESS
        ) {
        if (!clean_file(from)) {
            return false;
        }
        if (symlink(to, from) != ERR_SUCCESS) {
            return false;
        }
    }
    return true;
}

bool copyMe(const char *from, const char *to) {
    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:from]]) {
        [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithUTF8String:from] toPath:[NSString stringWithUTF8String:to] error:&error];
        if (error){
            LOG("ERROR: %@", error);
        } else {
            util_info("FILE COPIED!");
        }
    } else {
        util_info("FILE DOESN'T EXIST!");
    }
    return false;
}

/*struct hfs_mount_args {
    char    *fspec;            // block special device to mount /
    uid_t    hfs_uid;        // uid that owns hfs files (standard HFS only) /
    gid_t    hfs_gid;        // gid that owns hfs files (standard HFS only) /
    mode_t    hfs_mask;        // mask to be applied for hfs perms  (standard HFS only) /
    u_int32_t hfs_encoding;    // encoding for this volume (standard HFS only) /
    struct    timezone hfs_timezone;    // user time zone info (standard HFS only) /
    int        flags;            // mounting flags, see below /
    int     journal_tbuffer_size;   // size in bytes of the journal transaction buffer /
    int        journal_flags;          // flags to pass to journal_open/create /
    int        journal_disable;        // don't use journaling (potentially dangerous) /
};*/
static char* mntpathSW;
static char* otamntpath;
static char* otamntpathpriv;
static char* otamntpathLib;
static char* otamntpathREMOVE;
static char* mntpath;
    
void remountFS(bool shouldRestore) {
    mntpathSW = "/var/rootfsmnt";
    mntpath = strdup("/var/rootfsmnt");
    otamntpath = "/var/MobileSoftwareUpdate/mnt1";
    otamntpathpriv = "/private/var/MobileSoftwareUpdate/mnt1";
    otamntpathLib = "/private/var/Library/MobileSoftwareUpdate/mnt1";
    otamntpathREMOVE = "/var/MobileSoftwareUpdate";

    uint64_t islaunchdProcstruct = get_proc_struct_for_pid(1);
    printf("launchd procStruct: 0x%llx\n", islaunchdProcstruct);
    if(isOTAMounted()) {
        waitOTAOK("deleting OTA...");
        util_info("OTA update already mounted, removing now please wait.........");
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:otamntpath] error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:otamntpathpriv] error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:otamntpathREMOVE] error:nil];
        unlink(otamntpath);
        remove(otamntpath);
        unlink(otamntpathpriv);
        remove(otamntpathpriv);
        unlink(otamntpathREMOVE);
        remove(otamntpathREMOVE);
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"12.5.6")) {
            [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:otamntpath] error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:otamntpathREMOVE] error:nil];
            unlink(otamntpathREMOVE);
            remove(otamntpathREMOVE); }
        need_initialSSRenamed = 0;//
        showMSG(NSLocalizedString(@"Failed to remount, please remove update file if I didn't already!. Try again after rebooting.", nil), 1, 1);
        dispatch_sync( dispatch_get_main_queue(), ^{ UIApplication *app = [UIApplication sharedApplication]; [app performSelector:@selector(suspend)]; //wait 2 seconds while app is going background
            [NSThread sleepForTimeInterval:1.0]; reboot(RB_QUICK); });
    }
    
    if (kCFCoreFoundationVersionNumber >= 1556.00) {// ios 12           1452.23) {// <- ios 11.3  .............->  1556.00) {// ios 12
        bool resultofMountattempt = remount(islaunchdProcstruct);
        printf("resultofMountattempt true = 1: %d\n", resultofMountattempt);
        if ( resultofMountattempt == 0 ) { printf("failed to remount, please remove update file if I didn't already, rebooting.... try again after reboot\n");
            showMSG(NSLocalizedString(@"Failed to remount, please remove update file if I didn't already!. Try again after rebooting.", nil), 1, 1);
            dispatch_sync( dispatch_get_main_queue(), ^{ UIApplication *app = [UIApplication sharedApplication]; [app performSelector:@selector(suspend)]; //wait 2 seconds while app is going background
                [NSThread sleepForTimeInterval:1.0]; reboot(RB_QUICK); }); }
        if (need_initialSSRenamed == 3) { ourprogressMeter(); util_info("Rebooting...");
            showMSG(NSLocalizedString(@"RootFS snapshot renamed! We are going to reboot your device.", nil), 1, 1);
            dispatch_sync( dispatch_get_main_queue(), ^{ UIApplication *app = [UIApplication sharedApplication]; [app performSelector:@selector(suspend)]; [NSThread sleepForTimeInterval:1.0];
                reboot(RB_QUICK); }); }
        else if (need_initialSSRenamed == 2) {//  Remount RootFS snapshot already renamed - bootstrap time
            //justrenamesnap();
            
            FILE *f = fopen("/.remount_success", "w"); fprintf(f,"Hello World!\n"); fclose(f);
            if(access("/.remount_success", F_OK) == -1) { util_info("Failed write file on rootfs.");
                showMSG(NSLocalizedString(@"Failed write file on rootfs, We're going to restore RootFS! then reboot your device. Better luck next time", nil), 1, 1);
                restoreRootFS(); }
            util_info("Successfully write file on rootfs."); unlink("/.remount_success");
            if (shouldRestore) { restoreRootFS(); } }
        else if (need_initialSSRenamed == 1) { //  Remount RootFS
            FILE *f = fopen("/.remount_success", "w"); fprintf(f,"Hello World!\n"); fclose(f);
            if(access("/.remount_success", F_OK) == -1) { util_info("Failed write file on rootfs.");
                showMSG(NSLocalizedString(@"Failed write file on rootfs, We're going to restore RootFS! then reboot your device. Better luck next time", nil), 1, 1);
                restoreRootFS(); }
            util_info("Successfully write file on rootfs."); unlink("/.remount_success");
            int root_fs = open("/", O_RDONLY);
            _assert(root_fs > 0, @"Error Opening The Root Filesystem!", true);
            const char **snapshots = snapshot_list(root_fs);
            const char *origfs = "orig-fs";
            bool isOriginalFS = false;
            const char *root_disk = "/dev/disk0s1s1";
            if (snapshots == NULL) {
                util_info("No System Snapshot Found! Don't worry, I'll Make One!");//Clear Dev Flags
                uint64_t devVnode = vnodeForPath(root_disk);
                _assert(ISADDR(devVnode), @"Failed to clear dev vnode's si_flags.", true);
                uint64_t v_specinfo = ReadKernel64(devVnode + koffset(KSTRUCT_OFFSET_VNODE_VU_SPECINFO));
                _assert(ISADDR(v_specinfo), @"Failed to clear dev vnode's si_flags.", true);
                WriteKernel32(v_specinfo + koffset(KSTRUCT_OFFSET_SPECINFO_SI_FLAGS), 0);
                uint32_t si_flags = ReadKernel32(v_specinfo + koffset(KSTRUCT_OFFSET_SPECINFO_SI_FLAGS));
                _assert(si_flags == 0, @"Failed to clear dev vnode's si_flags.", true);
                _assert(_vnode_put(devVnode) == ERR_SUCCESS, @"Failed to clear dev vnode's si_flags.", true);
                preMountFS(root_disk, root_fs, snapshots, origfs);//Pre-Mount
                close(root_fs); }
            list_all_snapshots(snapshots, origfs, isOriginalFS);
            uint64_t rootfs_vnode = vnodeForPath("/");
            LOG("rootfs_vnode = " ADDR, rootfs_vnode);
            _assert(ISADDR(rootfs_vnode), @"Failed to mount", true);
            uint64_t v_mount = ReadKernel64(rootfs_vnode + koffset(KSTRUCT_OFFSET_VNODE_V_MOUNT));
            LOG("v_mount = " ADDR, v_mount);
            _assert(ISADDR(v_mount), @"Failed to mount", true);
            uint32_t v_flag = ReadKernel32(v_mount + koffset(KSTRUCT_OFFSET_MOUNT_MNT_FLAG));
            if ((v_flag & (MNT_RDONLY | MNT_NOSUID))) {
                v_flag = v_flag & ~(MNT_RDONLY | MNT_NOSUID);
                WriteKernel32(v_mount + koffset(KSTRUCT_OFFSET_MOUNT_MNT_FLAG), v_flag & ~MNT_ROOTFS);
                _assert(execCmd("/sbin/mount", "-u", root_disk, NULL) == ERR_SUCCESS, @"Failed to mount", true);
                WriteKernel32(v_mount + koffset(KSTRUCT_OFFSET_MOUNT_MNT_FLAG), v_flag); }
            _assert(_vnode_put(rootfs_vnode) == ERR_SUCCESS, @"Failed to mount", true);
            _assert(execCmd("/sbin/mount", NULL) == ERR_SUCCESS, @"Failed to mount", true);
            if (shouldRestore) { restoreRootFS(); }
        }
    } else {
        int root_fs = open("/", O_RDONLY);
        _assert(root_fs > 0, @"Error Opening The Root Filesystem!", true);
        const char **snapshots = snapshot_list(root_fs);
        const char *origfs = "orig-fs";
        bool isOriginalFS = false;
        const char *root_disk = "/dev/disk0s1s1";
        if (snapshots == NULL) {
            util_info("No System Snapshot Found! Don't worry, I'll Make One!");//Clear Dev Flags
            uint64_t devVnode = vnodeForPath(root_disk);
            _assert(ISADDR(devVnode), @"Failed to clear dev vnode's si_flags.", true);
            uint64_t v_specinfo = ReadKernel64(devVnode + koffset(KSTRUCT_OFFSET_VNODE_VU_SPECINFO));
            _assert(ISADDR(v_specinfo), @"Failed to clear dev vnode's si_flags.", true);
            WriteKernel32(v_specinfo + koffset(KSTRUCT_OFFSET_SPECINFO_SI_FLAGS), 0);
            uint32_t si_flags = ReadKernel32(v_specinfo + koffset(KSTRUCT_OFFSET_SPECINFO_SI_FLAGS));
            _assert(si_flags == 0, @"Failed to clear dev vnode's si_flags.", true);
            _assert(_vnode_put(devVnode) == ERR_SUCCESS, @"Failed to clear dev vnode's si_flags.", true);
            preMountFS(root_disk, root_fs, snapshots, origfs);//Pre-Mount
            close(root_fs); }
        list_all_snapshots(snapshots, origfs, isOriginalFS);
        uint64_t rootfs_vnode = vnodeForPath("/");
        LOG("rootfs_vnode = " ADDR, rootfs_vnode);
        _assert(ISADDR(rootfs_vnode), @"Failed to mount", true);
        uint64_t v_mount = ReadKernel64(rootfs_vnode + koffset(KSTRUCT_OFFSET_VNODE_V_MOUNT));
        LOG("v_mount = " ADDR, v_mount);
        _assert(ISADDR(v_mount), @"Failed to mount", true);
        uint32_t v_flag = ReadKernel32(v_mount + koffset(KSTRUCT_OFFSET_MOUNT_MNT_FLAG));
        if ((v_flag & (MNT_RDONLY | MNT_NOSUID))) {
            v_flag = v_flag & ~(MNT_RDONLY | MNT_NOSUID);
            WriteKernel32(v_mount + koffset(KSTRUCT_OFFSET_MOUNT_MNT_FLAG), v_flag & ~MNT_ROOTFS);
            _assert(execCmd("/sbin/mount", "-u", root_disk, NULL) == ERR_SUCCESS, @"Failed to mount", true);
            WriteKernel32(v_mount + koffset(KSTRUCT_OFFSET_MOUNT_MNT_FLAG), v_flag); }
        _assert(_vnode_put(rootfs_vnode) == ERR_SUCCESS, @"Failed to mount", true);
        _assert(execCmd("/sbin/mount", NULL) == ERR_SUCCESS, @"Failed to mount", true);
        if (shouldRestore) { restoreRootFS(); }
    }
}

bool doesThisExist(const char *fileToCheck) {
    NSString *file2C = [NSString stringWithUTF8String:fileToCheck];
    if ([[NSFileManager defaultManager] fileExistsAtPath:file2C]) { return true; }
    else { return false; }
    return false;
}

bool ensure_file(const char *file, int owner, mode_t mode) {
    NSString *path = @(file);
    NSFileManager *fm = [NSFileManager defaultManager];
    id attributes = [fm attributesOfItemAtPath:path error:nil];
    if (attributes &&
        [attributes[NSFileType] isEqual:NSFileTypeRegular] &&
        [attributes[NSFileOwnerAccountID] isEqual:@(owner)] &&
        [attributes[NSFileGroupOwnerAccountID] isEqual:@(owner)] &&
        [attributes[NSFilePosixPermissions] isEqual:@(mode)]
        ) {
        // File exists and matches arguments
        return true;
    }
    if (attributes) {
        if ([attributes[NSFileType] isEqual:NSFileTypeRegular]) {
            // Item exists and is a file
            return [fm setAttributes:@{
                                       NSFileOwnerAccountID: @(owner),
                                       NSFileGroupOwnerAccountID: @(owner),
                                       NSFilePosixPermissions: @(mode)
                                       } ofItemAtPath:path error:nil];
        } else if (![fm removeItemAtPath:path error:nil]) {
            // Item exists and is not a file but could not be removed
            return false;
        }
    }
    // Item does not exist at this point
    return [fm createFileAtPath:path contents:nil attributes:@{
                                                               NSFileOwnerAccountID: @(owner),
                                                               NSFileGroupOwnerAccountID: @(owner),
                                                               NSFilePosixPermissions: @(mode)
                                                               }];
}


//NONCE SHIT
void setNonce(const char *nonce, bool shouldSet) {
    if (shouldSet) {
        execCmd("/usr/sbin/nvram", "-p", NULL);//Unlock NVRam
        if (execCmd("/usr/sbin/nvram", "com.apple.System.boot-nonce", NULL) != ERR_SUCCESS || strstr(lastSystemOutput.bytes, nonce) == NULL) {// Set boot-nonce.
            _assert(execCmd("/usr/sbin/nvram", [NSString stringWithFormat:@"%s=%s", "com.apple.System.boot-nonce", nonce].UTF8String, NULL) == ERR_SUCCESS, localize(@"Unable to set boot nonce."), true);
            _assert(execCmd("/usr/sbin/nvram", [NSString stringWithFormat:@"%s=%s", "IONVRAM-FORCESYNCNOW-PROPERTY", "com.apple.System.boot-nonce"].UTF8String, NULL) == ERR_SUCCESS, localize(@"Unable to synchronize boot nonce."), true); }
        execCmd("/usr/sbin/nvram", "-p", NULL); //LockNVRAM();
    }
}

bool doesFileExist(NSString *fileName) {
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        return true; }
    else { return false; }
}

void fixspringboardPlistAndFS() {
    util_info("[freya] Fixing Fileystem");
    //removeFileIfExists("/Library/MobileSubstrate/ServerPlugins/Unrestrict.dylib");
    if (access("/usr/bin/ldid", F_OK) != ERR_SUCCESS) {
        _assert(access("/usr/libexec/ldid", F_OK) == ERR_SUCCESS, @"Failed to copy over our resources to RootFS.", true);
        _assert(ensure_symlink("../libexec/ldid", "/usr/bin/ldid"), @"Failed to copy over our resources to RootFS.", true); }
    util_info("Allowing SpringBoard to show non-default system apps...");
    _assert(mod_plist_file(@"/var/mobile/Library/Preferences/com.apple.springboard.plist", ^(id plist) {
        plist[@"SBShowNonDefaultSystemApps"] = @true;
    }), @"Failed to disallow SpringBoard to show non-default system apps.", true);
    util_info("Successfully allowed SpringBoard to show non-default system apps.");
    _assert(ensure_directory("/var/lib", 0, 0755), @"Failed to repair filesystem.", true);
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;
    if ([fm fileExistsAtPath:@"/var/lib/dpkg" isDirectory:&isDir] && isDir) {
        if ([fm fileExistsAtPath:@"/Library/dpkg" isDirectory:&isDir] && isDir) {
            LOG(@"Removing /var/lib/dpkg...");
            _assert([fm removeItemAtPath:@"/var/lib/dpkg" error:nil], @"Failed to repair filesystem.", true); }
        else {
            LOG(@"Moving /var/lib/dpkg to /Library/dpkg...");
            _assert([fm moveItemAtPath:@"/var/lib/dpkg" toPath:@"/Library/dpkg" error:nil], @"Failed to repair filesystem.", true); } }
    _assert(ensure_symlink("/Library/dpkg", "/var/lib/dpkg"), @"Failed to repair filesystem.", true);
    _assert(ensure_directory("/Library/dpkg", 0, 0755), @"Failed to repair filesystem.", true);
    _assert(ensure_file("/var/lib/dpkg/status", 0, 0644), @"Failed to repair filesystem.", true);
    _assert(ensure_file("/var/lib/dpkg/available", 0, 0644), @"Failed to repair filesystem.", true);
    NSString *file = [NSString stringWithContentsOfFile:@"/var/lib/dpkg/info/firmware-sbin.list" encoding:NSUTF8StringEncoding error:nil];
    if ([file rangeOfString:@"/sbin/fstyp"].location != NSNotFound || [file rangeOfString:@"\n\n"].location != NSNotFound) {
        file = [file stringByReplacingOccurrencesOfString:@"/sbin/fstyp\n" withString:@""];
        file = [file stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"];
        [file writeToFile:@"/var/lib/dpkg/info/firmware-sbin.list" atomically:YES encoding:NSUTF8StringEncoding error:nil]; }
    
    _assert(ensure_symlink("/usr/lib", "/usr/lib/_ncurses"), message, true);
    _assert(ensure_directory("/Library/Caches", 0, S_ISVTX | S_IRWXU | S_IRWXG | S_IRWXO), message, true);
    trust_file(@"/bin/inject_criticald");
    util_info("[freya] Finished Fixing Filesystem!");
    if (weneedaUICACHE == 1) {
        uicaching("uicache");
        trust_file(@"/usr/bin/uicache");
        execCmd("/usr/bin/plutil","-key", "SBShowNonDefaultSystemApps", "-value", "YES", "/var/mobile/Library/Preferences/com.apple.springboard.plist", NULL);
        _assert(execCmd("/usr/bin/uicache", NULL) >= 0, localize(@"Unable to refresh icon cache."), true); }
}

void startjbd() {
    removeFileIfExists("/var/log/pspawn.log");
    removeFileIfExists("/freya/suckmyd.old.log");
    copyMe("/var/log/suckmyd-stderr.log", "/freya/suckmyd.old.log");
    removeFileIfExists("/var/log/suckmyd-stdout.log");
    removeFileIfExists("/var/log/suckmyd-stderr.log");
    removeFileIfExists("/var/log/suckmyd-stdout.log.bak");
    removeFileIfExists("/var/log/suckmyd-stderr.log.bak");
    removeFileIfExists("/var/log/amfid_payload.log");
    removeFileIfExists("/var/log/pspawn_payload.log");
    removeFileIfExists("/var/log/pspawn_hook.log");
    removeFileIfExists("/var/log/pspawn_payload_xpcproxy.log");
    removeFileIfExists("/var/log/pspawn_payload_other.log");
    removeFileIfExists("/var/log/pspawn_hook_xpcproxy.log");
    chown("/usr/lib/suckmyd", 0, 0);
    chmod("/usr/lib/suckmyd", 0755);
    _assert(execCmd("/freya/launchctl", "load", "/freya/LD/suckmyd.plist", NULL) == ERR_SUCCESS, @"Failed to load jbd", true);
    usleep(10000);
    if (waitFF("/var/tmp/suckmyd.pid") == ERR_SUCCESS) {
        printf(".\n"); util_info("jbd has been loaded!"); jbdfinished("started jbd"); thejbdawaits = 1; }
    else {
        util_info("Error loading jbd!");
        if (waitFF("/var/tmp/suckmyd.pid") == ERR_SUCCESS) { util_info("AGAIN FFS Error loading jbd!"); printf(".\n"); util_info("jbd has been loaded!"); jbdfinished("started jbd"); thejbdawaits = 1; }
        else {
                showMSG(NSLocalizedString(@"Error loading jbd try again", nil), 1, 1);
                dispatch_sync( dispatch_get_main_queue(), ^{
                    UIApplication *app = [UIApplication sharedApplication];
                    [app performSelector:@selector(suspend)];//wait 2 seconds while app is going background
                    [NSThread sleepForTimeInterval:1.0];//exit app when app is in background
                    exit(1);  }); } }//reboot(RB_QUICK);
}//

bool killAMFID() {
    amfid_pid = pidOfProcess("/usr/libexec/amfid");
    util_info("amfid pid: %d", amfid_pid);
    if (!(amfid_pid > 1)) {
        util_info("Unable to find amfid pid.");
        return false; }
    if (kill(amfid_pid, SIGKILL) != ERR_SUCCESS) {
        util_info("Unable to terminate amfid.");
        return false; }
    util_info("amfid pid: %d", amfid_pid);
    util_info("SIGKILL amfid pid.");
    return true;
}

bool reBack() {
    //execCmd("/usr/bin/sbreload", NULL);
    execCmd("/usr/bin/killall", "SpringBoard", NULL);

    pid_t backboardd_pid = pidOfProcess("/usr/libexec/backboardd");
    if (!(backboardd_pid > 1)) {
        util_info("Unable to find backboardd pid.");
        return false;
    }
    if (kill(backboardd_pid, SIGTERM) != ERR_SUCCESS) {
        util_info("Unable to terminate backboardd.");
        return false;
    }
    //execCmd("/usr/bin/sbreload", NULL);
    return true;
}

void disableStashing()
{
    if (access("/.cydia_no_stash", F_OK) != ERR_SUCCESS) {
        // Disable stashing.
        
        util_info("Disabling stashing...");
        ensure_file("/.cydia_no_stash", 0, 0644);
        util_info("Successfully disabled stashing.");
    }
}

void startAMFID() {
/*    char dict = xpc_dictionary_create(nil, nil, 0);
    xpc_dictionary_set_uint64(dict, "subsystem", 3);
    xpc_dictionary_set_uint64(dict, "handle", UInt64(HANDLE_SYSTEM));
    xpc_dictionary_set_uint64(dict, "routine", UInt64(ROUTINE_START));
    xpc_dictionary_set_uint64(dict, "type", 1);
    xpc_dictionary_set_string(dict, "name", "com.apple.MobileFileIntegrity");
    
    var outDict: xpc_object_t?;
    let rc = xpc_pipe_routine(xpc_bootstrap_pipe(), dict, &outDict);
    if rc == 0,
        let outDict = outDict {
        let rc2 = Int32(xpc_dictionary_get_int64(outDict, "error"))
        if rc2 != 0 {
            return
        }
    } else if rc != 0 {
        return
    }
    */
}

void createWorkingDir() {
    unlink("/freya");
    rmdir("/freya");
    _assert(ensure_directory("/freya", 0, 0755), @"yo wtf?", true);
}
void createWorkingTweakDir() {
    unlink("/usr/lib/TweakInject/"); rmdir("/usr/lib/TweakInject/");
    _assert(ensure_directory("/usr/lib/TweakInject/", 0, 0755), @"yo tweaks?", true);
}
void createWorkingDir_rootless() { _assert(ensure_directory("/var/containers/Bundle/freya", 0, 755), @"yo wtf", true); }
bool runDpkg(NSArray <NSString*> *args, bool forceDeps) {
    if ([args count] < 2) {
        LOG("%s: Nothing to do", __FUNCTION__);
        return false; }
    NSMutableArray <NSString*> *command = [NSMutableArray
                                           arrayWithArray:@[
                                                            @"/usr/bin/dpkg",
                                                            @"--force-bad-path",
                                                            @"--force-configure-any",
                                                            @"--no-triggers"
                                                            ]];
    
    if (forceDeps) { [command addObjectsFromArray:@[@"--force-depends", @"--force-remove-essential"]]; }
    for (NSString *arg in args) { [command addObject:arg]; }
    const char *argv[command.count];
    for (int i=0; i<[command count]; i++) { argv[i] = [command[i] UTF8String]; }
    argv[command.count] = NULL;
    int rv = execCmdV("/usr/bin/dpkg", (int)[command count], argv, NULL);
    return !WEXITSTATUS(rv);
}

bool installDeb(const char *debName, bool forceDeps) {
    return runDpkg(@[@"-i", @(debName)], forceDeps);
}


//Many Thanks to Jake
typedef struct vnode_resolve* vnode_resolve_t;
typedef struct {
    union {
        uint64_t lck_mtx_data;
        uint64_t lck_mtx_tag;
    };
    union {
        struct {
            uint16_t lck_mtx_waiters;
            uint8_t lck_mtx_pri;
            uint8_t lck_mtx_type;
        };
        struct {
            struct _lck_mtx_ext_ *lck_mtx_ptr;
        };
    };
} lck_mtx_t;

bool runApt(NSArray <NSString*> *args) {
    if ([args count] < 1) {
        LOG("%s: Nothing to do", __FUNCTION__);
        return false;
    }
    NSMutableArray <NSString*> *command = [NSMutableArray arrayWithArray:@[
                                                                           @"/usr/bin/apt-get",
                                                                           @"-o", @"Dir::Etc::sourcelist=freya/freya.list",
                                                                           @"-o", @"Dir::Etc::sourceparts=-",
                                                                           @"-o", @"APT::Get::List-Cleanup=0"
                                                                           ]];
    [command addObjectsFromArray:args];
    
    const char *argv[command.count];
    for (int i=0; i<[command count]; i++) {
        argv[i] = [command[i] UTF8String];
    }
    argv[command.count] = NULL;
    int rv = execCmdV(argv[0], (int)[command count], argv, NULL);
    return !WEXITSTATUS(rv);
}

typedef uint32_t kauth_action_t;
LIST_HEAD(buflists, buf);

struct vnode {
    lck_mtx_t v_lock;            /* vnode mutex */
    TAILQ_ENTRY(vnode) v_freelist;        /* vnode freelist */
    TAILQ_ENTRY(vnode) v_mntvnodes;        /* vnodes for mount point */
    TAILQ_HEAD(, namecache) v_ncchildren;    /* name cache entries that regard us as their parent */
    LIST_HEAD(, namecache) v_nclinks;    /* name cache entries that name this vnode */
    vnode_t     v_defer_reclaimlist;        /* in case we have to defer the reclaim to avoid recursion */
    uint32_t v_listflag;            /* flags protected by the vnode_list_lock (see below) */
    uint32_t v_flag;            /* vnode flags (see below) */
    uint16_t v_lflag;            /* vnode local and named ref flags */
    uint8_t     v_iterblkflags;        /* buf iterator flags */
    uint8_t     v_references;            /* number of times io_count has been granted */
    int32_t     v_kusecount;            /* count of in-kernel refs */
    int32_t     v_usecount;            /* reference count of users */
    int32_t     v_iocount;            /* iocounters */
    void *   v_owner;            /* act that owns the vnode */
    uint16_t v_type;            /* vnode type */
    uint16_t v_tag;                /* type of underlying data */
    uint32_t v_id;                /* identity of vnode contents */
    union {
        struct mount    *vu_mountedhere;/* ptr to mounted vfs (VDIR) */
        struct socket    *vu_socket;    /* unix ipc (VSOCK) */
        struct specinfo    *vu_specinfo;    /* device (VCHR, VBLK) */
        struct fifoinfo    *vu_fifoinfo;    /* fifo (VFIFO) */
        struct ubc_info *vu_ubcinfo;    /* valid for (VREG) */
    } v_un;
    struct    buflists v_cleanblkhd;        /* clean blocklist head */
    struct    buflists v_dirtyblkhd;        /* dirty blocklist head */
    struct klist v_knotes;            /* knotes attached to this vnode */
    /*
     * the following 4 fields are protected
     * by the name_cache_lock held in
     * excluive mode
     */
    kauth_cred_t    v_cred;            /* last authorized credential */
    kauth_action_t    v_authorized_actions;    /* current authorized actions for v_cred */
    int        v_cred_timestamp;    /* determine if entry is stale for MNTK_AUTH_OPAQUE */
    int        v_nc_generation;    /* changes when nodes are removed from the name cache */
    /*
     * back to the vnode lock for protection
     */
    int32_t        v_numoutput;            /* num of writes in progress */
    int32_t        v_writecount;            /* reference count of writers */
    const char *v_name;            /* name component of the vnode */
    vnode_t v_parent;            /* pointer to parent vnode */
    struct lockf    *v_lockf;        /* advisory lock list head */
    int     (**v_op)(void *);        /* vnode operations vector */
    mount_t v_mount;            /* ptr to vfs we are in */
    void *    v_data;                /* private data for fs */
    
    struct label *v_label;            /* MAC security label */
    
    //#if CONFIG_TRIGGERS
    vnode_resolve_t v_resolve;        /* trigger vnode resolve info (VDIR only) */
    //#endif /* CONFIG_TRIGGERS */
};


NSArray *getPackages(const char *packageFile) {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSError *error;
    NSCharacterSet *separator = [NSCharacterSet newlineCharacterSet]; //Read File Line By Line
    NSString *contentsOfFile = [NSString stringWithContentsOfFile:[NSString stringWithUTF8String:packageFile] encoding:NSASCIIStringEncoding error:&error];
    NSArray *linesOfFile = [contentsOfFile componentsSeparatedByCharactersInSet:separator];
    for (NSString *line in linesOfFile) {//Read Lines
        if ([line hasPrefix:@"Filename: "]) {//Does the line start with Package: ? //If so, what is after that? Lets add it to our array.
            NSString *packageNameToAdd = [line componentsSeparatedByString:@"Filename: ./"][1]; //Good Practice I guess?
            if (![array containsObject:packageNameToAdd]) {
                [array addObject:packageNameToAdd]; } }
    }//We got our array.
    return array;
}
void createTweakinjectRepo(){
     FILE *file;
     file = fopen("/etc/apt/sources.list.d/freya.list","w"); /* write file (create a file if it does not exist and if it does treat as empty.*/
     fprintf(file,"%s","deb https://shogunpwnd.github.io/cydia/ ./\n"); //writes
     fprintf(file,"%s","\n"); //writes
     fclose(file);
//      FILE *file;
  //    file = fopen("/etc/apt/sources.list.d/freya.list","w"); /* write file (create a file if it does not exist and if it does treat as empty.*/
      //fprintf(file,"%s","deb https://repo.theodyssey.dev/ ./\n"); //writes
      //fprintf(file,"%s","deb https://ricklantis.github.io/repo/ ./\n"); //writes
      //fprintf(file,"%s","\n"); //writes
      //fclose(file);
}
void createLocalRepo()
{
    _assert(ensure_directory("/etc/apt/freya", 0, 0755), @"Failed to extract bootstrap.", true);
    clean_file("/etc/apt/sources.list.d/freya");
    const char *listPath = "/etc/apt/freya/freya.list";
    NSString *listContents = @"deb file:///var/lib/freya/apt ./\n";
    NSString *existingList = [NSString stringWithContentsOfFile:@(listPath) encoding:NSUTF8StringEncoding error:nil];
    if (![listContents isEqualToString:existingList]) {
        clean_file(listPath);
        [listContents writeToFile:@(listPath) atomically:NO encoding:NSUTF8StringEncoding error:nil];
    }
    createFile(listPath, 0, 0644);
    NSString *repoPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/bootstrap/DEBS"];
    _assert(repoPath != nil, @"Repo path is null!", true);
    ensure_directory("/var/lib/freya", 0, 0755);
    ensure_symlink([repoPath UTF8String], "/var/lib/freya/apt");
    //runApt(@[@"update"]);
   // FILE *file;
    //file = fopen("/etc/apt/sources.list.d/TH0R.list","w"); /* write file (create a file if it does not exist and if it does treat as empty.*/
    //fprintf(file,"%s","deb https://shogunpwnd.github.io/cydia/ ./\n"); //writes
   // fprintf(file,"%s","\n"); //writes
    //fclose(file);
    
     //FILE *file;
     //file = fopen("/etc/apt/sources.list.d/freya.list","w"); /* write file (create a file if it does not exist and if it does treat as empty.*/
     //fprintf(file,"%s","deb https://repo.theodyssey.dev/ ./\n"); //writes
     //fprintf(file,"%s","deb https://ricklantis.github.io/repo/ ./\n"); //writes
     //fprintf(file,"%s","\n"); //writes
     //fclose(file);
    // Workaround for what appears to be an apt bug
    ensure_symlink("/var/lib/freya/apt/./Packages", "/var/lib/apt/lists/_var_lib_freya_apt_._Packages");
}

void yesdebsinstall() {


    debsinstalling();
    cp("/bin/tar", "/freya/tar");
    cp("/bin/rm", "/freya/rm");
    trust_file(@"/bin/rm");
    trust_file(@"/bin/sh");
    trust_file(@"/bin/ln");
    trust_file(@"/bin/bash");
    trust_file(@"/freya/tar");
    trust_file(@"/bin/tar");
    execCmd("/bin/rm", "-rdf", "/bin/sh", NULL);
    execCmd("/bin/ln", "/bin/bash", "/bin/sh", NULL);
    NSString *deb1 = get_bootstrap_file(@"DEEZDEBS.tar.gz");//  ///DEEZDEBS.tar.gz
    pid_t pd;
    posix_spawn(&pd, "/freya/tar", NULL, NULL, (char **)&(const char*[]){ "/freya/tar", "-xf", [deb1 UTF8String], "-C", "/freya/", NULL }, NULL);
    waitpid(pd, NULL, 0);
    //cp(to,from);
    int checkcheckRa1nmarker1 = (file_exists("/.bootstrapped"));
    extractFile(get_bootstrap_file(@"rmDevice.tar"), @"/freya/");
   // ls("/freya/");
    //cp("/freya/rm", "/bin/rm");

    execCmd("/freya/rm", "-rdf", "/bin/tar", NULL);
    execCmd("/bin/rm", "-rdf", "/bin/tar", NULL);

    cp("/bin/tar", "/freya/tar");
    trust_file(@"/bin/tar");
    trust_file(@"/freya/tar");

    if (checkfsfixswitch == 1) {
        int ret = systemCmd("/freya/cydiafix.sh");
        printf("did we script cydia successfully? =%d\n", ret);
        posix_spawn(&pd, "/freya/tar", NULL, NULL, (char **)&(const char*[]){ "/freya/tar", "--preserve-permissions", "-xf", [deb1 UTF8String], "-C", "/freya/", NULL }, NULL);
        waitpid(pd, NULL, 0);

        installDeb([get_debian_file(@"substitute.deb") UTF8String], true);
        installDeb([get_debian_file(@"tweakinject.deb") UTF8String], true);
        installDeb([get_debian_file(@"mobilesubstrate.deb") UTF8String], true);
    } else {
        if (checkcheckRa1nmarker1 == 0) {
            trust_file(@"/usr/bin/dpkg");
            trust_file(@"/usr/bin/dpkg-deb");
            trust_file(@"/usr/bin/dpkg-split");
            trust_file(@"/usr/bin/tar");
            trust_file(@"/bin/tar");
            trust_file(@"/bin/rm");
            removeFileIfExists("/private/etc/apt/sources.list.d/freya.list");
            removeFileIfExists("/private/etc/apt/freya");
            removeFileIfExists("/private/etc/apt/trusted.gpg.d");
            installDeb([get_debian_file(@"file_5.35-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"openssh_8.4-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"base_1-5_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"system-cmds_790.30.1-2_iphoneos-arm.deb") UTF8String], true);
            
            installDeb([get_debian_file(@"cydia_1.1.36_iphoneos-arm.deb") UTF8String], true);

            installDeb([get_debian_file(@"signing-certificate_0.0.1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"uikittools_1.1.21-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"cydia-lproj_1.1.32~b1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"launchctl_25_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"com.bingner.plutil_0.2.1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"substitute.deb") UTF8String], true);
            installDeb([get_debian_file(@"tweakinject.deb") UTF8String], true);
            installDeb([get_debian_file(@"mobilesubstrate.deb") UTF8String], true);
            installDeb([get_debian_file(@"firmware-sbin_0-1_all.deb") UTF8String], true);
            installDeb([get_debian_file(@"essential_0-3_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"dpkg_1.19.7-2_iphoneos-arm.deb") UTF8String], true);
            //installDeb([get_bootstrap_file(@"cydia_1.1.37_iphoneos-arm_OG.deb") UTF8String], true);
            installDeb([get_debian_file(@"cydia_1.1.36_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"mmaintenanced-reback_1.0-1+debug_iphoneos-arm.deb") UTF8String], true);
            //installDeb([get_debian_file(@"com.mtac.sbshownondefaultsystemapps_1.0.0_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"diffutils_3.6-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"readline_8.0-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"trustinjector_0.4~b5_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"debianutils_4.8.6-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"darwintools_1.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libssl1.1.1_1.1.1i-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libssl-dev_1.1.1i-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"npth_1.6-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"xz_5.2.4-4_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"sed_4.5-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"shell-cmds_118-8_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"lzma_4.32.7-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"lz4_1.7.5-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"bzip2_1.0.6-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"ncurses5-libs_5.9-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libtasn1_4.13-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"ncurses_6.1+20181013-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libassuan_2.5.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"berkeleydb_6.2.32-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"ca-certificates_0.0.2_all.deb") UTF8String], true);
            installDeb([get_debian_file(@"gnutls_3.5.19-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"file_5.35-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libplist3_2.2.1-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"grep_3.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"gzip_1.9-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libunistring_0.9.10-1_iphoneos-arm.deb") UTF8String], true);
            //installDeb([get_debian_file(@"coreutils_8.31-1_iphoneos-arm.deb") UTF8String], true);
            //installDeb([get_debian_file(@"coreutils-bin_8.31-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"file-cmds_220.7-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"nettle_3.4.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libksba_1.3.5-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libidn2_6.1.2-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"diskdev-cmds_593.221.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libplist++3_2.2.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libapt-pkg5.0_1.8.2.2-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libapt_1.8.2.2-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"apt_1.8.2.2-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libgpg-error_1.32-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"apt-key_1.8.2.2-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"profile.d_0-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"developer-cmds_48-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libstdc++_0-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"ldid_2_2.1.5-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"openssh-client_8.4-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"openssh-server_8.4-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"openssh-global-listener_8.4-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"openssh_8.4-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libssl1.1.1_1.1.1n-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libssl-dev_1.1.1n-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libplist_2.2.1-3_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"openssl_1.1.1i-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"p11-kit_0.23.12-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libplist-utils_2.2.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libplist-dev_2.2.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libplist++3_2.2.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libplist++-dev_2.2.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"tar_1.33-1_iphoneos-arm.deb") UTF8String], true);
          
            //extractFile(get_bootstrap_file(@"rmDevice.tar"), @"/bin");
            //cp("/freya/rm", "/bin/rm");
            //extractFile(get_bootstrap_file(@"rmDevice.tar"), @"/freya");

            execCmd("/bin/rm", "-rdf", "/freya/DEBS", NULL);
            cp("/usr/bin/ldrestart", "/freya/ldrestart");
            execCmd("/usr/bin/dpkg", "--configure", "-a", NULL);
           // _assert(clean_file("/usr/lib/libjailbreak.dylib"), localize(@"Unable to clean old libjailbreak dylib."), true);
            _assert(execCmd("/usr/bin/uicache", NULL) >= 0, localize(@"Unable to refresh icon cache."), true);
            weneedaUICACHE = 1;
            systemCmd("/usr/libexec/cydia/firmware.sh");
        } else {
            trust_file(@"/usr/bin/dpkg");
            trust_file(@"/usr/bin/dpkg-deb");
            trust_file(@"/usr/bin/dpkg-split");
            trust_file(@"/usr/bin/tar");
            trust_file(@"/bin/tar");
            trust_file(@"/bin/rm");
            removeFileIfExists("/private/etc/apt/sources.list.d/freya.list");
            removeFileIfExists("/private/etc/apt/freya");
            removeFileIfExists("/private/etc/apt/trusted.gpg.d");
            installDeb([get_debian_file(@"file_5.35-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"openssh_8.4-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"base_1-5_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"system-cmds_790.30.1-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"cydia_1.1.36_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"signing-certificate_0.0.1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"uikittools_1.1.21-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"cydia-lproj_1.1.32~b1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"launchctl_25_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"com.bingner.plutil_0.2.1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"substitute.deb") UTF8String], true);
            installDeb([get_debian_file(@"tweakinject.deb") UTF8String], true);
            installDeb([get_debian_file(@"mobilesubstrate.deb") UTF8String], true);
            installDeb([get_debian_file(@"firmware-sbin_0-1_all.deb") UTF8String], true);
            installDeb([get_debian_file(@"essential_0-3_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"dpkg_1.19.7-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"cydia_1.1.36_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"mmaintenanced-reback_1.0-1+debug_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"com.mtac.sbshownondefaultsystemapps_1.0.0_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"diffutils_3.6-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"readline_8.0-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"trustinjector_0.4~b5_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"debianutils_4.8.6-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"darwintools_1.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libssl1.1.1_1.1.1i-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libssl-dev_1.1.1i-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"npth_1.6-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"xz_5.2.4-4_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"sed_4.5-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"shell-cmds_118-8_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"lzma_4.32.7-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"lz4_1.7.5-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"bzip2_1.0.6-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"ncurses5-libs_5.9-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libtasn1_4.13-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"ncurses_6.1+20181013-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libassuan_2.5.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"berkeleydb_6.2.32-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"ca-certificates_0.0.2_all.deb") UTF8String], true);
            installDeb([get_debian_file(@"gnutls_3.5.19-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"file_5.35-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libplist3_2.2.1-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"grep_3.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"gzip_1.9-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libunistring_0.9.10-1_iphoneos-arm.deb") UTF8String], true);
            //installDeb([get_debian_file(@"coreutils_8.31-1_iphoneos-arm.deb") UTF8String], true);
            //installDeb([get_debian_file(@"coreutils-bin_8.31-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"file-cmds_220.7-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"nettle_3.4.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libksba_1.3.5-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libidn2_6.1.2-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"diskdev-cmds_593.221.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libplist++3_2.2.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libapt-pkg5.0_1.8.2.2-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libapt_1.8.2.2-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"apt_1.8.2.2-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libgpg-error_1.32-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"apt-key_1.8.2.2-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"profile.d_0-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"developer-cmds_48-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libstdc++_0-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"ldid_2_2.1.5-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"openssh-client_8.4-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"openssh-server_8.4-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"openssh-global-listener_8.4-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"openssh_8.4-2_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libssl1.1.1_1.1.1n-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libssl-dev_1.1.1n-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libplist_2.2.1-3_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"openssl_1.1.1i-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"p11-kit_0.23.12-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libplist-utils_2.2.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libplist-dev_2.2.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libplist++3_2.2.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"libplist++-dev_2.2.1-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_debian_file(@"tar_1.33-1_iphoneos-arm.deb") UTF8String], true);
            installDeb([get_bootstrap_file(@"cydia_1.1.37_iphoneos-arm_OG.deb") UTF8String], true);

            cp("/usr/bin/ldrestart", "/freya/ldrestart");
            int ret = systemCmd("/freya/cydiafix.sh");
            printf("did we script cydia successfully? =%d\n", ret);
            execCmd("/freya/rm", "-rdf", "/freya/DEBS", NULL);
            execCmd("/usr/bin/dpkg", "--configure", "-a", NULL);
            _assert(execCmd("/usr/bin/uicache", NULL) >= 0, localize(@"Unable to refresh icon cache."), true);
            weneedaUICACHE = 1;
        }
        trust_file(@"/usr/lib/libapt-private.0.0.dylib");
        trust_file(@"/usr/lib/libapt-pkg.5.0.dylib");
        execCmd("/usr/bin/dpkg", "--configure", "-a", NULL);
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:@"/freya/DEBS" error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:@"/freya/Deezdebs" error:nil];
    removeFileIfExists("/freya/DEBS_4_ios12_updates");
    cydiaDone("Cydia done");
    weneedaUICACHE = 1;
}

void xpcFucker() {
    util_info("Patching XPCPROXY...");
    const char *patchedExec = "/usr/libexec/xpcproxy.sliced";
    //Always update xpcproxy
    //TODO: Hash Check here so we don't have to patch it everytime.
    if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:patchedExec]]) {
        usleep(200);
        util_info("%s Does Not Exist! Continuing...", patchedExec);
        copyMe("/usr/libexec/xpcproxy", "/usr/libexec/xpcproxy.sliced");
        usleep(200);
        //INSERT DYLIB ARGS
        const char *args[] = { "insert_dylib", "--all-yes", "--inplace", "--overwrite", "/usr/lib/pspawn_payload.dylib", "/usr/libexec/xpcproxy.sliced", NULL};
        insert_dylib_main(6, args);
        util_info("Patched Executable!");
        //Set Permissions
        chmod(patchedExec, 755);
        chown(patchedExec, 0, 0);
        //Sign WITH JTOOL (ldid wasn't working all that well, but who cares. This works JUST fine.0
        execCmd("/freya/jtool", "--sign", "--inplace", "--ent", "/freya/default.ent", "/usr/libexec/xpcproxy.sliced", NULL);
    }
    
    trust_file([NSString stringWithUTF8String:patchedExec]);
    //Fake The New File Path
    uint64_t realxpc = vnodeForPath("/usr/libexec/xpcproxy");
    uint64_t fakexpc = vnodeForPath(patchedExec);
    struct vnode rvp, fvp;
    rkbuffer(realxpc, &rvp, sizeof(struct vnode));
    rkbuffer(fakexpc, &fvp, sizeof(struct vnode));
    
    fvp.v_usecount = rvp.v_usecount;
    fvp.v_kusecount = rvp.v_kusecount;
    fvp.v_parent = rvp.v_parent;
    fvp.v_freelist = rvp.v_freelist;
    fvp.v_mntvnodes = rvp.v_mntvnodes;
    fvp.v_ncchildren = rvp.v_ncchildren;
    fvp.v_nclinks = rvp.v_nclinks;
    
    wkbuffer(realxpc, &fvp, sizeof(struct vnode)); // :o
    //We Should Now Have A WORKING Patched XPCProxy!
    //We should be alive.
    util_info("Hello?");
 }

char *itoasss(long n) {
    int len = n==0 ? 1 : floor(log10l(labs(n)))+1;
    if (n<0) len++; // room for negative sign '-'
    
    char    *buf = calloc(sizeof(char), len+1); // +1 for null
    snprintf(buf, len+1, "%ld", n);
    return   buf;
}
uint32_t find_pid_of_proc(const char *proc_name) {
    uint64_t proc = ReadKernel64(GETOFFSET(allproc));
    while (proc) {
        uint32_t pid = (uint32_t)ReadKernel32(proc + off_p_pid);
        char name[40] = {0};
        kreadOwO(proc+0x268, name, 20);
        if (strstr(name, proc_name)){
            return pid;
        }
        proc = ReadKernel64(proc);
    }
    return 0;
}

void kickMe()
{

    //After we extracted the bootstrap, this is all we need to get back into jailbroken state.
#define BinaryLocation "/freya/inject_criticald"
    
    if (kickcheck == 0) { //removeFileIfExists("/Library/MobileSubstrate/ServerPlugins/Unrestrict.dylib");
       // trust_file(@"/usr/lib/libsubstitute.dylib");
        trust_file(@"/usr/lib/libsubstrate.dylib");
       // trust_file(@"/usr/lib/libjailbreak.dylib");
       // trust_file(@"/usr/lib/TweakInject.dylib");
        //trust_file(@"/usr/lib/pspawn_payload.dylib");
        //trust_file(@"/usr/lib/amfid_payload.dylib");
        //copyMe("/freya/inject_criticald", "/bin/inject_criticald");
        if (thejbdawaits == 0) {
            startingJBD("jbd waiting...6");
            startjbd();
            removeFileIfExists("/usr/libexec/xpcproxy.sliced");
            xpcFucker();//might need to not do this step too but lets see
            
            if (checkforceuicacheswitch == 1) {
                uicaching("uicache");
                execCmd("/usr/bin/plutil","-key", "SBShowNonDefaultSystemApps", "-value", "YES", "/var/mobile/Library/Preferences/com.apple.springboard.plist", NULL);
                trust_file(@"/usr/bin/uicache");
                _assert(execCmd("/usr/bin/uicache", NULL) >= 0, localize(@"Unable to refresh icon cache."), true);
                execCmd("/usr/bin/uicache", "-a", NULL); } }
        kickcheck = 1;
    }
    if (checkforceuicacheswitch == 1) {
        uicaching("uicache");
        trust_file(@"/usr/bin/uicache");
        _assert(execCmd("/usr/bin/uicache", NULL) >= 0, localize(@"Unable to refresh icon cache."), true);
        execCmd("/usr/bin/uicache", "-a", NULL);
    }
    update_springboard_plist();

    
}

void updatePayloads() {

    extractamfidjbdstuff("extracting base tools waiting");

    if (ourtoolsextracted != 1) {
        extractFile(get_bootstrap_file(@"aJBDofSorts.tar.gz"), @"/");
        ourtoolsextracted = 1;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults integerForKey:@"SetNonce"] == 0) {//if ([defaults objectForKey:@"SetNonce"] == 0) {
        unlocknvram();
        setNonce(genToSet(), TRUE);
        locknvram(); }
    
    if (doweneedamfidPatch == 1) {
        util_info("Amfid done fucked up already!");
    } else {
        if (patchtheSIGNSofCOde()){
            util_info("Amfid bombed without bootstrapping!");
        } else {
            util_info("Failure to bomb Amfid");
            showMSG(NSLocalizedString(@"Failure to bomb Amfid! We are going to reboot your device.", nil), 1, 1);
            dispatch_sync( dispatch_get_main_queue(), ^{
                UIApplication *app = [UIApplication sharedApplication];
                [app performSelector:@selector(suspend)];
                [NSThread sleepForTimeInterval:1.0];//wait 2 seconds while app is going background
                reboot(RB_QUICK); });//exit app when app is in background
        }
    }

    //Backup Tweaks
    removeFileIfExists("/freya/showappsfix.sh");
    removeFileIfExists("/freya/cydiafix.sh");
    removeFileIfExists("/freya/Ent.plist");
    removeFileIfExists("/freya/jailbreakd");
    removeFileIfExists("/freya/jailbreakd_client");
    removeFileIfExists("/freya/ra1nscriptsign.sh");
    removeFileIfExists("/freya/cydiafixscript.sh");
    
    if (file_exists("/usr/lib/TweakInject") || file_exists("/Library/MobileSubstrate/DynamicLibraries")) {
        //copyMe("/Library/MobileSubstrate/DynamicLibraries", "/usr/lib/TweakInject");
        copyMe("/usr/lib/TweakInject", "/usr/lib/TweakInject.bak");
        removeFileIfExists("/usr/lib/TweakInject");
        removeFileIfExists("/Library/MobileSubstrate/DynamicLibraries");
        execCmd("/bin/ln", "-s",  "../../usr/lib/TweakInject", "/Library/MobileSubstrate/DynamicLibraries", NULL);
        //_assert(ensure_directory("/usr/lib/TweakInject/", 0, 0755), @"yo tweaks?", true);
        copyMe("/usr/lib/TweakInject.bak/", "/usr/lib/TweakInject/");
        //execCmd("/bin/mv", "/usr/lib/TweakInject.bak", "/usr/lib/TweakInject", NULL);

        //execCmd("/bin/ls", "-la",  "/Library/MobileSubstrate/", NULL);
        removeFileIfExists("/usr/lib/TweakInject/MobileSafety.plist");
        removeFileIfExists("/usr/lib/TweakInject/MobileSafety.dylib");

       // execCmd("/bin/ls", "-la",  "/usr/lib/TweakInject/", NULL);
        removeFileIfExists("/usr/lib/TweakInject.bak");
    }
    
    kickMe();
}


void addToArray(NSString *package, NSMutableArray *array)
{
    NSString *dir = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/bootstrap/DEBS/"];
    NSString *strToAdd = [dir stringByAppendingString:package];
    
    [array addObject:strToAdd];
}

int ios15getrootXina() {
    uint64_t self_ucred = ReadKernel64(our_procStruct_addr_exported + off_p_ucred);
    //my_ucred=self_ucred;
    uint64_t cr_posix_p = self_ucred +0x18;
   // struct posix_cred zero_cred={0};
   // kwritetw(cr_posix_p,&zero_cred, sizeof(struct posix_cred));
   // KernelWrite(cr_posix_p,&zero_cred, sizeof(struct posix_cred));
    int  err= setgroups(0,0);
    if (err) {
      perror("setgroups");
        NSLog(@"setgroups error\n");
    }
    self_ucred = ReadKernel64(our_procStruct_addr_exported + off_p_ucred);

    return getuid();
}


void installCydia(bool post) {
    if (post == false) {
        extractamfidjbdstuff("extracting base tools waiting");
        removeFileIfExists("/var/freya");
        removeFileIfExists("/freya");
        unlink("/var/freya");
        remove("/var/freya");
        unlink("/freya");
        remove("/freya");
        
        _assert(ensure_directory("/var/freya", 0, 0777), @"yo wtf?", true);
        _assert(ensure_directory("/freya", 0, 0777), @"yo wtf?", true);
        
        if (ourtoolsextracted == 0) {
            
            extractFile(get_bootstrap_file(@"aJBDofSorts.tar.gz"), @"/var/freya/");
            NSString *newout = get_bootstrap_file(@"aJBDofSorts.tar.gz");
            pid_t pd;

            posix_spawn(&pd, "/var/freya/freya/tar", NULL, NULL, (char **)&(const char*[]){ "/var/freya/freya/tar", "--preserve-permissions", "-xvpf", [newout UTF8String], "-C", "/", NULL }, NULL);
            waitpid(pd, NULL, 0);
            cp("/freya/tar", "/var/freya/freya/tar");
            if (!file_exists("/freya/tar")) {
                    util_info("Failed write file on rootfs.");
                    showMSG(NSLocalizedString(@"Failed write file on rootfs, We're going to restore RootFS! then reboot your device. Better luck next time", nil), 1, 1);
                    restoreRootFS();
            }
            extractFile(get_bootstrap_file(@"aJBDofSorts.tar.gz"), @"/");
            ourtoolsextracted = 1;
            extractFile(get_bootstrap_file(@"gangZip.tar"), @"/");
            removeFileIfExists("/var/freya");
            unlink("/var/freya");
            remove("/var/freya");
            cp("/freya/ldrestart", "/usr/bin/ldrestart");

        }
        if (doweneedamfidPatch == 1) {
            util_info("Amfid done fucked up already!");
        } else {
            if (patchtheSIGNSofCOde()){
                util_info("Amfid bombed!");
            } else {
                util_info("Failure to bomb Amfid");
                showMSG(NSLocalizedString(@"Failure to bomb Amfid! We are going to reboot your device.", nil), 1, 1);
                dispatch_sync( dispatch_get_main_queue(), ^{
                    UIApplication *app = [UIApplication sharedApplication];
                    [app performSelector:@selector(suspend)];//wait 2 seconds while app is going background
                    [NSThread sleepForTimeInterval:1.0];//exit app when app is in background
                    reboot(RB_QUICK); }); } }
        chmod("/freya/tar", 0755);
        chown("/freya/tar", 0, 0);
        chmod("/bin/gzip", 0755);
        chown("/bin/gzip", 0, 0);
        //binpack64-256.tar.lzma //strapu0.tar.gz
        updatePayloads();
        thelabelbtnchange("bootstrap extracting....");

        NSString *ourdir = get_bootstrap_file(@"freyastrap.tar.gz");//freyastrapSlim.tar.gz//zeusstrap
        pid_t pd;
        posix_spawn(&pd, "/freya/tar", NULL, NULL, (char **)&(const char*[]){ "/freya/tar", "--preserve-permissions", "-xvpf", [ourdir UTF8String], "-C", "/", NULL}, NULL);
        waitpid(pd, NULL, 0);
        fixspringboardPlistAndFS();
        yesdebsinstall();

        //execCmd("/usr/bin/plutil","-key", "SBShowNonDefaultSystemApps", "-value", "YES", "/var/mobile/Library/Preferences/com.apple.springboard.plist", NULL);
        createLocalRepo();
        //runApt(@[@"update"]);
        //runApt([@[@"-y", @"--allow-unauthenticated", @"--allow-downgrades", @"install"] arrayByAddingObjectsFromArray:@[@"--reinstall", @"cydia"]]);
        ensure_file("/.freya_installed", 0, 0644);
    }
    
}

void uninstallRJB() {
    removeFileIfExists("/var/containers/Bundle/freya");
    showMSG(NSLocalizedString(@"freya Rootless Has Been Uninstalled! We are going to reboot your device.", nil), 1, 1);
    reboot(RB_QUICK);
}
void dothera1n() {
    createWorkingTweakDir();
    removeFileIfExists("/usr/lib/TweakInject");
    copyMe("/Library/MobileSubstrate/DynamicLibraries", "/usr/lib/TweakInject");//worked
    removeFileIfExists("/usr/lib/TweakInject/MobileSafety.plist");
    removeFileIfExists("/usr/lib/TweakInject/MobileSafety.dylib");

    int ret = systemCmd("/freya/ra1nscriptsign.sh");
    printf("did we script successfully? =%d\n", ret);
}
bool checkfsfixswitch;
bool checkforceuicacheswitch;

void initInstall(int packagerType)
{   //0 = Cydia //1 = Zebra
    int f = open("/.freya_installed", O_RDONLY);
    int fcheckra1n = (file_exists("/.bootstrapped")); //int fcheckra1n = open("/.bootstrapped", O_RDONLY);
    if (checkfsfixswitch == 0) {
        if (fcheckra1n == 0) {
            if (f == -1) {
                installCydia(false); ourprogressMeter();
                char *targettype = sysctlWithName("hw.targettype");
                _assert(targettype != NULL, localize(@"Unable to get hardware targettype."), true);
                NSString *const jetsamFile = [NSString stringWithFormat:@"/System/Library/LaunchDaemons/com.apple.jetsamproperties.%s.plist", targettype];
                free(targettype);
                targettype = NULL;
                _assert(mod_plist_file(jetsamFile, ^(id plist) {
                    plist[@"Version4"][@"System"][@"Override"][@"Global"][@"UserHighWaterMark"] = [NSNumber numberWithInteger:[plist[@"Version4"][@"PListDevice"][@"MemoryCapacity"] integerValue]];
                }), localize(@"Unable to update Jetsam plist to increase memory limit."), true);
                ensure_file("/.freya_installed", 0, 0644);
                ourprogressMeter();
                updatePayloads(); ourprogressMeter();
            } else { //checkra1in installed
                    fixspringboardPlistAndFS();
                    ourprogressMeter(); updatePayloads(); ourprogressMeter();
            }
        } else {
                installCydia(false); ourprogressMeter();
                char *targettype = sysctlWithName("hw.targettype");
                _assert(targettype != NULL, localize(@"Unable to get hardware targettype."), true);
                NSString *const jetsamFile = [NSString stringWithFormat:@"/System/Library/LaunchDaemons/com.apple.jetsamproperties.%s.plist", targettype];
                free(targettype);
                targettype = NULL;
                _assert(mod_plist_file(jetsamFile, ^(id plist) {
                    plist[@"Version4"][@"System"][@"Override"][@"Global"][@"UserHighWaterMark"] = [NSNumber numberWithInteger:[plist[@"Version4"][@"PListDevice"][@"MemoryCapacity"] integerValue]];
                }), localize(@"Unable to update Jetsam plist to increase memory limit."), true);
                ensure_file("/.freya_installed", 0, 0644);
                //checkra1in installed
                ourprogressMeter(); updatePayloads();
                dothera1n();ourprogressMeter();
                fixspringboardPlistAndFS();

            }
    } else {
        //fixfs reinstall cydia components
        installCydia(false);
        ourprogressMeter(); //}
        char *targettype = sysctlWithName("hw.targettype");
        _assert(targettype != NULL, localize(@"Unable to get hardware targettype."), true);
        NSString *const jetsamFile = [NSString stringWithFormat:@"/System/Library/LaunchDaemons/com.apple.jetsamproperties.%s.plist", targettype];
        free(targettype);
        targettype = NULL;
        _assert(mod_plist_file(jetsamFile, ^(id plist) {
            plist[@"Version4"][@"System"][@"Override"][@"Global"][@"UserHighWaterMark"] = [NSNumber numberWithInteger:[plist[@"Version4"][@"PListDevice"][@"MemoryCapacity"] integerValue]];
        }), localize(@"Unable to update Jetsam plist to increase memory limit."), true);
        ensure_file("/.freya_installed", 0, 0644);
        if (fcheckra1n == 0) { ourprogressMeter();
            fixspringboardPlistAndFS();
            updatePayloads(); ourprogressMeter();
        }else { //checkra1in installed
            ourprogressMeter(); updatePayloads();fixspringboardPlistAndFS();
            dothera1n(); ourprogressMeter(); }
    }
}

void finish(bool shouldLoadTweaks)
{
    //TODO: Daemons, etc...
    util_info("Finishing up...");
    
    respringing("respringing");
    disableStashing();
    removeFileIfExists("/bin/launchctl");
    //Set Permissions
//    copyMe("/freya/inject_criticald", "/bin/inject_criticald");
  //  copyMe("/freya/jtool", "/usr/local/bin/jtool");
    removeFileIfExists("/freya/jtool");
    removeFileIfExists("/freya/tar");
    removeFileIfExists("/freya/inject_criticald");
    copyMe("/freya/launchctl", "/bin/launchctl");
    removeFileIfExists("/freya/launchctl");
    removeFileIfExists("/freya/signcert.p12");
    removeFileIfExists("/freya/default.ent");
    removeFileIfExists("/freya/LD");
    removeFileIfExists("/ent");
    removeFileIfExists("/freya/suckmyd_client");
    removeFileIfExists("/freya/suckmyd.old.log");
    removeFileIfExists("/freya");
    chown("/usr/bin/ldrestart", 0, 0);
    chmod("/usr/bin/ldrestart", 0755);

    chmod("/usr/bin/sbreload", 0755);
    chown("/usr/bin/sbreload", 0, 0);
    chmod("/usr/bin/rebackboardd", 0755);
    chown("/usr/bin/rebackboardd", 0, 0);

    createFile("/tmp/.jailbroken_freya", 0, 0644);
    //killAMFID();
   // execCmd("/usr/bin/plutil","-key", "SBShowNonDefaultSystemApps", "-value", "YES", "/var/mobile/Library/Preferences/com.apple.springboard.plist", NULL);

    if (shouldLoadTweaks)
    {
        util_info("LOADING TWEAKS...");
        clean_file("/var/tmp/.pspawn_disable_loader");
        chown("/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist", 0, 0);
        chmod("/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist", 0644);
        
        systemCmd("echo 'really jailbroken';"
                  "shopt -s nullglob;"
                  "for a in /Library/LaunchDaemons/*.plist;"
                  "do echo loading $a;"
                  "launchctl load \"$a\" ;"
                  "done; ");
        systemCmd("for file in /etc/rc.d/*; do "
                  "if [[ -x \"$file\" && \"$file\" != \"/etc/rc.d/substrate\" ]]; then "
                  "\"$file\";"
                  "fi;"
                  "done");
        systemCmd("nohup bash -c \""
                  "launchctl stop com.apple.mDNSResponder ;"
                  "launchctl stop com.apple.backboardd"
                  "\" >/dev/null 2>&1 &");
    } else {
        util_info("NOT LOADING TWEAKS...");
        ensure_file("/var/tmp/.pspawn_disable_loader", 0, 0644);
        systemCmd("nohup bash -c \""
                  "launchctl stop com.apple.mDNSResponder ;"
                  "launchctl stop com.apple.backboardd"
                  "\" >/dev/null 2>&1 &");
    }

    util_info("You're welcome.");
    
    reBack(); //Enable this to respring your device safely.
}

static void util_vprintf(const char *fmt, va_list ap);


void util_nanosleep(uint64_t nanosecs)
{
    int ret;
    struct timespec tp;
    tp.tv_sec = nanosecs / (1000 * 1000 * 1000);
    tp.tv_nsec = nanosecs % (1000 * 1000 * 1000);
    do {
        ret = nanosleep(&tp, &tp);
    } while (ret && errno == EINTR);
}

void util_msleep(unsigned int ms)
{
    uint64_t nanosecs = ms * 1000 * 1000;
    util_nanosleep(nanosecs);
}


void (*log_UI)(const char *text) = NULL;

static void log_vprintf(int type, const char *fmt, va_list ap)
{
    char message[256];

    vsnprintf(message, sizeof(message), fmt, ap);
    switch (type) {
        case 'D': type = 'D'; break;
        case 'I': type = '+'; break;
        case 'W': type = '!'; break;
        case 'E': type = '-'; break;
    }
    fprintf(stdout, "[%c] %s\n", type, message);
    if (0) {
        CF_EXPORT void CFLog(int32_t level, CFStringRef format, ...);
        CFLog(6, CFSTR("[%c] %s\n"), type, message);
    }
    if (log_UI) {
        char ui_text[512];
        snprintf(ui_text, sizeof(ui_text), "[%c] %s\n", type, message);
        log_UI(ui_text);
    }
}

void util_debug(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    log_vprintf('D', fmt, ap);
    va_end(ap);
}

void util_info(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    log_vprintf('I', fmt, ap);
    va_end(ap);
}

void util_warning(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    log_vprintf('W', fmt, ap);
    va_end(ap);
}

void util_error(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    log_vprintf('E', fmt, ap);
    va_end(ap);
}

static void util_vprintf(const char *fmt, va_list ap)
{
    vfprintf(stdout, fmt, ap);
    if (log_UI) {
        char ui_text[512];
        vsnprintf(ui_text, sizeof(ui_text), fmt, ap);
        log_UI(ui_text);
    }
}

void util_printf(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    util_vprintf(fmt, ap);
    va_end(ap);
}

#define PROC_PIDPATHINFO_MAXSIZE (4*MAXPATHLEN)

extern char **environ;


void util_hexprint(void *data, size_t len, const char *desc)
{
    uint8_t *ptr = (uint8_t *)data;
    size_t i;

    if (desc) {
        util_printf("%s\n", desc);
    }
    for (i = 0; i < len; i++) {
        if (i % 16 == 0) {
            util_printf("%04x: ", (uint16_t)i);
        }
        util_printf("%02x ", ptr[i]);
        if (i % 16 == 7) {
            util_printf(" ");
        }
        if (i % 16 == 15) {
            util_printf("\n");
        }
    }
    if (i % 16 != 0) {
        util_printf("\n");
    }
}

void util_hexprint_width(void *data, size_t len, int width, const char *desc)
{
    uint8_t *ptr = (uint8_t *)data;
    size_t i;

    if (desc) {
        util_printf("%s\n", desc);
    }
    for (i = 0; i < len; i += width) {
        if (i % 16 == 0) {
            util_printf("%04x: ", (uint16_t)i);
        }
        if (width == 8) {
            util_printf("%016llx ", *(uint64_t *)(ptr + i));
        }
        else if (width == 4) {
            util_printf("%08x ", *(uint32_t *)(ptr + i));
        }
        else if (width == 2) {
            util_printf("%04x ", *(uint16_t *)(ptr + i));
        }
        else {
            util_printf("%02x ", ptr[i]);
        }
        if ((i + width) % 16 == 8) {
            util_printf(" ");
        }
        if ((i + width) % 16 == 0) {
            util_printf("\n");
        }
    }
    if (i % 16 != 0) {
        util_printf("\n");
    }
}

_Noreturn static void vfail(const char *fmt, va_list ap)
{
    char text[512];
    vsnprintf(text, sizeof(text), fmt, ap);
    util_printf("[!] fail < %s >\n", text);
    util_printf("[*] endless loop\n");
    while (1) {
        util_msleep(1000);
    }
}

void fail_if(bool cond, const char *fmt, ...)
{
    if (cond) {
        va_list ap;
        va_start(ap, fmt);
        vfail(fmt, ap);
        va_end(ap);
    }
}

_Noreturn void fail_info(const char *info)
{
    util_printf("[!] fail < %s >\n", info ? info : "null");
    util_printf("[*] endless loop\n");
    exit(1);
    while (1) {
        util_msleep(1000);
    }
}
