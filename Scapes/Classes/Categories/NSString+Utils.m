//
//  NSString+Utils.m
//  Scapes
//
//  Created by MachOSX on 8/13/13.
//
//

#import "NSString+Utils.h"

@implementation NSString (Utils)

- (NSString *)stringByTrimmingLeadingWhitespace
{
    NSInteger i = 0;
    
    while ( (i < [self length])
           && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self characterAtIndex:i]] )
    {
        i++;
    }
    
    return [self substringFromIndex:i];
}

- (NSString *)stringByRemovingEmoji
{
    __block NSMutableString *temp = [NSMutableString string];
    
    [self enumerateSubstringsInRange: NSMakeRange(0, self.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
     ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop){
         
         const unichar hs = [substring characterAtIndex: 0];
         
         if ( 0xd800 <= hs && hs <= 0xdbff ) // Surrogate pair.
         {
             const unichar ls = [substring characterAtIndex: 1];
             const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
             
             [temp appendString: (0x1d000 <= uc && uc <= 0x1f77f)? @"": substring]; // U+1D000-1F77F
         }
         else // Non-surrogate pair.
         {
             [temp appendString: (0x2100 <= hs && hs <= 0x26ff)? @"": substring]; // U+2100-26FF
         }
     }];
    
    return temp;
}

@end
