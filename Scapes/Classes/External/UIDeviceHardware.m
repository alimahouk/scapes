//
//  UIDeviceHardware.m
//
//  Used to determine EXACT version of device software is running on.

#import "UIDeviceHardware.h"
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation UIDeviceHardware

+ (NSString *)platform
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    
    return platform;
}

+ (NSString *)platformString
{
    NSString *platform = [self platform];
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3Gs";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4s";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5c (GSM)";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5c (Global)";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5s (GSM)";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5s (Global)";
    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (Wi-Fi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (Wi-Fi Rev A)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad mini (Wi-Fi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad mini (GSM)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad mini (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (Wi-Fi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (Wi-Fi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,1"])      return @"iPad Air (Wi-Fi)";
    if ([platform isEqualToString:@"iPad4,2"])      return @"iPad Air (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,4"])      return @"iPad mini with Retina Display (Wi-Fi)";
    if ([platform isEqualToString:@"iPad4,5"])      return @"iPad mini with Retina Display (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,7"])      return @"iPad mini 3 (WiFi)";
    if ([platform isEqualToString:@"iPad4,8"])      return @"iPad mini 3 (Cellular)";
    if ([platform isEqualToString:@"iPad4,9"])      return @"iPad mini 3 (China)";
    if ([platform isEqualToString:@"iPad5,3"])      return @"iPad Air 2 (WiFi)";
    if ([platform isEqualToString:@"iPad5,4"])      return @"iPad Air 2 (Cellular)";
    if ([platform isEqualToString:@"i386"])         return @"iOS Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"iOS Simulator";
    
    return platform;
}

+ (NSString *)platformNumericString
{
    NSString *platform = [self platform];
    if ([platform isEqualToString:@"iPhone1,1"])    return @"1";  // iPhone 1G
    if ([platform isEqualToString:@"iPhone1,2"])    return @"2";  // iPhone 3G
    if ([platform isEqualToString:@"iPhone2,1"])    return @"3";  // iPhone 3Gs
    if ([platform isEqualToString:@"iPhone3,1"])    return @"4";  // iPhone 4
    if ([platform isEqualToString:@"iPhone3,3"])    return @"5";  // Verizon iPhone 4
    if ([platform isEqualToString:@"iPhone4,1"])    return @"6";  // iPhone 4s
    if ([platform isEqualToString:@"iPhone5,1"])    return @"7";  // iPhone 5 (GSM)
    if ([platform isEqualToString:@"iPhone5,2"])    return @"8";  // iPhone 5 (GSM+CDMA)
    if ([platform isEqualToString:@"iPhone5,3"])    return @"9";  // iPhone 5c (GSM)
    if ([platform isEqualToString:@"iPhone5,4"])    return @"10"; // iPhone 5c (Global)
    if ([platform isEqualToString:@"iPhone6,1"])    return @"11"; // iPhone 5s (GSM)
    if ([platform isEqualToString:@"iPhone6,2"])    return @"12"; // iPhone 5s (Global)
    if ([platform isEqualToString:@"iPhone7,1"])    return @"37"; // iPhone 6 Plus
    if ([platform isEqualToString:@"iPhone7,2"])    return @"38"; // iPhone 6
    if ([platform isEqualToString:@"iPod1,1"])      return @"13"; // iPod Touch 1G
    if ([platform isEqualToString:@"iPod2,1"])      return @"14"; // iPod Touch 2G
    if ([platform isEqualToString:@"iPod3,1"])      return @"15"; // iPod Touch 3G
    if ([platform isEqualToString:@"iPod4,1"])      return @"16"; // iPod Touch 4G
    if ([platform isEqualToString:@"iPod5,1"])      return @"17"; // iPod Touch 5G
    if ([platform isEqualToString:@"iPad1,1"])      return @"18"; // iPad
    if ([platform isEqualToString:@"iPad2,1"])      return @"19"; // iPad 2 (Wi-Fi)
    if ([platform isEqualToString:@"iPad2,2"])      return @"20"; // iPad 2 (GSM)
    if ([platform isEqualToString:@"iPad2,3"])      return @"21"; // iPad 2 (CDMA)
    if ([platform isEqualToString:@"iPad2,4"])      return @"22"; // iPad 2 (Wi-Fi Rev A)
    if ([platform isEqualToString:@"iPad2,5"])      return @"23"; // iPad mini (Wi-Fi)
    if ([platform isEqualToString:@"iPad2,6"])      return @"24"; // iPad mini (GSM)
    if ([platform isEqualToString:@"iPad2,7"])      return @"25"; // iPad mini (GSM+CDMA)
    if ([platform isEqualToString:@"iPad3,1"])      return @"26"; // iPad 3 (Wi-Fi)
    if ([platform isEqualToString:@"iPad3,2"])      return @"27"; // iPad 3 (GSM+CDMA)
    if ([platform isEqualToString:@"iPad3,3"])      return @"28"; // iPad 3 (GSM)
    if ([platform isEqualToString:@"iPad3,4"])      return @"29"; // iPad 4 (Wi-Fi)
    if ([platform isEqualToString:@"iPad3,5"])      return @"30"; // iPad 4 (GSM)
    if ([platform isEqualToString:@"iPad3,6"])      return @"31"; // iPad 4 (GSM+CDMA)
    if ([platform isEqualToString:@"i386"])         return @"32"; // iOS Simulator
    if ([platform isEqualToString:@"x86_64"])       return @"32"; // iOS Simulator
    if ([platform isEqualToString:@"iPad4,1"])      return @"33"; // iPad Air (Wi-Fi)
    if ([platform isEqualToString:@"iPad4,2"])      return @"34"; // iPad Air (GSM+CDMA)
    if ([platform isEqualToString:@"iPad4,4"])      return @"35"; // iPad mini with Retina Display (Wi-Fi)
    if ([platform isEqualToString:@"iPad4,5"])      return @"36"; // iPad mini with Retina Display (GSM+CDMA)
    if ([platform isEqualToString:@"iPad4,7"])      return @"41"; // iPad mini 3 (WiFi)
    if ([platform isEqualToString:@"iPad4,8"])      return @"42"; // iPad mini 3 (Cellular)
    if ([platform isEqualToString:@"iPad4,9"])      return @"43"; // iPad mini 3 (China)
    if ([platform isEqualToString:@"iPad5,3"])      return @"39"; // iPad Air 2 (WiFi)
    if ([platform isEqualToString:@"iPad5,4"])      return @"40"; // iPad Air 2 (Cellular)
    
    return platform;
}

@end