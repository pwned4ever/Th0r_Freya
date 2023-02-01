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
    
    execCmdCh("/bin/rm", "-rdvf", "/electra/launchctl", NULL);
    execCmdCh("/bin/rm", "-rdvf", "/var/mobile/Media/.bootstrapped_electraremover", NULL);
    execCmdCh("/bin/rm", "-rdvf", "/var/mobile/testremover.txt", NULL);
    unlink("/var/mobile/testremover.txt");
    execCmdCh("/bin/rm", "-rdvf", "/.bootstrapped_Th0r", NULL);
    execCmdCh("/bin/rm", "-rdvf", "/.freya_installed", NULL);
    execCmdCh("/bin/rm", "-rdvf", "/.bootstrapped_electra", NULL);
    execCmdCh("/bin/rm", "-rdvf", "/.installed_unc0ver", NULL);
    execCmdCh("/bin/rm", "-rdvf", "/.install_unc0ver", NULL);
    execCmdCh("/bin/rm", "-rdvf", "/.electra_no_snapshot", NULL);
    execCmdCh("/bin/rm", "-rdvf", "/.installed_unc0vered", NULL);
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
        
        
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/motd", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/.cydia_no_stash", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/Applications/Cydia.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Network", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/aclocal", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/bigboss", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/common-lisp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/dict", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/dpkg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/gnupg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/libgpg-error", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/p11-kit", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/tabset", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/terminfo", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/local/bin", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/local/lib", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/authorize.sh", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/.cydia_no_stash", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/zsh", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/profile", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/rc.d", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/rc.d/substrate", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/etc/zshrc", NULL);
        ////usr/etc//
        execCmdCh("/bin/rm", "-rdvf", "/usr/etc", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/scp", NULL);
        ////usr/lib////
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/_ncurses", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/apt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/bash", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/gettext", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.1.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-private.0.0.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-private.0.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libasprintf.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libasprintf.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libassuan.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libassuan.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libassuan.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libdpkg.a", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libform.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libform.6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libform5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libformw.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libformw.6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libformw.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libformw5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgcrypt.20.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgcrypt.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgcrypt.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgettextlib-0.19.8.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgettextlib.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgettextpo.1.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgettextpo.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgettextsrc-0.19.8.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgettextsrc.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgmp.10.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgmp.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgmp.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgnutls.30.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgnutls.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgnutlsxx.28.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgnutlsxx.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgpg-error.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgpg-error.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgpg-error.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhistory.5.2.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhistory.6.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhistory.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhistory.7.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhistory.7.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhistory.dylib ", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhogweed.4.4.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhogweed.4.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhogweed.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libidn2.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libidn2.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libidn2.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libintl.9.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libintl.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libksba.8.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libksba.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libksba.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/liblz4.1.7.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/liblz4.1.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/liblz4.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libmenu.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libmenu.6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libmenu.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libmenu5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libmenuw.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libmenuw.6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libmenuw.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libmenuw5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncurses.6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncurses5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncurses6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncursesw.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncursesw.6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncursesw.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncursesw5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncursesw6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libnettle.6.4.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libnettle.6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libnettle.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libnpth.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libnpth.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libnpth.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libp11-kit.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libp11-kit.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libp11-kit.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpanel.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpanel.6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpanel.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpanel5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpanelw.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpanelw.6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpanelw.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpanelw5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libreadline.5.2.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libreadline.6.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libreadline.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libreadline.7.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libreadline.7.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libreadline.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libresolv.9.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libresolv.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libtasn1.6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libtasn1.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libtasn1.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libunistring.2.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libunistring.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libunistring.la", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libsubstitute.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libsubstitute.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libsubstrate.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libjailbreak.dylib", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/recode-sr-latin", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/recache", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/rollectra", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/Rollectra", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/killall", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/sftp-server", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/SBInject.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/zsh", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/electra-prejailbreak", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/electra/createSnapshot", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/jb", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/jb", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/backups", NULL);
        ////////////Applications cleanup and root
        execCmdCh("/bin/rm", "-rdvf", "/RWTEST", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/pwnedWritefileatrootTEST", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/Cydia\ Update\ Helper.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/NETWORK", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/AppCake.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/Activator.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/Anemone.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/BestCallerId.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/CrackTool3.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/Cydia.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/Sileo.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/Rollectra.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/cydown.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/Cylinder.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/iCleaner.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/icleaner.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/BarrelSettings.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/Ext3nder.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/Filza.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/Flex.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/GBA4iOS.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/jjjj.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/ReProvision.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/SafeMode.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/NewTerm.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/MobileTerminal.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/MTerminal.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/MovieBox3.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/BobbyMovie.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/PopcornTime.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/RST.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/TSSSaver.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/CertRemainTime.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/CrashReporter.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/AudioRecorder.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/ADManager.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/CocoaTop.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/calleridfaker.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/CallLogPro.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/WiFiPasswords.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/WifiPasswordList.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/calleridfaker.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/ClassDumpGUI.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/idevicewallsapp.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/UDIDFaker.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/UDIDCalculator.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/CallRecorder.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/Rehosts.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/NGXCarPlay.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/Audicy.app", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Applications/NGXCarplay.app", NULL);
        ///////////USR/LIBEXEC
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/as", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/frcode", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/bigram", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/code", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/reload", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/rmt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/MSUnrestrictProcess", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/perl5", NULL);
        //////////USR/SHARE
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/git-core", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/git-gui", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/gitk", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/gitweb", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/man", NULL);
        ////////USR/LOCAL
        execCmdCh("/bin/rm", "-rdvf", "/usr/local/bin", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/local/lib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/local/lib/libluajit.a", NULL);
        
        ////var
        execCmdCh("/bin/rm", "-rdvf", "/var/containers/Bundle/iosbinpack64", NULL);
        ////etc folder cleanup
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/pam.d", NULL);
        
        //private/etc
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/apt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/dropbear", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/alternatives", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/default", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/dpkg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/ssh", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/ssl", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/profile.d", NULL);
        
        ////private/var
        
        execCmdCh("/bin/rm", "-rdvf", "/private/var/cache", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/lib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/local", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/lock", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/spool", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/lib/apt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/lib/cydia", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/cache/apt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/db/stash", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/stash", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/tweak", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
        //var/mobile/Library
        
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia/", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
        
        //var/mobile/Library/Caches
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
        
        //snapshot.library
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/run/utmp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
        unlink("/private/etc/apt/sources.list.d/cydia.list");
        unlink("/private/etc/apt");
        
        ////usr/include files
        execCmdCh("/bin/rm", "-rdvf", "/usr/include", NULL);
        ////usr/local files
        execCmdCh("/bin/rm", "-rdvf", "/usr/local/bin", NULL);
        ////usr/libexec files
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/apt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/ssh-pkcs11-helper", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/ssh-keysign", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/cydia", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/dpkg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/gnupg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/gpg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/gpg-check-pattern", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/gpg-preset-passphrase", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/gpg-protect-tool", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/gpg-wks-client", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/git-core", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/p11-kit", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/scdaemon", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/vndevice", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/frcode", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/bigram", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/code", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/coreutils", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/reload", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/rmt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/filza", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/sudo", NULL);
        ////usr/lib files
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/TweakInject", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/tweakloader.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/pspawn_hook.dylib", NULL);
        unlink("/usr/lib/pspawn_hook.dylib");
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/tweaks", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/Activator", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/apt", NULL);
        
        unlink("/usr/lib/apt");
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/dpkg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/pam", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/p11-kit.0.dylib", NULL);
        unlink("/usr/lib/p11-kit-proxy.dylib");
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/p11-kit-proxy.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/pkcs11", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/pam", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/pkgconfig", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/ssl", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/bash", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/gettext", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/coreutils", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/engines", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/p7zip", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/Cephei.framework", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/CepheiPrefs.framework", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/SBInject", NULL);
        //usr/local
        execCmdCh("/bin/rm", "-rdvf", "/usr/local/bin", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/local/lib", NULL);
        ////library folder files and subfolders
        execCmdCh("/bin/rm", "-rdvf", "/Library/Alkaline", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Activator", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Barrel", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/BarrelSettings", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Cylinder", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/dpkg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Frameworks", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/LaunchDaemons", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/.DS_Store", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/MobileSubstrate", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/PreferenceBundles", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/Library/PreferenceLoader", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/SBInject", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/Snoverlay", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/Flame", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/CallBlocker", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/CCSupport", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/Compatimark", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/Dynastic", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/Malipo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/SafariPlus.bundle", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/Activator", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/Cylinder", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/Barrel", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/BarrelSettings", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/libGitHubIssues/", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Themes", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/TweakInject", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Zeppelin", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Flipswitch", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Switches", NULL);
        
        //////system/library
        execCmdCh("/bin/rm", "-rdvf", "/System/Library/PreferenceBundles/AppList.bundle", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/System/Library/Themes", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/System/Library/Internet\ Plug-Ins", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/System/Library/KeyboardDictionaries", NULL);
        
        /////root
        
        execCmdCh("/bin/rm", "-rdvf", "/FELICITYICON.png", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bootstrap", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/mnt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/lib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/boot", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/libexec", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/include", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/mnt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/jb", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/games", NULL);
        //////////////USR/LIBRARY
        execCmdCh("/bin/rm", "-rdvf", "/usr/Library", NULL);
        
        ///////////PRIVATE
        execCmdCh("/bin/rm", "-rdvf", "/private/var/run/utmp", NULL);
        ///
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/killall", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/reboot", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/.bootstrapped_Th0r", NULL);
        
        
        execCmdCh("/bin/rm", "-rf", "/Library/test_inject_springboard.cy", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/SBInject.dylib", NULL);
        ////usr/local files and folders cleanup
        execCmdCh("/bin/rm", "-rdvf", "/usr/local/lib", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libsparkapplist.dylib", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcrashreport.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libsymbolicate.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/TweakInject.dylib", NULL);
        //////ROOT FILES :(
        execCmdCh("/bin/rm", "-rdvf", "/.bootstrapped_electra", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/.cydia_no_stash", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/.bit_of_fun", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/RWTEST", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/pwnedWritefileatrootTEST", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
        
        
        ////////// BIN/
        execCmdCh("/bin/rm", "-rdvf", "/bin/bashbug", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/bunzip2", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/bzcat", NULL);
        unlink("usr/bin/bzcat");
        execCmdCh("/bin/rm", "-rdvf", "/bin/bzip2", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/bzip2recover", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/bzip2_64", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/cat", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/chgrp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/chmod", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/chown", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/cp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/date", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/dd", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/dir", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/echo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/egrep", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/false", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/fgrep", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/grep", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/gzip", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/gtar", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/gunzip", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/gzexe", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/hostname", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/launchctl", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/ln", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/ls", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/jtoold", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/kill", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/mkdir", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/mknod", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/mv", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/mktemp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/pwd", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/bin/rmdir", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/readlink", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/unlink", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/run-parts", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/su", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/sync", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/stty", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/sh", NULL);
        unlink("/bin/sh");
        
        execCmdCh("/bin/rm", "-rdvf", "/bin/sleep", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/sed", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/su", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/tar", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/touch", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/true", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/uname", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/vdr", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/vdir", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/uncompress", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/znew", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/zegrep", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/zmore", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/zdiff", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/zcat", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/zcmp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/zfgrep", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/zforce", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/zless", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/zgrep", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/zegrep", NULL);
        
        //////////SBIN
        execCmdCh("/bin/rm", "-rdvf", "/sbin/reboot", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/halt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/ifconfig", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/kextunload", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/ping", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/update_dyld_shared_cache", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/dmesg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/dynamic_pager", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/nologin", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/fstyp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/fstyp_msdos", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/fstyp_ntfs", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/fstyp_udf", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/mount_devfs", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/mount_fdesc", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/quotacheck", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/umount", NULL);
        
        
        /////usr/bin files folders cleanup
        //symbols
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/[", NULL);
        //a
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ADMHelper", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/arch", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/apt", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ar", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/apt-key", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/apt-cache", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/apt-cdrom", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/apt-config", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/apt-extracttemplates", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/apt-ftparchive", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/apt-sortpkgs", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/apt-mark", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/apt-get", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/arch", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/asu_inject", NULL);
        
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/asn1Coding", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/asn1Decoding", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/asn1Parser", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/autopoint", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/as", NULL);
        //b
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/bashbug", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/b2sum", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/base32", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/base64", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/basename", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/bitcode_strip", NULL);
        //c
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/CallLogPro", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/com.julioverne.ext3nder-installer", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/chown", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/chmod", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/chroot", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/chcon", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/chpass", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/check_dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/checksyms", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/chfn", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/chsh", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/cksum", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/comm", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/cmpdylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/codesign_allocate", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/csplit", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ctf_insert", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/cut", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/curl", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/curl-config", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/c_rehash", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/captoinfo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/certtool", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/cfversion", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/clear", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/cmp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/cydown", NULL);//cydown
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/cydown.arch_arm64", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/cydown.arch_armv7", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/cycript", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/cycc", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/cynject", NULL);
        //d
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dbclient", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/db_archive", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/db_checkpoint", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/db_deadlock", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/db_dump", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/db_hotbackup", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/db_load", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/db_log_verify", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/db_printlog", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/db_recover", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/db_replicate", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/db_sql_codegen", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/db_stat", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/db_tuner", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/db_upgrade", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/db_verify", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dbsql", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/debugserver", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/defaults", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/df", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/diff", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/diff3", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dirname", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dircolors", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dirmngr", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dirmngr-client", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-architecture", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-buildflags", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-buildpackage", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-checkbuilddeps", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-deb", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-distaddfile", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-divert", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-genbuildinfo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-genchanges", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-gencontrol", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-gensymbols", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-maintscript-helper", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-mergechangelogs", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-name", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-parsechangelog", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-query", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-scanpackages", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-scansources", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-shlibdeps", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-source", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-split", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-statoverride", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-trigger", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dpkg-vendor", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/du", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dumpsexp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dselect", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dsymutil", NULL);
        ////e
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/expand", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/expr", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/env", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/envsubst", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ecidecid", NULL);
        //f
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/factor", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/filemon", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/Filza", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/fmt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/fold", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/funzip", NULL);
        //g
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/games", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/getconf", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/getty", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gettext", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gettext.sh", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gettextize", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/git", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/git-cvsserver", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/git-recieve-pack", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/git-shell", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/git-upload-pack", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gitk", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gnutar", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gnutls-cli", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gnutls-cli-debug", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gnutls-serv", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gpg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gpgrt-config", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gpg-zip", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gpgsplit", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gpgv", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gssc", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/groups", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gpg-agent", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gpg-connect-agent ", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gpg-error", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gpg-error-config", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gpg2", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gpgconf", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gpgparsemail", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gpgscm", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gpgsm", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gpgtar", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gpgv2", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/groups", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/gtar", NULL);
        //h
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/head", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/hmac256", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/hostid", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/hostinfo", NULL);
        //i
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/install", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/id", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/idn2", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/indr", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/inout", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/infocmp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/infotocap", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/iomfsetgamma", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/install_name_tool", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/libtool", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/lipo", NULL);
        //j
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/join", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/jtool", NULL);
        //k
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/killall", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/kbxutil", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ksba-config", NULL);
        //l
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/less", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/libassuan-config", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/libgcrypt-config", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/link", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ldid", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ldid2", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ldrestart", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/locate", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/login", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/logname", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/lzcat", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/lz4", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/lz4c", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/lz4cat", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/lzcmp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/lzdiff", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/lzegrep", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/lzfgrep", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/lzgrep", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/lzless", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/lzma", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/lzmadec", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/lzmainfo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/lzmore", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin.lipo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/lipo", NULL);
        
        //m
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/md5sum", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/mkfifo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/mktemp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/more", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/msgattrib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/msgcat", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/msgcmp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/msgcomm", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/msgconv", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/msgen", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/msgexec", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/msgfilter", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/msgfmt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/msggrep", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/msginit", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/msgmerge", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/msgunfmt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/msguniq", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/mpicalc", NULL);
        //n
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/nano", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/nettle-hash", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/nettle-lfib-stream", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/nettle-pbkdf2", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ngettext", NULL);
        
        
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/nm", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/nmedit", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/nice", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/nl", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/nohup", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/nproc", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/npth-config", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/numfmt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ncurses6-config", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ncursesw6-config", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ncursesw5-config", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ncurses5-config", NULL);
        //o
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/od", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ocsptool", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ObjectDump", NULL);//ld64
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/dyldinfo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ld", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/machocheck", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/unwinddump", NULL);//ld64 done
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/otool", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/openssl", NULL);
        //p
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/pincrush", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/pagestuff", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/pagesize", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/passwd", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/paste", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/pathchk", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/pinky", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/plconvert", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/pr", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/printenv", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/printf", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/procexp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ptx", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/p11-kit", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/p11tool", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/pkcs1-conv", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/psktool", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/quota", NULL);
        
        
        //r
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/renice", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ranlib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/redo_prebinding", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/reprovisiond", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/reset", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/realpath", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/rnano", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/runcon", NULL);
        //s
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/snapUtil", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/sbdidlaunch", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/sbreload", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/script", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/sdiff", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/seq", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/sexp-conv", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/seg_addr_table", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/seg_hack", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/segedit", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/sftp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/shred", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/shuf", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/sort", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ssh", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ssh-add", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ssh-agent", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ssh-keygen", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/ssh-keyscan", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/sw_vers", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/seq", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/SemiRestore11-Lite", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/sha1sum", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/sha224sum", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/sha256sum", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/sha384sum", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/sha512sum", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/shred", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/shuf", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/size", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/split", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/srptool", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/stat", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/stdbuf", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/strings", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/strip", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/sum", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/sync", NULL);
        //t
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/tabs", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/tac", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/tar", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/tail", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/tee", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/test", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/tic", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/time", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/timeout", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/toe", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/tput", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/tr", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/tset", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/truncate", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/trust", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/tsort", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/tty", NULL);
        //u
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/uiduid", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/uuid", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/uuid-config", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/uiopen", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/unlz4", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/unlzma", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/unxz", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/update-alternatives", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/updatedb", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/unexpand", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/uniq", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/unzip", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/unzipsfx", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/unrar", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/uptime", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/users", NULL);
        //w
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/watchgnupg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/wc", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/wget", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/which", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/who", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/whoami", NULL);
        //x
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/xargs", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/xz", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/xgettext", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/xzcat", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/xzcmp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/xzdec", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/xzdiff", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/xzegrep", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/xzfgrep", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/xzgrep", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/xzless", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/xzmore", NULL);
        //y
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/yat2m", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/yes", NULL);
        //z
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/zip", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/zipcloak", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/zipnote", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/zipsplit", NULL);
        //numbers
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/7z", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/7za", NULL);
        //////////////
        ////
        //////////USR/SBIN
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/chown", NULL);
        
        unlink("/usr/sbin/chown");
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/chmod", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/chroot", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/dev_mkdb", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/edquota", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/applygnupgdefaults", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/fdisk", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/halt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/sshd", NULL);
        
        //////////////USR/LIB
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhistory.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/xxxMobileGestalt.dylib", NULL);//for cydown
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/xxxSystem.dylib", NULL);//for cydown
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcolorpicker.dylib", NULL);//
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcrypto.dylib", NULL);//
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcrypto.a", NULL);//
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libdb_sql-6.2.dylib", NULL);//
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libdb_sql-6.dylib", NULL);//
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libdb_sql.dylib", NULL);//
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libdb-6.2.dylib", NULL);//
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libdb-6.dylib", NULL);//
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libdb.dylib", NULL);//
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/liblzma.a", NULL);//
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/liblzma.la", NULL);//
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libprefs.dylib", NULL);//
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libssl.a", NULL);//
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libssl.dylib", NULL);//
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libST.dylib", NULL);//
        //////////////////
        //////////////8
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpam.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpamc.1.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6.0", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpanelw.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhistory.5.2.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libreadline.6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpanel.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcurses.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhistory.6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libformw.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncursesw.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libreadline.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhistory.6.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libform.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpanelw.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libmenuw.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/terminfo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpam.1.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libmenu.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpatcyh.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libreadline.6.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncurses.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhistory.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpamc.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libformw.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1.0", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpanel.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.0.0.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/_ncurses", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpam_misc.1.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libreadline.5.2.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpam_misc.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libreadline.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libmenuw.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpam.1.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libmenu.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncursesw.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcycript.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcycript.jar", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libdpkg.a", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcrypto.1.0.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libssl.1.0.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcycript.db", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcurl.4.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcycript.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcycript.cy", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libdpkg.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libswift", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libsubstrate.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libuuid.16.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libuuid.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libtapi.dylib", NULL);//ld64
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libnghttp2.14.dylib", NULL);//ld64
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libnghttp2.dylib", NULL);//ld64
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libnghttp2.la", NULL);//ld64
        ///sauirks new substrate
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/substrate", NULL);//ld64
        
        //////////USR/SBIN
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/accton", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/vifs", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/ac", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/update", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/pwd_mkdb", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/sysctl", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/zdump", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/startupfiletool", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/iostat", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/nologin", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/mkfile", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/quotaon", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/repquota", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/zic", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/vipw", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/vsdbutil", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/start-stop-daemon", NULL);
        ////////USR/LOCAL
        execCmdCh("/bin/rm", "-rdvf", "/usr/local/lib/libluajit.a", NULL);
        //////LIBRARY
        execCmdCh("/bin/rm", "-rdvf", "/Library/test_inject_springboard.cy", NULL);
        //////sbin folder files cleanup
        execCmdCh("/bin/rm", "-rdvf", "/sbin/dmesg", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/sbin/cat", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/sbin/zshrc", NULL);
        ////usr/sbin files
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/start-start-daemon", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/accton", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/addgnupghome", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/vifs", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/ac", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/update", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/sysctl", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/zdump", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/startupfiletool", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/iostat", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/mkfile", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/zic", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/sbin/vipw", NULL);
        ////usr/libexec files
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/_rocketd_reenable", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/rocketd", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/MSUnrestrictProcess", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/substrate", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/libexec/substrated", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/applist.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapplist.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhAcxTools.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhAcxTools2.dylib", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libflipswitch.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.1.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-private.0.0.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-private.0.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libassuan.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libassuan.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libassuan.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libnpth.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libnpth.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libnpth.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgpg-error.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgpg-error.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libgpg-error.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libksba.8.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libksba.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libksba.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/cycript0.9", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhistory.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpam.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpamc.1.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpackageinfo.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/librocketbootstrap.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6.0", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpanelw.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhistory.5.2.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libreadline.6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpanel.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcurses.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhistory.6.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libformw.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncursesw.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libreadline.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhistory.6.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libform.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpanelw.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libmenuw.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/terminfo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/terminfo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpam.1.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libmenu.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpatcyh.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libreadline.6.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncurses.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhistory.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpamc.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libformw.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1.0", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpanel.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.0.0.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/_ncurses", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpam_misc.1.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libreadline.5.2.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpam_misc.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libreadline.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libmenuw.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libpam.1.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libmenu.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncursesw.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcycript.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcycript.jar", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcycript.db", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcurl.4.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcurl.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcurl.la", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcycript.0.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcycript.cy", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcephei.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libcepheiprefs.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhbangcommon.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libhbangprefs.dylib", NULL);
        /////end it
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libjailbreak.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/profile", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/motd", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/log/testbin.log", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/log/apt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/log/jailbreakd-stderr.log", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/log/jailbreakd-stdout.log", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/test_inject_springboard.cy", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/local/lib/libluajit.a", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/bin/zsh", NULL);
        //missing from removeMe.sh oddly
        //////mine above lol
        //////////////////Jakes below
        
        execCmdCh("/bin/rm", "-rdvf", "/var/LIB", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/bin", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/sbin", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/profile", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/motd", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/dropbear", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/containers/Bundle/tweaksupport", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/containers/Bundle/iosbinpack64", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/containers/Bundle/dylibs", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/LIB", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/motd", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/log/testbin.log", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/log/jailbreakd-stdout.log", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/log/jailbreakd-stderr.log", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/bin/find", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/var/cache", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/freya", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/lib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/stash", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/db/stash", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/mobile/Library/Cydia", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/etc/apt/sources.list.d", NULL);
                     
        execCmdCh("/bin/rm", "-rdvf", "/etc/apt/sources.list", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/apt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/alternatives", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/default", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/dpkg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/dropbear", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/localtime", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/motd", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/pam.d", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/profile", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/pkcs11", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/profile.d", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/profile.ro", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/rc.d", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/resolv.conf", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/ssh", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/ssl", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/sudo.conf", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/sudoers", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/sudoers.d", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/sudoers.dist", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/wgetrc", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/zshrc", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/etc/zprofile", NULL);
        
        execCmdCh("/bin/rm", "-rdvf", "/private/private", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/containers/Bundle/dylibs", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/containers/Bundle/iosbinpack64", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/containers/Bundle/tweaksupport", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/log/suckmyd-stderr.log", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/log/suckmyd-stdout.log", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/log/jailbreakd-stderr.log", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/log/jailbreakd-stdout.log", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/backups", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/empty", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/bin", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/cache", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/db/stash", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/db/sudo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/dropbear", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/lib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/var/lib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/LIB", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/local", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/log/apt", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/log/dpkg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/log/testbin.log", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/lock", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Cr4shed", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/CT4", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Logs/Cydia", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Sileo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Toonsy", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Widgets", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/AmyCache", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/org.coolstar.SileoStore", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/motd", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/profile", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/run/utmp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/run/sudo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/sbin", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/spool", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/tweak", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/private/var/unlimapps_tweak_resources", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Alkaline", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Activator", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/Snoverlay", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/Flame", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/CallBlocker", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/CCSupport", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/Compatimark", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/Malipo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/SafariPlus.bundle", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/Activator", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/Cylinder", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/Barrel", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/BarrelSettings", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Application\ Support/libGitHubIssues", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Barrel", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/BarrelSettings", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Cylinder", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/dpkg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Flipswitch", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Frameworks", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/LaunchDaemons", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/MobileSubstrate", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/MobileSubstrate/", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/MobileSubstrate/DynamicLibraries", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/PreferenceBundles", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/PreferenceLoader", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/SBInject", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Switches", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/test_inject_springboard.cy", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Themes", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/TweakInject", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/Zeppelin", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/Library/.DS_Store", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/System/Library/PreferenceBundles/AppList.bundle", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/System/Library/Themes", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/System/Library/KeyboardDictionaries", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/libresolv.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/lib/liblzma.dylib", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/include", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/aclocal", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/bigboss", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/share/common-lisp", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/dict", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/dpkg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/git-core", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/git-gui", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/gnupg", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/gitk", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/gitweb", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/libgpg-error", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/man", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/p11-kit", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/tabset", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/usr/share/terminfo", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/.freya_installed", NULL);
        execCmdCh("/bin/rm", "-rdvf", "/.freya_bootstrap", NULL);
        
        
        
        ////////
    }
    //////////////////////////////
    //////////////////////////////finally added the check for changing remvoving files without needing two separate apps
    
    else if (/* iOS 11.3 and higher can use lucky snapshot */ kCFCoreFoundationVersionNumber > 1451.51){ printf("[*] Removing Jailbreak for ios 11.3 - 11.4 beta 1-3 devices..\n");
        int testexec =execCmdCh("/bin/rm", "-rdvf", "/private/etc/apt", NULL);
        if (testexec == 0) {
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/motd", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/profile", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/rc.d", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/rc.d/substrate", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/etc/zshrc", NULL);
            ////usr/etc//
            execCmdCh("/bin/rm", "-rdvf", "/var/backups", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/containers/Bundle/iosbinpack64", NULL);
            ////etc folder cleanup
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/pam.d", NULL);
            //private/etc
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/apt", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/dropbear", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/alternatives", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/default", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/dpkg", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/ssh", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/ssl", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/profile.d", NULL);
            ////private/var
            execCmdCh("/bin/rm", "-rdvf", "/private/var/cache", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/lib", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/local", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/lock", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/spool", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/lib/apt", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/lib/cydia", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/cache/apt", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/db/stash", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/stash", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/tweak", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
            //var/mobile/Library
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia/", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
            //var/mobile/Library/Caches
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
            //snapshot.library
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/run/utmp", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
            unlink("/private/etc/apt/sources.list.d/cydia.list");
            unlink("/private/etc/apt");
            //////system/library
            execCmdCh("/bin/rm", "-rdvf", "/private/var/run/utmp", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/profile", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/motd", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/log/testbin.log", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/log/apt", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/log/jailbreakd-stderr.log", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/log/jailbreakd-stdout.log", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/LIB", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/bin", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/sbin", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/profile", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/motd", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/dropbear", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/containers/Bundle/tweaksupport", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/containers/Bundle/iosbinpack64", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/containers/Bundle/dylibs", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/LIB", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/motd", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/log/testbin.log", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/log/jailbreakd-stdout.log", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/log/jailbreakd-stderr.log", NULL);
            
            
            
            
            
            
            execCmdCh("/bin/rm", "-rdvf", "/var/cache", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/freya/", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/lib", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/stash", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/db/stash", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/mobile/Library/Cydia", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/etc/apt/sources.list.d", NULL);
                         
            execCmdCh("/bin/rm", "-rdvf", "/etc/apt/sources.list", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/apt", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/alternatives", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/default", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/dpkg", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/dropbear", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/localtime", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/motd", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/pam.d", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/profile", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/pkcs11", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/profile.d", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/profile.ro", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/rc.d", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/resolv.conf", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/ssh", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/ssl", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/sudo.conf", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/sudoers", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/sudoers.d", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/sudoers.dist", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/wgetrc", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/zshrc", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/etc/zprofile", NULL);
            
            execCmdCh("/bin/rm", "-rdvf", "/private/private", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/containers/Bundle/dylibs", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/containers/Bundle/iosbinpack64", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/containers/Bundle/tweaksupport", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/log/suckmyd-stderr.log", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/log/suckmyd-stdout.log", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/log/jailbreakd-stderr.log", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/log/jailbreakd-stdout.log", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/backups", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/empty", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/bin", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/cache", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/db/stash", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/db/sudo", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/dropbear", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/lib", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/var/lib", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/LIB", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/local", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/log/apt", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/log/dpkg", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/log/testbin.log", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/lock", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Cr4shed", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/CT4", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Logs/Cydia", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Sileo", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Toonsy", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Widgets", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/AmyCache", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/org.coolstar.SileoStore", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/motd", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/profile", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/run/utmp", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/run/sudo", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/sbin", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/spool", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/tweak", NULL);
            execCmdCh("/bin/rm", "-rdvf", "/private/var/unlimapps_tweak_resources", NULL);
            
        }
        else {
            printf("FAILED TO REMOVE WITH RM FREYA\n");
        }
    }
}
