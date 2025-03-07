//
//  SHPasscodeViewController.h
//  Scapes
//
//  Created by MachOSX on 11/13/13.
//
//

@class SHPasscodeViewController;

@protocol SHPasscodeViewDelegate<NSObject>
@optional

- (void)passcodeViewDidAuthenticate;
- (void)passcodeViewDidAcceptNewPasscode;
- (void)passcodeViewShouldChangeToNewPasscode:(NSString *)passcode;

@end

@interface SHPasscodeViewController : UIViewController <UITextFieldDelegate>
{
    SHPasscodeWindowMode windowMode;
    UITextField *passcodeField;
    UILabel *headerLabel;
    UILabel *lockTimeLabel;
    UILabel *lockTimeDescriptionLabel;
    UIView *dotContainer;
    UIImageView *dot_1;
    UIImageView *dot_2;
    UIImageView *dot_3;
    UIImageView *dot_4;
    UIImageView *dotFill_1;
    UIImageView *dotFill_2;
    UIImageView *dotFill_3;
    UIImageView *dotFill_4;
    UIButton *dismissWindowButton;
    UIButton *forgotPasswordButton;
    NSString *currentPasscode;
    NSString *newPasscode;
    NSArray *passcodeTestCases;
    NSArray *lockupDelays;
    NSTimer *timer_UILock;
    NSTimer *timer_UILockLabel;
    NSDate *unlockTime;
    int attemptCount;
    BOOL isAuthenticating;
    BOOL isConfirmingPasscode;
    BOOL isTestingAgainstCases;
}

@property (nonatomic, weak) id <SHPasscodeViewDelegate> delegate;
@property (nonatomic) BOOL authenticationPassed;

- (void)dismissView;
- (void)shakeWithReset:(BOOL)reset;
- (void)lockUIAsResume:(BOOL)resume;
- (void)unlockUI;
- (void)updateLockTimeLabel;
- (void)presentNewPasswordPrompt;
- (void)presentConfirmationPrompt;
- (void)testAgainstCases:(NSArray *)cases;
- (void)textFieldDidChange:(id)sender;
- (void)setMode:(SHPasscodeWindowMode)theWindowMode;
- (void)checkTimeout;
- (void)resetTimeout;

@end
