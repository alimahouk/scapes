//
//  SHStrobeLight.m
//  Scapes
//
//  Created by MachOSX on 8/10/13.
//
//

#import "SHStrobeLight.h"

@implementation SHStrobeLight

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        
        self.frame = CGRectMake(0, 11, screenBounds.size.width, 20);
        
        _position = SHStrobeLightPositionStatusBar;
        _oldPosition = _position;
    }
    
    return self;
}

- (void)activateStrobeLight
{
    self.animationImages = [NSArray arrayWithObjects:	
								  [UIImage imageNamed:@"Strobe_Light_1"],
								  [UIImage imageNamed:@"Strobe_Light_2"],
								  [UIImage imageNamed:@"Strobe_Light_3"],
								  [UIImage imageNamed:@"Strobe_Light_4"],
								  [UIImage imageNamed:@"Strobe_Light_5"],
								  [UIImage imageNamed:@"Strobe_Light_6"],
								  [UIImage imageNamed:@"Strobe_Light_7"],
								  [UIImage imageNamed:@"Strobe_Light_8"],
								  [UIImage imageNamed:@"Strobe_Light_9"],
								  [UIImage imageNamed:@"Strobe_Light_10"],
								  [UIImage imageNamed:@"Strobe_Light_11"],
								  [UIImage imageNamed:@"Strobe_Light_12"],
								  [UIImage imageNamed:@"Strobe_Light_13"],
								  [UIImage imageNamed:@"Strobe_Light_14"],
								  [UIImage imageNamed:@"Strobe_Light_15"],
								  [UIImage imageNamed:@"Strobe_Light_16"],
								  [UIImage imageNamed:@"Strobe_Light_17"],
								  [UIImage imageNamed:@"Strobe_Light_18"],
								  [UIImage imageNamed:@"Strobe_Light_19"],
								  [UIImage imageNamed:@"Strobe_Light_20"],
								  [UIImage imageNamed:@"Strobe_Light_21"],
								  [UIImage imageNamed:@"Strobe_Light_22"],
								  [UIImage imageNamed:@"Strobe_Light_23"],
								  [UIImage imageNamed:@"Strobe_Light_24"],
								  [UIImage imageNamed:@"Strobe_Light_25"],
								  [UIImage imageNamed:@"Strobe_Light_26"],
								  [UIImage imageNamed:@"Strobe_Light_27"],
								  [UIImage imageNamed:@"Strobe_Light_28"],
								  [UIImage imageNamed:@"Strobe_Light_29"],
								  [UIImage imageNamed:@"Strobe_Light_30"],
								  [UIImage imageNamed:@"Strobe_Light_31"],
								  [UIImage imageNamed:@"Strobe_Light_32"],
								  [UIImage imageNamed:@"Strobe_Light_33"],
								  [UIImage imageNamed:@"Strobe_Light_34"],
								  [UIImage imageNamed:@"Strobe_Light_35"],
								  [UIImage imageNamed:@"Strobe_Light_36"],
								  [UIImage imageNamed:@"Strobe_Light_37"],
								  [UIImage imageNamed:@"Strobe_Light_38"],
								  [UIImage imageNamed:@"Strobe_Light_39"],
								  [UIImage imageNamed:@"Strobe_Light_40"],
								  [UIImage imageNamed:@"Strobe_Light_41"],
								  [UIImage imageNamed:@"Strobe_Light_42"],
								  [UIImage imageNamed:@"Strobe_Light_43"],
								  [UIImage imageNamed:@"Strobe_Light_44"],
								  [UIImage imageNamed:@"Strobe_Light_45"],
								  [UIImage imageNamed:@"Strobe_Light_46"],
								  [UIImage imageNamed:@"Strobe_Light_47"],
								  [UIImage imageNamed:@"Strobe_Light_48"],
								  [UIImage imageNamed:@"Strobe_Light_49"],
								  [UIImage imageNamed:@"Strobe_Light_50"],
								  [UIImage imageNamed:@"Strobe_Light_51"],
								  [UIImage imageNamed:@"Strobe_Light_52"],
								  [UIImage imageNamed:@"Strobe_Light_53"],
								  [UIImage imageNamed:@"Strobe_Light_54"],
								  [UIImage imageNamed:@"Strobe_Light_55"],
								  [UIImage imageNamed:@"Strobe_Light_56"],
								  [UIImage imageNamed:@"Strobe_Light_57"],
								  [UIImage imageNamed:@"Strobe_Light_58"],
								  [UIImage imageNamed:@"Strobe_Light_59"],
								  [UIImage imageNamed:@"Strobe_Light_60"],
								  [UIImage imageNamed:@"Strobe_Light_61"],
								  [UIImage imageNamed:@"Strobe_Light_62"],
								  [UIImage imageNamed:@"Strobe_Light_63"],
								  [UIImage imageNamed:@"Strobe_Light_64"],
								  [UIImage imageNamed:@"Strobe_Light_65"],
								  [UIImage imageNamed:@"Strobe_Light_66"],
								  [UIImage imageNamed:@"Strobe_Light_67"],
								  [UIImage imageNamed:@"Strobe_Light_68"],
								  [UIImage imageNamed:@"Strobe_Light_69"],
								  [UIImage imageNamed:@"Strobe_Light_70"],
								  [UIImage imageNamed:@"Strobe_Light_71"],
								  [UIImage imageNamed:@"Strobe_Light_72"],
								  [UIImage imageNamed:@"Strobe_Light_73"],
								  [UIImage imageNamed:@"Strobe_Light_74"],
								  [UIImage imageNamed:@"Strobe_Light_75"],
								  [UIImage imageNamed:@"Strobe_Light_76"],
								  [UIImage imageNamed:@"Strobe_Light_77"],
								  [UIImage imageNamed:@"Strobe_Light_78"],
								  [UIImage imageNamed:@"Strobe_Light_79"],
								  [UIImage imageNamed:@"Strobe_Light_80"],
								  [UIImage imageNamed:@"Strobe_Light_81"],
								  [UIImage imageNamed:@"Strobe_Light_82"],
								  [UIImage imageNamed:@"Strobe_Light_83"],
								  [UIImage imageNamed:@"Strobe_Light"],
								  [UIImage imageNamed:@"Strobe_Light"],
								  [UIImage imageNamed:@"Strobe_Light"],
								  [UIImage imageNamed:@"Strobe_Light"],
								  [UIImage imageNamed:@"Strobe_Light"], nil]; // I repeated the last few frames to ease out the ending.
	
	// All frames will execute in 1.75 seconds.
	self.animationDuration = 1.75;
	
	// Repeat the annimation forever.
	self.animationRepeatCount = 0;
	
	// Start animating.
	[self startAnimating];
}

- (void)affirmativeStrobeLight
{
    [self stopAnimating];
    self.image = [UIImage imageNamed:@"Strobe_Light_Affirmative"];
    [NSTimer scheduledTimerWithTimeInterval:3.0
                                     target:self
                                   selector:@selector(deactivateStrobeLight)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)negativeStrobeLight
{
    [self stopAnimating];
    self.image = [UIImage imageNamed:@"Strobe_Light_Negative"];
    [NSTimer scheduledTimerWithTimeInterval:3.0
                                     target:self
                                   selector:@selector(deactivateStrobeLight)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)defaultStrobeLight
{
    [self stopAnimating];
    self.image = [UIImage imageNamed:@"Strobe_Light"];
}

- (void)deactivateStrobeLight
{
    [self stopAnimating];
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished){
        self.image = nil;
        self.alpha = 1;
    }];
}

- (void)setStrobeLightPosition:(SHStrobeLightPosition)position
{
    if ( (IS_IOS7) && position == SHStrobeLightPositionStatusBar ) // On iOS 7, there's no SHStrobeLightPositionStatusBar.
    {
        position = SHStrobeLightPositionFullScreen;
    }
    
    switch ( position )
    {
        case SHStrobeLightPositionFullScreen:
        {
            self.frame = CGRectMake(0, -9, self.frame.size.width, self.frame.size.height);
            break;
        }
            
        case SHStrobeLightPositionStatusBar:
        {
            self.frame = CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height - 9, self.frame.size.width, self.frame.size.height);
            break;
        }
            
        case SHStrobeLightPositionNavigationBar:
        {
            self.frame = CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height + 34, self.frame.size.width, self.frame.size.height);
            break;
        }
            
        default:
            break;
    }
    
    _oldPosition = _position;
    _position = position;
}

- (void)restoreOldPosition
{
    [self setStrobeLightPosition:_oldPosition];
}

@end
