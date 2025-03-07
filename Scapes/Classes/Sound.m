//
//  Sound.m
//  Scapes
//
//  Created by MachOSX on 8/20/13.
//
//


#import "Sound.h"

@implementation Sound

+ (void)playSoundEffect:(int)soundNumber
{
    NSString *effect = @"";
    NSString *type = @"";
	
	switch ( soundNumber )
    {
		case 1:
			effect = @"beep_1";
			type = @"aif";
			break;
            
        case 2:
			effect = @"beep_2";
			type = @"aif";
			break;
            
        case 3:
			effect = @"beep_3";
			type = @"aif";
			break;
            
        case 4:
			effect = @"beep_4";
			type = @"aif";
			break;
            
        case 5:
			effect = @"beep_5";
			type = @"aif";
			break;
            
        case 6:
			effect = @"beep_6";
			type = @"aif";
			break;
            
        case 7:
			effect = @"beep_7";
			type = @"aif";
			break;
            
        case 8:
			effect = @"pop_1";
			type = @"aif";
			break;
            
        case 9:
			effect = @"pop_2";
			type = @"aif";
			break;
            
        case 10:
			effect = @"radar_1";
			type = @"aif";
			break;
            
        case 11:
			effect = @"ding_1";
			type = @"aif";
			break;
            
        case 12:
			effect = @"ding_2";
			type = @"aif";
			break;
            
        case 13:
			effect = @"ding_3";
			type = @"aif";
			break;
            
		default:
			break;
	}
	
    SystemSoundID soundID;
	
    NSString *path = [[NSBundle mainBundle] pathForResource:effect ofType:type];
    NSURL *url = [NSURL fileURLWithPath:path];
	
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &soundID);
    AudioServicesPlaySystemSound(soundID);
}

@end
