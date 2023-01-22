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
            util_info("ERROR REMOVING FILE! ERROR REPORTED: %p", error);
        } else {
            util_info("REMOVED FILE: %p", fileToRM);
        }
    } else {
        util_info("File Doesn't exist. Not removing.");
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
        
        int rvchec1 = execCmdElectra("/usr/bin/find", ".", "-name", "*.deb", "-type", "f", "-delete");
        printf("[*] Trying find . with *.deb delete result = %d \n" , rvchec1);
        ///////delete the Malware from Satan////
        
        int rvchecdothidden1 = execCmdElectra("/usr/bin/find", ".", "-name", "._*", "-type", "f", "-delete");
        printf("[*] Trying find . with ._* delete result = %d \n" , rvchecdothidden1);
        
        printf("[*] Removing Jailbreak with custom remover...\n");
        
        
        removeFileIfExistsE("/private/etc/motd");
        removeFileIfExistsE("/.cydia_no_stash");
        removeFileIfExistsE("/electra/launchctl");
        removeFileIfExistsE("/var/mobile/Media/.bootstrapped_electraremover");
        removeFileIfExistsE("/var/mobile/testremover.txt");
        unlink("/var/mobile/testremover.txt");
        removeFileIfExistsE("/.bootstrapped_Th0r");
        removeFileIfExistsE("/.freya_installed");
        removeFileIfExistsE("/.bootstrapped_electra");
        removeFileIfExistsE("/.installed_unc0ver");
        removeFileIfExistsE("/.install_unc0ver");
        removeFileIfExistsE("/.electra_no_snapshot");
        removeFileIfExistsE("/.installed_unc0vered");
        removeFileIfExistsE("/Applications/Cydia.app");
        removeFileIfExistsE("/Network");
        
        removeFileIfExistsE("/usr/share/aclocal");
        removeFileIfExistsE("/usr/share/bigboss");
        removeFileIfExistsE("/usr/share/common-lisp");
        removeFileIfExistsE("/usr/share/dict");
        removeFileIfExistsE("/usr/share/dpkg");
        removeFileIfExistsE("/usr/share/gnupg");
        removeFileIfExistsE("/usr/share/libgpg-error");
        removeFileIfExistsE("/usr/share/p11-kit");
        removeFileIfExistsE("/usr/share/tabset");
        removeFileIfExistsE("/usr/share/terminfo");
        
        removeFileIfExistsE("/usr/local/bin");
        removeFileIfExistsE("/usr/local/lib");
        
        removeFileIfExistsE("/authorize.sh");
        removeFileIfExistsE("/.cydia_no_stash");
        removeFileIfExistsE("/bin/zsh");
        removeFileIfExistsE("/private/etc/profile");
        removeFileIfExistsE("/private/etc/rc.d");
        removeFileIfExistsE("/private/etc/rc.d/substrate");
        removeFileIfExistsE("/etc/zshrc");
        ////usr/etc//
        removeFileIfExistsE("/usr/etc");
        removeFileIfExistsE("/usr/bin/scp");
        ////usr/lib////
        
        removeFileIfExistsE("/usr/lib/_ncurses");
        removeFileIfExistsE("/usr/lib/apt");
        removeFileIfExistsE("/usr/lib/bash");
        removeFileIfExistsE("/usr/lib/gettext");
        removeFileIfExistsE("/usr/lib/libapt-inst.2.0.0.dylib");
        removeFileIfExistsE("/usr/lib/libapt-inst.2.0.dylib");
        removeFileIfExistsE("/usr/lib/libapt-inst.dylib");
        removeFileIfExistsE("/usr/lib/libapt-pkg.5.0.1.dylib");
        removeFileIfExistsE("/usr/lib/libapt-pkg.5.0.dylib");
        removeFileIfExistsE("/usr/lib/libapt-pkg.dylib");
        removeFileIfExistsE("/usr/lib/libapt-private.0.0.0.dylib");
        removeFileIfExistsE("/usr/lib/libapt-private.0.0.dylib");
        removeFileIfExistsE("/usr/lib/libasprintf.0.dylib");
        removeFileIfExistsE("/usr/lib/libasprintf.dylib");
        removeFileIfExistsE("/usr/lib/libassuan.0.dylib");
        removeFileIfExistsE("/usr/lib/libassuan.dylib");
        removeFileIfExistsE("/usr/lib/libassuan.la");
        removeFileIfExistsE("/usr/lib/libdpkg.a");
        removeFileIfExistsE("/usr/lib/libform.5.dylib");
        removeFileIfExistsE("/usr/lib/libform.6.dylib");
        removeFileIfExistsE("/usr/lib/libform.dylib");
        removeFileIfExistsE("/usr/lib/libform5.dylib");
        removeFileIfExistsE("/usr/lib/libformw.5.dylib");
        removeFileIfExistsE("/usr/lib/libformw.6.dylib");
        removeFileIfExistsE("/usr/lib/libformw.dylib");
        removeFileIfExistsE("/usr/lib/libformw5.dylib");
        removeFileIfExistsE("/usr/lib/libgcrypt.20.dylib");
        removeFileIfExistsE("/usr/lib/libgcrypt.dylib");
        removeFileIfExistsE("/usr/lib/libgcrypt.la");
        removeFileIfExistsE("/usr/lib/libgettextlib-0.19.8.dylib");
        removeFileIfExistsE("/usr/lib/libgettextlib.dylib");
        removeFileIfExistsE("/usr/lib/libgettextpo.1.dylib");
        removeFileIfExistsE("/usr/lib/libgettextpo.dylib");
        removeFileIfExistsE("/usr/lib/libgettextsrc-0.19.8.dylib");
        removeFileIfExistsE("/usr/lib/libgettextsrc.dylib");
        removeFileIfExistsE("/usr/lib/libgmp.10.dylib");
        removeFileIfExistsE("/usr/lib/libgmp.dylib");
        removeFileIfExistsE("/usr/lib/libgmp.la");
        removeFileIfExistsE("/usr/lib/libgnutls.30.dylib");
        removeFileIfExistsE("/usr/lib/libgnutls.dylib");
        removeFileIfExistsE("/usr/lib/libgnutlsxx.28.dylib");
        removeFileIfExistsE("/usr/lib/libgnutlsxx.dylib");
        removeFileIfExistsE("/usr/lib/libgpg-error.0.dylib");
        removeFileIfExistsE("/usr/lib/libgpg-error.dylib");
        removeFileIfExistsE("/usr/lib/libgpg-error.la");
        removeFileIfExistsE("/usr/lib/libhistory.5.2.dylib");
        removeFileIfExistsE("/usr/lib/libhistory.6.0.dylib");
        removeFileIfExistsE("/usr/lib/libhistory.5.dylib");
        removeFileIfExistsE("/usr/lib/libhistory.7.0.dylib");
        removeFileIfExistsE("/usr/lib/libhistory.7.dylib");
        removeFileIfExistsE("/usr/lib/libhistory.dylib ");
        removeFileIfExistsE("/usr/lib/libhogweed.4.4.dylib");
        removeFileIfExistsE("/usr/lib/libhogweed.4.dylib");
        removeFileIfExistsE("/usr/lib/libhogweed.dylib");
        removeFileIfExistsE("/usr/lib/libidn2.0.dylib");
        removeFileIfExistsE("/usr/lib/libidn2.dylib");
        removeFileIfExistsE("/usr/lib/libidn2.la");
        removeFileIfExistsE("/usr/lib/libintl.9.dylib");
        removeFileIfExistsE("/usr/lib/libintl.dylib");
        removeFileIfExistsE("/usr/lib/libksba.8.dylib");
        removeFileIfExistsE("/usr/lib/libksba.dylib");
        removeFileIfExistsE("/usr/lib/libksba.la");
        removeFileIfExistsE("/usr/lib/liblz4.1.7.5.dylib");
        removeFileIfExistsE("/usr/lib/liblz4.1.dylib");
        removeFileIfExistsE("/usr/lib/liblz4.dylib");
        removeFileIfExistsE("/usr/lib/liblzmadec.0.dylib");
        removeFileIfExistsE("/usr/lib/liblzmadec.dylib");
        removeFileIfExistsE("/usr/lib/libmenu.5.dylib");
        removeFileIfExistsE("/usr/lib/libmenu.6.dylib");
        removeFileIfExistsE("/usr/lib/libmenu.dylib");
        removeFileIfExistsE("/usr/lib/libmenu5.dylib");
        removeFileIfExistsE("/usr/lib/libmenuw.5.dylib");
        removeFileIfExistsE("/usr/lib/libmenuw.6.dylib");
        removeFileIfExistsE("/usr/lib/libmenuw.dylib");
        removeFileIfExistsE("/usr/lib/libmenuw5.dylib");
        removeFileIfExistsE("/usr/lib/libncurses.5.dylib");
        removeFileIfExistsE("/usr/lib/libncurses.6.dylib");
        removeFileIfExistsE("/usr/lib/libncurses5.dylib");
        removeFileIfExistsE("/usr/lib/libncurses6.dylib");
        removeFileIfExistsE("/usr/lib/libncursesw.5.dylib");
        removeFileIfExistsE("/usr/lib/libncursesw.6.dylib");
        removeFileIfExistsE("/usr/lib/libncursesw.dylib");
        removeFileIfExistsE("/usr/lib/libncursesw5.dylib");
        removeFileIfExistsE("/usr/lib/libncursesw6.dylib");
        removeFileIfExistsE("/usr/lib/libnettle.6.4.dylib");
        removeFileIfExistsE("/usr/lib/libnettle.6.dylib");
        removeFileIfExistsE("/usr/lib/libnettle.dylib");
        removeFileIfExistsE("/usr/lib/libnpth.0.dylib");
        removeFileIfExistsE("/usr/lib/libnpth.dylib");
        removeFileIfExistsE("/usr/lib/libnpth.la");
        removeFileIfExistsE("/usr/lib/libp11-kit.0.dylib");
        removeFileIfExistsE("/usr/lib/libp11-kit.dylib");
        removeFileIfExistsE("/usr/lib/libp11-kit.la");
        removeFileIfExistsE("/usr/lib/libpanel.5.dylib");
        removeFileIfExistsE("/usr/lib/libpanel.6.dylib");
        removeFileIfExistsE("/usr/lib/libpanel.dylib");
        removeFileIfExistsE("/usr/lib/libpanel5.dylib");
        removeFileIfExistsE("/usr/lib/libpanelw.5.dylib");
        removeFileIfExistsE("/usr/lib/libpanelw.6.dylib");
        removeFileIfExistsE("/usr/lib/libpanelw.dylib");
        removeFileIfExistsE("/usr/lib/libpanelw5.dylib");
        removeFileIfExistsE("/usr/lib/libreadline.5.2.dylib");
        removeFileIfExistsE("/usr/lib/libreadline.6.0.dylib");
        removeFileIfExistsE("/usr/lib/libreadline.5.dylib");
        removeFileIfExistsE("/usr/lib/libreadline.7.0.dylib");
        removeFileIfExistsE("/usr/lib/libreadline.7.dylib");
        removeFileIfExistsE("/usr/lib/libreadline.dylib");
        removeFileIfExistsE("/usr/lib/libresolv.9.dylib");
        removeFileIfExistsE("/usr/lib/libresolv.dylib");
        removeFileIfExistsE("/usr/lib/libtasn1.6.dylib");
        removeFileIfExistsE("/usr/lib/libtasn1.dylib");
        removeFileIfExistsE("/usr/lib/libtasn1.la");
        removeFileIfExistsE("/usr/lib/libunistring.2.dylib");
        removeFileIfExistsE("/usr/lib/libunistring.dylib");
        removeFileIfExistsE("/usr/lib/libunistring.la");
        
        removeFileIfExistsE("/usr/lib/libsubstitute.0.dylib");
        removeFileIfExistsE("/usr/lib/libsubstitute.dylib");
        removeFileIfExistsE("/usr/lib/libsubstrate.dylib");
        removeFileIfExistsE("/usr/lib/libjailbreak.dylib");
        
        removeFileIfExistsE("/usr/bin/recode-sr-latin");
        removeFileIfExistsE("/usr/bin/recache");
        removeFileIfExistsE("/usr/bin/rollectra");
        removeFileIfExistsE("/usr/bin/Rollectra");
        removeFileIfExistsE("/usr/bin/killall");
        
        removeFileIfExistsE("/usr/libexec/sftp-server");
        removeFileIfExistsE("/usr/lib/SBInject.dylib");
        removeFileIfExistsE("/bin/zsh");
        removeFileIfExistsE("/electra-prejailbreak");
        removeFileIfExistsE("/electra/createSnapshot");
        removeFileIfExistsE("/jb");
        removeFileIfExistsE("/jb");
        removeFileIfExistsE("/var/backups");
        ////////////Applications cleanup and root
        removeFileIfExistsE("/RWTEST");
        removeFileIfExistsE("/pwnedWritefileatrootTEST");
        removeFileIfExistsE("/Applications/Cydia\ Update\ Helper.app");
        removeFileIfExistsE("/NETWORK");
        removeFileIfExistsE("/Applications/AppCake.app");
        removeFileIfExistsE("/Applications/Activator.app");
        removeFileIfExistsE("/Applications/Anemone.app");
        removeFileIfExistsE("/Applications/BestCallerId.app");
        removeFileIfExistsE("/Applications/CrackTool3.app");
        removeFileIfExistsE("/Applications/Cydia.app");
        removeFileIfExistsE("/Applications/Sileo.app");
        removeFileIfExistsE("/Applications/Rollectra.app");
        removeFileIfExistsE("/Applications/cydown.app");
        removeFileIfExistsE("/Applications/Cylinder.app");
        removeFileIfExistsE("/Applications/iCleaner.app");
        removeFileIfExistsE("/Applications/icleaner.app");
        removeFileIfExistsE("/Applications/BarrelSettings.app");
        removeFileIfExistsE("/Applications/Ext3nder.app");
        removeFileIfExistsE("/Applications/Filza.app");
        removeFileIfExistsE("/Applications/Flex.app");
        removeFileIfExistsE("/Applications/GBA4iOS.app");
        removeFileIfExistsE("/Applications/jjjj.app");
        removeFileIfExistsE("/Applications/ReProvision.app");
        removeFileIfExistsE("/Applications/SafeMode.app");
        removeFileIfExistsE("/Applications/NewTerm.app");
        removeFileIfExistsE("/Applications/MobileTerminal.app");
        removeFileIfExistsE("/Applications/MTerminal.app");
        removeFileIfExistsE("/Applications/MovieBox3.app");
        removeFileIfExistsE("/Applications/BobbyMovie.app");
        removeFileIfExistsE("/Applications/PopcornTime.app");
        removeFileIfExistsE("/Applications/RST.app");
        removeFileIfExistsE("/Applications/TSSSaver.app");
        removeFileIfExistsE("/Applications/CertRemainTime.app");
        removeFileIfExistsE("/Applications/CrashReporter.app");
        removeFileIfExistsE("/Applications/AudioRecorder.app");
        removeFileIfExistsE("/Applications/ADManager.app");
        removeFileIfExistsE("/Applications/CocoaTop.app");
        removeFileIfExistsE("/Applications/calleridfaker.app");
        removeFileIfExistsE("/Applications/CallLogPro.app");
        removeFileIfExistsE("/Applications/WiFiPasswords.app");
        removeFileIfExistsE("/Applications/WifiPasswordList.app");
        removeFileIfExistsE("/Applications/calleridfaker.app");
        removeFileIfExistsE("/Applications/ClassDumpGUI.app");
        removeFileIfExistsE("/Applications/idevicewallsapp.app");
        removeFileIfExistsE("/Applications/UDIDFaker.app");
        removeFileIfExistsE("/Applications/UDIDCalculator.app");
        removeFileIfExistsE("/Applications/CallRecorder.app");
        removeFileIfExistsE("/Applications/Rehosts.app");
        removeFileIfExistsE("/Applications/NGXCarPlay.app");
        removeFileIfExistsE("/Applications/Audicy.app");
        removeFileIfExistsE("/Applications/NGXCarplay.app");
        ///////////USR/LIBEXEC
        removeFileIfExistsE("/usr/libexec/as");
        removeFileIfExistsE("/usr/libexec/frcode");
        removeFileIfExistsE("/usr/libexec/bigram");
        removeFileIfExistsE("/usr/libexec/code");
        removeFileIfExistsE("/usr/libexec/reload");
        removeFileIfExistsE("/usr/libexec/rmt");
        removeFileIfExistsE("/usr/libexec/MSUnrestrictProcess");
        removeFileIfExistsE("/usr/lib/perl5");
        //////////USR/SHARE
        removeFileIfExistsE("/usr/share/git-core");
        removeFileIfExistsE("/usr/share/git-gui");
        removeFileIfExistsE("/usr/share/gitk");
        removeFileIfExistsE("/usr/share/gitweb");
        removeFileIfExistsE("/usr/share/man");
        ////////USR/LOCAL
        removeFileIfExistsE("/usr/local/bin");
        removeFileIfExistsE("/usr/local/lib");
        removeFileIfExistsE("/usr/local/lib/libluajit.a");
        
        ////var
        removeFileIfExistsE("/var/containers/Bundle/iosbinpack64");
        ////etc folder cleanup
        removeFileIfExistsE("/private/etc/pam.d");
        
        //private/etc
        removeFileIfExistsE("/private/etc/apt");
        removeFileIfExistsE("/private/etc/dropbear");
        removeFileIfExistsE("/private/etc/alternatives");
        removeFileIfExistsE("/private/etc/default");
        removeFileIfExistsE("/private/etc/dpkg");
        removeFileIfExistsE("/private/etc/ssh");
        removeFileIfExistsE("/private/etc/ssl");
        removeFileIfExistsE("/private/etc/profile.d");
        
        ////private/var
        
        removeFileIfExistsE("/private/var/cache");
        removeFileIfExistsE("/private/var/Ext3nder-Installer");
        removeFileIfExistsE("/private/var/lib");
        removeFileIfExistsE("/private/var/local");
        removeFileIfExistsE("/private/var/lock");
        removeFileIfExistsE("/private/var/spool");
        removeFileIfExistsE("/private/var/lib/apt");
        removeFileIfExistsE("/private/var/lib/dpkg");
        removeFileIfExistsE("/private/var/lib/dpkg");
        removeFileIfExistsE("/private/var/lib/cydia");
        removeFileIfExistsE("/private/var/cache/apt");
        removeFileIfExistsE("/private/var/db/stash");
        removeFileIfExistsE("/private/var/stash");
        removeFileIfExistsE("/private/var/tweak");
        removeFileIfExistsE("/private/var/cercube_stashed");
        removeFileIfExistsE("/private/var/tmp/cydia.log");
        //var/mobile/Library
        
        removeFileIfExistsE("/private/var/mobile/Library/Flex3");
        
        removeFileIfExistsE("/private/var/mobile/Library/Notchification");
        removeFileIfExistsE("/private/var/mobile/Library/unlimapps_tweaks_resources");
        removeFileIfExistsE("/private/var/mobile/Library/Fingal");
        removeFileIfExistsE("/private/var/mobile/Library/Filza");
        removeFileIfExistsE("/private/var/mobile/Library/CT3");
        removeFileIfExistsE("/private/var/mobile/Library/Cydia");
        
        removeFileIfExistsE("/private/var/mobile/Library/com.saurik.Cydia");
        removeFileIfExistsE("/private/var/mobile/Library/com.saurik.Cydia/");
        
        removeFileIfExistsE("/private/var/mobile/Library/SBHTML");
        removeFileIfExistsE("/private/var/mobile/Library/LockHTML");
        removeFileIfExistsE("/private/var/mobile/Library/iWidgets");
        
        //var/mobile/Library/Caches
        removeFileIfExistsE("/private/var/mobile/Library/Application\ Support/Flex3");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/libactivator.plist");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/com.saurik.Cydia");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/com.tigisoftware.Filza");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/com.johncoates.Flex");
        removeFileIfExistsE("/private/var/mobile/Library/libactivator.plist");
        removeFileIfExistsE("/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist");
        removeFileIfExistsE("/private/var/mobile/Library/Application\ Support/Activator");
        removeFileIfExistsE("/private/var/mobile/Library/Activator");
        
        //snapshot.library
        removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal");
        removeFileIfExistsE("/private/var/run/utmp");
        removeFileIfExistsE("/private/var/run/pspawn_hook.ts");
        unlink("/private/etc/apt/sources.list.d/cydia.list");
        unlink("/private/etc/apt");
        
        ////usr/include files
        removeFileIfExistsE("/usr/include");
        ////usr/local files
        removeFileIfExistsE("/usr/local/bin");
        ////usr/libexec files
        removeFileIfExistsE("/usr/libexec/apt");
        removeFileIfExistsE("/usr/libexec/ssh-pkcs11-helper");
        removeFileIfExistsE("/usr/libexec/ssh-keysign");
        removeFileIfExistsE("/usr/libexec/cydia");
        removeFileIfExistsE("/usr/libexec/dpkg");
        removeFileIfExistsE("/usr/libexec/gnupg");
        removeFileIfExistsE("/usr/libexec/gpg");
        removeFileIfExistsE("/usr/libexec/gpg-check-pattern");
        removeFileIfExistsE("/usr/libexec/gpg-preset-passphrase");
        removeFileIfExistsE("/usr/libexec/gpg-protect-tool");
        removeFileIfExistsE("/usr/libexec/gpg-wks-client");
        removeFileIfExistsE("/usr/libexec/git-core");
        removeFileIfExistsE("/usr/libexec/p11-kit");
        removeFileIfExistsE("/usr/libexec/scdaemon");
        removeFileIfExistsE("/usr/libexec/vndevice");
        removeFileIfExistsE("/usr/libexec/frcode");
        removeFileIfExistsE("/usr/libexec/bigram");
        removeFileIfExistsE("/usr/libexec/code");
        removeFileIfExistsE("/usr/libexec/coreutils");
        removeFileIfExistsE("/usr/libexec/reload");
        removeFileIfExistsE("/usr/libexec/rmt");
        removeFileIfExistsE("/usr/libexec/filza");
        removeFileIfExistsE("/usr/libexec/sudo");
        ////usr/lib files
        removeFileIfExistsE("/usr/lib/TweakInject");
        removeFileIfExistsE("/usr/lib/tweakloader.dylib");
        removeFileIfExistsE("/usr/lib/pspawn_hook.dylib");
        unlink("/usr/lib/pspawn_hook.dylib");
        removeFileIfExistsE("/usr/lib/tweaks");
        removeFileIfExistsE("/usr/lib/Activator");
        removeFileIfExistsE("/usr/lib/apt");
        
        unlink("/usr/lib/apt");
        
        removeFileIfExistsE("/usr/lib/dpkg");
        removeFileIfExistsE("/usr/lib/pam");
        removeFileIfExistsE("/usr/lib/p11-kit.0.dylib");
        unlink("/usr/lib/p11-kit-proxy.dylib");
        removeFileIfExistsE("/usr/lib/p11-kit-proxy.dylib");
        removeFileIfExistsE("/usr/lib/pkcs11");
        removeFileIfExistsE("/usr/lib/pam");
        removeFileIfExistsE("/usr/lib/pkgconfig");
        removeFileIfExistsE("/usr/lib/ssl");
        removeFileIfExistsE("/usr/lib/bash");
        removeFileIfExistsE("/usr/lib/gettext");
        removeFileIfExistsE("/usr/lib/coreutils");
        removeFileIfExistsE("/usr/lib/engines");
        removeFileIfExistsE("/usr/lib/p7zip");
        removeFileIfExistsE("/usr/lib/Cephei.framework");
        removeFileIfExistsE("/usr/lib/CepheiPrefs.framework");
        removeFileIfExistsE("/usr/lib/SBInject");
        //usr/local
        removeFileIfExistsE("/usr/local/bin");
        removeFileIfExistsE("/usr/local/lib");
        ////library folder files and subfolders
        removeFileIfExistsE("/Library/Alkaline");
        removeFileIfExistsE("/Library/Activator");
        removeFileIfExistsE("/Library/Barrel");
        removeFileIfExistsE("/Library/BarrelSettings");
        removeFileIfExistsE("/Library/Cylinder");
        removeFileIfExistsE("/Library/dpkg");
        removeFileIfExistsE("/Library/Frameworks");
        removeFileIfExistsE("/Library/LaunchDaemons");
        removeFileIfExistsE("/Library/.DS_Store");
        removeFileIfExistsE("/Library/MobileSubstrate");
        removeFileIfExistsE("/Library/PreferenceBundles");
        
        removeFileIfExistsE("/Library/PreferenceLoader");
        removeFileIfExistsE("/Library/SBInject");
        removeFileIfExistsE("/Library/Application\ Support/Snoverlay");
        removeFileIfExistsE("/Library/Application\ Support/Flame");
        removeFileIfExistsE("/Library/Application\ Support/CallBlocker");
        removeFileIfExistsE("/Library/Application\ Support/CCSupport");
        removeFileIfExistsE("/Library/Application\ Support/Compatimark");
        removeFileIfExistsE("/Library/Application\ Support/Dynastic");
        removeFileIfExistsE("/Library/Application\ Support/Malipo");
        removeFileIfExistsE("/Library/Application\ Support/SafariPlus.bundle");
        
        removeFileIfExistsE("/Library/Application\ Support/Activator");
        removeFileIfExistsE("/Library/Application\ Support/Cylinder");
        removeFileIfExistsE("/Library/Application\ Support/Barrel");
        removeFileIfExistsE("/Library/Application\ Support/BarrelSettings");
        removeFileIfExistsE("/Library/Application\ Support/libGitHubIssues/");
        removeFileIfExistsE("/Library/Themes");
        removeFileIfExistsE("/Library/TweakInject");
        removeFileIfExistsE("/Library/Zeppelin");
        removeFileIfExistsE("/Library/Flipswitch");
        removeFileIfExistsE("/Library/Switches");
        
        //////system/library
        removeFileIfExistsE("/System/Library/PreferenceBundles/AppList.bundle");
        removeFileIfExistsE("/System/Library/Themes");
        
        removeFileIfExistsE("/System/Library/Internet\ Plug-Ins");
        removeFileIfExistsE("/System/Library/KeyboardDictionaries");
        
        /////root
        
        removeFileIfExistsE("/FELICITYICON.png");
        removeFileIfExistsE("/bootstrap");
        removeFileIfExistsE("/mnt");
        removeFileIfExistsE("/lib");
        removeFileIfExistsE("/boot");
        removeFileIfExistsE("/libexec");
        removeFileIfExistsE("/include");
        removeFileIfExistsE("/mnt");
        removeFileIfExistsE("/jb");
        removeFileIfExistsE("/usr/games");
        //////////////USR/LIBRARY
        removeFileIfExistsE("/usr/Library");
        
        ///////////PRIVATE
        removeFileIfExistsE("/private/var/run/utmp");
        ///
        removeFileIfExistsE("/usr/bin/killall");
        removeFileIfExistsE("/usr/sbin/reboot");
        removeFileIfExistsE("/.bootstrapped_Th0r");
        
        
        execCmdElectra("/freya/rm", "-rf", "/Library/test_inject_springboard.cy");
        removeFileIfExistsE("/usr/lib/SBInject.dylib");
        ////usr/local files and folders cleanup
        removeFileIfExistsE("/usr/local/lib");
        
        removeFileIfExistsE("/usr/lib/libsparkapplist.dylib");
        
        removeFileIfExistsE("/usr/lib/libcrashreport.dylib");
        removeFileIfExistsE("/usr/lib/libsymbolicate.dylib");
        removeFileIfExistsE("/usr/lib/TweakInject.dylib");
        //////ROOT FILES :(
        removeFileIfExistsE("/.bootstrapped_electra");
        removeFileIfExistsE("/.cydia_no_stash");
        removeFileIfExistsE("/.bit_of_fun");
        removeFileIfExistsE("/RWTEST");
        removeFileIfExistsE("/pwnedWritefileatrootTEST");
        removeFileIfExistsE("/private/etc/symlibs.dylib");
        
        
        ////////// BIN/
        removeFileIfExistsE("/bin/bashbug");
        removeFileIfExistsE("/bin/bunzip2");
        removeFileIfExistsE("/bin/bzcat");
        unlink("usr/bin/bzcat");
        removeFileIfExistsE("/bin/bzip2");
        removeFileIfExistsE("/bin/bzip2recover");
        removeFileIfExistsE("/bin/bzip2_64");
        removeFileIfExistsE("/bin/cat");
        removeFileIfExistsE("/bin/chgrp");
        removeFileIfExistsE("/bin/chmod");
        removeFileIfExistsE("/bin/chown");
        removeFileIfExistsE("/bin/cp");
        removeFileIfExistsE("/bin/date");
        removeFileIfExistsE("/bin/dd");
        removeFileIfExistsE("/bin/dir");
        removeFileIfExistsE("/bin/echo");
        removeFileIfExistsE("/bin/egrep");
        removeFileIfExistsE("/bin/false");
        removeFileIfExistsE("/bin/fgrep");
        removeFileIfExistsE("/bin/grep");
        removeFileIfExistsE("/bin/gzip");
        removeFileIfExistsE("/bin/gtar");
        removeFileIfExistsE("/bin/gunzip");
        removeFileIfExistsE("/bin/gzexe");
        removeFileIfExistsE("/bin/hostname");
        removeFileIfExistsE("/bin/launchctl");
        removeFileIfExistsE("/bin/ln");
        removeFileIfExistsE("/bin/ls");
        removeFileIfExistsE("/bin/jtoold");
        removeFileIfExistsE("/bin/kill");
        removeFileIfExistsE("/bin/mkdir");
        removeFileIfExistsE("/bin/mknod");
        removeFileIfExistsE("/bin/mv");
        removeFileIfExistsE("/bin/mktemp");
        removeFileIfExistsE("/bin/pwd");
        
        removeFileIfExistsE("/bin/rmdir");
        removeFileIfExistsE("/bin/readlink");
        removeFileIfExistsE("/bin/unlink");
        removeFileIfExistsE("/bin/run-parts");
        removeFileIfExistsE("/bin/su");
        removeFileIfExistsE("/bin/sync");
        removeFileIfExistsE("/bin/stty");
        removeFileIfExistsE("/bin/sh");
        unlink("/bin/sh");
        
        removeFileIfExistsE("/bin/sleep");
        removeFileIfExistsE("/bin/sed");
        removeFileIfExistsE("/bin/su");
        removeFileIfExistsE("/bin/tar");
        removeFileIfExistsE("/bin/touch");
        removeFileIfExistsE("/bin/true");
        removeFileIfExistsE("/bin/uname");
        removeFileIfExistsE("/bin/vdr");
        removeFileIfExistsE("/bin/vdir");
        removeFileIfExistsE("/bin/uncompress");
        removeFileIfExistsE("/bin/znew");
        removeFileIfExistsE("/bin/zegrep");
        removeFileIfExistsE("/bin/zmore");
        removeFileIfExistsE("/bin/zdiff");
        removeFileIfExistsE("/bin/zcat");
        removeFileIfExistsE("/bin/zcmp");
        removeFileIfExistsE("/bin/zfgrep");
        removeFileIfExistsE("/bin/zforce");
        removeFileIfExistsE("/bin/zless");
        removeFileIfExistsE("/bin/zgrep");
        removeFileIfExistsE("/bin/zegrep");
        
        //////////SBIN
        removeFileIfExistsE("/sbin/reboot");
        removeFileIfExistsE("/sbin/halt");
        removeFileIfExistsE("/sbin/ifconfig");
        removeFileIfExistsE("/sbin/kextunload");
        removeFileIfExistsE("/sbin/ping");
        removeFileIfExistsE("/sbin/update_dyld_shared_cache");
        removeFileIfExistsE("/sbin/dmesg");
        removeFileIfExistsE("/sbin/dynamic_pager");
        removeFileIfExistsE("/sbin/nologin");
        removeFileIfExistsE("/sbin/fstyp");
        removeFileIfExistsE("/sbin/fstyp_msdos");
        removeFileIfExistsE("/sbin/fstyp_ntfs");
        removeFileIfExistsE("/sbin/fstyp_udf");
        removeFileIfExistsE("/sbin/mount_devfs");
        removeFileIfExistsE("/sbin/mount_fdesc");
        removeFileIfExistsE("/sbin/quotacheck");
        removeFileIfExistsE("/sbin/umount");
        
        
        /////usr/bin files folders cleanup
        //symbols
        removeFileIfExistsE("/usr/bin/[");
        //a
        removeFileIfExistsE("/usr/bin/ADMHelper");
        removeFileIfExistsE("/usr/bin/arch");
        removeFileIfExistsE("/usr/bin/apt");
        
        removeFileIfExistsE("/usr/bin/ar");
        
        removeFileIfExistsE("/usr/bin/apt-key");
        removeFileIfExistsE("/usr/bin/apt-cache");
        removeFileIfExistsE("/usr/bin/apt-cdrom");
        removeFileIfExistsE("/usr/bin/apt-config");
        removeFileIfExistsE("/usr/bin/apt-extracttemplates");
        removeFileIfExistsE("/usr/bin/apt-ftparchive");
        removeFileIfExistsE("/usr/bin/apt-sortpkgs");
        removeFileIfExistsE("/usr/bin/apt-mark");
        removeFileIfExistsE("/usr/bin/apt-get");
        removeFileIfExistsE("/usr/bin/arch");
        removeFileIfExistsE("/usr/bin/asu_inject");
        
        
        removeFileIfExistsE("/usr/bin/asn1Coding");
        removeFileIfExistsE("/usr/bin/asn1Decoding");
        removeFileIfExistsE("/usr/bin/asn1Parser");
        removeFileIfExistsE("/usr/bin/autopoint");
        
        removeFileIfExistsE("/usr/bin/as");
        //b
        removeFileIfExistsE("/usr/bin/bashbug");
        removeFileIfExistsE("/usr/bin/b2sum");
        removeFileIfExistsE("/usr/bin/base32");
        removeFileIfExistsE("/usr/bin/base64");
        removeFileIfExistsE("/usr/bin/basename");
        removeFileIfExistsE("/usr/bin/bitcode_strip");
        //c
        removeFileIfExistsE("/usr/bin/CallLogPro");
        removeFileIfExistsE("/usr/bin/com.julioverne.ext3nder-installer");
        removeFileIfExistsE("/usr/bin/chown");
        removeFileIfExistsE("/usr/bin/chmod");
        removeFileIfExistsE("/usr/bin/chroot");
        removeFileIfExistsE("/usr/bin/chcon");
        removeFileIfExistsE("/usr/bin/chpass");
        removeFileIfExistsE("/usr/bin/check_dylib");
        removeFileIfExistsE("/usr/bin/checksyms");
        removeFileIfExistsE("/usr/bin/chfn");
        removeFileIfExistsE("/usr/bin/chsh");
        removeFileIfExistsE("/usr/bin/cksum");
        removeFileIfExistsE("/usr/bin/comm");
        removeFileIfExistsE("/usr/bin/cmpdylib");
        removeFileIfExistsE("/usr/bin/codesign_allocate");
        removeFileIfExistsE("/usr/bin/csplit");
        removeFileIfExistsE("/usr/bin/ctf_insert");
        removeFileIfExistsE("/usr/bin/cut");
        removeFileIfExistsE("/usr/bin/curl");
        removeFileIfExistsE("/usr/bin/curl-config");
        removeFileIfExistsE("/usr/bin/c_rehash");
        removeFileIfExistsE("/usr/bin/captoinfo");
        removeFileIfExistsE("/usr/bin/certtool");
        removeFileIfExistsE("/usr/bin/cfversion");
        removeFileIfExistsE("/usr/bin/clear");
        removeFileIfExistsE("/usr/bin/cmp");
        removeFileIfExistsE("/usr/bin/cydown");//cydown
        removeFileIfExistsE("/usr/bin/cydown.arch_arm64");
        removeFileIfExistsE("/usr/bin/cydown.arch_armv7");
        
        removeFileIfExistsE("/usr/bin/cycript");
        removeFileIfExistsE("/usr/bin/cycc");
        removeFileIfExistsE("/usr/bin/cynject");
        //d
        removeFileIfExistsE("/usr/bin/dbclient");
        removeFileIfExistsE("/usr/bin/db_archive");
        removeFileIfExistsE("/usr/bin/db_checkpoint");
        removeFileIfExistsE("/usr/bin/db_deadlock");
        removeFileIfExistsE("/usr/bin/db_dump");
        removeFileIfExistsE("/usr/bin/db_hotbackup");
        removeFileIfExistsE("/usr/bin/db_load");
        removeFileIfExistsE("/usr/bin/db_log_verify");
        removeFileIfExistsE("/usr/bin/db_printlog");
        removeFileIfExistsE("/usr/bin/db_recover");
        removeFileIfExistsE("/usr/bin/db_replicate");
        removeFileIfExistsE("/usr/bin/db_sql_codegen");
        removeFileIfExistsE("/usr/bin/db_stat");
        removeFileIfExistsE("/usr/bin/db_tuner");
        removeFileIfExistsE("/usr/bin/db_upgrade");
        removeFileIfExistsE("/usr/bin/db_verify");
        removeFileIfExistsE("/usr/bin/dbsql");
        removeFileIfExistsE("/usr/bin/debugserver");
        removeFileIfExistsE("/usr/bin/defaults");
        removeFileIfExistsE("/usr/bin/df");
        removeFileIfExistsE("/usr/bin/diff");
        removeFileIfExistsE("/usr/bin/diff3");
        removeFileIfExistsE("/usr/bin/dirname");
        removeFileIfExistsE("/usr/bin/dircolors");
        removeFileIfExistsE("/usr/bin/dirmngr");
        removeFileIfExistsE("/usr/bin/dirmngr-client");
        removeFileIfExistsE("/usr/bin/dpkg");
        removeFileIfExistsE("/usr/bin/dpkg-architecture");
        removeFileIfExistsE("/usr/bin/dpkg-buildflags");
        removeFileIfExistsE("/usr/bin/dpkg-buildpackage");
        removeFileIfExistsE("/usr/bin/dpkg-checkbuilddeps");
        removeFileIfExistsE("/usr/bin/dpkg-deb");
        removeFileIfExistsE("/usr/bin/dpkg-distaddfile");
        removeFileIfExistsE("/usr/bin/dpkg-divert");
        removeFileIfExistsE("/usr/bin/dpkg-genbuildinfo");
        removeFileIfExistsE("/usr/bin/dpkg-genchanges");
        removeFileIfExistsE("/usr/bin/dpkg-gencontrol");
        removeFileIfExistsE("/usr/bin/dpkg-gensymbols");
        removeFileIfExistsE("/usr/bin/dpkg-maintscript-helper");
        removeFileIfExistsE("/usr/bin/dpkg-mergechangelogs");
        removeFileIfExistsE("/usr/bin/dpkg-name");
        removeFileIfExistsE("/usr/bin/dpkg-parsechangelog");
        removeFileIfExistsE("/usr/bin/dpkg-query");
        removeFileIfExistsE("/usr/bin/dpkg-scanpackages");
        removeFileIfExistsE("/usr/bin/dpkg-scansources");
        removeFileIfExistsE("/usr/bin/dpkg-shlibdeps");
        removeFileIfExistsE("/usr/bin/dpkg-source");
        removeFileIfExistsE("/usr/bin/dpkg-split");
        removeFileIfExistsE("/usr/bin/dpkg-statoverride");
        removeFileIfExistsE("/usr/bin/dpkg-trigger");
        removeFileIfExistsE("/usr/bin/dpkg-vendor");
        removeFileIfExistsE("/usr/bin/du");
        removeFileIfExistsE("/usr/bin/dumpsexp");
        removeFileIfExistsE("/usr/bin/dselect");
        removeFileIfExistsE("/usr/bin/dsymutil");
        ////e
        removeFileIfExistsE("/usr/bin/expand");
        removeFileIfExistsE("/usr/bin/expr");
        removeFileIfExistsE("/usr/bin/env");
        removeFileIfExistsE("/usr/bin/envsubst");
        removeFileIfExistsE("/usr/bin/ecidecid");
        //f
        removeFileIfExistsE("/usr/bin/factor");
        removeFileIfExistsE("/usr/bin/filemon");
        removeFileIfExistsE("/usr/bin/Filza");
        removeFileIfExistsE("/usr/bin/fmt");
        removeFileIfExistsE("/usr/bin/fold");
        removeFileIfExistsE("/usr/bin/funzip");
        //g
        removeFileIfExistsE("/usr/bin/games");
        removeFileIfExistsE("/usr/bin/getconf");
        removeFileIfExistsE("/usr/bin/getty");
        removeFileIfExistsE("/usr/bin/gettext");
        removeFileIfExistsE("/usr/bin/gettext.sh");
        removeFileIfExistsE("/usr/bin/gettextize");
        removeFileIfExistsE("/usr/bin/git");
        removeFileIfExistsE("/usr/bin/git-cvsserver");
        removeFileIfExistsE("/usr/bin/git-recieve-pack");
        removeFileIfExistsE("/usr/bin/git-shell");
        removeFileIfExistsE("/usr/bin/git-upload-pack");
        removeFileIfExistsE("/usr/bin/gitk");
        removeFileIfExistsE("/usr/bin/gnutar");
        removeFileIfExistsE("/usr/bin/gnutls-cli");
        removeFileIfExistsE("/usr/bin/gnutls-cli-debug");
        removeFileIfExistsE("/usr/bin/gnutls-serv");
        removeFileIfExistsE("/usr/bin/gpg");
        removeFileIfExistsE("/usr/bin/gpgrt-config");
        removeFileIfExistsE("/usr/bin/gpg-zip");
        removeFileIfExistsE("/usr/bin/gpgsplit");
        removeFileIfExistsE("/usr/bin/gpgv");
        removeFileIfExistsE("/usr/bin/gssc");
        removeFileIfExistsE("/usr/bin/groups");
        removeFileIfExistsE("/usr/bin/gpg-agent");
        removeFileIfExistsE("/usr/bin/gpg-connect-agent ");
        removeFileIfExistsE("/usr/bin/gpg-error");
        removeFileIfExistsE("/usr/bin/gpg-error-config");
        removeFileIfExistsE("/usr/bin/gpg2");
        removeFileIfExistsE("/usr/bin/gpgconf");
        removeFileIfExistsE("/usr/bin/gpgparsemail");
        removeFileIfExistsE("/usr/bin/gpgscm");
        removeFileIfExistsE("/usr/bin/gpgsm");
        removeFileIfExistsE("/usr/bin/gpgtar");
        removeFileIfExistsE("/usr/bin/gpgv2");
        removeFileIfExistsE("/usr/bin/groups");
        removeFileIfExistsE("/usr/bin/gtar");
        //h
        removeFileIfExistsE("/usr/bin/head");
        removeFileIfExistsE("/usr/bin/hmac256");
        removeFileIfExistsE("/usr/bin/hostid");
        removeFileIfExistsE("/usr/bin/hostinfo");
        //i
        removeFileIfExistsE("/usr/bin/install");
        removeFileIfExistsE("/usr/bin/id");
        removeFileIfExistsE("/usr/bin/idn2");
        removeFileIfExistsE("/usr/bin/indr");
        removeFileIfExistsE("/usr/bin/inout");
        removeFileIfExistsE("/usr/bin/infocmp");
        removeFileIfExistsE("/usr/bin/infotocap");
        removeFileIfExistsE("/usr/bin/iomfsetgamma");
        removeFileIfExistsE("/usr/bin/install_name_tool");
        removeFileIfExistsE("/usr/bin/libtool");
        removeFileIfExistsE("/usr/bin/lipo");
        //j
        removeFileIfExistsE("/usr/bin/join");
        removeFileIfExistsE("/usr/bin/jtool");
        //k
        removeFileIfExistsE("/usr/bin/killall");
        removeFileIfExistsE("/usr/bin/kbxutil");
        removeFileIfExistsE("/usr/bin/ksba-config");
        //l
        removeFileIfExistsE("/usr/bin/less");
        removeFileIfExistsE("/usr/bin/libassuan-config");
        removeFileIfExistsE("/usr/bin/libgcrypt-config");
        removeFileIfExistsE("/usr/bin/link");
        removeFileIfExistsE("/usr/bin/ldid");
        removeFileIfExistsE("/usr/bin/ldid2");
        removeFileIfExistsE("/usr/bin/ldrestart");
        removeFileIfExistsE("/usr/bin/locate");
        removeFileIfExistsE("/usr/bin/login");
        removeFileIfExistsE("/usr/bin/logname");
        removeFileIfExistsE("/usr/bin/lzcat");
        removeFileIfExistsE("/usr/bin/lz4");
        removeFileIfExistsE("/usr/bin/lz4c");
        removeFileIfExistsE("/usr/bin/lz4cat");
        removeFileIfExistsE("/usr/bin/lzcmp");
        removeFileIfExistsE("/usr/bin/lzdiff");
        removeFileIfExistsE("/usr/bin/lzegrep");
        removeFileIfExistsE("/usr/bin/lzfgrep");
        removeFileIfExistsE("/usr/bin/lzgrep");
        removeFileIfExistsE("/usr/bin/lzless");
        removeFileIfExistsE("/usr/bin/lzma");
        removeFileIfExistsE("/usr/bin/lzmadec");
        removeFileIfExistsE("/usr/bin/lzmainfo");
        removeFileIfExistsE("/usr/bin/lzmore");
        removeFileIfExistsE("/usr/bin.lipo");
        removeFileIfExistsE("/usr/bin/lipo");
        
        //m
        removeFileIfExistsE("/usr/bin/md5sum");
        removeFileIfExistsE("/usr/bin/mkfifo");
        removeFileIfExistsE("/usr/bin/mktemp");
        removeFileIfExistsE("/usr/bin/more");
        removeFileIfExistsE("/usr/bin/msgattrib");
        removeFileIfExistsE("/usr/bin/msgcat");
        removeFileIfExistsE("/usr/bin/msgcmp");
        removeFileIfExistsE("/usr/bin/msgcomm");
        removeFileIfExistsE("/usr/bin/msgconv");
        removeFileIfExistsE("/usr/bin/msgen");
        removeFileIfExistsE("/usr/bin/msgexec");
        removeFileIfExistsE("/usr/bin/msgfilter");
        removeFileIfExistsE("/usr/bin/msgfmt");
        removeFileIfExistsE("/usr/bin/msggrep");
        removeFileIfExistsE("/usr/bin/msginit");
        removeFileIfExistsE("/usr/bin/msgmerge");
        removeFileIfExistsE("/usr/bin/msgunfmt");
        removeFileIfExistsE("/usr/bin/msguniq");
        removeFileIfExistsE("/usr/bin/mpicalc");
        //n
        removeFileIfExistsE("/usr/bin/nano");
        removeFileIfExistsE("/usr/bin/nettle-hash");
        removeFileIfExistsE("/usr/bin/nettle-lfib-stream");
        removeFileIfExistsE("/usr/bin/nettle-pbkdf2");
        removeFileIfExistsE("/usr/bin/ngettext");
        
        
        
        removeFileIfExistsE("/usr/bin/nm");
        removeFileIfExistsE("/usr/bin/nmedit");
        removeFileIfExistsE("/usr/bin/nice");
        removeFileIfExistsE("/usr/bin/nl");
        removeFileIfExistsE("/usr/bin/nohup");
        removeFileIfExistsE("/usr/bin/nproc");
        removeFileIfExistsE("/usr/bin/npth-config");
        removeFileIfExistsE("/usr/bin/numfmt");
        removeFileIfExistsE("/usr/bin/ncurses6-config");
        removeFileIfExistsE("/usr/bin/ncursesw6-config");
        removeFileIfExistsE("/usr/bin/ncursesw5-config");
        removeFileIfExistsE("/usr/bin/ncurses5-config");
        //o
        
        removeFileIfExistsE("/usr/bin/od");
        removeFileIfExistsE("/usr/bin/ocsptool");
        removeFileIfExistsE("/usr/bin/ObjectDump");//ld64
        removeFileIfExistsE("/usr/bin/dyldinfo");
        removeFileIfExistsE("/usr/bin/ld");
        removeFileIfExistsE("/usr/bin/machocheck");
        removeFileIfExistsE("/usr/bin/unwinddump");//ld64 done
        removeFileIfExistsE("/usr/bin/otool");
        
        removeFileIfExistsE("/usr/bin/openssl");
        //p
        removeFileIfExistsE("/usr/bin/pincrush");
        removeFileIfExistsE("/usr/bin/pagestuff");
        
        removeFileIfExistsE("/usr/bin/pagesize");
        removeFileIfExistsE("/usr/bin/passwd");
        removeFileIfExistsE("/usr/bin/paste");
        removeFileIfExistsE("/usr/bin/pathchk");
        removeFileIfExistsE("/usr/bin/pinky");
        removeFileIfExistsE("/usr/bin/plconvert");
        removeFileIfExistsE("/usr/bin/pr");
        removeFileIfExistsE("/usr/bin/printenv");
        removeFileIfExistsE("/usr/bin/printf");
        removeFileIfExistsE("/usr/bin/procexp");
        removeFileIfExistsE("/usr/bin/ptx");
        removeFileIfExistsE("/usr/bin/p11-kit");
        removeFileIfExistsE("/usr/bin/p11tool");
        
        removeFileIfExistsE("/usr/bin/pkcs1-conv");
        
        removeFileIfExistsE("/usr/bin/psktool");
        
        removeFileIfExistsE("/usr/bin/quota");
        
        
        //r
        removeFileIfExistsE("/usr/bin/renice");
        removeFileIfExistsE("/usr/bin/ranlib");
        removeFileIfExistsE("/usr/bin/redo_prebinding");
        removeFileIfExistsE("/usr/bin/reprovisiond");
        
        removeFileIfExistsE("/usr/bin/reset");
        removeFileIfExistsE("/usr/bin/realpath");
        removeFileIfExistsE("/usr/bin/rnano");
        removeFileIfExistsE("/usr/bin/runcon");
        //s
        
        removeFileIfExistsE("/usr/bin/snapUtil");
        removeFileIfExistsE("/usr/bin/sbdidlaunch");
        removeFileIfExistsE("/usr/bin/sbreload");
        removeFileIfExistsE("/usr/bin/script");
        removeFileIfExistsE("/usr/bin/sdiff");
        removeFileIfExistsE("/usr/bin/seq");
        removeFileIfExistsE("/usr/bin/sexp-conv");
        removeFileIfExistsE("/usr/bin/seg_addr_table");
        removeFileIfExistsE("/usr/bin/seg_hack");
        removeFileIfExistsE("/usr/bin/segedit");
        removeFileIfExistsE("/usr/bin/sftp");
        removeFileIfExistsE("/usr/bin/shred");
        removeFileIfExistsE("/usr/bin/shuf");
        removeFileIfExistsE("/usr/bin/sort");
        removeFileIfExistsE("/usr/bin/ssh");
        removeFileIfExistsE("/usr/bin/ssh-add");
        removeFileIfExistsE("/usr/bin/ssh-agent");
        removeFileIfExistsE("/usr/bin/ssh-keygen");
        removeFileIfExistsE("/usr/bin/ssh-keyscan");
        removeFileIfExistsE("/usr/bin/sw_vers");
        removeFileIfExistsE("/usr/bin/seq");
        removeFileIfExistsE("/usr/bin/SemiRestore11-Lite");
        
        removeFileIfExistsE("/usr/bin/sha1sum");
        removeFileIfExistsE("/usr/bin/sha224sum");
        removeFileIfExistsE("/usr/bin/sha256sum");
        removeFileIfExistsE("/usr/bin/sha384sum");
        removeFileIfExistsE("/usr/bin/sha512sum");
        removeFileIfExistsE("/usr/bin/shred");
        removeFileIfExistsE("/usr/bin/shuf");
        removeFileIfExistsE("/usr/bin/size");
        removeFileIfExistsE("/usr/bin/split");
        removeFileIfExistsE("/usr/bin/srptool");
        removeFileIfExistsE("/usr/bin/stat");
        removeFileIfExistsE("/usr/bin/stdbuf");
        removeFileIfExistsE("/usr/bin/strings");
        removeFileIfExistsE("/usr/bin/strip");
        removeFileIfExistsE("/usr/bin/sum");
        removeFileIfExistsE("/usr/bin/sync");
        //t
        removeFileIfExistsE("/usr/bin/tabs");
        removeFileIfExistsE("/usr/bin/tac");
        removeFileIfExistsE("/usr/bin/tar");
        removeFileIfExistsE("/usr/bin/tail");
        removeFileIfExistsE("/usr/bin/tee");
        removeFileIfExistsE("/usr/bin/test");
        removeFileIfExistsE("/usr/bin/tic");
        removeFileIfExistsE("/usr/bin/time");
        removeFileIfExistsE("/usr/bin/timeout");
        removeFileIfExistsE("/usr/bin/toe");
        removeFileIfExistsE("/usr/bin/tput");
        removeFileIfExistsE("/usr/bin/tr");
        removeFileIfExistsE("/usr/bin/tset");
        removeFileIfExistsE("/usr/bin/truncate");
        removeFileIfExistsE("/usr/bin/trust");
        removeFileIfExistsE("/usr/bin/tsort");
        removeFileIfExistsE("/usr/bin/tty");
        //u
        removeFileIfExistsE("/usr/bin/uiduid");
        removeFileIfExistsE("/usr/bin/uuid");
        removeFileIfExistsE("/usr/bin/uuid-config");
        removeFileIfExistsE("/usr/bin/uiopen");
        removeFileIfExistsE("/usr/bin/unlz4");
        removeFileIfExistsE("/usr/bin/unlzma");
        removeFileIfExistsE("/usr/bin/unxz");
        removeFileIfExistsE("/usr/bin/update-alternatives");
        removeFileIfExistsE("/usr/bin/updatedb");
        removeFileIfExistsE("/usr/bin/unexpand");
        removeFileIfExistsE("/usr/bin/uniq");
        removeFileIfExistsE("/usr/bin/unzip");
        removeFileIfExistsE("/usr/bin/unzipsfx");
        removeFileIfExistsE("/usr/bin/unrar");
        removeFileIfExistsE("/usr/bin/uptime");
        removeFileIfExistsE("/usr/bin/users");
        //w
        removeFileIfExistsE("/usr/bin/watchgnupg");
        removeFileIfExistsE("/usr/bin/wc");
        removeFileIfExistsE("/usr/bin/wget");
        removeFileIfExistsE("/usr/bin/which");
        removeFileIfExistsE("/usr/bin/who");
        removeFileIfExistsE("/usr/bin/whoami");
        //x
        removeFileIfExistsE("/usr/bin/xargs");
        removeFileIfExistsE("/usr/bin/xz");
        removeFileIfExistsE("/usr/bin/xgettext");
        removeFileIfExistsE("/usr/bin/xzcat");
        removeFileIfExistsE("/usr/bin/xzcmp");
        removeFileIfExistsE("/usr/bin/xzdec");
        removeFileIfExistsE("/usr/bin/xzdiff");
        removeFileIfExistsE("/usr/bin/xzegrep");
        removeFileIfExistsE("/usr/bin/xzfgrep");
        removeFileIfExistsE("/usr/bin/xzgrep");
        removeFileIfExistsE("/usr/bin/xzless");
        removeFileIfExistsE("/usr/bin/xzmore");
        //y
        removeFileIfExistsE("/usr/bin/yat2m");
        removeFileIfExistsE("/usr/bin/yes");
        //z
        removeFileIfExistsE("/usr/bin/zip");
        removeFileIfExistsE("/usr/bin/zipcloak");
        removeFileIfExistsE("/usr/bin/zipnote");
        removeFileIfExistsE("/usr/bin/zipsplit");
        //numbers
        removeFileIfExistsE("/usr/bin/7z");
        removeFileIfExistsE("/usr/bin/7za");
        //////////////
        ////
        //////////USR/SBIN
        removeFileIfExistsE("/usr/sbin/chown");
        
        unlink("/usr/sbin/chown");
        
        removeFileIfExistsE("/usr/sbin/chmod");
        removeFileIfExistsE("/usr/sbin/chroot");
        removeFileIfExistsE("/usr/sbin/dev_mkdb");
        removeFileIfExistsE("/usr/sbin/edquota");
        removeFileIfExistsE("/usr/sbin/applygnupgdefaults");
        removeFileIfExistsE("/usr/sbin/fdisk");
        removeFileIfExistsE("/usr/sbin/halt");
        removeFileIfExistsE("/usr/sbin/sshd");
        
        //////////////USR/LIB
        
        removeFileIfExistsE("/usr/lib/libhistory.5.dylib");
        removeFileIfExistsE("/usr/lib/xxxMobileGestalt.dylib");//for cydown
        
        removeFileIfExistsE("/usr/lib/xxxSystem.dylib");//for cydown
        
        removeFileIfExistsE("/usr/lib/libcolorpicker.dylib");//
        removeFileIfExistsE("/usr/lib/libcrypto.dylib");//
        removeFileIfExistsE("/usr/lib/libcrypto.a");//
        removeFileIfExistsE("/usr/lib/libdb_sql-6.2.dylib");//
        removeFileIfExistsE("/usr/lib/libdb_sql-6.dylib");//
        removeFileIfExistsE("/usr/lib/libdb_sql.dylib");//
        removeFileIfExistsE("/usr/lib/libdb-6.2.dylib");//
        removeFileIfExistsE("/usr/lib/libdb-6.dylib");//
        removeFileIfExistsE("/usr/lib/libdb.dylib");//
        removeFileIfExistsE("/usr/lib/liblzma.a");//
        removeFileIfExistsE("/usr/lib/liblzma.la");//
        removeFileIfExistsE("/usr/lib/libprefs.dylib");//
        removeFileIfExistsE("/usr/lib/libssl.a");//
        removeFileIfExistsE("/usr/lib/libssl.dylib");//
        removeFileIfExistsE("/usr/lib/libST.dylib");//
        //////////////////
        //////////////8
        removeFileIfExistsE("/usr/lib/libapt-pkg.dylib.4.6");
        removeFileIfExistsE("/usr/lib/libapt-pkg.4.6.dylib");
        removeFileIfExistsE("/usr/lib/libpam.dylib");
        removeFileIfExistsE("/usr/lib/libpamc.1.dylib");
        removeFileIfExistsE("/usr/lib/libapt-pkg.dylib.4.6.0");
        removeFileIfExistsE("/usr/lib/libapt-pkg.4.6.0.dylib");
        removeFileIfExistsE("/usr/lib/libpanelw.5.dylib");
        removeFileIfExistsE("/usr/lib/libhistory.5.2.dylib");
        removeFileIfExistsE("/usr/lib/libreadline.6.dylib");
        removeFileIfExistsE("/usr/lib/libpanel.dylib");
        removeFileIfExistsE("/usr/lib/libapt-inst.dylib.1.1");
        removeFileIfExistsE("/usr/lib/libapt-inst.1.1.dylib");
        removeFileIfExistsE("/usr/lib/libcurses.dylib");
        removeFileIfExistsE("/usr/lib/liblzmadec.0.dylib");
        removeFileIfExistsE("/usr/lib/libhistory.6.dylib");
        removeFileIfExistsE("/usr/lib/libformw.dylib");
        removeFileIfExistsE("/usr/lib/libncursesw.dylib");
        removeFileIfExistsE("/usr/lib/libapt-inst.dylib");
        removeFileIfExistsE("/usr/lib/libncurses.5.dylib");
        removeFileIfExistsE("/usr/lib/libapt-pkg.dylib");
        removeFileIfExistsE("/usr/lib/libreadline.5.dylib");
        removeFileIfExistsE("/usr/lib/libhistory.6.0.dylib");
        removeFileIfExistsE("/usr/lib/libform.5.dylib");
        removeFileIfExistsE("/usr/lib/libpanelw.dylib");
        removeFileIfExistsE("/usr/lib/libmenuw.dylib");
        removeFileIfExistsE("/usr/lib/libform.dylib");
        removeFileIfExistsE("/usr/lib/terminfo");
        removeFileIfExistsE("/usr/lib/libpam.1.0.dylib");
        removeFileIfExistsE("/usr/lib/libmenu.5.dylib");
        removeFileIfExistsE("/usr/lib/libpatcyh.dylib");
        removeFileIfExistsE("/usr/lib/libreadline.6.0.dylib");
        removeFileIfExistsE("/usr/lib/liblzmadec.dylib");
        removeFileIfExistsE("/usr/lib/libncurses.dylib");
        removeFileIfExistsE("/usr/lib/libhistory.dylib");
        removeFileIfExistsE("/usr/lib/libpamc.dylib");
        removeFileIfExistsE("/usr/lib/libformw.5.dylib");
        removeFileIfExistsE("/usr/lib/libapt-inst.dylib.1.1.0");
        removeFileIfExistsE("/usr/lib/libapt-inst.1.1.0.dylib");
        removeFileIfExistsE("/usr/lib/libpanel.5.dylib");
        removeFileIfExistsE("/usr/lib/liblzmadec.0.0.0.dylib");
        removeFileIfExistsE("/usr/lib/_ncurses");
        removeFileIfExistsE("/usr/lib/libpam_misc.1.dylib");
        removeFileIfExistsE("/usr/lib/libreadline.5.2.dylib");
        removeFileIfExistsE("/usr/lib/libpam_misc.dylib");
        removeFileIfExistsE("/usr/lib/libreadline.dylib");
        removeFileIfExistsE("/usr/lib/libmenuw.5.dylib");
        removeFileIfExistsE("/usr/lib/libpam.1.dylib");
        removeFileIfExistsE("/usr/lib/libmenu.dylib");
        removeFileIfExistsE("/usr/lib/liblzmadec.la");
        removeFileIfExistsE("/usr/lib/libncursesw.5.dylib");
        removeFileIfExistsE("/usr/lib/libcycript.dylib");
        removeFileIfExistsE("/usr/lib/libcycript.jar");
        removeFileIfExistsE("/usr/lib/libdpkg.a");
        removeFileIfExistsE("/usr/lib/libcrypto.1.0.0.dylib");
        removeFileIfExistsE("/usr/lib/libssl.1.0.0.dylib");
        removeFileIfExistsE("/usr/lib/libcycript.db");
        removeFileIfExistsE("/usr/lib/libcurl.4.dylib");
        removeFileIfExistsE("/usr/lib/libcycript.0.dylib");
        removeFileIfExistsE("/usr/lib/libcycript.cy");
        removeFileIfExistsE("/usr/lib/libdpkg.la");
        removeFileIfExistsE("/usr/lib/libswift");
        removeFileIfExistsE("/usr/lib/libsubstrate.0.dylib");
        removeFileIfExistsE("/usr/lib/libuuid.16.dylib");
        removeFileIfExistsE("/usr/lib/libuuid.dylib");
        removeFileIfExistsE("/usr/lib/libtapi.dylib");//ld64
        removeFileIfExistsE("/usr/lib/libnghttp2.14.dylib");//ld64
        removeFileIfExistsE("/usr/lib/libnghttp2.dylib");//ld64
        removeFileIfExistsE("/usr/lib/libnghttp2.la");//ld64
        ///sauirks new substrate
        removeFileIfExistsE("/usr/lib/substrate");//ld64
        
        //////////USR/SBIN
        removeFileIfExistsE("/usr/sbin/accton");
        removeFileIfExistsE("/usr/sbin/vifs");
        removeFileIfExistsE("/usr/sbin/ac");
        removeFileIfExistsE("/usr/sbin/update");
        removeFileIfExistsE("/usr/sbin/pwd_mkdb");
        removeFileIfExistsE("/usr/sbin/sysctl");
        removeFileIfExistsE("/usr/sbin/zdump");
        removeFileIfExistsE("/usr/sbin/startupfiletool");
        removeFileIfExistsE("/usr/sbin/iostat");
        removeFileIfExistsE("/usr/sbin/nologin");
        
        removeFileIfExistsE("/usr/sbin/mkfile");
        removeFileIfExistsE("/usr/sbin/quotaon");
        removeFileIfExistsE("/usr/sbin/repquota");
        removeFileIfExistsE("/usr/sbin/zic");
        removeFileIfExistsE("/usr/sbin/vipw");
        removeFileIfExistsE("/usr/sbin/vsdbutil");
        
        removeFileIfExistsE("/usr/sbin/start-stop-daemon");
        ////////USR/LOCAL
        removeFileIfExistsE("/usr/local/lib/libluajit.a");
        //////LIBRARY
        removeFileIfExistsE("/Library/test_inject_springboard.cy");
        //////sbin folder files cleanup
        removeFileIfExistsE("/sbin/dmesg");
        
        removeFileIfExistsE("/sbin/cat");
        removeFileIfExistsE("/sbin/zshrc");
        ////usr/sbin files
        removeFileIfExistsE("/usr/sbin/start-start-daemon");
        removeFileIfExistsE("/usr/sbin/accton");
        removeFileIfExistsE("/usr/sbin/addgnupghome");
        removeFileIfExistsE("/usr/sbin/vifs");
        removeFileIfExistsE("/usr/sbin/ac");
        removeFileIfExistsE("/usr/sbin/update");
        removeFileIfExistsE("/usr/sbin/sysctl");
        removeFileIfExistsE("/usr/sbin/zdump");
        removeFileIfExistsE("/usr/sbin/startupfiletool");
        removeFileIfExistsE("/usr/sbin/iostat");
        removeFileIfExistsE("/usr/sbin/mkfile");
        removeFileIfExistsE("/usr/sbin/zic");
        removeFileIfExistsE("/usr/sbin/vipw");
        ////usr/libexec files
        removeFileIfExistsE("/usr/libexec/_rocketd_reenable");
        removeFileIfExistsE("/usr/libexec/rocketd");
        removeFileIfExistsE("/usr/libexec/MSUnrestrictProcess");
        removeFileIfExistsE("/usr/libexec/substrate");
        removeFileIfExistsE("/usr/libexec/substrated");
        
        removeFileIfExistsE("/usr/lib/applist.dylib");
        removeFileIfExistsE("/usr/lib/libapplist.dylib");
        removeFileIfExistsE("/usr/lib/libhAcxTools.dylib");
        removeFileIfExistsE("/usr/lib/libhAcxTools2.dylib");
        
        removeFileIfExistsE("/usr/lib/libflipswitch.dylib");
        removeFileIfExistsE("/usr/lib/libapt-inst.2.0.0.dylib");
        removeFileIfExistsE("/usr/lib/libapt-inst.2.0.dylib");
        removeFileIfExistsE("/usr/lib/libapt-pkg.5.0.1.dylib");
        removeFileIfExistsE("/usr/lib/libapt-pkg.5.0.dylib");
        removeFileIfExistsE("/usr/lib/libapt-private.0.0.0.dylib");
        removeFileIfExistsE("/usr/lib/libapt-private.0.0.dylib");
        removeFileIfExistsE("/usr/lib/libassuan.0.dylib");
        removeFileIfExistsE("/usr/lib/libassuan.dylib");
        removeFileIfExistsE("/usr/lib/libassuan.la");
        removeFileIfExistsE("/usr/lib/libnpth.0.dylib");
        removeFileIfExistsE("/usr/lib/libnpth.dylib");
        removeFileIfExistsE("/usr/lib/libnpth.la");
        removeFileIfExistsE("/usr/lib/libgpg-error.0.dylib");
        removeFileIfExistsE("/usr/lib/libgpg-error.dylib");
        removeFileIfExistsE("/usr/lib/libgpg-error.la");
        removeFileIfExistsE("/usr/lib/libksba.8.dylib");
        removeFileIfExistsE("/usr/lib/libksba.dylib");
        removeFileIfExistsE("/usr/lib/libksba.la");
        removeFileIfExistsE("/usr/lib/cycript0.9");
        removeFileIfExistsE("/usr/lib/libhistory.5.dylib");
        removeFileIfExistsE("/usr/lib/libapt-pkg.dylib.4.6");
        removeFileIfExistsE("/usr/lib/libapt-pkg.4.6.dylib");
        removeFileIfExistsE("/usr/lib/libpam.dylib");
        removeFileIfExistsE("/usr/lib/libpamc.1.dylib");
        removeFileIfExistsE("/usr/lib/libpackageinfo.dylib");
        removeFileIfExistsE("/usr/lib/librocketbootstrap.dylib");
        removeFileIfExistsE("/usr/lib/libapt-pkg.dylib.4.6.0");
        removeFileIfExistsE("/usr/lib/libapt-pkg.4.6.0.dylib");
        removeFileIfExistsE("/usr/lib/libpanelw.5.dylib");
        removeFileIfExistsE("/usr/lib/libhistory.5.2.dylib");
        removeFileIfExistsE("/usr/lib/libreadline.6.dylib");
        removeFileIfExistsE("/usr/lib/libpanel.dylib");
        removeFileIfExistsE("/usr/lib/libapt-inst.dylib.1.1");
        removeFileIfExistsE("/usr/lib/libapt-inst.1.1.dylib");
        removeFileIfExistsE("/usr/lib/libcurses.dylib");
        removeFileIfExistsE("/usr/lib/liblzmadec.0.dylib");
        removeFileIfExistsE("/usr/lib/libhistory.6.dylib");
        removeFileIfExistsE("/usr/lib/libformw.dylib");
        removeFileIfExistsE("/usr/lib/libncursesw.dylib");
        removeFileIfExistsE("/usr/lib/libncurses.5.dylib");
        removeFileIfExistsE("/usr/lib/libreadline.5.dylib");
        removeFileIfExistsE("/usr/lib/libhistory.6.0.dylib");
        removeFileIfExistsE("/usr/lib/libform.5.dylib");
        removeFileIfExistsE("/usr/lib/libpanelw.dylib");
        removeFileIfExistsE("/usr/lib/libmenuw.dylib");
        removeFileIfExistsE("/usr/lib/libform.dylib");
        removeFileIfExistsE("/usr/lib/terminfo");
        removeFileIfExistsE("/usr/lib/terminfo");
        removeFileIfExistsE("/usr/lib/libpam.1.0.dylib");
        removeFileIfExistsE("/usr/lib/libmenu.5.dylib");
        removeFileIfExistsE("/usr/lib/libpatcyh.dylib");
        removeFileIfExistsE("/usr/lib/libreadline.6.0.dylib");
        removeFileIfExistsE("/usr/lib/liblzmadec.dylib");
        removeFileIfExistsE("/usr/lib/libncurses.dylib");
        removeFileIfExistsE("/usr/lib/libhistory.dylib");
        removeFileIfExistsE("/usr/lib/libpamc.dylib");
        removeFileIfExistsE("/usr/lib/libformw.5.dylib");
        removeFileIfExistsE("/usr/lib/libapt-inst.dylib.1.1.0");
        removeFileIfExistsE("/usr/lib/libapt-inst.1.1.0.dylib");
        removeFileIfExistsE("/usr/lib/libpanel.5.dylib");
        removeFileIfExistsE("/usr/lib/liblzmadec.0.0.0.dylib");
        removeFileIfExistsE("/usr/lib/_ncurses");
        removeFileIfExistsE("/usr/lib/libpam_misc.1.dylib");
        removeFileIfExistsE("/usr/lib/libreadline.5.2.dylib");
        removeFileIfExistsE("/usr/lib/libpam_misc.dylib");
        removeFileIfExistsE("/usr/lib/libreadline.dylib");
        removeFileIfExistsE("/usr/lib/libmenuw.5.dylib");
        removeFileIfExistsE("/usr/lib/libpam.1.dylib");
        removeFileIfExistsE("/usr/lib/libmenu.dylib");
        removeFileIfExistsE("/usr/lib/liblzmadec.la");
        removeFileIfExistsE("/usr/lib/libncursesw.5.dylib");
        removeFileIfExistsE("/usr/lib/libcycript.dylib");
        removeFileIfExistsE("/usr/lib/libcycript.jar");
        removeFileIfExistsE("/usr/lib/libcycript.db");
        removeFileIfExistsE("/usr/lib/libcurl.4.dylib");
        removeFileIfExistsE("/usr/lib/libcurl.dylib");
        removeFileIfExistsE("/usr/lib/libcurl.la");
        removeFileIfExistsE("/usr/lib/libcycript.0.dylib");
        removeFileIfExistsE("/usr/lib/libcycript.cy");
        removeFileIfExistsE("/usr/lib/libcephei.dylib");
        removeFileIfExistsE("/usr/lib/libcepheiprefs.dylib");
        removeFileIfExistsE("/usr/lib/libhbangcommon.dylib");
        removeFileIfExistsE("/usr/lib/libhbangprefs.dylib");
        /////end it
        removeFileIfExistsE("/usr/lib/libjailbreak.dylib");
        removeFileIfExistsE("/var/profile");
        removeFileIfExistsE("/var/motd");
        removeFileIfExistsE("/var/log/testbin.log");
        removeFileIfExistsE("/var/log/apt");
        removeFileIfExistsE("/var/log/jailbreakd-stderr.log");
        removeFileIfExistsE("/var/log/jailbreakd-stdout.log");
        removeFileIfExistsE("/Library/test_inject_springboard.cy");
        removeFileIfExistsE("/usr/local/lib/libluajit.a");
        removeFileIfExistsE("/bin/zsh");
        //missing from removeMe.sh oddly
        //////mine above lol
        //////////////////Jakes below
        
        removeFileIfExistsE("/var/LIB");
        removeFileIfExistsE("/var/bin");
        removeFileIfExistsE("/var/sbin");
        removeFileIfExistsE("/var/profile");
        removeFileIfExistsE("/var/motd");
        removeFileIfExistsE("/var/dropbear");
        removeFileIfExistsE("/var/containers/Bundle/tweaksupport");
        removeFileIfExistsE("/var/containers/Bundle/iosbinpack64");
        removeFileIfExistsE("/var/containers/Bundle/dylibs");
        removeFileIfExistsE("/var/LIB");
        removeFileIfExistsE("/var/motd");
        removeFileIfExistsE("/var/log/testbin.log");
        removeFileIfExistsE("/var/log/jailbreakd-stdout.log");
        removeFileIfExistsE("/var/log/jailbreakd-stderr.log");
        removeFileIfExistsE("/usr/bin/find");
        
        
        
        
        
        removeFileIfExistsE("/var/cache");
        removeFileIfExistsE("/var/freya");
        removeFileIfExistsE("/var/lib");
        removeFileIfExistsE("/var/stash");
        removeFileIfExistsE("/var/db/stash");
        removeFileIfExistsE("/var/mobile/Library/Cydia");
        removeFileIfExistsE("/var/mobile/Library/Caches/com.saurik.Cydia");
        removeFileIfExistsE("/etc/apt/sources.list.d");
                     
        removeFileIfExistsE("/etc/apt/sources.list");
        removeFileIfExistsE("/private/etc/apt");
        removeFileIfExistsE("/private/etc/alternatives");
        removeFileIfExistsE("/private/etc/default");
        removeFileIfExistsE("/private/etc/dpkg");
        removeFileIfExistsE("/private/etc/dropbear");
        removeFileIfExistsE("/private/etc/localtime");
        removeFileIfExistsE("/private/etc/motd");
        removeFileIfExistsE("/private/etc/pam.d");
        removeFileIfExistsE("/private/etc/profile");
        removeFileIfExistsE("/private/etc/pkcs11");
        removeFileIfExistsE("/private/etc/profile.d");
        removeFileIfExistsE("/private/etc/profile.ro");
        removeFileIfExistsE("/private/etc/rc.d");
        removeFileIfExistsE("/private/etc/resolv.conf");
        removeFileIfExistsE("/private/etc/ssh");
        removeFileIfExistsE("/private/etc/ssl");
        removeFileIfExistsE("/private/etc/sudo_logsrvd.conf");
        removeFileIfExistsE("/private/etc/sudo.conf");
        removeFileIfExistsE("/private/etc/sudo_logsrvd.conf");
        removeFileIfExistsE("/private/etc/sudoers");
        removeFileIfExistsE("/private/etc/sudoers.d");
        removeFileIfExistsE("/private/etc/sudoers.dist");
        removeFileIfExistsE("/private/etc/wgetrc");
        removeFileIfExistsE("/private/etc/symlibs.dylib");
        removeFileIfExistsE("/private/etc/zshrc");
        removeFileIfExistsE("/private/etc/zprofile");
        
        removeFileIfExistsE("/private/private");
        removeFileIfExistsE("/private/var/containers/Bundle/dylibs");
        removeFileIfExistsE("/private/var/containers/Bundle/iosbinpack64");
        removeFileIfExistsE("/private/var/containers/Bundle/tweaksupport");
        removeFileIfExistsE("/private/var/log/suckmyd-stderr.log");
        removeFileIfExistsE("/private/var/log/suckmyd-stdout.log");
        removeFileIfExistsE("/private/var/log/jailbreakd-stderr.log");
        removeFileIfExistsE("/private/var/log/jailbreakd-stdout.log");
        removeFileIfExistsE("/private/var/backups");
        removeFileIfExistsE("/private/var/empty");
        removeFileIfExistsE("/private/var/bin");
        removeFileIfExistsE("/private/var/cache");
        removeFileIfExistsE("/private/var/cercube_stashed");
        removeFileIfExistsE("/private/var/db/stash");
        removeFileIfExistsE("/private/var/db/sudo");
        removeFileIfExistsE("/private/var/dropbear");
        removeFileIfExistsE("/private/var/Ext3nder-Installer");
        removeFileIfExistsE("/private/var/lib");
        removeFileIfExistsE("/var/lib");
        removeFileIfExistsE("/private/var/LIB");
        removeFileIfExistsE("/private/var/local");
        removeFileIfExistsE("/private/var/log/apt");
        removeFileIfExistsE("/private/var/log/dpkg");
        removeFileIfExistsE("/private/var/log/testbin.log");
        removeFileIfExistsE("/private/var/lock");
        removeFileIfExistsE("/private/var/mobile/Library/Activator");
        removeFileIfExistsE("/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist");
        removeFileIfExistsE("/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia");
        removeFileIfExistsE("/private/var/mobile/Library/Application\ Support/Activator");
        removeFileIfExistsE("/private/var/mobile/Library/Application\ Support/Flex3");
        removeFileIfExistsE("/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState");
        removeFileIfExistsE("/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState");
        removeFileIfExistsE("/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState");
        removeFileIfExistsE("/private/var/mobile/Library/com.saurik.Cydia");
        removeFileIfExistsE("/private/var/mobile/Library/Cr4shed");
        removeFileIfExistsE("/private/var/mobile/Library/CT4");
        removeFileIfExistsE("/private/var/mobile/Library/CT3");
        removeFileIfExistsE("/private/var/mobile/Library/Cydia");
        removeFileIfExistsE("/private/var/mobile/Library/Flex3");
        removeFileIfExistsE("/private/var/mobile/Library/Filza");
        removeFileIfExistsE("/private/var/mobile/Library/Fingal");
        removeFileIfExistsE("/private/var/mobile/Library/iWidgets");
        removeFileIfExistsE("/private/var/mobile/Library/LockHTML");
        removeFileIfExistsE("/private/var/mobile/Library/Logs/Cydia");
        removeFileIfExistsE("/private/var/mobile/Library/Notchification");
        removeFileIfExistsE("/private/var/mobile/Library/unlimapps_tweaks_resources");
        removeFileIfExistsE("/private/var/mobile/Library/Sileo");
        removeFileIfExistsE("/private/var/mobile/Library/SBHTML");
        removeFileIfExistsE("/private/var/mobile/Library/Toonsy");
        removeFileIfExistsE("/private/var/mobile/Library/Widgets");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/libactivator.plist");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/com.johncoates.Flex");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/com.saurik.Cydia");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/AmyCache");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/org.coolstar.SileoStore");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/com.saurik.Cydia");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/com.saurik.Cydia");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/com.tigisoftware.Filza");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal");
        removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo");
        removeFileIfExistsE("/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist");
        removeFileIfExistsE("/private/var/mobile/Library/libactivator.plist");
        removeFileIfExistsE("/private/var/motd");
        removeFileIfExistsE("/private/var/profile");
        removeFileIfExistsE("/private/var/run/pspawn_hook.ts");
        removeFileIfExistsE("/private/var/run/utmp");
        removeFileIfExistsE("/private/var/run/sudo");
        removeFileIfExistsE("/private/var/sbin");
        removeFileIfExistsE("/private/var/spool");
        removeFileIfExistsE("/private/var/tmp/cydia.log");
        removeFileIfExistsE("/private/var/tweak");
        removeFileIfExistsE("/private/var/unlimapps_tweak_resources");
        removeFileIfExistsE("/Library/Alkaline");
        removeFileIfExistsE("/Library/Activator");
        removeFileIfExistsE("/Library/Application\ Support/Snoverlay");
        removeFileIfExistsE("/Library/Application\ Support/Flame");
        removeFileIfExistsE("/Library/Application\ Support/CallBlocker");
        removeFileIfExistsE("/Library/Application\ Support/CCSupport");
        removeFileIfExistsE("/Library/Application\ Support/Compatimark");
        removeFileIfExistsE("/Library/Application\ Support/Malipo");
        removeFileIfExistsE("/Library/Application\ Support/SafariPlus.bundle");
        removeFileIfExistsE("/Library/Application\ Support/Activator");
        removeFileIfExistsE("/Library/Application\ Support/Cylinder");
        removeFileIfExistsE("/Library/Application\ Support/Barrel");
        removeFileIfExistsE("/Library/Application\ Support/BarrelSettings");
        removeFileIfExistsE("/Library/Application\ Support/libGitHubIssues");
        removeFileIfExistsE("/Library/Barrel");
        removeFileIfExistsE("/Library/BarrelSettings");
        removeFileIfExistsE("/Library/Cylinder");
        removeFileIfExistsE("/Library/dpkg");
        removeFileIfExistsE("/Library/Flipswitch");
        removeFileIfExistsE("/Library/Frameworks");
        removeFileIfExistsE("/Library/LaunchDaemons");
        removeFileIfExistsE("/Library/MobileSubstrate");
        removeFileIfExistsE("/Library/MobileSubstrate/");
        removeFileIfExistsE("/Library/MobileSubstrate/DynamicLibraries");
        removeFileIfExistsE("/Library/PreferenceBundles");
        removeFileIfExistsE("/Library/PreferenceLoader");
        removeFileIfExistsE("/Library/SBInject");
        removeFileIfExistsE("/Library/Switches");
        removeFileIfExistsE("/Library/test_inject_springboard.cy");
        removeFileIfExistsE("/Library/Themes");
        removeFileIfExistsE("/Library/TweakInject");
        removeFileIfExistsE("/Library/Zeppelin");
        removeFileIfExistsE("/Library/.DS_Store");
        removeFileIfExistsE("/System/Library/PreferenceBundles/AppList.bundle");
        removeFileIfExistsE("/System/Library/Themes");
        removeFileIfExistsE("/System/Library/KeyboardDictionaries");
        removeFileIfExistsE("/usr/lib/libform.dylib");
        removeFileIfExistsE("/usr/lib/libncurses.5.dylib");
        removeFileIfExistsE("/usr/lib/libresolv.dylib");
        removeFileIfExistsE("/usr/lib/liblzma.dylib");
        removeFileIfExistsE("/usr/include");
        removeFileIfExistsE("/usr/share/aclocal");
        removeFileIfExistsE("/usr/share/bigboss");
        removeFileIfExistsE("/share/common-lisp");
        removeFileIfExistsE("/usr/share/dict");
        removeFileIfExistsE("/usr/share/dpkg");
        removeFileIfExistsE("/usr/share/git-core");
        removeFileIfExistsE("/usr/share/git-gui");
        removeFileIfExistsE("/usr/share/gnupg");
        removeFileIfExistsE("/usr/share/gitk");
        removeFileIfExistsE("/usr/share/gitweb");
        removeFileIfExistsE("/usr/share/libgpg-error");
        removeFileIfExistsE("/usr/share/man");
        removeFileIfExistsE("/usr/share/p11-kit");
        removeFileIfExistsE("/usr/share/tabset");
        removeFileIfExistsE("/usr/share/terminfo");
        removeFileIfExistsE("/.freya_installed");
        removeFileIfExistsE("/.freya_bootstrap");
        
        ////////
    }
    
    ///////////////////////////////
    ///////////////////////////////
    //////////////////////////////finally added the check for changing remvoving files without needing two separate apps
    
    else if (/* iOS 11.3 and higher can use lucky snapshot */ kCFCoreFoundationVersionNumber > 1451.51){ printf("[*] Removing Jailbreak for devices greater or equal to ios 11.3....\n");
            removeFileIfExistsE("/private/etc/apt");
        
            ////usr/etc//
            ////etc folder cleanup
            ///        removeFileIfExistsE("/RWTEST");
            ///        
            
            
            
            removeFileIfExistsE("/electra/launchctl");
            
            removeFileIfExistsE("/electra/launchctl");
            removeFileIfExistsE("/var/mobile/Media/.bootstrapped_electraremover");
            removeFileIfExistsE("/var/mobile/testremover.txt");
            unlink("/var/mobile/testremover.txt");
            removeFileIfExistsE("/.bootstrapped_Th0r");
            removeFileIfExistsE("/.freya_installed");
            removeFileIfExistsE("/.bootstrapped_electra");
            removeFileIfExistsE("/.installed_unc0ver");
            removeFileIfExistsE("/.install_unc0ver");
            removeFileIfExistsE("/.electra_no_snapshot");
            removeFileIfExistsE("/.installed_unc0vered");
            removeFileIfExistsE("/pwnedWritefileatrootTEST");
            removeFileIfExistsE("/Applications/Cydia\ Update\ Helper.app");
            removeFileIfExistsE("/NETWORK");
            removeFileIfExistsE("/Applications/AppCake.app");
            removeFileIfExistsE("/Applications/Activator.app");
            removeFileIfExistsE("/Applications/Anemone.app");
            removeFileIfExistsE("/Applications/BestCallerId.app");
            removeFileIfExistsE("/Applications/CrackTool3.app");
            removeFileIfExistsE("/Applications/Cydia.app");
            removeFileIfExistsE("/Applications/Sileo.app");
            removeFileIfExistsE("/Applications/Rollectra.app");
            removeFileIfExistsE("/Applications/cydown.app");
            removeFileIfExistsE("/Applications/Cylinder.app");
            removeFileIfExistsE("/Applications/iCleaner.app");
            removeFileIfExistsE("/Applications/icleaner.app");
            removeFileIfExistsE("/Applications/BarrelSettings.app");
            removeFileIfExistsE("/Applications/Ext3nder.app");
            removeFileIfExistsE("/Applications/Filza.app");
            removeFileIfExistsE("/Applications/Flex.app");
            removeFileIfExistsE("/Applications/GBA4iOS.app");
            removeFileIfExistsE("/Applications/jjjj.app");
            removeFileIfExistsE("/Applications/ReProvision.app");
            removeFileIfExistsE("/Applications/SafeMode.app");
            removeFileIfExistsE("/Applications/NewTerm.app");
            removeFileIfExistsE("/Applications/MobileTerminal.app");
            removeFileIfExistsE("/Applications/MTerminal.app");
            removeFileIfExistsE("/Applications/MovieBox3.app");
            removeFileIfExistsE("/Applications/BobbyMovie.app");
            removeFileIfExistsE("/Applications/PopcornTime.app");
            removeFileIfExistsE("/Applications/RST.app");
            removeFileIfExistsE("/Applications/TSSSaver.app");
            removeFileIfExistsE("/Applications/CertRemainTime.app");
            removeFileIfExistsE("/Applications/CrashReporter.app");
            removeFileIfExistsE("/Applications/AudioRecorder.app");
            removeFileIfExistsE("/Applications/ADManager.app");
            removeFileIfExistsE("/Applications/CocoaTop.app");
            removeFileIfExistsE("/Applications/calleridfaker.app");
            removeFileIfExistsE("/Applications/CallLogPro.app");
            removeFileIfExistsE("/Applications/WiFiPasswords.app");
            removeFileIfExistsE("/Applications/WifiPasswordList.app");
            removeFileIfExistsE("/Applications/calleridfaker.app");
            removeFileIfExistsE("/Applications/ClassDumpGUI.app");
            removeFileIfExistsE("/Applications/idevicewallsapp.app");
            removeFileIfExistsE("/Applications/UDIDFaker.app");
            removeFileIfExistsE("/Applications/UDIDCalculator.app");
            removeFileIfExistsE("/Applications/CallRecorder.app");
            removeFileIfExistsE("/Applications/Rehosts.app");
            removeFileIfExistsE("/Applications/NGXCarPlay.app");
            removeFileIfExistsE("/Applications/Audicy.app");
            removeFileIfExistsE("/Applications/NGXCarplay.app");

            
            removeFileIfExistsE("/private/etc/pam.d");
            //private/etc
            removeFileIfExistsE("/private/etc/apt");
            removeFileIfExistsE("/private/etc/alternatives");
            removeFileIfExistsE("/private/etc/default");
            removeFileIfExistsE("/private/etc/dpkg");
            removeFileIfExistsE("/private/etc/dropbear");
            removeFileIfExistsE("/private/etc/localtime");
            removeFileIfExistsE("/private/etc/motd");
            removeFileIfExistsE("/private/etc/pam.d");
            removeFileIfExistsE("/private/etc/profile");
            removeFileIfExistsE("/private/etc/pkcs11");
            removeFileIfExistsE("/private/etc/profile.d");
            removeFileIfExistsE("/private/etc/profile.ro");
            removeFileIfExistsE("/private/etc/rc.d");
            removeFileIfExistsE("/private/etc/resolv.conf");
            removeFileIfExistsE("/private/etc/ssh");
            removeFileIfExistsE("/private/etc/ssl");
            removeFileIfExistsE("/private/etc/sudo_logsrvd.conf");
            removeFileIfExistsE("/private/etc/sudo.conf");
            removeFileIfExistsE("/private/etc/sudo_logsrvd.conf");
            removeFileIfExistsE("/private/etc/sudoers");
            removeFileIfExistsE("/private/etc/sudoers.d");
            removeFileIfExistsE("/private/etc/sudoers.dist");
            removeFileIfExistsE("/private/etc/wgetrc");
            removeFileIfExistsE("/private/etc/symlibs.dylib");
            removeFileIfExistsE("/private/etc/zshrc");
            removeFileIfExistsE("/private/etc/zprofile");
            ////private/var
            removeFileIfExistsE("/private/var/backups");
            removeFileIfExistsE("/private/var/cache");
            removeFileIfExistsE("/private/var/Ext3nder-Installer");
            removeFileIfExistsE("/private/var/lib");
            removeFileIfExistsE("/private/var/local");
            removeFileIfExistsE("/private/var/lock");
            removeFileIfExistsE("/private/var/spool");
            removeFileIfExistsE("/private/var/lib/apt");
            removeFileIfExistsE("/private/var/lib/dpkg");
            removeFileIfExistsE("/private/var/lib/dpkg");
            removeFileIfExistsE("/private/var/lib/cydia");
            removeFileIfExistsE("/private/var/db/stash");
            removeFileIfExistsE("/private/var/stash");
            removeFileIfExistsE("/private/var/tweak");
            removeFileIfExistsE("/private/var/cercube_stashed");
            removeFileIfExistsE("/private/var/tmp/cydia.log");
            removeFileIfExistsE("/private/var/run/utmp");
            removeFileIfExistsE("/private/var/profile");
            removeFileIfExistsE("/private/var/motd");
            removeFileIfExistsE("/private/var/log/testbin.log");
            removeFileIfExistsE("/private/var/log/apt");
            removeFileIfExistsE("/private/var/log/jailbreakd-stderr.log");
            removeFileIfExistsE("/private/var/log/jailbreakd-stdout.log");
            removeFileIfExistsE("/private/var/LIB");
            removeFileIfExistsE("/private/var/bin");
            removeFileIfExistsE("/private/var/sbin");
            removeFileIfExistsE("/private/var/dropbear");
            removeFileIfExistsE("/private/var/empty");
            removeFileIfExistsE("/private/var/bin");
            removeFileIfExistsE("/private/var/cercube_stashed");
            removeFileIfExistsE("/private/var/db/sudo");
            removeFileIfExistsE("/private/var/log/dpkg");
            removeFileIfExistsE("/private/var/containers/Bundle/tweaksupport");
            removeFileIfExistsE("/private/var/containers/Bundle/iosbinpack64");
            removeFileIfExistsE("/private/var/containers/Bundle/dylibs");
            removeFileIfExistsE("/private/var/freya/");
            //var/mobile/Library
            removeFileIfExistsE("/private/var/mobile/Library/Flex3");
            removeFileIfExistsE("/private/var/mobile/Library/Notchification");
            removeFileIfExistsE("/private/var/mobile/Library/unlimapps_tweaks_resources");
            removeFileIfExistsE("/private/var/mobile/Library/Fingal");
            removeFileIfExistsE("/private/var/mobile/Library/Filza");
            removeFileIfExistsE("/private/var/mobile/Library/CT3");
            removeFileIfExistsE("/private/var/mobile/Library/Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/com.saurik.Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/com.saurik.Cydia/");
            removeFileIfExistsE("/private/var/mobile/Library/SBHTML");
            removeFileIfExistsE("/private/var/mobile/Library/LockHTML");
            removeFileIfExistsE("/private/var/mobile/Library/iWidgets");
            //var/mobile/Library/Caches
            removeFileIfExistsE("/private/var/mobile/Library/Application\ Support/Flex3");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/libactivator.plist");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/com.tigisoftware.Filza");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/com.johncoates.Flex");
            removeFileIfExistsE("/private/var/mobile/Library/libactivator.plist");
            removeFileIfExistsE("/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist");
            removeFileIfExistsE("/private/var/mobile/Library/Application\ Support/Activator");
            removeFileIfExistsE("/private/var/mobile/Library/Activator");
            //snapshot.library
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal");
            removeFileIfExistsE("/private/var/run/utmp");
            removeFileIfExistsE("/private/var/run/pspawn_hook.ts");
            //////system/library
            removeFileIfExistsE("/var/mobile/Library/Cydia");
            removeFileIfExistsE("/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsE("/private/private");
            removeFileIfExistsE("/private/var/containers/Bundle/dylibs");
            removeFileIfExistsE("/private/var/containers/Bundle/iosbinpack64");
            removeFileIfExistsE("/private/var/containers/Bundle/tweaksupport");
            removeFileIfExistsE("/private/var/log/suckmyd-stderr.log");
            removeFileIfExistsE("/private/var/log/suckmyd-stdout.log");
            removeFileIfExistsE("/private/var/log/jailbreakd-stderr.log");
            removeFileIfExistsE("/private/var/log/jailbreakd-stdout.log");
            removeFileIfExistsE("/private/var/mobile/Library/Activator");
            removeFileIfExistsE("/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist");
            removeFileIfExistsE("/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Application\ Support/Activator");
            removeFileIfExistsE("/private/var/mobile/Library/Application\ Support/Flex3");
            removeFileIfExistsE("/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState");
            removeFileIfExistsE("/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState");
            removeFileIfExistsE("/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState");
            removeFileIfExistsE("/private/var/mobile/Library/com.saurik.Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Cr4shed");
            removeFileIfExistsE("/private/var/mobile/Library/CT4");
            removeFileIfExistsE("/private/var/mobile/Library/CT3");
            removeFileIfExistsE("/private/var/mobile/Library/Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Flex3");
            removeFileIfExistsE("/private/var/mobile/Library/Filza");
            removeFileIfExistsE("/private/var/mobile/Library/Fingal");
            removeFileIfExistsE("/private/var/mobile/Library/iWidgets");
            removeFileIfExistsE("/private/var/mobile/Library/LockHTML");
            removeFileIfExistsE("/private/var/mobile/Library/Logs/Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Notchification");
            removeFileIfExistsE("/private/var/mobile/Library/unlimapps_tweaks_resources");
            removeFileIfExistsE("/private/var/mobile/Library/Sileo");
            removeFileIfExistsE("/private/var/mobile/Library/SBHTML");
            removeFileIfExistsE("/private/var/mobile/Library/Toonsy");
            removeFileIfExistsE("/private/var/mobile/Library/Widgets");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/libactivator.plist");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/com.johncoates.Flex");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/AmyCache");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/org.coolstar.SileoStore");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/com.tigisoftware.Filza");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo");
            removeFileIfExistsE("/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist");
            removeFileIfExistsE("/private/var/mobile/Library/libactivator.plist");
            removeFileIfExistsE("/private/var/motd");
            removeFileIfExistsE("/private/var/profile");
            removeFileIfExistsE("/private/var/run/pspawn_hook.ts");
            removeFileIfExistsE("/private/var/run/utmp");
            removeFileIfExistsE("/private/var/run/sudo");
            removeFileIfExistsE("/private/var/sbin");
            removeFileIfExistsE("/private/var/spool");
            removeFileIfExistsE("/private/var/tmp/cydia.log");
            removeFileIfExistsE("/private/var/tweak");
            removeFileIfExistsE("/private/var/unlimapps_tweak_resources");
            
            
            removeFileIfExistsE("/var/cache");
            removeFileIfExistsE("/var/freya");
            removeFileIfExistsE("/var/lib");
            removeFileIfExistsE("/var/stash");
            removeFileIfExistsE("/var/db/stash");
            removeFileIfExistsE("/var/mobile/Library/Cydia");
            removeFileIfExistsE("/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsE("/etc/apt/sources.list.d");
            removeFileIfExistsE("/etc/apt/sources.list");
            removeFileIfExistsE("/private/etc/apt");
            removeFileIfExistsE("/private/etc/alternatives");
            removeFileIfExistsE("/private/etc/default");
            removeFileIfExistsE("/private/etc/dpkg");
            removeFileIfExistsE("/private/etc/dropbear");
            removeFileIfExistsE("/private/etc/localtime");
            removeFileIfExistsE("/private/etc/motd");
            removeFileIfExistsE("/private/etc/pam.d");
            removeFileIfExistsE("/private/etc/profile");
            removeFileIfExistsE("/private/etc/pkcs11");
            removeFileIfExistsE("/private/etc/profile.d");
            removeFileIfExistsE("/private/etc/profile.ro");
            removeFileIfExistsE("/private/etc/rc.d");
            removeFileIfExistsE("/private/etc/resolv.conf");
            removeFileIfExistsE("/private/etc/ssh");
            removeFileIfExistsE("/private/etc/ssl");
            removeFileIfExistsE("/private/etc/sudo_logsrvd.conf");
            removeFileIfExistsE("/private/etc/sudo.conf");
            removeFileIfExistsE("/private/etc/sudo_logsrvd.conf");
            removeFileIfExistsE("/private/etc/sudoers");
            removeFileIfExistsE("/private/etc/sudoers.d");
            removeFileIfExistsE("/private/etc/sudoers.dist");
            removeFileIfExistsE("/private/etc/wgetrc");
            removeFileIfExistsE("/private/etc/symlibs.dylib");
            removeFileIfExistsE("/private/etc/zshrc");
            removeFileIfExistsE("/private/etc/zprofile");
            removeFileIfExistsE("/private/private");
            removeFileIfExistsE("/private/var/containers/Bundle/dylibs");
            removeFileIfExistsE("/private/var/containers/Bundle/iosbinpack64");
            removeFileIfExistsE("/private/var/containers/Bundle/tweaksupport");
            removeFileIfExistsE("/private/var/log/suckmyd-stderr.log");
            removeFileIfExistsE("/private/var/log/suckmyd-stdout.log");
            removeFileIfExistsE("/private/var/log/jailbreakd-stderr.log");
            removeFileIfExistsE("/private/var/log/jailbreakd-stdout.log");
            removeFileIfExistsE("/private/var/backups");
            removeFileIfExistsE("/private/var/empty");
            removeFileIfExistsE("/private/var/bin");
            removeFileIfExistsE("/private/var/cache");
            removeFileIfExistsE("/private/var/cercube_stashed");
            removeFileIfExistsE("/private/var/db/stash");
            removeFileIfExistsE("/private/var/db/sudo");
            removeFileIfExistsE("/private/var/dropbear");
            removeFileIfExistsE("/private/var/Ext3nder-Installer");
            removeFileIfExistsE("/private/var/lib");
            removeFileIfExistsE("/var/lib");
            removeFileIfExistsE("/private/var/LIB");
            removeFileIfExistsE("/private/var/local");
            removeFileIfExistsE("/private/var/log/apt");
            removeFileIfExistsE("/private/var/log/dpkg");
            removeFileIfExistsE("/private/var/log/testbin.log");
            removeFileIfExistsE("/private/var/lock");
            removeFileIfExistsE("/private/var/mobile/Library/Activator");
            removeFileIfExistsE("/private/var/mobile/Library/Preferences/ws.hbang.Terminal.plist");
            removeFileIfExistsE("/private/var/mobile/Library/SplashBoard/Snapshots/com.saurik.Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Application\ Support/Activator");
            removeFileIfExistsE("/private/var/mobile/Library/Application\ Support/Flex3");
            removeFileIfExistsE("/private/var/mobile/Library/Saved\ Application\ State/ws.hbang.Terminal.savedState");
            removeFileIfExistsE("/private/var/mobile/Library/Saved\ Application\ State/org.coolstar.SileoStore.savedState");
            removeFileIfExistsE("/private/var/mobile/Library/Saved\ Application\ State/com.saurik.Cydia.savedState");
            removeFileIfExistsE("/private/var/mobile/Library/com.saurik.Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Cr4shed");
            removeFileIfExistsE("/private/var/mobile/Library/CT4");
            removeFileIfExistsE("/private/var/mobile/Library/CT3");
            removeFileIfExistsE("/private/var/mobile/Library/Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Flex3");
            removeFileIfExistsE("/private/var/mobile/Library/Filza");
            removeFileIfExistsE("/private/var/mobile/Library/Fingal");
            removeFileIfExistsE("/private/var/mobile/Library/iWidgets");
            removeFileIfExistsE("/private/var/mobile/Library/LockHTML");
            removeFileIfExistsE("/private/var/mobile/Library/Logs/Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Notchification");
            removeFileIfExistsE("/private/var/mobile/Library/unlimapps_tweaks_resources");
            removeFileIfExistsE("/private/var/mobile/Library/Sileo");
            removeFileIfExistsE("/private/var/mobile/Library/SBHTML");
            removeFileIfExistsE("/private/var/mobile/Library/Toonsy");
            removeFileIfExistsE("/private/var/mobile/Library/Widgets");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/libactivator.plist");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/com.johncoates.Flex");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/AmyCache");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/org.coolstar.SileoStore");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/com.saurik.Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/com.tigisoftware.Filza");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal");
            removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.Sileo");
            removeFileIfExistsE("/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist");
            removeFileIfExistsE("/private/var/mobile/Library/libactivator.plist");
            removeFileIfExistsE("/private/var/motd");
            removeFileIfExistsE("/private/var/profile");
            removeFileIfExistsE("/private/var/run/pspawn_hook.ts");
            removeFileIfExistsE("/private/var/run/utmp");
            removeFileIfExistsE("/private/var/run/sudo");
            removeFileIfExistsE("/private/var/sbin");
            removeFileIfExistsE("/private/var/spool");
            removeFileIfExistsE("/private/var/tmp/cydia.log");
            removeFileIfExistsE("/private/var/tweak");
            removeFileIfExistsE("/private/var/unlimapps_tweak_resources");
            [[NSFileManager defaultManager] removeItemAtPath:@"/etc/apt/sources.list.d" error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:@"/etc/profile" error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:@"/usr/bin/rsync" error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:@"/bin/rm" error:nil];

            
            
            FILE *file = fopen("/etc/hosts","w"); /* write file (create a file if it does not exist and if it does treat as empty.*/
                    fprintf(file,"%s","##\n"); //writes
                    fprintf(file,"%s","# Host Database\n"); //writes
                    fprintf(file,"%s","# localhost is used to configure the loopback interface\n"); //writes
                    fprintf(file,"%s","# when the system is booting.  Do not change this entry.\n"); //writes
                    fprintf(file,"%s","##\n"); //writes
                    fprintf(file,"%s","127.0.0.1    localhost\n"); //writes
                    fprintf(file,"%s","255.255.255.255 broadcasthost\n"); //writes
                    fprintf(file,"%s","::1      localhost\n"); //writes
                    fclose(file); /*done!*/
                    /////////START REMOVING FILES
                        
                        removeFileIfExistsE("/private/etc/motd");
                        removeFileIfExistsE("/.cydia_no_stash");
                        
                        removeFileIfExistsE("/Applications/Cydia.app");
                        
                        removeFileIfExistsE("/usr/share/aclocal");
                        removeFileIfExistsE("/usr/share/bigboss");
                        removeFileIfExistsE("/usr/share/common-lisp");
                        removeFileIfExistsE("/usr/share/dict");
                        removeFileIfExistsE("/usr/share/dpkg");
                        removeFileIfExistsE("/usr/share/gnupg");
                        removeFileIfExistsE("/usr/share/libgpg-error");
                        removeFileIfExistsE("/usr/share/p11-kit");
                        removeFileIfExistsE("/usr/share/tabset");
                        removeFileIfExistsE("/usr/share/terminfo");
                        
                        removeFileIfExistsE("/usr/local/bin");
                        removeFileIfExistsE("/usr/local/lib");
                        
                        removeFileIfExistsE("/authorize.sh");
                        removeFileIfExistsE("/.cydia_no_stash");
                        removeFileIfExistsE("/bin/zsh");
                        removeFileIfExistsE("/private/etc/profile");
                        removeFileIfExistsE("/private/etc/rc.d");
                        removeFileIfExistsE("/private/etc/rc.d/substrate");
                        removeFileIfExistsE("/etc/zshrc");
                        ////usr/etc//
                        removeFileIfExistsE("/usr/etc");
                        removeFileIfExistsE("/usr/bin/scp");
                        ////usr/lib////
                        
                        removeFileIfExistsE("/usr/lib/_ncurses");
                        removeFileIfExistsE("/usr/lib/apt");
                        removeFileIfExistsE("/usr/lib/bash");
                        removeFileIfExistsE("/usr/lib/gettext");
                        removeFileIfExistsE("/usr/lib/libapt-inst.2.0.0.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-inst.2.0.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-inst.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-pkg.5.0.1.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-pkg.5.0.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-pkg.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-private.0.0.0.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-private.0.0.dylib");
                        removeFileIfExistsE("/usr/lib/libasprintf.0.dylib");
                        removeFileIfExistsE("/usr/lib/libasprintf.dylib");
                        removeFileIfExistsE("/usr/lib/libassuan.0.dylib");
                        removeFileIfExistsE("/usr/lib/libassuan.dylib");
                        removeFileIfExistsE("/usr/lib/libassuan.la");
                        removeFileIfExistsE("/usr/lib/libdpkg.a");
                        removeFileIfExistsE("/usr/lib/libform.5.dylib");
                        removeFileIfExistsE("/usr/lib/libform.6.dylib");
                        removeFileIfExistsE("/usr/lib/libform.dylib");
                        removeFileIfExistsE("/usr/lib/libform5.dylib");
                        removeFileIfExistsE("/usr/lib/libformw.5.dylib");
                        removeFileIfExistsE("/usr/lib/libformw.6.dylib");
                        removeFileIfExistsE("/usr/lib/libformw.dylib");
                        removeFileIfExistsE("/usr/lib/libformw5.dylib");
                        removeFileIfExistsE("/usr/lib/libgcrypt.20.dylib");
                        removeFileIfExistsE("/usr/lib/libgcrypt.dylib");
                        removeFileIfExistsE("/usr/lib/libgcrypt.la");
                        removeFileIfExistsE("/usr/lib/libgettextlib-0.19.8.dylib");
                        removeFileIfExistsE("/usr/lib/libgettextlib.dylib");
                        removeFileIfExistsE("/usr/lib/libgettextpo.1.dylib");
                        removeFileIfExistsE("/usr/lib/libgettextpo.dylib");
                        removeFileIfExistsE("/usr/lib/libgettextsrc-0.19.8.dylib");
                        removeFileIfExistsE("/usr/lib/libgettextsrc.dylib");
                        removeFileIfExistsE("/usr/lib/libgmp.10.dylib");
                        removeFileIfExistsE("/usr/lib/libgmp.dylib");
                        removeFileIfExistsE("/usr/lib/libgmp.la");
                        removeFileIfExistsE("/usr/lib/libgnutls.30.dylib");
                        removeFileIfExistsE("/usr/lib/libgnutls.dylib");
                        removeFileIfExistsE("/usr/lib/libgnutlsxx.28.dylib");
                        removeFileIfExistsE("/usr/lib/libgnutlsxx.dylib");
                        removeFileIfExistsE("/usr/lib/libgpg-error.0.dylib");
                        removeFileIfExistsE("/usr/lib/libgpg-error.dylib");
                        removeFileIfExistsE("/usr/lib/libgpg-error.la");
                        removeFileIfExistsE("/usr/lib/libhistory.5.2.dylib");
                        removeFileIfExistsE("/usr/lib/libhistory.6.0.dylib");
                        removeFileIfExistsE("/usr/lib/libhistory.5.dylib");
                        removeFileIfExistsE("/usr/lib/libhistory.7.0.dylib");
                        removeFileIfExistsE("/usr/lib/libhistory.7.dylib");
                        removeFileIfExistsE("/usr/lib/libhistory.dylib ");
                        removeFileIfExistsE("/usr/lib/libhogweed.4.4.dylib");
                        removeFileIfExistsE("/usr/lib/libhogweed.4.dylib");
                        removeFileIfExistsE("/usr/lib/libhogweed.dylib");
                        removeFileIfExistsE("/usr/lib/libidn2.0.dylib");
                        removeFileIfExistsE("/usr/lib/libidn2.dylib");
                        removeFileIfExistsE("/usr/lib/libidn2.la");
                        removeFileIfExistsE("/usr/lib/libintl.9.dylib");
                        removeFileIfExistsE("/usr/lib/libintl.dylib");
                        removeFileIfExistsE("/usr/lib/libksba.8.dylib");
                        removeFileIfExistsE("/usr/lib/libksba.dylib");
                        removeFileIfExistsE("/usr/lib/libksba.la");
                        removeFileIfExistsE("/usr/lib/liblz4.1.7.5.dylib");
                        removeFileIfExistsE("/usr/lib/liblz4.1.dylib");
                        removeFileIfExistsE("/usr/lib/liblz4.dylib");
                        removeFileIfExistsE("/usr/lib/liblzmadec.0.dylib");
                        removeFileIfExistsE("/usr/lib/liblzmadec.dylib");
                        removeFileIfExistsE("/usr/lib/libmenu.5.dylib");
                        removeFileIfExistsE("/usr/lib/libmenu.6.dylib");
                        removeFileIfExistsE("/usr/lib/libmenu.dylib");
                        removeFileIfExistsE("/usr/lib/libmenu5.dylib");
                        removeFileIfExistsE("/usr/lib/libmenuw.5.dylib");
                        removeFileIfExistsE("/usr/lib/libmenuw.6.dylib");
                        removeFileIfExistsE("/usr/lib/libmenuw.dylib");
                        removeFileIfExistsE("/usr/lib/libmenuw5.dylib");
                        removeFileIfExistsE("/usr/lib/libncurses.5.dylib");
                        removeFileIfExistsE("/usr/lib/libncurses.6.dylib");
                        removeFileIfExistsE("/usr/lib/libncurses5.dylib");
                        removeFileIfExistsE("/usr/lib/libncurses6.dylib");
                        removeFileIfExistsE("/usr/lib/libncursesw.5.dylib");
                        removeFileIfExistsE("/usr/lib/libncursesw.6.dylib");
                        removeFileIfExistsE("/usr/lib/libncursesw.dylib");
                        removeFileIfExistsE("/usr/lib/libncursesw5.dylib");
                        removeFileIfExistsE("/usr/lib/libncursesw6.dylib");
                        removeFileIfExistsE("/usr/lib/libnettle.6.4.dylib");
                        removeFileIfExistsE("/usr/lib/libnettle.6.dylib");
                        removeFileIfExistsE("/usr/lib/libnettle.dylib");
                        removeFileIfExistsE("/usr/lib/libnpth.0.dylib");
                        removeFileIfExistsE("/usr/lib/libnpth.dylib");
                        removeFileIfExistsE("/usr/lib/libnpth.la");
                        removeFileIfExistsE("/usr/lib/libp11-kit.0.dylib");
                        removeFileIfExistsE("/usr/lib/libp11-kit.dylib");
                        removeFileIfExistsE("/usr/lib/libp11-kit.la");
                        removeFileIfExistsE("/usr/lib/libpanel.5.dylib");
                        removeFileIfExistsE("/usr/lib/libpanel.6.dylib");
                        removeFileIfExistsE("/usr/lib/libpanel.dylib");
                        removeFileIfExistsE("/usr/lib/libpanel5.dylib");
                        removeFileIfExistsE("/usr/lib/libpanelw.5.dylib");
                        removeFileIfExistsE("/usr/lib/libpanelw.6.dylib");
                        removeFileIfExistsE("/usr/lib/libpanelw.dylib");
                        removeFileIfExistsE("/usr/lib/libpanelw5.dylib");
                        removeFileIfExistsE("/usr/lib/libreadline.5.2.dylib");
                        removeFileIfExistsE("/usr/lib/libreadline.6.0.dylib");
                        removeFileIfExistsE("/usr/lib/libreadline.5.dylib");
                        removeFileIfExistsE("/usr/lib/libreadline.7.0.dylib");
                        removeFileIfExistsE("/usr/lib/libreadline.7.dylib");
                        removeFileIfExistsE("/usr/lib/libreadline.dylib");
                        removeFileIfExistsE("/usr/lib/libresolv.9.dylib");
                        removeFileIfExistsE("/usr/lib/libresolv.dylib");
                        removeFileIfExistsE("/usr/lib/libtasn1.6.dylib");
                        removeFileIfExistsE("/usr/lib/libtasn1.dylib");
                        removeFileIfExistsE("/usr/lib/libtasn1.la");
                        removeFileIfExistsE("/usr/lib/libunistring.2.dylib");
                        removeFileIfExistsE("/usr/lib/libunistring.dylib");
                        removeFileIfExistsE("/usr/lib/libunistring.la");
                        
                        removeFileIfExistsE("/usr/lib/libsubstitute.0.dylib");
                        removeFileIfExistsE("/usr/lib/libsubstitute.dylib");
                        removeFileIfExistsE("/usr/lib/libsubstrate.dylib");
                        removeFileIfExistsE("/usr/lib/libjailbreak.dylib");
                        
                        removeFileIfExistsE("/usr/bin/recode-sr-latin");
                        removeFileIfExistsE("/usr/bin/recache");
                        removeFileIfExistsE("/usr/bin/rollectra");
                        removeFileIfExistsE("/usr/bin/Rollectra");
                        removeFileIfExistsE("/usr/bin/killall");
                        
                        removeFileIfExistsE("/usr/libexec/sftp-server");
                        removeFileIfExistsE("/usr/lib/SBInject.dylib");
                        removeFileIfExistsE("/bin/zsh");
                        removeFileIfExistsE("/electra-prejailbreak");
                        removeFileIfExistsE("/electra/createSnapshot");
                        removeFileIfExistsE("/jb");
                        removeFileIfExistsE("/jb");
                        removeFileIfExistsE("/var/backups");
                        ////////////Applications cleanup and root
                        removeFileIfExistsE("/RWTEST");
                        removeFileIfExistsE("/pwnedWritefileatrootTEST");
                        removeFileIfExistsE("/Applications/Cydia\ Update\ Helper.app");
                        removeFileIfExistsE("/Applications/AppCake.app");
                        removeFileIfExistsE("/Applications/Activator.app");
                        removeFileIfExistsE("/Applications/Anemone.app");
                        removeFileIfExistsE("/Applications/BestCallerId.app");
                        removeFileIfExistsE("/Applications/CrackTool3.app");
                        removeFileIfExistsE("/Applications/Cydia.app");
                        removeFileIfExistsE("/Applications/Sileo.app");
                        removeFileIfExistsE("/Applications/Rollectra.app");
                        removeFileIfExistsE("/Applications/cydown.app");
                        removeFileIfExistsE("/Applications/Cylinder.app");
                        removeFileIfExistsE("/Applications/iCleaner.app");
                        removeFileIfExistsE("/Applications/icleaner.app");
                        removeFileIfExistsE("/Applications/BarrelSettings.app");
                        removeFileIfExistsE("/Applications/Ext3nder.app");
                        removeFileIfExistsE("/Applications/Filza.app");
                        removeFileIfExistsE("/Applications/Flex.app");
                        removeFileIfExistsE("/Applications/GBA4iOS.app");
                        removeFileIfExistsE("/Applications/jjjj.app");
                        removeFileIfExistsE("/Applications/ReProvision.app");
                        removeFileIfExistsE("/Applications/SafeMode.app");
                        removeFileIfExistsE("/Applications/NewTerm.app");
                        removeFileIfExistsE("/Applications/MobileTerminal.app");
                        removeFileIfExistsE("/Applications/MTerminal.app");
                        removeFileIfExistsE("/Applications/MovieBox3.app");
                        removeFileIfExistsE("/Applications/BobbyMovie.app");
                        removeFileIfExistsE("/Applications/PopcornTime.app");
                        removeFileIfExistsE("/Applications/RST.app");
                        removeFileIfExistsE("/Applications/TSSSaver.app");
                        removeFileIfExistsE("/Applications/CertRemainTime.app");
                        removeFileIfExistsE("/Applications/CrashReporter.app");
                        removeFileIfExistsE("/Applications/AudioRecorder.app");
                        removeFileIfExistsE("/Applications/ADManager.app");
                        removeFileIfExistsE("/Applications/CocoaTop.app");
                        removeFileIfExistsE("/Applications/calleridfaker.app");
                        removeFileIfExistsE("/Applications/CallLogPro.app");
                        removeFileIfExistsE("/Applications/WiFiPasswords.app");
                        removeFileIfExistsE("/Applications/WifiPasswordList.app");
                        removeFileIfExistsE("/Applications/calleridfaker.app");
                        removeFileIfExistsE("/Applications/ClassDumpGUI.app");
                        removeFileIfExistsE("/Applications/idevicewallsapp.app");
                        removeFileIfExistsE("/Applications/UDIDFaker.app");
                        removeFileIfExistsE("/Applications/UDIDCalculator.app");
                        removeFileIfExistsE("/Applications/CallRecorder.app");
                        removeFileIfExistsE("/Applications/Rehosts.app");
                        removeFileIfExistsE("/Applications/NGXCarPlay.app");
                        removeFileIfExistsE("/Applications/Audicy.app");
                        removeFileIfExistsE("/Applications/NGXCarplay.app");
                        ///////////USR/LIBEXEC
                        removeFileIfExistsE("/usr/libexec/as");
                        removeFileIfExistsE("/usr/libexec/frcode");
                        removeFileIfExistsE("/usr/libexec/bigram");
                        removeFileIfExistsE("/usr/libexec/code");
                        removeFileIfExistsE("/usr/libexec/reload");
                        removeFileIfExistsE("/usr/libexec/rmt");
                        removeFileIfExistsE("/usr/libexec/MSUnrestrictProcess");
                        removeFileIfExistsE("/usr/lib/perl5");
                        //////////USR/SHARE
                        removeFileIfExistsE("/usr/share/git-core");
                        removeFileIfExistsE("/usr/share/git-gui");
                        removeFileIfExistsE("/usr/share/gitk");
                        removeFileIfExistsE("/usr/share/gitweb");
                        removeFileIfExistsE("/usr/share/man");
                        ////////USR/LOCAL
                        removeFileIfExistsE("/usr/local/bin");
                        removeFileIfExistsE("/usr/local/lib");
                        removeFileIfExistsE("/usr/local/lib/libluajit.a");
                        
                        ////var
                        removeFileIfExistsE("/var/containers/Bundle/iosbinpack64");
                        ////etc folder cleanup
                        removeFileIfExistsE("/private/etc/pam.d");
                        
                        //private/etc
                        removeFileIfExistsE("/private/etc/apt");
                        removeFileIfExistsE("/private/etc/dropbear");
                        removeFileIfExistsE("/private/etc/alternatives");
                        removeFileIfExistsE("/private/etc/default");
                        removeFileIfExistsE("/private/etc/dpkg");
                        removeFileIfExistsE("/private/etc/ssh");
                        removeFileIfExistsE("/private/etc/ssl");
                        removeFileIfExistsE("/private/etc/profile.d");
                        
                        ////private/var
                        
                        removeFileIfExistsE("/private/var/cache");
                        removeFileIfExistsE("/private/var/Ext3nder-Installer");
                        removeFileIfExistsE("/private/var/lib");
                        removeFileIfExistsE("/private/var/local");
                        removeFileIfExistsE("/private/var/lock");
                        removeFileIfExistsE("/private/var/spool");
                        removeFileIfExistsE("/private/var/lib/apt");
                        removeFileIfExistsE("/private/var/lib/dpkg");
                        removeFileIfExistsE("/private/var/lib/dpkg");
                        removeFileIfExistsE("/private/var/lib/cydia");
                        removeFileIfExistsE("/private/var/cache/apt");
                        removeFileIfExistsE("/private/var/db/stash");
                        removeFileIfExistsE("/private/var/stash");
                        removeFileIfExistsE("/private/var/tweak");
                        removeFileIfExistsE("/private/var/cercube_stashed");
                        removeFileIfExistsE("/private/var/tmp/cydia.log");
                        //var/mobile/Library
                        
                        removeFileIfExistsE("/private/var/mobile/Library/Flex3");
                        
                        removeFileIfExistsE("/private/var/mobile/Library/Notchification");
                        removeFileIfExistsE("/private/var/mobile/Library/unlimapps_tweaks_resources");
                        removeFileIfExistsE("/private/var/mobile/Library/Fingal");
                        removeFileIfExistsE("/private/var/mobile/Library/Filza");
                        removeFileIfExistsE("/private/var/mobile/Library/CT3");
                        removeFileIfExistsE("/private/var/mobile/Library/Cydia");
                        
                        removeFileIfExistsE("/private/var/mobile/Library/com.saurik.Cydia");
                        removeFileIfExistsE("/private/var/mobile/Library/com.saurik.Cydia/");
                        
                        removeFileIfExistsE("/private/var/mobile/Library/SBHTML");
                        removeFileIfExistsE("/private/var/mobile/Library/LockHTML");
                        removeFileIfExistsE("/private/var/mobile/Library/iWidgets");
                        
                        //var/mobile/Library/Caches
                        removeFileIfExistsE("/private/var/mobile/Library/Application\ Support/Flex3");
                        removeFileIfExistsE("/private/var/mobile/Library/Caches/libactivator.plist");
                        removeFileIfExistsE("/private/var/mobile/Library/Caches/com.saurik.Cydia");
                        removeFileIfExistsE("/private/var/mobile/Library/Caches/com.tigisoftware.Filza");
                        removeFileIfExistsE("/private/var/mobile/Library/Caches/com.johncoates.Flex");
                        removeFileIfExistsE("/private/var/mobile/Library/libactivator.plist");
                        removeFileIfExistsE("/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist");
                        removeFileIfExistsE("/private/var/mobile/Library/Application\ Support/Activator");
                        removeFileIfExistsE("/private/var/mobile/Library/Activator");
                        
                        //snapshot.library
                        removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.saurik.Cydia");
                        removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.tigisoft.Filza");
                        removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/com.johncoates.Flex");
                        removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/org.coolstar.SafeMode");
                        removeFileIfExistsE("/private/var/mobile/Library/Caches/Snapshots/ws.hbang.Terminal");
                        removeFileIfExistsE("/private/var/run/utmp");
                        removeFileIfExistsE("/private/var/run/pspawn_hook.ts");
                        unlink("/private/etc/apt/sources.list.d/cydia.list");
                        unlink("/private/etc/apt");
                        
                        ////usr/include files
                        removeFileIfExistsE("/usr/include");
                        ////usr/local files
                        removeFileIfExistsE("/usr/local/bin");
                        ////usr/libexec files
                        removeFileIfExistsE("/usr/libexec/apt");
                        removeFileIfExistsE("/usr/libexec/ssh-pkcs11-helper");
                        removeFileIfExistsE("/usr/libexec/ssh-keysign");
                        removeFileIfExistsE("/usr/libexec/cydia");
                        removeFileIfExistsE("/usr/libexec/dpkg");
                        removeFileIfExistsE("/usr/libexec/gnupg");
                        removeFileIfExistsE("/usr/libexec/gpg");
                        removeFileIfExistsE("/usr/libexec/gpg-check-pattern");
                        removeFileIfExistsE("/usr/libexec/gpg-preset-passphrase");
                        removeFileIfExistsE("/usr/libexec/gpg-protect-tool");
                        removeFileIfExistsE("/usr/libexec/gpg-wks-client");
                        removeFileIfExistsE("/usr/libexec/git-core");
                        removeFileIfExistsE("/usr/libexec/p11-kit");
                        removeFileIfExistsE("/usr/libexec/scdaemon");
                        removeFileIfExistsE("/usr/libexec/vndevice");
                        removeFileIfExistsE("/usr/libexec/frcode");
                        removeFileIfExistsE("/usr/libexec/bigram");
                        removeFileIfExistsE("/usr/libexec/code");
                        removeFileIfExistsE("/usr/libexec/coreutils");
                        removeFileIfExistsE("/usr/libexec/reload");
                        removeFileIfExistsE("/usr/libexec/rmt");
                        removeFileIfExistsE("/usr/libexec/filza");
                        removeFileIfExistsE("/usr/libexec/sudo");
                        ////usr/lib files
                        removeFileIfExistsE("/usr/lib/TweakInject");
                        removeFileIfExistsE("/usr/lib/tweakloader.dylib");
                        removeFileIfExistsE("/usr/lib/pspawn_hook.dylib");
                        unlink("/usr/lib/pspawn_hook.dylib");
                        removeFileIfExistsE("/usr/lib/tweaks");
                        removeFileIfExistsE("/usr/lib/Activator");
                        removeFileIfExistsE("/usr/lib/apt");
                        
                        unlink("/usr/lib/apt");
                        
                        removeFileIfExistsE("/usr/lib/dpkg");
                        removeFileIfExistsE("/usr/lib/pam");
                        removeFileIfExistsE("/usr/lib/p11-kit.0.dylib");
                        unlink("/usr/lib/p11-kit-proxy.dylib");
                        removeFileIfExistsE("/usr/lib/p11-kit-proxy.dylib");
                        removeFileIfExistsE("/usr/lib/pkcs11");
                        removeFileIfExistsE("/usr/lib/pam");
                        removeFileIfExistsE("/usr/lib/pkgconfig");
                        removeFileIfExistsE("/usr/lib/ssl");
                        removeFileIfExistsE("/usr/lib/bash");
                        removeFileIfExistsE("/usr/lib/gettext");
                        removeFileIfExistsE("/usr/lib/coreutils");
                        removeFileIfExistsE("/usr/lib/engines");
                        removeFileIfExistsE("/usr/lib/p7zip");
                        removeFileIfExistsE("/usr/lib/Cephei.framework");
                        removeFileIfExistsE("/usr/lib/CepheiPrefs.framework");
                        removeFileIfExistsE("/usr/lib/SBInject");
                        //usr/local
                        removeFileIfExistsE("/usr/local/bin");
                        removeFileIfExistsE("/usr/local/lib");
                        ////library folder files and subfolders
                        removeFileIfExistsE("/Library/Alkaline");
                        removeFileIfExistsE("/Library/Activator");
                        removeFileIfExistsE("/Library/Barrel");
                        removeFileIfExistsE("/Library/BarrelSettings");
                        removeFileIfExistsE("/Library/Cylinder");
                        removeFileIfExistsE("/Library/dpkg");
                        removeFileIfExistsE("/Library/Frameworks");
                        removeFileIfExistsE("/Library/LaunchDaemons");
                        removeFileIfExistsE("/Library/.DS_Store");
                        removeFileIfExistsE("/Library/MobileSubstrate");
                        removeFileIfExistsE("/Library/PreferenceBundles");
                        
                        removeFileIfExistsE("/Library/PreferenceLoader");
                        removeFileIfExistsE("/Library/SBInject");
                        removeFileIfExistsE("/Library/Application\ Support/Snoverlay");
                        removeFileIfExistsE("/Library/Application\ Support/Flame");
                        removeFileIfExistsE("/Library/Application\ Support/CallBlocker");
                        removeFileIfExistsE("/Library/Application\ Support/CCSupport");
                        removeFileIfExistsE("/Library/Application\ Support/Compatimark");
                        removeFileIfExistsE("/Library/Application\ Support/Dynastic");
                        removeFileIfExistsE("/Library/Application\ Support/Malipo");
                        removeFileIfExistsE("/Library/Application\ Support/SafariPlus.bundle");
                        
                        removeFileIfExistsE("/Library/Application\ Support/Activator");
                        removeFileIfExistsE("/Library/Application\ Support/Cylinder");
                        removeFileIfExistsE("/Library/Application\ Support/Barrel");
                        removeFileIfExistsE("/Library/Application\ Support/BarrelSettings");
                        removeFileIfExistsE("/Library/Application\ Support/libGitHubIssues/");
                        removeFileIfExistsE("/Library/Themes");
                        removeFileIfExistsE("/Library/TweakInject");
                        removeFileIfExistsE("/Library/Zeppelin");
                        removeFileIfExistsE("/Library/Flipswitch");
                        removeFileIfExistsE("/Library/Switches");
                        
                        //////system/library
                        removeFileIfExistsE("/System/Library/PreferenceBundles/AppList.bundle");
                        removeFileIfExistsE("/System/Library/Themes");
                        
                        removeFileIfExistsE("/System/Library/Internet\ Plug-Ins");
                        removeFileIfExistsE("/System/Library/KeyboardDictionaries");
                        
                        /////root
                        
                        removeFileIfExistsE("/FELICITYICON.png");
                        removeFileIfExistsE("/bootstrap");
                        removeFileIfExistsE("/mnt");
                        removeFileIfExistsE("/lib");
                        removeFileIfExistsE("/boot");
                        removeFileIfExistsE("/libexec");
                        removeFileIfExistsE("/include");
                        removeFileIfExistsE("/mnt");
                        removeFileIfExistsE("/jb");
                        removeFileIfExistsE("/usr/games");
                        //////////////USR/LIBRARY
                        removeFileIfExistsE("/usr/Library");
                        
                        ///////////PRIVATE
                        removeFileIfExistsE("/private/var/run/utmp");
                        ///
                        removeFileIfExistsE("/usr/bin/killall");
                        removeFileIfExistsE("/usr/sbin/reboot");
                        removeFileIfExistsE("/.bootstrapped_Th0r");
                        
                        
                        removeFileIfExistsE("/Library/test_inject_springboard.cy");
                        removeFileIfExistsE("/usr/lib/SBInject.dylib");
                        ////usr/local files and folders cleanup
                        removeFileIfExistsE("/usr/local/lib");
                        
                        removeFileIfExistsE("/usr/lib/libsparkapplist.dylib");
                        
                        removeFileIfExistsE("/usr/lib/libcrashreport.dylib");
                        removeFileIfExistsE("/usr/lib/libsymbolicate.dylib");
                        removeFileIfExistsE("/usr/lib/TweakInject.dylib");
                        //////ROOT FILES :(
                        removeFileIfExistsE("/.bootstrapped_electra");
                        removeFileIfExistsE("/.cydia_no_stash");
                        removeFileIfExistsE("/.bit_of_fun");
                        removeFileIfExistsE("/RWTEST");
                        removeFileIfExistsE("/pwnedWritefileatrootTEST");
                        removeFileIfExistsE("/private/etc/symlibs.dylib");
                        
                        
                        ////////// BIN/
                        removeFileIfExistsE("/bin/bashbug");
                        removeFileIfExistsE("/bin/bunzip2");
                        removeFileIfExistsE("/bin/bzcat");
                        unlink("usr/bin/bzcat");
                        removeFileIfExistsE("/bin/bzip2");
                        removeFileIfExistsE("/bin/bzip2recover");
                        removeFileIfExistsE("/bin/bzip2_64");
                        removeFileIfExistsE("/bin/cat");
                        removeFileIfExistsE("/bin/chgrp");
                        removeFileIfExistsE("/bin/chmod");
                        removeFileIfExistsE("/bin/chown");
                        removeFileIfExistsE("/bin/cp");
                        removeFileIfExistsE("/bin/date");
                        removeFileIfExistsE("/bin/dd");
                        removeFileIfExistsE("/bin/dir");
                        removeFileIfExistsE("/bin/echo");
                        removeFileIfExistsE("/bin/egrep");
                        removeFileIfExistsE("/bin/false");
                        removeFileIfExistsE("/bin/fgrep");
                        removeFileIfExistsE("/bin/grep");
                        removeFileIfExistsE("/bin/gzip");
                        removeFileIfExistsE("/bin/gtar");
                        removeFileIfExistsE("/bin/gunzip");
                        removeFileIfExistsE("/bin/gzexe");
                        removeFileIfExistsE("/bin/hostname");
                        removeFileIfExistsE("/bin/launchctl");
                        removeFileIfExistsE("/bin/ln");
                        removeFileIfExistsE("/bin/ls");
                        removeFileIfExistsE("/bin/jtoold");
                        removeFileIfExistsE("/bin/kill");
                        removeFileIfExistsE("/bin/mkdir");
                        removeFileIfExistsE("/bin/mknod");
                        removeFileIfExistsE("/bin/mv");
                        removeFileIfExistsE("/bin/mktemp");
                        removeFileIfExistsE("/bin/pwd");
                        
                        removeFileIfExistsE("/bin/rmdir");
                        removeFileIfExistsE("/bin/readlink");
                        removeFileIfExistsE("/bin/unlink");
                        removeFileIfExistsE("/bin/run-parts");
                        removeFileIfExistsE("/bin/su");
                        removeFileIfExistsE("/bin/sync");
                        removeFileIfExistsE("/bin/stty");
                        removeFileIfExistsE("/bin/sh");
                        unlink("/bin/sh");
                        
                        removeFileIfExistsE("/bin/sleep");
                        removeFileIfExistsE("/bin/sed");
                        removeFileIfExistsE("/bin/su");
                        removeFileIfExistsE("/bin/tar");
                        removeFileIfExistsE("/bin/touch");
                        removeFileIfExistsE("/bin/true");
                        removeFileIfExistsE("/bin/uname");
                        removeFileIfExistsE("/bin/vdr");
                        removeFileIfExistsE("/bin/vdir");
                        removeFileIfExistsE("/bin/uncompress");
                        removeFileIfExistsE("/bin/znew");
                        removeFileIfExistsE("/bin/zegrep");
                        removeFileIfExistsE("/bin/zmore");
                        removeFileIfExistsE("/bin/zdiff");
                        removeFileIfExistsE("/bin/zcat");
                        removeFileIfExistsE("/bin/zcmp");
                        removeFileIfExistsE("/bin/zfgrep");
                        removeFileIfExistsE("/bin/zforce");
                        removeFileIfExistsE("/bin/zless");
                        removeFileIfExistsE("/bin/zgrep");
                        removeFileIfExistsE("/bin/zegrep");
                        
                        //////////SBIN
                        removeFileIfExistsE("/sbin/reboot");
                        removeFileIfExistsE("/sbin/halt");
                        removeFileIfExistsE("/sbin/ifconfig");
                        removeFileIfExistsE("/sbin/kextunload");
                        removeFileIfExistsE("/sbin/ping");
                        removeFileIfExistsE("/sbin/update_dyld_shared_cache");
                        removeFileIfExistsE("/sbin/dmesg");
                        removeFileIfExistsE("/sbin/dynamic_pager");
                        removeFileIfExistsE("/sbin/nologin");
                        removeFileIfExistsE("/sbin/fstyp");
                        removeFileIfExistsE("/sbin/fstyp_msdos");
                        removeFileIfExistsE("/sbin/fstyp_ntfs");
                        removeFileIfExistsE("/sbin/fstyp_udf");
                        removeFileIfExistsE("/sbin/mount_devfs");
                        removeFileIfExistsE("/sbin/mount_fdesc");
                        removeFileIfExistsE("/sbin/quotacheck");
                        removeFileIfExistsE("/sbin/umount");
                        
                        
                        /////usr/bin files folders cleanup
                        //symbols
                        removeFileIfExistsE("/usr/bin/[");
                        //a
                        removeFileIfExistsE("/usr/bin/ADMHelper");
                        removeFileIfExistsE("/usr/bin/arch");
                        removeFileIfExistsE("/usr/bin/apt");
                        
                        removeFileIfExistsE("/usr/bin/ar");
                        
                        removeFileIfExistsE("/usr/bin/apt-key");
                        removeFileIfExistsE("/usr/bin/apt-cache");
                        removeFileIfExistsE("/usr/bin/apt-cdrom");
                        removeFileIfExistsE("/usr/bin/apt-config");
                        removeFileIfExistsE("/usr/bin/apt-extracttemplates");
                        removeFileIfExistsE("/usr/bin/apt-ftparchive");
                        removeFileIfExistsE("/usr/bin/apt-sortpkgs");
                        removeFileIfExistsE("/usr/bin/apt-mark");
                        removeFileIfExistsE("/usr/bin/apt-get");
                        removeFileIfExistsE("/usr/bin/arch");
                        removeFileIfExistsE("/usr/bin/asu_inject");
                        
                        
                        removeFileIfExistsE("/usr/bin/asn1Coding");
                        removeFileIfExistsE("/usr/bin/asn1Decoding");
                        removeFileIfExistsE("/usr/bin/asn1Parser");
                        removeFileIfExistsE("/usr/bin/autopoint");
                        
                        removeFileIfExistsE("/usr/bin/as");
                        //b
                        removeFileIfExistsE("/usr/bin/bashbug");
                        removeFileIfExistsE("/usr/bin/b2sum");
                        removeFileIfExistsE("/usr/bin/base32");
                        removeFileIfExistsE("/usr/bin/base64");
                        removeFileIfExistsE("/usr/bin/basename");
                        removeFileIfExistsE("/usr/bin/bitcode_strip");
                        //c
                        removeFileIfExistsE("/usr/bin/CallLogPro");
                        removeFileIfExistsE("/usr/bin/com.julioverne.ext3nder-installer");
                        removeFileIfExistsE("/usr/bin/chown");
                        removeFileIfExistsE("/usr/bin/chmod");
                        removeFileIfExistsE("/usr/bin/chroot");
                        removeFileIfExistsE("/usr/bin/chcon");
                        removeFileIfExistsE("/usr/bin/chpass");
                        removeFileIfExistsE("/usr/bin/check_dylib");
                        removeFileIfExistsE("/usr/bin/checksyms");
                        removeFileIfExistsE("/usr/bin/chfn");
                        removeFileIfExistsE("/usr/bin/chsh");
                        removeFileIfExistsE("/usr/bin/cksum");
                        removeFileIfExistsE("/usr/bin/comm");
                        removeFileIfExistsE("/usr/bin/cmpdylib");
                        removeFileIfExistsE("/usr/bin/codesign_allocate");
                        removeFileIfExistsE("/usr/bin/csplit");
                        removeFileIfExistsE("/usr/bin/ctf_insert");
                        removeFileIfExistsE("/usr/bin/cut");
                        removeFileIfExistsE("/usr/bin/curl");
                        removeFileIfExistsE("/usr/bin/curl-config");
                        removeFileIfExistsE("/usr/bin/c_rehash");
                        removeFileIfExistsE("/usr/bin/captoinfo");
                        removeFileIfExistsE("/usr/bin/certtool");
                        removeFileIfExistsE("/usr/bin/cfversion");
                        removeFileIfExistsE("/usr/bin/clear");
                        removeFileIfExistsE("/usr/bin/cmp");
                        removeFileIfExistsE("/usr/bin/cydown");
                        removeFileIfExistsE("/usr/bin/cydown.arch_arm64");
                        removeFileIfExistsE("/usr/bin/cydown.arch_armv7");
                        
                        removeFileIfExistsE("/usr/bin/cycript");
                        removeFileIfExistsE("/usr/bin/cycc");
                        removeFileIfExistsE("/usr/bin/cynject");
                        //d
                        removeFileIfExistsE("/usr/bin/dbclient");
                        removeFileIfExistsE("/usr/bin/db_archive");
                        removeFileIfExistsE("/usr/bin/db_checkpoint");
                        removeFileIfExistsE("/usr/bin/db_deadlock");
                        removeFileIfExistsE("/usr/bin/db_dump");
                        removeFileIfExistsE("/usr/bin/db_hotbackup");
                        removeFileIfExistsE("/usr/bin/db_load");
                        removeFileIfExistsE("/usr/bin/db_log_verify");
                        removeFileIfExistsE("/usr/bin/db_printlog");
                        removeFileIfExistsE("/usr/bin/db_recover");
                        removeFileIfExistsE("/usr/bin/db_replicate");
                        removeFileIfExistsE("/usr/bin/db_sql_codegen");
                        removeFileIfExistsE("/usr/bin/db_stat");
                        removeFileIfExistsE("/usr/bin/db_tuner");
                        removeFileIfExistsE("/usr/bin/db_upgrade");
                        removeFileIfExistsE("/usr/bin/db_verify");
                        removeFileIfExistsE("/usr/bin/dbsql");
                        removeFileIfExistsE("/usr/bin/debugserver");
                        removeFileIfExistsE("/usr/bin/defaults");
                        removeFileIfExistsE("/usr/bin/df");
                        removeFileIfExistsE("/usr/bin/diff");
                        removeFileIfExistsE("/usr/bin/diff3");
                        removeFileIfExistsE("/usr/bin/dirname");
                        removeFileIfExistsE("/usr/bin/dircolors");
                        removeFileIfExistsE("/usr/bin/dirmngr");
                        removeFileIfExistsE("/usr/bin/dirmngr-client");
                        removeFileIfExistsE("/usr/bin/dpkg");
                        removeFileIfExistsE("/usr/bin/dpkg-architecture");
                        removeFileIfExistsE("/usr/bin/dpkg-buildflags");
                        removeFileIfExistsE("/usr/bin/dpkg-buildpackage");
                        removeFileIfExistsE("/usr/bin/dpkg-checkbuilddeps");
                        removeFileIfExistsE("/usr/bin/dpkg-deb");
                        removeFileIfExistsE("/usr/bin/dpkg-distaddfile");
                        removeFileIfExistsE("/usr/bin/dpkg-divert");
                        removeFileIfExistsE("/usr/bin/dpkg-genbuildinfo");
                        removeFileIfExistsE("/usr/bin/dpkg-genchanges");
                        removeFileIfExistsE("/usr/bin/dpkg-gencontrol");
                        removeFileIfExistsE("/usr/bin/dpkg-gensymbols");
                        removeFileIfExistsE("/usr/bin/dpkg-maintscript-helper");
                        removeFileIfExistsE("/usr/bin/dpkg-mergechangelogs");
                        removeFileIfExistsE("/usr/bin/dpkg-name");
                        removeFileIfExistsE("/usr/bin/dpkg-parsechangelog");
                        removeFileIfExistsE("/usr/bin/dpkg-query");
                        removeFileIfExistsE("/usr/bin/dpkg-scanpackages");
                        removeFileIfExistsE("/usr/bin/dpkg-scansources");
                        removeFileIfExistsE("/usr/bin/dpkg-shlibdeps");
                        removeFileIfExistsE("/usr/bin/dpkg-source");
                        removeFileIfExistsE("/usr/bin/dpkg-split");
                        removeFileIfExistsE("/usr/bin/dpkg-statoverride");
                        removeFileIfExistsE("/usr/bin/dpkg-trigger");
                        removeFileIfExistsE("/usr/bin/dpkg-vendor");
                        removeFileIfExistsE("/usr/bin/du");
                        removeFileIfExistsE("/usr/bin/dumpsexp");
                        removeFileIfExistsE("/usr/bin/dselect");
                        removeFileIfExistsE("/usr/bin/dsymutil");
                        ////e
                        removeFileIfExistsE("/usr/bin/expand");
                        removeFileIfExistsE("/usr/bin/expr");
                        removeFileIfExistsE("/usr/bin/env");
                        removeFileIfExistsE("/usr/bin/envsubst");
                        removeFileIfExistsE("/usr/bin/ecidecid");
                        //f
                        removeFileIfExistsE("/usr/bin/factor");
                        removeFileIfExistsE("/usr/bin/filemon");
                        removeFileIfExistsE("/usr/bin/Filza");
                        removeFileIfExistsE("/usr/bin/fmt");
                        removeFileIfExistsE("/usr/bin/fold");
                        removeFileIfExistsE("/usr/bin/funzip");
                        //g
                        removeFileIfExistsE("/usr/bin/games");
                        removeFileIfExistsE("/usr/bin/getconf");
                        removeFileIfExistsE("/usr/bin/getty");
                        removeFileIfExistsE("/usr/bin/gettext");
                        removeFileIfExistsE("/usr/bin/gettext.sh");
                        removeFileIfExistsE("/usr/bin/gettextize");
                        removeFileIfExistsE("/usr/bin/git");
                        removeFileIfExistsE("/usr/bin/git-cvsserver");
                        removeFileIfExistsE("/usr/bin/git-recieve-pack");
                        removeFileIfExistsE("/usr/bin/git-shell");
                        removeFileIfExistsE("/usr/bin/git-upload-pack");
                        removeFileIfExistsE("/usr/bin/gitk");
                        removeFileIfExistsE("/usr/bin/gnutar");
                        removeFileIfExistsE("/usr/bin/gnutls-cli");
                        removeFileIfExistsE("/usr/bin/gnutls-cli-debug");
                        removeFileIfExistsE("/usr/bin/gnutls-serv");
                        removeFileIfExistsE("/usr/bin/gpg");
                        removeFileIfExistsE("/usr/bin/gpgrt-config");
                        removeFileIfExistsE("/usr/bin/gpg-zip");
                        removeFileIfExistsE("/usr/bin/gpgsplit");
                        removeFileIfExistsE("/usr/bin/gpgv");
                        removeFileIfExistsE("/usr/bin/gssc");
                        removeFileIfExistsE("/usr/bin/groups");
                        removeFileIfExistsE("/usr/bin/gpg-agent");
                        removeFileIfExistsE("/usr/bin/gpg-connect-agent ");
                        removeFileIfExistsE("/usr/bin/gpg-error");
                        removeFileIfExistsE("/usr/bin/gpg-error-config");
                        removeFileIfExistsE("/usr/bin/gpg2");
                        removeFileIfExistsE("/usr/bin/gpgconf");
                        removeFileIfExistsE("/usr/bin/gpgparsemail");
                        removeFileIfExistsE("/usr/bin/gpgscm");
                        removeFileIfExistsE("/usr/bin/gpgsm");
                        removeFileIfExistsE("/usr/bin/gpgtar");
                        removeFileIfExistsE("/usr/bin/gpgv2");
                        removeFileIfExistsE("/usr/bin/groups");
                        removeFileIfExistsE("/usr/bin/gtar");
                        //h
                        removeFileIfExistsE("/usr/bin/head");
                        removeFileIfExistsE("/usr/bin/hmac256");
                        removeFileIfExistsE("/usr/bin/hostid");
                        removeFileIfExistsE("/usr/bin/hostinfo");
                        //i
                        removeFileIfExistsE("/usr/bin/install");
                        removeFileIfExistsE("/usr/bin/id");
                        removeFileIfExistsE("/usr/bin/idn2");
                        removeFileIfExistsE("/usr/bin/indr");
                        removeFileIfExistsE("/usr/bin/inout");
                        removeFileIfExistsE("/usr/bin/infocmp");
                        removeFileIfExistsE("/usr/bin/infotocap");
                        removeFileIfExistsE("/usr/bin/iomfsetgamma");
                        removeFileIfExistsE("/usr/bin/install_name_tool");
                        removeFileIfExistsE("/usr/bin/libtool");
                        removeFileIfExistsE("/usr/bin/lipo");
                        //j
                        removeFileIfExistsE("/usr/bin/join");
                        removeFileIfExistsE("/usr/bin/jtool");
                        //k
                        removeFileIfExistsE("/usr/bin/killall");
                        removeFileIfExistsE("/usr/bin/kbxutil");
                        removeFileIfExistsE("/usr/bin/ksba-config");
                        //l
                        removeFileIfExistsE("/usr/bin/less");
                        removeFileIfExistsE("/usr/bin/libassuan-config");
                        removeFileIfExistsE("/usr/bin/libgcrypt-config");
                        removeFileIfExistsE("/usr/bin/link");
                        removeFileIfExistsE("/usr/bin/ldid");
                        removeFileIfExistsE("/usr/bin/ldid2");
                        removeFileIfExistsE("/usr/bin/ldrestart");
                        removeFileIfExistsE("/usr/bin/locate");
                        removeFileIfExistsE("/usr/bin/login");
                        removeFileIfExistsE("/usr/bin/logname");
                        removeFileIfExistsE("/usr/bin/lzcat");
                        removeFileIfExistsE("/usr/bin/lz4");
                        removeFileIfExistsE("/usr/bin/lz4c");
                        removeFileIfExistsE("/usr/bin/lz4cat");
                        removeFileIfExistsE("/usr/bin/lzcmp");
                        removeFileIfExistsE("/usr/bin/lzdiff");
                        removeFileIfExistsE("/usr/bin/lzegrep");
                        removeFileIfExistsE("/usr/bin/lzfgrep");
                        removeFileIfExistsE("/usr/bin/lzgrep");
                        removeFileIfExistsE("/usr/bin/lzless");
                        removeFileIfExistsE("/usr/bin/lzma");
                        removeFileIfExistsE("/usr/bin/lzmadec");
                        removeFileIfExistsE("/usr/bin/lzmainfo");
                        removeFileIfExistsE("/usr/bin/lzmore");
                        removeFileIfExistsE("/usr/bin.lipo");
                        removeFileIfExistsE("/usr/bin/lipo");
                        
                        //m
                        removeFileIfExistsE("/usr/bin/md5sum");
                        removeFileIfExistsE("/usr/bin/mkfifo");
                        removeFileIfExistsE("/usr/bin/mktemp");
                        removeFileIfExistsE("/usr/bin/more");
                        removeFileIfExistsE("/usr/bin/msgattrib");
                        removeFileIfExistsE("/usr/bin/msgcat");
                        removeFileIfExistsE("/usr/bin/msgcmp");
                        removeFileIfExistsE("/usr/bin/msgcomm");
                        removeFileIfExistsE("/usr/bin/msgconv");
                        removeFileIfExistsE("/usr/bin/msgen");
                        removeFileIfExistsE("/usr/bin/msgexec");
                        removeFileIfExistsE("/usr/bin/msgfilter");
                        removeFileIfExistsE("/usr/bin/msgfmt");
                        removeFileIfExistsE("/usr/bin/msggrep");
                        removeFileIfExistsE("/usr/bin/msginit");
                        removeFileIfExistsE("/usr/bin/msgmerge");
                        removeFileIfExistsE("/usr/bin/msgunfmt");
                        removeFileIfExistsE("/usr/bin/msguniq");
                        removeFileIfExistsE("/usr/bin/mpicalc");
                        //n
                        removeFileIfExistsE("/usr/bin/nano");
                        removeFileIfExistsE("/usr/bin/nettle-hash");
                        removeFileIfExistsE("/usr/bin/nettle-lfib-stream");
                        removeFileIfExistsE("/usr/bin/nettle-pbkdf2");
                        removeFileIfExistsE("/usr/bin/ngettext");
                        
                        
                        
                        removeFileIfExistsE("/usr/bin/nm");
                        removeFileIfExistsE("/usr/bin/nmedit");
                        removeFileIfExistsE("/usr/bin/nice");
                        removeFileIfExistsE("/usr/bin/nl");
                        removeFileIfExistsE("/usr/bin/nohup");
                        removeFileIfExistsE("/usr/bin/nproc");
                        removeFileIfExistsE("/usr/bin/npth-config");
                        removeFileIfExistsE("/usr/bin/numfmt");
                        removeFileIfExistsE("/usr/bin/ncurses6-config");
                        removeFileIfExistsE("/usr/bin/ncursesw6-config");
                        removeFileIfExistsE("/usr/bin/ncursesw5-config");
                        removeFileIfExistsE("/usr/bin/ncurses5-config");
                        //o
                        
                        removeFileIfExistsE("/usr/bin/od");
                        removeFileIfExistsE("/usr/bin/ocsptool");
                        removeFileIfExistsE("/usr/bin/ObjectDump");
                        removeFileIfExistsE("/usr/bin/dyldinfo");
                        removeFileIfExistsE("/usr/bin/ld");
                        removeFileIfExistsE("/usr/bin/machocheck");
                        removeFileIfExistsE("/usr/bin/unwinddump");//ld64 done
                        removeFileIfExistsE("/usr/bin/otool");
                        
                        removeFileIfExistsE("/usr/bin/openssl");
                        //p
                        removeFileIfExistsE("/usr/bin/pincrush");
                        removeFileIfExistsE("/usr/bin/pagestuff");
                        
                        removeFileIfExistsE("/usr/bin/pagesize");
                        removeFileIfExistsE("/usr/bin/passwd");
                        removeFileIfExistsE("/usr/bin/paste");
                        removeFileIfExistsE("/usr/bin/pathchk");
                        removeFileIfExistsE("/usr/bin/pinky");
                        removeFileIfExistsE("/usr/bin/plconvert");
                        removeFileIfExistsE("/usr/bin/pr");
                        removeFileIfExistsE("/usr/bin/printenv");
                        removeFileIfExistsE("/usr/bin/printf");
                        removeFileIfExistsE("/usr/bin/procexp");
                        removeFileIfExistsE("/usr/bin/ptx");
                        removeFileIfExistsE("/usr/bin/p11-kit");
                        removeFileIfExistsE("/usr/bin/p11tool");
                        
                        removeFileIfExistsE("/usr/bin/pkcs1-conv");
                        
                        removeFileIfExistsE("/usr/bin/psktool");
                        
                        removeFileIfExistsE("/usr/bin/quota");
                        
                        
                        //r
                        removeFileIfExistsE("/usr/bin/renice");
                        removeFileIfExistsE("/usr/bin/ranlib");
                        removeFileIfExistsE("/usr/bin/redo_prebinding");
                        removeFileIfExistsE("/usr/bin/reprovisiond");
                        
                        removeFileIfExistsE("/usr/bin/reset");
                        removeFileIfExistsE("/usr/bin/realpath");
                        removeFileIfExistsE("/usr/bin/rnano");
                        removeFileIfExistsE("/usr/bin/runcon");
                        //s
                        
                        removeFileIfExistsE("/usr/bin/snapUtil");
                        removeFileIfExistsE("/usr/bin/sbdidlaunch");
                        removeFileIfExistsE("/usr/bin/sbreload");
                        removeFileIfExistsE("/usr/bin/script");
                        removeFileIfExistsE("/usr/bin/sdiff");
                        removeFileIfExistsE("/usr/bin/seq");
                        removeFileIfExistsE("/usr/bin/sexp-conv");
                        removeFileIfExistsE("/usr/bin/seg_addr_table");
                        removeFileIfExistsE("/usr/bin/seg_hack");
                        removeFileIfExistsE("/usr/bin/segedit");
                        removeFileIfExistsE("/usr/bin/sftp");
                        removeFileIfExistsE("/usr/bin/shred");
                        removeFileIfExistsE("/usr/bin/shuf");
                        removeFileIfExistsE("/usr/bin/sort");
                        removeFileIfExistsE("/usr/bin/ssh");
                        removeFileIfExistsE("/usr/bin/ssh-add");
                        removeFileIfExistsE("/usr/bin/ssh-agent");
                        removeFileIfExistsE("/usr/bin/ssh-keygen");
                        removeFileIfExistsE("/usr/bin/ssh-keyscan");
                        removeFileIfExistsE("/usr/bin/sw_vers");
                        removeFileIfExistsE("/usr/bin/seq");
                        removeFileIfExistsE("/usr/bin/SemiRestore11-Lite");
                        
                        removeFileIfExistsE("/usr/bin/sha1sum");
                        removeFileIfExistsE("/usr/bin/sha224sum");
                        removeFileIfExistsE("/usr/bin/sha256sum");
                        removeFileIfExistsE("/usr/bin/sha384sum");
                        removeFileIfExistsE("/usr/bin/sha512sum");
                        removeFileIfExistsE("/usr/bin/shred");
                        removeFileIfExistsE("/usr/bin/shuf");
                        removeFileIfExistsE("/usr/bin/size");
                        removeFileIfExistsE("/usr/bin/split");
                        removeFileIfExistsE("/usr/bin/srptool");
                        removeFileIfExistsE("/usr/bin/stat");
                        removeFileIfExistsE("/usr/bin/stdbuf");
                        removeFileIfExistsE("/usr/bin/strings");
                        removeFileIfExistsE("/usr/bin/strip");
                        removeFileIfExistsE("/usr/bin/sum");
                        removeFileIfExistsE("/usr/bin/sync");
                        //t
                        removeFileIfExistsE("/usr/bin/tabs");
                        removeFileIfExistsE("/usr/bin/tac");
                        removeFileIfExistsE("/usr/bin/tar");
                        removeFileIfExistsE("/usr/bin/tail");
                        removeFileIfExistsE("/usr/bin/tee");
                        removeFileIfExistsE("/usr/bin/test");
                        removeFileIfExistsE("/usr/bin/tic");
                        removeFileIfExistsE("/usr/bin/time");
                        removeFileIfExistsE("/usr/bin/timeout");
                        removeFileIfExistsE("/usr/bin/toe");
                        removeFileIfExistsE("/usr/bin/tput");
                        removeFileIfExistsE("/usr/bin/tr");
                        removeFileIfExistsE("/usr/bin/tset");
                        removeFileIfExistsE("/usr/bin/truncate");
                        removeFileIfExistsE("/usr/bin/trust");
                        removeFileIfExistsE("/usr/bin/tsort");
                        removeFileIfExistsE("/usr/bin/tty");
                        //u
                        removeFileIfExistsE("/usr/bin/uiduid");
                        removeFileIfExistsE("/usr/bin/uuid");
                        removeFileIfExistsE("/usr/bin/uuid-config");
                        removeFileIfExistsE("/usr/bin/uiopen");
                        removeFileIfExistsE("/usr/bin/unlz4");
                        removeFileIfExistsE("/usr/bin/unlzma");
                        removeFileIfExistsE("/usr/bin/unxz");
                        removeFileIfExistsE("/usr/bin/update-alternatives");
                        removeFileIfExistsE("/usr/bin/updatedb");
                        removeFileIfExistsE("/usr/bin/unexpand");
                        removeFileIfExistsE("/usr/bin/uniq");
                        removeFileIfExistsE("/usr/bin/unzip");
                        removeFileIfExistsE("/usr/bin/unzipsfx");
                        removeFileIfExistsE("/usr/bin/unrar");
                        removeFileIfExistsE("/usr/bin/uptime");
                        removeFileIfExistsE("/usr/bin/users");
                        //w
                        removeFileIfExistsE("/usr/bin/watchgnupg");
                        removeFileIfExistsE("/usr/bin/wc");
                        removeFileIfExistsE("/usr/bin/wget");
                        removeFileIfExistsE("/usr/bin/which");
                        removeFileIfExistsE("/usr/bin/who");
                        removeFileIfExistsE("/usr/bin/whoami");
                        //x
                        removeFileIfExistsE("/usr/bin/xargs");
                        removeFileIfExistsE("/usr/bin/xz");
                        removeFileIfExistsE("/usr/bin/xgettext");
                        removeFileIfExistsE("/usr/bin/xzcat");
                        removeFileIfExistsE("/usr/bin/xzcmp");
                        removeFileIfExistsE("/usr/bin/xzdec");
                        removeFileIfExistsE("/usr/bin/xzdiff");
                        removeFileIfExistsE("/usr/bin/xzegrep");
                        removeFileIfExistsE("/usr/bin/xzfgrep");
                        removeFileIfExistsE("/usr/bin/xzgrep");
                        removeFileIfExistsE("/usr/bin/xzless");
                        removeFileIfExistsE("/usr/bin/xzmore");
                        //y
                        removeFileIfExistsE("/usr/bin/yat2m");
                        removeFileIfExistsE("/usr/bin/yes");
                        //z
                        removeFileIfExistsE("/usr/bin/zip");
                        removeFileIfExistsE("/usr/bin/zipcloak");
                        removeFileIfExistsE("/usr/bin/zipnote");
                        removeFileIfExistsE("/usr/bin/zipsplit");
                        //numbers
                        removeFileIfExistsE("/usr/bin/7z");
                        removeFileIfExistsE("/usr/bin/7za");
                        //////////////
                        ////
                        //////////USR/SBIN
                        removeFileIfExistsE("/usr/sbin/chown");
                        
                        unlink("/usr/sbin/chown");
                        
                        removeFileIfExistsE("/usr/sbin/chmod");
                        removeFileIfExistsE("/usr/sbin/chroot");
                        removeFileIfExistsE("/usr/sbin/dev_mkdb");
                        removeFileIfExistsE("/usr/sbin/edquota");
                        removeFileIfExistsE("/usr/sbin/applygnupgdefaults");
                        removeFileIfExistsE("/usr/sbin/fdisk");
                        removeFileIfExistsE("/usr/sbin/halt");
                        removeFileIfExistsE("/usr/sbin/sshd");
                        
                        //////////////USR/LIB
                        
                        removeFileIfExistsE("/usr/lib/libhistory.5.dylib");
                        removeFileIfExistsE("/usr/lib/xxxMobileGestalt.dylib");//for cydown
                        
                        removeFileIfExistsE("/usr/lib/xxxSystem.dylib");//for cydown
                        
                        removeFileIfExistsE("/usr/lib/libcolorpicker.dylib");//
                        removeFileIfExistsE("/usr/lib/libcrypto.dylib");//
                        removeFileIfExistsE("/usr/lib/libcrypto.a");//
                        removeFileIfExistsE("/usr/lib/libdb_sql-6.2.dylib");//
                        removeFileIfExistsE("/usr/lib/libdb_sql-6.dylib");//
                        removeFileIfExistsE("/usr/lib/libdb_sql.dylib");//
                        removeFileIfExistsE("/usr/lib/libdb-6.2.dylib");//
                        removeFileIfExistsE("/usr/lib/libdb-6.dylib");//
                        removeFileIfExistsE("/usr/lib/libdb.dylib");//
                        removeFileIfExistsE("/usr/lib/liblzma.a");//
                        removeFileIfExistsE("/usr/lib/liblzma.la");//
                        removeFileIfExistsE("/usr/lib/libprefs.dylib");//
                        removeFileIfExistsE("/usr/lib/libssl.a");//
                        removeFileIfExistsE("/usr/lib/libssl.dylib");//
                        removeFileIfExistsE("/usr/lib/libST.dylib");//
                        //////////////////
                        //////////////8
                        removeFileIfExistsE("/usr/lib/libapt-pkg.dylib.4.6");
                        removeFileIfExistsE("/usr/lib/libapt-pkg.4.6.dylib");
                        removeFileIfExistsE("/usr/lib/libpam.dylib");
                        removeFileIfExistsE("/usr/lib/libpamc.1.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-pkg.dylib.4.6.0");
                        removeFileIfExistsE("/usr/lib/libapt-pkg.4.6.0.dylib");
                        removeFileIfExistsE("/usr/lib/libpanelw.5.dylib");
                        removeFileIfExistsE("/usr/lib/libhistory.5.2.dylib");
                        removeFileIfExistsE("/usr/lib/libreadline.6.dylib");
                        removeFileIfExistsE("/usr/lib/libpanel.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-inst.dylib.1.1");
                        removeFileIfExistsE("/usr/lib/libapt-inst.1.1.dylib");
                        removeFileIfExistsE("/usr/lib/libcurses.dylib");
                        removeFileIfExistsE("/usr/lib/liblzmadec.0.dylib");
                        removeFileIfExistsE("/usr/lib/libhistory.6.dylib");
                        removeFileIfExistsE("/usr/lib/libformw.dylib");
                        removeFileIfExistsE("/usr/lib/libncursesw.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-inst.dylib");
                        removeFileIfExistsE("/usr/lib/libncurses.5.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-pkg.dylib");
                        removeFileIfExistsE("/usr/lib/libreadline.5.dylib");
                        removeFileIfExistsE("/usr/lib/libhistory.6.0.dylib");
                        removeFileIfExistsE("/usr/lib/libform.5.dylib");
                        removeFileIfExistsE("/usr/lib/libpanelw.dylib");
                        removeFileIfExistsE("/usr/lib/libmenuw.dylib");
                        removeFileIfExistsE("/usr/lib/libform.dylib");
                        removeFileIfExistsE("/usr/lib/terminfo");
                        removeFileIfExistsE("/usr/lib/libpam.1.0.dylib");
                        removeFileIfExistsE("/usr/lib/libmenu.5.dylib");
                        removeFileIfExistsE("/usr/lib/libpatcyh.dylib");
                        removeFileIfExistsE("/usr/lib/libreadline.6.0.dylib");
                        removeFileIfExistsE("/usr/lib/liblzmadec.dylib");
                        removeFileIfExistsE("/usr/lib/libncurses.dylib");
                        removeFileIfExistsE("/usr/lib/libhistory.dylib");
                        removeFileIfExistsE("/usr/lib/libpamc.dylib");
                        removeFileIfExistsE("/usr/lib/libformw.5.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-inst.dylib.1.1.0");
                        removeFileIfExistsE("/usr/lib/libapt-inst.1.1.0.dylib");
                        removeFileIfExistsE("/usr/lib/libpanel.5.dylib");
                        removeFileIfExistsE("/usr/lib/liblzmadec.0.0.0.dylib");
                        removeFileIfExistsE("/usr/lib/_ncurses");
                        removeFileIfExistsE("/usr/lib/libpam_misc.1.dylib");
                        removeFileIfExistsE("/usr/lib/libreadline.5.2.dylib");
                        removeFileIfExistsE("/usr/lib/libpam_misc.dylib");
                        removeFileIfExistsE("/usr/lib/libreadline.dylib");
                        removeFileIfExistsE("/usr/lib/libmenuw.5.dylib");
                        removeFileIfExistsE("/usr/lib/libpam.1.dylib");
                        removeFileIfExistsE("/usr/lib/libmenu.dylib");
                        removeFileIfExistsE("/usr/lib/liblzmadec.la");
                        removeFileIfExistsE("/usr/lib/libncursesw.5.dylib");
                        removeFileIfExistsE("/usr/lib/libcycript.dylib");
                        removeFileIfExistsE("/usr/lib/libcycript.jar");
                        removeFileIfExistsE("/usr/lib/libdpkg.a");
                        removeFileIfExistsE("/usr/lib/libcrypto.1.0.0.dylib");
                        removeFileIfExistsE("/usr/lib/libssl.1.0.0.dylib");
                        removeFileIfExistsE("/usr/lib/libcycript.db");
                        removeFileIfExistsE("/usr/lib/libcurl.4.dylib");
                        removeFileIfExistsE("/usr/lib/libcycript.0.dylib");
                        removeFileIfExistsE("/usr/lib/libcycript.cy");
                        removeFileIfExistsE("/usr/lib/libdpkg.la");
                        removeFileIfExistsE("/usr/lib/libswift");
                        removeFileIfExistsE("/usr/lib/libsubstrate.0.dylib");
                        removeFileIfExistsE("/usr/lib/libuuid.16.dylib");
                        removeFileIfExistsE("/usr/lib/libuuid.dylib");
                        removeFileIfExistsE("/usr/lib/libtapi.dylib");
                        removeFileIfExistsE("/usr/lib/libnghttp2.14.dylib");//ld64
                        removeFileIfExistsE("/usr/lib/libnghttp2.dylib");//ld64
                        removeFileIfExistsE("/usr/lib/libnghttp2.la");//ld64
                        ///sauirks new substrate
                        removeFileIfExistsE("/usr/lib/substrate");//ld64
                        
                        //////////USR/SBIN
                        removeFileIfExistsE("/usr/sbin/accton");
                        removeFileIfExistsE("/usr/sbin/vifs");
                        removeFileIfExistsE("/usr/sbin/ac");
                        removeFileIfExistsE("/usr/sbin/update");
                        removeFileIfExistsE("/usr/sbin/pwd_mkdb");
                        removeFileIfExistsE("/usr/sbin/sysctl");
                        removeFileIfExistsE("/usr/sbin/zdump");
                        removeFileIfExistsE("/usr/sbin/startupfiletool");
                        removeFileIfExistsE("/usr/sbin/iostat");
                        removeFileIfExistsE("/usr/sbin/nologin");
                        
                        removeFileIfExistsE("/usr/sbin/mkfile");
                        removeFileIfExistsE("/usr/sbin/quotaon");
                        removeFileIfExistsE("/usr/sbin/repquota");
                        removeFileIfExistsE("/usr/sbin/zic");
                        removeFileIfExistsE("/usr/sbin/vipw");
                        removeFileIfExistsE("/usr/sbin/vsdbutil");
                        
                        removeFileIfExistsE("/usr/sbin/start-stop-daemon");
                        ////////USR/LOCAL
                        removeFileIfExistsE("/usr/local/lib/libluajit.a");
                        //////LIBRARY
                        removeFileIfExistsE("/Library/test_inject_springboard.cy");
                        //////sbin folder files cleanup
                        removeFileIfExistsE("/sbin/dmesg");
                        
                        removeFileIfExistsE("/sbin/cat");
                        removeFileIfExistsE("/sbin/zshrc");
                        ////usr/sbin files
                        removeFileIfExistsE("/usr/sbin/start-start-daemon");
                        removeFileIfExistsE("/usr/sbin/accton");
                        removeFileIfExistsE("/usr/sbin/addgnupghome");
                        removeFileIfExistsE("/usr/sbin/vifs");
                        removeFileIfExistsE("/usr/sbin/ac");
                        removeFileIfExistsE("/usr/sbin/update");
                        removeFileIfExistsE("/usr/sbin/sysctl");
                        removeFileIfExistsE("/usr/sbin/zdump");
                        removeFileIfExistsE("/usr/sbin/startupfiletool");
                        removeFileIfExistsE("/usr/sbin/iostat");
                        removeFileIfExistsE("/usr/sbin/mkfile");
                        removeFileIfExistsE("/usr/sbin/zic");
                        removeFileIfExistsE("/usr/sbin/vipw");
                        ////usr/libexec files
                        removeFileIfExistsE("/usr/libexec/_rocketd_reenable");
                        removeFileIfExistsE("/usr/libexec/rocketd");
                        removeFileIfExistsE("/usr/libexec/MSUnrestrictProcess");
                        removeFileIfExistsE("/usr/libexec/substrate");
                        removeFileIfExistsE("/usr/libexec/substrated");
                        
                        removeFileIfExistsE("/usr/lib/applist.dylib");
                        removeFileIfExistsE("/usr/lib/libapplist.dylib");
                        removeFileIfExistsE("/usr/lib/libhAcxTools.dylib");
                        removeFileIfExistsE("/usr/lib/libhAcxTools2.dylib");
                        
                        removeFileIfExistsE("/usr/lib/libflipswitch.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-inst.2.0.0.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-inst.2.0.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-pkg.5.0.1.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-pkg.5.0.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-private.0.0.0.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-private.0.0.dylib");
                        removeFileIfExistsE("/usr/lib/libassuan.0.dylib");
                        removeFileIfExistsE("/usr/lib/libassuan.dylib");
                        removeFileIfExistsE("/usr/lib/libassuan.la");
                        removeFileIfExistsE("/usr/lib/libnpth.0.dylib");
                        removeFileIfExistsE("/usr/lib/libnpth.dylib");
                        removeFileIfExistsE("/usr/lib/libnpth.la");
                        removeFileIfExistsE("/usr/lib/libgpg-error.0.dylib");
                        removeFileIfExistsE("/usr/lib/libgpg-error.dylib");
                        removeFileIfExistsE("/usr/lib/libgpg-error.la");
                        removeFileIfExistsE("/usr/lib/libksba.8.dylib");
                        removeFileIfExistsE("/usr/lib/libksba.dylib");
                        removeFileIfExistsE("/usr/lib/libksba.la");
                        removeFileIfExistsE("/usr/lib/cycript0.9");
                        removeFileIfExistsE("/usr/lib/libhistory.5.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-pkg.dylib.4.6");
                        removeFileIfExistsE("/usr/lib/libapt-pkg.4.6.dylib");
                        removeFileIfExistsE("/usr/lib/libpam.dylib");
                        removeFileIfExistsE("/usr/lib/libpamc.1.dylib");
                        removeFileIfExistsE("/usr/lib/libpackageinfo.dylib");
                        removeFileIfExistsE("/usr/lib/librocketbootstrap.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-pkg.dylib.4.6.0");
                        removeFileIfExistsE("/usr/lib/libapt-pkg.4.6.0.dylib");
                        removeFileIfExistsE("/usr/lib/libpanelw.5.dylib");
                        removeFileIfExistsE("/usr/lib/libhistory.5.2.dylib");
                        removeFileIfExistsE("/usr/lib/libreadline.6.dylib");
                        removeFileIfExistsE("/usr/lib/libpanel.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-inst.dylib.1.1");
                        removeFileIfExistsE("/usr/lib/libapt-inst.1.1.dylib");
                        removeFileIfExistsE("/usr/lib/libcurses.dylib");
                        removeFileIfExistsE("/usr/lib/liblzmadec.0.dylib");
                        removeFileIfExistsE("/usr/lib/libhistory.6.dylib");
                        removeFileIfExistsE("/usr/lib/libformw.dylib");
                        removeFileIfExistsE("/usr/lib/libncursesw.dylib");
                        removeFileIfExistsE("/usr/lib/libncurses.5.dylib");
                        removeFileIfExistsE("/usr/lib/libreadline.5.dylib");
                        removeFileIfExistsE("/usr/lib/libhistory.6.0.dylib");
                        removeFileIfExistsE("/usr/lib/libform.5.dylib");
                        removeFileIfExistsE("/usr/lib/libpanelw.dylib");
                        removeFileIfExistsE("/usr/lib/libmenuw.dylib");
                        removeFileIfExistsE("/usr/lib/libform.dylib");
                        removeFileIfExistsE("/usr/lib/terminfo");
                        removeFileIfExistsE("/usr/lib/terminfo");
                        removeFileIfExistsE("/usr/lib/libpam.1.0.dylib");
                        removeFileIfExistsE("/usr/lib/libmenu.5.dylib");
                        removeFileIfExistsE("/usr/lib/libpatcyh.dylib");
                        removeFileIfExistsE("/usr/lib/libreadline.6.0.dylib");
                        removeFileIfExistsE("/usr/lib/liblzmadec.dylib");
                        removeFileIfExistsE("/usr/lib/libncurses.dylib");
                        removeFileIfExistsE("/usr/lib/libhistory.dylib");
                        removeFileIfExistsE("/usr/lib/libpamc.dylib");
                        removeFileIfExistsE("/usr/lib/libformw.5.dylib");
                        removeFileIfExistsE("/usr/lib/libapt-inst.dylib.1.1.0");
                        removeFileIfExistsE("/usr/lib/libapt-inst.1.1.0.dylib");
                        removeFileIfExistsE("/usr/lib/libpanel.5.dylib");
                        removeFileIfExistsE("/usr/lib/liblzmadec.0.0.0.dylib");
                        removeFileIfExistsE("/usr/lib/_ncurses");
                        removeFileIfExistsE("/usr/lib/libpam_misc.1.dylib");
                        removeFileIfExistsE("/usr/lib/libreadline.5.2.dylib");
                        removeFileIfExistsE("/usr/lib/libpam_misc.dylib");
                        removeFileIfExistsE("/usr/lib/libreadline.dylib");
                        removeFileIfExistsE("/usr/lib/libmenuw.5.dylib");
                        removeFileIfExistsE("/usr/lib/libpam.1.dylib");
                        removeFileIfExistsE("/usr/lib/libmenu.dylib");
                        removeFileIfExistsE("/usr/lib/liblzmadec.la");
                        removeFileIfExistsE("/usr/lib/libncursesw.5.dylib");
                        removeFileIfExistsE("/usr/lib/libcycript.dylib");
                        removeFileIfExistsE("/usr/lib/libcycript.jar");
                        removeFileIfExistsE("/usr/lib/libcycript.db");
                        removeFileIfExistsE("/usr/lib/libcurl.4.dylib");
                        removeFileIfExistsE("/usr/lib/libcurl.dylib");
                        removeFileIfExistsE("/usr/lib/libcurl.la");
                        removeFileIfExistsE("/usr/lib/libcycript.0.dylib");
                        removeFileIfExistsE("/usr/lib/libcycript.cy");
                        removeFileIfExistsE("/usr/lib/libcephei.dylib");
                        removeFileIfExistsE("/usr/lib/libcepheiprefs.dylib");
                        removeFileIfExistsE("/usr/lib/libhbangcommon.dylib");
                        removeFileIfExistsE("/usr/lib/libhbangprefs.dylib");
                        /////end it
                        removeFileIfExistsE("/usr/lib/libjailbreak.dylib");
                        removeFileIfExistsE("/var/profile");
                        removeFileIfExistsE("/var/motd");
                        removeFileIfExistsE("/var/log/testbin.log");
                        removeFileIfExistsE("/var/log/apt");
                        removeFileIfExistsE("/var/log/jailbreakd-stderr.log");
                        removeFileIfExistsE("/var/log/jailbreakd-stdout.log");
                        removeFileIfExistsE("/Library/test_inject_springboard.cy");
                        removeFileIfExistsE("/usr/local/lib/libluajit.a");
                        removeFileIfExistsE("/bin/zsh");
                        //missing from removeMe.sh oddly
                        //////mine above lol
                        //////////////////Jakes below
                        
                        removeFileIfExistsE("/var/LIB");
                        removeFileIfExistsE("/var/bin");
                        removeFileIfExistsE("/var/sbin");
                        removeFileIfExistsE("/var/profile");
                        removeFileIfExistsE("/var/motd");
                        removeFileIfExistsE("/var/dropbear");
                        removeFileIfExistsE("/var/containers/Bundle/tweaksupport");
                        removeFileIfExistsE("/var/containers/Bundle/iosbinpack64");
                        removeFileIfExistsE("/var/containers/Bundle/dylibs");
                        removeFileIfExistsE("/var/LIB");
                        removeFileIfExistsE("/var/motd");
                        removeFileIfExistsE("/var/log/testbin.log");
                        removeFileIfExistsE("/var/log/jailbreakd-stdout.log");
                        removeFileIfExistsE("/var/log/jailbreakd-stderr.log");
            
        }
        else {
            printf("FAILED TO REMOVE WITH RM FREYA\n");
        }
}
