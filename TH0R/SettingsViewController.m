//
//  SettingsViewViewController.m


#import "SettingsViewController.h"
#import "ViewController.h"
#import "utils/utilsZS.h"
#include "cs_blob.h"
#include "file_utils.h"
#include "offsets.h"
#include <sys/sysctl.h>

#define localize(key) NSLocalizedString(key, @"")
#define postProgress(prg) [[NSNotificationCenter defaultCenter] postNotificationName: @"JB" object:nil userInfo:@{@"JBProgress": prg}]

@interface SettingsViewController ()

@end

char *sysctlWithNameS(const char *name) {
    kern_return_t kr = KERN_FAILURE;
    char *ret = NULL;
    size_t *size = NULL;
    size = (size_t *)malloc(sizeof(size_t));
    if (size == NULL) goto out;
    bzero(size, sizeof(size_t));
    if (sysctlbyname(name, NULL, size, NULL, 0) != ERR_SUCCESS) goto out;
    ret = (char *)malloc(*size);
    if (ret == NULL) goto out;
    bzero(ret, *size);
    if (sysctlbyname(name, ret, size, NULL, 0) != ERR_SUCCESS) goto out;
    kr = KERN_SUCCESS;
    out:
    if (kr == KERN_FAILURE)
    {
        free(ret);
        ret = NULL;
    }
    free(size);
    size = NULL;
    return ret;
}


NSString *getKernelBuildVersionS() {
    NSString *kernelBuild = nil;
    NSString *cleanString = nil;
    char *kernelVersion = NULL;
    kernelVersion = sysctlWithNameS("kern.version");
    if (kernelVersion == NULL) return nil;
    cleanString = [NSString stringWithUTF8String:kernelVersion];
    free(kernelVersion);
    kernelVersion = NULL;
    cleanString = [[cleanString componentsSeparatedByString:@"; "] objectAtIndex:1];
    cleanString = [[cleanString componentsSeparatedByString:@"-"] objectAtIndex:1];
    cleanString = [[cleanString componentsSeparatedByString:@"/"] objectAtIndex:0];
    kernelBuild = [cleanString copy];
    return kernelBuild;
}

@implementation SettingsViewController

- (IBAction)setthenoncewith:(id)sender {
    [self.noncesettertxtfeild setValue:@"0x1111111111111111" forKey:@"Nonce"];
}

- (IBAction)jbbutton:(id)sender {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    #define CS_OPS_STATUS       0   /* return status */
    uint32_t flags;
    csops(getpid(), CS_OPS_STATUS, &flags, 0);
    int checkcheckRa1nmarker2 = (file_exists("/.bootstrapped"));
    int checkuncovermarker = (file_exists("/.installed_unc0ver"));
    int checkth0rmarkerFinal = (file_exists("/.freya_installed"));
    int checkchimeramarker = (file_exists("/.procursus_strapped"));
    printf("Uncover marker exists?: %d\n",checkuncovermarker);
    printf("Th0r final marker exists?: %d\n",checkth0rmarkerFinal);
    printf("Chimera marker exists?: %d\n",checkchimeramarker);
    
    CAGradientLayer *gradient = [CAGradientLayer layer];

    gradient.frame = self.backGroundView.bounds;
    //gradient.colors = @[(id)[[UIColor colorWithRed:0.26 green:0.81 blue:0.64 alpha:1.0] CGColor], (id)[[UIColor colorWithRed:0.09 green:0.35 blue:0.62 alpha:1.0] CGColor]];
    gradient.colors = @[(id)[[UIColor colorWithRed:0.02 green:0.02 blue:0.02 alpha:1.0] CGColor], (id)[[UIColor colorWithRed:0.29 green:0.05 blue:0.22 alpha:1.0] CGColor]];
    [self.backGroundView.layer insertSublayer:gradient atIndex:0];
    [self.settingsGradientView.layer insertSublayer:gradient atIndex:0];
    if (shouldLoadTweaks())
    {
        [_loadTweaksSwitch setOn:true];
    } else {
        [_loadTweaksSwitch setOn:false];
    }
    if (checkth0rmarkerFinal == 1) {
        
        if (checkfsfixswitch == 1) {
            [self.fixfsswitch setOn:TRUE];
            [self.fixfsswitch setHidden:NO];
            [self.fixfsswitch setEnabled:YES];
            [self.fixfsswitch setUserInteractionEnabled:YES];

        } else {
            [self.fixfsswitch setOn:FALSE];
            [self.fixfsswitch setHidden:NO];
            [self.fixfsswitch setEnabled:YES];
            [self.fixfsswitch setUserInteractionEnabled:YES];

        }
    } else {
        [self.fixfsswitch setOn:FALSE];
        [self.fixfsswitch setHidden:YES];
        [self.fixfsswitch setEnabled:NO];
        [self.fixfsswitch setUserInteractionEnabled:NO];

    }
    //0 = Cydia
    //1 = Zebra
   /* if (getPackagerType() == 0)
    {*/
    
        [_Cydia_Outlet sendActionsForControlEvents:UIControlEventTouchUpInside];
   /* } else if (getPackagerType() == 1)
    {
        [_Zebra_Outlet sendActionsForControlEvents:UIControlEventTouchUpInside];
    } else if (getPackagerType() == 2)
    {
        [_Sileo_Outlet sendActionsForControlEvents:UIControlEventTouchUpInside];
    }*/
    
    [self.setnoncebtn setEnabled:FALSE];
    [self.setnoncebtn setHidden:TRUE];

    //0 = MS
    //1 = MS2
    //2 = VS
    //3 = SP
    //4 = TW
    /*
     * 12.0     1556.00
     * 12.1     1560.10
     * 12.2     1570.15
     * 12.3     1575.13
     * 12.4     1575.17
     * 12.5     1575.23
     * 13.0     1665.15
     * 13.1     1671.101
     * 13.2     1673.126
     * 13.3     1674.102
     * 13.4     1675.129
     * 13.5     1676.104
     * 14.0     1751.108
     * 14.1     1751.108
     * 14.2     1770.106
     */
     NSString *minKernelBuildVersion = nil;
     NSString *maxKernelBuildVersion = nil;

    
    UIColor *grey = [UIColor colorWithRed:0.30 green:0.00 blue:0.30 alpha:0.5];;
    double whatsmykoreNUMBER = kCFCoreFoundationVersionNumber;
    printf("whatsmykoreNUMBER: %f\n", whatsmykoreNUMBER);
    if (kCFCoreFoundationVersionNumber > 1575.17) { // > 12.4 //1556.00 12.0
        
        _MS1_OUTLET.userInteractionEnabled = FALSE;
        _MS1_OUTLET.enabled = false;
        _MS1_OUTLET.backgroundColor = grey;
        _VS_Outlet.userInteractionEnabled = FALSE;
        _VS_Outlet.enabled = false;
        _VS_Outlet.backgroundColor = grey;
        _MS2_Outlet.userInteractionEnabled = FALSE;
        _MS2_Outlet.enabled = false;
        _MS2_Outlet.backgroundColor = grey;
        _SP_Outlet.userInteractionEnabled = FALSE;
        _SP_Outlet.enabled = false;
        _SP_Outlet.backgroundColor = grey;
        _TWOutlet.userInteractionEnabled = TRUE;
        _TWOutlet.enabled = true;
        _TWOutlet.backgroundColor = grey;
    } else if (kCFCoreFoundationVersionNumber == 1575.17) { //12.4
        _MS1_OUTLET.userInteractionEnabled = FALSE;
        _MS1_OUTLET.enabled = false;
        _MS1_OUTLET.backgroundColor = grey;
        _VS_Outlet.userInteractionEnabled = FALSE;
        _VS_Outlet.enabled = false;
        _VS_Outlet.backgroundColor = grey;
        _MS2_Outlet.userInteractionEnabled = FALSE;
        _MS2_Outlet.enabled = false;
        _MS2_Outlet.backgroundColor = grey;
        _SP_Outlet.userInteractionEnabled = TRUE;
        _SP_Outlet.enabled = true;
        _SP_Outlet.backgroundColor = grey;
        _TWOutlet.userInteractionEnabled = TRUE;
        _TWOutlet.enabled = true;
        _TWOutlet.backgroundColor = grey;

    } else if (kCFCoreFoundationVersionNumber == 1570.15) { //12.2
        _MS1_OUTLET.userInteractionEnabled = FALSE;
        _MS1_OUTLET.enabled = false;
        _MS1_OUTLET.backgroundColor = grey;
        _VS_Outlet.userInteractionEnabled = FALSE;
        _VS_Outlet.enabled = false;
        _VS_Outlet.backgroundColor = grey;
        _MS2_Outlet.userInteractionEnabled = FALSE;
        _MS2_Outlet.enabled = false;
        _MS2_Outlet.backgroundColor = grey;
        _SP_Outlet.userInteractionEnabled = TRUE;
        _SP_Outlet.enabled = true;
        _SP_Outlet.backgroundColor = grey;
        _TWOutlet.userInteractionEnabled = TRUE;
        _TWOutlet.enabled = true;
        _TWOutlet.backgroundColor = grey;

    } else if (kCFCoreFoundationVersionNumber >= 1570.13) { //12.3
        _MS1_OUTLET.userInteractionEnabled = FALSE;
        _MS1_OUTLET.enabled = false;
        _MS1_OUTLET.backgroundColor = grey;
        _VS_Outlet.userInteractionEnabled = FALSE;
        _VS_Outlet.enabled = false;
        _VS_Outlet.backgroundColor = grey;
        _MS2_Outlet.userInteractionEnabled = FALSE;
        _MS2_Outlet.enabled = false;
        _MS2_Outlet.backgroundColor = grey;
        _SP_Outlet.userInteractionEnabled = FALSE;
        _SP_Outlet.enabled = false;
        _SP_Outlet.backgroundColor = grey;
        _TWOutlet.userInteractionEnabled = TRUE;
        _TWOutlet.enabled = true;
        _TWOutlet.backgroundColor = grey;

    } else if (kCFCoreFoundationVersionNumber >= 1561.00) { //12.1.4 // 12.1.3 = 1561.
        
        minKernelBuildVersion = @"4397.0.0.2.4~1";
        maxKernelBuildVersion = @"4903.240.8~8";
                //            maxKernelBuildVersion = @"4903.232.2~1";// <- ios 12.1.1/2?  -- -- @"4903.240.8~8";
        

        if (minKernelBuildVersion != nil && maxKernelBuildVersion != nil) {
            NSString *kernelBuildVersion = getKernelBuildVersionS();
            if (kernelBuildVersion != nil) {
                if ([kernelBuildVersion compare:minKernelBuildVersion options:NSNumericSearch] != NSOrderedAscending && [kernelBuildVersion compare:maxKernelBuildVersion options:NSNumericSearch] != NSOrderedDescending) {
                  //  return true;
                    _MS1_OUTLET.userInteractionEnabled = TRUE;
                    _MS1_OUTLET.enabled = true;
                    _MS1_OUTLET.backgroundColor = grey;
                    _VS_Outlet.userInteractionEnabled = TRUE;
                    _VS_Outlet.enabled = true;
                    _VS_Outlet.backgroundColor = grey;
                    _MS2_Outlet.userInteractionEnabled = TRUE;
                    _MS2_Outlet.enabled = true;
                    _MS2_Outlet.backgroundColor = grey;
                    _SP_Outlet.userInteractionEnabled = TRUE;
                    _SP_Outlet.enabled = true;
                    _SP_Outlet.backgroundColor = grey;

                    _TWOutlet.userInteractionEnabled = TRUE;
                    _TWOutlet.enabled = true;
                    _TWOutlet.backgroundColor = grey;
                }
            }
        } else {
        
        _MS1_OUTLET.userInteractionEnabled = FALSE;
        _MS1_OUTLET.enabled = false;
        _MS1_OUTLET.backgroundColor = grey;
        _VS_Outlet.userInteractionEnabled = FALSE;
        _VS_Outlet.enabled = false;
        _VS_Outlet.backgroundColor = grey;
        _MS2_Outlet.userInteractionEnabled = FALSE;
        _MS2_Outlet.enabled = false;
        _MS2_Outlet.backgroundColor = grey;
        _SP_Outlet.userInteractionEnabled = TRUE;
        _SP_Outlet.enabled = true;
        _SP_Outlet.backgroundColor = grey;

        _TWOutlet.userInteractionEnabled = TRUE;
        _TWOutlet.enabled = true;
        _TWOutlet.backgroundColor = grey;
        }
    } else { //12.0
        _MS1_OUTLET.userInteractionEnabled = TRUE;
        _MS1_OUTLET.enabled = true;
        _MS1_OUTLET.backgroundColor = grey;
        _VS_Outlet.userInteractionEnabled = TRUE;
        _VS_Outlet.enabled = true;
        _VS_Outlet.backgroundColor = grey;
        _MS2_Outlet.userInteractionEnabled = TRUE;
        _MS2_Outlet.enabled = true;
        _MS2_Outlet.backgroundColor = grey;
        _SP_Outlet.userInteractionEnabled = TRUE;
        _SP_Outlet.enabled = true;
        _SP_Outlet.backgroundColor = grey;

        _TWOutlet.userInteractionEnabled = TRUE;
        _TWOutlet.enabled = true;
        _TWOutlet.backgroundColor = grey;

    }
    
    
    
    if (getExploitType() == 0)
    {
        [_MS1_OUTLET sendActionsForControlEvents:UIControlEventTouchUpInside];
    } else if (getExploitType() == 1)
    {
        [_MS2_Outlet sendActionsForControlEvents:UIControlEventTouchUpInside];
    } else if (getExploitType() == 2)
    {
        [_VS_Outlet sendActionsForControlEvents:UIControlEventTouchUpInside];
    } else if (getExploitType() == 3)
    {
        [_SP_Outlet sendActionsForControlEvents:UIControlEventTouchUpInside];
    } else if (getExploitType() == 4)
    {
        [_TWOutlet sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
    

    if ((checkuncovermarker == 0) && (checkchimeramarker == 1) && (checkth0rmarkerFinal == 0)){
        [ViewController.sharedController.buttontext setTitle:localize(@"Remove Chimera?") forState:UIControlStateNormal];
        newTFcheckMyRemover4me = TRUE;
        JUSTremovecheck = true;
        saveCustomSetting(@"RestoreFS", 0);
        [_loadTweaksSwitch setEnabled:NO];
        [_loadTweaksSwitch setOn:TRUE];
        [_restoreFSSwitch setOn:true];

        [_loadTweaksSwitch setUserInteractionEnabled:NO];
        [_restoreFSSwitch setEnabled:NO];
        [_restoreFSSwitch setUserInteractionEnabled:NO];
        [ViewController.sharedController.restoreFSSwitch setEnabled:NO];
        [ViewController.sharedController.restoreFSSwitch setUserInteractionEnabled:NO];
        //    goto end;
    } else if ((checkuncovermarker == 1) && (checkchimeramarker == 0) && (checkth0rmarkerFinal == 0)){
        [ViewController.sharedController.buttontext setTitle:localize(@"Remove u0?") forState:UIControlStateNormal];
        newTFcheckMyRemover4me = TRUE;
        JUSTremovecheck = true;
        saveCustomSetting(@"RestoreFS", 0);
        [_loadTweaksSwitch setEnabled:NO];
        [_loadTweaksSwitch setOn:TRUE];
        [_restoreFSSwitch setOn:true];
        [_loadTweaksSwitch setUserInteractionEnabled:NO];
        [_restoreFSSwitch setEnabled:NO];
        [_restoreFSSwitch setUserInteractionEnabled:NO];
        [ViewController.sharedController.restoreFSSwitch setEnabled:NO];
        [ViewController.sharedController.restoreFSSwitch setUserInteractionEnabled:NO];
        //    goto end;
    } else if ((checkth0rmarkerFinal == 1) && (checkuncovermarker == 0) && (checkchimeramarker == 0)) {
        if (shouldRestoreFS())
        {
            JUSTremovecheck = true;
            dispatch_async(dispatch_get_main_queue(), ^{
                [ViewController.sharedController.buttontext setTitle:localize(@"Remove Freya?") forState:UIControlStateNormal];
                [self.fixfsswitch setOn:FALSE];
                [self.fixfsswitch setHidden:YES];
                [self.fixfsswitch setEnabled:NO];
                [self.fixfsswitch setUserInteractionEnabled:NO];
                [self.restoreFSSwitch setHidden:NO];
                [self.restoreFSSwitch setEnabled:YES];
                [self.restoreFSSwitch setOn:TRUE];
                [self.restoreFSSwitch setUserInteractionEnabled:YES];
                [self.setnoncebtn setEnabled:FALSE];
                [self.setnoncebtn setHidden:TRUE];
            });
        } else {
            
            JUSTremovecheck = false;
            if (checkfsfixswitch == 1) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                         [ViewController.sharedController.buttontext setTitle:localize(@"Fix FS?") forState:UIControlStateNormal];
                        [self.fixfsswitch setOn:TRUE];
                        [self.restoreFSSwitch setOn:FALSE];
                        [self.restoreFSSwitch setHidden:YES];
                        [self.restoreFSSwitch setEnabled:NO];
                        [self.restoreFSSwitch setUserInteractionEnabled:NO];
                        [self.setnoncebtn setEnabled:TRUE];
                        [self.setnoncebtn setHidden:FALSE];
                        [ViewController.sharedController.loadTweakSwitch setEnabled:YES];
                        [ViewController.sharedController.loadTweakSwitch setOn:TRUE];
                     });
            } else {
                if (checkcheckRa1nmarker2 == 0) {

                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ViewController.sharedController.buttontext setTitle:localize(@"Enable Freya?") forState:UIControlStateNormal];
                        [self.fixfsswitch setOn:FALSE];
                        
                        [self.restoreFSSwitch setEnabled:YES];
                        [self.restoreFSSwitch setOn:FALSE];
                        [self.restoreFSSwitch setHidden:NO];
                        [self.restoreFSSwitch setEnabled:YES];
                        [self.restoreFSSwitch setUserInteractionEnabled:YES];

                        [self.setnoncebtn setEnabled:TRUE];
                        [self.setnoncebtn setHidden:FALSE];
                        [ViewController.sharedController.loadTweakSwitch setEnabled:YES];
                        [ViewController.sharedController.loadTweakSwitch setOn:TRUE];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ViewController.sharedController.buttontext setTitle:localize(@"checkra1n & Freya?") forState:UIControlStateNormal];
                        [self.fixfsswitch setOn:FALSE];
                        [self.fixfsswitch setUserInteractionEnabled:YES];

                        [self.restoreFSSwitch setEnabled:YES];
                        [self.restoreFSSwitch setOn:FALSE];
                        [self.restoreFSSwitch setHidden:NO];
                        [self.restoreFSSwitch setEnabled:YES];
                        [self.restoreFSSwitch setUserInteractionEnabled:YES];
                        [self.setnoncebtn setEnabled:TRUE];
                        [self.setnoncebtn setHidden:FALSE];
                        [ViewController.sharedController.loadTweakSwitch setEnabled:YES];
                        [ViewController.sharedController.loadTweakSwitch setOn:TRUE];
                    });
                }
            }
        }
    }else {
            if (shouldRestoreFS())
            {
                JUSTremovecheck = true;
                [_restoreFSSwitch setOn:true];
                
            } else {
                JUSTremovecheck = false;
                [_restoreFSSwitch setOn:false];
            }
        }
        
    if (isRootless())
    {
        [_rootless_Switch sendActionsForControlEvents:UIControlEventTouchUpInside];
    } else {
        [_rooted_Switch sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
   /* if (shouldfixFS()) {
        checkfsfixswitch = 1;
        [_fixfsswitch setOn:true];
    } else {
        checkfsfixswitch = 0;
        [_fixfsswitch setOn:false];
    }*/
}


- (void)viewDidAppear:(BOOL)animated{
    
    CAGradientLayer *gradient2 = [CAGradientLayer layer];

    gradient2.frame = self.settingsGradientView.bounds;
    gradient2.colors = @[(id)[[UIColor colorWithRed:0.49 green:0.43 blue:0.84 alpha:1.0] CGColor], (id)[[UIColor colorWithRed:0.36 green:0.64 blue:0.80 alpha:1.0] CGColor]];

    [UIView animateWithDuration:1.0f animations:^{

        [self.settingsGradientView setAlpha:1.0];
        [self.settingsGradientView.layer insertSublayer:gradient2 atIndex:0];

    }];
    
    
    }

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self setGradient];
}

-(void)setGradient {
    CAGradientLayer *gradient2 = [CAGradientLayer layer];
    
    gradient2.frame = self.settingsGradientView.bounds;
    gradient2.colors = @[(id)[[UIColor colorWithRed:0.49 green:0.43 blue:0.84 alpha:1.0] CGColor], (id)[[UIColor colorWithRed:0.36 green:0.64 blue:0.80 alpha:1.0] CGColor]];
    
    [UIView animateWithDuration:1.0f animations:^{
        
        [self.settingsGradientView setAlpha:1.0];
        [self.settingsGradientView.layer insertSublayer:gradient2 atIndex:0];
        
    }];
    
}



///////////////////////----UI STUFF----////////////////////////////
- (IBAction)MS1_ACTION:(UIButton *)sender {
    
    saveCustomSetting(@"ExploitType", 0);
    
    //color var
    UIColor *purple = [UIColor colorWithRed:0.43 green:0.53 blue:0.82 alpha:1.0];
    UIColor *white = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];;
    UIColor *black = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];;
    
    //button color
    self.VS_Outlet.backgroundColor = purple;
    self.MS1_OUTLET.backgroundColor = white;
    self.MS2_Outlet.backgroundColor = purple;
    self.SP_Outlet.backgroundColor = purple;
    self.TWOutlet.backgroundColor = purple;

    //button label color
    [self.TWOutlet setTitleColor:white forState:UIControlStateNormal];
    [self.VS_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.MS1_OUTLET setTitleColor:black forState:UIControlStateNormal];
    [self.MS2_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.SP_Outlet setTitleColor:white forState:UIControlStateNormal];

    
}

- (IBAction)MS2_ACTION:(UIButton *)sender {
    
    saveCustomSetting(@"ExploitType", 1);
    
    UIColor *purple = [UIColor colorWithRed:0.43 green:0.53 blue:0.82 alpha:1.0];
    UIColor *white = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];;
    UIColor *black = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];;
    
    self.VS_Outlet.backgroundColor = purple;
    self.MS1_OUTLET.backgroundColor = purple;
    self.MS2_Outlet.backgroundColor = white;
    self.SP_Outlet.backgroundColor = purple;
    self.TWOutlet.backgroundColor = purple;

    
    //button label color
    [self.TWOutlet setTitleColor:white forState:UIControlStateNormal];
    [self.VS_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.MS1_OUTLET setTitleColor:white forState:UIControlStateNormal];
    [self.MS2_Outlet setTitleColor:black forState:UIControlStateNormal];
    [self.SP_Outlet setTitleColor:white forState:UIControlStateNormal];

}

- (IBAction)VS_ACTION:(UIButton *)sender {
    
    saveCustomSetting(@"ExploitType", 2);
    
    UIColor *purple = [UIColor colorWithRed:0.43 green:0.53 blue:0.82 alpha:1.0];
    UIColor *white = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];;
    UIColor *black = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];;
    
    
    self.VS_Outlet.backgroundColor = white;
    self.MS1_OUTLET.backgroundColor = purple;
    self.MS2_Outlet.backgroundColor = purple;
    self.SP_Outlet.backgroundColor = purple;
    self.TWOutlet.backgroundColor = purple;

    
    //button label color
    [self.TWOutlet setTitleColor:white forState:UIControlStateNormal];
    [self.VS_Outlet setTitleColor:black forState:UIControlStateNormal];
    [self.MS1_OUTLET setTitleColor:white forState:UIControlStateNormal];
    [self.MS2_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.SP_Outlet setTitleColor:white forState:UIControlStateNormal];

    
}

- (IBAction)SP_Action:(UIButton *)sender {
    
    saveCustomSetting(@"ExploitType", 3);
    
    UIColor *purple = [UIColor colorWithRed:0.43 green:0.53 blue:0.82 alpha:1.0];
    UIColor *white = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];;
    UIColor *black = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];;
    
    
    self.VS_Outlet.backgroundColor = purple;
    self.MS1_OUTLET.backgroundColor = purple;
    self.MS2_Outlet.backgroundColor = purple;
    self.SP_Outlet.backgroundColor = white;
    self.TWOutlet.backgroundColor = purple;

    
    //button label color
    [self.VS_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.MS1_OUTLET setTitleColor:white forState:UIControlStateNormal];
    [self.MS2_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.SP_Outlet setTitleColor:black forState:UIControlStateNormal];
    [self.TWOutlet setTitleColor:white forState:UIControlStateNormal];

}

- (IBAction)TW_Action:(UIButton *)sender {
    
    saveCustomSetting(@"ExploitType", 4);
    
    UIColor *purple = [UIColor colorWithRed:0.43 green:0.53 blue:0.82 alpha:1.0];
    UIColor *white = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];;
    UIColor *black = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];;
    
    
    self.VS_Outlet.backgroundColor = purple;
    self.MS1_OUTLET.backgroundColor = purple;
    self.MS2_Outlet.backgroundColor = purple;
    self.SP_Outlet.backgroundColor = purple;
    self.TWOutlet.backgroundColor = white;

    
    //button label color
    [self.VS_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.MS1_OUTLET setTitleColor:white forState:UIControlStateNormal];
    [self.MS2_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.SP_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.TWOutlet setTitleColor:black forState:UIControlStateNormal];

}

- (IBAction)Cydia_Button:(UIButton *)sender {
    
    saveCustomSetting(@"PackagerType", 0);
    
    UIColor *purple = [UIColor colorWithRed:0.43 green:0.53 blue:0.82 alpha:1.0];
    UIColor *white = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];;
    UIColor *black = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];;
    
    
    self.Cydia_Outlet.backgroundColor = white;
    self.Zebra_Outlet.backgroundColor = purple;
    self.Sileo_Outlet.backgroundColor = purple;
    
    //button label color
    [self.Cydia_Outlet setTitleColor:black forState:UIControlStateNormal];
    [self.Zebra_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.Sileo_Outlet setTitleColor:white forState:UIControlStateNormal];
    
}

- (IBAction)Zebra_Button:(UIButton *)sender {
    
    saveCustomSetting(@"PackagerType", 1);
    
    //color var
    UIColor *purple = [UIColor colorWithRed:0.43 green:0.53 blue:0.82 alpha:1.0];
    UIColor *white = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];;
    UIColor *black = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];;
    
    //button color
    self.Cydia_Outlet.backgroundColor = purple;
    self.Zebra_Outlet.backgroundColor = white;
    self.Sileo_Outlet.backgroundColor = purple;
    
    //button label color
    [self.Cydia_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.Zebra_Outlet setTitleColor:black forState:UIControlStateNormal];
    [self.Sileo_Outlet setTitleColor:white forState:UIControlStateNormal];
}

- (IBAction)Sileo_Button:(UIButton *)sender {
    
    saveCustomSetting(@"PackagerType", 2);
    
    UIColor *purple = [UIColor colorWithRed:0.43 green:0.53 blue:0.82 alpha:1.0];
    UIColor *white = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];;
    UIColor *black = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];;
    
    self.Cydia_Outlet.backgroundColor = purple;
    self.Zebra_Outlet.backgroundColor = purple;
    self.Sileo_Outlet.backgroundColor = white;
    
    //button label color
    [self.Cydia_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.Zebra_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.Sileo_Outlet setTitleColor:black forState:UIControlStateNormal];
}


//ViewController *sharedController = nil;
static ViewController *currentViewController;

- (IBAction)fix_fs_switch_action:(id)sender {
    if ([sender isOn]) {
        saveCustomSetting(@"fixFS", 1);
        checkfsfixswitch = 1;

        dispatch_async(dispatch_get_main_queue(), ^{
            [ViewController.sharedController.buttontext setTitle:localize(@"Fix FS?") forState:UIControlStateNormal];
            [self.fixfsswitch setOn:TRUE];
            [self.restoreFSSwitch setOn:FALSE];
            [self.restoreFSSwitch setHidden:YES];
            [self.restoreFSSwitch setEnabled:NO];
            [self.restoreFSSwitch setUserInteractionEnabled:NO];
            [self.setnoncebtn setEnabled:TRUE];
            [self.setnoncebtn setHidden:FALSE];

        });
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Important notice:"
                                                     message:@"This option requires internet to succeed. Please make sure you're connected to the internet before proceeding. !You've been warned!"
                                                    delegate:self
                                           cancelButtonTitle: nil
                                           otherButtonTitles:@"OK", nil];
        [alert show];
    } else {
        saveCustomSetting(@"fixFS", 0);
        checkfsfixswitch = 0;
        #define CS_OPS_STATUS       0   /* return status */
        uint32_t flags;
        csops(getpid(), CS_OPS_STATUS, &flags, 0);
        int checkuncovermarker = (file_exists("/.installed_unc0ver"));
        int checkth0rmarkerFinal = (file_exists("/.freya_installed"));
        int checkchimeramarker = (file_exists("/.procursus_strapped"));
        int checkcheckRa1nmarker2 = (file_exists("/.bootstrapped"));

        printf("Uncover marker exists?: %d\n",checkuncovermarker);
        printf("Th0r final marker exists?: %d\n",checkth0rmarkerFinal);
        printf("Chimera marker exists?: %d\n",checkchimeramarker);
        [ViewController.sharedController.buttontext setEnabled:true];

        if ([sender isOn])
        {
            if ((checkth0rmarkerFinal == 1) && (checkuncovermarker == 0) && (checkchimeramarker == 0)){
                [ViewController.sharedController.buttontext setTitle:localize(@"Remove Freya?") forState:UIControlStateNormal];
                newTFcheckMyRemover4me = TRUE;
                [self.fixfsswitch setOn:FALSE];
                [self.fixfsswitch setHidden:YES];
                [self.fixfsswitch setEnabled:NO];
                [self.fixfsswitch setUserInteractionEnabled:NO];
                [self.restoreFSSwitch setHidden:NO];
                [self.restoreFSSwitch setEnabled:YES];
                [self.restoreFSSwitch setOn:TRUE];
                [self.restoreFSSwitch setUserInteractionEnabled:YES];

            } else if ((checkuncovermarker == 1) && (checkth0rmarkerFinal == 0) && (checkchimeramarker == 0)) {
                [ViewController.sharedController.buttontext setTitle:localize(@"Remove u0?") forState:UIControlStateNormal];
                newTFcheckMyRemover4me = TRUE;
                saveCustomSetting(@"RestoreFS", 0);
                [_restoreFSSwitch setEnabled:NO];
                [_restoreFSSwitch setHidden:YES];
                [_restoreFSSwitch setUserInteractionEnabled:NO];
                JUSTremovecheck = true;
                [ViewController.sharedController.restoreFSSwitch setEnabled:NO];
                [ViewController.sharedController.restoreFSSwitch setUserInteractionEnabled:NO];

            } else if ((checkuncovermarker == 0) && (checkchimeramarker == 1) && (checkth0rmarkerFinal == 0)){
                [ViewController.sharedController.buttontext setTitle:localize(@"Remove Chimera?") forState:UIControlStateNormal];
                newTFcheckMyRemover4me = TRUE;
                saveCustomSetting(@"RestoreFS", 0);
                [_restoreFSSwitch setEnabled:NO];
                [_restoreFSSwitch setHidden:YES];
                [_restoreFSSwitch setUserInteractionEnabled:NO];
                JUSTremovecheck = true;
                [ViewController.sharedController.restoreFSSwitch setEnabled:NO];
                [ViewController.sharedController.restoreFSSwitch setUserInteractionEnabled:NO];
                //    goto end;
            } else {
                [ViewController.sharedController.buttontext setTitle:localize(@"Remove JB?") forState:UIControlStateNormal];
                newTFcheckMyRemover4me = TRUE;
                [self.fixfsswitch setOn:FALSE];
                [self.fixfsswitch setHidden:YES];
                [self.fixfsswitch setEnabled:NO];
                [self.fixfsswitch setUserInteractionEnabled:NO];
                [self.restoreFSSwitch setHidden:NO];
                [self.restoreFSSwitch setEnabled:YES];
                [self.restoreFSSwitch setOn:TRUE];
                [self.restoreFSSwitch setUserInteractionEnabled:YES];            }
            JUSTremovecheck = true;
            saveCustomSetting(@"RestoreFS", 0);
        } else {
            if ((checkth0rmarkerFinal == 1) && (checkuncovermarker == 0) && (checkchimeramarker == 0)){
                if (checkfsfixswitch == 1) {
                     dispatch_async(dispatch_get_main_queue(), ^{
                             [ViewController.sharedController.buttontext setTitle:localize(@"Fix FS?") forState:UIControlStateNormal];
                            [self.fixfsswitch setOn:TRUE];
                            [self.restoreFSSwitch setOn:FALSE];
                            [self.restoreFSSwitch setHidden:YES];
                            [self.restoreFSSwitch setEnabled:NO];
                            [self.restoreFSSwitch setUserInteractionEnabled:NO];
                             [self.setnoncebtn setEnabled:TRUE];
                             [self.setnoncebtn setHidden:FALSE];
                             [ViewController.sharedController.loadTweakSwitch setEnabled:YES];
                             [ViewController.sharedController.loadTweakSwitch setOn:TRUE];
                         });
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Important notice:"
                                                                 message:@"This option requires internet to succeed. Please make sure you're connected to the internet before proceeding. !You've been warned!"
                                                                delegate:self
                                                       cancelButtonTitle: nil
                                                       otherButtonTitles:@"OK", nil];
                    [alert show];
                } else {
                    if (checkcheckRa1nmarker2 == 0) {

                        [ViewController.sharedController.buttontext setTitle:localize(@"Enable Freya?") forState:UIControlStateNormal];
                        [_setnoncebtn setHidden:NO];
                        [_setnoncebtn setEnabled:YES];
                        [self.fixfsswitch setOn:FALSE];
                        [self.restoreFSSwitch setEnabled:YES];
                        [self.restoreFSSwitch setOn:FALSE];
                    } else {
                        [ViewController.sharedController.buttontext setTitle:localize(@"checkra1n & Freya?") forState:UIControlStateNormal];
                        [_setnoncebtn setHidden:NO];
                        [_setnoncebtn setEnabled:YES];

                    }
                }
            } else if ((checkuncovermarker == 1) && (checkth0rmarkerFinal == 0) && (checkchimeramarker == 0)) {
                [ViewController.sharedController.buttontext setTitle:localize(@"Remove u0 1st") forState:UIControlStateNormal];
                newTFcheckMyRemover4me = TRUE;
                saveCustomSetting(@"RestoreFS", 0);
                [_restoreFSSwitch setHidden:YES];

                [_restoreFSSwitch setEnabled:NO];
                [_restoreFSSwitch setUserInteractionEnabled:NO];
                JUSTremovecheck = true;
                [ViewController.sharedController.restoreFSSwitch setEnabled:NO];
                [ViewController.sharedController.restoreFSSwitch setUserInteractionEnabled:NO];

                [ViewController.sharedController.buttontext setEnabled:false];
            } else if ((checkuncovermarker == 0) && (checkchimeramarker == 1) && (checkth0rmarkerFinal == 0)){
                [ViewController.sharedController.buttontext setTitle:localize(@"Remove Chimera 1st") forState:UIControlStateNormal];
                newTFcheckMyRemover4me = TRUE;
                saveCustomSetting(@"RestoreFS", 0);
                [_restoreFSSwitch setHidden:YES];

                [_restoreFSSwitch setEnabled:NO];
                [_restoreFSSwitch setUserInteractionEnabled:NO];
                JUSTremovecheck = true;
                [ViewController.sharedController.restoreFSSwitch setEnabled:NO];
                [ViewController.sharedController.restoreFSSwitch setUserInteractionEnabled:NO];
                [ViewController.sharedController.buttontext setEnabled:false];

            } else {
                [_setnoncebtn setHidden:NO];
                [_setnoncebtn setEnabled:NO];

                [ViewController.sharedController.buttontext setTitle:localize(@"Jailbreak") forState:UIControlStateNormal];
                [self.fixfsswitch setOn:FALSE];
                [self.fixfsswitch setHidden:YES];
                [self.fixfsswitch setEnabled:NO];
                [self.fixfsswitch setUserInteractionEnabled:NO];

                [self.restoreFSSwitch setOn:FALSE];
                [self.restoreFSSwitch setHidden:NO];
                [self.restoreFSSwitch setEnabled:YES];
                [self.restoreFSSwitch setUserInteractionEnabled:YES];
            }
            newTFcheckMyRemover4me = false;
            JUSTremovecheck = false;
            saveCustomSetting(@"RestoreFS", 1);
        }
    }
    
}

- (IBAction)Restore_FS_Switch_Action:(UISwitch *)sender {
    #define CS_OPS_STATUS       0   /* return status */
    uint32_t flags;
    csops(getpid(), CS_OPS_STATUS, &flags, 0);
    int checkuncovermarker = (file_exists("/.installed_unc0ver"));
    int checkth0rmarkerFinal = (file_exists("/.freya_installed"));
    int checkchimeramarker = (file_exists("/.procursus_strapped"));
    int checkcheckRa1nmarker2 = (file_exists("/.bootstrapped"));

    printf("Uncover marker exists?: %d\n",checkuncovermarker);
    printf("Th0r final marker exists?: %d\n",checkth0rmarkerFinal);
    printf("Chimera marker exists?: %d\n",checkchimeramarker);
    [ViewController.sharedController.buttontext setEnabled:true];

    if ([sender isOn])
    {
        if ((checkth0rmarkerFinal == 1) && (checkuncovermarker == 0) && (checkchimeramarker == 0)){
            [ViewController.sharedController.buttontext setTitle:localize(@"Remove Freya?") forState:UIControlStateNormal];
            newTFcheckMyRemover4me = TRUE;
            [self.fixfsswitch setOn:FALSE];
            [self.fixfsswitch setHidden:YES];
            [self.fixfsswitch setEnabled:NO];
            [self.fixfsswitch setUserInteractionEnabled:NO];
            [self.restoreFSSwitch setHidden:NO];
            [self.restoreFSSwitch setEnabled:YES];
            [self.restoreFSSwitch setOn:TRUE];
            [self.restoreFSSwitch setUserInteractionEnabled:YES];
        } else if ((checkuncovermarker == 1) && (checkth0rmarkerFinal == 0) && (checkchimeramarker == 0)) {
            [ViewController.sharedController.buttontext setTitle:localize(@"Remove u0?") forState:UIControlStateNormal];
            newTFcheckMyRemover4me = TRUE;
            saveCustomSetting(@"RestoreFS", 0);
            [_restoreFSSwitch setEnabled:NO];
            [_restoreFSSwitch setHidden:YES];
            [_restoreFSSwitch setUserInteractionEnabled:NO];
            JUSTremovecheck = true;
            [ViewController.sharedController.restoreFSSwitch setEnabled:NO];
            [ViewController.sharedController.restoreFSSwitch setUserInteractionEnabled:NO];

        } else if ((checkuncovermarker == 0) && (checkchimeramarker == 1) && (checkth0rmarkerFinal == 0)){
            [ViewController.sharedController.buttontext setTitle:localize(@"Remove Chimera?") forState:UIControlStateNormal];
            newTFcheckMyRemover4me = TRUE;
            saveCustomSetting(@"RestoreFS", 0);
            [_restoreFSSwitch setEnabled:NO];
            [_restoreFSSwitch setHidden:YES];
            [_restoreFSSwitch setUserInteractionEnabled:NO];
            JUSTremovecheck = true;
            [ViewController.sharedController.restoreFSSwitch setEnabled:NO];
            [ViewController.sharedController.restoreFSSwitch setUserInteractionEnabled:NO];
            //    goto end;
        } else {
            [ViewController.sharedController.buttontext setTitle:localize(@"Remove JB?") forState:UIControlStateNormal];
            newTFcheckMyRemover4me = TRUE;
            [self.fixfsswitch setOn:FALSE];
            [self.fixfsswitch setHidden:YES];
            [self.fixfsswitch setEnabled:NO];
            [self.fixfsswitch setUserInteractionEnabled:NO];
            [self.restoreFSSwitch setHidden:NO];
            [self.restoreFSSwitch setEnabled:YES];
            [self.restoreFSSwitch setOn:TRUE];
            [self.restoreFSSwitch setUserInteractionEnabled:YES];
        }
        JUSTremovecheck = true;
        saveCustomSetting(@"RestoreFS", 0);
    } else {
        if ((checkth0rmarkerFinal == 1) && (checkuncovermarker == 0) && (checkchimeramarker == 0)){
            if (checkfsfixswitch == 1) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                         [ViewController.sharedController.buttontext setTitle:localize(@"Fix FS?") forState:UIControlStateNormal];
                         [self.fixfsswitch setOn:TRUE];
                         [self.restoreFSSwitch setOn:FALSE];
                         [self.restoreFSSwitch setHidden:YES];
                         [self.restoreFSSwitch setEnabled:NO];
                         [self.restoreFSSwitch setUserInteractionEnabled:NO];

                        [self.setnoncebtn setEnabled:TRUE];
                         [self.setnoncebtn setHidden:FALSE];
                         [ViewController.sharedController.loadTweakSwitch setEnabled:YES];
                         [ViewController.sharedController.loadTweakSwitch setOn:TRUE];
                     });
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Important notice:"
                                                             message:@"This option requires internet to succeed. Please make sure you're connected to the internet before proceeding. !You've been warned!"
                                                            delegate:self
                                                   cancelButtonTitle: nil
                                                   otherButtonTitles:@"OK", nil];
                [alert show];
            } else {
                if (checkcheckRa1nmarker2 == 0) {

                    [ViewController.sharedController.buttontext setTitle:localize(@"Enable Freya?") forState:UIControlStateNormal];
                    [_setnoncebtn setHidden:NO];
                    [_setnoncebtn setEnabled:YES];
                } else {
                    [ViewController.sharedController.buttontext setTitle:localize(@"checkra1n & Freya?") forState:UIControlStateNormal];
                    [_setnoncebtn setHidden:NO];
                    [_setnoncebtn setEnabled:YES];

                }
            }
        } else if ((checkuncovermarker == 1) && (checkth0rmarkerFinal == 0) && (checkchimeramarker == 0)) {
            [ViewController.sharedController.buttontext setTitle:localize(@"Remove u0 1st") forState:UIControlStateNormal];
            newTFcheckMyRemover4me = TRUE;
            saveCustomSetting(@"RestoreFS", 0);
            [_restoreFSSwitch setHidden:YES];

            [_restoreFSSwitch setEnabled:NO];
            [_restoreFSSwitch setUserInteractionEnabled:NO];
            JUSTremovecheck = true;
            [ViewController.sharedController.restoreFSSwitch setEnabled:NO];
            [ViewController.sharedController.restoreFSSwitch setUserInteractionEnabled:NO];

            [ViewController.sharedController.buttontext setEnabled:false];
        } else if ((checkuncovermarker == 0) && (checkchimeramarker == 1) && (checkth0rmarkerFinal == 0)){
            [ViewController.sharedController.buttontext setTitle:localize(@"Remove Chimera 1st") forState:UIControlStateNormal];
            newTFcheckMyRemover4me = TRUE;
            saveCustomSetting(@"RestoreFS", 0);
            [_restoreFSSwitch setHidden:YES];

            [_restoreFSSwitch setEnabled:NO];
            [_restoreFSSwitch setUserInteractionEnabled:NO];
            JUSTremovecheck = true;
            [ViewController.sharedController.restoreFSSwitch setEnabled:NO];
            [ViewController.sharedController.restoreFSSwitch setUserInteractionEnabled:NO];
            [ViewController.sharedController.buttontext setEnabled:false];

        } else {
            [_setnoncebtn setHidden:NO];
            [_setnoncebtn setEnabled:NO];

            [ViewController.sharedController.buttontext setTitle:localize(@"Jailbreak") forState:UIControlStateNormal];
            [self.fixfsswitch setOn:FALSE];
            [self.fixfsswitch setHidden:YES];
            [self.fixfsswitch setEnabled:NO];
            [self.fixfsswitch setUserInteractionEnabled:NO];

            [self.restoreFSSwitch setOn:FALSE];
            [self.restoreFSSwitch setHidden:NO];
            [self.restoreFSSwitch setEnabled:YES];
            [self.restoreFSSwitch setUserInteractionEnabled:YES];

        }
        newTFcheckMyRemover4me = false;
        JUSTremovecheck = false;
        saveCustomSetting(@"RestoreFS", 1);
    }
}

- (IBAction)loadTweaksPushed:(id)sender {
    if ([sender isOn])
    {
        saveCustomSetting(@"LoadTweaks", 0);
    } else {
        saveCustomSetting(@"LoadTweaks", 1);
    }
}

- (IBAction)dismissSwipe:(UISwipeGestureRecognizer *)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
- (IBAction)dismissButton:(UIButton *)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)rooted_Switch:(UIButton *)sender {
    
    //0 = root
    //1 = rootless
    saveCustomSetting(@"RootSetting", 0);
    
    UIColor *purple = [UIColor colorWithRed:0.48 green:0.44 blue:0.83 alpha:1.0];
    UIColor *white = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];;
    UIColor *black = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];;
    
    self.rooted_Switch.backgroundColor = white;
    self.rootless_Switch.backgroundColor = purple;
    
    //button label color
    [self.rootless_Switch setTitleColor:white forState:UIControlStateNormal];
    [self.rooted_Switch setTitleColor:black forState:UIControlStateNormal];
    
}

- (IBAction)rootless_Switch:(UIButton *)sender {
    
    saveCustomSetting(@"RootSetting", 1);
    UIColor *purple = [UIColor colorWithRed:0.48 green:0.44 blue:0.83 alpha:1.0];
    UIColor *white = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];;
    UIColor *black = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];;
    
    self.rooted_Switch.backgroundColor = purple;
    self.rootless_Switch.backgroundColor = white;
    
    //button label color
    [self.rootless_Switch setTitleColor:black forState:UIControlStateNormal];
    [self.rooted_Switch setTitleColor:white forState:UIControlStateNormal];
    
    
}
- (IBAction)fukbut:(id)sender {
    
}
- (IBAction)creditspressed:(id)sender {
    //show confirmation message to user
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Credits To:"
                                                 message:@"@YcS_dev for helping out with remount & pushing me to make this project.\n@Chr0nicT for teaching me some general basics.\nEveryone whom helped to create ziyou and published it on github.\nThank you! for using Freya to jailbreak your device!"
                                                delegate:self
                                       cancelButtonTitle: nil
                                       otherButtonTitles:@"OK", nil];
    [alert show];
}

- (IBAction)setnoncepressedbtn:(id)sender {
    __block NSString *generatorToSet = nil;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:localize(@"Set the system boot nonce on jailbreak") message:localize(@"Enter the generator for the nonce you want the system to generate on boot") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:localize(@"Cancel") style:UIAlertActionStyleDefault handler:nil]];
    UIAlertAction *set = [UIAlertAction actionWithTitle:localize(@"Set") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        const char *generatorInput = [alertController.textFields.firstObject.text UTF8String];
        char compareString[22];
        uint64_t rawGeneratorValue;
        sscanf(generatorInput, "0x%16llx",&rawGeneratorValue);
        sprintf(compareString, "0x%016llx", rawGeneratorValue);
        if(strcmp(compareString, generatorInput) != 0) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:localize(@"Error") message:localize(@"Failed to validate generator") preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:localize(@"OK") style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
            return;
        }
        generatorToSet = [NSString stringWithUTF8String:generatorInput];
        [userDefaults setObject:generatorToSet forKey:@K_GENERATOR];
        [userDefaults synchronize];
        uint32_t flags;
        csops(getpid(), CS_OPS_STATUS, &flags, 0);
        UIAlertController *alertController = nil;
        if ((flags & CS_PLATFORM_BINARY)) {
            alertController = [UIAlertController alertControllerWithTitle:localize(@"Notice") message:localize(@"The system boot nonce will be set the next time you enable your jailbreak") preferredStyle:UIAlertControllerStyleAlert];
            
        } else {
            alertController = [UIAlertController alertControllerWithTitle:localize(@"Notice") message:localize(@"The system boot nonce will be set once you enable the jailbreak") preferredStyle:UIAlertControllerStyleAlert];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setInteger:0 forKey:@"SetNonce"];
            
        }
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }];
    [alertController addAction:set];
    [alertController setPreferredAction:set];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = [NSString stringWithFormat:@"%s", genToSet()];
    }];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end

