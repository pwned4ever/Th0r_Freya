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


#define LOG(str, args...) do { NSLog(@"[*] " str "\n", ##args); } while(false)

void removeFileIfExistsFREYA( const char *fileToRemove )
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
        //LOG("File Doesn't exist. Not removing.");
    }
}

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
        
        removeFileIfExistsFREYA("/var/mobile/Media/.bootstrapped_electraremover");
        removeFileIfExistsFREYA("/var/mobile/testremover.txt");
        removeFileIfExistsFREYA("/.bootstrapped_Th0r");
        removeFileIfExistsFREYA("/.freya_installed");
        removeFileIfExistsFREYA("/.bootstrapped_electra");
        removeFileIfExistsFREYA("/.installed_unc0ver");
        removeFileIfExistsFREYA("/.install_unc0ver");
        removeFileIfExistsFREYA("/.electra_no_snapshot");
        removeFileIfExistsFREYA("/.installed_unc0vered");

        
        removeFileIfExistsFREYA("/private/etc/motd");
        removeFileIfExistsFREYA("/.cydia_no_stash");
        
        removeFileIfExistsFREYA("/Applications/Cydia.app");
        removeFileIfExistsFREYA("/Network");
        
        removeFileIfExistsFREYA("/usr/share/aclocal");
        removeFileIfExistsFREYA("/usr/share/bigboss");
        removeFileIfExistsFREYA("/usr/share/common-lisp");
        removeFileIfExistsFREYA("/usr/share/dict");
        removeFileIfExistsFREYA("/usr/share/dpkg");
        removeFileIfExistsFREYA("/usr/share/gnupg");
        removeFileIfExistsFREYA("/usr/share/libgpg-error");
        removeFileIfExistsFREYA("/usr/share/p11-kit");
        removeFileIfExistsFREYA("/usr/share/tabset");
        removeFileIfExistsFREYA("/usr/share/terminfo");
        
        removeFileIfExistsFREYA("/usr/local/bin");
        removeFileIfExistsFREYA("/usr/local/lib");
        
        removeFileIfExistsFREYA("/authorize.sh");
        removeFileIfExistsFREYA("/.cydia_no_stash");
        removeFileIfExistsFREYA("/bin/zsh");
        removeFileIfExistsFREYA("/private/etc/profile");
        removeFileIfExistsFREYA("/private/etc/rc.d");
        removeFileIfExistsFREYA("/private/etc/rc.d/substrate");
        removeFileIfExistsFREYA("/etc/zshrc");
        ////usr/etc//
        removeFileIfExistsFREYA("/usr/etc");
        removeFileIfExistsFREYA("/usr/bin/scp");
        ////usr/lib////
        
        removeFileIfExistsFREYA("/usr/lib/_ncurses");
        removeFileIfExistsFREYA("/usr/lib/apt");
        removeFileIfExistsFREYA("/usr/lib/bash");
        removeFileIfExistsFREYA("/usr/lib/gettext");
        removeFileIfExistsFREYA("/usr/lib/libapt-inst.2.0.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-inst.2.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-inst.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-pkg.5.0.1.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-pkg.5.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-pkg.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-private.0.0.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-private.0.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libasprintf.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libasprintf.dylib");
        removeFileIfExistsFREYA("/usr/lib/libassuan.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libassuan.dylib");
        removeFileIfExistsFREYA("/usr/lib/libassuan.la");
        removeFileIfExistsFREYA("/usr/lib/libdpkg.a");
        removeFileIfExistsFREYA("/usr/lib/libform.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libform.6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libform.dylib");
        removeFileIfExistsFREYA("/usr/lib/libform5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libformw.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libformw.6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libformw.dylib");
        removeFileIfExistsFREYA("/usr/lib/libformw5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgcrypt.20.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgcrypt.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgcrypt.la");
        removeFileIfExistsFREYA("/usr/lib/libgettextlib-0.19.8.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgettextlib.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgettextpo.1.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgettextpo.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgettextsrc-0.19.8.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgettextsrc.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgmp.10.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgmp.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgmp.la");
        removeFileIfExistsFREYA("/usr/lib/libgnutls.30.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgnutls.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgnutlsxx.28.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgnutlsxx.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgpg-error.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgpg-error.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgpg-error.la");
        removeFileIfExistsFREYA("/usr/lib/libhistory.5.2.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhistory.6.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhistory.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhistory.7.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhistory.7.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhistory.dylib ");
        removeFileIfExistsFREYA("/usr/lib/libhogweed.4.4.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhogweed.4.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhogweed.dylib");
        removeFileIfExistsFREYA("/usr/lib/libidn2.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libidn2.dylib");
        removeFileIfExistsFREYA("/usr/lib/libidn2.la");
        removeFileIfExistsFREYA("/usr/lib/libintl.9.dylib");
        removeFileIfExistsFREYA("/usr/lib/libintl.dylib");
        removeFileIfExistsFREYA("/usr/lib/libksba.8.dylib");
        removeFileIfExistsFREYA("/usr/lib/libksba.dylib");
        removeFileIfExistsFREYA("/usr/lib/libksba.la");
        removeFileIfExistsFREYA("/usr/lib/liblz4.1.7.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/liblz4.1.dylib");
        removeFileIfExistsFREYA("/usr/lib/liblz4.dylib");
        removeFileIfExistsFREYA("/usr/lib/liblzmadec.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/liblzmadec.dylib");
        removeFileIfExistsFREYA("/usr/lib/libmenu.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libmenu.6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libmenu.dylib");
        removeFileIfExistsFREYA("/usr/lib/libmenu5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libmenuw.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libmenuw.6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libmenuw.dylib");
        removeFileIfExistsFREYA("/usr/lib/libmenuw5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libncurses.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libncurses.6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libncurses5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libncurses6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libncursesw.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libncursesw.6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libncursesw.dylib");
        removeFileIfExistsFREYA("/usr/lib/libncursesw5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libncursesw6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libnettle.6.4.dylib");
        removeFileIfExistsFREYA("/usr/lib/libnettle.6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libnettle.dylib");
        removeFileIfExistsFREYA("/usr/lib/libnpth.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libnpth.dylib");
        removeFileIfExistsFREYA("/usr/lib/libnpth.la");
        removeFileIfExistsFREYA("/usr/lib/libp11-kit.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libp11-kit.dylib");
        removeFileIfExistsFREYA("/usr/lib/libp11-kit.la");
        removeFileIfExistsFREYA("/usr/lib/libpanel.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpanel.6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpanel.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpanel5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpanelw.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpanelw.6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpanelw.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpanelw5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libreadline.5.2.dylib");
        removeFileIfExistsFREYA("/usr/lib/libreadline.6.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libreadline.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libreadline.7.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libreadline.7.dylib");
        removeFileIfExistsFREYA("/usr/lib/libreadline.dylib");
        removeFileIfExistsFREYA("/usr/lib/libresolv.9.dylib");
        removeFileIfExistsFREYA("/usr/lib/libresolv.dylib");
        removeFileIfExistsFREYA("/usr/lib/libtasn1.6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libtasn1.dylib");
        removeFileIfExistsFREYA("/usr/lib/libtasn1.la");
        removeFileIfExistsFREYA("/usr/lib/libunistring.2.dylib");
        removeFileIfExistsFREYA("/usr/lib/libunistring.dylib");
        removeFileIfExistsFREYA("/usr/lib/libunistring.la");
        
        removeFileIfExistsFREYA("/usr/lib/libsubstitute.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libsubstitute.dylib");
        removeFileIfExistsFREYA("/usr/lib/libsubstrate.dylib");
        removeFileIfExistsFREYA("/usr/lib/libjailbreak.dylib");
        
        removeFileIfExistsFREYA("/usr/bin/recode-sr-latin");
        removeFileIfExistsFREYA("/usr/bin/recache");
        removeFileIfExistsFREYA("/usr/bin/rollectra");
        removeFileIfExistsFREYA("/usr/bin/Rollectra");
        removeFileIfExistsFREYA("/usr/bin/killall");
        
        removeFileIfExistsFREYA("/usr/libexec/sftp-server");
        removeFileIfExistsFREYA("/usr/lib/SBInject.dylib");
        removeFileIfExistsFREYA("/bin/zsh");
        removeFileIfExistsFREYA("/electra-prejailbreak");
        removeFileIfExistsFREYA("/electra/createSnapshot");
        removeFileIfExistsFREYA("/jb");
        removeFileIfExistsFREYA("/jb");
        removeFileIfExistsFREYA("/var/backups");
        ////////////Applications cleanup and root
        removeFileIfExistsFREYA("/RWTEST");
        removeFileIfExistsFREYA("/pwnedWritefileatrootTEST");
        removeFileIfExistsFREYA("/Applications/Cydia\ Update\ Helper.app");
        removeFileIfExistsFREYA("/NETWORK");
        removeFileIfExistsFREYA("/Applications/AppCake.app");
        removeFileIfExistsFREYA("/Applications/Activator.app");
        removeFileIfExistsFREYA("/Applications/Anemone.app");
        removeFileIfExistsFREYA("/Applications/BestCallerId.app");
        removeFileIfExistsFREYA("/Applications/CrackTool3.app");
        removeFileIfExistsFREYA("/Applications/Cydia.app");
        removeFileIfExistsFREYA("/Applications/Sileo.app");
        removeFileIfExistsFREYA("/Applications/Rollectra.app");
        removeFileIfExistsFREYA("/Applications/cydown.app");
        removeFileIfExistsFREYA("/Applications/Cylinder.app");
        removeFileIfExistsFREYA("/Applications/iCleaner.app");
        removeFileIfExistsFREYA("/Applications/icleaner.app");
        removeFileIfExistsFREYA("/Applications/BarrelSettings.app");
        removeFileIfExistsFREYA("/Applications/Ext3nder.app");
        removeFileIfExistsFREYA("/Applications/Filza.app");
        removeFileIfExistsFREYA("/Applications/Flex.app");
        removeFileIfExistsFREYA("/Applications/GBA4iOS.app");
        removeFileIfExistsFREYA("/Applications/jjjj.app");
        removeFileIfExistsFREYA("/Applications/ReProvision.app");
        removeFileIfExistsFREYA("/Applications/SafeMode.app");
        removeFileIfExistsFREYA("/Applications/NewTerm.app");
        removeFileIfExistsFREYA("/Applications/MobileTerminal.app");
        removeFileIfExistsFREYA("/Applications/MTerminal.app");
        removeFileIfExistsFREYA("/Applications/MovieBox3.app");
        removeFileIfExistsFREYA("/Applications/BobbyMovie.app");
        removeFileIfExistsFREYA("/Applications/PopcornTime.app");
        removeFileIfExistsFREYA("/Applications/RST.app");
        removeFileIfExistsFREYA("/Applications/TSSSaver.app");
        removeFileIfExistsFREYA("/Applications/CertRemainTime.app");
        removeFileIfExistsFREYA("/Applications/CrashReporter.app");
        removeFileIfExistsFREYA("/Applications/AudioRecorder.app");
        removeFileIfExistsFREYA("/Applications/ADManager.app");
        removeFileIfExistsFREYA("/Applications/CocoaTop.app");
        removeFileIfExistsFREYA("/Applications/calleridfaker.app");
        removeFileIfExistsFREYA("/Applications/CallLogPro.app");
        removeFileIfExistsFREYA("/Applications/WiFiPasswords.app");
        removeFileIfExistsFREYA("/Applications/WifiPasswordList.app");
        removeFileIfExistsFREYA("/Applications/calleridfaker.app");
        removeFileIfExistsFREYA("/Applications/ClassDumpGUI.app");
        removeFileIfExistsFREYA("/Applications/idevicewallsapp.app");
        removeFileIfExistsFREYA("/Applications/UDIDFaker.app");
        removeFileIfExistsFREYA("/Applications/UDIDCalculator.app");
        removeFileIfExistsFREYA("/Applications/CallRecorder.app");
        removeFileIfExistsFREYA("/Applications/Rehosts.app");
        removeFileIfExistsFREYA("/Applications/NGXCarPlay.app");
        removeFileIfExistsFREYA("/Applications/Audicy.app");
        removeFileIfExistsFREYA("/Applications/NGXCarplay.app");
        ///////////USR/LIBEXEC
        removeFileIfExistsFREYA("/usr/libexec/as");
        removeFileIfExistsFREYA("/usr/libexec/frcode");
        removeFileIfExistsFREYA("/usr/libexec/bigram");
        removeFileIfExistsFREYA("/usr/libexec/code");
        removeFileIfExistsFREYA("/usr/libexec/reload");
        removeFileIfExistsFREYA("/usr/libexec/rmt");
        removeFileIfExistsFREYA("/usr/libexec/MSUnrestrictProcess");
        removeFileIfExistsFREYA("/usr/lib/perl5");
        //////////USR/SHARE
        removeFileIfExistsFREYA("/usr/share/git-core");
        removeFileIfExistsFREYA("/usr/share/git-gui");
        removeFileIfExistsFREYA("/usr/share/gitk");
        removeFileIfExistsFREYA("/usr/share/gitweb");
        removeFileIfExistsFREYA("/usr/share/man");
        ////////USR/LOCAL
        removeFileIfExistsFREYA("/usr/local/bin");
        removeFileIfExistsFREYA("/usr/local/lib");
        removeFileIfExistsFREYA("/usr/local/lib/libluajit.a");
        
        ////var
        removeFileIfExistsFREYA("/var/containers/Bundle/iosbinpack64");
        ////etc folder cleanup
        removeFileIfExistsFREYA("/private/etc/pam.d");
        
        //private/etc
        removeFileIfExistsFREYA("/private/etc/apt");
        removeFileIfExistsFREYA("/private/etc/dropbear");
        removeFileIfExistsFREYA("/private/etc/alternatives");
        removeFileIfExistsFREYA("/private/etc/default");
        removeFileIfExistsFREYA("/private/etc/dpkg");
        removeFileIfExistsFREYA("/private/etc/ssh");
        removeFileIfExistsFREYA("/private/etc/ssl");
        removeFileIfExistsFREYA("/private/etc/profile.d");
        
        ////private/var
        
        removeFileIfExistsFREYA("/private/var/cache");
        removeFileIfExistsFREYA("/private/var/Ext3nder-Installer");
        removeFileIfExistsFREYA("/private/var/lib");
        removeFileIfExistsFREYA("/private/var/local");
        removeFileIfExistsFREYA("/private/var/lock");
        removeFileIfExistsFREYA("/private/var/spool");
        removeFileIfExistsFREYA("/private/var/lib/apt");
        removeFileIfExistsFREYA("/private/var/lib/dpkg");
        removeFileIfExistsFREYA("/private/var/lib/dpkg");
        removeFileIfExistsFREYA("/private/var/lib/cydia");
        removeFileIfExistsFREYA("/private/var/cache/apt");
        removeFileIfExistsFREYA("/private/var/db/stash");
        removeFileIfExistsFREYA("/private/var/stash");
        removeFileIfExistsFREYA("/private/var/tweak");
        removeFileIfExistsFREYA("/private/var/cercube_stashed");
        removeFileIfExistsFREYA("/private/var/tmp/cydia.log");
        //var/mobile/Library
        
        removeFileIfExistsFREYA("/private/var/mobile/Library/Flex3");
        
        removeFileIfExistsFREYA("/private/var/mobile/Library/Notchification");
        removeFileIfExistsFREYA("/private/var/mobile/Library/unlimapps_tweaks_resources");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Fingal");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Filza");
        removeFileIfExistsFREYA("/private/var/mobile/Library/CT3");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Cydia");
        
        removeFileIfExistsFREYA("/private/var/mobile/Library/com.saurik.Cydia");
        removeFileIfExistsFREYA("/private/var/mobile/Library/com.saurik.Cydia/");
        
        removeFileIfExistsFREYA("/private/var/mobile/Library/SBHTML");
        removeFileIfExistsFREYA("/private/var/mobile/Library/LockHTML");
        removeFileIfExistsFREYA("/private/var/mobile/Library/iWidgets");
        
        //var/mobile/Library/Caches
        removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Flex3");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/libactivator.plist");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.tigisoftware.Filza");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.johncoates.Flex");
        removeFileIfExistsFREYA("/private/var/mobile/Library/libactivator.plist");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Activator");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Activator");
        
        //snapshot.library
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal");
        removeFileIfExistsFREYA("/private/var/run/utmp");
        removeFileIfExistsFREYA("/private/var/run/pspawn_hook.ts");
        unlink("/private/etc/apt/sources.list.d/cydia.list");
        unlink("/private/etc/apt");
        
        ////usr/include files
        removeFileIfExistsFREYA("/usr/include");
        ////usr/local files
        removeFileIfExistsFREYA("/usr/local/bin");
        ////usr/libexec files
        removeFileIfExistsFREYA("/usr/libexec/apt");
        removeFileIfExistsFREYA("/usr/libexec/ssh-pkcs11-helper");
        removeFileIfExistsFREYA("/usr/libexec/ssh-keysign");
        removeFileIfExistsFREYA("/usr/libexec/cydia");
        removeFileIfExistsFREYA("/usr/libexec/dpkg");
        removeFileIfExistsFREYA("/usr/libexec/gnupg");
        removeFileIfExistsFREYA("/usr/libexec/gpg");
        removeFileIfExistsFREYA("/usr/libexec/gpg-check-pattern");
        removeFileIfExistsFREYA("/usr/libexec/gpg-preset-passphrase");
        removeFileIfExistsFREYA("/usr/libexec/gpg-protect-tool");
        removeFileIfExistsFREYA("/usr/libexec/gpg-wks-client");
        removeFileIfExistsFREYA("/usr/libexec/git-core");
        removeFileIfExistsFREYA("/usr/libexec/p11-kit");
        removeFileIfExistsFREYA("/usr/libexec/scdaemon");
        removeFileIfExistsFREYA("/usr/libexec/vndevice");
        removeFileIfExistsFREYA("/usr/libexec/frcode");
        removeFileIfExistsFREYA("/usr/libexec/bigram");
        removeFileIfExistsFREYA("/usr/libexec/code");
        removeFileIfExistsFREYA("/usr/libexec/coreutils");
        removeFileIfExistsFREYA("/usr/libexec/reload");
        removeFileIfExistsFREYA("/usr/libexec/rmt");
        removeFileIfExistsFREYA("/usr/libexec/filza");
        removeFileIfExistsFREYA("/usr/libexec/sudo");
        ////usr/lib files
        removeFileIfExistsFREYA("/usr/lib/TweakInject");
        removeFileIfExistsFREYA("/usr/lib/tweakloader.dylib");
        removeFileIfExistsFREYA("/usr/lib/pspawn_hook.dylib");
        unlink("/usr/lib/pspawn_hook.dylib");
        removeFileIfExistsFREYA("/usr/lib/tweaks");
        removeFileIfExistsFREYA("/usr/lib/Activator");
        removeFileIfExistsFREYA("/usr/lib/apt");
        
        unlink("/usr/lib/apt");
        
        removeFileIfExistsFREYA("/usr/lib/dpkg");
        removeFileIfExistsFREYA("/usr/lib/pam");
        removeFileIfExistsFREYA("/usr/lib/p11-kit.0.dylib");
        unlink("/usr/lib/p11-kit-proxy.dylib");
        removeFileIfExistsFREYA("/usr/lib/p11-kit-proxy.dylib");
        removeFileIfExistsFREYA("/usr/lib/pkcs11");
        removeFileIfExistsFREYA("/usr/lib/pam");
        removeFileIfExistsFREYA("/usr/lib/pkgconfig");
        removeFileIfExistsFREYA("/usr/lib/ssl");
        removeFileIfExistsFREYA("/usr/lib/bash");
        removeFileIfExistsFREYA("/usr/lib/gettext");
        removeFileIfExistsFREYA("/usr/lib/coreutils");
        removeFileIfExistsFREYA("/usr/lib/engines");
        removeFileIfExistsFREYA("/usr/lib/p7zip");
        removeFileIfExistsFREYA("/usr/lib/Cephei.framework");
        removeFileIfExistsFREYA("/usr/lib/CepheiPrefs.framework");
        removeFileIfExistsFREYA("/usr/lib/SBInject");
        //usr/local
        removeFileIfExistsFREYA("/usr/local/bin");
        removeFileIfExistsFREYA("/usr/local/lib");
        ////library folder files and subfolders
        removeFileIfExistsFREYA("/Library/Alkaline");
        removeFileIfExistsFREYA("/Library/Activator");
        removeFileIfExistsFREYA("/Library/Barrel");
        removeFileIfExistsFREYA("/Library/BarrelSettings");
        removeFileIfExistsFREYA("/Library/Cylinder");
        removeFileIfExistsFREYA("/Library/dpkg");
        removeFileIfExistsFREYA("/Library/Frameworks");
        removeFileIfExistsFREYA("/Library/LaunchDaemons");
        removeFileIfExistsFREYA("/Library/.DS_Store");
        removeFileIfExistsFREYA("/Library/MobileSubstrate");
        removeFileIfExistsFREYA("/Library/PreferenceBundles");
        
        removeFileIfExistsFREYA("/Library/PreferenceLoader");
        removeFileIfExistsFREYA("/Library/SBInject");
        removeFileIfExistsFREYA("/Library/Application\ Support/Snoverlay");
        removeFileIfExistsFREYA("/Library/Application\ Support/Flame");
        removeFileIfExistsFREYA("/Library/Application\ Support/CallBlocker");
        removeFileIfExistsFREYA("/Library/Application\ Support/CCSupport");
        removeFileIfExistsFREYA("/Library/Application\ Support/Compatimark");
        removeFileIfExistsFREYA("/Library/Application\ Support/Dynastic");
        removeFileIfExistsFREYA("/Library/Application\ Support/Malipo");
        removeFileIfExistsFREYA("/Library/Application\ Support/SafariPlus.bundle");
        
        removeFileIfExistsFREYA("/Library/Application\ Support/Activator");
        removeFileIfExistsFREYA("/Library/Application\ Support/Cylinder");
        removeFileIfExistsFREYA("/Library/Application\ Support/Barrel");
        removeFileIfExistsFREYA("/Library/Application\ Support/BarrelSettings");
        removeFileIfExistsFREYA("/Library/Application\ Support/libGitHubIssues/");
        removeFileIfExistsFREYA("/Library/Themes");
        removeFileIfExistsFREYA("/Library/TweakInject");
        removeFileIfExistsFREYA("/Library/Zeppelin");
        removeFileIfExistsFREYA("/Library/Flipswitch");
        removeFileIfExistsFREYA("/Library/Switches");
        
        //////system/library
        removeFileIfExistsFREYA("/System/Library/PreferenceBundles/AppList.bundle");
        removeFileIfExistsFREYA("/System/Library/Themes");
        
        removeFileIfExistsFREYA("/System/Library/Internet\ Plug-Ins");
        removeFileIfExistsFREYA("/System/Library/KeyboardDictionaries");
        
        /////root
        
        removeFileIfExistsFREYA("/FELICITYICON.png");
        removeFileIfExistsFREYA("/bootstrap");
        removeFileIfExistsFREYA("/mnt");
        removeFileIfExistsFREYA("/lib");
        removeFileIfExistsFREYA("/boot");
        removeFileIfExistsFREYA("/libexec");
        removeFileIfExistsFREYA("/include");
        removeFileIfExistsFREYA("/jb");
        removeFileIfExistsFREYA("/usr/games");
        //////////////USR/LIBRARY
        removeFileIfExistsFREYA("/usr/Library");
        
        ///////////PRIVATE
        removeFileIfExistsFREYA("/private/var/run/utmp");
        ///
        removeFileIfExistsFREYA("/usr/bin/killall");
        removeFileIfExistsFREYA("/usr/sbin/reboot");
        removeFileIfExistsFREYA("/.bootstrapped_Th0r");
        
        
        execCmdFreya("/bin/rm", "-rf", "/Library/test_inject_springboard.cy");
        removeFileIfExistsFREYA("/usr/lib/SBInject.dylib");
        ////usr/local files and folders cleanup
        removeFileIfExistsFREYA("/usr/local/lib");
        
        removeFileIfExistsFREYA("/usr/lib/libsparkapplist.dylib");
        
        removeFileIfExistsFREYA("/usr/lib/libcrashreport.dylib");
        removeFileIfExistsFREYA("/usr/lib/libsymbolicate.dylib");
        removeFileIfExistsFREYA("/usr/lib/TweakInject.dylib");
        //////ROOT FILES :(
        removeFileIfExistsFREYA("/.bootstrapped_electra");
        removeFileIfExistsFREYA("/.cydia_no_stash");
        removeFileIfExistsFREYA("/.bit_of_fun");
        removeFileIfExistsFREYA("/RWTEST");
        removeFileIfExistsFREYA("/pwnedWritefileatrootTEST");
        removeFileIfExistsFREYA("/private/etc/symlibs.dylib");
        
        
        ////////// BIN/
        removeFileIfExistsFREYA("/bin/bashbug");
        removeFileIfExistsFREYA("/bin/bunzip2");
        removeFileIfExistsFREYA("/bin/bzcat");
        unlink("usr/bin/bzcat");
        removeFileIfExistsFREYA("/bin/bzip2");
        removeFileIfExistsFREYA("/bin/bzip2recover");
        removeFileIfExistsFREYA("/bin/bzip2_64");
        removeFileIfExistsFREYA("/bin/cat");
        removeFileIfExistsFREYA("/bin/chgrp");
        removeFileIfExistsFREYA("/bin/chmod");
        removeFileIfExistsFREYA("/bin/chown");
        removeFileIfExistsFREYA("/bin/cp");
        removeFileIfExistsFREYA("/bin/date");
        removeFileIfExistsFREYA("/bin/dd");
        removeFileIfExistsFREYA("/bin/dir");
        removeFileIfExistsFREYA("/bin/echo");
        removeFileIfExistsFREYA("/bin/egrep");
        removeFileIfExistsFREYA("/bin/false");
        removeFileIfExistsFREYA("/bin/fgrep");
        removeFileIfExistsFREYA("/bin/grep");
        removeFileIfExistsFREYA("/bin/gzip");
        removeFileIfExistsFREYA("/bin/gtar");
        removeFileIfExistsFREYA("/bin/gunzip");
        removeFileIfExistsFREYA("/bin/gzexe");
        removeFileIfExistsFREYA("/bin/hostname");
        removeFileIfExistsFREYA("/bin/launchctl");
        removeFileIfExistsFREYA("/bin/ln");
        removeFileIfExistsFREYA("/bin/ls");
        removeFileIfExistsFREYA("/bin/jtoold");
        removeFileIfExistsFREYA("/bin/kill");
        removeFileIfExistsFREYA("/bin/mkdir");
        removeFileIfExistsFREYA("/bin/mknod");
        removeFileIfExistsFREYA("/bin/mv");
        removeFileIfExistsFREYA("/bin/mktemp");
        removeFileIfExistsFREYA("/bin/pwd");
        
        removeFileIfExistsFREYA("/bin/rmdir");
        removeFileIfExistsFREYA("/bin/readlink");
        removeFileIfExistsFREYA("/bin/unlink");
        removeFileIfExistsFREYA("/bin/run-parts");
        removeFileIfExistsFREYA("/bin/su");
        removeFileIfExistsFREYA("/bin/sync");
        removeFileIfExistsFREYA("/bin/stty");
        removeFileIfExistsFREYA("/bin/sh");
        unlink("/bin/sh");
        
        removeFileIfExistsFREYA("/bin/sleep");
        removeFileIfExistsFREYA("/bin/sed");
        removeFileIfExistsFREYA("/bin/su");
        removeFileIfExistsFREYA("/bin/tar");
        removeFileIfExistsFREYA("/bin/touch");
        removeFileIfExistsFREYA("/bin/true");
        removeFileIfExistsFREYA("/bin/uname");
        removeFileIfExistsFREYA("/bin/vdr");
        removeFileIfExistsFREYA("/bin/vdir");
        removeFileIfExistsFREYA("/bin/uncompress");
        removeFileIfExistsFREYA("/bin/znew");
        removeFileIfExistsFREYA("/bin/zegrep");
        removeFileIfExistsFREYA("/bin/zmore");
        removeFileIfExistsFREYA("/bin/zdiff");
        removeFileIfExistsFREYA("/bin/zcat");
        removeFileIfExistsFREYA("/bin/zcmp");
        removeFileIfExistsFREYA("/bin/zfgrep");
        removeFileIfExistsFREYA("/bin/zforce");
        removeFileIfExistsFREYA("/bin/zless");
        removeFileIfExistsFREYA("/bin/zgrep");
        removeFileIfExistsFREYA("/bin/zegrep");
        
        //////////SBIN
        removeFileIfExistsFREYA("/sbin/reboot");
        removeFileIfExistsFREYA("/sbin/halt");
        removeFileIfExistsFREYA("/sbin/ifconfig");
        removeFileIfExistsFREYA("/sbin/kextunload");
        removeFileIfExistsFREYA("/sbin/ping");
        removeFileIfExistsFREYA("/sbin/update_dyld_shared_cache");
        removeFileIfExistsFREYA("/sbin/dmesg");
        removeFileIfExistsFREYA("/sbin/dynamic_pager");
        removeFileIfExistsFREYA("/sbin/nologin");
        removeFileIfExistsFREYA("/sbin/fstyp");
        removeFileIfExistsFREYA("/sbin/fstyp_msdos");
        removeFileIfExistsFREYA("/sbin/fstyp_ntfs");
        removeFileIfExistsFREYA("/sbin/fstyp_udf");
        removeFileIfExistsFREYA("/sbin/mount_devfs");
        removeFileIfExistsFREYA("/sbin/mount_fdesc");
        removeFileIfExistsFREYA("/sbin/quotacheck");
        removeFileIfExistsFREYA("/sbin/umount");
        
        
        /////usr/bin files folders cleanup
        //symbols
        removeFileIfExistsFREYA("/usr/bin/[");
        //a
        removeFileIfExistsFREYA("/usr/bin/ADMHelper");
        removeFileIfExistsFREYA("/usr/bin/arch");
        removeFileIfExistsFREYA("/usr/bin/apt");
        
        removeFileIfExistsFREYA("/usr/bin/ar");
        
        removeFileIfExistsFREYA("/usr/bin/apt-key");
        removeFileIfExistsFREYA("/usr/bin/apt-cache");
        removeFileIfExistsFREYA("/usr/bin/apt-cdrom");
        removeFileIfExistsFREYA("/usr/bin/apt-config");
        removeFileIfExistsFREYA("/usr/bin/apt-extracttemplates");
        removeFileIfExistsFREYA("/usr/bin/apt-ftparchive");
        removeFileIfExistsFREYA("/usr/bin/apt-sortpkgs");
        removeFileIfExistsFREYA("/usr/bin/apt-mark");
        removeFileIfExistsFREYA("/usr/bin/apt-get");
        removeFileIfExistsFREYA("/usr/bin/arch");
        removeFileIfExistsFREYA("/usr/bin/asu_inject");
        
        
        removeFileIfExistsFREYA("/usr/bin/asn1Coding");
        removeFileIfExistsFREYA("/usr/bin/asn1Decoding");
        removeFileIfExistsFREYA("/usr/bin/asn1Parser");
        removeFileIfExistsFREYA("/usr/bin/autopoint");
        
        removeFileIfExistsFREYA("/usr/bin/as");
        //b
        removeFileIfExistsFREYA("/usr/bin/bashbug");
        removeFileIfExistsFREYA("/usr/bin/b2sum");
        removeFileIfExistsFREYA("/usr/bin/base32");
        removeFileIfExistsFREYA("/usr/bin/base64");
        removeFileIfExistsFREYA("/usr/bin/basename");
        removeFileIfExistsFREYA("/usr/bin/bitcode_strip");
        //c
        removeFileIfExistsFREYA("/usr/bin/CallLogPro");
        removeFileIfExistsFREYA("/usr/bin/com.julioverne.ext3nder-installer");
        removeFileIfExistsFREYA("/usr/bin/chown");
        removeFileIfExistsFREYA("/usr/bin/chmod");
        removeFileIfExistsFREYA("/usr/bin/chroot");
        removeFileIfExistsFREYA("/usr/bin/chcon");
        removeFileIfExistsFREYA("/usr/bin/chpass");
        removeFileIfExistsFREYA("/usr/bin/check_dylib");
        removeFileIfExistsFREYA("/usr/bin/checksyms");
        removeFileIfExistsFREYA("/usr/bin/chfn");
        removeFileIfExistsFREYA("/usr/bin/chsh");
        removeFileIfExistsFREYA("/usr/bin/cksum");
        removeFileIfExistsFREYA("/usr/bin/comm");
        removeFileIfExistsFREYA("/usr/bin/cmpdylib");
        removeFileIfExistsFREYA("/usr/bin/codesign_allocate");
        removeFileIfExistsFREYA("/usr/bin/csplit");
        removeFileIfExistsFREYA("/usr/bin/ctf_insert");
        removeFileIfExistsFREYA("/usr/bin/cut");
        removeFileIfExistsFREYA("/usr/bin/curl");
        removeFileIfExistsFREYA("/usr/bin/curl-config");
        removeFileIfExistsFREYA("/usr/bin/c_rehash");
        removeFileIfExistsFREYA("/usr/bin/captoinfo");
        removeFileIfExistsFREYA("/usr/bin/certtool");
        removeFileIfExistsFREYA("/usr/bin/cfversion");
        removeFileIfExistsFREYA("/usr/bin/clear");
        removeFileIfExistsFREYA("/usr/bin/cmp");
        removeFileIfExistsFREYA("/usr/bin/cydown");//cydown
        removeFileIfExistsFREYA("/usr/bin/cydown.arch_arm64");
        removeFileIfExistsFREYA("/usr/bin/cydown.arch_armv7");
        
        removeFileIfExistsFREYA("/usr/bin/cycript");
        removeFileIfExistsFREYA("/usr/bin/cycc");
        removeFileIfExistsFREYA("/usr/bin/cynject");
        //d
        removeFileIfExistsFREYA("/usr/bin/dbclient");
        removeFileIfExistsFREYA("/usr/bin/db_archive");
        removeFileIfExistsFREYA("/usr/bin/db_checkpoint");
        removeFileIfExistsFREYA("/usr/bin/db_deadlock");
        removeFileIfExistsFREYA("/usr/bin/db_dump");
        removeFileIfExistsFREYA("/usr/bin/db_hotbackup");
        removeFileIfExistsFREYA("/usr/bin/db_load");
        removeFileIfExistsFREYA("/usr/bin/db_log_verify");
        removeFileIfExistsFREYA("/usr/bin/db_printlog");
        removeFileIfExistsFREYA("/usr/bin/db_recover");
        removeFileIfExistsFREYA("/usr/bin/db_replicate");
        removeFileIfExistsFREYA("/usr/bin/db_sql_codegen");
        removeFileIfExistsFREYA("/usr/bin/db_stat");
        removeFileIfExistsFREYA("/usr/bin/db_tuner");
        removeFileIfExistsFREYA("/usr/bin/db_upgrade");
        removeFileIfExistsFREYA("/usr/bin/db_verify");
        removeFileIfExistsFREYA("/usr/bin/dbsql");
        removeFileIfExistsFREYA("/usr/bin/debugserver");
        removeFileIfExistsFREYA("/usr/bin/defaults");
        removeFileIfExistsFREYA("/usr/bin/df");
        removeFileIfExistsFREYA("/usr/bin/diff");
        removeFileIfExistsFREYA("/usr/bin/diff3");
        removeFileIfExistsFREYA("/usr/bin/dirname");
        removeFileIfExistsFREYA("/usr/bin/dircolors");
        removeFileIfExistsFREYA("/usr/bin/dirmngr");
        removeFileIfExistsFREYA("/usr/bin/dirmngr-client");
        removeFileIfExistsFREYA("/usr/bin/dpkg");
        removeFileIfExistsFREYA("/usr/bin/dpkg-architecture");
        removeFileIfExistsFREYA("/usr/bin/dpkg-buildflags");
        removeFileIfExistsFREYA("/usr/bin/dpkg-buildpackage");
        removeFileIfExistsFREYA("/usr/bin/dpkg-checkbuilddeps");
        removeFileIfExistsFREYA("/usr/bin/dpkg-deb");
        removeFileIfExistsFREYA("/usr/bin/dpkg-distaddfile");
        removeFileIfExistsFREYA("/usr/bin/dpkg-divert");
        removeFileIfExistsFREYA("/usr/bin/dpkg-genbuildinfo");
        removeFileIfExistsFREYA("/usr/bin/dpkg-genchanges");
        removeFileIfExistsFREYA("/usr/bin/dpkg-gencontrol");
        removeFileIfExistsFREYA("/usr/bin/dpkg-gensymbols");
        removeFileIfExistsFREYA("/usr/bin/dpkg-maintscript-helper");
        removeFileIfExistsFREYA("/usr/bin/dpkg-mergechangelogs");
        removeFileIfExistsFREYA("/usr/bin/dpkg-name");
        removeFileIfExistsFREYA("/usr/bin/dpkg-parsechangelog");
        removeFileIfExistsFREYA("/usr/bin/dpkg-query");
        removeFileIfExistsFREYA("/usr/bin/dpkg-scanpackages");
        removeFileIfExistsFREYA("/usr/bin/dpkg-scansources");
        removeFileIfExistsFREYA("/usr/bin/dpkg-shlibdeps");
        removeFileIfExistsFREYA("/usr/bin/dpkg-source");
        removeFileIfExistsFREYA("/usr/bin/dpkg-split");
        removeFileIfExistsFREYA("/usr/bin/dpkg-statoverride");
        removeFileIfExistsFREYA("/usr/bin/dpkg-trigger");
        removeFileIfExistsFREYA("/usr/bin/dpkg-vendor");
        removeFileIfExistsFREYA("/usr/bin/du");
        removeFileIfExistsFREYA("/usr/bin/dumpsexp");
        removeFileIfExistsFREYA("/usr/bin/dselect");
        removeFileIfExistsFREYA("/usr/bin/dsymutil");
        ////e
        removeFileIfExistsFREYA("/usr/bin/expand");
        removeFileIfExistsFREYA("/usr/bin/expr");
        removeFileIfExistsFREYA("/usr/bin/env");
        removeFileIfExistsFREYA("/usr/bin/envsubst");
        removeFileIfExistsFREYA("/usr/bin/ecidecid");
        //f
        removeFileIfExistsFREYA("/usr/bin/factor");
        removeFileIfExistsFREYA("/usr/bin/filemon");
        removeFileIfExistsFREYA("/usr/bin/Filza");
        removeFileIfExistsFREYA("/usr/bin/fmt");
        removeFileIfExistsFREYA("/usr/bin/fold");
        removeFileIfExistsFREYA("/usr/bin/funzip");
        //g
        removeFileIfExistsFREYA("/usr/bin/games");
        removeFileIfExistsFREYA("/usr/bin/getconf");
        removeFileIfExistsFREYA("/usr/bin/getty");
        removeFileIfExistsFREYA("/usr/bin/gettext");
        removeFileIfExistsFREYA("/usr/bin/gettext.sh");
        removeFileIfExistsFREYA("/usr/bin/gettextize");
        removeFileIfExistsFREYA("/usr/bin/git");
        removeFileIfExistsFREYA("/usr/bin/git-cvsserver");
        removeFileIfExistsFREYA("/usr/bin/git-recieve-pack");
        removeFileIfExistsFREYA("/usr/bin/git-shell");
        removeFileIfExistsFREYA("/usr/bin/git-upload-pack");
        removeFileIfExistsFREYA("/usr/bin/gitk");
        removeFileIfExistsFREYA("/usr/bin/gnutar");
        removeFileIfExistsFREYA("/usr/bin/gnutls-cli");
        removeFileIfExistsFREYA("/usr/bin/gnutls-cli-debug");
        removeFileIfExistsFREYA("/usr/bin/gnutls-serv");
        removeFileIfExistsFREYA("/usr/bin/gpg");
        removeFileIfExistsFREYA("/usr/bin/gpgrt-config");
        removeFileIfExistsFREYA("/usr/bin/gpg-zip");
        removeFileIfExistsFREYA("/usr/bin/gpgsplit");
        removeFileIfExistsFREYA("/usr/bin/gpgv");
        removeFileIfExistsFREYA("/usr/bin/gssc");
        removeFileIfExistsFREYA("/usr/bin/groups");
        removeFileIfExistsFREYA("/usr/bin/gpg-agent");
        removeFileIfExistsFREYA("/usr/bin/gpg-connect-agent ");
        removeFileIfExistsFREYA("/usr/bin/gpg-error");
        removeFileIfExistsFREYA("/usr/bin/gpg-error-config");
        removeFileIfExistsFREYA("/usr/bin/gpg2");
        removeFileIfExistsFREYA("/usr/bin/gpgconf");
        removeFileIfExistsFREYA("/usr/bin/gpgparsemail");
        removeFileIfExistsFREYA("/usr/bin/gpgscm");
        removeFileIfExistsFREYA("/usr/bin/gpgsm");
        removeFileIfExistsFREYA("/usr/bin/gpgtar");
        removeFileIfExistsFREYA("/usr/bin/gpgv2");
        removeFileIfExistsFREYA("/usr/bin/groups");
        removeFileIfExistsFREYA("/usr/bin/gtar");
        //h
        removeFileIfExistsFREYA("/usr/bin/head");
        removeFileIfExistsFREYA("/usr/bin/hmac256");
        removeFileIfExistsFREYA("/usr/bin/hostid");
        removeFileIfExistsFREYA("/usr/bin/hostinfo");
        //i
        removeFileIfExistsFREYA("/usr/bin/install");
        removeFileIfExistsFREYA("/usr/bin/id");
        removeFileIfExistsFREYA("/usr/bin/idn2");
        removeFileIfExistsFREYA("/usr/bin/indr");
        removeFileIfExistsFREYA("/usr/bin/inout");
        removeFileIfExistsFREYA("/usr/bin/infocmp");
        removeFileIfExistsFREYA("/usr/bin/infotocap");
        removeFileIfExistsFREYA("/usr/bin/iomfsetgamma");
        removeFileIfExistsFREYA("/usr/bin/install_name_tool");
        removeFileIfExistsFREYA("/usr/bin/libtool");
        removeFileIfExistsFREYA("/usr/bin/lipo");
        //j
        removeFileIfExistsFREYA("/usr/bin/join");
        removeFileIfExistsFREYA("/usr/bin/jtool");
        //k
        removeFileIfExistsFREYA("/usr/bin/killall");
        removeFileIfExistsFREYA("/usr/bin/kbxutil");
        removeFileIfExistsFREYA("/usr/bin/ksba-config");
        //l
        removeFileIfExistsFREYA("/usr/bin/less");
        removeFileIfExistsFREYA("/usr/bin/libassuan-config");
        removeFileIfExistsFREYA("/usr/bin/libgcrypt-config");
        removeFileIfExistsFREYA("/usr/bin/link");
        removeFileIfExistsFREYA("/usr/bin/ldid");
        removeFileIfExistsFREYA("/usr/bin/ldid2");
        removeFileIfExistsFREYA("/usr/bin/ldrestart");
        removeFileIfExistsFREYA("/usr/bin/locate");
        removeFileIfExistsFREYA("/usr/bin/login");
        removeFileIfExistsFREYA("/usr/bin/logname");
        removeFileIfExistsFREYA("/usr/bin/lzcat");
        removeFileIfExistsFREYA("/usr/bin/lz4");
        removeFileIfExistsFREYA("/usr/bin/lz4c");
        removeFileIfExistsFREYA("/usr/bin/lz4cat");
        removeFileIfExistsFREYA("/usr/bin/lzcmp");
        removeFileIfExistsFREYA("/usr/bin/lzdiff");
        removeFileIfExistsFREYA("/usr/bin/lzegrep");
        removeFileIfExistsFREYA("/usr/bin/lzfgrep");
        removeFileIfExistsFREYA("/usr/bin/lzgrep");
        removeFileIfExistsFREYA("/usr/bin/lzless");
        removeFileIfExistsFREYA("/usr/bin/lzma");
        removeFileIfExistsFREYA("/usr/bin/lzmadec");
        removeFileIfExistsFREYA("/usr/bin/lzmainfo");
        removeFileIfExistsFREYA("/usr/bin/lzmore");
        removeFileIfExistsFREYA("/usr/bin.lipo");
        removeFileIfExistsFREYA("/usr/bin/lipo");
        
        //m
        removeFileIfExistsFREYA("/usr/bin/md5sum");
        removeFileIfExistsFREYA("/usr/bin/mkfifo");
        removeFileIfExistsFREYA("/usr/bin/mktemp");
        removeFileIfExistsFREYA("/usr/bin/more");
        removeFileIfExistsFREYA("/usr/bin/msgattrib");
        removeFileIfExistsFREYA("/usr/bin/msgcat");
        removeFileIfExistsFREYA("/usr/bin/msgcmp");
        removeFileIfExistsFREYA("/usr/bin/msgcomm");
        removeFileIfExistsFREYA("/usr/bin/msgconv");
        removeFileIfExistsFREYA("/usr/bin/msgen");
        removeFileIfExistsFREYA("/usr/bin/msgexec");
        removeFileIfExistsFREYA("/usr/bin/msgfilter");
        removeFileIfExistsFREYA("/usr/bin/msgfmt");
        removeFileIfExistsFREYA("/usr/bin/msggrep");
        removeFileIfExistsFREYA("/usr/bin/msginit");
        removeFileIfExistsFREYA("/usr/bin/msgmerge");
        removeFileIfExistsFREYA("/usr/bin/msgunfmt");
        removeFileIfExistsFREYA("/usr/bin/msguniq");
        removeFileIfExistsFREYA("/usr/bin/mpicalc");
        //n
        removeFileIfExistsFREYA("/usr/bin/nano");
        removeFileIfExistsFREYA("/usr/bin/nettle-hash");
        removeFileIfExistsFREYA("/usr/bin/nettle-lfib-stream");
        removeFileIfExistsFREYA("/usr/bin/nettle-pbkdf2");
        removeFileIfExistsFREYA("/usr/bin/ngettext");
        
        
        
        removeFileIfExistsFREYA("/usr/bin/nm");
        removeFileIfExistsFREYA("/usr/bin/nmedit");
        removeFileIfExistsFREYA("/usr/bin/nice");
        removeFileIfExistsFREYA("/usr/bin/nl");
        removeFileIfExistsFREYA("/usr/bin/nohup");
        removeFileIfExistsFREYA("/usr/bin/nproc");
        removeFileIfExistsFREYA("/usr/bin/npth-config");
        removeFileIfExistsFREYA("/usr/bin/numfmt");
        removeFileIfExistsFREYA("/usr/bin/ncurses6-config");
        removeFileIfExistsFREYA("/usr/bin/ncursesw6-config");
        removeFileIfExistsFREYA("/usr/bin/ncursesw5-config");
        removeFileIfExistsFREYA("/usr/bin/ncurses5-config");
        //o
        
        removeFileIfExistsFREYA("/usr/bin/od");
        removeFileIfExistsFREYA("/usr/bin/ocsptool");
        removeFileIfExistsFREYA("/usr/bin/ObjectDump");//ld64
        removeFileIfExistsFREYA("/usr/bin/dyldinfo");
        removeFileIfExistsFREYA("/usr/bin/ld");
        removeFileIfExistsFREYA("/usr/bin/machocheck");
        removeFileIfExistsFREYA("/usr/bin/unwinddump");//ld64 done
        removeFileIfExistsFREYA("/usr/bin/otool");
        
        removeFileIfExistsFREYA("/usr/bin/openssl");
        //p
        removeFileIfExistsFREYA("/usr/bin/pincrush");
        removeFileIfExistsFREYA("/usr/bin/pagestuff");
        
        removeFileIfExistsFREYA("/usr/bin/pagesize");
        removeFileIfExistsFREYA("/usr/bin/passwd");
        removeFileIfExistsFREYA("/usr/bin/paste");
        removeFileIfExistsFREYA("/usr/bin/pathchk");
        removeFileIfExistsFREYA("/usr/bin/pinky");
        removeFileIfExistsFREYA("/usr/bin/plconvert");
        removeFileIfExistsFREYA("/usr/bin/pr");
        removeFileIfExistsFREYA("/usr/bin/printenv");
        removeFileIfExistsFREYA("/usr/bin/printf");
        removeFileIfExistsFREYA("/usr/bin/procexp");
        removeFileIfExistsFREYA("/usr/bin/ptx");
        removeFileIfExistsFREYA("/usr/bin/p11-kit");
        removeFileIfExistsFREYA("/usr/bin/p11tool");
        
        removeFileIfExistsFREYA("/usr/bin/pkcs1-conv");
        
        removeFileIfExistsFREYA("/usr/bin/psktool");
        
        removeFileIfExistsFREYA("/usr/bin/quota");
        
        
        //r
        removeFileIfExistsFREYA("/usr/bin/renice");
        removeFileIfExistsFREYA("/usr/bin/ranlib");
        removeFileIfExistsFREYA("/usr/bin/redo_prebinding");
        removeFileIfExistsFREYA("/usr/bin/reprovisiond");
        
        removeFileIfExistsFREYA("/usr/bin/reset");
        removeFileIfExistsFREYA("/usr/bin/realpath");
        removeFileIfExistsFREYA("/usr/bin/rnano");
        removeFileIfExistsFREYA("/usr/bin/runcon");
        //s
        
        removeFileIfExistsFREYA("/usr/bin/snapUtil");
        removeFileIfExistsFREYA("/usr/bin/sbdidlaunch");
        removeFileIfExistsFREYA("/usr/bin/sbreload");
        removeFileIfExistsFREYA("/usr/bin/script");
        removeFileIfExistsFREYA("/usr/bin/sdiff");
        removeFileIfExistsFREYA("/usr/bin/seq");
        removeFileIfExistsFREYA("/usr/bin/sexp-conv");
        removeFileIfExistsFREYA("/usr/bin/seg_addr_table");
        removeFileIfExistsFREYA("/usr/bin/seg_hack");
        removeFileIfExistsFREYA("/usr/bin/segedit");
        removeFileIfExistsFREYA("/usr/bin/sftp");
        removeFileIfExistsFREYA("/usr/bin/shred");
        removeFileIfExistsFREYA("/usr/bin/shuf");
        removeFileIfExistsFREYA("/usr/bin/sort");
        removeFileIfExistsFREYA("/usr/bin/ssh");
        removeFileIfExistsFREYA("/usr/bin/ssh-add");
        removeFileIfExistsFREYA("/usr/bin/ssh-agent");
        removeFileIfExistsFREYA("/usr/bin/ssh-keygen");
        removeFileIfExistsFREYA("/usr/bin/ssh-keyscan");
        removeFileIfExistsFREYA("/usr/bin/sw_vers");
        removeFileIfExistsFREYA("/usr/bin/seq");
        removeFileIfExistsFREYA("/usr/bin/SemiRestore11-Lite");
        
        removeFileIfExistsFREYA("/usr/bin/sha1sum");
        removeFileIfExistsFREYA("/usr/bin/sha224sum");
        removeFileIfExistsFREYA("/usr/bin/sha256sum");
        removeFileIfExistsFREYA("/usr/bin/sha384sum");
        removeFileIfExistsFREYA("/usr/bin/sha512sum");
        removeFileIfExistsFREYA("/usr/bin/shred");
        removeFileIfExistsFREYA("/usr/bin/shuf");
        removeFileIfExistsFREYA("/usr/bin/size");
        removeFileIfExistsFREYA("/usr/bin/split");
        removeFileIfExistsFREYA("/usr/bin/srptool");
        removeFileIfExistsFREYA("/usr/bin/stat");
        removeFileIfExistsFREYA("/usr/bin/stdbuf");
        removeFileIfExistsFREYA("/usr/bin/strings");
        removeFileIfExistsFREYA("/usr/bin/strip");
        removeFileIfExistsFREYA("/usr/bin/sum");
        removeFileIfExistsFREYA("/usr/bin/sync");
        //t
        removeFileIfExistsFREYA("/usr/bin/tabs");
        removeFileIfExistsFREYA("/usr/bin/tac");
        removeFileIfExistsFREYA("/usr/bin/tar");
        removeFileIfExistsFREYA("/usr/bin/tail");
        removeFileIfExistsFREYA("/usr/bin/tee");
        removeFileIfExistsFREYA("/usr/bin/test");
        removeFileIfExistsFREYA("/usr/bin/tic");
        removeFileIfExistsFREYA("/usr/bin/time");
        removeFileIfExistsFREYA("/usr/bin/timeout");
        removeFileIfExistsFREYA("/usr/bin/toe");
        removeFileIfExistsFREYA("/usr/bin/tput");
        removeFileIfExistsFREYA("/usr/bin/tr");
        removeFileIfExistsFREYA("/usr/bin/tset");
        removeFileIfExistsFREYA("/usr/bin/truncate");
        removeFileIfExistsFREYA("/usr/bin/trust");
        removeFileIfExistsFREYA("/usr/bin/tsort");
        removeFileIfExistsFREYA("/usr/bin/tty");
        //u
        removeFileIfExistsFREYA("/usr/bin/uiduid");
        removeFileIfExistsFREYA("/usr/bin/uuid");
        removeFileIfExistsFREYA("/usr/bin/uuid-config");
        removeFileIfExistsFREYA("/usr/bin/uiopen");
        removeFileIfExistsFREYA("/usr/bin/unlz4");
        removeFileIfExistsFREYA("/usr/bin/unlzma");
        removeFileIfExistsFREYA("/usr/bin/unxz");
        removeFileIfExistsFREYA("/usr/bin/update-alternatives");
        removeFileIfExistsFREYA("/usr/bin/updatedb");
        removeFileIfExistsFREYA("/usr/bin/unexpand");
        removeFileIfExistsFREYA("/usr/bin/uniq");
        removeFileIfExistsFREYA("/usr/bin/unzip");
        removeFileIfExistsFREYA("/usr/bin/unzipsfx");
        removeFileIfExistsFREYA("/usr/bin/unrar");
        removeFileIfExistsFREYA("/usr/bin/uptime");
        removeFileIfExistsFREYA("/usr/bin/users");
        //w
        removeFileIfExistsFREYA("/usr/bin/watchgnupg");
        removeFileIfExistsFREYA("/usr/bin/wc");
        removeFileIfExistsFREYA("/usr/bin/wget");
        removeFileIfExistsFREYA("/usr/bin/which");
        removeFileIfExistsFREYA("/usr/bin/who");
        removeFileIfExistsFREYA("/usr/bin/whoami");
        //x
        removeFileIfExistsFREYA("/usr/bin/xargs");
        removeFileIfExistsFREYA("/usr/bin/xz");
        removeFileIfExistsFREYA("/usr/bin/xgettext");
        removeFileIfExistsFREYA("/usr/bin/xzcat");
        removeFileIfExistsFREYA("/usr/bin/xzcmp");
        removeFileIfExistsFREYA("/usr/bin/xzdec");
        removeFileIfExistsFREYA("/usr/bin/xzdiff");
        removeFileIfExistsFREYA("/usr/bin/xzegrep");
        removeFileIfExistsFREYA("/usr/bin/xzfgrep");
        removeFileIfExistsFREYA("/usr/bin/xzgrep");
        removeFileIfExistsFREYA("/usr/bin/xzless");
        removeFileIfExistsFREYA("/usr/bin/xzmore");
        //y
        removeFileIfExistsFREYA("/usr/bin/yat2m");
        removeFileIfExistsFREYA("/usr/bin/yes");
        //z
        removeFileIfExistsFREYA("/usr/bin/zip");
        removeFileIfExistsFREYA("/usr/bin/zipcloak");
        removeFileIfExistsFREYA("/usr/bin/zipnote");
        removeFileIfExistsFREYA("/usr/bin/zipsplit");
        //numbers
        removeFileIfExistsFREYA("/usr/bin/7z");
        removeFileIfExistsFREYA("/usr/bin/7za");
        //////////////
        ////
        //////////USR/SBIN
        removeFileIfExistsFREYA("/usr/sbin/chown");
        
        unlink("/usr/sbin/chown");
        
        removeFileIfExistsFREYA("/usr/sbin/chmod");
        removeFileIfExistsFREYA("/usr/sbin/chroot");
        removeFileIfExistsFREYA("/usr/sbin/dev_mkdb");
        removeFileIfExistsFREYA("/usr/sbin/edquota");
        removeFileIfExistsFREYA("/usr/sbin/applygnupgdefaults");
        removeFileIfExistsFREYA("/usr/sbin/fdisk");
        removeFileIfExistsFREYA("/usr/sbin/halt");
        removeFileIfExistsFREYA("/usr/sbin/sshd");
        
        //////////////USR/LIB
        
        removeFileIfExistsFREYA("/usr/lib/libhistory.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/xxxMobileGestalt.dylib");//for cydown
        
        removeFileIfExistsFREYA("/usr/lib/xxxSystem.dylib");//for cydown
        
        removeFileIfExistsFREYA("/usr/lib/libcolorpicker.dylib");//
        removeFileIfExistsFREYA("/usr/lib/libcrypto.dylib");//
        removeFileIfExistsFREYA("/usr/lib/libcrypto.a");//
        removeFileIfExistsFREYA("/usr/lib/libdb_sql-6.2.dylib");//
        removeFileIfExistsFREYA("/usr/lib/libdb_sql-6.dylib");//
        removeFileIfExistsFREYA("/usr/lib/libdb_sql.dylib");//
        removeFileIfExistsFREYA("/usr/lib/libdb-6.2.dylib");//
        removeFileIfExistsFREYA("/usr/lib/libdb-6.dylib");//
        removeFileIfExistsFREYA("/usr/lib/libdb.dylib");//
        removeFileIfExistsFREYA("/usr/lib/liblzma.a");//
        removeFileIfExistsFREYA("/usr/lib/liblzma.la");//
        removeFileIfExistsFREYA("/usr/lib/libprefs.dylib");//
        removeFileIfExistsFREYA("/usr/lib/libssl.a");//
        removeFileIfExistsFREYA("/usr/lib/libssl.dylib");//
        removeFileIfExistsFREYA("/usr/lib/libST.dylib");//
        //////////////////
        //////////////8
        removeFileIfExistsFREYA("/usr/lib/libapt-pkg.dylib.4.6");
        removeFileIfExistsFREYA("/usr/lib/libapt-pkg.4.6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpam.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpamc.1.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-pkg.dylib.4.6.0");
        removeFileIfExistsFREYA("/usr/lib/libapt-pkg.4.6.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpanelw.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhistory.5.2.dylib");
        removeFileIfExistsFREYA("/usr/lib/libreadline.6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpanel.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-inst.dylib.1.1");
        removeFileIfExistsFREYA("/usr/lib/libapt-inst.1.1.dylib");
        removeFileIfExistsFREYA("/usr/lib/libcurses.dylib");
        removeFileIfExistsFREYA("/usr/lib/liblzmadec.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhistory.6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libformw.dylib");
        removeFileIfExistsFREYA("/usr/lib/libncursesw.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-inst.dylib");
        removeFileIfExistsFREYA("/usr/lib/libncurses.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-pkg.dylib");
        removeFileIfExistsFREYA("/usr/lib/libreadline.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhistory.6.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libform.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpanelw.dylib");
        removeFileIfExistsFREYA("/usr/lib/libmenuw.dylib");
        removeFileIfExistsFREYA("/usr/lib/libform.dylib");
        removeFileIfExistsFREYA("/usr/lib/terminfo");
        removeFileIfExistsFREYA("/usr/lib/libpam.1.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libmenu.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpatcyh.dylib");
        removeFileIfExistsFREYA("/usr/lib/libreadline.6.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/liblzmadec.dylib");
        removeFileIfExistsFREYA("/usr/lib/libncurses.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhistory.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpamc.dylib");
        removeFileIfExistsFREYA("/usr/lib/libformw.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-inst.dylib.1.1.0");
        removeFileIfExistsFREYA("/usr/lib/libapt-inst.1.1.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpanel.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/liblzmadec.0.0.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/_ncurses");
        removeFileIfExistsFREYA("/usr/lib/libpam_misc.1.dylib");
        removeFileIfExistsFREYA("/usr/lib/libreadline.5.2.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpam_misc.dylib");
        removeFileIfExistsFREYA("/usr/lib/libreadline.dylib");
        removeFileIfExistsFREYA("/usr/lib/libmenuw.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpam.1.dylib");
        removeFileIfExistsFREYA("/usr/lib/libmenu.dylib");
        removeFileIfExistsFREYA("/usr/lib/liblzmadec.la");
        removeFileIfExistsFREYA("/usr/lib/libncursesw.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libcycript.dylib");
        removeFileIfExistsFREYA("/usr/lib/libcycript.jar");
        removeFileIfExistsFREYA("/usr/lib/libdpkg.a");
        removeFileIfExistsFREYA("/usr/lib/libcrypto.1.0.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libssl.1.0.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libcycript.db");
        removeFileIfExistsFREYA("/usr/lib/libcurl.4.dylib");
        removeFileIfExistsFREYA("/usr/lib/libcycript.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libcycript.cy");
        removeFileIfExistsFREYA("/usr/lib/libdpkg.la");
        removeFileIfExistsFREYA("/usr/lib/libswift");
        removeFileIfExistsFREYA("/usr/lib/libsubstrate.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libuuid.16.dylib");
        removeFileIfExistsFREYA("/usr/lib/libuuid.dylib");
        removeFileIfExistsFREYA("/usr/lib/libtapi.dylib");//ld64
        removeFileIfExistsFREYA("/usr/lib/libnghttp2.14.dylib");//ld64
        removeFileIfExistsFREYA("/usr/lib/libnghttp2.dylib");//ld64
        removeFileIfExistsFREYA("/usr/lib/libnghttp2.la");//ld64
        ///sauirks new substrate
        removeFileIfExistsFREYA("/usr/lib/substrate");//ld64
        
        //////////USR/SBIN
        removeFileIfExistsFREYA("/usr/sbin/accton");
        removeFileIfExistsFREYA("/usr/sbin/vifs");
        removeFileIfExistsFREYA("/usr/sbin/ac");
        removeFileIfExistsFREYA("/usr/sbin/update");
        removeFileIfExistsFREYA("/usr/sbin/pwd_mkdb");
        removeFileIfExistsFREYA("/usr/sbin/sysctl");
        removeFileIfExistsFREYA("/usr/sbin/zdump");
        removeFileIfExistsFREYA("/usr/sbin/startupfiletool");
        removeFileIfExistsFREYA("/usr/sbin/iostat");
        removeFileIfExistsFREYA("/usr/sbin/nologin");
        
        removeFileIfExistsFREYA("/usr/sbin/mkfile");
        removeFileIfExistsFREYA("/usr/sbin/quotaon");
        removeFileIfExistsFREYA("/usr/sbin/repquota");
        removeFileIfExistsFREYA("/usr/sbin/zic");
        removeFileIfExistsFREYA("/usr/sbin/vipw");
        removeFileIfExistsFREYA("/usr/sbin/vsdbutil");
        
        removeFileIfExistsFREYA("/usr/sbin/start-stop-daemon");
        ////////USR/LOCAL
        removeFileIfExistsFREYA("/usr/local/lib/libluajit.a");
        //////LIBRARY
        removeFileIfExistsFREYA("/Library/test_inject_springboard.cy");
        //////sbin folder files cleanup
        removeFileIfExistsFREYA("/sbin/dmesg");
        
        removeFileIfExistsFREYA("/sbin/cat");
        removeFileIfExistsFREYA("/sbin/zshrc");
        ////usr/sbin files
        removeFileIfExistsFREYA("/usr/sbin/start-start-daemon");
        removeFileIfExistsFREYA("/usr/sbin/accton");
        removeFileIfExistsFREYA("/usr/sbin/addgnupghome");
        removeFileIfExistsFREYA("/usr/sbin/vifs");
        removeFileIfExistsFREYA("/usr/sbin/ac");
        removeFileIfExistsFREYA("/usr/sbin/update");
        removeFileIfExistsFREYA("/usr/sbin/sysctl");
        removeFileIfExistsFREYA("/usr/sbin/zdump");
        removeFileIfExistsFREYA("/usr/sbin/startupfiletool");
        removeFileIfExistsFREYA("/usr/sbin/iostat");
        removeFileIfExistsFREYA("/usr/sbin/mkfile");
        removeFileIfExistsFREYA("/usr/sbin/zic");
        removeFileIfExistsFREYA("/usr/sbin/vipw");
        ////usr/libexec files
        removeFileIfExistsFREYA("/usr/libexec/_rocketd_reenable");
        removeFileIfExistsFREYA("/usr/libexec/rocketd");
        removeFileIfExistsFREYA("/usr/libexec/MSUnrestrictProcess");
        removeFileIfExistsFREYA("/usr/libexec/substrate");
        removeFileIfExistsFREYA("/usr/libexec/substrated");
        
        removeFileIfExistsFREYA("/usr/lib/applist.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapplist.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhAcxTools.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhAcxTools2.dylib");
        
        removeFileIfExistsFREYA("/usr/lib/libflipswitch.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-inst.2.0.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-inst.2.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-pkg.5.0.1.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-pkg.5.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-private.0.0.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-private.0.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libassuan.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libassuan.dylib");
        removeFileIfExistsFREYA("/usr/lib/libassuan.la");
        removeFileIfExistsFREYA("/usr/lib/libnpth.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libnpth.dylib");
        removeFileIfExistsFREYA("/usr/lib/libnpth.la");
        removeFileIfExistsFREYA("/usr/lib/libgpg-error.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgpg-error.dylib");
        removeFileIfExistsFREYA("/usr/lib/libgpg-error.la");
        removeFileIfExistsFREYA("/usr/lib/libksba.8.dylib");
        removeFileIfExistsFREYA("/usr/lib/libksba.dylib");
        removeFileIfExistsFREYA("/usr/lib/libksba.la");
        removeFileIfExistsFREYA("/usr/lib/cycript0.9");
        removeFileIfExistsFREYA("/usr/lib/libhistory.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-pkg.dylib.4.6");
        removeFileIfExistsFREYA("/usr/lib/libapt-pkg.4.6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpam.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpamc.1.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpackageinfo.dylib");
        removeFileIfExistsFREYA("/usr/lib/librocketbootstrap.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-pkg.dylib.4.6.0");
        removeFileIfExistsFREYA("/usr/lib/libapt-pkg.4.6.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpanelw.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhistory.5.2.dylib");
        removeFileIfExistsFREYA("/usr/lib/libreadline.6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpanel.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-inst.dylib.1.1");
        removeFileIfExistsFREYA("/usr/lib/libapt-inst.1.1.dylib");
        removeFileIfExistsFREYA("/usr/lib/libcurses.dylib");
        removeFileIfExistsFREYA("/usr/lib/liblzmadec.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhistory.6.dylib");
        removeFileIfExistsFREYA("/usr/lib/libformw.dylib");
        removeFileIfExistsFREYA("/usr/lib/libncursesw.dylib");
        removeFileIfExistsFREYA("/usr/lib/libncurses.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libreadline.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhistory.6.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libform.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpanelw.dylib");
        removeFileIfExistsFREYA("/usr/lib/libmenuw.dylib");
        removeFileIfExistsFREYA("/usr/lib/libform.dylib");
        removeFileIfExistsFREYA("/usr/lib/terminfo");
        removeFileIfExistsFREYA("/usr/lib/terminfo");
        removeFileIfExistsFREYA("/usr/lib/libpam.1.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libmenu.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpatcyh.dylib");
        removeFileIfExistsFREYA("/usr/lib/libreadline.6.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/liblzmadec.dylib");
        removeFileIfExistsFREYA("/usr/lib/libncurses.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhistory.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpamc.dylib");
        removeFileIfExistsFREYA("/usr/lib/libformw.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libapt-inst.dylib.1.1.0");
        removeFileIfExistsFREYA("/usr/lib/libapt-inst.1.1.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpanel.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/liblzmadec.0.0.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/_ncurses");
        removeFileIfExistsFREYA("/usr/lib/libpam_misc.1.dylib");
        removeFileIfExistsFREYA("/usr/lib/libreadline.5.2.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpam_misc.dylib");
        removeFileIfExistsFREYA("/usr/lib/libreadline.dylib");
        removeFileIfExistsFREYA("/usr/lib/libmenuw.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libpam.1.dylib");
        removeFileIfExistsFREYA("/usr/lib/libmenu.dylib");
        removeFileIfExistsFREYA("/usr/lib/liblzmadec.la");
        removeFileIfExistsFREYA("/usr/lib/libncursesw.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libcycript.dylib");
        removeFileIfExistsFREYA("/usr/lib/libcycript.jar");
        removeFileIfExistsFREYA("/usr/lib/libcycript.db");
        removeFileIfExistsFREYA("/usr/lib/libcurl.4.dylib");
        removeFileIfExistsFREYA("/usr/lib/libcurl.dylib");
        removeFileIfExistsFREYA("/usr/lib/libcurl.la");
        removeFileIfExistsFREYA("/usr/lib/libcycript.0.dylib");
        removeFileIfExistsFREYA("/usr/lib/libcycript.cy");
        removeFileIfExistsFREYA("/usr/lib/libcephei.dylib");
        removeFileIfExistsFREYA("/usr/lib/libcepheiprefs.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhbangcommon.dylib");
        removeFileIfExistsFREYA("/usr/lib/libhbangprefs.dylib");
        /////end it
        removeFileIfExistsFREYA("/usr/lib/libjailbreak.dylib");
        removeFileIfExistsFREYA("/var/profile");
        removeFileIfExistsFREYA("/var/motd");
        removeFileIfExistsFREYA("/var/log/testbin.log");
        removeFileIfExistsFREYA("/var/log/apt");
        removeFileIfExistsFREYA("/var/log/jailbreakd-stderr.log");
        removeFileIfExistsFREYA("/var/log/jailbreakd-stdout.log");
        removeFileIfExistsFREYA("/Library/test_inject_springboard.cy");
        removeFileIfExistsFREYA("/usr/local/lib/libluajit.a");
        removeFileIfExistsFREYA("/bin/zsh");
        //missing from removeMe.sh oddly
        //////mine above lol
        //////////////////Jakes below
        
        removeFileIfExistsFREYA("/var/LIB");
        removeFileIfExistsFREYA("/var/bin");
        removeFileIfExistsFREYA("/var/sbin");
        removeFileIfExistsFREYA("/var/profile");
        removeFileIfExistsFREYA("/var/motd");
        removeFileIfExistsFREYA("/var/dropbear");
        removeFileIfExistsFREYA("/var/containers/Bundle/tweaksupport");
        removeFileIfExistsFREYA("/var/containers/Bundle/iosbinpack64");
        removeFileIfExistsFREYA("/var/containers/Bundle/dylibs");
        removeFileIfExistsFREYA("/var/LIB");
        removeFileIfExistsFREYA("/var/motd");
        removeFileIfExistsFREYA("/var/log/testbin.log");
        removeFileIfExistsFREYA("/var/log/jailbreakd-stdout.log");
        removeFileIfExistsFREYA("/var/log/jailbreakd-stderr.log");
        removeFileIfExistsFREYA("/usr/bin/find");
        
        removeFileIfExistsFREYA("/var/cache");
        removeFileIfExistsFREYA("/var/freya");
        removeFileIfExistsFREYA("/var/lib");
        removeFileIfExistsFREYA("/var/stash");
        removeFileIfExistsFREYA("/var/db/stash");
        removeFileIfExistsFREYA("/var/mobile/Library/Cydia");
        removeFileIfExistsFREYA("/var/mobile/Library/Caches/com.saurik.Cydia");
        removeFileIfExistsFREYA("/etc/apt/sources.list.d");
                     
        removeFileIfExistsFREYA("/etc/apt/sources.list");
        removeFileIfExistsFREYA("/private/etc/apt");
        removeFileIfExistsFREYA("/private/etc/alternatives");
        removeFileIfExistsFREYA("/private/etc/default");
        removeFileIfExistsFREYA("/private/etc/dpkg");
        removeFileIfExistsFREYA("/private/etc/dropbear");
        removeFileIfExistsFREYA("/private/etc/localtime");
        removeFileIfExistsFREYA("/private/etc/motd");
        removeFileIfExistsFREYA("/private/etc/pam.d");
        removeFileIfExistsFREYA("/private/etc/profile");
        removeFileIfExistsFREYA("/private/etc/pkcs11");
        removeFileIfExistsFREYA("/private/etc/profile.d");
        removeFileIfExistsFREYA("/private/etc/profile.ro");
        removeFileIfExistsFREYA("/private/etc/rc.d");
        removeFileIfExistsFREYA("/private/etc/resolv.conf");
        removeFileIfExistsFREYA("/private/etc/ssh");
        removeFileIfExistsFREYA("/private/etc/ssl");
        removeFileIfExistsFREYA("/private/etc/sudo_logsrvd.conf");
        removeFileIfExistsFREYA("/private/etc/sudo.conf");
        removeFileIfExistsFREYA("/private/etc/sudo_logsrvd.conf");
        removeFileIfExistsFREYA("/private/etc/sudoers");
        removeFileIfExistsFREYA("/private/etc/sudoers.d");
        removeFileIfExistsFREYA("/private/etc/sudoers.dist");
        removeFileIfExistsFREYA("/private/etc/wgetrc");
        removeFileIfExistsFREYA("/private/etc/symlibs.dylib");
        removeFileIfExistsFREYA("/private/etc/zshrc");
        removeFileIfExistsFREYA("/private/etc/zprofile");
        
        removeFileIfExistsFREYA("/private/private");
        removeFileIfExistsFREYA("/private/var/containers/Bundle/dylibs");
        removeFileIfExistsFREYA("/private/var/containers/Bundle/iosbinpack64");
        removeFileIfExistsFREYA("/private/var/containers/Bundle/tweaksupport");
        removeFileIfExistsFREYA("/private/var/log/suckmyd-stderr.log");
        removeFileIfExistsFREYA("/private/var/log/suckmyd-stdout.log");
        removeFileIfExistsFREYA("/private/var/log/jailbreakd-stderr.log");
        removeFileIfExistsFREYA("/private/var/log/jailbreakd-stdout.log");
        removeFileIfExistsFREYA("/private/var/backups");
        removeFileIfExistsFREYA("/private/var/empty");
        removeFileIfExistsFREYA("/private/var/bin");
        removeFileIfExistsFREYA("/private/var/cache");
        removeFileIfExistsFREYA("/private/var/cercube_stashed");
        removeFileIfExistsFREYA("/private/var/db/stash");
        removeFileIfExistsFREYA("/private/var/db/sudo");
        removeFileIfExistsFREYA("/private/var/dropbear");
        removeFileIfExistsFREYA("/private/var/Ext3nder-Installer");
        removeFileIfExistsFREYA("/private/var/lib");
        removeFileIfExistsFREYA("/var/lib");
        removeFileIfExistsFREYA("/private/var/LIB");
        removeFileIfExistsFREYA("/private/var/local");
        removeFileIfExistsFREYA("/private/var/log/apt");
        removeFileIfExistsFREYA("/private/var/log/dpkg");
        removeFileIfExistsFREYA("/private/var/log/testbin.log");
        removeFileIfExistsFREYA("/private/var/lock");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Activator");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist");
        removeFileIfExistsFREYA("/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Activator");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Flex3");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState");
        removeFileIfExistsFREYA("/private/var/mobile/Library/com.saurik.Cydia");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Cr4shed");
        removeFileIfExistsFREYA("/private/var/mobile/Library/CT4");
        removeFileIfExistsFREYA("/private/var/mobile/Library/CT3");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Cydia");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Flex3");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Filza");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Fingal");
        removeFileIfExistsFREYA("/private/var/mobile/Library/iWidgets");
        removeFileIfExistsFREYA("/private/var/mobile/Library/LockHTML");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Logs/Cydia");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Notchification");
        removeFileIfExistsFREYA("/private/var/mobile/Library/unlimapps_tweaks_resources");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Sileo");
        removeFileIfExistsFREYA("/private/var/mobile/Library/SBHTML");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Toonsy");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Widgets");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/libactivator.plist");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.johncoates.Flex");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/AmyCache");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/org.coolstar.SileoStore");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.tigisoftware.Filza");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo");
        removeFileIfExistsFREYA("/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist");
        removeFileIfExistsFREYA("/private/var/mobile/Library/libactivator.plist");
        removeFileIfExistsFREYA("/private/var/motd");
        removeFileIfExistsFREYA("/private/var/profile");
        removeFileIfExistsFREYA("/private/var/run/pspawn_hook.ts");
        removeFileIfExistsFREYA("/private/var/run/utmp");
        removeFileIfExistsFREYA("/private/var/run/sudo");
        removeFileIfExistsFREYA("/private/var/sbin");
        removeFileIfExistsFREYA("/private/var/spool");
        removeFileIfExistsFREYA("/private/var/tmp/cydia.log");
        removeFileIfExistsFREYA("/private/var/tweak");
        removeFileIfExistsFREYA("/private/var/unlimapps_tweak_resources");
        removeFileIfExistsFREYA("/Library/Alkaline");
        removeFileIfExistsFREYA("/Library/Activator");
        removeFileIfExistsFREYA("/Library/Application\ Support/Snoverlay");
        removeFileIfExistsFREYA("/Library/Application\ Support/Flame");
        removeFileIfExistsFREYA("/Library/Application\ Support/CallBlocker");
        removeFileIfExistsFREYA("/Library/Application\ Support/CCSupport");
        removeFileIfExistsFREYA("/Library/Application\ Support/Compatimark");
        removeFileIfExistsFREYA("/Library/Application\ Support/Malipo");
        removeFileIfExistsFREYA("/Library/Application\ Support/SafariPlus.bundle");
        removeFileIfExistsFREYA("/Library/Application\ Support/Activator");
        removeFileIfExistsFREYA("/Library/Application\ Support/Cylinder");
        removeFileIfExistsFREYA("/Library/Application\ Support/Barrel");
        removeFileIfExistsFREYA("/Library/Application\ Support/BarrelSettings");
        removeFileIfExistsFREYA("/Library/Application\ Support/libGitHubIssues");
        removeFileIfExistsFREYA("/Library/Barrel");
        removeFileIfExistsFREYA("/Library/BarrelSettings");
        removeFileIfExistsFREYA("/Library/Cylinder");
        removeFileIfExistsFREYA("/Library/dpkg");
        removeFileIfExistsFREYA("/Library/Flipswitch");
        removeFileIfExistsFREYA("/Library/Frameworks");
        removeFileIfExistsFREYA("/Library/LaunchDaemons");
        removeFileIfExistsFREYA("/Library/MobileSubstrate");
        removeFileIfExistsFREYA("/Library/MobileSubstrate/");
        removeFileIfExistsFREYA("/Library/MobileSubstrate/DynamicLibraries");
        removeFileIfExistsFREYA("/Library/PreferenceBundles");
        removeFileIfExistsFREYA("/Library/PreferenceLoader");
        removeFileIfExistsFREYA("/Library/SBInject");
        removeFileIfExistsFREYA("/Library/Switches");
        removeFileIfExistsFREYA("/Library/test_inject_springboard.cy");
        removeFileIfExistsFREYA("/Library/Themes");
        removeFileIfExistsFREYA("/Library/TweakInject");
        removeFileIfExistsFREYA("/Library/Zeppelin");
        removeFileIfExistsFREYA("/Library/.DS_Store");
        removeFileIfExistsFREYA("/System/Library/PreferenceBundles/AppList.bundle");
        removeFileIfExistsFREYA("/System/Library/Themes");
        removeFileIfExistsFREYA("/System/Library/KeyboardDictionaries");
        removeFileIfExistsFREYA("/usr/lib/libform.dylib");
        removeFileIfExistsFREYA("/usr/lib/libncurses.5.dylib");
        removeFileIfExistsFREYA("/usr/lib/libresolv.dylib");
        removeFileIfExistsFREYA("/usr/lib/liblzma.dylib");
        removeFileIfExistsFREYA("/usr/include");
        removeFileIfExistsFREYA("/usr/share/aclocal");
        removeFileIfExistsFREYA("/usr/share/bigboss");
        removeFileIfExistsFREYA("/share/common-lisp");
        removeFileIfExistsFREYA("/usr/share/dict");
        removeFileIfExistsFREYA("/usr/share/dpkg");
        removeFileIfExistsFREYA("/usr/share/git-core");
        removeFileIfExistsFREYA("/usr/share/git-gui");
        removeFileIfExistsFREYA("/usr/share/gnupg");
        removeFileIfExistsFREYA("/usr/share/gitk");
        removeFileIfExistsFREYA("/usr/share/gitweb");
        removeFileIfExistsFREYA("/usr/share/libgpg-error");
        removeFileIfExistsFREYA("/usr/share/man");
        removeFileIfExistsFREYA("/usr/share/p11-kit");
        removeFileIfExistsFREYA("/usr/share/tabset");
        removeFileIfExistsFREYA("/usr/share/terminfo");
        removeFileIfExistsFREYA("/.freya_installed");
        removeFileIfExistsFREYA("/.freya_bootstrap");
        
        
        
        ////////
    }
    //////////////////////////////
    //////////////////////////////finally added the check for changing remvoving files without needing two separate apps
    
    else if (/* iOS 11.3 and higher can use lucky snapshot */ kCFCoreFoundationVersionNumber > 1451.51){ printf("[*] Removing Jailbreak for devices greater or equal to ios 11.3....\n");
            removeFileIfExistsFREYA("/private/etc/apt");
        
            removeFileIfExistsFREYA("/private/etc/apt");
            removeFileIfExistsFREYA("/var/mobile/testremover.txt");
            removeFileIfExistsFREYA("/private/etc/pam.d");
            removeFileIfExistsFREYA("/private/etc/apt");
            removeFileIfExistsFREYA("/private/etc/alternatives");
            removeFileIfExistsFREYA("/private/etc/default");
            removeFileIfExistsFREYA("/private/etc/dpkg");
            removeFileIfExistsFREYA("/private/etc/dropbear");
            removeFileIfExistsFREYA("/private/etc/localtime");
            removeFileIfExistsFREYA("/private/etc/motd");
            removeFileIfExistsFREYA("/private/etc/pam.d");
            removeFileIfExistsFREYA("/private/etc/profile");
            removeFileIfExistsFREYA("/private/etc/pkcs11");
            removeFileIfExistsFREYA("/private/etc/profile.d");
            removeFileIfExistsFREYA("/private/etc/profile.ro");
            removeFileIfExistsFREYA("/private/etc/rc.d");
            removeFileIfExistsFREYA("/private/etc/resolv.conf");
            removeFileIfExistsFREYA("/private/etc/ssh");
            removeFileIfExistsFREYA("/private/etc/ssl");
            removeFileIfExistsFREYA("/private/etc/sudo_logsrvd.conf");
            removeFileIfExistsFREYA("/private/etc/sudo.conf");
            removeFileIfExistsFREYA("/private/etc/sudo_logsrvd.conf");
            removeFileIfExistsFREYA("/private/etc/sudoers");
            removeFileIfExistsFREYA("/private/etc/sudoers.d");
            removeFileIfExistsFREYA("/private/etc/sudoers.dist");
            removeFileIfExistsFREYA("/private/etc/wgetrc");
            removeFileIfExistsFREYA("/private/etc/symlibs.dylib");
            removeFileIfExistsFREYA("/private/etc/zshrc");
            removeFileIfExistsFREYA("/private/etc/zprofile");
            removeFileIfExistsFREYA("/private/var/backups");
            removeFileIfExistsFREYA("/private/var/cache");
            removeFileIfExistsFREYA("/private/var/Ext3nder-Installer");
            removeFileIfExistsFREYA("/private/var/lib");
            removeFileIfExistsFREYA("/private/var/local");
            removeFileIfExistsFREYA("/private/var/lock");
            removeFileIfExistsFREYA("/private/var/spool");
            removeFileIfExistsFREYA("/private/var/lib/apt");
            removeFileIfExistsFREYA("/private/var/lib/dpkg");
            removeFileIfExistsFREYA("/private/var/lib/dpkg");
            removeFileIfExistsFREYA("/private/var/lib/cydia");
            removeFileIfExistsFREYA("/private/var/db/stash");
            removeFileIfExistsFREYA("/private/var/stash");
            removeFileIfExistsFREYA("/private/var/tweak");
            removeFileIfExistsFREYA("/private/var/cercube_stashed");
            removeFileIfExistsFREYA("/private/var/tmp/cydia.log");
            removeFileIfExistsFREYA("/private/var/run/utmp");
            removeFileIfExistsFREYA("/private/var/profile");
            removeFileIfExistsFREYA("/private/var/motd");
            removeFileIfExistsFREYA("/private/var/log/testbin.log");
            removeFileIfExistsFREYA("/private/var/log/apt");
            removeFileIfExistsFREYA("/private/var/log/jailbreakd-stderr.log");
            removeFileIfExistsFREYA("/private/var/log/jailbreakd-stdout.log");
            removeFileIfExistsFREYA("/private/var/LIB");
            removeFileIfExistsFREYA("/private/var/bin");
            removeFileIfExistsFREYA("/private/var/sbin");
            removeFileIfExistsFREYA("/private/var/dropbear");
            removeFileIfExistsFREYA("/private/var/empty");
            removeFileIfExistsFREYA("/private/var/bin");
            removeFileIfExistsFREYA("/private/var/cercube_stashed");
            removeFileIfExistsFREYA("/private/var/db/sudo");
            removeFileIfExistsFREYA("/private/var/log/dpkg");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/tweaksupport");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/iosbinpack64");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/dylibs");
            removeFileIfExistsFREYA("/private/var/freya/");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Flex3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Notchification");
            removeFileIfExistsFREYA("/private/var/mobile/Library/unlimapps_tweaks_resources");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Fingal");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/CT3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/com.saurik.Cydia/");
            removeFileIfExistsFREYA("/private/var/mobile/Library/SBHTML");
            removeFileIfExistsFREYA("/private/var/mobile/Library/LockHTML");
            removeFileIfExistsFREYA("/private/var/mobile/Library/iWidgets");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Flex3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/libactivator.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.tigisoftware.Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.johncoates.Flex");
            removeFileIfExistsFREYA("/private/var/mobile/Library/libactivator.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Activator");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Activator");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal");
            removeFileIfExistsFREYA("/private/var/run/utmp");
            removeFileIfExistsFREYA("/private/var/run/pspawn_hook.ts");
            removeFileIfExistsFREYA("/var/mobile/Library/Cydia");
            removeFileIfExistsFREYA("/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/private");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/dylibs");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/iosbinpack64");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/tweaksupport");
            removeFileIfExistsFREYA("/private/var/log/suckmyd-stderr.log");
            removeFileIfExistsFREYA("/private/var/log/suckmyd-stdout.log");
            removeFileIfExistsFREYA("/private/var/log/jailbreakd-stderr.log");
            removeFileIfExistsFREYA("/private/var/log/jailbreakd-stdout.log");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Activator");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Activator");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Flex3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState");
            removeFileIfExistsFREYA("/private/var/mobile/Library/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Cr4shed");
            removeFileIfExistsFREYA("/private/var/mobile/Library/CT4");
            removeFileIfExistsFREYA("/private/var/mobile/Library/CT3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Flex3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Fingal");
            removeFileIfExistsFREYA("/private/var/mobile/Library/iWidgets");
            removeFileIfExistsFREYA("/private/var/mobile/Library/LockHTML");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Logs/Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Notchification");
            removeFileIfExistsFREYA("/private/var/mobile/Library/unlimapps_tweaks_resources");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Sileo");
            removeFileIfExistsFREYA("/private/var/mobile/Library/SBHTML");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Toonsy");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Widgets");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/libactivator.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.johncoates.Flex");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/AmyCache");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/org.coolstar.SileoStore");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.tigisoftware.Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/libactivator.plist");
            removeFileIfExistsFREYA("/private/var/motd");
            removeFileIfExistsFREYA("/private/var/profile");
            removeFileIfExistsFREYA("/private/var/run/pspawn_hook.ts");
            removeFileIfExistsFREYA("/private/var/run/utmp");
            removeFileIfExistsFREYA("/private/var/run/sudo");
            removeFileIfExistsFREYA("/private/var/sbin");
            removeFileIfExistsFREYA("/private/var/spool");
            removeFileIfExistsFREYA("/private/var/tmp/cydia.log");
            removeFileIfExistsFREYA("/private/var/tweak");
            removeFileIfExistsFREYA("/private/var/unlimapps_tweak_resources");
            removeFileIfExistsFREYA("/var/cache");
            removeFileIfExistsFREYA("/var/freya");
            removeFileIfExistsFREYA("/var/lib");
            removeFileIfExistsFREYA("/var/stash");
            removeFileIfExistsFREYA("/var/db/stash");
            removeFileIfExistsFREYA("/var/mobile/Library/Cydia");
            removeFileIfExistsFREYA("/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/etc/apt/sources.list.d");
            removeFileIfExistsFREYA("/etc/apt/sources.list");
            removeFileIfExistsFREYA("/private/etc/apt");
            removeFileIfExistsFREYA("/private/etc/alternatives");
            removeFileIfExistsFREYA("/private/etc/default");
            removeFileIfExistsFREYA("/private/etc/dpkg");
            removeFileIfExistsFREYA("/private/etc/dropbear");
            removeFileIfExistsFREYA("/private/etc/localtime");
            removeFileIfExistsFREYA("/private/etc/motd");
            removeFileIfExistsFREYA("/private/etc/pam.d");
            removeFileIfExistsFREYA("/private/etc/profile");
            removeFileIfExistsFREYA("/private/etc/pkcs11");
            removeFileIfExistsFREYA("/private/etc/profile.d");
            removeFileIfExistsFREYA("/private/etc/profile.ro");
            removeFileIfExistsFREYA("/private/etc/rc.d");
            removeFileIfExistsFREYA("/private/etc/resolv.conf");
            removeFileIfExistsFREYA("/private/etc/ssh");
            removeFileIfExistsFREYA("/private/etc/ssl");
            removeFileIfExistsFREYA("/private/etc/sudo_logsrvd.conf");
            removeFileIfExistsFREYA("/private/etc/sudo.conf");
            removeFileIfExistsFREYA("/private/etc/sudo_logsrvd.conf");
            removeFileIfExistsFREYA("/private/etc/sudoers");
            removeFileIfExistsFREYA("/private/etc/sudoers.d");
            removeFileIfExistsFREYA("/private/etc/sudoers.dist");
            removeFileIfExistsFREYA("/private/etc/wgetrc");
            removeFileIfExistsFREYA("/private/etc/symlibs.dylib");
            removeFileIfExistsFREYA("/private/etc/zshrc");
            removeFileIfExistsFREYA("/private/etc/zprofile");
            removeFileIfExistsFREYA("/private/private");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/dylibs");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/iosbinpack64");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/tweaksupport");
            removeFileIfExistsFREYA("/private/var/log/suckmyd-stderr.log");
            removeFileIfExistsFREYA("/private/var/log/suckmyd-stdout.log");
            removeFileIfExistsFREYA("/private/var/log/jailbreakd-stderr.log");
            removeFileIfExistsFREYA("/private/var/log/jailbreakd-stdout.log");
            removeFileIfExistsFREYA("/private/var/backups");
            removeFileIfExistsFREYA("/private/var/empty");
            removeFileIfExistsFREYA("/private/var/bin");
            removeFileIfExistsFREYA("/private/var/cache");
            removeFileIfExistsFREYA("/private/var/cercube_stashed");
            removeFileIfExistsFREYA("/private/var/db/stash");
            removeFileIfExistsFREYA("/private/var/db/sudo");
            removeFileIfExistsFREYA("/private/var/dropbear");
            removeFileIfExistsFREYA("/private/var/Ext3nder-Installer");
            removeFileIfExistsFREYA("/private/var/lib");
            removeFileIfExistsFREYA("/var/lib");
            removeFileIfExistsFREYA("/private/var/LIB");
            removeFileIfExistsFREYA("/private/var/local");
            removeFileIfExistsFREYA("/private/var/log/apt");
            removeFileIfExistsFREYA("/private/var/log/dpkg");
            removeFileIfExistsFREYA("/private/var/log/testbin.log");
            removeFileIfExistsFREYA("/private/var/lock");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Activator");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Activator");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Flex3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState");
            removeFileIfExistsFREYA("/private/var/mobile/Library/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Cr4shed");
            removeFileIfExistsFREYA("/private/var/mobile/Library/CT4");
            removeFileIfExistsFREYA("/private/var/mobile/Library/CT3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Flex3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Fingal");
            removeFileIfExistsFREYA("/private/var/mobile/Library/iWidgets");
            removeFileIfExistsFREYA("/private/var/mobile/Library/LockHTML");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Logs/Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Notchification");
            removeFileIfExistsFREYA("/private/var/mobile/Library/unlimapps_tweaks_resources");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Sileo");
            removeFileIfExistsFREYA("/private/var/mobile/Library/SBHTML");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Toonsy");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Widgets");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/libactivator.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.johncoates.Flex");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/AmyCache");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/org.coolstar.SileoStore");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.tigisoftware.Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/libactivator.plist");
            removeFileIfExistsFREYA("/private/var/motd");
            removeFileIfExistsFREYA("/private/var/profile");
            removeFileIfExistsFREYA("/private/var/run/pspawn_hook.ts");
            removeFileIfExistsFREYA("/private/var/run/utmp");
            removeFileIfExistsFREYA("/private/var/run/sudo");
            removeFileIfExistsFREYA("/private/var/sbin");
            removeFileIfExistsFREYA("/private/var/spool");
            removeFileIfExistsFREYA("/private/var/tmp/cydia.log");
            removeFileIfExistsFREYA("/private/var/tweak");
            removeFileIfExistsFREYA("/private/var/unlimapps_tweak_resources");
            
            removeFileIfExistsFREYA("/var/mobile/testremover.txt");
            removeFileIfExistsFREYA("/private/etc/pam.d");
            removeFileIfExistsFREYA("/private/etc/apt");
            removeFileIfExistsFREYA("/private/etc/alternatives");
            removeFileIfExistsFREYA("/private/etc/default");
            removeFileIfExistsFREYA("/private/etc/dpkg");
            removeFileIfExistsFREYA("/private/etc/dropbear");
            removeFileIfExistsFREYA("/private/etc/localtime");
            removeFileIfExistsFREYA("/private/etc/motd");
            removeFileIfExistsFREYA("/private/etc/pam.d");
            removeFileIfExistsFREYA("/private/etc/profile");
            removeFileIfExistsFREYA("/private/etc/pkcs11");
            removeFileIfExistsFREYA("/private/etc/profile.d");
            removeFileIfExistsFREYA("/private/etc/profile.ro");
            removeFileIfExistsFREYA("/private/etc/rc.d");
            removeFileIfExistsFREYA("/private/etc/resolv.conf");
            removeFileIfExistsFREYA("/private/etc/ssh");
            removeFileIfExistsFREYA("/private/etc/ssl");
            removeFileIfExistsFREYA("/private/etc/sudo_logsrvd.conf");
            removeFileIfExistsFREYA("/private/etc/sudo.conf");
            removeFileIfExistsFREYA("/private/etc/sudo_logsrvd.conf");
            removeFileIfExistsFREYA("/private/etc/sudoers");
            removeFileIfExistsFREYA("/private/etc/sudoers.d");
            removeFileIfExistsFREYA("/private/etc/sudoers.dist");
            removeFileIfExistsFREYA("/private/etc/wgetrc");
            removeFileIfExistsFREYA("/private/etc/symlibs.dylib");
            removeFileIfExistsFREYA("/private/etc/zshrc");
            removeFileIfExistsFREYA("/private/etc/zprofile");
            removeFileIfExistsFREYA("/private/var/backups");
            removeFileIfExistsFREYA("/private/var/cache");
            removeFileIfExistsFREYA("/private/var/Ext3nder-Installer");
            removeFileIfExistsFREYA("/private/var/lib");
            removeFileIfExistsFREYA("/private/var/local");
            removeFileIfExistsFREYA("/private/var/lock");
            removeFileIfExistsFREYA("/private/var/spool");
            removeFileIfExistsFREYA("/private/var/lib/apt");
            removeFileIfExistsFREYA("/private/var/lib/dpkg");
            removeFileIfExistsFREYA("/private/var/lib/dpkg");
            removeFileIfExistsFREYA("/private/var/lib/cydia");
            removeFileIfExistsFREYA("/private/var/db/stash");
            removeFileIfExistsFREYA("/private/var/stash");
            removeFileIfExistsFREYA("/private/var/tweak");
            removeFileIfExistsFREYA("/private/var/cercube_stashed");
            removeFileIfExistsFREYA("/private/var/tmp/cydia.log");
            removeFileIfExistsFREYA("/private/var/run/utmp");
            removeFileIfExistsFREYA("/private/var/profile");
            removeFileIfExistsFREYA("/private/var/motd");
            removeFileIfExistsFREYA("/private/var/log/testbin.log");
            removeFileIfExistsFREYA("/private/var/log/apt");
            removeFileIfExistsFREYA("/private/var/log/jailbreakd-stderr.log");
            removeFileIfExistsFREYA("/private/var/log/jailbreakd-stdout.log");
            removeFileIfExistsFREYA("/private/var/LIB");
            removeFileIfExistsFREYA("/private/var/bin");
            removeFileIfExistsFREYA("/private/var/sbin");
            removeFileIfExistsFREYA("/private/var/dropbear");
            removeFileIfExistsFREYA("/private/var/empty");
            removeFileIfExistsFREYA("/private/var/bin");
            removeFileIfExistsFREYA("/private/var/cercube_stashed");
            removeFileIfExistsFREYA("/private/var/db/sudo");
            removeFileIfExistsFREYA("/private/var/log/dpkg");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/tweaksupport");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/iosbinpack64");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/dylibs");
            removeFileIfExistsFREYA("/private/var/freya/");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Flex3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Notchification");
            removeFileIfExistsFREYA("/private/var/mobile/Library/unlimapps_tweaks_resources");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Fingal");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/CT3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/com.saurik.Cydia/");
            removeFileIfExistsFREYA("/private/var/mobile/Library/SBHTML");
            removeFileIfExistsFREYA("/private/var/mobile/Library/LockHTML");
            removeFileIfExistsFREYA("/private/var/mobile/Library/iWidgets");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Flex3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/libactivator.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.tigisoftware.Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.johncoates.Flex");
            removeFileIfExistsFREYA("/private/var/mobile/Library/libactivator.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Activator");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Activator");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal");
            removeFileIfExistsFREYA("/private/var/run/utmp");
            removeFileIfExistsFREYA("/private/var/run/pspawn_hook.ts");
                                                            
            removeFileIfExistsFREYA("/var/mobile/Library/Cydia");
            removeFileIfExistsFREYA("/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/private");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/dylibs");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/iosbinpack64");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/tweaksupport");
            removeFileIfExistsFREYA("/private/var/log/suckmyd-stderr.log");
            removeFileIfExistsFREYA("/private/var/log/suckmyd-stdout.log");
            removeFileIfExistsFREYA("/private/var/log/jailbreakd-stderr.log");
            removeFileIfExistsFREYA("/private/var/log/jailbreakd-stdout.log");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Activator");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Activator");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Flex3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState");
            removeFileIfExistsFREYA("/private/var/mobile/Library/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Cr4shed");
            removeFileIfExistsFREYA("/private/var/mobile/Library/CT4");
            removeFileIfExistsFREYA("/private/var/mobile/Library/CT3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Flex3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Fingal");
            removeFileIfExistsFREYA("/private/var/mobile/Library/iWidgets");
            removeFileIfExistsFREYA("/private/var/mobile/Library/LockHTML");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Logs/Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Notchification");
            removeFileIfExistsFREYA("/private/var/mobile/Library/unlimapps_tweaks_resources");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Sileo");
            removeFileIfExistsFREYA("/private/var/mobile/Library/SBHTML");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Toonsy");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Widgets");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/libactivator.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.johncoates.Flex");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/AmyCache");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/org.coolstar.SileoStore");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.tigisoftware.Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/libactivator.plist");
            removeFileIfExistsFREYA("/private/var/motd");
            removeFileIfExistsFREYA("/private/var/profile");
            removeFileIfExistsFREYA("/private/var/run/pspawn_hook.ts");
            removeFileIfExistsFREYA("/private/var/run/utmp");
            removeFileIfExistsFREYA("/private/var/run/sudo");
            removeFileIfExistsFREYA("/private/var/sbin");
            removeFileIfExistsFREYA("/private/var/spool");
            removeFileIfExistsFREYA("/private/var/tmp/cydia.log");
            removeFileIfExistsFREYA("/private/var/tweak");
            removeFileIfExistsFREYA("/private/var/unlimapps_tweak_resources");
            removeFileIfExistsFREYA("/var/cache");
            removeFileIfExistsFREYA("/var/freya");
            removeFileIfExistsFREYA("/var/lib");
            removeFileIfExistsFREYA("/var/stash");
            removeFileIfExistsFREYA("/var/db/stash");
            removeFileIfExistsFREYA("/var/mobile/Library/Cydia");
            removeFileIfExistsFREYA("/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/etc/apt/sources.list.d");
            removeFileIfExistsFREYA("/etc/apt/sources.list");
            removeFileIfExistsFREYA("/private/etc/apt");
            removeFileIfExistsFREYA("/private/etc/alternatives");
            removeFileIfExistsFREYA("/private/etc/default");
            removeFileIfExistsFREYA("/private/etc/dpkg");
            removeFileIfExistsFREYA("/private/etc/dropbear");
            removeFileIfExistsFREYA("/private/etc/localtime");
            removeFileIfExistsFREYA("/private/etc/motd");
            removeFileIfExistsFREYA("/private/etc/pam.d");
            removeFileIfExistsFREYA("/private/etc/profile");
            removeFileIfExistsFREYA("/private/etc/pkcs11");
            removeFileIfExistsFREYA("/private/etc/profile.d");
            removeFileIfExistsFREYA("/private/etc/profile.ro");
            removeFileIfExistsFREYA("/private/etc/rc.d");
            removeFileIfExistsFREYA("/private/etc/resolv.conf");
            removeFileIfExistsFREYA("/private/etc/ssh");
            removeFileIfExistsFREYA("/private/etc/ssl");
            removeFileIfExistsFREYA("/private/etc/sudo_logsrvd.conf");
            removeFileIfExistsFREYA("/private/etc/sudo.conf");
            removeFileIfExistsFREYA("/private/etc/sudo_logsrvd.conf");
            removeFileIfExistsFREYA("/private/etc/sudoers");
            removeFileIfExistsFREYA("/private/etc/sudoers.d");
            removeFileIfExistsFREYA("/private/etc/sudoers.dist");
            removeFileIfExistsFREYA("/private/etc/wgetrc");
            removeFileIfExistsFREYA("/private/etc/symlibs.dylib");
            removeFileIfExistsFREYA("/private/etc/zshrc");
            removeFileIfExistsFREYA("/private/etc/zprofile");
            removeFileIfExistsFREYA("/private/private");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/dylibs");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/iosbinpack64");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/tweaksupport");
            removeFileIfExistsFREYA("/private/var/log/suckmyd-stderr.log");
            removeFileIfExistsFREYA("/private/var/log/suckmyd-stdout.log");
            removeFileIfExistsFREYA("/private/var/log/jailbreakd-stderr.log");
            removeFileIfExistsFREYA("/private/var/log/jailbreakd-stdout.log");
            removeFileIfExistsFREYA("/private/var/backups");
            removeFileIfExistsFREYA("/private/var/empty");
            removeFileIfExistsFREYA("/private/var/bin");
            removeFileIfExistsFREYA("/private/var/cache");
            removeFileIfExistsFREYA("/private/var/cercube_stashed");
            removeFileIfExistsFREYA("/private/var/db/stash");
            removeFileIfExistsFREYA("/private/var/db/sudo");
            removeFileIfExistsFREYA("/private/var/dropbear");
            removeFileIfExistsFREYA("/private/var/Ext3nder-Installer");
            removeFileIfExistsFREYA("/private/var/lib");
            removeFileIfExistsFREYA("/var/lib");
            removeFileIfExistsFREYA("/private/var/LIB");
            removeFileIfExistsFREYA("/private/var/local");
            removeFileIfExistsFREYA("/private/var/log/apt");
            removeFileIfExistsFREYA("/private/var/log/dpkg");
            removeFileIfExistsFREYA("/private/var/log/testbin.log");
            removeFileIfExistsFREYA("/private/var/lock");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Activator");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Activator");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Flex3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState");
            removeFileIfExistsFREYA("/private/var/mobile/Library/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Cr4shed");
            removeFileIfExistsFREYA("/private/var/mobile/Library/CT4");
            removeFileIfExistsFREYA("/private/var/mobile/Library/CT3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Flex3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Fingal");
            removeFileIfExistsFREYA("/private/var/mobile/Library/iWidgets");
            removeFileIfExistsFREYA("/private/var/mobile/Library/LockHTML");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Logs/Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Notchification");
            removeFileIfExistsFREYA("/private/var/mobile/Library/unlimapps_tweaks_resources");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Sileo");
            removeFileIfExistsFREYA("/private/var/mobile/Library/SBHTML");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Toonsy");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Widgets");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/libactivator.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.johncoates.Flex");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/AmyCache");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/org.coolstar.SileoStore");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.tigisoftware.Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/libactivator.plist");
            removeFileIfExistsFREYA("/private/var/motd");
            removeFileIfExistsFREYA("/private/var/profile");
            removeFileIfExistsFREYA("/private/var/run/pspawn_hook.ts");
            removeFileIfExistsFREYA("/private/var/run/utmp");
            removeFileIfExistsFREYA("/private/var/run/sudo");
            removeFileIfExistsFREYA("/private/var/sbin");
            removeFileIfExistsFREYA("/private/var/spool");
            removeFileIfExistsFREYA("/private/var/tmp/cydia.log");
            removeFileIfExistsFREYA("/private/var/tweak");
            removeFileIfExistsFREYA("/private/var/unlimapps_tweak_resources");
            removeFileIfExistsFREYA("/var/mobile/testremover.txt");
            removeFileIfExistsFREYA("/private/etc/pam.d");
            //private/etc
            removeFileIfExistsFREYA("/private/etc/apt");
            removeFileIfExistsFREYA("/private/etc/alternatives");
            removeFileIfExistsFREYA("/private/etc/default");
            removeFileIfExistsFREYA("/private/etc/dpkg");
            removeFileIfExistsFREYA("/private/etc/dropbear");
            removeFileIfExistsFREYA("/private/etc/localtime");
            removeFileIfExistsFREYA("/private/etc/motd");
            removeFileIfExistsFREYA("/private/etc/pam.d");
            removeFileIfExistsFREYA("/private/etc/profile");
            removeFileIfExistsFREYA("/private/etc/pkcs11");
            removeFileIfExistsFREYA("/private/etc/profile.d");
            removeFileIfExistsFREYA("/private/etc/profile.ro");
            removeFileIfExistsFREYA("/private/etc/rc.d");
            removeFileIfExistsFREYA("/private/etc/resolv.conf");
            removeFileIfExistsFREYA("/private/etc/ssh");
            removeFileIfExistsFREYA("/private/etc/ssl");
            removeFileIfExistsFREYA("/private/etc/sudo_logsrvd.conf");
            removeFileIfExistsFREYA("/private/etc/sudo.conf");
            removeFileIfExistsFREYA("/private/etc/sudo_logsrvd.conf");
            removeFileIfExistsFREYA("/private/etc/sudoers");
            removeFileIfExistsFREYA("/private/etc/sudoers.d");
            removeFileIfExistsFREYA("/private/etc/sudoers.dist");
            removeFileIfExistsFREYA("/private/etc/wgetrc");
            removeFileIfExistsFREYA("/private/etc/symlibs.dylib");
            removeFileIfExistsFREYA("/private/etc/zshrc");
            removeFileIfExistsFREYA("/private/etc/zprofile");
            ////private/var
            removeFileIfExistsFREYA("/private/var/backups");
            removeFileIfExistsFREYA("/private/var/cache");
            removeFileIfExistsFREYA("/private/var/Ext3nder-Installer");
            removeFileIfExistsFREYA("/private/var/lib");
            removeFileIfExistsFREYA("/private/var/local");
            removeFileIfExistsFREYA("/private/var/lock");
            removeFileIfExistsFREYA("/private/var/spool");
            removeFileIfExistsFREYA("/private/var/lib/apt");
            removeFileIfExistsFREYA("/private/var/lib/dpkg");
            removeFileIfExistsFREYA("/private/var/lib/dpkg");
            removeFileIfExistsFREYA("/private/var/lib/cydia");
            removeFileIfExistsFREYA("/private/var/db/stash");
            removeFileIfExistsFREYA("/private/var/stash");
            removeFileIfExistsFREYA("/private/var/tweak");
            removeFileIfExistsFREYA("/private/var/cercube_stashed");
            removeFileIfExistsFREYA("/private/var/tmp/cydia.log");
            removeFileIfExistsFREYA("/private/var/run/utmp");
            removeFileIfExistsFREYA("/private/var/profile");
            removeFileIfExistsFREYA("/private/var/motd");
            removeFileIfExistsFREYA("/private/var/log/testbin.log");
            removeFileIfExistsFREYA("/private/var/log/apt");
            removeFileIfExistsFREYA("/private/var/log/jailbreakd-stderr.log");
            removeFileIfExistsFREYA("/private/var/log/jailbreakd-stdout.log");
            removeFileIfExistsFREYA("/private/var/LIB");
            removeFileIfExistsFREYA("/private/var/bin");
            removeFileIfExistsFREYA("/private/var/sbin");
            removeFileIfExistsFREYA("/private/var/dropbear");
            removeFileIfExistsFREYA("/private/var/empty");
            removeFileIfExistsFREYA("/private/var/bin");
            removeFileIfExistsFREYA("/private/var/cercube_stashed");
            removeFileIfExistsFREYA("/private/var/db/sudo");
            removeFileIfExistsFREYA("/private/var/log/dpkg");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/tweaksupport");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/iosbinpack64");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/dylibs");
            removeFileIfExistsFREYA("/private/var/freya/");
            //var/mobile/Library
            removeFileIfExistsFREYA("/private/var/mobile/Library/Flex3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Notchification");
            removeFileIfExistsFREYA("/private/var/mobile/Library/unlimapps_tweaks_resources");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Fingal");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/CT3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/com.saurik.Cydia/");
            removeFileIfExistsFREYA("/private/var/mobile/Library/SBHTML");
            removeFileIfExistsFREYA("/private/var/mobile/Library/LockHTML");
            removeFileIfExistsFREYA("/private/var/mobile/Library/iWidgets");
            //var/mobile/Library/Caches
            removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Flex3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/libactivator.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.tigisoftware.Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.johncoates.Flex");
            removeFileIfExistsFREYA("/private/var/mobile/Library/libactivator.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Activator");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Activator");
            //snapshot.library
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal");
            removeFileIfExistsFREYA("/private/var/run/utmp");
            removeFileIfExistsFREYA("/private/var/run/pspawn_hook.ts");
            //////system/library
            removeFileIfExistsFREYA("/var/mobile/Library/Cydia");
            removeFileIfExistsFREYA("/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/private");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/dylibs");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/iosbinpack64");
            removeFileIfExistsFREYA("/private/var/containers/Bundle/tweaksupport");
            removeFileIfExistsFREYA("/private/var/log/suckmyd-stderr.log");
            removeFileIfExistsFREYA("/private/var/log/suckmyd-stdout.log");
            removeFileIfExistsFREYA("/private/var/log/jailbreakd-stderr.log");
            removeFileIfExistsFREYA("/private/var/log/jailbreakd-stdout.log");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Activator");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Activator");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Application\ Support/Flex3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState");
            removeFileIfExistsFREYA("/private/var/mobile/Library/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Cr4shed");
            removeFileIfExistsFREYA("/private/var/mobile/Library/CT4");
            removeFileIfExistsFREYA("/private/var/mobile/Library/CT3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Flex3");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Fingal");
            removeFileIfExistsFREYA("/private/var/mobile/Library/iWidgets");
            removeFileIfExistsFREYA("/private/var/mobile/Library/LockHTML");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Logs/Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Notchification");
            removeFileIfExistsFREYA("/private/var/mobile/Library/unlimapps_tweaks_resources");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Sileo");
            removeFileIfExistsFREYA("/private/var/mobile/Library/SBHTML");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Toonsy");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Widgets");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/libactivator.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.johncoates.Flex");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/AmyCache");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/org.coolstar.SileoStore");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/com.tigisoftware.Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo");
            removeFileIfExistsFREYA("/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist");
            removeFileIfExistsFREYA("/private/var/mobile/Library/libactivator.plist");
            removeFileIfExistsFREYA("/private/var/motd");
            removeFileIfExistsFREYA("/private/var/profile");
            removeFileIfExistsFREYA("/private/var/run/pspawn_hook.ts");
            removeFileIfExistsFREYA("/private/var/run/utmp");
            removeFileIfExistsFREYA("/private/var/run/sudo");
            removeFileIfExistsFREYA("/private/var/sbin");
            removeFileIfExistsFREYA("/private/var/spool");
            removeFileIfExistsFREYA("/private/var/tmp/cydia.log");
            removeFileIfExistsFREYA("/private/var/tweak");
            removeFileIfExistsFREYA("/private/var/jb");
            removeFileIfExistsFREYA("/var/jb");
            execCmdFreya("/bin/rm", "-rdvf", "/private/var/jb", NULL);
            execCmdFreya("/bin/rm", "-rdvf", "/var/jb", NULL);
            removeFileIfExistsFREYA("/Library/dpkg");
            removeFileIfExistsFREYA("/Library/LaunchDaemons");
            removeFileIfExistsFREYA("/private/var/unlimapps_tweak_resources");
     //   chdir("/");
        /*int rvchecdothidden1 = execCmdFreya("/usr/bin/find", ".", "-name", "._*", "-type", "f", "-delete", NULL);
        
        printf("[*] Trying find . with ._* delete result = %d \n" , rvchecdothidden1);
       */
        // chdir("/var/");
       /* int rvchecdothidden2 = execCmdFreya("/usr/bin/find", ".", "-name", "._*", "-type", "f", "-delete", NULL);
        
        printf("[*] Trying find in var  . with ._* delete result = %d \n" , rvchecdothidden2);
*/
            printf("[*] Removing Jailbreak with custom remover...\n");
        }
        else {
            printf("FAILED TO REMOVE WITH RM FREYA\n");
        }
}
