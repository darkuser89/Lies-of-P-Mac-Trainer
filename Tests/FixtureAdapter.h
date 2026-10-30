// SPDX-License-Identifier: GPL-3.0-only
#import "GameAdapter.h"
// Pure in-process simulation. Never reads or writes a game or save file.
@interface MTFixtureAdapter : NSObject <MTGameAdapter>
@property(nonatomic) MTSessionKind mode;
@property(nonatomic,readonly) NSDictionary<NSNumber *,NSNumber *> *values;
- (void)newArea;
@end
