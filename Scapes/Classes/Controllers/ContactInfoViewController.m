//
//  ContactInfoViewController.m
//  Scapes
//
//  Created by MachOSX on 6/10/14.
//
//

#import "ContactInfoViewController.h"

@implementation ContactInfoViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        contactDetails = [NSMutableArray array];
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor whiteColor];
    
    infoTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height)];
    infoTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    infoTable.delegate = self;
    infoTable.dataSource = self;
    
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, infoTable.frame.size.width, 90)];
    infoTable.tableHeaderView = tableHeaderView;
    
    userThumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(35, 10, 60, 60)];
    userThumbnail.opaque = YES;
    
    nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(110, 10, infoTable.frame.size.width - 130, 24)];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.textColor = [UIColor blackColor];
    nameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:19];
    nameLabel.opaque = YES;
    
    organizationLabel = [[UILabel alloc] initWithFrame:CGRectMake(110, 34, infoTable.frame.size.width - 130, 19)];
    organizationLabel.backgroundColor = [UIColor clearColor];
    organizationLabel.textColor = [UIColor blackColor];
    organizationLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    organizationLabel.opaque = YES;
    
    [tableHeaderView addSubview:userThumbnail];
    [tableHeaderView addSubview:nameLabel];
    [tableHeaderView addSubview:organizationLabel];
    [contentView addSubview:infoTable];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    [self setTitle:NSLocalizedString(@"CONTACT_INFO_TITLE", nil)];
    
    activeCountryCallingCode = [_phoneNumber objectForKey:@"country_calling_code"];
    activePrefix = [_phoneNumber objectForKey:@"prefix"];
    activePhoneNumber = [_phoneNumber objectForKey:@"phone_number"];
    
    [self fetchContactInfo];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    [super viewWillDisappear:animated];
}

- (void)fetchContactInfo
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ABRecordRef user = (__bridge ABRecordRef)([appDelegate.contactManager addressBookInfoForNumber:activePhoneNumber withCountryCallingCode:activeCountryCallingCode prefix:activePrefix]);
        
        if ( user )
        {
            NSData *imageData;
            
            if ( ABPersonHasImageData(user) )
            {
                imageData = (__bridge_transfer NSData *)ABPersonCopyImageDataWithFormat(user, kABPersonImageFormatThumbnail);
            }
            else
            {
                imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0);
            }
            
            __block UIImage *thumbnail = [UIImage imageWithData:imageData];
            
            NSString *firstName = (__bridge NSString *)(ABRecordCopyValue(user, kABPersonFirstNameProperty));
            NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(user, kABPersonLastNameProperty));
            NSString *organizationName = (__bridge NSString *)(ABRecordCopyValue(user, kABPersonOrganizationProperty));
            ABMultiValueRef *phones = ABRecordCopyValue(user, kABPersonPhoneProperty);
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                UIBezierPath *bezierPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, thumbnail.size.width, thumbnail.size.height)];
                
                // Create an image context containing the original UIImage.
                UIGraphicsBeginImageContext(thumbnail.size);
                
                // Clip to the bezier path and clear that portion of the image.
                CGContextRef context = UIGraphicsGetCurrentContext();
                
                CGContextAddPath(context, bezierPath.CGPath);
                CGContextClip(context);
                
                // Draw here when the context is clipped.
                [thumbnail drawAtPoint:CGPointZero];
                
                // Build a new UIImage from the image context.
                UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                thumbnail = newImage;
                userThumbnail.image = thumbnail;
                
                nameLabel.text = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
                organizationLabel.text = organizationName;
                
                if ( firstName.length == 0 )
                {
                    nameLabel.text = lastName;
                }
                
                if ( lastName.length == 0 )
                {
                    nameLabel.text = firstName;
                }
                
                if ( organizationName.length == 0 )
                {
                    nameLabel.frame = CGRectMake(nameLabel.frame.origin.x, 30, nameLabel.frame.size.width, nameLabel.frame.size.height);
                }
                
                if ( firstName.length == 0 && lastName.length == 0 )
                {
                    nameLabel.frame = CGRectMake(nameLabel.frame.origin.x, 30, nameLabel.frame.size.width, nameLabel.frame.size.height);
                    nameLabel.text = organizationName;
                    
                    organizationLabel.text = @"";
                }
            });
            
            for ( int i = 0; i < ABMultiValueGetCount(phones); i++ )
            {
                CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, i);
                CFStringRef labelRef = ABMultiValueCopyLabelAtIndex(phones, i);
                NSString *phoneNumberString = (__bridge NSString *)phoneNumberRef;
                NSString *label = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(labelRef);
                
                NSMutableDictionary *phoneNumberPack = [[appDelegate.contactManager formatPhoneNumber:phoneNumberString mobileOnly:NO] mutableCopy];
                
                if ( phoneNumberPack )
                {
                    [phoneNumberPack setObject:label forKey:@"label"];
                    [contactDetails addObject:phoneNumberPack];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [infoTable reloadData];
            });
            
            CFRelease(user);
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self contactNotFound];
            });
        }
    });
}

- (void)contactNotFound
{
    userNotFoundLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, infoTable.frame.size.width - 20, infoTable.frame.size.height)];
    userNotFoundLabel.backgroundColor = [UIColor clearColor];
    userNotFoundLabel.textColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
    userNotFoundLabel.textAlignment = NSTextAlignmentCenter;
    userNotFoundLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE];
    userNotFoundLabel.numberOfLines = 0;
    userNotFoundLabel.text = NSLocalizedString(@"CONTACT_INFO_NOT_FOUND", nil);
    userNotFoundLabel.opaque = YES;
    
    infoTable.hidden = YES;
    
    [self.view addSubview:userNotFoundLabel];
}

- (void)callPhoneNumber:(NSString *)phoneNumber
{
    UIDevice *device = [UIDevice currentDevice];
    
    if ([[device model] isEqualToString:@"iPhone"] )
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", phoneNumber]]]; // Needs to be a URL, so no spaces.
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:NSLocalizedString(@"PROFILE_CALL_ERROR", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)copyPhoneNumber:(id)sender
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSMutableDictionary *phoneNumberPack = [contactDetails objectAtIndex:activeIndexPath.row];
    NSString *preparedPhoneNumber = [NSString stringWithFormat:@"+%@%@%@", [phoneNumberPack objectForKey:@"country_calling_code"], [phoneNumberPack objectForKey:@"prefix"], [phoneNumberPack objectForKey:@"phone_number"]];
    NSString *phoneNumber = [appDelegate.contactManager formatPhoneNumberForDisplay:preparedPhoneNumber];
    
    [[UIPasteboard generalPasteboard] setString:phoneNumber];
    
    activeIndexPath = nil;
}

#pragma mark -
#pragma mark Gestures

- (void)userDidTapAndHoldRow:(UILongPressGestureRecognizer *)longPress
{
    if ( longPress.state == UIGestureRecognizerStateBegan )
    {
        CGPoint pressLocation = [longPress locationInView:infoTable];
        activeIndexPath = [infoTable indexPathForRowAtPoint:pressLocation];
        UITableViewCell *activeRow = [infoTable cellForRowAtIndexPath:activeIndexPath];
        
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:@"Copy" action:@selector(copyPhoneNumber:)];
        
        [activeRow becomeFirstResponder];
        [menuController setMenuItems:[NSArray arrayWithObject:menuItem]];
        [menuController setTargetRect:activeRow.frame inView:infoTable];
        [menuController setMenuVisible:YES animated:YES];
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if ( action == @selector(copyPhoneNumber:) )
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark -
#pragma mark UITableViewDataSource methods.

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
	return contactDetails.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    static NSString *cellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    UILabel *detailLabel;
    UILabel *detailValueLabel;
    
	if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
        UILongPressGestureRecognizer *gesture_longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapAndHoldRow:)];
        [cell addGestureRecognizer:gesture_longPress];
        
        detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(35, 10, tableView.frame.size.width - 155, 20)];
        detailLabel.backgroundColor = [UIColor clearColor];
        detailLabel.textColor = [UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0];
        detailLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
        detailLabel.tag = 7;
        
        detailValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(35, 30, tableView.frame.size.width - 155, 22)];
        detailValueLabel.backgroundColor = [UIColor clearColor];
        detailValueLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17];
        detailValueLabel.tag = 8;
        
        UIImageView *phoneIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"phone_blue"]];
        phoneIcon.frame = CGRectMake(tableView.frame.size.width - 45, 20, 25, 25);
        phoneIcon.opaque = YES;
        
        [cell.contentView addSubview:detailLabel];
        [cell.contentView addSubview:detailValueLabel];
        [cell.contentView addSubview:phoneIcon];
	}
    
    detailLabel = (UILabel *)[cell.contentView viewWithTag:7];
    detailValueLabel = (UILabel *)[cell.contentView viewWithTag:8];
    
    NSDictionary *phoneNumberPack = [contactDetails objectAtIndex:indexPath.row];
    NSString *preparedPhoneNumber = [NSString stringWithFormat:@"+%@%@%@", [phoneNumberPack objectForKey:@"country_calling_code"], [phoneNumberPack objectForKey:@"prefix"], [phoneNumberPack objectForKey:@"phone_number"]];
    NSString *displayPhoneNumber = [appDelegate.contactManager formatPhoneNumberForDisplay:preparedPhoneNumber];
    
    int countryCallingCode = [[phoneNumberPack objectForKey:@"country_calling_code"] intValue];
    int prefix = [[phoneNumberPack objectForKey:@"prefix"] intValue];
    int phoneNumber = [[phoneNumberPack objectForKey:@"phone_number"] intValue];
    
    if ( countryCallingCode == activeCountryCallingCode.intValue &&
        prefix == activePrefix.intValue &&
        phoneNumber == activePhoneNumber.intValue )
    {
        detailValueLabel.textColor = [UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0];
    }
    else
    {
        detailValueLabel.textColor = [UIColor blackColor];
    }
    
    detailLabel.text = [phoneNumberPack objectForKey:@"label"];
    detailValueLabel.text = displayPhoneNumber;
    
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *phoneNumberPack = [contactDetails objectAtIndex:indexPath.row];
    NSString *preparedPhoneNumber = [NSString stringWithFormat:@"+%@%@%@", [phoneNumberPack objectForKey:@"country_calling_code"], [phoneNumberPack objectForKey:@"prefix"], [phoneNumberPack objectForKey:@"phone_number"]];
    
    [self callPhoneNumber:preparedPhoneNumber];
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
