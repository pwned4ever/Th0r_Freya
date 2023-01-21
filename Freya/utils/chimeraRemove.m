//
//  chimeraRemove.m
//  Freya
//
//  Created by Marcel Cianchino on 2023-01-20.
//  Copyright © 2023 Th0r Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <string.h>
#include <sys/attr.h>
#include <sys/snapshot.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <sys/fcntl.h>
#include <sys/unistd.h>
#include <malloc/_malloc.h>
#include <errno.h>
#include <spawn.h>
#include <sys/mount.h>
#include <spawn.h>
#include <pwd.h>
#include <mach/error.h>
#include <mach-o/getsect.h>
#include "chimeraRemove.h"


char *myenvironCh[] = {
    "PATH=/freya/usr/local/sbin:/freya/usr/local/bin:/freya/usr/sbin:/freya/usr/bin:/freya/sbin:/freya/bin:/freya/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games",
    "PS1=\\h:\\w \\u\\$ ",
    NULL
};
NSData *lastSystemOutputCh=nil;
int execCmdVCh(const char *cmd, int argc, const char * const* argv, void (^unrestrict)(pid_t)) {
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
    
    int rv = posix_spawn(&pid, cmd, actions, attr, (char *const *)argv, myenvironCh);
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
            lastSystemOutputCh = [outData copy];
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

int execCmdCh(const char *cmd, ...) {
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
    
    int rv = execCmdVCh(cmd, argc, argv, NULL);
    return WEXITSTATUS(rv);
}

int systemCmdCh(const char *cmd) {
    const char *argv[] = {"sh", "-c", (char *)cmd, NULL};
    return execCmdVCh("/bin/sh", 3, argv, NULL);
}

void removingChimeraiOS() {
    
    execCmdCh("/freya/rm", "-rdvf", "/electra/launchctl", NULL);
    execCmdCh("/freya/rm", "-rdvf", "/var/mobile/Media/.bootstrapped_electraremover", NULL);
    execCmdCh("/freya/rm", "-rdvf", "/var/mobile/testremover.txt", NULL);
    unlink("/var/mobile/testremover.txt");
    execCmdCh("/freya/rm", "-rdvf", "/.bootstrapped_Th0r", NULL);
    execCmdCh("/freya/rm", "-rdvf", "/.freya_installed", NULL);
    execCmdCh("/freya/rm", "-rdvf", "/.bootstrapped_electra", NULL);
    execCmdCh("/freya/rm", "-rdvf", "/.installed_unc0ver", NULL);
    execCmdCh("/freya/rm", "-rdvf", "/.install_unc0ver", NULL);
    execCmdCh("/freya/rm", "-rdvf", "/.electra_no_snapshot", NULL);
    execCmdCh("/freya/rm", "-rdvf", "/.installed_unc0vered", NULL);
    util_info("Removing Files...");
    //removingJailbreaknotice();
    /////////START REMOVING FILES
    if (/* iOS 11.2.6 or lower don't use snapshot */ kCFCoreFoundationVersionNumber <= 1451.51){
        
        printf("Removing Jailbreak with Eremover.for ios 11.2.x devices..\n");
        
        int rvchec1 = execCmdCh("/usr/bin/find", ".", "-name", "*.deb", "-type", "f", "-delete", NULL);
        printf("[*] Trying find . with *.deb delete result = %d \n" , rvchec1);
        ///////delete the Malware from Satan////
        
        int rvchecdothidden1 = execCmdCh("/usr/bin/find", ".", "-name", "._*", "-type", "f", "-delete", NULL);
        printf("[*] Trying find . with ._* delete result = %d \n" , rvchecdothidden1);
        
        printf("[*] Removing Jailbreak with custom remover...\n");
        
        
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/motd", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/.cydia_no_stash", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/Applications/Cydia.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Network", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/aclocal", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/bigboss", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/common-lisp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/dict", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/dpkg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/gnupg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/libgpg-error", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/p11-kit", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/tabset", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/terminfo", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/local/bin", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/local/lib", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/authorize.sh", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/.cydia_no_stash", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/zsh", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/profile", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/rc.d", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/rc.d/substrate", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/etc/zshrc", NULL);
        ////usr/etc//
        execCmdCh("/freya/rm", "-rdvf", "/usr/etc", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/scp", NULL);
        ////usr/lib////
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/_ncurses", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/apt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/bash", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/gettext", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.1.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-private.0.0.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-private.0.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libasprintf.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libasprintf.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libassuan.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libassuan.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libassuan.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libdpkg.a", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libform.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libform.6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libform5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libformw.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libformw.6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libformw.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libformw5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgcrypt.20.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgcrypt.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgcrypt.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgettextlib-0.19.8.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgettextlib.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgettextpo.1.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgettextpo.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgettextsrc-0.19.8.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgettextsrc.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgmp.10.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgmp.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgmp.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgnutls.30.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgnutls.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgnutlsxx.28.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgnutlsxx.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.2.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhistory.6.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhistory.7.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhistory.7.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhistory.dylib ", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhogweed.4.4.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhogweed.4.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhogweed.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libidn2.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libidn2.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libidn2.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libintl.9.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libintl.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libksba.8.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libksba.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libksba.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/liblz4.1.7.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/liblz4.1.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/liblz4.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libmenu.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libmenu.6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libmenu.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libmenu5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libmenuw.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libmenuw.6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libmenuw.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libmenuw5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncurses.6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncurses5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncurses6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncursesw.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncursesw.6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncursesw.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncursesw5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncursesw6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libnettle.6.4.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libnettle.6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libnettle.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libnpth.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libnpth.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libnpth.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libp11-kit.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libp11-kit.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libp11-kit.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpanel.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpanel.6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpanel.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpanel5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpanelw.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpanelw.6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpanelw.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpanelw5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.2.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libreadline.6.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libreadline.7.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libreadline.7.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libreadline.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libresolv.9.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libresolv.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libtasn1.6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libtasn1.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libtasn1.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libunistring.2.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libunistring.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libunistring.la", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libsubstitute.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libsubstitute.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libsubstrate.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libjailbreak.dylib", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/recode-sr-latin", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/recache", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/rollectra", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/Rollectra", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/killall", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/sftp-server", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/SBInject.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/zsh", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/electra-prejailbreak", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/electra/createSnapshot", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/jb", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/jb", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/backups", NULL);
        ////////////Applications cleanup and root
        execCmdCh("/freya/rm", "-rdvf", "/RWTEST", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/pwnedWritefileatrootTEST", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/Cydia\ Update\ Helper.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/NETWORK", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/AppCake.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/Activator.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/Anemone.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/BestCallerId.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/CrackTool3.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/Cydia.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/Sileo.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/Rollectra.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/cydown.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/Cylinder.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/iCleaner.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/icleaner.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/BarrelSettings.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/Ext3nder.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/Filza.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/Flex.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/GBA4iOS.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/jjjj.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/ReProvision.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/SafeMode.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/NewTerm.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/MobileTerminal.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/MTerminal.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/MovieBox3.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/BobbyMovie.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/PopcornTime.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/RST.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/TSSSaver.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/CertRemainTime.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/CrashReporter.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/AudioRecorder.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/ADManager.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/CocoaTop.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/calleridfaker.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/CallLogPro.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/WiFiPasswords.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/WifiPasswordList.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/calleridfaker.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/ClassDumpGUI.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/idevicewallsapp.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/UDIDFaker.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/UDIDCalculator.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/CallRecorder.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/Rehosts.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/NGXCarPlay.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/Audicy.app", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Applications/NGXCarplay.app", NULL);
        ///////////USR/LIBEXEC
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/as", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/frcode", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/bigram", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/code", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/reload", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/rmt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/MSUnrestrictProcess", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/perl5", NULL);
        //////////USR/SHARE
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/git-core", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/git-gui", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/gitk", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/gitweb", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/man", NULL);
        ////////USR/LOCAL
        execCmdCh("/freya/rm", "-rdvf", "/usr/local/bin", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/local/lib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/local/lib/libluajit.a", NULL);
        
        ////var
        execCmdCh("/freya/rm", "-rdvf", "/var/containers/Bundle/iosbinpack64", NULL);
        ////etc folder cleanup
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/pam.d", NULL);
        
        //private/etc
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/apt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/dropbear", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/alternatives", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/default", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/dpkg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/ssh", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/ssl", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/profile.d", NULL);
        
        ////private/var
        
        execCmdCh("/freya/rm", "-rdvf", "/private/var/cache", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/lib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/local", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/lock", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/spool", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/lib/apt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/lib/cydia", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/cache/apt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/db/stash", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/stash", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/tweak", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
        //var/mobile/Library
        
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia/", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
        
        //var/mobile/Library/Caches
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
        
        //snapshot.library
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
        unlink("/private/etc/apt/sources.list.d/cydia.list");
        unlink("/private/etc/apt");
        
        ////usr/include files
        execCmdCh("/freya/rm", "-rdvf", "/usr/include", NULL);
        ////usr/local files
        execCmdCh("/freya/rm", "-rdvf", "/usr/local/bin", NULL);
        ////usr/libexec files
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/apt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/ssh-pkcs11-helper", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/ssh-keysign", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/cydia", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/dpkg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/gnupg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/gpg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/gpg-check-pattern", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/gpg-preset-passphrase", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/gpg-protect-tool", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/gpg-wks-client", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/git-core", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/p11-kit", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/scdaemon", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/vndevice", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/frcode", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/bigram", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/code", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/coreutils", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/reload", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/rmt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/filza", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/sudo", NULL);
        ////usr/lib files
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/TweakInject", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/tweakloader.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/pspawn_hook.dylib", NULL);
        unlink("/usr/lib/pspawn_hook.dylib");
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/tweaks", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/Activator", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/apt", NULL);
        
        unlink("/usr/lib/apt");
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/dpkg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/pam", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/p11-kit.0.dylib", NULL);
        unlink("/usr/lib/p11-kit-proxy.dylib");
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/p11-kit-proxy.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/pkcs11", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/pam", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/pkgconfig", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/ssl", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/bash", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/gettext", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/coreutils", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/engines", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/p7zip", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/Cephei.framework", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/CepheiPrefs.framework", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/SBInject", NULL);
        //usr/local
        execCmdCh("/freya/rm", "-rdvf", "/usr/local/bin", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/local/lib", NULL);
        ////library folder files and subfolders
        execCmdCh("/freya/rm", "-rdvf", "/Library/Alkaline", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Activator", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Barrel", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/BarrelSettings", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Cylinder", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/dpkg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Frameworks", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/LaunchDaemons", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/.DS_Store", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/MobileSubstrate", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/PreferenceBundles", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/Library/PreferenceLoader", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/SBInject", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/Snoverlay", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/Flame", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/CallBlocker", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/CCSupport", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/Compatimark", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/Dynastic", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/Malipo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/SafariPlus.bundle", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/Activator", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/Cylinder", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/Barrel", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/BarrelSettings", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/libGitHubIssues/", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Themes", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/TweakInject", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Zeppelin", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Flipswitch", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Switches", NULL);
        
        //////system/library
        execCmdCh("/freya/rm", "-rdvf", "/System/Library/PreferenceBundles/AppList.bundle", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/System/Library/Themes", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/System/Library/Internet\ Plug-Ins", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/System/Library/KeyboardDictionaries", NULL);
        
        /////root
        
        execCmdCh("/freya/rm", "-rdvf", "/FELICITYICON.png", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bootstrap", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/mnt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/lib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/boot", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/libexec", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/include", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/mnt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/jb", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/games", NULL);
        //////////////USR/LIBRARY
        execCmdCh("/freya/rm", "-rdvf", "/usr/Library", NULL);
        
        ///////////PRIVATE
        execCmdCh("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
        ///
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/killall", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/reboot", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/.bootstrapped_Th0r", NULL);
        
        
        execCmdCh("/freya/rm", "-rf", "/Library/test_inject_springboard.cy", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/SBInject.dylib", NULL);
        ////usr/local files and folders cleanup
        execCmdCh("/freya/rm", "-rdvf", "/usr/local/lib", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libsparkapplist.dylib", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcrashreport.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libsymbolicate.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/TweakInject.dylib", NULL);
        //////ROOT FILES :(
        execCmdCh("/freya/rm", "-rdvf", "/.bootstrapped_electra", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/.cydia_no_stash", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/.bit_of_fun", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/RWTEST", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/pwnedWritefileatrootTEST", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
        
        
        ////////// BIN/
        execCmdCh("/freya/rm", "-rdvf", "/bin/bashbug", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/bunzip2", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/bzcat", NULL);
        unlink("usr/bin/bzcat");
        execCmdCh("/freya/rm", "-rdvf", "/bin/bzip2", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/bzip2recover", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/bzip2_64", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/cat", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/chgrp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/chmod", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/chown", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/cp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/date", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/dd", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/dir", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/echo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/egrep", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/false", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/fgrep", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/grep", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/gzip", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/gtar", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/gunzip", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/gzexe", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/hostname", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/launchctl", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/ln", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/ls", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/jtoold", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/kill", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/mkdir", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/mknod", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/mv", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/mktemp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/pwd", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/bin/rmdir", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/readlink", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/unlink", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/run-parts", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/su", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/sync", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/stty", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/sh", NULL);
        unlink("/bin/sh");
        
        execCmdCh("/freya/rm", "-rdvf", "/bin/sleep", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/sed", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/su", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/tar", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/touch", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/true", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/uname", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/vdr", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/vdir", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/uncompress", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/znew", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/zegrep", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/zmore", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/zdiff", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/zcat", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/zcmp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/zfgrep", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/zforce", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/zless", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/zgrep", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/zegrep", NULL);
        
        //////////SBIN
        execCmdCh("/freya/rm", "-rdvf", "/sbin/reboot", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/halt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/ifconfig", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/kextunload", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/ping", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/update_dyld_shared_cache", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/dmesg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/dynamic_pager", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/nologin", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/fstyp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/fstyp_msdos", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/fstyp_ntfs", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/fstyp_udf", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/mount_devfs", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/mount_fdesc", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/quotacheck", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/umount", NULL);
        
        
        /////usr/bin files folders cleanup
        //symbols
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/[", NULL);
        //a
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ADMHelper", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/arch", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/apt", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ar", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/apt-key", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/apt-cache", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/apt-cdrom", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/apt-config", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/apt-extracttemplates", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/apt-ftparchive", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/apt-sortpkgs", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/apt-mark", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/apt-get", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/arch", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/asu_inject", NULL);
        
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/asn1Coding", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/asn1Decoding", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/asn1Parser", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/autopoint", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/as", NULL);
        //b
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/bashbug", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/b2sum", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/base32", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/base64", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/basename", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/bitcode_strip", NULL);
        //c
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/CallLogPro", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/com.julioverne.ext3nder-installer", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/chown", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/chmod", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/chroot", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/chcon", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/chpass", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/check_dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/checksyms", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/chfn", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/chsh", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/cksum", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/comm", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/cmpdylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/codesign_allocate", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/csplit", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ctf_insert", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/cut", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/curl", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/curl-config", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/c_rehash", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/captoinfo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/certtool", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/cfversion", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/clear", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/cmp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/cydown", NULL);//cydown
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/cydown.arch_arm64", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/cydown.arch_armv7", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/cycript", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/cycc", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/cynject", NULL);
        //d
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dbclient", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/db_archive", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/db_checkpoint", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/db_deadlock", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/db_dump", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/db_hotbackup", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/db_load", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/db_log_verify", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/db_printlog", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/db_recover", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/db_replicate", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/db_sql_codegen", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/db_stat", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/db_tuner", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/db_upgrade", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/db_verify", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dbsql", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/debugserver", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/defaults", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/df", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/diff", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/diff3", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dirname", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dircolors", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dirmngr", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dirmngr-client", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-architecture", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-buildflags", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-buildpackage", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-checkbuilddeps", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-deb", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-distaddfile", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-divert", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-genbuildinfo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-genchanges", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-gencontrol", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-gensymbols", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-maintscript-helper", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-mergechangelogs", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-name", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-parsechangelog", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-query", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-scanpackages", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-scansources", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-shlibdeps", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-source", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-split", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-statoverride", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-trigger", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dpkg-vendor", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/du", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dumpsexp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dselect", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dsymutil", NULL);
        ////e
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/expand", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/expr", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/env", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/envsubst", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ecidecid", NULL);
        //f
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/factor", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/filemon", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/Filza", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/fmt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/fold", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/funzip", NULL);
        //g
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/games", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/getconf", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/getty", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gettext", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gettext.sh", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gettextize", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/git", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/git-cvsserver", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/git-recieve-pack", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/git-shell", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/git-upload-pack", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gitk", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gnutar", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gnutls-cli", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gnutls-cli-debug", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gnutls-serv", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gpg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gpgrt-config", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gpg-zip", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gpgsplit", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gpgv", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gssc", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/groups", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gpg-agent", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gpg-connect-agent ", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gpg-error", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gpg-error-config", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gpg2", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gpgconf", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gpgparsemail", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gpgscm", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gpgsm", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gpgtar", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gpgv2", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/groups", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/gtar", NULL);
        //h
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/head", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/hmac256", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/hostid", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/hostinfo", NULL);
        //i
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/install", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/id", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/idn2", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/indr", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/inout", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/infocmp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/infotocap", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/iomfsetgamma", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/install_name_tool", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/libtool", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/lipo", NULL);
        //j
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/join", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/jtool", NULL);
        //k
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/killall", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/kbxutil", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ksba-config", NULL);
        //l
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/less", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/libassuan-config", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/libgcrypt-config", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/link", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ldid", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ldid2", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ldrestart", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/locate", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/login", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/logname", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/lzcat", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/lz4", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/lz4c", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/lz4cat", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/lzcmp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/lzdiff", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/lzegrep", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/lzfgrep", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/lzgrep", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/lzless", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/lzma", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/lzmadec", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/lzmainfo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/lzmore", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin.lipo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/lipo", NULL);
        
        //m
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/md5sum", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/mkfifo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/mktemp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/more", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/msgattrib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/msgcat", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/msgcmp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/msgcomm", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/msgconv", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/msgen", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/msgexec", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/msgfilter", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/msgfmt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/msggrep", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/msginit", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/msgmerge", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/msgunfmt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/msguniq", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/mpicalc", NULL);
        //n
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/nano", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/nettle-hash", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/nettle-lfib-stream", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/nettle-pbkdf2", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ngettext", NULL);
        
        
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/nm", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/nmedit", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/nice", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/nl", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/nohup", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/nproc", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/npth-config", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/numfmt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ncurses6-config", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ncursesw6-config", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ncursesw5-config", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ncurses5-config", NULL);
        //o
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/od", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ocsptool", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ObjectDump", NULL);//ld64
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/dyldinfo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ld", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/machocheck", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/unwinddump", NULL);//ld64 done
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/otool", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/openssl", NULL);
        //p
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/pincrush", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/pagestuff", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/pagesize", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/passwd", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/paste", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/pathchk", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/pinky", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/plconvert", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/pr", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/printenv", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/printf", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/procexp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ptx", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/p11-kit", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/p11tool", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/pkcs1-conv", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/psktool", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/quota", NULL);
        
        
        //r
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/renice", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ranlib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/redo_prebinding", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/reprovisiond", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/reset", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/realpath", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/rnano", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/runcon", NULL);
        //s
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/snapUtil", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/sbdidlaunch", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/sbreload", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/script", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/sdiff", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/seq", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/sexp-conv", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/seg_addr_table", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/seg_hack", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/segedit", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/sftp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/shred", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/shuf", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/sort", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ssh", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ssh-add", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ssh-agent", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ssh-keygen", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/ssh-keyscan", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/sw_vers", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/seq", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/SemiRestore11-Lite", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/sha1sum", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/sha224sum", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/sha256sum", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/sha384sum", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/sha512sum", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/shred", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/shuf", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/size", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/split", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/srptool", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/stat", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/stdbuf", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/strings", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/strip", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/sum", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/sync", NULL);
        //t
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/tabs", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/tac", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/tar", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/tail", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/tee", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/test", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/tic", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/time", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/timeout", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/toe", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/tput", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/tr", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/tset", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/truncate", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/trust", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/tsort", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/tty", NULL);
        //u
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/uiduid", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/uuid", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/uuid-config", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/uiopen", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/unlz4", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/unlzma", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/unxz", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/update-alternatives", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/updatedb", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/unexpand", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/uniq", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/unzip", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/unzipsfx", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/unrar", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/uptime", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/users", NULL);
        //w
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/watchgnupg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/wc", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/wget", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/which", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/who", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/whoami", NULL);
        //x
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/xargs", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/xz", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/xgettext", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/xzcat", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/xzcmp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/xzdec", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/xzdiff", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/xzegrep", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/xzfgrep", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/xzgrep", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/xzless", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/xzmore", NULL);
        //y
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/yat2m", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/yes", NULL);
        //z
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/zip", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/zipcloak", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/zipnote", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/zipsplit", NULL);
        //numbers
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/7z", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/7za", NULL);
        //////////////
        ////
        //////////USR/SBIN
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/chown", NULL);
        
        unlink("/usr/sbin/chown");
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/chmod", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/chroot", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/dev_mkdb", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/edquota", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/applygnupgdefaults", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/fdisk", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/halt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/sshd", NULL);
        
        //////////////USR/LIB
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/xxxMobileGestalt.dylib", NULL);//for cydown
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/xxxSystem.dylib", NULL);//for cydown
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcolorpicker.dylib", NULL);//
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcrypto.dylib", NULL);//
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcrypto.a", NULL);//
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libdb_sql-6.2.dylib", NULL);//
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libdb_sql-6.dylib", NULL);//
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libdb_sql.dylib", NULL);//
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libdb-6.2.dylib", NULL);//
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libdb-6.dylib", NULL);//
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libdb.dylib", NULL);//
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/liblzma.a", NULL);//
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/liblzma.la", NULL);//
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libprefs.dylib", NULL);//
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libssl.a", NULL);//
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libssl.dylib", NULL);//
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libST.dylib", NULL);//
        //////////////////
        //////////////8
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpam.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpamc.1.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6.0", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpanelw.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.2.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libreadline.6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpanel.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcurses.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhistory.6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libformw.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncursesw.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhistory.6.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libform.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpanelw.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libmenuw.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/terminfo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpam.1.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libmenu.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpatcyh.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libreadline.6.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncurses.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhistory.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpamc.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libformw.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1.0", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpanel.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.0.0.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/_ncurses", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpam_misc.1.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.2.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpam_misc.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libreadline.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libmenuw.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpam.1.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libmenu.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncursesw.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcycript.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcycript.jar", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libdpkg.a", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcrypto.1.0.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libssl.1.0.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcycript.db", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcurl.4.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcycript.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcycript.cy", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libdpkg.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libswift", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libsubstrate.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libuuid.16.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libuuid.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libtapi.dylib", NULL);//ld64
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libnghttp2.14.dylib", NULL);//ld64
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libnghttp2.dylib", NULL);//ld64
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libnghttp2.la", NULL);//ld64
        ///sauirks new substrate
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/substrate", NULL);//ld64
        
        //////////USR/SBIN
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/accton", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/vifs", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/ac", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/update", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/pwd_mkdb", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/sysctl", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/zdump", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/startupfiletool", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/iostat", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/nologin", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/mkfile", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/quotaon", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/repquota", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/zic", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/vipw", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/vsdbutil", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/start-stop-daemon", NULL);
        ////////USR/LOCAL
        execCmdCh("/freya/rm", "-rdvf", "/usr/local/lib/libluajit.a", NULL);
        //////LIBRARY
        execCmdCh("/freya/rm", "-rdvf", "/Library/test_inject_springboard.cy", NULL);
        //////sbin folder files cleanup
        execCmdCh("/freya/rm", "-rdvf", "/sbin/dmesg", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/sbin/cat", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/sbin/zshrc", NULL);
        ////usr/sbin files
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/start-start-daemon", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/accton", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/addgnupghome", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/vifs", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/ac", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/update", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/sysctl", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/zdump", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/startupfiletool", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/iostat", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/mkfile", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/zic", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/sbin/vipw", NULL);
        ////usr/libexec files
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/_rocketd_reenable", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/rocketd", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/MSUnrestrictProcess", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/substrate", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/libexec/substrated", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/applist.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapplist.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhAcxTools.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhAcxTools2.dylib", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libflipswitch.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.1.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-private.0.0.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-private.0.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libassuan.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libassuan.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libassuan.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libnpth.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libnpth.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libnpth.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libksba.8.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libksba.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libksba.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/cycript0.9", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpam.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpamc.1.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpackageinfo.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/librocketbootstrap.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6.0", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpanelw.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.2.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libreadline.6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpanel.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcurses.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhistory.6.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libformw.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncursesw.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhistory.6.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libform.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpanelw.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libmenuw.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/terminfo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/terminfo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpam.1.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libmenu.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpatcyh.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libreadline.6.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncurses.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhistory.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpamc.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libformw.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1.0", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpanel.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.0.0.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/_ncurses", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpam_misc.1.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.2.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpam_misc.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libreadline.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libmenuw.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libpam.1.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libmenu.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncursesw.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcycript.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcycript.jar", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcycript.db", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcurl.4.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcurl.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcurl.la", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcycript.0.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcycript.cy", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcephei.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libcepheiprefs.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhbangcommon.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libhbangprefs.dylib", NULL);
        /////end it
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libjailbreak.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/profile", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/motd", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/log/testbin.log", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/log/apt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/log/jailbreakd-stderr.log", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/log/jailbreakd-stdout.log", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/test_inject_springboard.cy", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/local/lib/libluajit.a", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/bin/zsh", NULL);
        //missing from removeMe.sh oddly
        //////mine above lol
        //////////////////Jakes below
        
        execCmdCh("/freya/rm", "-rdvf", "/var/LIB", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/bin", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/sbin", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/profile", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/motd", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/dropbear", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/containers/Bundle/tweaksupport", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/containers/Bundle/iosbinpack64", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/containers/Bundle/dylibs", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/LIB", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/motd", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/log/testbin.log", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/log/jailbreakd-stdout.log", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/log/jailbreakd-stderr.log", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/bin/find", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/var/cache", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/freya", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/lib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/stash", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/db/stash", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/mobile/Library/Cydia", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/etc/apt/sources.list.d", NULL);
                     
        execCmdCh("/freya/rm", "-rdvf", "/etc/apt/sources.list", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/apt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/alternatives", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/default", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/dpkg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/dropbear", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/localtime", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/motd", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/pam.d", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/profile", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/pkcs11", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/profile.d", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/profile.ro", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/rc.d", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/resolv.conf", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/ssh", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/ssl", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/sudo.conf", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/sudoers", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/sudoers.d", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/sudoers.dist", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/wgetrc", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/zshrc", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/etc/zprofile", NULL);
        
        execCmdCh("/freya/rm", "-rdvf", "/private/private", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/containers/Bundle/dylibs", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/containers/Bundle/iosbinpack64", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/containers/Bundle/tweaksupport", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/log/suckmyd-stderr.log", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/log/suckmyd-stdout.log", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/log/jailbreakd-stderr.log", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/log/jailbreakd-stdout.log", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/backups", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/empty", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/bin", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/cache", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/db/stash", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/db/sudo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/dropbear", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/lib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/var/lib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/LIB", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/local", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/log/apt", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/log/dpkg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/log/testbin.log", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/lock", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cr4shed", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT4", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Logs/Cydia", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Sileo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Toonsy", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Widgets", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/AmyCache", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/org.coolstar.SileoStore", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/motd", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/profile", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/run/sudo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/sbin", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/spool", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/tweak", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/private/var/unlimapps_tweak_resources", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Alkaline", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Activator", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/Snoverlay", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/Flame", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/CallBlocker", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/CCSupport", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/Compatimark", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/Malipo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/SafariPlus.bundle", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/Activator", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/Cylinder", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/Barrel", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/BarrelSettings", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Application\ Support/libGitHubIssues", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Barrel", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/BarrelSettings", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Cylinder", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/dpkg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Flipswitch", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Frameworks", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/LaunchDaemons", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/MobileSubstrate", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/MobileSubstrate/", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/MobileSubstrate/DynamicLibraries", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/PreferenceBundles", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/PreferenceLoader", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/SBInject", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Switches", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/test_inject_springboard.cy", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Themes", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/TweakInject", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/Zeppelin", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/Library/.DS_Store", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/System/Library/PreferenceBundles/AppList.bundle", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/System/Library/Themes", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/System/Library/KeyboardDictionaries", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/libresolv.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/lib/liblzma.dylib", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/include", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/aclocal", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/bigboss", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/share/common-lisp", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/dict", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/dpkg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/git-core", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/git-gui", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/gnupg", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/gitk", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/gitweb", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/libgpg-error", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/man", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/p11-kit", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/tabset", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/usr/share/terminfo", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/.freya_installed", NULL);
        execCmdCh("/freya/rm", "-rdvf", "/.freya_bootstrap", NULL);
        
        
        
        ////////
    }
    //////////////////////////////
    //////////////////////////////finally added the check for changing remvoving files without needing two separate apps
    
    else if (/* iOS 11.3 and higher can use lucky snapshot */ kCFCoreFoundationVersionNumber > 1451.51){ printf("[*] Removing Jailbreak for ios 11.3 - 11.4 beta 1-3 devices..\n");
        int testexec =execCmdCh("/freya/rm", "-rdvf", "/private/etc/apt", NULL);
        if (testexec == 0) {
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/motd", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/profile", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/rc.d", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/rc.d/substrate", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/etc/zshrc", NULL);
            ////usr/etc//
            execCmdCh("/freya/rm", "-rdvf", "/var/backups", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/containers/Bundle/iosbinpack64", NULL);
            ////etc folder cleanup
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/pam.d", NULL);
            //private/etc
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/apt", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/dropbear", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/alternatives", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/default", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/dpkg", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/ssh", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/ssl", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/profile.d", NULL);
            ////private/var
            execCmdCh("/freya/rm", "-rdvf", "/private/var/cache", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/lib", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/local", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/lock", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/spool", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/lib/apt", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/lib/cydia", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/cache/apt", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/db/stash", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/stash", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/tweak", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
            //var/mobile/Library
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia/", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
            //var/mobile/Library/Caches
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
            //snapshot.library
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
            unlink("/private/etc/apt/sources.list.d/cydia.list");
            unlink("/private/etc/apt");
            //////system/library
            execCmdCh("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/profile", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/motd", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/log/testbin.log", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/log/apt", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/log/jailbreakd-stderr.log", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/log/jailbreakd-stdout.log", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/LIB", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/bin", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/sbin", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/profile", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/motd", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/dropbear", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/containers/Bundle/tweaksupport", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/containers/Bundle/iosbinpack64", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/containers/Bundle/dylibs", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/LIB", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/motd", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/log/testbin.log", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/log/jailbreakd-stdout.log", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/log/jailbreakd-stderr.log", NULL);
            
            
            
            
            
            
            execCmdCh("/freya/rm", "-rdvf", "/var/cache", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/freya/", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/lib", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/stash", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/db/stash", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/mobile/Library/Cydia", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/etc/apt/sources.list.d", NULL);
                         
            execCmdCh("/freya/rm", "-rdvf", "/etc/apt/sources.list", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/apt", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/alternatives", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/default", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/dpkg", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/dropbear", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/localtime", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/motd", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/pam.d", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/profile", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/pkcs11", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/profile.d", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/profile.ro", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/rc.d", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/resolv.conf", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/ssh", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/ssl", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/sudo.conf", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/sudoers", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/sudoers.d", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/sudoers.dist", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/wgetrc", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/zshrc", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/etc/zprofile", NULL);
            
            execCmdCh("/freya/rm", "-rdvf", "/private/private", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/containers/Bundle/dylibs", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/containers/Bundle/iosbinpack64", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/containers/Bundle/tweaksupport", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/log/suckmyd-stderr.log", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/log/suckmyd-stdout.log", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/log/jailbreakd-stderr.log", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/log/jailbreakd-stdout.log", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/backups", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/empty", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/bin", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/cache", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/db/stash", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/db/sudo", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/dropbear", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/lib", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/var/lib", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/LIB", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/local", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/log/apt", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/log/dpkg", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/log/testbin.log", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/lock", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cr4shed", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT4", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Logs/Cydia", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Sileo", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Toonsy", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Widgets", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/AmyCache", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/org.coolstar.SileoStore", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/motd", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/profile", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/run/sudo", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/sbin", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/spool", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/tweak", NULL);
            execCmdCh("/freya/rm", "-rdvf", "/private/var/unlimapps_tweak_resources", NULL);
            
        }
        else {
            printf("FAILED TO REMOVE WITH RM FREYA\n");
        }
    }
}
