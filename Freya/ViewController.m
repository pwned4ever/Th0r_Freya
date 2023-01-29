//
//  ViewController.m
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
#include "unlocknvram.h"

#define localize(key) NSLocalizedString(key, @"")
#define postProgress(prg) [[NSNotificationCenter defaultCenter] postNotificationName: @"JB" object:nil userInfo:@{@"JBProgress": prg}]

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
int back4romset;

bool newTFcheckofCyforce;
bool JUSTremovecheck;
long timespentelapsed;
extern void (*log_UI)(const char *text);
void log_toView(const char *text);

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


char *_cur_deviceModel = NULL;
char *get_current_deviceModel(void){
    if(_cur_deviceModel)
        return _cur_deviceModel;
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* code = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];
    static NSDictionary* deviceNamesByCode = nil;
    if (!deviceNamesByCode) {
        deviceNamesByCode = @{@"i386"      : @"Simulator",
                              @"x86_64"    : @"Simulator",
                              @"iPod1,1"   : @"iPod Touch",        // (Original)
                              @"iPod2,1"   : @"iPod Touch",        // (Second Generation)
                              @"iPod3,1"   : @"iPod Touch",        // (Third Generation)
                              @"iPod4,1"   : @"iPod Touch",        // (Fourth Generation)
                              @"iPod7,1"   : @"iPod Touch",        // (6th Generation)
                              @"iPhone1,1" : @"iPhone",            // (Original)
                              @"iPhone1,2" : @"iPhone",            // (3G)
                              @"iPhone2,1" : @"iPhone",            // (3GS)
                              @"iPad1,1"   : @"iPad",              // (Original)
                              @"iPad2,1"   : @"iPad 2",            //
                              @"iPad3,1"   : @"iPad",              // (3rd Generation)
                              @"iPhone3,1" : @"iPhone 4",          // (GSM)
                              @"iPhone3,3" : @"iPhone 4",          // (CDMA/Verizon/Sprint)
                              @"iPhone4,1" : @"iPhone 4S",         //
                              @"iPhone5,1" : @"iPhone 5",          // (model A1428, AT&T/Canada)
                              @"iPhone5,2" : @"iPhone 5",          // (model A1429, everything else)
                              @"iPad3,4"   : @"iPad",              // (4th Generation)
                              @"iPad2,5"   : @"iPad Mini",         // (Original)
                              @"iPhone5,3" : @"iPhone 5c",         // (model A1456, A1532 | GSM)
                              @"iPhone5,4" : @"iPhone 5c",         // (model A1507, A1516, A1526 (China), A1529 | Global)
                              @"iPhone6,1" : @"iPhone 5s",         // (model A1433, A1533 | GSM)
                              @"iPhone6,2" : @"iPhone 5s",         // (model A1457, A1518, A1528 (China), A1530 | Global)
                              @"iPhone7,1" : @"iPhone 6 Plus",     //
                              @"iPhone7,2" : @"iPhone 6",          //
                              @"iPhone8,1" : @"iPhone 6S",         //
                              @"iPhone8,2" : @"iPhone 6S Plus",    //
                              @"iPhone8,4" : @"iPhone SE",         //
                              @"iPhone9,1" : @"iPhone 7",          //
                              @"iPhone9,3" : @"iPhone 7",          //
                              @"iPhone9,2" : @"iPhone 7 Plus",     //
                              @"iPhone9,4" : @"iPhone 7 Plus",     //
                              @"iPhone10,1": @"iPhone 8",          // CDMA
                              @"iPhone10,4": @"iPhone 8",          // GSM
                              @"iPhone10,2": @"iPhone 8 Plus",     // CDMA
                              @"iPhone10,5": @"iPhone 8 Plus",     // GSM
                              @"iPhone10,3": @"iPhone X",          // CDMA
                              @"iPhone10,6": @"iPhone X",          // GSM
                              @"iPhone11,2": @"iPhone XS",         //
                              @"iPhone11,4": @"iPhone XS Max",     //
                              @"iPhone11,6": @"iPhone XS Max",     // China
                              @"iPhone11,8": @"iPhone XR",         //
                              @"iPhone12,1": @"iPhone 11",         //
                              @"iPhone12,3": @"iPhone 11 Pro",     //
                              @"iPhone12,5": @"iPhone 11 Pro Max", //
                              
                              @"iPad4,1"   : @"iPad Air",          // 5th Generation iPad (iPad Air) - Wifi
                              @"iPad4,2"   : @"iPad Air",          // 5th Generation iPad (iPad Air) - Cellular
                              @"iPad4,4"   : @"iPad Mini",         // (2nd Generation iPad Mini - Wifi)
                              @"iPad4,5"   : @"iPad Mini",         // (2nd Generation iPad Mini - Cellular)
                              @"iPad4,7"   : @"iPad Mini",         // (3rd Generation iPad Mini - Wifi (model A1599))
                              @"iPad6,7"   : @"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1584)
                              @"iPad6,8"   : @"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1652)
                              @"iPad6,3"   : @"iPad Pro (9.7\")",  // iPad Pro 9.7 inches - (model A1673)
                              @"iPad6,4"   : @"iPad Pro (9.7\")"   // iPad Pro 9.7 inches - (models A1674 and A1675)
        };
    }
    NSString* deviceName = [deviceNamesByCode objectForKey:code];
    if (!deviceName) {
        // Not found on database. At least guess main device type from string contents:
        
        if ([code rangeOfString:@"iPod"].location != NSNotFound) {
            deviceName = @"iPod Touch";
        }
        else if([code rangeOfString:@"iPad"].location != NSNotFound) {
            deviceName = @"iPad";
        }
        else if([code rangeOfString:@"iPhone"].location != NSNotFound){
            deviceName = @"iPhone";
        }
        else {
            deviceName = @"Unknown";
        }
    }
    _cur_deviceModel = strdup([deviceName UTF8String]);
    return _cur_deviceModel;
}
char *_cur_deviceversion = NULL;
char *get_current_deviceversion(void){
    if(_cur_deviceversion)
        return _cur_deviceversion;
    struct utsname systemVersion;
    uname(&systemVersion);
    
    NSString* vcode = [NSString stringWithCString: systemVersion.version
                                         encoding:NSUTF8StringEncoding];

    _cur_deviceversion = strdup([vcode UTF8String]);
    return _cur_deviceversion;
    
}

@interface ViewController ()

@end

@implementation ViewController

+ (instancetype)currentViewController {
    return currentViewController;
}
ViewController *sharedController = nil;
static ViewController *currentViewController;


double uptime(void){
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
    NSString *music=[[NSBundle mainBundle]pathForResource:@"Premonition" ofType:@"mp3"];
    audioPlayer1=[[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:music]error:NULL];
    audioPlayer1.delegate=self;
    [audioPlayer1 stop];
}
- (IBAction)startmusic:(id)sender {
    NSString *music=[[NSBundle mainBundle]pathForResource:@"Trust" ofType:@"mp3"];
    audioPlayer1=[[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:music]error:NULL];
    audioPlayer1.delegate=self;
    audioPlayer1.volume=1;
    audioPlayer1.numberOfLoops=-1;
    [audioPlayer1 play];
}


NSString *freyaversion = @"1.3.3⚡️";
char *freyaversionnew = "1.3.3⚡️";

char *freyaupdateDate = "4:45AM 1/29/23";
char *freyaurlDownload = "github.com/pwned4ever/Th0r_Freya/tree/main/Releases/Freya.ipa";//github.com/pwned4ever/Th0r_Freya/blob/main/Releases/Freya.ipa";// "mega.nz/file/BhNxBSgJ#gNcngNQBtXS0Ipa5ivX09-jtIr7BckUhrA7YMkSFaNM"//

- (void)u0alertreboot {
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
       UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Reboot 1st", nil) message:NSLocalizedString(@"Please reboot & remove u0 in order to use Freya on the next bootup, after a successful restore with my tool. You can use my tool to remove u0 jailbreak, once you reboot. When you reboot you can open Freya to remove u0, you don't need to use u0, I got you!", nil) preferredStyle:UIAlertControllerStyleAlert];UIAlertAction *OK = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

       }];
       [alertController addAction:OK];
       [alertController setPreferredAction:OK];
       [self presentViewController:alertController animated:YES completion:nil];
   });

}


- (void)u0alert {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Remove unc0ver", nil) message:NSLocalizedString(@"I've set my tool to remove unc0ver for you, there's no other option available for you at this moment, I've disabled the options, except you are able to change the exploit to use, in settings. Please remove u0, in order to use Freya on the next bootup, after a successful restore with my tool.", nil) preferredStyle:UIAlertControllerStyleAlert];UIAlertAction *OK = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
 
        }];
        [alertController addAction:OK];
        [alertController setPreferredAction:OK];
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)chimeraalertreboot {
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
       UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Reboot 1st", nil) message:NSLocalizedString(@"Please reboot & remove chimera in order to use Freya on the next bootup, after a successful restore with my tool. You can use my tool to remove chimera jailbreak, once you reboot. When you reboot you can open Freya to remove chimera, you don't need to use chimera, I got you!", nil) preferredStyle:UIAlertControllerStyleAlert];UIAlertAction *OK = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

       }];
       [alertController addAction:OK];
       [alertController setPreferredAction:OK];
       [self presentViewController:alertController animated:YES completion:nil];
   });
}
- (void)chimeraalert {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Remove chimera", nil) message:NSLocalizedString(@"I've set my tool to remove chimera for you, there's no other option available for you at this moment, I've disabled the options, except you are able to change the exploit to use, in settings. Please remove chimera, in order to use Freya on the next bootup, after a successful restore with my tool.", nil) preferredStyle:UIAlertControllerStyleAlert];UIAlertAction *OK = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) { }];
        [alertController addAction:OK];
        [alertController setPreferredAction:OK];
        [self presentViewController:alertController animated:YES completion:nil]; });
}
- (void)electraalertreboot {
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
       UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Reboot 1st", nil) message:NSLocalizedString(@"Please reboot & remove electra in order to use Freya on the next bootup, after a successful restore with my tool. You can use my tool to remove electra jailbreak, once you reboot. When you reboot you can open Freya to remove electra, you don't need to use electra, I got you!", nil) preferredStyle:UIAlertControllerStyleAlert];UIAlertAction *OK = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

       }];
       [alertController addAction:OK];
       [alertController setPreferredAction:OK];
       [self presentViewController:alertController animated:YES completion:nil];
   });
}
- (void)electraalert {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Remove electra", nil) message:NSLocalizedString(@"I've set my tool to remove electra for you, there's no other option available for you at this moment, I've disabled the options, except you are able to change the exploit to use, in settings. Please remove electra in order to use Freya on the next bootup, after a successful restore with my tool.", nil) preferredStyle:UIAlertControllerStyleAlert];UIAlertAction *OK = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) { }];
        [alertController addAction:OK];
        [alertController setPreferredAction:OK];
        [self presentViewController:alertController animated:YES completion:nil]; });
}
- (void)shareTh0r {
    struct utsname u = { 0 };
    uname(&u);
    int theups = uptime();
    int therealups = ((theups / 60) / 60) / 24;
    NSString *device = [NSString stringWithUTF8String: get_current_deviceModel()];
    //NSString *version = [NSString stringWithUTF8String: get_current_deviceversion()];
    dispatch_async(dispatch_get_main_queue(), ^{
        //self->_thebuttonsJBbackground.backgroundColor = [UIColor redColor];
        //self thebuttonsJBbackground:CGRectMake(10, 100, self.
        //self.thebuttonsJBbackground.backgroundColor;
        
//        self->_thebuttonsJBbackground.backgroundColor = [UIColor redColor]; CGRectMake(10, 100, self->_thebuttonsJBbackground.view.frame.size.width-20, 30);

        [self.devicelabel setText: [NSString stringWithFormat:localize(@"%@ - %@" ), device, [[UIDevice currentDevice] systemVersion]]];
        if (therealups == 1) {
            [self.uptimelabel setText:[NSString stringWithFormat:localize(@"uptime: %d day" ), therealups]];
        }else {
            [self.uptimelabel setText:[NSString stringWithFormat:localize(@"uptime: %d days" ), therealups]]; }

    });
    //(*devicemodel)];
//    u.sysname;  /* [XSI] Name of OS */
  //  u.nodename; /* [XSI] Name of this network node */
   // u.release;  /* [XSI] Release level */
   // u.version;  /* [XSI] Version level */
   // u.machine;
    [NSString stringWithUTF8String:u.machine];//𝓢Ⓗ⒜𝕽ᴱ F𝕽ᴱy⒜
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Share Freya Jailbreak", nil) message:NSLocalizedString(@"𝓢hare Freya", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *OK = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSString stringWithFormat:localize(@"I'm using Freya %@, to jailbreak my %@ iOS %@.\nUpdated %s. By:@%@ 🍻.\nDownload @ %s" ), freyaversion, [NSString stringWithUTF8String: get_current_deviceModel()], [[UIDevice currentDevice] systemVersion], freyaupdateDate, @pwned4ever_TEAM_TWITTER_HANDLE, freyaurlDownload]] applicationActivities:nil];
                activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAirDrop, UIActivityTypeOpenInIBooks, UIActivityTypeMarkupAsPDF];
                if ([activityViewController respondsToSelector:@selector(popoverPresentationController)] ) {
                    activityViewController.popoverPresentationController.sourceView = self.buttontext; }
                [self presentViewController:activityViewController animated:YES completion:nil];
                [self.buttontext setEnabled:YES];
                [self.buttontext setHidden:NO]; });
        }];
        UIAlertAction *Cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"No thanks, maybe another time.", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.buttontext setEnabled:YES];
                [self.buttontext setHidden:NO]; }); }];
        [alertController addAction:OK];
        [alertController addAction:Cancel];
        [alertController setPreferredAction:Cancel];
        [self presentViewController:alertController animated:YES completion:nil];
    });
}
int wantstoviewlog;
bool wantsmusic;
int justinstalledcydia = 0;


- (void)wannaplaymusic {
    //dispatch_async(dispatch_get_main_queue(), ^{ });

    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Play Music", nil) message:NSLocalizedString(@"Would you like music to play while you wait?", nil) preferredStyle:UIAlertControllerStyleAlert];UIAlertAction *OK = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
           // wantsmusic = true;
           // if (wantsmusic == true ) {//|| setplaymusic == 0
                NSString *music=[[NSBundle mainBundle]pathForResource:@"Premonition" ofType:@"mp3"];
            self->audioPlayer1=[[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:music]error:NULL];
            self->audioPlayer1.delegate=self;
            self->audioPlayer1.volume=1;
            self->audioPlayer1.numberOfLoops=-1;
                setplaymusic = 1;
                [self->audioPlayer1 play];
           // }
        }];
        UIAlertAction *Cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"No, quiet please", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        //    wantsmusic = false;

        }];
        [alertController addAction:OK];
        [alertController addAction:Cancel];
        [alertController setPreferredAction:Cancel];
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];

    
    uint32_t flags;
    csops(getpid(), CS_OPS_STATUS, (void *)&flags, 0);
    int checkuncovermarker = (file_exists("/.installed_unc0ver"));
    int checkcheckRa1nmarker = (file_exists("/.bootstrapped"));
    int checkelectra = (file_exists("/.bootstrapped_electra"));
    int checkth0rmarkerFinal = (file_exists("/.freya_installed"));
    int checkchimeramarker = (file_exists("/.procursus_strapped"));
    int checkjbdTmpRun = (file_exists("/var/tmp/suckmyd.pid"));
    int checku0slide = (file_exists("/var/tmp/slide.txt"));
    int checkcylog = (file_exists("/var/tmp/cydia.log"));
    int checkjbdRun = (file_exists("/var/run/jailbreakd.pid"));
    int cydiaexists = file_exists("/Applications/Cydia.app/Cydia");
   
    int checkpspawnhook = (file_exists("/var/run/pspawn_hook.ts"));
    uint32_t whatisflags = CS_PLATFORM_BINARY; // 67108864 nonjb  // jb stat 67108864
    int permaflagplat = flags & CS_PLATFORM_BINARY;// 0  905981956 jb state 905981956 // non jb state 1864992116
    bool boopermaflagplat = (void *)&flags; //1 statejb true //& CS_PLATFORM_BINARY;// 905981956 jb state  // non jb state 1864992116
    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
    currentViewController = self;
    sharedController = self;
    initSettingsIfNotExist();
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.layer.borderColor = UIColor.greenColor.CGColor;
        self.textView.text = @"";
        [self->_textView setAlpha:0.55];
        self.textView.textContainer.lineBreakMode = NSLineBreakByCharWrapping; });
    log_UI = log_toView;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.backGroundView.bounds;
    gradient.colors = @[(id)[[UIColor colorWithRed:0.56 green:0.02 blue:0.54 alpha:1.0] CGColor],
                        (id)[[UIColor colorWithRed:0.09 green:0.45 blue:0.42 alpha:1.0] CGColor]];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.backGroundView.layer insertSublayer:gradient atIndex:0];
        [self.thorbackgroundjpeg setHidden:NO];
        [self.thorbackgroundjpeg setAlpha: 0.4];
    });
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/.jailbroken_freya"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self buttontext] setEnabled:false]; }); }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.uptimelabel setHidden:YES];
        [self.devicelabel setHidden:NO]; });
    struct utsname u = { 0 };
    uname(&u);
    [[UIDevice currentDevice] systemVersion];
    NSString *device = [NSString stringWithUTF8String: get_current_deviceModel()];
    NSString *version = [NSString stringWithUTF8String: get_current_deviceversion()];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.devicelabel setText: [NSString stringWithFormat:localize(@"%@ - %@" ), device, [[UIDevice currentDevice] systemVersion]]];
        [self.appverlabel setText: [NSString stringWithUTF8String:freyaversionnew]]; });
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:1 forKey:@"SetNonce"];
    initSettingsIfNotExist();
    if (shouldLoadTweaks()) { loadTweaks = true; } else { loadTweaks = false; }
    if ((checkjbdTmpRun == 1) && (checkpspawnhook == 1) && (checkth0rmarkerFinal == 1) && (checkuncovermarker == 0) && (checkelectra == 0) && (checkchimeramarker == 0)){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.buttontext setHidden:NO];
            [self.buttontext setTitle:localize(@"𝓢Ⓗ⒜𝕽ᴱ Freya?") forState:UIControlStateNormal];
            [self.uptimelabel setHidden:NO];
            [self.devicelabel setHidden:NO];
            [self.settingsButton setHidden:YES];
            [self.progressmeterView setHidden:YES];
            [self.progressMeterUIVIEW setHidden:YES];
            [self.settingsButton setEnabled:NO];
            [self.textView setHidden:YES];
            [self.settings_buttun_bg setHidden:YES];
            [self.settings_buttun_bg setUserInteractionEnabled:NO];
            [self.thorbackgroundjpeg setHidden:NO];
            [self.thorbackgroundjpeg setAlpha: 1.0];

        });
        
        [UITabBarController setAccessibilityElementsHidden:(TRUE)];
        
        [self shareTh0r];
    } else if ((checkjbdTmpRun == 1) && (checkth0rmarkerFinal == 1) && (checkuncovermarker == 0) && (checkelectra == 0) && (checkchimeramarker == 0)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.buttontext setEnabled:YES];
            [self.settingsButton setHidden:YES];
            [self.settings_buttun_bg setHidden:YES];
            [self.settings_buttun_bg setUserInteractionEnabled:NO];
            [self.settingsButton setEnabled:NO];
            [self.textView setHidden:YES];
            [self.buttontext setTitle:localize(@"𝓢Ⓗ⒜𝕽ᴱ F𝕽ᴱy⒜") forState:UIControlStateNormal];
            [self.uptimelabel setHidden:NO];
            [self.devicelabel setHidden:NO];
            [self.progressmeterView setHidden:YES];
            [self.progressMeterUIVIEW setHidden:YES];
            [self.thorbackgroundjpeg setHidden:NO];
            [self.thorbackgroundjpeg setAlpha: 1.0];

        });
        [self shareTh0r];
    } else if (checkth0rmarkerFinal ==1 && (!file_exists("/Applications/Cydia.app/Cydia"))) {
        newTFcheckMyRemover4me = FALSE;
        saveCustomSetting(@"RestoreFS", 1);
        JUSTremovecheck = false;
        dispatch_async(dispatch_get_main_queue(), ^{
                [self.buttontext setEnabled:YES];
                [self.buttontext setTitle:localize(@"Jailbreak") forState:UIControlStateNormal];
                [self.restoreFSSwitch setOn:false];
                [self.loadTweakSwitch setEnabled:YES];
                [self.loadTweakSwitch setOn:TRUE];
            if (shouldLoadTweaks()) {
                loadTweaks = true; }
            else { loadTweaks = false; }
        });
        goto end;
    } else if ((checkth0rmarkerFinal == 1) && (checkuncovermarker == 0) && (checkchimeramarker == 0) && (checkelectra == 0) && (checkjbdTmpRun == 0) && (checkpspawnhook == 0)){
        if (shouldRestoreFS()) {
            JUSTremovecheck = true;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.buttontext setTitle:localize(@"Remove Freya?") forState:UIControlStateNormal];
                [self.fixfsswitch setOn:FALSE];
                [self.fixfsswitch setEnabled:NO];
                [self.restoreFSSwitch setEnabled:YES];
                [self.restoreFSSwitch setOn:true];
                [self.loadTweakSwitch setEnabled:YES];
                [self.loadTweakSwitch setOn:TRUE]; });
        } else {
            JUSTremovecheck = false;
         if (checkcheckRa1nmarker == 0) {
             if (checkfsfixswitch == 1) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self.buttontext setTitle:localize(@"fix fs?") forState:UIControlStateNormal];
                     [self.fixfsswitch setOn:TRUE];
                     [self.restoreFSSwitch setEnabled:NO];
                     [self.restoreFSSwitch setOn:false];
                     [self.loadTweakSwitch setEnabled:YES];
                     [self.loadTweakSwitch setOn:TRUE]; });
             } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.buttontext setTitle:localize(@"Enable Freya?") forState:UIControlStateNormal];
                    [self.fixfsswitch setOn:FALSE];
                    [self.restoreFSSwitch setEnabled:YES];
                    [self.restoreFSSwitch setOn:false];
                    [self.loadTweakSwitch setEnabled:YES];
                    [self.loadTweakSwitch setOn:TRUE]; });
             }
         } else {
            if (checkfsfixswitch == 1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.buttontext setTitle:localize(@"fix fs?") forState:UIControlStateNormal];
                    [self.fixfsswitch setOn:TRUE];
                    [self.restoreFSSwitch setEnabled:NO];
                    [self.restoreFSSwitch setOn:false];
                    [self.loadTweakSwitch setEnabled:YES];
                    [self.loadTweakSwitch setOn:TRUE]; });
            } else {
                [self.buttontext setTitle:localize(@"checkra1n & Freya?") forState:UIControlStateNormal];
                [self.fixfsswitch setOn:FALSE];
                [self.restoreFSSwitch setOn:false];
                [self.loadTweakSwitch setEnabled:YES];
                [self.loadTweakSwitch setOn:TRUE]; }
        }
    }
        goto end;
    } else if ((checkcheckRa1nmarker == 1) && (flags & CS_PLATFORM_BINARY)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.buttontext setEnabled:NO];
            [ViewController.sharedController.settingsButton setEnabled:NO];
            [ViewController.sharedController.settingsButton setHidden:TRUE];
            [ViewController.sharedController.settingsButton setHidden:YES];
            [ViewController.sharedController.settingsButton setEnabled:NO];
            [ViewController.sharedController.settings_buttun_bg setHidden:YES];
            [self.buttontext setTitle:localize(@"checkra1n w/freya?") forState:UIControlStateNormal];
            [self.restoreFSSwitch setOn:false];
            [self.loadTweakSwitch setEnabled:YES];
            [self.loadTweakSwitch setOn:TRUE]; });
    } else if (((checkuncovermarker == 1) && (checku0slide == 1)) || ((checkuncovermarker == 1) && (checkcylog == 1))){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.buttontext setTitle:localize(@"Remove u0 1st") forState:UIControlStateNormal];
            [self.buttontext setEnabled:NO];
            [self.progressMeterUIVIEW setHidden:true];
            [ViewController.sharedController.progressMeterUIVIEW setHidden:YES];
            [ViewController.sharedController.settingsButton setEnabled:NO];
            [ViewController.sharedController.settings_buttun_bg setHidden:YES]; });
        JUSTremovecheck = true;
        saveCustomSetting(@"RestoreFS", 0);
        [self u0alertreboot];
        goto end;
    } else if ((checkuncovermarker == 1) && (checku0slide == 0)){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.buttontext setTitle:localize(@"Remove u0?") forState:UIControlStateNormal];
            [self.buttontext setEnabled:YES];
            [self.progressMeterUIVIEW setHidden:NO];
            [ViewController.sharedController.progressMeterUIVIEW setHidden:NO];
            [ViewController.sharedController.settingsButton setEnabled:YES];
            [ViewController.sharedController.settings_buttun_bg setHidden:NO]; });
        JUSTremovecheck = true;
        saveCustomSetting(@"RestoreFS", 0);
        [self u0alert];
        goto end;
    } else if ((checkjbdRun == 1) && (checkelectra == 1)){
        saveCustomSetting(@"RestoreFS", 0);
        JUSTremovecheck = true;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.buttontext setTitle:localize(@"Remove Electra 1st") forState:UIControlStateNormal];
            [self.restoreFSSwitch setEnabled:NO];
            [self.buttontext setEnabled:NO];
            [ViewController.sharedController.progressMeterUIVIEW setHidden:YES];
            [ViewController.sharedController.restoreFSSwitch setEnabled:NO];
            [ViewController.sharedController.settingsButton setEnabled:NO];
            [ViewController.sharedController.settings_buttun_bg setHidden:YES];
            [ViewController.sharedController.restoreFSSwitch setUserInteractionEnabled:NO]; });
        [self electraalertreboot];
        goto end;
    } else if ((checkjbdRun == 0) && (checkelectra == 1)){
        saveCustomSetting(@"RestoreFS", 0);
        JUSTremovecheck = true;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.restoreFSSwitch setEnabled:NO];
            [self.buttontext setEnabled:YES];
            [self.progressMeterUIVIEW setHidden:NO];
            [self.buttontext setTitle:localize(@"Remove Electra?") forState:UIControlStateNormal];
            [ViewController.sharedController.progressMeterUIVIEW setHidden:NO];
            [ViewController.sharedController.settingsButton setEnabled:YES];
            [ViewController.sharedController.settings_buttun_bg setHidden:NO];
            [ViewController.sharedController.restoreFSSwitch setEnabled:NO];
            [ViewController.sharedController.restoreFSSwitch setUserInteractionEnabled:NO]; });
        [self electraalert];
        goto end;
    } else if ((checkjbdRun == 1) && (checkchimeramarker == 1)){
        saveCustomSetting(@"RestoreFS", 0);
        JUSTremovecheck = true;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.restoreFSSwitch setEnabled:NO];
            [self.buttontext setEnabled:NO];
            [self.buttontext setTitle:localize(@"Remove Chimera 1st") forState:UIControlStateNormal];
            [ViewController.sharedController.progressMeterUIVIEW setHidden:YES];
            [ViewController.sharedController.restoreFSSwitch setEnabled:NO];
            [ViewController.sharedController.settingsButton setEnabled:NO];
            [ViewController.sharedController.settings_buttun_bg setHidden:YES];
            [ViewController.sharedController.restoreFSSwitch setUserInteractionEnabled:NO]; });
        [self chimeraalertreboot];
        goto end;
    } else if ((checkjbdRun == 0) && (checkchimeramarker == 1)){
        saveCustomSetting(@"RestoreFS", 0);
        JUSTremovecheck = true;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.restoreFSSwitch setEnabled:NO];
            [self.buttontext setEnabled:YES];
            [self.progressMeterUIVIEW setHidden:NO];
            [self.buttontext setTitle:localize(@"Remove Chimera?") forState:UIControlStateNormal];
            [ViewController.sharedController.progressMeterUIVIEW setHidden:NO];
            [ViewController.sharedController.settingsButton setEnabled:YES];
            [ViewController.sharedController.settings_buttun_bg setHidden:NO];
            [ViewController.sharedController.restoreFSSwitch setEnabled:NO];
            [ViewController.sharedController.restoreFSSwitch setUserInteractionEnabled:NO]; });
        [self chimeraalert];
        goto end;
    } else if (checkth0rmarkerFinal ==1 && (!file_exists("/Applications/Cydia.app/Cydia"))) {
            newTFcheckMyRemover4me = FALSE;
            saveCustomSetting(@"RestoreFS", 1);
            JUSTremovecheck = false;
            dispatch_async(dispatch_get_main_queue(), ^{
                    [self.buttontext setEnabled:YES];
                    [self.buttontext setTitle:localize(@"Jailbreak") forState:UIControlStateNormal];
                    [self.restoreFSSwitch setOn:false];
                    [self.loadTweakSwitch setEnabled:YES];
                    [self.loadTweakSwitch setOn:TRUE];
                if (shouldLoadTweaks()) {
                    loadTweaks = true; }
                else { loadTweaks = false; }
            });
            goto end;
    } else if(((checkjbdTmpRun == 0) && (checkpspawnhook == 0) && (checkth0rmarkerFinal == 0) && (checkuncovermarker == 0)) && (checkchimeramarker == 0) && (checkelectra == 0)){
            if (checkcheckRa1nmarker == 0) {
                newTFcheckMyRemover4me = FALSE;
                saveCustomSetting(@"RestoreFS", 1);
                JUSTremovecheck = false;
                dispatch_async(dispatch_get_main_queue(), ^{
                        [self.buttontext setEnabled:YES];
                        [self.buttontext setTitle:localize(@"Jailbreak") forState:UIControlStateNormal];
                        [self.restoreFSSwitch setOn:false];
                        [self.loadTweakSwitch setEnabled:YES];
                        [self.loadTweakSwitch setOn:TRUE];
                    if (shouldLoadTweaks()) {
                        loadTweaks = true; }
                    else { loadTweaks = false; }

                    
                });
                
                goto end;
            } else {
                newTFcheckMyRemover4me = FALSE;
                saveCustomSetting(@"RestoreFS", 1);
                JUSTremovecheck = false;
                
                if (checkcheckRa1nmarker == 1) {
                    [self.buttontext setEnabled:YES];
                    [self.buttontext setTitle:localize(@"checkra1n/freya") forState:UIControlStateNormal];
                    [self.restoreFSSwitch setOn:false];
                    [self.loadTweakSwitch setEnabled:YES];
                    [self.loadTweakSwitch setOn:TRUE];
                } else if (flags & CS_PLATFORM_BINARY) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.buttontext setEnabled:NO];
                        [ViewController.sharedController.settingsButton setEnabled:NO];
                        [ViewController.sharedController.settingsButton setHidden:TRUE];
                        [ViewController.sharedController.settingsButton setHidden:YES];
                        [ViewController.sharedController.settingsButton setEnabled:NO];
                        [ViewController.sharedController.settings_buttun_bg setHidden:YES];
                        [self.buttontext setTitle:localize(@"checkra1n??") forState:UIControlStateNormal];
                        [self.restoreFSSwitch setOn:false];
                        [self.loadTweakSwitch setEnabled:YES];
                        [self.loadTweakSwitch setOn:TRUE]; });
                }
                goto end;
            }

    } else if(((checkjbdTmpRun == 0) && (checkpspawnhook == 0) && (checkth0rmarkerFinal == 1) && (checkuncovermarker == 0)) && (checkchimeramarker == 0) && (checkelectra == 0)){
        newTFcheckMyRemover4me = FALSE;
        [self.buttontext setEnabled:YES];
        if (shouldRestoreFS()) {
            JUSTremovecheck = true;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.buttontext setTitle:localize(@"Remove Freya?") forState:UIControlStateNormal];
                [self.fixfsswitch setOn:FALSE];
                [self.fixfsswitch setEnabled:NO];
                [self.restoreFSSwitch setOn:true];
                [self.loadTweakSwitch setEnabled:YES];
                [self.loadTweakSwitch setOn:TRUE]; });
        } else {
            JUSTremovecheck = false;
            if (checkcheckRa1nmarker == 0) {
                if (checkfsfixswitch == 1) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.buttontext setTitle:localize(@"fix fs?") forState:UIControlStateNormal];
                        [self.fixfsswitch setOn:TRUE];
                        [self.restoreFSSwitch setEnabled:NO];
                        [self.restoreFSSwitch setOn:false];
                        [self.loadTweakSwitch setEnabled:YES];
                        [self.loadTweakSwitch setOn:TRUE]; });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.buttontext setTitle:localize(@"Enable Freya?") forState:UIControlStateNormal];
                        [self.fixfsswitch setOn:FALSE];
                        [self.restoreFSSwitch setEnabled:YES];
                        [self.restoreFSSwitch setOn:false];
                        [self.loadTweakSwitch setEnabled:YES];
                        [self.loadTweakSwitch setOn:TRUE];
                    });
                }
            } else {
                if (checkfsfixswitch == 1) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.buttontext setTitle:localize(@"fix fs?") forState:UIControlStateNormal];
                        [self.fixfsswitch setOn:TRUE];
                        [self.restoreFSSwitch setEnabled:NO];
                        [self.restoreFSSwitch setOn:false];
                        [self.loadTweakSwitch setEnabled:YES];
                        [self.loadTweakSwitch setOn:TRUE];                    });
                } else {
                    [self.buttontext setTitle:localize(@"checkra1n & Freya?") forState:UIControlStateNormal];
                    [self.fixfsswitch setOn:FALSE];
                    [self.restoreFSSwitch setEnabled:YES];
                    [self.restoreFSSwitch setOn:false];
                    [self.loadTweakSwitch setEnabled:YES];
                    [self.loadTweakSwitch setOn:TRUE]; }
            }
        }
        newTFcheckofCyforce = FALSE;
        newTFcheckMyRemover4me = TRUE;
    }
 
    end:
err:
    if (back4romset == 1) {
        back4romset = 2; }
    printf("oof\n");
    //dispatch_async(dispatch_get_main_queue(), ^{ });
    [self wannaplaymusic];
    
}
+ (ViewController *)sharedController {
    return sharedController;
}
#pragma mark - Progress methods

- (void)addProgressViewyes:(CGRect)progressFrame {
//addProgressView:CGRectMake(10, 100, self.view.frame.size.width-20, 30)];

// Apply colors
//[self setProgressBgColor
 
    UIView *addProgressView = [[UIView alloc] initWithFrame:progressFrame];

    //Progress background view
    addProgressView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, addProgressView.frame.size.width-10, addProgressView.frame.size.height-10)];
    addProgressView.backgroundColor = [UIColor redColor];
    addProgressView.layer.cornerRadius = 4.0;

    //Progress animation view
    addProgressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, addProgressView.frame.size.height)];
    addProgressView.backgroundColor = [UIColor greenColor];
    addProgressView.layer.cornerRadius = 4.0;

   [addProgressView addSubview:addProgressView];
   [addProgressView addSubview:addProgressView];
   [self.view addSubview:addProgressView];
}

- (void)setPercentage:(int)percentage {

    [UIView animateWithDuration:1.0 animations:^{

        [self.jailbreakButtonBackground setFrame:CGRectMake(0,0,(self->_jailbreakButtonBackground.frame.size.width*percentage)/100,self->_jailbreakButtonBackground.frame.size.height)];

    } completion:^(BOOL finished) {
    }];
}

 - (void)setProgressBgColor:(UIColor *)color {
     [self->_buttontext setBackgroundColor:[UIColor blueColor]];

     self->_jailbreakButtonBackground.backgroundColor = [UIColor blackColor];
 }

 - (void)setProgressBarColor:(UIColor *)color {
         [self setProgressBarColor:[UIColor redColor]];
         self->_progressMeterUIVIEW.progressTintColor = [UIColor yellowColor];
                    
     //self->_jailbreakButtonBackground.backgroundColor = [UIColor greenColor];
 }


- (IBAction)sliceTwitterHandle:(id)sender {
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
void runOnMainQueueWithoutDeadlocking(void (^block)(void)) {
    if ([NSThread isMainThread]) { block(); }
    else { dispatch_sync(dispatch_get_main_queue(), block); }
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

void logSlice(const char *sliceOfText) {
    //Simple Log Function
    NSString *stringToLog = [NSString stringWithUTF8String:sliceOfText];
    LOG("%@", stringToLog);
}
- (void)updateStatus:(NSString*)statusNum {
    runOnMainQueueWithoutDeadlocking(^{
        [UIView transitionWithView:self.buttontext duration:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.buttontext setTitle:statusNum forState:UIControlStateNormal];
        } completion:nil]; });
}
- (void)kek {
    runOnMainQueueWithoutDeadlocking(^{
        [self.buttontext setTitle:[NSString stringWithFormat:@"Jailbroken"] forState:UIControlStateNormal]; });
}
bool restore_fs = false;
bool fix_fs = false;
bool loadTweaks = true;
bool setNonceBool = false;
int exploitType = 0;
int packagerType = 0;//0 = Cydia //1 = Zebra

void wannaSliceOfMe(void) { //Run The Exploit
    uint32_t flags;
    csops(getpid(), CS_OPS_STATUS, &flags, 0);
    int checkuncovermarker = (file_exists("/.installed_unc0ver"));
    int checkth0rmarkerFinal = (file_exists("/.freya_installed"));
    int checkchimeramarker = (file_exists("/.procursus_strapped"));
    int checkJBRemoverMarker = (file_exists("/var/mobile/Media/.bootstrapped_Th0r_remover"));
    int checkjbdTmpRun = (file_exists("/var/tmp/suckmyd.pid"));
    int checkpspawnhook = (file_exists("/var/run/pspawn_hook.ts"));
    int checkelectra = (file_exists("/.bootstrapped_electra"));

    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
    if ((checkjbdTmpRun == 1) && (checkpspawnhook == 1) && (checkth0rmarkerFinal == 1) && (checkuncovermarker == 0) && (checkelectra == 0) && (checkchimeramarker == 0) ){
        dispatch_async(dispatch_get_main_queue(), ^{
            [ViewController.sharedController.buttontext setHidden:NO];
            [ViewController.sharedController.buttontext setTitle:localize(@"𝓢Ⓗ⒜𝕽ᴱ F𝕽ᴱy⒜") forState:UIControlStateNormal];
            [ViewController.sharedController.uptimelabel setHidden:NO];
            [ViewController.sharedController.devicelabel setHidden:NO];
            [ViewController.sharedController.settingsButton setHidden:YES];
            [ViewController.sharedController.progressmeterView setHidden:YES];
            [ViewController.sharedController.progressMeterUIVIEW setHidden:YES];
            [ViewController.sharedController.settingsButton setEnabled:NO];
            [ViewController.sharedController.settings_buttun_bg setHidden:YES];
            [ViewController.sharedController.settings_buttun_bg setUserInteractionEnabled:NO];
            [ViewController.sharedController.thorbackgroundjpeg setHidden:NO];
        });
        [ViewController.sharedController shareTh0r];
        goto end;
    } else if ((checkjbdTmpRun == 1) && (checkth0rmarkerFinal == 1) && (checkuncovermarker == 0) && (checkelectra == 0) && (checkchimeramarker == 0)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ViewController.sharedController.buttontext setEnabled:YES];
            [ViewController.sharedController.settingsButton setHidden:YES];
            [ViewController.sharedController.settings_buttun_bg setHidden:YES];
            [ViewController.sharedController.settings_buttun_bg setUserInteractionEnabled:NO];
            [ViewController.sharedController.settingsButton setEnabled:NO];
            [ViewController.sharedController.buttontext setTitle:localize(@"𝓢Ⓗ⒜𝕽ᴱ F𝕽ᴱy⒜") forState:UIControlStateNormal];
            [ViewController.sharedController.uptimelabel setHidden:NO];
            [ViewController.sharedController.devicelabel setHidden:NO];
            [ViewController.sharedController.progressmeterView setHidden:YES];
            [ViewController.sharedController.progressMeterUIVIEW setHidden:YES];
            [ViewController.sharedController.thorbackgroundjpeg setHidden:NO];
        });
        [ViewController.sharedController shareTh0r];
        goto end;
    }else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ViewController.sharedController.settingsButton setHidden:YES];
            [ViewController.sharedController.settings_buttun_bg setHidden:YES];
            [ViewController.sharedController.settings_buttun_bg setUserInteractionEnabled:NO];
            [ViewController.sharedController.settingsButton setEnabled:NO];
        });
        runOnMainQueueWithoutDeadlocking(^{
            logSlice("Jailbreaking");});
        //0 = MachSwap //1 = MachSwap2 //2 = Voucher_Swap //3 = SockPuppet //4 = timewaste
       
        struct timeval begin, end;
        long whattimeisit = gettimeofday(&begin, 0);
        long seconds = end.tv_sec - begin.tv_sec;
        //printf("Time measured: %.2ld.\n", whattimeisit);
        //printf("Time measured sec: %.2ld.\n", seconds);
        runExploit(getExploitType());
        dothepatch();
       // progressMeterUIVIEW
        ourprogressMeter();
        offs_init();
        getOffsets();
        init_kexecute();
        yeasnapshot();
        remountFS(restore_fs);
        ourprogressMeter();
        createWorkingDir();
        saveOffs();
        ourprogressMeter();
        setHSP4();
        initInstall(getPackagerType());
        //post_exploit();
        ourprogressMeter();
        term_kexecute();
        ourprogressMeter();
        //int exploit
        loadinglaunchds("loading the ds");
        // Stop measuring time and calculate the elapsed time
        gettimeofday(&end, 0);
        seconds = end.tv_sec - begin.tv_sec;
        double elapsed = seconds ;//+ microseconds*1e-6;
        timespentelapsed = seconds;//elapsed;
        printf("Time in seconds: %.2ld \n", seconds);
        printf("Time elapsed seconds: %.2f \n", elapsed);

        while(wantstoviewlog == 0){
   // switch(wantxstoviewlog) {
     //   case 1: { finish(loadTweaks); continue;}
       // case 0: {
            if (wantstoviewlog == 1 ){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ViewController.sharedController.buttontext setTitle:@"Respringing" forState: normal];
                    respringing("yup");});
                finish(loadTweaks);
            } else {waittoviewlogOK("hello log");
                
                break;}
            //}
    //}
        }
        

        if (wantstoviewlog == 1 ){
            dispatch_async(dispatch_get_main_queue(), ^{
                [ViewController.sharedController.buttontext setTitle:@"Respringing" forState: normal];
                respringing("yup");});

            finish(loadTweaks);
        }
    }
end:
    printf("swell seeing you here\n");
}

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

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != 0) {
        UIApplication *app = [UIApplication sharedApplication];
        [app performSelector:@selector(suspend)];
        [NSThread sleepForTimeInterval:2.0];
        exit(0); }
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
            self.progressMeterUIVIEW.progress = theprogressis; }); }
}

-(void)findingoffsoutput{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_thebuttonsJBbackground.backgroundColor = [UIColor blackColor];
        [self->_buttontext setTitleColor:[UIColor whiteColor] forState: (normal)];
        self.progressMeterUIVIEW.progressTintColor = [UIColor yellowColor];

        
         //(UI_APPEARANCE_SELECTOR UIColor *):@"Finding Offsets" forState: normal]; });
        [self->_buttontext setTitle:@"Finding Offsets" forState: normal]; });
}

-(void)savedoffsoutput{
    dispatch_async(dispatch_get_main_queue(), ^{
    self->_thebuttonsJBbackground.backgroundColor = [UIColor blackColor];
        self.progressMeterUIVIEW.progressTintColor = [UIColor greenColor];

    [self->_buttontext setTitleColor:[UIColor greenColor] forState: (normal)];
        [self->_buttontext setTitle:@"Saved Offsets" forState: normal]; });

    //CGRectMake(10, 100, self.view.frame.size.width-20, 30);

}

-(void)wait4pad {
    int ut =0 ;
    while ((ut = 45 - uptime()) > 0 ) {
         //char msgme = [NSString stringWithFormat:localize(@"sec: %d" ), ut];
        //showThePopup(@"Wait you're too fast", @"I'm going to close the app, come back in @@ut", true, 0);
        NSString *msg1 = [NSString stringWithFormat:localize(@"Hold up you're too fast, I'm going to close the app. Please wait %ds before trying again"), ut];
        showMSG(msg1, 1, 1 );

        //showMSG(NSLocalizedString(@"so soon, closing app. come back in a few seconds.", nil ), 1, 1);
        printf("%d", ut);
        dispatch_sync( dispatch_get_main_queue(), ^{
            
            UIApplication *app = [UIApplication sharedApplication];
            [app performSelector:@selector(suspend)];
            //wait 2 seconds while app is going background
            [NSThread sleepForTimeInterval:1.0];
            //exit app when app is in background
            exit(0); }); }
    while ((ut = 49 - uptime()) > 0 ) {
        NSString *msg = [NSString stringWithFormat:localize(@"waiting %ds"), ut];
        dispatch_async(dispatch_get_main_queue(), ^{
            printf("please wait %d sec\n", ut);
            [self->_buttontext setTitle:localize(msg) forState: normal]; });
        sleep(1); }
}

-(void)wait4fun{
    int ut =0 ;
    while ((ut = 45 - uptime()) > 0 ) {
         //char msgme = [NSString stringWithFormat:localize(@"sec: %d" ), ut];
        NSString *msg1 = [NSString stringWithFormat:localize(@"Hold up you're too fast, I'm going to close the app. Please wait %ds before trying again"), ut];
        showMSG(msg1, 1, 1 );
        printf("%d", ut);
        dispatch_sync( dispatch_get_main_queue(), ^{
            
            UIApplication *app = [UIApplication sharedApplication];
            [app performSelector:@selector(suspend)];
            //wait 2 seconds while app is going background
            [NSThread sleepForTimeInterval:1.0];
            //exit app when app is in background
            exit(0); }); }
    while ((ut = 49 - uptime()) > 0 ) {
        NSString *msg = [NSString stringWithFormat:localize(@"waiting %ds"), ut];
        dispatch_async(dispatch_get_main_queue(), ^{
            printf("please wait %d sec\n", ut);
            [self->_buttontext setTitle:localize(msg) forState: normal]; });
        sleep(1); }
}

-(void)sploitn{
    dispatch_async(dispatch_get_main_queue(), ^{
        //CGRectMake(10, 100, self.view.frame.size.width-20, 30);
        //[self->_buttontext setBackgroundColor:[UIColor redColor]];
        self->_thebuttonsJBbackground.backgroundColor = [UIColor blackColor];
        [self->_buttontext setTitleColor:[UIColor blueColor] forState: (normal)];
        self.progressMeterUIVIEW.progressTintColor = [UIColor blueColor];

        [self->_buttontext setTitle:@"exploiting" forState: normal]; });
}
-(void)sploitnfailed{
    dispatch_async(dispatch_get_main_queue(), ^{
        //CGRectMake(10, 100, self.view.frame.size.width-20, 30);
        //[self->_buttontext setBackgroundColor:[UIColor redColor]];
        self->_thebuttonsJBbackground.backgroundColor = [UIColor blackColor];
        [self->_buttontext setTitleColor:[UIColor redColor] forState: (normal)];
         //(UIColor blackColor) forState:normal]; //WithColor:[UIColor blackColor]];
        self.progressMeterUIVIEW.progressTintColor = [UIColor redColor];

        [self->_buttontext setTitle:@"sploit failed" forState: normal]; });
}

-(void)patchnshit{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_thebuttonsJBbackground.backgroundColor = [UIColor blueColor]; //CGRectMake(10, 100, self.view.frame.size.width-20, 30);
        [self->_buttontext setTitleColor:[UIColor whiteColor] forState: (normal)];
        self.progressMeterUIVIEW.progressTintColor = [UIColor redColor];

        [self->_buttontext setTitle:@"patching" forState: normal]; });
}
-(void)remountsnap{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_thebuttonsJBbackground.backgroundColor = [UIColor blackColor]; //CGRectMake(10, 100, self.view.frame.size.width-20, 30);
        self.progressMeterUIVIEW.progressTintColor = [UIColor redColor];

        [self->_buttontext setTitleColor:[UIColor redColor] forState: (normal)];

        [self->_buttontext setTitle:@"remounting" forState: normal]; });
}
-(void)amfidjbdextract{
    runOnMainQueueWithoutDeadlocking(^{
        self->_thebuttonsJBbackground.backgroundColor = [UIColor blackColor]; //CGRectMake(10, 100, self.view.frame.size.width-20, 30);
        [self->_buttontext setTitleColor:[UIColor whiteColor] forState: (normal)];
        self.progressMeterUIVIEW.progressTintColor = [UIColor yellowColor];

        [self.buttontext setTitle:[NSString stringWithFormat:@"Amfid patch"] forState:UIControlStateNormal]; });
}
-(void)updatingthejbbuttonlabel{
    runOnMainQueueWithoutDeadlocking(^{
        self->_thebuttonsJBbackground.backgroundColor = [UIColor blackColor]; //CGRectMake(10, 100, self.view.frame.size.width-20, 30);
        [self->_buttontext setTitleColor:[UIColor blueColor] forState: (normal)];
        self.progressMeterUIVIEW.progressTintColor = [UIColor blueColor];

        [self.buttontext setTitle:[NSString stringWithFormat:@"extracting strap"] forState:UIControlStateNormal]; });
}
-(void)cydiafinish{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_thebuttonsJBbackground.backgroundColor = [UIColor blackColor]; //CGRectMake(10, 100, self.view.frame.size.width-20, 30);
        [self->_buttontext setTitleColor:[UIColor greenColor] forState: (normal)];
        self.progressMeterUIVIEW.progressTintColor = [UIColor yellowColor];

        [self->_buttontext setTitle:@"cydia done" forState: normal]; });
}
-(void)installingDs{
    runOnMainQueueWithoutDeadlocking(^{
        self->_thebuttonsJBbackground.backgroundColor = [UIColor blueColor]; //CGRectMake(10, 100, self.view.frame.size.width-20, 30);
        [self->_buttontext setTitleColor:[UIColor whiteColor] forState: (normal)];
        self.progressMeterUIVIEW.progressTintColor = [UIColor greenColor];

        [self.buttontext setTitle:[NSString stringWithFormat:@"installing debs"] forState:UIControlStateNormal]; });
}
-(void)respring{
    runOnMainQueueWithoutDeadlocking(^{
        self->_thebuttonsJBbackground.backgroundColor = [UIColor greenColor]; //CGRectMake(10, 100, self.view.frame.size.width-20, 30);
        [self->_buttontext setTitleColor:[UIColor blueColor] forState: (normal)];
        self.progressMeterUIVIEW.progressTintColor = [UIColor blueColor];

        [self.buttontext setTitle:[NSString stringWithFormat:@"respringing"] forState:UIControlStateNormal]; });
}
-(void)thecacheofcaching{
    runOnMainQueueWithoutDeadlocking(^{
        self->_thebuttonsJBbackground.backgroundColor = [UIColor blueColor]; //CGRectMake(10, 100, self.view.frame.size.width-20, 30);
        [self->_buttontext setTitleColor:[UIColor greenColor] forState: (normal)];
        self.progressMeterUIVIEW.progressTintColor = [UIColor greenColor];

        [self.buttontext setTitle:[NSString stringWithFormat:@"uicache"] forState:UIControlStateNormal]; });
}
-(void)launchdsareloading{
    runOnMainQueueWithoutDeadlocking(^{
        self->_thebuttonsJBbackground.backgroundColor = [UIColor blackColor]; //CGRectMake(10, 100, self.view.frame.size.width-20, 30);
        [self->_buttontext setTitleColor:[UIColor redColor] forState: (normal)];
        self.progressMeterUIVIEW.progressTintColor = [UIColor redColor];

        [self.buttontext setTitle:[NSString stringWithFormat:@"loading daemons"] forState:UIControlStateNormal]; });
}

-(void)RunningTheD{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_thebuttonsJBbackground.backgroundColor = [UIColor blueColor]; //CGRectMake(10, 100, self.view.frame.size.width-20, 30);
        [self->_buttontext setTitleColor:[UIColor whiteColor] forState: (normal)];
        self.progressMeterUIVIEW.progressTintColor = [UIColor orangeColor];

        [self->_buttontext setTitle:@"jbd waiting..." forState: normal]; });
}

-(void)spotlessclean{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_thebuttonsJBbackground.backgroundColor = [UIColor blackColor]; //CGRectMake(10, 100, self.view.frame.size.width-20, 30);
        [self->_buttontext setTitleColor:[UIColor yellowColor] forState: (normal)];
        self.progressMeterUIVIEW.progressTintColor = [UIColor greenColor];

        [self->_buttontext setTitle:@"spotless..." forState: normal]; });
}

-(void)ohsnapnofail{
    showMSG(NSLocalizedString(@"Exploit Failed but just open the app when it closes and try again, as long as it didn't already kernel panic you can keep trying.", nil), 1, 1);
    dispatch_sync( dispatch_get_main_queue(), ^{
        UIApplication *app = [UIApplication sharedApplication];
        [app performSelector:@selector(suspend)];
        //wait 2 seconds while app is going background
        [NSThread sleepForTimeInterval:1.0];
        //exit app when app is in background
        exit(0); });
}
-(void)showwaitlogOKA {
    dispatch_sync( dispatch_get_main_queue(), ^{
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Freya finished:"
                                                        message:@"Would you like to view the log or Respring now......"
                                                       delegate:self
                                              cancelButtonTitle:@"View log"
                                              otherButtonTitles:@"Respring", nil];

        [alert show];});
}


-(void)showwaittoviewlogOKA {
    dispatch_sync( dispatch_get_main_queue(), ^{
        NSString *msg1;
        //timespentelapsed
       // NSString stringWithFormat:localize(@"I'm using Freya %@, to jailbreak my %@ iOS %@.\nUpdated %s. By:@%@ 🍻.\nDownload @ %s" ), freyaversion;
        if ( justinstalledcydia == 0) {
            msg1 = [NSString stringWithFormat:localize(@"Enabled jailbreak in %2ld seconds.\nWould you like to respring now or view the log window?"), timespentelapsed];
        } else {
            msg1 = [NSString stringWithFormat:localize(@"Jailbreak successfully installed cydia and completed in %2ld seconds.\nWould you like to respring now or view the log window?"), timespentelapsed];
        }
        //showMSG(msg1, 1, 1 );
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Freya Jailbreak", nil) message:msg1 preferredStyle:UIAlertControllerStyleAlert];
       // UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Freya Jailbreak donzo", nil) message:NSLocalizedString(@"respring NOW or view log", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *OK = [UIAlertAction actionWithTitle:NSLocalizedString(@"Respring", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [ViewController.sharedController.buttontext setTitle:@"Respringing" forState: normal];

                [self.buttontext setEnabled:NO];
                [self.buttontext setHidden:NO];
                //[self->_buttontext setTitle:@"Respringing..." forState: normal];
                respringing("yup");
            });
            wantstoviewlog = 1;
            finish(loadTweaks);

        }];
        UIAlertAction *Cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"View log", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //[self->_buttontext setTitle:@"Respring?" forState: normal];
                [ViewController.sharedController.buttontext setTitle:@"Respring?" forState: normal];

                [self.buttontext setEnabled:YES];
                [self.buttontext setHidden:NO];
                
            });
            wantstoviewlog = 2;
        }];
        [alertController addAction:OK];
        [alertController addAction:Cancel];
        [alertController setPreferredAction:Cancel];
        [self presentViewController:alertController animated:YES completion:nil];
        });
    
    
}

-(void)showwaitOTA {
    dispatch_sync( dispatch_get_main_queue(), ^{
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"OTA MOUNTED:"
                                                        message:@"The OTA update files is present on the device. I'll remove it now, then force your device to reboot. Try again after the device reboots. Please wait and don't close the app, this can take a minute......"
                                                       delegate:self
                                              cancelButtonTitle: nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];});
}
-(void)jbremoving{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_thebuttonsJBbackground.backgroundColor = [UIColor blackColor]; //CGRectMake(10, 100, self.view.frame.size.width-20, 30);
        [self->_buttontext setTitleColor:[UIColor blueColor] forState: (normal)];
        self.progressMeterUIVIEW.progressTintColor = [UIColor greenColor];

        [self->_buttontext setTitle:@"Cleaning files..." forState: normal]; });
}
-(void)TheDstarted{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_thebuttonsJBbackground.backgroundColor = [UIColor blackColor]; //CGRectMake(10, 100, self.view.frame.size.width-20, 30);
        [self->_buttontext setTitleColor:[UIColor greenColor] forState: (normal)];
        self.progressMeterUIVIEW.progressTintColor = [UIColor purpleColor];
        [self->_buttontext setTitle:@"jbd started..." forState: normal]; });
}
bool pressedJBbut;
- (IBAction)jailbreak:(id)sender {
    if (wantstoviewlog >=1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ViewController.sharedController.buttontext setTitle:@"Respringing" forState: normal];
            respringing("yup");});
        finish(loadTweaks);
        wantstoviewlog = 0;
    } else {
        pressedJBbut = true;
        back4romset = 2;
        if (shouldRestoreFS()) { restore_fs = true; } else { restore_fs = false; }
        if (shouldfixFS()) { fix_fs = true; } else { fix_fs = false; }
        if (shouldLoadTweaks()) { loadTweaks = true; } else { loadTweaks = false; }
        [sender setEnabled:false];//Disable The Button
        //Disable and fade out the settings button
        [[self fixfsswitch] setHidden:true];
        [[self loadTweakSwitch] setHidden:true];
        [[self forceuisswizitch] setHidden:true];
        [[self restoreFSSwitch] setHidden:true];
        [UIView animateWithDuration:1.0f animations:^{ [[self settingsButton] setEnabled:false]; }];
        ourprogressMeter();
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
            wannaSliceOfMe(); });
    }
end:
    printf("finally we done!");
    //Run the exploit in a void.
}
- (IBAction)fixfsswitch:(id)sender { }
- (IBAction)forceuisswizitch:(id)sender { }



@end
void log_toView(const char *text) {
    dispatch_sync( dispatch_get_main_queue(), ^{
        [[sharedController textView] insertText:[NSString stringWithUTF8String:text]];
        [[sharedController textView] scrollRangeToVisible:NSMakeRange([sharedController textView].text.length, 1)]; });
}

void extractamfidjbdstuff(char *msg){ [[ViewController currentViewController] amfidjbdextract]; }
void thelabelbtnchange(char *msg){ [[ViewController currentViewController] updatingthejbbuttonlabel]; }
void cydiaDone(char *msg){ [[ViewController currentViewController] cydiafinish]; }
void startingJBD(char *msg){ [[ViewController currentViewController] RunningTheD]; }
void waitOTAOK(char *msg) { [[ViewController currentViewController] showwaitOTA]; }
void waittoviewlogOK(bool yuppwewaiting) { [[ViewController currentViewController] showwaittoviewlogOKA]; }


void jbdfinished(char *msg){ [[ViewController currentViewController] TheDstarted]; }
void uicaching(char *msg){ [[ViewController currentViewController] thecacheofcaching]; }
void respringing(char *msg){ [[ViewController currentViewController] respring]; }
void loadinglaunchds(char *msg){ [[ViewController currentViewController] launchdsareloading]; }
void ourprogressMeter(void){ [[ViewController currentViewController] ourprogressMeterjeez]; }
void savedoffs() { [[ViewController currentViewController] savedoffsoutput]; }
void findoffs() { [[ViewController currentViewController] findingoffsoutput]; }
void dothesploit() { [[ViewController currentViewController] sploitn]; }
void failedsploit() { [[ViewController currentViewController] sploitnfailed]; }
void juswaitn() { [[ViewController currentViewController] wait4fun]; }

void juswaitn4pad() { [[ViewController currentViewController] wait4pad]; }
void yeasnapshot() { [[ViewController currentViewController] remountsnap]; }
void dothepatch() { [[ViewController currentViewController] patchnshit]; }
void debsinstalling() { [[ViewController currentViewController] installingDs]; }
void removethejb() { [[ViewController currentViewController] jbremoving]; }
void spotless() { [[ViewController currentViewController] spotlessclean]; }
void youknowtryagain() { [[ViewController currentViewController] ohsnapnofail]; }
