//
//  ViewController.m
//  Ziyou
//
//  Created by Tanay Findley on 5/7/19.
//  Copyright © 2019 Ziyou Team. All rights reserved.
//

//THIS PROJECT IS IN VERY EARLY STAGES OF DEVELOPMENT!

#import <time.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>

#import "ViewController.h"
#import "SettingsViewController.h"
#import "utils/utilsZS.h"
#include "utils/holders/ImportantHolders.h"
#include "offsets.h"
#include "remap_tfp_set_hsp.h"
#include "kernel_slide.h"
#include "kernel_exec.h"
#include <mach/host_priv.h>
#include <mach/mach_error.h>
#include <mach/mach_host.h>
#include <mach/mach_port.h>
#include <mach/mach_time.h>
#include <mach/task.h>
#include <mach/thread_act.h>
#include "reboot.h"
#include "machswap.h"
#include "cs_blob.h"
#include "file_utils.h"

#define localize(key) NSLocalizedString(key, @"")
#define postProgress(prg) [[NSNotificationCenter defaultCenter] postNotificationName: @"JB" object:nil userInfo:@{@"JBProgress": prg}]

//#define pwned4ever_URL "https://www.dropbox.com/s/7ynb8eotrp2ycc3/Th0r-2.ipa"

#define pwned4ever_URL "https://www.dropbox.com/s/stnh0out4tkoces/Th0r.ipa"
#define pwned4ever_TEAM_TWITTER_HANDLE "shogunpwnd"
#define K_ENABLE_TWEAKS "enableTweaks"
#define CS_OPS_STATUS       0   /* return status */


int setplaymusic = 0;
int theViewLoaded = 0;
float theprogressis = 0.000000000;
struct timeval tv1, tv2;
mach_port_t statusphier = MACH_PORT_NULL;

bool newTFcheckMyRemover4me;
bool newTFcheckofCyforce;
bool JUSTremovecheck;

extern void (*log_UI)(const char *text);
void log_toView(const char *text);

@interface ViewController ()

@end

@implementation ViewController

+ (instancetype)currentViewController {
    return currentViewController;
}
ViewController *sharedController = nil;
static ViewController *currentViewController;


double uptime(){
    struct timeval boottime;
    size_t len = sizeof(boottime);
    int mib[2] = { CTL_KERN, KERN_BOOTTIME };
    if( sysctl(mib, 2, &boottime, &len, NULL, 0) < 0 )
    {
        return -1.0;
    }
    time_t bsec = boottime.tv_sec, csec = time(NULL);
    
    return difftime(csec, bsec);
}

- (IBAction)stopbtnMusic:(id)sender {
    NSString *music=[[NSBundle mainBundle]pathForResource:@"RealBadBoyz" ofType:@"mp3"];
    audioPlayer1=[[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:music]error:NULL];
    audioPlayer1.delegate=self;
    [audioPlayer1 stop];
}
- (IBAction)startmusic:(id)sender {
    NSString *music=[[NSBundle mainBundle]pathForResource:@"RealBadBoyz" ofType:@"mp3"];
    audioPlayer1=[[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:music]error:NULL];
    audioPlayer1.delegate=self;
    audioPlayer1.volume=1;
    audioPlayer1.numberOfLoops=-1;
    [audioPlayer1 play];
}


- (void)shareTh0r {
    struct utsname u = { 0 };
    uname(&u);
    
   // util_info("machine: %s", u.machine);
    //util_info("sysname: %s", u.sysname);
    //util_info("version: %s", u.version);
    //util_info("nodename: %s", u.nodename);
    //util_info("release: %s", u.release);
    //char *devicemodel = u.machine;
    //[NSString stringWithUTF8String:u.machine
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.devicelabel setText:[NSString stringWithUTF8String:u.machine]];
        [self.versionlabel setText:[[UIDevice currentDevice] systemVersion] ];

    });
//    [_uptimelabel setText:[NSString stringWithUTF8String:up]];//(*devicemodel)];
    //(*devicemodel)];
//    u.sysname;  /* [XSI] Name of OS */
  //  u.nodename; /* [XSI] Name of this network node */
   // u.release;  /* [XSI] Release level */
   // u.version;  /* [XSI] Version level */
   // u.machine;
    
    //[self.jailbreak setEnabled:NO];
    //[self.jailbreak setHidden:YES];
    [NSString stringWithUTF8String:u.machine];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Wanna Share Th0r Jailbreak", nil) message:NSLocalizedString(@"𝓢Ⓗ⒜𝕽ᴱ Th0r 👍🏽 Jailbreak?", nil) preferredStyle:UIAlertControllerStyleAlert];UIAlertAction *OK = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ya of course", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //[self.buttontext setEnabled:YES];
                UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSString stringWithFormat:localize(@"I'm using Th0r-Freya - Jailbreak Toolkit for iOS 12.0 - 12.5.5, Updated 03/23/22 5:00PM-EDT. By:@%@ 🍻, to jailbreak my %@ iOS %@. You can download it now @ %@" ), @pwned4ever_TEAM_TWITTER_HANDLE, [NSString stringWithUTF8String:u.machine],[[UIDevice currentDevice] systemVersion], @pwned4ever_URL]] applicationActivities:nil];
                activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAirDrop, UIActivityTypeOpenInIBooks, UIActivityTypeMarkupAsPDF];
                if ([activityViewController respondsToSelector:@selector(popoverPresentationController)] ) {
                    activityViewController.popoverPresentationController.sourceView = self.buttontext;
                }
                [self presentViewController:activityViewController animated:YES completion:nil];
                [self.buttontext setEnabled:NO];
                [self.buttontext setHidden:YES];
                
            });
        }];
        UIAlertAction *Cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Nah, don't want anyone to know", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.buttontext setEnabled:NO];
                [self.buttontext setHidden:YES];
            });
        }];
        [alertController addAction:OK];
        [alertController addAction:Cancel];
        [alertController setPreferredAction:Cancel];
        [self presentViewController:alertController animated:YES completion:nil];
    });
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
    //runExploit(4);
    currentViewController = self;
    initSettingsIfNotExist();
    sharedController = self;
    //self.textView.layer.borderWidth = 1.0;
    self.textView.layer.borderColor = UIColor.greenColor.CGColor;
    self.textView.text = @"";
    self.textView.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
   // [self.jailbreak setEnabled:FALSE];
    //self.jailbreak.backgroundColor = UIColor.lightGrayColor;
    //self.progressMeterUIVIEW.backgroundColor UIColor.systemRedColor.CIColor;
    //UIColor.purpleColor.CGColor);
    log_UI = log_toView;
    CAGradientLayer *gradient = [CAGradientLayer layer];

    gradient.frame = self.backGroundView.bounds;
    //gradient.colors = @[(id)[[UIColor colorWithRed:0.26 green:0.81 blue:0.64 alpha:1.0] CGColor], (id)[[UIColor colorWithRed:0.09 green:0.35 blue:0.62 alpha:1.0] CGColor]];
    gradient.colors = @[(id)[[UIColor colorWithRed:0.02 green:0.02 blue:0.02 alpha:1.0] CGColor], (id)[[UIColor colorWithRed:0.29 green:0.05 blue:0.22 alpha:1.0] CGColor]];

    [self.progressMeterUIVIEW.layer insertSublayer: gradient atIndex:1];
    [self.backGroundView.layer insertSublayer:gradient atIndex:0];
    [self.thorbackgroundjpeg setHidden:YES];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/.jailbroken_freya"])
    {
        [[self buttontext] setEnabled:false];
    }
    if (setplaymusic == 0) {
        NSString *music=[[NSBundle mainBundle]pathForResource:@"RealBadBoyz" ofType:@"mp3"];
        audioPlayer1=[[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:music]error:NULL];
        audioPlayer1.delegate=self;
        audioPlayer1.volume=1;
        audioPlayer1.numberOfLoops=-1;
        //[audioPlayer1 play];
        setplaymusic = 1;
    }
    
    uint32_t flags;
    csops(getpid(), CS_OPS_STATUS, &flags, 0);
    int checkuncovermarker = (file_exists("/.installed_unc0ver"));
    int checkth0rmarker = (file_exists("/.freya_installed"));
    int checkelectramarker = (file_exists("/.bootstrapped_chimera"));
    int checkJBRemoverMarker = (file_exists("/var/mobile/Media/.bootstrapped_Th0r_remover"));
    int checkjailbreakdRun = (file_exists("/var/tmp/jailbreakd.pid"));
    int checkpspawnhook = (file_exists("/var/run/pspawn_hook.ts"));
    printf("JUSTremovecheck exists?: %d\n",JUSTremovecheck);
    printf("Uncover marker exists?: %d\n", checkuncovermarker);
    printf("pspawnhook marker exists?: %d\n", checkpspawnhook);
    printf("Uncover marker exists?: %d\n", checkuncovermarker);
    printf("JBRemover marker exists?: %d\n", checkJBRemoverMarker);
    printf("Th0r marker exists?: %d\n", checkth0rmarker);
    printf("Electra marker exists?: %d\n", checkelectramarker);
    printf("Jailbreakd Run marker exists?: %d\n", checkjailbreakdRun);
    [self.uptimelabel setHidden:YES];
    [self.devicelabel setHidden:NO];
    struct utsname u = { 0 };
    uname(&u);
    [[UIDevice currentDevice] systemVersion];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.devicelabel setText:[NSString stringWithUTF8String:u.machine] ];
        [self.versionlabel setText:[[UIDevice currentDevice] systemVersion] ];
    });
        if ((checkjailbreakdRun == 1) && (checkpspawnhook == 1) && (checkth0rmarker == 1) && (checkuncovermarker == 0) && (checkelectramarker == 0)){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.buttontext setHidden:NO];
                [self.buttontext setTitle:localize(@"𝓢Ⓗ⒜𝕽ᴱ Th0r?") forState:UIControlStateNormal];
                [self.uptimelabel setHidden:NO];
                [self.devicelabel setHidden:NO];
                [self.settingsButton setHidden:YES];
                [self.progressmeterView setHidden:YES];
                [self.progressMeterUIVIEW setHidden:YES];
                [self.settingsButton setEnabled:NO];
                [self.settings_buttun_bg setHidden:YES];
                [self.settings_buttun_bg setUserInteractionEnabled:NO];
                [self.thorbackgroundjpeg setHidden:NO];
            });
            [self shareTh0r];
            goto end;
        }
        if ((checkjailbreakdRun == 1) && (checkth0rmarker == 1) && (checkuncovermarker == 0) && (checkelectramarker == 0)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.buttontext setEnabled:YES];
                [self.settingsButton setHidden:YES];
                [self.settings_buttun_bg setHidden:YES];
                [self.settings_buttun_bg setUserInteractionEnabled:NO];
                [self.settingsButton setEnabled:NO];
                [self.buttontext setTitle:localize(@"𝓢Ⓗ⒜𝕽ᴱ Th0r?👍🏽") forState:UIControlStateNormal];
                [self.uptimelabel setHidden:NO];
                [self.devicelabel setHidden:NO];
                [self.progressmeterView setHidden:YES];
                [self.progressMeterUIVIEW setHidden:YES];
                [self.thorbackgroundjpeg setHidden:NO];
            });
            [self shareTh0r];
            goto end;
            return;
        }
        if ((checkth0rmarker == 1) && (checkuncovermarker == 0) && (checkelectramarker == 0) && (checkjailbreakdRun == 0) && (checkpspawnhook == 0)){
            if (shouldRestoreFS())
            {
                [_buttontext setTitle:localize(@"Remove Freya?") forState:UIControlStateNormal];
                JUSTremovecheck = true;
                [_restoreFSSwitch setOn:true];
            } else {
                [_buttontext setTitle:localize(@"Enable Freya?") forState:UIControlStateNormal];
                JUSTremovecheck = false;
                [_restoreFSSwitch setOn:false];
            }
            goto end;
        }
        
        if ((checkuncovermarker == 1) && (checkpspawnhook == 0) && (checkth0rmarker == 0) && (checkjailbreakdRun == 0)){
            //[_enableTweaks setEnabled:NO];
            [self.buttontext setEnabled:NO];
            if (shouldRestoreFS())
            {
                [_buttontext setTitle:localize(@"Remove u0 JB?") forState:UIControlStateNormal];
                JUSTremovecheck = true;
                [_restoreFSSwitch setOn:true];
            } else {
                [_buttontext setTitle:localize(@"Remove u0 JB") forState:UIControlStateNormal];
                JUSTremovecheck = false;
                [_restoreFSSwitch setOn:false];
            }
            goto end;
            return;
        }

        if (((checkuncovermarker == 1) && (checkjailbreakdRun == 0) && (checkpspawnhook == 0)) || ((checkelectramarker == 1) && (checkjailbreakdRun == 0) && (checkpspawnhook == 0))){
            [self.buttontext setEnabled:YES];
            if (shouldRestoreFS())
            {
                [_buttontext setTitle:localize(@"Remove Chimera?") forState:UIControlStateNormal];
                JUSTremovecheck = true;
                [_restoreFSSwitch setOn:true];
            } else {
                [_buttontext setTitle:localize(@"Remove Chimera") forState:UIControlStateNormal];
                JUSTremovecheck = false;
                [_restoreFSSwitch setOn:false];
            }
            goto end;
            
        }

        if(((checkjailbreakdRun == 0) && (checkpspawnhook == 0) && (checkth0rmarker == 0) && (checkuncovermarker == 0)) && (checkelectramarker == 0)){
            newTFcheckMyRemover4me = FALSE;
            [self.buttontext setEnabled:YES];
            if (shouldRestoreFS())
            {
                [_buttontext setTitle:localize(@"Remove Jailbreak?") forState:UIControlStateNormal];
                JUSTremovecheck = true;
                [_restoreFSSwitch setOn:true];
            } else {
                [_buttontext setTitle:localize(@"Jailbreak") forState:UIControlStateNormal];
                JUSTremovecheck = false;
                [_restoreFSSwitch setOn:false];
            }
            //[_buttontext setTitleColor:localize(GL_BLUE) forState:UIControlStateNormal];

            newTFcheckofCyforce = FALSE;
            newTFcheckMyRemover4me = TRUE;
        }
    end:

    gettimeofday(&tv1, NULL);

    setgid(0);
    uint32_t gid = getgid();
    NSLog(@"getgid() returns %u\n", gid);
    setuid(0);
    uint32_t uid = getuid();
    NSLog(@"getuid() returns %u\n", uid);
       /* dispatch_async(dispatch_get_main_queue(), ^{
            [_buttontext setTitle:localize(@"Patch $hit?") forState:UIControlStateNormal];
        });*/

    gettimeofday(&tv2, NULL);
    uint64_t cost = (tv2.tv_sec - tv1.tv_sec) * 1000 * 1000 + tv2.tv_usec - tv1.tv_usec;
    printf("load time: %.4f mins & seconds", ((cost / 1000000.0) / 60));
    //ourprogressMeter();



    LOG("Starting the jailbreak...");
    
err:
    printf("oof");
    
}


+ (ViewController *)sharedController {
    return sharedController;
}


- (IBAction)sliceTwitterHandle:(id)sender
{
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/sliceteam1"] options:@{} completionHandler:nil];

}

- (void)xFinished {
    printf("[-] Failed\n");

    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *jailbreak = [UIAlertController alertControllerWithTitle:@"fuck sakes"
                                                                           message:@"failed..."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:jailbreak animated:YES completion:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                printf("[-] Failed\n");
                [self.buttontext setTitle:localize(@"Failed") forState:UIControlStateNormal];
                UIAlertController *jailbreak = [UIAlertController alertControllerWithTitle:@"fuck sakes"
                                                                                   message:@"failed..."
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                if (tfp0 == MACH_PORT_NULL) {
                    sleep(2);
                    exit(0);
                }
                [jailbreak dismissViewControllerAnimated:YES completion:^{}];
            });
        }];
    });
}



/***
 Thanks Conor
 **/
void runOnMainQueueWithoutDeadlocking(void (^block)(void))
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

- (void)runSpinAnimationOnView:(UIView*)view duration:(CGFloat)duration rotations:(CGFloat)rotations repeat:(float)repeat {
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * rotations * duration ];
    rotationAnimation.duration = duration;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = repeat ? HUGE_VALF : 0;
    
    [view.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)runAnimateGradientOnView:(UIView*)view {
    [UIView animateWithDuration:HUGE_VAL animations:^{
        
    }];
}

- (void)finishOnView:(UIView*)view {
    
    [UIView animateWithDuration:0.5f animations:^{
        [[self sliceLabel] setAlpha:0.0f];
    }];
    
    [UIView animateWithDuration:2.5f animations:^{
        [[self paintBrush] setCenter:CGPointMake(self.view.center.x, self.view.center.y)];
    }];
}

///////////////////////----JELBREK TIEM----////////////////////////////

void logSlice(const char *sliceOfText) {
    //Simple Log Function
    NSString *stringToLog = [NSString stringWithUTF8String:sliceOfText];
    LOG("%@", stringToLog);
}

- (void)updateStatus:(NSString*)statusNum {
    
    runOnMainQueueWithoutDeadlocking(^{
        [UIView transitionWithView:self.buttontext duration:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.buttontext setTitle:statusNum forState:UIControlStateNormal];
        } completion:nil];
    });
    
    
}

- (void)kek {
    runOnMainQueueWithoutDeadlocking(^{
        [self.buttontext setTitle:[NSString stringWithFormat:@"Jailbroken"] forState:UIControlStateNormal];
    });
}


//Wen eta bootloop?

bool restore_fs = false;
bool loadTweaks = true;
bool setNonceBool = false;
int exploitType = 0;


//0 = Cydia
//1 = Zebra

int packagerType = 0;


void wannaSliceOfMe() {
    //Run The Exploit
    
    
    runOnMainQueueWithoutDeadlocking(^{
        logSlice("Jailbreaking");});
        //INIT. EXPLOIT. HERE WE ACHIEVE THE FOLLOWING:
    //[*] TFP0
    //[*] ROOT
    //[*] UNSANDBOX
    //[*] OFFSETS
    
    
    //0 = MachSwap
    //1 = MachSwap2
    //2 = Voucher_Swap
    //3 = SockPuppet
    //4 = timewaste
    //usleep(30000);
    runExploit(getExploitType()); //Change this depending on what device you have...
    
    ourprogressMeter();
    
    getOffsets();
    offs_init();
    //usleep(1000);
    
    //MID-POINT. HERE WE ACHIEVE THE FOLLOWING:
    //[*] INIT KEXECUTE
    //[*] REMOUNT //
    //[*] REQUIRED FILES TO FINISH ARE EXTRACTED
    //[*] REMAP
    
    init_kexecute();
    //usleep(10000);

    remountFS(restore_fs);
    //ourprogressMeter();
    createWorkingDir();
    saveOffs();
    ourprogressMeter();
    setHSP4();
    initInstall(getPackagerType());
    ourprogressMeter();
    term_kexecute();
    ourprogressMeter();
    finish(loadTweaks);
    
    
    
    
    
    
    
    
}

///////////////////////----BOOTON----////////////////////////////



-(IBAction)doExit
{
    //show confirmation message to user
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Confirmation"
                                                 message:@"Do you want to exit?"
                                                delegate:self
                                       cancelButtonTitle:@"Cancel"
                                       otherButtonTitles:@"OK", nil];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 0)  // 0 == the cancel button
    {
        //home button press programmatically
        UIApplication *app = [UIApplication sharedApplication];
        [app performSelector:@selector(suspend)];

        //wait 2 seconds while app is going background
        [NSThread sleepForTimeInterval:2.0];

        //exit app when app is in background
        exit(0);
    }
}


- (IBAction)Credits:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Credits" message:@"Main Developers\n-\n @BrandonPlank6, @Chr0nicT\n Special Thanks\n @Pwn20wnd" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *THANKS = [UIAlertAction actionWithTitle:@"Thanks!" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        [alertController dismissViewControllerAnimated:true completion:nil];
    }];
    [alertController addAction:THANKS];
    [alertController setPreferredAction:THANKS];
    [self presentViewController:alertController animated:false completion:nil];
    
}


-(void)ourprogressMeterjeez{
    if (theprogressis < 1.000000001) {
        theprogressis = theprogressis + 0.100000000;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_progressMeterUIVIEW setProgress: theprogressis];
            [self->_buttontext setTitle:@"oh ya" forState: normal];
        });
    }
}

-(void)updatingthejbbuttonlabel{
    runOnMainQueueWithoutDeadlocking(^{
        [self.buttontext setTitle:[NSString stringWithFormat:@"extracting strap"] forState:UIControlStateNormal];
    });
}

-(void)cydiafinish{
    runOnMainQueueWithoutDeadlocking(^{
        [self.buttontext setTitle:[NSString stringWithFormat:@"cydia done"] forState:UIControlStateNormal];
    });
}
-(void)respring{
    runOnMainQueueWithoutDeadlocking(^{
        [self.buttontext setTitle:[NSString stringWithFormat:@"respringing"] forState:UIControlStateNormal];
    });
}
-(void)thecacheofcaching{
    runOnMainQueueWithoutDeadlocking(^{
        [self.buttontext setTitle:[NSString stringWithFormat:@"uicache"] forState:UIControlStateNormal];
    });
}

-(void)RunningTheD{
    runOnMainQueueWithoutDeadlocking(^{
        [self.buttontext setTitle:[NSString stringWithFormat:@"Jailbreakd..."] forState:UIControlStateNormal];
    });
}
-(void)TheDstarted{
    runOnMainQueueWithoutDeadlocking(^{
        [self.buttontext setTitle:[NSString stringWithFormat:@"JBD started"] forState:UIControlStateNormal];
    });
}

- (IBAction)jailbreak:(id)sender {
    
    //HERE
    if (shouldRestoreFS())
    {
        restore_fs = true;
        saveCustomSetting(@"RestoreFS", 1);
    } else {
        restore_fs = false;
    }
    
    if (shouldLoadTweaks())
    {
        loadTweaks = true;
    } else {
        loadTweaks = false;
    }
    
    //Disable The Button
    [sender setEnabled:false];
    
    //Disable and fade out the settings button
    [[self settingsButton] setEnabled:false];
    [UIView animateWithDuration:1.0f animations:^{
        [[self settingsButton] setAlpha:0.0f];
    }];
    ourprogressMeter();
    //Run the exploit in a void.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        wannaSliceOfMe();
    });
}



@end
void log_toView(const char *text)
{
    dispatch_sync( dispatch_get_main_queue(), ^{
        [[sharedController textView] insertText:[NSString stringWithUTF8String:text]];
        [[sharedController textView] scrollRangeToVisible:NSMakeRange([sharedController textView].text.length, 1)];
    });
}

void thelabelbtnchange(char *msg){
    [[ViewController currentViewController] updatingthejbbuttonlabel];

}
void cydiaDone(char *msg){
    [[ViewController currentViewController] cydiafinish];

}

void startJBD(char *msg){
    [[ViewController currentViewController] RunningTheD];

}
void jbdfinished(char *msg){
    [[ViewController currentViewController] TheDstarted];

}
void uicaching(char *msg){
    [[ViewController currentViewController] thecacheofcaching];

}
void respringing(char *msg){
    [[ViewController currentViewController] respring];

}
void ourprogressMeter(){
    
    [[ViewController currentViewController] ourprogressMeterjeez];
    
    
}
