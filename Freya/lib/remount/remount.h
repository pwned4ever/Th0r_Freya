//
//  remount.h
//  LiRa-Rootfs
//
//  Created by hoahuynh on 2021/05/29.
//

#ifndef remount_h
#define remount_h

#include <stdio.h>
#include <stdbool.h>
#include <sys/time.h>

struct hfs_mount_args {
    char    *fspec;            /* block special device to mount */
    uid_t    hfs_uid;        /* uid that owns hfs files (standard HFS only) */
    gid_t    hfs_gid;        /* gid that owns hfs files (standard HFS only) */
    mode_t    hfs_mask;        /* mask to be applied for hfs perms  (standard HFS only) */
    u_int32_t hfs_encoding;    /* encoding for this volume (standard HFS only) */
    struct    timezone hfs_timezone;    /* user time zone info (standard HFS only) */
    int        flags;            /* mounting flags, see below */
    int     journal_tbuffer_size;   /* size in bytes of the journal transaction buffer */
    int        journal_flags;          /* flags to pass to journal_open/create */
    int        journal_disable;        /* don't use journaling (potentially dangerous) */
};

bool remount(uint64_t launchd_proc);
uint64_t findRootVnode(uint64_t launchd_proc);
bool isRenameRequired(void);
bool isOTAMounted(void);
char* find_boot_snapshot(void);
int mountRealRootfs(uint64_t rootvnode);
uint64_t findNewMount(uint64_t rootvnode);
bool unsetSnapshotFlag(uint64_t newmnt);
unsigned long kstrlen(uint64_t string);
void util_debug(const char * _Nullable fmt, ...) __printflike(1, 2);
void util_info(const char * _Nullable fmt, ...) __printflike(1, 2);
void util_warning(const char * _Nullable fmt, ...) __printflike(1, 2);
void util_error(const char * _Nullable fmt, ...) __printflike(1, 2);
void util_printf(const char * _Nullable fmt, ...) __printflike(1, 2);


#endif /* remount_h */

