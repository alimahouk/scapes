//
//  ContactInfoViewController.h
//  Scapes
//
//  Created by MachOSX on 6/10/14.
//
//



@interface ContactInfoViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    UITableView *infoTable;
    UIImageView *userThumbnail;
    UILabel *userNotFoundLabel;
    UILabel *nameLabel;
    UILabel *organizationLabel;
    NSMutableArray *contactDetails;
    NSIndexPath *activeIndexPath;
    NSString *activeCountryCallingCode;
    NSString *activePrefix;
    NSString *activePhoneNumber;
}

@property (nonatomic) NSDictionary *phoneNumber;

- (void)fetchContactInfo;
- (void)contactNotFound;
- (void)callPhoneNumber:(NSString *)phoneNumber;
- (void)copyPhoneNumber:(id)sender;

// Gestures.
- (void)userDidTapAndHoldRow:(UILongPressGestureRecognizer *)longPress;

@end
