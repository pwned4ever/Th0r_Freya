//
//  SettingsViewViewController.h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingsViewController : UIViewController



//-------UI STUFF--------//

@property (strong, nonatomic) IBOutlet UIView *backGroundView;
@property (weak, nonatomic) IBOutlet UIView *settingsGradientView;

@property (weak, nonatomic) IBOutlet UITextField *noncesettertxtfeild;
@property (weak, nonatomic) IBOutlet UILabel *ExploitTitleLabel;

- (IBAction)fukbut:(id)sender;
//SWITCH FUNCTIONS
@property (weak, nonatomic) IBOutlet UIButton *creditsbutton;
@property (weak, nonatomic) IBOutlet UIButton *setnoncebtn;
@property (weak, nonatomic) IBOutlet UILabel *LoadTweakslabel;
@property (weak, nonatomic) IBOutlet UILabel *ReinstallcydiaLabel;
@property (weak, nonatomic) IBOutlet UILabel *RestorerootLabel;


@property (weak, nonatomic) IBOutlet UILabel *ForceuicacheLabel;
- (IBAction)Restore_FS_Switch_Action:(UISwitch *)sender;

//Fucking Switched
@property (strong, nonatomic) IBOutlet UISwitch *loadTweaksSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *restoreFSSwitch;

@property (strong, nonatomic) IBOutlet UISwitch *fixfsswitch;
@property (weak, nonatomic) IBOutlet UISwitch *forceuicacheswitch;

//THE EXPLOIT BUTTONS outlet
@property (weak, nonatomic) IBOutlet UIButton *VS_Outlet;
@property (weak, nonatomic) IBOutlet UIButton *MS1_OUTLET;
@property (weak, nonatomic) IBOutlet UIButton *MS2_Outlet;
@property (weak, nonatomic) IBOutlet UIButton *SP_Outlet;
@property (weak, nonatomic) IBOutlet UIButton *TWOutlet;

//the exploit buttons action

- (IBAction)MS1_ACTION:(UIButton *)sender;
- (IBAction)MS2_ACTION:(UIButton *)sender;
- (IBAction)VS_ACTION:(UIButton *)sender;
- (IBAction)SP_Action:(UIButton *)sender;
- (IBAction)TW_Action:(UIButton *)sender;

//THE PACKAGE MANAGER BUTTONS outlet
@property (weak, nonatomic) IBOutlet UIButton *Cydia_Outlet;
@property (weak, nonatomic) IBOutlet UIButton *Zebra_Outlet;
@property (weak, nonatomic) IBOutlet UIButton *Sileo_Outlet;

//the package manager buttons action
- (IBAction)Cydia_Button:(UIButton *)sender;
- (IBAction)Zebra_Button:(UIButton *)sender;
- (IBAction)Sileo_Button:(UIButton *)sender;

//the root/rootless swich outlets
@property (weak, nonatomic) IBOutlet UIButton *rooted_Switch;
@property (weak, nonatomic) IBOutlet UIButton *rootless_Switch;

//the root/rootless switch actions
- (IBAction)rooted_Switch:(UIButton *)sender;
- (IBAction)rootless_Switch:(UIButton *)sender;


@end

NS_ASSUME_NONNULL_END
