//
//  electraRemove.m
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
#include "electraRemove.h"

char *myenvironElectra[] = {
    "PATH=/freya/usr/local/sbin:/freya/usr/local/bin:/freya/usr/sbin:/freya/usr/bin:/freya/sbin:/freya/bin:/freya/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games",
    "PS1=\\h:\\w \\u\\$ ",
    NULL
};


NSData *lastSystemOutputElectra=nil;

void removeFileIfExistsE(const char *fileToRemove)
{
    NSString *fileToRM = [NSString stringWithUTF8String:fileToRemove];
    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileToRM])
    {
        [[NSFileManager defaultManager] removeItemAtPath:fileToRM error:&error];
        if (error)
        {
            printf("ERROR REMOVING FILE! ERROR REPORTED: %@", error);
        } else {
            printf("REMOVED FILE: %@\n", fileToRM);
        }
    } else {
        //util_info("File Doesn't exist. Not removing.");
    }
}

int execCmdVElectra(const char *cmd, int argc, const char * const* argv, void (^unrestrict)(pid_t)) {
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
    
    int rv = posix_spawn(&pid, cmd, actions, attr, (char *const *)argv, myenvironElectra);
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
            lastSystemOutputElectra = [outData copy];
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

int execCmdElectra(const char *cmd, ...) {
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
    
    int rv = execCmdVElectra(cmd, argc, argv, NULL);
    return WEXITSTATUS(rv);
}

int systemCmdElectra(const char *cmd) {
    const char *argv[] = {"sh", "-c", (char *)cmd, NULL};
    return execCmdVElectra("/bin/sh", 3, argv, NULL);
}


void removingElectraiOS() {
    


    util_info("Removing Files...");
    //removingJailbreaknotice();
    /////////START REMOVING FILES
    if (/* iOS 11.2.6 or lower don't use snapshot */ kCFCoreFoundationVersionNumber <= 1451.51){
        
        printf("Removing Jailbreak with Eremover.for ios 11.2.x devices..\n");
        
        int rvchec1 = execCmdElectra("/usr/bin/find", ".", "-name", "*.deb", "-type", "f", "-delete", NULL);
        printf("[*] Trying find . with *.deb delete result = %d \n" , rvchec1);
        ///////delete the Malware from Satan////
        
        int rvchecdothidden1 = execCmdElectra("/usr/bin/find", ".", "-name", "._*", "-type", "f", "-delete", NULL);
        printf("[*] Trying find . with ._* delete result = %d \n" , rvchecdothidden1);
        
        printf("[*] Removing Jailbreak with custom remover...\n");
        execCmdElectra("/bin/rm", "-rdvf", "/var/mobile/Media/.bootstrapped_electraremover", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/mobile/testremover.txt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/.bootstrapped_Th0r", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/.freya_installed", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/.bootstrapped_electra", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/.installed_unc0ver", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/.install_unc0ver", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/.electra_no_snapshot", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/.installed_unc0vered", NULL);

        
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/motd", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/.cydia_no_stash", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/Cydia.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Network", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/aclocal", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/bigboss", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/common-lisp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/dict", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/dpkg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/gnupg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/libgpg-error", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/p11-kit", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/tabset", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/terminfo", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/local/bin", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/local/lib", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/authorize.sh", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/.cydia_no_stash", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/zsh", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/profile", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/rc.d", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/rc.d/substrate", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/etc/zshrc", NULL);
        ////usr/etc//
        execCmdElectra("/bin/rm", "-rdvf", "/usr/etc", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/scp", NULL);
        ////usr/lib////
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/_ncurses", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/apt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/bash", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/gettext", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.1.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-private.0.0.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-private.0.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libasprintf.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libasprintf.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libassuan.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libassuan.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libassuan.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libdpkg.a", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libform.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libform.6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libform5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libformw.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libformw.6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libformw.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libformw5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgcrypt.20.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgcrypt.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgcrypt.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgettextlib-0.19.8.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgettextlib.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgettextpo.1.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgettextpo.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgettextsrc-0.19.8.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgettextsrc.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgmp.10.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgmp.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgmp.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgnutls.30.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgnutls.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgnutlsxx.28.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgnutlsxx.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgpg-error.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgpg-error.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgpg-error.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhistory.5.2.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhistory.6.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhistory.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhistory.7.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhistory.7.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhistory.dylib ", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhogweed.4.4.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhogweed.4.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhogweed.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libidn2.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libidn2.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libidn2.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libintl.9.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libintl.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libksba.8.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libksba.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libksba.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/liblz4.1.7.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/liblz4.1.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/liblz4.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libmenu.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libmenu.6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libmenu.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libmenu5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libmenuw.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libmenuw.6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libmenuw.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libmenuw5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncurses.6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncurses5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncurses6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncursesw.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncursesw.6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncursesw.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncursesw5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncursesw6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libnettle.6.4.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libnettle.6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libnettle.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libnpth.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libnpth.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libnpth.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libp11-kit.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libp11-kit.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libp11-kit.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpanel.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpanel.6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpanel.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpanel5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpanelw.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpanelw.6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpanelw.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpanelw5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libreadline.5.2.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libreadline.6.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libreadline.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libreadline.7.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libreadline.7.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libreadline.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libresolv.9.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libresolv.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libtasn1.6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libtasn1.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libtasn1.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libunistring.2.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libunistring.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libunistring.la", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libsubstitute.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libsubstitute.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libsubstrate.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libjailbreak.dylib", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/recode-sr-latin", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/recache", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/rollectra", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/Rollectra", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/killall", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/sftp-server", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/SBInject.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/zsh", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/electra-prejailbreak", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/electra/createSnapshot", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/jb", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/jb", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/backups", NULL);
        ////////////Applications cleanup and root
        execCmdElectra("/bin/rm", "-rdvf", "/RWTEST", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/pwnedWritefileatrootTEST", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/Cydia\ Update\ Helper.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/NETWORK", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/AppCake.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/Activator.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/Anemone.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/BestCallerId.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/CrackTool3.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/Cydia.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/Sileo.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/Rollectra.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/cydown.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/Cylinder.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/iCleaner.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/icleaner.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/BarrelSettings.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/Ext3nder.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/Filza.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/Flex.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/GBA4iOS.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/jjjj.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/ReProvision.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/SafeMode.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/NewTerm.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/MobileTerminal.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/MTerminal.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/MovieBox3.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/BobbyMovie.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/PopcornTime.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/RST.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/TSSSaver.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/CertRemainTime.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/CrashReporter.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/AudioRecorder.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/ADManager.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/CocoaTop.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/calleridfaker.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/CallLogPro.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/WiFiPasswords.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/WifiPasswordList.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/calleridfaker.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/ClassDumpGUI.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/idevicewallsapp.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/UDIDFaker.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/UDIDCalculator.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/CallRecorder.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/Rehosts.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/NGXCarPlay.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/Audicy.app", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Applications/NGXCarplay.app", NULL);
        ///////////USR/LIBEXEC
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/as", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/frcode", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/bigram", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/code", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/reload", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/rmt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/MSUnrestrictProcess", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/perl5", NULL);
        //////////USR/SHARE
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/git-core", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/git-gui", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/gitk", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/gitweb", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/man", NULL);
        ////////USR/LOCAL
        execCmdElectra("/bin/rm", "-rdvf", "/usr/local/bin", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/local/lib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/local/lib/libluajit.a", NULL);
        
        ////var
        execCmdElectra("/bin/rm", "-rdvf", "/var/containers/Bundle/iosbinpack64", NULL);
        ////etc folder cleanup
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/pam.d", NULL);
        
        //private/etc
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/apt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/dropbear", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/alternatives", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/default", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/dpkg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/ssh", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/ssl", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/profile.d", NULL);
        
        ////private/var
        
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/cache", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/lib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/local", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/lock", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/spool", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/lib/apt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/lib/cydia", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/cache/apt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/db/stash", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/stash", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/tweak", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
        //var/mobile/Library
        
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia/", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
        
        //var/mobile/Library/Caches
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
        
        //snapshot.library
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/run/utmp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
        unlink("/private/etc/apt/sources.list.d/cydia.list");
        unlink("/private/etc/apt");
        
        ////usr/include files
        execCmdElectra("/bin/rm", "-rdvf", "/usr/include", NULL);
        ////usr/local files
        execCmdElectra("/bin/rm", "-rdvf", "/usr/local/bin", NULL);
        ////usr/libexec files
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/apt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/ssh-pkcs11-helper", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/ssh-keysign", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/cydia", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/dpkg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/gnupg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/gpg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/gpg-check-pattern", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/gpg-preset-passphrase", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/gpg-protect-tool", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/gpg-wks-client", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/git-core", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/p11-kit", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/scdaemon", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/vndevice", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/frcode", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/bigram", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/code", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/coreutils", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/reload", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/rmt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/filza", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/sudo", NULL);
        ////usr/lib files
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/TweakInject", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/tweakloader.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/pspawn_hook.dylib", NULL);
        unlink("/usr/lib/pspawn_hook.dylib");
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/tweaks", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/Activator", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/apt", NULL);
        
        unlink("/usr/lib/apt");
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/dpkg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/pam", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/p11-kit.0.dylib", NULL);
        unlink("/usr/lib/p11-kit-proxy.dylib");
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/p11-kit-proxy.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/pkcs11", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/pam", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/pkgconfig", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/ssl", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/bash", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/gettext", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/coreutils", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/engines", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/p7zip", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/Cephei.framework", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/CepheiPrefs.framework", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/SBInject", NULL);
        //usr/local
        execCmdElectra("/bin/rm", "-rdvf", "/usr/local/bin", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/local/lib", NULL);
        ////library folder files and subfolders
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Alkaline", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Activator", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Barrel", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/BarrelSettings", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Cylinder", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/dpkg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Frameworks", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/LaunchDaemons", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/.DS_Store", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/MobileSubstrate", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/PreferenceBundles", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/Library/PreferenceLoader", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/SBInject", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/Snoverlay", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/Flame", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/CallBlocker", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/CCSupport", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/Compatimark", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/Dynastic", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/Malipo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/SafariPlus.bundle", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/Activator", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/Cylinder", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/Barrel", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/BarrelSettings", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/libGitHubIssues/", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Themes", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/TweakInject", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Zeppelin", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Flipswitch", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Switches", NULL);
        
        //////system/library
        execCmdElectra("/bin/rm", "-rdvf", "/System/Library/PreferenceBundles/AppList.bundle", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/System/Library/Themes", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/System/Library/Internet\ Plug-Ins", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/System/Library/KeyboardDictionaries", NULL);
        
        /////root
        
        execCmdElectra("/bin/rm", "-rdvf", "/FELICITYICON.png", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bootstrap", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/mnt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/lib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/boot", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/libexec", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/include", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/mnt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/jb", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/games", NULL);
        //////////////USR/LIBRARY
        execCmdElectra("/bin/rm", "-rdvf", "/usr/Library", NULL);
        
        ///////////PRIVATE
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/run/utmp", NULL);
        ///
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/killall", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/reboot", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/.bootstrapped_Th0r", NULL);
        
        
        execCmdElectra("/bin/rm", "-rf", "/Library/test_inject_springboard.cy", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/SBInject.dylib", NULL);
        ////usr/local files and folders cleanup
        execCmdElectra("/bin/rm", "-rdvf", "/usr/local/lib", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libsparkapplist.dylib", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcrashreport.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libsymbolicate.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/TweakInject.dylib", NULL);
        //////ROOT FILES :(
        execCmdElectra("/bin/rm", "-rdvf", "/.bootstrapped_electra", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/.cydia_no_stash", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/.bit_of_fun", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/RWTEST", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/pwnedWritefileatrootTEST", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
        
        
        ////////// BIN/
        execCmdElectra("/bin/rm", "-rdvf", "/bin/bashbug", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/bunzip2", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/bzcat", NULL);
        unlink("usr/bin/bzcat");
        execCmdElectra("/bin/rm", "-rdvf", "/bin/bzip2", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/bzip2recover", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/bzip2_64", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/cat", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/chgrp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/chmod", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/chown", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/cp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/date", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/dd", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/dir", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/echo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/egrep", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/false", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/fgrep", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/grep", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/gzip", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/gtar", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/gunzip", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/gzexe", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/hostname", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/launchctl", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/ln", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/ls", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/jtoold", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/kill", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/mkdir", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/mknod", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/mv", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/mktemp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/pwd", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/bin/rmdir", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/readlink", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/unlink", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/run-parts", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/su", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/sync", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/stty", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/sh", NULL);
        unlink("/bin/sh");
        
        execCmdElectra("/bin/rm", "-rdvf", "/bin/sleep", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/sed", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/su", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/tar", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/touch", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/true", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/uname", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/vdr", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/vdir", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/uncompress", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/znew", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/zegrep", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/zmore", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/zdiff", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/zcat", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/zcmp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/zfgrep", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/zforce", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/zless", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/zgrep", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/zegrep", NULL);
        
        //////////SBIN
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/reboot", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/halt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/ifconfig", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/kextunload", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/ping", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/update_dyld_shared_cache", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/dmesg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/dynamic_pager", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/nologin", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/fstyp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/fstyp_msdos", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/fstyp_ntfs", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/fstyp_udf", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/mount_devfs", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/mount_fdesc", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/quotacheck", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/umount", NULL);
        
        
        /////usr/bin files folders cleanup
        //symbols
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/[", NULL);
        //a
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ADMHelper", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/arch", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/apt", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ar", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/apt-key", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/apt-cache", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/apt-cdrom", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/apt-config", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/apt-extracttemplates", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/apt-ftparchive", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/apt-sortpkgs", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/apt-mark", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/apt-get", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/arch", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/asu_inject", NULL);
        
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/asn1Coding", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/asn1Decoding", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/asn1Parser", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/autopoint", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/as", NULL);
        //b
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/bashbug", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/b2sum", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/base32", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/base64", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/basename", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/bitcode_strip", NULL);
        //c
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/CallLogPro", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/com.julioverne.ext3nder-installer", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/chown", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/chmod", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/chroot", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/chcon", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/chpass", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/check_dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/checksyms", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/chfn", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/chsh", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/cksum", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/comm", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/cmpdylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/codesign_allocate", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/csplit", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ctf_insert", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/cut", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/curl", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/curl-config", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/c_rehash", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/captoinfo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/certtool", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/cfversion", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/clear", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/cmp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/cydown", NULL);//cydown
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/cydown.arch_arm64", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/cydown.arch_armv7", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/cycript", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/cycc", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/cynject", NULL);
        //d
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dbclient", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/db_archive", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/db_checkpoint", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/db_deadlock", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/db_dump", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/db_hotbackup", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/db_load", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/db_log_verify", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/db_printlog", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/db_recover", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/db_replicate", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/db_sql_codegen", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/db_stat", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/db_tuner", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/db_upgrade", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/db_verify", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dbsql", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/debugserver", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/defaults", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/df", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/diff", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/diff3", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dirname", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dircolors", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dirmngr", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dirmngr-client", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-architecture", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-buildflags", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-buildpackage", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-checkbuilddeps", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-deb", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-distaddfile", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-divert", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-genbuildinfo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-genchanges", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-gencontrol", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-gensymbols", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-maintscript-helper", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-mergechangelogs", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-name", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-parsechangelog", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-query", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-scanpackages", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-scansources", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-shlibdeps", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-source", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-split", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-statoverride", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-trigger", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dpkg-vendor", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/du", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dumpsexp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dselect", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dsymutil", NULL);
        ////e
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/expand", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/expr", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/env", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/envsubst", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ecidecid", NULL);
        //f
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/factor", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/filemon", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/Filza", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/fmt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/fold", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/funzip", NULL);
        //g
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/games", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/getconf", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/getty", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gettext", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gettext.sh", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gettextize", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/git", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/git-cvsserver", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/git-recieve-pack", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/git-shell", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/git-upload-pack", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gitk", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gnutar", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gnutls-cli", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gnutls-cli-debug", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gnutls-serv", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gpg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gpgrt-config", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gpg-zip", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gpgsplit", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gpgv", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gssc", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/groups", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gpg-agent", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gpg-connect-agent ", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gpg-error", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gpg-error-config", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gpg2", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gpgconf", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gpgparsemail", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gpgscm", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gpgsm", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gpgtar", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gpgv2", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/groups", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/gtar", NULL);
        //h
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/head", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/hmac256", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/hostid", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/hostinfo", NULL);
        //i
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/install", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/id", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/idn2", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/indr", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/inout", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/infocmp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/infotocap", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/iomfsetgamma", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/install_name_tool", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/libtool", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/lipo", NULL);
        //j
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/join", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/jtool", NULL);
        //k
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/killall", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/kbxutil", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ksba-config", NULL);
        //l
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/less", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/libassuan-config", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/libgcrypt-config", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/link", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ldid", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ldid2", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ldrestart", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/locate", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/login", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/logname", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/lzcat", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/lz4", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/lz4c", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/lz4cat", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/lzcmp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/lzdiff", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/lzegrep", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/lzfgrep", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/lzgrep", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/lzless", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/lzma", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/lzmadec", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/lzmainfo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/lzmore", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin.lipo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/lipo", NULL);
        
        //m
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/md5sum", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/mkfifo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/mktemp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/more", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/msgattrib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/msgcat", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/msgcmp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/msgcomm", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/msgconv", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/msgen", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/msgexec", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/msgfilter", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/msgfmt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/msggrep", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/msginit", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/msgmerge", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/msgunfmt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/msguniq", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/mpicalc", NULL);
        //n
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/nano", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/nettle-hash", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/nettle-lfib-stream", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/nettle-pbkdf2", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ngettext", NULL);
        
        
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/nm", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/nmedit", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/nice", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/nl", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/nohup", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/nproc", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/npth-config", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/numfmt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ncurses6-config", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ncursesw6-config", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ncursesw5-config", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ncurses5-config", NULL);
        //o
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/od", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ocsptool", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ObjectDump", NULL);//ld64
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/dyldinfo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ld", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/machocheck", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/unwinddump", NULL);//ld64 done
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/otool", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/openssl", NULL);
        //p
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/pincrush", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/pagestuff", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/pagesize", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/passwd", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/paste", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/pathchk", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/pinky", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/plconvert", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/pr", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/printenv", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/printf", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/procexp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ptx", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/p11-kit", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/p11tool", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/pkcs1-conv", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/psktool", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/quota", NULL);
        
        
        //r
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/renice", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ranlib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/redo_prebinding", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/reprovisiond", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/reset", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/realpath", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/rnano", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/runcon", NULL);
        //s
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/snapUtil", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/sbdidlaunch", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/sbreload", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/script", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/sdiff", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/seq", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/sexp-conv", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/seg_addr_table", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/seg_hack", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/segedit", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/sftp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/shred", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/shuf", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/sort", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ssh", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ssh-add", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ssh-agent", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ssh-keygen", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/ssh-keyscan", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/sw_vers", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/seq", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/SemiRestore11-Lite", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/sha1sum", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/sha224sum", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/sha256sum", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/sha384sum", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/sha512sum", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/shred", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/shuf", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/size", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/split", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/srptool", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/stat", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/stdbuf", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/strings", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/strip", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/sum", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/sync", NULL);
        //t
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/tabs", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/tac", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/tar", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/tail", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/tee", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/test", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/tic", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/time", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/timeout", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/toe", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/tput", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/tr", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/tset", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/truncate", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/trust", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/tsort", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/tty", NULL);
        //u
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/uiduid", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/uuid", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/uuid-config", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/uiopen", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/unlz4", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/unlzma", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/unxz", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/update-alternatives", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/updatedb", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/unexpand", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/uniq", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/unzip", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/unzipsfx", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/unrar", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/uptime", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/users", NULL);
        //w
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/watchgnupg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/wc", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/wget", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/which", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/who", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/whoami", NULL);
        //x
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/xargs", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/xz", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/xgettext", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/xzcat", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/xzcmp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/xzdec", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/xzdiff", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/xzegrep", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/xzfgrep", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/xzgrep", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/xzless", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/xzmore", NULL);
        //y
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/yat2m", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/yes", NULL);
        //z
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/zip", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/zipcloak", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/zipnote", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/zipsplit", NULL);
        //numbers
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/7z", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/7za", NULL);
        //////////////
        ////
        //////////USR/SBIN
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/chown", NULL);
        
        unlink("/usr/sbin/chown");
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/chmod", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/chroot", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/dev_mkdb", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/edquota", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/applygnupgdefaults", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/fdisk", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/halt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/sshd", NULL);
        
        //////////////USR/LIB
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhistory.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/xxxMobileGestalt.dylib", NULL);//for cydown
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/xxxSystem.dylib", NULL);//for cydown
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcolorpicker.dylib", NULL);//
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcrypto.dylib", NULL);//
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcrypto.a", NULL);//
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libdb_sql-6.2.dylib", NULL);//
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libdb_sql-6.dylib", NULL);//
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libdb_sql.dylib", NULL);//
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libdb-6.2.dylib", NULL);//
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libdb-6.dylib", NULL);//
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libdb.dylib", NULL);//
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/liblzma.a", NULL);//
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/liblzma.la", NULL);//
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libprefs.dylib", NULL);//
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libssl.a", NULL);//
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libssl.dylib", NULL);//
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libST.dylib", NULL);//
        //////////////////
        //////////////8
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpam.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpamc.1.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6.0", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpanelw.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhistory.5.2.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libreadline.6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpanel.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcurses.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhistory.6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libformw.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncursesw.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libreadline.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhistory.6.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libform.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpanelw.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libmenuw.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/terminfo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpam.1.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libmenu.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpatcyh.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libreadline.6.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncurses.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhistory.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpamc.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libformw.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1.0", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpanel.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.0.0.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/_ncurses", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpam_misc.1.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libreadline.5.2.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpam_misc.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libreadline.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libmenuw.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpam.1.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libmenu.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncursesw.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcycript.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcycript.jar", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libdpkg.a", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcrypto.1.0.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libssl.1.0.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcycript.db", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcurl.4.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcycript.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcycript.cy", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libdpkg.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libswift", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libsubstrate.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libuuid.16.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libuuid.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libtapi.dylib", NULL);//ld64
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libnghttp2.14.dylib", NULL);//ld64
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libnghttp2.dylib", NULL);//ld64
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libnghttp2.la", NULL);//ld64
        ///sauirks new substrate
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/substrate", NULL);//ld64
        
        //////////USR/SBIN
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/accton", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/vifs", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/ac", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/update", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/pwd_mkdb", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/sysctl", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/zdump", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/startupfiletool", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/iostat", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/nologin", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/mkfile", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/quotaon", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/repquota", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/zic", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/vipw", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/vsdbutil", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/start-stop-daemon", NULL);
        ////////USR/LOCAL
        execCmdElectra("/bin/rm", "-rdvf", "/usr/local/lib/libluajit.a", NULL);
        //////LIBRARY
        execCmdElectra("/bin/rm", "-rdvf", "/Library/test_inject_springboard.cy", NULL);
        //////sbin folder files cleanup
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/dmesg", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/cat", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/sbin/zshrc", NULL);
        ////usr/sbin files
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/start-start-daemon", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/accton", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/addgnupghome", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/vifs", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/ac", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/update", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/sysctl", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/zdump", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/startupfiletool", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/iostat", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/mkfile", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/zic", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/sbin/vipw", NULL);
        ////usr/libexec files
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/_rocketd_reenable", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/rocketd", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/MSUnrestrictProcess", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/substrate", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/libexec/substrated", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/applist.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapplist.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhAcxTools.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhAcxTools2.dylib", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libflipswitch.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.2.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.1.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.5.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-private.0.0.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-private.0.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libassuan.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libassuan.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libassuan.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libnpth.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libnpth.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libnpth.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgpg-error.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgpg-error.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libgpg-error.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libksba.8.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libksba.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libksba.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/cycript0.9", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhistory.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpam.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpamc.1.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpackageinfo.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/librocketbootstrap.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.dylib.4.6.0", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-pkg.4.6.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpanelw.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhistory.5.2.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libreadline.6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpanel.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcurses.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhistory.6.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libformw.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncursesw.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libreadline.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhistory.6.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libform.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpanelw.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libmenuw.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/terminfo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/terminfo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpam.1.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libmenu.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpatcyh.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libreadline.6.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncurses.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhistory.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpamc.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libformw.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.dylib.1.1.0", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libapt-inst.1.1.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpanel.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.0.0.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/_ncurses", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpam_misc.1.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libreadline.5.2.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpam_misc.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libreadline.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libmenuw.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libpam.1.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libmenu.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/liblzmadec.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncursesw.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcycript.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcycript.jar", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcycript.db", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcurl.4.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcurl.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcurl.la", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcycript.0.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcycript.cy", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcephei.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libcepheiprefs.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhbangcommon.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libhbangprefs.dylib", NULL);
        /////end it
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libjailbreak.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/profile", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/motd", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/log/testbin.log", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/log/apt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/log/jailbreakd-stderr.log", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/log/jailbreakd-stdout.log", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/test_inject_springboard.cy", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/local/lib/libluajit.a", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/bin/zsh", NULL);
        //missing from removeMe.sh oddly
        //////mine above lol
        //////////////////Jakes below
        
        execCmdElectra("/bin/rm", "-rdvf", "/var/LIB", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/bin", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/sbin", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/profile", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/motd", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/dropbear", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/containers/Bundle/tweaksupport", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/containers/Bundle/iosbinpack64", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/containers/Bundle/dylibs", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/LIB", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/motd", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/log/testbin.log", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/log/jailbreakd-stdout.log", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/log/jailbreakd-stderr.log", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/bin/find", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/var/cache", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/freya", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/lib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/stash", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/db/stash", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/mobile/Library/Cydia", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/etc/apt/sources.list.d", NULL);
                     
        execCmdElectra("/bin/rm", "-rdvf", "/etc/apt/sources.list", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/apt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/alternatives", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/default", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/dpkg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/dropbear", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/localtime", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/motd", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/pam.d", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/profile", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/pkcs11", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/profile.d", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/profile.ro", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/rc.d", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/resolv.conf", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/ssh", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/ssl", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/sudo.conf", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/sudoers", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/sudoers.d", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/sudoers.dist", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/wgetrc", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/zshrc", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/etc/zprofile", NULL);
        
        execCmdElectra("/bin/rm", "-rdvf", "/private/private", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/containers/Bundle/dylibs", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/containers/Bundle/iosbinpack64", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/containers/Bundle/tweaksupport", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/log/suckmyd-stderr.log", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/log/suckmyd-stdout.log", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/log/jailbreakd-stderr.log", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/log/jailbreakd-stdout.log", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/backups", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/empty", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/bin", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/cache", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/db/stash", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/db/sudo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/dropbear", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/lib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/var/lib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/LIB", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/local", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/log/apt", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/log/dpkg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/log/testbin.log", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/lock", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Cr4shed", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/CT4", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Logs/Cydia", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Sileo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Toonsy", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Widgets", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/AmyCache", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/org.coolstar.SileoStore", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/motd", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/profile", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/run/utmp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/run/sudo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/sbin", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/spool", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/tweak", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/private/var/unlimapps_tweak_resources", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Alkaline", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Activator", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/Snoverlay", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/Flame", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/CallBlocker", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/CCSupport", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/Compatimark", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/Malipo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/SafariPlus.bundle", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/Activator", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/Cylinder", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/Barrel", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/BarrelSettings", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Application\ Support/libGitHubIssues", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Barrel", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/BarrelSettings", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Cylinder", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/dpkg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Flipswitch", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Frameworks", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/LaunchDaemons", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/MobileSubstrate", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/MobileSubstrate/", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/MobileSubstrate/DynamicLibraries", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/PreferenceBundles", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/PreferenceLoader", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/SBInject", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Switches", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/test_inject_springboard.cy", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Themes", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/TweakInject", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/Zeppelin", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/Library/.DS_Store", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/System/Library/PreferenceBundles/AppList.bundle", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/System/Library/Themes", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/System/Library/KeyboardDictionaries", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libform.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libncurses.5.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/libresolv.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/lib/liblzma.dylib", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/include", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/aclocal", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/bigboss", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/share/common-lisp", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/dict", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/dpkg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/git-core", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/git-gui", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/gnupg", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/gitk", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/gitweb", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/libgpg-error", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/man", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/p11-kit", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/tabset", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/usr/share/terminfo", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/.freya_installed", NULL);
        execCmdElectra("/bin/rm", "-rdvf", "/.freya_bootstrap", NULL);


        
        ////////
    }
    //////////////////////////////
    //////////////////////////////finally added the check for changing remvoving files without needing two separate apps
    
    else if (/* iOS 11.3 and higher can use lucky snapshot */ kCFCoreFoundationVersionNumber >= 1452.23){ printf("[*] Removing Jailbreak for devices greater or equal to ios 11.3....\n");
        int testexec = execCmdElectra("/bin/rm", "-rdvf", "/private/etc/apt", NULL);
        if (testexec == 0) {
            ////usr/etc//
            ////etc folder cleanup
            ///        execCmdElectra("/bin/rm", "-rdvf", "/RWTEST", NULL);
            ///            execCmdElectra("/bin/rm", "-rdvf", "/var/mobile/Media/.bootstrapped_electraremover", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/var/mobile/testremover.txt", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/pam.d", NULL);
            //private/etc
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/Cydia\ Update\ Helper.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/AppCake.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/Activator.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/Anemone.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/BestCallerId.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/CrackTool3.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/Cydia.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/Sileo.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/Rollectra.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/cydown.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/Cylinder.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/iCleaner.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/icleaner.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/BarrelSettings.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/Ext3nder.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/Filza.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/Flex.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/GBA4iOS.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/jjjj.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/ReProvision.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/SafeMode.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/NewTerm.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/MobileTerminal.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/MTerminal.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/MovieBox3.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/BobbyMovie.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/PopcornTime.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/RST.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/TSSSaver.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/CertRemainTime.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/CrashReporter.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/AudioRecorder.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/ADManager.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/CocoaTop.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/calleridfaker.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/CallLogPro.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/WiFiPasswords.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/WifiPasswordList.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/calleridfaker.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/ClassDumpGUI.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/idevicewallsapp.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/UDIDFaker.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/UDIDCalculator.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/CallRecorder.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/Rehosts.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/NGXCarPlay.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/Audicy.app", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/Applications/NGXCarplay.app", NULL);
            ///////////USR/LIBEXEC

            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/apt", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/alternatives", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/default", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/dpkg", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/dropbear", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/localtime", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/motd", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/pam.d", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/profile", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/pkcs11", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/profile.d", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/profile.ro", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/rc.d", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/resolv.conf", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/ssh", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/ssl", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/sudo.conf", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/sudo_logsrvd.conf", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/sudoers", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/sudoers.d", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/sudoers.dist", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/wgetrc", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/symlibs.dylib", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/zshrc", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/etc/zprofile", NULL);
            ////private/var
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/backups", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/cache", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/Ext3nder-Installer", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/lib", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/local", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/lock", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/spool", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/lib/apt", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/lib/dpkg", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/lib/cydia", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/db/stash", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/stash", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/tweak", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/run/utmp", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/profile", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/motd", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/log/testbin.log", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/log/apt", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/log/jailbreakd-stderr.log", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/log/jailbreakd-stdout.log", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/LIB", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/bin", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/sbin", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/dropbear", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/empty", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/bin", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/cercube_stashed", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/db/sudo", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/log/dpkg", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/containers/Bundle/tweaksupport", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/containers/Bundle/iosbinpack64", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/containers/Bundle/dylibs", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/freya/", NULL);
            //var/mobile/Library
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia/", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
            //var/mobile/Library/Caches
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
            //snapshot.library
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/run/utmp", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
            //////system/library
            execCmdElectra("/bin/rm", "-rdvf", "/var/mobile/Library/Cydia", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/private", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/containers/Bundle/dylibs", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/containers/Bundle/iosbinpack64", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/containers/Bundle/tweaksupport", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/log/suckmyd-stderr.log", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/log/suckmyd-stdout.log", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/log/jailbreakd-stderr.log", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/log/jailbreakd-stdout.log", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Activator", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Activator", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Application\ Support/Flex3", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/com.saurik.Cydia", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Cr4shed", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/CT4", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/CT3", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Cydia", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Flex3", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Filza", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Fingal", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/iWidgets", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/LockHTML", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Logs/Cydia", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Notchification", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/unlimapps_tweaks_resources", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Sileo", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/SBHTML", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Toonsy", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Widgets", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/libactivator.plist", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.johncoates.Flex", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/AmyCache", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/org.coolstar.SileoStore", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.saurik.Cydia", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/com.tigisoftware.Filza", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/mobile/Library/libactivator.plist", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/motd", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/profile", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/run/pspawn_hook.ts", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/run/utmp", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/run/sudo", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/sbin", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/spool", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/tmp/cydia.log", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/tweak", NULL);
            execCmdElectra("/bin/rm", "-rdvf", "/private/var/unlimapps_tweak_resources", NULL);
           
        }
        else {
            printf("FAILED TO REMOVE WITH RM FREYA\n");
        }
    }
}
