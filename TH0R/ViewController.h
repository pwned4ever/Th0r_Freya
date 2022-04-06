//
//  ViewController.h


#import <UIKit/UIKit.h>
#include "utils/utilsZS.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface ViewController : UIViewController <AVAudioPlayerDelegate> {
//@interface ViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, AVAudioPlayerDelegate> {
    SystemSoundID PlaySoundID1;
    AVAudioPlayer *audioPlayer1;
}

@property (readonly) ViewController *sharedController;
+ (ViewController*)sharedController;
@property (weak, nonatomic) IBOutlet UILabel *uptimelabel;
@property (weak, nonatomic) IBOutlet UILabel *versionlabel;
@property (weak, nonatomic) IBOutlet UILabel *appverlabel;

@property (weak, nonatomic) IBOutlet UILabel *devicelabel;
@property (strong, nonatomic) IBOutlet UIView *backGroundView;
@property (weak, nonatomic) IBOutlet UIImageView *thorbackgroundjpeg;
@property (strong, nonatomic) IBOutlet UILabel *sliceLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressmeterView;
@property (strong, nonatomic) IBOutlet UIImageView *paintBrush;
@property (strong, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIImageView *settings_buttun_bg;
@property (weak, nonatomic) IBOutlet UIButton *buttontext;
@property (weak, nonatomic) IBOutlet UIImageView *jailbreakButtonBackground;
@property (weak, nonatomic) IBOutlet UIView *credits_view;
@property (strong, nonatomic) IBOutlet UISwitch *restoreFSSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *loadTweakSwitch;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressMeterUIVIEW;





-(void)ourprogressMeterjeez;
- (void)xFinished;


@end
//extern bool newTFcheckMyRemover4me;
//extern bool newTFcheckofCyforce;
//extern bool JUSTremovecheck;
void ourprogressMeter(void);
void xFinishFailed(void);
void savedoffs(void);
void findoffs(void);
void dothesploit(void);
void dothepatch(void);
void debsinstalling(void);
void yeasnapshot(void);
void spotless(void);
void removethejb(void);

void thelabelbtnchange(char *msg);
void cydiaDone(char *msg);
void uicaching(char *msg);
void startJBD(char *msg);
void jbdfinished(char *msg);
void respringing(char *msg);
extern bool newTFcheckMyRemover4me;
extern bool newTFcheckofCyforce;
extern bool JUSTremovecheck;

static inline void showAlertWithCancel(NSString *title, NSString *message, Boolean wait, Boolean destructive, NSString *cancel) {
    dispatch_semaphore_t semaphore;
    if (wait)
    semaphore = dispatch_semaphore_create(0);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController *controller = [ViewController sharedController];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *OK = [UIAlertAction actionWithTitle:@"Okay" style:destructive ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (wait)
            dispatch_semaphore_signal(semaphore);
        }];
        [alertController addAction:OK];
        [alertController setPreferredAction:OK];
        if (cancel) {
            UIAlertAction *abort = [UIAlertAction actionWithTitle:cancel style:destructive ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (wait)
                dispatch_semaphore_signal(semaphore);
            }];
            [alertController addAction:abort];
            [alertController setPreferredAction:abort];
        }
        [controller presentViewController:alertController animated:YES completion:nil];
    });
    if (wait)
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

static inline void showAlertPopup(NSString *title, NSString *message, Boolean wait, Boolean destructive, NSString *cancel) {
    dispatch_semaphore_t semaphore;
    if (wait)
    semaphore = dispatch_semaphore_create(0);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController *controller = [ViewController sharedController];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [controller presentViewController:alertController animated:YES completion:nil];
    });
    if (wait)
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}



static inline void showAlert(NSString *title, NSString *message, Boolean wait, Boolean destructive) {
    //dispatch_async(dispatch_get_main_queue(), ^{
    //    ViewController *controller = [ViewController sharedController];
    //    [controller dismissViewControllerAnimated:false completion:nil];
    //});
    
    showAlertWithCancel(title, message, wait, destructive, nil);
}



static inline void showThePopup(NSString *title, NSString *message, Boolean wait, Boolean destructive) {
    //dispatch_async(dispatch_get_main_queue(), ^{
     //   ViewController *controller = [ViewController sharedController];
    //    [controller dismissViewControllerAnimated:false completion:nil];
   // });
    
    showAlertPopup(title, message, wait, destructive, nil);
}

static inline void disableRootFS() {
    ViewController *controller = [ViewController sharedController];
    [[controller restoreFSSwitch] setOn:false];
    saveCustomSetting(@"RestoreFS", 1);
}



