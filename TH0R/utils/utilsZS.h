//
//  utils.h
//  electra
//
//  Created by Jamie on 27/01/2018.
//  Copyright © 2018 Electra Team. All rights reserved.
//

#ifndef utils_h
#define utils_h
#import <sys/types.h>
#import <sys/stat.h>
#include <stdio.h>
#include <stdbool.h>

#include <stddef.h>
#include <stdint.h>

#define showMSG(msg, wait, destructive) showAlert(@"freya", msg, wait, destructive)
#define showPopup(msg, wait, destructive) showThePopup(@"", msg, wait, destructive)
#define __FILENAME__ (__builtin_strrchr(__FILE__, '/') ? __builtin_strrchr(__FILE__, '/') + 1 : __FILE__)
#define _assert(test, message, fatal) do \
if (!(test)) { \
int saved_errno = errno; \
LOG("__assert(%d:%s)@%s:%u[%s]", saved_errno, #test, __FILENAME__, __LINE__, __FUNCTION__); \
} \
while (false)

const char *userGenerator(void);
const char *genToSet(void);
#define K_GENERATOR "generator"
#define K_freya_GENERATOR "0x1111111111111111"

void xFinishFailed(void);

void util_hexprint(void *data, size_t len, const char *desc);
void util_hexprint_width(void *data, size_t len, int width, const char *desc);
void util_nanosleep(uint64_t nanosecs);
void util_msleep(unsigned int ms);
_Noreturn void fail_info(const char *info);
void fail_if(bool cond, const char *fmt, ...)  __printflike(2, 3);
//void move_in_jbResources();
// don't like macro
void util_debug(const char *fmt, ...) __printflike(1, 2);
void util_info(const char *fmt, ...) __printflike(1, 2);
void util_warning(const char *fmt, ...) __printflike(1, 2);
void util_error(const char *fmt, ...) __printflike(1, 2);
void util_printf(const char *fmt, ...) __printflike(1, 2);

//int util_runCommand(const char *cmd, ...);




bool is_mountpoint(const char *filename);
int run(const char *cmd);
char* itoa(long n);
void do_restart(void);
void post_exploit(void);

void runMachswap(void);
void getOffsets(void);
void rootMe(uint64_t proc);
void unsandbox(uint64_t proc);
void remountFS(bool shouldRestore);
void restoreRootFS(void);
int trust_file(NSString *path);
void installSubstitute(void);
void saveOffs(void);
void createWorkingDir(void);
void installSSH(void);
void xpcFucker(void);
void finish(bool shouldLoadTweaks);
void runVoucherSwap(void);
void runExploit(int expType);
void initInstall(int packagerType);
bool canRead(const char *file);
struct tfp0;

//SETTINGS
BOOL shouldLoadTweaks(void);
int getExploitType(void);
int getPackagerType(void);
void initSettingsIfNotExist(void);
void saveCustomSetting(NSString *setting, int settingResult);
BOOL shouldRestoreFS(void);
BOOL isRootless(void);


//ROOTLESS JB
void createWorkingDir_rootless(void);
void saveOffs_rootless(void);
void uninstallRJB(void);
//EXPLOIT
int autoSelectExploit(void);

//Nonce
void setNonce(const char *nonce, bool shouldSet);
NSString* getBootNonce(void);
bool shouldSetNonce(void);
#endif /* utils_h */
