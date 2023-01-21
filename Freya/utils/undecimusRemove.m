//
//  undecimusRemove.m
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
#include "undecimusRemove.h"

char *myenvironu0[] = {
    "PATH=/freya/usr/local/sbin:/freya/usr/local/bin:/freya/usr/sbin:/freya/usr/bin:/freya/sbin:/freya/bin:/freya/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games",
    "PS1=\\h:\\w \\u\\$ ",
    NULL
};
NSData *lastSystemOutputu0=nil;
int execCmdVu0(const char *cmd, int argc, const char * const* argv, void (^unrestrict)(pid_t)) {
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
    
    int rv = posix_spawn(&pid, cmd, actions, attr, (char *const *)argv, myenvironu0);
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
            lastSystemOutputu0 = [outData copy];
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

int execCmdu0(const char *cmd, ...) {
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
    
    int rv = execCmdVu0(cmd, argc, argv, NULL);
    return WEXITSTATUS(rv);
}

int systemCmdu0(const char *cmd) {
    const char *argv[] = {"sh", "-c", (char *)cmd, NULL};
    return execCmdVu0("/bin/sh", 3, argv, NULL);
}

void removingu0iOS() {
    
    execCmdu0("/freya/rm", "-rdvf", "/electra/launchctl", NULL);
    execCmdu0("/freya/rm", "-rdvf", "/var/mobile/Media/.bootstrapped_electraremover", NULL);
    execCmdu0("/freya/rm", "-rdvf", "/var/mobile/testremover.txt", NULL);
    unlink("/var/mobile/testremover.txt");
    execCmdu0("/freya/rm", "-rdvf", "/.bootstrapped_Th0r", NULL);
    execCmdu0("/freya/rm", "-rdvf", "/.freya_installed", NULL);
    execCmdu0("/freya/rm", "-rdvf", "/.bootstrapped_electra", NULL);
    execCmdu0("/freya/rm", "-rdvf", "/.installed_unc0ver", NULL);
    execCmdu0("/freya/rm", "-rdvf", "/.install_unc0ver", NULL);
    execCmdu0("/freya/rm", "-rdvf", "/.electra_no_snapshot", NULL);
    execCmdu0("/freya/rm", "-rdvf", "/.installed_unc0vered", NULL);
    util_info("Removing Files...");
    //removingJailbreaknotice();
    /////////START REMOVING FILES
    if (/* iOS 11.2.6 or lower don't use snapshot */ kCFCoreFoundationVersionNumber <= 1451.51){
        
        printf("Removing Jailbreak with Eremover.for ios 11.2.x devices..\n");
        
        int rvchec1 = execCmdu0("/usr/bin/find", ".", "-name", "*.deb", "-type", "f", "-delete", NULL);
        printf("[*] Trying find . with *.deb delete result = %d \n" , rvchec1);
        ///////delete the Malware from Satan////
        
        int rvchecdothidden1 = execCmdu0("/usr/bin/find", ".", "-name", "._*", "-type", "f", "-delete", NULL);
        printf("[*] Trying find . with ._* delete result = %d \n" , rvchecdothidden1);
        
        printf("[*] Removing Jailbreak with custom remover...\n");
        
        
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/motd", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/.cydia_no_stash", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/Applications/Cydia.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Network", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/aclocal", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/bigboss", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/common-lisp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/dict", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/dpkg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/gnupg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/libgpg-error", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/p11-kit", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/tabset", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/terminfo", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/local/bin", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/local/lib", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/authorize.sh", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/.cydia_no_stash", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/zsh", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/profile", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/rc.d", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/rc.d/substrate", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/etc/zshrc", NULL);
        ////usr/etc//
        execCmdu0("/freya/rm", "-rdvf", "/usr/etc", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/scp", NULL);
        ////usr/lib////
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/_ncurses", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/apt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/bash", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/gettext", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.1.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-private.0.0.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-private.0.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libasprintf.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libasprintf.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libassuan.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libassuan.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libassuan.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libdpkg.a", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libform.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libform.6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libform5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libformw.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libformw.6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libformw.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libformw5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgcrypt.20.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgcrypt.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgcrypt.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgettextlib-0.19.8.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgettextlib.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgettextpo.1.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgettextpo.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgettextsrc-0.19.8.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgettextsrc.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgmp.10.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgmp.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgmp.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgnutls.30.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgnutls.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgnutlsxx.28.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgnutlsxx.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.2.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhistory.6.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhistory.7.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhistory.7.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhistory.dylib ", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhogweed.4.4.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhogweed.4.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhogweed.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libidn2.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libidn2.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libidn2.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libintl.9.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libintl.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libksba.8.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libksba.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libksba.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/liblz4.1.7.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/liblz4.1.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/liblz4.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libmenu.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libmenu.6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libmenu.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libmenu5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libmenuw.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libmenuw.6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libmenuw.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libmenuw5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncurses.6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncurses5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncurses6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncursesw.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncursesw.6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncursesw.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncursesw5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncursesw6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libnettle.6.4.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libnettle.6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libnettle.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libnpth.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libnpth.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libnpth.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libp11-kit.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libp11-kit.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libp11-kit.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpanel.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpanel.6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpanel.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpanel5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpanelw.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpanelw.6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpanelw.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpanelw5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.2.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libreadline.6.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libreadline.7.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libreadline.7.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libreadline.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libresolv.9.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libresolv.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libtasn1.6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libtasn1.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libtasn1.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libunistring.2.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libunistring.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libunistring.la", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libsubstitute.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libsubstitute.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libsubstrate.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libjailbreak.dylib", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/recode-sr-latin", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/recache", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/rollectra", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/Rollectra", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/killall", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/sftp-server", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/SBInject.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/zsh", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/electra-prejailbreak", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/electra/createSnapshot", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/jb", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/jb", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/backups", NULL);
        ////////////Applications cleanup and root
        execCmdu0("/freya/rm", "-rdvf", "/RWTEST", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/pwnedWritefileatrootTEST", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/Cydia\ Update\ Helper.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/NETWORK", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/AppCake.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/Activator.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/Anemone.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/BestCallerId.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/CrackTool3.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/Cydia.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/Sileo.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/Rollectra.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/cydown.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/Cylinder.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/iCleaner.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/icleaner.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/BarrelSettings.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/Ext3nder.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/Filza.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/Flex.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/GBA4iOS.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/jjjj.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/ReProvision.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/SafeMode.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/NewTerm.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/MobileTerminal.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/MTerminal.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/MovieBox3.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/BobbyMovie.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/PopcornTime.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/RST.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/TSSSaver.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/CertRemainTime.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/CrashReporter.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/AudioRecorder.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/ADManager.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/CocoaTop.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/calleridfaker.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/CallLogPro.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/WiFiPasswords.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/WifiPasswordList.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/calleridfaker.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/ClassDumpGUI.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/idevicewallsapp.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/UDIDFaker.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/UDIDCalculator.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/CallRecorder.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/Rehosts.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/NGXCarPlay.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/Audicy.app", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Applications/NGXCarplay.app", NULL);
        ///////////USR/LIBEXEC
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/as", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/frcode", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/bigram", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/code", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/reload", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/rmt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/MSUnrestrictProcess", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/perl5", NULL);
        //////////USR/SHARE
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/git-core", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/git-gui", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/gitk", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/gitweb", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/man", NULL);
        ////////USR/LOCAL
        execCmdu0("/freya/rm", "-rdvf", "/usr/local/bin", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/local/lib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/local/lib/libluajit.a", NULL);
        
        ////var
        execCmdu0("/freya/rm", "-rdvf", "/var/containers/Bundle/iosbinpack64", NULL);
        ////etc folder cleanup
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/pam.d", NULL);
        
        //private/etc
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/apt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/dropbear", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/alternatives", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/default", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/dpkg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/ssh", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/ssl", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/profile.d", NULL);
        
        ////private/var
        
        execCmdu0("/freya/rm", "-rdvf", "/private/var/cache", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/lib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/local", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/lock", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/spool", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/lib/apt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/lib/cydia", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/cache/apt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/db/stash", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/stash", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/tweak", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
        //var/mobile/Library
        
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia/", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
        
        //var/mobile/Library/Caches
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
        
        //snapshot.library
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
        unlink("/private/etc/apt/sources.list.d/cydia.list");
        unlink("/private/etc/apt");
        
        ////usr/include files
        execCmdu0("/freya/rm", "-rdvf", "/usr/include", NULL);
        ////usr/local files
        execCmdu0("/freya/rm", "-rdvf", "/usr/local/bin", NULL);
        ////usr/libexec files
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/apt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/ssh-pkcs11-helper", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/ssh-keysign", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/cydia", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/dpkg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/gnupg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/gpg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/gpg-check-pattern", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/gpg-preset-passphrase", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/gpg-protect-tool", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/gpg-wks-client", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/git-core", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/p11-kit", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/scdaemon", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/vndevice", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/frcode", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/bigram", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/code", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/coreutils", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/reload", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/rmt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/filza", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/sudo", NULL);
        ////usr/lib files
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/TweakInject", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/tweakloader.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/pspawn_hook.dylib", NULL);
        unlink("/usr/lib/pspawn_hook.dylib");
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/tweaks", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/Activator", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/apt", NULL);
        
        unlink("/usr/lib/apt");
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/dpkg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/pam", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/p11-kit.0.dylib", NULL);
        unlink("/usr/lib/p11-kit-proxy.dylib");
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/p11-kit-proxy.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/pkcs11", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/pam", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/pkgconfig", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/ssl", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/bash", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/gettext", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/coreutils", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/engines", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/p7zip", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/Cephei.framework", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/CepheiPrefs.framework", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/SBInject", NULL);
        //usr/local
        execCmdu0("/freya/rm", "-rdvf", "/usr/local/bin", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/local/lib", NULL);
        ////library folder files and subfolders
        execCmdu0("/freya/rm", "-rdvf", "/Library/Alkaline", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Activator", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Barrel", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/BarrelSettings", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Cylinder", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/dpkg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Frameworks", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/LaunchDaemons", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/.DS_Store", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/MobileSubstrate", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/PreferenceBundles", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/Library/PreferenceLoader", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/SBInject", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/Snoverlay", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/Flame", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/CallBlocker", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/CCSupport", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/Compatimark", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/Dynastic", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/Malipo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/SafariPlus.bundle", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/Activator", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/Cylinder", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/Barrel", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/BarrelSettings", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/libGitHubIssues/", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Themes", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/TweakInject", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Zeppelin", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Flipswitch", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Switches", NULL);
        
        //////system/library
        execCmdu0("/freya/rm", "-rdvf", "/System/Library/PreferenceBundles/AppList.bundle", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/System/Library/Themes", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/System/Library/Internet\ Plug-Ins", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/System/Library/KeyboardDictionaries", NULL);
        
        /////root
        
        execCmdu0("/freya/rm", "-rdvf", "/FELICITYICON.png", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bootstrap", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/mnt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/lib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/boot", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/libexec", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/include", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/mnt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/jb", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/games", NULL);
        //////////////USR/LIBRARY
        execCmdu0("/freya/rm", "-rdvf", "/usr/Library", NULL);
        
        ///////////PRIVATE
        execCmdu0("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
        ///
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/killall", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/reboot", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/.bootstrapped_Th0r", NULL);
        
        
        execCmdu0("/freya/rm", "-rf", "/Library/test_inject_springboard.cy", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/SBInject.dylib", NULL);
        ////usr/local files and folders cleanup
        execCmdu0("/freya/rm", "-rdvf", "/usr/local/lib", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libsparkapplist.dylib", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcrashreport.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libsymbolicate.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/TweakInject.dylib", NULL);
        //////ROOT FILES :(
        execCmdu0("/freya/rm", "-rdvf", "/.bootstrapped_electra", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/.cydia_no_stash", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/.bit_of_fun", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/RWTEST", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/pwnedWritefileatrootTEST", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
        
        
        ////////// BIN/
        execCmdu0("/freya/rm", "-rdvf", "/bin/bashbug", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/bunzip2", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/bzcat", NULL);
        unlink("usr/bin/bzcat");
        execCmdu0("/freya/rm", "-rdvf", "/bin/bzip2", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/bzip2recover", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/bzip2_64", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/cat", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/chgrp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/chmod", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/chown", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/cp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/date", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/dd", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/dir", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/echo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/egrep", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/false", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/fgrep", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/grep", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/gzip", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/gtar", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/gunzip", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/gzexe", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/hostname", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/launchctl", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/ln", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/ls", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/jtoold", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/kill", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/mkdir", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/mknod", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/mv", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/mktemp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/pwd", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/bin/rmdir", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/readlink", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/unlink", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/run-parts", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/su", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/sync", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/stty", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/sh", NULL);
        unlink("/bin/sh");
        
        execCmdu0("/freya/rm", "-rdvf", "/bin/sleep", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/sed", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/su", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/tar", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/touch", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/true", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/uname", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/vdr", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/vdir", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/uncompress", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/znew", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/zegrep", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/zmore", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/zdiff", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/zcat", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/zcmp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/zfgrep", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/zforce", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/zless", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/zgrep", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/zegrep", NULL);
        
        //////////SBIN
        execCmdu0("/freya/rm", "-rdvf", "/sbin/reboot", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/halt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/ifconfig", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/kextunload", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/ping", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/update_dyld_shared_cache", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/dmesg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/dynamic_pager", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/nologin", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/fstyp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/fstyp_msdos", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/fstyp_ntfs", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/fstyp_udf", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/mount_devfs", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/mount_fdesc", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/quotacheck", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/umount", NULL);
        
        
        /////usr/bin files folders cleanup
        //symbols
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/[", NULL);
        //a
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ADMHelper", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/arch", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/apt", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ar", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/apt-key", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/apt-cache", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/apt-cdrom", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/apt-config", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/apt-extracttemplates", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/apt-ftparchive", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/apt-sortpkgs", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/apt-mark", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/apt-get", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/arch", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/asu_inject", NULL);
        
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/asn1Coding", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/asn1Decoding", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/asn1Parser", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/autopoint", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/as", NULL);
        //b
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/bashbug", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/b2sum", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/base32", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/base64", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/basename", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/bitcode_strip", NULL);
        //c
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/CallLogPro", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/com.julioverne.ext3nder-installer", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/chown", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/chmod", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/chroot", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/chcon", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/chpass", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/check_dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/checksyms", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/chfn", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/chsh", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/cksum", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/comm", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/cmpdylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/codesign_allocate", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/csplit", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ctf_insert", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/cut", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/curl", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/curl-config", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/c_rehash", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/captoinfo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/certtool", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/cfversion", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/clear", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/cmp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/cydown", NULL);//cydown
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/cydown.arch_arm64", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/cydown.arch_armv7", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/cycript", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/cycc", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/cynject", NULL);
        //d
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dbclient", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/db_archive", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/db_checkpoint", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/db_deadlock", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/db_dump", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/db_hotbackup", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/db_load", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/db_log_verify", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/db_printlog", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/db_recover", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/db_replicate", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/db_sql_codegen", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/db_stat", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/db_tuner", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/db_upgrade", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/db_verify", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dbsql", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/debugserver", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/defaults", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/df", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/diff", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/diff3", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dirname", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dircolors", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dirmngr", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dirmngr-client", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-architecture", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-buildflags", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-buildpackage", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-checkbuilddeps", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-deb", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-distaddfile", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-divert", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-genbuildinfo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-genchanges", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-gencontrol", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-gensymbols", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-maintscript-helper", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-mergechangelogs", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-name", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-parsechangelog", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-query", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-scanpackages", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-scansources", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-shlibdeps", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-source", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-split", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-statoverride", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-trigger", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dpkg-vendor", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/du", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dumpsexp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dselect", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dsymutil", NULL);
        ////e
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/expand", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/expr", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/env", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/envsubst", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ecidecid", NULL);
        //f
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/factor", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/filemon", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/Filza", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/fmt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/fold", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/funzip", NULL);
        //g
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/games", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/getconf", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/getty", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gettext", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gettext.sh", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gettextize", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/git", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/git-cvsserver", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/git-recieve-pack", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/git-shell", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/git-upload-pack", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gitk", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gnutar", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gnutls-cli", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gnutls-cli-debug", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gnutls-serv", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gpg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gpgrt-config", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gpg-zip", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gpgsplit", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gpgv", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gssc", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/groups", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gpg-agent", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gpg-connect-agent ", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gpg-error", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gpg-error-config", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gpg2", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gpgconf", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gpgparsemail", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gpgscm", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gpgsm", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gpgtar", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gpgv2", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/groups", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/gtar", NULL);
        //h
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/head", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/hmac256", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/hostid", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/hostinfo", NULL);
        //i
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/install", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/id", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/idn2", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/indr", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/inout", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/infocmp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/infotocap", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/iomfsetgamma", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/install_name_tool", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/libtool", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/lipo", NULL);
        //j
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/join", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/jtool", NULL);
        //k
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/killall", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/kbxutil", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ksba-config", NULL);
        //l
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/less", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/libassuan-config", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/libgcrypt-config", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/link", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ldid", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ldid2", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ldrestart", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/locate", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/login", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/logname", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/lzcat", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/lz4", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/lz4c", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/lz4cat", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/lzcmp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/lzdiff", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/lzegrep", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/lzfgrep", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/lzgrep", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/lzless", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/lzma", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/lzmadec", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/lzmainfo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/lzmore", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin.lipo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/lipo", NULL);
        
        //m
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/md5sum", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/mkfifo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/mktemp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/more", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/msgattrib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/msgcat", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/msgcmp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/msgcomm", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/msgconv", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/msgen", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/msgexec", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/msgfilter", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/msgfmt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/msggrep", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/msginit", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/msgmerge", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/msgunfmt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/msguniq", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/mpicalc", NULL);
        //n
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/nano", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/nettle-hash", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/nettle-lfib-stream", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/nettle-pbkdf2", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ngettext", NULL);
        
        
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/nm", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/nmedit", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/nice", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/nl", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/nohup", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/nproc", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/npth-config", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/numfmt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ncurses6-config", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ncursesw6-config", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ncursesw5-config", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ncurses5-config", NULL);
        //o
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/od", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ocsptool", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ObjectDump", NULL);//ld64
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/dyldinfo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ld", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/machocheck", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/unwinddump", NULL);//ld64 done
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/otool", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/openssl", NULL);
        //p
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/pincrush", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/pagestuff", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/pagesize", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/passwd", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/paste", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/pathchk", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/pinky", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/plconvert", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/pr", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/printenv", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/printf", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/procexp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ptx", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/p11-kit", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/p11tool", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/pkcs1-conv", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/psktool", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/quota", NULL);
        
        
        //r
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/renice", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ranlib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/redo_prebinding", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/reprovisiond", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/reset", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/realpath", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/rnano", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/runcon", NULL);
        //s
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/snapUtil", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/sbdidlaunch", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/sbreload", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/script", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/sdiff", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/seq", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/sexp-conv", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/seg_addr_table", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/seg_hack", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/segedit", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/sftp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/shred", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/shuf", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/sort", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ssh", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ssh-add", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ssh-agent", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ssh-keygen", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/ssh-keyscan", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/sw_vers", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/seq", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/SemiRestore11-Lite", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/sha1sum", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/sha224sum", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/sha256sum", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/sha384sum", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/sha512sum", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/shred", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/shuf", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/size", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/split", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/srptool", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/stat", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/stdbuf", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/strings", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/strip", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/sum", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/sync", NULL);
        //t
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/tabs", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/tac", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/tar", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/tail", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/tee", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/test", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/tic", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/time", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/timeout", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/toe", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/tput", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/tr", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/tset", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/truncate", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/trust", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/tsort", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/tty", NULL);
        //u
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/uiduid", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/uuid", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/uuid-config", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/uiopen", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/unlz4", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/unlzma", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/unxz", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/update-alternatives", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/updatedb", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/unexpand", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/uniq", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/unzip", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/unzipsfx", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/unrar", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/uptime", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/users", NULL);
        //w
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/watchgnupg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/wc", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/wget", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/which", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/who", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/whoami", NULL);
        //x
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/xargs", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/xz", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/xgettext", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/xzcat", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/xzcmp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/xzdec", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/xzdiff", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/xzegrep", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/xzfgrep", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/xzgrep", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/xzless", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/xzmore", NULL);
        //y
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/yat2m", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/yes", NULL);
        //z
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/zip", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/zipcloak", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/zipnote", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/zipsplit", NULL);
        //numbers
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/7z", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/7za", NULL);
        //////////////
        ////
        //////////USR/SBIN
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/chown", NULL);
        
        unlink("/usr/sbin/chown");
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/chmod", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/chroot", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/dev_mkdb", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/edquota", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/applygnupgdefaults", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/fdisk", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/halt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/sshd", NULL);
        
        //////////////USR/LIB
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/xxxMobileGestalt.dylib", NULL);//for cydown
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/xxxSystem.dylib", NULL);//for cydown
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcolorpicker.dylib", NULL);//
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcrypto.dylib", NULL);//
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcrypto.a", NULL);//
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libdb_sql-6.2.dylib", NULL);//
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libdb_sql-6.dylib", NULL);//
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libdb_sql.dylib", NULL);//
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libdb-6.2.dylib", NULL);//
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libdb-6.dylib", NULL);//
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libdb.dylib", NULL);//
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/liblzma.a", NULL);//
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/liblzma.la", NULL);//
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libprefs.dylib", NULL);//
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libssl.a", NULL);//
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libssl.dylib", NULL);//
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libST.dylib", NULL);//
        //////////////////
        //////////////8
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpam.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpamc.1.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6.0", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpanelw.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.2.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libreadline.6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpanel.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcurses.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhistory.6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libformw.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncursesw.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhistory.6.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libform.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpanelw.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libmenuw.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/terminfo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpam.1.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libmenu.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpatcyh.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libreadline.6.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncurses.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhistory.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpamc.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libformw.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1.0", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpanel.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.0.0.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/_ncurses", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpam_misc.1.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.2.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpam_misc.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libreadline.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libmenuw.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpam.1.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libmenu.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncursesw.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcycript.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcycript.jar", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libdpkg.a", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcrypto.1.0.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libssl.1.0.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcycript.db", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcurl.4.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcycript.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcycript.cy", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libdpkg.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libswift", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libsubstrate.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libuuid.16.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libuuid.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libtapi.dylib", NULL);//ld64
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libnghttp2.14.dylib", NULL);//ld64
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libnghttp2.dylib", NULL);//ld64
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libnghttp2.la", NULL);//ld64
        ///sauirks new substrate
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/substrate", NULL);//ld64
        
        //////////USR/SBIN
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/accton", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/vifs", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/ac", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/update", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/pwd_mkdb", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/sysctl", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/zdump", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/startupfiletool", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/iostat", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/nologin", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/mkfile", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/quotaon", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/repquota", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/zic", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/vipw", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/vsdbutil", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/start-stop-daemon", NULL);
        ////////USR/LOCAL
        execCmdu0("/freya/rm", "-rdvf", "/usr/local/lib/libluajit.a", NULL);
        //////LIBRARY
        execCmdu0("/freya/rm", "-rdvf", "/Library/test_inject_springboard.cy", NULL);
        //////sbin folder files cleanup
        execCmdu0("/freya/rm", "-rdvf", "/sbin/dmesg", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/sbin/cat", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/sbin/zshrc", NULL);
        ////usr/sbin files
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/start-start-daemon", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/accton", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/addgnupghome", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/vifs", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/ac", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/update", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/sysctl", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/zdump", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/startupfiletool", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/iostat", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/mkfile", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/zic", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/sbin/vipw", NULL);
        ////usr/libexec files
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/_rocketd_reenable", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/rocketd", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/MSUnrestrictProcess", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/substrate", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/libexec/substrated", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/applist.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapplist.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhAcxTools.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhAcxTools2.dylib", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libflipswitch.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.1.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-private.0.0.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-private.0.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libassuan.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libassuan.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libassuan.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libnpth.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libnpth.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libnpth.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libgpg-error.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libksba.8.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libksba.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libksba.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/cycript0.9", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpam.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpamc.1.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpackageinfo.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/librocketbootstrap.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6.0", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpanelw.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhistory.5.2.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libreadline.6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpanel.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcurses.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhistory.6.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libformw.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncursesw.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhistory.6.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libform.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpanelw.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libmenuw.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/terminfo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/terminfo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpam.1.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libmenu.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpatcyh.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libreadline.6.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncurses.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhistory.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpamc.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libformw.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1.0", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpanel.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.0.0.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/_ncurses", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpam_misc.1.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libreadline.5.2.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpam_misc.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libreadline.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libmenuw.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libpam.1.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libmenu.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/liblzmadec.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncursesw.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcycript.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcycript.jar", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcycript.db", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcurl.4.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcurl.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcurl.la", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcycript.0.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcycript.cy", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcephei.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libcepheiprefs.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhbangcommon.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libhbangprefs.dylib", NULL);
        /////end it
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libjailbreak.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/profile", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/motd", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/log/testbin.log", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/log/apt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/log/jailbreakd-stderr.log", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/log/jailbreakd-stdout.log", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/test_inject_springboard.cy", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/local/lib/libluajit.a", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/bin/zsh", NULL);
        //missing from removeMe.sh oddly
        //////mine above lol
        //////////////////Jakes below
        
        execCmdu0("/freya/rm", "-rdvf", "/var/LIB", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/bin", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/sbin", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/profile", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/motd", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/dropbear", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/containers/Bundle/tweaksupport", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/containers/Bundle/iosbinpack64", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/containers/Bundle/dylibs", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/LIB", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/motd", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/log/testbin.log", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/log/jailbreakd-stdout.log", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/log/jailbreakd-stderr.log", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/bin/find", NULL);
        
        
        
        
        
        
        execCmdu0("/freya/rm", "-rdvf", "/var/cache", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/freya", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/lib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/stash", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/db/stash", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/mobile/Library/Cydia", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/etc/apt/sources.list.d", NULL);
                     
        execCmdu0("/freya/rm", "-rdvf", "/etc/apt/sources.list", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/apt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/alternatives", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/default", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/dpkg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/dropbear", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/localtime", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/motd", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/pam.d", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/profile", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/pkcs11", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/profile.d", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/profile.ro", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/rc.d", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/resolv.conf", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/ssh", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/ssl", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/sudo.conf", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/sudoers", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/sudoers.d", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/sudoers.dist", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/wgetrc", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/zshrc", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/etc/zprofile", NULL);
        
        execCmdu0("/freya/rm", "-rdvf", "/private/private", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/containers/Bundle/dylibs", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/containers/Bundle/iosbinpack64", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/containers/Bundle/tweaksupport", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/log/suckmyd-stderr.log", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/log/suckmyd-stdout.log", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/log/jailbreakd-stderr.log", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/log/jailbreakd-stdout.log", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/backups", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/empty", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/bin", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/cache", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/db/stash", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/db/sudo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/dropbear", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/lib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/var/lib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/LIB", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/local", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/log/apt", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/log/dpkg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/log/testbin.log", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/lock", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cr4shed", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT4", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Logs/Cydia", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Sileo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Toonsy", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Widgets", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/AmyCache", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/org.coolstar.SileoStore", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/motd", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/profile", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/run/sudo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/sbin", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/spool", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/tweak", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/private/var/unlimapps_tweak_resources", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Alkaline", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Activator", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/Snoverlay", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/Flame", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/CallBlocker", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/CCSupport", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/Compatimark", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/Malipo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/SafariPlus.bundle", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/Activator", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/Cylinder", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/Barrel", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/BarrelSettings", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Application\ Support/libGitHubIssues", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Barrel", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/BarrelSettings", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Cylinder", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/dpkg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Flipswitch", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Frameworks", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/LaunchDaemons", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/MobileSubstrate", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/MobileSubstrate/", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/MobileSubstrate/DynamicLibraries", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/PreferenceBundles", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/PreferenceLoader", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/SBInject", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Switches", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/test_inject_springboard.cy", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Themes", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/TweakInject", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/Zeppelin", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/Library/.DS_Store", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/System/Library/PreferenceBundles/AppList.bundle", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/System/Library/Themes", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/System/Library/KeyboardDictionaries", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/libresolv.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/lib/liblzma.dylib", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/include", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/aclocal", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/bigboss", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/share/common-lisp", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/dict", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/dpkg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/git-core", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/git-gui", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/gnupg", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/gitk", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/gitweb", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/libgpg-error", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/man", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/p11-kit", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/tabset", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/usr/share/terminfo", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/.freya_installed", NULL);
        execCmdu0("/freya/rm", "-rdvf", "/.freya_bootstrap", NULL);
        
        
        
        ////////
    }
    //////////////////////////////
    //////////////////////////////finally added the check for changing remvoving files without needing two separate apps
    
    else if (/* iOS 11.3 and higher can use lucky snapshot */ kCFCoreFoundationVersionNumber > 1451.51){ printf("[*] Removing Jailbreak for ios 11.3 - 11.4 beta 1-3 devices..\n");
        int testexec = execCmdu0("/freya/rm", "-rdvf", "/private/etc/apt", NULL);//execCmdu0("/freya/rm", "-rdvf", "/Applications/Cydia.app", NULL);
        if (testexec == 0) { 
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/motd", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/profile", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/rc.d", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/rc.d/substrate", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/etc/zshrc", NULL);
            ////usr/etc//
            execCmdu0("/freya/rm", "-rdvf", "/var/backups", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/containers/Bundle/iosbinpack64", NULL);
            ////etc folder cleanup
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/pam.d", NULL);
            //private/etc
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/apt", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/dropbear", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/alternatives", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/default", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/dpkg", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/ssh", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/ssl", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/profile.d", NULL);
            ////private/var
            execCmdu0("/freya/rm", "-rdvf", "/private/var/cache", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/lib", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/local", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/lock", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/spool", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/lib/apt", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/lib/cydia", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/cache/apt", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/db/stash", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/stash", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/tweak", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
            //var/mobile/Library
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia/", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
            //var/mobile/Library/Caches
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
            //snapshot.library
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
            unlink("/private/etc/apt/sources.list.d/cydia.list");
            unlink("/private/etc/apt");
            //////system/library
            execCmdu0("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/profile", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/motd", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/log/testbin.log", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/log/apt", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/log/jailbreakd-stderr.log", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/log/jailbreakd-stdout.log", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/LIB", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/bin", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/sbin", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/profile", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/motd", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/dropbear", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/containers/Bundle/tweaksupport", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/containers/Bundle/iosbinpack64", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/containers/Bundle/dylibs", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/LIB", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/motd", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/log/testbin.log", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/log/jailbreakd-stdout.log", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/log/jailbreakd-stderr.log", NULL);
            
            
            execCmdu0("/freya/rm", "-rdvf", "/var/cache", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/freya", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/lib", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/stash", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/db/stash", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/mobile/Library/Cydia", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/etc/apt/sources.list.d", NULL);
                         
            execCmdu0("/freya/rm", "-rdvf", "/etc/apt/sources.list", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/apt", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/alternatives", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/default", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/dpkg", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/dropbear", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/localtime", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/motd", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/pam.d", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/profile", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/pkcs11", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/profile.d", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/profile.ro", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/rc.d", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/resolv.conf", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/ssh", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/ssl", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/sudo.conf", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/sudoers", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/sudoers.d", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/sudoers.dist", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/wgetrc", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/zshrc", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/etc/zprofile", NULL);
            
            execCmdu0("/freya/rm", "-rdvf", "/private/private", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/containers/Bundle/dylibs", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/containers/Bundle/iosbinpack64", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/containers/Bundle/tweaksupport", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/log/suckmyd-stderr.log", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/log/suckmyd-stdout.log", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/log/jailbreakd-stderr.log", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/log/jailbreakd-stdout.log", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/backups", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/empty", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/bin", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/cache", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/db/stash", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/db/sudo", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/dropbear", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/lib", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/var/lib", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/LIB", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/local", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/log/apt", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/log/dpkg", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/log/testbin.log", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/lock", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cr4shed", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT4", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Logs/Cydia", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Sileo", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Toonsy", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Widgets", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/AmyCache", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/org.coolstar.SileoStore", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/motd", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/profile", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/run/utmp", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/run/sudo", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/sbin", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/spool", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/tweak", NULL);
            execCmdu0("/freya/rm", "-rdvf", "/private/var/unlimapps_tweak_resources", NULL);

            
        }
        else {
            printf("FAILED TO REMOVE WITH RM FREYA\n");
        }
    }
}
