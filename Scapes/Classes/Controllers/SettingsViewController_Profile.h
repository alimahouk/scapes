//
//  SettingsViewController_Profile.h
//  Scapes
//
//  Created by MachOSX on 9/24/13.
//
//

#import "MBProgressHUD.h"

@interface SettingsViewController_Profile : UIViewController <MBProgressHUDDelegate, UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
{
    MBProgressHUD *HUD;
    UISwipeGestureRecognizer *viewSwipeRecognizer;
    UIBarButtonItem *doneButton;
    UIScrollView *mainView;
    id activeField;
    UITextField *firstNameField;
    UITextField *lastNameField;
    UITextField *usernameField;
    UITextField *emailField;
    UITextField *websiteField;
    UITextField *cityField;
    UITextField *facebookField;
    UITextField *twitterField;
    UITextField *instagramField;
    UITextView *bioField;
    UIButton *genderButton;
    UIButton *birthdayButton;
    UIButton *removeBirthdayButton;
    UIButton *stateButton;
    UIButton *countryButton;
    UILabel *firstNameLabel;
    UILabel *lastNameLabel;
    UILabel *usernameLabel;
    UILabel *genderLabel;
    UILabel *emailLabel;
    UILabel *birthdayLabel;
    UILabel *cityLabel;
    UILabel *stateLabel;
    UILabel *countryLabel;
    UILabel *bioLabel;
    UILabel *websiteLabel;
    UILabel *facebookLabel;
    UILabel *twitterLabel;
    UILabel *instagramLabel;
    UILabel *bioFieldPlaceholderLabel;
    UILabel *bioFieldCounterLabel;
    UIImageView *horizontalSeparator_1;
    UIImageView *horizontalSeparator_2;
    UIImageView *horizontalSeparator_3;
    UIImageView *horizontalSeparator_4;
    UIImageView *horizontalSeparator_5;
    UIImageView *horizontalSeparator_6;
    UIImageView *horizontalSeparator_7;
    UIImageView *horizontalSeparator_8;
    UIImageView *horizontalSeparator_9;
    UIImageView *verticalSeparator_1;
    UIImageView *verticalSeparator_2;
    UIImageView *verticalSeparator_3;
    UIDatePicker *birthdayPicker;
    UIPickerView *detailPicker;
    NSMutableArray *countries;
    NSMutableArray *states;
    NSMutableArray *genders;
    NSMutableArray *activeDataSource;
    NSString *firstName;
    NSString *lastName;
    NSString *username;
    NSString *email;
    NSString *gender;
    NSString *birthday;
    NSString *location_city;
    NSString *location_state;
    NSString *location_country;
    NSString *bio;
    NSString *website;
    NSString *facebookHandle;
    NSString *twitterHandle;
    NSString *instagramHandle;
    BOOL shouldDismissKeyboard;
}

- (void)goBack;
- (void)save;
- (void)removeBirthday;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillBeHidden:(NSNotification *)notification;
- (void)showBirthdayPicker;
- (void)dismissBirthdayPicker;
- (void)showGenderPicker;
- (void)showStatePicker;
- (void)showCountryPicker;
- (void)dismissDetailPicker;
- (void)datePickerValueChanged;

- (void)showNetworkError;

@end
