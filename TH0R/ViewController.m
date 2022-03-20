//
//  ViewController.m
//  Ziyou
//
//  Created by Tanay Findley on 5/7/19.
//  Copyright © 2019 Ziyou Team. All rights reserved.
//

//THIS PROJECT IS IN VERY EARLY STAGES OF DEVELOPMENT!

#import <time.h>
#import "ViewController.h"
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



int theViewLoaded = 0;
float theprogressis = 0.000000000;
struct timeval tv1, tv2;
mach_port_t statusphier = MACH_PORT_NULL;

extern void (*log_UI)(const char *text);
void log_toView(const char *text);

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressMeterUIVIEW;
@end

@implementation ViewController

+ (instancetype)currentViewController {
    return currentViewController;
}

ViewController *sharedController = nil;
static ViewController *currentViewController;

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
    

    currentViewController = self;

   // [_progressMeterUIVIEW    setProgress: theprogressis];
   // ourprogressMeter();

    initSettingsIfNotExist();
    
    //ourprogressMeter();
    sharedController = self;
    //self.textView.layer.borderWidth = 1.0;
    self.textView.layer.borderColor = UIColor.greenColor.CGColor;
    self.textView.text = @"";
    // 只有当前行中不包含空格等字符时才生效，sad
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

    [self.progressMeterUIVIEW.layer insertSublayer: gradient atIndex:0];
    [self.backGroundView.layer insertSublayer:gradient atIndex:0];
    
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/.jailbroken_TH0R"])
    {
        [[self buttontext] setEnabled:false];
    }
    LOG("Starting the jailbreak...");

}




+ (ViewController *)sharedController {
    return sharedController;
}


- (IBAction)sliceTwitterHandle:(id)sender
{
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/sliceteam1"] options:@{} completionHandler:nil];

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
    
    runExploit(getExploitType()); //Change this depending on what device you have...
    

    ourprogressMeter();
    
    getOffsets();
    offs_init();
    usleep(1000);
    //MID-POINT. HERE WE ACHIEVE THE FOLLOWING:
    //[*] INIT KEXECUTE
    //[*] REMOUNT //
    //[*] REQUIRED FILES TO FINISH ARE EXTRACTED
    //[*] REMAP
    
    init_kexecute();
    usleep(10000);

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
        [self.buttontext setTitle:[NSString stringWithFormat:@"Installing Cydia"] forState:UIControlStateNormal];
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
