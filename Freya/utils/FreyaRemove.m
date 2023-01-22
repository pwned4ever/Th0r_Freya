//
//  FreyaRemove.m
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
#include "FreyaRemove.h"

char *myenvironFreya[] = {
    "PATH=/freya/usr/local/sbin:/freya/usr/local/bin:/freya/usr/sbin:/freya/usr/bin:/freya/sbin:/freya/bin:/freya/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games",
    "PS1=\\h:\\w \\u\\$ ",
    NULL
};
NSData *lastSystemOutputFreya=nil;
int execCmdVFreya(const char *cmd, int argc, const char * const* argv, void (^unrestrict)(pid_t)) {
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
    
    int rv = posix_spawn(&pid, cmd, actions, attr, (char *const *)argv, myenvironFreya);
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
            lastSystemOutputFreya = [outData copy];
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

int execCmdFreya(const char *cmd, ...) {
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
    
    int rv = execCmdVFreya(cmd, argc, argv, NULL);
    return WEXITSTATUS(rv);
}

int systemCmdFreya(const char *cmd) {
    const char *argv[] = {"sh", "-c", (char *)cmd, NULL};
    return execCmdVFreya("/bin/sh", 3, argv, NULL);
}

void removingFreyaiOS() {
    
    util_info("Removing Files...");
    //removingJailbreaknotice();
    /////////START REMOVING FILES
    if (/* iOS 11.2.6 or lower don't use snapshot */ kCFCoreFoundationVersionNumber <= 1451.51){
        
        printf("Removing Jailbreak with Eremover.for ios 11.2.x devices..\n");
        
        int rvchec1 = execCmdFreya("/usr/bin/find", ".", "-name", "*.deb", "-type", "f", "-delete", NULL);
        printf("[*] Trying find . with *.deb delete result = %d \n" , rvchec1);
        ///////delete the Malware from Satan////
        
        int rvchecdothidden1 = execCmdFreya("/usr/bin/find", ".", "-name", "._*", "-type", "f", "-delete", NULL);
        printf("[*] Trying find . with ._* delete result = %d \n" , rvchecdothidden1);
        
        printf("[*] Removing Jailbreak with custom remover...\n");
        execCmdFreya("/freya/rm", "-rdvf", "/var/mobile/Media/.bootstrapped_electraremover", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/mobile/testremover.txt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/.bootstrapped_Th0r", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/.freya_installed", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/.bootstrapped_electra", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/.installed_unc0ver", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/.install_unc0ver", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/.electra_no_snapshot", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/.installed_unc0vered", NULL);

        
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/motd", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/.cydia_no_stash", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/Cydia.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Network", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/aclocal", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/bigboss", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/common-lisp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/dict", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/dpkg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/gnupg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/libgpg-error", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/p11-kit", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/tabset", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/terminfo", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/local/bin", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/local/lib", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/authorize.sh", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/.cydia_no_stash", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/zsh", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/profile", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/rc.d", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/rc.d/substrate", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/etc/zshrc", NULL);
        ////usr/etc//
        execCmdFreya("/freya/rm", "-rdvf", "/usr/etc", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/scp", NULL);
        ////usr/lib////
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/_ncurses", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/apt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/bash", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/gettext", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.1.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-private.0.0.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-private.0.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libasprintf.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libasprintf.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libassuan.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libassuan.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libassuan.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libdpkg.a", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libform.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libform.6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libform5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libformw.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libformw.6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libformw.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libformw5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgcrypt.20.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgcrypt.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgcrypt.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgettextlib-0.19.8.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgettextlib.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgettextpo.1.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgettextpo.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgettextsrc-0.19.8.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgettextsrc.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgmp.10.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgmp.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgmp.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgnutls.30.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgnutls.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgnutlsxx.28.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgnutlsxx.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.2.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhistory.6.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhistory.7.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhistory.7.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhistory.dylib ", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhogweed.4.4.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhogweed.4.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhogweed.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libidn2.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libidn2.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libidn2.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libintl.9.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libintl.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libksba.8.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libksba.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libksba.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/liblz4.1.7.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/liblz4.1.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/liblz4.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libmenu.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libmenu.6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libmenu.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libmenu5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libmenuw.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libmenuw.6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libmenuw.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libmenuw5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncurses.6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncurses5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncurses6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncursesw.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncursesw.6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncursesw.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncursesw5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncursesw6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libnettle.6.4.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libnettle.6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libnettle.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libnpth.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libnpth.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libnpth.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libp11-kit.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libp11-kit.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libp11-kit.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpanel.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpanel.6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpanel.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpanel5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpanelw.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpanelw.6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpanelw.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpanelw5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.2.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libreadline.6.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libreadline.7.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libreadline.7.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libreadline.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libresolv.9.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libresolv.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libtasn1.6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libtasn1.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libtasn1.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libunistring.2.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libunistring.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libunistring.la", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libsubstitute.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libsubstitute.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libsubstrate.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libjailbreak.dylib", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/recode-sr-latin", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/recache", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/rollectra", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/Rollectra", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/killall", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/sftp-server", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/SBInject.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/zsh", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/electra-prejailbreak", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/electra/createSnapshot", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/jb", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/jb", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/backups", NULL);
        ////////////Applications cleanup and root
        execCmdFreya("/freya/rm", "-rdvf", "/RWTEST", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/pwnedWritefileatrootTEST", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/Cydia\ Update\ Helper.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/NETWORK", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/AppCake.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/Activator.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/Anemone.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/BestCallerId.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/CrackTool3.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/Cydia.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/Sileo.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/Rollectra.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/cydown.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/Cylinder.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/iCleaner.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/icleaner.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/BarrelSettings.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/Ext3nder.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/Filza.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/Flex.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/GBA4iOS.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/jjjj.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/ReProvision.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/SafeMode.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/NewTerm.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/MobileTerminal.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/MTerminal.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/MovieBox3.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/BobbyMovie.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/PopcornTime.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/RST.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/TSSSaver.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/CertRemainTime.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/CrashReporter.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/AudioRecorder.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/ADManager.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/CocoaTop.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/calleridfaker.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/CallLogPro.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/WiFiPasswords.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/WifiPasswordList.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/calleridfaker.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/ClassDumpGUI.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/idevicewallsapp.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/UDIDFaker.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/UDIDCalculator.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/CallRecorder.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/Rehosts.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/NGXCarPlay.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/Audicy.app", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Applications/NGXCarplay.app", NULL);
        ///////////USR/LIBEXEC
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/as", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/frcode", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/bigram", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/code", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/reload", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/rmt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/MSUnrestrictProcess", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/perl5", NULL);
        //////////USR/SHARE
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/git-core", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/git-gui", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/gitk", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/gitweb", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/man", NULL);
        ////////USR/LOCAL
        execCmdFreya("/freya/rm", "-rdvf", "/usr/local/bin", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/local/lib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/local/lib/libluajit.a", NULL);
        
        ////var
        execCmdFreya("/freya/rm", "-rdvf", "/var/containers/Bundle/iosbinpack64", NULL);
        ////etc folder cleanup
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/pam.d", NULL);
        
        //private/etc
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/apt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/dropbear", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/alternatives", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/default", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/dpkg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/ssh", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/ssl", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/profile.d", NULL);
        
        ////private/var
        
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/cache", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/lib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/local", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/lock", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/spool", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/lib/apt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/lib/cydia", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/cache/apt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/db/stash", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/stash", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/tweak", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
        //var/mobile/Library
        
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia/", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
        
        //var/mobile/Library/Caches
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
        
        //snapshot.library
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
        unlink("/private/etc/apt/sources.list.d/cydia.list");
        unlink("/private/etc/apt");
        
        ////usr/include files
        execCmdFreya("/freya/rm", "-rdvf", "/usr/include", NULL);
        ////usr/local files
        execCmdFreya("/freya/rm", "-rdvf", "/usr/local/bin", NULL);
        ////usr/libexec files
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/apt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/ssh-pkcs11-helper", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/ssh-keysign", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/cydia", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/dpkg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/gnupg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/gpg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/gpg-check-pattern", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/gpg-preset-passphrase", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/gpg-protect-tool", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/gpg-wks-client", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/git-core", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/p11-kit", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/scdaemon", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/vndevice", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/frcode", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/bigram", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/code", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/coreutils", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/reload", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/rmt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/filza", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/sudo", NULL);
        ////usr/lib files
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/TweakInject", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/tweakloader.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/pspawn_hook.dylib", NULL);
        unlink("/usr/lib/pspawn_hook.dylib");
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/tweaks", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/Activator", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/apt", NULL);
        
        unlink("/usr/lib/apt");
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/dpkg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/pam", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/p11-kit.0.dylib", NULL);
        unlink("/usr/lib/p11-kit-proxy.dylib");
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/p11-kit-proxy.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/pkcs11", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/pam", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/pkgconfig", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/ssl", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/bash", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/gettext", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/coreutils", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/engines", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/p7zip", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/Cephei.framework", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/CepheiPrefs.framework", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/SBInject", NULL);
        //usr/local
        execCmdFreya("/freya/rm", "-rdvf", "/usr/local/bin", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/local/lib", NULL);
        ////library folder files and subfolders
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Alkaline", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Activator", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Barrel", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/BarrelSettings", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Cylinder", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/dpkg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Frameworks", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/LaunchDaemons", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/.DS_Store", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/MobileSubstrate", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/PreferenceBundles", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/Library/PreferenceLoader", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/SBInject", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/Snoverlay", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/Flame", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/CallBlocker", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/CCSupport", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/Compatimark", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/Dynastic", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/Malipo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/SafariPlus.bundle", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/Activator", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/Cylinder", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/Barrel", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/BarrelSettings", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/libGitHubIssues/", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Themes", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/TweakInject", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Zeppelin", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Flipswitch", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Switches", NULL);
        
        //////system/library
        execCmdFreya("/freya/rm", "-rdvf", "/System/Library/PreferenceBundles/AppList.bundle", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/System/Library/Themes", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/System/Library/Internet\ Plug-Ins", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/System/Library/KeyboardDictionaries", NULL);
        
        /////root
        
        execCmdFreya("/freya/rm", "-rdvf", "/FELICITYICON.png", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bootstrap", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/mnt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/lib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/boot", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/libexec", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/include", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/mnt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/jb", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/games", NULL);
        //////////////USR/LIBRARY
        execCmdFreya("/freya/rm", "-rdvf", "/usr/Library", NULL);
        
        ///////////PRIVATE
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
        ///
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/killall", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/reboot", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/.bootstrapped_Th0r", NULL);
        
        
        execCmdFreya("/freya/rm", "-rf", "/Library/test_inject_springboard.cy", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/SBInject.dylib", NULL);
        ////usr/local files and folders cleanup
        execCmdFreya("/freya/rm", "-rdvf", "/usr/local/lib", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libsparkapplist.dylib", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcrashreport.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libsymbolicate.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/TweakInject.dylib", NULL);
        //////ROOT FILES :(
        execCmdFreya("/freya/rm", "-rdvf", "/.bootstrapped_electra", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/.cydia_no_stash", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/.bit_of_fun", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/RWTEST", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/pwnedWritefileatrootTEST", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
        
        
        ////////// BIN/
        execCmdFreya("/freya/rm", "-rdvf", "/bin/bashbug", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/bunzip2", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/bzcat", NULL);
        unlink("usr/bin/bzcat");
        execCmdFreya("/freya/rm", "-rdvf", "/bin/bzip2", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/bzip2recover", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/bzip2_64", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/cat", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/chgrp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/chmod", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/chown", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/cp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/date", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/dd", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/dir", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/echo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/egrep", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/false", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/fgrep", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/grep", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/gzip", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/gtar", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/gunzip", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/gzexe", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/hostname", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/launchctl", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/ln", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/ls", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/jtoold", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/kill", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/mkdir", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/mknod", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/mv", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/mktemp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/pwd", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/bin/rmdir", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/readlink", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/unlink", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/run-parts", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/su", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/sync", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/stty", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/sh", NULL);
        unlink("/bin/sh");
        
        execCmdFreya("/freya/rm", "-rdvf", "/bin/sleep", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/sed", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/su", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/tar", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/touch", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/true", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/uname", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/vdr", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/vdir", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/uncompress", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/znew", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/zegrep", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/zmore", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/zdiff", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/zcat", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/zcmp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/zfgrep", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/zforce", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/zless", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/zgrep", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/zegrep", NULL);
        
        //////////SBIN
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/reboot", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/halt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/ifconfig", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/kextunload", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/ping", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/update_dyld_shared_cache", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/dmesg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/dynamic_pager", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/nologin", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/fstyp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/fstyp_msdos", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/fstyp_ntfs", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/fstyp_udf", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/mount_devfs", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/mount_fdesc", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/quotacheck", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/umount", NULL);
        
        
        /////usr/bin files folders cleanup
        //symbols
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/[", NULL);
        //a
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ADMHelper", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/arch", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/apt", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ar", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/apt-key", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/apt-cache", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/apt-cdrom", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/apt-config", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/apt-extracttemplates", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/apt-ftparchive", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/apt-sortpkgs", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/apt-mark", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/apt-get", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/arch", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/asu_inject", NULL);
        
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/asn1Coding", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/asn1Decoding", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/asn1Parser", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/autopoint", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/as", NULL);
        //b
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/bashbug", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/b2sum", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/base32", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/base64", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/basename", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/bitcode_strip", NULL);
        //c
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/CallLogPro", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/com.julioverne.ext3nder-installer", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/chown", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/chmod", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/chroot", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/chcon", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/chpass", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/check_dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/checksyms", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/chfn", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/chsh", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/cksum", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/comm", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/cmpdylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/codesign_allocate", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/csplit", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ctf_insert", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/cut", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/curl", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/curl-config", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/c_rehash", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/captoinfo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/certtool", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/cfversion", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/clear", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/cmp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/cydown", NULL);//cydown
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/cydown.arch_arm64", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/cydown.arch_armv7", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/cycript", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/cycc", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/cynject", NULL);
        //d
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dbclient", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/db_archive", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/db_checkpoint", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/db_deadlock", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/db_dump", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/db_hotbackup", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/db_load", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/db_log_verify", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/db_printlog", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/db_recover", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/db_replicate", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/db_sql_codegen", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/db_stat", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/db_tuner", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/db_upgrade", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/db_verify", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dbsql", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/debugserver", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/defaults", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/df", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/diff", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/diff3", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dirname", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dircolors", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dirmngr", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dirmngr-client", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-architecture", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-buildflags", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-buildpackage", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-checkbuilddeps", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-deb", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-distaddfile", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-divert", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-genbuildinfo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-genchanges", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-gencontrol", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-gensymbols", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-maintscript-helper", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-mergechangelogs", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-name", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-parsechangelog", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-query", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-scanpackages", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-scansources", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-shlibdeps", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-source", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-split", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-statoverride", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-trigger", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dpkg-vendor", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/du", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dumpsexp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dselect", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dsymutil", NULL);
        ////e
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/expand", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/expr", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/env", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/envsubst", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ecidecid", NULL);
        //f
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/factor", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/filemon", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/Filza", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/fmt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/fold", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/funzip", NULL);
        //g
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/games", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/getconf", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/getty", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gettext", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gettext.sh", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gettextize", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/git", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/git-cvsserver", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/git-recieve-pack", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/git-shell", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/git-upload-pack", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gitk", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gnutar", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gnutls-cli", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gnutls-cli-debug", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gnutls-serv", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gpg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gpgrt-config", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gpg-zip", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gpgsplit", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gpgv", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gssc", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/groups", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gpg-agent", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gpg-connect-agent ", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gpg-error", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gpg-error-config", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gpg2", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gpgconf", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gpgparsemail", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gpgscm", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gpgsm", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gpgtar", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gpgv2", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/groups", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/gtar", NULL);
        //h
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/head", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/hmac256", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/hostid", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/hostinfo", NULL);
        //i
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/install", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/id", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/idn2", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/indr", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/inout", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/infocmp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/infotocap", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/iomfsetgamma", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/install_name_tool", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/libtool", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/lipo", NULL);
        //j
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/join", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/jtool", NULL);
        //k
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/killall", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/kbxutil", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ksba-config", NULL);
        //l
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/less", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/libassuan-config", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/libgcrypt-config", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/link", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ldid", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ldid2", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ldrestart", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/locate", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/login", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/logname", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/lzcat", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/lz4", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/lz4c", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/lz4cat", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/lzcmp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/lzdiff", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/lzegrep", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/lzfgrep", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/lzgrep", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/lzless", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/lzma", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/lzmadec", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/lzmainfo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/lzmore", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin.lipo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/lipo", NULL);
        
        //m
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/md5sum", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/mkfifo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/mktemp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/more", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/msgattrib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/msgcat", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/msgcmp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/msgcomm", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/msgconv", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/msgen", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/msgexec", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/msgfilter", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/msgfmt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/msggrep", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/msginit", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/msgmerge", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/msgunfmt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/msguniq", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/mpicalc", NULL);
        //n
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/nano", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/nettle-hash", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/nettle-lfib-stream", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/nettle-pbkdf2", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ngettext", NULL);
        
        
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/nm", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/nmedit", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/nice", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/nl", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/nohup", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/nproc", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/npth-config", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/numfmt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ncurses6-config", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ncursesw6-config", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ncursesw5-config", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ncurses5-config", NULL);
        //o
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/od", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ocsptool", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ObjectDump", NULL);//ld64
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/dyldinfo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ld", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/machocheck", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/unwinddump", NULL);//ld64 done
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/otool", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/openssl", NULL);
        //p
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/pincrush", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/pagestuff", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/pagesize", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/passwd", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/paste", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/pathchk", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/pinky", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/plconvert", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/pr", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/printenv", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/printf", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/procexp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ptx", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/p11-kit", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/p11tool", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/pkcs1-conv", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/psktool", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/quota", NULL);
        
        
        //r
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/renice", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ranlib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/redo_prebinding", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/reprovisiond", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/reset", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/realpath", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/rnano", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/runcon", NULL);
        //s
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/snapUtil", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/sbdidlaunch", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/sbreload", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/script", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/sdiff", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/seq", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/sexp-conv", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/seg_addr_table", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/seg_hack", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/segedit", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/sftp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/shred", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/shuf", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/sort", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ssh", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ssh-add", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ssh-agent", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ssh-keygen", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/ssh-keyscan", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/sw_vers", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/seq", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/SemiRestore11-Lite", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/sha1sum", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/sha224sum", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/sha256sum", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/sha384sum", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/sha512sum", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/shred", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/shuf", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/size", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/split", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/srptool", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/stat", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/stdbuf", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/strings", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/strip", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/sum", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/sync", NULL);
        //t
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/tabs", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/tac", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/tar", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/tail", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/tee", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/test", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/tic", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/time", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/timeout", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/toe", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/tput", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/tr", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/tset", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/truncate", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/trust", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/tsort", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/tty", NULL);
        //u
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/uiduid", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/uuid", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/uuid-config", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/uiopen", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/unlz4", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/unlzma", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/unxz", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/update-alternatives", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/updatedb", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/unexpand", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/uniq", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/unzip", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/unzipsfx", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/unrar", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/uptime", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/users", NULL);
        //w
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/watchgnupg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/wc", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/wget", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/which", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/who", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/whoami", NULL);
        //x
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/xargs", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/xz", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/xgettext", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/xzcat", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/xzcmp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/xzdec", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/xzdiff", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/xzegrep", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/xzfgrep", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/xzgrep", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/xzless", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/xzmore", NULL);
        //y
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/yat2m", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/yes", NULL);
        //z
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/zip", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/zipcloak", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/zipnote", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/zipsplit", NULL);
        //numbers
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/7z", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/7za", NULL);
        //////////////
        ////
        //////////USR/SBIN
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/chown", NULL);
        
        unlink("/usr/sbin/chown");
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/chmod", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/chroot", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/dev_mkdb", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/edquota", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/applygnupgdefaults", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/fdisk", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/halt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/sshd", NULL);
        
        //////////////USR/LIB
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/xxxMobileGestalt.dylib", NULL);//for cydown
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/xxxSystem.dylib", NULL);//for cydown
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcolorpicker.dylib", NULL);//
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcrypto.dylib", NULL);//
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcrypto.a", NULL);//
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libdb_sql-6.2.dylib", NULL);//
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libdb_sql-6.dylib", NULL);//
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libdb_sql.dylib", NULL);//
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libdb-6.2.dylib", NULL);//
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libdb-6.dylib", NULL);//
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libdb.dylib", NULL);//
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/liblzma.a", NULL);//
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/liblzma.la", NULL);//
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libprefs.dylib", NULL);//
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libssl.a", NULL);//
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libssl.dylib", NULL);//
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libST.dylib", NULL);//
        //////////////////
        //////////////8
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpam.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpamc.1.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6.0", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpanelw.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.2.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libreadline.6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpanel.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcurses.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhistory.6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libformw.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncursesw.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhistory.6.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libform.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpanelw.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libmenuw.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/terminfo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpam.1.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libmenu.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpatcyh.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libreadline.6.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncurses.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhistory.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpamc.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libformw.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1.0", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpanel.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.0.0.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/_ncurses", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpam_misc.1.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.2.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpam_misc.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libreadline.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libmenuw.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpam.1.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libmenu.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncursesw.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcycript.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcycript.jar", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libdpkg.a", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcrypto.1.0.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libssl.1.0.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcycript.db", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcurl.4.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcycript.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcycript.cy", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libdpkg.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libswift", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libsubstrate.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libuuid.16.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libuuid.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libtapi.dylib", NULL);//ld64
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libnghttp2.14.dylib", NULL);//ld64
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libnghttp2.dylib", NULL);//ld64
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libnghttp2.la", NULL);//ld64
        ///sauirks new substrate
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/substrate", NULL);//ld64
        
        //////////USR/SBIN
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/accton", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/vifs", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/ac", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/update", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/pwd_mkdb", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/sysctl", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/zdump", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/startupfiletool", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/iostat", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/nologin", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/mkfile", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/quotaon", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/repquota", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/zic", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/vipw", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/vsdbutil", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/start-stop-daemon", NULL);
        ////////USR/LOCAL
        execCmdFreya("/freya/rm", "-rdvf", "/usr/local/lib/libluajit.a", NULL);
        //////LIBRARY
        execCmdFreya("/freya/rm", "-rdvf", "/Library/test_inject_springboard.cy", NULL);
        //////sbin folder files cleanup
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/dmesg", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/cat", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/sbin/zshrc", NULL);
        ////usr/sbin files
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/start-start-daemon", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/accton", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/addgnupghome", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/vifs", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/ac", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/update", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/sysctl", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/zdump", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/startupfiletool", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/iostat", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/mkfile", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/zic", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/sbin/vipw", NULL);
        ////usr/libexec files
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/_rocketd_reenable", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/rocketd", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/MSUnrestrictProcess", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/substrate", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/libexec/substrated", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/applist.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapplist.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhAcxTools.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhAcxTools2.dylib", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libflipswitch.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.1.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-private.0.0.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-private.0.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libassuan.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libassuan.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libassuan.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libnpth.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libnpth.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libnpth.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libksba.8.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libksba.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libksba.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/cycript0.9", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpam.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpamc.1.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpackageinfo.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/librocketbootstrap.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6.0", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpanelw.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.2.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libreadline.6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpanel.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcurses.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhistory.6.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libformw.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncursesw.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhistory.6.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libform.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpanelw.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libmenuw.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/terminfo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/terminfo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpam.1.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libmenu.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpatcyh.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libreadline.6.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncurses.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhistory.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpamc.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libformw.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1.0", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpanel.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.0.0.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/_ncurses", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpam_misc.1.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.2.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpam_misc.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libreadline.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libmenuw.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libpam.1.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libmenu.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncursesw.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcycript.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcycript.jar", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcycript.db", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcurl.4.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcurl.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcurl.la", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcycript.0.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcycript.cy", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcephei.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libcepheiprefs.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhbangcommon.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libhbangprefs.dylib", NULL);
        /////end it
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libjailbreak.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/profile", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/motd", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/log/testbin.log", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/log/apt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/log/jailbreakd-stderr.log", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/log/jailbreakd-stdout.log", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/test_inject_springboard.cy", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/local/lib/libluajit.a", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/bin/zsh", NULL);
        //missing from removeMe.sh oddly
        //////mine above lol
        //////////////////Jakes below
        
        execCmdFreya("/freya/rm", "-rdvf", "/var/LIB", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/bin", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/sbin", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/profile", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/motd", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/dropbear", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/containers/Bundle/tweaksupport", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/containers/Bundle/iosbinpack64", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/containers/Bundle/dylibs", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/LIB", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/motd", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/log/testbin.log", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/log/jailbreakd-stdout.log", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/log/jailbreakd-stderr.log", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/bin/find", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/var/cache", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/freya", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/lib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/stash", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/db/stash", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/mobile/Library/Cydia", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/etc/apt/sources.list.d", NULL);
                     
        execCmdFreya("/freya/rm", "-rdvf", "/etc/apt/sources.list", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/apt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/alternatives", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/default", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/dpkg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/dropbear", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/localtime", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/motd", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/pam.d", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/profile", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/pkcs11", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/profile.d", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/profile.ro", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/rc.d", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/resolv.conf", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/ssh", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/ssl", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/sudo.conf", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/sudoers", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/sudoers.d", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/sudoers.dist", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/wgetrc", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/zshrc", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/etc/zprofile", NULL);
        
        execCmdFreya("/freya/rm", "-rdvf", "/private/private", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/containers/Bundle/dylibs", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/containers/Bundle/iosbinpack64", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/containers/Bundle/tweaksupport", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/log/suckmyd-stderr.log", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/log/suckmyd-stdout.log", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/log/jailbreakd-stderr.log", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/log/jailbreakd-stdout.log", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/backups", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/empty", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/bin", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/cache", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/db/stash", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/db/sudo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/dropbear", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/lib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/var/lib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/LIB", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/local", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/log/apt", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/log/dpkg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/log/testbin.log", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/lock", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cr4shed", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT4", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Logs/Cydia", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Sileo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Toonsy", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Widgets", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/AmyCache", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/org.coolstar.SileoStore", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/motd", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/profile", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/run/sudo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/sbin", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/spool", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/tweak", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/private/var/unlimapps_tweak_resources", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Alkaline", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Activator", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/Snoverlay", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/Flame", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/CallBlocker", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/CCSupport", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/Compatimark", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/Malipo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/SafariPlus.bundle", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/Activator", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/Cylinder", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/Barrel", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/BarrelSettings", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Application\ Support/libGitHubIssues", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Barrel", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/BarrelSettings", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Cylinder", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/dpkg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Flipswitch", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Frameworks", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/LaunchDaemons", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/MobileSubstrate", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/MobileSubstrate/", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/MobileSubstrate/DynamicLibraries", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/PreferenceBundles", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/PreferenceLoader", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/SBInject", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Switches", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/test_inject_springboard.cy", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Themes", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/TweakInject", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/Zeppelin", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/Library/.DS_Store", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/System/Library/PreferenceBundles/AppList.bundle", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/System/Library/Themes", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/System/Library/KeyboardDictionaries", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/libresolv.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/lib/liblzma.dylib", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/include", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/aclocal", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/bigboss", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/share/common-lisp", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/dict", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/dpkg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/git-core", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/git-gui", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/gnupg", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/gitk", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/gitweb", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/libgpg-error", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/man", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/p11-kit", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/tabset", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/usr/share/terminfo", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/.freya_installed", NULL);
        execCmdFreya("/freya/rm", "-rdvf", "/.freya_bootstrap", NULL);
        
        
        
        ////////
    }
    //////////////////////////////
    //////////////////////////////finally added the check for changing remvoving files without needing two separate apps
    
    else if (/* iOS 11.3 and higher can use lucky snapshot */ kCFCoreFoundationVersionNumber > 1451.51){ printf("[*] Removing Jailbreak for devices greater or equal to ios 11.3....\n");
        int testexec = execCmdFreya("/freya/rm", "-rdvf", "/private/etc/apt", NULL);
        if (testexec == 0) {
            ////usr/etc//
            ////etc folder cleanup
            ///        execCmdFreya("/freya/rm", "-rdvf", "/RWTEST", NULL);
            ///            execCmdFreya("/freya/rm", "-rdvf", "/var/mobile/Media/.bootstrapped_electraremover", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/var/mobile/testremover.txt", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/pam.d", NULL);
            //private/etc
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/apt", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/alternatives", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/default", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/dpkg", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/dropbear", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/localtime", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/motd", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/pam.d", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/profile", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/pkcs11", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/profile.d", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/profile.ro", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/rc.d", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/resolv.conf", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/ssh", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/ssl", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/sudo.conf", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/sudoers", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/sudoers.d", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/sudoers.dist", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/wgetrc", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/zshrc", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/etc/zprofile", NULL);
            ////private/var
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/backups", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/cache", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/lib", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/local", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/lock", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/spool", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/lib/apt", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/lib/cydia", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/db/stash", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/stash", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/tweak", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/profile", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/motd", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/log/testbin.log", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/log/apt", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/log/jailbreakd-stderr.log", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/log/jailbreakd-stdout.log", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/LIB", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/bin", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/sbin", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/dropbear", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/empty", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/bin", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/db/sudo", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/log/dpkg", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/containers/Bundle/tweaksupport", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/containers/Bundle/iosbinpack64", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/containers/Bundle/dylibs", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/freya/", NULL);
            //var/mobile/Library
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia/", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
            //var/mobile/Library/Caches
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
            //snapshot.library
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
            //////system/library
            execCmdFreya("/freya/rm", "-rdvf", "/var/mobile/Library/Cydia", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/private", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/containers/Bundle/dylibs", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/containers/Bundle/iosbinpack64", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/containers/Bundle/tweaksupport", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/log/suckmyd-stderr.log", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/log/suckmyd-stdout.log", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/log/jailbreakd-stderr.log", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/log/jailbreakd-stdout.log", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cr4shed", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT4", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Logs/Cydia", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Sileo", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Toonsy", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Widgets", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/AmyCache", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/org.coolstar.SileoStore", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/motd", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/profile", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/run/sudo", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/sbin", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/spool", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/tweak", NULL);
            execCmdFreya("/freya/rm", "-rdvf", "/private/var/unlimapps_tweak_resources", NULL);
           
        }
        else {
            printf("FAILED TO REMOVE WITH RM FREYA\n");
        }
    }
}
