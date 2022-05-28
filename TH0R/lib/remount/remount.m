//
//  remount.c
//  LiRa-Rootfs
//
//  Created by hoahuynh on 2021/05/29.
//
#include <string.h>
#include <sys/attr.h>
#include <sys/snapshot.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <sys/fcntl.h>
#include <sys/unistd.h>
#include <malloc/_malloc.h>
#include <errno.h>

#include "remount.h"

//#include "../../utils/utilsZS.h"
//#include "../../exploits/offsets/ms_offs.h"
#include "../../exploits/wasteoftfime/offsets_TW.h"
#include "../amfi/amfi_utils.h"
#include "../kernel_call/OffsetHolder.h"
#include "../kernel_call/offsets.h"
#include "../amfi/amfi.h"
#include "../../utils/shenanigans.h"
#include "../../lib/remap_tfp_set_hsp/remap_tfp_set_hsp.h"
#include "../../utils/KernelUtils.h"

#include "../../exploits/wasteoftfime/IOKitLibTW.h"
//#import <Foundation/Foundation.h>

static char* mntpathSW;
static char* mntpath;

bool remount(uint64_t launchd_proc) {
    //let mntpathSW = "/var/rootfsmnt" ios 13 odyssey
   // let mntpath = strdup("/var/rootfsmnt")
    
    mntpathSW = "/private/var/mnt";
    mntpath = strdup("/private/var/mnt");
    uint64_t rootvnode = findRootVnode(launchd_proc);
    util_info("rootvnode: 0x%llx", rootvnode);
    
    if(isRenameRequired()) {
        if(access(mntpathSW, F_OK) == 0) {
            [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:mntpathSW] error:nil];
        }
        
        mkdir(mntpath, 0755);
        chown(mntpath, 0, 0);
        
        if(isOTAMounted()) {
            util_info("OTA update already mounted");
            need_initialSSRenamed = 0;//
            return false;
        }
        
        uint64_t kernCreds = ReadKernel64(get_proc_struct_for_pid(0) + koffset(KSTRUCT_OFFSET_PROC_UCRED));
        uint64_t selfCreds = ReadKernel64(get_proc_struct_for_pid(getpid()) + koffset(KSTRUCT_OFFSET_PROC_UCRED));
        WriteKernel64(get_proc_struct_for_pid(getpid()) + koffset(KSTRUCT_OFFSET_PROC_UCRED), kernCreds);
        grabEntitlementsForRootFS(get_proc_struct_for_pid(getpid()));
        
        char* bootSnapshot = find_boot_snapshot();
        
        if(!bootSnapshot
           || mountRealRootfs(rootvnode)) {
            resetEntitlementsForRootFS(get_proc_struct_for_pid(getpid()));
            WriteKernel64(get_proc_struct_for_pid(getpid()) + koffset(KSTRUCT_OFFSET_PROC_UCRED), selfCreds);
            
            return false;
        }
        
        int fd = open("/private/var/mnt", O_RDONLY, 0);
        if(fd <= 0
           || fs_snapshot_revert(fd, bootSnapshot, 0) != 0) {
            util_error("fs_snapshot_revert failed");
            resetEntitlementsForRootFS(get_proc_struct_for_pid(getpid()));
            WriteKernel64(get_proc_struct_for_pid(getpid()) + koffset(KSTRUCT_OFFSET_PROC_UCRED), selfCreds);
            return false;
        }
        close(fd);
        unmount(mntpath, MNT_FORCE);
        
        if(mountRealRootfs(rootvnode)) {
            resetEntitlementsForRootFS(get_proc_struct_for_pid(getpid()));
            WriteKernel64(get_proc_struct_for_pid(getpid()) + koffset(KSTRUCT_OFFSET_PROC_UCRED), selfCreds);
            return false;
        }
        
        uint64_t newmnt = findNewMount(rootvnode);
        if(!newmnt) {
            resetEntitlementsForRootFS(get_proc_struct_for_pid(getpid()));
            WriteKernel64(get_proc_struct_for_pid(getpid()) + koffset(KSTRUCT_OFFSET_PROC_UCRED), selfCreds);
            return false;
        }
        
        if(!unsetSnapshotFlag(newmnt)) {
            resetEntitlementsForRootFS(get_proc_struct_for_pid(getpid()));
            WriteKernel64(get_proc_struct_for_pid(getpid()) + koffset(KSTRUCT_OFFSET_PROC_UCRED), selfCreds);
            return false;
        }
        
        int fd2 = open("/private/var/mnt", O_RDONLY, 0);
        if(fd <= 0
           || fs_snapshot_rename(fd2, bootSnapshot, "orig-fs", 0) != 0) {
            util_error("fs_snapshot_rename failed");
            resetEntitlementsForRootFS(get_proc_struct_for_pid(getpid()));
            WriteKernel64(get_proc_struct_for_pid(getpid()) + koffset(KSTRUCT_OFFSET_PROC_UCRED), selfCreds);
            //need_initialSSRenamed = 3;
            return false;
        }
        close(fd2);
        
        unmount(mntpath, 0);
        
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:mntpath] error:nil];
        unlink(mntpath);
        rmdir(mntpath);
        resetEntitlementsForRootFS(get_proc_struct_for_pid(getpid()));
        WriteKernel64(get_proc_struct_for_pid(getpid()) + koffset(KSTRUCT_OFFSET_PROC_UCRED), selfCreds);
        
        
        
        util_info("Successfully remounted RootFS! Reboot.");
        need_initialSSRenamed = 3;
        return true;

        //reboot(0);
    } else {
        uint64_t vmount = ReadKernel64(rootvnode + koffset(KSTRUCT_OFFSET_VNODE_V_MOUNT));
        uint32_t vflag = ReadKernel32(vmount + koffset(KSTRUCT_OFFSET_MOUNT_MNT_FLAG)) & ~(MNT_RDONLY);
        WriteKernel32(vmount + koffset(KSTRUCT_OFFSET_MOUNT_MNT_FLAG), vflag & ~(MNT_ROOTFS));

        char* dev_path = strdup("/dev/disk0s1s1");
        int retval = mount("apfs", "/", MNT_UPDATE, &dev_path);
        free(dev_path);

        WriteKernel32(vmount + koffset(KSTRUCT_OFFSET_MOUNT_MNT_FLAG), vflag | (MNT_NOSUID));
        if(retval == 0) {
            util_info("Already remounted RootFS!");
            need_initialSSRenamed = 2;

            return true;
        }
        need_initialSSRenamed = 0;//
        return false;
        
    }
    return true;
    
}

uint64_t findRootVnode(uint64_t launchd_proc) {
    //  https://github.com/apple/darwin-xnu/blob/xnu-7195.60.75/bsd/sys/proc_internal.h#L193
    //  https://github.com/apple/darwin-xnu/blob/xnu-7195.60.75/bsd/sys/vnode_internal.h#L127
    
    uint64_t textvp = ReadKernel64(launchd_proc + off_p_textvp);
    uint64_t nameptr = ReadKernel64(textvp + off_v_name);
    char name[20];
    kreadOwO(nameptr, &name, 20);  //  <- launchd;
    
    uint64_t sbin = ReadKernel64(textvp + off_v_parent);
    nameptr = ReadKernel64(sbin + off_v_name);
    kreadOwO(nameptr, &name, 20);  //  <- sbin
    
    uint64_t rootvnode = ReadKernel64(sbin + off_v_parent);
    nameptr = ReadKernel64(sbin + off_v_name);
    kreadOwO(nameptr, &name, 20);  //  <- / (ROOT)
    
    uint32_t flags = ReadKernel32(rootvnode + off_v_flags);
    util_info("rootvnode flags: 0x%x", flags);
    
    return rootvnode;
}

bool isRenameRequired() {
    struct statfs *st;
    
    int ret = getmntinfo(&st, MNT_NOWAIT);
    if(ret <= 0) {
        util_error("getmntinfo error");
    }
    
    for (int i = 0; i < ret; i++) {
        if(strstr(st[i].f_mntfromname, "com.apple.os.update-") != NULL) {
            return true;
        }
        if(strcmp(st[i].f_mntfromname, "/dev/disk0s1s1") == 0) {
            return false;
        }
    }
    return false;
}

bool isOTAMounted() {
    const char* path = strdup("/var/MobileSoftwareUpdate/mnt1");
    
    struct stat buffer;
    if (lstat(path, &buffer) != 0) {
        return false;
    }
    
    if((buffer.st_mode & S_IFMT) != S_IFDIR) {
        return false;
    }
    
    char* cwd = getcwd(nil, 0);
    chdir(path);
    
    struct stat p_buf;
    lstat("..", &p_buf);
    
    if(cwd) {
        chdir(cwd);
        free(cwd);
    }
    
    return buffer.st_dev != p_buf.st_dev || buffer.st_ino == p_buf.st_ino;
}

char* find_boot_snapshot() {
    io_registry_entry_t chosen = IORegistryEntryFromPath(0, "IODeviceTree:/chosen");
    CFDataRef data = IORegistryEntryCreateCFProperty(chosen, CFSTR("boot-manifest-hash"), kCFAllocatorDefault, 0);
    if(!data)
        return nil;
    IOObjectRelease(chosen);
    
    CFIndex length = CFDataGetLength(data) * 2 + 1;
    char *manifestHash = (char*)calloc(length, sizeof(char));
    
    int i = 0;
    for (i = 0; i<(int)CFDataGetLength(data); i++) {
        sprintf(manifestHash+i*2, "%02X", CFDataGetBytePtr(data)[i]);
    }
    manifestHash[i*2] = 0;
    
    CFRelease(data);

    char* systemSnapshot = malloc(sizeof(char) * 64);
    strcpy(systemSnapshot, "com.apple.os.update-");
    strcat(systemSnapshot, manifestHash);
    
    return systemSnapshot;
}

int mountRealRootfs(uint64_t rootvnode) {
    //  https://github.com/apple/darwin-xnu/blob/main/bsd/sys/vnode_internal.h#L127
    //  https://github.com/apple/darwin-xnu/blob/main/bsd/sys/mount_internal.h#L107
    //  https://github.com/apple/darwin-xnu/blob/main/bsd/miscfs/specfs/specdev.h#L77
    uint64_t vmount = ReadKernel64(rootvnode + koffset(KSTRUCT_OFFSET_VNODE_V_MOUNT));
    uint64_t dev = ReadKernel64(vmount + off_mnt_devvp);
    
    uint64_t nameptr = ReadKernel64(dev + off_v_name);
    char name[20];
    kreadOwO(nameptr, &name, 20);   //  <- disk0s1s1
    util_info("Found dev vnode name: %s", name);
    
    uint64_t specinfo = ReadKernel64(dev + koffset(KSTRUCT_OFFSET_VNODE_VU_SPECINFO));
    uint32_t flags = ReadKernel32(specinfo + off_specflags);
    util_info("Found dev flags: 0x%x", flags);
    
    WriteKernel32(specinfo + off_specflags, 0);
    char* fspec = strdup("/dev/disk0s1s1");
    
    struct hfs_mount_args mntargs;
    mntargs.fspec = fspec;
    mntargs.hfs_mask = 1;
    gettimeofday(nil, &mntargs.hfs_timezone);
    
    int retval = mount("apfs", mntpath, 0, &mntargs);
    free(fspec);
    
    util_info("Mount completed with status: %d", retval);
    if(retval == -1) {
        util_error("Mount failed with errno: %d", errno);
        //need_initialSSRenamed = 3;
    }
    
    return retval;
}

uint64_t findNewMount(uint64_t rootvnode) {
    uint64_t vmount = ReadKernel64(rootvnode + koffset(KSTRUCT_OFFSET_VNODE_V_MOUNT));
    
    vmount = ReadKernel64(vmount + off_mnt_next);
    while (vmount != 0) {
        uint64_t dev = ReadKernel64(vmount + off_mnt_devvp);
        if(dev != 0) {
            uint64_t nameptr = ReadKernel64(dev + off_v_name);
            char name[20];
            kreadOwO(nameptr, &name, 20);
            char* devName = name;
            util_info("Found dev vnode name: %s", devName);
            
            if(strcmp(devName, "disk0s1s1") == 0) {
                return vmount;
            }
        }
        vmount = ReadKernel64(vmount + off_mnt_next);
    }
    return 0;
}

bool unsetSnapshotFlag(uint64_t newmnt) {
    //  https://github.com/apple/darwin-xnu/blob/main/bsd/sys/mount_internal.h#L107
    uint64_t dev = ReadKernel64(newmnt + off_mnt_devvp);
    uint64_t nameptr = ReadKernel64(dev + off_v_name);
    char name[20];
    kreadOwO(nameptr, &name, 20);
    util_info("Found dev vnode name: %s", name);
    
    uint64_t specinfo = ReadKernel64(dev + off_v_specinfo);
    uint64_t flags = ReadKernel32(specinfo + off_specflags);
    util_info("Found dev flags: 0x%llx", flags);
    
    uint64_t vnodelist = ReadKernel64(newmnt + off_mnt_vnodelist);
    while (vnodelist != 0) {
        util_info("vnodelist: 0x%llx", vnodelist);
        uint64_t nameptr = ReadKernel64(vnodelist + off_v_name);
        unsigned long len = kstrlen(nameptr);
        char name[len];
        kreadOwO(nameptr, &name, len);
        
        char* vnodeName = name;
        util_info("Found vnode name: %s", vnodeName);
        
        if(strstr(vnodeName, "com.apple.os.update-") != NULL) {
            uint64_t vdata = ReadKernel64(vnodelist + koffset(KSTRUCT_OFFSET_VNODE_V_DATA));
            uint32_t flag = ReadKernel32(vdata + off_apfs_data_flag);
            util_info("Found APFS flag: 0x%x", flag);
            
            if ((flag & 0x40) != 0) {
                util_info("would unset the flag here to: 0x%x", flag & ~0x40);
                WriteKernel32(vdata + off_apfs_data_flag, flag & ~0x40);
                return true;
            }
        }
        vnodelist = ReadKernel64(vnodelist + 0x20);
    }
    return false;
}

unsigned long kstrlen(uint64_t string) {
    if (!string) return 0;
    
    unsigned long len = 0;
    char ch = 0;
    int i = 0;
    while (true) {
        kreadOwO(string + i, &ch, 1);
        if (!ch) break;
        len++;
        i++;
    }
    return len;
}
