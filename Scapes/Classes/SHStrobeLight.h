//
//  SHStrobeLight.h
//  Scapes
//
//  Created by MachOSX on 8/10/13.
//
//

@interface SHStrobeLight : UIImageView
{
    
}

@property (nonatomic) SHStrobeLightPosition oldPosition;
@property (nonatomic) SHStrobeLightPosition position;

- (void)activateStrobeLight;
- (void)affirmativeStrobeLight;
- (void)negativeStrobeLight;
- (void)defaultStrobeLight;
- (void)deactivateStrobeLight;
- (void)setStrobeLightPosition:(SHStrobeLightPosition)position;
- (void)restoreOldPosition;

@end
